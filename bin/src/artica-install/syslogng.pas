unit syslogng;

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
  tsyslogng=class


private
     LOGS:Tlogs;
     SYS:Tsystem;
     artica_path:string;
SyslogNgPref:integer;
     InsufficentRessources:boolean;
     function IF_MYSQL_CONFIGURED():boolean;
     procedure KILL_MYSQL_INSTANCES();



public
    procedure   Free;
    constructor Create(const zSYS:Tsystem);
    procedure   START();
    function    DEAMON_BIN_PATH():string;
    function    DEAMON_CONF_PATH():string;
    function    INITD_PATH():string;
    function    VERSION():string;
    FUNCTION    STATUS():string;
    function    SYSLOG_PID():string;
    procedure   CONFIG_MYSQL();
    procedure   patch_syslogng_ulimit();
    procedure   STOP();
    function    MON():string;


END;

implementation

constructor tsyslogng.Create(const zSYS:Tsystem);
begin
       SyslogNgPref:=0;
       forcedirectories('/etc/artica-postfix');
       LOGS:=tlogs.Create();
       SYS:=zSYS;
       if not TryStrToInt(SYS.GET_PERFS('SyslogNgPref'),SyslogNgPref) then SyslogNgPref:=1;
       InsufficentRessources:=SYS.ISMemoryHiger1G();
       if not InsufficentRessources then begin
          SyslogNgPref:=4;
          SYS.SET_PERFS('SyslogNgPref','4');
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
procedure tsyslogng.free();
begin
    logs.Free;
end;
//##############################################################################
function tsyslogng.DEAMON_BIN_PATH():string;
begin
  if FileExists('/sbin/syslog-ng') then exit('/sbin/syslog-ng');
  if FileExists('/usr/sbin/syslog-ng') then exit('/usr/sbin/syslog-ng');
end;
//##############################################################################
function tsyslogng.DEAMON_CONF_PATH():string;
begin
 result:=SYS.LOCATE_SYSLOG_NG_CONF();
end;
//##############################################################################
function tsyslogng.INITD_PATH():string;
begin
  if FileExists('/etc/init.d/syslog-ng') then exit('/etc/init.d/syslog-ng');
  if FileExists('/etc/init.d/syslog') then exit('/etc/init.d/syslog');
  if FileExists('/etc/rc.d/syslog-ng') then exit('/etc/rc.d/syslog-ng');
end;
//##############################################################################
function tsyslogng.SYSLOG_PID():string;
var
   pid_path:string;
begin
 pid_path:='/var/run/syslog-ng.pid';
 if FileExists(pid_path) then begin
    result:=SYS.GET_PID_FROM_PATH(pid_path);
    exit;
 end;

 result:=SYS.PidByProcessPath(DEAMON_BIN_PATH());
end;
//##############################################################################
procedure tsyslogng.KILL_MYSQL_INSTANCES();
var
  cmdline:string;
  PIDS:string;
begin

  cmdline:=SYS.LOCATE_mysql_bin()+' --host='+SYS.MYSQL_INFOS('mysql_server')+' --port='+SYS.MYSQL_INFOS('port')+' --user='+SYS.MYSQL_INFOS('database_admin');
  cmdline:=cmdline+'(.+?)--database=artica_events';
  logs.DebugLogs('KILL_MYSQL_INSTANCES:: finding ' + cmdline);
  
  PIDS:=SYS.AllPidsByPatternInPath(cmdline);
  
  if length(PIDS)>0 then begin
     logs.DebugLogs('Starting......: syslog-ng stopping ghosts processes ' + PIDS);
     logs.OutputCmd('/bin/kill ' + PIDS);
  end;
  

end;
//##############################################################################
function tsyslogng.MON():string;
var
l:TstringList;
begin

if not FileExists(DEAMON_BIN_PATH()) then begin
   logs.DebugLogs('Starting......: syslog-ng is not installed, abort');
   exit;
end;

