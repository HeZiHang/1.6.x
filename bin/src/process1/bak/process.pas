unit artica_process;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,variants, Process,Linux,IniFiles,oldlinux,strutils,logs,dateutils,
  RegExpr,
  global_conf in 'global_conf.pas',common,process_infos;
type
  Tprocess1=class
  private
    LOGS:Tlogs;
    GLOBAL_INI:myconf;
    COMMON:Tcommon;
    processINFOS:Tprocessinfos;
    function ExecPipe(commandline:string):string;
    procedure CheckFoldersPermissions();
    procedure killfile(path:string);
    PROCEDURE web_settings();
    procedure MailGraph();
    debug:boolean;
    PHP_PATH:string;
    procedure Execute;
    D:boolean;


  public

    constructor Create;
    end;

implementation

//##############################################################################
procedure Tprocess1.Execute;
var count:integer;
CacheQueue:integer;
IpInterface:integer;
QueueNumber:integer;
artica_send_pid:string;
begin

  logs.logsThread('process1','artica-daemon:: ThProcThread[1] Execute...');
  logs.logsThread('process1','artica-daemon:: ThProcThread[1] PID ' +IntTOStr(getpid));
  GLOBAL_INI.SET_ARTICA_LOCAL_SECOND_PORT(0);
  COMMON:=Tcommon.Create;
  processINFOS:=Tprocessinfos.Create;
  CheckFoldersPermissions();
  logs.DeleteLogs();

        web_settings();



  logs.logsThread('process1','artica-daemon:: ThProcThread[1] FINISH...');

end;

//##############################################################################
constructor Tprocess1.Create;
begin
   D:=false;
   forcedirectories('/etc/artica-postfix');
   GLOBAL_INI:=myConf.Create();
   D:=GLOBAL_INI.COMMANDLINE_PARAMETERS('-V');
   if not D then if ParamStr(1)='-V' then D:=true;
   LOGS:=Tlogs.Create;
   Debug:=GLOBAL_INI.get_DEBUG_DAEMON();
   LOGS.logsStart('artica-daemon:: ThProcThread[1]:: Create');
   if D then writeln('process 1 execute....');
   Execute;
end;

//##############################################################################
procedure Tprocess1.CheckFoldersPermissions();
var
artica_path:string;
begin
artica_path:=GLOBAL_INI.get_ARTICA_PHP_PATH();

  logs.logsThread('process1','CheckFoldersPermissions():: CheckFoldersPermissions...');
  forcedirectories(artica_path + '/ressources/userdb');
  forcedirectories(artica_path + '/ressources/conf');
  forcedirectories(artica_path + '/ressources/logs');

  if debug then LOGS.logs('thprocThread.CheckFoldersPermissions() -> Set permissions on ' + artica_path + '/ressources/userdb');
  if debug then LOGS.logs('thprocThread.CheckFoldersPermissions() -> Set permissions on ' + artica_path + '/ressources/conf');
  if debug then LOGS.logs('thprocThread.CheckFoldersPermissions() -> Set permissions on ' + artica_path + '/ressources/logs');
  if debug then LOGS.logs('thprocThread.CheckFoldersPermissions() -> Set permissions on ' + artica_path + '/ressources/databases');
  Shell('/bin/chmod 0777 ' + artica_path + '/ressources/databases');
  Shell('/bin/chmod 0777 ' + artica_path + '/ressources/userdb');
  Shell('/bin/chmod 0777 ' + artica_path + '/ressources/conf');
  Shell('/bin/chmod 0777 ' + artica_path + '/ressources/logs');
  Shell('/bin/chown ' + GLOBAL_INI.get_www_userGroup() +' ' + artica_path + '/ressources/userdb');
  Shell('/bin/chown ' + GLOBAL_INI.get_www_userGroup() +' ' + artica_path + '/ressources/conf');
  Shell('/bin/chown ' + GLOBAL_INI.get_www_userGroup() +' ' + artica_path + '/ressources/logs');
  Shell('/bin/chown ' + GLOBAL_INI.get_www_userGroup() +' ' + artica_path + '/ressources/databases');
  Shell('/bin/chown -R artica:root /etc/artica-postfix');
  GLOBAL_INI.ARTICA_FILTER_CHECK_PERMISSIONS();

  if D then writeln('CheckFoldersPermissions...-> END');

