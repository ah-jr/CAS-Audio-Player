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
  CasTrackU;

type
  TPlayerGUI = class(TForm)
    btnOpenFile: TButton;
    btnPlay: TButton;
    btnStop: TButton;
    btnPause: TButton;
    odOpenFile: TOpenDialog;
    tbVolume: TTrackBar;
    tbProgress: TTrackBar;
    cbDriver: TComboBox;
    btnDriverControlPanel: TButton;
    ilMediaButtons: TImageList;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cbDriverChange(Sender: TObject);
    procedure btnDriverControlPanelClick(Sender: TObject);
    procedure btnPlayClick(Sender: TObject);
    procedure btnPauseClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure btnOpenFileClick(Sender: TObject);
    procedure tbVolumeChange(Sender: TObject);
    procedure tbProgressChange(Sender: TObject);

  private
    m_bBlockBufferPositionUpdate : Boolean;
    m_bFileLoaded                : Boolean;

    m_CasEngine                  : TCasEngine;
    m_CasDecoder                 : TCasDecoder;
    m_CasTrack                   : TCasTrack;

    m_DriverList                 : TAsioDriverList;

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
  Caption     := 'CAS Audio Player';
  BorderStyle := bsDialog;

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
  m_CasEngine  := TCasEngine.Create(Self);
  m_CasDecoder := TCasDecoder.Create;
  m_CasTrack   := nil;

  tbVolume.Position            := 30;

  m_bFileLoaded                := False;
  m_bBlockBufferPositionUpdate := False;

  SetLength(m_DriverList, 0);
  ListAsioDrivers(m_DriverList);
  for nDriverIdx := Low(m_DriverList) to High(m_DriverList) do
    cbDriver.Items.Add(String(m_DriverList[nDriverIdx].name));
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
procedure TPlayerGUI.cbDriverChange(Sender: TObject);
begin
  m_CasEngine.ChangeDriver(cbDriver.ItemIndex);

  ChangeEnabledObjects;
end;

//==============================================================================
procedure TPlayerGUI.btnOpenFileClick(Sender: TObject);
var
  dSampleRate : Double;
begin
  if odOpenFile.Execute then
  begin
    m_bFileLoaded := True;

    try
      m_CasEngine.ClearTracks;
      dSampleRate := m_CasEngine.SampleRate;

      m_CasTrack       := m_CasDecoder.DecodeFile(odOpenFile.FileName, dSampleRate);
      m_CasTrack.Level := 0.7;
      m_CasEngine.AddTrack(m_CasTrack, 0);
      m_CasEngine.AddTrackToPlaylist(m_CasTrack.ID, 0);
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
end;

//==============================================================================
procedure TPlayerGUI.btnPauseClick(Sender: TObject);
begin
  m_CasEngine.Pause;
end;

//==============================================================================
procedure TPlayerGUI.btnStopClick(Sender: TObject);
begin
  m_CasEngine.Stop;
end;

//==============================================================================
procedure TPlayerGUI.tbVolumeChange(Sender: TObject);
begin
  m_CasEngine.Level := (tbVolume.Max - tbVolume.Position) / tbVolume.Max;
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

end.
