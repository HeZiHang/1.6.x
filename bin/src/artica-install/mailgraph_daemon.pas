unit mailgraph_daemon;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils, Process,logs,unix,RegExpr in 'RegExpr.pas',zsystem,postfix_class;

  type
  tMailgraphClass=class


private
     LOGS:Tlogs;
     D:boolean;
     SYS:TSystem;
     artica_path:string;
     postfix:Tpostfix;
     MailGraphEnabled:integer;
     procedure   MAILGRAPH_RECONFIGURE();
     PROCEDURE   MAILGRAPH_PATCH();


public
    procedure   Free;
    constructor Create(const zSYS:Tsystem);



    function    DAEMON_BIN_PATH():string;


    function    VERSION():string;
    function    MAILGRAPH_PID():string;
    function    MAILGRAPH_BIN():string;
    function    QUEUEGRAPH_BIN():string;
    procedure   MAILGRAPH_GENERATE();
    function    MAILGRAPH_PL_PATH():string;
    procedure   MAILGRAPH_START();
    PROCEDURE   QUEUEGRAPH_INSTALL();
    function    QUEUEGRAPH_RRD():string;
    procedure   MAILGRAPH_STOP();
    function    MAILGRAPH_VERSION():string;
    function    MAILGRAPH_TMP_PATH():string;
    function    MAILGRAPGH_STATUS():string;
    function    STATUS:string;
    procedure   WRITE_INITD();

END;

implementation

constructor tMailgraphClass.Create(const zSYS:Tsystem);
begin
       forcedirectories('/etc/artica-postfix');
       forcedirectories('/opt/artica/tmp');
       LOGS:=tlogs.Create();
       SYS:=zSYS;
       postfix:=Tpostfix.Create(SYS);
       if not TryStrToInt(SYS.GET_INFO('MailGraphEnabled'),MailGraphEnabled) then MailGraphEnabled:=0;


       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;
end;
//##############################################################################
procedure tMailgraphClass.free();
begin
    logs.Free;
    SYS.Free;
    postfix.free;

end;
//##############################################################################
function tMailgraphClass.DAEMON_BIN_PATH():string;
begin
   if FileExists('/usr/bin/stunnel4') then exit('/usr/bin/stunnel4');
end;
//##############################################################################
function tMailgraphClass.MAILGRAPH_BIN():string;
begin
exit(artica_path + '/bin/install/rrd/mailgraph1.cgi');
end;
//##############################################################################
function tMailgraphClass.MAILGRAPH_TMP_PATH():string;
var
   RegExpr:TRegExpr;
   cgi_path,filedatas:string;
begin
 cgi_path:=MAILGRAPH_BIN();
 if not FileExists(cgi_path) then exit;
 RegExpr:=TRegExpr.create;
  RegExpr.expression:='my \$tmp_dir[|=| ]+[''|"]([a-zA-Z0-9\/\.]+)[''|"];';
 filedatas:=logs.ReadFromFile(cgi_path);
  if  RegExpr.Exec(filedatas) then begin
  result:=RegExpr.Match[1];
  end;
  RegExpr.Free;
end;


//#############################################################################

function tMailgraphClass.MAILGRAPGH_STATUS():string;
var pid,pid_path,status:string;
begin


   if not FileExists('/etc/init.d/mailgraph-init') then begin
      if D then logs.Debuglogs('MAILGRAPGH_STATUS() -> /etc/init.d/mailgraph-init not installed...(information... not important)');
      status:='-1;0;0';
      exit(status);
      end else begin
          status:='0;'+MAILGRAPH_VERSION() +';0';
      end;


   pid_path:=MAILGRAPH_PID();
   logs.Debuglogs('MAILGRAPGH_STATUS() -> pid ->' + pid_path);
   if length(pid_path)=0 then begin
      status:='-1;0;0';
      exit(status);
   end;

   pid:=logs.ReadFromFile(pid_path);
   pid:=trim(pid);
   if FileExists('/proc/' + pid + '/exe') then status:='1' ;
   result:=status + ';' + MAILGRAPH_VERSION() + ';' +pid;
   exit(result);


