unit postfix_class;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,IniFiles, Process,logs,unix,RegExpr in 'RegExpr.pas',zsystem,openldap,miltergreylist,lighttpd,cyrus;

  type
  tpostfix=class


private
     LOGS:Tlogs;
     D:boolean;
     SYS:TSystem;
     artica_path:string;
     postfixServices:TstringList;
     PostfixEnableSubmission:integer;
     EnablePolicydWeight:integer;
     MilterGreyListEnabled:integer;
     EnablePostfixMultiInstance:integer;
     EnableStopPostfix:integer;
     EnablePostfix:integer;
     ActAsSMTPGatewayStatistics:integer;
     cyrus:Tcyrus;
    dbg:boolean;
    PROCEDURE SET_LDAP_COMPLIANCE();
    procedure POSTFIX_CHECK_LDAP();
    procedure hash_postfix_allowed_connections();
    procedure PARSE_POSTFIX_BINARY_OUTPUT(filename:string);
public
    MYSQMAIL_STARTUP:string;
    procedure   Free;
    constructor Create(const zSYS:Tsystem);
    procedure   SAVE_CERTIFICATE();
    function    READ_CONF(key:string):string;
    procedure   POSTFIX_STOP();
    function    STATUS():string;
    function    MAIN_CONF_PATH():string;
    function    WRITE_CONF(key:string;value:string):string;
    function    SOCKET_PATH():string;
    procedure   POSTFIX_START();
    function    POSTFIX_PID():string;
    function    POSTFIX_PID_PATH():string;
    function    POSFTIX_POSTCONF_PATH():string;
    function    POSFTIX_MASTER_CF_PATH:string;
    function    POSTFIX_VERSION():string;
    procedure   POSTFIX_CHECK_SASLDB2();
    function    SASLPASSWD_PATH():string;
    function    POSTFIX_QUEUE_DIRECTORY():string;
    procedure   POSTFIX_INITIALIZE_FOLDERS();
    function    POSTFIX_STATUS():string;
    function    POSTFIX_INT_VERSION(string_version:string):integer;
    procedure   POSTFIX_INI_TD();
    function    POSTFIX_LDAP_COMPLIANCE():boolean;
    function    POSTFIX_PCRE_COMPLIANCE():boolean;
    procedure   POSFTIX_VERIFY_MAINCF();
    procedure   POSTFIX_RELOAD();
    function    POSFTIX_READ_QUEUE(queuename:string):string;
    function    POSTFIX_READ_QUEUE_MESSAGE(MessageID:string):string;
    function    POSTFIX_EXTRACT_MAINCF(key:string):string;
    procedure   POSTFIX_MOVE_CORRUPTED_QUEUE();
    procedure   POSTFIX_DISABLE_MGREYLIST();
    function    master_path():string;
    function    Is_CYRUS_enabled_in_master_cf():boolean;
    function    postfix_path():string;
    function    FIX_RETRY_DAEMON():boolean;
    procedure   GENERATE_CERTIFICATE();
    function    QUEUE_PATH():string;
    procedure   VERIFY_BOUNCE_TEMPLATE();
    function    MSMTP_VERSION():string;
    function    PFLOGSUMM_VERSION():string;
    procedure   postmap_standard_db();
    procedure   REMOVE();
    function    MAILLOG_TAIL(Filter:string):string;
    function    MON():string;
    procedure    POSTFIX_START_LIMITED();



    procedure    MYSQMAIL_START();
    procedure    MYSQMAIL_STOP();
    function     MYSQMAIL_STATUS():string;
    function     MYSQMAIL_PID():string;


    function     gnarwl_VERSION():string;
    function     gnarwl_path():string;
    procedure    gnarwl_set_config();


END;

implementation

constructor tpostfix.Create(const zSYS:Tsystem);
begin
       forcedirectories('/etc/artica-postfix');
       forcedirectories('/opt/artica/tmp');
       LOGS:=tlogs.Create();
       SYS:=zSYS;
       dbg:=LOGS.COMMANDLINE_PARAMETERS('debug');
       MYSQMAIL_STARTUP:=SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.maillog.php';
       EnablePostfix:=1;
       EnableStopPostfix:=0;
       if not TryStrToInt(SYS.GET_INFO('EnablePolicydWeight'),EnablePolicydWeight) then EnablePolicydWeight:=0;
       if not TryStrToInt(SYS.GET_INFO('MilterGreyListEnabled'),MilterGreyListEnabled) then MilterGreyListEnabled:=0;
       if not TryStrToInt(SYS.GET_INFO('EnableStopPostfix'),EnableStopPostfix) then EnableStopPostfix:=0;
       if not TryStrToInt(SYS.GET_INFO('ActAsSMTPGatewayStatistics'),ActAsSMTPGatewayStatistics) then ActAsSMTPGatewayStatistics:=0;



       if not TryStrToInt(SYS.GET_INFO('EnablePostfixMultiInstance'),EnablePostfixMultiInstance) then begin
          EnablePostfixMultiInstance:=0;
          SYS.set_INFO('EnablePostfixMultiInstance','0');
       end;


       if EnableStopPostfix=0 then EnablePostfix:=1;

       if FileExists('/etc/artica-postfix/OPENVPN_APPLIANCE') then EnablePostfix:=0;


       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;
end;
//##############################################################################
procedure tpostfix.free();
begin
    logs.Free;
    postfixServices.free;
end;
//##############################################################################
function tpostfix.MAIN_CONF_PATH():string;
begin
    if FileExists('/etc/dkim-filter.conf') then exit('/etc/dkim-filter.conf');
    if FileExists('/etc/mail/dkim-filter.conf') then exit('/etc/mail/dkim-filter.conf');

end;
//##############################################################################
function tpostfix.SASLPASSWD_PATH():string;
begin
  if FileExists('/opt/artica/bin/saslpasswd2') then exit('/opt/artica/bin/saslpasswd2');
  if FileExists('/usr/sbin/saslpasswd2') then exit('/usr/sbin/saslpasswd2');
end;
//##############################################################################
function tpostfix.master_path:string;
begin
if FIleExists('/usr/lib/postfix/master') then exit('/usr/lib/postfix/master');
end;
//##############################################################################
function tpostfix.postfix_path():string;
begin
if FIleExists('/usr/sbin/postfix') then exit('/usr/sbin/postfix');
end;
//##############################################################################
function tpostfix.gnarwl_path():string;
begin
if FIleExists('/usr/bin/gnarwl') then exit('/usr/bin/gnarwl');
end;
//##############################################################################
function tpostfix.gnarwl_VERSION():string;
var
    tmp:string;
    RegExpr:TRegExpr;
    l:Tstringlist;
    i:integer;
    D:boolean;
begin
D:=false;
D:=SYS.COMMANDLINE_PARAMETERS('--verbose');
result:=trim(SYS.GET_CACHE_VERSION('APP_GNARWL'));
  if not D then if length(result)>0 then exit;
   tmp:=logs.FILE_TEMP();
   RegExpr:=TRegExpr.Create;
   if not FileExists(gnarwl_path()) then exit;
   if d then writeln(gnarwl_path() +' -h >' + tmp + ' 2>&1');
   fpsystem(gnarwl_path() +' -h >' + tmp + ' 2>&1');
   if not fileExists(tmp) then begin
      writeln('unable to stat ' + tmp);
      exit;
   end;

   l:=Tstringlist.Create;
   l.LoadFromFile(tmp);
   RegExpr.Expression:='^GNARWL\(v([0-9\.]+)';
   for i:=0 to l.Count-1 do begin
       writeln(l.Strings[i]);
       if RegExpr.Exec(l.Strings[i]) then begin
          result:=trim(RegExpr.Match[1]);
          break;
       end;
   end;


   l.free;
   logs.DeleteFile(tmp);

   SYS.SET_CACHE_VERSION('APP_GNARWL',result);

end;
//#############################################################################

procedure tpostfix.REMOVE();
begin
POSTFIX_STOP();
fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --remove "postfix"');
fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --remove "postfix-ldap"');
if DirectoryExists('/usr/lib/postfix') then logs.OutputCmd('/bin/rm -rf /usr/lib/postfix');
if FIleExists(POSFTIX_POSTCONF_PATH()) then logs.DeleteFile(POSFTIX_POSTCONF_PATH());
if fileExists('/usr/sbin/postfix') then logs.DeleteFile('/usr/sbin/postfix');
logs.DeleteFile('/etc/artica-postfix/versions.cache');
fpsystem('/usr/share/artica-postfix/bin/artica-install --write-versions');
fpsystem('/usr/share/artica-postfix/bin/process1 --force');
end;


procedure tpostfix.gnarwl_set_config();
var
l:TstringList;
xldap:topenldap;

begin

l:=Tstringlist.Create;
xldap:=topenldap.Create;

l.Add('map_sender $sender');
l.Add('map_receiver $recepient');
l.Add('map_subject $subject');
l.Add('map_field $begin vacationStart');
l.Add('map_field $end vacationEnd ');
l.Add('map_field $fullname cn');
l.Add('map_field $deputy vacationForward');
l.Add('server '+xldap.ldap_settings.servername);
l.Add('port '+xldap.ldap_settings.Port);
l.Add('scope sub');
l.Add('login cn='+xldap.ldap_settings.admin+','+xldap.ldap_settings.suffix);
l.Add('password '+xldap.ldap_settings.password);
l.Add('protocol 3');
l.Add('base '+xldap.ldap_settings.suffix);
l.Add('queryfilter (&(mail=$recepient)(vacationActive=TRUE))');
l.Add('result vacationInfo');
l.Add('blockfiles /var/lib/gnarwl/block/');
l.Add('umask 0644');
l.Add('blockexpire 48');
l.Add('mta '+artica_path+'/bin/artica-msmtp --syslog=on --host=127.0.0.1 --read-envelope-from --read-recipients --');
l.Add('maxreceivers 64');
l.Add('maxheader 512');
l.Add('charset ISO8859-1');
l.Add('badheaders /var/lib/gnarwl/badheaders.db');
l.Add('blacklist /var/lib/gnarwl/blacklist.db');
l.Add('forceheader /var/lib/gnarwl/header.txt');
l.Add('forcefooter /var/lib/gnarwl/footer.txt');
l.Add('recvheader To Cc');
l.Add('# 0 - Critical messages only. Anything, gnarwl cannot continue afterwards.');
l.Add('# 1 - Warnings. Gnarwl can continue, but with reduced functionality.');
l.Add('# 2 - Info. General information on gnarwl''s status.');
l.Add('# 3 - Debug. ');
l.Add('loglevel 1');

