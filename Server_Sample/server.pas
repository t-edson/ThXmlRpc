program server;

{$mode objfpc}{$H+}
uses
  SysUtils, ThXmlRpc ;

procedure Hello(params: TthXmlRpcParams; response: TthXmlRpcResult);
begin
  if (params.Count<>1) or (params[0].rpcTyp<>xmlRpcString) then begin
    writeln('Parameters error.');
    exit;
  end;
  response.valStr := 'Hi ' + params[0].valStr + '!';
end;

var
  Serv: TthXmlRpcServer;

begin
  RegisterFunction('Hello', @Hello);
  writeln('Listening...');
  Serv := TthXmlRpcServer.Create(nil);
  try
    Serv.Port:=1234;
    Serv.Active:=true;
  finally
    Serv.Free;
  end;
  ReadLn;
end.
