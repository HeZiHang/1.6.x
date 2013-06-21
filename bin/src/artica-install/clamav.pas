unit clamav;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,Process,logs,unix,RegExpr in 'RegExpr.pas',zsystem,
    postfix_class   in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/postfix_class.pas';

type LDAP=record
      admin:string;
      password:string;
      suffix:string;
      servername:string;
      Port:string;
  end;

  type
  TClamav=class


private
     LOGS:Tlogs;
     SYS:Tsystem;
     artica_path:string;
     postfix:tpostfix;
     FreshClam_pidpath:string;
     Clamd_PidPath:string;
     ClamavMilterEnabled:integer;
     EnableAmavisDaemon:integer;
     EnableClamavDaemon:integer;
     EnableFreshClam:integer;
     EnableClamavDaemonForced:integer;
     CLAMD_BIN_PATH_MEM:string;
     function COMMANDLINE_PARAMETERS(FoundWhatPattern:string):boolean;
     procedure FRESHCLAM_REWRITE_INITD();
     function ReadFileIntoString(path:string):string;
     procedure SENDMAIL_CF_AND_MILTER();
     procedure WRITE_CLAMAV_MILTER();

public
    DEBUG:Boolean;
    NotEngoughMemory:boolean;
    procedure   Free;
    constructor Create;
    function  MILTER_PID():string;
    function  MILTER_DAEMON_PATH():string;
    function  MILTER_INITD_PATH():string;
    procedure MILTER_ETC_DEFAULT();
    procedure MILTER_START();
    procedure MILTER_STOP();
    function  MILTER_SOCK_PATH():string;
    function  MILTER_GET_SOCK_PATH():string;
    procedure MILTER_CHANGE_INITD();

    
    
    function  CLAMAV_VERSION():string;
    function  CLAMD_PID() :string;
    function  CLAMAV_PATTERN_VERSION():string;
    function  CLAMD_BIN_PATH():string;
    function  CLAMD_CONF_PATH():string;
    function  CLAMD_GETINFO(Key:String):string;
    PROCEDURE CLAMD_SETINFO(Key:String;value:string);
    procedure CLAMD_START();
    procedure CLAMD_STOP();
    procedure CLAMD_RELOAD();

    function  CLAMD_WRITE_CONF():boolean;



    function  CLAMAV_INITD():string;
    FUNCTION  CLAMAV_STATUS():string;
    function  CLAMSCAN_BIN_PATH():string;
    function  CLAMAV_CONFIG_BIN_PATH():string;
    function  StartStopDaemonPath():string;
    
    function  FRESHCLAM_PATH():string;
    function  FRESHCLAM_INITD():string;
    procedure FRESHCLAM_STOP();
    function  FRESHCLAM_CONF_PATH():string;
    function  FRESHCLAM_GETINFO(Key:String):string;
    procedure FRESHCLAM_SETINFO(Key:String;value:string);
    function  FRESHCLAM_PID() :string;
    procedure FRESHCLAM_START();
    procedure FRESHCLAM_CLEAN();
    function  PATTERNS_VERSIONS():string;
    function  CLAMAV_BINVERSION():integer;
    function  AMAVISD_PID() :string;
    function  clamd_LocalSocket():string;
    PROCEDURE CLAMAV_UNOFICIAL();



END;

implementation

constructor TClamav.Create;
begin
       DEBUG:=false;
       forcedirectories('/etc/artica-postfix');
       LOGS:=tlogs.Create();
       SYS:=Tsystem.Create();
       ClamavMilterEnabled:=0;
       EnableFreshClam:=1;
       NotEngoughMemory:=false;
       if ParamStr(1)='--clamav-status' then DEBUG:=True;
       SYS:=Tsystem.Create;
       postfix:=tpostfix.Create(SYS);
       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;

      if not TryStrToInt(SYS.GET_INFO('EnableAmavisDaemon'),EnableAmavisDaemon) then EnableAmavisDaemon:=0;
      if not TryStrToInt(SYS.GET_INFO('ClamavMilterEnabled'),ClamavMilterEnabled) then ClamavMilterEnabled:=0;
      if not TryStrToInt(SYS.GET_INFO('EnableClamavDaemon'),EnableClamavDaemon) then EnableClamavDaemon:=0;
      if not TryStrToInt(SYS.GET_INFO('EnableClamavDaemonForced'),EnableClamavDaemonForced) then EnableClamavDaemonForced:=0;


      if FileExists('/etc/artica-postfix/KASPER_MAIL_APP') then begin
          EnableAmavisDaemon:=0;
          ClamavMilterEnabled:=0;
          EnableClamavDaemon:=0;
          EnableFreshClam:=0;
      end;

      if FileExists('/etc/artica-postfix/KASPERSKY_WEB_APPLIANCE') then begin
          EnableAmavisDaemon:=0;
          ClamavMilterEnabled:=0;
          EnableClamavDaemon:=0;
          EnableFreshClam:=0;
      end;

      if not SYS.ISMemoryHiger1G() then begin
          if EnableAmavisDaemon=1 then begin
             logs.Syslogs('Starting......: Fatal: artica-install:: Memory is under 1G, Clamd will be disabled');
             logs.Debuglogs('Starting......: Fatal: artica-install:: Memory is under 1G, Clamd will be disabled');
          end;

          if EnableClamavDaemonForced=0 then begin
                   ClamavMilterEnabled:=0;
                   EnableClamavDaemon:=0;
                   EnableFreshClam:=0;
                   SYS.set_INFO('EnableAmavisDaemon','0');
                   SYS.set_INFO('ClamavMilterEnabled','0');
                   SYS.set_INFO('EnableFreshClam','0');
                   SYS.set_INFO('EnableClamavDaemon','0');
          end;
                    EnableAmavisDaemon:=0;

      end;

      if EnableClamavDaemonForced=1 then begin
         SYS.set_INFO('EnableFreshClam','1');
         SYS.set_INFO('EnableClamavDaemon','1');
         EnableClamavDaemon:=1;
         EnableFreshClam:=1;
      end;

      if ClamavMilterEnabled=1 then begin
         if EnableAmavisDaemon=1 then begin
                ClamavMilterEnabled:=0;
                SYS.set_INFO('ClamavMilterEnabled','0');
         end;
      end;


end;
//##############################################################################
procedure TClamav.free();
begin
    logs.Free;
end;
//##############################################################################
function TClamav.MILTER_DAEMON_PATH():string;
begin
    result:=SYS.LOCATE_GENERIC_BIN('clamav-milter');
end;
//#############################################################################
function TClamav.StartStopDaemonPath():string;
begin
if FileExists('/sbin/start-stop-daemon') then exit('/sbin/start-stop-daemon');
end;
//#############################################################################
function TClamav.clamd_LocalSocket():string;
begin
result:=CLAMD_GETINFO('LocalSocket');
end;
//#############################################################################


function TClamav.MILTER_PID():string;
var pid:string;
begin
    if FileExists('/var/spool/postfix/var/run/clamav/clamav-milter.pid') then begin
       pid:=trim(SYS.GET_PID_FROM_PATH('/var/spool/postfix/var/run/clamav/clamav-milter.pid'));
       //logs.Debuglogs('TClamav.MILTER_PID():: pid='+pid);
       if pid='0' then pid:='';
       if not FileExists('/proc/'+pid+'/exe') then pid:='';
    end;
    if length(pid)=0 then pid:=SYS.PidByProcessPath(MILTER_DAEMON_PATH());
    result:=pid;
end;
//#############################################################################
function TClamav.AMAVISD_PID() :string;
begin
 if FileExists('/var/run/amavisd/amavis-artica.pid') then exit(SYS.GET_PID_FROM_PATH('/var/run/amavisd/amavis-artica.pid'));
 if FileExists('/var/run/amavis/amavisd.pid') then exit(SYS.GET_PID_FROM_PATH('/var/run/amavis/amavisd.pid'));
