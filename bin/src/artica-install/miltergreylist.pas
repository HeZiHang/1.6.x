unit miltergreylist;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,Process,logs,unix,RegExpr in 'RegExpr.pas',zsystem;

  type
  tmilter_greylist=class


private
     LOGS:Tlogs;
     SYS:TSystem;
     artica_path:string;
     why_is_disabled:string;
     EnableASSP:integer;
     MilterGreyListEnabled:integer;
     MilterGreyListEnabled_string:string;
     EnablePostfixMultiInstance:integer;
     EnableStopPostfix:integer;
     procedure START_WITHOUT_INITD(NotRepairIfFailed:boolean=false);
     procedure FIX_START_ERROR();

public
    procedure   Free;
    constructor Create(const zSYS:Tsystem);
    //function    STATUS:string;
    function    MILTER_GREYLIST_PID_PATH():string;
    function    MILTER_GREYLIST_PID():string;
    function    MILTER_GREYLIST_ETC_DEFAULT():string;
    procedure   MILTER_GREYLIST_START();
    procedure   MILTER_GREYLIST_CHANGE_INIT_TO_POSTFIX();
    function    MILTER_GREYLIST_INITD():string;
    function    MILTER_GREYLIST_CONF_PATH():string;
    function    MILTER_GREYLIST_BIN_PATH():string;
    function    MILTER_GREYLIST_GET_VALUE(key:string):string;
    function    MILTER_GREYLIST_SET_VALUE(key:string;value:string):string;
    procedure   MILTER_GREYLIST_CHANGE_PID_IN_INITD();
    procedure   MILTER_GREYLIST_STOP();
    function    VERSION():string;
    procedure   FIX_RACL();
    FUNCTION    STATUS():string;
    function    CheckSocket():string;
    procedure   REMOVE();
END;

implementation

constructor tmilter_greylist.Create(const zSYS:Tsystem);
begin
       forcedirectories('/etc/artica-postfix');
       forcedirectories('/opt/artica/tmp');
       LOGS:=tlogs.Create();
       SYS:=zSYS;
       MilterGreyListEnabled:=0;
       EnablePostfixMultiInstance:=0;
       MilterGreyListEnabled_string:=trim(SYS.GET_INFO('MilterGreyListEnabled'));
       if MilterGreyListEnabled_string='1' then MilterGreyListEnabled:=1;

       if not TryStrToInt(SYS.GET_INFO('EnableASSP'),EnableASSP) then EnableASSP:=0;
       if not FileExists('/usr/share/assp/assp.pl') then EnableASSP:=0;
       if not TryStrToInt(SYS.GET_INFO('EnablePostfixMultiInstance'),EnablePostfixMultiInstance) then EnablePostfixMultiInstance:=0;
       if not TryStrToInt(SYS.GET_INFO('EnableStopPostfix'),EnableStopPostfix) then EnableStopPostfix:=0;

       if EnableStopPostfix=1 then MilterGreyListEnabled:=0;

       if MilterGreyListEnabled=1 then begin
          if EnableASSP=1 then begin
             why_is_disabled:=' ASSP do the same feature';
             MilterGreyListEnabled:=0;
          end;

          if EnablePostfixMultiInstance=1 then begin
             why_is_disabled:='multiple postfix instances enabled';
             MilterGreyListEnabled:=0;
             //logs.Debuglogs('tmilter_greylist.Create() :: Postfix multiple instance is enabled, disable milter-greylist');
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
procedure tmilter_greylist.free();
begin
    logs.Free;


end;
//##############################################################################
function tmilter_greylist.MILTER_GREYLIST_PID_PATH():string;
begin
  if FileExists('/var/run/milter-greylist.pid') then exit('/var/run/milter-greylist.pid');
  result:=MILTER_GREYLIST_GET_VALUE('pidfile');
end;
//############################################################################# #
function tmilter_greylist.MILTER_GREYLIST_PID():string;
var pid:string;
begin
pid:=SYS.GET_PID_FROM_PATH(MILTER_GREYLIST_PID_PATH());
if length(pid)=0 then begin
   pid:=SYS.PidByProcessPath(MILTER_GREYLIST_BIN_PATH());