l:=TstringList.Create;

l.Add('check process syslog-ng with pidfile /var/run/syslog-ng.pid');
l.Add('group daemons');
l.Add('start program = "/etc/init.d/artica-postfix start syslogng"');
l.Add('stop program = "/etc/init.d/artica-postfix stop syslogng"');
l.Add('if 5 restarts within 5 cycles then timeout');

result:=l.Text;
l.free;

end;
//##############################################################################

procedure tsyslogng.START();
 var
    logs       :Tlogs;
    FileTemp   :string;
    PIDS       :string;
    EnableMysqlFeatures:integer;
    EnableMysql:string;
    
begin
     logs:=Tlogs.Create;
     EnableMysqlFeatures:=0;


if SyslogNgPref=4 then begin
   EnableMysqlFeatures:=0
   end else begin
       EnableMysql:=SYS.GET_INFO('EnableMysqlFeatures');
       if not TryStrToInt(EnableMysql,EnableMysqlFeatures) then EnableMysqlFeatures:=0;
end;



     
      FileTemp:=artica_path+'/ressources/logs/syslogng.start.daemon';
     if not FileExists(DEAMON_BIN_PATH()) then begin
        logs.Debuglogs('tsyslogng.START():: syslog-ng is not installed');
        exit;
     end;


     if not FileExists(DEAMON_CONF_PATH()) then begin
        logs.Debuglogs('tsyslogng.START():: syslog-ng not configured');
        exit;
     end;
     
  if EnableMysqlFeatures=1 then begin
     if not FileExists('/tmp/mysql.syslog-ng.pipe') then begin
       fpsystem(SYS.LOCATE_MKFIFO()+' /tmp/mysql.syslog-ng.pipe');
       fpsystem('/etc/syslog-ng/syslogng-mysql-pipe.sh &');
       STOP();
     end;
  end;
  
  
 if EnableMysqlFeatures=0 then begin
    if IF_MYSQL_CONFIGURED() then begin
       logs.DebugLogs('Starting......: Mysql features is disabled so syslogng will return in standalone mode...');
    end;
 end;
       CONFIG_MYSQL();
  
 PIDS:=SYS.AllPidsByPatternInPath('/etc/syslog-ng/syslogng-mysql-pipe.sh');
 if length(PIDS)>0 then begin
    logs.DebugLogs('syslog-ng: killing pids "' + PIDS+'"');
    KILL_MYSQL_INSTANCES();
    fpsystem('/bin/kill '+ PIDS);
 end;
 
   if EnableMysqlFeatures=1 then begin
      fpsystem('/etc/syslog-ng/syslogng-mysql-pipe.sh &');
      PIDS:=SYS.AllPidsByPatternInPath('/etc/syslog-ng/syslogng-mysql-pipe.sh');
      logs.DebugLogs('Starting......: syslog-ng mysql pipe is now running using PID ' + PIDS + '...');
   end;

 if SYS.PROCESS_EXIST(SYSLOG_PID()) then begin
        logs.DebugLogs('Starting......: syslog-ng daemon is already running using PID ' + SYSLOG_PID() + '...');
        exit;
 end;

  patch_syslogng_ulimit();
  if FileExists(INITD_PATH()) then begin
     logs.DebugLogs('Starting......: syslog-ng ' + INITD_PATH());
     fpsystem(INITD_PATH() + ' start >'+ FileTemp+' 2>&1');
      if not SYS.PROCESS_EXIST(SYSLOG_PID()) then begin
        logs.DebugLogs('Starting......: syslog-ng Failed ! ' + logs.ReadFromFile(FileTemp));
        exit;
      end;
   logs.DebugLogs('Starting......: syslog-ng daemon started with new PID ' + SYSLOG_PID() + '...');

   exit;
  end;

end;
//##############################################################################
function tsyslogng.VERSION():string;
var
  RegExpr:TRegExpr;
  l:TstringList;
  i:integer;
  FileTemp:string;
