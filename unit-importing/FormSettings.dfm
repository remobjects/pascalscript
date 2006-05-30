object frmSettings: TfrmSettings
  Left = 405
  Top = 290
  BorderStyle = bsDialog
  Caption = 'Import settings'
  ClientHeight = 178
  ClientWidth = 490
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  DesignSize = (
    490
    178)
  PixelsPerInch = 120
  TextHeight = 16
  object Label1: TLabel
    Left = 10
    Top = 10
    Width = 96
    Height = 16
    Caption = 'Output directory:'
  end
  object Bevel1: TBevel
    Left = 0
    Top = 130
    Width = 490
    Height = 48
    Align = alBottom
    Shape = bsTopLine
  end
  object Label2: TLabel
    Left = 10
    Top = 39
    Width = 60
    Height = 16
    Caption = 'File prefix:'
  end
  object Button1: TButton
    Left = 385
    Top = 140
    Width = 93
    Height = 31
    Anchors = [akRight, akBottom]
    Caption = 'Ok'
    Default = True
    ModalResult = 1
    TabOrder = 5
  end
  object Button2: TButton
    Left = 288
    Top = 140
    Width = 92
    Height = 31
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 6
  end
  object edtOutPutDir: TEdit
    Left = 117
    Top = 6
    Width = 330
    Height = 24
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
  end
  object cbUseUnitAtCompileTime: TCheckBox
    Left = 116
    Top = 64
    Width = 222
    Height = 31
    Caption = 'Use the unit at compiletime'
    TabOrder = 3
  end
  object btnOutPutDir: TButton
    Left = 447
    Top = 6
    Width = 26
    Height = 26
    Anchors = [akTop, akRight]
    Caption = '...'
    TabOrder = 1
    OnClick = btnOutPutDirClick
  end
  object cbCreateOneImportfile: TCheckBox
    Left = 116
    Top = 89
    Width = 222
    Height = 30
    Caption = 'Create one importfile'
    Checked = True
    State = cbChecked
    TabOrder = 4
  end
  object Default: TCheckBox
    Left = 5
    Top = 146
    Width = 119
    Height = 21
    Anchors = [akLeft, akBottom]
    Caption = 'Default'
    TabOrder = 7
  end
  object edtPrefix: TEdit
    Left = 117
    Top = 34
    Width = 149
    Height = 24
    TabOrder = 2
    Text = 'edtPrefix'
  end
end
