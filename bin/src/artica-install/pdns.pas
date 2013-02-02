unit pdns;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,Process,logs,unix,RegExpr,zsystem,openldap,tcpip,bind9;



  type
  tpdns=class


private
     LOGS:Tlogs;
     SYS:TSystem;
     artica_path:string;
     zldap:Topenldap;
     cdirlist:string;
     DisablePowerDnsManagement:integer;
     EnablePDNS:integer;
    procedure   WRITE_INITD();
    function   CONTROL_BIN_PATH():string;
    function   RECURSOR_BIN_PATH():string;
    function   RECURSOR_PID_NUM():string;
    function   MODULE_DIR():string;
public
    procedure   Free;
    constructor Create(const zSYS:Tsystem);
    procedure   CONFIG_DEFAULT();

    function    VERSION():string;
    function    BIN_PATH():string;
    function    PID_NUM():string;
    procedure   START();
    procedure   STOP();
    procedure   RELOAD();
    procedure   RECURSOR_STOP();
    procedure   RECURSOR_START();
    function    STATUS:string;
    function    MYSQL_EXISTS():boolean;

END;

implementation

constructor tpdns.Create(const zSYS:Tsystem);
begin
       forcedirectories('/etc/artica-postfix');
       LOGS:=tlogs.Create();
       SYS:=zSYS;
       zldap:=Topenldap.Create;
       DisablePowerDnsManagement:=0;
       if Not TryStrToInt(SYS.GET_INFO('DisablePowerDnsManagement'),DisablePowerDnsManagement) then DisablePowerDnsManagement:=0;
       if Not TryStrToInt(SYS.GET_INFO('EnablePDNS'),EnablePDNS) then EnablePDNS:=1;



       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;
end;
//##############################################################################
procedure tpdns.free();
begin
    logs.Free;
    zldap.Free;
end;
//##############################################################################
function tpdns.BIN_PATH():string;
begin
   exit(SYS.LOCATE_PDNS_BIN());

end;
//##############################################################################
function tpdns.RECURSOR_BIN_PATH():string;
begin
   if FileExists('/usr/sbin/pdns_recursor') then exit('/usr/sbin/pdns_recursor');

end;
//##############################################################################
function tpdns.CONTROL_BIN_PATH():string;
begin
   if FileExists('/usr/sbin/pdns_control') then exit('/usr/sbin/pdns_control');

end;
//##############################################################################
function tpdns.PID_NUM():string;
begin
    if not FIleExists(BIN_PATH()) then exit;
    result:=SYS.PIDOF(BIN_PATH());
end;
//##############################################################################
function tpdns.RECURSOR_PID_NUM():string;
begin
    if not FIleExists(RECURSOR_BIN_PATH()) then exit;
    result:=SYS.PIDOF(RECURSOR_BIN_PATH());
end;
//##############################################################################

function tpdns.VERSION():string;
var
    RegExpr:TRegExpr;
    FileDatas:TStringList;
    i:integer;
    filetmp:string;
    D:boolean;
begin
D:=false;
D:=SYS.COMMANDLINE_PARAMETERS('--verbose');
result:=SYS.GET_CACHE_VERSION('APP_PDNS');
if length(result)>0 then exit;

filetmp:=logs.FILE_TEMP();
if not FileExists(BIN_PATH()) then begin
   logs.Debuglogs('unable to find pdns');
   exit;
end;

logs.Debuglogs(BIN_PATH()+' --version >'+filetmp+' 2>&1');
fpsystem(BIN_PATH()+' --version >'+filetmp+' 2>&1');

    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='Version:\s+([0-9\.]+)';
    FileDatas:=TStringList.Create;
    FileDatas.LoadFromFile(filetmp);
    logs.DeleteFile(filetmp);
    for i:=0 to FileDatas.Count-1 do begin
        writeln(FileDatas.Strings[i]);
        if RegExpr.Exec(FileDatas.Strings[i]) then begin
             result:=RegExpr.Match[1];
             break;
        end;
    end;

FileDatas.Clear;
if length(trim(result))=0 then begin
     logs.Debuglogs(RECURSOR_BIN_PATH()+' --version >'+filetmp+' 2>&1');
     fpsystem(RECURSOR_BIN_PATH()+' --version >'+filetmp+' 2>&1');
     RegExpr.Expression:='version:\s+([0-9\.]+)';
     FileDatas.LoadFromFile(filetmp);
    logs.DeleteFile(filetmp);
    for i:=0 to FileDatas.Count-1 do begin

        if RegExpr.Exec(FileDatas.Strings[i]) then begin
            if D then writeln('found',FileDatas.Strings[i]);
             result:=RegExpr.Match[1];
             break;
        end else begin
            if D then writeln('Not found',FileDatas.Strings[i], ' for ', RegExpr.Expression);
        end;
    end;
