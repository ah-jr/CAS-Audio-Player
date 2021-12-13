program CAS_AudioPlayer;

uses
  Vcl.Forms,
  MainForm      in 'MainForm.pas',
  AudioManagerU in 'AudioManagerU.pas',

  // Cas Libraries
  CasEngineU    in '..\deps\CasAudioEngine\CasEngineU.pas',
  CasTrackU     in '..\deps\CasUtils\CasTrackU.pas',
  CasMessagesU  in '..\deps\CasUtils\CasMessagesU.pas',
  CasDecoderU   in '..\deps\CasUtils\CasDecoderU.pas',

  // ASIO
  Asiolist      in '..\deps\CasAudioEngine\Asio\AsioList.pas',
  Asio          in '..\deps\CasAudioEngine\Asio\Asio.pas',
  OpenAsio      in '..\deps\CasAudioEngine\Asio\OpenAsio.pas';


{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TPlayerGUI, PlayerGUI);
  Application.Run;
end.
