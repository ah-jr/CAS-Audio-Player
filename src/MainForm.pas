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
  System.SysUtils,
  System.Variants,
  System.Classes,
  System.ImageList,
  System.UITypes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ComCtrls,
  Vcl.ImgList,
  AsioList,
  OpenAsio,
  Asio,
  Math,
  ShellApi,
  IOUtils;

const
  PM_ASIO             = WM_User + 1652;
  PM_UpdateSamplePos  = PM_ASIO + 1;

  AM_ResetRequest         = 0;
  AM_BufferSwitch         = 1;
  AM_BufferSwitchTimeInfo = 2;
  AM_LatencyChanged       = 3;

  c_nBitDepth       = 24;
  c_nChannelCount   = 2;
  c_nByteSize       = 8;
  c_nBytesInChannel = 3;
  c_nBytesInSample  = 6;


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
    m_nRightChannelData          : Array of Integer;
    m_nLeftChannelData           : Array of Integer;
    m_nLeftChannelBufferIndex    : Integer;
    m_nRightChannelBufferIndex   : Integer;
    m_nTrackSize                 : Integer;
    m_nCurrentBufferSize         : Integer;
    m_nAudioLevel                : Double;
    m_nTrackProgress             : Double;
    m_bBlockBufferPositionUpdate : Boolean;
    m_bFileLoaded                : Boolean;
    m_bBuffersCreated            : Boolean;
    m_bIsStarted                 : Boolean;

    m_AsioDriver                 : IOpenAsio;
    m_DriverList                 : TAsioDriverList;
    m_Callbacks                  : TASIOCallbacks;
    m_BufferInfo                 : PAsioBufferInfo;
    m_BufferTime                 : TAsioTime;
    m_ChannelInfos               : Array[0..1] of TASIOChannelInfo;

    procedure InitializeVariables;
    procedure ChangeEnabledObjects;
    procedure CloseDriver;
    procedure CreateBuffers;
    procedure DestroyBuffers;
    procedure UpdateBufferPosition;
    procedure UpdateProgressBar;

    procedure BufferSwitch         (a_nIndex : Integer);
    procedure BufferSwitchTimeInfo (a_nIndex : Integer; const Params : TAsioTime);
    procedure ExecuteAndWait       (a_strCommand : string);
    procedure PopulateBuffers      (a_aobInputPCMData : TBytes);
    procedure DecodeFile           (a_strFileName : String);

  public
    procedure PMAsio(var Message: TMessage); message PM_ASIO;

    property BufferTime : TAsioTime read m_BufferTime write m_BufferTime;
  end;

var
  PlayerGUI: TPlayerGUI;

implementation

{$R *.dfm}

////////////////////////////////////////////////////////////////////////////////
//
//   AsioBufferSwitch
//
////////////////////////////////////////////////////////////////////////////////
procedure AsioBufferSwitch(DoubleBufferIndex: LongInt; DirectProcess: TASIOBool); cdecl;
begin
  case DirectProcess of
    ASIOFalse :  PostMessage(PlayerGUI.Handle, PM_ASIO, AM_BufferSwitch, DoubleBufferIndex);
    ASIOTrue  :  PlayerGUI.BufferSwitch(DoubleBufferIndex);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
//
//   AsioSampleRateDidChange
//
////////////////////////////////////////////////////////////////////////////////
procedure AsioSampleRateDidChange(sRate: TASIOSampleRate); cdecl;
begin
  MessageDlg('The sample rate has been changed to ' + FloatToStr(sRate), mtInformation, [mbOK], 0);
end;