try
   l.SaveToFile('/etc/gnarwl.cfg');
except
   logs.Syslogs('tpostfix.gnarwl_set_config():: FATAL ERROR While saving /etc/gnarwl.cfg');
end;

Logs.OutputCmd('/bin/chown gnarwl:gnarwl /etc/gnarwl.cfg');
Logs.OutputCmd('/bin/chmod 644 /etc/gnarwl.cfg');

l.free;
xldap.free;

end;
//#############################################################################

function tpostfix.POSTFIX_VERSION():string;
var
    ver:string;
    tmp:string;
    RegExpr:TRegExpr;

begin
   result:=SYS.GET_CACHE_VERSION('APP_POSTFIX');
   if length(result)>0 then exit;
   tmp:=logs.FILE_TEMP();
   RegExpr:=TRegExpr.Create;
   if not FileExists(POSFTIX_POSTCONF_PATH()) then exit;
   fpsystem(POSFTIX_POSTCONF_PATH() +' -h mail_version >' + tmp + ' 2>&1');
   if not fileExists(tmp) then exit;
   ver:=logs.ReadFromFile(tmp);
   RegExpr.Expression:='([0-9\.]+)';
   RegExpr.Exec(ver);
   
   logs.DeleteFile(tmp);
   result:=trim(RegExpr.Match[1]);
   SYS.SET_CACHE_VERSION('APP_POSTFIX',result);

end;
//#############################################################################
function tpostfix.MSMTP_VERSION():string;
var
    tmp:string;
    RegExpr:TRegExpr;
    l:TstringList;
    i:integer;
begin
result:=SYS.GET_CACHE_VERSION('APP_MSMTP');
   if length(result)>0 then exit;
   tmp:=logs.FILE_TEMP();
   RegExpr:=TRegExpr.Create;
   if not FileExists('/usr/share/artica-postfix/bin/artica-msmtp') then exit;
   fpsystem('/usr/share/artica-postfix/bin/artica-msmtp --version >' + tmp + ' 2>&1');
   if not fileExists(tmp) then exit;

   l:=TstringList.Create;
   l.LoadFromFile(tmp);
   RegExpr.Expression:='^msmtp version\s+([0-9\.]+)';
   for i:=0 to l.Count-1 do begin
       if RegExpr.Exec(l.Strings[i]) then begin
          result:=RegExpr.Match[1];
          break;
       end;
   end;

   if length(result)>0 then SYS.SET_CACHE_VERSION('APP_MSMTP',result);
   l.free;
   RegExpr.free;

end;
//#############################################################################
function tpostfix.PFLOGSUMM_VERSION():string;
var
    tmp:string;
    RegExpr:TRegExpr;
    l:TstringList;
    i:integer;
begin



result:=SYS.GET_CACHE_VERSION('APP_PFLOGSUMM');
   if length(result)>0 then exit;
   tmp:=logs.FILE_TEMP();
   RegExpr:=TRegExpr.Create;
   if not FileExists('/usr/sbin/pflogsumm') then exit;
   fpsystem('/usr/sbin/pflogsumm --version >' + tmp + ' 2>&1');
   if not fileExists(tmp) then exit;

   l:=TstringList.Create;
   l.LoadFromFile(tmp);
   RegExpr.Expression:='^pflogsumm.pl\s+([0-9\.]+)';
   for i:=0 to l.Count-1 do begin
       if RegExpr.Exec(l.Strings[i]) then begin
          result:=RegExpr.Match[1];
          break;
       end;
   end;

   if length(result)>0 then SYS.SET_CACHE_VERSION('APP_PFLOGSUMM',result);
   l.free;
   RegExpr.free;

end;
//#############################################################################
function tpostfix.POSTFIX_INT_VERSION(string_version:string):longint;
var
    vercompile:string;
    int:longint;
    RegExpr:TRegExpr;

begin
   result:=0;
   int:=0;
   RegExpr:=TRegExpr.Create;
   writeln(string_version);
   RegExpr.Expression:='([0-9]+)\.([0-9]+)\.([0-9]+)';
   if RegExpr.Exec(string_version) then begin
      vercompile:=RegExpr.Match[1]+RegExpr.Match[2]+RegExpr.Match[3];
     if not TryStrToint(vercompile,int) then writeln('failed');
     result:=int;
      exit;
   end;


   RegExpr.Expression:='([0-9]+)\.([0-9]+)-([0-9]+)';
   if RegExpr.Exec(string_version) then begin
      vercompile:=RegExpr.Match[1]+RegExpr.Match[2]+'0';
      TryStrToint(vercompile,result);
      exit;
   end;

   RegExpr.free;

end;
//#############################################################################
function tpostfix.POSTFIX_QUEUE_DIRECTORY():string;
var
    ver:string;
    tmp:string;
begin
   if not FileExists(POSFTIX_POSTCONF_PATH()) then exit;
   tmp:=logs.FILE_TEMP();
   fpsystem(POSFTIX_POSTCONF_PATH() +' -h queue_directory >'+tmp+' 2>&1');
   if not FileExists(tmp) then exit;
   ver:=logs.ReadFromFile(tmp);
   logs.DeleteFile(tmp);
   exit(trim(ver));

end;
//#############################################################################





function tpostfix.READ_CONF(key:string):string;
var
    RegExpr:TRegExpr;
    FileDatas:TStringList;
    i:integer;
begin
 if not FileExists(MAIN_CONF_PATH()) then exit;
 FileDatas:=TstringList.Create;
 FileDatas.LoadFromFile(MAIN_CONF_PATH());
 RegExpr:=TRegExpr.Create;
 RegExpr.Expression:='^'+key+'\s+(.+)';
 for i:=0 to FileDatas.Count-1 do begin
     if RegExpr.Exec(FileDatas.Strings[i]) then begin
         result:=RegExpr.Match[1];
         break;
     end;

 end;
         FileDatas.Free;
         RegExpr.Free;

end;
//##############################################################################
function tpostfix.SOCKET_PATH():string;
begin
exit('/var/run/dkim-filter/dkim-filter.sock');
end;
//##############################################################################
function tpostfix.WRITE_CONF(key:string;value:string):string;
var
    RegExpr:TRegExpr;
    FileDatas:TStringList;
    i:integer;
    found:boolean;
    main_path:string;
begin
result:='';
 found:=false;
 main_path:=MAIN_CONF_PATH();
 if not FileExists(main_path) then exit;
 FileDatas:=TstringList.Create;
 FileDatas.LoadFromFile(main_path);
 RegExpr:=TRegExpr.Create;
 RegExpr.Expression:='^'+key+'\s+(.+)';
 for i:=0 to FileDatas.Count-1 do begin
     if RegExpr.Exec(FileDatas.Strings[i]) then begin
         FileDatas.Strings[i]:=key+chr(9)+value;
         FileDatas.SaveToFile(main_path);
         found:=true;
         break;
     end;

 end;

         if not found then begin
            FileDatas.Add(key+chr(9)+value);
            FileDatas.SaveToFile(main_path);
         end;


         FileDatas.Free;
         RegExpr.Free;

end;
//##############################################################################
PROCEDURE tpostfix.SET_LDAP_COMPLIANCE();
begin
  if not FileExists(POSFTIX_POSTCONF_PATH()) then exit;
  if POSTFIX_LDAP_COMPLIANCE() then begin
         logs.set_INFOS('postfix_ldap_compliance','1');
         exit;
  end;

  logs.set_INFOS('postfix_ldap_compliance','0');

end;
//##############################################################################
procedure tpostfix.POSTFIX_CHECK_LDAP();

begin

if not POSTFIX_LDAP_COMPLIANCE() then begin
   if FileExists('/home/artica/packages/postfix-ldap.deb') then begin
       if FIleExists('/usr/bin/dpkg') then begin
            fpsystem('/usr/bin/dpkg -i /home/artica/packages/postfix-ldap.deb');
       end;
   end;

end;

end;
//##############################################################################
procedure tpostfix.POSFTIX_VERIFY_MAINCF();


var
   mailbox_transport:string;
begin


       if not FileExists(POSFTIX_POSTCONF_PATH()) then begin
           logs.Debuglogs('POSFTIX_VERIFY_MAINCF() -> POSFTIX_POSTCONF_PATH !! null !!');
           exit;
        end;


        if FileExists('/etc/postfix/post-install') then begin
           if FIleExists('/usr/lib/postfix/postfix-files') then begin
                if FileExists('/etc/artica-postfix/pids/postinstall.time') then begin
                   if SYS.FILE_TIME_BETWEEN_MIN('/etc/artica-postfix/pids/postinstall.time')>30 then logs.DeleteFile('/etc/artica-postfix/pids/postinstall.time');
                end;
                 if not FileExists('/etc/artica-postfix/pids/postinstall.time') then begin
                    forceDirectories('/etc/artica-postfix/pids');
                    fpsystem('/etc/postfix/post-install create-missing config_directory=/etc/postfix daemon_directory=/usr/lib/postfix >/etc/artica-postfix/pids/postinstall.time 2>&1');
                 end;
           end;

        end;

        if FileExists('/etc/postfix/bounce.template.cf') then begin
           logs.OutputCmd('/bin/chown root:root /etc/postfix/bounce.template.cf')
        end else begin
           logs.OutputCmd('/bin/cp /usr/share/artica-postfix/bin/install/postfix/bounce.cf.default /etc/postfix/bounce.template.cf')
        end;


        mailbox_transport:=POSTFIX_EXTRACT_MAINCF('mailbox_transport');
        logs.Debuglogs('Starting......: Postfix mailbox_transport=' + mailbox_transport);



