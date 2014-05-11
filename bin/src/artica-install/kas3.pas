unit kas3;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,Process,logs,unix,RegExpr in 'RegExpr.pas',zsystem;

type LDAP=record
      admin:string;
      password:string;
      suffix:string;
      servername:string;
      Port:string;
  end;

  type
  tkas3=class


private
     LOGS:Tlogs;

     SYS:TSystem;
     artica_path:string;

     FUNCTION  KAS_AP_SPF_PID():string;
     FUNCTION  KAS_AP_PROCESS_SERVER_PID():string;
     FUNCTION  KAS_LICENCE_PID():string;
     FUNCTION  KAS_THTTPD_PID():string;
     FUNCTION  KAS_MILTER_PID():string;
     function  PATTERN_xml():string;
     procedure DEFAUL_CONF();

public
    procedure   Free;
    constructor Create(const zSYS:Tsystem);
    function    INITD_PATH():string;
    function    VERSION():string;
    function    CONF_PATH():string;
    procedure   START();
    procedure   STOP();
    function    STATUS():string;
    function    GET_VALUE(key:string):string;
    function    PATTERN_DATE():string;
    procedure   PERFORM_UPDATE();
    procedure   DELETE_VALUE(key:string);
    procedure   WRITE_VALUE(key:string;datas:string);
    function    KAS_STATUS():string;
    procedure   CHANGE_CRONTAB();
    procedure   RESTART();
    procedure   RELOAD();
    procedure   mailflt3();
    procedure   REMOVE();
END;

implementation

constructor tkas3.Create(const zSYS:Tsystem);
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
procedure tkas3.free();
begin
    logs.Free;
end;
//##############################################################################
function tkas3.INITD_PATH():string;
begin
   if FileExists('/etc/init.d/kas3') then result:='/etc/init.d/kas3';
end;
//##############################################################################
function tkas3.CONF_PATH():string;
begin
  if FileExists('/usr/local/ap-mailfilter3/etc/filter.conf') then exit('/usr/local/ap-mailfilter3/etc/filter.conf');
end;
//#############################################################################
FUNCTION tkas3.KAS_AP_PROCESS_SERVER_PID():string;
begin
  result:=SYS.GET_PID_FROM_PATH('/usr/local/ap-mailfilter3/run/ap-process-server.pid');
  if not SYS.PROCESS_EXIST(result) then result:=SYS.PIDOF('/usr/local/ap-mailfilter3/bin/ap-process-server');
end;
 //#############################################################################
FUNCTION tkas3.KAS_AP_SPF_PID():string;
begin
  result:=SYS.GET_PID_FROM_PATH('/usr/local/ap-mailfilter3/run/ap-spfd.pid');
end;
 //#############################################################################
FUNCTION tkas3.KAS_LICENCE_PID():string;
begin
  result:=SYS.GET_PID_FROM_PATH('/usr/local/ap-mailfilter3/run/kas-license.pid');
end;
 //#############################################################################
FUNCTION tkas3.KAS_THTTPD_PID():string;
begin
  result:=SYS.GET_PID_FROM_PATH('/usr/local/ap-mailfilter3/run/kas-thttpd.pid');
end;
 //#############################################################################
FUNCTION tkas3.KAS_MILTER_PID():string;
begin
    result:=SYS.GET_PID_FROM_PATH('/usr/local/ap-mailfilter3/run/kas-milter.pid');
    if length(result)=0 then result:=SYS.PIDOF('/usr/local/ap-mailfilter3/bin/kas-milter');
end;
 //#############################################################################
procedure tkas3.DELETE_VALUE(key:string);
var
   RegExpr,RegExpr2:TRegExpr;
   filter_conf:TstringList;
   i:integer;

begin
    if not fileexists('/usr/local/ap-mailfilter3/etc/filter.conf') then exit;
  filter_conf:=TstringList.Create;
  filter_conf.LoadFromFile('/usr/local/ap-mailfilter3/etc/filter.conf');
  RegExpr:=TRegExpr.Create;
  RegExpr2:=TRegExpr.Create;
  RegExpr2.Expression:='#';
  RegExpr.Expression:=key + '(.+)';
 for i:=0 to filter_conf.Count -1 do begin
        if not RegExpr2.Exec(filter_conf.Strings[i]) then begin
            if  RegExpr.Exec(filter_conf.Strings[i]) then begin
                filter_conf.Delete(i);
                filter_conf.SaveToFile('/usr/local/ap-mailfilter3/etc/filter.conf');
                break;
            end;
        end;
  end;
  filter_conf.Free;
  RegExpr2.Free;
  RegExpr.free;