end;
//##############################################################################
function TClamav.CLAMD_PID() :string;
begin
if length(Clamd_PidPath)=0 then Clamd_PidPath:=CLAMD_GETINFO('PidFile');
if DEBUG then writeln('Clamd_PidPath=',Clamd_PidPath);
result:=SYS.GET_PID_FROM_PATH(Clamd_PidPath);
if result='0' then result:='';
if length(result)=0 then result:=SYS.PIDOF(CLAMD_BIN_PATH());


//logs.Debuglogs('TClamav.CLAMD_PID():: Clamd_PidPath='+Clamd_PidPath+' "' + result + '"');
end;
//##############################################################################
function TClamav.MILTER_INITD_PATH():string;
begin
    if FileExists('/etc/init.d/clamav-milter') then exit('/etc/init.d/clamav-milter');
end;
//#############################################################################
function TClamav.MILTER_SOCK_PATH():string;
var path:string;
begin
    path:=MILTER_GET_SOCK_PATH();
    if length(path)>0 then exit(path);
    if FileExists('/var/spool/postfix/var/run/clamav/clamav-milter.ctl') then exit('/var/spool/postfix/var/run/clamav/clamav-milter.ctl');
end;
//#############################################################################
function TClamav.MILTER_GET_SOCK_PATH():string;
begin
exit('/var/spool/postfix/var/run/clamav/clamav-milter.ctl');
end;
//#############################################################################
function Tclamav.CLAMSCAN_BIN_PATH():string;
begin
if FileExists('/usr/bin/clamscan') then exit('/usr/bin/clamscan');
end;
//#############################################################################
function Tclamav.CLAMAV_CONFIG_BIN_PATH():string;
begin
    if FileExists('/usr/bin/clamav-config') then exit('/usr/bin/clamav-config');
end;
//#############################################################################
function TClamav.CLAMD_BIN_PATH():string;
begin
if length(CLAMD_BIN_PATH_MEM)>0 then exit(CLAMD_BIN_PATH_MEM);

CLAMD_BIN_PATH_MEM:=SYS.LOCATE_GENERIC_BIN('clamd');
if length(CLAMD_BIN_PATH_MEM)>0 then begin
   exit(CLAMD_BIN_PATH_MEM);
end;

if FileExists('/opt/artica/sbin/clamd') then begin
   CLAMD_BIN_PATH_MEM:='/opt/artica/sbin/clamd';
   exit('/opt/artica/sbin/clamd');
end;

end;
//#############################################################################
function TClamav.CLAMAV_INITD():string;
begin
if FileExists('/etc/init.d/clamav-daemon') then exit('/etc/init.d/clamav-daemon');
if FileExists('/etc/init.d/clamd') then exit('/etc/init.d/clamd');
end;
//#############################################################################

function TClamav.FRESHCLAM_PATH():string;
begin
if FileExists('/usr/local/bin/freshclam') then exit('/usr/local/bin/freshclam');
if FileExists('/usr/bin/freshclam') then exit('/usr/bin/freshclam');
if FileExists('/opt/artica/bin/freshclam') then exit('/opt/artica/bin/freshclam');
end;
//##############################################################################
function TClamav.FRESHCLAM_INITD():string;
begin
    if FileExists('/etc/init.d/clamav-freshclam') then exit('/etc/init.d/clamav-freshclam');
    if FileExists('/etc/init.d/freshclam') then exit('/etc/init.d/freshclam');
    
end;
//##############################################################################
function TClamav.FRESHCLAM_CONF_PATH():string;
begin
    if FileExists('/etc/clamav/freshclam.conf') then exit('/etc/clamav/freshclam.conf');
    if FileExists('/etc/freshclam.conf') then exit('/etc/freshclam.conf');
    if FileExists('/opt/artica/etc/freshclam.conf') then exit('/opt/artica/etc/freshclam.conf');
end;
//##############################################################################
function TClamav.CLAMD_CONF_PATH():string;
begin
   if FileExists('/etc/clamav/clamd.conf') then exit('/etc/clamav/clamd.conf');
   if FIleExists('/etc/clamd.conf') then exit('/etc/clamd.conf');
   if FileExists('/usr/local/etc/clamav/clamd.conf') then exit('/usr/local/etc/clamav/clamd.conf');
   if FIleExists('/usr/local/etc/clamd.conf') then exit('/usr/local/etc/clamd.conf');
   if FileExists('/opt/artica/etc/clamd.conf') then exit('/opt/artica/etc/clamd.conf');
end;
//##############################################################################
function TClamav.FRESHCLAM_PID() :string;
var
   pid:string;
begin
if length(FreshClam_pidpath)=0 then FreshClam_pidpath:=FRESHCLAM_GETINFO('PidFile');
pid:=trim(SYS.GET_PID_FROM_PATH(FreshClam_pidpath));
if length(pid)=0 then pid:=SYS.PIDOF(FRESHCLAM_PATH());
result:=pid;
end;
//##############################################################################
function Tclamav.PATTERNS_VERSIONS():string;
var
 DatabaseDirectory:string;
 i:integer;
 FilePath:string;
 l:TstringList;

begin
  if not FileExists(CLAMSCAN_BIN_PATH()) then begin
     logs.Debuglogs('Tclamav.PATTERNS_VERSIONS():: unable to stat clamscan');
     exit;
  end;


  DatabaseDirectory:=FRESHCLAM_GETINFO('DatabaseDirectory');
  if not DirectoryExists(DatabaseDirectory) then begin
          logs.Debuglogs('Tclamav.PATTERNS_VERSIONS():: unable to stat DatabaseDirectory ('+DatabaseDirectory+')');
          exit;
  end;

  l:=TstringList.Create;
  l.Add('[CLAMAV]');
  SYS.DirFiles(DatabaseDirectory,'*.*');
  for i:=0 to SYS.DirListFiles.Count-1 do begin
        FilePath:=DatabaseDirectory+'/'+SYS.DirListFiles.Strings[i];
        l.Add(SYS.DirListFiles.Strings[i]+'='+SYS.FILE_TIME(FilePath));
  end;

  result:=l.Text;
  l.free;

end;


//##############################################################################
function TClamav.FRESHCLAM_GETINFO(Key:String):string;
var
RegExpr:TRegExpr;
l:TStringList;
i:integer;
begin
 if not FileExists(FRESHCLAM_CONF_PATH()) then exit;
 l:=TStringList.Create;
 RegExpr:=TRegExpr.Create;
 l.LoadFromFile(FRESHCLAM_CONF_PATH());
 RegExpr.Expression:='^' + Key + '\s+(.+)';
 For i:=0 to l.Count-1 do begin
     if RegExpr.Exec(l.Strings[i]) then begin
        result:=RegExpr.Match[1];
        break;
     end;

 end;
  RegExpr.Free;
  l.free;
end;
//##############################################################################
procedure TClamav.CLAMD_RELOAD();
var pid:string;
begin
pid:=CLAMD_PID();
if SYS.PROCESS_EXIST(pid) then begin
logs.DebugLogs('Starting......: clamav daemon (reloading) PID: '+pid);
        CLAMD_WRITE_CONF();
        fpsystem('/bin/kill -HUP '+pid);
        exit;
end;
    CLAMD_START();
end;

procedure TClamav.CLAMD_START();
 var
    count      :integer;

    cmdline    :string;
    Socket     :string;
    PidFile    :string;
    Pids       :string;
    LogFile    :string;
    LogPath    :string;
    DatabaseDirectory:string;
    pid        :string;
    user_daemon:string;
    aa_complain:string;
    daemon_bin_path:string;