begin

     if not FileExists(DEAMON_BIN_PATH()) then begin
        exit;
     end;
     result:=SYS.GET_CACHE_VERSION('APP_SYSLOGNG');
     if length(result)>0 then exit;
     FileTemp:=LOGS.FILE_TEMP();
     fpsystem(DEAMON_BIN_PATH()+' -V >'+FileTemp+' 2>&1');


     if not FileExists(FileTemp) then exit;

     l:=TstringList.Create;
     l.LoadFromFile(FileTemp);
     logs.DeleteFile(FileTemp);

     RegExpr:=tRegExpr.Create;
     RegExpr.Expression:='syslog-ng\s+([0-9\.a-zA-Z]+)';

     for i:=0 to l.Count-1 do begin
            if RegExpr.Exec(l.Strings[i]) then begin
               result:=RegExpr.Match[1];
               break;
            end else begin

            end;
    end;
      SYS.SET_CACHE_VERSION('APP_SYSLOGNG',result);
    l.free;
    RegExpr.free;
end;
//##############################################################################
FUNCTION tsyslogng.STATUS():string;
var
   ini:TstringList;
   pid     :string;
begin


     if not FileExists(DEAMON_BIN_PATH()) then begin
        logs.Debuglogs('tsyslogng.STATUS():: Unable to stat syslog-ng');
        exit;
     end;


ini:=TstringList.Create;
pid:=SYSLOG_PID();
  ini.Add('[SYSLOGNG]');
  if SYS.PROCESS_EXIST(pid) then ini.Add('running=1') else  ini.Add('running=0');
      ini.Add('application_installed=1');
      ini.Add('application_enabled=1');
      ini.Add('master_pid='+ pid);
      ini.Add('master_memory=' + IntToStr(SYS.PROCESS_MEMORY(pid)));
      ini.Add('master_version=' + VERSION());
      ini.Add('status='+SYS.PROCESS_STATUS(pid));
      ini.Add('service_name=APP_SYSLOGNG');
      ini.Add('start_logs=syslogng.start.daemon');
      ini.Add('service_cmd=syslogng');
      
      
result:=ini.Text;
ini.free
end;
//#########################################################################################
procedure tsyslogng.STOP();
 var
    count      :integer;
begin

     count:=0;
     if not FileExists(DEAMON_BIN_PATH()) then exit;


     if SYS.PROCESS_EXIST(SYSLOG_PID()) then begin
        writeln('Stopping syslog-ng...........: ' + SYSLOG_PID() + ' PID..');

        if FileExists(INITD_PATH()) then begin
              if FileExists('/tmp/mysql.syslog-ng.pipe') then logs.DeleteFile('/tmp/mysql.syslog-ng.pipe');
              fpsystem(INITD_PATH() + ' stop');
              exit;
        end;

        fpsystem('/bin/kill ' + SYSLOG_PID());
        while sys.PROCESS_EXIST(SYSLOG_PID()) do begin
              sleep(100);
              inc(count);
              if count>100 then begin
                 writeln('Stopping syslog-ng...........: Failed');
                 exit;
              end;
        end;

      end else begin
        writeln('Stopping syslog-ng...........: Already stopped');
     end;

end;
//##############################################################################
function tsyslogng.IF_MYSQL_CONFIGURED():boolean;
var
    RegExpr:TRegExpr;
    FileDatas:TStringList;
    i:integer;
begin
   result:=false;
   if not FileExists(DEAMON_CONF_PATH()) then exit(false);
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='destination d_mysql';
   FileDatas:=TStringList.Create;
   FileDatas.LoadFromFile(DEAMON_CONF_PATH());
   for i:=0 to FileDatas.Count-1 do begin
      if RegExpr.Exec(FileDatas.Strings[i]) then begin
         result:=true;
         break;
      end;
   end;
    FileDatas.Free;
    RegExpr.free;
    
    if not LOGS.IF_TABLE_EXISTS('syslogs','artica_events') then begin
          logs.DebugLogs('Starting......: syslog-ng no mysql table...');
          exit(false);
    end;