end;


//##############################################################################
procedure tkas3.CHANGE_CRONTAB();
var
   l:TstringList;
   tmpstr:string;
begin

if not FileExists(INITD_PATH()) then exit;
tmpstr:=LOGS.FILE_TEMP();
l:=TstringList.Create;
l.Add('MAILTO=postmaster');
l.Add('PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin');
l.Add('HOME=/usr/local/ap-mailfilter3/run');
l.Add('8,28,48 * * * * /usr/local/ap-mailfilter3/bin/sfupdates -q');
l.Add('2,13,24,35,46,57 * * * * /usr/local/ap-mailfilter3/bin/uds-rtts.sh -q');
l.Add('*/5 * * * * /usr/local/ap-mailfilter3/control/bin/sfmonitoring -q');
l.Add('* * * * * /usr/local/ap-mailfilter3/control/bin/dologs.sh -q');
l.Add('*/5 * * * * /usr/local/ap-mailfilter3/control/bin/dograph.sh -q');
l.Add('7 */12 * * * /usr/local/ap-mailfilter3/control/bin/logrotate.sh -q');
try
   l.SaveToFile(tmpstr);
except
      logs.DebugLogs('Starting......: kaspersky anti-spam milter change crontab fatal error');
      exit;
end;
fpsystem('crontab -u mailflt3 -r');
fpsystem('crontab -u mailflt3 ' + tmpstr);
logs.DebugLogs('Starting......: kaspersky anti-spam milter change crontab done...');
logs.DeleteFile(tmpstr);
l.Free;
end;
//##############################################################################
procedure tkas3.RESTART();
begin

    logs.OutputCmd('/usr/local/ap-mailfilter3/bin/kas-restart -p');
    logs.OutputCmd('/usr/local/ap-mailfilter3/bin/kas-restart -f');
    logs.OutputCmd('/usr/local/ap-mailfilter3/bin/kas-restart -s');
end;
//##############################################################################

procedure tkas3.DEFAUL_CONF();
var
   l:TstringList;
begin

if FIleExists('/usr/local/ap-mailfilter3/etc/keepup2date.conf') then exit;


l:=TstringList.Create;
l.add('[locale]');
l.add('DateFormat=%d-%m-%Y');
l.add('TimeFormat=%H:%M:%S');
l.add('');
l.add('[path]');
l.add('BasesPath=/usr/local/ap-mailfilter3/cfdata/bases');
l.add('LicensePath=/usr/local/ap-mailfilter3/conf/lk-license');
l.add('');
l.add('[updater.options]');
l.add('ConnectTimeout=20');
l.add('PassiveFtp=0');
l.add('UseProxy=0');
l.add('UseUpdateServerUrl=0');
l.add('UseUpdateServerUrlOnly=0');
l.add('ProxyAddress=');
l.add('RegionSettings=Russia');
l.add('UpdateServerUrl=');
l.add('KeepSilent=0');
l.add('');
l.add('[updater.path]');
l.add('BackUpPath=/usr/local/ap-mailfilter3/cfdata/bases.backup');
l.add('UploadPatchPath=/usr/local/ap-mailfilter3/cfdata/patches');
l.add('');
l.add('[updater.report]');
l.add('Append=1');
l.add('ReportFileName=/usr/local/ap-mailfilter3/log/updater.log');
l.add('ReportLevel=4');
try
   l.SaveToFile('/usr/local/ap-mailfilter3/etc/keepup2date.conf');
except
   logs.DebugLogs('Starting......: kaspersky anti-spam milter FAILED while saving /usr/local/ap-mailfilter3/etc/keepup2date.conf');
end;

end;
//##############################################################################



procedure tkas3.WRITE_VALUE(key:string;datas:string);
var
   RegExpr,RegExpr2:TRegExpr;
   filter_conf:TstringList;
   i:integer;
   found:boolean;