end;

RegExpr.free;
FileDatas.Free;
SYS.SET_CACHE_VERSION('APP_PDNS',result);

end;
//#############################################################################
procedure tpdns.WRITE_INITD();
var
   l:TstringList;
   initPath:string;
begin
initPath:='';
l:=TstringList.Create;
if length(initPath)=0 then initPath:='/etc/init.d/pdns';

l.add('#! /bin/sh');
l.add('#');
l.add('# pdns		Startup script for the PowerDNS');
l.add('#');
l.add('#');
l.add('### BEGIN INIT INFO');
l.add('# Provides:          pdns');
l.add('# Required-Start:    $local_fs $network');
l.add('# Required-Stop:     $local_fs $network');
l.add('# Should-Start:      $named');
l.add('# Should-Stop:       $named');
l.add('# Default-Start:     2 3 4 5');
l.add('# Default-Stop:      0 1 6');
l.add('# Short-Description: PowerDNS');
l.add('### END INIT INFO');
l.add('');
l.add('PATH=/bin:/usr/bin:/sbin:/usr/sbin');
l.add('');
l.add('');
l.add('start () {');
l.add('	/etc/init.d/artica-postfix start pdns');
l.add('}');
l.add('');
l.add('stop () {');
l.add('      /etc/init.d/artica-postfix stop pdns');
l.add('}');
l.add('');
l.add('case "$1" in');
l.add('    start)');
l.add('	/etc/init.d/artica-postfix start pdns');
l.add('	;;');
l.add('    stop)');
l.add('	/etc/init.d/artica-postfix stop pdns');
l.add('	;;');
l.add('    reload|force-reload)');
l.add('	/etc/init.d/artica-postfix stop pdns');
l.add('	/etc/init.d/artica-postfix start pdns');
l.add('	;;');
l.add('    restart)');
l.add('	/etc/init.d/artica-postfix stop pdns');
l.add('	/etc/init.d/artica-postfix start pdns');
l.add('	;;');
l.add('    *)');
l.add('	echo "Usage: '+initPath+' {start|stop|reload|force-reload|restart}"');
l.add('	exit 3');
l.add('	;;');
l.add('esac');
l.add('');
l.add('exit 0');

l.SaveToFile(initPath);
fpsystem('/bin/chmod 755 '+initPath);
l.free;


end;

//#############################################################################
procedure tpdns.START();
var
   count:integer;
   pid:string;
   bind9:tbind9;
   loglevel:integer;
   PowerDNSLogsQueries:integer;
   PowerDNSDNSSEC:integer;
   straces:string;
   dnsmasq_bin:string;
   dnsmasq_pid:string;
begin
    pid:=PID_NUM();
    if DisablePowerDnsManagement=1 then begin
       logs.DebugLogs('Starting......: PowerDNS is unlinked from Artica');
       if FileExists('/etc/init.d/pdns.bak') then fpsystem('/bin/cp /etc/init.d/pdns.bak /etc/init.d/pdns');
       exit;
    end;
     if not TryStrToInt(SYS.GET_INFO('PowerDNSLogLevel'),loglevel) then loglevel:=1;
     if not TryStrToInt(SYS.GET_INFO('PowerDNSLogsQueries'),PowerDNSLogsQueries) then PowerDNSLogsQueries:=0;
     if not TryStrToInt(SYS.GET_INFO('PowerDNSDNSSEC'),PowerDNSDNSSEC) then PowerDNSDNSSEC:=0;



    IF sys.PROCESS_EXIST(pid) then begin
       logs.DebugLogs('Starting......: PowerDNS Already running PID '+ pid);
       if EnablePDNS=0 then begin
          STOP();
          RECURSOR_STOP();
           exit;
       end;
       RECURSOR_START();
       exit;
    end;

    bind9:=Tbind9.Create(SYS);
    if not FIleExists(BIN_PATH()) then begin
       logs.DebugLogs('Starting......: PowerDNS is not installed');
       exit;
    end;

    if EnablePDNS=0 then begin
       logs.DebugLogs('Starting......: PowerDNS is Disabled');
       exit;
    end;

    if FileExists('/etc/init.d/pdns') then begin
       if not FileExists('/etc/init.d/pdns.bak') then fpsystem('/bin/mv /etc/init.d/pdns /etc/init.d/pdns.bak');
       WRITE_INITD();
    end;

    forcedirectories('/var/run/pdns');
    CONFIG_DEFAULT();
    dnsmasq_bin:=SYS.LOCATE_GENERIC_BIN('dnsmasq');
    if FileExists(dnsmasq_bin) then  begin
       dnsmasq_pid:=SYS.PIDOF(dnsmasq_bin);
       if SYS.PROCESS_EXIST(dnsmasq_pid) then begin
          logs.DebugLogs('Starting......: PowerDNS killing DnsMASQ PID '+ dnsmasq_pid);
          fpsystem('/bin/kill -9 '+dnsmasq_pid+' >/dev/null 2>&1');
       end;
    end;
    bind9.STOP();
    if loglevel>8 then straces:=' --log-dns-details --log-failed-updates --loglevel=3';
    fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.pdns.php --mysql');
    fpsystem(BIN_PATH()+' --daemon --guardian=yes --recursor=127.0.0.1:1553 --config-dir=/etc/powerdns --lazy-recursion=yes'+straces);
    count:=0;

 while not SYS.PROCESS_EXIST(PID_NUM()) do begin

        sleep(100);
        inc(count);
        if count>10 then begin
           logs.DebugLogs('Starting......: PowerDNS (timeout)');
           break;
        end;
  end;

