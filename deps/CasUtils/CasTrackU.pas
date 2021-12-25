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
    //m_nProgress : Double;

    procedure Normalize;

    //procedure SetPosition(a_nPosition : Integer);

    //function GetProgress : Double;
    function GetSize     : Integer;


  public
    constructor Create;

    property ID          : Integer  read m_nID         write m_nID;
    property Title       : String   read m_strTitle    write m_strTitle;
    property Position    : Integer  read m_nPosition   write m_nPosition;//SetPosition;

    property RawData     : PRawData read m_RawData     write m_RawData;
    property Level       : Double   read m_dLevel      write m_dLevel;
    //property Progress    : Double   read GetProgress;
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
  //m_nProgress := 0;
end;

//==============================================================================
procedure TCasTrack.Normalize;
begin
  // WIP
end;

////==============================================================================
//procedure TCasTrack.SetPosition(a_nPosition : Integer);
//begin
//  m_nPosition := Max(Min(0, a_nPosition), GetSize);
//end;

////==============================================================================
//function TCasTrack.GetProgress : Double;
//begin
//  Result := m_nPosition / GetSize;
//end;

//==============================================================================
function TCasTrack.GetSize : Integer;
begin
  if m_RawData <> nil then
  begin
    Result := Length(m_RawData.Right);// div c_nBytesInSample;
  end
  else
    Result := 0;
end;


end.

