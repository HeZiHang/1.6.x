unit cgi_actions;
{$MODE DELPHI}
//{$mode objfpc}{$H+}
{$LONGSTRINGS ON}

interface

uses
Classes, SysUtils,Process,IniFiles,unix,Logs,RegExpr in 'RegExpr.pas',global_conf in 'global_conf.pas',openldap,kav4proxy,squid,
kas3      in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/kas3.pas',
kavmilter in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/kavmilter.pas',
zsystem;

  type
  Tcgi_actions=class


private
       GLOBAL_INI:myConf;
       LOGS:Tlogs;
       PHP_PATH:string;
       SYS:Tsystem;
       openldap:topenldap;
       function ReadFileIntoString(path:string):string;



public
       DirListFiles:TstringList;
       FA:TStringList;
       constructor Create();
       procedure Free;
       function DirectoryCountFiles(FilePath: string):integer;
       function DirFiles(FilePath: string;pattern:string):TstringList;
       function QuarantineDeletePattern(pathToFileList:string):boolean;
       
       //KAspersky anti-spa
       function KAS_TRAP_UPDATES_ERROR(logsPath:string):string;
       function KAS_FORCE_UPDATES_ERROR():string;
       function KAS_TRAP_UPDATES_SUCCESS(logsPath:string):string;
       function KAS_FORCE_UPDATES_NOW():string;
       function KAS_GET_CRON_TASK_UPDATE():string;
       procedure KAS_STATUS();

       function KAV_PERFORM_UPDATE():string;
       function KAV_TRAP_UPDATES_ERROR():string;
       function KAV_TRAP_UPDATES_SUCCESS():string;
       function KAV_TRAP_DAEMON_ERROR():string;
       function KAV_TRAP_DAEMON_EVENTS():TStringList;
       function KAV_GET_CRON_TASK_UPDATE():string;
       function KAV_GET_DAEMON_INFOS():string;
       
       FUNCTION ARTICA_ALL_STATUS():string;
       

       procedure POSTFIX_MAILLOG_HISTORY(filter:string);
       function  AMAVIS_MAILLOG():string;
       function  CYRUS_MAILLOG():string;
       function  SQLGREY_MAILLOG():string;
       function  FRESHCLAM_MAILLOG():string;
       function  MILTERGREYLIST_MAILLOG():string;
       function  OBM_APACHE_MAILLOG():string;
       
       procedure SYSTEM_START_STOP_SERVICES(APPS:string;Start:boolean);
       procedure APP_AUTOREMOVE(application_name:string);
       procedure APP_AUTOINSTALL(application_name:string);
       procedure KAV4PORXY_GENERATE_STATS();
       function DNSMASQ_LOGS():string;
       
       //SHARED FOLDERS
       procedure UMOUNT_FOLDERS(SourceFolder:string);
       procedure UMOUNT_ALL_FOLDERS();
       
       FUNCTION            SQUID_STATUS():string;
       function            SQUID_START_LOGS():string;
       function            DAEMON_STATUS():string;
       

       function            CHANGE_SUPERUSER(admin:string;password:string):boolean;
       procedure           SASLDB2(username:string;password:string);
       PROCEDURE SET_PARAMETERS_ARTICA_FILTER(key:string;value:string);
       

END;

implementation

constructor Tcgi_actions.Create();
begin
LOGS:=TLogs.Create;
GLOBAL_INI:=MyConf.Create();
PHP_PATH:=GLOBAL_INI.get_ARTICA_PHP_PATH();
FA:=TstringList.Create;
openldap:=Topenldap.Create;
SYS:=Tsystem.Create();
end;
PROCEDURE Tcgi_actions.Free();
begin
DirListFiles.Free;
GLOBAL_INI.Free;
FA.free;
Logs.Free;
end;
//#########################################################################################
procedure Tcgi_actions.SASLDB2(username:string;password:string);
var
   RegExpr       :TRegExpr;
   cmd           :string;
   user          :string;
   domain        :string;

