unit kav4samba;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,IniFiles, Process,logs,unix,RegExpr in 'RegExpr.pas',zsystem;

type LDAP=record
      admin:string;
      password:string;
      suffix:string;
      servername:string;
      Port:string;
  end;

  type
  tkav4samba=class


private
     LOGS:Tlogs;
     D:boolean;
     GLOBAL_INI:TiniFIle;
     SYS:TSystem;
     artica_path:string;
     function CONF_GET_VALUE(KEY:string;VALUE:string):string;


public
    SambaEnabled                        :integer;
    EnableKav4Samba                     :integer;
    procedure   Free;
    constructor Create;
    function    bin_path():string;
    function    conf_path():string;
    function    PID_PATH():string;
    function    PID_NUM():string;
    function    VERSION():string;
    procedure   SERVICE_START();
    procedure   SERVICE_STOP();
    FUNCTION    STATUS():string;
    function    VFS_MODULE():string;
    function    PATTERN_DATE():string;
    function    LICENCE_STATUS():string;
    procedure   REMOVE();


END;

implementation

constructor tkav4samba.Create;
begin
       forcedirectories('/etc/artica-postfix');
       LOGS:=tlogs.Create();
       SYS:=Tsystem.Create;
       D:=LOGS.COMMANDLINE_PARAMETERS('debug');

       if not TryStrToInt(SYS.GET_INFO('SambaEnabled'),SambaEnabled) then SambaEnabled:=1;
       if not TryStrToInt(SYS.GET_INFO('EnableKav4Samba'),EnableKav4Samba) then EnableKav4Samba:=1;
       if SambaEnabled=0 then EnableKav4Samba:=0;


       if D then logs.Debuglogs('tkav4samba.Create():: debug=true');
       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;
end;
//##############################################################################
procedure tkav4samba.free();
begin
    logs.Free;
    SYS.Free;
end;
//##############################################################################
function tkav4samba.bin_path():string;
begin
if FileExists('/opt/kaspersky/kav4samba/bin/kav4samba-kavscanner') then exit('/opt/kaspersky/kav4samba/bin/kav4samba-kavscanner');
end;
//##############################################################################
function tkav4samba.conf_path():string;
begin
if FileExists('/etc/opt/kaspersky/kav4samba.conf') then exit('/etc/opt/kaspersky/kav4samba.conf');
end;
//##############################################################################
function tkav4samba.PID_PATH():string;
begin
if not FileExists(conf_path()) then begin
   if D  then logs.Debuglogs(' tkav4samba.PID_PATH():: unable to stat kav4samba.conf');
   exit;
end;
GLOBAL_INI:=TiniFile.Create(conf_path());
result:=GLOBAL_INI.ReadString('samba.path','PidFile','');
if D  then logs.Debuglogs(' tkav4samba.PID_PATH():: result:='+result);
GLOBAL_INI.free;
end;
//##############################################################################
function tkav4samba.PID_NUM():string;
begin
result:=SYS.GET_PID_FROM_PATH(PID_PATH());
end;
//##############################################################################
procedure tkav4samba.REMOVE();
begin
  SERVICE_STOP();
  writeln('Removing Kaspersky Antivirus For Samba');
  if FileExists('/opt/kaspersky/kav4samba/lib/bin/setup/uninstall.pl') then fpsystem('/opt/kaspersky/kav4samba/lib/bin/setup/uninstall.pl');
  fpsystem('/bin/rm -rf /opt/kaspersky/kav4samba >/dev/null 2>&1');
  fpsystem('/bin/rm -f /etc/opt/kaspersky/kav4samba.conf >/dev/null 2>&1');
  fpsystem('/bin/rm -rf /var/opt/kaspersky/kav4samba >/dev/null 2>&1');
  writeln('Reconfigure Samba...');
  fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.samba.php --reconfigure --verbose &');
  fpsystem('/bin/rm -f /etc/init.d/kav4samba >/dev/null 2>&1');
  writeln('Remove Kaspersky Antivirus For Samba done.');
end;
//##############################################################################


procedure tkav4samba.SERVICE_STOP();
var
   pid:string;
   count:integer;
begin

if not FileExists('/etc/init.d/kav4samba') then exit;


pid:=PID_NUM();



if not SYS.PROCESS_EXIST(pid) then begin
   writeln('Stopping kav4Samba...........: Already stopped');
   exit;
end;
     writeln('Stopping kav4Samba...........: '  + pid + ' PID');
     logs.Output('/etc/init.d/kav4samba stop');


  if SYS.PROCESS_EXIST(pid) then begin
       writeln('Stopping kav4Samba...........: Killing ' + pid + ' PID');
       fpsystem('/bin/kill -9 ' + pid);
  end;
  count:=0;
  pid:=SYS.PIDOF('kav4samba-kavsamba');
    while SYS.PROCESS_EXIST(pid) do begin
        sleep(100);
        inc(count);
        logs.OutputCmd('/bin/kill -9 '+pid);
        if count>50 then begin
           writeln('Stopping kav4Samba...........: ' + pid + ' PID (timeout) kill it');
           logs.OutputCmd('/bin/kill -9 ' + pid);
           break;
        end;
          pid:=SYS.PIDOF('kav4samba-kavsamba');
  end;

end;
//##############################################################################

procedure tkav4samba.SERVICE_START();
var
   pid:string;
   err:string;
   tpmfls:string;
begin

if not FileExists('/etc/init.d/kav4samba') then exit;

pid:=PID_NUM();