begin
     Socket:='';
     logs.Debuglogs('###################### CLAMAV ######################');
     daemon_bin_path:=CLAMD_BIN_PATH();
     if not FileExists(daemon_bin_path) then begin
        logs.DebugLogs('TClamav.CLAMD_START():: unable to stat clamd path');
        SYS.MONIT_DELETE('APP_CLAMAV');
        exit;
     end;
     count:=0;


     if NotEngoughMemory then logs.DebugLogs('Starting......: Warning !!! not enough memory !!!, node at least 728Mb memory on this computer');

     if EnableClamavDaemonForced=1 then begin
        logs.DebugLogs('Starting......: Clamav Daemon is force to run by EnableClamavDaemonForced');
        EnableClamavDaemon:=1;
     end;
     if SYS.PROCESS_EXIST(CLAMD_PID()) then begin
        if EnableClamavDaemon=0 then begin
           CLAMD_STOP();
           exit;
        end;
        logs.DebugLogs('Starting......: clamav daemon is already running using PID ' + CLAMD_PID() + '...');
        exit;
     end;


     
     Pids:=SYS.PROCESS_LIST_PID(CLAMD_BIN_PATH());
     if length(Pids)>0 then begin

     if EnableClamavDaemon=0 then begin
           CLAMD_STOP();
           exit;
        end;

        logs.DebugLogs('Starting......: clamav daemon is already running using PID(s) ' + Pids + '...');
        exit;
     end;

     if EnableClamavDaemon=0 then begin
          logs.DebugLogs('Starting......: clamav daemon is disabled by  EnableClamavDaemon token...');
          exit;
     end;

     CLAMD_WRITE_CONF();
     PidFile:=CLAMD_GETINFO('PidFile');

     
     if length(Socket)=0 then begin
        CLAMD_SETINFO('LocalSocket','/var/run/clamav/clamav.sock');
        Socket:='/var/run/clamav/clamav.sock';
     end;
      LogFile:=CLAMD_GETINFO('LogFile');
      Socket:=ExtractFilePath(CLAMD_GETINFO('LocalSocket'));
      DatabaseDirectory:=CLAMD_GETINFO('DatabaseDirectory');
      LogPath:=ExtractFilePath(CLAMD_GETINFO('LogFile'));

     if length(LogPath)>0 then forceDirectories(LogPath);

     if not FileExists('/var/log/clamav/clamav.log') then begin
        ForceDirectories('/var/log/clamav');
        fpsystem('/bin/touch /var/log/clamav/clamav.log');
     end;
     
     forcedirectories('/var/run/clamav');
     forcedirectories(DatabaseDirectory);
     ForceDirectories('/var/clamav/tmp');
     fpsystem('/bin/chmod 777 /tmp');
     
     if fileExists(postfix.POSFTIX_POSTCONF_PATH()) then begin
        user_daemon:='postfix';
     end else begin
         if FIleExists(SYS.LOCATE_DANSGUARDIAN_BIN_PATH()) then begin
              user_daemon:='squid';
          end else begin
              user_daemon:='clamav';
          end;
     end;

         CLAMD_SETINFO('User',user_daemon);
         SYS.AddUserToGroup(user_daemon,user_daemon,'','');
         logs.DebugLogs('Starting......: clamav daemon change to '+user_daemon+' user');
         logs.OutputCmd('/bin/chown -R '+user_daemon+':'+user_daemon+' /var/run/clamav');
         logs.OutputCmd('/bin/chown -R '+user_daemon+':'+user_daemon+' '+DatabaseDirectory);
         logs.OutputCmd('/bin/chown -R '+user_daemon+':'+user_daemon+' /var/clamav');
         logs.OutputCmd('/bin/chmod 775 /var/run/clamav');


         if DirectoryExists(LogFile) then fpsystem('/bin/rm -rf ' + LogFile);

         logs.OutputCmd('/bin/chown '+user_daemon+':'+user_daemon+' '+LogFile);
         logs.OutputCmd('/bin/chown '+user_daemon+':'+user_daemon+' '+LogPath);
         logs.OutputCmd('/bin/chmod 777 /dev/null');
         logs.DebugLogs('Starting......: clamav daemon..................:"'+daemon_bin_path+'"');
         logs.DebugLogs('Starting......: clamav log file................:"'+LogFile+'"');
         logs.Debuglogs('Starting......: clamav daemon PidFile..........:"'+PidFile+'"');
         logs.Debuglogs('Starting......: clamav daemon Socket...........:"'+CLAMD_GETINFO('LocalSocket')+'"');
         logs.Debuglogs('Starting......: clamav daemon Configuration....:"'+CLAMD_CONF_PATH()+'"');
         logs.Debuglogs('Starting......: clamav daemon DatabaseDirectory:"'+DatabaseDirectory+'"');
         sleep(100);



         aa_complain:=SYS.LOCATE_GENERIC_BIN('aa-complain');
         if FileExists(aa_complain) then begin
              logs.Debuglogs('Starting......: clamav daemon add clamd Profile to AppArmor..');
              fpsystem(aa_complain+' '+daemon_bin_path+' >/dev/null 2>&1');
         end;
         logs.Debuglogs('Starting......: clamav daemon is ready to start...');
         cmdline:=daemon_bin_path+' --config-file='+CLAMD_CONF_PATH()+' &';
         logs.Debuglogs(cmdline);
         fpsystem(cmdline);
         pid:=CLAMD_PID();
 count:=0;
  while not SYS.PROCESS_EXIST(pid) do begin
        pid:=CLAMD_PID();
        sleep(300);
        count:=count+1;
        write('.');
        if count>50 then begin
            logs.DebugLogs('Starting......: clamav daemon daemon timeout');
            writeln('');
            break;
        end;
  end;

  if not SYS.PROCESS_EXIST(CLAMD_PID()) then begin
             Pids:=SYS.PROCESS_LIST_PID(daemon_bin_path);
               writeln('');
             if length(Pids)=0 then logs.Syslogs('Starting......: clamav daemon Failed to start clamav');
  end;



     if SYS.PROCESS_EXIST(CLAMD_PID()) then begin
              writeln('');
             logs.DebugLogs('Starting......: clamav daemon with new PID ' + CLAMD_PID() + '...');
             logs.Syslogs('success starting clamav with new PID  ' + CLAMD_PID() + '...' );

     end else begin
         writeln('');
         logs.DebugLogs('Starting......: failed start clamav daemon...');
     end;
     FRESHCLAM_START();
     CLAMAV_UNOFICIAL();

end;
//##############################################################################

PROCEDURE Tclamav.CLAMAV_UNOFICIAL();
var
l:Tstringlist;
socket:string;
PidFile:string;
DatabaseDirectory:string;
Proxy,ProxyUser,ProxyPassword,ProxyName:string;
RegExpr:TRegExpr;
curlstring:string;
begin

  Proxy:=SYS.GET_HTTP_PROXY();
  Proxy:=AnsiReplaceStr(Proxy,'"','');
  Proxy:=AnsiReplaceStr(Proxy,'http://','');
  Proxy:=AnsiReplaceStr(Proxy,'https://','');

   if length(Proxy)>0 then begin
       RegExpr:=TRegExpr.CReate();
       RegExpr.Expression:='(.+?):(.+?)@(.+)';
       if RegExpr.Exec(Proxy) then begin
            ProxyUser:=RegExpr.Match[1];
            ProxyPassword:=RegExpr.Match[2];
            ProxyName:=RegExpr.Match[3];
       end else begin
           RegExpr.Expression:='(.+?)@(.+)';
            if RegExpr.Exec(Proxy) then begin
               ProxyUser:=RegExpr.Match[1];
               ProxyName:=RegExpr.Match[3];
               end;
       end;
   end;

   if length(ProxyName)=0 then ProxyName:=Proxy;

   if length(ProxyName)>0 then begin
        curlstring:='-x '+ProxyName;
        if length( ProxyUser)>0 then  curlstring:=curlstring+' -U '+ProxyUser;
        if length( ProxyPassword)>0 then  curlstring:=curlstring+':'+ProxyPassword;
   end;

  socket:=CLAMD_GETINFO('LocalSocket');
  PidFile:=CLAMD_GETINFO('PidFile');
  DatabaseDirectory:=CLAMD_GETINFO('DatabaseDirectory');
