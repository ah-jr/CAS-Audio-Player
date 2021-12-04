object PlayerGUI: TPlayerGUI
  Left = 0
  Top = 0
  Caption = 'TPlayerGUI'
  ClientHeight = 530
  ClientWidth = 562
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object lblVolume: TLabel
    Left = 448
    Top = 128
    Width = 44
    Height = 13
    Caption = 'lblVolume'
  end
  object lblProgress: TLabel
    Left = 56
    Top = 352
    Width = 44
    Height = 13
    Caption = 'lblVolume'
  end
  object btnOpenFile: TButton
    Left = 152
    Top = 72
    Width = 75
    Height = 25
    Caption = 'Open File'
    TabOrder = 0
    OnClick = btnOpenFileClick
  end
  object btnPlay: TButton
    Left = 56
    Top = 72
    Width = 75
    Height = 25
    TabOrder = 1
    OnClick = StartBtnClick
  end
  object btnStop: TButton
    Left = 56
    Top = 134
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 2
    OnClick = btnStopClick
  end
  object btnPause: TButton
    Left = 56
    Top = 103
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 3
  end
  object tbVolume: TTrackBar
    Left = 448
    Top = 192
    Width = 45
    Height = 150
    Max = 100
    Orientation = trVertical
    TabOrder = 4
    OnChange = TrackBar1Change
  end
  object tbProgress: TTrackBar
    Left = 56
    Top = 384
    Width = 150
    Height = 45
    Max = 100
    TabOrder = 5
    OnChange = tbProgressChange
  end
  object cbDriver: TComboBox
    Left = 72
    Top = 16
    Width = 145
    Height = 21
    TabOrder = 6
    Text = 'cbDriver'
    OnChange = cbDriverChange
  end
  object temp1: TButton
    Left = 280
    Top = 353
    Width = 75
    Height = 25
    Caption = 'temp1'
    TabOrder = 7
    OnClick = temp1Click
  end
  object temp2: TButton
    Left = 280
    Top = 384
    Width = 75
    Height = 25
    Caption = 'temp2'
    TabOrder = 8
    OnClick = temp2Click
  end
  object btnDriverControlPanel: TButton
    Left = 256
    Top = 272
    Width = 75
    Height = 25
    Caption = 'btnDriverControlPanel'
    TabOrder = 9
    OnClick = ControlPanelBtnClick
  end
  object odOpenFile: TOpenDialog
    Left = 320
    Top = 184
  end
end