if SYS.PROCESS_EXIST(pid) then begin
   logs.Debuglogs('SERVICE_START:: kav4samba Already running PID ' + pid);
   if SambaEnabled=0 then  SERVICE_STOP();
   if EnableKav4Samba=0 then SERVICE_STOP();
   exit;
end;

   if SambaEnabled=0  then begin
      logs.Debuglogs('Starting......: Samba is disabled, skipping Kaspersky');
      exit;
   end;

   if EnableKav4Samba=0  then begin
      logs.Debuglogs('Starting......: kav4samba is disabled, skipping Kaspersky');
      exit;
   end;


   tpmfls:=logs.FILE_TEMP();
   fpsystem('/etc/init.d/kav4samba start >'+tpmfls + ' 2>&1');
   err:=logs.ReadFromFile(tpmfls);
   logs.DeleteFile(tpmfls);

   pid:=PID_NUM();

     if not SYS.PROCESS_EXIST(pid) then begin
        logs.Debuglogs('SERVICE_START:: Failed to start kav4samba with error ' + err);
        exit;
     end;

  logs.Debuglogs('SERVICE_START:: kav4samba running PID ' + pid);

end;
//##############################################################################
function tkav4samba.VERSION():string;
var
   RegExpr:TRegExpr;
   x:string;
   tmpstr:string;
begin
if not FileExists(bin_path()) then exit;
tmpstr:=logs.FILE_TEMP();
fpsystem(bin_path() + ' -v >'+tmpstr + ' 2>&1');
x:=logs.ReadFromFile(tmpstr);
RegExpr:=TRegExpr.Create;
RegExpr.Expression:='Version\s+([0-9a-z\.]+)';
if RegExpr.Exec(x) then result:=trim(RegExpr.Match[1]);
end;
//##############################################################################
function tkav4samba.VFS_MODULE():string;
begin
if not FileExists('/var/opt/kaspersky/applications.setup') then begin
   logs.Debuglogs('tkav4samba.VFS_MODULE():: unable to stat /var/opt/kaspersky/applications.setup');
   exit;
end;
GLOBAL_INI:=TiniFile.Create('/var/opt/kaspersky/applications.setup');
result:=GLOBAL_INI.ReadString('1108','SAMBA_VFSMODULE','');
if D  then logs.Debuglogs(' tkav4samba.VFS_MODULE():: result:='+result);
GLOBAL_INI.free;
end;
//##############################################################################
function tkav4samba.PATTERN_DATE():string;
var
   BasesPath:string;
   xml:string;
   RegExpr:TRegExpr;
begin
//#UpdateDate="([0-9]+)\s+([0-9]+)"#
 BasesPath:=CONF_GET_VALUE('path','BasesPath');
 if not FileExists(BasesPath + '/master.xml') then exit;
 xml:=logs.ReadFromFile(BasesPath + '/master.xml');
 RegExpr:=TRegExpr.Create;
 RegExpr.Expression:='UpdateDate="([0-9]+)\s+([0-9]+)"';
 if RegExpr.Exec(xml) then begin

 //date --date "$dte 3 days 5 hours 10 sec ago"

    result:=RegExpr.Match[1] + ';' + RegExpr.Match[2];
 end;
 RegExpr.Free;
end;
//##############################################################################
function tkav4samba.CONF_GET_VALUE(KEY:string;VALUE:string):string;
var path:string;
begin
  path:=CONF_PATH();
  if not FileExists(path) then exit;
  GLOBAL_INI:=TIniFile.Create(path);
  result:=GLOBAL_INI.ReadString(KEY,VALUE,'');
  GLOBAL_INI.Free;
end;
//#############################################################################
function tkav4samba.LICENCE_STATUS():string;
var
   l:TstringList;
   i:integer;
   RegExpr:TRegExpr;
   tmpf:string;
begin
   result:='license_active';
   tmpf:=logs.FILE_TEMP();
   fpsystem('/opt/kaspersky/kav4samba/bin/kav4samba-licensemanager -s >' + tmpf + ' 2>&1');
   if not fileexists(tmpf) then exit;
   
   l:=TstringList.Create;
   l.LoadFromFile(tmpf);
   logs.DeleteFile(tmpf);
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^Error.+license.+expired';
   
   for i:=0 to l.Count-1 do begin
        if RegExpr.Exec(l.Strings[i]) then begin
           result:='license_expired';
           break;
        end;
   end;
   
   l.free;
   RegExpr.FRee;
end;
//#############################################################################







FUNCTION tkav4samba.STATUS():string;
var
   ini:TstringList;
   pid:string;
begin

  if not FileExists(bin_path()) then exit;
  ini:=TstringList.Create;
  pid:=PID_NUM();

  ini.Add('[KAV4SAMBA]');
  if SYS.PROCESS_EXIST(pid) then ini.Add('running=1') else  ini.Add('running=0');
  ini.Add('application_installed=1');
  ini.Add('application_enabled=1');
  ini.Add('master_pid='+ pid);
  ini.Add('master_memory=' + IntToStr(SYS.PROCESS_MEMORY(pid)));
  ini.Add('master_version=' +VERSION());
  ini.Add('status='+SYS.PROCESS_STATUS(pid));
  ini.Add('service_name=APP_KAV4SAMBA');
  ini.Add('pattern_date='+PATTERN_DATE());
  ini.Add('license='+LICENCE_STATUS());
  ini.Add('service_cmd=kav4samba');
  ini.Add('service_disabled='+IntToStr(EnableKav4Samba));
  ini.Add('remove_cmd=--kav4samba-remove');
  result:=ini.Text;
  ini.free;
end;



end.
