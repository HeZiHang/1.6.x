unit dansguardian;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils, Process,logs,unix,RegExpr in 'RegExpr.pas',zsystem,kav4proxy,clamav,
    squid in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/squid.pas';

type LDAP=record
      admin:string;
      password:string;
      suffix:string;
      servername:string;
      Port:string;
  end;

  type
  tdansguardian=class


private
     LOGS:Tlogs;
     SYS:TSystem;
     artica_path:string;
     kav4proxy:tkav4proxy;
     clamav:Tclamav;
     cicap_mem_pid:string;
     dansguardian_mem_pid:string;
     username:string;
     SQUIDEnable:integer;
     EnableStatisticsCICAPService:integer;
     EnableRemoteStatisticsAppliance:integer;
     TAIL_STARTUP:string;
     function LOCATE_C_ICAP_CONFIG():string;
     function GET_VALUE_DATA(conf_path:string;key:string):string;
     function CheckUserButton():boolean;
     function DANSGUARDIAN_TAIL_PID():string;
public
    DansGuardianEnabled:integer;
    kavicapserverEnabled:integer;
    DansGuardianEnableUserFrontEnd:integer;
    CicapEnabled:integer;
    procedure   Free;
    constructor Create(const zSYS:Tsystem);
    function    INITD_PATH():string;
    function    BIN_PATH():string;
    FUNCTION    DANSGUARDIAN_PID():string;
    procedure   DANSGUARDIAN_STOP();
    procedure   DANSGUARDIAN_START(nottroubleshoot:boolean=false);
    procedure   DANSGUARDIAN_RELOAD();
    function    DANSGUARDIAN_STATUS():string;
    function    DANSGUARDIAN_CONFIG_VALUE(key:string):string;
    procedure   DANSGUARDIAN_CONFIG_VALUE_SET(key:string;value:string);
    function    DANSGUARDIAN_VERSION():string;
    function    DANSGUARDIAN_STATS():string;
    procedure   DANSGUARDIAN_TAIL_START();
    function    DANSGUARDIAN_TAIL_STATUS():string;
    procedure   DANSGUARDIAN_TAIL_STOP();
    procedure   DANSGUARDIAN_TROUBLESHOT();
    function    transparent_image_path():string;
    function    CONF_PATH():string;
    function    filtergroupslist_path():string;
    function    DANSGUARDIAN_DELETE_VALUE(key:string):string;
    function    DANSGUARDIAN_BIN_VERSION(version:string):int64;
    procedure   DANSGUARDIAN_TEMPLATE();
    procedure   REMOVE();

    function    C_ICAP_BIN_PATH():string;
    function    C_ICAP_CONF_PATH():string;
    procedure   C_ICAP_VALUE_SET(key:string;value:string);
    FUNCTION    C_ICAP_PID():string;
    function    C_ICAP_STATUS():string;
    procedure   C_ICAP_START();
    procedure   C_ICAP_STOP();
    procedure   C_ICAP_CONFIGURE();
    procedure   C_ICAP_RELOAD();
    function    C_ICAP_VERSION():string;
END;

implementation

constructor tdansguardian.Create(const zSYS:Tsystem);
begin
       forcedirectories('/etc/artica-postfix');
       LOGS:=tlogs.Create();
       SYS:=zSYS;
       kav4proxy:=tkav4proxy.Create(zSYS);
       clamav:=tclamav.Create;
       username:='squid';
       if fileExists(clamav.CLAMD_BIN_PATH()) then begin
          username:=clamav.CLAMD_GETINFO('User');
       end;

       DansGuardianEnableUserFrontEnd:=1;

       kavicapserverEnabled:=0;
       CicapEnabled:=0;
       TAIL_STARTUP:=SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.dansguardian-tail.php';
       if not TryStrToInt(SYS.GET_INFO('DansGuardianEnabled'),DansGuardianEnabled) then DansGuardianEnabled:=0;
       if not TryStrToInt(SYS.GET_INFO('kavicapserverEnabled'),kavicapserverEnabled) then kavicapserverEnabled:=0;
       if not TryStrToInt(SYS.GET_INFO('CicapEnabled'),CicapEnabled) then CicapEnabled:=0;
       if not TryStrToInt(SYS.GET_INFO('DansGuardianEnableUserFrontEnd'),DansGuardianEnableUserFrontEnd) then DansGuardianEnableUserFrontEnd:=1;
       if not TryStrToInt(SYS.GET_INFO('SQUIDEnable'),SQUIDEnable) then SQUIDEnable:=1;
       if not TryStrToInt(SYS.GET_INFO('EnableStatisticsCICAPService'),EnableStatisticsCICAPService) then EnableStatisticsCICAPService:=1;
       if not TryStrToInt(SYS.GET_INFO('EnableRemoteStatisticsAppliance'),EnableRemoteStatisticsAppliance) then EnableRemoteStatisticsAppliance:=0;





       if SQUIDEnable=0 then begin
          DansGuardianEnabled:=0;
          CicapEnabled:=0;
       end;

       if FileExists('/etc/artica-postfix/WEBSTATS_APPLIANCE') then begin
          CicapEnabled:=1;
          if EnableStatisticsCICAPService=0 then CicapEnabled:=0;
       end;
       if EnableRemoteStatisticsAppliance=0 then begin
        if not SYS.ISMemoryHiger1G() then begin
              if CicapEnabled=1 then logs.Syslogs('Starting......: Fatal Memory is under 1G, C-ICAP will be disabled');
              SYS.set_INFO('CicapEnabled','0');
              CicapEnabled:=0;
        end;
       end;



       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;
end;
//##############################################################################
procedure tdansguardian.free();
begin
    logs.Free;
    clamav.free;
    
end;
//##############################################################################
function tdansguardian.INITD_PATH():string;
begin
   if FileExists('/etc/init.d/dansguardian') then exit('/etc/init.d/dansguardian');
