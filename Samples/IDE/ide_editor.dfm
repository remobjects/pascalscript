object editor: Teditor
  Left = 350
  Top = 222
  Width = 696
  Height = 480
  Caption = 'Editor'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  Position = poDesktopCenter
  PixelsPerInch = 120
  TextHeight = 16
  object Splitter1: TSplitter
    Left = 0
    Top = 311
    Width = 688
    Height = 4
    Cursor = crVSplit
    Align = alBottom
  end
  object ed: TSynEdit
    Left = 0
    Top = 0
    Width = 688
    Height = 311
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -17
    Font.Name = 'Courier New'
    Font.Style = []
    PopupMenu = PopupMenu1
    TabOrder = 0
    Gutter.AutoSize = True
    Gutter.Font.Charset = DEFAULT_CHARSET
    Gutter.Font.Color = clWindowText
    Gutter.Font.Height = -11
    Gutter.Font.Name = 'Terminal'
    Gutter.Font.Style = []
    Gutter.ShowLineNumbers = True
    Highlighter = pashighlighter
    Lines.Strings = (
      'Program test;'
      'begin'
      'end.')
    Options = [eoAutoIndent, eoDragDropEditing, eoDropFiles, eoGroupUndo, eoScrollPastEol, eoShowScrollHint, eoSmartTabDelete, eoSmartTabs, eoTabsToSpaces, eoTrimTrailingSpaces]
    OnDropFiles = edDropFiles
    OnSpecialLineColors = edSpecialLineColors
    OnStatusChange = edStatusChange
    RemovedKeystrokes = <
      item
        Command = ecContextHelp
        ShortCut = 112
      end>
    AddedKeystrokes = <
      item
        Command = ecContextHelp
        ShortCut = 16496
      end>
  end
  object messages: TListBox
    Left = 0
    Top = 315
    Width = 688
    Height = 81
    Align = alBottom
    ItemHeight = 16
    TabOrder = 1
    OnDblClick = messagesDblClick
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 396
    Width = 688
    Height = 19
    Panels = <
      item
        Width = 50
      end>
  end
  object ce: TPSScriptDebugger
    CompilerOptions = []
    OnCompile = ceCompile
    OnExecute = ceExecute
    OnAfterExecute = ceAfterExecute
    Plugins = <
      item
        Plugin = IFPS3CE_DateUtils1
      end
      item
        Plugin = IFPS3CE_Std1
      end
      item
        Plugin = IFPS3CE_Controls1
      end
      item
        Plugin = IFPS3CE_StdCtrls1
      end
      item
        Plugin = IFPS3CE_Forms1
      end
      item
        Plugin = IFPS3DllPlugin1
      end
      item
        Plugin = IFPS3CE_ComObj1
      end>
    MainFileName = 'Unnamed'
    UsePreProcessor = True
    OnNeedFile = ceNeedFile
    OnIdle = ceIdle
    OnLineInfo = ceLineInfo
    OnBreakpoint = ceBreakpoint
    Left = 592
    Top = 112
  end
  object IFPS3DllPlugin1: TPSDllPlugin
    Left = 560
    Top = 112
  end
  object pashighlighter: TSynPasSyn
    Left = 592
    Top = 64
  end
  object PopupMenu1: TPopupMenu
    Left = 592
    Top = 16
    object BreakPointMenu: TMenuItem
      Caption = '&Set/Clear Breakpoint'
      ShortCut = 116
      OnClick = BreakPointMenuClick
    end
  end
  object MainMenu1: TMainMenu
    Left = 592
    Top = 160
    object File1: TMenuItem
      Caption = '&File'
      object New1: TMenuItem
        Caption = '&New'
        ShortCut = 16462
        OnClick = New1Click
      end
      object N3: TMenuItem
        Caption = '-'
      end
      object Open1: TMenuItem
        Caption = '&Open...'
        ShortCut = 16463
        OnClick = Open1Click
      end
      object Save1: TMenuItem
        Caption = '&Save'
        ShortCut = 16467
        OnClick = Save1Click
      end
      object Saveas1: TMenuItem
        Caption = 'Save &as...'
        OnClick = Saveas1Click
      end
      object N4: TMenuItem
        Caption = '-'
      end
      object Exit1: TMenuItem
        Caption = '&Exit'
        OnClick = Exit1Click
      end
    end
    object Search1: TMenuItem
      Caption = '&Search'
      object Find1: TMenuItem
        Caption = '&Find...'
        OnClick = Find1Click
      end
      object Replace1: TMenuItem
        Caption = '&Replace...'
        OnClick = Replace1Click
      end
      object Searchagain1: TMenuItem
        Caption = '&Search again'
        OnClick = Searchagain1Click
      end
      object N6: TMenuItem
        Caption = '-'
      end
      object Gotolinenumber1: TMenuItem
        Caption = '&Go to...'
        OnClick = Gotolinenumber1Click
      end
    end
    object Run1: TMenuItem
      Caption = '&Run'
      object Syntaxcheck1: TMenuItem
        Caption = 'Syntax &check'
        OnClick = Syntaxcheck1Click
      end
      object Decompile1: TMenuItem
        Caption = '&Decompile...'
        OnClick = Decompile1Click
      end
      object N5: TMenuItem
        Caption = '-'
      end
      object StepOver1: TMenuItem
        Caption = '&Step Over'
        ShortCut = 119
        OnClick = StepOver1Click
      end
      object StepInto1: TMenuItem
        Caption = 'Step &Into'
        ShortCut = 118
        OnClick = StepInto1Click
      end
      object N1: TMenuItem
        Caption = '-'
      end
      object Pause1: TMenuItem
        Caption = '&Pause'
        OnClick = Pause1Click
      end
      object Reset1: TMenuItem
        Caption = 'R&eset'
        ShortCut = 16497
        OnClick = Reset1Click
      end
      object N2: TMenuItem
        Caption = '-'
      end
      object Run2: TMenuItem
        Caption = '&Run'
        ShortCut = 120
        OnClick = Run2Click
      end
    end
  end
  object SaveDialog1: TSaveDialog
    DefaultExt = 'ROPS'
    Filter = 'ROPS Files|*.ROPS'
    Options = [ofHideReadOnly, ofPathMustExist, ofEnableSizing]
    Left = 200
    Top = 104
  end
  object OpenDialog1: TOpenDialog
    DefaultExt = 'ROPS'
    Filter = 'ROPS Files|*.ROPS'
    Options = [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Left = 168
    Top = 104
  end
  object IFPS3CE_Controls1: TPSImport_Controls
    EnableStreams = True
    EnableGraphics = True
    EnableControls = True
    Left = 328
    Top = 40
  end
  object IFPS3CE_DateUtils1: TPSImport_DateUtils
    Left = 328
    Top = 72
  end
  object IFPS3CE_Std1: TPSImport_Classes
    EnableStreams = True
    EnableClasses = True
    Left = 328
    Top = 104
  end
  object IFPS3CE_Forms1: TPSImport_Forms
    EnableForms = True
    EnableMenus = True
    Left = 328
    Top = 136
  end
  object IFPS3CE_StdCtrls1: TPSImport_StdCtrls
    EnableExtCtrls = True
    EnableButtons = True
    Left = 328
    Top = 168
  end
  object IFPS3CE_ComObj1: TPSImport_ComObj
    Left = 328
    Top = 200
  end
  object SynEditSearch: TSynEditSearch
    Left = 136
    Top = 216
  end
  object SynEditRegexSearch: TSynEditRegexSearch
    Left = 168
    Top = 216
  end
end