end;
//#####################################################################################
procedure tpostfix.MYSQMAIL_START();
var
   pid:string;
   log_path:string;
   count:integer;
   cmd:string;
   stime:string;
   detect_tail:string;
   pidlist:Tstringlist;
   pidlistInt:integer;
   i:integer;
begin



log_path:=SYS.MAILLOG_PATH();


pid:=MYSQMAIL_PID();
if SYS.PROCESS_EXIST(pid) then begin
      logs.DebugLogs('Starting......: artica-postfix realtime logs already running with pid '+pid);
      if ActAsSMTPGatewayStatistics=0 then begin
            if EnablePostfix=0 then MYSQMAIL_STOP();
      end;
      exit;
end;



if not FileExists(log_path) then begin
   logs.Syslogs('Starting......: artica-postfix realtime logs unable to locate mail logs !!');
   exit;
end;
logs.DebugLogs('Starting......: artica-postfix realtime logs path: '+log_path);



stime:=logs.DateTimeNowSQL();
stime:=AnsiReplaceText(stime,' ','-');
stime:=AnsiReplaceText(stime,':','-');
detect_tail:='/usr/bin/tail -f -n 0 '+log_path;
pidlist:=Tstringlist.Create;
pidlist.AddStrings(SYS.PIDOF_PATTERN_PROCESS_LIST(detect_tail));
for i:=0 to pidlist.count-1 do begin
   if not TryStrToInt(pidlist.Strings[i],pidlistInt) then continue;
   if pidlistInt>5 then begin
       logs.DebugLogs('Starting......: artica-postfix kill old tail : '+IntTOStr(pidlistInt));
       fpsystem('/bin/kill -9 '+ intToStr(pidlistInt));
   end;
end;



cmd:='/usr/bin/tail -f -n 0 '+log_path+'|'+MYSQMAIL_STARTUP+' >>/var/log/artica-postfix/postfix-logger-start.log 2>&1 &';
logs.Debuglogs(cmd);
fpsystem(cmd);
pid:=SYS.PIDOF_PATTERN(MYSQMAIL_STARTUP);
count:=0;
while not SYS.PROCESS_EXIST(pid) do begin

        sleep(100);
        inc(count);
        if count>40 then begin
           logs.DebugLogs('Starting......: artica-postfix realtime logs (timeout)');
           break;
        end;
        pid:=SYS.PIDOF_PATTERN(MYSQMAIL_STARTUP);
  end;


  pid:=SYS.PIDOF_PATTERN(MYSQMAIL_STARTUP);
if SYS.PROCESS_EXIST(pid) then begin
      logs.DebugLogs('Starting......: artica-postfix realtime logs success with pid '+pid);
      exit;
end else begin
    logs.DebugLogs('Starting......: artica-postfix realtime logs failed');
end;
end;
//#####################################################################################
function tpostfix.MYSQMAIL_STATUS():string;
var
pidpath:string;
begin
SYS.MONIT_DELETE('APP_POSTFIX');
SYS.MONIT_DELETE('APP_ARTICA_MYSQMAIL');
pidpath:=logs.FILE_TEMP();
fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.status.php --postfix-logger >'+pidpath +' 2>&1');
result:=logs.ReadFromFile(pidpath);
logs.DeleteFile(pidpath);
end;
//#####################################################################################
function tpostfix.MYSQMAIL_PID():string;
var
   pid:string;
begin

if FileExists('/etc/artica-postfix/exec.maillog.php.pid') then begin
   pid:=SYS.GET_PID_FROM_PATH('/etc/artica-postfix/exec.maillog.php.pid');
   logs.Debuglogs('MYSQMAIL_PID /etc/artica-postfix/exec.maillog.php.pid='+pid);
   if SYS.PROCESS_EXIST(pid) then result:=pid;
   exit;
end;


result:=SYS.PIDOF_PATTERN(MYSQMAIL_STARTUP);
logs.Debuglogs(MYSQMAIL_STARTUP+' pid='+pid);
end;
//#####################################################################################
procedure tpostfix.hash_postfix_allowed_connections();
var
   l:TstringList;
   s:Tstringlist;
   i:integer;
begin

if not FileExists('/etc/postfix/postfix_allowed_connections') then begin
   logs.OutputCmd('/bin/touch /etc/postfix/postfix_allowed_connections');
end;

if FileExists('/etc/artica-postfix/settings/Daemons/PostfixAutoBlockWhiteList') then begin
   l:=Tstringlist.Create;
   l.LoadFromFile('/etc/artica-postfix/settings/Daemons/PostfixAutoBlockWhiteList');
   s:=Tstringlist.Create;
   for i:=0 to l.Count-1 do begin
     if length(trim(l.Strings[i]))=0 then continue;
     s.Add(l.Strings[i]+chr(9)+'OK');
   end;
   logs.WriteToFile(s.Text,'/etc/postfix/postfix_allowed_connections');
   s.free;
   l.free;
end;

logs.OutputCmd('/usr/sbin/postmap hash:/etc/postfix/postfix_allowed_connections');
end;
//#####################################################################################

procedure tpostfix.MYSQMAIL_STOP();
var
   pid:string;
begin
pid:=MYSQMAIL_PID();
logs.NOTIFICATION('order to stop Postfix logger...','An order has been executed to stop postfix-logger','smtp' );
if SYS.PROCESS_EXIST(pid) then begin
      writeln('artica-postfix realtime logs.: Stopping pid '+pid);
      while SYS.PROCESS_EXIST(pid) do begin
           fpsystem('/bin/kill '+pid);
           sleep(100);
           pid:=MYSQMAIL_PID();
      end;
end else begin
      writeln('artica-postfix realtime logs.: Already stopped');
      exit;
end;

pid:=SYS.PIDOF_PATTERN(MYSQMAIL_STARTUP);
if not SYS.PROCESS_EXIST(pid) then begin
      writeln('artica-postfix realtime logs.: stopped');
end else begin
      writeln('artica-postfix realtime logs.: Failed to stop');
end;

end;
//#####################################################################################

function tpostfix.POSTFIX_EXTRACT_MAINCF(key:string):string;
var
   List:TstringList;
   RegExpr:TRegExpr;
   i:integer;

begin

    if not FileExists('/etc/postfix/main.cf') then exit;


    try
    list:=TstringList.Create;
    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='^' + key + '[=\s]+(.+)';

    list.LoadFromFile('/etc/postfix/main.cf');
    For i:=0 to list.Count -1 do begin

         if RegExpr.Exec(list.Strings[i]) then begin
            result:=RegExpr.Match[1];
            break;
         end;
    end;

    finally
    RegExpr.Free;
    List.free;
    end;

end;
//#####################################################################################
procedure tpostfix.VERIFY_BOUNCE_TEMPLATE();
var bounce_template_file:string;

begin
  bounce_template_file:=POSTFIX_EXTRACT_MAINCF('bounce_template_file');
  if length(bounce_template_file)=0 then exit;
  if not FileExists(bounce_template_file) then begin
        logs.DebugLogs('Starting......: Postfix daemon load default bounce template file');
        logs.OutputCmd('/bin/cp '+artica_path+'/bin/install/postfix/bounce.cf.default '+bounce_template_file);
  end;
end;
//#####################################################################################

procedure tpostfix.POSTFIX_RELOAD();
var
   pid:string;
   pidnum:integer;
   cmdline_verbose:string;
   tmpstr:string;
begin

        if EnableStopPostfix=1 then writeln('Starting......: Postfix Warning Sopping postfix feature has been enabled...');
        if EnablePostfix=0 then POSTFIX_STOP();
        logs.Debuglogs('POSTFIX_START:: Start POSTFIX service server ');
        logs.Debuglogs('POSTFIX_START:: Pid path="'+POSTFIX_PID_PATH()+'"');
        logs.Debuglogs('POSTFIX_START:: Version="'+POSTFIX_VERSION()+'"');
        logs.Debuglogs('POSTFIX_START:: queue directory="'+POSTFIX_QUEUE_DIRECTORY()+'"');

        forcedirectories('/etc/amavis/dkim');
        forceDirectories('/var/log/artica-postfix/RTM');
        if SYS.COMMANDLINE_PARAMETERS('--verbose') then cmdline_verbose:=' --verbose';

fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.postfix.maincf.php --memory'+cmdline_verbose);



POSTFIX_INI_TD();

POSTFIX_CHECK_LDAP();

SET_LDAP_COMPLIANCE();

POSTFIX_INITIALIZE_FOLDERS();

POSTFIX_CHECK_SASLDB2();

POSFTIX_VERIFY_MAINCF();

VERIFY_BOUNCE_TEMPLATE();

gnarwl_set_config();

GENERATE_CERTIFICATE();

MYSQMAIL_START();



//unrestricted_senders();

POSTFIX_DISABLE_MGREYLIST();

hash_postfix_allowed_connections();

postmap_standard_db();


if(EnablePostfixMultiInstance=1) then begin
    logs.DebugLogs('Starting......: Postfix, please wait, compiling main.cf for multiple instances...');
   fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.postfix-multi.php'+cmdline_verbose);
