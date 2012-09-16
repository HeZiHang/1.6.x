unit PolicySocket;
{$MODE DELPHI}
//{$mode objfpc}{$H+}
{$LONGSTRINGS ON}
interface

uses
  Classes, blcksock, synsock,logs,strutils,SysUtils,filter;

type
  TTCPEchoDaemon = class(TThread)
  private
    Sock:TTCPBlockSocket;
  public
    Constructor Create;
    Destructor Destroy; override;
    procedure Execute; override;
  end;

  TTCPEchoThrd = class(TThread)
  private
    Sock:TTCPBlockSocket;
    CSock: TSocket;
    MssgCount:longint;
  public
    Constructor Create (hsock:tSocket);
    procedure Execute; override;
  end;

implementation

{ TEchoDaemon }

Constructor TTCPEchoDaemon.Create;
begin
  sock:=TTCPBlockSocket.create;
  FreeOnTerminate:=true;
  inherited create(false);
end;

Destructor TTCPEchoDaemon.Destroy;
begin
  Sock.free;
end;

procedure TTCPEchoDaemon.Execute;
var
  ClientSock:TSocket;
  LOGS:TLOgs;
  TCPEchoThrd:TTCPEchoThrd;
begin
     LOGS:=TLogs.Create;
     LOGS.logs('artica-policy:: PolicySocket:: Initialize thread....');

      sock.CreateSocket;
      sock.setLinger(true,10);
      sock.EnableReuse(true);
      sock.bind('127.0.0.1','29001');
      if sock.lastError>0 then begin
         LOGS.logs('artica-policy:: PolicySocket:: ' + IntToStr(sock.lastError) + ' ' + sock.LastErrorDesc);

         repeat
         sock.CloseSocket;
         Select(0,nil,nil,nil,10*10000);
         sock.CreateSocket;
         sock.setLinger(true,10);
         sock.bind('127.0.0.1','29001');
         if sock.lastError>0 then LOGS.logs('artica-policy:: PolicySocket:: Error ' + IntToStr(sock.lastError) + ' ' + sock.LastErrorDesc + ' retry bind. until the system has release the socket');
         until sock.lastError=0;
      end;

      LOGS.logs('artica-policy:: PolicySocket:: listen 127.0.0.1 port 29900');
      sock.listen;
      repeat
        if terminated then break;

        if sock.canread(1000) then begin
           LOGS.logs('artica-policy:: PolicySocket:: purge...');
            sock.Purge;
            sock.SizeRecvBuffer:=2000;
            sock.SizeSendBuffer:=2000;
            ClientSock:=sock.Accept;
            if sock.lastError=0 then TCPEchoThrd:=TTCPEchoThrd.create(ClientSock);

          end;
      sock.Purge;
      sock.SizeRecvBuffer:=2000;
      sock.SizeSendBuffer:=2000;

      until false;

    LOGS.logs('artica-policy:: PolicySocket:: finishing thread....');
    LOGS.Free;
end;

{ TEchoThrd }

Constructor TTCPEchoThrd.Create(Hsock:TSocket);
begin
  Csock := Hsock;
  FreeOnTerminate:=true;
  inherited create(false);
end;

procedure TTCPEchoThrd.Execute;
         const
            CRLF = #$0D + #$0A;
var
       s: string;
       response:string;
       LOGS:TLOgs;
       StringToSend:string;
       xfilter:Tfilter;
begin

  LOGS:=TLogs.Create;
  sock:=TTCPBlockSocket.create;
  xfilter:=TFilter.Create;

  try
    Sock.socket:=CSock;
    Sock.GetSins;

    LOGS.logs('artica-policy:: TTCPSMTPThrd:: GetRemoteSinIP:: ' + sock.GetRemoteSinIP);
    //sock.SendString(CRLF);
    with sock do
      begin
        repeat
          if terminated then break;
          s := RecvPacket(60000);

          if lastError<>0 then begin
             LOGS.logs('artica-policy:: PolicySocketThread::[' + GetRemoteSinIP + '] Error number ' + IntToStr(lastError) + ' ' + LastErrorDesc);
             break;
          end;
          TRY
             response:=xfilter.ParseLines(s);
             sock.SendString(response);
          EXCEPT
             LOGS.logs('artica-policy:: PolicySocketThread::FATAL ERROR');
             break;
          end;
          

          if lastError<>0 then break;
        until false;
      end;
  finally
   LOGS.logs('artica-policy:: PolicySocketThread::free sockets...');
   sock.SizeRecvBuffer:=2000;
   sock.CloseSocket;
   FreeAndNil(sock);
   LOGS.logs('artica-policy:: PolicySocketThread::free classes...');

  end;
end;

end.