end;
//##############################################################################
procedure tsyslogng.CONFIG_MYSQL();
 var
    mysql_bin:string;
    sql        :string;
    l,t        :TstringList;
    syslogng_log_fifo_size:string;
    syslogng_sync:string;
    log_fifo_size:integer;
    sync:integer;
    EnableMysqlFeatures:boolean;
    syslogng_max_connections:integer;
begin
     EnableMysqlFeatures:=false;
     if SYS.GET_INFO('EnableMysqlFeatures')='1' then EnableMysqlFeatures:=true;
     if SyslogNgPref=4 then EnableMysqlFeatures:=false;
     
     
     
   mysql_bin:=SYS.LOCATE_mysql_bin();
   if not FileExists(mysql_bin) then begin
       logs.DebugLogs('Starting......: syslog-ng no mysql client...');
       exit;
   end;

  t:=TstringList.Create;
  if SyslogNgPref=1 then begin
     logs.DebugLogs('Starting......: syslog-ng filter mysql to all events');
     t.add('log {');
     t.add('        source(s_all);');
     t.add('        filter(f_syslog);');
     t.add('        destination(d_mysql);');
     t.add('};');
  end;
  
  if SyslogNgPref=2 then begin
     logs.DebugLogs('Starting......: syslog-ng filter mysql to mail events + errors');
     t.add('log {');
     t.add('        source(s_all);');
     t.add('        filter(f_mail);');
     t.add('        filter(f_at_least_notice);');
     t.add('        filter(f_at_least_warn);');
     t.add('        filter(f_at_least_err);');
     t.add('        filter(f_at_least_crit);');
     t.add('        destination(d_mysql);');
     t.add('};');
  end;
  
  if SyslogNgPref=3 then begin
    logs.DebugLogs('Starting......: syslog-ng filter mysql to errors');
     t.add('log {');
     t.add('        source(s_all);');
     t.add('        filter(f_at_least_notice);');
     t.add('        filter(f_at_least_warn);');
     t.add('        filter(f_at_least_err);');
     t.add('        filter(f_at_least_crit);');
     t.add('        destination(d_mysql);');
     t.add('};');
  end;
  
  if (SyslogNgPref=4) or (EnableMysqlFeatures=false) then begin
     EnableMysqlFeatures:=false;
     logs.DebugLogs('Starting......: syslog-ng filter disabling mysql...');
     t.Clear;
  end;
  
sql:='CREATE TABLE syslogs (';
sql:=sql+'host varchar(32) default NULL,';
sql:=sql+'facility varchar(10) default NULL,';
sql:=sql+'priority varchar(10) default NULL,';
sql:=sql+'level varchar(10) default NULL,';
sql:=sql+'tag varchar(10) default NULL,';
sql:=sql+'date datetime default NULL,';

sql:=sql+'program varchar(15) default NULL,';
sql:=sql+'msg text,';
sql:=sql+'seq int(10) unsigned NOT NULL auto_increment,PRIMARY KEY (seq),KEY host (host),';
sql:=sql+'KEY seq (seq),KEY program (program),KEY date (date),KEY priority (priority),KEY facility (facility)) TYPE=MyISAM;';
if EnableMysqlFeatures then begin
if not LOGS.IF_TABLE_EXISTS('syslogs','artica_events') then begin
   logs.DebugLogs('Starting......: syslog-ng create Table syslogs in artica_events database....');
   LOGS.QUERY_SQL(pChar(sql),'artica_events');
   if not LOGS.IF_TABLE_EXISTS('syslogs','artica_events') then begin
      logs.DebugLogs('Starting......: syslog-ng unable to create Table syslogs in artica_events database....');
      exit;
   end else begin
      logs.DebugLogs('Starting......: syslog-ng Success creating Table syslogs');
   end;
