unit roundcube;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,IniFiles, Process,logs,unix,RegExpr in 'RegExpr.pas',zsystem,lighttpd;

type LDAP=record
      admin:string;
      password:string;
      suffix:string;
      servername:string;
      Port:string;
  end;

  type
  troundcube=class


private
     LOGS:Tlogs;
     D:boolean;
     GLOBAL_INI:TiniFIle;
     SYS:TSystem;
     artica_path:string;
     lighttpd:Tlighttpd;
     RoundCubeHTTPEngineEnabled:integer;
     function COMMANDLINE_PARAMETERS(FoundWhatPattern:string):boolean;
     function get_INFOS(key:string):string;
     function get_LDAP(key:string):string;
     function ReadFileIntoString(path:string):string;
     function  roundcube_db_inc_php():string;
     function  MYSQL_SERVER_PARAMETERS_CF(key:string):string;
     function  MYSQL_MYCNF_PATH:string;
     procedure APPLY_CONFIGURATIONS();
     procedure PHP_CONFIG();
     procedure SavePlugins();
     function  lighttpd_server_key(key:string):string;
     procedure lighttpd_set_server_key(key:string;value:string);
public
    procedure   Free;
    constructor Create(const zSYS:Tsystem);
    procedure   START();
    function    main_folder():string;
    procedure   SetPermissions();
    function    MYSQL_SOURCE_PATH():string;
    procedure   ROUNDCUBE_START_SERVICE();
    procedure   ROUNDCUBE_STOP_SERVICE();
    function    ROUNDCUBE_PID():string;
    function    web_folder():string;
    function    STATUS:string;
    function    VERSION():string;
    procedure   DEBIAN_CONFIG();
    function    INTVERSION(version_str:string):integer;
    function    PluginsList():string;



END;

implementation

constructor troundcube.Create(const zSYS:Tsystem);
begin
       forcedirectories('/etc/artica-postfix');
       LOGS:=tlogs.Create();
       SYS:=zSys;
       lighttpd:=Tlighttpd.Create(SYS);
       D:=COMMANDLINE_PARAMETERS('--roundcube');
       RoundCubeHTTPEngineEnabled:=0;
       if Not TryStrtoInt(SYS.GET_INFO('RoundCubeHTTPEngineEnabled'),RoundCubeHTTPEngineEnabled) then RoundCubeHTTPEngineEnabled:=0;


       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;
end;
//##############################################################################
procedure troundcube.free();
begin
    logs.Free;
    lighttpd.Free;
end;
//##############################################################################
procedure troundcube.START();
var
   import:boolean;
begin

   import:=false;
   if not FileExists(roundcube_db_inc_php()) then begin
      logs.Debuglogs('ROUNDCUBE:: unable to stat db.inc.php, (not installed) abort..;' );
      exit;
   end;
   
   
   if D then writeln('DEBIAN_CONFIG();');
   DEBIAN_CONFIG();

   
   if not FileExists(MYSQL_SOURCE_PATH()) then begin
     logs.Debuglogs('ROUNDCUBE:: unable to stat sql5 commands');
     exit;
   end;

   if not logs.IF_DATABASE_EXISTS('roundcubemail') then import:=true;
   if not logs.IF_TABLE_EXISTS('contacts','roundcubemail') then import:=true;
   if D then writeln('import=',import);
   if import then begin
      logs.Debuglogs('ROUNDCUBE:: not really set... import database');
      logs.EXECUTE_SQL_FILE(MYSQL_SOURCE_PATH(),'roundcubemail');
   end else begin
      logs.Debuglogs('ROUNDCUBE:: mysql test success');
   end;
    SavePlugins();
end;

//##############################################################################
function troundcube.STATUS:string;
var
pidpath:string;
begin

   if not DirectoryExists(web_folder()) then exit;
   SYS.MONIT_DELETE('APP_ROUNDCUBE');
   if not FileExists(roundcube_db_inc_php()) then  exit;
   pidpath:=logs.FILE_TEMP();
   fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.status.php --roundcube >'+pidpath +' 2>&1');
   result:=logs.ReadFromFile(pidpath);
   logs.DeleteFile(pidpath);

end;
//##############################################################################
function troundcube.VERSION():string;
var
path:string;
 RegExpr:TRegExpr;
    FileDatas:TStringList;
    i:integer;
