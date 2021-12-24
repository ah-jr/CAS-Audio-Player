unit CasEngineU;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.Generics.Collections,
  CasTrackU,
  CasConstantsU,
  CasMixerU,
  CasDatabaseU,
  CasPlaylistU,
  AsioList,
  OpenAsio,
  Asio;

type
  TCasEngine = class(TObject)

  private
    m_hwndHandle                 : HWND;
    m_Owner                      : TObject;
    m_MainMixer                  : TCasMixer;

    m_CasDatabase                : TCasDatabase;
    m_CasPlaylist                : TCasPlaylist;

    m_nCurrentBufferSize         : Integer;
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

    function  GetLevel      : Double;
    function  GetPosition   : Integer;
    function  GetProgress   : Double;
    function  GetLength     : Integer;
    function  GetReady      : Boolean;
    function  GetSampleRate : Double;

    procedure SetLevel   (a_dLevel : Double);
    procedure SetPosition(a_nPosition : Integer);

    function  AddTrack(a_CasTrack : TCasTrack; a_nMixerId : Integer) : Boolean;
    procedure ClearTracks;
    procedure ChangeDriver(a_nID : Integer);

    procedure BufferSwitch         (a_nIndex : Integer);
    procedure BufferSwitchTimeInfo (a_nIndex : Integer; const Params : TAsioTime);

    procedure CMAsio(var Message: TMessage); message CM_ASIO;

    property Level      : Double    read GetLevel     write SetLevel;
    property Position   : Integer   read GetPosition  write SetPosition;
    property Progress   : Double    read GetProgress;
    property Length     : Integer   read GetLength;

    property Ready      : Boolean   read GetReady;
    property Playing    : Boolean   read m_bIsStarted;
    property BuffersOn  : Boolean   read m_bBuffersCreated;
    property SampleRate : Double    read GetSampleRate;

    property AsioDriver : IOpenAsio read m_AsioDriver write m_AsioDriver;

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
  m_Owner   := a_Owner;
  CasEngine := Self;

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
begin
  m_hwndHandle := AllocateHWnd(ProcessMessage);

  m_CasDatabase := TCasDatabase.Create;
  m_CasPlaylist := TCasPlaylist.Create(m_CasDatabase);
  m_CasPlaylist.Position := 0;

  m_MainMixer       := TCasMixer.Create;
  m_MainMixer.ID    := 0;
  m_MainMixer.Level := 1;

  m_CasDatabase.AddMixer(m_MainMixer);

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
end;

//==============================================================================
function TCasEngine.AddTrack(a_CasTrack : TCasTrack; a_nMixerId : Integer) : Boolean;
var
  CasMixer : TCasMixer;
begin
  Result := False;

  if m_CasDatabase.GetMixerById(a_nMixerId, CasMixer) then
    begin
      CasMixer.AddTrack(a_CasTrack.ID);
      m_CasDatabase.AddTrack(a_CasTrack);

      Result := True;
    end;
end;

//==============================================================================
procedure TCasEngine.ClearTracks;
begin
  m_CasDatabase.ClearTracks;
end;

//==============================================================================
procedure TCasEngine.ChangeDriver(a_nID : Integer);
begin
  if m_AsioDriver <> nil then
    CloseDriver;

  if a_nID >= 0 then
  begin
    if OpenAsioCreate(m_DriverList[a_nID].Id, m_AsioDriver) then
      if (m_AsioDriver <> nil) then
        if not Succeeded(m_AsioDriver.Init(Handle))
          then m_AsioDriver := nil
          else CreateBuffers;
  end;
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
   nChannelIdx              : Integer;
   nBufferIdx               : Integer;
   Info                     : PAsioBufferInfo;
   OutputInt32              : PInteger;
   nLeftChannelBufferIndex  : Integer;
   nRightChannelBufferIndex : Integer;
begin
  if (m_CasPlaylist.Position < m_CasPlaylist.Length - m_nCurrentBufferSize) then
  begin
    Info := m_BufferInfo;

    nLeftChannelBufferIndex  := m_CasPlaylist.Position;
    nRightChannelBufferIndex := m_CasPlaylist.Position;

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
                  //OutputInt32^ := Trunc(Power(2, 32 - c_nBitDepth) * m_MainTrack.RawData.Left[nLeftChannelBufferIndex] * m_MainTrack.Level);
                  //Inc(nLeftChannelBufferIndex);
                end
              else
                begin
                  //OutputInt32^ := Trunc(Power(2, 32 - c_nBitDepth) * m_MainTrack.RawData.Right[nRightChannelBufferIndex] * m_MainTrack.Level);
                  //Inc(nRightChannelBufferIndex);
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

    m_CasPlaylist.Position := nLeftChannelBufferIndex;

    PostMessage(Handle, CM_UpdateSamplePos, Params.TimeInfo.SamplePosition.Hi, Params.TimeInfo.SamplePosition.Lo);
    m_AsioDriver.OutputReady;
  end
  else
  begin
    m_CasPlaylist.Position := 0;
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
    Pause;
    m_CasPlaylist.Position := 0;
//    UpdateProgressBar;
//    ChangeEnabledObjects;
  end;
end;

//==============================================================================
function TCasEngine.GetLevel : Double;
begin
  Result := m_MainMixer.Level;
end;

//==============================================================================
function TCasEngine.GetPosition : Integer;
begin
  Result := m_CasPlaylist.Position;
end;

//==============================================================================
function TCasEngine.GetProgress : Double;
begin
  Result := m_CasPlaylist.Progress;
end;

//==============================================================================
function TCasEngine.GetLength : Integer;
begin
  Result := m_CasPlaylist.Length;
end;

//==============================================================================
function TCasEngine.GetReady : Boolean;
begin
  Result := m_AsioDriver <> nil;
end;

//==============================================================================
function TCasEngine.GetSampleRate : Double;
begin
  if Ready then
  begin
    try
      m_AsioDriver.GetSampleRate(Result);
    except
      Result := 0;
    end;
  end;
end;

//==============================================================================
procedure TCasEngine.SetLevel(a_dLevel : Double);
begin
  m_MainMixer.Level := a_dLevel;
end;

//==============================================================================
procedure TCasEngine.SetPosition(a_nPosition : Integer);
begin
  m_CasPlaylist.Position := a_nPosition;
end;

//==============================================================================
end.