pid:=PID_NUM();
    IF sys.PROCESS_EXIST(pid) then begin
       logs.DebugLogs('Starting......: PowerDNS successfully started and running PID '+ pid);
       if PowerDNSDNSSEC=1 then fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.pdns.php --dnssec');
       RECURSOR_START();
       exit;
    end;

logs.DebugLogs('Starting......: PowerDNS failed');

end;


//#############################################################################
procedure tpdns.RECURSOR_START();
var
   count:integer;
   pid,trace,quiet:string;
   loglevel:integer;
   PowerDNSLogsQueries:integer;
   PowerDNSDNSSEC:integer;
   cmdline:string;
begin
     if DisablePowerDnsManagement=1 then exit;
     quiet:='yes';
    pid:=RECURSOR_PID_NUM();
    IF sys.PROCESS_EXIST(pid) then begin
       logs.DebugLogs('Starting......: PowerDNS Recursor Already running PID '+ pid);
       if EnablePDNS=0 then RECURSOR_STOP();
       exit;
    end;

    if not FIleExists(RECURSOR_BIN_PATH()) then begin
       logs.DebugLogs('Starting......: PowerDNS Recursor is not installed');
       exit;
    end;

    if not TryStrToInt(SYS.GET_INFO('PowerDNSLogLevel'),loglevel) then loglevel:=1;
    if not TryStrToInt(SYS.GET_INFO('PowerDNSLogsQueries'),PowerDNSLogsQueries) then PowerDNSLogsQueries:=0;
    if not TryStrToInt(SYS.GET_INFO('PowerDNSDNSSEC'),PowerDNSDNSSEC) then PowerDNSDNSSEC:=0;
    forcedirectories('/var/run/pdns');
    if loglevel>8 then trace:=' --trace';
    if PowerDNSLogsQueries=1 then quiet:='no';
    cmdline:=RECURSOR_BIN_PATH()+' --daemon --export-etc-hosts --socket-dir=/var/run/pdns --quiet='+quiet+' --config-dir=/etc/powerdns'+trace;
    fpsystem(cmdline);
    count:=0;
 while not SYS.PROCESS_EXIST(RECURSOR_PID_NUM()) do begin

        sleep(100);
        inc(count);
        if count>90 then begin
           logs.DebugLogs('Starting......: PowerDNS Recursor (timeout)');
           logs.DebugLogs('Starting......: PowerDNS Recursor "'+cmdline+'"');
           break;
        end;
  end;

pid:=RECURSOR_PID_NUM();
    IF sys.PROCESS_EXIST(pid) then begin
       logs.DebugLogs('Starting......: PowerDNS Recursor successfully started and running PID '+ pid);
       exit;
    end;

logs.DebugLogs('Starting......: PowerDNS Recursor failed');

end;


//#############################################################################

procedure tpdns.RELOAD();
var
   recursor_pid:string;
   pdns_pid:string;
   pdns_control,rec_control:string;
begin
recursor_pid:=RECURSOR_PID_NUM();
pdns_pid:=PID_NUM();
pdns_control:=SYS.LOCATE_GENERIC_BIN('pdns_control');
rec_control:=SYS.LOCATE_GENERIC_BIN('rec_control');
logs.DebugLogs('Starting......: PowerDNS reloading PID:'+pdns_pid);
fpsystem(pdns_control+' --config-dir=/etc/powerdns reload >/dev/null 2>&1');
logs.DebugLogs('Starting......: PowerDNS Recursor reloading PID:'+recursor_pid);
fpsystem(rec_control+' --config-dir=/etc/powerdns --socket-dir=/var/run/pdns  reload >/dev/null 2>&1');

end;
//#############################################################################



procedure tpdns.STOP();
var
   count:integer;
   pid:string;
   pgrep:string;
   zpids:Tstringlist;