l:=Tstringlist.Create;
l.add('PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"');
l.add('export PATH');
l.add('');
l.add('clam_user="clamav"');
l.add('clam_group="clamav"');
l.add('clam_dbs="'+DatabaseDirectory+'"');
l.add('clamd_pid="'+PidFile+'"');
l.add('reload_dbs="yes"');
l.add('');
l.add('reload_opt="clamdscan --reload"  # Default');
l.add('clamd_socket="'+socket+'"');
l.add('start_clamd="service clamd start"');
l.add('enable_random="yes"');
l.add('min_sleep_time="60"    # Default minimum is 60 seconds (1 minute).');
l.add('max_sleep_time="600"   # Default maximum is 600 seconds (10 minutes).');
l.add('ss_dbs="');
l.add('   junk.ndb');
l.add('   jurlbl.ndb');
l.add('   phish.ndb');
l.add('   rogue.hdb');
l.add('   sanesecurity.ftm');
l.add('   scam.ndb');
l.add('   spamimg.hdb');
l.add('   winnow_malware.hdb');
l.add('   winnow_malware_links.ndb');
l.add('"');
l.add('');
l.add('si_dbs="');
l.add('   honeynet.hdb');
l.add('   securiteinfobat.hdb');
l.add('   securiteinfodos.hdb');
l.add('   securiteinfoelf.hdb');
l.add('   securiteinfo.hdb');
l.add('   securiteinfohtml.hdb');
l.add('   securiteinfooffice.hdb');
l.add('   securiteinfopdf.hdb');
l.add('   securiteinfosh.hdb');
l.add('"');
l.add('');
l.add('si_update_hours="4"   # Default is 4 hours (6 update checks daily).');
l.add('mbl_dbs="');
l.add('   mbl.ndb');
l.add('"');
l.add('mbl_update_hours="6"   # Default is 6 hours (4 downloads daily).');
l.add('work_dir="/usr/unofficial-dbs"   #Top level working directory');
l.add('ss_dir="$work_dir/ss-dbs"        # Sanesecurity sub-directory');
l.add('si_dir="$work_dir/si-dbs"        # SecuriteInfo sub-directory');
l.add('mbl_dir="$work_dir/mbl-dbs"      # MalwarePatrol sub-directory');
l.add('config_dir="$work_dir/configs"   # Script configs sub-directory');
l.add('gpg_dir="$work_dir/gpg-key"      # Sanesecurity GPG Key sub-directory');
l.add('add_dir="$work_dir/add-dbs"      # User defined databases sub-directory');
l.add('keep_db_backup="no"');
l.add('curl_silence="no"      # Default is "no" to report curl statistics');
l.add('rsync_silence="no"     # Default is "no" to report rsync statistics');
l.add('gpg_silence="no"       # Default is "no" to report gpg signature status');
l.add('comment_silence="no"   # Default is "no" to report script comments');
l.add('');
l.add('enable_logging="yes"');
l.add('log_file_path="/var/log"');
l.add('log_file_name="clamav-unofficial-sigs.log"');
l.add('curl_proxy="'+curlstring+'"');
l.add('user_configuration_complete="yes"');
logs.WriteToFile(l.Text,'/etc/clamav-unofficial-sigs.conf');
logs.Debuglogs('Starting......: clamav-unofficial-sigs.conf done...');
end;



FUNCTION TClamav.CLAMAV_STATUS():string;
var
   pidpath:string;
begin
if FileExists('/etc/artica-postfix/KASPER_MAIL_APP') then exit;
SYS.MONIT_DELETE('APP_CLAMAV');
SYS.MONIT_DELETE('APP_CLAMAV_MILTER');
SYS.MONIT_DELETE('APP_FRESHCLAM');
pidpath:=logs.FILE_TEMP();
fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.status.php --clamav >'+pidpath +' 2>&1');
result:=logs.ReadFromFile(pidpath);
logs.DeleteFile(pidpath);

end;

//#########################################################################################
procedure TClamav.CLAMD_STOP();
var
procs:string;
binpath:string;
count:integer;

begin

binpath:=CLAMD_BIN_PATH();

  if not FileExists(binpath) then begin
     writeln('Stopping clamav daemon.......: Not installed');
     exit;
  end;

  writeln('Stopping clamav daemon.......: ',binpath);
  count:=0;
  if not SYS.PROCESS_EXIST(CLAMD_PID()) then begin
       procs:=SYS.PIDOF(binpath);
       writeln('Stopping clamav daemon.......: Already stopped testing ',binpath,' ghost processes: "'+procs+'"');
       while SYS.PROCESS_EXIST(procs) do begin
             writeln('Stopping clamav daemon.......: ghost processes "' + procs,'" PID ('+intTostr(count)+')/50');
             fpsystem('/bin/kill -9 '+procs+' >/dev/null 2>&1');
             sleep(500);
             procs:=SYS.PIDOF(binpath);
             count:=count+1;
             if count>50 then begin
                writeln('Stopping clamav daemon.......: ghost processes timeout...');
                break;
             end;
       end;

       FRESHCLAM_STOP();
       exit;
  end;

  if FileExists(CLAMAV_INITD()) then begin
     fpsystem(CLAMAV_INITD() + ' stop >/opt/artica/tmp/clamav.tmp 2>&1');
     if FileExists('/opt/artica/tmp/clamav.tmp') then begin
           logs.Output(logs.ReadFromFile('/opt/artica/tmp/clamav.tmp'),'info');
           logs.DeleteFile('/opt/artica/tmp/clamav.tmp');
     end;
 end;

  procs:=CLAMD_PID();
  if SYS.PROCESS_EXIST(procs) then begin
   count:=0;
    while SYS.PROCESS_EXIST(procs) do begin
         writeln('Stopping clamav daemon.......: ',procs,' PID');
         fpsystem('/bin/kill '+procs+' >/dev/null 2>&1');
         sleep(200);
         count:=count+1;
         if count>20 then break;
         procs:=CLAMD_PID();
    end;
  end;

 count:=0;
 procs:=SYS.PIDOF(binpath);
 if SYS.PROCESS_EXIST(procs) then begin
    count:=0;
    while SYS.PROCESS_EXIST(procs) do begin
       writeln('Stopping clamav daemon.......: ghost processes ' + procs,' PID');
       fpsystem('/bin/kill -9 '+procs+' >/dev/null 2>&1');
       sleep(200);
       procs:=SYS.PIDOF(binpath);
      count:=count+1;
      if count>50 then begin
         writeln('Stopping clamav daemon.......: ghost processes timeout...');
         break;
      end;
    end;
 end else begin
     writeln('Stopping clamav daemon.......: stopped');
 end;
 FRESHCLAM_STOP();


end;
//##############################################################################

procedure TClamav.FRESHCLAM_SETINFO(Key:String;value:string);
var
RegExpr:TRegExpr;
l:TStringList;
i:integer;
F:boolean;
path:string;
begin
 f:=False;
 path:=FRESHCLAM_CONF_PATH();
 if length(Key)=0 then exit;
 if length(value)=0 then exit;
 if length(path)=0 then exit;
 l:=TStringList.Create;
 
 if not FileExists(path) then begin
    l.Add(key + ' ' + value);
    l.SaveToFile(path);
    l.free;
    exit;
 end;


 RegExpr:=TRegExpr.Create;
 l.LoadFromFile(path);
 RegExpr.Expression:='^' + Key + '\s+(.+)';
 For i:=0 to l.Count-1 do begin
     if RegExpr.Exec(l.Strings[i]) then begin
        F:=true;
        l.Strings[i]:=key + ' ' + value;
        break;
     end;

 end;

  if not F then l.Add(key + ' ' + value);
  l.SaveToFile(path);
  RegExpr.Free;
  l.free;