begin
  found:=false;
  if not fileexists('/usr/local/ap-mailfilter3/etc/filter.conf') then exit;
  filter_conf:=TstringList.Create;
  filter_conf.LoadFromFile('/usr/local/ap-mailfilter3/etc/filter.conf');
  RegExpr:=TRegExpr.Create;
  RegExpr2:=TRegExpr.Create;
  RegExpr2.Expression:='#';
  RegExpr.Expression:=key + '(.+)';
  for i:=0 to filter_conf.Count -1 do begin
        if not RegExpr2.Exec(filter_conf.Strings[i]) then begin
            if  RegExpr.Exec(filter_conf.Strings[i]) then begin
                filter_conf.Strings[i]:=key + ' ' + datas;
                filter_conf.SaveToFile('/usr/local/ap-mailfilter3/etc/filter.conf');
                found:=True;
                break;
            end;
        end;
  end;

  if found=false then begin
          filter_conf.Add(key + ' ' + datas);
          filter_conf.SaveToFile('/usr/local/ap-mailfilter3/etc/filter.conf');
  end;


  RegExpr.Free;
  RegExpr2.Free;
  filter_conf.Free;

end;

//##############################################################################
function tkas3.KAS_STATUS():string;
var
   pid,one,two,three,four:string;
begin
   pid:=KAS_AP_PROCESS_SERVER_PID();
   if length(pid)=0 then one:='0-0';
   if FileExists('/proc/' + pid + '/exe') then one:=pid+'-1' else one:=pid+'-0';

   pid:=KAS_AP_SPF_PID();
   if length(pid)=0 then two:='0-0';
   if FileExists('/proc/' + pid + '/exe') then two:=pid+'-1' else two:=pid+'-0';

   pid:=KAS_LICENCE_PID();
   if length(pid)=0 then three:='0-0';
   if FileExists('/proc/' + pid + '/exe') then three:=pid+'-1' else three:=pid+'-0';

   pid:=KAS_THTTPD_PID();
   if length(pid)=0 then four:='0-0';
   if FileExists('/proc/' + pid + '/exe') then four:=pid+'-1' else four:=pid+'-0';

   result:=one + ';' + two + ';' + three + ';' + four;
end;
//##############################################################################
function tkas3.GET_VALUE(key:string):string;
var
   RegExpr,RegExpr2:TRegExpr;
   filter_conf:TstringList;
   i:integer;
begin
  if not fileexists('/usr/local/ap-mailfilter3/etc/filter.conf') then exit;
  filter_conf:=TstringList.Create;
  filter_conf.LoadFromFile('/usr/local/ap-mailfilter3/etc/filter.conf');
  RegExpr:=TRegExpr.Create;
  RegExpr2:=TRegExpr.Create;
  RegExpr2.Expression:='#';
  RegExpr.Expression:=key + '(.+)';
  for i:=0 to filter_conf.Count -1 do begin
        if not RegExpr2.Exec(filter_conf.Strings[i]) then begin
            if  RegExpr.Exec(filter_conf.Strings[i]) then begin
                result:=trim(RegExpr.Match[1]);
                break;
            end;
        end;
  end;

  RegExpr.Free;
  RegExpr2.Free;
  filter_conf.Free;

end;

//#############################################################################
function tkas3.PATTERN_DATE():string;
var
   BasesPath:string;
   xml:string;
   RegExpr:TRegExpr;
begin
 BasesPath:=PATTERN_xml();
 if not FileExists(BasesPath) then exit;
 xml:=logs.ReadFromFile(BasesPath);
 RegExpr:=TRegExpr.Create;
 RegExpr.Expression:='UpdateDate="([0-9]+)\s+([0-9]+)"';
 if RegExpr.Exec(xml) then begin
  result:=RegExpr.Match[1] + ';' + RegExpr.Match[2];
 end;
 RegExpr.Free;