begin
     path:=web_folder() +  '/program/include/iniset.php';

     result:=SYS.GET_CACHE_VERSION('APP_ROUNDCUBE');
     if length(result)>0 then exit;

     if not FileExists(path) then exit;
     FileDatas:=TstringList.Create;
     FileDatas.LoadFromFile(path);
     RegExpr:=TRegExpr.Create;
     RegExpr.Expression:='define\(.+?RCMAIL_VERSION.+?([0-9\.]+)';
     for i:=0 to FileDatas.Count-1 do begin
         if RegExpr.Exec(FileDatas.Strings[i]) then begin
            result:=RegExpr.Match[1];
            break;
         end;
     end;
  RegExpr.free;
  FileDatas.free;
  SYS.SET_CACHE_VERSION('APP_ROUNDCUBE',result);

end;
//##############################################################################
function troundcube.INTVERSION(version_str:string):integer;
var
 vers:string;
 RegExpr:TRegExpr;
begin
   if length(version_str)=0 then exit(0);
   vers:=version_str;
   vers:=AnsiReplaceText(vers,'-stable','');
   vers:=AnsiReplaceText(vers,'-beta','');
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^([0-9]+)\.([0-9]+)\.([0-9]+)$';
   if RegExpr.Exec(vers) then begin
      vers:=RegExpr.Match[1]+RegExpr.Match[2]+RegExpr.Match[3];
      if not TryStrToInt(vers,result) then result:=0;
      exit;
   end;

   RegExpr.Expression:='^([0-9]+)\.([0-9]+)$';
   if RegExpr.Exec(vers) then begin
      vers:=RegExpr.Match[1]+RegExpr.Match[2]+'0';
      if not TryStrToInt(vers,result) then result:=0;
      exit;
   end;
   RegExpr.Expression:='^([0-9]+)\.([0-9]+)\.([0-9]+)-';
    if RegExpr.Exec(vers) then begin
      vers:=RegExpr.Match[1]+RegExpr.Match[2]+'0';
      if not TryStrToInt(vers,result) then result:=0;
      exit;
   end;


   if not TryStrToInt(vers,result) then result:=0;
end;
//##############################################################################
function troundcube.PluginsList():string;
var
   i:Integer;
   str:string;

begin
   str:='';
   if not DirectoryExists(web_folder()+'/plugins') then exit;
   SYS.DirDir(web_folder()+'/plugins');
   for i:=0 to SYS.DirListFiles.Count-1 do begin
       str:=str+SYS.DirListFiles.Strings[i]+';';
   end;

result:=str;

end;
//##############################################################################
function troundcube.roundcube_db_inc_php():string;
begin
   if FileExists('/etc/roundcube/db.inc.php') then exit('/etc/roundcube/db.inc.php');
   if FileExists('/usr/share/roundcubemail/config/db.inc.php') then exit('/usr/share/roundcubemail/config/db.inc.php');
   if FileExists('/usr/share/roundcube/config/db.inc.php') then exit('/usr/share/roundcube/config/db.inc.php');
   if DirectoryExists('/usr/share/roundcube/config') then exit('/usr/share/roundcube/config/db.inc.php');

end;
//##############################################################################
function troundcube.main_folder():string;
begin

if FileExists('/usr/share/roundcubemail/index.php') then exit('/usr/share/roundcubemail');
if FileExists('/usr/share/roundcube/index.php') then exit('/usr/share/roundcube');
if FileExists('/var/lib/roundcube/index.php') then exit('/var/lib/roundcube');
end;
//##############################################################################
function troundcube.web_folder():string;
begin
if FileExists('/usr/share/roundcube/index.php') then exit('/usr/share/roundcube');
if FileExists('/usr/share/roundcubemail/index.php') then exit('/usr/share/roundcubemail');
end;
//##############################################################################
function troundcube.ROUNDCUBE_PID():string;
var
   pidpath:string;
   pid:string;
begin
     pidpath:='/var/run/lighttpd/lighttpd-roundcube.pid';
     pid:=SYS.GET_PID_FROM_PATH(pidpath);
     if length(pid)=0 then PID:=trim(SYS.ExecPipe('/usr/bin/pgrep -f "'+sys.LOCATE_LIGHTTPD_BIN_PATH()+ ' -f /etc/artica-postfix/lighttpd-roundcube.conf"'));
     result:=pid;
