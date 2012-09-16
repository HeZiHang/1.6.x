unit postfilter;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,Process,logs,unix,
    RegExpr      in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/RegExpr.pas',
    zsystem      in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/zsystem.pas';



  type
  tpostfilter=class


private
     LOGS:Tlogs;
     SYS:TSystem;
     artica_path:string;
     verbose:boolean;
     EnablePostFilter:integer;
     INSTALLED:boolean;
     function  GET_PID():string;
     function  PID_PATH():string;



public
    procedure   Free;
    constructor Create(const zSYS:Tsystem);
    function    VERSION():string;
    procedure   START();
    procedure   RELOAD();
    procedure   STOP();
    function    STATUS():string;
    function    BIN_PATH():string;
    procedure   REMOVE();
END;

implementation

constructor tpostfilter.Create(const zSYS:Tsystem);
begin
       forcedirectories('/etc/artica-postfix');
       verbose:=SYS.COMMANDLINE_PARAMETERS('--verbose');
       LOGS:=tlogs.Create();
       SYS:=zSYS;
       INSTALLED:=false;

       if FileExists('/usr/share/postfilter/sbin/postfilterd') then INSTALLED:=true;

       if not TryStrToInt(SYS.GET_INFO('EnablePostFilter'),EnablePostFilter) then EnablePostFilter:=1;
       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;
end;
//##############################################################################
procedure tpostfilter.free();
begin
    logs.Free;

end;
//##############################################################################
function tpostfilter.PID_PATH():string;
begin
if not INSTALLED then exit;
if FIleExists('/var/run/postfilter/postfilterd.pid') then exit('/var/run/postfilter/postfilterd.pid');
end;
//##############################################################################
function tpostfilter.BIN_PATH():string;
begin
if not INSTALLED then exit;
if FIleExists('/usr/share/postfilter/sbin/postfilterd') then exit('/usr/share/postfilter/sbin/postfilterd');
end;
//##############################################################################
function tpostfilter.GET_PID():string;
var
   xpid_path:string;
   pid:string;
begin
    if not INSTALLED then exit;
    xpid_path:=PID_PATH();
    pid:=SYS.GET_PID_FROM_PATH(xpid_path);

   if not SYS.PROCESS_EXIST(pid) then begin
       if verbose then logs.Debuglogs('GET_PID: '+pid+' failed');
      result:=SYS.PIDOF(BIN_PATH());
      if verbose then logs.Debuglogs('GET_PID: pidof='+pid);
   end else begin
       result:=pid;
   end;
end;
//##############################################################################
function tpostfilter.VERSION():string;
var
    RegExpr:TRegExpr;
    FileDatas:TStringList;
    i:integer;
    filetmp:string;
begin
if not INSTALLED then exit;

result:=SYS.GET_CACHE_VERSION('APP_POSTFILTER');
if length(result)>0 then exit;

    filetmp:=ExtractFilePath(BIN_PATH())+'postfilter.cgi.pl';
    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='my \$version.+?([0-9\.]+)';
    FileDatas:=TStringList.Create;
    FileDatas.LoadFromFile(filetmp);
    logs.DeleteFile(filetmp);
    for i:=0 to FileDatas.Count-1 do begin
        if RegExpr.Exec(FileDatas.Strings[i]) then begin
             result:=RegExpr.Match[1];
             break;
        end;
    end;
             RegExpr.free;
             FileDatas.Free;
             SYS.SET_CACHE_VERSION('APP_POSTFILTER',result);

end;
//#############################################################################
procedure tpostfilter.REMOVE();
begin
STOP();
if DirectoryExists('/usr/share/postfilter') then fpsystem('/bin/rm -rf /usr/share/postfilter');
if DirectoryExists('/etc/postfilter') then fpsystem('/bin/rm -rf /etc/postfilter');
logs.DeleteFile('/etc/artica-postfix/versions.cache');
fpsystem('/usr/share/artica-postfix/bin/artica-install --write-versions');
fpsystem('/usr/share/artica-postfix/bin/process1 --force');
end;
//##############################################################################
procedure tpostfilter.RELOAD();
var
   pid:string;
begin
pid:=GET_PID();
if not  SYS.PROCESS_EXIST(pid) then begin
   START();
   exit;
end;
fpsystem(SYS.LOCATE_PERL_BIN()+' /usr/share/artica-postfix/exec.postfilter.php');
fpsystem(BIN_PATH()+' reload');
end;

//#############################################################################
function tpostfilter.STATUS():string;
var ini:TstringList;
pid:string;
begin
ini:=TstringList.Create;
 if INSTALLED then begin
   pid:=GET_PID();
   ini.Add('[APP_POSTFILTER]');
   if SYS.PROCESS_EXIST(pid) then ini.Add('running=1') else  ini.Add('running=0');
   ini.Add('application_installed=1');
   ini.Add('master_pid='+ pid);
   ini.Add('master_memory=' + IntToStr(SYS.PROCESS_MEMORY(pid)));
   ini.Add('master_version=' + VERSION());
   ini.Add('status='+SYS.PROCESS_STATUS(pid));
   ini.Add('service_name=APP_POSTFILTER');
   ini.Add('service_cmd=postfilter');
   ini.Add('service_disabled='+IntToStr(EnablePostFilter));
   ini.Add('remove_cmd=--postfilter-remove');
   ini.add('');
 end;

   result:=ini.Text;
   ini.free;

end;
//#########################################################################################
procedure tpostfilter.START();
var
   cmd:string;
   pid:string;
   count:integer;
begin


if not INSTALLED then begin
   logs.Debuglogs('Starting......: PostFilter server is not installed');
   exit;
end;

if EnablePostFilter=0 then begin
   STOP();
   exit;
end;

pid:=GET_PID();
if SYS.PROCESS_EXIST(pid) then begin
    logs.Debuglogs('Starting......: PostFilter server is already running pid '+pid);
    exit;
end;

logs.Debuglogs('Starting......: PostFilter server Deamon');
fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.postfilter.php');

cmd:=BIN_PATH()+' start';

logs.OutputCmd(cmd);
pid:=GET_PID();
count:=0;
  while not SYS.PROCESS_EXIST(pid) do begin
              sleep(100);
              inc(count);
              if count>10 then begin
                 logs.DebugLogs('Starting......: PostFilter server daemon (timeout!!!)');
                 break;
              end;

              pid:=GET_PID();
        end;


pid:=GET_PID();

    if not SYS.PROCESS_EXIST(pid) then begin

         logs.DebugLogs('Starting......: PostFilter server daemon (failed!!!)');
    end else begin

         logs.DebugLogs('Starting......: PostFilter server Success with new PID '+pid);
    end;
end;
//#############################################################################
procedure tpostfilter.STOP();
var
   pid:string;
   count:integer;
begin

if not INSTALLED then begin
   writeln('Stopping PostFilter......: Not Installed');
   exit;
end;
pid:=GET_PID();

if sys.PROCESS_EXIST(pid) then begin
   writeln('Stopping PostFilter......: Daemon PID '+pid);
   fpsystem(BIN_PATH()+' stop');
   count:=0;
   while SYS.PROCESS_EXIST(pid) do begin
      sleep(500);
      inc(count);
       if count>50 then begin
           writeln('Stopping PostFilter......: Timeout while force stopping Daemon pid:'+pid);
            fpsystem('/bin/kill -9 '+pid);
            break;
       end;
       pid:=GET_PID();
   end;
end else begin
   writeln('Stopping PostFilter......: Daemon Already stopped');
   exit;
end;
end;
//#############################################################################
end.