end else begin
    logs.DebugLogs('Starting......: Postfix, please wait, compiling main.cf...');
    fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.postfix.maincf.php --write-maincf no-restart'+cmdline_verbose);
    logs.DebugLogs('Starting......: Postfix, please wait, compiling Policyd Daemon settings...');
    fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.policyd-weight.php'+cmdline_verbose);
    logs.DebugLogs('Starting......: Postfix, please wait, Checking Artica-filter');
    fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.postfix.maincf.php --artica-filter'+cmdline_verbose);
    logs.DebugLogs('Starting......: Postfix, compiling settings done..');
    //fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.postfix.hashtables.php');
end;




     if FileExists('/etc/init.d/sendmail') then begin
           if not SYS.FileSymbolicExists('/etc/init.d/sendmail') then begin
              logs.Debuglogs('Starting......: stopping sendmail...');
              fpsystem('/etc/init.d/sendmail stop');
              pid:=SYS.PIDOF_PATTERN('sendmail');
              if SYS.PROCESS_EXIST(pid) then begin
              TryStrToInt(pid,pidnum);
                 if pidnum>5 then begin
                     logs.DebugLogs('Starting......: Postfix, killing old sendmail instance: ' +pid+ ' PID..');
                     fpsystem('kill -9 '+pid);
                 end;
              end;
           end;
        end;

SYS.AddShell('postfix');

tmpstr:=logs.FILE_TEMP();
pid:=POSTFIX_PID();
if SYS.PROCESS_EXIST(pid) then begin
   if fileExists('/usr/sbin/postfix') then begin
      fpsystem('/usr/sbin/postfix reload >'+tmpstr+' 2>&1');
      fpsystem('/etc/init.d/artica-postfix start saslauthd  >/dev/null 2>&1 &');
      PARSE_POSTFIX_BINARY_OUTPUT(tmpstr);
      exit
   end;
end;

if fileExists('/usr/sbin/postfix') then begin
   ForceDirectories('/var/spool/postfix/var');
   fpsystem(SYS.LOCATE_GENERIC_BIN('rm')+' -rf /var/spool/postfix/var/run');
   fpsystem(SYS.LOCATE_GENERIC_BIN('ln')+' -s --force /var/run /var/spool/postfix/var/run');
   fpsystem('/usr/sbin/postfix start >'+tmpstr+' 2>&1');
   fpsystem('/etc/init.d/artica-postfix start saslauthd  >/dev/null 2>&1 &');
   PARSE_POSTFIX_BINARY_OUTPUT(tmpstr);
   exit;
end;

end;
//#####################################################################################
procedure tpostfix.PARSE_POSTFIX_BINARY_OUTPUT(filename:string);
var
   l:Tstringlist;
   RegExpr:TRegExpr;
   i:integer;
begin

     l:=tstringlist.Create;
     l.LoadFromFile(filename);
     logs.DeleteFile(filename);
     RegExpr:=TRegExpr.Create;

     for i:=0 to l.Count-1 do begin

         RegExpr.Expression:='error while loading shared libraries';
         logs.DebugLogs('Starting......: Postfix,'+l.Strings[i]);
         if  RegExpr.Exec(l.Strings[i]) then begin
              logs.DebugLogs('Starting......: Postfix, reinstall...');
              fpsystem('/usr/share/artica-postfix/bin/artica-make APP_POSTFIX');
         end;
     end;
end;
//#####################################################################################



procedure tpostfix.postmap_standard_db();
begin
 if FileExists('/etc/postfix/local_domains') then begin
    logs.DebugLogs('Starting......: postmap local_domains');
    logs.OutputCmd('postmap hash:/etc/postfix/local_domains');
 end;

 if FileExists('/etc/postfix/unrestricted_senders') then begin
    logs.DebugLogs('Starting......: postmap unrestricted_senders');
    logs.OutputCmd('postmap hash:/etc/postfix/unrestricted_senders');
 end;

end;
//#####################################################################################
procedure tpostfix.POSTFIX_MOVE_CORRUPTED_QUEUE();
var
   queue:string;
   postfix_queue:string;
begin
postfix_queue:=POSTFIX_QUEUE_DIRECTORY();
queue:=postfix_queue+'/corrupt';

if DirectoryExists(queue) then begin
   writeln('move ',SYS.DirectoryCountFiles(queue),' email(s)');
   logs.OutputCmd('/bin/mv '+queue+'/* '+postfix_queue+'/maildrop/',true);
end else begin
    writeln('Unable to stat '+queue);
    exit;
end;

writeln('Storage area store ',SYS.DirectoryCountFiles(queue),' emails after operation');

end;
//#####################################################################################
procedure tpostfix.POSTFIX_DISABLE_MGREYLIST();
var
   POSFTIX_POSTCONF:string;
   milter:tmilter_greylist;
   line,str:string;
   smtpd_milters:string;
begin

if MilterGreyListEnabled=1 then exit;
milter:=tmilter_greylist.Create(SYS);
line:='unix:'+milter.CheckSocket();
milter.free;
POSFTIX_POSTCONF:=POSFTIX_POSTCONF_PATH();
str:=logs.FILE_TEMP();
fpsystem(POSFTIX_POSTCONF+' -h smtpd_milters >'+str+' 2>&1');
smtpd_milters:=trim(logs.ReadFromFile(str));
smtpd_milters:=AnsiReplaceText(smtpd_milters,line,'');
logs.OutputCmd(POSFTIX_POSTCONF +' -e "smtpd_milters = '+smtpd_milters+'"');
end;
//#####################################################################################
function tpostfix.POSTFIX_LDAP_COMPLIANCE():boolean;
var
   LIST:TstringList;
   i:integer;
begin
  result:=false;
 if not FileExists(POSFTIX_POSTCONF_PATH()) then exit;



 if FileExists('/etc/artica-postfix/postconf-m.conf') then begin
    if SYS.FILE_TIME_BETWEEN_MIN('/etc/artica-postfix/postconf-m.conf')>60 then logs.DeleteFile('/etc/artica-postfix/postconf-m.conf');
 end;

 if not FileExists('/etc/artica-postfix/postconf-m.conf') then fpsystem(POSFTIX_POSTCONF_PATH()+' -m >/etc/artica-postfix/postconf-m.conf 2>&1');
 if not FileExists('/etc/artica-postfix/postconf-m.conf')then exit;
 LIST:=TStringList.Create;
 LIST.LoadFromFile('/etc/artica-postfix/postconf-m.conf');
 for i:=0 to LIST.Count -1 do begin
     if trim(list.Strings[i])='ldap' then begin
        result:=true;
        list.free;
        exit;
     end;

 end;
end;
//##############################################################################
function tpostfix.POSTFIX_PCRE_COMPLIANCE():boolean;
var
   LIST:TstringList;
   i:integer;
begin
  result:=false;
 if not FileExists(POSFTIX_POSTCONF_PATH()) then exit;



 if FileExists('/etc/artica-postfix/postconf-m.conf') then begin
    if SYS.FILE_TIME_BETWEEN_MIN('/etc/artica-postfix/postconf-m.conf')>60 then begin
       logs.Debuglogs('POSTFIX_PCRE_COMPLIANCE:: Delete /etc/artica-postfix/postconf-m.conf cache file');
       logs.DeleteFile('/etc/artica-postfix/postconf-m.conf');
    end else begin
       logs.Debuglogs('POSTFIX_PCRE_COMPLIANCE:: Keep /etc/artica-postfix/postconf-m.conf cache file');
    end;
 end;

 if not FileExists('/etc/artica-postfix/postconf-m.conf') then fpsystem(POSFTIX_POSTCONF_PATH()+' -m >/etc/artica-postfix/postconf-m.conf 2>&1');
 if not FileExists('/etc/artica-postfix/postconf-m.conf')then exit;
 LIST:=TStringList.Create;
 LIST.LoadFromFile('/etc/artica-postfix/postconf-m.conf');
 for i:=0 to LIST.Count -1 do begin
     if trim(list.Strings[i])='pcre' then begin
        result:=true;
        list.free;
        exit;
     end;

 end;
end;
//##############################################################################
procedure tpostfix.SAVE_CERTIFICATE();
begin
    D:=false;
    D:=logs.COMMANDLINE_PARAMETERS('html');

    forcedirectories('/etc/mail');
    WRITE_CONF('PidFile','/var/run/dkim-filter/dkim-filter.pid');
    WRITE_CONF('Socket','local:/var/run/dkim-filter/dkim-filter.sock');
    WRITE_CONF('KeyFile','/etc/mail/mail.filter.private');
    WRITE_CONF('Domain','/etc/mail/localdomains.txt');
    WRITE_CONF('Selector','mail');
    WRITE_CONF('Syslog','yes');
    WRITE_CONF('AutoRestart','yes');
    WRITE_CONF('X-Header','yes');
    WRITE_CONF('SendReports','yes');
    WRITE_CONF('InternalHosts','/etc/mail/localNetworks.txt');



    fpsystem(artica_path + '/bin/artica-ldap -localdomains /etc/mail/localdomains.txt');
    fpsystem(artica_path + '/bin/artica-ldap -pnetworks /etc/mail/localNetworks.txt');

    fpsystem('/bin/chown postfix:postfix /etc/mail/localdomains.txt'+ ' >/dev/null 2>&1');
    fpsystem('/bin/chown postfix:postfix /etc/mail/localNetworks.txt'+ ' >/dev/null 2>&1');



   GENERATE_CERTIFICATE();

end;
//##############################################################################
procedure tpostfix.POSTFIX_INI_TD();
var
   myFile : TStringList;
