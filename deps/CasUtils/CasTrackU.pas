unit CasTrackU;

interface

uses
  Winapi.Windows,
  Winapi.Messages;

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
    m_dLevel    : Double;
    m_RawData   : PRawData;

    procedure Normalize;
    function  GetSize : Integer;


  public
    constructor Create;
    destructor  Destroy; override;

    property ID          : Integer  read m_nID         write m_nID;
    property Title       : String   read m_strTitle    write m_strTitle;
    property Position    : Integer  read m_nPosition   write m_nPosition;

    property RawData     : PRawData read m_RawData     write m_RawData;
    property Level       : Double   read m_dLevel      write m_dLevel;
    property Size        : Integer  read GetSize;

  end;

implementation

uses
  Math,
  CasConstantsU;

//==============================================================================
constructor TCasTrack.Create;
begin
  m_nID       := 0;
  m_strTitle  := '';
  m_nPosition := -1;
  m_dLevel    := 1;
end;

//==============================================================================
destructor TCasTrack.Destroy;
begin
  SetLength(m_RawData.Left,  0);
  SetLength(m_RawData.Right, 0);

  Inherited;
end;

//==============================================================================
procedure TCasTrack.Normalize;
begin
  // WIP
end;

//==============================================================================
function TCasTrack.GetSize : Integer;
begin
  if m_RawData <> nil then
  begin
    Result := Length(m_RawData.Right);
  end
  else
    Result := 0;
end;


end.