end;
//##############################################################################
procedure TClamav.FRESHCLAM_CLEAN();
var
RegExpr:TRegExpr;
l:TStringList;
i:integer;
path:string;
t:integer;
begin
 logs.Debuglogs('Starting......: Cleaning freshclam');
 path:=FRESHCLAM_CONF_PATH();
 if not FileExists(path) then exit;
 RegExpr:=TRegExpr.Create;
 l:=TStringList.Create;
 l.LoadFromFile(path);
 t:=0;

 For i:=0 to l.Count-1 do begin
     if t>l.Count-1 then break;
     RegExpr.Expression:='^freshclam';
     if RegExpr.Exec(l.Strings[t]) then begin
        l.Delete(t);
        continue;
     end;

    RegExpr.Expression:='^#';
     if RegExpr.Exec(l.Strings[t]) then begin
        l.Delete(t);
        continue;
     end;

    RegExpr.Expression:='^\s+WARNING:';
     if RegExpr.Exec(l.Strings[t]) then begin
        l.Delete(t);
        continue;
     end;

     RegExpr.Expression:='Bytecode';
     if RegExpr.Exec(l.Strings[t]) then begin
        l.Delete(t);
        continue;
     end;

     RegExpr.Expression:='([a-zA-Z]+)\s+(.+)';
     if not RegExpr.Exec(l.Strings[t]) then begin
        logs.Debuglogs('Starting......: Cleaning line '+intToStr(t));
        l.Delete(t);
        continue;
     end;
     
     
     
 t:=t+1;
 if t>l.Count-1 then break;
 end;
 
logs.Debuglogs('Starting......: Cleaning freshclam done...');
 try
    l.SaveToFile(path);
 except
   logs.Syslogs('TClamav.FRESHCLAM_CLEAN():: FATAL ERROR WHILE SAVING '+path);
   exit;
 end;
end;
//##############################################################################
procedure TClamav.FRESHCLAM_START();
var
   cmdline,DatabaseDirectory:string;
   count:integer;
   user:string;
   pid:string;
begin
    count:=0;

     logs.Debuglogs('###################### FRESHCLAM ######################');


     if not FileExists(FRESHCLAM_PATH()) then begin
         logs.Debuglogs('FRESHCLAM_START:: freshclam is not installed (could not stat freshclam)');
         exit;
     end;
     
     pid:=FRESHCLAM_PID();
     if SYS.PROCESS_EXIST(pid) then begin
        if EnableFreshClam=0 then FRESHCLAM_STOP();
        logs.DebugLogs('Starting......: FreshClam daemon Already running PID ' + pid);
        exit();
     end;
     
     
     DatabaseDirectory:=CLAMD_GETINFO('DatabaseDirectory');
     if fileExists(postfix.POSFTIX_POSTCONF_PATH()) then begin
        user:='postfix';
     end else begin
         if FIleExists(SYS.LOCATE_DANSGUARDIAN_BIN_PATH()) then begin
              user:='squid';
          end else begin
              user:='clamav';
          end;
     end;


     if FileExists('/etc/artica-postfix/settings/Daemons/freshclamConfig') then begin
        logs.WriteToFile(logs.ReadFromFile('/etc/artica-postfix/settings/Daemons/freshclamConfig'),FRESHCLAM_CONF_PATH());
     end else begin
         FRESHCLAM_SETINFO('NotifyClamd',CLAMD_CONF_PATH());
         FRESHCLAM_SETINFO('DatabaseDirectory',DatabaseDirectory);
         FRESHCLAM_SETINFO('LogSyslog','true');
         FRESHCLAM_SETINFO('AllowSupplementaryGroups','true');
         FRESHCLAM_SETINFO('DatabaseMirror','db.gb.clamav.net');
         FRESHCLAM_SETINFO('PidFile','/var/run/clamav/freshclam.pid');
         FRESHCLAM_SETINFO('UpdateLogFile','/var/log/clamav/freshclam.log');
         FRESHCLAM_SETINFO('NotifyClamd',CLAMD_CONF_PATH());
         FRESHCLAM_SETINFO('DatabaseOwner',user);

     end;


     
     logs.DebugLogs('Starting......: FreshClam daemon Main Configuration path....:' + FRESHCLAM_CONF_PATH());
     logs.DebugLogs('Starting......: FreshClam daemon PidPath....................:'+FRESHCLAM_GETINFO('PidFile'));
     logs.DebugLogs('Starting......: FreshClam daemon Clamav main configuration..:'+CLAMD_CONF_PATH());
     logs.DebugLogs('Starting......: FreshClam daemon DatabaseDirectory..........:'+DatabaseDirectory);
     


     forceDirectories('/var/run/clamav');
     forceDirectories('/var/clamav');
     if FileExists('/var/log/clamav/freshclam.log') then logs.DeleteFile('/var/log/clamav/freshclam.log');
     logs.OutputCmd('/bin/chown '+user+':'+user+' /var/run/clamav');
     logs.OutputCmd('/bin/chown '+user+':'+user+' /var/clamav');
     logs.OutputCmd('/bin/chown -R '+user+':'+user+' /var/run/clamav');
     logs.OutputCmd('/bin/chown -R '+user+':'+user+' /var/log/clamav');
     logs.OutputCmd('/bin/chown -R '+user+':'+user+' '+DatabaseDirectory);
     logs.DebugLogs('Starting......: FreshClam daemon owner......................:'+user);

     
     if FileExists(FRESHCLAM_INITD()) then begin
        FRESHCLAM_REWRITE_INITD();
        logs.DebugLogs('Starting......: FreshClam daemon rewriting init.d');
     end;
     FRESHCLAM_CLEAN();
     logs.DebugLogs('Starting......: FreshClam daemon Run AS.....................:'+user);
     cmdline:=FRESHCLAM_PATH()+ ' --daemon --config-file='+FRESHCLAM_CONF_PATH()+' --pid=/var/run/clamav/freshclam.pid --user='+user+' --log=/var/log/clamav/freshclam.log';
     logs.OutputCmd(cmdline);


  pid:=FRESHCLAM_PID();
  while not SYS.PROCESS_EXIST(pid) do begin
        pid:=FRESHCLAM_PID();
        sleep(100);
        count:=count+1;
        if count>20 then begin
            logs.DebugLogs('Starting......: FreshClam daemon timeout');
            break;
        end;
  end;

  pid:=FRESHCLAM_PID();
  if SYS.PROCESS_EXIST(pid) then begin
     logs.DebugLogs('Starting......: FreshClam daemon succes PID ' +pid);
  end else begin
     logs.DebugLogs('Starting......: FreshClam daemon failed');
  end;



end;
//##############################################################################
procedure TClamav.FRESHCLAM_REWRITE_INITD();
var
l:TstringList;
initpath:string;
begin
  if not FileExists(FRESHCLAM_INITD()) then exit;
  initpath:=FRESHCLAM_INITD();
  l:=TstringList.Create;


l.Add('#!/bin/sh');
l.Add('#Begin ' + initpath);

 if fileExists('/sbin/chkconfig') then begin
    l.Add('# chkconfig: 2345 11 89');
    l.Add('# description: Artica-postfix Daemon');
 end;

l.Add('case "$1" in');
l.Add(' start)');
l.Add('    /usr/share/artica-postfix/bin/artica-install -watchdog freshclam');
l.Add('    ;;');
l.Add('');
l.Add('  stop)');
l.Add('    /usr/share/artica-postfix/bin/artica-install -shutdown freshclam');
l.Add('    ;;');
l.Add('');
l.Add(' restart)');
l.Add('     /usr/share/artica-postfix/bin/artica-install -shutdown freshclam');
l.Add('     sleep 3');
l.Add('     /usr/share/artica-postfix/bin/artica-install -watchdog freshclam');
l.Add('    ;;');
l.Add('');
l.Add('  *)');
l.Add('    echo "Usage: $0 {start|stop|restart}"');
l.Add('    exit 1');
l.Add('    ;;');
l.Add('esac');
l.Add('exit 0');
l.SaveToFile(initpath);
l.free;