end;
//##############################################################################
procedure tMailgraphClass.MAILGRAPH_GENERATE();
var
   start:boolean;
   l:Tstringlist;
   mailgraph_path:string;
   qgraphbin:string;
begin
  start:=false;

  if Not FileExists(postfix.POSFTIX_POSTCONF_PATH()) then exit;
  qgraphbin:=QUEUEGRAPH_BIN();
  mailgraph_path:=MAILGRAPH_BIN();


  if FileExists(qgraphbin) then begin
     logs.OutputCmd(qgraphbin);
  end;


  if not FileExists(mailgraph_path) then exit;
  if not FileExists('/etc/artica-postfix/mailgraph.time') then start:=true;

  if not start then begin
      if SYS.FILE_TIME_BETWEEN_MIN('/etc/artica-postfix/mailgraph.time')>=3 then start:=true;
  end;

  if start then begin
          DeleteFile('/etc/artica-postfix/mailgraph.time');
          l:=Tstringlist.Create;
          l.Add('######################');
          l.SaveToFile('/etc/artica-postfix/mailgraph.time');
          l.free;
          logs.OutputCmd(mailgraph_path);
      end;

end;


//##############################################################################
function tMailgraphClass.QUEUEGRAPH_BIN():string;
begin
    if FileExists('/usr/share/queuegraph/count.sh') then exit('/usr/share/queuegraph/count.sh');
    if FileExists(artica_path+ '/bin/install/rrd/queuegraph-rrd.sh') then exit(artica_path + '/bin/install/rrd/queuegraph-rrd.sh');
end;
//##############################################################################
function tMailgraphClass.VERSION():string;
var
    RegExpr:TRegExpr;
    FileDatas:TStringList;
    i:integer;
begin
 if not FileExists(DAEMON_BIN_PATH()) then exit;
 FileDatas:=TstringList.Create;
 fpsystem(DAEMON_BIN_PATH() + ' -version >/opt/artica/tmp/stunnel.ver 2>&1');
 if not FileExists('/opt/artica/tmp/stunnel.ver') then exit;
 FileDatas.LoadFromFile('/opt/artica/tmp/stunnel.ver');
 logs.DeleteFile('/opt/artica/tmp/stunnel.ver');
 RegExpr:=TRegExpr.Create;
 RegExpr.Expression:='stunnel\s+([0-9\.]+)\s+';
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
function tMailgraphClass.MAILGRAPH_VERSION():string;
var
   RegExpr:TRegExpr;
   cgi_path:string;
   FileDatas:TStringList;
   i:integer;
begin
  cgi_path:=MAILGRAPH_BIN();
  if not FileExists(cgi_path) then exit;
  
  result:=SYS.GET_CACHE_VERSION('APP_MAILGRAPH');
  if length(result)>0 then exit;
  
  RegExpr:=TRegExpr.create;
  RegExpr.expression:='my\s+\$VERSION[\s=''"]+([0-9\.]+).+;';
  FileDatas:=TStringList.Create;

  FileDatas.LoadFromFile(cgi_path);
  for i:=0 to FileDatas.Count-1 do begin
      if  RegExpr.Exec(filedatas.Strings[i]) then begin
          result:=RegExpr.Match[1];
          RegExpr.Free;
          exit;
      end;
  end;

  RegExpr.Free;
  SYS.SET_CACHE_VERSION('APP_MAILGRAPH',result);
end;