end;
//##############################################################################
function tdansguardian.BIN_PATH():string;
begin
    exit(SYS.LOCATE_DANSGUARDIAN_BIN_PATH());
end;
//##############################################################################
function tdansguardian.CONF_PATH():string;
begin
if FileExists('/etc/dansguardian/dansguardian.conf') then exit('/etc/dansguardian/dansguardian.conf');
exit('/etc/dansguardian/dansguardian.conf');
end;
//##############################################################################
function tdansguardian.C_ICAP_BIN_PATH():string;
begin
if FileExists('/usr/sbin/c-icap') then exit('/usr/sbin/c-icap');
if FileExists('/usr/bin/c-icap') then exit('/usr/bin/c-icap');
end;
//##############################################################################
function tdansguardian.C_ICAP_CONF_PATH():string;
begin
if FileExists('/etc/c-icap/c-icap.conf') then exit('/etc/c-icap/c-icap.conf');
if FileExists('/etc/c-icap.conf') then exit('/etc/c-icap.conf');
end;
//##############################################################################

function tdansguardian.filtergroupslist_path():string;
begin
result:=DANSGUARDIAN_CONFIG_VALUE('filtergroupslist');
end;
//##############################################################################

function tdansguardian.DANSGUARDIAN_VERSION():string;
var
   RegExpr        :TRegExpr;
   F              :TstringList;
   T              :string;
   i              :integer;
begin
   result:='';
   if not FileExists(BIN_PATH()) then begin
      logs.Debuglogs('DANSGUARDIAN_VERSION -> unable to stat dansguardian');
      exit;
   end;
   
   result:=SYS.GET_CACHE_VERSION('APP_DANSGUARDIAN');
   if length(result)>0 then exit;
   
   t:=logs.FILE_TEMP();
   fpsystem(BIN_PATH()+' -v >'+t+' 2>&1');
   if not FileExists(t) then exit;
   f:=TstringList.Create;
   f.LoadFromFile(t);
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='DansGuardian\s+([0-9\.A-Za-z]+)';
   For i:=0 to f.Count-1 do begin

   if RegExpr.Exec(f.Strings[i]) then begin
      result:=RegExpr.Match[1];
      break;
   end;
   end;
   SYS.SET_CACHE_VERSION('APP_DANSGUARDIAN',result);
   RegExpr.Free;
   f.free;
end;
//#############################################################################
FUNCTION tdansguardian.DANSGUARDIAN_PID():string;
var
  RegExpr:TRegExpr;
  tmp:string;
begin
  if length(dansguardian_mem_pid)>0 then exit(dansguardian_mem_pid);
  tmp:=logs.FILE_TEMP();
  if FileExists(BIN_PATH()) then begin
     tmp:=SYS.ExecPipe(BIN_PATH()+' -s');
  end else begin
      exit;
  end;

  RegExpr:=TRegExpr.Create;
  RegExpr.expression:='([0-9]+)';
  if RegExpr.Exec(tmp) then begin
       result:=RegExpr.Match[1];
  end else begin
       logs.Debuglogs(BIN_PATH()+' -s return null "'+tmp+'"');
       result:=SYS.PIDOF(BIN_PATH());
  end;
 dansguardian_mem_pid:=result;
 if not SYS.PROCESS_EXIST(dansguardian_mem_pid) then dansguardian_mem_pid:=SYS.PIDOF(BIN_PATH());

 RegExpr.Free;


end;

//##############################################################################
FUNCTION tdansguardian.C_ICAP_PID():string;
var PID,PID2:string;
begin

 if length(cicap_mem_pid)>0 then exit(cicap_mem_pid);


 if not FileExists('/var/run/c-icap/c-icap.pid') then begin
    result:=SYS.PidByProcessPath(C_ICAP_BIN_PATH());
    cicap_mem_pid:=result;
    exit;
 end;
 PID:=SYS.GET_PID_FROM_PATH('/var/run/c-icap/c-icap.pid');
 
 if (PID='0') OR (length(PID)=0) then begin
    result:=SYS.PidByProcessPath(C_ICAP_BIN_PATH());
    cicap_mem_pid:=result;
    exit;
 end;
 
 PID2:=SYS.PidByProcessPath(C_ICAP_BIN_PATH());
 if SYS.PROCESS_EXIST(PID2) and not SYS.PROCESS_EXIST(PID) then begin
    result:=PID2;
    cicap_mem_pid:=PID2;
    exit;
 end;
 
 result:=PID;
 cicap_mem_pid:=PID;
 

end;
//##############################################################################
function tdansguardian.transparent_image_path():string;
begin
if Fileexists('/usr/share/dansguardian/transparent1x1.gif') then exit('/usr/share/dansguardian/transparent1x1.gif');

end;

//##############################################################################
procedure tdansguardian.REMOVE();
begin
writeln('Uninstall Dansguardian');
   DANSGUARDIAN_TAIL_STOP();
   DANSGUARDIAN_STOP();
   fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --remove "dansguardian"');
   fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.dansguardian.compile.php --clean-db');
   if FIleExists(INITD_PATH()) then logs.DeleteFile(INITD_PATH());
   if FIleExists(BIN_PATH()) then logs.DeleteFile(BIN_PATH());
   logs.DeleteFile('/etc/artica-postfix/versions.cache');
   logs.OutputCmd('/usr/share/artica-postfix/bin/artica-install --write-versions');
   logs.OutputCmd('/usr/share/artica-postfix/bin/process1 --force');
   fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.squid.php --reconfigure');
   writeln('Uninstall Dansguardian DONE');
   end;
//##############################################################################



procedure tdansguardian.DANSGUARDIAN_RELOAD();
var
   pid:string;
   noconfig:boolean;
begin
   noconfig:=false;
if not FileExists(BIN_PATH()) then begin
   logs.Debuglogs('Starting......: DansGuardian is not installed');
   exit;
end;

if DansGuardianEnabled=0 then begin
     logs.Debuglogs('Starting......: DansGuardian is disabled, aborting');
     DANSGUARDIAN_TAIL_STOP();
     exit;
