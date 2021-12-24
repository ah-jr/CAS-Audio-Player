unit CasMixerU;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.Generics.Collections;

type
  TCasMixer = class

  private
    m_nID       : Integer;
    m_strTitle  : String;
    m_dLevel    : Double;
    m_dPan      : Double;

    m_lstTracks : TList<Integer>;
    m_lstMixers : TList<Integer>;

  public
    constructor Create;
    destructor  Destroy;

    function GetTracks   : TList<Integer>;
    function GetMixers   : TList<Integer>;

    procedure AddTrack(a_nID : Integer);
    procedure AddMixer(a_nID : Integer);

    procedure RemoveTrack(a_nID : Integer);
    procedure RemoveMixer(a_nID : Integer);

    property ID          : Integer  read m_nID         write m_nID;
    property Title       : String   read m_strTitle    write m_strTitle;
    property Level       : Double   read m_dLevel      write m_dLevel;
    property Pan         : Double   read m_dPan        write m_dPan;

  end;

implementation

uses
  Math,
  CasConstantsU;

//==============================================================================
constructor TCasMixer.Create;
begin
  m_nID       := 0;
  m_strTitle  := '';
  m_dLevel    := 1;

  m_lstTracks := TList<Integer>.Create;
  m_lstMixers := TList<Integer>.Create;
end;

//==============================================================================
destructor TCasMixer.Destroy;
begin
  m_lstTracks.Free;
  m_lstMixers.Free;
end;

//==============================================================================
function TCasMixer.GetTracks : TList<Integer>;
begin
  Result := m_lstTracks;
end;

//==============================================================================
function TCasMixer.GetMixers : TList<Integer>;
begin
  Result := m_lstMixers;
end;

//==============================================================================
procedure TCasMixer.AddTrack(a_nID : Integer);
begin
  m_lstTracks.Add(a_nID);
end;

//==============================================================================
procedure TCasMixer.AddMixer(a_nID : Integer);
begin
  m_lstMixers.Add(a_nID);
end;

//==============================================================================
procedure TCasMixer.RemoveTrack(a_nID : Integer);
begin
  m_lstTracks.Remove(a_nID);
end;

//==============================================================================
procedure TCasMixer.RemoveMixer(a_nID : Integer);
begin
  m_lstMixers.Remove(a_nID);
end;

end.

