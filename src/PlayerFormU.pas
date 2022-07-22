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
  AcrylicControlU;

type
  TPlayerGUI = class(TAcrylicForm)
    odOpenFile            : TOpenDialog;
    tbVolume              : TTrackBar;
    tbProgress            : TTrackBar;
    tbSpeed               : TTrackBar;
    cbDriver              : TComboBox;
    btnPrev               : TAcrylicButton;
    btnPlay               : TAcrylicButton;
    btnNext               : TAcrylicButton;
    btnOpenFile           : TAcrylicButton;
    btnDriverControlPanel : TAcrylicButton;
    btnStop               : TAcrylicButton;
    btnBlur               : TAcrylicButton;
    lblTime               : TAcrylicLabel;
    lblTitle              : TAcrylicLabel;
    pnlBlurHint           : TPanel;


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
    procedure trackClick                 (Sender: TObject);
    procedure trackWheelUp               (Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    procedure trackWheelDown             (Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    procedure tbVolumeChange             (Sender: TObject);
    procedure tbProgressChange           (Sender: TObject);
    procedure tbSpeedChange              (Sender: TObject);

    procedure WMNCSize(var Message: TWMSize); message WM_SIZE;

  private
    m_bBlockBufferPositionUpdate : Boolean;
    m_nLoadedTrackCount          : Integer;

    m_CasEngine                  : TCasEngine;
    m_CasDecoder                 : TCasDecoder;

    m_DriverList                 : TAsioDriverList;
    m_lstTracks                  : TList<TAcrylicGhostPanel>;

    procedure EngineNotification(var MsgRec: TMessage); message CM_NotifyOwner;

    procedure AddTrackInfo(a_CasTrack : TCasTrack);

    procedure InitializeVariables;
    procedure InitializeControls;
    procedure ChangeEnabledObjects;
    procedure UpdateBufferPosition;
    procedure UpdateProgressBar;
    procedure RearrangeTracks;
    procedure UpdateFormSize;
    procedure SwitchTracks(a_nTrack1, a_nTrack2 : Integer);
end;

const
  c_nPanelHeight   = 75;
  c_nPanelOffset   = 25;
  c_nFirstPanelTop = 145;
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
  AcrylicUtilsU;

{$R *.dfm}

//==============================================================================
procedure TPlayerGUI.FormCreate(Sender: TObject);
begin
  Inherited;
  Caption     := 'CAS Audio Player';
  Resizable   := False;
  BlurColor   := $000000;
  BackColor   := $1F1F1F;
  WithBorder  := True;
  BorderColor := $A064FFFF;
  BlurAmount  := 150;
  KeyPreview  := True;

  Resizable   := True;
  Width       := 500;
  Height      := 500;

  MinHeight   := 500;
  MinWidth    := 500;

  MaxHeight   := 1000;
  MaxWidth    := 1000;

  InitializeVariables;
  InitializeControls;

  ChangeEnabledObjects;
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

  btnBlur.ShowHint     := True;
  btnBlur.Hint         := 'Blur is available in Windows 10';
  pnlBlurHint.ShowHint := True;
  pnlBlurHint.Hint     := btnBlur.Hint;
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

  m_lstTracks.Free;

  SetLength(m_DriverList, 0);
end;

//==============================================================================
procedure TPlayerGUI.WMNCSize(var Message: TWMSize);
var
  nIndex : Integer;
begin
  inherited;

  pnlBlurHint.Left := ClientWidth - pnlBlurHint.Width - c_nBntBlurRight;

  if (m_lstTracks <> nil) then
  begin
    for nIndex := 0 to m_lstTracks.Count - 1 do
    begin
      (m_lstTracks.Items[nIndex] as TAcrylicGhostPanel).Width := Self.Width - 2 * c_nPanelOffset;

      (m_lstTracks.Items[nIndex] as TAcrylicGhostPanel).Controls[0].Left := Self.Width - 2 * c_nPanelOffset - c_nButtonRight2;
      (m_lstTracks.Items[nIndex] as TAcrylicGhostPanel).Controls[1].Left := Self.Width - 2 * c_nPanelOffset - c_nButtonRight2;
      (m_lstTracks.Items[nIndex] as TAcrylicGhostPanel).Controls[2].Left := Self.Width - 2 * c_nPanelOffset - c_nButtonRight1;
      (m_lstTracks.Items[nIndex] as TAcrylicGhostPanel).Controls[3].Left := Self.Width - 2 * c_nPanelOffset - c_nButtonRight1;

      (m_lstTracks.Items[nIndex] as TAcrylicGhostPanel).Controls[4].Width := Self.Width - 2 * c_nPanelOffset - c_nTrackOffset;
    end;
  end;
end;

//==============================================================================
procedure TPlayerGUI.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_SPACE then
    btnPlayClick(nil);
end;

//==============================================================================
procedure TPlayerGUI.InitializeVariables;
var
  nDriverIdx : Integer;
begin
  m_CasEngine   := TCasEngine.Create(Self, Handle);
  m_CasDecoder  := TCasDecoder.Create;

  m_lstTracks   := TList<TAcrylicGhostPanel>.Create;

  tbVolume.Position   := 30;
  m_nLoadedTrackCount := 0;

  m_bBlockBufferPositionUpdate := False;

  SetLength(m_DriverList, 0);
  ListAsioDrivers(m_DriverList);
  for nDriverIdx := Low(m_DriverList) to High(m_DriverList) do
    cbDriver.Items.Add(String(m_DriverList[nDriverIdx].name));

  cbDriver.ItemIndex := High(m_DriverList);
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
procedure TPlayerGUI.ChangeEnabledObjects;
begin
  btnDriverControlPanel.Enabled := (m_CasEngine.Ready);
  btnOpenFile.Enabled           := (m_CasEngine.Ready);

  btnPlay.Enabled               := (m_CasEngine.Ready)       and
                                   (m_CasEngine.BuffersOn)   and
                                   (m_nLoadedTrackCount > 0);

  btnStop.Enabled               := (m_nLoadedTrackCount > 0);
  btnPrev.Enabled               := (m_nLoadedTrackCount > 0);
  btnNext.Enabled               := (m_nLoadedTrackCount > 0);

  RefreshAcrylicControls(Self);
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
  CasTrack    : TCasTrack;
begin
  if odOpenFile.Execute then
  begin
    try
      dSampleRate := m_CasEngine.SampleRate;

      for strFileName in odOpenFile.Files do
      begin
        CasTrack       := m_CasDecoder.DecodeFile(strFileName, dSampleRate);
        CasTrack.Level := 0.7;
        CasTrack.ID    := m_CasEngine.GenerateID;
        m_CasEngine.AddTrack(CasTrack, 0);
        m_CasEngine.AddTrackToPlaylist(CasTrack.ID, m_CasEngine.Length);

        AddTrackInfo(CasTrack);
      end;

      UpdateFormSize;
    finally
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
var
  CasTrack  : TCasTrack;
  dProgress : Double;
  nPanelIdx : Integer;
begin
  m_bBlockBufferPositionUpdate := True;
  tbProgress.Position          := Trunc(m_CasEngine.Progress*tbProgress.Max);
  m_bBlockBufferPositionUpdate := False;
  CasTrack                     := nil;

  lblTime.Text := m_CasEngine.GetTime + '/' + m_CasEngine.GetDuration;

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
procedure TPlayerGUI.UpdateFormSize;
//var
//  nHeight : Integer;
begin
//  nHeight := 150 + m_nLoadedTrackCount * 60 + 10 * BoolToInt(m_nLoadedTrackCount > 0);
//
//  if Height <> nHeight then
//    Height := nHeight;
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

  UpdateFormSize;
end;

//==============================================================================
procedure TPlayerGUI.SwitchTracks(a_nTrack1, a_nTrack2 : Integer);
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
  pnlTrack.Width       := Self.Width - 2 * c_nPanelOffset;
  pnlTrack.Height      := c_nPanelHeight;
  pnlTrack.Left        := c_nPanelOffset;
  pnlTrack.Top         := m_nLoadedTrackCount * (c_nPanelGap + c_nPanelHeight) + c_nFirstPanelTop;

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
    m_CasEngine.Playlist.RemoveTrack(CasTrack.ID);
    m_CasEngine.MainMixer.RemoveTrack(CasTrack.ID);
    m_CasEngine.Position := m_CasEngine.Position - CasTrack.Size;

    CasTrack.Destroy;
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
    UpdateFormSize;
  end;
end;

//==============================================================================
procedure TPlayerGUI.btnUpClick(Sender : TObject);
var
  nTrack : Integer;
begin
  nTrack := m_lstTracks.IndexOf((Sender as TAcrylicButton).Parent as TAcrylicGhostPanel);

  SwitchTracks(nTrack, nTrack - 1);
end;

//==============================================================================
procedure TPlayerGUI.btnDownClick(Sender : TObject);
var
  nTrack : Integer;
begin
  nTrack := m_lstTracks.IndexOf((Sender as TAcrylicButton).Parent as TAcrylicGhostPanel);

  SwitchTracks(nTrack, nTrack + 1);
end;

//==============================================================================
procedure TPlayerGUI.trackClick(Sender : TObject);
var
  CasTrack : TCasTrack;
begin
  if m_CasEngine.Database.GetTrackByID(StrToInt(String((Sender as TAcrylicTrack).Parent.Name).SubString(3)), CasTrack) then
    m_CasEngine.Position := CasTrack.Position;

  UpdateProgressBar;
end;

//==============================================================================
procedure TPlayerGUI.trackWheelUp(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
var
  ptMouse : TPoint;
  nTrack  : Integer;
begin
  nTrack := m_lstTracks.IndexOf((Sender as TAcrylicTrack).Parent as TAcrylicGhostPanel);

  SwitchTracks(nTrack, nTrack - 1);

  if nTrack > 0 then
  begin
    ptMouse := Mouse.CursorPos;
    SetCursorPos(ptMouse.X, ptMouse.Y - (c_nPanelGap + c_nPanelHeight));
  end;
end;

//==============================================================================
procedure TPlayerGUI.trackWheelDown(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
var
  ptMouse : TPoint;
  nTrack  : Integer;
begin
  nTrack := m_lstTracks.IndexOf((Sender as TAcrylicTrack).Parent as TAcrylicGhostPanel);

  SwitchTracks(nTrack, nTrack + 1);

  if nTrack < m_lstTracks.Count - 1 then
  begin
    ptMouse := Mouse.CursorPos;
    SetCursorPos(ptMouse.X, ptMouse.Y + (c_nPanelGap + c_nPanelHeight));
  end;
end;

end.