end;

  pid:=DANSGUARDIAN_PID();
  noconfig:=SYS.COMMANDLINE_PARAMETERS('--withoutconfig');




if SYS.PROCESS_EXIST(pid) then begin
     logs.Debuglogs('Starting......: DansGuardian reload dansgardian with PID '+ pid);
     DANSGUARDIAN_TEMPLATE();
     logs.Syslogs('Starting......: DansGuardian will be reloaded with username "'+username+'"');
     logs.OutputCmd(BIN_PATH() + ' -r');
     DANSGUARDIAN_TAIL_START();
     exit;
end;


DANSGUARDIAN_START();
end;

//##############################################################################
procedure tdansguardian.DANSGUARDIAN_START(nottroubleshoot:boolean);
var
   count:integer;
   pid:string;
   verb:string;
begin
count:=0;

logs.Debuglogs('###################### DANSGUARDIAN #####################');


if not FileExists(BIN_PATH()) then begin
   logs.Debuglogs('Starting......: DansGuardian is not installed');
   exit;
end;

if DansGuardianEnabled=0 then begin
   logs.Debuglogs('Starting......: DansGuardian is disabled');
    DANSGUARDIAN_STOP();
    exit;
end;
if SYS.isoverloadedTooMuch() then begin
   logs.DebugLogs('Starting......: DansGuardian System is overloaded');
   exit;
end;



if FileExists(transparent_image_path()) then logs.OutputCmd('/bin/ln -s --force '+transparent_image_path()+' /etc/dansguardian/transparent1x1.gif');



forcedirectories('/var/log/dansguardian');
logs.OutputCmd('/bin/chown -R '+username+':'+username+' /var/log/dansguardian');
C_ICAP_START();
pid:=DANSGUARDIAN_PID();



  if length(pid)=0 then begin
     pid:=SYS.PIDOF(BIN_PATH());
     if length(pid)>0 then begin
         logs.DebugLogs('Starting......: DansGuardian kill all bad pids ' + pid);
         fpsystem('/bin/kill -9 ' + pid);
     end;
  end;


 logs.Debuglogs('DANSGUARDIAN_START() -> PID='+ DANSGUARDIAN_PID());
 if SYS.PROCESS_EXIST(DANSGUARDIAN_PID()) then begin
    logs.DebugLogs('Starting......: DansGuardian already running using pid ' + DANSGUARDIAN_PID()+ '...');
    exit;
 end;
 if SYS.COMMANDLINE_PARAMETERS('--verbose') then verb:=' --verbose';
 fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.squidguard.php --dansguardian'+verb);
 DANSGUARDIAN_TEMPLATE();
 logs.Debuglogs('Starting......: DansGuardian width username '+username);
 logs.Debuglogs('Starting......: DansGuardian...');
 if Not FileExists('/var/log/dansguardian/dansguardian.log') then begin
    forcedirectories('/var/log/dansguardian');
    logs.OutputCmd('/bin/touch /var/log/dansguardian/dansguardian.log');
 end;
 logs.OutputCmd('/bin/chown -R '+username+':'+username+' /var/log/dansguardian');
 if FileExists('/tmp/.dguardianipc') then logs.DeleteFile('/tmp/.dguardianipc');
 if FileExists('/tmp/.dguardianurlipc') then logs.DeleteFile('/tmp/.dguardianurlipc');
 logs.OutputCmd('/bin/chmod 777 /tmp');

 logs.OutputCmd(BIN_PATH());
     

 while not SYS.PROCESS_EXIST(DANSGUARDIAN_PID()) do begin
        sleep(100);
        inc(count);
        if count>10 then begin
           logs.DebugLogs('Starting......: DansGuardian (failed)');
           break;
        end;
  end;

 logs.Debuglogs('Starting......: DansGuardian...');
 sleep(200);


 logs.OutputCmd(BIN_PATH());

 count:=0;
 while not SYS.PROCESS_EXIST(DANSGUARDIAN_PID()) do begin
        sleep(100);
        inc(count);
        if count>10 then begin
           logs.DebugLogs('Starting......: DansGuardian (failed)');
           if not nottroubleshoot then DANSGUARDIAN_TROUBLESHOT();
           exit;
        end;
  end;

 logs.DebugLogs('Starting......: DansGuardian started with new pid ' + DANSGUARDIAN_PID());
 DANSGUARDIAN_TAIL_START();
end;
//##############################################################################
procedure tdansguardian.DANSGUARDIAN_TROUBLESHOT();
var
   tmpstr:string;
   RegExpr     :TRegExpr;
   l:Tstringlist;
   i:integer;
begin
   tmpstr:=logs.FILE_TEMP();
   logs.DebugLogs('Starting......: DansGuardian investigate the problem...');
   fpsystem(BIN_PATH() + ' >' + tmpstr +' 2>&1');

   if not FileExists(tmpstr) then begin
        logs.DebugLogs('Starting......: DansGuardian investigate failed');
        exit;
   end;


   l:=Tstringlist.Create;
   l.LoadFromFile(tmpstr);
   logs.DeleteFile(tmpstr);
   RegExpr:=TRegExpr.Create;


   for i:=0 to l.Count-1 do begin


   RegExpr.Expression:='Error binding ipc server file.+?rm\s+(.+?)''';
   if RegExpr.Exec(l.Strings[i]) then begin
       logs.DebugLogs('Starting......: DansGuardian found ipc server error on '+RegExpr.Match[1] +' file');
       if FileExists(RegExpr.Match[1]) then logs.DeleteFile(RegExpr.Match[1]);
       DANSGUARDIAN_START(true);
       break;
   end;

    RegExpr.Expression:='Error binding server socket';
     if RegExpr.Exec(l.Strings[i]) then begin
       logs.DebugLogs('Starting......: DansGuardian Error binding server socket -> restart squid');
       logs.NOTIFICATION('DansGuardian Error binding server socket -> restart squid','','squid');
       fpsystem('/etc/init.d/artica-postfix restart squid-cache');
       DANSGUARDIAN_START(true);
       break;
   end;


   RegExpr.Expression:='Unable.+?plugin.+?clamdscan';
     if RegExpr.Exec(l.Strings[i]) then begin
         logs.DebugLogs('Starting......: DansGuardian found clamav error "'+l.Strings[i]+'" disable Clamav');
         SYS.SET_INFO('DansGuardianEnableClamav','0');
         fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.dansguardian.compile.php');
         break;
     end;

     logs.DebugLogs('Starting......: '+l.Strings[i]);

   end;

 l.free;
 RegExpr.free;