begin
  if EnablePostfix=0 then exit();

  IF not sys.COMMANDLINE_PARAMETERS('--force') then begin
    if FileExists('/etc/init.d/postfix.old') then exit;
  end;

  myFile:=TstringList.Create;
  myFile.Add('#!/bin/sh');
  myFile.Add('#Begin /etc/init.d/postfix');


    myFile.Add('### BEGIN INIT INFO');
    myFile.Add('# Provides:          Postfix SMTP MTA');
    myFile.Add('# Required-Start:    $local_fs $remote_fs $syslog $named $network $time');
    myFile.Add('# Required-Stop:     $local_fs $remote_fs $syslog $named $network');
    myFile.Add('# Should-Start:');
    myFile.Add('# Should-Stop:');
    myFile.Add('# Default-Start:     2 3 4 5');
    myFile.Add('# Default-Stop:      0 1 6');
    myFile.Add('# Short-Description: Start Postfix daemon');
    myFile.Add('# chkconfig: 2345 11 89');
    myFile.Add('# description: Postfix Daemon');
    myFile.Add('### END INIT INFO');
    myFile.Add('');

    myFile.Add('case "$1" in');
    myFile.Add(' start)');
    myFile.Add('    /usr/share/artica-postfix/bin/artica-install -watchdog postfix-single $2 $3');
    myFile.Add('    ;;');
    myFile.Add('');
    myFile.Add('  stop)');
    myFile.Add('    /usr/share/artica-postfix/bin/artica-install -shutdown postfix-single $2 $3');
    myFile.Add('    ;;');
    myFile.Add('');
    myFile.Add(' restart)');
    myFile.Add('     /usr/share/artica-postfix/bin/artica-install -shutdown postfix-single $2 $3');
    myFile.Add('     sleep 3');
    myFile.Add('     /usr/share/artica-postfix/bin/artica-install -watchdog postfix-single $2 $3');
    myFile.Add('    ;;');
    myFile.Add('');
    myFile.Add(' reload)');
    myFile.Add('     /usr/share/artica-postfix/bin/artica-install --postfix-reload $2 $3');
    myFile.Add('    ;;');
    myFile.Add('');
    myFile.Add('  *)');
    myFile.Add('    echo "Usage: $0 {start|stop|restart|reload} (+ debug or --verbose for more infos)"');
    myFile.Add('    exit 1');
    myFile.Add('    ;;');
    myFile.Add('esac');
    myFile.Add('exit 0');

    fpsystem('/bin/mv /etc/init.d/postfix /etc/init.d/postfix.old');
    logs.WriteToFile(myfile.Text,'/etc/init.d/postfix');
    myFile.free;
  LOGS.debuglogs('install postfix init.d scripts........:OK');
  LOGS.debuglogs('install init.d scripts........:Adding startup scripts to the system OK');
  fpsystem('/bin/chmod +x /etc/init.d/postfix');

 if FileExists('/usr/sbin/update-rc.d') then begin
    fpsystem('/usr/sbin/update-rc.d -f postfix defaults >/dev/null 2>&1');
 end;

  if FileExists('/sbin/chkconfig') then begin
     fpsystem('/sbin/chkconfig --add postfix >/dev/null 2>&1');
     fpsystem('/sbin/chkconfig --level 2345 postfix on >/dev/null 2>&1');
  end;


end;


//##############################################################################
procedure tpostfix.GENERATE_CERTIFICATE();
var
   CertificateIniFile:string;
   certini:Tinifile;
   tmpstr,cmd:string;
   POSFTIX_POSTCONF:string;
   l:TstringList;
   generate:boolean;
   i:integer;
   CertificateMaxDays:string;
   input_password,passfile,extensions:string;
   ldap:topenldap;
begin

  POSFTIX_POSTCONF:=POSFTIX_POSTCONF_PATH();
  ldap:=topenldap.Create;
  if not FileExists(POSFTIX_POSTCONF) then begin
     logs.Syslogs('Starting......: Unable to stat postconf tool path');
     exit;
  end;

  l:=TstringList.Create;
  l.Add('server.key');
  l.Add('ca.key');
  l.add('ca.csr');
  l.add('ca.crt');

    CertificateMaxDays:=SYS.GET_INFO('CertificateMaxDays');
    if length(CertificateMaxDays)=0 then CertificateMaxDays:='730';
    if length(SYS.OPENSSL_CERTIFCATE_HOSTS())>0 then extensions:=' -extensions HOSTS_ADDONS ';

  generate:=false;
  for i:=0 to l.Count-1 do begin
       if not FileExists('/etc/ssl/certs/postfix/' +l.Strings[i]) then begin
          generate:=true;
          break;
       end else begin
          logs.DebugLogs('Starting......: /etc/ssl/certs/postfix/' +l.Strings[i] + ' OK');
       end;
  end;

  if generate then begin
     SYS.OPENSSL_CERTIFCATE_CONFIG();
     CertificateIniFile:=SYS.OPENSSL_CONFIGURATION_PATH();
     if not FileExists(CertificateIniFile) then begin
        logs.Syslogs('tpostfix.GENERATE_CERTIFICATE():: FATAL ERROR, unable to find any ssl configuration path');
        exit;
     end;
  
     if not fileExists(SYS.LOCATE_OPENSSL_TOOL_PATH()) then begin
        logs.Syslogs('tpostfix.GENERATE_CERTIFICATE():: FATAL ERROR, unable to stat openssl');
        exit;
     end;
  
     tmpstr:=LOGS.FILE_TEMP();
     fpsystem('/bin/cp '+CertificateIniFile+' '+tmpstr);
     certini:=TiniFile.Create(tmpstr);
     input_password:=certini.ReadString('req','input_password',ldap.ldap_settings.password);

     if length(input_password)=0 then input_password:=ldap.ldap_settings.password;
  
     logs.Debuglogs('Settings certificate file...');
     certini.WriteString('req_distinguished_name','organizationalUnitName_default','Mailserver');
     certini.UpdateFile;
     forcedirectories('/etc/ssl/certs/postfix');
     logs.Debuglogs('Generate server certificate');
     logs.Debuglogs('extensions:"'+extensions+'"');
  
     cmd:=SYS.LOCATE_OPENSSL_TOOL_PATH()+' genrsa -out /etc/ssl/certs/postfix/server.key 1024';
     logs.OutputCmd(cmd);
     cmd:=SYS.LOCATE_OPENSSL_TOOL_PATH()+' req -new -key /etc/ssl/certs/postfix/server.key -batch -config '+tmpstr+extensions+' -out /etc/ssl/certs/postfix/server.csr';
     logs.OutputCmd(cmd);
     cmd:=SYS.LOCATE_OPENSSL_TOOL_PATH()+' genrsa -out /etc/ssl/certs/postfix/ca.key 1024 -batch -config '+tmpstr+extensions;
     logs.OutputCmd(cmd);
     cmd:=SYS.LOCATE_OPENSSL_TOOL_PATH()+' req -new -x509 -days '+CertificateMaxDays+' -key /etc/ssl/certs/postfix/ca.key -batch -config '+tmpstr+extensions+' -out /etc/ssl/certs/postfix/ca.csr';
     logs.OutputCmd(cmd);
     cmd:=SYS.LOCATE_OPENSSL_TOOL_PATH()+' x509 -extfile '+tmpstr+extensions+' -x509toreq -days '+CertificateMaxDays+' -in /etc/ssl/certs/postfix/ca.csr -signkey /etc/ssl/certs/postfix/ca.key -out /etc/ssl/certs/postfix/ca.req';
     logs.OutputCmd(cmd);
     cmd:=SYS.LOCATE_OPENSSL_TOOL_PATH()+' x509 -extfile '+tmpstr+extensions+' -req -days '+CertificateMaxDays+' -in /etc/ssl/certs/postfix/ca.req -signkey /etc/ssl/certs/postfix/ca.key -out /etc/ssl/certs/postfix/ca.crt';
     logs.OutputCmd(cmd);





     passfile:=logs.FILE_TEMP();
     logs.WriteToFile(input_password,passfile);
     forceDirectories('/usr/share/artica-postfix/certs');
     cmd:=SYS.LOCATE_OPENSSL_TOOL_PATH()+' pkcs12 -export -password file:'+passfile+' -in /etc/ssl/certs/postfix/ca.crt -inkey /etc/ssl/certs/postfix/ca.key -out /usr/share/artica-postfix/certs/OutlookSMTP.p12';
     logs.OutputCmd(cmd);
     cmd:=SYS.LOCATE_OPENSSL_TOOL_PATH()+' x509 -in /etc/ssl/certs/postfix/ca.crt -outform DER -out /usr/share/artica-postfix/certs/smtp.der';
     logs.OutputCmd(cmd);
     logs.OutputCmd('/bin/chmod 755 /usr/share/artica-postfix/certs');
     logs.OutputCmd('/bin/chmod -R 666 /usr/share/artica-postfix/certs/*');
     logs.DeleteFile(tmpstr);

  end;

     fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.postfix.maincf.php --smtp-sasl');



end;
//##############################################################################


function tpostfix.POSTFIX_STATUS():string;
var pid,mail_version:string;
begin
result:='-1;0.0.0;' ;
pid:=POSTFIX_PID();
if not FileExists(POSFTIX_POSTCONF_PATH()) then exit;

if FileExists('/proc/' + pid + '/exe') then result:='1' else result:='0';
mail_version:=POSTFIX_VERSION();
result:=result + ';' + mail_version + ';' +pid
end;
//##############################################################################

function tpostfix.STATUS:string;
var
    pidpath:string;
begin
   if not FileExists(POSFTIX_POSTCONF_PATH()) then exit;
pidpath:=logs.FILE_TEMP();
fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.status.php --postfix >'+pidpath +' 2>&1');
result:=logs.ReadFromFile(pidpath);
end;
//##############################################################################
procedure tpostfix.POSTFIX_START_LIMITED();
var pid,tmpstr:string;

begin
if EnableStopPostfix=1 then begin
   writeln('Starting......: Postfix Warning Stopping postfix feature has been enabled...');
   POSTFIX_STOP();
   exit;