end;
end;
l:=TstringList.Create;

syslogng_sync:=SYS.GET_PERFS('syslogng_sync');

if not TryStrToInt(SYS.GET_PERFS('syslogng_max_connections'),syslogng_max_connections) then syslogng_max_connections:=50;
logs.DebugLogs('Starting......: syslog-ng max-connections '+IntToStr(syslogng_max_connections));


syslogng_log_fifo_size:=SYS.GET_PERFS('syslogng_log_fifo_size');

if not TryStrToInt(syslogng_log_fifo_size,log_fifo_size) then log_fifo_size:=2048;
if not TryStrToInt(syslogng_sync,sync) then sync:=0;
logs.DebugLogs('Starting......: sync:'+IntToStr(sync)+' log_fifo_size:'+IntToStr(log_fifo_size));
if not EnableMysqlFeatures then logs.DebugLogs('Starting......: syslog-ng Mysql disabled in this configuration');

l.add('options {');
l.add('        chain_hostnames(0);');
l.add('        sync('+IntToStr(sync)+');');
l.add('        time_reopen(10);');
l.add('        time_reap(360);');
l.add('        log_fifo_size('+IntToStr(log_fifo_size)+');');
l.add('        create_dirs(yes);');
l.add('        group(adm);');
l.add('        perm(0640);');
l.add('        dir_perm(0755);');
l.add('        use_dns(no);');
//l.add('	       stats_freq(3600);');
l.add('	       bad_hostname("^gconfd$");');
l.add('};');
l.add('source s_all {');
l.add('        internal();');
l.add('        unix-stream("/dev/log" max-connections('+IntToStr(syslogng_max_connections)+'));');
//l.add('        file("/proc/kmsg" log_prefix("kernel: "));');
l.add('};');
l.add('destination df_auth { file("/var/log/auth.log"); };');
l.add('destination df_syslog { file("/var/log/syslog"); };');
l.add('destination df_cron { file("/var/log/cron.log"); };');
l.add('destination df_daemon { file("/var/log/daemon.log"); };');
l.add('destination df_kern { file("/var/log/kern.log"); };');
l.add('destination df_lpr { file("/var/log/lpr.log"); };');
l.add('destination df_mail { file("/var/log/mail.log"); };');
l.add('destination df_user { file("/var/log/user.log"); };');
l.add('destination df_uucp { file("/var/log/uucp.log"); };');
l.add('destination df_facility_dot_info { file("/var/log/$FACILITY.info"); };');
l.add('destination df_facility_dot_notice { file("/var/log/$FACILITY.notice"); };');
l.add('destination df_facility_dot_warn { file("/var/log/$FACILITY.warn"); };');
l.add('destination df_facility_dot_err { file("/var/log/$FACILITY.err"); };');
l.add('destination df_facility_dot_crit { file("/var/log/$FACILITY.crit"); };');
l.add('destination df_news_dot_notice { file("/var/log/news/news.notice" owner("news")); };');
l.add('destination df_news_dot_err { file("/var/log/news/news.err" owner("news")); };');
l.add('destination df_news_dot_crit { file("/var/log/news/news.crit" owner("news")); };');
l.add('destination df_debug { file("/var/log/debug"); };');
l.add('destination df_messages { file("/var/log/messages"); };');
if FileExists('/dev/xconsole') then begin
   l.add('destination dp_xconsole { pipe("/dev/xconsole"); };');
