# ThXmlRpc 0.1
==============
Basic Server for Web Service on the XML-RPC protocol.

Implemented in Free Pascal. Only has support for the types: int, double, Boolean, and string. No structured data types are supported.

To implement a XML-RPC server, only it's needed to include the unit ThXmlRpc.

Sample code:

```
program server;
{$mode objfpc}{$H+}
uses
  SysUtils, ThXmlRpc;

procedure Hello(params: TthXmlRpcParams; response: TthXmlRpcResult);
begin
  if (params.Count<>1) or (params[0].rpcTyp<>xmlRpcString) then
  begin
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
```
