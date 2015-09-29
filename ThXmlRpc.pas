{Unit ThXmlRpc
 Implement the class TthXmlRpcServer, that is a basic Web Service provider for the
 XML-RPC protocol.

}
unit ThXmlRpc;
{$mode objfpc}{$H+}
interface
uses
  Classes, SysUtils, XMLRead, DOM,
  fphttpserver, fgl, HttpDefs;

type
  // Tipos estándar del XML-RPC. No se implementan todos por ahora.
  tXmlRpcDataType = (
    xmlRpcString,
    xmlRpcInt,
    xmlRpcBoolean,
    xmlRpcDouble
  );

  TthXmlRpcValue = class
  private
    FvalBool: boolean;
    FvalDouble: double;
    FvalStr: string;
    FvalInt: integer;
  private
    procedure SetvalBool(AValue: boolean);
    procedure SetvalDouble(AValue: double);
    procedure SetvalInt(AValue: integer);
    procedure SetvalStr(AValue: string);
  public
    rpcTyp: tXmlRpcDataType;
    property valStr: string read FvalStr write SetvalStr;
    property valInt: integer read FvalInt write SetvalInt;
    property valBool: boolean read FvalBool write SetvalBool;
    property valDouble: double read FvalDouble write SetvalDouble;
  end;

  //Objeto que representa a un parámetro
  TthXmlRpcParam = class(TthXmlRpcValue)
  public
    name: string;  //not used
  end;
  TthXmlRpcParamList = specialize TFPGObjectList<TthXmlRpcParam>;

  { TthXmlRpcParams }
  // Objeto usado para el almacenamiento de los parámetros
  TthXmlRpcParams = class
  private
    items: TthXmlRpcParamList;
    function GetItem(Index: Integer): TthXmlRpcParam;
    procedure ReadParams(nod: TDOMNode);
  public
    function Count: integer;
    property Item[Index: Integer]: TthXmlRpcParam read GetItem; default;
    constructor Create;
    destructor Destroy; override;
  end;

  { TthXmlRpcResult }
  TthXmlRpcResult = class(TthXmlRpcValue)
  private
    function GetXml: string;
  public
    constructor Create;
  end;

type
  EThXmlRpc = class(Exception);

  TthXmlRpcFunctionProc = procedure(params: TthXmlRpcParams; response: TthXmlRpcResult);

  // Objeto para almacenar las funciones registradas
  TthXmlRpcFunction = class
    name: string;
    proc: TthXmlRpcFunctionProc;
  end;

  // Lista de funciones registradas
  TthXmlRpcFunctions = specialize TFPGObjectList<TthXmlRpcFunction>;

  // Servidor Web usado para recibir las peticiones de Web Service
  TthXmlRpcServer = class(TFPHttpServer)
    procedure HandleRequest(var ARequest: TFPHTTPConnectionRequest; var AResponse: TFPHTTPConnectionResponse);
      override;
  end;

var
  XmlRpcFunctions : TthXmlRpcFunctions;

procedure RegisterFunction(funName: string; funProc: TthXmlRpcFunctionProc);

implementation

{ TthXmlRpcResult }
procedure TthXmlRpcValue.SetvalInt(AValue: integer);
begin
  FvalInt:=AValue;
  rpcTyp := xmlRpcInt;
end;
procedure TthXmlRpcValue.SetvalStr(AValue: string);
begin
  FvalStr:=AValue;
  rpcTyp:=xmlRpcString;
end;
procedure TthXmlRpcValue.SetvalBool(AValue: boolean);
begin
  FvalBool:=AValue;
  rpcTyp:=xmlRpcBoolean;
end;
procedure TthXmlRpcValue.SetvalDouble(AValue: double);
begin
  FvalDouble:=AValue;
  rpcTyp:=xmlRpcDouble;
end;

{ TthXmlRpcResult }
function TthXmlRpcResult.GetXml: string;
begin
  Result := '<?xml version=''1.0''?>' + LineEnding;
  Result += '<methodResponse>' + LineEnding;
  Result += ' <params>' + LineEnding;
  Result += '  <param>';
  //escribe tipo
  case rpcTyp of
  xmlRpcString: begin
    Result += '  <value><string>' + FvalStr +'</string></value>';
  end;
  xmlRpcInt: begin
    Result += '  <value><int>' + IntToStr(FvalInt) +'</int></value>';
  end;
  xmlRpcBoolean: begin
    if FvalBool then
      Result += '  <value><boolean>1</boolean></value>'
    else
      Result += '  <value><boolean>0</boolean></value>';
  end;
  xmlRpcDouble: begin
    Result += '  <value><double>' + FloatToStr(FvalDouble) +'</double></value>';
  end;
  else
    Result += '  <value><string>--ThXmlRpc:error--</string></value>';
  end;
  Result += '  </param>' + LineEnding;
  Result += ' </params>'+ LineEnding;
  Result += '</methodResponse>';
end;

constructor TthXmlRpcResult.Create;
begin
  rpcTyp := xmlRpcInt;  //entero por defecto
end;

{ TthXmlRpcParams }
procedure TthXmlRpcParams.ReadParams(nod: TDOMNode);
var
  nod2: TDOMNode;
  par: TthXmlRpcParam;
  nodTyp: TDOMNode;
  n: Integer;
  d: Extended;
  b: Boolean;