end;

procedure tdansguardian.C_ICAP_RELOAD();
var
   pid:string;
   squid:tsquid;
begin
   if CicapEnabled=0 then begin
     logs.Debuglogs('Starting......: c-icap is disabled by artica by "CicapEnabled" token...');
     C_ICAP_STOP();
     exit;
   end;

   PID:= C_ICAP_PID();
   if not SYS.PROCESS_EXIST(pid) then begin
        C_ICAP_START();
        exit;
   end;

   logs.Debuglogs('Starting......: reloading c-icap pid '+PID);

   if FileExists('/var/run/c-icap/c-icap.ctl') then begin
      squid:=tsquid.Create;
      logs.OutputCmd('echo -n "reconfigure"  > /var/run/c-icap/c-icap.ctl');
   end else begin
      logs.OutputCmd('/bin/kill -HUP ' + PID);
   end;
end;
//##############################################################################

procedure tdansguardian.C_ICAP_START();
var
   count:integer;
   pid:string;
   squid:tsquid;

begin
count:=0;
if not FileExists(C_ICAP_BIN_PATH()) then begin
   logs.Debuglogs('C_ICAP_START():: unable to stat c-icap bin...');
   exit;
end;

//if not FileExists(clamav.CLAMSCAN_BIN_PATH()) then begin
  //    logs.Debuglogs('Starting......: c-icap Unable to stat clamscan bin path, aborting...');
  //    exit;
//end;

if CicapEnabled=0 then begin
     logs.Debuglogs('Starting......: c-icap is disabled by artica by "CicapEnabled" token...');
     C_ICAP_STOP();
     exit;
end;

 if EnableRemoteStatisticsAppliance=1 then begin
     logs.Debuglogs('Starting......: c-icap is disabled it using the remote appliance "EnableRemoteStatisticsAppliance" token ...');
     C_ICAP_STOP();
     exit;
 end;

PID:= C_ICAP_PID();



 logs.Debuglogs('C_ICAP_START() -> PID='+ PID);
 if SYS.PROCESS_EXIST(PID) then begin
    logs.Debuglogs('Starting......: c-icap already running using pid ' + PID+ '...');
    exit;
 end;
 C_ICAP_CONFIGURE();
 logs.Debuglogs('Starting......: c-icap...');
 logs.Debuglogs(C_ICAP_BIN_PATH() + ' -f '+C_ICAP_CONF_PATH());

 fpsystem(C_ICAP_BIN_PATH() + ' -f '+C_ICAP_CONF_PATH()+' -d 3');

 

 while not SYS.PROCESS_EXIST(PID) do begin

        sleep(100);
        inc(count);
        if count>80 then begin
           logs.DebugLogs('Starting......: c-icap (timeout)');
           break;
        end;
        PID:= C_ICAP_PID();
  end;

 
 PID:= C_ICAP_PID();
 
 if length(PID)>0 then begin
    squid:=tsquid.Create;
    logs.DebugLogs('Starting......: c-icap started with new pid ' + PID);
 end else begin
    writeln('Starting......: c-icap failed with command line '+C_ICAP_BIN_PATH() + ' -f '+C_ICAP_CONF_PATH()+' -d 3');
 end;


end;
//##############################################################################
procedure tdansguardian.C_ICAP_CONFIGURE();
begin
logs.DebugLogs('Starting......: c-icap reconfigure settings..');
fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.c-icap.php --build');
logs.DebugLogs('Starting......: c-icap reconfigure settings done..');
end;
//##############################################################################
procedure tdansguardian.DANSGUARDIAN_STOP();
 var
    pid:string;
    count:integer;
begin
count:=0;
  if not FileExists(BIN_pATH) then begin
     writeln('Stopping DansGuardian........: Not installed');
     exit;
  end;
  pid:=DANSGUARDIAN_PID();

   if not SYS.PROCESS_EXIST(pid) then begin
      writeln('Stopping DansGuardian........: Already stopped');
      DANSGUARDIAN_TAIL_STOP();
      exit;
   end;

  if SYS.PROCESS_EXIST(pid) then begin
  writeln('Stopping DansGuardian........: ' + pid + ' PID');
  logs.OutputCmd('/bin/kill '+pid);
  logs.OutputCmd(BIN_pATH()+' -q');
  pid:=trim(DANSGUARDIAN_PID());
  if length(trim(pid))=0 then begin
      writeln('Stopping DansGuardian........: Stopped success');
       if FileExists('/tmp/.dguardianipc') then logs.DeleteFile('/tmp/.dguardianipc');
       if FileExists('/tmp/.dguardianurlipc') then logs.DeleteFile('/tmp/.dguardianurlipc');
       exit;
  end;


       while SYS.PROCESS_EXIST(pid) do begin
        sleep(100);
        inc(count);
        if length(trim(pid))=0 then break;
        logs.OutputCmd('/bin/kill '+pid);
        logs.OutputCmd(BIN_pATH()+' -q');
        dansguardian_mem_pid:='';
        if count>30 then break;
        pid:=trim(DANSGUARDIAN_PID());
       end;
  end;

  if not SYS.PROCESS_EXIST(DANSGUARDIAN_PID()) then begin
     writeln('Stopping DansGuardian........: Stopped success');
     if FileExists('/tmp/.dguardianipc') then logs.DeleteFile('/tmp/.dguardianipc');
     if FileExists('/tmp/.dguardianurlipc') then logs.DeleteFile('/tmp/.dguardianurlipc');
  end;

  DANSGUARDIAN_TAIL_STOP();

