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
unit PlayerFormU;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.Classes,
  System.SysUtils,
  System.UITypes,
  System.ImageList,
  System.Generics.Collections,
  Vcl.ComCtrls,
  Vcl.StdCtrls,
  Vcl.Dialogs,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.ImgList,
  Vcl.ExtCtrls,
  AsioList,
  Math,
  ShellApi,
  IOUtils,
  GDIPOBJ,
  AudioManagerU,
  CasEngineU,
  CasDecoderU,
  CasTrackU,
  CasConstantsU,
  AcrylicFormU,
  AcrylicButtonU,
  AcrylicTrackU,
  AcrylicLabelU,
  AcrylicGhostPanelU,
  AcrylicControlU,
  AcrylicScrollBoxU,
  AcrylicKnobU,
  AcrylicFrameU,
  AcrylicTrackBarU;

type
  TPlayerGUI = class(TAcrylicForm)
    odOpenFile            : TOpenDialog;
    cbDriver              : TComboBox;
    btnPrev               : TAcrylicButton;
    btnPlay               : TAcrylicButton;
    btnNext               : TAcrylicButton;
    btnOpenFile           : TAcrylicButton;
    btnDriverControlPanel : TAcrylicButton;
    btnStop               : TAcrylicButton;
    btnBlur               : TAcrylicButton;
    btnBarFunc            : TAcrylicButton;
    btnInfo               : TAcrylicButton;
    lblTime               : TAcrylicLabel;
    lblTitle              : TAcrylicLabel;
    lblVolume             : TAcrylicLabel;
    lblPitch              : TAcrylicLabel;
    lblLoading            : TAcrylicLabel;
    sbTracks              : TAcrylicScrollBox;
    knbLevel              : TAcrylicKnob;
    knbSpeed              : TAcrylicKnob;
    pnlBlurHint           : TPanel;
    tbProgress            : TAcrylicTrackBar;

        

    procedure FormCreate                 (Sender: TObject);
    procedure FormDestroy                (Sender: TObject);
    procedure FormKeyDown                (Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure cbDriverChange             (Sender: TObject);
    procedure btnDriverControlPanelClick (Sender: TObject);
    procedure btnStopClick               (Sender: TObject);
    procedure btnPlayClick               (Sender: TObject);
    procedure btnPrevClick               (Sender: TObject);
    procedure btnNextClick               (Sender: TObject);
    procedure btnBlurClick               (Sender: TObject);
    procedure btnPrevDblClick            (Sender: TObject);
    procedure btnCloseClick              (Sender: TObject);
    procedure btnAddClick                (Sender: TObject);
    procedure btnUpClick                 (Sender: TObject);
    procedure btnDownClick               (Sender: TObject);
    procedure btnOpenFileClick           (Sender: TObject);
    procedure btnBarFuncClick            (Sender: TObject);
    procedure btnInfoClick               (Sender: TObject);
    procedure trackClick                 (Sender: TObject);
    procedure trackWheelUp               (Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    procedure trackWheelDown             (Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    procedure tbProgressChange           (Sender: TObject);
    procedure knbLevelChange             (Sender: TObject);
    procedure knbSpeedChange             (Sender: TObject);

    procedure WMNCSize(var Message: TWMSize); message WM_SIZE;


  private
    m_bBlockBufferPositionUpdate : Boolean;
    m_bPlaylistBar               : Boolean;
    m_bStartPlaying              : Boolean;
    m_nLoadedTrackCount          : Integer;

    m_CasEngine                  : TCasEngine;
    m_CasDecoder                 : TCasDecoder;

    m_DriverList                 : TAsioDriverList;
    m_lstTracks                  : TList<TAcrylicGhostPanel>;
    m_lstFiles                   : TStringList;
    m_frameInfo                  : TAcrylicFrame;

    procedure EngineNotification(var MsgRec: TMessage); message CM_NotifyOwner;
    procedure DecodeReady       (var MsgRec: TMessage); message CM_NotifyDecode;

    procedure AddTrackInfo(a_CasTrack : TCasTrack);

    procedure InitializeVariables;
    procedure InitializeControls;
    procedure SetupInfoFrame;
    procedure LoadFiles;
    procedure ChangeEnabledObjects;
    procedure UpdateBufferPosition;
    procedure UpdateProgressBar;
    procedure RearrangeTracks;
    procedure SwapTracks(a_nTrack1, a_nTrack2 : Integer);

end;

const
  c_nPanelHeight   = 75;
  c_nPanelOffset   = 3;
  c_nFirstPanelTop = 3;
  c_nPanelGap      = 10;
  c_nButtonWidth   = 25;
  c_nButtonHeight  = 25;
  c_nButtonRight1  = 30;
  c_nButtonRight2  = 58;
  c_nButtonTop1    = 1;
  c_nButtonTop2    = 29;
  c_nTrackOffset   = 61;
  c_nBntBlurRight  = 150;

var
  PlayerGUI: TPlayerGUI;

implementation

uses
  GDIPAPI,
  GDIPUTIL,
  Vcl.Imaging.pngimage,
  CasUtilsU,
  CasTypesU,
  Registry,
  AcrylicUtilsU,
  AcrylicTypesU;

{$R *.dfm}

//==============================================================================
procedure TPlayerGUI.FormCreate(Sender: TObject);
begin
  Caption     := 'CAS Audio Player';
  Resizable   := False;
  BlurColor   := $000000;
  BackColor   := $1F1F1F;
  WithBorder  := True;
  BorderColor := $A064FFFF;
  BlurAmount  := 210;
  KeyPreview  := True;

  Resizable   := False;
  Width       := 500;
  Height      := 700;

  MinWidth    := 500;
  MinHeight   := 700;

  MaxWidth    := 500;
  MaxHeight   := 700;

  Style       := [fsClose, fsMinimize];

  InitializeVariables;
  InitializeControls;
  SetupInfoFrame;
  LoadFiles;

  ChangeEnabledObjects;

  Inherited;
end;

//==============================================================================
procedure TPlayerGUI.InitializeControls;
var
  pngImage : TPngImage;
begin
  pngImage := TPngImage.Create;
  pngImage.LoadFromResourceName(HInstance, 'btnPlay');
  btnPlay.Png := pngImage;

  pngImage := TPngImage.Create;
  pngImage.LoadFromResourceName(HInstance, 'btnPrev');
  btnPrev.Png := pngImage;

  pngImage := TPngImage.Create;
  pngImage.LoadFromResourceName(HInstance, 'btnNext');
  btnNext.Png := pngImage;

  pngImage := TPngImage.Create;
  pngImage.LoadFromResourceName(HInstance, 'btnStop');
  btnStop.Png := pngImage;

  btnBlur.Enabled     := SupportBlur;
  btnBlur.WithBorder  := True;
  btnBlur.FontColor   := $FFFF8B64;
  btnBlur.BorderColor := $1FFF8B64;

  btnBarFunc.FontColor := c_clSeaBlue;
  btnBarFunc.Text      := 'P';

  lblLoading.FontColor := $FFFF8B64;
  lblLoading.Visible   := False;

  btnBlur.ShowHint     := True;
  btnBlur.Hint         := 'Blur is available in Windows 10';
  pnlBlurHint.ShowHint := True;
  pnlBlurHint.Hint     := btnBlur.Hint;

  btnPrev.TriggerDblClick := True;

  btnInfo.FontColor    := $FFFF8B64;
  btnInfo.BorderColor  := $1FFF8B64;
end;

//==============================================================================
procedure TPlayerGUI.SetupInfoFrame;
var
  lblTitle : TAcrylicLabel;
  lblText  : TAcrylicLabel;
begin
  m_frameInfo           := TAcrylicFrame.Create(Self);
  m_frameInfo.Parent    := Self;
  m_frameInfo.Resisable := False;
  m_frameInfo.Width     := 300;
  m_frameInfo.Height    := 350;
  m_frameInfo.Left      := (ClientWidth  - m_frameInfo.Width)  div 2;
  m_frameInfo.Top       := (ClientHeight - m_frameInfo.Height) div 2;
  m_frameInfo.Title     := 'Information';
  m_frameInfo.Visible   := False;

  lblTitle                := TAcrylicLabel.Create(m_frameInfo.Body);
  lblTitle.Parent         := m_frameInfo.Body;
  lblTitle.Left           := 5;
  lblTitle.Top            := 5;
  lblTitle.Width          := m_frameInfo.Width - 10;
  lblTitle.Height         := 40;
  lblTitle.Color          := m_frameInfo.Body.Color;
  lblTitle.WithBackground := True;
  lblTitle.Font.Size      := 11;
  lblTitle.Font.Style     := [fsBold];
  lblTitle.Text           := 'Cas Audio Player 1.0';

  lblText                := TAcrylicLabel.Create(m_frameInfo.Body);
  lblText.Parent         := m_frameInfo.Body;
  lblText.Left           := 5;
  lblText.Top            := 45;
  lblText.Width          := m_frameInfo.Width - 10;
  lblText.Height         := m_frameInfo.Height - 10;
  lblText.Color          := m_frameInfo.Body.Color;
  lblText.Font.Size      := 9;
  lblText.WithBackground := True;

  lblText.Texts.Add('Created by A. H. Junior - 2021');
  lblText.Texts.Add('Version 1.0');
  lblText.Texts.Add('');
  lblText.Texts.Add('Extra functionalities:');
  lblText.Texts.Add(' 1. Shift + scroll in tracks to rearrange them');
  lblText.Texts.Add(' 2. Press numbers (1-9) to jump to a specific ');
  lblText.Texts.Add('    track');
  lblText.Texts.Add(' 3. Double click in knobs to reset value (0.5)');
  lblText.Texts.Add(' 4. Press P/T button to change trackbar to');
  lblText.Texts.Add('    playlist/track mode');
  lblText.Texts.Add(' 5. Press SpaceBar to play/pause');
  lblText.Texts.Add('');
  lblText.Texts.Add('');
  lblText.Texts.Add('Add your suggestions as Issues at:');
  lblText.Texts.Add('https://github.com/ah-jr/CAS-Audio-Player');
end;

//==============================================================================
procedure TPlayerGUI.LoadFiles;
begin
  if ParamCount > 0 then
  begin
    m_lstFiles.Clear;
    m_lstFiles.Add(ParamStr(1));
    m_bStartPlaying    := True;
    lblLoading.Visible := True;

    m_CasDecoder.AsyncDecodeFile(Handle, m_lstFiles, m_CasEngine.SampleRate);
  end;
end;

//==============================================================================
procedure TPlayerGUI.FormDestroy(Sender: TObject);
var
  pnlPanel : TAcrylicGhostPanel;
begin
  m_CasEngine.Free;
  m_CasDecoder.Free;

  for pnlPanel in m_lstTracks do
    pnlPanel.Destroy;

  FreeAndNil(m_lstTracks);
  FreeAndNil(m_lstFiles);

  SetLength(m_DriverList, 0);
end;

//==============================================================================
procedure TPlayerGUI.WMNCSize(var Message: TWMSize);
var
  nIndex : Integer;
begin
  inherited;

  pnlBlurHint.Left := ClientWidth - pnlBlurHint.Width - c_nBntBlurRight;
  btnInfo.Left     := pnlBlurHint.Left - btnInfo.Width - 5;

  sbTracks.Width  := ClientWidth  - 50;
  sbTracks.Height := ClientHeight - 170;

  if (m_lstTracks <> nil) then
  begin
    for nIndex := 0 to m_lstTracks.Count - 1 do
    begin
      (m_lstTracks.Items[nIndex] as TAcrylicGhostPanel).Width := sbTracks.ScrollPanel.Width - 2 * c_nPanelOffset;

      (m_lstTracks.Items[nIndex] as TAcrylicGhostPanel).Controls[0].Left := sbTracks.ScrollPanel.Width - 2 * c_nPanelOffset - c_nButtonRight2;
      (m_lstTracks.Items[nIndex] as TAcrylicGhostPanel).Controls[1].Left := sbTracks.ScrollPanel.Width - 2 * c_nPanelOffset - c_nButtonRight2;
      (m_lstTracks.Items[nIndex] as TAcrylicGhostPanel).Controls[2].Left := sbTracks.ScrollPanel.Width - 2 * c_nPanelOffset - c_nButtonRight1;
      (m_lstTracks.Items[nIndex] as TAcrylicGhostPanel).Controls[3].Left := sbTracks.ScrollPanel.Width - 2 * c_nPanelOffset - c_nButtonRight1;

      (m_lstTracks.Items[nIndex] as TAcrylicGhostPanel).Controls[4].Width := sbTracks.ScrollPanel.Width - 2 * c_nPanelOffset - c_nTrackOffset;
    end;
  end;
end;

//==============================================================================
procedure TPlayerGUI.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_SPACE then
    btnPlayClick(nil);

  if GE_L(Key, $30, $3A) and ((Key - 49) <  m_lstTracks.Count) then
    m_CasEngine.GoToTrack(StrToInt(String((m_lstTracks.Items[Key - 49] as TAcrylicGhostPanel).Name).SubString(3)));
end;

//==============================================================================
procedure TPlayerGUI.InitializeVariables;
var
  nDriverIdx : Integer;
begin
  m_CasEngine   := TCasEngine.Create(Self, Handle);
  m_CasDecoder  := TCasDecoder.Create;

  m_lstTracks   := TList<TAcrylicGhostPanel>.Create;
  m_lstFiles    := TStringList.Create;

  knbLevel.Level := 0.7;
  knbSpeed.Level := 0.5;

  m_nLoadedTrackCount := 0;

  m_bPlaylistBar               := True;
  m_bStartPlaying              := False;
  m_bBlockBufferPositionUpdate := False;

  SetLength(m_DriverList, 0);
  ListAsioDrivers(m_DriverList);
  cbDriver.Items.Add('DirectSound');

  for nDriverIdx := Low(m_DriverList) to High(m_DriverList) do
    cbDriver.Items.Add(String(m_DriverList[nDriverIdx].name));

  cbDriver.ItemIndex := 0;
  cbDriverChange(cbDriver);
end;

//==============================================================================
procedure TPlayerGUI.EngineNotification(var MsgRec: TMessage);
begin
  case TNotificationType(MsgRec.Wparam) of
    ntBuffersDestroyed,
    ntBuffersCreated,
    ntDriverClosed     : ChangeEnabledObjects;
    ntRequestedReset   : cbDriverChange(cbDriver);
    ntBuffersUpdated   : UpdateProgressBar;
  end;
end;

//==============================================================================
procedure TPlayerGUI.DecodeReady(var MsgRec: TMessage);
var
  CasTrack : TCasTrack;
begin
  for CasTrack in m_CasDecoder.Tracks do
  begin
    CasTrack.Level := 0.7;
    CasTrack.ID    := m_CasEngine.GenerateID;
    m_CasEngine.AddTrack(CasTrack, 0);
    m_CasEngine.AddTrackToPlaylist(CasTrack.ID, m_CasEngine.Length);
    AddTrackInfo(CasTrack);
  end;

  if m_bStartPlaying then
    btnPlayClick(nil);

  lblLoading.Visible := False;
  m_CasDecoder.Tracks.Clear;
  ChangeEnabledObjects;
end;

//==============================================================================
procedure TPlayerGUI.ChangeEnabledObjects;
begin
  btnOpenFile.Enabled           := (m_CasEngine.Ready);
  btnDriverControlPanel.Enabled := (m_CasEngine.Ready) and
                                   (m_CasEngine.DriverType = dtASIO);

  btnPlay.Enabled               := (m_CasEngine.Ready) and
                                   (m_nLoadedTrackCount > 0);

  btnStop.Enabled               := (m_nLoadedTrackCount > 0);
  btnPrev.Enabled               := (m_nLoadedTrackCount > 0);
  btnNext.Enabled               := (m_nLoadedTrackCount > 0);
  btnBarFunc.Enabled            := (m_nLoadedTrackCount > 0);
  tbProgress.Enabled            := (m_nLoadedTrackCount > 0);

  RefreshAcrylicControls(Self);
end;

//==============================================================================
procedure TPlayerGUI.cbDriverChange(Sender: TObject);
var
  dtDriverType : TDriverType;
  pngImage     : TPngImage;
begin
  if cbDriver.ItemIndex = 0
    then dtDriverType := dtDirectSound
    else dtDriverType := dtASIO;

  m_CasEngine.ChangeDriver(dtDriverType, cbDriver.ItemIndex - 1);
  m_CasEngine.AsyncUpdate := dtDriverType = dtDirectSound;

  pngImage    := TPngImage.Create;
  pngImage.LoadFromResourceName(HInstance, 'btnPlay');
  btnPlay.Png := pngImage;

  ChangeEnabledObjects;
end;

//==============================================================================
procedure TPlayerGUI.btnOpenFileClick(Sender: TObject);
begin
  if odOpenFile.Execute then
  begin
    try
      m_CasDecoder.AsyncDecodeFile(Handle, odOpenFile.Files, m_CasEngine.SampleRate);

      lblLoading.Visible := True;
    finally
    end;
  end;
end;

//==============================================================================
procedure TPlayerGUI.btnDriverControlPanelClick(Sender: TObject);
begin
  if m_CasEngine.Ready then
    m_CasEngine.ControlPanel;
end;

//==============================================================================
procedure TPlayerGUI.btnInfoClick(Sender: TObject);
begin
  m_frameInfo.Visible := not m_frameInfo.Visible;
end;

//==============================================================================
procedure TPlayerGUI.btnPlayClick(Sender: TObject);
var
  pngImage : TPngImage;
begin
  if m_CasEngine.Playing then
  begin
    pngImage    := TPngImage.Create;
    pngImage.LoadFromResourceName(HInstance, 'btnPlay');
    btnPlay.Png := pngImage;

    m_CasEngine.Pause;
  end
  else
  begin
    pngImage    := TPngImage.Create;
    pngImage.LoadFromResourceName(HInstance, 'btnPause');
    btnPlay.Png := pngImage;

    m_CasEngine.Play;
  end;

  ChangeEnabledObjects;
end;

//==============================================================================
procedure TPlayerGUI.btnStopClick(Sender: TObject);
var
  pngImage : TPngImage;
begin
  pngImage    := TPngImage.Create;
  pngImage.LoadFromResourceName(HInstance, 'btnPlay');
  btnPlay.Png := pngImage;

  m_CasEngine.Stop;
  UpdateProgressBar;
  ChangeEnabledObjects;
end;

//==============================================================================
procedure TPlayerGUI.btnPrevClick(Sender: TObject);
begin
  m_CasEngine.Prev;
  UpdateProgressBar;
  ChangeEnabledObjects;
end;

//==============================================================================
procedure TPlayerGUI.btnNextClick(Sender: TObject);
begin
  m_CasEngine.Next;
  UpdateProgressBar;
  ChangeEnabledObjects;
end;

//==============================================================================
procedure TPlayerGUI.btnPrevDblClick(Sender: TObject);
begin
  m_CasEngine.Prev;
  m_CasEngine.Prev;
  UpdateProgressBar;
  ChangeEnabledObjects;
end;

//==============================================================================
procedure TPlayerGUI.knbLevelChange(Sender: TObject);
begin
  m_CasEngine.Level := knbLevel.Level;
end;

//==============================================================================
procedure TPlayerGUI.knbSpeedChange(Sender: TObject);
begin
  m_CasEngine.Playlist.Speed := 2 * knbSpeed.Level;
end;

//==============================================================================
procedure TPlayerGUI.tbProgressChange(Sender: TObject);
begin
  UpdateBufferPosition;
end;

//==============================================================================
procedure TPlayerGUI.UpdateBufferPosition;
var
  CasTrack  : TCasTrack;
begin
  if not m_bBlockBufferPositionUpdate then
  begin
    if m_bPlaylistBar then
      m_CasEngine.Position := Trunc(tbProgress.Level * m_CasEngine.Length)
    else
    begin
      if (m_CasEngine.ActiveTracks.Count > 0) and
         (m_CasEngine.Database.GetTrackById(m_CasEngine.ActiveTracks.Items[0], CasTrack)) then
      begin
        m_CasEngine.Position := CasTrack.Position + Trunc(tbProgress.Level * CasTrack.Size);
      end;
    end;
  end;
end;

//==============================================================================
procedure TPlayerGUI.UpdateProgressBar;
var
  CasTrack  : TCasTrack;
  dProgress : Double;
  nPanelIdx : Integer;
begin
  m_bBlockBufferPositionUpdate := True;
  if m_bPlaylistBar then
  begin
    tbProgress.Level := m_CasEngine.Progress;
    lblTime.Text     := m_CasEngine.GetTime + '/' + m_CasEngine.GetDuration;
  end
  else
  begin
    if m_CasEngine.ActiveTracks.Count > 0 then
    begin
      tbProgress.Level := m_CasEngine.GetTrackProgress(m_CasEngine.ActiveTracks.Items[0]);
      lblTime.Text     := m_CasEngine.GetTime + '/' + m_CasEngine.GetDuration;
    end
    else
    begin
      tbProgress.Level := 0;
      lblTime.Text     := m_CasEngine.GetTime + '/' + m_CasEngine.GetDuration;
    end;
  end;
  m_bBlockBufferPositionUpdate := False;
  
  for nPanelIdx := 0 to m_lstTracks.Count - 1 do
  begin
    if m_CasEngine.Database.GetTrackByID(StrToInt(String((m_lstTracks.Items[nPanelIdx] as TAcrylicGhostPanel).Name).SubString(3)), CasTrack) then
    begin
      dProgress := (m_CasEngine.Position - CasTrack.Position) / CasTrack.Size;

      ((m_lstTracks.Items[nPanelIdx] as TAcrylicGhostPanel).Controls[4] as TAcrylicTrack).Position := dProgress;
      ((m_lstTracks.Items[nPanelIdx] as TAcrylicGhostPanel).Controls[4] as TAcrylicTrack).Refresh;
    end;
  end;
end;

//==============================================================================
procedure TPlayerGUI.RearrangeTracks;
var
  nPanelIdx   : Integer;
  TotalLength : Integer;
  CasTrack    : TCasTrack;
begin
  TotalLength := 0;

  for nPanelIdx := 0 to m_lstTracks.Count - 1 do
  begin
    (m_lstTracks.Items[nPanelIdx] as TAcrylicGhostPanel).Top := nPanelIdx * (c_nPanelGap + c_nPanelHeight) + c_nFirstPanelTop;

    if m_CasEngine.Database.GetTrackByID(StrToInt(String((m_lstTracks.Items[nPanelIdx] as TAcrylicGhostPanel).Name).SubString(3)), CasTrack) then
    begin
      CasTrack.Position := TotalLength;
      TotalLength := TotalLength + CasTrack.Size;

      ((m_lstTracks.Items[nPanelIdx] as TAcrylicGhostPanel).Controls[4] as TAcrylicTrack).Text := IntToStr(nPanelIdx + 1) + ') ' + CasTrack.Title;
    end;
  end;
end;

//==============================================================================
procedure TPlayerGUI.SwapTracks(a_nTrack1, a_nTrack2 : Integer);
var
  pnlTrack1 : TAcrylicGhostPanel;
  pnlTrack2 : TAcrylicGhostPanel;
begin
  if (a_nTrack1 < m_lstTracks.Count) and
     (a_nTrack2 < m_lstTracks.Count) and
     (a_nTrack1 <> a_nTrack2)        and
     (a_nTrack1 >= 0)                and
     (a_nTrack2 >= 0) then
  begin
    pnlTrack1 := m_lstTracks.Items[a_nTrack1];
    pnlTrack2 := m_lstTracks.Items[a_nTrack2];

    m_lstTracks.Remove(pnlTrack1);
    m_lstTracks.Remove(pnlTrack2);

    if a_nTrack1 < a_nTrack2 then
    begin
      m_lstTracks.Insert(a_nTrack1, pnlTrack2);
      m_lstTracks.Insert(a_nTrack2, pnlTrack1);
    end
    else
    begin
      m_lstTracks.Insert(a_nTrack2, pnlTrack1);
      m_lstTracks.Insert(a_nTrack1, pnlTrack2);
    end;

    RearrangeTracks;
    RefreshAcrylicControls(Self);
  end;
end;

//==============================================================================
procedure TPlayerGUI.btnBarFuncClick(Sender: TObject);
begin
  m_bPlaylistBar := not m_bPlaylistBar;

  if m_bPlaylistBar then
  begin
    tbProgress.TrackColor := c_clSeaBlue;
    btnBarFunc.FontColor  := c_clSeaBlue;
    btnBarFunc.Text       := 'P';
  end
  else
  begin
    tbProgress.TrackColor := c_clLavaOrange;
    btnBarFunc.FontColor  := c_clLavaOrange;
    btnBarFunc.Text       := 'T';
  end
end;

//==============================================================================
procedure TPlayerGUI.btnBlurClick(Sender: TObject);
begin
  inherited;
  WithBlur := not WithBlur;
end;

procedure TPlayerGUI.AddTrackInfo(a_CasTrack : TCasTrack);
var
  pnlTrack     : TAcrylicGhostPanel;
  btnUp        : TAcrylicButton;
  btnDown      : TAcrylicButton;
  btnAdd       : TAcrylicButton;
  btnClose     : TAcrylicButton;
  AcrylicTrack : TAcrylicTrack;
  pngImage     : TPngImage;
begin
  //////////////////////////////////////////////////////////////////////////////
  // Track Panel
  pnlTrack             := TAcrylicGhostPanel.Create(Self);
  pnlTrack.Parent      := Self;
  pnlTrack.BevelOuter  := bvNone;
  pnlTrack.Align       := alNone;
  pnlTrack.Caption     := '';
  pnlTrack.Name        := 'pnl' + IntToStr(a_CasTrack.ID);
  pnlTrack.Width       := sbTracks.ScrollPanel.Width - 2 * c_nPanelOffset;
  pnlTrack.Height      := c_nPanelHeight;
  pnlTrack.Left        := c_nPanelOffset;
  pnlTrack.Top         := m_nLoadedTrackCount * (c_nPanelGap + c_nPanelHeight) + c_nFirstPanelTop;

  sbTracks.AddControl(pnlTrack);
  m_lstTracks.Add(pnlTrack);

  //////////////////////////////////////////////////////////////////////////////
  // Button to move up
  btnUp                := TAcrylicButton.Create(pnlTrack);
  btnUp.Parent         := pnlTrack;
  btnUp.Align          := alNone;
  btnUp.Top            := c_nButtonTop1;
  btnUp.Left           := pnlTrack.Width - c_nButtonRight2;
  btnUp.Text           := '';
  btnUp.Name           := 'btnUp_' + IntToStr(a_CasTrack.ID);
  btnUp.OnClick        := btnUpClick;
  btnUp.Width          := c_nButtonWidth;
  btnUp.Height         := c_nButtonHeight;
  pngImage             := TPngImage.Create;
  pngImage.LoadFromResourceName(HInstance, 'btnUp');
  btnUp.Png            := pngImage;

  //////////////////////////////////////////////////////////////////////////////
  // Button to move down
  btnDown              := TAcrylicButton.Create(pnlTrack);
  btnDown.Parent       := pnlTrack;
  btnDown.Align        := alNone;
  btnDown.Top          := c_nButtonTop2;
  btnDown.Left         := pnlTrack.Width - c_nButtonRight2;
  btnDown.Text         := '';
  btnDown.Name         := 'btnDown_' + IntToStr(a_CasTrack.ID);
  btnDown.OnClick      := btnDownClick;
  btnDown.Width        := c_nButtonWidth;
  btnDown.Height       := c_nButtonHeight;
  pngImage             := TPngImage.Create;
  pngImage.LoadFromResourceName(HInstance, 'btnDown');
  btnDown.Png          := pngImage;

  //////////////////////////////////////////////////////////////////////////////
  // Button to clone track
  btnAdd               := TAcrylicButton.Create(pnlTrack);
  btnAdd.Parent        := pnlTrack;
  btnAdd.Align         := alNone;
  btnAdd.Top           := c_nButtonTop2;
  btnAdd.Left          := pnlTrack.Width - c_nButtonRight1;
  btnAdd.Text          := '';
  btnAdd.Name          := 'btnAdd_' + IntToStr(a_CasTrack.ID);
  btnAdd.OnClick       := btnAddClick;
  btnAdd.Width         := c_nButtonWidth;
  btnAdd.Height        := c_nButtonHeight;
  pngImage             := TPngImage.Create;
  pngImage.LoadFromResourceName(HInstance, 'btnAdd');
  btnAdd.Png           := pngImage;

  //////////////////////////////////////////////////////////////////////////////
  // Button to close track
  btnClose             := TAcrylicButton.Create(pnlTrack);
  btnClose.Parent      := pnlTrack;
  btnClose.Align       := alNone;
  btnClose.Top         := c_nButtonTop1;
  btnClose.Left        := pnlTrack.Width - c_nButtonRight1;
  btnClose.Text        := '';
  btnClose.Name        := 'btnClose_' + IntToStr(a_CasTrack.ID);
  btnClose.OnClick     := btnCloseClick;
  btnClose.Width       := c_nButtonWidth;
  btnClose.Height      := c_nButtonHeight;
  pngImage             := TPngImage.Create;
  pngImage.LoadFromResourceName(HInstance, 'btnClose');
  btnClose.Png         := pngImage;

  //////////////////////////////////////////////////////////////////////////////
  // Track title and image
  AcrylicTrack         := TAcrylicTrack.Create(pnlTrack);
  AcrylicTrack.Parent  := pnlTrack;
  AcrylicTrack.Align   := alNone;
  AcrylicTrack.Width   := pnlTrack.Width - c_nTrackOffset;
  AcrylicTrack.Height  := c_nPanelHeight;
  AcrylicTrack.OnClick := trackClick;
  AcrylicTrack.OnMouseWheelUp   := trackWheelUp;
  AcrylicTrack.OnMouseWheelDown := trackWheelDown;
  AcrylicTrack.Text    := IntToStr(m_nLoadedTrackCount + 1) + ') ' + a_CasTrack.Title;
  AcrylicTrack.Name    := 'trkTrack_' + IntToStr(a_CasTrack.ID);
  AcrylicTrack.SetData(@a_CasTrack.RawData.Right, a_CasTrack.Size);

  lblTime.Text := m_CasEngine.GetTime + '/' + m_CasEngine.GetDuration;
  Inc(m_nLoadedTrackCount);
end;

//==============================================================================
procedure TPlayerGUI.btnCloseClick(Sender : TObject);
var
  CasTrack : TCasTrack;
begin
  if m_CasEngine.Database.GetTrackByID(StrToInt(String((Sender as TAcrylicButton).Parent.Name).SubString(3)), CasTrack) then
  begin
    m_CasEngine.Position := m_CasEngine.Position - CasTrack.Size;
    m_CasEngine.DeleteTrack(CasTrack.ID);
  end;

  m_lstTracks.Remove((Sender as TAcrylicButton).Parent as TAcrylicGhostPanel);
  (Sender as TAcrylicButton).Parent.Destroy;
  Dec(m_nLoadedTrackCount);

  if m_nLoadedTrackCount = 0 then
    m_CasEngine.Stop;

  RearrangeTracks;
  UpdateProgressBar;
  ChangeEnabledObjects;
end;

//==============================================================================
procedure TPlayerGUI.btnAddClick(Sender : TObject);
var
  OriginalTrack : TCasTrack;
  NewTrack      : TCasTrack;
begin
  if m_CasEngine.Database.GetTrackByID(StrToInt(String((Sender as TAcrylicButton).Parent.Name).SubString(3)), OriginalTrack) then
  begin
    NewTrack       := OriginalTrack.Clone;
    NewTrack.ID    := m_CasEngine.GenerateID;
    m_CasEngine.AddTrack(NewTrack, 0);
    m_CasEngine.AddTrackToPlaylist(NewTrack.ID, m_CasEngine.Length);

    AddTrackInfo(NewTrack);

    UpdateProgressBar;
  end;
end;

//==============================================================================
procedure TPlayerGUI.btnUpClick(Sender : TObject);
var
  nTrack : Integer;
begin
  nTrack := m_lstTracks.IndexOf((Sender as TAcrylicButton).Parent as TAcrylicGhostPanel);

  SwapTracks(nTrack, nTrack - 1);
end;

//==============================================================================
procedure TPlayerGUI.btnDownClick(Sender : TObject);
var
  nTrack : Integer;
begin
  nTrack := m_lstTracks.IndexOf((Sender as TAcrylicButton).Parent as TAcrylicGhostPanel);

  SwapTracks(nTrack, nTrack + 1);
end;

//==============================================================================
procedure TPlayerGUI.trackClick(Sender : TObject);
begin
  m_CasEngine.GoToTrack(StrToInt(String((Sender as TAcrylicTrack).Parent.Name).SubString(3)));
  UpdateProgressBar;
end;

//==============================================================================
procedure TPlayerGUI.trackWheelUp(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
var
  ptMouse : TPoint;
  nTrack  : Integer;
  nDist   : Integer;
begin
  if ssShift in Shift then
  begin
    nTrack  := m_lstTracks.IndexOf((Sender as TAcrylicTrack).Parent as TAcrylicGhostPanel);
    nDist   := c_nPanelGap + c_nPanelHeight;

    SwapTracks(nTrack, nTrack - 1);

    GetCursorPos(ptMouse);
    ptMouse := ScreenToClient(ptMouse);

    if (ptMouse.Y - nDist) < (sbTracks.Top) then
    begin
      sbTracks.Scroll(nDist);
    end
    else if nTrack > 0 then
    begin
      ptMouse := Mouse.CursorPos;
      SetCursorPos(ptMouse.X, ptMouse.Y - nDist);
    end;
  end;
end;

//==============================================================================
procedure TPlayerGUI.trackWheelDown(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
var
  ptMouse : TPoint;
  nTrack  : Integer;
  nDist   : Integer;
begin
  if ssShift in Shift then
  begin
    nTrack  := m_lstTracks.IndexOf((Sender as TAcrylicTrack).Parent as TAcrylicGhostPanel);
    nDist   := c_nPanelGap + c_nPanelHeight;

    SwapTracks(nTrack, nTrack + 1);

    GetCursorPos(ptMouse);
    ptMouse := ScreenToClient(ptMouse);

    if (ptMouse.Y + nDist) > (sbTracks.Top + sbTracks.Height) then
    begin
      sbTracks.Scroll(-nDist);
    end
    else if nTrack < m_lstTracks.Count - 1 then
    begin
      ptMouse := Mouse.CursorPos;
      SetCursorPos(ptMouse.X, ptMouse.Y + nDist);
    end;
  end;
end;

end.