begin

    if DisablePowerDnsManagement=1 then begin
       writeln('Stopping PowerDNS............: Unlinked from Artica');
       exit;
    end;


    if FileExists('/etc/init.d/pdns') then begin
       if not FileExists('/etc/init.d/pdns.bak') then fpsystem('/bin/mv /etc/init.d/pdns /etc/init.d/pdns.bak');
       WRITE_INITD();
    end;

    CONFIG_DEFAULT();

pid:=PID_NUM();
    IF not sys.PROCESS_EXIST(pid) then begin
       writeln('Stopping PowerDNS............: Already stopped');
    zpids:=Tstringlist.Create;
    zpids:=SYS.PIDOF_PATTERN_PROCESS_LIST('exec.pdns.pipe.php');
    count:=0;
    for count:=0 to zpids.Count-1 do begin
        writeln('Stopping PowerDNS............: Stopping artica hook pid: ' +zpids.Strings[count]);
       fpsystem('/bin/kill '+zpids.Strings[count]+' >/dev/null');
    end;
       RECURSOR_STOP();
       exit;
    end;

    writeln('Stopping PowerDNS............: Stopping Smoothly PID '+pid);
    if FileExists(CONTROL_BIN_PATH()) then begin
       count:=0;
       logs.OutputCmd(CONTROL_BIN_PATH() +' stop');
       pid:=PID_NUM();
       while SYS.PROCESS_EXIST(pid) do begin
            sleep(100);
            inc(count);
        if count>10 then begin
           logs.DebugLogs('Starting......: PowerDNS (timeout)');
           break;
        end;
        pid:=PID_NUM()
      end;
    end;

pid:=PID_NUM();
IF not sys.PROCESS_EXIST(pid) then begin
       writeln('Stopping PowerDNS............: Successfully stopped');
       exit;
    end;

    writeln('Stopping PowerDNS............: Stopping PID '+pid);
       logs.OutputCmd('/bin/kill '+pid);
       count:=0;
       pid:=PID_NUM();
       while SYS.PROCESS_EXIST(pid) do begin
            sleep(200);
            inc(count);
        if count>10 then begin
           writeln('Stopping PowerDNS............: time-out');
           logs.OutputCmd('/bin/kill -9 '+pid);
           break;
        end;
         logs.OutputCmd('/bin/kill '+pid);
         pid:=PID_NUM();
     end;

    writeln('Stopping PowerDNS............: Stopping cheks artica hooks processes');
    zpids:=Tstringlist.Create;
    zpids:=SYS.PIDOF_PATTERN_PROCESS_LIST('exec.pdns.pipe.php');
    count:=0;
    for count:=0 to zpids.Count-1 do begin
        writeln('Stopping PowerDNS............: Stopping artica hook pid: ' +zpids.Strings[count]);
       fpsystem('/bin/kill '+zpids.Strings[count]+' >/dev/null');
    end;


pid:=PID_NUM();
IF not sys.PROCESS_EXIST(pid) then begin
       writeln('Stopping PowerDNS............: Successfully stopped');
       RECURSOR_STOP();
       exit;
    end;



       writeln('Stopping PowerDNS............: Failed');

end;


//#############################################################################
procedure tpdns.RECURSOR_STOP();
var
   count:integer;
   pid:string;
begin

    if DisablePowerDnsManagement=1 then begin
       writeln('Stopping PowerDNS Recursor...: Unlinked from Artica');
       exit;
    end;

pid:=RECURSOR_PID_NUM();
    IF not sys.PROCESS_EXIST(pid) then begin
       writeln('Stopping PowerDNS Recursor...: Already stopped');
       exit;
    end;

    writeln('Stopping PowerDNS Recursor...: Stopping Smoothly PID '+pid);                                                                                                                               

       logs.OutputCmd('/bin/kill '+pid);
       count:=0;
       pid:=RECURSOR_PID_NUM();
       while SYS.PROCESS_EXIST(pid) do begin
            sleep(100);
            inc(count);
        if count>10 then begin
           writeln('Stopping PowerDNS Recursor...: time-out');
           break;
        end;
         logs.OutputCmd('/bin/kill '+pid);
         pid:=RECURSOR_PID_NUM();
     end;


pid:=RECURSOR_PID_NUM();
IF not sys.PROCESS_EXIST(pid) then begin
       writeln('Stopping PowerDNS Recursor...: Successfully stopped');
       exit;
    end;



    writeln('Stopping PowerDNS Recursor...: Failed');

end;


//#############################################################################
function tpdns.STATUS:string;
var
pidpath:string;
begin
   SYS.MONIT_DELETE('APP_PDNS');
   SYS.MONIT_DELETE('APP_PDNS_RECURSOR');
pidpath:=logs.FILE_TEMP();
fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.status.php --pdns >'+pidpath +' 2>&1');
result:=logs.ReadFromFile(pidpath);
logs.DeleteFile(pidpath);

