unit WebModule;

interface

uses
  System.SysUtils, System.Classes, Web.HTTPApp, MVCFramework, System.JSON;

type
  TVerifyWebModule = class(TWebModule)
    procedure WebModuleCreate(Sender: TObject);
    procedure WebModuleDestroy(Sender: TObject);
  private
    FMVC: TMVCEngine;
  public
    { Public declarations }
  end;

var
  WebModuleClass: TComponentClass = TVerifyWebModule;

implementation

{$R *.dfm}

uses
  VerifyController, System.IOUtils, MVCFramework.Commons,
  MVCFramework.Middleware.ActiveRecord, MVCFramework.Middleware.StaticFiles,
  MVCFramework.Middleware.Analytics, MVCFramework.Middleware.Trace,
  MVCFramework.Middleware.CORS, MVCFramework.Middleware.ETag,
  MVCFramework.Middleware.Compression;

procedure TVerifyWebModule.WebModuleCreate(Sender: TObject);
var
  lExceptionHandler: TMVCExceptionHandlerProc;
begin
  lExceptionHandler :=
    procedure(E: Exception; SelectedController: TMVCController; WebContext: TWebContext; var ExceptionHandled: Boolean)

      procedure CreateResponse(const iErrorCode: Integer; const sErrorName: string);
      var
        jo: TJSONObject;
      begin
        WebContext.Response.StatusCode := iErrorCode;
        jo := TJSONObject.Create;
        try
          jo.AddPair('Verify', TJSONBool.Create(False));
          jo.AddPair('Error', TJSONString.Create(sErrorName));
          //jo.AddPair('Error', TJSONString.Create(IntToStr(iErrorCode) + ': ' + sErrorName));
          WebContext.Response.Content := jo.ToString;
        finally
          jo.Free
        end;
      end;


    begin

      WebContext.Response.ContentType := TMVCMediaType.APPLICATION_JSON;

      if E is ECustomException then
        CreateResponse(ECustomException(E).Code, ECustomException(E).Details)
      else if E is EMVCException then
        CreateResponse(EMVCException(E).HTTPStatusCode, E.Message)
      else
        CreateResponse(500, E.Message);

      ExceptionHandled := True;

    end;

  FMVC := TMVCEngine.Create(Self,
    procedure(Config: TMVCConfig)
    begin
      Config.dotEnv := dotEnv;
      // session timeout (0 means session cookie)
      Config[TMVCConfigKey.SessionTimeout] := dotEnv.Env('dmvc.session_timeout', '0');
      //default content-type
      Config[TMVCConfigKey.DefaultContentType] := dotEnv.Env('dmvc.default.content_type', TMVCConstants.DEFAULT_CONTENT_TYPE);
      //default content charset
      Config[TMVCConfigKey.DefaultContentCharset] := dotEnv.Env('dmvc.default.content_charset', TMVCConstants.DEFAULT_CONTENT_CHARSET);
      //unhandled actions are permitted?
      Config[TMVCConfigKey.AllowUnhandledAction] := dotEnv.Env('dmvc.allow_unhandled_actions', 'false');
      //enables or not system controllers loading (available only from localhost requests)
      Config[TMVCConfigKey.LoadSystemControllers] := dotEnv.Env('dmvc.load_system_controllers', 'true');
      //default view file extension
      Config[TMVCConfigKey.DefaultViewFileExtension] := dotEnv.Env('dmvc.default.view_file_extension', 'html');
      //view path
      Config[TMVCConfigKey.ViewPath] := dotEnv.Env('dmvc.view_path', 'templates');
      //use cache for server side views (use "false" in debug and "true" in production for faster performances
      Config[TMVCConfigKey.ViewCache] := dotEnv.Env('dmvc.view_cache', 'false');
      //Max Record Count for automatic Entities CRUD
      Config[TMVCConfigKey.MaxEntitiesRecordCount] := dotEnv.Env('dmvc.max_entities_record_count', IntToStr(TMVCConstants.MAX_RECORD_COUNT));
      //Enable Server Signature in response
      Config[TMVCConfigKey.ExposeServerSignature] := dotEnv.Env('dmvc.expose_server_signature', 'false');
      //Enable X-Powered-By Header in response
      Config[TMVCConfigKey.ExposeXPoweredBy] := dotEnv.Env('dmvc.expose_x_powered_by', 'true');
      // Max request size in bytes
      Config[TMVCConfigKey.MaxRequestSize] := dotEnv.Env('dmvc.max_request_size', IntToStr(TMVCConstants.DEFAULT_MAX_REQUEST_SIZE * 5));
    end);
  FMVC.AddController(TVerifyController);
  FMVC.SetExceptionHandler(lExceptionHandler);

  // Analytics middleware generates a csv log, useful to do traffic analysis
  //FMVC.AddMiddleware(TMVCAnalyticsMiddleware.Create(GetAnalyticsDefaultLogger));

  // The folder mapped as documentroot for TMVCStaticFilesMiddleware must exists!
  //FMVC.AddMiddleware(TMVCStaticFilesMiddleware.Create('/static', TPath.Combine(ExtractFilePath(GetModuleName(HInstance)), 'www')));

  // Trace middlewares produces a much detailed log for debug purposes
  //FMVC.AddMiddleware(TMVCTraceMiddleware.Create);

  // CORS middleware handles... well, CORS
  //FMVC.AddMiddleware(TMVCCORSMiddleware.Create);

  // Simplifies TMVCActiveRecord connection definition
  {
  FMVC.AddMiddleware(TMVCActiveRecordMiddleware.Create(
    dotEnv.Env('firedac.connection_definition_name', 'MyConnDef'),
    dotEnv.Env('firedac.connection_definitions_filename', 'FDConnectionDefs.ini')
  ));
  }

  // Compression middleware must be the last in the chain, just before the ETag, if present.
  //FMVC.AddMiddleware(TMVCCompressionMiddleware.Create);

  // ETag middleware must be the latest in the chain
  //FMVC.AddMiddleware(TMVCETagMiddleware.Create);

  {
  FMVC.OnWebContextCreate(
    procedure(const Context: TWebContext)
    begin
      // Initialize services to make them accessibile from Context
      // Context.CustomIntfObject := TMyService.Create;
    end);

  FMVC.OnWebContextDestroy(
    procedure(const Context: TWebContext)
    begin
      //Cleanup services, if needed
    end);
  }
end;

procedure TVerifyWebModule.WebModuleDestroy(Sender: TObject);
begin
  FMVC.Free;
end;

end.

