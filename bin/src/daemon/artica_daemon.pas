program artica_daemon;

uses
  cthreads,libc,linux,BaseUnix,unix,Dos,Classes,SysUtils, logs,Process,RegExpr,
  DaemonThread1,dateutils,zSystem;

var
 myFile         :TextFile;
 pid            :Tpid;
 zlogs          :Tlogs;
 thread1        :TSampleThread;



function IsRoot():boolean;
begin
if FpGetEUid=0 then exit(true);
exit(false);
end;

//##############################################################################
procedure daemon;
var
   debug:string;
   D:boolean;
   Beetwen:integer;
   SYS:Tsystem;
begin
D:=false;
debug:='';
zlogs:=Tlogs.Create;
SYS:=Tsystem.Create;

if SYS.PROCESS_EXIST(sys.GET_PID_FROM_PATH('/etc/artica-postfix/artica-agent.pid')) then begin
    zlogs.Debuglogs('daemon process already exists...aborting');
    halt(0);
end;

if FileExists('/etc/artica-postfix/artica-agent.pid') then zlogs.DeleteFile('/etc/artica-postfix/artica-agent.pid');

TRY

      if length(ParamStr(1))>0 then begin
         writeln('No command lines here...');
         halt(0);
      end;
      
      ForceDirectories('/etc/artica-postfix');
      AssignFile(myFile, '/etc/artica-postfix/artica-agent.pid');
      ReWrite(myFile);
      WriteLn(myFile, intTostr(fpgetpid));
      zlogs.Debuglogs('daemon():: starting PID '+intTostr(fpgetpid));
      CloseFile(myFile);
      zlogs.Debuglogs('daemon():: artica-postfix daemon..SavePid-> writing /etc/artica-postfix/artica-agent.pid pid=' + IntTostr(fpgetpid));
      EXCEPT
      zlogs.Debuglogs('daemon()::artica-postfix daemon..SavePid-> fatal error writing /etc/artica-postfix/artica-agent.pid');

      END;
sys.set_INFOS('MysqlTooManyConnections','0');
 

 

 
 zlogs.Syslogs('Starting artica-postfix daemon pid ' + IntTostr(fpgetpid));
 zlogs.DeleteFile('/etc/artica-postfix/startall');
 
 zlogs.Debuglogs('Starting......: Thread1');
 thread1 := TSampleThread.Create(false, 1);
 zlogs.Debuglogs('daemon()::Daemon successfull started with new PID '+intTostr(fpgetpid)+' --> Starting loop');

 while (true) do begin
    if FileExists('/etc/artica-postfix/autokill') then fpsystem('/bin/rm /etc/artica-postfix/autokill');
    Beetwen:=SYS.FILE_TIME_BETWEEN_MIN('/etc/artica-postfix/artica-agent.pid');
    zlogs.Debuglogs('master daemon:: NOOP ('+ IntToStr(Beetwen)+') mn uptime...');
    sleep(10000);
    if Beetwen>80 then begin
         zlogs.Syslogs('Refresh artica-postfix main daemon');
         fpsystem('/etc/init.d/artica-postfix restart daemon &');
         halt(0);
     end;
    
  end;


  
zlogs.Debuglogs('daemon --> Terminate ----------------------------');
SYS.Free;

end;
//##############################################################################
begin
 zlogs:=Tlogs.Create;
 if IsRoot()=false then begin
        writeln('This program wust run as root');
        halt(0);
    end;
  if FileExists('/etc/artica-postfix/autokill') then fpsystem('/bin/rm /etc/artica-postfix/autokill');
     pid:=fpfork;
    Case pid of
      0 : Begin { we are in the child }
         Close(input);  { close standard in }
         Close(output); { close standard out }
         Assign(output,'/dev/null');
         ReWrite(output);
         //Close(stderr); { close standard error }
         //Assign(stderr,Char('/dev/null'));
         //ReWrite(stderr);
         daemon();
      End;
      -1 : daemon();    { forking error, so run as non-daemon }
      Else Halt;          { successful fork, so parent dies }
   End;
   
   
   
end.

