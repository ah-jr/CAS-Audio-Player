object PlayerGUI: TPlayerGUI
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'TPlayerGUI'
  ClientHeight = 150
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
    Max = 500
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
    TabOrder = 3
    TickMarks = tmBoth
    TickStyle = tsNone
    OnChange = tbSpeedChange
  end
  object btnPlay: TAcrylicButton
    Left = 142
    Top = 48
    Width = 85
    Height = 53
    Text = ''
    OnClick = btnPlayClick
  end
  object btnPause: TAcrylicButton
    Left = 235
    Top = 48
    Width = 85
    Height = 53
    Text = ''
    OnClick = btnPauseClick
  end
  object btnStop: TAcrylicButton
    Left = 328
    Top = 48
    Width = 85
    Height = 53
    Text = ''
    OnClick = btnStopClick
  end
  object btnOpenFile: TAcrylicButton
    Left = 26
    Top = 77
    Width = 108
    Height = 24
    Text = 'Open File'
    OnClick = btnOpenFileClick
  end
  object btnDriverControlPanel: TAcrylicButton
    Left = 26
    Top = 107
    Width = 108
    Height = 24
    Text = 'Driver Settings'
    OnClick = btnDriverControlPanelClick
  end
  object odOpenFile: TOpenDialog
    Options = [ofHideReadOnly, ofAllowMultiSelect, ofEnableSizing]
    Left = 64
    Top = 88
  end
end