end;
//##############################################################################


procedure TClamav.FRESHCLAM_STOP();
var
count:integer;
pids:string;
begin
  pids:=FRESHCLAM_PID();
  count:=0;
  if not SYS.PROCESS_EXIST(FRESHCLAM_PID()) then begin
      writeln('Stopping fresh clam..........: Already stopped');
      exit;
  end;
  writeln('Stopping fresh clam..........: Stopping '+ pids);
  logs.OutputCmd('/bin/kill ' + FRESHCLAM_PID());
  
  pids:=SYS.PidAllByProcessPath(FRESHCLAM_PATH());
  if length(pids)>0 then begin
     writeln('Stopping fresh clam..........: Stopping PIDS '+ pids);
     logs.OutputCmd('/bin/kill -9 ' + pids);
  end;
  
  while SYS.PROCESS_EXIST(FRESHCLAM_PID()) do begin
        Inc(count);
        sleep(100);
        if count>100 then break;
  end;

  pids:=FRESHCLAM_PID();
  


end;
//##############################################################################

procedure TClamav.MILTER_ETC_DEFAULT();
var
   l:TstringList;
begin
    if not FileExists('/etc/default/clamav-milter') then exit();
l:=TstringList.Create;
l.Add('OPTIONS="--max-children=2 -ol"');
l.Add('#If you want to set an alternate pidfile (why?) please do it here:');
l.Add('#PIDFILE=/var/run/clamav/clamav-milter.pid');
l.Add('#If you want to set an alternate socket, do so here (remember to change ');
l.Add('#  sendmail.mc):');
l.Add('#SOCKET=local:/var/run/clamav/clamav-milter.ctl');
l.Add('#');
l.Add('#For postfix, you might want these settings:');
l.Add('USE_POSTFIX=''yes''');
l.Add('SOCKET=local:/var/spool/postfix/var/run/clamav/clamav-milter.ctl');
l.SaveToFile('/etc/default/clamav-milter');
l.free;
end;
//#############################################################################
procedure TClamav.MILTER_START();
var
   daemon_path:string;
   cmd:string;
   ClamavMilterEnabled:integer;
   pid:string;
   count:integer;
   LogFile:string;
   DatabaseDirectory:string;
   UpdateLogFile:string;
begin
   daemon_path:=MILTER_DAEMON_PATH();
   pid:='';
   count:=0;
   if not FileExists(daemon_path) then exit;
   
   if FileExists('/etc/init.d/clamav-milter') then begin
      fpsystem('/bin/rm /etc/init.d/clamav-milter');
      SYS.RemoveService('clamav-milter');
   end;

   if not TryStrToInt(SYS.GET_INFO('ClamavMilterEnabled'),ClamavMilterEnabled) then ClamavMilterEnabled:=0;
   
   if ClamavMilterEnabled=0 then begin
        logs.DebugLogs('Starting......: Clamav-milter daemon is disabled');
        exit;
   end;
   
   if SYS.PROCESS_EXIST(MILTER_PID()) then begin
        logs.DebugLogs('clamav-milter daemon is already running using PID ' + MILTER_PID() + '...');
        exit;
   end;
   
   
   if FileExists(MILTER_INITD_PATH()) then SYS.RemoveService('clamav-milter');
   
   MILTER_ETC_DEFAULT();
   MILTER_CHANGE_INITD();
   SENDMAIL_CF_AND_MILTER();
   WRITE_CLAMAV_MILTER();
   
   if not SYS.IsUserExists('clamav') then begin
      SYS.AddUserToGroup('clamav','clamav','','');
   end;

   
   forcedirectories('/var/spool/postfix/var/run/clamav');

   SYS.AddUserToGroup('postfix','clamav','','');
   SYS.AddUserToGroup('clamav','postfix','','');
   SYS.AddUserToGroup('clamav','mail','','');
   
   LogFile:=ExtractFilePath(CLAMD_GETINFO('LogFile'));
   DatabaseDirectory:=CLAMD_GETINFO('DatabaseDirectory');
   UpdateLogFile:=ExtractFilePath(FRESHCLAM_GETINFO('UpdateLogFile'));
   
   logs.Syslogs('Starting......: Clamav-milter daemon');
   logs.Syslogs('Starting......: Clamav-milter daemon log file: '+LogFile);
   logs.Syslogs('Starting......: Clamav-milter daemon DatabaseDirectory: '+DatabaseDirectory);
   
   

   
      logs.OutputCmd('/bin/chown -R postfix:postfix /var/spool/postfix/var/run/clamav');
      logs.OutputCmd('/bin/chown -R postfix:postfix '+LogFile);
      logs.OutputCmd('/bin/chown -R postfix:postfix '+DatabaseDirectory);
      logs.OutputCmd('/bin/chown -R postfix:postfix '+UpdateLogFile);
      logs.OutputCmd('/bin/chown -R postfix:postfix '+UpdateLogFile);
      logs.OutputCmd('/bin/chown -R postfix:postfix /var/run/clamav');
   

   if not FileExists(SYS.LOCATE_SU()) then begin
      logs.Syslogs('Starting......: Clamav-milter daemon unable to stat su....');
      exit;
   end;

   {cmd:=SYS.LOCATE_SU() + ' postfix -c "' + daemon_path;
   cmd:=cmd+' --sendmail-cf=/etc/mail/sendmail.cf --force-scan --sign';
   cmd:=cmd+' --pidfile=/var/spool/postfix/var/run/clamav/clamav-milter.pid';
   cmd:=cmd+' --config-file='+CLAMD_CONF_PATH();
   cmd:=cmd+' --freshclam-monitor=360 local:/var/spool/postfix/var/run/clamav/clamav-milter.ctl" &';
   }

   cmd:=daemon_path +' --config-file=/etc/clamav/clamav-milter.conf';
   logs.Debuglogs(cmd);
   fpsystem(cmd);


  pid:=MILTER_PID();
  while not SYS.PROCESS_EXIST(pid) do begin

        sleep(500);
        count:=count+1;
        if count>50 then begin
            logs.DebugLogs('Starting......: Clamav-milter daemon timeout...');
            break;
        end;
        pid:=MILTER_PID();
  end;

          
   if not SYS.PROCESS_EXIST(MILTER_PID()) then begin
      logs.DebugLogs('Starting......: Clamav-milter daemon failed to start');
      exit;
   end;

 logs.syslogs('Starting......: Clamav-milter success with new PID '+MILTER_PID());
 CLAMD_START();
 FRESHCLAM_START();

end;
//#############################################################################
procedure Tclamav.WRITE_CLAMAV_MILTER();
var
   l:Tstringlist;
   LocalSocket:string;
begin

localsocket:=CLAMD_GETINFO('LocalSocket');
l:=Tstringlist.create;
l.add('MilterSocket local:/var/spool/postfix/var/run/clamav/clamav-milter.ctl');
l.add('FixStaleSocket yes');
l.add('User postfix');
l.add('AllowSupplementaryGroups yes');
l.add('ReadTimeout 300');
l.add('Foreground no');
l.add('PidFile /var/spool/postfix/var/run/clamav/clamav-milter.pid');
l.add('TemporaryDirectory /var/tmp');
l.add('## LocalSocket unix: in clamd.conf');
l.add('ClamdSocket unix:'+ localsocket);
l.add('OnClean Accept');
l.add('OnInfected Quarantine');
l.add('OnFail Accept');
l.add('AddHeader Yes');
l.add('LogFile /var/log/clamav/clamav-milter.log');
l.add('LogFileMaxSize 2M');
l.add('LogTime yes');
l.add('LogSyslog yes');
l.add('LogFacility LOG_MAIL');
l.add('LogVerbose no');
l.add('LogInfected Basic');
l.add('MaxFileSize 5');
logs.WriteToFile(l.Text,'/etc/clamav/clamav-milter.conf');
l.free;
end;
//#############################################################################
procedure Tclamav.SENDMAIL_CF_AND_MILTER();
var
   l:TstringList;
   RegExpr:TRegExpr;
   found:boolean;
   sendmail_path:string;
   line:string;
   i:integer;