end;
l.add('destination du_all { usertty("*"); };');
l.add('');
if EnableMysqlFeatures then begin
l.add('destination d_mysql {');
l.add('        pipe("/tmp/mysql.syslog-ng.pipe"');
l.add('        template("INSERT INTO syslogs');
l.add('        (host, facility, priority, level, tag, date, program, msg)');
l.add('        VALUES ( ''$HOST'', ''$FACILITY'', ''$PRIORITY'', ''$LEVEL'', ''$TAG'', ''$YEAR-$MONTH-$DAY $HOUR:$MIN:$SEC'',');
l.add('        ''$PROGRAM'', ''$MSG'' );\n") template-escape(yes));');
l.add('};');
end;
l.add('');
l.add('filter f_auth { facility(auth, authpriv); };');
l.add('filter f_syslog { not facility(auth, authpriv); };');
l.add('filter f_cron { facility(cron); };');
l.add('filter f_daemon { facility(daemon); };');
l.add('filter f_kern { facility(kern); };');
l.add('filter f_lpr { facility(lpr); };');
l.add('filter f_mail { facility(mail); };');
l.add('filter f_news { facility(news); };');
l.add('filter f_user { facility(user); };');
l.add('filter f_uucp { facility(uucp); };');
l.add('filter f_at_least_info { level(info..emerg); };');
l.add('filter f_at_least_notice { level(notice..emerg); };');
l.add('filter f_at_least_warn { level(warn..emerg); };');
l.add('filter f_at_least_err { level(err..emerg); };');
l.add('filter f_at_least_crit { level(crit..emerg); };');
l.add('filter f_debug { level(debug) and not facility(auth, authpriv, news, mail); };');
l.add('filter f_messages {');
l.add('        level(info,notice,warn)');
l.add('            and not facility(auth,authpriv,cron,daemon,mail,news);');
l.add('};');
l.add('filter f_emerg { level(emerg); };');
l.add('filter f_xconsole {');
l.add('    facility(daemon,mail)');
l.add('        or level(debug,info,notice,warn)');
l.add('        or (facility(news)');
l.add('                and level(crit,err,notice));');
l.add('};');

l.add(t.text);
l.add('log {');
l.add('        source(s_all);');
l.add('        filter(f_auth);');
l.add('        destination(df_auth);');
l.add('};');
l.add('log {');
l.add('        source(s_all);');
l.add('        filter(f_syslog);');
l.add('        destination(df_syslog);');
l.add('};');
l.add('log {');
l.add('        source(s_all);');
l.add('        filter(f_daemon);');
l.add('        destination(df_daemon);');
l.add('};');
l.add('log {');
l.add('        source(s_all);');
l.add('        filter(f_kern);');
l.add('        destination(df_kern);');
l.add('};');
l.add('log {');
l.add('        source(s_all);');
l.add('        filter(f_lpr);');
l.add('        destination(df_lpr);');
l.add('};');
l.add('log {');
l.add('        source(s_all);');
l.add('        filter(f_mail);');
l.add('        destination(df_mail);');
l.add('};');
l.add('log {');
l.add('        source(s_all);');
l.add('        filter(f_user);');
l.add('        destination(df_user);');
l.add('};');
l.add('log {');
l.add('        source(s_all);');
l.add('        filter(f_uucp);');
l.add('        destination(df_uucp);');
l.add('};');
l.add('log {');
l.add('        source(s_all);');
l.add('        filter(f_mail);');
l.add('        filter(f_at_least_info);');
l.add('        destination(df_facility_dot_info);');
l.add('};');
l.add('log {');
l.add('        source(s_all);');
l.add('        filter(f_mail);');
l.add('        filter(f_at_least_warn);');
l.add('        destination(df_facility_dot_warn);');
l.add('};');
l.add('log {');
l.add('        source(s_all);');
l.add('        filter(f_mail);');
l.add('        filter(f_at_least_err);');
l.add('        destination(df_facility_dot_err);');
l.add('};');
l.add('log {');
l.add('        source(s_all);');
l.add('        filter(f_news);');
l.add('        filter(f_at_least_crit);');
l.add('        destination(df_news_dot_crit);');
l.add('};');
l.add('log {');
l.add('        source(s_all);');
l.add('        filter(f_news);');
l.add('        filter(f_at_least_err);');
l.add('        destination(df_news_dot_err);');
l.add('};');
l.add('log {');
l.add('        source(s_all);');
l.add('        filter(f_news);');
l.add('        filter(f_at_least_notice);');
l.add('        destination(df_news_dot_notice);');
l.add('};');
if EnableMysqlFeatures then begin
l.add('log {');
l.add('        source(s_all);');
l.add('        filter(f_debug);');
l.add('        destination(d_mysql);');
l.add('};');
end;
l.add('log {');
l.add('        source(s_all);');
l.add('        filter(f_messages);');
l.add('        destination(df_messages);');
l.add('};');
l.add('log {');
l.add('        source(s_all);');
l.add('        filter(f_emerg);');
l.add('        destination(du_all);');
l.add('};');
if FileExists('/dev/xconsole') then begin
l.add('log {');
l.add('        source(s_all);');
l.add('        filter(f_xconsole);');
l.add('        destination(dp_xconsole);');
l.add('};');
end;