end;
//#############################################################################
function tpdns.MODULE_DIR():string;
begin
if FileExists('/usr/lib/pdns/libldapbackend.so') then exit('/usr/lib/pdns');
if FileExists('/usr/lib/powerdns/libldapbackend.so') then exit('/usr/lib/powerdns');
if FileExists('/usr/lib64/pdns/libldapbackend.so') then exit('/usr/lib64/pdns');
if FileExists('/usr/lib64/powerdns/libldapbackend.so') then exit('/usr/lib64/powerdns');
logs.DebugLogs('Starting......: PowerDNS FATAL, Unable to stat libldapbackend.so !');
SYS.THREAD_COMMAND_SET('/usr/share/artica-postfix/setup-ubuntu --check-pdns');
end;
//#############################################################################
function tpdns.MYSQL_EXISTS():boolean;
begin
result:=false;
if FileExists(MODULE_DIR()+'/libgmysqlbackend.so') then exit(true);
end;
//#############################################################################
procedure tpdns.CONFIG_DEFAULT();
var
   l:Tstringlist;
   z:Tstringlist;
   tcp:ttcpip;
   i:integer;
   ipstr:string;
   iplist:string;
   cdirtmp:string;
   loglevel:integer;
   ldapserver:string;
   mysql_server:string;
   mysql_port:integer;
   localldap:boolean;
   PowerDNSMySQLEngine:integer;
   PowerDNSListenAddr:Tstringlist;
   PowerDNSListenAddrDefault:boolean;
   PowerUseGreenSQL:integer;
   PowerDisableDisplayVersion:integer;
   PowerChroot:integer;
   PowerActHasMaster:integer;
   PowerDNSDNSSEC:integer;
   PowerDNSDisableLDAP,PDSNInUfdb:integer;
   gmysql,launch_ldap:string;
   PowerDNSPublicMode:integer;
   SquidActHasReverse:integer;
   PowerActAsSlave:integer;
   PdnsNoWriteConf:integer;
   PowerSkipCname:integer;
   cdirlistV6,pipe:string;
   iplistV6:string;
   RecursoriplistV6:string;
   RecursoripAllowFrom:string;
   database_admin:string;
   EnableUfdbGuard:integer;
begin
if DisablePowerDnsManagement=1 then exit;

iplist:='';
iplistV6:='';
RecursoriplistV6:='';
RecursoripAllowFrom:='';
ForceDirectories('/etc/powerdns/pdns.d');
if not TryStrToInt(SYS.GET_INFO('PowerDNSLogLevel'),loglevel) then loglevel:=1;
if not TryStrToInt(SYS.GET_INFO('PowerDNSMySQLEngine'),PowerDNSMySQLEngine) then PowerDNSMySQLEngine:=1;
if not TryStrToInt(SYS.GET_INFO('PowerUseGreenSQL'),PowerUseGreenSQL) then PowerUseGreenSQL:=0;
if not TryStrToInt(SYS.GET_INFO('PowerDisableDisplayVersion'),PowerDisableDisplayVersion) then PowerDisableDisplayVersion:=0;
if not TryStrToInt(SYS.GET_INFO('PowerChroot'),PowerChroot) then PowerChroot:=0;
if not TryStrToInt(SYS.GET_INFO('PowerActHasMaster'),PowerActHasMaster) then PowerActHasMaster:=0;
if not TryStrToInt(SYS.GET_INFO('PowerDNSDNSSEC'),PowerDNSDNSSEC) then PowerDNSDNSSEC:=0;
if not TryStrToInt(SYS.GET_INFO('PowerDNSDisableLDAP'),PowerDNSDisableLDAP) then PowerDNSDisableLDAP:=1;
if not TryStrToInt(SYS.GET_INFO('PowerDNSPublicMode'),PowerDNSPublicMode) then PowerDNSPublicMode:=0;
if not TryStrToInt(SYS.GET_INFO('PowerActAsSlave'),PowerActAsSlave) then PowerActAsSlave:=0;
if not TryStrToInt(SYS.GET_INFO('PdnsNoWriteConf'),PdnsNoWriteConf) then PdnsNoWriteConf:=0;
if not TryStrToInt(SYS.GET_INFO('PowerSkipCname'),PowerSkipCname) then PowerSkipCname:=0;
if not TryStrToInt(SYS.GET_INFO('PDSNInUfdb'),PDSNInUfdb) then PDSNInUfdb:=0;
if not TryStrToInt(SYS.GET_INFO('SquidActHasReverse'),SquidActHasReverse) then SquidActHasReverse:=0;
if not TryStrToInt(SYS.GET_INFO('EnableUfdbGuard'),EnableUfdbGuard) then EnableUfdbGuard:=0;



