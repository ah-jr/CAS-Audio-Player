object PlayerGUI: TPlayerGUI
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'TPlayerGUI'
  ClientHeight = 386
  ClientWidth = 497
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnPaint = FormPaint
  PixelsPerInch = 96
  TextHeight = 13
  object tbVolume: TTrackBar
    Left = 421
    Top = 43
    Width = 34
    Height = 92
    Hint = 'Output Level'
    Max = 100
    Orientation = trVertical
    ParentShowHint = False
    ShowHint = True
    ShowSelRange = False
    TabOrder = 0
    TickMarks = tmBoth
    TickStyle = tsNone
    OnChange = tbVolumeChange
  end
  object tbProgress: TTrackBar
    Left = 136
    Top = 108
    Width = 282
    Height = 24
    Max = 100
    ShowSelRange = False
    TabOrder = 1
    TickMarks = tmBoth
    TickStyle = tsNone
    OnChange = tbProgressChange
  end
  object cbDriver: TComboBox
    Left = 26
    Top = 50
    Width = 108
    Height = 21
    TabOrder = 2
    Text = 'Select Output'
    OnChange = cbDriverChange
  end
  object sbTrackList: TScrollBox
    Left = 26
    Top = 148
    Width = 444
    Height = 214
    BevelInner = bvNone
    BevelOuter = bvNone
    BorderStyle = bsNone
    Color = clBackground
    ParentColor = False
    TabOrder = 3
    OnMouseWheelDown = sbTrackListMouseWheelDown
    OnMouseWheelUp = sbTrackListMouseWheelUp
  end
  object tbSpeed: TTrackBar
    Left = 449
    Top = 43
    Width = 34
    Height = 92
    Hint = 'Speed: 1x'
    Orientation = trVertical
    ParentShowHint = False
    Position = 5
    ShowHint = True
    ShowSelRange = False
    TabOrder = 4
    TickMarks = tmBoth
    TickStyle = tsNone
    OnChange = tbSpeedChange
  end
  object odOpenFile: TOpenDialog
    Options = [ofHideReadOnly, ofAllowMultiSelect, ofEnableSizing]
    Left = 64
    Top = 88
  end
end