end;
//##############################################################################
function tkas3.PATTERN_xml():string;
begin
    if FileExists('/usr/local/ap-mailfilter3/cfdata/bases/kas300.xml') then exit('/usr/local/ap-mailfilter3/cfdata/bases/kas300.xml');
    if FileExists('/usr/local/ap-mailfilter3/cfdata/bases/kas303-0607g.xml') then exit('/usr/local/ap-mailfilter3/cfdata/bases/kas303-0607g.xml');
    if FileExists('/usr/local/ap-mailfilter3/cfdata/bases/u0607g.xml') then exit('/usr/local/ap-mailfilter3/cfdata/bases/u0607g.xml');
end;

//##############################################################################
FUNCTION tkas3.STATUS():string;
var
   pidpath:string;
begin

if not FileExists('/usr/local/ap-mailfilter3/bin/kas-milter') then exit;
pidpath:=logs.FILE_TEMP();
fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.status.php --kas3 >'+pidpath +' 2>&1');
result:=logs.ReadFromFile(pidpath);
logs.DeleteFile(pidpath);
end;
//#########################################################################################
function tkas3.VERSION():string;
var
    path:string;
    RegExpr:TRegExpr;
    FileData:TStringList;
    i:integer;
begin
     path:='/usr/local/ap-mailfilter3/bin/curvers';
     if not FileExists('/usr/local/ap-mailfilter3/bin/curvers') then exit;
     result:=SYS.GET_CACHE_VERSION('APP_KAS3');
     if length(result)>0 then exit;
     FileData:=TStringList.Create;
     RegExpr:=TRegExpr.Create;
     try
     FileData.LoadFromFile(path);
     except
      exit;
     end;
     RegExpr.Expression:='CUR_PRODUCT_VERSION="([0-9\.]+)"';
     for i:=0 to FileData.Count -1 do begin
          if RegExpr.Exec(FileData.Strings[i]) then  begin
            result:=RegExpr.Match[1];
            FileData.Free;
            RegExpr.Free;
            SYS.SET_CACHE_VERSION('APP_KAS3',result);
            exit;
          end;
     end;
end;

//###############################################################################
procedure tkas3.PERFORM_UPDATE();
var
tmp:string;
pid:string;
begin
if SYS.Get_INFO('KasxFilterEnabled')<>'1' then exit;

if not FileExists('/usr/local/ap-mailfilter3/bin/sfupdates') then exit;
if not FileExists('/usr/local/ap-mailfilter3/etc/keepup2date.conf') then begin
   logs.Syslogs('Unable to update Kaspersky Anti-spam, it seems that /usr/local/ap-mailfilter3/etc/keepup2date.conf' );
   logs.Syslogs('Does not exists, do you have save the Kaspersky Anti-spam configuration in Artica interface ???' );
   logs.NOTIFICATION('[ARTICA]: ('+ SYS.HOSTNAME_g()+') Failed to update Kaspersky Anti-spam Pattern file','/usr/local/ap-mailfilter3/etc/keepup2date.conf file is missing','update');
   exit;
end;

ForceDirectories('/var/log/artica-postfix/kaspersky/kas3');
tmp:=logs.FileTimeName();
fpsystem('/usr/local/ap-mailfilter3/bin/sfupdates >/var/log/artica-postfix/kaspersky/kas3/' + tmp + ' 2>&1 &');
sleep(500);
pid:=SYS.PIDOF('/usr/local/ap-mailfilter3/bin/sfupdates');
logs.Debuglogs('tkas3.PERFORM_UPDATE() pid:'+pid);
if SYS.PROCESS_EXIST(pid) then SYS.cpulimit(pid);
end;
//##############################################################################
procedure tkas3.RELOAD();
begin

if not SYS.PROCESS_EXIST(KAS_MILTER_PID()) then begin
      START();
      exit;
end;

logs.Syslogs('Reloading kaspersky Anti-spam milter');
fpsystem('/bin/kill -l USR2 ' + KAS_MILTER_PID());

if not SYS.PROCESS_EXIST(KAS_AP_PROCESS_SERVER_PID()) then begin
            START();
            exit;
end;

logs.Syslogs('Reloading kaspersky Anti-spam ap-process');
fpsystem('/kill -l HUP ' + KAS_MILTER_PID()+' & ');


end;
//##############################################################################
procedure tkas3.mailflt3();
begin
     SYS:=Tsystem.Create;
     SYS.AddUserToGroup('postfix','mailflt3','','');
     SYS.AddShell('mailflt3');
end;


