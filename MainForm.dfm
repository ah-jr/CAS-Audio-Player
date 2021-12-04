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
  end
  object btnPlay: TButton
    Left = 56
    Top = 72
    Width = 75
    Height = 25
    TabOrder = 1
  end
  object btnStop: TButton
    Left = 152
    Top = 192
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 2
  end
  object btnPause: TButton
    Left = 56
    Top = 192
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
    Orientation = trVertical
    TabOrder = 4
  end
  object tbProgress: TTrackBar
    Left = 56
    Top = 384
    Width = 150
    Height = 45
    TabOrder = 5
  end
  object cbDriver: TComboBox
    Left = 72
    Top = 16
    Width = 145
    Height = 21
    TabOrder = 6
    Text = 'cbDriver'
  end
  object temp1: TButton
    Left = 280
    Top = 353
    Width = 75
    Height = 25
    Caption = 'temp1'
    TabOrder = 7
  end
  object temp2: TButton
    Left = 280
    Top = 384
    Width = 75
    Height = 25
    Caption = 'temp2'
    TabOrder = 8
  end
  object odOpenFile: TOpenDialog
    Left = 320
    Top = 184
  end
end