if SquidActHasReverse=1 then PDSNInUfdb:=0;
if EnableUfdbGuard=0 then PDSNInUfdb:=0;
if not FileExists('/usr/bin/ufdbgclient') then PDSNInUfdb:=0;

database_admin:=SYS.GET_MYSQL('database_admin');
if length(database_admin)=0 then database_admin:='root';
pipe:='';
if PDSNInUfdb=1 then pipe:='pipe,';


// PowerSkipCname: Do not perform CNAME indirection for each query

if PdnsNoWriteConf=1 then begin
      logs.DebugLogs('Starting......: PowerDNS PdnsNoWriteConf is enabled, skip the config and aborting pdns.conf');
      exit;
end;

if not FileExists(SYS.LOCATE_GENERIC_BIN('pdnssec')) then PowerDNSDNSSEC:=0;
if not MYSQL_EXISTS() then begin
   logs.DebugLogs('Starting......: PowerDNS seems not MySQL compliance but continue anyway...');
end;

PowerDNSListenAddrDefault:=true;
tcp:=ttcpip.Create;
z:=Tstringlist.Create;
z.AddStrings(tcp.InterfacesStringList());
cdirlist:='127.0.0.0/8,127.0.0.1,';

 if FileExists('/etc/artica-postfix/settings/Daemons/PowerDNSListenAddr') then begin
        PowerDNSListenAddr:=Tstringlist.Create;
        PowerDNSListenAddr.LoadFromFile('/etc/artica-postfix/settings/Daemons/PowerDNSListenAddr');
        for i:=0 to PowerDNSListenAddr.Count-1 do begin
              if length(trim(PowerDNSListenAddr.Strings[i]))>0 then begin
                      logs.DebugLogs('Starting......: PowerDNS listen IP address '+PowerDNSListenAddr.Strings[i]);
                      cdirtmp:=tcp.CDIR(ipstr);
                      iplist:=iplist+trim(PowerDNSListenAddr.Strings[i])+',';
                      PowerDNSListenAddrDefault:=false;
                      if length(cdirtmp)>0 then begin
                           if pos(cdirtmp,' '+cdirlist)=0 then cdirlist:=cdirlist+cdirtmp+',';
                      end;
              end;
        end;

 end;

  if FileExists('/etc/artica-postfix/settings/Daemons/PowerDNSListenAddrV6') then begin
        PowerDNSListenAddr:=Tstringlist.Create;
        PowerDNSListenAddr.LoadFromFile('/etc/artica-postfix/settings/Daemons/PowerDNSListenAddrV6');
        for i:=0 to PowerDNSListenAddr.Count-1 do begin
              if length(trim(PowerDNSListenAddr.Strings[i]))>0 then begin
               logs.DebugLogs('Starting......: PowerDNS listen IPV6 address '+PowerDNSListenAddr.Strings[i]);
               if length(trim(PowerDNSListenAddr.Strings[i]))=0 then continue;
               iplistV6:=iplistV6+trim(PowerDNSListenAddr.Strings[i])+',';
               RecursoriplistV6:=RecursoriplistV6+'['+PowerDNSListenAddr.Strings[i]+'],';
               RecursoripAllowFrom:=RecursoripAllowFrom+PowerDNSListenAddr.Strings[i]+',';
              end;
        end;

 end;


for i:=0 to z.Count-1 do begin
    if(length(z.Strings[i]))=0 then continue;
    if z.Strings[i]='vmnet1' then continue;
    if z.Strings[i]='vmnet8' then continue;
    if z.Strings[i]='tun0' then continue;
   // writeln('interface:',z.Strings[i]);
    ipstr:=tcp.IP_ADDRESS_INTERFACE(z.Strings[i]);
    if ipstr='0.0.0.0' then continue;
    if PowerDNSListenAddrDefault then logs.DebugLogs('Starting......: PowerDNS listen IP address '+ipstr);
    cdirtmp:=tcp.CDIR(ipstr);

    if length(cdirtmp)>0 then begin
       if pos(cdirtmp,' '+cdirlist)=0 then cdirlist:=cdirlist+cdirtmp+',';
    end;

    if PowerDNSListenAddrDefault then if pos(ipstr,' '+iplist)=0 then iplist:=iplist+ipstr+',';
end;

logs.DebugLogs('Starting......: PowerDNS log level '+IntToStr(loglevel));
l:=Tstringlist.Create;

if Copy(iplist,length(iplist),1)=',' then iplist:=Copy(iplist,1,length(iplist)-1);
if Copy(cdirlist,length(cdirlist),1)=',' then cdirlist:=Copy(cdirlist,1,length(cdirlist)-1);
//if PowerDNSMySQLEngine=1 then gmysql:='gmysql ';
gmysql:='gmysql ';
logs.DebugLogs('Starting......: PowerDNS PowerDNSMySQLEngine='+IntToStr(PowerDNSMySQLEngine));