end;
if EnablePostfix=0 then exit;
 if not FileExists(POSFTIX_POSTCONF_PATH()) then begin
    logs.Debuglogs('POSTFIX_START:: Postfix is not installed');
    exit;
 end;

 pid:=POSTFIX_PID();

 if not SYS.PROCESS_EXIST(pid) then begin
    tmpstr:='Parm[1]='+ParamStr(1)+',Parm[2]='+ParamStr(2);
    logs.NOTIFICATION('Postfix will be started by artica','The postfix SMTP MTA main system will be started by artica by ['+tmpstr+']','system');
    ForceDirectories('/var/spool/postfix/var');
    fpsystem(SYS.LOCATE_GENERIC_BIN('rm')+' -rf /var/spool/postfix/var/run');
    fpsystem(SYS.LOCATE_GENERIC_BIN('ln')+' -s --force /var/run /var/spool/postfix/var/run');
    fpsystem(SYS.LOCATE_GENERIC_BIN('postfix')+' start >/dev/null 2>&1');
    pid:=POSTFIX_PID();
    if not SYS.PROCESS_EXIST(pid) then begin
       logs.DebugLogs('Starting......: Postfix daemon failed...');
       logs.NOTIFICATION('[ARTICA]: Warning: Unable to start postfix daemon !!','Please come back quickly, the postfix daemon did not want to start !','system');
       exit;
    end;
    logs.DebugLogs('Starting......: Postfix daemon success PID ...'+pid);
end;

 end;
//##############################################################################

procedure tpostfix.POSTFIX_START();
var pid:string;

begin
if EnableStopPostfix=1 then begin
   writeln('Starting......: Postfix Warning Stopping postfix feature has been enabled...');
   POSTFIX_STOP();
   exit;
end;
if EnablePostfix=0 then exit;
 if not FileExists(POSFTIX_POSTCONF_PATH()) then begin
    logs.Debuglogs('POSTFIX_START:: Postfix is not installed');
    exit;
 end;
 MYSQMAIL_START();
 pid:=POSTFIX_PID();

 if not SYS.PROCESS_EXIST(pid) then begin

 if SYS.isoverloadedTooMuch() then begin
     logs.DebugLogs('Starting......: Postfix System is overloaded');
     exit;
end;

        logs.Syslogs('starting Postfix main MTA');
        POSTFIX_RELOAD();
        
        
         if not SYS.PROCESS_EXIST(POSTFIX_PID()) then begin
            logs.DebugLogs('Starting......: Postfix daemon failed...');
            logs.NOTIFICATION('[ARTICA]: Warning: Unable to start postfix daemon !!','Please come back quickly, the postfix daemon did not want to start !','system');
            exit;
         end;
         MYSQMAIL_START();
        
  end;

 logs.DebugLogs('Starting......: Postfix daemon is already running using PID ' + pid + '...');
end;
//##############################################################################
procedure tpostfix.POSTFIX_INITIALIZE_FOLDERS();
var
   queue:string;
   l:TstringList;
   i:integer;
begin

queue:=POSTFIX_QUEUE_DIRECTORY();
if length(queue)=0 then begin
   logs.Syslogs('POSTFIX_INITIALIZE_FOLDERS():: Queue directory is null');
   exit;
end;

if SYS.isoverloadedTooMuch() then begin
   logs.DebugLogs('Starting......: Postfix System is overloaded');
   exit;
end;

  forcedirectories(queue + '/pid');
   forcedirectories(queue + '/corrupt');
   forcedirectories(queue + '/trace');
   forcedirectories(queue + '/saved');
   forcedirectories(queue + '/private');
   forcedirectories(queue + '/etc');
   forcedirectories(queue + '/incoming');
   forcedirectories(queue + '/defer');
   forcedirectories(queue + '/maildrop');
   forcedirectories(queue + '/public');
   forcedirectories(queue + '/active');
   forcedirectories(queue + '/hold');
   forcedirectories(queue + '/flush');
   forcedirectories(queue + '/bounce');
   forcedirectories(queue + '/public');

   if not DirectoryExists('/etc/amavis/dkim') then forcedirectories('/etc/amavis/dkim');
   if not FileExists('/usr/local/etc/sender_scores_sitewide') then logs.WriteToFile('#','/usr/local/etc/sender_scores_sitewide');


   Logs.OutputCmd('/bin/chmod -R 0755 '+queue);
   Logs.OutputCmd('/bin/chmod -R 0755 '+queue+'/etc');
   Logs.OutputCmd('/bin/chown -R root:root '+queue+'/etc');
   Logs.OutputCmd('/bin/chown -R root:root /usr/libexec/postfix');
   Logs.OutputCmd('/bin/chmod -R 0755 /usr/libexec/postfix/*');
   Logs.OutputCmd('/bin/chown -R postfix:postdrop '+queue+'/public');

   forcedirectories(queue + '/var');
   forcedirectories(queue+'/var/run/cyrus/socket');
   cyrus:=Tcyrus.Create(SYS);
   Logs.OutputCmd('/bin/chown -R postfix:postfix '+queue+'/var');

   Logs.OutputCmd('/bin/chown -R root:root '+queue+'/pid');
   Logs.OutputCmd('/bin/chmod -R 0755 '+queue+'/pid');
   Logs.OutputCmd('/bin/chown root:postdrop /usr/sbin/postqueue');
   Logs.OutputCmd('/bin/chmod 2755 /usr/sbin/postqueue');

   Logs.OutputCmd('/bin/chown root:postdrop /usr/sbin/postdrop');
   Logs.OutputCmd('/bin/chmod 2755 /usr/sbin/postdrop');
   Logs.OutputCmd('/bin/cp /etc/services '+queue+'/etc/services');
   Logs.OutputCmd('/bin/cp /etc/resolv.conf '+queue+'/etc/resolv.conf');
   Logs.OutputCmd('/bin/cp /etc/hosts '+queue+'/etc/hosts');
   Logs.OutputCmd('/bin/cp /etc/localtime '+queue+'/etc/localtime');
   Logs.OutputCmd('/bin/cp /etc/nsswitch.conf '+queue+'/etc/nsswitch.conf');

        logs.DebugLogs('Starting......: Fixing main.cf permissions...');
        logs.OutputCmd('/bin/chmod 644 /etc/postfix/main.cf');
        logs.OutputCmd('/bin/chown root:root /etc/postfix/main.cf');
   