end;
//##############################################################################

procedure tdansguardian.C_ICAP_STOP();
 var
    pid:string;
    allpids:TstringList;
    count,i,pidf:integer;
begin
count:=0;
  if not FileExists(C_ICAP_BIN_PATH()) then begin
     writeln('Stopping C-icap..............: Not installed');
     exit;
  end;
  
  pid:=C_ICAP_PID();
  if not SYS.PROCESS_EXIST(pid) then begin
     PID:=SYS.PidByProcessPath(C_ICAP_BIN_PATH());
  end;
  
if SYS.PROCESS_EXIST(pid) then begin
   writeln('Stopping C-icap..............: Stopping smoothly ' + pid + ' PID');
   fpsystem('/bin/echo -n "stop"  > /var/run/c-icap/c-icap.ctl');
     while SYS.PROCESS_EXIST(pid) do begin
        sleep(100);
        inc(count);
        if count>30 then break;
        pid:=C_ICAP_PID();
    end;
end;

pid:=C_ICAP_PID();
if SYS.PROCESS_EXIST(pid) then begin
   writeln('Stopping C-icap..............: Stopping must kill ' + pid + ' PID');
   logs.OutputCmd('/bin/kill '+ pid);

  while SYS.PROCESS_EXIST(pid) do begin
        sleep(100);
        inc(count);
        pid:=C_ICAP_PID();
        if count>30 then break;
  end;

end else begin
       writeln('Stopping C-icap..............: seems stopped');
end;
  writeln('Stopping C-icap..............: found childrend running on '+ C_ICAP_BIN_PATH());
  allpids:=Tstringlist.Create;
  allpids.AddStrings(SYS.PIDOF_PATTERN_PROCESS_LIST(C_ICAP_BIN_PATH()));
     for i:=0 to allpids.Count-1 do begin
         if not TryStrToInt(allpids.Strings[i],pidf) then continue;
         if pidf>3 then begin
            writeln('Stopping C-icap..............: child: ' + IntToStr(pidf) + ' PIDs');
            fpsystem('/bin/kill -9 '+ IntToStr(pidf));
         end;
  end;

  cicap_mem_pid:='';
  pid:=C_ICAP_PID();
  if not SYS.PROCESS_EXIST(pid) then begin
     writeln('Stopping C-icap..............: Stopped');
  end else begin
     writeln('Stopping C-icap..............: Failed pid '+pid);
  end;
end;
//##############################################################################

function tdansguardian.DANSGUARDIAN_STATUS():string;
var
  pidpath:string;
begin
if not FileExists(BIN_PATH()) then exit;
pidpath:=logs.FILE_TEMP();
fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.status.php --dansguardian >'+pidpath +' 2>&1');
result:=logs.ReadFromFile(pidpath);
logs.DeleteFile(pidpath);
end;
//##############################################################################
function tdansguardian.C_ICAP_VERSION():string;
var
    filetmp:string;
    path:string;
begin

path:=LOCATE_C_ICAP_CONFIG();
if not FIleExists(path) then result:='060708rc2';
   result:=SYS.GET_CACHE_VERSION('APP_C_ICAP');
   if length(result)>2 then exit;

filetmp:=logs.FILE_TEMP();
if not FileExists(path) then begin
   logs.Debuglogs('unable to find c-icap-config');
   exit;
end;

logs.Debuglogs(path+' --version >'+filetmp+' 2>&1');
fpsystem(path+' --version >'+filetmp+' 2>&1');
result:=trim(logs.ReadFromFile(filetmp));
logs.DeleteFile(filetmp);
SYS.SET_CACHE_VERSION('APP_C_ICAP',result);
end;


//##############################################################################
function tdansguardian.LOCATE_C_ICAP_CONFIG():string;
var path:string;
begin
path:=SYS.LOCATE_GENERIC_BIN('c-icap-config');
if FileExists(path) then exit(path);
path:=SYS.LOCATE_GENERIC_BIN('c-icap-libicapapi-config');
if FileExists(path) then exit(path);
end;





function tdansguardian.C_ICAP_STATUS():string;
var
pidpath:string;
begin
 if not FileExists(C_ICAP_BIN_PATH()) then exit;

  pidpath:=logs.FILE_TEMP();
 fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.status.php --c-icap >'+pidpath +' 2>&1');
 result:=logs.ReadFromFile(pidpath);
 logs.DeleteFile(pidpath);

 if CicapEnabled=0 then begin
 SYS.MONIT_DELETE('APP_C_ICAP');
 exit;
 end;
 SYS.MONIT_CONFIG('APP_C_ICAP','/var/run/c-icap/c-icap.pid','cicap');

end;
//##############################################################################
function tdansguardian.DANSGUARDIAN_STATS():string;
var
   phpfile:string;
begin
result:='';
if not FileExists(BIN_PATH) then exit;
phpfile:=artica_path+'/cron.dansguardian.php';
if not FileExists(phpfile) then begin
   writeln('Unable to stat ' +phpfile);
   logs.Syslogs('Unable to stat '+phpfile);
   exit;
end;

DANSGUARDIAN_STOP();
logs.OutputCmd('/bin/mv /var/log/dansguardian/access.log /var/log/dansguardian/access_work.log');
logs.OutputCmd('/bin/touch /var/log/dansguardian/access.log');
logs.OutputCmd('/bin/chown '+username+':'+username+' /var/log/dansguardian/access.log');
DANSGUARDIAN_START();
writeln('');
logs.OutputCmd(SYS.EXEC_NICE()+SYS.LOCATE_PHP5_BIN() + ' ' +phpfile+ ' /var/log/dansguardian/access_work.log &');
writeln('');
end;
//##############################################################################
function tdansguardian.DANSGUARDIAN_TAIL_PID():string;
var
   pid:string;