begin

   if not FileExists('/usr/sbin/saslpasswd2') then begin
      logs.syslogs('SASLDB2:: unable to stat /usr/sbin/saslpasswd2');
      exit;
   end;

   if not FileExists('/bin/echo') then begin
      logs.syslogs('SASLDB2:: unable to stat /bin/echo');
      exit;
   end;


   user:=username;
   RegExpr:=TRegExpr.CReate();
   RegExpr.Expression:='(.+?)@(.+)';
   if RegExpr.Exec(username) then begin
       user:=RegExpr.Match[1];
       domain:=RegExpr.Match[2];
   end;

   if length(domain)=0 then begin
         cmd:='/bin/echo ' + password+'|/usr/sbin/saslpasswd2 -p -f /etc/sasldb2 '+user;
   end else begin
        cmd:='/bin/echo '+ password + '|/usr/sbin/saslpasswd2 -p -f /etc/sasldb2 -u '+domain+' ' +user;
   end;

   logs.Debuglogs('SASLDB2::'+cmd);
   fpsystem(cmd);
end;
//#########################################################################################



function Tcgi_actions.CHANGE_SUPERUSER(admin:string;password:string):boolean;
var suffix:string;
begin
    result:=true;
    suffix:=GLOBAL_INI.get_LDAP('suffix');
    GLOBAL_INI.set_LDAP('admin',admin);
    GLOBAL_INI.set_LDAP('password',password);
    SYS.THREAD_COMMAND_SET(global_ini.get_ARTICA_PHP_PATH() + '/bin/process1 --force');
    SYS.THREAD_COMMAND_SET(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.change.password.php');
    end;
//#########################################################################################
function Tcgi_actions.QuarantineDeletePattern(pathToFileList:string):boolean;
var
   i:integer;
   ArrayDatas:TStringList;

begin

ArrayDatas:=TStringList.Create;
  LOGS.logs('CGI_ACTIONS:: QuarantineDeletePattern:: LOAD ->"'+pathToFileList+'"');
  if FileExists(pathToFileList) then begin
          ArrayDatas:=TStringList.Create;
          ArrayDatas.LoadFromFile(pathToFileList);
            LOGS.logs('CGI_ACTIONS:: QuarantineDeletePattern:: LOAD ->"'+IntToStr(ArrayDatas.Count) +'" line(s)');
          for i:=0 to ArrayDatas.Count -1 do begin
               LOGS.logs('CGI_ACTIONS:: QuarantineDeletePattern:: file index [' + IntToStr(i) + ']="'+ArrayDatas.Strings[i]+'"');
               if length(ArrayDatas.Strings[i])>0 then begin
                     if FileExists(ArrayDatas.Strings[i]) then begin
                        LOGS.logs('CGI_ACTIONS:: QuarantineDeletePattern ->' + trim(ArrayDatas.Strings[i]));
                        fpsystem('/bin/rm -f ' + trim(ArrayDatas.Strings[i]));
                     end else begin
                       LOGS.logs('CGI_ACTIONS:: QuarantineDeletePattern:: (ERROR)  unable to stat file index [' + IntToStr(i) + ']="'+ArrayDatas.Strings[i]+'"');
                       
                     end;
               end;

          end;
         fpsystem('/bin/rm ' +  pathToFileList);
         exit(true);
      end else begin
          LOGS.logs('CGI_ACTIONS:: QuarantineDeletePattern:: (ERROR) unable to stat ->"'+pathToFileList+'"');
      
      end;

    exit(false);

end;

//#########################################################################################
procedure Tcgi_actions.UMOUNT_FOLDERS(SourceFolder:string);
var
   l:TstringList;
   i:integer;
   cmd:string;
   
begin
   l:=TStringLIst.Create;
   l.AddStrings(GLOBAL_INI.SHARED_CONF_GET_CLIENTS(SourceFolder));
   
   for i:=0 to l.Count-1 do begin
       cmd:='/bin/umount -l ' + l.Strings[i];
       fpsystem(cmd);
       Rmdir(l.Strings[i]);
       LOGS.logs(cmd);
   end;

end;


//#########################################################################################
procedure Tcgi_actions.UMOUNT_ALL_FOLDERS();
var
   l:TstringList;
   i:integer;
   RegExpr       :TRegExpr;
   cmd:string;

begin
   l:=TStringLIst.Create;
   if not FileExists('/etc/mtab') then exit;
   l.LoadFromFile('/etc/mtab');
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='(.+?)\s+(\/.+?)\s+none\s+.+?bind\s+';
   for i:=0 to l.Count-1 do begin
       if RegExpr.Exec(l.Strings[i]) then begin
          cmd:='/bin/umount -l ' + RegExpr.Match[2];
          fpsystem(cmd);
          Rmdir(RegExpr.Match[2]);
          LOGS.logs(cmd);
       end;
   end;

end;
//#########################################################################################
PROCEDURE Tcgi_actions.SET_PARAMETERS_ARTICA_FILTER(key:string;value:string);
Var
   INIF:TIniFile;
   P:Tprocess;
begin
     INIF:=TIniFile.Create('/etc/artica-postfix/artica-filter.conf');
     INIF.WriteString('INFOS',key,value);
     INIF.Free;
     P:=TProcess.Create(nil);
     P.Options:=[poWaitOnExit];
     P.CommandLine:=GLOBAL_INI.get_ARTICA_PHP_PATH() + '/bin/process1';
     P.Execute;
     
end;
//#########################################################################################
procedure Tcgi_actions.KAV4PORXY_GENERATE_STATS();
var
   kav4proxy:Tkav4proxy;
begin
     kav4proxy:=Tkav4proxy.Create(GLOBAL_INI.SYS);
    fpsystem('/bin/kill -USR2 ' + kav4proxy.KAV4PROXY_PID() + '>/dev/null 2>&1');
end;
//#########################################################################################
FUNCTION Tcgi_actions.SQUID_STATUS():string;
begin
   result:=DAEMON_STATUS();
end;
//#########################################################################################
FUNCTION Tcgi_actions.DAEMON_STATUS():string;
  var
     config:string;
     Generate:boolean;
     l:TstringList;
     C:integer;
begin
     Generate:=false;
     config:='/etc/artica-postfix/cache.global.status';
     if not FileExists(config) then Generate:=True;
     
     if Not Generate then begin
        C:=GLOBAL_INI.SYSTEM_FILE_MIN_BETWEEN_NOW(config);
        if C>=2 then begin
            Generate:=true;
        end;
     end;

     l:=TstringList.Create;
     if generate then begin
        logs.logs('CGI_ACTIONS:: DAEMON_STATUS:: generate new status...');
        GLOBAL_INI.DeleteFile(config);
        l.Add(GLOBAL_INI.GLOBAL_STATUS());
        l.SaveToFile(config);

    end;
     logs.logs('CGI_ACTIONS:: DAEMON_STATUS:: Load cached file (' + IntToStr(C) + ' minute(s))');
     l.LoadFromFile(config);
     result:=l.Text;
     l.Free;
     exit;



end;
//#########################################################################################
FUNCTION Tcgi_actions.ARTICA_ALL_STATUS():string;
var
   pidtemp:string;
   i:integer;
   SYS:Tsystem;
begin
     result:='';
     Sys:=Tsystem.Create;
     
     DirFiles('/etc/artica-postfix','artica-send.*');
     

     for i:=0 to DirListFiles.Count-1 do begin
            pidtemp:=SYS.GET_PID_FROM_PATH(DirListFiles.Strings[i]);
            if SYS.PROCESS_EXIST(pidtemp) then begin
                FA.Add('artica-send;1;' + IntToStr(SYS.PROCESS_MEMORY(pidtemp)));
            end;

     end;

     

end;
//#########################################################################################


procedure Tcgi_actions.SYSTEM_START_STOP_SERVICES(APPS:string;Start:boolean);
var
   cmd_Start:string;
   kas3:tkas3;

begin
     if start then cmd_start:=' start' else cmd_start:=' stop';

     logs.Debuglogs('CGI_ACTIONS:: SYSTEM_START_STOP_SERVICES:: ' + APPS + cmd_start);

  if APPS='APP_MYSQL' then begin
     logs.Debuglogs('CGI_ACTIONS:: SYSTEM_START_STOP_SERVICES:: ' + GLOBAL_INI.MYSQL_INIT_PATH + cmd_start);
      fpsystem(GLOBAL_INI.MYSQL_INIT_PATH + cmd_start);
      exit;
  end;
  
  if APPS='APP_KAS3' then begin
      kas3:=Tkas3.Create(GLOBAL_INI.SYS);
      fpsystem(kas3.INITD_PATH() + cmd_start);
      exit;
  end;
  

  if APPS='APP_POSTFIX' then begin
      fpsystem('/etc/init.d/postfix' + cmd_start);
      exit;
  end;
  if APPS='APP_AVESERVER' then begin
      fpsystem('/etc/init.d/aveserver' + cmd_start);
      exit;
  end;
  if APPS='APP_FETCHMAIL' then begin
      fpsystem('/etc/init.d/fetchmail' + cmd_start);
      exit;
  end;
  if APPS='APP_MAILGRAPH' then begin
      fpsystem('/etc/init.d/mailgraph-init' + cmd_start);
      exit;
  end;
  
  if APPS='APP_CRON' then begin
      fpsystem(GLOBAL_INI.CROND_INIT_PATH() + cmd_start);
      exit;
  end;

  logs.Debuglogs('Tcgi_actions.SYSTEM_START_STOP_SERVICES:: could not understand ' + APPS);


end;


function Tcgi_actions.KAS_GET_CRON_TASK_UPDATE():string;
var
   i,t:integer;
   RegExpr:TRegExpr;
   FD,FA:TStringList;

begin
     FD:=TstringList.Create;
     FD.AddStrings(DirFiles('/etc/cron.d','*'));
     RegExpr:=TRegExpr.Create;
     FA:=TstringList.Create;
     LOGS.logs('CGI_ACTIONS:: KAS_GET_CRON_TASK_UPDATE:: scanning ' + IntToStr(FD.Count) +' file(s)');
     RegExpr.Expression:='^(.+/usr/local/ap-mailfilter3/bin/keepup2date)';

     for i:=0 to FD.Count-1 do begin

       FA.LoadFromFile('/etc/cron.d/' + FD.Strings[i]);
       for t:=0 to FA.Count -1 do begin
           if RegExpr.Exec(FA.Strings[t]) then begin
              LOGS.logs('CGI_ACTIONS:: KAS_GET_CRON_TASK_UPDATE:: FOUND ' + RegExpr.Match[1] + ' in file ' + FD.Strings[i]);
              FA.free;
              FD.free;
              result:=RegExpr.Match[1];
              RegExpr.free;
              exit;
           end;
       end;
     end;



end;
//#########################################################################################
function Tcgi_actions.KAV_GET_DAEMON_INFOS():string;
var
   pid,memory,version:string;
   kavmilter:tkavmilter;
begin
kavmilter:=tkavmilter.Create(GLOBAL_INI.SYS);
pid:=kavmilter.KAV_MILTER_PID();
memory:=inttostr(GLOBAL_INI.SYSTEM_PROCESS_MEMORY(pid));
version:=kavmilter.VERSION();
result:=pid+';'+memory + ';' + version + ';';
end;




//#########################################################################################
function Tcgi_actions.KAV_GET_CRON_TASK_UPDATE():string;
var
   i,t:integer;
   RegExpr:TRegExpr;
   FD,FA:TStringList;

begin
     FD:=TstringList.Create;
     FD.AddStrings(DirFiles('/etc/cron.d','*'));
     RegExpr:=TRegExpr.Create;
     FA:=TstringList.Create;
     LOGS.logs('CGI_ACTIONS:: KAV_GET_CRON_TASK_UPDATE:: scanning ' + IntToStr(FD.Count) +' file(s)');
     RegExpr.Expression:='^(.+/opt/kav/5.5/kav4mailservers/bin/keepup2date).+';

     for i:=0 to FD.Count-1 do begin

       FA.LoadFromFile('/etc/cron.d/' + FD.Strings[i]);
       for t:=0 to FA.Count -1 do begin
           if RegExpr.Exec(FA.Strings[t]) then begin
              LOGS.logs('CGI_ACTIONS:: KAV_GET_CRON_TASK_UPDATE:: FOUND ' + RegExpr.Match[1] + ' in file ' + FD.Strings[i]);
              FA.free;
              FD.free;
              result:=RegExpr.Match[1];
              RegExpr.free;
              exit;
           end;
       end;
     end;



end;
//#########################################################################################
function Tcgi_actions.KAS_TRAP_UPDATES_ERROR(logsPath:string):string;
var
   CMD:string;
begin
if length(logsPath)=0 then logsPath:='/usr/local/ap-mailfilter3/log/updater.log';
if not FileExists(logsPath) then exit;

CMD:='/usr/bin/tail -n 500 '+logsPath+'|grep -E ".+(E|F)\]" >/opt/artica/logs/grep.txt';
LOGS.LOGS('CGI_ACTIONS:: KAS_TRAP_UPDATES_ERROR:: -> ' + CMD);
fpsystem(CMD);
FA.LoadFromFile('/opt/artica/logs/grep.txt');
exit(FA.Text);
end;
//#########################################################################################
function Tcgi_actions.KAV_TRAP_UPDATES_ERROR():string;

begin
  result:=KAS_TRAP_UPDATES_ERROR(GLOBAL_INI.AVESERVER_GET_KEEPUP2DATE_LOGS_PATH());
end;
function Tcgi_actions.KAV_TRAP_UPDATES_SUCCESS():string;

begin
  result:=KAS_TRAP_UPDATES_SUCCESS(GLOBAL_INI.AVESERVER_GET_KEEPUP2DATE_LOGS_PATH());
end;
function Tcgi_actions.KAV_PERFORM_UPDATE():string;
begin
result:='';
GLOBAL_INI.THREAD_COMMAND_SET('/opt/kav/5.5/kav4mailservers/bin/keepup2date -q &');
end;
function Tcgi_actions.KAV_TRAP_DAEMON_ERROR():string;
begin
  result:=KAS_TRAP_UPDATES_ERROR(GLOBAL_INI.AVESERVER_GET_LOGS_PATH());
end;
function Tcgi_actions.KAV_TRAP_DAEMON_EVENTS():TStringList;
var
   Path,mycmd:string;
begin
     result:=FA;
     Path:=GLOBAL_INI.AVESERVER_GET_LOGS_PATH();
     mycmd:='/usr/bin/tail '+ path + ' -n 100 >/opt/artica/logs/grep_aveserver';
     LOGS.LOGS('CGI_ACTIONS:: KAV_TRAP_DAEMON_EVENTS:: -> ' + mycmd);
     fpsystem(mycmd);
     FA.LoadFromFile('/opt/artica/logs/grep_aveserver');

end;

//#########################################################################################
function Tcgi_actions.KAS_TRAP_UPDATES_SUCCESS(logsPath:string):string;
         const
            CR = #$0d;
            LF = #$0a;
            CRLF = CR + LF;
var
   i:integer;
   RegExpr:TRegExpr;
   FD:TStringList;
begin
result:='';
if length(logsPath)=0 then logsPath:='/usr/local/ap-mailfilter3/log/updater.log';
logs.logs('CGI_ACTIONS:: KAS_TRAP_UPDATES_SUCCESS:: -> ' + logsPath);
if not FileExists(logsPath) then exit;
 RegExpr:=TRegExpr.Create;
     RegExpr.Expression:='.+completed successfully';
     FD:=TStringList.Create;
     FD.LoadFromFile(logsPath);
For i:=0 to FD.Count-1 do begin
          if RegExpr.Exec(FD.Strings[i]) then begin
                result:=result + FD.Strings[i]+CRLF;
          end;

     end;

     RegExpr.Free;
     FD.free;


end;
//#########################################################################################
function Tcgi_actions.KAS_FORCE_UPDATES_ERROR():string;
begin
result:='';
fpsystem('/bin/rm -rf /usr/local/ap-mailfilter3/cfdata/bases/*');
fpsystem('/bin/rm -rf /usr/local/ap-mailfilter3/cfdata/bases.backup');
GLOBAL_INI.THREAD_COMMAND_SET('/usr/local/ap-mailfilter3/bin/sfupdates');
end;
//#########################################################################################
function Tcgi_actions.KAS_FORCE_UPDATES_NOW():string;
begin
result:='';
GLOBAL_INI.THREAD_COMMAND_SET('/usr/local/ap-mailfilter3/bin/sfupdates');

end;
//#########################################################################################

function Tcgi_actions.ReadFileIntoString(path:string):string;
         const
            CR = #$0d;
            LF = #$0a;
            CRLF = CR + LF;
var
   Afile:text;
   datas:string;
   datas_file:string;
begin
     datas_file:='';
      if not FileExists(path) then begin
        writeln('Error:thProcThread.ReadFileIntoString -> file not found (' + path + ')');
        exit;

      end;
      TRY
     assign(Afile,path);
     reset(Afile);
     while not EOF(Afile) do
           begin
           readln(Afile,datas);
           datas_file:=datas_file + datas +CRLF;
           end;

close(Afile);
             EXCEPT
              writeln('Error:thProcThread.ReadFileIntoString -> unable to read (' + path + ')');
           end;
result:=datas_file;


end;
//#########################################################################################
procedure Tcgi_actions.KAS_STATUS();
var
   mstr:string;
   RegExpr:TRegExpr;
   kas3:tkas3;
begin
  FA:=TStringList.Create;
  kas3:=Tkas3.Create(GLOBAL_INI.SYS);
  mstr:=kas3.KAS_STATUS();
  RegExpr:=TRegExpr.Create;
  RegExpr.Expression:='([0-9\-]+)-([0-9\-]+);([0-9\-]+)-([0-9\-]+);([0-9\-]+)-([0-9\-]+);([0-9\-]+)-([0-9\-]+)';
  if RegExpr.Exec(mstr) then begin
      FA.Add('ap-process-server;'+RegExpr.Match[1]+ ';' +RegExpr.Match[2]+';'+IntToStr(GLOBAL_INI.SYSTEM_PROCESS_MEMORY(RegExpr.Match[1])));
      FA.Add('ap-spfd;'+RegExpr.Match[3]+ ';' +RegExpr.Match[4]+';'+IntToStr(GLOBAL_INI.SYSTEM_PROCESS_MEMORY(RegExpr.Match[3])));
      FA.Add('kas-license;'+RegExpr.Match[5]+ ';' +RegExpr.Match[6]+';'+IntToStr(GLOBAL_INI.SYSTEM_PROCESS_MEMORY(RegExpr.Match[5])));
      FA.Add('kas-thttpd;'+RegExpr.Match[7]+ ';' +RegExpr.Match[8]+';'+IntToStr(GLOBAL_INI.SYSTEM_PROCESS_MEMORY(RegExpr.Match[7])));
  end;
end;
//#########################################################################################
procedure Tcgi_actions.APP_AUTOREMOVE(application_name:string);
begin
FA:=TStringList.Create;
fpsystem(GLOBAL_INI.get_ARTICA_PHP_PATH() + '/bin/artica-install -autoremove ' + application_name + ' auto');
if FileExists('/var/log/artica-postfix/artica-install-' + application_name + '.log') then FA.LoadFromFile('/var/log/artica-postfix/artica-install-' + application_name + '.log');
end;
//#########################################################################################
procedure Tcgi_actions.APP_AUTOINSTALL(application_name:string);
begin
FA:=TStringList.Create;
LOGS.logs(GLOBAL_INI.get_ARTICA_PHP_PATH() + '/bin/artica-install -autoinstall ' + application_name + ' auto');
fpsystem(GLOBAL_INI.get_ARTICA_PHP_PATH() + '/bin/artica-install -autoinstall ' + application_name + ' auto');
if FileExists('/var/log/artica-postfix/artica-install-' + application_name + '.log') then  FA.LoadFromFile('/var/log/artica-postfix/artica-install-' + application_name + '.log');
end;
//#########################################################################################

function Tcgi_actions.SQLGREY_MAILLOG():string;
var maillog_path,cmdline:string;
begin
    result:='';
    maillog_path:=GLOBAL_INI.get_LINUX_MAILLOG_PATH();
    FA:=TstringList.Create;
    LOGS.logs('SQLGREY_MAILLOG: maillog_path=' + maillog_path);
    if not FileExists(maillog_path) then begin
       FA.Add('unable to stat ' + maillog_path);
       exit;
    end;

    cmdline:='/usr/bin/tail -n 500 ' + maillog_path + '|grep sqlgrey >/opt/artica/logs/sqlgrey.logs.tmp';
    LOGS.logs('SQLGREY_MAILLOG:'+cmdline);
    fpsystem(cmdline);
    if FileExists('/opt/artica/logs/sqlgrey.logs.tmp') then begin
       FA.LoadFromFile('/opt/artica/logs/sqlgrey.logs.tmp');
    end;
    LOGS.logs('SQLGREY_MAILLOG: ' +IntToStr(FA.Count) + ' lines');


end;
//#########################################################################################

function Tcgi_actions.AMAVIS_MAILLOG():string;
var cmdline:string;
begin
    result:='';
    FA:=TstringList.Create;
    cmdline:='/usr/bin/tail -n 500 /opt/artica/logs/amavis/amavis.log >/opt/artica/logs/amavis.logs.tmp';
    LOGS.logs('AMAVIS_MAILLOG:'+cmdline);
    fpsystem(cmdline);
    if FileExists('/opt/artica/logs/amavis.logs.tmp') then begin
       FA.LoadFromFile('/opt/artica/logs/amavis.logs.tmp');
    end;
    LOGS.logs('AMAVIS_MAILLOG: ' +IntToStr(FA.Count) + ' lines');


end;
//#########################################################################################
function Tcgi_actions.FRESHCLAM_MAILLOG():string;
var cmdline:string;
begin
    result:='';
    FA:=TstringList.Create;
    cmdline:='/bin/cat ' + GLOBAL_INI.SYSTEM_GET_SYSLOG_PATH() + '|grep freshclam|/usr/bin/tail -n 200 >/opt/artica/logs/freshclam.logs.tmp';
    LOGS.logs('FRESHCLAM_MAILLOG:'+cmdline);
    fpsystem(cmdline);
    if FileExists('/opt/artica/logs/freshclam.logs.tmp') then begin
       FA.LoadFromFile('/opt/artica/logs/freshclam.logs.tmp');
    end;
    LOGS.logs('AMAVIS_MAILLOG: ' +IntToStr(FA.Count) + ' lines');


end;
//#########################################################################################
function Tcgi_actions.MILTERGREYLIST_MAILLOG():string;
var cmdline:string;
begin
    result:='';
    FA:=TstringList.Create;
    cmdline:='/bin/cat ' + GLOBAL_INI.SYSTEM_GET_SYSLOG_PATH() + '|grep  milter-greylist|/usr/bin/tail -n 200 >/opt/artica/logs/miltergrey.logs.tmp';
    LOGS.logs('FRESHCLAM_MAILLOG:'+cmdline);
    fpsystem(cmdline);
    if FileExists('/opt/artica/logs/miltergrey.logs.tmp') then begin
       FA.LoadFromFile('/opt/artica/logs/miltergrey.logs.tmp');
    end;
    LOGS.logs('MILTERGREYLIST_MAILLOG: ' +IntToStr(FA.Count) + ' lines');


end;
//#########################################################################################
function Tcgi_actions.CYRUS_MAILLOG():string;
var cmdline:string;
begin
    result:='';
    FA:=TstringList.Create;
    cmdline:='/bin/cat ' + GLOBAL_INI.SYSTEM_GET_SYSLOG_PATH() + '|grep  cyrus|/usr/bin/tail -n 200 >/opt/artica/logs/cyrus.logs.tmp';
    LOGS.logs('CYRUS_MAILLOG:'+cmdline);
    fpsystem(cmdline);
    if FileExists('/opt/artica/logs/cyrus.logs.tmp') then begin
       FA.LoadFromFile('/opt/artica/logs/cyrus.logs.tmp');
    end;
    LOGS.logs('CYRUS_MAILLOG: ' +IntToStr(FA.Count) + ' lines');


end;
//#########################################################################################
function Tcgi_actions.OBM_APACHE_MAILLOG():string;
var cmdline:string;
begin
    result:='';
    FA:=TstringList.Create;
    cmdline:='/usr/bin/tail -n 500 /var/log/lighttpd/obm-error.log >/opt/artica/logs/apache-obm.logs.tmp';
    LOGS.logs('CYRUS_MAILLOG:'+cmdline);
    fpsystem(cmdline);
    if FileExists('/opt/artica/logs/apache-obm.logs.tmp') then begin
       FA.LoadFromFile('/opt/artica/logs/apache-obm.logs.tmp');
       GLOBAL_INI.DeleteFile('/opt/artica/logs/apache-obm.logs.tmp');
    end;
    LOGS.logs('OBM_APACHE_MAILLOG: ' +IntToStr(FA.Count) + ' lines');


end;
//#########################################################################################
function Tcgi_actions.DNSMASQ_LOGS():string;
var maillog_path,cmdline:string;
begin
    result:='';
    maillog_path:='/var/log/dnsmasq/dnsmasq.log';
    if not FileExists(maillog_path) then exit;
    FA:=TstringList.Create;
    cmdline:='/usr/bin/tail -n 100 ' + maillog_path;
    FA.LoadFromStream(GLOBAL_INI.ExecStream(cmdline,false));
end;
//#########################################################################################
procedure Tcgi_actions.POSTFIX_MAILLOG_HISTORY(filter:string);
      var
      maillog_path,cmdline:string;
begin
    maillog_path:=GLOBAL_INI.get_LINUX_MAILLOG_PATH();
    if not FileExists(maillog_path) then exit;
    FA:=TstringList.Create;
    cmdline:='/bin/cat ' + maillog_path + '|/bin/grep -E "' + filter + '" >/opt/artica/logs/POSTFIX_MAILLOG_HISTORY.tmp';
    LOGS.logs('POSTFIX_MAILLOG_HISTORY: ' + cmdline);
    fpsystem(cmdline);
    FA.LoadFromFile('/opt/artica/logs/POSTFIX_MAILLOG_HISTORY.tmp');
    LOGS.logs('POSTFIX_MAILLOG_HISTORY: ' + IntToStr(FA.Count) + ' lines');
end;
//#########################################################################################

function Tcgi_actions.DirectoryCountFiles(FilePath: string):integer;
Var Info : TSearchRec;
    Count : Longint;

Begin
  Count:=0;
  If FindFirst (FilePath+'/*',faAnyFile and faDirectory,Info)=0 then
    begin
    Repeat
      if Info.Name<>'..' then begin
         if Info.Name <>'.' then begin
              if Info.Attr=48 then count:=count +  DirectoryCountFiles(FilePath + '/' +Info.Name);
              if Info.Attr=16 then count:=count +  DirectoryCountFiles(FilePath + '/' +Info.Name);
              if Info.Attr=32 then Inc(Count);
              //Writeln (Info.Name:40,Info.Size:15);
         end;
      end;

    Until FindNext(info)<>0;
    end;
  FindClose(Info);
  exit(count);
end;
//#########################################################################################
function Tcgi_actions.DirFiles(FilePath: string;pattern:string):TstringList;
Var Info : TSearchRec;

Begin

   DirListFiles:=TstringList.Create();
  If FindFirst (FilePath+'/'+ pattern,faAnyFile,Info)=0 then begin
    Repeat
      if Info.Name<>'..' then begin
         if Info.Name <>'.' then begin
           DirListFiles.Add(Info.Name);

         end;
      end;

    Until FindNext(info)<>0;
    end;
  FindClose(Info);
  DirFiles:=DirListFiles;
  exit();
end;
//#########################################################################################
function Tcgi_actions.SQUID_START_LOGS():string;
var
   F:TstringList;
   T:TstringList;
   RegExpr:TRegExpr;
   i:Integer;
   LineTo:integer;
   squid:Tsquid;
   
begin
  squid:=tsquid.CReate;
  fpsystem('/usr/bin/tail -n 500 '+squid.SQUID_GET_CONFIG('cache_log') +' >/opt/artica/logs/tail.cache.log');
  if not FileExists('/opt/artica/logs/tail.cache.log') then exit;
  F:=TstringList.Create;
  F.LoadFromFile('/opt/artica/logs/tail.cache.log');
  LOGS.DeleteFile('/opt/artica/logs/tail.cache.log');
  RegExpr:=TRegExpr.Create;
  RegExpr.Expression:='\s+Starting Squid Cache version 3.+';
  For i:=0 to F.Count-1 do begin
     if RegExpr.Exec(f.Strings[i]) then LineTo:=i;
  end;
  T:=TstringList.Create;
For i:=LineTo to F.Count-1 do begin
    T.Add(f.Strings[i]);
  end;

  result:=T.Text;
  T.free;
  f.free;
  RegExpr.Free;
  

end;























end.