l:=TstringList.Create;
l.add('/usr/lib/postfix/dict_cdb.so');
l.add('/usr/lib/postfix/dict_mysql.so');
l.add('/usr/lib/postfix/dict_sdbm.so');
l.add('/usr/lib/postfix/dict_pcre.so');
l.add('/etc/postfix/TLS_LICENSE');
l.add('/etc/postfix/LICENSE');
l.add('/etc/postfix/access');
l.add('/etc/postfix/aliases');
l.add('/etc/postfix/bounce.cf.default');
l.add('/etc/postfix/canonical');
l.add('/etc/postfix/generic');
l.add('/etc/postfix/header_checks');
l.add('/etc/postfix/main.cf.default');
l.add('/etc/postfix/makedefs.out');
l.add('/etc/postfix/relocated');
l.add('/etc/postfix/transport');
l.add('/etc/postfix/virtual');
l.add('/usr/share/man/man1/mailq.1');
l.add('/usr/share/man/man1/newaliases.1');
l.add('/usr/share/man/man1/postalias.1');
l.add('/usr/share/man/man1/postcat.1');
l.add('/usr/share/man/man1/postconf.1');
l.add('/usr/share/man/man1/postdrop.1');
l.add('/usr/share/man/man1/postfix.1');
l.add('/usr/share/man/man1/postkick.1');
l.add('/usr/share/man/man1/postlock.1');
l.add('/usr/share/man/man1/postlog.1');
l.add('/usr/share/man/man1/postmap.1');
l.add('/usr/share/man/man1/postqueue.1');
l.add('/usr/share/man/man1/postsuper.1');
l.add('/usr/share/man/man1/sendmail.1');
l.add('/usr/share/man/man5/access.5');
l.add('/usr/share/man/man5/aliases.5');
l.add('/usr/share/man/man5/body_checks.5');
l.add('/usr/share/man/man5/bounce.5');
l.add('/usr/share/man/man5/canonical.5');
l.add('/usr/share/man/man5/cidr_table.5');
l.add('/usr/share/man/man5/generic.5');
l.add('/usr/share/man/man5/header_checks.5');
l.add('/usr/share/man/man5/ldap_table.5');
l.add('/usr/share/man/man5/master.5');
l.add('/usr/share/man/man5/mysql_table.5');
l.add('/usr/share/man/man5/nisplus_table.5');
l.add('/usr/share/man/man5/pcre_table.5');
l.add('/usr/share/man/man5/pgsql_table.5');
l.add('/usr/share/man/man5/postconf.5');
l.add('/usr/share/man/man5/regexp_table.5');
l.add('/usr/share/man/man5/relocated.5');
l.add('/usr/share/man/man5/tcp_table.5');
l.add('/usr/share/man/man5/transport.5');
l.add('/usr/share/man/man5/virtual.5');
l.add('/usr/share/man/man8/bounce.8');
l.add('/usr/share/man/man8/cleanup.8');
l.add('/usr/share/man/man8/anvil.8');
l.add('/usr/share/man/man8/defer.8');
l.add('/usr/share/man/man8/discard.8');
l.add('/usr/share/man/man8/error.8');
l.add('/usr/share/man/man8/flush.8');
l.add('/usr/share/man/man8/lmtp.8');
l.add('/usr/share/man/man8/local.8');
l.add('/usr/share/man/man8/master.8');
l.add('/usr/share/man/man8/oqmgr.8');
l.add('/usr/share/man/man8/pickup.8');
l.add('/usr/share/man/man8/pipe.8');
l.add('/usr/share/man/man8/proxymap.8');
l.add('/usr/share/man/man8/qmgr.8');
l.add('/usr/share/man/man8/qmqpd.8');
l.add('/usr/share/man/man8/scache.8');
l.add('/usr/share/man/man8/showq.8');
l.add('/usr/share/man/man8/smtp.8');
l.add('/usr/share/man/man8/smtpd.8');
l.add('/usr/share/man/man8/spawn.8');
l.add('/usr/share/man/man8/tlsmgr.8');
l.add('/usr/share/man/man8/trace.8');
l.add('/usr/share/man/man8/trivial-rewrite.8');
l.add('/usr/share/man/man8/verify.8');
l.add('/usr/share/man/man8/virtual.8');
l.add('/usr/share/doc/postfix/AAAREADME');
l.add('/usr/share/doc/postfix/ADDRESS_CLASS_README');
l.add('/usr/share/doc/postfix/ADDRESS_REWRITING_README');
l.add('/usr/share/doc/postfix/ADDRESS_VERIFICATION_README');
l.add('/usr/share/doc/postfix/BACKSCATTER_README');
l.add('/usr/share/doc/postfix/BASIC_CONFIGURATION_README');
l.add('/usr/share/doc/postfix/BUILTIN_FILTER_README');
l.add('/usr/share/doc/postfix/CDB_README');
l.add('/usr/share/doc/postfix/CONNECTION_CACHE_README');
l.add('/usr/share/doc/postfix/CONTENT_INSPECTION_README');
l.add('/usr/share/doc/postfix/DATABASE_README');
l.add('/usr/share/doc/postfix/DB_README');
l.add('/usr/share/doc/postfix/DEBUG_README');
l.add('/usr/share/doc/postfix/DSN_README');
l.add('/usr/share/doc/postfix/ETRN_README');
l.add('/usr/share/doc/postfix/FILTER_README');
l.add('/usr/share/doc/postfix/INSTALL');
l.add('/usr/share/doc/postfix/IPV6_README');
l.add('/usr/share/doc/postfix/LDAP_README');
l.add('/usr/share/doc/postfix/LINUX_README');
l.add('/usr/share/doc/postfix/LOCAL_RECIPIENT_README');
l.add('/usr/share/doc/postfix/MAILDROP_README');
l.add('/usr/share/doc/postfix/MILTER_README');
l.add('/usr/share/doc/postfix/MYSQL_README');
l.add('/usr/share/doc/postfix/NFS_README');
l.add('/usr/share/doc/postfix/OVERVIEW');
l.add('/usr/share/doc/postfix/PACKAGE_README');
l.add('/usr/share/doc/postfix/PCRE_README');
l.add('/usr/share/doc/postfix/PGSQL_README');
l.add('/usr/share/doc/postfix/RELEASE_NOTES');
l.add('/usr/share/doc/postfix/RESTRICTION_CLASS_README');
l.add('/usr/share/doc/postfix/SASL_README');
l.add('/usr/share/doc/postfix/SCHEDULER_README');
l.add('/usr/share/doc/postfix/SMTPD_ACCESS_README');
l.add('/usr/share/doc/postfix/SMTPD_POLICY_README');
l.add('/usr/share/doc/postfix/SMTPD_PROXY_README');
l.add('/usr/share/doc/postfix/STANDARD_CONFIGURATION_README');
l.add('/usr/share/doc/postfix/STRESS_README');
l.add('/usr/share/doc/postfix/TLS_LEGACY_README');
l.add('/usr/share/doc/postfix/TLS_README');
l.add('/usr/share/doc/postfix/TUNING_README');
l.add('/usr/share/doc/postfix/ULTRIX_README');
l.add('/usr/share/doc/postfix/UUCP_README');
l.add('/usr/share/doc/postfix/VERP_README');
l.add('/usr/share/doc/postfix/VIRTUAL_README');
l.add('/usr/share/doc/postfix/XCLIENT_README');
l.add('/usr/share/doc/postfix/XFORWARD_README');
l.add('/usr/local/man/man1/mailq.1');
forceDirectories('/usr/share/man/man8');
forceDirectories('/usr/share/man/man5');
forceDirectories('/usr/share/man/man1');

for i:=0 to l.Count-1 do begin
    if Not FileExists(l.Strings[i]) then begin
       logs.syslogs('Starting......: postfix Fixing '+l.Strings[i]);
       logs.OutputCmd('/bin/touch ' + l.Strings[i]);
    end;
end;

       logs.OutputCmd(postfix_path() + ' set-permissions');
       logs.DebugLogs('Starting......: Fixing maildrops permissions...');
       Logs.OutputCmd('/bin/chmod -R 1733 '+queue+'/maildrop');
       Logs.OutputCmd('/bin/chown -R postfix:postdrop '+queue+'/maildrop');
       Logs.OutputCmd('/usr/bin/killall -9 postdrop');
       Logs.OutputCmd('/bin/chgrp -R postdrop /var/spool/postfix/public');
       Logs.OutputCmd('/bin/chgrp -R postdrop /var/spool/postfix/maildrop/');
       Logs.OutputCmd('/bin/chown -R root:root /var/spool/postfix/lib');
       Logs.OutputCmd('/bin/chown -R root:root /var/spool/postfix/usr');
end;
//##############################################################################

procedure tpostfix.POSTFIX_CHECK_SASLDB2();
var
   list2:Tstringlist;
   EnableMechCramMD5:integer;
   EnableMechDigestMD5:integer;
   EnableMechLogin:integer;
   EnableMechPlain:integer;
   mech_list:string;
begin
EnableMechDigestMD5:=0;
EnableMechLogin:=1;
EnableMechPlain:=1;
EnableMechCramMD5:=0;
if not TryStrToInt(SYS.GET_INFO('EnableMechLogin'),EnableMechLogin) then EnableMechLogin:=1;
if not TryStrToInt(SYS.GET_INFO('EnableMechPlain'),EnableMechPlain) then EnableMechPlain:=1;
if not TryStrToInt(SYS.GET_INFO('EnableMechDigestMD5'),EnableMechDigestMD5) then EnableMechDigestMD5:=0;
if not TryStrToInt(SYS.GET_INFO('EnableMechCramMD5'),EnableMechCramMD5) then EnableMechCramMD5:=0;
if(EnableMechLogin=1) then mech_list:=mech_list+' LOGIN';
if(EnableMechPlain=1) then mech_list:=mech_list+' PLAIN';
if(EnableMechCramMD5=1) then mech_list:=mech_list+' CRAM-MD5';
if(EnableMechDigestMD5=1) then mech_list:=mech_list+' DIGEST-MD5';
mech_list:=trim(mech_list);
if length(mech_list)=0 then mech_list:='PLAIN LOGIN';
  logs.DebugLogs('Starting......: postfix authentication mechanisms: ' +mech_list);
  logs.DebugLogs('Starting......: postfix creating /etc/postfix/sasl/smtpd.conf');
  list2:=Tstringlist.Create;
  list2.Add('pwcheck_method: saslauthd');
  list2.Add('mech_list: '+mech_list);
  list2.Add('log_level: 5');
  forcedirectories('/etc/postfix/sasl');
  logs.WriteToFile(list2.Text, '/etc/postfix/sasl/smtpd.conf');
  if not FileExists('/usr/lib/sasl2/smtpd.conf') then logs.OutputCmd('/bin/ln -s /etc/postfix/sasl/smtpd.conf  /usr/lib/sasl2/smtpd.conf');
  list2.free;

   if not FileExists(SASLPASSWD_PATH()) then begin
   logs.Debuglogs('Starting......: saslpasswd2 doesn''t exists');
   exit;
   end;

   if not DirectoryExists('/var/spool/postfix/etc') then begin
      logs.Debuglogs('Starting......: Creating /var/spool/postfix/etc (POSTFIX_CHECK_SASLDB2)');
      ForceDirectories('/var/spool/postfix/etc');
   end;
   logs.Debuglogs('Starting......: saslpasswd: '+ SASLPASSWD_PATH());

   if not FileExists('/var/spool/postfix/etc/sasldb2') then begin
      logs.Debuglogs('Starting......: /var/spool/postfix/etc/sasldb2 doesn''t exists start procedure');
      if not FileExists('/etc/sasldb2') then begin
         logs.OutputCmd('/bin/echo cyrus|'  + SASLPASSWD_PATH() + ' -c cyrus');
       end;

      if FileExists('/etc/sasldb2') then begin
         logs.OutputCmd('/bin/mv /etc/sasldb2 /var/spool/postfix/etc/sasldb2');
         logs.OutputCmd('/bin/ln -s /var/spool/postfix/etc/sasldb2 /etc/sasldb2');
      end;
   end;

    logs.OutputCmd('/bin/chown root:root /var/spool/postfix/etc/sasldb2');
    logs.OutputCmd('/bin/chmod 755 /var/spool/postfix/etc/sasldb2');

end;
//##############################################################################
function tpostfix.MON():string;
var
l:TstringList;
begin
 if not FileExists(POSFTIX_POSTCONF_PATH()) then begin
    logs.DebugLogs('Starting......: Postfix is not installed, abort');
    exit;
 end;

l:=TstringList.Create;

l.Add('check process postfix with pidfile '+POSTFIX_PID_PATH());
l.Add('group mail');
l.Add('start program = "/etc/init.d/artica-postfix start postfix"');
l.Add('stop program = "/etc/init.d/postfix stop"');
l.Add('if 5 restarts within 5 cycles then timeout');
l.Add('');
l.Add('check process postfix-logger with pidfile /etc/artica-postfix/exec.maillog.php.pid');
l.Add('group mail');
l.Add('start program = "/etc/init.d/artica-postfix start postfix-logger"');
l.Add('stop program = "/etc/init.d/artica-postfix stop postfix-logger"');
l.Add('if 5 restarts within 5 cycles then timeout');
l.Add('');


result:=l.Text;
l.free;