////////////////////////////////////////////////////////////////////////////////
//
//   AsioMessage
//
////////////////////////////////////////////////////////////////////////////////
function AsioMessage(Selector, Value: LongInt; message: Pointer; Ppt: PDouble): LongInt; cdecl;
begin
  Result := 0;

  case Selector of
    kAsioSelectorSupported :
      begin
        case value of
          kAsioEngineVersion        :  Result := 1;
          kAsioResetRequest         :  Result := 1;
          kAsioBufferSizeChange     :  Result := 0;
          kAsioResyncRequest        :  Result := 1;
          kAsioLatenciesChanged     :  Result := 1;
          kAsioSupportsTimeInfo     :  Result := 1;
          kAsioSupportsTimeCode     :  Result := 1;
          kAsioSupportsInputMonitor :  Result := 0;
        end;
      end;
    kAsioEngineVersion :  Result := 2;
    kAsioResetRequest  :
      begin
        PostMessage(PlayerGUI.Handle, PM_Asio, AM_ResetRequest, 0);
        Result := 1;
      end;
    kAsioBufferSizeChange :
      begin
        PostMessage(PlayerGUI.Handle, PM_Asio, AM_ResetRequest, 0);
        Result := 1;
      end;
    kAsioResyncRequest    : ;
    kAsioLatenciesChanged :
      begin
        PostMessage(PlayerGUI.Handle, PM_Asio, AM_LatencyChanged, 0);
        Result := 1;
      end;
    kAsioSupportsTimeInfo     : Result := 1;
    kAsioSupportsTimeCode     : Result := 0;
    kAsioSupportsInputMonitor : ;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
//
//   AsioBufferSwitchTimeInfo
//
////////////////////////////////////////////////////////////////////////////////
function AsioBufferSwitchTimeInfo(var Params: TASIOTime; DoubleBufferIndex: LongInt; DirectProcess: TASIOBool): PASIOTime; cdecl;
begin
  case directProcess of
    ASIOFalse :
      begin
        PlayerGUI.BufferTime := Params;
        PostMessage(PlayerGUI.Handle, PM_ASIO, AM_BufferSwitchTimeInfo, DoubleBufferIndex);
      end;
    ASIOTrue  : PlayerGUI.BufferSwitchTimeInfo(DoubleBufferIndex, Params);
  end;

  Result := nil;
end;

////////////////////////////////////////////////////////////////////////////////
//
//   PMAsio : Receives and process messages from ASIO
//
////////////////////////////////////////////////////////////////////////////////
procedure TPlayerGUI.PMAsio(var Message: TMessage);
var
   inp, outp: integer;
begin
  case Message.WParam of
    AM_ResetRequest         :  cbDriverChange(cbDriver);
    AM_BufferSwitch         :  BufferSwitch(Message.LParam);
    AM_BufferSwitchTimeInfo :  BufferSwitchTimeInfo(Message.LParam, m_BufferTime);
    AM_LatencyChanged       :
      if (m_AsioDriver <> nil) then
      begin
        m_AsioDriver.GetLatencies(inp, outp);
      end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
//
//   BufferSwitch
//
////////////////////////////////////////////////////////////////////////////////
procedure TPlayerGUI.BufferSwitch(a_nIndex : Integer);
begin
  FillChar(m_BufferTime, SizeOf(TAsioTime), 0);

  if m_AsioDriver.GetSamplePosition(m_BufferTime.TimeInfo.SamplePosition, m_BufferTime.TimeInfo.SystemTime) = ASE_OK then
    m_BufferTime.TimeInfo.Flags := kSystemTimeValid or kSamplePositionValid;

  BufferSwitchTimeInfo(a_nIndex, m_BufferTime)
end;

////////////////////////////////////////////////////////////////////////////////
//
//   BufferSwitchTimeInfo
//
////////////////////////////////////////////////////////////////////////////////
procedure TPlayerGUI.BufferSwitchTimeInfo(a_nIndex : Integer; const Params : TAsioTime);
var
   nChannelIdx : Integer;
   nBufferIdx  : Integer;
   Info        : PAsioBufferInfo;
   OutputInt32 : PInteger;