end;
//##############################################################################

PROCEDURE Tprocess1.web_settings();
var
   myFile,lock : TextFile;
   usemysql,dummy,dummy1,dummy2,dummy3:string;
   bool:boolean;
   NewIni:TConfFiles;
   application_postgrey:string;
   courier_authdaemon,courier_imap,courier_imap_ssl,courier_pop,courier_pop_ssl,kav_mail,awstats_path:string;
   authmodulelist,authdaemonrc_path,enable_postfix_mailboxes,ressourcespath,aveserver,cyr_deliver_path,mysql_init_path:string;
   list:TstringList;
   fetchmail_path:string;
   cyrus_imapd_path:string;
begin
       logs.logsThread('process1','web_settings:: writing status for artica-postfix php service');

      php_path:=GLOBAL_INI.get_ARTICA_PHP_PATH();
      awstats_path:=GLOBAL_INI.AWSTATS_PATH();


      shell(php_path + '/bin/artica-install -postfix alllogs silent');



      if not FileExists(php_path) then begin
          LOGS.logs('thProcThread.web_settings()::ERROR -> Unable to locate ressourcespath [' + php_path + ']');
          exit;
      end;


      if GLOBAL_INI.get_MANAGE_MAILBOXES()='yes' then enable_postfix_mailboxes:='True';
      if GLOBAL_INI.get_MANAGE_MAILBOXES()='no' then enable_postfix_mailboxes:='False';

      if not DirectoryExists(GLOBAL_INI.PROCMAIL_QUARANTINE_PATH()) then begin
         forcedirectories(GLOBAL_INI.PROCMAIL_QUARANTINE_PATH());
         Shell('/bin/chown ' + GLOBAL_INI.PROCMAIL_USER() +' ' +  GLOBAL_INI.PROCMAIL_QUARANTINE_PATH());
      end;



    application_postgrey:='False';
    courier_authdaemon:='False';
    courier_imap:='False';
    courier_imap_ssl:='False';
    courier_pop:='False';
    courier_pop_ssl:='False';
    kav_mail:='False';


    if FileExists('/etc/init.d/postgrey') then application_postgrey:='True';
    if FileExists('/etc/init.d/courier-authdaemon') then courier_authdaemon:='True';
    if FileExists('/etc/init.d/courier-imap') then courier_imap:='True';
    if FileExists('/etc/init.d/courier-imap-ssl') then courier_imap_ssl:='True';
    if FileExists('/etc/init.d/courier-pop') then begin
            if debug then LOGS.logs('thProcThread.web_settings()-> /etc/init.d/courier-pop =courier_pop=True');
             courier_pop:='True';
    end;

    if FileExists('/etc/init.d/courier-pop-ssl') then begin
       if debug then LOGS.logs('thProcThread.web_settings()-> courier-pop-ssl=True');
       courier_pop_ssl:='True';
    end;


    if FileExists('/opt/kav/5.5/kav4mailservers/bin/aveserver') then kav_mail:='True';
    if FileExists('/etc/init.d/aveserver') then kav_mail:='True';



    if debug then  LOGS.logs('thProcThread.web_settings() ->set Locked file ' + php_path + '/ressources/settings.loc');
    AssignFile(lock, php_path + '/ressources/settings.loc');
    ReWrite(lock);
    writeln(lock,'->LOCKED');
    CloseFile(lock);

    list:=TstringList.Create;
    list.Add('<?php');
    list.Add('$_GLOBAL["postfix_database_method"]=' + GLOBAL_INI.get_POSTFIX_DATABASE() + ';');
    list.Add('$_GLOBAL["postgrey"]=' +application_postgrey + ';');
    list.Add('$_GLOBAL["courier_authdaemon"]=' +courier_authdaemon + ';');
    list.Add('$_GLOBAL["courier_imap"]=' +courier_imap + ';');
    list.Add('$_GLOBAL["courier_imap_ssl"]=' +courier_imap_ssl + ';');
    list.Add('$_GLOBAL["courier_pop"]=' +courier_pop + ';');
    list.Add('$_GLOBAL["courier_pop_ssl"]=' +courier_pop_ssl + ';');
    list.Add('$_GLOBAL["kav_mail"]=' +kav_mail + ';');
    list.Add('$_GLOBAL["authmodulelist"]="' +  authmodulelist + '";');
    list.Add('$_GLOBAL["UseMailBoxes"]=' +  enable_postfix_mailboxes + ';');
    list.Add('$_GLOBAL["kav_mail"]=' +  kav_mail + ';');
    list.Add('$_GLOBAL["kav_ver"]="' +  GLOBAL_INI.get_INFOS('kaspersky_version') + '";');
    list.Add('$_GLOBAL["aveserver_pattern_date"]="' +  GLOBAL_INI.AVESERVER_PATTERN_DATE() + '";');
    list.Add('$_GLOBAL["ARTICA_ROOT_PATH"]="' +  GLOBAL_INI.get_ARTICA_PHP_PATH() + '";');


    list.Add('$_GLOBAL["mailboxes_server"]="' +  GLOBAL_INI.get_MANAGE_MAILBOX_SERVER() + '";');
    list.Add('$_GLOBAL["ldap_admin"]="' +  GLOBAL_INI.get_LDAP('admin') + '";');
    list.Add('$_GLOBAL["ldap_password"]="' +  GLOBAL_INI.get_LDAP('password') + '";');
    list.Add('$_GLOBAL["ldap_root_database"]="' +  GLOBAL_INI.get_LDAP('suffix') + '";');
    list.Add('$_GLOBAL["ldap_host"]="' +  GLOBAL_INI.get_LDAP('server') + '";');
    list.Add('$_GLOBAL["cyrus_ldap_admin"]="' +  GLOBAL_INI.get_LDAP('cyrus_admin') + '";');
    list.Add('$_GLOBAL["cyrus_ldap_admin_password"]="' +  GLOBAL_INI.get_LDAP('cyrus_password') + '";');
    list.Add('$_GLOBAL["cyrus_admin_password"]="' +  GLOBAL_INI.Cyrus_get_adminpassword() + '";');
    list.Add('$_GLOBAL["cyrus_admin_username"]="' +  GLOBAL_INI.Cyrus_get_admin_name() + '";');

    list.Add('$_GLOBAL["mysql_password"]="' +  GLOBAL_INI.MYSQL_PASSWORD() + '";');
    list.Add('$_GLOBAL["mysql_admin"]="' +  GLOBAL_INI.MYSQL_ROOT() + '";');
    list.Add('$_GLOBAL["mysql_server"]="' +  GLOBAL_INI.MYSQL_SERVER() + '";');

    if GLOBAL_INI.MYSQL_ENABLED then  list.Add('$_GLOBAL["mysql_enabled"]=True;') else list.Add('$_GLOBAL["mysql_enabled"]=false;');


    list.Add('$_GLOBAL["ARTICA_DAEMON_PORT"]=' +  IntToStr(GLOBAL_INI.get_ARTICA_LOCAL_PORT()) + ';');
    list.Add('$_GLOBAL["ARTICA_SECOND_PORT"]=' +  IntToStr(GLOBAL_INI.get_ARTICA_LOCAL_SECOND_PORT()) + ';');
    list.Add('$_GLOBAL["ARTICA_DAEMON_IP"]="' +  GLOBAL_INI.get_ARTICA_LISTEN_IP() + '";');
    list.Add('$_GLOBAL["fetchmail_daemon_pool"]="' +  GLOBAL_INI.FETCHMAIL_DAEMON_POOL() + '";');
    list.Add('$_GLOBAL["fetchmail_daemon_postmaster"]="' +  GLOBAL_INI.FETCHMAIL_DAEMON_POSTMASTER() + '";');
    list.Add('$_GLOBAL["POSTFIX_QUEUE"]=array("active"=>' + GLOBAL_INI.POSTFIX_QUEUE_FILE_NUMBER('active') + ',"deferred"=>' + GLOBAL_INI.POSTFIX_QUEUE_FILE_NUMBER('deferred') +',"incoming"=>' + GLOBAL_INI.POSTFIX_QUEUE_FILE_NUMBER('incoming') + ',"bounce"=>'+ GLOBAL_INI.POSTFIX_QUEUE_FILE_NUMBER('bounce')+',"artica-filter"=>' + intToStr(GLOBAL_INI.ARTICA_SEND_QUEUE_NUMBER()) +');');
    list.Add('$_GLOBAL["ChangeAutoInterface"]="' + GLOBAL_INI.get_INFOS('ChangeAutoInterface') + '";');
    list.Add('$_GLOBAL["POSTFIX_STATUS"]="' + GLOBAL_INI.POSTFIX_STATUS()+ '";');
    list.Add('$_GLOBAL["KAS_STATUS"]="' + GLOBAL_INI.KAS_STATUS() + '";');
    list.Add('$_GLOBAL["CYRUS_STATUS"]="' + GLOBAL_INI.CYRUS_STATUS() + '";');
    list.Add('$_GLOBAL["KAV_STATUS"]="' + GLOBAL_INI.AVESERVER_STATUS() + '";');
    list.Add('$_GLOBAL["FETCHMAIL_STATUS"]="' + GLOBAL_INI.FETCHMAIL_STATUS() + '";');
    list.Add('$_GLOBAL["ARTICA_FILTER_QUEUE_PATH"]="' + GLOBAL_INI.ARTICA_FILTER_QUEUEPATH() + '";');
    list.Add('$_GLOBAL["ARTICA_VERSION"]="' + GLOBAL_INI.ARTICA_VERSION() + '";');

     if D then writeln('ARTICA_FILTER_MAXSUBQUEUE=',GLOBAL_INI.ARTICA_SEND_MAX_SUBQUEUE_NUMBER());

     list.Add('$_GLOBAL["ARTICA_FILTER_MAXSUBQUEUE"]="' + IntToStr(GLOBAL_INI.ARTICA_SEND_MAX_SUBQUEUE_NUMBER()) + '";');
     if GLOBAL_INI.SYSTEM_PROCESS_EXIST(GLOBAL_INI.ARTICA_FILTER_GET_PID()) then list.Add('$_GLOBAL["ARTICA_FILTER_STATUS"]=True;') else list.Add('$_GLOBAL["ARTICA_FILTER_STATUS"]=false;');
     if GLOBAL_INI.SYSTEM_PROCESS_EXIST(GLOBAL_INI.ARTICA_POLICY_GET_PID()) then list.Add('$_GLOBAL["ARTICA_POLICY_STATUS"]=True;')  else list.Add('$_GLOBAL["ARTICA_POLICY_STATUS"]=false;');
     if GLOBAL_INI.SYSTEM_PROCESS_EXIST(GLOBAL_INI.EMAILRELAY_PID()) then list.Add('$_GLOBAL["EMAILRELAY_STATUS"]=True;')  else list.Add('$_GLOBAL["EMAILRELAY_STATUS"]=false;');

     if FIleExists('/usr/local/sbin/emailrelay') then begin

        list.Add('$_GLOBAL["EMAILRELAY_INSTALLED"]=True;')

     end else begin
         list.Add('$_GLOBAL["EMAILRELAY_INSTALLED"]=False;');
     end;

       if GLOBAL_INI.LDAP_USE_SUSE_SCHEMA()=True then begin
          list.Add('$_GLOBAL["USE_SUSE_SCHEMA"]=True;');
       end
       else begin
          list.Add('$_GLOBAL["USE_SUSE_SCHEMA"]=False;');
       end;


    if GLOBAL_INI.ARTICA_AutomaticConfig()=True then begin
       list.Add('$_GLOBAL["AutomaticConfig"]=True;');
       end
       else begin
           list.Add('$_GLOBAL["AutomaticConfig"]=False;');
    end;



    //---------------------- DNSASQ STATUS --------------------------------------------------
    if fileExists(GLOBAL_INI.DNSMASQ_BIN_PATH()) then begin
              list.Add('$_GLOBAL["dnsmasq_installed"]=True;');
              if not FileExists('/var/log/syslog') then begin
                 LOGS.logs('thProcThread.web_settings() -> unable to stat /var/log/syslog');
              end else begin
                  shell('/bin/cat /var/log/syslog|/bin/grep dnsmasq >' + GLOBAL_INI.get_ARTICA_PHP_PATH() + '/ressources/logs/dnsmasq.log');
              end;
    end else begin
              list.Add('$_GLOBAL["dnsmasq_installed"]=false;');
    end;
   //--------------------------------------------------------------------------------------------



   if GLOBAL_INI.PROCMAIL_INSTALLED()=True then begin
       list.Add('$_GLOBAL["procmail_installed"]=True;');
       end
       else begin
       list.Add('$_GLOBAL["procmail_installed"]=False;');
    end;

    if debug then LOGS.logs('thProcThread.web_settings() ->analyze applications status in memory');
     if processINFOS.ISprocessExist('master')=True then begin
           list.Add('$_GLOBAL["postfix_on_memorie"]=True;');
     end
           else begin
                list.Add('$_GLOBAL["postfix_on_memorie"]=False;');
                if debug then LOGS.logs('thProcThread.web_settings() -> postfix status false');
     end;

     if kav_mail='True' then begin
        if processINFOS.ISprocessExist('aveserver')=True then begin
           list.Add('$_GLOBAL["aveserver_on_memorie"]=True;');
           end
              else begin
                list.Add('$_GLOBAL["aveserver_on_memorie"]=False;');
                if debug then LOGS.logs('thProcThread.web_settings() -> aveserver status false');
        end;
     end;

     if processINFOS.ISprocessExist('mailgraph')=True then begin
        list.Add('$_GLOBAL["mailgraph_on_memorie"]=True;');
     end
           else begin
                list.Add('$_GLOBAL["mailgraph_on_memorie"]=False;');
     end;

     if fileExists('/usr/local/ap-mailfilter3/etc/filter.conf') then begin
              list.Add('$_GLOBAL["kas_installed"]=True;');
              end else begin
              list.Add('$_GLOBAL["kas_installed"]=false;');
     end;

     if fileExists('/etc/init.d/aveserver') then begin
              list.Add('$_GLOBAL["aveserver_installed"]=True;');
              end else begin
              list.Add('$_GLOBAL["aveserver_installed"]=false;');
     end;


     fetchmail_path:=GLOBAL_INI.FETCHMAIL_BIN_PATH();
     if length(fetchmail_path)>0 then begin
          list.Add('$_GLOBAL["fetchmail_installed"]=True;');
          end else begin
          list.Add('$_GLOBAL["fetchmail_installed"]=false;');
     end;

     cyrus_imapd_path:=GLOBAL_INI.CYRUS_GET_INITD_PATH();
     if length(cyrus_imapd_path)>0 then begin
          if fileExists(cyrus_imapd_path) then begin
             list.Add('$_GLOBAL["cyrus_imapd_installed"]=True;');
             list.Add('$_GLOBAL["cyrus_initd_path"]="' + cyrus_imapd_path + '";');
             end else begin
               list.Add('$_GLOBAL["cyrus_imapd_installed"]=false;');
             end;
     end else begin
         list.Add('$_GLOBAL["cyrus_imapd_installed"]=false;');
     end;


     if fileexists('/usr/bin/rrdtool') then begin
             list.Add('$_GLOBAL["rrdtool_installed"]=True;');
             end else begin
               list.Add('$_GLOBAL["rrdtool_installed"]=false;');
    end;

    mysql_init_path:=GLOBAL_INI.MYSQL_INIT_PATH;
     if fileexists(mysql_init_path) then begin
             list.Add('$_GLOBAL["mysql_installed"]=True;');
             end else begin
             list.Add('$_GLOBAL["mysql_installed"]=false;');
    end;


    if FileExists('/etc/init.d/mailgraph-init') then begin
     list.Add('$_GLOBAL["mailgraph_installed"]=True;');
             end else begin
             list.Add('$_GLOBAL["mailgraph_installed"]=false;');
    end;

    if FileExists('/etc/cron.d/artica_queuegraph') then begin
     list.Add('$_GLOBAL["queuegraph_installed"]=True;');
             end else begin
             list.Add('$_GLOBAL["queuegraph_installed"]=false;');
    end;

    if FileExists('/etc/cron.d/artica_yorel') then begin
     list.Add('$_GLOBAL["yorel_installed"]=True;');
             end else begin
             list.Add('$_GLOBAL["yorel_installed"]=false;');
    end;

    if length(awstats_path)=0 then begin
         list.Add('$_GLOBAL["awstats_installed"]=false;');
    end else begin
        if fileExists(awstats_path) then  begin list.Add('$_GLOBAL["awstats_installed"]=True;') end else begin list.Add('$_GLOBAL["awstats_installed"]=False;'); end;
    end;



    cyr_deliver_path:=GLOBAL_INI.CYRUS_DELIVER_BIN_PATH();

    list.Add('$_GLOBAL["cyr_deliver_path"]="' + cyr_deliver_path + '";');
    list.Add('$_GLOBAL["procmail_quarantine_path"]="' + GLOBAL_INI.PROCMAIL_QUARANTINE_PATH() + '";');
    list.Add('$_GLOBAL["mailgraph_virus_database"]="' + GLOBAL_INI.get_MAILGRAPH_RRD_VIRUS() + '";');
    list.Add('$_GLOBAL["mailgraph_postfix_database"]="' + GLOBAL_INI.get_MAILGRAPH_RRD() + '";');


    if DirectoryExists('/usr/share/roundcube') then begin
          list.Add('$_GLOBAL["roundcube_installed"]=True;');
             end else begin
             list.Add('$_GLOBAL["roundcube_installed"]=false;');
    end;


    list.Add('?>');
    list.SaveToFile( php_path + '/ressources/settings.inc');
    if debug then LOGS.logs('thProcThread.web_settings() ->Apply Security chmod 666 on settings.inc');


    Shell('/bin/chmod 666 '+ php_path + '/ressources/settings.inc');
    Shell('/bin/chmod -R 0755 ' + php_path + '/ressources/conf');


    if debug then LOGS.Logs('thProcThread.web_settings('+ php_path + ') -> TERM');
    list.Free;