end;
//##############################################################################
procedure troundcube.APPLY_CONFIGURATIONS();
var confFile,SourceCOnf:string;

begin

confFile:=ExtractFilePath(roundcube_db_inc_php())+'main.inc.php';
logs.Debuglogs('Starting......: Roundcube configuration file: building "'+confFile+'"...');
logs.Debuglogs('Starting......: Roundcube configuration -> exec.roundcube.php');
fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.roundcube.php --build');
confFile:='/etc/artica-postfix/lighttpd-roundcube.conf';
SourceCOnf:='/etc/artica-postfix/settings/Daemons/RoundCubeLightHTTPD';

     if FileExists(SourceCOnf) then begin
         if logs.MD5FromString(logs.ReadFromFile(SourceCOnf))<>logs.MD5FromString(logs.ReadFromFile(confFile)) then begin
             logs.Debuglogs('Starting......: Roundcube replicate lighttpd-roundcube.conf');
             logs.OutputCmd('/bin/cp '+SourceCOnf+' '+confFile);
         end;
     end;
     DEBIAN_CONFIG();
     PHP_CONFIG();
     SavePlugins();


end;
//##############################################################################
procedure troundcube.PHP_CONFIG();
var
   php5UploadMaxFileSize:string;
   RegExpr:TRegExpr;
   l:TStringList;
   i:integer;
begin
     exit;
     php5UploadMaxFileSize:=SYS.GET_INFO('php5UploadMaxFileSize');

     logs.Debuglogs('Starting......: Roundcube writing php.ini file');
     logs.Debuglogs('Starting......: Roundcube Max upload to '+php5UploadMaxFileSize);
     fpsystem(paramstr(0)+' --php-ini >/dev/null');
     l:=Tstringlist.Create;
     l.LoadFromFile('/etc/artica/php-roundcube.ini');
     RegExpr:=TRegExpr.Create;
     RegExpr.Expression:='upload_max_filesize';
     for i:=0 to l.Count-1 do begin
         if RegExpr.Exec(l.Strings[i]) then begin
            l.Strings[i]:='upload_max_filesize = '+php5UploadMaxFileSize+'M';
            break;
         end;
     end;

l.SaveToFile('/etc/artica/php-roundcube.in');
l.free;
RegExpr.free;

end;
//##############################################################################


procedure troundcube.SetPermissions();
var
   webfolder:string;
   www_userGroup:string;
   username:string;
   username_src:string;
   groupname_src:string;
   groupname:string;
   errorlog:string;
   RegExpr:TRegExpr;
   find_pr:string;
   chmod_pr:string;
