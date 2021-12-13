unit CasTrackU;

interface

uses
  Winapi.Windows,
  Winapi.Messages;

const
  //////////////////////////////////////////////////////////////////////////////
  // Send these to another file later
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
  TRawData = record
    Right : Array of Integer;
    Left  : Array of Integer;
  end;
  PRawData = ^TRawData;

  TCasTrack = class

  private
    m_nID       : Integer;
    m_strTitle  : String;
    m_nPosition : Integer;
    m_nLevel    : Integer;
    m_RawData   : PRawData;
    m_nProgress : Double;

    constructor Create;

    procedure Normalize;

    procedure SetPosition(a_nPosition : Integer);

    function GetProgress : Double;
    function GetSize     : Integer;


  public

    property ID          : Integer  read m_nID         write m_nID;
    property Title       : String   read m_strTitle    write m_strTitle;
    property Position    : Integer  read m_nPosition   write SetPosition;

    property RawData     : PRawData read m_RawData     write m_RawData;
    property Level       : Integer  read m_nLevel      write m_nLevel;
    property Progress    : Double   read GetProgress;
    property Size        : Integer  read GetSize;


  end;

implementation

uses
  Math;

//==============================================================================
constructor TCasTrack.Create;
begin
  m_nID       := 0;
  m_strTitle  := '';
  m_nPosition := 0;
  m_nLevel    := 100;
  m_nProgress := 0;
end;

//==============================================================================
procedure TCasTrack.Normalize;
begin
  // WIP
end;

//==============================================================================
procedure TCasTrack.SetPosition(a_nPosition : Integer);
begin
  m_nPosition := Max(Min(0, a_nPosition), GetSize);
end;

//==============================================================================
function TCasTrack.GetProgress : Double;
begin
  Result := m_nPosition / GetSize;
end;

//==============================================================================
function TCasTrack.GetSize : Integer;
begin
  Result := Length(m_RawData.Right) div c_nBytesInSample;
end;


end.

