unit CasPlaylistU;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.Generics.Collections,
  CasDatabaseU;

type
  TCasPlaylist = class

  private
    m_nPosition : Integer;
    m_nProgress : Double;

    m_CasDatabase : TCasDatabase;

    function GetProgress : Double;
    function GetLength   : Integer;

    procedure SetPosition(a_nPosition : Integer);

  public
    constructor Create(a_CasDatabase: TCasDatabase);
    destructor  Destroy;

    property Progress    : Double   read GetProgress;
    property Position    : Integer  read m_nPosition   write SetPosition;
    property TotalLength : Integer  read GetLength;

  end;

implementation

uses
  Math,
  CasConstantsU;

//==============================================================================
constructor TCasPlaylist.Create(a_CasDatabase: TCasDatabase);
begin
  m_CasDatabase := a_CasDatabase;
end;

//==============================================================================
destructor TCasPlaylist.Destroy;
begin
//
end;

//==============================================================================
procedure TCasPlaylist.SetPosition(a_nPosition : Integer);
begin
  m_nPosition := Max(Min(0, a_nPosition), GetLength);
end;

//==============================================================================
function TCasPlaylist.GetProgress : Double;
begin
  Result := m_nPosition / GetLength;
end;

//==============================================================================
function TCasPlaylist.GetLength : Integer;
begin
//  if m_RawData <> nil then
//  begin
//    Result := Length(m_RawData.Right) div c_nBytesInSample;
//  end
//  else
//    Result := 0;
end;


end.