l.SaveToFile(DEAMON_CONF_PATH());



l.clear;

if not EnableMysqlFeatures then begin
   l.Free;
   exit;
end;

l.add('#!/bin/sh');
l.add('#');
l.add('# File: syslogng-mysql-pipe.sh');
l.add('#');
l.add('# Take input from a FIFO and run execute it as a query for');
l.add('# a mysql database.');
l.add('#');
l.add('# IMPORTANT NOTE:  This could potentially be a huge security hole.');
l.add('# You should change permissions on the FIFO accordingly.');
l.add('#');
l.add('');
l.add('if [ -e /tmp/mysql.syslog-ng.pipe ]; then');
l.add('        while [ -e /tmp/mysql.syslog-ng.pipe ]');
l.add('                do');
l.add('                        '+SYS.LOCATE_mysql_bin()+' --host='+SYS.MYSQL_INFOS('mysql_server')+' --port='+SYS.MYSQL_INFOS('port')+' --user='+SYS.MYSQL_INFOS('database_admin')+' --password='+SYS.MYSQL_INFOS('database_password')+' --database=artica_events < /tmp/mysql.syslog-ng.pipe');
l.add('        done');
l.add('else');
l.add('        mkfifo /tmp/mysql.syslog-ng.pipe');
l.add('fi');
l.add('');
l.SaveToFile('/etc/syslog-ng/syslogng-mysql-pipe.sh');
logs.OutputCmd('/bin/chmod 777 /etc/syslog-ng/syslogng-mysql-pipe.sh');
logs.DebugLogs('Starting......: Success Configuring syslog-ng with mysql...');
end;
//##############################################################################
procedure tsyslogng.patch_syslogng_ulimit();
var
  RegExpr:TRegExpr;
  l:TstringList;
  i:integer;
  commut1:boolean;
  commut2:boolean;

begin
   if not FileExists(INITD_PATH()) then begin
      logs.syslogs('patch_syslogng_ulimit:: Unable to stat syslog-ng init script...');
      exit;
   end;
   
   
   l:=TstringList.Create;
   RegExpr:=TRegExpr.Create;
   l.LoadFromFile(INITD_PATH());
   commut1:=false;
   commut2:=false;
   for i:=0 to l.Count-1 do begin
         RegExpr.Expression:='syslogng_start\(';
         if RegExpr.Exec(l.Strings[i]) then commut1:=True;
         if commut1 then begin
              RegExpr.Expression:='ulimit';
              if RegExpr.Exec(l.Strings[i]) then begin
                 logs.DebugLogs('Starting......: ulimit patch already set...');
                 break;
              end;
              RegExpr.Expression:='start-stop-daemon';
              if RegExpr.Exec(l.Strings[i]) then begin
                   logs.DebugLogs('Starting......: patching init.d syslog-ng to ulimit');
                   l.Insert(i,'    umask 077 && ulimit -c 0');
                   commut2:=true;
                   break;
              end;
         
         end;
         
         
         
   end;
if(commut2) then l.SaveToFile(INITD_PATH());
l.free;
RegExpr.free;
end;
//##############################################################################




end.