end;
result:=pid;
exit;
end;
 //##############################################################################
procedure tmilter_greylist.REMOVE();
begin
MILTER_GREYLIST_STOP();
fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --remove milter-greylist');
logs.DeleteFile(MILTER_GREYLIST_BIN_PATH());
logs.DeleteFile(MILTER_GREYLIST_INITD());
fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.main-cf.php --reconfigure');
logs.DeleteFile('/etc/artica-postfix/versions.cache');
fpsystem('/usr/share/artica-postfix/bin/artica-install --write-versions');
fpsystem('/usr/share/artica-postfix/bin/process1 --force');

end;
 //##############################################################################


function tmilter_greylist.VERSION():string;
var
tmpstr:string;
FileDatas:TstringList;
i:integer;
RegExpr:tRegExpr;

begin

result:=SYS.GET_CACHE_VERSION('APP_MGREYLIST');
   if length(result)>2 then exit;

tmpstr:=LOGS.FILE_TEMP();
if not FileExists(MILTER_GREYLIST_BIN_PATH()) then exit;
fpsystem(MILTER_GREYLIST_BIN_PATH()+' -r >'+tmpstr+' 2>&1');
    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='^milter-greylist-([0-9a-z\.]+)';
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
             SYS.SET_CACHE_VERSION('APP_MGREYLIST',result);

end;
//##############################################################################
function tmilter_greylist.MILTER_GREYLIST_INITD():string;
begin
    if FileExists('/etc/init.d/milter-greylist') then exit('/etc/init.d/milter-greylist');
    if FileExists('/etc/init.d/milter-greylist') then exit('/etc/init.d/milter-greylist');
end;
//############################################################################# #
function tmilter_greylist.MILTER_GREYLIST_CONF_PATH():string;
begin
if FileExists('/etc/milter-greylist/greylist.conf') then exit('/etc/milter-greylist/greylist.conf');
if FileExists('/etc/mail/greylist.conf') then exit('/etc/mail/greylist.conf');
if FileExists('/opt/artica/etc/milter-greylist/greylist.conf') then exit('/opt/artica/etc/milter-greylist/greylist.conf');
exit('/etc/mail/greylist.conf');
end;
 //##############################################################################
 function tmilter_greylist.MILTER_GREYLIST_BIN_PATH():string;
begin
result:=sys.LOCATE_GENERIC_BIN('milter-greylist');
end;
 //##############################################################################
FUNCTION tmilter_greylist.STATUS():string;
var  pidpath:string;
begin

if not FileExists(MILTER_GREYLIST_BIN_PATH()) then begin
   SYS.MONIT_DELETE('APP_MILTERGREYLIST');
   exit;
end;
SYS.MONIT_DELETE('APP_MILTERGREYLIST');
if not FileExists(MILTER_GREYLIST_BIN_PATH()) then exit;
pidpath:=logs.FILE_TEMP();
fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.status.php --milter-greylist >'+pidpath +' 2>&1');
result:=logs.ReadFromFile(pidpath);
logs.DeleteFile(pidpath);
end;
 //##############################################################################
 procedure tmilter_greylist.MILTER_GREYLIST_STOP();
 var
    count:integer;
    processes:string;