begin
  webfolder:=lighttpd_server_key('document-root');
  if not DirectoryExists(webfolder) then begin
     logs.Debuglogs('Unable to find Roundcube directory');
     exit;
  end;
  lighttpd:=Tlighttpd.Create(SYS);
  find_pr:=SYS.LOCATE_GENERIC_BIN('find');
  chmod_pr:=SYS.LOCATE_GENERIC_BIN('chmod');
  username_src:=lighttpd.lighttpd_server_key('username');
  groupname_src:=lighttpd.lighttpd_server_key('groupname');
  RegExpr:=TRegExpr.Create;
  RegExpr.Expression:='(.+?):(.+)';
  if RegExpr.Exec(username_src) then username_src:=RegExpr.Match[1];


  username:=lighttpd_server_key('username');
  groupname:=lighttpd_server_key('groupname');

  if username_src<>username then begin
     logs.Debuglogs('Starting......: Roundcube change user from: '+username +':'+groupname+' -> '+username_src +':' +groupname_src);
     lighttpd_set_server_key('username',username_src);
     lighttpd_set_server_key('groupname',groupname_src);
  end;
  www_userGroup:=username_src+':'+groupname_src;

     logs.Debuglogs('Starting......: Roundcube Folder...:'+webfolder);
     logs.Debuglogs('Starting......: Roundcube user.....:'+www_userGroup);
     errorlog:=lighttpd_server_key('errorlog');
     logs.Debuglogs('Starting......: Roundcube error log:'+errorlog);
     if length(errorlog)>0 then begin
        if not FileExists(errorlog) then fpsystem('/bin/touch '+errorlog);
        fpsystem('/bin/chown '+www_userGroup+' '+errorlog +' >/dev/null 2>&1');
     end;

  logs.Debuglogs('Starting......: Settings securities on RoundCube path');
  logs.OutputCmd('rm -f '+webfolder+'/roundcube');
  logs.OutputCmd('rm -f '+webfolder+'/*.exe');
  logs.OutputCmd('rm -f '+webfolder+'/*.vbs');
  logs.OutputCmd('rm -f '+webfolder+'/*.scr');


  logs.Debuglogs('Starting......: Fix permissions on RoundCube path');
  logs.OutputCmd(chmod_pr+' -R 0500 '+webfolder);
  logs.OutputCmd(chmod_pr+' 755 '+webfolder+'/temp');
  logs.OutputCmd(chmod_pr+' 755 '+webfolder+'/logs');
  if not FileExists(webfolder+'/logs/errors') then logs.OutputCmd('/bin/touch '+webfolder+'/logs/errors');
  logs.OutputCmd(chmod_pr+' 755 '+webfolder+'/plugins/artica_ldap_addr/logs');
  logs.OutputCmd('/bin/chown -R '+www_userGroup+' '+webfolder);
  logs.OutputCmd('/bin/chown '+www_userGroup+' '+webfolder+'/logs/errors');
  SYS.SecureWeb(webfolder);
  logs.OutputCmd(chmod_pr+' 777 '+webfolder+'/logs/errors');
  if DirectoryExists(webfolder+'/plugins/globaladdressbook') then begin
     logs.OutputCmd(find_pr+' '+webfolder+'/plugins/globaladdressbook -type d -exec '+chmod_pr+' 770 {} \;');
     logs.OutputCmd(find_pr+' '+webfolder+'/plugins/globaladdressbook -type f -exec '+chmod_pr+' 660 {} \;');
  end;

  RegExpr.free;
end;
//##############################################################################

procedure troundcube.SavePlugins();
var
   l,t:Tstringlist;
   folder:string;
   sieve_port:integer;

begin

sieve_port:=SYS.ETC_SERVICES_PORT('sieve');
if sieve_port=0 then sieve_port:=2000;
l:=Tstringlist.Create;
folder:=web_folder();
l.Add('<?php');
l.Add('$sieverules_config = array();');
l.Add('$sieverules_config["managesieve_host"] = "127.0.0.1";');
l.Add('$sieverules_config["managesieve_port"] = '+IntToStr(sieve_port)+';');
l.Add('$sieverules_config["usetls"] = FALSE;');
l.Add('$sieverules_config["folder_delimiter"] = null;');
l.Add('$sieverules_config["include_imap_root"] = FALSE;');
l.Add('$sieverules_config["ruleset_name"] = "roundcube";');
l.Add('$sieverules_config["multiple_actions"] = TRUE;');
l.Add('$sieverules_config["allowed_actions"] = array("fileinto" => TRUE,"vacation" => TRUE,"reject" => TRUE,"redirect" => TRUE,"keep" => TRUE,"discard" => TRUE,"imapflags" => TRUE,"notify" => TRUE,"stop" => TRUE);');
l.Add('$sieverules_config["other_headers"] = array("Reply-To", "List-Id", "MailingList", "Mailing-List",');
l.add(chr(9)+'"X-ML-Name", "X-List", "X-List-Name", "X-Mailing-List","Resent-From", "Resent-To", "X-Mailer",');
l.add(chr(9)+'"X-MailingList","X-Spam-Status", "X-Priority", "Importance", "X-MSMail-Priority","Precedence", "Return-Path", "Received", "Auto-Submitted","X-Spam-Flag", "X-Spam-Tests");');
l.Add('$sieverules_config["predefined_rules"] = array();');
l.Add('$sieverules_config["adveditor"] = "0";');
l.Add('$sieverules_config["default_file"] = "/etc/dovecot/sieve/default";');
l.Add('$sieverules_config["auto_load_default"] = TRUE;');
l.Add('$sieverules_config["example_file"] = "/etc/dovecot/sieve/example";');
l.Add('?>');