begin
  if nod.NodeName<>'param' then begin
    raise EThXmlRpc.Create('bad XML-RPC structure.');
  end;
  nod2 := nod.ChildNodes[0];
  if nod2.NodeName<>'value' then begin
    raise EThXmlRpc.Create('bad XML-RPC structure.');
  end;
  nodTyp := nod2.ChildNodes[0];
  // Agrega parámetro
  case nodTyp.NodeName of
  'string': begin
    par := TthXmlRpcParam.Create;  //lo crea aquí, para no tener que destruirlo, en caso de error
    par.valStr:=nodTyp.TextContent;  //fija tipo implícitamente
    items.Add(par);   //agrega parámetro
  end;
  'int': begin
    n := StrToInt(nodTyp.TextContent);
    par := TthXmlRpcParam.Create;  //lo crea aquí, para no tener que destruirlo, en caso de error
    par.valInt:=n;  //fija tipo implícitamente
    items.Add(par);   //agrega parámetro
  end;
  'double': begin
    d := StrToFloat(nodTyp.TextContent);
    par := TthXmlRpcParam.Create;  //lo crea aquí, para no tener que destruirlo, en caso de error
    par.valDouble:=d;  //fija tipo implícitamente
    items.Add(par);   //agrega parámetro
  end;
  'Boolean': begin
    b := trim(nodTyp.TextContent) = '1';
    par := TthXmlRpcParam.Create;  //lo crea aquí, para no tener que destruirlo, en caso de error
    par.valBool:=b;  //fija tipo implícitamente
    items.Add(par);   //agrega parámetro
  end;
  else
    raise EThXmlRpc.Create('Unsupported Data type.');
  end;
end;

function TthXmlRpcParams.GetItem(Index: Integer): TthXmlRpcParam;
begin
  Result := items[Index];
end;

function TthXmlRpcParams.Count: integer;
begin
  Result := items.Count;
end;

constructor TthXmlRpcParams.Create;
begin
  items:= TthXmlRpcParamList.Create(true);

end;

destructor TthXmlRpcParams.Destroy;
begin
  items.Destroy;
  inherited Destroy;
end;

procedure DecodeXML(xmlStr: string; var funName: string; funParams: TthXmlRpcParams);

var
  nod: TDOMNode;
  doc: TXMLDocument;
  st: TStringStream;
  i: Integer;
  nod2: TDOMNode;
begin
  st := TStringStream.Create(xmlStr);
  try
    ReadXMLFile(Doc, st);
    //Verifica contenido
    if doc.FirstChild.NodeName <> 'methodCall' then begin
      raise EThXmlRpc.Create('XML is not a XML-RPC call.');
    end;
    //busca "methodName"
    nod := Doc.DocumentElement.FindNode('methodName');
    if nod = nil then begin
      raise EThXmlRpc.Create('bad XML-RPC structure.');
    end;
    funName := nod.TextContent;   //devuelve nombre
//    funName := trim(funName);
    nod := Doc.DocumentElement.FindNode('params');
    if nod = nil then begin
      raise EThXmlRpc.Create('bad XML-RPC structure.');
    end;
    //construye objeto de parámetros
    funParams.items.Clear;
    for i := 0 to nod.ChildNodes.Count-1 do begin
      nod2 := nod.ChildNodes[i];
      //hay un parámetro
      funParams.ReadParams(nod2);
    end;
    doc.Free;  //libera
  except
    on e: Exception do begin
      //completa el mensaje
//      WriteLn('!!!ERROR: ' + e.Message);
      doc.Free;
      raise   //genera de nuevo
    end;
  end;
end;

procedure RegisterFunction(funName: string; funProc: TthXmlRpcFunctionProc);
var
  r: TthXmlRpcFunction;
  n: Integer;
begin
  r := TthXmlRpcFunction.Create;
  r.name:=funName;
  r.proc:=funProc;
  XmlRpcFunctions.Add(r);
end;

function FindFunction(funName: string): TthXmlRpcFunction;
var
  fun : TthXmlRpcFunction;
begin
  for fun in XmlRpcFunctions do begin
    if fun.name = funName then begin
       exit(fun);
    end;
  end;
  Result := nil;
end;

procedure TthXmlRpcServer.HandleRequest(var ARequest: TFPHTTPConnectionRequest;
var AResponse: TFPHTTPConnectionResponse);
var
  funName: string;
  funParams: TthXmlRpcParams;
  funResult: TthXmlRpcResult;
  f : TthXmlRpcFunction;
begin
  try
//    writeln(ARequest.Content);
    funParams := TthXmlRpcParams.Create;
    funResult := TthXmlRpcResult.Create;

    DecodeXML(ARequest.Content, funName, funParams);
    f := FindFunction(funName);
    if f = nil then begin
      exit;  //no existe
    end;
    //llama a la función apropiada
    f.proc(funParams, funResult);
    // Debe devolver la respuesta
    AResponse.Content := funResult.GetXml;
//    writeln(AResponse.Content);
//    AResponse.Code := 200;
  except
    on E: Exception do begin
      AResponse.CodeText := E.Message;
      AResponse.Code := 400;
    end;
  end;
  funResult.Destroy;
  funParams.Destroy;
end;

initialization
  XmlRpcFunctions := TthXmlRpcFunctions.Create(true);

finalization
  XmlRpcFunctions.Destroy;

end.

