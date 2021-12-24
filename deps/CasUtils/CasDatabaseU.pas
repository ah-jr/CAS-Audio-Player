unit CasDatabaseU;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.Generics.Collections,
  CasMixerU,
  CasTrackU;

type
  TCasDatabase = class

  private
    m_lstTracks : TList<TCasTrack>;
    m_lstMixers : TList<TCasMixer>;

    m_dctTracks : TDictionary<Integer, TCasTrack>;
    m_dctMixers : TDictionary<Integer, TCasMixer>;

  public
    constructor Create;
    destructor  Destroy;

    procedure AddTrack(a_CasTrack : TCasTrack);
    procedure AddMixer(a_CasMixer : TCasMixer);

    procedure RemoveTrack(a_nID: Integer);
    procedure RemoveMixer(a_nID: Integer);

    function  GetTrackById(a_nID: Integer; var a_Castrack : TCasTrack) : Boolean;
    function  GetMixerById(a_nID: Integer; var a_CasMixer : TCasMixer) : Boolean;

    procedure ClearTracks;
    procedure ClearMixers;

  end;

implementation

uses
  CasConstantsU;

//==============================================================================
constructor TCasDatabase.Create;
begin
  // Remember to always keep the list and dictionary equal. They should contain
  // the same tracks/mixers.
  m_lstTracks := TList<TCasTrack>.Create;
  m_lstMixers := TList<TCasMixer>.Create;

  m_dctTracks := TDictionary<Integer, TCasTrack>.Create;
  m_dctMixers := TDictionary<Integer, TCasMixer>.Create;
end;

//==============================================================================
destructor  TCasDatabase.Destroy;
var
  CasTrack : TCasTrack;
  CasMixer : TCasMixer;
begin
  for CasTrack in m_lstTracks do
    CasTrack.Free;

  for CasMixer in m_lstMixers do
    CasMixer.Free;

  m_lstTracks.Free;
  m_lstMixers.Free;

  m_dctTracks.Free;
  m_dctMixers.Free;
end;

//==============================================================================
procedure TCasDatabase.AddTrack(a_CasTrack : TCasTrack);
begin
  m_lstTracks.Add(a_CasTrack);
  m_dctTracks.AddOrSetValue(a_CasTrack.ID, a_CasTrack);
end;

//==============================================================================
procedure TCasDatabase.AddMixer(a_CasMixer : TCasMixer);
begin
  m_lstMixers.Add(a_CasMixer);
  m_dctMixers.AddOrSetValue(a_CasMixer.ID, a_CasMixer);
end;

//==============================================================================
procedure TCasDatabase.RemoveTrack(a_nID: Integer);
var
  CasTrack : TCasTrack;
begin
  if m_dctTracks.TryGetValue(a_nID, CasTrack) then
  begin
    m_lstTracks.Remove(CasTrack);

    CasTrack.Free;

    m_dctTracks.Remove(a_nID);
  end;
end;

//==============================================================================
procedure TCasDatabase.RemoveMixer(a_nID: Integer);
var
  CasMixer : TCasMixer;
begin
  if m_dctMixers.TryGetValue(a_nID, CasMixer) then
  begin
    m_lstMixers.Remove(CasMixer);

    CasMixer.Free;

    m_dctMixers.Remove(a_nID);
  end;
end;

//==============================================================================
function TCasDatabase.GetTrackById(a_nID: Integer; var a_Castrack : TCasTrack) : Boolean;
begin
  Result := m_dctTracks.TryGetValue(a_nID, a_Castrack);
end;

//==============================================================================
function TCasDatabase.GetMixerById(a_nID: Integer; var a_CasMixer : TCasMixer) : Boolean;
begin
  Result := m_dctMixers.TryGetValue(a_nID, a_CasMixer);
end;

//==============================================================================
procedure TCasDatabase.ClearTracks;
var
  CasTrack : TCasTrack;
begin
  for CasTrack in m_lstTracks do
  begin
    CasTrack.Free;
  end;

  m_dctTracks.Clear;
  m_lstTracks.Clear;
end;

//==============================================================================
procedure TCasDatabase.ClearMixers;
var
  CasMixer : TCasMixer;
begin
  for CasMixer in m_lstMixers do
  begin
    CasMixer.Free;
  end;

  m_dctMixers.Clear;
  m_lstMixers.Clear;
end;

end.

