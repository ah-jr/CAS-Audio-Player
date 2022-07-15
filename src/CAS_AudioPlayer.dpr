program CAS_AudioPlayer;

{$R 'icons.res' 'icons.rc'}

uses
  Vcl.Forms,
  MainForm      in 'MainForm.pas',
  AudioManagerU in 'AudioManagerU.pas',

  // Cas Libraries
  CasEngineU    in '..\deps\CasAudioEngine\src\CasEngineU.pas',
  CasTrackU     in '..\deps\CasAudioEngine\src\CasTrackU.pas',
  CasMixerU     in '..\deps\CasAudioEngine\src\CasMixerU.pas',
  CasPlaylistU  in '..\deps\CasAudioEngine\src\CasPlaylistU.pas',
  CasConstantsU in '..\deps\CasAudioEngine\src\CasConstantsU.pas',
  CasDecoderU   in '..\deps\CasAudioEngine\src\CasDecoderU.pas',
  CasDatabaseU  in '..\deps\CasAudioEngine\src\CasDatabaseU.pas',
  CasBasicFxU   in '..\deps\CasAudioEngine\src\CasBasicFxU.pas',
  CasUtilsU     in '..\deps\CasAudioEngine\src\CasUtilsU.pas',

  // ASIO
  Asiolist      in '..\deps\CasAudioEngine\Asio\AsioList.pas',
  Asio          in '..\deps\CasAudioEngine\Asio\Asio.pas',

  // Acrylic Form
  AcrylicGhostPanelU in '..\deps\TAcrylicForm\src\AcrylicGhostPanelU.pas',
  AcrylicFormU       in '..\deps\TAcrylicForm\src\AcrylicFormU.pas',
  AcrylicButtonU     in '..\deps\TAcrylicForm\src\AcrylicButtonU.pas',
  AcrylicLabelU      in '..\deps\TAcrylicForm\src\AcrylicLabelU.pas',
  AcrylicTypesU      in '..\deps\TAcrylicForm\src\AcrylicTypesU.pas';


{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TPlayerGUI, PlayerGUI);
  Application.Run;
end.