begin
  if (m_nLeftChannelBufferIndex  < Length(m_nLeftChannelData)  - m_nCurrentBufferSize) and
     (m_nRightChannelBufferIndex < Length(m_nRightChannelData) - m_nCurrentBufferSize) then
  begin
    Info := m_BufferInfo;

    for nChannelIdx := 0 to c_nChannelCount - 1 do
    begin
      case m_ChannelInfos[nChannelIdx].vType of
        ASIOSTInt16MSB   : ;
        ASIOSTInt24MSB   : ;
        ASIOSTInt32MSB   : ;
        ASIOSTFloat32MSB : ;
        ASIOSTFloat64MSB : ;

        ASIOSTInt32MSB16 : ;
        ASIOSTInt32MSB18 : ;
        ASIOSTInt32MSB20 : ;
        ASIOSTInt32MSB24 : ;

        ASIOSTInt16LSB   : ;
        ASIOSTInt24LSB   : ;
        ASIOSTInt32LSB   :
          begin
            OutputInt32 := Info^.Buffers[a_nIndex];
            for nBufferIdx := 0 to m_nCurrentBufferSize-1 do
            begin
              if nChannelIdx = 0 then
                begin
                  OutputInt32^ := Trunc(Power(2, 32 - c_nBitDepth) * m_nLeftChannelData[m_nLeftChannelBufferIndex] * m_nAudioLevel);
                  Inc(m_nLeftChannelBufferIndex);
                end
              else
                begin
                  OutputInt32^ := Trunc(Power(2, 32 - c_nBitDepth) * m_nRightChannelData[m_nRightChannelBufferIndex] * m_nAudioLevel);
                  Inc(m_nRightChannelBufferIndex);
                end;

              inc(OutputInt32);
            end;
          end;
        ASIOSTFloat32LSB : ;
        ASIOSTFloat64LSB : ;
        ASIOSTInt32LSB16 : ;
        ASIOSTInt32LSB18 : ;
        ASIOSTInt32LSB20 : ;
        ASIOSTInt32LSB24 : ;
      end;

      Inc(Info);
    end;

    PostMessage(Handle, PM_UpdateSamplePos, Params.TimeInfo.SamplePosition.Hi, Params.TimeInfo.SamplePosition.Lo);
    m_AsioDriver.OutputReady;
  end
  else
  begin
    m_nLeftChannelBufferIndex  := 0;
    m_nRightChannelBufferIndex := 0;
  end;

  UpdateProgressBar;
  ChangeEnabledObjects
end;

////////////////////////////////////////////////////////////////////////////////
//
//   FormCreate
//
////////////////////////////////////////////////////////////////////////////////
procedure TPlayerGUI.FormCreate(Sender: TObject);
begin
  Caption     := 'CAS Audio Player';
  BorderStyle := bsDialog;

  InitializeVariables;
  ChangeEnabledObjects;
end;

////////////////////////////////////////////////////////////////////////////////
//
//   FormDestroy
//
////////////////////////////////////////////////////////////////////////////////
procedure TPlayerGUI.FormDestroy(Sender: TObject);
begin
  DestroyBuffers;
  CloseDriver;
  SetLength(m_DriverList, 0);
end;

////////////////////////////////////////////////////////////////////////////////
//
//   cbDriverChange
//
////////////////////////////////////////////////////////////////////////////////
procedure TPlayerGUI.cbDriverChange(Sender: TObject);
begin
  if m_AsioDriver <> nil then
    CloseDriver;

  if cbDriver.ItemIndex >= 0 then
  begin
    if OpenAsioCreate(m_DriverList[cbDriver.ItemIndex].Id, m_AsioDriver) then
      if (m_AsioDriver <> nil) then
        if not Succeeded(m_AsioDriver.Init(Handle))
          then m_AsioDriver := nil
          else CreateBuffers;
  end;

  ChangeEnabledObjects;
end;

////////////////////////////////////////////////////////////////////////////////
//
//   btnOpenFileClick
//
////////////////////////////////////////////////////////////////////////////////
procedure TPlayerGUI.btnOpenFileClick(Sender: TObject);
var
  nSampleIdx : Integer;
begin
  if (m_AsioDriver <> nil) then
  begin
    for nSampleIdx := 0 to Length(m_nLeftChannelData) - 1 do
    begin
      m_nLeftChannelData[nSampleIdx]  := 0;
      m_nRightChannelData[nSampleIdx] := 0;
    end;

    m_nLeftChannelBufferIndex  := 0;
    m_nRightChannelBufferIndex := 0;

    if odOpenFile.Execute then
    begin
      m_bFileLoaded := True;

      try
        DecodeFile(odOpenFile.FileName);
      except
        m_bFileLoaded := False;
      end;
    end;

    ChangeEnabledObjects;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
