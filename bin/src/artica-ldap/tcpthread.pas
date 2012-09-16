unit tcpthread;

{$mode objfpc}{$H+}

interface

uses
  Classes,echo,logs,oldlinux,SysUtils;
type
  ttcpthread = class(TThread)
  private

  protected
    procedure Execute; override;
    procedure LaunchEcho;


  public

  end;

implementation

procedure ttcpthread.Execute;
var LOGS:Tlogs;
count:integer;
ECHO:TTCPEchoDaemon;
begin
        LOGS:=Tlogs.Create;
  while not terminated do begin
        logs.logs('ttcpthread:: ->LaunchEcho');
        LaunchEcho;
        logs.logs('ttcpthread:: ->restart');
        Select(0,nil,nil,nil,10*500);
  end;

end;

procedure ttcpthread.LaunchEcho;
var LOGS:Tlogs;
count:integer;
ECHO:TTCPEchoDaemon;
begin
 LOGS:=Tlogs.Create;
   logs.logs('LaunchEcho:: Execute create socket daemon');
    count:=0;
   TRY
   ECHO:=TTCPEchoDaemon.Create;
   EXCEPT
   logs.logs('LaunchEcho:: Error while execute TTCPEchoDaemon');
   end;
   LOGS:=Tlogs.Create;

  while not ECHO.terminated do begin
      if terminated then break;
      Select(0,nil,nil,nil,10*500);
      if fileExists('/etc/terminateecho') then begin
         shell('/bin/rm /etc/terminateecho');
         ECHO.Terminate;
      end;
   end;

   logs.logs('LaunchEcho:: TERMINTATED SMTP ECHO thread');
   logs.free;
  end;


end.


