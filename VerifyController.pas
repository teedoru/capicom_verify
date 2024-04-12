unit VerifyController;

interface

uses
  MVCFramework, MVCFramework.Commons, MVCFramework.Serializer.Commons,
  System.Generics.Collections, System.SysUtils;

type
  [MVCPath('/api')]
  TVerifyController = class(TMVCController)
  public
    [MVCPath]
    [MVCHTTPMethod([httpGET])]
    procedure Index;
    [MVCPath('/verify')]
    [MVCHTTPMethod([httpPOST])]
    procedure Verify(CTX: TWebContext);
  private
  protected
    procedure OnBeforeAction(Context: TWebContext; const AActionName: string; var Handled: Boolean); override;
    procedure OnAfterAction(Context: TWebContext; const AActionName: string); override;
  public
  end;

  TCustomExceptionSeverity = (Fatal, Error, Warning, Information);

  ECustomException = class(Exception)
  private
    FSeverity: TCustomExceptionSeverity;
    FCode: Integer;
    FDetails: string;
    FDiagnostics: string;
    FExpression: string;
  public
    constructor Create(Msg: string; ASeverity: TCustomExceptionSeverity; ACode: Integer; ADetails, ADiagnostics, AExpression: string);
    property Severity: TCustomExceptionSeverity read FSeverity write FSeverity;
    property Code: Integer read FCode write FCode;
    property Details: string read FDetails write FDetails;
    property Diagnostics: string read FDiagnostics write FDiagnostics;
    property Expression: string read FExpression write FExpression;
  end;

implementation

uses
  MVCFramework.Logger, System.StrUtils, System.Classes, Winapi.ActiveX,
  System.IOUtils, CAPICOM_TLB, System.JSON;

procedure TVerifyController.Index;
begin
  ContentType := TMVCMediaType.TEXT_PLAIN;
  Render('Signature verification service using capicom');
end;

procedure TVerifyController.OnAfterAction(Context: TWebContext; const AActionName: string);
begin
  { Executed after each action }
  inherited;
end;

procedure TVerifyController.OnBeforeAction(Context: TWebContext; const AActionName: string; var Handled: Boolean);
begin
   {
  if Context.Request.Headers['api-key'] = '' then
    Handled := True
  else
    raise Exception.Create('403 Forbien');
  }
  inherited;
end;

procedure TVerifyController.Verify(CTX: TWebContext);
var
  lFile: TFileStream;
  numberContent: Integer;
  numberSignature: Integer;
  fileNameContent: string;
  fileNameSignature: string;
  i: Integer;
  streamContent, streamSignature: TFileStream;
  oSignedData: CAPICOM_TLB.ISignedData;
  content: WideString;
  signedMessage: WideString;
  lJObj: TJSONObject;
  lJObj1: TJSONObject;
  responseJson: string;
  uploadFolder: string;