//##############################################################################
function tMailgraphClass.STATUS:string;
var
ini:TstringList;
pid:string;
begin

 if not FileExists(DAEMON_BIN_PATH()) then exit;
   ini:=TstringList.Create;
   ini.Add('[MAILGRAPH]');
   ini.Add('service_name=APP_MAILGRAPH');
   ini.Add('service_cmd=mailgraph');
   ini.Add('service_disabled='+IntToStr(MailGraphEnabled));
   ini.Add('master_version='+MAILGRAPH_VERSION());

   if MailGraphEnabled=0 then begin
         result:=ini.Text;
         ini.free;
         SYS.MONIT_DELETE('APP_MAILGRAPH');
         exit;
     end;

      if SYS.MONIT_CONFIG('APP_MAILGRAPH','/var/run/mailgraph.pid','mailgraph') then begin
         ini.Add('monit=1');
         result:=ini.Text;
         ini.free;
         exit;
      end;

       pid:=MAILGRAPH_PID();
      if SYS.PROCESS_EXIST(pid) then ini.Add('running=1') else  ini.Add('running=0');
      ini.Add('application_installed=1');
      ini.Add('master_pid='+ pid);
      ini.Add('master_memory=' + IntToStr(SYS.PROCESS_MEMORY(pid)));
      ini.Add('status='+SYS.PROCESS_STATUS(pid));
      result:=ini.Text;
      ini.free;

end;
//##############################################################################
function tMailgraphClass.MAILGRAPH_PL_PATH():string;
begin
if FileExists('/usr/sbin/mailgraph') then exit('/usr/sbin/mailgraph');
end;
//##############################################################################
PROCEDURE tMailgraphClass.QUEUEGRAPH_INSTALL();
var
   TL            :TstringList;
   script_path   :string;
   q             :string;
   RegExpr       :TRegExpr;
   i             :integer;