;


end;
//##############################################################################
procedure Tprocess1.killfile(path:string);
Var F : Text;
begin
 if not FileExists(path) then begin
        LOGS.logs('Error:thProcThread.killfile -> file not found (' + path + ')');
        exit;
 end;
TRY
 Assign (F,path);
 Erase (f);
 EXCEPT
 LOGS.logs('Error:thProcThread.killfile -> unable to delete (' + path + ')');
 end;
end;
//##############################################################################
procedure Tprocess1.MailGraph();
var cgi_temp,cgibin,rrd,rrd_virus:string;
sIni:Myconf;
begin
   sIni:=MyConf.Create();
   cgi_temp:=sIni.get_MAILGRAPH_TMP_PATH();
   cgibin:=sIni.get_MAILGRAPH_BIN();
   rrd:=sIni.get_MAILGRAPH_RRD();
   rrd_virus:=sIni.get_MAILGRAPH_RRD_VIRUS();
   php_path:=sIni.get_ARTICA_PHP_PATH();

    if processINFOS.ISprocessExist('mailgraph')=false then begin
        if debug then LOGS.logs('thProcThread.MailGraph is not executed...');
        exit;
    end;

   if length(cgi_temp)=0 then begin
    if debug then LOGS.logs('Error:thProcThread.MailGraph -> unable to locate cgi temp');
    exit;
   end;
   if debug then LOGS.logs('thProcThread.MailGraph tmp ->' + cgi_temp);
   if debug then LOGS.logs('thProcThread.MailGraph bin ->' + cgibin);
   if debug then LOGS.logs('thProcThread.MailGraph rrd ->' + rrd);
   if debug then LOGS.logs('thProcThread.MailGraph rrd_virus ->' + rrd_virus);

   if not FileExists(rrd) then begin
      LOGS.logs('thProcThread.MailGraph ->' + rrd + ' seems not to be a good path.. change it..');
      sIni.set_MAILGRAPH_RRD('');
   end;
   if not FileExists(rrd_virus) then begin
      LOGS.logs('thProcThread.MailGraph ->' + rrd_virus + ' seems not to be a good path.. change it..');
      sIni.set_MAILGRAPH_RRD_VIRUS('');
   end;

   if debug then LOGS.logs('thProcThread.MailGraph shell(' + cgibin + ')');
   Shell(cgibin);
   if debug then LOGS.logs('thProcThread.MailGraph shell(/bin/cp ' + cgi_temp + '/*.png ' + php_path + '/img/)');
   Shell('/bin/cp ' + cgi_temp + '/*.png ' + php_path + '/img/');