begin
  //Путь для загрузки файлов.
  uploadFolder := TPath.Combine(AppPath, 'uploads');

  //Если папки нет, создаем.
  if not DirectoryExists(uploadFolder) then
    TDirectory.CreateDirectory(uploadFolder);

  numberContent := 0;
  numberSignature := 0;

  fileNameContent := '';
  fileNameSignature := '';

  //Проверяем наличие файлов
  for i := 0 to CTX.Request.RawWebRequest.Files.Count - 1 do
  begin
    if string(CTX.Request.Files[i].FieldName) = 'signature_file' then
    begin
      numberSignature := i;
      fileNameSignature := string(CTX.Request.Files[i].FileName);
    end;

    if (string(CTX.Request.Files[i].FieldName) = 'content_file') then
    begin
      numberContent := i;
      fileNameContent := string(CTX.Request.Files[i].FileName);
    end;
  end;

  if (fileNameContent <> '') and (fileNameSignature <> '') then
  begin

    //Сохраняем файлы
    lFile := TFile.Create(TPath.Combine(uploadFolder, fileNameContent));
    try
      lFile.CopyFrom(CTX.Request.Files[numberContent].Stream, 0);
    finally
      lFile.free;
    end;

    lFile := TFile.Create(TPath.Combine(uploadFolder, fileNameSignature));
    try
      lFile.CopyFrom(CTX.Request.Files[numberSignature].Stream, 0);
    finally
      lFile.free;
    end;

    streamContent := TFileStream.Create(TPath.Combine(uploadFolder, fileNameContent), fmOpenRead or fmShareDenyWrite);
    try
      Pointer(content) := SysAllocStringByteLen(nil, streamContent.Size);
      streamContent.ReadBuffer(Pointer(content)^, streamContent.Size);
    finally
      FreeAndNil(streamContent);
    end;

    streamSignature := TFileStream.Create(TPath.Combine(uploadFolder, fileNameSignature), fmOpenRead or fmShareDenyWrite);
    try
      Pointer(signedMessage) := SysAllocStringByteLen(nil, streamSignature.Size);
      streamSignature.ReadBuffer(Pointer(signedMessage)^, streamSignature.Size);
    finally
      FreeAndNil(streamSignature);
    end;

    //Удаляем файлы
    DeleteFile(TPath.Combine(uploadFolder, fileNameContent));
    DeleteFile(TPath.Combine(uploadFolder, fileNameSignature));

    CoInitializeEx(NIL, COINIT_MULTITHREADED);

    //Проверяем с помощью Capicom Verify
    //Должны быть установлены корневые сертификаты https://goskey.ru/certificates/
    oSignedData := CoSignedData.Create;
    oSignedData.Content := content;
    try
      //Подпись отделная // False совмещенная.
      oSignedData.Verify(signedMessage, True, CAPICOM_VERIFY_SIGNATURE_AND_CERTIFICATE);
      //Информация по сертификату.
      lJObj1 := TJSONObject.Create;
      try
        lJObj1.AddPair('SubjectName', oSignedData.Signers.Item[1].Certificate.SubjectName);
        lJObj1.AddPair('IssuerName', oSignedData.Signers.Item[1].Certificate.IssuerName);
        lJObj1.AddPair('SerialNumber', oSignedData.Signers.Item[1].Certificate.SerialNumber);
        lJObj1.AddPair('Thumbprint', oSignedData.Signers.Item[1].Certificate.Thumbprint);
        lJObj1.AddPair('ValidFromDate', oSignedData.Signers.Item[1].Certificate.ValidFromDate);
        lJObj1.AddPair('ValidToDate', oSignedData.Signers.Item[1].Certificate.ValidToDate);
        lJObj1.AddPair('Version', oSignedData.Signers.Item[1].Certificate.Version);
        for i := 1 to oSignedData.Signers.Item[1].AuthenticatedAttributes.Count do
        begin
          lJObj1.AddPair('SigningTime', oSignedData.Signers.Item[1].AuthenticatedAttributes[i].Value);
        end;

        responseJson := lJObj1.ToString;
      finally
        lJObj1.Free;
      end;

      lJObj := TJSONObject.Create;
      try
        lJObj.AddPair('Verify', TJSONBool.Create(True));
        lJObj.AddPair('Certificate', TJSONObject.ParseJSONValue(responseJson));
        responseJson := lJObj.ToString;
      finally
        lJObj.Free;
      end;
      CoUninitialize;
    except
      on E: Exception do
      begin
        lJObj := TJSONObject.Create;
        try
          lJObj.AddPair('Verify', TJSONBool.Create(False));
          lJObj.AddPair('Error', E.Message);
          responseJson := lJObj.ToString;
          ResponseStatus(200);
        finally
          lJObj.Free;
        end;
      end;
    end;
  end
  else
  begin
    lJObj := TJSONObject.Create;
    try
      lJObj.AddPair('Verify', TJSONBool.Create(False));
      lJObj.AddPair('Error', 'Отсутсвуют обязательные файлы');
      lJObj.AddPair('CountFiles',IntToStr(CTX.Request.RawWebRequest.Files.Count));
      responseJson := lJObj.ToString;
      ResponseStatus(400);
    finally
      lJObj.Free;
    end;
  end;

  Render(responseJson);
end;

constructor ECustomException.Create(Msg: string; ASeverity: TCustomExceptionSeverity; ACode: Integer; ADetails, ADiagnostics, AExpression: string);
begin
  inherited Create(Msg);
  FSeverity := ASeverity;
  FCode := ACode;
  FDetails := ADetails;
  FDiagnostics := ADiagnostics;
  FExpression := AExpression;
end;

end.