begin
    found:=false;
    line:='INPUT_MAIL_FILTER(''clamav'', ''S=local:/var/spool/postfix/var/run/clamav/clamav-milter.ctl, F=, T=S:2m;R:2m'')dnl';
    sendmail_path:=SYS.LOCATE_SENDMAIL_CF();
    if not fileExists(sendmail_path) then exit;
     RegExpr:=TRegExpr.Create;
     RegExpr.Expression:='^INPUT_MAIL_FILTER.+clamav';
     l:=TstringList.Create;
     l.LoadFromFile('/etc/mail/sendmail.cf');
     for i:=0 to l.Count-1 do begin
           if RegExpr.Exec(l.Strings[i]) then begin
               l.Strings[i]:=line;
               found:=true;
               break;
           end;
     
     end;

     if not found then l.Add(line);
     logs.Syslogs('Starting......: Clamav-milter Patching ' +sendmail_path+' ->"'+line+'"');
     l.SaveToFile(sendmail_path);
     l.free;
     RegExpr.free;
     
end;
//#############################################################################



procedure Tclamav.MILTER_CHANGE_INITD();
var
l:TstringList;
initpath:string;
begin
  if not FileExists(MILTER_INITD_PATH()) then exit;
  initpath:=MILTER_INITD_PATH();
  l:=TstringList.Create;
  

l.Add('#!/bin/sh');
l.Add('#Begin ' + initpath);

 if fileExists('/sbin/chkconfig') then begin
    l.Add('# chkconfig: 2345 11 89');
    l.Add('# description: Artica-postfix Daemon');
 end;

l.Add('case "$1" in');
l.Add(' start)');
l.Add('    /usr/share/artica-postfix/bin/artica-install start clammilter');
l.Add('    ;;');
l.Add('');
l.Add('  stop)');
l.Add('    /usr/share/artica-postfix/bin/artica-install stop clammilter');
l.Add('    ;;');
l.Add('');
l.Add(' restart)');
l.Add('     /usr/share/artica-postfix/bin/artica-install start clammilter');
l.Add('     sleep 3');
l.Add('     /usr/share/artica-postfix/bin/artica-install stop clammilter');
l.Add('    ;;');
l.Add('');
l.Add('  *)');
l.Add('    echo "Usage: $0 {start|stop|restart}');
l.Add('    exit 1');
l.Add('    ;;');
l.Add('esac');
l.Add('exit 0');
l.SaveToFile(MILTER_INITD_PATH());
l.free;
end;
//#############################################################################


procedure TClamav.MILTER_STOP();
var
count:integer;
pids:string;
begin
  if not FileExists(MILTER_DAEMON_PATH()) then begin
     writeln('Stopping clamav-milter.......: Not installed');
     exit;
  end;

  count:=0;
  pids:=MILTER_PID();
  if SYS.PROCESS_EXIST(pids) then begin
     writeln('Stopping clamav-milter.......: PID '+pids);

     while SYS.PROCESS_EXIST(pids) do begin
           Inc(count);
            fpsystem('/bin/kill ' + pids);
           sleep(100);
           if count>20 then begin
                  logs.Output('killing clamav-milter........: ' + MILTER_PID() + ' PID (timeout)');
                   fpsystem('/bin/kill -9 ' + pids);
                  break;
           end;
     end;
  end;
  pids:=SYS.PidAllByProcessPath(MILTER_DAEMON_PATH());

  if length(pids)>0 then begin
         writeln('Stopping clamav-milter.......: PIDs '+pids);
         fpsystem('/bin/kill -9 ' + pids);
  end;
  
  


end;
//##############################################################################
function TClamav.ReadFileIntoString(path:string):string;
var
   List:TstringList;
begin

      if not FileExists(path) then begin
        exit;
      end;

      List:=Tstringlist.Create;
      List.LoadFromFile(path);
      result:=List.Text;
      List.Free;
end;
//##############################################################################
function TClamav.COMMANDLINE_PARAMETERS(FoundWhatPattern:string):boolean;
var
   i:integer;
   s:string;
   RegExpr:TRegExpr;

begin
 result:=false;
 s:='';
 if ParamCount>1 then begin
     for i:=2 to ParamCount do begin
        s:=s  + ' ' +ParamStr(i);
     end;
 end;
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:=FoundWhatPattern;
   if RegExpr.Exec(s) then begin
      RegExpr.Free;
      result:=True;
   end;


end;
//##############################################################################
function TClamav.CLAMAV_VERSION():string;
var
    RegExpr:TRegExpr;
    FileDatas:TStringList;
    i:integer;
    BinPath:string;
    tmpstr:string;
begin

if FileExists(CLAMSCAN_BIN_PATH()) then Binpath:=CLAMSCAN_BIN_PATH();
if length(BinPath)=0 then begin
   if not FileExists(CLAMD_BIN_PATH()) then exit;
end;
result:=SYS.GET_CACHE_VERSION('APP_CLAMAV');
if length(result)>1 then exit;

tmpstr:=logs.FILE_TEMP();

fpsystem(Binpath+' --version >'+tmpstr);
    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='ClamAV\s+([0-9\.a-z]+)';
    FileDatas:=TStringList.Create;
    FileDatas.LoadFromFile(tmpstr);
    logs.DeleteFile(tmpstr);
    for i:=0 to FileDatas.Count-1 do begin
        if RegExpr.Exec(FileDatas.Strings[i]) then begin
             result:=RegExpr.Match[1];
             break;
        end;
    end;
             RegExpr.free;
             FileDatas.Free;
             SYS.SET_CACHE_VERSION('APP_CLAMAV',result);

end;
//#############################################################################
function TClamav.CLAMAV_BINVERSION():integer;
var
    RegExpr:TRegExpr;
    FileDatas:TStringList;
    i:integer;
    BinPath:string;
    tmpstr:string;
    strversion:string;
begin

if FileExists(CLAMSCAN_BIN_PATH()) then Binpath:=CLAMSCAN_BIN_PATH();
if length(BinPath)=0 then begin
   if not FileExists(CLAMD_BIN_PATH()) then exit(0);
end;



   strversion:=SYS.GET_CACHE_VERSION('APP_CLAMAVBIN');
   if length(strversion)>1 then begin
       TryStrToInt(strversion,result);
      exit;
   end;



tmpstr:=logs.FILE_TEMP();


fpsystem(Binpath+' --version >'+tmpstr);
    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='ClamAV\s+([0-9\.]+)';
    FileDatas:=TStringList.Create;
    FileDatas.LoadFromFile(tmpstr);
    logs.DeleteFile(tmpstr);
    for i:=0 to FileDatas.Count-1 do begin
        if RegExpr.Exec(FileDatas.Strings[i]) then begin
             strversion:=RegExpr.Match[1];
             break;
        end;
    end;

if strversion='' then strversion:='0';
strversion:=AnsiReplaceText(strversion,'.','');

TryStrToInt(strversion,result);
RegExpr.free;
FileDatas.Free;
SYS.SET_CACHE_VERSION('APP_CLAMAVBIN',IntToSTr(result));
end;
//#############################################################################
function TClamav.CLAMAV_PATTERN_VERSION():string;
var
    RegExpr:TRegExpr;
    FileDatas:TStringList;
    i:integer;
    main_dbver,BinPath:string;
    D:boolean;
    tmpstr:string;
