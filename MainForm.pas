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
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ComCtrls,
  AsioList,
  OpenAsio,
  Asio,
  Math,
  ShellApi,
  IOUtils;

const
  PM_ASIO = WM_User + 1652;

  AM_ResetRequest         = 0;
  AM_BufferSwitch         = 1;
  AM_BufferSwitchTimeInfo = 2;

  AM_LatencyChanged       = 3;

  PM_UpdateSamplePos      = PM_ASIO + 1;


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
    lblVolume: TLabel;
    lblProgress: TLabel;
    cbDriver: TComboBox;
    temp1: TButton;
    temp2: TButton;
    btnDriverControlPanel: TButton;

    procedure FormCreate(Sender: TObject);
    procedure InterpretFile(a_aobInputPCMData : TBytes);
    procedure FormDestroy(Sender: TObject);
    procedure cbDriverChange(Sender: TObject);
    procedure ControlPanelBtnClick(Sender: TObject);
    procedure StartBtnClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure temp1Click(Sender: TObject);
    procedure temp2Click(Sender: TObject);
    procedure btnOpenFileClick(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure tbProgressChange(Sender: TObject);
  private

    m_nRightChannelData        : Array of Integer;
    m_nLeftChannelData         : Array of Integer;
    m_nLeftChannelBufferIndex  : Integer;
    m_nRightChannelBufferIndex : Integer;


    m_nTrackSize               : Integer;
    m_nAudioLevel              : Double;
    m_nTrackProgress           : Double;

    m_bBlockBufferPositionUpdate : Boolean;

    procedure ChangeEnabled;
    procedure CloseDriver;
    procedure UpdateBufferPosition;
    procedure BufferSwitch(index: integer);
    procedure BufferSwitchTimeInfo(index: integer; const params: TAsioTime);
    procedure ExecuteAndWait(const aCommando: string);

  public
    driverlist        : TAsioDriverList;
    Driver            : IOpenAsio;
    BuffersCreated    : boolean;
    IsStarted         : boolean;
    callbacks         : TASIOCallbacks;
    bufferinfo        : PAsioBufferInfo;
    BufferTime        : TAsioTime;
    ChannelInfos      : array[0..1] of TASIOChannelInfo;
    SampleRate        : TASIOSampleRate;
    CurrentBufferSize : integer;
    procedure PMAsio(var Message: TMessage); message PM_ASIO;
  end;

var
  PlayerGUI: TPlayerGUI;

implementation

{$R *.dfm}

function ChannelTypeToString(vType: TAsioSampleType): AnsiString;
begin
  Result := '';
  case vType of
    ASIOSTInt16MSB   :  Result := 'Int16MSB';
    ASIOSTInt24MSB   :  Result := 'Int24MSB';
    ASIOSTInt32MSB   :  Result := 'Int32MSB';
    ASIOSTFloat32MSB :  Result := 'Float32MSB';
    ASIOSTFloat64MSB :  Result := 'Float64MSB';

    // these are used for 32 bit data buffer, with different alignment of the data inside
    // 32 bit PCI bus systems can be more easily used with these
    ASIOSTInt32MSB16 :  Result := 'Int32MSB16';
    ASIOSTInt32MSB18 :  Result := 'Int32MSB18';
    ASIOSTInt32MSB20 :  Result := 'Int32MSB20';
    ASIOSTInt32MSB24 :  Result := 'Int32MSB24';

    ASIOSTInt16LSB   :  Result := 'Int16LSB';
    ASIOSTInt24LSB   :  Result := 'Int24LSB';
    ASIOSTInt32LSB   :  Result := 'Int32LSB';
    ASIOSTFloat32LSB :  Result := 'Float32LSB';
    ASIOSTFloat64LSB :  Result := 'Float64LSB';

    // these are used for 32 bit data buffer, with different alignment of the data inside
    // 32 bit PCI bus systems can more easily used with these
    ASIOSTInt32LSB16 :  Result := 'Int32LSB16';
    ASIOSTInt32LSB18 :  Result := 'Int32LSB18';
    ASIOSTInt32LSB20 :  Result := 'Int32LSB20';
    ASIOSTInt32LSB24 :  Result := 'Int32LSB24';
  end;
end;

procedure AsioBufferSwitch(doubleBufferIndex: longint; directProcess: TASIOBool); cdecl;
begin
  case directProcess of
    ASIOFalse :  PostMessage(PlayerGUI.Handle, PM_ASIO, AM_BufferSwitch, doubleBufferIndex);
    ASIOTrue  :  PlayerGUI.BufferSwitch(doubleBufferIndex);
  end;
end;

procedure AsioSampleRateDidChange(sRate: TASIOSampleRate); cdecl;
begin
  MessageDlg('The sample rate has been changed to ' + FloatToStr(sRate), mtInformation, [mbOK], 0);
end;

function AsioMessage(selector, value: longint; message: pointer; opt: pdouble): longint; cdecl;
begin
  Result := 0;

  case selector of
    kAsioSelectorSupported    :   // return 1 if a selector is supported
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
    kAsioEngineVersion        :  Result := 2;   // ASIO 2 is supported
    kAsioResetRequest         :
      begin
        PostMessage(PlayerGUI.Handle, PM_Asio, AM_ResetRequest, 0);
        Result := 1;
      end;
    kAsioBufferSizeChange     :
      begin
        PostMessage(PlayerGUI.Handle, PM_Asio, AM_ResetRequest, 0);
        Result := 1;
      end;
    kAsioResyncRequest        :  ;
    kAsioLatenciesChanged     :
      begin
        PostMessage(PlayerGUI.Handle, PM_Asio, AM_LatencyChanged, 0);
        Result := 1;
      end;
    kAsioSupportsTimeInfo     :  Result := 1;
    kAsioSupportsTimeCode     :  Result := 0;
    kAsioSupportsInputMonitor :  ;
  end;
end;

function AsioBufferSwitchTimeInfo(var params: TASIOTime; doubleBufferIndex: longint; directProcess: TASIOBool): PASIOTime; cdecl;
begin
  case directProcess of
    ASIOFalse :
      begin
        PlayerGUI.BufferTime := params;
        PostMessage(PlayerGUI.Handle, PM_ASIO, AM_BufferSwitchTimeInfo, doubleBufferIndex);
      end;
    ASIOTrue  :  PlayerGUI.BufferSwitchTimeInfo(doubleBufferIndex, params);
  end;

  Result := nil;
end;

procedure TPlayerGUI.InterpretFile(a_aobInputPCMData : TBytes);
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

procedure TPlayerGUI.ExecuteAndWait(const aCommando: string);
var
  tmpStartupInfo: TStartupInfo;
  tmpProcessInformation: TProcessInformation;
  tmpProgram: String;
begin
  tmpProgram := trim(aCommando);
  FillChar(tmpStartupInfo, SizeOf(tmpStartupInfo), 0);
  with tmpStartupInfo do
  begin
    cb := SizeOf(TStartupInfo);
    wShowWindow := SW_HIDE;
  end;

  if CreateProcess(nil, pchar(tmpProgram), nil, nil, true, CREATE_NO_WINDOW,
    nil, nil, tmpStartupInfo, tmpProcessInformation) then
  begin
    // loop every 10 ms
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









procedure TPlayerGUI.FormCreate(Sender: TObject);
var
   nDriverIdx         : Integer;
begin
  //InterpretFile(TFile.ReadAllBytes('output.raw'));
  m_nAudioLevel := 0.7;
  tbVolume.Position := 70;
  btnOpenFile.Enabled := False;
  m_bBlockBufferPositionUpdate := False;

  BorderStyle := bsDialog;

  bufferinfo := nil;

  // init the driver list
  SetLength(driverlist, 0);
  ListAsioDrivers(driverlist);
  for nDriverIdx := Low(driverlist) to High(driverlist) do
    cbDriver.Items.Add(String(driverlist[nDriverIdx].name));

  // set the callbacks record fields
  callbacks.bufferSwitch := AsioBufferSwitch;
  callbacks.sampleRateDidChange := AsioSampleRateDidChange;
  callbacks.asioMessage := AsioMessage;
  callbacks.bufferSwitchTimeInfo := AsioBufferSwitchTimeInfo;

  // set the driver itself to nil for now
  Driver := nil;
  BuffersCreated := FALSE;
  IsStarted := FALSE;

  // and make sure all controls are enabled or disabled
  ChangeEnabled;
end;

procedure TPlayerGUI.FormDestroy(Sender: TObject);
begin
  CloseDriver;
  SetLength(driverlist, 0);
end;

procedure TPlayerGUI.cbDriverChange(Sender: TObject);
begin
  if Driver <> nil then
    CloseDriver;

  if cbDriver.ItemIndex >= 0 then
  begin
    if OpenAsioCreate(driverList[cbDriver.ItemIndex].id, Driver) then
      if (Driver <> nil) then
        if not Succeeded(Driver.Init(Handle)) then
          Driver := nil;  // RELEASE

    btnOpenFile.Enabled := True;
  end
  else
    btnOpenFile.Enabled := False;


  ChangeEnabled;
end;

procedure TPlayerGUI.ChangeEnabled;
var
   buf       : array[0..255] of AnsiChar;
   inp, outp : integer;
   i                    : integer;
const
     boolstrings : array[0..1] of AnsiString = ('no', 'yes');
begin
  btnDriverControlPanel.Enabled := (Driver <> nil);

  temp1.Enabled := (Driver <> nil) and not BuffersCreated;
  temp2.Enabled := BuffersCreated;
  btnPlay.Enabled := (Driver <> nil) and BuffersCreated and not IsStarted;
  btnStop.Enabled := IsStarted;


  if Driver <> nil then
  begin
    Driver.GetDriverName(buf);
    Driver.GetChannels(inp, outp);

    if BuffersCreated then
    begin
      Driver.GetLatencies(inp, outp);
      // now get all the buffer details, sample word length, name, word clock group and activation
      for i := 0 to 1 do
      begin
        ChannelInfos[i].channel := i;
        ChannelInfos[i].isInput := ASIOFalse;   //  output
        Driver.GetChannelInfo(ChannelInfos[i]);
      end;
    end;
  end;
end;

procedure TPlayerGUI.ControlPanelBtnClick(Sender: TObject);
begin
  if (Driver <> nil) then
    Driver.ControlPanel;
end;

procedure TPlayerGUI.CloseDriver;
begin
  if Driver <> nil then
  begin
    if IsStarted then
      btnStop.Click;
    if BuffersCreated then
      temp2.Click;
    Driver := nil;  // RELEASE;
  end;

  ChangeEnabled;
end;

procedure TPlayerGUI.StartBtnClick(Sender: TObject);
begin
  if Driver = nil then
    Exit;

  IsStarted := (Driver.Start = ASE_OK);
  ChangeEnabled;
end;

procedure TPlayerGUI.btnStopClick(Sender: TObject);
begin
  m_nLeftChannelBufferIndex  := 0;
  m_nRightChannelBufferIndex := 0;

  if Driver = nil then
    Exit;

  if IsStarted then
  begin
    Driver.Stop;
    IsStarted := FALSE;
  end;

  ChangeEnabled;
end;

procedure TPlayerGUI.TrackBar1Change(Sender: TObject);
begin
  m_nAudioLevel := tbVolume.Position / tbVolume.Max;
end;

procedure TPlayerGUI.tbProgressChange(Sender: TObject);
begin
  UpdateBufferPosition;
end;

procedure TPlayerGUI.UpdateBufferPosition;
begin
  if not m_bBlockBufferPositionUpdate then
    begin
      m_nTrackProgress := tbProgress.Position/tbProgress.Max;

      m_nLeftChannelBufferIndex  := Trunc(m_nTrackProgress * m_nTrackSize);
      m_nRightChannelBufferIndex := Trunc(m_nTrackProgress * m_nTrackSize);
    end;
end;

procedure TPlayerGUI.temp1Click(Sender: TObject);
var
   min, max, pref, gran : integer;
   currentbuffer        : PAsioBufferInfo;
   i                    : integer;
begin
  if Driver = nil then
    Exit;

  if BuffersCreated then
    temp2.Click;

  Driver.GetBufferSize(min, max, pref, gran);

  // two output channels
  GetMem(bufferinfo, SizeOf(TAsioBufferInfo)*2);
  currentbuffer := bufferinfo;
  for i := 0 to 1 do
  begin
    currentbuffer^.isInput := ASIOFalse;  // create an output buffer
    currentbuffer^.channelNum := i;
    currentbuffer^.buffers[0] := nil;
    currentbuffer^.buffers[1] := nil;
    inc(currentbuffer);
  end;

  // actually create the buffers
  BuffersCreated := (Driver.CreateBuffers(bufferinfo, 2, pref, callbacks) = ASE_OK);
  if BuffersCreated then
    CurrentBufferSize := pref
  else
    CurrentBufferSize := 0;

  ChangeEnabled;
end;

procedure TPlayerGUI.temp2Click(Sender: TObject);
begin
  if (Driver = nil) or not BuffersCreated then
    Exit;

  if IsStarted then
    btnStop.Click;

  FreeMem(bufferinfo);
  bufferinfo := nil;
  Driver.DisposeBuffers;
  BuffersCreated := FALSE;
  CurrentBufferSize := 0;

  ChangeEnabled;
end;

procedure TPlayerGUI.PMAsio(var Message: TMessage);
var
   inp, outp: integer;
begin
  case Message.WParam of
    AM_ResetRequest         :  cbDriverChange(cbDriver);                    // restart the driver
    AM_BufferSwitch         :  BufferSwitch(Message.LParam);                      // process a buffer
    AM_BufferSwitchTimeInfo :  BufferSwitchTimeInfo(Message.LParam, BufferTime);  // process a buffer with time
    AM_LatencyChanged       :
      if (Driver <> nil) then
      begin
        Driver.GetLatencies(inp, outp);
      end;
  end;
end;

procedure TPlayerGUI.BufferSwitch(index: integer);
begin
  FillChar(BufferTime, SizeOf(TAsioTime), 0);

  // get the time stamp of the buffer, not necessary if no
  // synchronization to other media is required
  if Driver.GetSamplePosition(BufferTime.timeInfo.samplePosition, BufferTime.timeInfo.systemTime) = ASE_OK then
    BufferTime.timeInfo.flags := kSystemTimeValid or kSamplePositionValid;

  BufferSwitchTimeInfo(index, BufferTime);
end;

procedure TPlayerGUI.BufferSwitchTimeInfo(index: integer; const params: TAsioTime);
var
   i, ndx        : integer;
   info          : PAsioBufferInfo;
   outputInt16   : PSmallint;
   outputInt32   : PInteger;
   outputFloat32 : PSingle;
begin
  // this is where processing occurs, with the buffers provided by Driver.CreateBuffers
  // beware of the buffer output format, of course
  info := BufferInfo;

  for i := 0 to 1 do
  begin
    case ChannelInfos[i].vType of
      ASIOSTInt16MSB   :  ;
      ASIOSTInt24MSB   :  ;
      ASIOSTInt32MSB   :  ;
      ASIOSTFloat32MSB :  ;
      ASIOSTFloat64MSB :  ;

      ASIOSTInt32MSB16 :  ;
      ASIOSTInt32MSB18 :  ;
      ASIOSTInt32MSB20 :  ;
      ASIOSTInt32MSB24 :  ;

      ASIOSTInt16LSB   :
        begin
          // example:
          outputInt16 := info^.buffers[index];
          for ndx := 0 to CurrentBufferSize-1 do
          begin
            outputInt16^ := 0;   // here we actually fill the output buffer (with zeroes)
            inc(outputInt16);
          end;
        end;
      ASIOSTInt24LSB   :  ;
      ASIOSTInt32LSB   :
        begin
          // example:
          outputInt32 := info^.buffers[index];
          for ndx := 0 to CurrentBufferSize-1 do
          begin
            if i = 0 then
              begin
                outputInt32^ := Trunc((Power(2,32)/Power(2,c_nBitDepth)) * m_nLeftChannelData[m_nLeftChannelBufferIndex] * m_nAudioLevel);
                Inc(m_nLeftChannelBufferIndex);

                m_nTrackProgress := m_nLeftChannelBufferIndex / m_nTrackSize;

                m_bBlockBufferPositionUpdate := True;
                tbProgress.Position := Trunc(m_nTrackProgress*tbProgress.Max);
                m_bBlockBufferPositionUpdate := False;
              end
            else
              begin
                outputInt32^ := Trunc((Power(2,32)/Power(2,c_nBitDepth)) * m_nRightChannelData[m_nRightChannelBufferIndex] * m_nAudioLevel);
                Inc(m_nRightChannelBufferIndex);
              end;

            inc(outputInt32);
          end;
        end;
      ASIOSTFloat32LSB :
        begin
          // example:
          outputFloat32 := info^.buffers[index];
          for ndx := 0 to CurrentBufferSize-1 do
          begin
            outputFloat32^ := 0;   // here we actually fill the output buffer (with zeroes)
            inc(outputFloat32);
          end;
        end;
      ASIOSTFloat64LSB :  ;
      ASIOSTInt32LSB16 :  ;
      ASIOSTInt32LSB18 :  ;
      ASIOSTInt32LSB20 :  ;
      ASIOSTInt32LSB24 :  ;
    end;

    inc(info);  // don't forget to go to the next buffer in this loop
  end;


  // tell the interface that the sample position has changed
  PostMessage(Handle, PM_UpdateSamplePos, params.timeInfo.samplePosition.hi, params.timeInfo.samplePosition.lo);

  Driver.OutputReady;    // some asio drivers require this
end;

procedure TPlayerGUI.btnOpenFileClick(Sender: TObject);
var
  strCommand      : String;
  nSampleIdx      : Integer;
  dSampleRate     : Double;
const
  c_strFfmpegBin = 'ffmpeg';
  c_strOutPutFileName = 'output.raw';
begin
  if (Driver <> nil) then
  begin
    for nSampleIdx := 0 to Length(m_nLeftChannelData) - 1 do
    begin
      m_nLeftChannelData[nSampleIdx]  := 0;
      m_nRightChannelData[nSampleIdx] := 0;
    end;

    Driver.GetSampleRate(dSampleRate);

    m_nLeftChannelBufferIndex  := 0;
    m_nRightChannelBufferIndex := 0;

    if odOpenFile.Execute then
    begin
      strCommand := '-i "'+ odOpenFile.FileName + '" -f s24le -acodec pcm_s24le -ar ' + dSampleRate.ToString + ' -ac 2 ' + c_strOutPutFileName;

      DeleteFile(c_strOutPutFileName);
      ExecuteAndWait(c_strFfmpegBin + ' ' + strCommand);

      InterpretFile(TFile.ReadAllBytes(c_strOutPutFileName));
    end;
  end;
end;


end.