begin
count:=0;
  if not FileExists(MILTER_GREYLIST_BIN_PATH()) then exit;

    if EnablePostfixMultiInstance=1 then begin
       fpsystem(SYS.LOCATE_PHP5_BIN() +' /usr/share/artica-postfix/exec.milter-greylist.php --stop');
       exit;
    end;

  if not SYS.PROCESS_EXIST(SYS.PIDOF(MILTER_GREYLIST_BIN_PATH())) then begin
      writeln('Stopping milter-greylist.....: Already stopped');             
      exit;
  end;

  //  if SYS.PROCESS_EXIST(MILTER_GREYLIST_PID()) then begin

   writeln('Stopping milter-greylist.....: ' + MILTER_GREYLIST_PID() + ' PID');
   logs.Syslogs('artica will try to stop milter-greylist');
   logs.OutputCmd('/bin/kill ' + MILTER_GREYLIST_PID());
   sleep(100);

  while SYS.PROCESS_EXIST(MILTER_GREYLIST_PID()) do begin
        sleep(100);
        inc(count);

        if count>50 then begin
           writeln('Stopping milter-greylist.....: ' + MILTER_GREYLIST_PID() + ' PID (timeout) kill it');
           logs.OutputCmd('/bin/kill -9 ' + MILTER_GREYLIST_PID());
           break;
        end;
  end;


  processes:=SYS.PROCESS_LIST_PID(MILTER_GREYLIST_BIN_PATH());

  if length(processes)>0 then begin
      writeln('Stopping milter-greylist.....: ' + processes +' PID(s)');
      logs.OutputCmd('/bin/kill ' + processes);
      sleep(100);
  end;

  if not SYS.PROCESS_EXIST(MILTER_GREYLIST_PID()) then begin
     writeln('Stopping milter-greylist.....: successfully stopped');
  end else begin
     writeln('Stopping milter-greylist.....: failed to stop.');
  end;

  //MILTER_GREYLIST_PID
end;
//############################################################################
function tmilter_greylist.CheckSocket():string;
var
l:TstringList;
i:Integer;
RegExpr:TRegExpr;