if DirectoryExists(folder+'/plugins/sieverules') then begin
   logs.Debuglogs('Starting......: Roundcube sieverules sieve listen port "'+IntToStr(sieve_port)+'"');
   t:=Tstringlist.Create;
   t.add('<?php');
   t.add('$rcmail_config["sieverules_host"] = "127.0.0.1";');
   t.add('$rcmail_config["sieverules_port"] = '+IntToStr(sieve_port)+';');
   t.add('$rcmail_config["sieverules_usetls"] = FALSE;');
   t.add('$rcmail_config["sieverules_folder_delimiter"] = null;');
   t.add('$rcmail_config["sieverules_folder_encoding"] = null;');
   t.add('$rcmail_config["sieverules_include_imap_root"] = null;');
   t.add('$rcmail_config["sieverules_ruleset_name"] = "roundcube";');
   t.add('$rcmail_config["sieverules_multiple_actions"] = TRUE;');
   t.add('$rcmail_config["sieverules_allowed_actions"] = array("fileinto" => TRUE,"vacation" => TRUE,"reject" => TRUE,"redirect" => TRUE,"keep" => TRUE,"discard" => TRUE,"imapflags" => TRUE,"notify" => TRUE,"stop" => TRUE);');
   t.add('$rcmail_config["sieverules_other_headers"] = array("Reply-To", "List-Id", "MailingList", "Mailing-List","X-ML-Name", "X-List", "X-List-Name", "X-Mailing-List","Resent-From",');
   t.add(chr(9)+'"Resent-To", "X-Mailer", "X-MailingList","X-Spam-Status", "X-Priority", "Importance", "X-MSMail-Priority","Precedence", "Return-Path", "Received", "Auto-Submitted","X-Spam-Flag", "X-Spam-Tests");');
   t.add('$rcmail_config["sieverules_predefined_rules"] = array();');
   t.add('$rcmail_config["sieverules_adveditor"] = 0;');
   t.add('$rcmail_config["sieverules_multiplerules"] = FALSE;');
   t.add('$rcmail_config["sieverules_default_file"] = "/etc/dovecot/sieve/default";');
   t.add('$rcmail_config["sieverules_auto_load_default"] = FALSE;');
   t.add('$rcmail_config["sieverules_example_file"] = "/etc/dovecot/sieve/example";');
   t.add('$rcmail_config["sieverules_force_vacto"] = TRUE;');
   t.add('$rcmail_config["sieverules_use_elsif"] = TRUE;');
   t.add('?>');
   logs.WriteToFile(t.Text,folder+'/plugins/sieverules/config.inc.php');
   logs.Debuglogs('Starting......: Roundcube writing '+folder+'/plugins/sieverules/config.inc.php done');
   logs.WriteToFile(t.Text,'/usr/share/artica-postfix/bin/install/roundcube/sieverules/config.inc.php');
   logs.Debuglogs('Starting......: Roundcube writing Artica config done...');

   logs.OutputCmd('/bin/chmod 755 '+folder+'/plugins/sieverules/config.inc.php');
   t.free;
end;

L.Clear;

