unit echo;
{$MODE DELPHI}
//{$mode objfpc}{$H+}
{$LONGSTRINGS ON}
interface

uses
  Classes, blcksock, synsock,logs,protocol in 'procotcol.pas',strutils,SysUtils;

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
    LOGS.logs('artica-filter:: TTCPSMTPDaemon:: Initialize thread....');
      sock.CreateSocket;
      sock.setLinger(true,10);
      sock.EnableReuse(true);
      sock.bind('127.0.0.1','29900');
      if sock.lastError>0 then begin
         LOGS.logs('artica-filter:: TTCPSMTPDaemon:: Error ' + IntToStr(sock.lastError) + ' ' + sock.LastErrorDesc);

         repeat
         sock.CloseSocket;
         Select(0,nil,nil,nil,10*10000);
         sock.CreateSocket;
         sock.setLinger(true,10);
         sock.bind('127.0.0.1','29900');
         if sock.lastError>0 then LOGS.logs('TTCPSMTPDaemon:: Error ' + IntToStr(sock.lastError) + ' ' + sock.LastErrorDesc + ' retry bind. until the system has release the socket');
         until sock.lastError=0;
      end;

      LOGS.logs('artica-filter:: TTCPSMTPDaemon:: listen 127.0.0.1 port 29900');
      sock.listen;
      repeat
        if terminated then break;

        if sock.canread(1000) then begin
           LOGS.logs('artica-filter:: TTCPSMTPDaemon:: purge...');
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

    LOGS.logs('artica-filter:: TTCPSMTPDaemon:: finishing thread....');
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
            CR = #$0d;
            LF = #$0a;
            CRLF = CR + LF;
var
       s: string;
       LOGS:TLOgs;
       ptcol:Tprotocol;
       StringToSend:string;
begin

  LOGS:=TLogs.Create;
  ptcol:=Tprotocol.Create;
  ptcol.RECEIVE_DATA:=false;
  ptcol.RECEIVE_QUIT:=false;
  sock:=TTCPBlockSocket.create;


  try
    Sock.socket:=CSock;
    Sock.GetSins;

    LOGS.logs('artica-filter:: TTCPSMTPThrd:: GetRemoteSinIP:: ' + sock.GetRemoteSinIP);
    sock.SendString('220 artica-filter.localhost ESMTP Service ready'+CRLF);
    with sock do
      begin
        repeat
          if terminated then break;
          s := RecvPacket(60000);

          if lastError<>0 then begin
             LOGS.logs('TTCPSMTPThrd:: [' + GetRemoteSinIP + '] Error number ' + IntToStr(lastError) + ' ' + LastErrorDesc);
             break;
          end;


        if ptcol.RECEIVE_DATA=true then begin
              MssgCount:=MssgCount+1;
              //LOGS.logs('TTCPSMTPThrd::' + IntToStr(MssgCount) + ' (RECEIVE_DATA) [' + GetRemoteSinIP + '] receive ' + IntToStr(sock.SizeRecvBuffer) + ' bytes');

              StringToSend:=ptcol.ParseDatas(s);

              if length(StringToSend)>0 then begin
                 //LOGS.logs('TTCPSMTPThrd:: [' + GetRemoteSinIP + '] Send ' + trim(StringToSend));
                 SendString(StringToSend);
              end;

              if ptcol.RECEIVE_QUIT=true then begin
                 LOGS.logs('artica-filter:: TTCPSMTPThrd:: [' + GetRemoteSinIP + '] Receive QUIT....Send Bye..');
                 SendString('221 2.0.0 Bye'+CRLF);
                 break;
              end;

          end else begin
              StringToSend:=ptcol.ParseProtocol(s);
              if length(StringToSend)>0 then begin
                 SendString(StringToSend);
              end;


              if ptcol.RECEIVE_QUIT=true then begin
                 LOGS.logs('artica-filter:: TTCPSMTPThrd:: [' + GetRemoteSinIP + '] Receive QUIT....Send Bye..');
                 SendString('221 2.0.0 Bye'+CRLF);
                 break;
              end;


          end;



          if lastError<>0 then break;
        until false;
      end;
  finally
   LOGS.logs('artica-filter:: TTCPSMTPThrd:: free sockets...');
   sock.SizeRecvBuffer:=2000;
   sock.CloseSocket;
   FreeAndNil(sock);
   FreeAndNil(ptcol);
 //  LOGS.logs('TTCPSMTPThrd:: free classes...');

  end;
end;

end.