end;
//##############################################################################
 function tpostfix.POSTFIX_PID():string;
 var pidp:string;
 
begin
   pidp:= POSTFIX_PID_PATH();
   if not FileExists(pidp) then begin
      logs.Debuglogs('POSTFIX_PID():: unable to locate pid path !!!');
      exit;
   end;
   
   result:=SYS.GET_PID_FROM_PATH(pidp);
   
end;
 //##############################################################################
 function tpostfix.POSTFIX_PID_PATH():string;
var queue:string;
begin
   if not FileExists(POSFTIX_POSTCONF_PATH()) then exit;
   fpsystem(POSFTIX_POSTCONF_PATH() + ' -h queue_directory >/opt/artica/tmp/queue_directory');
   queue:=trim(SYS.ReadFileIntoString('/opt/artica/tmp/queue_directory'));
   result:=queue+'/pid/master.pid';
end;
//##############################################################################
function tpostfix.POSFTIX_POSTCONF_PATH:string;
begin
    if FileExists('/etc/artica-postfix/OPENVPN_APPLIANCE') then exit;
    if FileExists('/usr/sbin/postconf') then exit('/usr/sbin/postconf');
end;
//##############################################################################
function tpostfix.POSFTIX_MASTER_CF_PATH:string;
begin
    if FileExists('/etc/postfix/master.cf') then exit('/etc/postfix/master.cf');
end;
//##############################################################################
procedure tpostfix.POSTFIX_STOP();
var
   pid:string;
   pidnum:integer;
   tmpstr:string;
begin
pid:=POSTFIX_PID();
pidnum:=0;
if SYS.PROCESS_EXIST(pid) then begin
   logs.Debuglogs('Postfix was ordered to be stopped');
   tmpstr:='Parm[1]='+ParamStr(1)+',Parm[2]='+ParamStr(2);
   logs.NOTIFICATION('Postfix pid '+pid+' has been stopped by artica','The postfix SMTP MTA main system has been stopped by artica by ['+tmpstr+']','system');
   writeln('Stopping Postfix.............: ' + pid + ' PID..');
   if fileExists('/usr/sbin/postfix') then begin
      fpsystem('/usr/sbin/postfix stop >/dev/null 2>&1');
      POSTFIX_INI_TD();
      exit;
   end;
end;

if FIleExists('/usr/lib/postfix/master') then begin
    if not TryStrToInt(SYS.PIDOF('/usr/lib/postfix/master'),pidnum) then pidnum:=0;
    if pidnum>0 then begin
       writeln('Stopping Postfix.............: ' ,pidnum, ' PID..');
       fpsystem('/bin/kill '+ IntToStr(pidnum));
    end;
end;

pid:=SYS.PIDOF_PATTERN('sendmail');
if SYS.PROCESS_EXIST(pid) then begin
    TryStrToInt(pid,pidnum);
    if pidnum>5 then begin
         writeln('Stopping Postfix.............: killing old sendmail instance: ' ,pidnum, ' PID..');
         fpsystem('/bin/kill -9 '+pid);
    end;
end;




end;

//##############################################################################
function tpostfix.Is_CYRUS_enabled_in_master_cf():boolean;
var
   RegExpr:TRegExpr;
   list:TstringList;
   i:Integer;
begin
   result:=false;
   if not FileExists('/etc/postfix/master.cf') then exit;
   list:=TStringList.Create;
   list.LoadFromFile('/etc/postfix/master.cf');
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='flags= user=cyrus argv=(.+)';
   for i:=0 to list.Count-1 do begin
        if RegExpr.Exec(list.Strings[i]) then begin
            result:=true;
            break;
        end;
   end;
   RegExpr.free;
   list.free;
end;
//##############################################################################
function tpostfix.FIX_RETRY_DAEMON():boolean;
var
   RegExpr:TRegExpr;
   list:TstringList;
   i:Integer;
   t:integer;
begin
   result:=false;
   if not FileExists('/etc/postfix/master.cf') then exit;
   list:=TStringList.Create;
   list.LoadFromFile('/etc/postfix/master.cf');
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='retry\s+unix';
   for i:=0 to list.Count-1 do begin
        if RegExpr.Exec(list.Strings[i]) then begin
             RegExpr.Expression:='\s+flags=DRhu\s+user=vmail';
             t:=i+1;
             if RegExpr.Exec(list.Strings[t]) then begin
                list.Delete(t);
                list.SaveToFile('/etc/postfix/master.cf');
                result:=true;
                break;
             end;
        end;
   end;
   RegExpr.free;
   list.free;
end;
//##############################################################################
function tpostfix.QUEUE_PATH():string;
var tmp:string;
begin
  if Not FileExists(POSFTIX_POSTCONF_PATH()) then exit;
  tmp:=LOGS.FILE_TEMP();
  fpsystem(POSFTIX_POSTCONF_PATH()+ ' -h queue_directory >'+tmp+' 2>&1');
  result:=trim(logs.ReadFromFile(tmp));
  logs.DeleteFile(tmp);
end;
//##############################################################################
function tpostfix.POSFTIX_READ_QUEUE(queuename:string):string;
var
   queuepath,path,messageid:string;
   send,i:integer;
   l:TstringList;
begin
   queuepath:=QUEUE_PATH();
   if length(queuepath)=0 then begin
      logs.Debuglogs('tpostfix.POSFTIX_READ_QUEUE:: unable to get queue path');
      exit;
   end;
   path:=queuepath + '/' + queuename;
   logs.Debuglogs('POSFTIX_READ_QUEUE:: requested queue='+path);
   SYS.DirDirRecursive(path);
   
   logs.Debuglogs('POSFTIX_READ_QUEUE:: Files: '+IntToStr(SYS.DirListFiles.Count));
   
   if SYS.DirListFiles.Count>200 then send:=200 else send:=SYS.DirListFiles.Count-1;
   l:=TstringList.Create;
   for i:=0 to send do begin
       if FileExists(SYS.DirListFiles.Strings[i]) then begin
          messageid:=ExtractFileName(SYS.DirListFiles.Strings[i]);
          if length(messageid)>4 then l.Add(POSTFIX_READ_QUEUE_MESSAGE(messageid));
       end;
   end;
   
   result:=l.Text;
   l.Free;
end;
//##############################################################################
function tpostfix.POSTFIX_READ_QUEUE_MESSAGE(MessageID:string):string;
var
    RegExpr,RegExpr2,RegExpr3,RegExpr4,RegExpr5:TRegExpr;
    FileData:TStringList;
    i:integer;
    m_Time,named_attribute,sender,recipient,Subject:string;
    tmpstr:string;
begin
   if not fileExists('/usr/sbin/postcat') then begin
      logs.Debuglogs('POSTFIX_READ_QUEUE_MESSAGE:: unable to stat /usr/sbin/postcat');
      exit;
   end;
    tmpstr:=LOGS.FILE_TEMP();

   fpsystem('/usr/sbin/postcat -q ' + MessageID + ' >'+tmpstr);

   if not fileExists(tmpstr) then begin
       logs.Debuglogs('unable to stat ' +tmpstr);
       exit;
   end;
   FileData:=TStringList.Create;
   FileData.LoadFromFile(tmpstr);
   logs.DeleteFile(tmpstr);
   RegExpr:=TRegExpr.Create;
   RegExpr2:=TRegExpr.Create;
   RegExpr3:=TRegExpr.Create;
   RegExpr4:=TRegExpr.Create;
   RegExpr5:=TRegExpr.Create;
   RegExpr.Expression:='message_arrival_time: (.+)';
   RegExpr2.Expression:='named_attribute: (.+)';
   RegExpr3.Expression:='sender: ([a-zA-Z0-9\.@\-_]+)';
   RegExpr4.Expression:='recipient: ([a-zA-Z0-9\.@\-_]+)';
   RegExpr5.Expression:='Subject: (.+)';
   For i:=0 to FileData.Count-1 do begin
        if RegExpr.Exec(FileData.Strings[i]) then m_Time:=RegExpr.Match[1];
        if RegExpr2.Exec(FileData.Strings[i]) then named_attribute:=RegExpr2.Match[1];
        if RegExpr3.Exec(FileData.Strings[i]) then sender:=RegExpr3.Match[1];
        if RegExpr4.Exec(FileData.Strings[i]) then recipient:=RegExpr4.Match[1];
        if RegExpr5.Exec(FileData.Strings[i]) then Subject:=RegExpr5.Match[1];

        if length(m_Time)>0 then begin
           if  length(named_attribute)>0 then begin
               if length(sender)>0 then begin
                  if length(recipient)>0 then begin
                     if length(subject)>0 then begin
                        break
                     end;
                  end;
               end;
           end;
        end;



   end;
   RegExpr.Free;
   RegExpr2.Free;
   RegExpr3.Free;
   RegExpr4.Free;
   RegExpr5.Free;
   FileData.Free;

  exit('<time>' + m_Time + '</time><named_attr>' + named_attribute + '</named_attr><sender>' + sender + '</sender><recipient>' + recipient + '</recipient><subject>' + subject + '</subject><MessageID>'+MessageID+'</MessageID>');
  
end;
//#########################################################################################
function tpostfix.MAILLOG_TAIL(Filter:string):string;
var maillog_path,cmdline:string;
loglines:string;
begin
    loglines:='200';
    result:='';
    maillog_path:=SYS.MAILLOG_PATH();

    if not FileExists(maillog_path) then begin
       writeln('unable to stat mail.log path "' + maillog_path+'"');
       exit;
    end;


    if length(Filter)>0 then begin
       filter:='|grep "'+Filter+'"';
       loglines:='800';
    end;

    cmdline:='/usr/bin/tail -n '+loglines+' ' + maillog_path+Filter+' 2>&1';

    fpsystem(cmdline);
end;
//#########################################################################################





end.