//if ldapserver='127.0.0.1' then ldapserver:='localhost';
if PowerDNSPublicMode=0 then l.add('allow-recursion='+cdirlist);
l.add('#allow-recursion=0.0.0.0/0 ');
l.add('#allow-recursion-override=on');
l.add('cache-ttl=20');
if PowerChroot=1 then begin
   logs.DebugLogs('Starting......: PowerDNS is chrooted...');
   l.add('chroot=./');
end;


if PowerActHasMaster=1 then begin
   logs.DebugLogs('Starting......: PowerDNS Act has master');
   l.add('master=yes');
end;

if PowerActAsSlave=1 then begin
   logs.DebugLogs('Starting......: PowerDNS Act has Slave');
   l.add('slave=yes');
end;



l.add('config-dir=/etc/powerdns');
l.add('# config-name=');
l.add('# control-console=no');
l.add('daemon=yes');
l.add('# default-soa-name=a.misconfigured.powerdns.server');
l.add('disable-axfr=no');
l.add('# disable-tcp=no');
l.add('# distributor-threads=3');
l.add('# fancy-records=no');
l.add('guardian=yes');

launch_ldap:=',ldap';
if PowerDNSDisableLDAP=1 then launch_ldap:='';
l.add('launch='+pipe+gmysql+launch_ldap);
if PDSNInUfdb=1 then begin
   fpsystem('/bin/chmod 777 /usr/share/artica-postfix/exec.pdns.pipe.php >/dev/null 2>&1');
   l.add('pipe-command=/usr/share/artica-postfix/exec.pdns.pipe.php');
   l.add('pipebackend-abi-version=2');
   l.add('distributor-threads=2');
end;
l.add('lazy-recursion=yes');
l.add('# load-modules=');
l.add('#local-address=0.0.0.0');
l.add('local-address='+iplist);

if(length(iplistV6)>3) then iplistV6:='::1,'+iplistV6;
iplistV6:=AnsiReplaceText(iplistV6,',,',',');
iplistV6:=AnsiReplaceText(iplistV6,',,',',');
if(length(iplistV6)=0) then l.add('#local-ipv6=::1');
if(length(iplistV6)>3) then l.add('local-ipv6='+iplistV6);
//l.add('query-local-address6=::1');
l.add('local-port=53');
l.add('log-dns-details=on');
l.add('log-failed-updates=on');
l.add('logfile=/var/log/pdns.log');
l.add('# logging-facility=');
l.add('loglevel='+IntToStr(loglevel));
l.add('# max-queue-length=5000');
l.add('# max-tcp-connections=10');
l.add('module-dir='+MODULE_DIR());
l.add('# negquery-cache-ttl=60');
l.add('out-of-zone-additional-processing=yes');
l.add('# query-cache-ttl=20');
l.add('query-logging=yes');
l.add('# queue-limit=1500');
l.add('# receiver-threads=1');
l.add('# recursive-cache-ttl=10');
l.add('recursor=127.0.0.1:1553');        //
l.add('#setgid=pdns');
l.add('#setuid=pdns');
//l.add('skip-cname=yes');
l.add('# slave-cycle-interval=60');
l.add('# smtpredirector=a.misconfigured.powerdns.smtp.server');
l.add('# soa-minimum-ttl=3600');
l.add('# soa-refresh-default=10800');
l.add('# soa-retry-default=3600');
l.add('# soa-expire-default=604800');
l.add('# soa-serial-offset=0');
l.add('socket-dir=/var/run/pdns');
l.add('# strict-rfc-axfrs=no');
l.add('# urlredirector=127.0.0.1');
l.add('use-logfile=yes');
l.add('webserver=yes');
l.add('webserver-address=127.0.0.1');
l.add('webserver-password=');
l.add('webserver-port=8081');
l.add('webserver-print-arguments=no');
//if PowerSkipCname=0 then l.add('skip-cname=no') else l.add('skip-cname=yes');
l.add('# wildcard-url=no');
l.add('# wildcards=');
if PowerDisableDisplayVersion=0 then l.add('version-string=powerdns') else l.add('version-string=nope');



fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.greensql.php --sets');
mysql_server:=SYS.GET_MYSQL('mysql_server');
if not TryStrToInt(SYS.GET_MYSQL('port'),mysql_port) then mysql_port:=3306;

if PowerUseGreenSQL=1 then begin
    mysql_server:=SYS.GET_MYSQL('GreenIP');
    if not TryStrToInt(SYS.GET_MYSQL('GreenPort'),mysql_port) then mysql_port:=3305;