begin

if FileExists('/etc/artica-postfix/exec.dansguardian-tail.php.pid') then begin
   pid:=SYS.GET_PID_FROM_PATH('/etc/artica-postfix/exec.dansguardian-tail.php.pid');
   logs.Debuglogs('DANSGUARDIAN_TAIL_PID /etc/artica-postfix/exec.dansguardian-tail.php.pid='+pid);
   if SYS.PROCESS_EXIST(pid) then result:=pid;
   exit;
end;


result:=SYS.PIDOF_PATTERN(TAIL_STARTUP);
logs.Debuglogs(TAIL_STARTUP+' pid='+pid);
end;
//#####################################################################################


procedure tdansguardian.DANSGUARDIAN_TAIL_START();
var
   pid:string;
   pidint:integer;
   log_path:string;
   count:integer;
   cmd:string;
   CountTail:Tstringlist;
begin
exit();
if not FileExists(BIN_PATH()) then begin
   logs.Debuglogs('Starting......: artica-dansguardian realtime logs:: DansGuardian is not installed');
   exit;
end;


if DansGuardianEnabled=0 then begin
    logs.Debuglogs('Starting......: artica-dansguardian realtime logs:: DansGuardian is disabled');
    DANSGUARDIAN_TAIL_STOP();
    exit;
end;

pid:=DANSGUARDIAN_TAIL_PID();
if SYS.PROCESS_EXIST(pid) then begin
      logs.DebugLogs('Starting......: artica-dansguardian realtime logs already running with pid '+pid);
      if DansGuardianEnabled=0 then DANSGUARDIAN_TAIL_STOP();
      CountTail:=Tstringlist.Create;
      CountTail.AddStrings(SYS.PIDOF_PATTERN_PROCESS_LIST('/usr/bin/tail -f -n 0 /var/log/dansguardian/access.log'));
      logs.DebugLogs('Starting......: artica-dansguardian realtime process number:'+IntToStr(CountTail.Count));
      if CountTail.Count>3 then fpsystem('/etc/init.d/artica-postfix restart dansguardian-tail');
      CountTail.free;
      exit;
end;
log_path:='/var/log/dansguardian/access.log';

if not FileExists(log_path) then begin
   logs.DebugLogs('Starting......: artica-dansguardian realtime stats, unable to stats logfile');
   exit;
end;
DANSGUARDIAN_TAIL_STOP();
logs.DebugLogs('Starting......: artica-dansguardian realtime logs path: '+log_path);

pid:=SYS.PIDOF_PATTERN('/usr/bin/tail -f -n 0 /var/log/dansguardian/access.log');
count:=0;
pidint:=0;
      while SYS.PROCESS_EXIST(pid) do begin
          if count>0 then break;
          if not TryStrToInt(pid,pidint) then continue;
          logs.DebugLogs('Starting......: artica-dansguardian realtime logs stop tail pid '+pid);
          if pidint>0 then  fpsystem('/bin/kill '+pid);
          sleep(200);
          pid:=SYS.PIDOF_PATTERN('/usr/bin/tail -f -n 0 /var/log/dansguardian/access.log');
          inc(count);
      end;

cmd:='/usr/bin/tail -f -n 0 '+log_path+'|'+TAIL_STARTUP+' >>/var/log/artica-postfix/dansguardian-logger-start.log 2>&1 &';
logs.Debuglogs(cmd);
fpsystem(cmd);
pid:=DANSGUARDIAN_TAIL_PID();
count:=0;
while not SYS.PROCESS_EXIST(pid) do begin
        sleep(100);
        inc(count);
        if count>40 then begin
           logs.DebugLogs('Starting......: artica-dansguardian realtime logs (timeout)');
           break;
        end;
        pid:=DANSGUARDIAN_TAIL_PID();
  end;

pid:=DANSGUARDIAN_TAIL_PID();

if SYS.PROCESS_EXIST(pid) then begin
      logs.DebugLogs('Starting......: artica-dansguardian realtime logs success with pid '+pid);
      exit;
end else begin
    logs.DebugLogs('Starting......: artica-dansguardian realtime logs failed');
end;
end;
//#####################################################################################
function tdansguardian.DANSGUARDIAN_TAIL_STATUS():string;
begin
result:='';
       SYS.MONIT_DELETE('APP_ARTICA_DANSGUARDIAN_TAIL');
if not FileExists(BIN_PATH()) then begin
 SYS.MONIT_DELETE('APP_ARTICA_DANSGUARDIAN_TAIL');
 exit;
end;
end;
//#####################################################################################
procedure tdansguardian.DANSGUARDIAN_TAIL_STOP();
var
   pid:string;
   pidint,i:integer;
   count:integer;
   CountTail:Tstringlist;
begin
pid:=DANSGUARDIAN_TAIL_PID();
if not SYS.PROCESS_EXIST(pid) then begin
      writeln('Stopping DansGuardian RealTime log: Already stopped');
      CountTail:=Tstringlist.Create;
      try
         CountTail.AddStrings(SYS.PIDOF_PATTERN_PROCESS_LIST('/usr/bin/tail -f -n 0 /var/log/dansguardian/access.log'));
         writeln('Stopping DansGuardian RealTime log: Tail processe(s) number '+IntToStr(CountTail.Count));
      except
        logs.Debuglogs('Stopping DansGuardian RealTime log: fatal error on SYS.PIDOF_PATTERN_PROCESS_LIST() function');
      end;

      count:=0;
     for i:=0 to CountTail.Count-1 do begin;
          pid:=CountTail.Strings[i];
          if count>100 then break;
          if not TryStrToInt(pid,pidint) then continue;
          writeln('Stopping DansGuardian RealTime log: Stop tail pid '+pid);
          if pidint>0 then  fpsystem('/bin/kill '+pid);
          sleep(100);
          inc(count);
      end;
      exit;
end;