begin
l:=TstringList.Create;
RegExpr:=TRegExpr.Create;
if FileExists(MILTER_GREYLIST_INITD()) then begin
       logs.Debuglogs('CheckSocket:: Checking in ' + MILTER_GREYLIST_INITD());
       RegExpr.Expression:='SOCKET=(.+)';
       l.LoadFromFile(MILTER_GREYLIST_INITD());
         for i:=0 to l.Count-1 do begin
             if RegExpr.Exec(l.Strings[i]) then begin
                result:=RegExpr.Match[1];
                result:=AnsiReplaceText(result,'"','');
                result:=AnsiReplaceText(result,'''','');
                RegExpr.free;
                l.free;
                exit;
             end;
         end;
end;

if FileExists(MILTER_GREYLIST_ETC_DEFAULT()) then begin
     logs.Debuglogs('CheckSocket:: Checking in ' + MILTER_GREYLIST_ETC_DEFAULT());
      RegExpr.Expression:='SOCKET=(.+)';
      l.LoadFromFile(MILTER_GREYLIST_ETC_DEFAULT());
         for i:=0 to l.Count-1 do begin
             if RegExpr.Exec(l.Strings[i]) then begin
                result:=RegExpr.Match[1];
                result:=AnsiReplaceText(result,'"','');
                result:=AnsiReplaceText(result,'''','');
                RegExpr.free;
                l.free;
                exit;
             end;
         end;
end;



result:=MILTER_GREYLIST_GET_VALUE('socket');
result:=AnsiReplaceText(result,'"','');
result:=AnsiReplaceText(result,'''','');
if length(trim(result))=0 then result:='/var/run/milter-greylist/milter-greylist.sock';
RegExpr.free;
l.free;
end;
//############################################################################
procedure tmilter_greylist.MILTER_GREYLIST_CHANGE_PID_IN_INITD();
  var
     l:TstringList;
     RegExpr:TRegExpr;
     i:integer;
     initPath:string;
     pidpath:string;

begin
   initPath:=MILTER_GREYLIST_INITD();
   pidpath:=MILTER_GREYLIST_PID_PATH();
   
   if not FileExists(initPath) then begin
      logs.Debuglogs('MILTER_GREYLIST_CHANGE_PID_IN_INITD:: unable to stat init.d script');
      exit;
   end;
   
   if length(pidpath)=0 then begin
      logs.Debuglogs('MILTER_GREYLIST_CHANGE_PID_IN_INITD:: unable to locate "pidfile" value in "'+MILTER_GREYLIST_CONF_PATH()+'" config file !');
      exit;
   end;

   
   l:=TstringList.Create;
   l.LoadFromFile(MILTER_GREYLIST_INITD());
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^PIDFILE=.+';
   for i:=0 to l.Count-1 do begin
       if RegExpr.Exec(l.Strings[i]) then begin
          l.Strings[i]:='PIDFILE="'+pidpath+'"';
          logs.Debuglogs('MILTER_GREYLIST_CHANGE_PID_IN_INITD:: success change PIDFILE to ' + pidpath);
          try
             l.SaveToFile(MILTER_GREYLIST_INITD());
          except
             logs.Debuglogs('MILTER_GREYLIST_CHANGE_PID_IN_INITD:: fatal error while saving ' + MILTER_GREYLIST_INITD());
             exit;
          end;
          break;
       end;
   end;

   l.free;
   RegExpr.free;
end;
//############################################################################




function tmilter_greylist.MILTER_GREYLIST_SET_VALUE(key:string;value:string):string;
  var
     l:TstringList;
     RegExpr:TRegExpr;
     i:integer;

begin
result:='';
   if not FileExists(MILTER_GREYLIST_CONF_PATH()) then exit;
try
   l:=TstringList.Create;
   l.LoadFromFile(MILTER_GREYLIST_CONF_PATH());
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^'+key+'.+?"(.+?)"';
   for i:=0 to l.Count-1 do begin
        if RegExpr.Exec(l.Strings[i]) then begin
            l.Strings[i]:=key+ ' "'+value+'"';
            l.SaveToFile(MILTER_GREYLIST_CONF_PATH());
            break;
        end;
   end;
except
    logs.Debuglogs('MILTER_GREYLIST_SET_VALUE('+key+') FATAL ERROR');
end;
   l.free;
   RegExpr.free;
end;
 //##############################################################################
 function tmilter_greylist.MILTER_GREYLIST_GET_VALUE(key:string):string;
  var
     l:TstringList;
     RegExpr:TRegExpr;
     i:integer;


begin


   if not FileExists(MILTER_GREYLIST_CONF_PATH()) then begin
      logs.Debuglogs('MILTER_GREYLIST_GET_VALUE:: unable to get configuration file ' + MILTER_GREYLIST_CONF_PATH());
      exit;
   end;
try

   l:=TstringList.Create;
   l.LoadFromFile(MILTER_GREYLIST_CONF_PATH());
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^'+key+'.+?"(.+?)"';
   for i:=0 to l.Count-1 do begin
        if RegExpr.Exec(l.Strings[i]) then begin
            result:=RegExpr.Match[1];

            break;
        end;
   end;
except
    logs.Debuglogs('MILTER_GREYLIST_GET_VALUE('+key+') FATAL ERROR');
end;
   l.free;
   RegExpr.free;
   if length(result)=0 then begin
      logs.Debuglogs('MILTER_GREYLIST_GET_VALUE:: unable to get infos on ' + key + ' expression=^'+key+'.+?"(.+?)"' );
      logs.Debuglogs('conffile is ' + MILTER_GREYLIST_CONF_PATH());
   end;
   
end;
 //##############################################################################
function tmilter_greylist.MILTER_GREYLIST_ETC_DEFAULT():string;
var
   l:TstringList;
begin
result:='';
if not FileExists('/etc/default/milter-greylist') then exit;
l:=TstringList.Create;
l.Add('# Defaults for milter-greylist initscript');
l.Add('# sourced by /etc/init.d/milter-greylist');
l.Add('# installed at /etc/default/milter-greylist by the maintainer scripts');
l.Add('# 2006-08-18 Herbert Straub');
l.Add('');
l.Add('# Change to one to enable milter-greylist');
l.Add('# Don''t forget to edit the configurationfile /etc/mail/greylist.conf');
l.Add('ENABLED=1');
l.Add('');
l.Add('PIDFILE="/var/run/milter-greylist/milter-greylist.pid"');
l.Add('SOCKET="/var/run/milter-greylist/milter-greylist.sock"');
l.Add('USER="postfix"');
l.Add('');
l.Add('# Other options');
l.Add('# OPTIONS=""');
try
l.SaveToFile('/etc/default/milter-greylist');
except
    logs.Debuglogs('MILTER_GREYLIST_ETC_DEFAULT:: FATAL ERROR WHILE WRITING ON /etc/default/milter-greylist is there appArmor or SeLinux here ???' );
    logs.syslogs('MILTER_GREYLIST_ETC_DEFAULT:: FATAL ERROR WHILE WRITING ON /etc/default/milter-greylist is there appArmor or SeLinux here ???' );
    l.free;
    exit;
end;
logs.Debuglogs('MILTER_GREYLIST_ETC_DEFAULT: /etc/default/milter-greylist OK');
end;
//############################################################################# #
procedure tmilter_greylist.MILTER_GREYLIST_CHANGE_INIT_TO_POSTFIX();
var
    RegExpr:TRegExpr;
    FileDatas:TStringList;
    i:integer;
    l:Tstringlist;
begin
 if not FileExists(MILTER_GREYLIST_INITD()) then begin
    logs.Debuglogs('MILTER_GREYLIST_CHANGE_INIT_TO_POSTFIX:: unable to stat milter-greylist init.d');
    exit;
 end;
 FileDatas:=TstringList.Create;
 FileDatas.LoadFromFile(MILTER_GREYLIST_INITD());
 RegExpr:=TRegExpr.Create;

 for i:=0 to FileDatas.Count-1 do begin
      RegExpr.Expression:='^USER=.+';
 
     if RegExpr.Exec(FileDatas.Strings[i]) then begin
         logs.Debuglogs('MILTER_GREYLIST_CHANGE_INIT_TO_POSTFIX:: found ' + FileDatas.Strings[i]);
         FileDatas.Strings[i]:='USER="postfix"';
         FileDatas.SaveToFile(MILTER_GREYLIST_INITD());
         break;
     end;
     
 end;
 
 
 if FIleExists('/sbin/chkconfig') then begin
         logs.Debuglogs('MILTER_GREYLIST_CHANGE_INIT_TO_POSTFIX:: save /etc/init.d/milter-greylist');
         l:=TstringList.Create;
         l.Add('#!/bin/sh');
         l.Add('# $Id: rc-redhat.sh.in,v 1.7 2006/08/20 05:20:51 manu Exp $');
         l.Add('#  init file for milter-greylist');
         l.Add('#');
         l.Add('# chkconfig: - 79 21');
         l.Add('# description: Milter Greylist Daemon');
         l.Add('#');
         l.Add('# processname: /usr/bin/milter-greylist');
         l.Add('# config: /etc/mail/greylist.conf');
         l.Add('# pidfile: /var/run/milter-greylist/milter-greylist.pid');
         l.Add('');
         l.Add('# source function library');
         l.Add('. /etc/init.d/functions');
         l.Add('');
         l.Add('pidfile="/var/run/milter-greylist/milter-greylist.pid"');
         l.Add('socket="/var/run/milter-greylist/milter-greylist.sock"');
         l.Add('user="postfix"');
         l.Add('OPTIONS="-u $user -P $pidfile -p $socket"');
         l.Add('if [ -f /etc/sysconfig/milter-greylist ]');
         l.Add('then');
         l.Add('    . /etc/sysconfig/milter-greylist');
         l.Add('fi');
         l.Add('RETVAL=0');
         l.Add('prog="Milter-Greylist"');
         l.Add('');
         l.Add('start() {');
         l.Add('        echo -n $"Starting $prog: "');
         l.Add('        if [ $UID -ne 0 ]; then');
         l.Add('                RETVAL=1');
         l.Add('                failure');
         l.Add('        else');
         l.Add('		daemon '+MILTER_GREYLIST_BIN_PATH()+' $OPTIONS');
         l.Add('                RETVAL=$?');
         l.Add('                [ $RETVAL -eq 0 ] && touch /var/lock/subsys/milter-greylist');
         l.Add('		[ $RETVAL -eq 0 ] && success || failure');
         l.Add('        fi;');
         l.Add('        echo ');
         l.Add('        return $RETVAL');
         l.Add('}');
         l.Add('');
         l.Add('stop() {');
         l.Add('        echo -n $"Stopping $prog: "');
         l.Add('        if [ $UID -ne 0 ]; then');
         l.Add('                RETVAL=1');
         l.Add('                failure');
         l.Add('        else');
         l.Add('                killproc '+MILTER_GREYLIST_BIN_PATH());
         l.Add('                RETVAL=$?');
         l.Add('                [ $RETVAL -eq 0 ] && rm -f /var/lock/subsys/milter-greylist');
         l.Add('		[ $RETVAL -eq 0 ] && success || failure');
         l.Add('        fi;');
         l.Add('        echo');
         l.Add('        return $RETVAL');
         l.Add('}');
         l.Add('');
         l.Add('');
         l.Add('restart(){');
         l.Add('	stop');
         l.Add('	start');
         l.Add('}');
         l.Add('');
         l.Add('condrestart(){');
         l.Add('    [ -e /var/lock/subsys/milter-greylist ] && restart');
         l.Add('    return 0');
         l.Add('}');
         l.Add('');
         l.Add('case "$1" in');
         l.Add('  start)');
         l.Add('	start');
         l.Add('	;;');
         l.Add('  stop)');
         l.Add('	stop');
         l.Add('	;;');
         l.Add('  restart)');
         l.Add('	restart');
         l.Add('        ;;');
         l.Add('  condrestart)');
         l.Add('	condrestart');
         l.Add('	;;');
         l.Add('  status)');
         l.Add('        status milter-greylist');
         l.Add('	RETVAL=$?');
         l.Add('        ;;');
         l.Add('  *)');
         l.Add('	echo $"Usage: $0 {start|stop|status|restart|condrestart}"');
         l.Add('	RETVAL=1');
         l.Add('esac');
         l.Add('');
         l.Add('exit $RETVAL');
         l.SaveToFile('/etc/init.d/milter-greylist');
         l.Free;
   end;
         FileDatas.Free;
         RegExpr.Free;

end;
 //##############################################################################
procedure tmilter_greylist.MILTER_GREYLIST_START();
var

   socketPath:string;
   user:string;
   pid_path:string;
   pid_dir:string;
   FullSocketPath:string;
begin

    logs.Debuglogs('############### MILTER-GREYLIST ################################');
    

    if not FileExists(MILTER_GREYLIST_BIN_PATH()) then begin
       logs.Debuglogs('Starting......: milter-greylist is not installed');
       exit;
    end;

    if EnablePostfixMultiInstance=1 then begin
       fpsystem(SYS.LOCATE_PHP5_BIN() +' /usr/share/artica-postfix/exec.milter-greylist.php --start');
       exit;
    end;
    logs.Debuglogs('MILTER_GREYLIST_START:: MilterGreyListEnabled_string -> "' + MilterGreyListEnabled_string+'" MilterGreyListEnabled="'+IntToStr(MilterGreyListEnabled) +'" EnableASSP="'+IntToStr(EnableASSP)+'" EnablePostfixMultiInstance="'+IntToStr(EnablePostfixMultiInstance)+'"');
    if MilterGreyListEnabled=0 then begin
       logs.Debuglogs('Starting......: milter-greylist is disabled by artica ('+why_is_disabled+')');
       exit;
    end else begin

    end;
    
    
    

  if SYS.PROCESS_EXIST(MILTER_GREYLIST_PID()) then begin
     logs.DebugLogs('Starting......: milter-greylist already running using PID ' +MILTER_GREYLIST_PID()+ '...');
     exit;
  end;
  
   logs.Syslogs('Starting......: milter-greylist');

   if not sys.COMMANDLINE_PARAMETERS('--noconfig') then fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.milter-greylist.php --norestart');
   pid_path:='/var/run/milter-greylist/milter-greylist.pid';
   user:='postfix';
   socketPath:=CheckSocket();
   FullSocketPath:=socketPath;


    if length(trim(socketPath))=0 then socketPath:='/var/run/milter-greylist/milter-greylist.sock';
    if length(trim(pid_path))=0 then pid_path:='/var/run/milter-greylist/milter-greylist.pid';

   DeleteFile(pid_path);
   if FileExists(socketPath) then DeleteFile(socketPath);
   socketPath:=ExtractFilePath(socketPath);
   if Copy(socketPath,length(socketPath),1)='/' then socketPath:=Copy(socketPath,1,length(socketPath)-1);


             pid_dir:='/var/run/milter-greylist';
             logs.DebugLogs('MILTER_GREYLIST_START:: Creating folder ' +pid_dir);
             try

                ForceDirectories(pid_dir);
                logs.OutputCmd('/bin/chown -R postfix:postfix '+ pid_dir);
             except
                    logs.DebugLogs('MILTER_GREYLIST_START:: Fatal error while creating pid path '+pid_dir);
             end;
             
             forcedirectories('/var/milter-greylist');
             logs.OutputCmd('/bin/chown -R postfix:postfix /var/milter-greylist');


             forceDirectories(socketPath);
             forceDirectories('/var/milter-greylist');

             logs.OutputCmd('/bin/chmod -R 755 ' +socketPath);
             SYS.FILE_CHOWN('postfix','postfix',socketPath);
             forceDirectories('/var/lib/milter-greylist');
             forceDirectories('/var/run/milter-greylist');
             SYS.FILE_CHOWN(user,user,'/var/lib/milter-greylist');
             SYS.FILE_CHOWN(user,user,'/var/run/milter-greylist');

             SYS.FILE_CHOWN(user,user,'/var/milter-greylist');
             fpsystem('/bin/chmod 755 /var/milter-greylist');
             fpsystem('/bin/chmod 755 /var/run/milter-greylist');


             if length(trim(FullSocketPath))=0 then FullSocketPath:='/var/run/milter-greylist/milter-greylist.sock';
             if length(trim(pid_path))=0 then pid_path:='/var/run/milter-greylist/milter-greylist.pid';
             if not FileExists('/var/milter-greylist/greylist.db') then logs.WriteToFile(' ','/var/milter-greylist/greylist.db');
             fpsystem('/bin/chown '+user+':'+user +' /var/milter-greylist/greylist.db');
             fpsystem('/bin/chmod 644 /var/milter-greylist/greylist.db');

             logs.DebugLogs('Starting......: milter-greylist PidPath..: ' +pid_path);
             logs.DebugLogs('Starting......: milter-greylist dump file: ' +'/var/milter-greylist/greylist.db');
             logs.DebugLogs('Starting......: milter-greylist Config...: ' +MILTER_GREYLIST_CONF_PATH());
             logs.DebugLogs('Starting......: milter-greylist user.....: ' +user);
             logs.DebugLogs('Starting......: milter-greylist Socket...: ' +FullSocketPath);
             logs.OutputCmd(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.white-black-central.php');
             START_WITHOUT_INITD();
      

   
   
    if SYS.PROCESS_EXIST(MILTER_GREYLIST_PID()) then begin
       logs.DebugLogs('Starting......: milter-greylist success PID '+ MILTER_GREYLIST_PID());
    end else begin
        logs.syslogs('Starting......: milter-greylist failed');
    end;
   
   
end;
 //##############################################################################
procedure tmilter_greylist.START_WITHOUT_INITD(NotRepairIfFailed:boolean);
var
   daemon_bin:string;
   pid_path:string;
   socketPath:string;
   cmd:string;
   count:integer;
   confpath:string;
begin
 daemon_bin:=MILTER_GREYLIST_BIN_PATH();
 pid_path:=MILTER_GREYLIST_PID_PATH();
 socketPath:=MILTER_GREYLIST_GET_VALUE('socket');
 confpath:=MILTER_GREYLIST_CONF_PATH();
 count:=0;

    if length(trim(socketPath))=0 then socketPath:='/var/run/milter-greylist/milter-greylist.sock';
    if length(trim(pid_path))=0 then pid_path:='/var/run/milter-greylist/milter-greylist.pid';

 FIX_START_ERROR();
 cmd:=daemon_bin + ' -u postfix -P '+ pid_path+' -p ' + socketpath + ' -f ' + confpath+' -d /var/milter-greylist/greylist.db';
 logs.OutputCmd(cmd);
 
 
         while not SYS.PROCESS_EXIST(MILTER_GREYLIST_PID()) do begin
              sleep(150);
              inc(count);
              if count>20 then begin
                 logs.DebugLogs('Starting......: milter-greylist timeout');
                 break;
              end;
        end;


        if not SYS.PROCESS_EXIST(MILTER_GREYLIST_PID()) then begin
           if not NotRepairIfFailed then begin
              logs.DebugLogs('Starting......: milter-greylist failed, try to investigate...');
              logs.DebugLogs('Starting......: '+cmd);
              FIX_START_ERROR();
              START_WITHOUT_INITD(true);
           end;
        end else begin
            if FileExists(socketPath) then fpsystem(SYS.LOCATE_GENERIC_BIN('chmod')+' 777 '+socketPath);
        end;
end;
//##############################################################################
procedure tmilter_greylist.FIX_START_ERROR();
var
    RegExpr:TRegExpr;
    i:integer;
    l:Tstringlist;
    confpath,confpath2,daemon_bin,tmpstr,cmd:string;

begin
 daemon_bin:=MILTER_GREYLIST_BIN_PATH();
 confpath:=MILTER_GREYLIST_CONF_PATH();

 tmpstr:=logs.FILE_TEMP();
 cmd:=daemon_bin + ' -f ' + confpath +' -c >'+ tmpstr+' 2>&1';
 logs.DebugLogs('"'+cmd+'"');
 fpsystem(cmd);
 l:=Tstringlist.Create;
 l.LoadFromFile(tmpstr);
 RegExpr:=tRegExpr.Create;

 //sed '3d' mon_fichier.txt

 for i:=0 to l.Count-1 do begin
   if length(l.Strings[i])=0 then continue;
   RegExpr.Expression:='config error at line ([0-9]+): syntax error';
   if RegExpr.Exec(l.Strings[i]) then begin
      confpath2:=logs.FILE_TEMP();
      logs.DebugLogs('Starting......: "'+l.Strings[i]+'"');
      logs.DebugLogs('Starting......: milter-greylist syntax error line '+RegExpr.Match[1]+' please, remove it');
      //logs.DebugLogs('Starting......: /bin/sed "'+RegExpr.Match[1]+'d" '+ confpath+' >'+confpath2+' 2>&1');
      //fpsystem('/bin/sed "'+RegExpr.Match[1]+'d" '+ confpath+' >'+confpath2+' 2>&1');
      //logs.WriteToFile(logs.ReadFromFile(confpath2),confpath);
      break;
  end;

   logs.DebugLogs('Starting......: Error not analyzed "'+l.Strings[i]+'"');


 end;


  RegExpr.free;
  l.free;

end;

//##############################################################################
procedure tmilter_greylist.FIX_RACL();
var
    RegExpr:TRegExpr;
    i:integer;
    l:Tstringlist;
    conf_path:string;
    Fix:boolean;
begin
Fix:=false;
conf_path:=MILTER_GREYLIST_CONF_PATH();
if not FileExists(conf_path) then begin
   logs.Syslogs('FATAL ERROR, unable to stat greylist.conf');
   exit;
end;


l:=TstringList.Create;
l.LoadFromFile(conf_path);
RegExpr:=TRegExpr.Create;
RegExpr.Expression:='^racl\s+(.+)';
for i:=0 to l.Count-1 do begin
    if RegExpr.Exec(l.Strings[i]) then begin
       logs.Debuglogs('Starting......: milter-greylist fix "racl" line ' + IntToStr(i));
       l.Strings[i]:='acl ' + RegExpr.Match[1];
       fix:=true;
    end;
end;

if fix then begin
   l.SaveToFile(conf_path);
end;

l.free;
RegExpr.free;
end;
//##############################################################################

end.