end;
if length(mysql_server)=0 then mysql_server:='127.0.0.1';
logs.DebugLogs('Starting......: PowerDNS MySQL backend is enabled ['+mysql_server+':'+IntTostr(mysql_port)+']');
l.add('gmysql-host='+mysql_server);
l.add('gmysql-user='+database_admin);
l.add('gmysql-password='+SYS.GET_MYSQL('database_password'));
l.add('gmysql-port='+IntTostr(mysql_port));
l.add('gmysql-dbname=powerdns');
if PowerDNSDNSSEC=1 then begin
    l.add('gmysql-dnssec');
    logs.DebugLogs('Starting......: PowerDNS DNSSEC is enabled...');
end;

if PowerDNSDisableLDAP=1 then logs.DebugLogs('Starting......: PowerDNS LDAP backend is disabled');

if PowerDNSDisableLDAP=0 then begin
    ldapserver:=zldap.ldap_settings.servername;
    if ldapserver='127.0.0.1' then localldap:=true;
    if ldapserver='localhost' then localldap:=true;

   l.add('ldap-host='+ldapserver+':'+zldap.ldap_settings.Port+'');
   l.add('ldap-basedn=ou=dns,'+zldap.ldap_settings.suffix);

   if not localldap then begin
   l.add('ldap-binddn="cn='+zldap.ldap_settings.admin+','+zldap.ldap_settings.suffix+'"');
   l.add('ldap-secret="'+zldap.ldap_settings.password+'"');
end;
   l.add('ldap-method=simple');
end;

forceDirectories('/etc/powerdns/pdns.d');
logs.WriteToFile(l.Text,'/etc/powerdns/pdns.conf');
if FileExists('/etc/pdns/pdns.conf') then  logs.WriteToFile(l.Text,'/etc/pdns/pdns.conf');
logs.DebugLogs('Starting......: PowerDNS updating /etc/powerdns/pdns.conf done...');
//http://wiki.debian.org/LDAP/PowerDNSSetup
//http://fxp0.org.ua/2006/sep/21/powerdns-ldap-backend-setup/
//dhcp3-server-ldap
//http://wiki.debian.org/DebianEdu/LdapifyServices
l.clear;

if PowerDNSDisableLDAP=0 then begin
   if not localldap then l.add('ldap-host='+ldapserver+':'+zldap.ldap_settings.Port+'');
   l.add('ldap-basedn=ou=dns,'+zldap.ldap_settings.suffix);

   if not localldap then begin
      l.add('ldap-binddn="cn='+zldap.ldap_settings.admin+','+zldap.ldap_settings.suffix+'"');
      l.add('ldap-secret="'+zldap.ldap_settings.password+'"');
   end;

   l.add('ldap-method=simple');
end;

l.add('recursor=127.0.0.1:1553');


l.add('gmysql-host='+mysql_server);
l.add('gmysql-port='+IntTostr(mysql_port));
l.add('gmysql-user='+database_admin);
l.add('gmysql-password='+SYS.GET_MYSQL('database_password'));
l.add('gmysql-dbname=powerdns');
logs.DebugLogs('Starting......: PowerDNS checks MySQL table and database...');
fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.pdns.php --mysql');




logs.WriteToFile(l.Text,'/etc/powerdns/pdns.d/pdns.local');
logs.DebugLogs('Starting......: PowerDNS updating /etc/powerdns/pdns.d/pdns.local done...');
L.Clear;
RecursoripAllowFrom:=cdirlist+','+RecursoripAllowFrom;
RecursoripAllowFrom:=AnsiReplaceText(RecursoripAllowFrom,',,',',');
RecursoripAllowFrom:=AnsiReplaceText(RecursoripAllowFrom,',,',',');

If FileExists('/etc/powerdns/forward-zones-file') then l.add('forward-zones-file=/etc/powerdns/forward-zones-file');
If FileExists('/etc/powerdns/forward-zones-recurse') then l.add('forward-zones-recurse='+logs.ReadFromFile('/etc/powerdns/forward-zones-recurse'));

// Forward-zone

l.add('local-address=127.0.0.1');
l.add('quiet=no');
l.add('config-dir=/etc/powerdns/');
l.add('daemon=yes');
l.add('local-port=1553');
l.add('log-common-errors=yes');
l.add('allow-from='+RecursoripAllowFrom);
l.add('socket-dir=/var/run/pdns');
//l.add('query-local-address6=');
logs.WriteToFile(l.Text,'/etc/powerdns/recursor.conf');
logs.DebugLogs('Starting......: PowerDNS updating /etc/powerdns/recursor.conf done...');

 if PowerDNSDNSSEC=1 then begin
    logs.DebugLogs('Starting......: PowerDNS DNSSEC checking settings.....');
    fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.pdns.php --dnsseck');
 end;



l.free;
end;








end.