begin
    if not FileExists(postfix.POSFTIX_POSTCONF_PATH()) then exit;
    q:=artica_path + '/bin/install/rrd/queuegraph-upd.pl';
    script_path:=QUEUEGRAPH_BIN();
    if not Fileexists(q) then exit;
    if not FileExists(script_path) then exit;

    logs.OutputCmd(script_path);
    ForceDirectories('/opt/artica/share/www/mailgraph');
    logs.OutputCmd(script_path);
        script_path:=q;
        fpsystem('chmod 755 ' + script_path);
        TL:=TstringList.Create;
        TL.Add('#This generate rrd pictures from postfix queue statistics');
        TL.Add('* * * * * root ' + script_path + ' >/dev/null 2>&1');
        Logs.logs('QUEUEGRAPH_INSTALL():: Restore /etc/cron.d/artica-queuegraph');
        TL.SaveToFile('/etc/cron.d/artica-queuegraph');


   TL.Clear;
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^my \$rrd =';
   if FileExists(q) then begin
      TL.LoadFromFile(q);
      for i:=0 to TL.Count-1 do begin
           if RegExpr.Exec(TL.Strings[i]) then begin
                TL.Strings[i]:='my $rrd = '''+QUEUEGRAPH_RRD()+'''; # path to where the RRD database is';
                TL.SaveToFile(q);
                break;
           end;
      end;
   end;

   TL.Free;
   RegExpr.Free;
end;
//##############################################################################
function tMailgraphClass.QUEUEGRAPH_RRD():string;
begin
    if FileExists('/var/lib/queuegraph/queuegraph.rrd') then exit('/var/lib/queuegraph/queuegraph.rrd');
    if FileExists('/opt/artica/var/rrd/queuegraph.rrd') then exit('/opt/artica/var/rrd/queuegraph.rrd');
end;
//##############################################################################
PROCEDURE tMailgraphClass.MAILGRAPH_PATCH();
var
   TL            :TstringList;
   RegExpr       :TRegExpr;
   F             :boolean;
   i             :integer;

begin
   if not FIleExists(MAILGRAPH_PL_PATH()) then exit;
   TL:=Tstringlist.CReate;
   TL.LoadFromFile(MAILGRAPH_PL_PATH());
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='File::Tail->new\(name=>\$logfile,';
   F:=false;
   for i:=0 to TL.Count-1 do begin
       if RegExpr.Exec(TL.Strings[i]) then begin
           logs.DebugLogs('Starting......: Mailgraph statistics patching line '+IntTOstr(i));
           TL.Strings[i]:=chr(9)+'$file = File::Tail->new(name=>$logfile, tail=>0);';
           F:=true;
       end;
   end;

   if f then logs.WriteToFile(TL.Text,MAILGRAPH_PL_PATH());
   RegExpr.free;
   TL.free;
end;
//##############################################################################
procedure tMailgraphClass.MAILGRAPH_START();
var
   pid   :string;
   path  :string;
   cmd   :string;
   count :integer;
   l:Tstringlist;
begin
count:=0;

logs.Debuglogs('################# MAILGRAH ##################');
if not FileExists(postfix.POSFTIX_POSTCONF_PATH()) then exit;

if MailGraphEnabled=0 then begin
    logs.DebugLogs('Starting......: Mailgraph statistics generator is disabled');
    if SYS.PROCESS_EXIST(MAILGRAPH_PID()) then MAILGRAPH_STOP();
    exit;
end;

if SYS.isoverloadedTooMuch() then begin
   logs.DebugLogs('Starting......: Mailgraph System is overloaded');
   exit;
end;

forcedirectories('/var/log');
forcedirectories('/var/lib/mailgraph');
if not FileExists('/var/log/syslog') then logs.OutputCmd('/bin/touch /var/log/syslog');
if not FileExists('/var/log/mailgraph.log') then logs.OutputCmd('/bin/touch /var/log/mailgraph.log');


path:=MAILGRAPH_PL_PATH();

if not FileExists(path) then begin
   logs.OutputCmd(artica_path + '/bin/artica-mailgraph');
   MAILGRAPH_PATCH();
end;

if SYS.PROCESS_EXIST(MAILGRAPH_PID()) then begin
   logs.DebugLogs('Starting......: Mailgraph statistics generator is already running using PID ' + MAILGRAPH_PID());
   exit;
end;
   if not FileExists(artica_path + '/bin/artica-mailgraph') then begin
      logs.Debuglogs('MAILGRAPH_START():: WARNING unable to stat '+artica_path + '/bin/artica-mailgraph');
      exit;
   end;


   logs.OutputCmd(artica_path + '/bin/artica-mailgraph');
   
   if not SYS.CHECK_PERL_MODULES('RRDs') then begin
      logs.Syslogs('Starting......: Mailgraph unable to find module RRDs');
      exit;
   end;
   
   MAILGRAPH_RECONFIGURE();
   MAILGRAPH_PATCH();
   QUEUEGRAPH_INSTALL();
   if FileExists('/etc/init.d/mailgraph') then begin
      WRITE_INITD();
   end;




   cmd:=path + ' --daemon-log=/var/log/mailgraph.log -d --daemon-pid=/var/run/mailgraph.pid --daemon-rrd=/var/lib/mailgraph -v';

  logs.OutputCmd(cmd);
  while not SYS.PROCESS_EXIST(MAILGRAPH_PID()) do begin
        sleep(100);
        inc(count);
        if count>20 then begin
           logs.Syslogs('Starting......: Mailgraph Timeout..');
           break;
        end;
  end;


  pid:=MAILGRAPH_PID();
  if SYS.PROCESS_EXIST(pid) then begin
     logs.DebugLogs('Starting......: Mailgraph statistics generator pid ' + pid);
  end else begin
      logs.DebugLogs('Starting......: Mailgraph statistics generator failed');
      if FileExists('/opt/artica/logs/mailgraph.tmp') then begin
         l:=Tstringlist.Create;
         l.LoadFromFile('/opt/artica/logs/mailgraph.tmp');
         writeln(l.Text);
         l.free;
      end;
  end;

end;
//##############################################################################
 function tMailgraphClass.MAILGRAPH_PID():string;
 var
    pid:string;
begin
pid:=SYS.GET_PID_FROM_PATH('/var/run/mailgraph.pid');
if length(trim(pid))=0 then begin
   pid:=SYS.PIDOF_PATTERN(MAILGRAPH_PL_PATH());
end;

result:=pid;

end;
 //##############################################################################


procedure tMailgraphClass.MAILGRAPH_RECONFIGURE();
var

   list:TstringList;
   images_path:string;
begin

   images_path:='/opt/artica/share/www/mailgraph';
if FileExists('/etc/cron.d/artica.cron.mailgraph') then logs.DeleteFile('/etc/cron.d/artica.cron.mailgraph');
if not FileExists('/etc/cron.d/artica-cron-mailgraph') then begin
list:=TstringList.Create;
try
   logs.DebugLogs('Starting......: Mailgraph statistics, Create anacron images generator..');
   list.Add('1,3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33,35,37,39,41,43,45,47,49,51,53,55,57,59 * * * *  root ' + MAILGRAPH_BIN()+' >/dev/null 2>&1');
   list.SaveToFile('/etc/cron.d/artica-cron-mailgraph');
finally
list.Free;
end;
end;

forcedirectories(images_path);

end;
//##############################################################################
procedure tMailgraphClass.MAILGRAPH_STOP();
var
   pid   :string;
   count :integer;
begin
  count:=0;
  if not FileExists(postfix.POSFTIX_POSTCONF_PATH()) then exit;
  pid:=MAILGRAPH_PID();
  if not SYS.PROCESS_EXIST(pid) then begin
      writeln('Stopping mailgraph...........: Already stopped');
      exit;
  end;

  WRITE_INITD();
  writeln('Stopping mailgraph...........: ' + pid + ' PID');


  logs.OutputCmd('/bin/kill ' + pid);
   while SYS.PROCESS_EXIST(MAILGRAPH_PID()) do begin
     sleep(100);
        inc(count);
        if count>20 then begin
           logs.OutputCmd('/bin/kill -9 ' + pid);
           break;
        end;
  end;
  if SYS.PROCESS_EXIST(MAILGRAPH_PID()) then begin
        writeln('Stopping mailgraph...........: Failed to stop PID ' + MAILGRAPH_PID());
  end;


  

end;
//##############################################################################
procedure tMailgraphClass.WRITE_INITD();
var
   l:TstringList;
begin

l:=TstringList.Create;
l.add('#! /bin/sh');
l.add('#');
l.add('# mailgraph		Startup script for the mailgraph.');
l.add('#');
l.add('#');
l.add('### BEGIN INIT INFO');
l.add('# Required-Start:');
l.add('# Required-Stop:');
l.add('# Provides:          mailgraph');
l.add('# Default-Start:     2 3 4 5');
l.add('# Default-Stop:      0 1 6');
l.add('# Short-Description: mailgraph');
l.add('### END INIT INFO');
l.add('');
l.add('PATH=/bin:/usr/bin:/sbin:/usr/sbin');
l.add('');
l.add('');
l.add('start () {');
l.add('	/etc/init.d/artica-postfix start mailgraph');
l.add('}');
l.add('');
l.add('stop () {');
l.add('      /etc/init.d/artica-postfix stop mailgraph');
l.add('}');
l.add('');
l.add('case "$1" in');
l.add('    start)');
l.add('	/etc/init.d/artica-postfix start mailgraph');
l.add('	;;');
l.add('    stop)');
l.add('	/etc/init.d/artica-postfix stop mailgraph');
l.add('	;;');
l.add('    reload|force-reload)');
l.add('	/etc/init.d/artica-postfix stop mailgraph');
l.add('	/etc/init.d/artica-postfix start mailgraph');
l.add('	;;');
l.add('    restart)');
l.add('	/etc/init.d/artica-postfix stop mailgraph');
l.add('	/etc/init.d/artica-postfix start mailgraph');
l.add('	;;');
l.add('    *)');
l.add('	echo "Usage:  {start|stop|reload|force-reload|restart}"');
l.add('	exit 3');
l.add('	;;');
l.add('esac');
l.add('');
l.add('exit 0');
if FileExists('/etc/init.d/mailgraph') then begin
        try
        logs.Debuglogs('Patching /etc/init.d/mailgraph');
        l.SaveToFile('/etc/init.d/mailgraph');
        except
        logs.Syslogs('FATAL ERROR WHILE Patching /etc/init.d/mailgraph');
        end;
end;
l.free;


end;
//#############################################################################

end.