l.Add('<?php');
l.Add('$rcmail_config[''managesieve_port''] = '+IntToStr(sieve_port)+';');
l.Add('$rcmail_config[''managesieve_host''] = ''127.0.0.1'';');
l.Add('$rcmail_config[''managesieve_usetls''] = false;');
l.Add('$rcmail_config[''managesieve_default''] = ''/etc/dovecot/sieve/global'';');
l.Add('$rcmail_config[''managesieve_replace_delimiter''] = '''';');
l.Add('$rcmail_config[''managesieve_disabled_extensions''] = array();');

l.Add('?>');

if DirectoryExists(folder+'/plugins/managesieve') then begin
   logs.Debuglogs('Starting......: Roundcube replicate plugin managesieve');
   logs.WriteToFile(l.Text,folder+'/plugins/managesieve/config.inc.php');
   logs.OutputCmd('/bin/chmod 755 '+folder+'/plugins/managesieve/config.inc.php');
end;

logs.OutputCmd('/bin/ln -s /usr/share/artica-postfix/roundcube-plugin/artica_ldap_addr '+ folder+'/plugins/artica_ldap_addr');
logs.OutputCmd('/bin/ln -s /usr/share/artica-postfix/ressources/settings.inc '+ folder+'/plugins/artica_ldap_addr/settings.inc');
forceDirectories(folder+'/plugins/artica_ldap_addr/logs');
logs.OutputCmd('/bin/chmod 777 '+folder+'/plugins/artica_ldap_addr/logs');


 L.Clear;

end;
//##############################################################################


procedure troundcube.ROUNDCUBE_START_SERVICE();
var
   conf_path:string;
   lighttpd:Tlighttpd;
   pid:string;
   user:string;
begin
     lighttpd:=Tlighttpd.Create(SYS);
     conf_path:='/etc/artica-postfix/lighttpd-roundcube.conf';

     if Not DirectoryExists(main_folder())then begin
        logs.Debuglogs('Starting......: RoundCube is not installed');
        exit;
     end;


     lighttpd:=Tlighttpd.Create(SYS);
     if not FileExists(lighttpd.LIGHTTPD_BIN_PATH()) then begin
        logs.Debuglogs('Starting......: lighttpd is not installed');
        exit;
     end;                                                        
     
     SYS.THREAD_COMMAND_SET(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.roundcube.php --verifyTables');


     if SYS.GET_INFO('RoundCubeHTTPEngineEnabled')<>'1' then begin
         logs.Debuglogs('Starting......: Roundcube Configuration file "/etc/artica-postfix/lighttpd-roundcube.conf"');
         logs.Debuglogs('Starting......: lighttpd For RoundCube is disabled');
         logs.Debuglogs('Starting......: Create symbolic link from '+web_folder+' to '+ artica_path + '/webmail');
         logs.OutputCmd('/bin/ln -s --force ' + web_folder + ' ' +artica_path + '/webmail');
         APPLY_CONFIGURATIONS();
         SetPermissions();
         pid:=ROUNDCUBE_PID();
         if SYS.PROCESS_EXIST(pid) then ROUNDCUBE_STOP_SERVICE();
         exit;
     end;

     pid:=ROUNDCUBE_PID();
     if SYS.PROCESS_EXIST(pid) then begin
        logs.Debuglogs('Starting......: lighttpd for RoundCube already running with pid '+pid);
        exit;
     end;


     if FileExists('/etc/artica-postfix/settings/Daemons/RoundCubeLightHTTPD') then begin
          logs.OutputCmd('/bin/cp /etc/artica-postfix/settings/Daemons/RoundCubeLightHTTPD /etc/artica-postfix/lighttpd-roundcube.conf');
     end;



     user:=lighttpd.LIGHTTPD_GET_USER();
     logs.Debuglogs('Starting......: Roundcube user '+user);
     APPLY_CONFIGURATIONS();
     SetPermissions();


     if not FileExists(conf_path) then begin
          logs.Debuglogs('ROUNDCUBE_START_SERVICE():: Unable to stat /etc/artica-postfix/lighttpd-roundcube.conf');
          exit;
     end;
     

     if not SYS.PROCESS_EXIST(pid) then begin
         logs.Debuglogs('Starting......: Roundcube Configuration file "'+roundcube_db_inc_php()+'"');
         logs.OutputCmd('/bin/cp /etc/artica-postfix/settings/Daemons/RoundCubeConfigurationFile '+roundcube_db_inc_php);
         DEBIAN_CONFIG();
         logs.OutputCmd(lighttpd.LIGHTTPD_BIN_PATH() + ' -f ' + '/etc/artica-postfix/lighttpd-roundcube.conf');

     
     pid:=ROUNDCUBE_PID();
      if not SYS.PROCESS_EXIST(pid) then begin
        logs.Debuglogs('Starting......: lighttpd for RoundCube Failed to start http engine');
        logs.Debuglogs('Starting......: "'+lighttpd.LIGHTTPD_BIN_PATH() + ' -f ' + '/etc/artica-postfix/lighttpd-roundcube.conf"');
        exit;
      end  else begin
        logs.Debuglogs('Starting......: lighttpd for RoundCube Success starting lighttpd pid number ' + pid);
     end;
     end else begin
         logs.Debuglogs('Starting......: lighttpd for RoundCube already started with PID ' + pid);
         exit;
     end;
end;
//##############################################################################
function troundcube.lighttpd_server_key(key:string):string;
var
   sourcefile:string;
   RegExpr:TRegExpr;
   l:Tstringlist;
   i:integer;
begin

sourcefile:='/etc/artica-postfix/lighttpd-roundcube.conf';
if not FileExists(sourcefile) then sourcefile:='/etc/artica-postfix/settings/Daemons/RoundCubeLightHTTPD';
if not FileExists(sourcefile) then exit;
RegExpr:=TRegExpr.Create;
RegExpr.Expression:='server\.'+key+'.*?=.*?"(.+?)"';
l:=Tstringlist.Create;
l.LoadFromFile(sourcefile);
For i:=0 to l.Count-1 do begin
   if RegExpr.Exec(l.Strings[i]) then begin
      result:=RegExpr.Match[1];
      break;
   end;
end;

l.free;
RegExpr.free;
end;
//##############################################################################
procedure troundcube.lighttpd_set_server_key(key:string;value:string);
var
   sourcefile:string;
   RegExpr:TRegExpr;
   l:Tstringlist;
   i:integer;
   f:boolean;
begin

sourcefile:='/etc/artica-postfix/lighttpd-roundcube.conf';
if not FileExists(sourcefile) then sourcefile:='/etc/artica-postfix/settings/Daemons/RoundCubeLightHTTPD';
if not FileExists(sourcefile) then exit;
RegExpr:=TRegExpr.Create;
f:=false;
RegExpr.Expression:='^server\.'+key;
l:=Tstringlist.Create;
l.LoadFromFile(sourcefile);
For i:=0 to l.Count-1 do begin
   if RegExpr.Exec(l.Strings[i]) then begin
      l.Strings[i]:='server.'+key+chr(9)+'= "'+value+'"';
      f:=true;
      break;
   end;
end;

if not f then l.Add('server.'+key+chr(9)+'= "'+value+'"');
logs.WriteToFile(l.Text,sourcefile);

l.free;
RegExpr.free;
end;
//##############################################################################
procedure troundcube.ROUNDCUBE_STOP_SERVICE();
var
   conf_path:string;
   lighttpd:Tlighttpd;
   pid:string;
begin
  conf_path:='/etc/artica-postfix/lighttpd-roundcube.conf';

     if not FileExists(conf_path) then begin
          logs.Debuglogs('ROUNDCUBE_START_SERVICE():: Unable to stat /etc/artica-postfix/lighttpd-roundcube.conf');
          exit;
     end;

     if Not DirectoryExists(main_folder())then begin
        logs.Debuglogs('ROUNDCUBE_START_SERVICE():: RoundCube is not installed');
        exit;
     end;
     lighttpd:=Tlighttpd.Create(SYS);
     if not FileExists(lighttpd.LIGHTTPD_BIN_PATH()) then begin
        logs.Debuglogs('ROUNDCUBE_START_SERVICE():: lighttpd is not installed');
        exit;
     end;
     
pid:=ROUNDCUBE_PID();
     if not SYS.PROCESS_EXIST(pid) then begin
        writeln('Stopping RoundCube service...: Already stopped');
        exit;
     end;

     writeln('Stopping RoundCube service...: ' + pid + ' PID');
     fpsystem('/bin/kill ' +pid);
     exit;
end;
//##############################################################################

procedure troundcube.DEBIAN_CONFIG();
var
   l:TstringList;
begin

     if not FileExists('/etc/roundcube/debian-db.php') then begin
        ForceDirectories('/etc/roundcube');
        logs.Debuglogs('DEBIAN_CONFIG():: unable to stat /etc/roundcube/debian-db.php force create it....');
     end;
     l:=TstringList.Create;
l.Add('<?php');
l.Add('##');
l.Add('## database access settings in php format');
l.Add('## automatically generated from /etc/dbconfig-common/roundcube.conf');
l.Add('## by /usr/sbin/dbconfig-generate-include');
l.Add('## Thu, 29 May 2008 11:22:21 +0200');
l.Add('##');
l.Add('## by default this file is managed via ucf, so you shouldn"t have to');
l.Add('## worry about manual changes being silently discarded.  *however*,');
l.Add('## you"ll probably also want to edit the configuration file mentioned');
l.Add('## above too.');
l.Add('##');
l.Add('$dbuser="'+ SYS.MYSQL_INFOS('database_admin') + '";');
l.Add('$dbpass="' + SYS.MYSQL_INFOS('database_password') + '";');
l.Add('$basepath="";');
l.Add('$dbname="roundcubemail";');
l.Add('$dbserver="' + SYS.MYSQL_INFOS('mysql_server') + '";');
l.Add('$dbport="' + SYS.MYSQL_INFOS('port') + '";');
l.Add('$dbtype="mysql";');
logs.WriteToFile(l.Text,'/etc/roundcube/debian-db.php');
logs.Debuglogs('saving /etc/roundcube/debian-db.php');

l.CLear;
l.Add('<?php');
l.Add('$rcmail_config = array();');
l.Add('$rcmail_config["db_dsnw"] = "mysql://'+SYS.MYSQL_INFOS('database_admin')+':' + SYS.MYSQL_INFOS('database_password') + '@'+ SYS.MYSQL_INFOS('mysql_server') +'/roundcubemail";');
l.Add('$rcmail_config["db_dsnr"] = "";');
l.Add('$rcmail_config["db_max_length"] = 512000;  // 500K');
l.Add('$rcmail_config["db_persistent"] = FALSE;');
l.Add('$rcmail_config["db_table_users"] = "users";');
l.Add('$rcmail_config["db_table_identities"] = "identities";');
l.Add('$rcmail_config["db_table_contacts"] = "contacts";');
l.Add('$rcmail_config["db_table_session"] = "session";');
l.Add('$rcmail_config["db_table_cache"] = "cache";');
l.Add('$rcmail_config["db_table_messages"] = "messages";');
l.Add('$rcmail_config["db_sequence_users"] = "user_ids";');
l.Add('$rcmail_config["db_sequence_identities"] = "identity_ids";');
l.Add('$rcmail_config["db_sequence_contacts"] = "contact_ids";');
l.Add('$rcmail_config["db_sequence_cache"] = "cache_ids";');
l.Add('$rcmail_config["db_sequence_messages"] = "message_ids";');
l.Add('$rcmail_config["db_sequence_contacts"] = "contact_ids";');
l.Add('$rcmail_config["db_sequence_contactgroups"] = "contactgroups_ids";');
l.Add('?>');
logs.Debuglogs('saving /usr/share/roundcube/config/db.inc.php');
logs.WriteToFile(l.Text,'/usr/share/roundcube/config/db.inc.php');
l.free;
end;

//##############################################################################
function troundcube.MYSQL_SOURCE_PATH():string;
begin
    if FileExists('/usr/share/dbconfig-common/data/roundcube/install/mysql') then exit('/usr/share/dbconfig-common/data/roundcube/install/mysql');
    if FileExists('/usr/share/dbconfig-common/data/roundcube/install/mysql') then exit('/usr/share/dbconfig-common/data/roundcube/install/mysql');
    if FileExists('/usr/share/roundcubemail/SQL/mysql5.initial.sql') then exit('/usr/share/roundcubemail/SQL/mysql5.initial.sql');
    if FileExists('/usr/share/roundcube/SQL/mysql.initial.sql') then exit('/usr/share/roundcube/SQL/mysql.initial.sql');
end;
//##############################################################################
function troundcube.get_INFOS(key:string):string;
var value:string;
begin
value:=SYS.GET_INFO(key);
result:=value;
end;
//#############################################################################
function troundcube.get_LDAP(key:string):string;
var value:string;
begin
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix-ldap.conf');
value:=GLOBAL_INI.ReadString('LDAP',key,'');
result:=value;
GLOBAL_INI.Free;
end;
//#############################################################################
function troundcube.COMMANDLINE_PARAMETERS(FoundWhatPattern:string):boolean;
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
function troundcube.ReadFileIntoString(path:string):string;
var
   List:TstringList;
begin

      if not FileExists(path) then begin
        exit;
      end;

      List:=Tstringlist.Create;
      List.LoadFromFile(path);
      result:=trim(List.Text);
      List.Free;
end;
//##############################################################################
function troundcube.MYSQL_SERVER_PARAMETERS_CF(key:string):string;
var ini:TiniFile;
begin
  result:='';
  if not FileExists(MYSQL_MYCNF_PATH()) then exit();
  ini:=TIniFile.Create(MYSQL_MYCNF_PATH());
  result:=ini.ReadString('mysqld',key,'');
  ini.free;
end;
//#############################################################################
function troundcube.MYSQL_MYCNF_PATH:string;
begin
  if FileExists('/etc/mysql/my.cnf') then exit('/etc/mysql/my.cnf');
  if FileExists('/etc/my.cnf') then exit('/etc/my.cnf');
  if FileExists('/opt/artica/mysql/etc/my.cnf') then exit('/opt/artica/mysql/etc/my.cnf');

end;
//#############################################################################

end.
