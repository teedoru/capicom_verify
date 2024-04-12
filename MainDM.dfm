object DModule: TDModule
  OldCreateOrder = False
  Height = 506
  Width = 525
  object FDConnection: TFDConnection
    Params.Strings = (
      'User_Name=sa'
      'Database=babydance'
      'Password=%W?b@Oea@l'
      'Server=85.193.90.200'
      'DriverID=MSSQL')
    LoginPrompt = False
    Left = 24
    Top = 16
  end
  object FDQuery: TFDQuery
    Connection = FDConnection
    Left = 64
    Top = 16
  end
end
