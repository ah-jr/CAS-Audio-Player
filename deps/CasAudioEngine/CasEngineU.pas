unit CasEngineU;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  CasTrackU,
  CasMessagesU,
  AsioList,
  OpenAsio,
  Asio;

const
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
  TCasEngine = class(TObject)

  private
    m_hwndHandle                 : HWND;
    m_Owner                      : TObject;

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

    procedure ProcessMessage(var MsgRec: TMessage);
    procedure InitializeVariables;
    procedure CloseDriver;
    procedure CreateBuffers;
    procedure DestroyBuffers;

  public
    constructor Create(a_Owner : TObject);
    destructor  Destroy; override;

    procedure Play;
    procedure Pause;
    procedure Stop;

    procedure BufferSwitch         (a_nIndex : Integer);
    procedure BufferSwitchTimeInfo (a_nIndex : Integer; const Params : TAsioTime);

    procedure CMAsio(var Message: TMessage); message CM_ASIO;

    property BufferTime : TAsioTime read m_BufferTime write m_BufferTime;
    property Handle     : HWND      read m_hwndHandle write m_hwndHandle;

  end;

var
  CasEngine: TCasEngine;

implementation

uses
  VCL.Dialogs,
  System.Classes,
  System.SysUtils,
  Math;


//==============================================================================
procedure AsioBufferSwitch(DoubleBufferIndex: LongInt; DirectProcess: TASIOBool); cdecl;
begin
  case DirectProcess of
    ASIOFalse :  PostMessage(CasEngine.Handle, CM_ASIO, AM_BufferSwitch, DoubleBufferIndex);
    ASIOTrue  :  CasEngine.BufferSwitch(DoubleBufferIndex);
  end;
end;

//==============================================================================s
function AsioMessage(Selector, Value: LongInt; message: Pointer; Ppt: PDouble): LongInt; cdecl;
begin
  Result := 0;

  case Selector of
    kAsioSelectorSupported :
      begin
        case Value of
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
        PostMessage(CasEngine.Handle, CM_ASIO, AM_ResetRequest, 0);
        Result := 1;
      end;
    kAsioBufferSizeChange :
      begin
        PostMessage(CasEngine.Handle, CM_ASIO, AM_ResetRequest, 0);
        Result := 1;
      end;
    kAsioResyncRequest    : ;
    kAsioLatenciesChanged :
      begin
        PostMessage(CasEngine.Handle, CM_ASIO, AM_LatencyChanged, 0);
        Result := 1;
      end;
    kAsioSupportsTimeInfo     : Result := 1;
    kAsioSupportsTimeCode     : Result := 0;
    kAsioSupportsInputMonitor : ;
  end;
end;

//==============================================================================
function AsioBufferSwitchTimeInfo(var Params: TASIOTime; DoubleBufferIndex: LongInt; DirectProcess: TASIOBool): PASIOTime; cdecl;
begin
  case directProcess of
    ASIOFalse :
      begin
        CasEngine.BufferTime := Params;
        PostMessage(CasEngine.Handle, CM_ASIO, AM_BufferSwitchTimeInfo, DoubleBufferIndex);
      end;
    ASIOTrue  : CasEngine.BufferSwitchTimeInfo(DoubleBufferIndex, Params);
  end;

  Result := nil;
end;

//==============================================================================
constructor TCasEngine.Create(a_Owner : TObject);
begin
  m_Owner := a_Owner;

  InitializeVariables;
end;

//==============================================================================
destructor TCasEngine.Destroy;
begin
  DestroyWindow(m_hwndHandle);
  inherited;
end;

//==============================================================================
procedure TCasEngine.InitializeVariables;
var
  nDriverIdx : Integer;
begin
  m_hwndHandle := AllocateHWnd(ProcessMessage);

  m_nAudioLevel                := 0.7;
//  tbVolume.Position            := 30;

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
//  for nDriverIdx := Low(m_DriverList) to High(m_DriverList) do
//    cbDriver.Items.Add(String(m_DriverList[nDriverIdx].name));
end;

//==============================================================================
procedure TCasEngine.ProcessMessage(var MsgRec: TMessage);
begin
  try
//    Case MsgRec.Msg of
//      //
//    else
//      //
//    end;
  finally

  end;
end;

//==============================================================================
procedure TCasEngine.CMAsio(var Message: TMessage);
var
   inp, outp: integer;
begin
  case Message.WParam of
//    AM_ResetRequest         :  cbDriverChange(cbDriver);
    AM_BufferSwitch         :  BufferSwitch(Message.LParam);
    AM_BufferSwitchTimeInfo :  BufferSwitchTimeInfo(Message.LParam, m_BufferTime);
    AM_LatencyChanged       :
      if (m_AsioDriver <> nil) then
      begin
        m_AsioDriver.GetLatencies(inp, outp);
      end;
  end;
end;

//==============================================================================
procedure TCasEngine.BufferSwitch(a_nIndex : Integer);
begin
  FillChar(m_BufferTime, SizeOf(TAsioTime), 0);

  if m_AsioDriver.GetSamplePosition(m_BufferTime.TimeInfo.SamplePosition, m_BufferTime.TimeInfo.SystemTime) = ASE_OK then
    m_BufferTime.TimeInfo.Flags := kSystemTimeValid or kSamplePositionValid;

  BufferSwitchTimeInfo(a_nIndex, m_BufferTime)
end;

//==============================================================================
procedure TCasEngine.BufferSwitchTimeInfo(a_nIndex : Integer; const Params : TAsioTime);
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

    PostMessage(Handle, CM_UpdateSamplePos, Params.TimeInfo.SamplePosition.Hi, Params.TimeInfo.SamplePosition.Lo);
    m_AsioDriver.OutputReady;
  end
  else
  begin
    m_nLeftChannelBufferIndex  := 0;
    m_nRightChannelBufferIndex := 0;
  end;

  //UpdateProgressBar;
  //ChangeEnabledObjects
end;

//==============================================================================
procedure TCasEngine.CreateBuffers;
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

//    ChangeEnabledObjects;

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

//==============================================================================
procedure TCasEngine.DestroyBuffers;
begin
  if (m_AsioDriver <> nil) and m_bBuffersCreated then
  begin
    FreeMem(m_BufferInfo);
    m_AsioDriver.DisposeBuffers;

    m_BufferInfo         := nil;
    m_bBuffersCreated    := False;
    m_nCurrentBufferSize := 0;

//    ChangeEnabledObjects;
  end;
end;

//==============================================================================
procedure TCasEngine.CloseDriver;
begin
  if m_AsioDriver <> nil then
  begin
    if m_bIsStarted then
      Stop;

    if m_bBuffersCreated then
      DestroyBuffers;

    m_AsioDriver := nil;
  end;

//  ChangeEnabledObjects;
end;

//==============================================================================
procedure TCasEngine.Play;
begin
  if m_AsioDriver <> nil then
  begin
    m_bIsStarted := (m_AsioDriver.Start = ASE_OK);
//    ChangeEnabledObjects;
  end;
end;

//==============================================================================
procedure TCasEngine.Pause;
begin
  if m_AsioDriver <> nil then
  begin
    if m_bIsStarted then
    begin
      m_AsioDriver.Stop;
      m_bIsStarted := False;
    end;

//    ChangeEnabledObjects;
  end;
end;

//==============================================================================
procedure TCasEngine.Stop;
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
//    UpdateProgressBar;
//    ChangeEnabledObjects;
  end;
end;

end.


