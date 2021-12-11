program CAS_AudioPlayer;

uses
  Vcl.Forms,
  MainForm  in 'MainForm.pas',
  AsioList  in '..\deps\asio\asiolist.pas',
  Asio      in '..\deps\asio\asio.pas',
  OpenASIO  in '..\deps\asio\openasio.pas',
  CasEngine in '..\deps\CasAudioEngine\CasEngine.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TPlayerGUI, PlayerGUI);
  Application.Run;
end.