end;
//##############################################################################



function Tprocess1.ExecPipe(commandline:string):string;
const
  READ_BYTES = 2048;
  CR = #$0d;
  LF = #$0a;
  CRLF = CR + LF;

var
  S: TStringList;
  M: TMemoryStream;
  P: TProcess;
  n: LongInt;
  BytesRead: LongInt;
  xRes:string;

begin
  // writeln(commandline);
  M := TMemoryStream.Create;
  BytesRead := 0;
  P := TProcess.Create(nil);
  P.CommandLine := commandline;
  P.Options := [poUsePipes];
  if debug then LOGS.Logs('MyConf.ExecPipe -> ' + commandline);

  P.Execute;
  while P.Running do begin
    M.SetSize(BytesRead + READ_BYTES);
    n := P.Output.Read((M.Memory + BytesRead)^, READ_BYTES);
    if n > 0 then begin
      Inc(BytesRead, n);
    end
    else begin
      Sleep(100);
    end;

  end;

  repeat
    M.SetSize(BytesRead + READ_BYTES);
    n := P.Output.Read((M.Memory + BytesRead)^, READ_BYTES);
    if n > 0 then begin
      Inc(BytesRead, n);
    end;
  until n <= 0;
  M.SetSize(BytesRead);
  S := TStringList.Create;
  S.LoadFromStream(M);
  if debug then LOGS.Logs('Tprocessinfos.ExecPipe -> ' + IntTostr(S.Count) + ' lines');
  for n := 0 to S.Count - 1 do
  begin
    if length(S[n])>1 then begin

      xRes:=xRes + S[n] +CRLF;
    end;
  end;
  if debug then LOGS.Logs('Tprocessinfos.ExecPipe -> exit');
  S.Free;
  P.Free;
  M.Free;
  exit( xRes);
end;
//##############################################################################
end.