//
//   btnDriverControlPanelClick
//
////////////////////////////////////////////////////////////////////////////////
procedure TPlayerGUI.btnDriverControlPanelClick(Sender: TObject);
begin
  if (m_AsioDriver <> nil) then
    m_AsioDriver.ControlPanel;
end;

////////////////////////////////////////////////////////////////////////////////
//
//   btnPlayClick
//
////////////////////////////////////////////////////////////////////////////////
procedure TPlayerGUI.btnPlayClick(Sender: TObject);
begin
  if m_AsioDriver <> nil then
  begin
    m_bIsStarted := (m_AsioDriver.Start = ASE_OK);
    ChangeEnabledObjects;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
//
//   btnPauseClick
//
////////////////////////////////////////////////////////////////////////////////
procedure TPlayerGUI.btnPauseClick(Sender: TObject);
begin
  if m_AsioDriver <> nil then
  begin
    if m_bIsStarted then
    begin
      m_AsioDriver.Stop;
      m_bIsStarted := False;
    end;

    ChangeEnabledObjects;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
//
//   btnStopClick
//
////////////////////////////////////////////////////////////////////////////////
procedure TPlayerGUI.btnStopClick(Sender: TObject);
begin
  if m_AsioDriver <> nil then
  begin
    if m_bIsStarted then
    begin
      m_AsioDriver.Stop;
      m_bIsStarted := False;
    end;

    m_nLeftChannelBufferIndex  := 0;
    m_nRightChannelBufferIndex := 0;
    UpdateProgressBar;
    ChangeEnabledObjects;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
//
//   tbVolumeChange
//
////////////////////////////////////////////////////////////////////////////////
procedure TPlayerGUI.tbVolumeChange(Sender: TObject);
begin
  m_nAudioLevel := (tbVolume.Max - tbVolume.Position) / tbVolume.Max;
end;

////////////////////////////////////////////////////////////////////////////////
//
//   tbProgressChange
//
////////////////////////////////////////////////////////////////////////////////
procedure TPlayerGUI.tbProgressChange(Sender: TObject);
begin
  UpdateBufferPosition;
end;

////////////////////////////////////////////////////////////////////////////////
//
//   DecodeFile
//
////////////////////////////////////////////////////////////////////////////////
procedure TPlayerGUI.DecodeFile(a_strFileName : String);
var
  strCommand  : String;
  dSampleRate : Double;
const
  c_strFfmpegBin      = 'ffmpeg/ffmpeg.exe';
  c_strOutPutFileName = 'output.raw';
begin
  if (m_AsioDriver <> nil) then
  begin
    m_AsioDriver.GetSampleRate(dSampleRate);

    strCommand := '-i "'                              +
                  odOpenFile.FileName                 +
                  '" -f s24le -acodec pcm_s24le -ar ' +
                  dSampleRate.ToString                +
                  ' -ac 2 '                           +
                  c_strOutPutFileName;

    DeleteFile(c_strOutPutFileName);
    ExecuteAndWait(c_strFfmpegBin + ' ' + strCommand);
    PopulateBuffers(TFile.ReadAllBytes(c_strOutPutFileName));
  end;
end;

////////////////////////////////////////////////////////////////////////////////
//
//   PopulateBuffers
//
////////////////////////////////////////////////////////////////////////////////
procedure TPlayerGUI.PopulateBuffers(a_aobInputPCMData : TBytes);
var
  nSampleIdx         : Integer;
  nByteIdx           : Integer;
  nRightChannelBytes : Integer;
  nLeftChannelBytes  : Integer;
