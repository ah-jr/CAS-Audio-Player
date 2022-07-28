program CAS_AudioPlayer;

{$R 'images.res' 'images\images.rc'}

uses
  Vcl.Forms,
  PlayerFormU   in 'src\PlayerFormU.pas',
  AudioManagerU in 'src\AudioManagerU.pas',

  // Cas Libraries
  CasEngineU      in 'deps\CasAudioEngine\src\CasEngineU.pas',
  CasAsioU        in 'deps\CasAudioEngine\src\CasAsioU.pas',
  CasDirectSoundU in 'deps\CasAudioEngine\src\CasDirectSoundU.pas',
  CasDsThreadU    in 'deps\CasAudioEngine\src\CasDsThreadU.pas',
  CasTrackU       in 'deps\CasAudioEngine\src\CasTrackU.pas',
  CasMixerU       in 'deps\CasAudioEngine\src\CasMixerU.pas',
  CasPlaylistU    in 'deps\CasAudioEngine\src\CasPlaylistU.pas',
  CasConstantsU   in 'deps\CasAudioEngine\src\CasConstantsU.pas',
  CasTypesU       in 'deps\CasAudioEngine\src\CasTypesU.pas',
  CasDecoderU     in 'deps\CasAudioEngine\src\CasDecoderU.pas',
  CasDatabaseU    in 'deps\CasAudioEngine\src\CasDatabaseU.pas',
  CasBasicFxU     in 'deps\CasAudioEngine\src\CasBasicFxU.pas',
  CasUtilsU       in 'deps\CasAudioEngine\src\CasUtilsU.pas',

  // ASIO
  Asiolist      in 'deps\CasAudioEngine\Asio\AsioList.pas',
  Asio          in 'deps\CasAudioEngine\Asio\Asio.pas',

  // Acrylic Form
  AcrylicControlU    in 'deps\TAcrylicForm\src\AcrylicControlU.pas',
  AcrylicGhostPanelU in 'deps\TAcrylicForm\src\AcrylicGhostPanelU.pas',
  AcrylicFrameU      in 'deps\TAcrylicForm\src\AcrylicFrameU.pas',
  AcrylicScrollBoxU  in 'deps\TAcrylicForm\src\AcrylicScrollBoxU.pas',
  AcrylicFormU       in 'deps\TAcrylicForm\src\AcrylicFormU.pas',
  AcrylicButtonU     in 'deps\TAcrylicForm\src\AcrylicButtonU.pas',
  AcrylicLabelU      in 'deps\TAcrylicForm\src\AcrylicLabelU.pas',
  AcrylicTypesU      in 'deps\TAcrylicForm\src\AcrylicTypesU.pas',
  AcrylicUtilsU      in 'deps\TAcrylicForm\src\AcrylicUtilsU.pas',
  AcrylicTrackU      in 'deps\TAcrylicForm\src\AcrylicTrackU.pas',
  AcrylicKnobU       in 'deps\TAcrylicForm\src\AcrylicKnobU.pas';


{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TPlayerGUI, PlayerGUI);
  Application.Run;
end.
