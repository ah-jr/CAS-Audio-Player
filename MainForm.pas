////////////////////////////////////////////////////////////////////////////////
//
//   CAS Audio Player
//
//
//   CAS is a very simple audio player which runs the CAS Audio Engine.
//   The user is able to load a file of any audio format and play it, using
//   ASIO or DirectSound to load buffers.
//
//   Creation: 12/04/2021 by Airton Junior
//
////////////////////////////////////////////////////////////////////////////////

unit MainForm;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ComCtrls,
  AsioList,
  OpenAsio,
  Asio,
  Math;

type
  TPlayerGUI = class(TForm)
    btnOpenFile: TButton;
    btnPlay: TButton;
    btnStop: TButton;
    btnPause: TButton;
    odOpenFile: TOpenDialog;
    tbVolume: TTrackBar;
    tbProgress: TTrackBar;
    lblVolume: TLabel;
    lblProgress: TLabel;
    cbDriver: TComboBox;
    temp1: TButton;
    temp2: TButton;
  private

  public

  end;

var
  PlayerGUI: TPlayerGUI;

implementation

{$R *.dfm}




end.
