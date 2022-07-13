////////////////////////////////////////////////////////////////////////////////
//
//   CAS Audio Player
//
//
//   CAS is a very simple audio player which runs the CAS Audio Engine.
//   The user is able to load a file of any audio format and play it, using
//   ASIO or DirectSound to load buffers.
//
//   Creation: 12/04/2021 by Airton Junior
//
////////////////////////////////////////////////////////////////////////////////
unit MainForm;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.Classes,
  System.SysUtils,
  System.UITypes,
  System.ImageList,
  Vcl.ComCtrls,
  Vcl.StdCtrls,
  Vcl.Dialogs,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.ImgList,
  AsioList,
  OpenAsio,
  Asio,
  Math,
  ShellApi,
  IOUtils,
  AudioManagerU,
  CasEngineU,
  CasDecoderU,
  CasTrackU,
  CasConstantsU,
  AcrylicFormU,
  Vcl.ExtCtrls;

type
  TPlayerGUI = class(TAcrylicForm)
    btnOpenFile           : TButton;
    btnPlay               : TButton;
    btnStop               : TButton;
    btnPause              : TButton;
    odOpenFile            : TOpenDialog;
    tbVolume              : TTrackBar;
    tbProgress            : TTrackBar;
    cbDriver              : TComboBox;
    btnDriverControlPanel : TButton;
    ilMediaButtons        : TImageList;
    sbTrackList           : TScrollBox;
    tbSpeed               : TTrackBar;

    procedure FormCreate                 (Sender: TObject);
    procedure FormDestroy                (Sender: TObject);
    procedure cbDriverChange             (Sender: TObject);
    procedure btnDriverControlPanelClick (Sender: TObject);
    procedure btnPauseClick              (Sender: TObject);
    procedure btnStopClick               (Sender: TObject);
    procedure btnPlayClick               (Sender: TObject);
    procedure btnJumpClick               (Sender: TObject);
    procedure btnOpenFileClick           (Sender: TObject);
    procedure tbVolumeChange             (Sender: TObject);
    procedure tbProgressChange           (Sender: TObject);
    procedure sbTrackListMouseWheelUp    (Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    procedure sbTrackListMouseWheelDown  (Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    procedure tbSpeedChange              (Sender: TObject);

  private
    m_bBlockBufferPositionUpdate : Boolean;
    m_bFileLoaded                : Boolean;

    m_nLoadedTrackCount          : Integer;

    m_CasEngine                  : TCasEngine;
    m_CasDecoder                 : TCasDecoder;
    m_CasTrack                   : TCasTrack;

    m_DriverList                 : TAsioDriverList;

    procedure EngineNotification(var MsgRec: TMessage); message CM_NotifyOwner;

    procedure AddTrackInfo(a_strTitle : String; a_nTrackId : Integer);

    procedure InitializeVariables;
    procedure ChangeEnabledObjects;
    procedure UpdateBufferPosition;
    procedure UpdateProgressBar;

end;

var
  PlayerGUI: TPlayerGUI;

implementation

{$R *.dfm}

//==============================================================================
procedure TPlayerGUI.FormCreate(Sender: TObject);
begin
  Inherited;
  Caption     := 'CAS Audio Player';
  Resizable   := False;
  Color       := $151515;
  BlurAmount  := 140;

  InitializeVariables;
  ChangeEnabledObjects;
end;

//==============================================================================
procedure TPlayerGUI.FormDestroy(Sender: TObject);
begin
  m_CasEngine.Free;
  m_CasDecoder.Free;
  m_CasTrack.Free;

  SetLength(m_DriverList, 0);
end;

//==============================================================================
procedure TPlayerGUI.InitializeVariables;
var
  nDriverIdx : Integer;
begin
  m_CasEngine  := TCasEngine.Create(Self, Handle);
  m_CasDecoder := TCasDecoder.Create;
  m_CasTrack   := nil;

  tbVolume.Position            := 30;
  m_nLoadedTrackCount          := 0;

  m_bFileLoaded                := False;
  m_bBlockBufferPositionUpdate := False;

  SetLength(m_DriverList, 0);
  ListAsioDrivers(m_DriverList);
  for nDriverIdx := Low(m_DriverList) to High(m_DriverList) do
    cbDriver.Items.Add(String(m_DriverList[nDriverIdx].name));
end;

//==============================================================================
procedure TPlayerGUI.EngineNotification(var MsgRec: TMessage);
begin
  case TNotificationType(MsgRec.Wparam) of
    ntBuffersDestroyed,
    ntBuffersCreated,
    ntDriverClosed     : ChangeEnabledObjects;

    ntRequestedReset   : cbDriverChange(cbDriver);

    ntBuffersUpdated   :
      begin
        UpdateProgressBar;
        ChangeEnabledObjects;
      end;
  end;
end;

//==============================================================================
procedure TPlayerGUI.ChangeEnabledObjects;
begin
  btnDriverControlPanel.Enabled := (m_CasEngine.Ready);
  btnOpenFile.Enabled           := (m_CasEngine.Ready);
  btnPlay.Enabled               := (m_CasEngine.Ready)       and
                                   (m_CasEngine.BuffersOn)   and
                                   (not m_CasEngine.Playing) and
                                   (m_bFileLoaded);
  btnPause.Enabled              := m_CasEngine.Playing;
  btnStop.Enabled               := m_CasEngine.Playing;
end;

//==============================================================================
procedure TPlayerGUI.sbTrackListMouseWheelDown(Sender: TObject;
  Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
begin
  sbTrackList.VertScrollBar.Position := sbTrackList.VertScrollBar.ScrollPos + 8;
end;

//==============================================================================
procedure TPlayerGUI.sbTrackListMouseWheelUp(Sender: TObject;
  Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
begin
  sbTrackList.VertScrollBar.Position := sbTrackList.VertScrollBar.ScrollPos - 8;
end;

//==============================================================================
procedure TPlayerGUI.cbDriverChange(Sender: TObject);
begin
  m_CasEngine.ChangeDriver(cbDriver.ItemIndex);

  ChangeEnabledObjects;
end;

//==============================================================================
procedure TPlayerGUI.btnOpenFileClick(Sender: TObject);
var
  dSampleRate : Double;
  strFileName : String;
begin
  if odOpenFile.Execute then
  begin
    m_bFileLoaded := True;

    try
      dSampleRate := m_CasEngine.SampleRate;

      for strFileName in odOpenFile.Files do
      begin
        m_CasTrack       := m_CasDecoder.DecodeFile(strFileName, dSampleRate);
        m_CasTrack.Level := 0.7;
        m_CasTrack.ID    := m_nLoadedTrackCount;
        m_CasEngine.AddTrack(m_CasTrack, 0);
        m_CasEngine.AddTrackToPlaylist(m_CasTrack.ID, m_CasEngine.Length);

        AddTrackInfo(m_CasTrack.Title, m_CasTrack.ID);
      end;
    except
      m_bFileLoaded := False;
    end;
  end;

  ChangeEnabledObjects;
end;

//==============================================================================
procedure TPlayerGUI.btnDriverControlPanelClick(Sender: TObject);
begin
  if m_CasEngine.Ready then
    m_CasEngine.AsioDriver.ControlPanel;
end;

//==============================================================================
procedure TPlayerGUI.btnPlayClick(Sender: TObject);
begin
  m_CasEngine.Play;
  ChangeEnabledObjects;
end;

//==============================================================================
procedure TPlayerGUI.btnPauseClick(Sender: TObject);
begin
  m_CasEngine.Pause;
  ChangeEnabledObjects;
end;

//==============================================================================
procedure TPlayerGUI.btnStopClick(Sender: TObject);
begin
  m_CasEngine.Stop;
  UpdateProgressBar;
  ChangeEnabledObjects;
end;

//==============================================================================
procedure TPlayerGUI.tbVolumeChange(Sender: TObject);
begin
  m_CasEngine.Level := (tbVolume.Max - tbVolume.Position) / tbVolume.Max;
end;

//==============================================================================
procedure TPlayerGUI.tbSpeedChange(Sender: TObject);
var
  dSpeed : Double;
begin
  case tbSpeed.Position of
    10: dSpeed := 0.1;
    9:  dSpeed := 0.3;
    8:  dSpeed := 0.5;
    7:  dSpeed := 0.75;
    6:  dSpeed := 0.9;
    5:  dSpeed := 1;
    4:  dSpeed := 1.2;
    3:  dSpeed := 1.5;
    2:  dSpeed := 2;
    1:  dSpeed := 3;
    0:  dSpeed := 5;
  else  dSpeed := 1;
  end;

  tbSpeed.Hint := 'Speed: ' + FloatToStr(dSpeed) + 'x';
  m_CasEngine.Playlist.Speed := dSpeed;
end;

//==============================================================================
procedure TPlayerGUI.tbProgressChange(Sender: TObject);
begin
  UpdateBufferPosition;
end;

//==============================================================================
procedure TPlayerGUI.UpdateBufferPosition;
var
  dProgress : Double;
begin
  if not m_bBlockBufferPositionUpdate then
  begin
    dProgress            := tbProgress.Position/tbProgress.Max;
    m_CasEngine.Position := Trunc(dProgress * m_CasEngine.Length);
  end;
end;

//==============================================================================
procedure TPlayerGUI.UpdateProgressBar;
begin
  m_bBlockBufferPositionUpdate := True;
  tbProgress.Position          := Trunc(m_CasEngine.Progress*tbProgress.Max);
  m_bBlockBufferPositionUpdate := False;
end;

//==============================================================================
procedure TPlayerGUI.AddTrackInfo(a_strTitle : String; a_nTrackId : Integer);
var
  lblTitle : TLabel;
  btnPlay  : TButton;
begin
  sbTrackList.VertScrollBar.Position := 0;

  lblTitle             := TLabel.Create(sbTrackList);
  lblTitle.Parent      := sbTrackList;
  lblTitle.Align       := alNone;
  lblTitle.Font.Size   := 10;
  lblTitle.Caption     := ' ' + IntToStr(m_nLoadedTrackCount + 1) + ') ' + a_strTitle;
  lblTitle.Top         := m_nLoadedTrackCount*25 + 3;
  lblTitle.Left        := 2;
  lblTitle.Width       := sbTrackList.Width - 75;
  lblTitle.Height      := 20;
  lblTitle.Transparent := False;
  lblTitle.Color       := clWhite;

  btnPlay              := TButton.Create(sbTrackList);
  btnPlay.Parent       := sbTrackList;
  btnPlay.Align        := alNone;
  btnPlay.Caption      := 'Jump';
  btnPlay.Name         := 'btn' + IntToStr(a_nTrackId);
  btnPlay.OnClick      := btnJumpClick;
  btnPlay.Width        := 40;
  btnPlay.Height       := 20;
  btnPlay.Left         := sbTrackList.Width - btnPlay.Width - 25;
  btnPlay.Top          := m_nLoadedTrackCount*25 + 3;

  Inc(m_nLoadedTrackCount);
end;

//==============================================================================
procedure TPlayerGUI.btnJumpClick(Sender : TObject);
var
  CasTrack : TCasTrack;
begin
  if m_CasEngine.Database.GetTrackByID(StrToInt(String((Sender as TButton).Name).SubString(3)), CasTrack) then
    m_CasEngine.Position := CasTrack.Position;
end;

end.