begin
  m_nLeftChannelBufferIndex  := 0;
  m_nRightChannelBufferIndex := 0;

  m_nTrackSize := Length(a_aobInputPCMData) div c_nBytesInSample;

  SetLength(m_nLeftChannelData,  m_nTrackSize);
  SetLength(m_nRightChannelData, m_nTrackSize);


  for nSampleIdx := 0 to Length(m_nRightChannelData) - 1 do
  begin
    for nByteIdx := 0 to c_nBytesInChannel - 1  do
    begin
      nLeftChannelBytes  := a_aobInputPCMData[c_nBytesInSample * nSampleIdx + nByteIdx];
      nRightChannelBytes := a_aobInputPCMData[c_nBytesInSample * nSampleIdx + nByteIdx + c_nBytesInChannel];

      m_nLeftChannelData[nSampleIdx]  := m_nLeftChannelData[nSampleIdx]  + nLeftChannelBytes  * Trunc(Power(2, c_nByteSize * nByteIdx));
      m_nRightChannelData[nSampleIdx] := m_nRightChannelData[nSampleIdx] + nRightChannelBytes * Trunc(Power(2, c_nByteSize * nByteIdx));
    end;

    // Two's complement:
    if (m_nLeftChannelData[nSampleIdx]  >= Power(2, c_nBitDepth - 1)) then
       m_nLeftChannelData[nSampleIdx]  := m_nLeftChannelData[nSampleIdx]  - Trunc(Power(2, c_nBitDepth));

    if (m_nRightChannelData[nSampleIdx] >= Power(2, c_nBitDepth - 1)) then
       m_nRightChannelData[nSampleIdx] := m_nRightChannelData[nSampleIdx] - Trunc(Power(2, c_nBitDepth));
  end;
end;

////////////////////////////////////////////////////////////////////////////////
//
//   ExecuteAndWait : Executes a shell command and waits for it to finish
//
////////////////////////////////////////////////////////////////////////////////
procedure TPlayerGUI.ExecuteAndWait(a_strCommand : string);
var
  tmpStartupInfo        : TStartupInfo;
  tmpProcessInformation : TProcessInformation;
  tmpProgram            : String;
begin
  tmpProgram := Trim(a_strCommand);
  FillChar(tmpStartupInfo, SizeOf(tmpStartupInfo), 0);
  with tmpStartupInfo do
  begin
    cb          := SizeOf(TStartupInfo);
    wShowWindow := SW_HIDE;
  end;

  if CreateProcess(nil, PChar(tmpProgram), nil, nil, True, CREATE_NO_WINDOW,
    nil, nil, tmpStartupInfo, tmpProcessInformation) then
  begin
    while WaitForSingleObject(tmpProcessInformation.hProcess, 10) > 0 do
    begin
      Application.ProcessMessages;
    end;
    CloseHandle(tmpProcessInformation.hProcess);
    CloseHandle(tmpProcessInformation.hThread);
  end
  else
  begin
    RaiseLastOSError;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
//
//   InitializeVariables
//
////////////////////////////////////////////////////////////////////////////////
procedure TPlayerGUI.InitializeVariables;
var
  nDriverIdx : Integer;
begin
  m_nAudioLevel                := 0.7;
  tbVolume.Position            := 30;

  m_Callbacks.BufferSwitch         := AsioBufferSwitch;
  m_Callbacks.AsioMessage          := AsioMessage;
  m_Callbacks.BufferSwitchTimeInfo := AsioBufferSwitchTimeInfo;

  m_AsioDriver := nil;
  m_BufferInfo := nil;

  m_bFileLoaded                := False;
  m_bBuffersCreated            := False;
  m_bIsStarted                 := False;
  m_bBlockBufferPositionUpdate := False;

  SetLength(m_DriverList, 0);
  ListAsioDrivers(m_DriverList);
  for nDriverIdx := Low(m_DriverList) to High(m_DriverList) do
    cbDriver.Items.Add(String(m_DriverList[nDriverIdx].name));
end;

////////////////////////////////////////////////////////////////////////////////
//
//  ChangeEnabledObjects
//
////////////////////////////////////////////////////////////////////////////////
procedure TPlayerGUI.ChangeEnabledObjects;
begin
  btnDriverControlPanel.Enabled := (m_AsioDriver <> nil);
  btnOpenFile.Enabled           := (m_AsioDriver <> nil);
  btnPlay.Enabled               := (m_AsioDriver <> nil) and
                                   (m_bBuffersCreated)   and
                                   (not m_bIsStarted)    and
                                   (m_bFileLoaded);
  btnPause.Enabled              := m_bIsStarted;
  btnStop.Enabled               := m_bIsStarted;