writeln('Stopping DansGuardian RealTime log: Stopping pid '+pid);
fpsystem('/bin/kill '+pid);

pid:=DANSGUARDIAN_TAIL_PID();
if not SYS.PROCESS_EXIST(pid) then begin
      writeln('Stopping DansGuardian RealTime log: Stopped');
end;


CountTail:=Tstringlist.Create;
CountTail.AddStrings(SYS.PIDOF_PATTERN_PROCESS_LIST('/usr/bin/tail -f -n 0 /var/log/dansguardian/access.log'));
writeln('Stopping DansGuardian RealTime log: Tail processe(s) number '+IntToStr(CountTail.Count));
count:=0;
     for i:=0 to CountTail.Count-1 do begin;
          pid:=CountTail.Strings[i];
          if count>100 then break;
          if not TryStrToInt(pid,pidint) then continue;
          writeln('Stopping DansGuardian RealTime log: Stop tail pid '+pid);
          if pidint>0 then  fpsystem('/bin/kill '+pid);
          sleep(100);
          inc(count);
      end;


end;
//#####################################################################################


function tdansguardian.DANSGUARDIAN_CONFIG_VALUE(key:string):string;
var
   l           :TstringList;
   RegExpr     :TRegExpr;
   i           :integer;
begin

    if not FileExists(CONF_PATH()) then exit;
    RegExpr:=TRegExpr.Create;
    l:=TstringList.create;

    RegExpr.Expression:='^'+key+'[\s=]+(.*)';
    l.LoadFromFile(CONF_PATH());
    For i:=0 to l.Count-1 do begin
        if RegExpr.Exec(l.Strings[i]) then begin
               result:=trim(RegExpr.Match[1]);
               result:=trim(result);
         end;

    end;
    
    
    result:=AnsiReplaceText(result,'''','');
    RegExpr.free;
    l.free;

end;
 //#############################################################################
function tdansguardian.DANSGUARDIAN_DELETE_VALUE(key:string):string;
var
   l           :TstringList;
   RegExpr     :TRegExpr;
   i           :integer;
begin
    result:='';
    if not FileExists(CONF_PATH()) then exit;
    RegExpr:=TRegExpr.Create;
    l:=TstringList.create;

    RegExpr.Expression:='^'+key+'[\s=]+(.*)';
    l.LoadFromFile(CONF_PATH());
    For i:=0 to l.Count-1 do begin
        if RegExpr.Exec(l.Strings[i]) then begin
               l.Delete(i);
               logs.DebugLogs('Starting......: Dansguardian delete key ' + key + ' line ' + IntToStr(i));
               l.SaveToFile(CONF_PATH());
               break;
         end;

    end;

    RegExpr.free;
    l.free;

end;
 //#############################################################################

 //#############################################################################
function tdansguardian.GET_VALUE_DATA(conf_path:string;key:string):string;
var
   l           :TstringList;
   RegExpr     :TRegExpr;
   i           :integer;
   tmpstr:string;
begin
   if not FileExists(conf_path) then begin
      logs.Debuglogs('tdansguardian.GET_VALUE_DATA: unable to stat "'+conf_path+'"');
      exit;
   end;

   l:=TstringList.Create;
   l.LoadFromFile(conf_path);
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^'+key+'(.+)';
   for i:=0 to l.Count-1 do begin
       if RegExpr.Exec(l.Strings[i]) then begin
          tmpstr:=RegExpr.Match[1];
          tmpstr:=AnsiReplaceText(tmpstr,'''','');
          tmpstr:=AnsiReplaceText(tmpstr,'=','');
          result:=trim(tmpstr);
          break;
       end;
   end;

   l.free;
   RegExpr.free;


end;
 //#############################################################################

procedure tdansguardian.DANSGUARDIAN_TEMPLATE();
var
DansGuardianHTMLTemplate:string;
l:TstringList;
i:integer;
begin

DansGuardianHTMLTemplate:=SYS.GET_INFO('DansGuardianHTMLTemplate');
if length(DansGuardianHTMLTemplate)<10 then begin
   if FileExists('/usr/share/artica-postfix/bin/install/dansguardian/template.html') then begin
      logs.DebugLogs('Starting......: Dansguardian installing new template file..');
      SYS.set_INFO('DansGuardianHTMLTemplate',logs.ReadFromFile('/usr/share/artica-postfix/bin/install/dansguardian/template.html'));
      DansGuardianHTMLTemplate:=SYS.GET_INFO('DansGuardianHTMLTemplate');
   end;

end;


DansGuardianHTMLTemplate:=SYS.GET_INFO('DansGuardianHTMLTemplate');
l:=TstringList.Create;
l.Add('/etc/dansguardian/languages/ukenglish/template.html');
l.add('/etc/dansguardian/languageslithuanian/template.html');
l.add('/etc/dansguardian/languagesptbrazilian/template.html');
l.add('/etc/dansguardian/languagesslovak/template.html');
l.add('/etc/dansguardian/languagesitalian/template.html');
l.add('/etc/dansguardian/languagesmalay/template.html');
l.add('/etc/dansguardian/languagesportuguese/template.html');
l.add('/etc/dansguardian/languageshebrew/template.html');
l.add('/etc/dansguardian/languagesrussian-koi8-r/template.html');
l.add('/etc/dansguardian/languagesfrench/template.html');
l.add('/etc/dansguardian/languagesdanish/template.html');
l.add('/etc/dansguardian/languageschinesegb2312/template.html');
l.add('/etc/dansguardian/languagesjapanese/template.html');
l.add('/etc/dansguardian/languagesukenglish/template.html');
l.add('/etc/dansguardian/languagesturkish/template.html');
l.add('/etc/dansguardian/languagesmxspanish/template.html');
l.add('/etc/dansguardian/languagespolish/template.html');
l.add('/etc/dansguardian/languagesspanish/template.html');
l.add('/etc/dansguardian/languagesswedish/template.html');
l.add('/etc/dansguardian/languageshungarian/template.html');
l.add('/etc/dansguardian/languagesarspanish/template.html');
l.add('/etc/dansguardian/languagesbulgarian/template.html');
l.add('/etc/dansguardian/languagesindonesian/template.html');
l.add('/etc/dansguardian/languageschinesebig5/template.html');
l.add('/etc/dansguardian/languagesgerman/template.html');
l.add('/etc/dansguardian/languagesczech/template.html');
l.add('/etc/dansguardian/languagesdutch/template.html');
l.add('/etc/dansguardian/languagesrussian-1251/template.html');
      logs.DebugLogs('Starting......: Dansguardian installing template file in all language');
for i:=0 to l.Count-1 do begin
    if FileExists(l.Strings[i]) then logs.WriteToFile(DansGuardianHTMLTemplate,l.Strings[i]);
end;
    l.free;


end;
//##############################################################################
function tdansguardian.CheckUserButton():boolean;
var
   l:TstringList;
   RegExpr     :TRegExpr;
   i:integer;
   DansGuardianEnableUserArticaIP:string;
   script:string;
begin
result:=false;
DansGuardianEnableUserArticaIP:=trim(SYS.GET_INFO('DansGuardianEnableUserArticaIP'));

if not FileExists('/etc/artica-postfix/settings/Daemons/DansGuardianHTMLTemplate') then exit();

script:='<script>';
script:=script+'function ljs(){';
script:=script+'var myhostname="'+DansGuardianEnableUserArticaIP+'";';
script:=script+'var myport="";var myurl="-URL-";';
script:=script+'var myreason="-REASONLOGGED-";var hostname=location.hostname;';
script:=script+'if(myhostname.length==0){myhostname=hostname;}if(myport.length==0){myport="9000";}';
script:=script+'var src="https://"+myhostname+":"+myport+"/dansguardian.users.index.php?uri="+myurl+"&myreason="+myreason;';
script:=script+'document.location.href=src;';
script:=script+'}';
script:=script+'</script><tr><td colspan=2 align="center"><input type="button" OnClick="javascript:ljs();" value="Continue..."></td></tr>';



   l:=TstringList.Create;
   l.LoadFromFile('/etc/artica-postfix/settings/Daemons/DansGuardianHTMLTemplate');
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='USER_BUTTON';
   for i:=0 to l.Count-1 do begin
      if RegExpr.Exec(l.Strings[i]) then begin
         logs.DebugLogs('Starting......: Dansguardian Enable release banned site: ' + IntToStr(DansGuardianEnableUserFrontEnd));
         if DansGuardianEnableUserFrontEnd=1 then l.Strings[i]:='<!-- USER_BUTTON -->'+ script else l.Strings[i]:='<!-- USER_BUTTON -->';
         result:=true;
         break;
      end;
   end;
   l.SaveToFile('/etc/artica-postfix/settings/Daemons/DansGuardianHTMLTemplate');
   RegExpr.free;
   l.free;
end;
//#############################################################################
procedure tdansguardian.DANSGUARDIAN_CONFIG_VALUE_SET(key:string;value:string);
var
   l           :TstringList;
   RegExpr     :TRegExpr;
   i           :integer;
   found       :boolean;
begin
    found:=false;
    if not FileExists(CONF_PATH()) then exit;
    RegExpr:=TRegExpr.Create;
    l:=TstringList.create;

    RegExpr.Expression:='^'+Lowercase(key)+'[\s=]+(.*)';
    l.LoadFromFile(CONF_PATH());
    For i:=0 to l.Count-1 do begin
      if RegExpr.Exec(Lowercase(l.Strings[i])) then begin
              found:=true;
              l.Strings[i]:=key + ' = ' + value;
              break;
         end;

    end;

    if not found then begin
        logs.DebugLogs('Starting......: Dansguardian adding setting '+ key + ' "' + value+'"');
        l.Add(key + ' = ' + value);
    end;

    logs.WriteToFile(l.Text,CONF_PATH());
    RegExpr.free;
    l.free;

end;


//#############################################################################
 procedure tdansguardian.C_ICAP_VALUE_SET(key:string;value:string);
var
   l           :TstringList;
   RegExpr     :TRegExpr;
   i           :integer;
   found       :boolean;
   keyF        :string;

begin
    found:=false;
    if not FileExists(C_ICAP_CONF_PATH()) then begin
       logs.Debuglogs('C_ICAP_VALUE_SET:: unable to stat c-icap.conf');
       exit;
    end;
    RegExpr:=TRegExpr.Create;
    l:=TstringList.create;
    keyF:=key;
    keyF:=AnsiReplaceText(keyF,'.','\.');
    RegExpr.Expression:='^'+keyF+'\s+(.*)';
    l.LoadFromFile(C_ICAP_CONF_PATH());
    For i:=0 to l.Count-1 do begin
      if RegExpr.Exec(l.Strings[i]) then begin
              found:=true;
              logs.Debuglogs('C_ICAP_VALUE_SET:: (modify) '+key + ' ' + value);
              l.Strings[i]:=key + ' ' + value;
              break;
         end else begin


         end;

    end;

    if not found then begin
        logs.Debuglogs('C_ICAP_VALUE_SET:: (Add) '+key + ' ' + value);
        l.Add(key + ' ' + value);
    end;

    l.SaveToFile(C_ICAP_CONF_PATH());
    RegExpr.free;
    l.free;

end;


//#############################################################################
function tdansguardian.DANSGUARDIAN_BIN_VERSION(version:string):int64;
var
   tmp2           :string;
begin
   result:=0;
   tmp2:=trim(AnsiReplaceText(version,'-',''));
   tmp2:=trim(AnsiReplaceText(version,'.',''));
   if length(tmp2)=3 then tmp2:=tmp2+'0';
   if length(tmp2)=2 then tmp2:=tmp2+'00';
   if not TryStrToInt64(tmp2,result) then writeln('int64 failed');
end;
//#############################################################################
end.