begin
d:=logs.COMMANDLINE_PARAMETERS('--verbose');

if FIleExists(FRESHCLAM_PATH()) then Binpath:=FRESHCLAM_PATH();

if length(BinPath)=0 then begin
   if FileExists(CLAMSCAN_BIN_PATH()) then Binpath:=CLAMSCAN_BIN_PATH();
end;
if length(BinPath)=0 then begin
   if not FileExists(CLAMD_BIN_PATH()) then exit;
end;

result:=SYS.GET_CACHE_VERSION('APP_CLAMAV_PATTERN');
if length(result)>0 then exit;

tmpstr:=logs.FILE_TEMP();
 if D then writeln(BinPath +' -V >'+tmpstr);

fpsystem(BinPath +' -V >'+tmpstr);
if D then writeln('^ClamAV (.+)/([0-9]+) --> ' + logs.ReadFromFile(tmpstr));
    if not FileExists(tmpstr) then exit;
    RegExpr:=TRegExpr.Create;
    FileDatas:=TStringList.Create;
    try FileDatas.LoadFromFile(tmpstr) except exit; end;
    logs.DeleteFile(tmpstr);
    for i:=0 to FileDatas.Count-1 do begin
        RegExpr.Expression:='^ClamAV (.+)/([0-9]+)';
        if RegExpr.Exec(FileDatas.Strings[i]) then begin
             main_dbver:=RegExpr.Match[2];
        end;



    end;
    result:=main_dbver;
    SYS.SET_CACHE_VERSION('APP_CLAMAV_PATTERN',result);
             RegExpr.free;
             FileDatas.Free;

end;
//#############################################################################
function TClamav.CLAMD_GETINFO(Key:String):string;
var
RegExpr:TRegExpr;
l:TStringList;
i:integer;
begin
 if not FileExists(CLAMD_CONF_PATH()) then begin
    logs.Debuglogs('CLAMD_GETINFO:: unable to stat clamd.conf');
    exit;
 end;
 
 if DEBUG then writeln('CLAMD_CONF_PATH()::',CLAMD_CONF_PATH());
 l:=TStringList.Create;
 
 RegExpr:=TRegExpr.Create;
 try
    l.LoadFromFile(CLAMD_CONF_PATH());
 except
    logs.Debuglogs('CLAMD_GETINFO:: Fatal error');
    exit;
 end;
 RegExpr.Expression:='^' + Key + '\s+(.+)';
 For i:=0 to l.Count-1 do begin
     if RegExpr.Exec(l.Strings[i]) then begin
        result:=RegExpr.Match[1];
        break;
     end;

 end;
  RegExpr.Free;
  l.free;
end;

//##############################################################################
PROCEDURE TClamav.CLAMD_SETINFO(Key:String;value:string);
var
RegExpr:TRegExpr;
l:TStringList;
i:integer;
Found:boolean;
begin
 if length(Key)=0 then exit;
 if length(value)=0 then exit;

 if not FileExists(CLAMD_CONF_PATH()) then begin
    logs.Syslogs('TClamav.CLAMD_SETINFO(): Unable to stat clamd.conf');
    exit;
 end;
 
Found:=false;
 l:=TStringList.Create;
 RegExpr:=TRegExpr.Create;
 l.LoadFromFile(CLAMD_CONF_PATH());
 RegExpr.Expression:='^' + Key + '\s+(.+)';
 For i:=0 to l.Count-1 do begin
     if RegExpr.Exec(l.Strings[i]) then begin
        l.Strings[i]:=Key+' '+ value;
        Found:=true;
        break;
     end;

 end;
  if not found then l.Add(Key+' '+ value);
  l.SaveToFile(CLAMD_CONF_PATH());
  l.Clear;
  l.free;
  RegExpr.Free;

end;
//##############################################################################
function TClamav.CLAMD_WRITE_CONF():boolean;
var
   l:TstringList;
   ClamavStreamMaxLength:integer;
   ClamavMaxRecursion:integer;
   ClamavMaxFiles:integer;
   ClamavMaxFileSize:integer;
   PhishingScanURLs:integer;
   ClamavMaxScanSize:integer;
begin
if not FileExists(CLAMD_CONF_PATH()) then exit;

if not TryStrToInt(SYS.GET_INFO('ClamavStreamMaxLength'),ClamavStreamMaxLength) then ClamavStreamMaxLength:=12;
if not TryStrToInt(SYS.GET_INFO('ClamavMaxRecursion'),ClamavMaxRecursion) then ClamavMaxRecursion:=5;
if not TryStrToInt(SYS.GET_INFO('ClamavMaxFiles'),ClamavMaxFiles) then ClamavMaxFiles:=10000;
if not TryStrToInt(SYS.GET_INFO('PhishingScanURLs'),PhishingScanURLs) then PhishingScanURLs:=1;
if not TryStrToInt(SYS.GET_INFO('ClamavMaxScanSize'),ClamavMaxScanSize) then ClamavMaxScanSize:=15;
if not TryStrToInt(SYS.GET_INFO('ClamavMaxFileSize'),ClamavMaxFileSize) then ClamavMaxFileSize:=20;


result:=false;
l:=TstringList.Create;
l.Add('LocalSocket /var/run/clamav/clamav.sock');
l.Add('FixStaleSocket true');
l.Add('User postfix');
l.Add('AllowSupplementaryGroups true');
l.Add('ScanMail true');
l.Add('ScanArchive true');
l.Add('#ArchiveLimitMemoryUsage false (depreciated)');
l.Add('ArchiveBlockEncrypted false');
l.Add('MaxDirectoryRecursion 15');
l.Add('FollowDirectorySymlinks false');
l.Add('FollowFileSymlinks false');
l.Add('ReadTimeout 180');
l.Add('MaxThreads 12');
l.Add('MaxConnectionQueueLength 15');
l.Add('StreamMaxLength '+IntToStr(ClamavStreamMaxLength)+'M');
l.Add('MaxFileSize '+IntToStr(ClamavMaxFileSize)+'M');
l.Add('MaxScanSize '+IntToStr(ClamavMaxScanSize)+'M');
l.Add('MaxFiles '+IntToStr(ClamavMaxFiles));
l.Add('MaxRecursion '+IntToStr(ClamavMaxRecursion));
l.Add('LogSyslog false');
l.Add('LogFacility LOG_LOCAL6');
l.Add('LogClean false');
l.Add('LogVerbose false');
l.Add('PidFile /var/run/clamav/clamd.pid');
l.Add('DatabaseDirectory /var/lib/clamav');
l.Add('SelfCheck 3600');
l.Add('Foreground false');
l.Add('Debug false');
l.Add('ScanPE true');
l.Add('ScanOLE2 true');
l.Add('ScanHTML true');
l.Add('DetectBrokenExecutables false');
l.Add('#MailFollowURLs false (depreciated)');
l.Add('ExitOnOOM false');
l.Add('LeaveTemporaryFiles false');
l.Add('AlgorithmicDetection true');
l.Add('ScanELF true');
l.Add('IdleTimeout 30');
l.Add('PhishingSignatures true');
if PhishingScanURLs=1 then l.Add('PhishingScanURLs yes') else l.Add('PhishingScanURLs no');
l.Add('PhishingAlwaysBlockSSLMismatch false');
l.Add('PhishingAlwaysBlockCloak false');
l.Add('DetectPUA false');
l.Add('ScanPartialMessages false');
l.Add('HeuristicScanPrecedence false');
l.Add('StructuredDataDetection false');
l.Add('LogFile /var/log/clamav/clamd.log');
l.Add('LogTime true');
l.Add('LogFileUnlock false');
l.Add('LogFileMaxSize 0');            
l.add('TemporaryDirectory /var/clamav/tmp');
l.Add('');

logs.WriteToFile(l.Text,CLAMD_CONF_PATH());
l.free;


end;
//##############################################################################


end.