end;

////////////////////////////////////////////////////////////////////////////////
//
//   CloseDriver
//
////////////////////////////////////////////////////////////////////////////////
procedure TPlayerGUI.CloseDriver;
begin
  if m_AsioDriver <> nil then
  begin
    if m_bIsStarted then
      btnStop.Click;

    if m_bBuffersCreated then
      DestroyBuffers;

    m_AsioDriver := nil;
  end;

  ChangeEnabledObjects;
end;

////////////////////////////////////////////////////////////////////////////////
//
//   UpdateBufferPosition
//
////////////////////////////////////////////////////////////////////////////////
procedure TPlayerGUI.UpdateBufferPosition;
begin
  if not m_bBlockBufferPositionUpdate then
    begin
      m_nTrackProgress := tbProgress.Position/tbProgress.Max;

      m_nLeftChannelBufferIndex  := Trunc(m_nTrackProgress * m_nTrackSize);
      m_nRightChannelBufferIndex := Trunc(m_nTrackProgress * m_nTrackSize);
    end;
end;

////////////////////////////////////////////////////////////////////////////////
//
//   CreateBuffers
//
////////////////////////////////////////////////////////////////////////////////
procedure TPlayerGUI.CreateBuffers;
var
   nMin          : Integer;
   nMax          : Integer;
   nPref         : Integer;
   nGran         : Integer;
   nChannelIdx   : Integer;
   Currentbuffer : PAsioBufferInfo;
begin
  if (m_AsioDriver <> nil) then
  begin
    if m_bBuffersCreated then
      DestroyBuffers;

    m_AsioDriver.GetBufferSize(nMin, nMax, nPref, nGran);
    GetMem(m_BufferInfo, SizeOf(TAsioBufferInfo)*c_nChannelCount);
    Currentbuffer := m_BufferInfo;

    for nChannelIdx := 0 to c_nChannelCount - 1 do
    begin
      Currentbuffer^.IsInput     := ASIOFalse;
      Currentbuffer^.ChannelNum  := nChannelIdx;
      Currentbuffer^.Buffers[0] := nil;
      Currentbuffer^.Buffers[1] := nil;
      Inc(Currentbuffer);
    end;

    m_bBuffersCreated := (m_AsioDriver.CreateBuffers(m_BufferInfo, c_nChannelCount, nPref, m_Callbacks) = ASE_OK);
    if m_bBuffersCreated then
      m_nCurrentBufferSize := nPref
    else
      m_nCurrentBufferSize := 0;

    ChangeEnabledObjects;

    if m_AsioDriver <> nil then
    begin
      if m_bBuffersCreated then
      begin
        for nChannelIdx := 0 to c_nChannelCount - 1 do
        begin
          m_ChannelInfos[nChannelIdx].Channel := nChannelIdx;
          m_ChannelInfos[nChannelIdx].IsInput := ASIOFalse;
          m_AsioDriver.GetChannelInfo(m_ChannelInfos[nChannelIdx]);
        end;
      end;
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
//
//   DestroyBuffers
//
////////////////////////////////////////////////////////////////////////////////
procedure TPlayerGUI.DestroyBuffers;
begin
  if (m_AsioDriver <> nil) and m_bBuffersCreated then
  begin
    FreeMem(m_BufferInfo);
    m_AsioDriver.DisposeBuffers;

    m_BufferInfo         := nil;
    m_bBuffersCreated    := False;
    m_nCurrentBufferSize := 0;

    ChangeEnabledObjects;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
//
//   UpdateProgressBar
//
////////////////////////////////////////////////////////////////////////////////
procedure TPlayerGUI.UpdateProgressBar;
begin
  m_nTrackProgress := m_nLeftChannelBufferIndex / m_nTrackSize;

  m_bBlockBufferPositionUpdate := True;
  tbProgress.Position          := Trunc(m_nTrackProgress*tbProgress.Max);
  m_bBlockBufferPositionUpdate := False;
end;

end.
