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
    m_lstTracks : TList<Integer>;

    m_CasDatabase : TCasDatabase;

    function GetProgress : Double;
    function GetLength   : Integer;

    procedure SetPosition(a_nPosition : Integer);

  public
    constructor Create(a_CasDatabase: TCasDatabase);
    destructor  Destroy; override;

    procedure AddTrack   (a_nID: Integer);
    procedure RemoveTrack(a_nID: Integer);
    procedure ClearTracks;

    property Progress    : Double   read GetProgress;
    property Position    : Integer  read m_nPosition   write SetPosition;
    property Length      : Integer  read GetLength;

  end;

implementation

uses
  Math,
  CasConstantsU,
  CasTrackU;

//==============================================================================
constructor TCasPlaylist.Create(a_CasDatabase: TCasDatabase);
begin
  m_nPosition   := 0;
  m_CasDatabase := a_CasDatabase;
  m_lstTracks   := TList<Integer>.Create;
end;

//==============================================================================
destructor TCasPlaylist.Destroy;
begin
  m_lstTracks.Free;

  Inherited;
end;

//==============================================================================
procedure TCasPlaylist.SetPosition(a_nPosition : Integer);
begin
  m_nPosition := Min(Max(0, a_nPosition), GetLength);
end;

//==============================================================================
function TCasPlaylist.GetProgress : Double;
begin
  Result := m_nPosition / GetLength;
end;

//==============================================================================
function TCasPlaylist.GetLength : Integer;
var
  nTrackIdx : Integer;
  nMaxSize  : Integer;
  CasTrack  : TCasTrack;
begin
  nMaxSize := 0;

  for nTrackIdx := 0 to m_lstTracks.Count - 1 do
    if m_CasDatabase.GetTrackById(m_lstTracks[nTrackIdx], CasTrack) then
      nMaxSize := Max(CasTrack.Position + CasTrack.Size, nMaxSize);

  Result := nMaxSize;
end;

//==============================================================================
procedure TCasPlaylist.AddTrack(a_nID: Integer);
begin
  m_lstTracks.Add(a_nID);
end;

//==============================================================================
procedure TCasPlaylist.RemoveTrack(a_nID: Integer);
begin
  m_lstTracks.Remove(a_nID);
end;

//==============================================================================
procedure TCasPlaylist.ClearTracks;
begin
  m_lstTracks.Clear;
end;


end.

