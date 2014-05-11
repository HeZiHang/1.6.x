unit vmwaretools;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils, Process,logs,unix,RegExpr,zsystem;



  type
  tvmtools=class


private
     LOGS:Tlogs;
     SYS:TSystem;
     artica_path:string;
     function PID_PATH():string;
     function INITD_VIRBOXPATH():string;
public
    procedure   Free;
    constructor Create(const zSYS:Tsystem);
    function    VERSION():string;
    function    BIN_PATH():string;
    function    PID_NUM():string;
    procedure   START();
    procedure   STOP();
    function    STATUS:string;
    function    INITD_PATH():string;
    procedure   RELOAD();
    procedure   VIRBOX_STOP();
    procedure   VIRBOX_START();
END;

implementation

constructor tvmtools.Create(const zSYS:Tsystem);
begin
       forcedirectories('/etc/artica-postfix');
       LOGS:=tlogs.Create();
       SYS:=zSYS;



       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;
end;
//##############################################################################
procedure tvmtools.free();
begin
    logs.Free;

end;
//##############################################################################
function tvmtools.BIN_PATH():string;
begin

   if FileExists('/usr/sbin/vmware-guestd') then exit('/usr/sbin/vmware-guestd');
   if FileExists('/usr/lib/vmware-tools/bin32/vmware-user-loader') then exit('/usr/lib/vmware-tools/bin32/vmware-user-loader');
   if FileExists('/usr/sbin/vmtoolsd') then exit('/usr/sbin/vmtoolsd');
end;
//##############################################################################
function tvmtools.INITD_PATH():string;
begin
if FileExists('/etc/init.d/vmware-tools') then exit('/etc/init.d/vmware-tools');
end;
//##############################################################################
function tvmtools.INITD_VIRBOXPATH():string;
begin
if FileExists('/etc/init.d/vboxadd-service') then exit('/etc/init.d/vboxadd-service');
end;
//##############################################################################



function tvmtools.PID_PATH():string;
begin
if FileExists('/var/run/vmtoolsd.pid') then exit('/var/run/vmtoolsd.pid');
exit('/var/run/vmware-guestd.pid');
end;
//##############################################################################
function tvmtools.PID_NUM():string;
begin
    if not FIleExists(PID_PATH()) then begin
       if FileExists('/usr/sbin/vmtoolsd') then result:=SYS.PIDOF('vmtoolsd');
       if FileExists('/usr/sbin/vmware-guestd') then result:=SYS.PIDOF('vmware-guestd');
       if FileExists('/usr/lib/vmware-tools/bin32/vmware-user-loader') then result:=SYS.PIDOF('/usr/lib/vmware-tools/bin32/vmware-user-loader');
    end else begin
        result:=SYS.GET_PID_FROM_PATH(PID_PATH());
    end;
end;
//##############################################################################
function tvmtools.VERSION():string;
var
    RegExpr:TRegExpr;
    FileDatas:TStringList;
    i:integer;
    filetmp:string;
begin

result:=SYS.GET_CACHE_VERSION('APP_VMTOOLS');
if length(result)>2 then exit;

filetmp:='/etc/vmware-tools/manifest.txt.shipped';
if not FileExists(BIN_PATH()) then exit;
if not FileExists(filetmp) then exit;

    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='guestd\.version.+?([0-9\.]+)';
    FileDatas:=TStringList.Create;
    FileDatas.LoadFromFile(filetmp);
    for i:=0 to FileDatas.Count-1 do begin
        if RegExpr.Exec(FileDatas.Strings[i]) then begin
             result:=RegExpr.Match[1];
             break;
        end;
    end;
             RegExpr.free;
             FileDatas.Free;
SYS.SET_CACHE_VERSION('APP_VMTOOLS',result);

end;
//#############################################################################
procedure tvmtools.RELOAD();
begin
    if not FileExists(INITD_PATH()) then exit;
    fpsystem(INITD_PATH()+' reload');

end;

procedure tvmtools.START();
var
   count:integer;
   pid:string;
begin
    pid:=PID_NUM();
    IF sys.PROCESS_EXIST(pid) then begin
       logs.DebugLogs('Starting......: VmwareTools Already running PID '+ pid);
       exit;
    end;

    if not FileExists(INITD_PATH()) then begin
       logs.DebugLogs('Starting......: VmwareTools is not installed');
       exit;
    end;


    fpsystem(INITD_PATH()+' start &');


count:=0;
 while not SYS.PROCESS_EXIST(PID_NUM()) do begin
        sleep(100);
        inc(count);
        if count>10 then begin
           logs.DebugLogs('Starting......: VmwareTools (timeout)');
           break;
        end;
  end;

pid:=PID_NUM();
    IF sys.PROCESS_EXIST(pid) then begin
       logs.DebugLogs('Starting......: VmwareTools successfully started and running PID '+ pid);
       exit;
    end;

logs.DebugLogs('Starting......: VmwareTools failed');

end;


//#############################################################################
procedure tvmtools.STOP();
begin
  fpsystem(INITD_PATH()+' stop');
end;


//#############################################################################
procedure tvmtools.VIRBOX_STOP();
begin
  if not FileExists(SYS.LOCATE_GENERIC_BIN('VBoxService')) then exit;
  fpsystem(INITD_VIRBOXPATH()+' stop');
end;


//#############################################################################
procedure tvmtools.VIRBOX_START();
begin
  if not FileExists(SYS.LOCATE_GENERIC_BIN('VBoxService')) then exit;

  fpsystem(INITD_VIRBOXPATH()+' start');
end;


//#############################################################################


function tvmtools.STATUS:string;
var
pidpath:string;
begin

 pidpath:=logs.FILE_TEMP();
 fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.status.php --vmtools >'+pidpath +' 2>&1');
 result:=logs.ReadFromFile(pidpath);
 logs.DeleteFile(pidpath);
end;
//##############################################################################


end.
