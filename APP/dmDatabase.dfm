object DB: TDB
  Height = 480
  Width = 640
  object FDConnection1: TFDConnection
    Params.Strings = (
      'DriverID=SQLite'
      'Database=..\database\fitmanager.db')
    FormatOptions.AssignedValues = [fvMapRules]
    FormatOptions.OwnMapRules = True
    FormatOptions.MapRules = <
      item
        SourceDataType = dtMemo
        TargetDataType = dtAnsiString
      end
      item
        SourceDataType = dtWideMemo
        TargetDataType = dtWideString
      end>
    LoginPrompt = False
    Left = 176
    Top = 160
  end
  object FDQuery1: TFDQuery
    Connection = FDConnection1
    FormatOptions.AssignedValues = [fvMapRules]
    FormatOptions.OwnMapRules = True
    FormatOptions.MapRules = <
      item
        SourceDataType = dtMemo
        TargetDataType = dtAnsiString
      end
      item
        SourceDataType = dtWideMemo
        TargetDataType = dtWideString
      end>
    Left = 368
    Top = 240
  end
end