//##############################################################################
procedure tkas3.START();
 var
    count      :integer;
    cmdline    :string;
    logs       :Tlogs;
    KasxFilterEnabled:integer;
begin
LOGS:=tlogs.Create();
logs.Debuglogs('###################### KAS3 ######################');
SYS:=Tsystem.Create;
     count:=0;
     KasxFilterEnabled:=0;
     if not FileExists('/etc/init.d/kas3-milter') then begin
        logs.DebugLogs('Starting kaspersky anti-spam milter service not installed');
        exit;
     end;
     DEFAUL_CONF();
     
if not TryStrToInt(SYS.Get_INFO('KasxFilterEnabled'),KasxFilterEnabled) then begin
   logs.debuglogs('tkas3.START():: unable to understand "KasxFilterEnabled" parameter');
   exit;
end;
     
     if KasxFilterEnabled=0 then begin
         if SYS.PROCESS_EXIST(KAS_MILTER_PID()) then begin
            logs.Syslogs('Stopping kaspersky Anti-spam service cause KasxFilterEnabled=' +SYS.Get_INFO('KasxFilterEnabled'));
            STOP();
         end;
        exit;
     end;

     logs:=Tlogs.Create;
     cmdline:='/etc/init.d/kas3-milter start';

     SYS:=Tsystem.Create;
     SYS.AddUserToGroup('postfix','mailflt3','','');
     SYS.AddShell('mailflt3');
     
if not SYS.PROCESS_EXIST(KAS_AP_PROCESS_SERVER_PID()) then begin
    fpsystem('/etc/init.d/kas3 start &');
end;


 if not SYS.PROCESS_EXIST(KAS_MILTER_PID()) then begin
        logs.DebugLogs('Starting kaspersky anti-spam milter service');
        logs.DebugLogs(cmdline);
        fpsystem(cmdline);
        while not SYS.PROCESS_EXIST(KAS_MILTER_PID()) do begin
              sleep(100);
              inc(count);
              if count>100 then begin
                 logs.DebugLogs('Starting......: kaspersky anti-spam milter daemon... (failed!!!)');
                 logs.Debuglogs('Failed starting kaspersky anti-spam milter');
                 logs.NOTIFICATION('Unable to start Kaspersky Anti-Spam','Artica was unable to start this service','system');
                 exit;
              end;
        end;

      end else begin
        logs.DebugLogs('Starting......: kaspersky anti-spam milter is already running using PID ' + KAS_MILTER_PID() + '...');
        exit;
     end;

     logs.DebugLogs('Starting......: kaspersky anti-spam milter daemon with new PID ' + KAS_MILTER_PID() + '...');


end;
//##############################################################################
procedure tkas3.STOP();
 var
    count      :integer;
    cmdline    :string;
    logs       :Tlogs;
begin

     count:=0;

     if not FileExists('/etc/init.d/kas3-milter') then exit;

     logs:=Tlogs.Create;
     cmdline:='/etc/init.d/kas3-milter stop';

 if SYS.PROCESS_EXIST(KAS_MILTER_PID()) then begin
        logs.Debuglogs('stopping kaspersky anti-spam milter service');
        logs.DebugLogs(cmdline);
        fpsystem(cmdline);
        while SYS.PROCESS_EXIST(KAS_MILTER_PID()) do begin
              sleep(100);
              inc(count);
              if count>100 then begin
                 logs.Debuglogs('stopping......: kaspersky anti-spam milter daemon... (failed!!!)');
                 logs.Debuglogs('Failed stopping kaspersky anti-spam milter');

                 exit;
              end;
        end;
 end;




end;
//##############################################################################
procedure tkas3.REMOVE();
begin

     STOP();
     exit;
     if FileExists('/usr/local/ap-mailfilter3/bin/scripts/pre-uninstall') then fpsystem('/usr/local/ap-mailfilter3/bin/scripts/pre-uninstall');
     if DirectoryExists('/usr/local/ap-mailfilter3') then fpsystem('/bin/rm -rf /usr/local/ap-mailfilter3');
     fpsystem('/usr/share/artica-postfix/bin/artica-make --empty-cache');
     fpsystem('/etc/init.d/artica-postfix restart postfix');
end;







end.
