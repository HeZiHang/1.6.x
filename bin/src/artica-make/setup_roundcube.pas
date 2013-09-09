unit setup_roundcube;
{$MODE DELPHI}
//{$mode objfpc}{$H+}
{$LONGSTRINGS ON}
//ln -s /usr/lib/libmilter/libsmutil.a /usr/local/lib/libsmutil.a
//apt-get install libmilter-dev
interface

uses
  Classes, SysUtils,RegExpr in 'RegExpr.pas',
  unix,setup_libs,distridetect,zsystem,roundcube,lighttpd,
  install_generic;

  type
  install_roundcube=class


private
     libs:tlibs;
     distri:tdistriDetect;
     install:tinstall;
   source_folder,cmd:string;
   mysql_server:string;
   mysql_admin:string;
   mysql_password:string;
   ldap_server:string;
   SYS:Tsystem;
   roundcube:troundcube;
   lighttpd:Tlighttpd;
   procedure fullinstall(Path:string);
   procedure main_inc_php();


public
      constructor Create();
      procedure Free;
      procedure xinstall();
      procedure SieveRules();

END;

implementation

constructor install_roundcube.Create();
begin
libs:=tlibs.Create;
install:=tinstall.Create;
source_folder:='';
SYS:=Tsystem.Create();
if DirectoryExists(ParamStr(2)) then source_folder:=ParamStr(2);
roundcube:=troundcube.Create(SYS);
lighttpd:=Tlighttpd.Create(SYS);
end;
//#########################################################################################
procedure install_roundcube.Free();
begin
  libs.Free;
  roundcube.free;
  lighttpd.free;

end;

//#########################################################################################
procedure install_roundcube.SieveRules();
var
   CODE_NAME,web_folder:string;
   localver:integer;
begin

// /usr/share/roundcube/plugins
CODE_NAME:='APP_ROUNDCUBE3_SIEVE_RULE';
fpsystem('/bin/rm /etc/artica-postfix/versions.cache');
localver:=roundcube.INTVERSION(roundcube.VERSION());
web_folder:=roundcube.web_folder();
if localver<30 then begin
   writeln('You must upgrade RoundCube to 0.3');
   install.INSTALL_PROGRESS(CODE_NAME,'{failed}');
   install.INSTALL_STATUS(CODE_NAME,110);
end;

  if length(source_folder)=0 then source_folder:=libs.COMPILE_GENERIC_APPS('sieverules');

 if not DirectoryExists(source_folder) then begin
     writeln('Install '+CODE_NAME+' failed...');
     install.INSTALL_PROGRESS(CODE_NAME,'Unpack {failed}');
     install.INSTALL_STATUS(CODE_NAME,110);
     exit;
  end;

 writeln('Source is '+source_folder);
 forceDirectories(web_folder+'/plugins/sieverules');

 fpsystem('/bin/cp -rf '+source_folder+'/* /usr/share/roundcube/plugins/sieverules/');
 if not FileExists('/usr/share/roundcube/plugins/sieverules/sieverules.php') then begin
      install.INSTALL_PROGRESS(CODE_NAME,'{install} {failed}');
      install.INSTALL_STATUS(CODE_NAME,110);
      exit;
 end;
 fpsystem('/bin/chown -R 755 '+web_folder+'/plugins/sieverules');
 fpsystem('/etc/init.d/artica-postfix restart roundcube');
 if not FileExists(web_folder+'/plugins/sieverules/sieverules.php') then begin
    writeln('plugin sieverules failed');
    install.INSTALL_PROGRESS(CODE_NAME,'{failed}');
    install.INSTALL_STATUS(CODE_NAME,110);
    exit;
 end;
 writeln('install plugin sieverules success');
 install.INSTALL_PROGRESS(CODE_NAME,'{installed}');
 install.INSTALL_STATUS(CODE_NAME,100);
end;
//#########################################################################################
procedure install_roundcube.xinstall();
var
   CODE_NAME:string;
   cmd,mysql_root,mysql_password,mysql_server,port:string;
   web_folder:string;
   localver:integer;
   remoteversion:integer;
   remoteversion_srt:string;
   upgrade:boolean;

begin

    CODE_NAME:='APP_ROUNDCUBE3';
    SYS:=Tsystem.Create();
    install.INSTALL_STATUS(CODE_NAME,10);
    web_folder:=roundcube.web_folder();
    if not DirectoryExists(web_folder) then web_folder:='/usr/share/roundcube';



    if DirectoryExists(web_folder) then begin
       localver:=roundcube.INTVERSION(roundcube.VERSION());
       remoteversion_srt:=libs.COMPILE_VERSION_STRING('roundcubemail3');
       remoteversion:=roundcube.INTVERSION(remoteversion_srt);
       writeln('A previous installation v',roundcube.VERSION(),'::',localver,'<>',remoteversion_srt,'::',remoteversion,' is detected');
       if remoteversion<=localver then begin
          writeln('No update required ',remoteversion,'>',localver);
          if not FileExists(web_folder+'/plugins/sieverules/sieverules.php') then SieveRules();
          install.INSTALL_PROGRESS(CODE_NAME,'{installed}');
          install.INSTALL_STATUS(CODE_NAME,100);
          exit;
       end;

       upgrade:=true;
    end;

  ForceDirectories(web_folder);
  fpsystem('/bin/rm -rf '+web_folder+'/*');
  SetCurrentDir('/root');
  install.INSTALL_STATUS(CODE_NAME,20);
  install.INSTALL_PROGRESS(CODE_NAME,'{downloading}');

  if length(source_folder)=0 then source_folder:=libs.COMPILE_GENERIC_APPS('roundcubemail3');

  if not DirectoryExists(source_folder) then begin
     writeln('Install '+CODE_NAME+' failed...');
     install.INSTALL_STATUS(CODE_NAME,110);
     exit;
  end;

  mysql_root    :=SYS.MYSQL_INFOS('database_admin');
  mysql_password:=SYS.MYSQL_INFOS('database_password');
  mysql_server:=SYS.MYSQL_INFOS('server');
  port:=SYS.MYSQL_INFOS('port');

  install.INSTALL_PROGRESS(CODE_NAME,'{installing}');


  if upgrade then begin
     fpsystem('/bin/cp -rfv '+source_folder+'/* '+ web_folder+'/');
     if FileExists(web_folder+'/SQL/mysql.update.sql') then begin
        libs.EXECUTE_SQL_FILE(web_folder+'/SQL/mysql.update.sql','roundcubemail','');
        writeln('Install '+CODE_NAME+' success...');
        install.INSTALL_PROGRESS(CODE_NAME,'{installed}');
        install.INSTALL_STATUS(CODE_NAME,100);
        SieveRules();
        fpsystem('/etc/init.d/artica-postfix restart roundcube');
        exit;
     end else begin
      writeln('unable to stat '+web_folder+'/SQL/mysql.update.sql');
     end;
  end;


  fullinstall(source_folder);
  fpsystem('/bin/rm /etc/artica-postfix/versions.cache');
  SieveRules();
  install.INSTALL_PROGRESS(CODE_NAME,'{installed}');
  install.INSTALL_STATUS(CODE_NAME,100);
  fpsystem('/bin/rm /etc/artica-postfix/versions.cache');
  fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.initslapd.php --roundcube');
  fpsystem('/etc/init.d/roundcube restart');
  fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.www.install.php');

end;
//#########################################################################################
procedure install_roundcube.fullinstall(Path:string);
var
   filenname:string;
begin

 install.INSTALL_STATUS('APP_ROUNDCUBE3',50);
 install.INSTALL_STATUS('APP_ROUNDCUBE3',60);
 writeln('Sources was stored in '+Path);
 if not DirectoryExists(Path) then begin
   writeln('Installation failed, unable to stat sources...');
 end;


 ForceDirectories('/usr/share/roundcube');
 fpsystem('/bin/rm -rf /usr/share/roundcube/*');
 fpsystem('/bin/cp -rf '+Path+'/* /usr/share/roundcube/');

 writeln('');
 writeln('-------- Creating folder security settings --------');
 fpsystem('/bin/chmod -R 0755 /usr/share/roundcube/temp');
 fpsystem('/bin/chmod -R 0755 /usr/share/roundcube/logs');
 fpsystem('/bin/chown -R '+lighttpd.LIGHTTPD_GET_USER()+' /usr/share/roundcube');
 writeln('');
 writeln('');
 writeln('-------- Creating Databases and Tables in Mysql --------');
 filenname:='/usr/share/roundcube/SQL/mysql.initial.sql';
 if not FileExists('/usr/share/roundcube/SQL/mysql.initial.sql') then begin
    writeln('install()::unable to stat ' + filenname );
     install.INSTALL_STATUS('APP_ROUNDCUBE3',110);
    exit;
 end;

 if not libs.EXECUTE_SQL_FILE(filenname,'roundcubemail','') then begin
    writeln('install():: there is a problem while creating tables with '+filenname);
    install.INSTALL_STATUS('APP_ROUNDCUBE3',110);
    exit;
 end;

 filenname:='/usr/share/roundcube/SQL/mysql.update.sql';
 if FileExists(filenname) then begin
    if not libs.EXECUTE_SQL_FILE(filenname,'roundcubemail','') then begin
       writeln('install():: there is a problem while creating tables with '+filenname);
       install.INSTALL_STATUS('APP_ROUNDCUBE3',110);
       exit;
    end;
 end;
 install.INSTALL_STATUS('APP_ROUNDCUBE3',70);
 writeln('');
 writeln('-------- Linking RoundCube to Artica --------');
 fpsystem('/bin/ln -s /usr/share/roundcube /usr/share/artica-postfix/webmail');
 fpsystem('/bin/ln -s --force /usr/share/roundcube /var/lib/roundcube');
 fpsystem('/bin/ln -s --force /usr/share/roundcube/config/db.inc.php /etc/roundcube/debian-db.php');
 writeln('');

 main_inc_php();

 writeln('-------- Rebuild settings --------');
 fpsystem('/usr/share/artica-postfix/bin/artica-ldap -modules --verbose');
 writeln('-------- Updating Artica --------');
 install.INSTALL_STATUS('APP_ROUNDCUBE3',80);
 fpsystem('/usr/share/artica-postfix/bin/process1 --force');
 install.INSTALL_STATUS('APP_ROUNDCUBE3',100);
  fpsystem('/etc/init.d/artica-postfix restart roundcube');
  fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.www.install.php');
end;
//############################################################################

procedure install_roundcube.main_inc_php();
var
l:TstringList;
begin

l:=TstringList.Create;
writeln('creating main.inc.php...');
l.Add('<?php');
l.Add('$rcmail_config = array();');
l.Add('$rcmail_config["debug_level"] =1;');
l.Add('$rcmail_config["enable_caching"] = TRUE;');
l.Add('$rcmail_config["message_cache_lifetime"] = "10d";');
l.Add('$rcmail_config["auto_create_user"] = TRUE;');
l.Add('$rcmail_config["default_host"] = "'+SYS.HOSTNAME_g()+'";');
l.Add('$rcmail_config["default_port"] = 143;');
l.Add('$rcmail_config["username_domain"] = "";');
l.Add('$rcmail_config["mail_domain"] = "";');
l.Add('$rcmail_config["virtuser_file"] = "";');
l.Add('$rcmail_config["virtuser_query"] = "";');
l.Add('$rcmail_config["smtp_server"] = "127.0.0.1";');
l.Add('$rcmail_config["smtp_port"] = 25;');
l.Add('$rcmail_config["smtp_user"] = "";');
l.Add('$rcmail_config["smtp_pass"] = "";');
l.Add('$rcmail_config["smtp_auth_type"] = "";');
l.Add('$rcmail_config["smtp_helo_host"] = "";');
l.Add('$rcmail_config["smtp_log"] = TRUE;');
l.Add('$rcmail_config["list_cols"] = array("subject", "from", "date", "size");');
l.Add('$rcmail_config["skin_path"] = "skins/default/";');
l.Add('$rcmail_config["skin_include_php"] = FALSE;');
l.Add('$rcmail_config["temp_dir"] = "temp/";');
l.Add('$rcmail_config["log_dir"] = "logs/";');
l.Add('$rcmail_config["session_lifetime"] = 10;');
l.Add('$rcmail_config["ip_check"] = false;');
l.Add('$rcmail_config["double_auth"] = false;');
l.Add('$rcmail_config["des_key"] = "NIbXC7RaFsZvQTV5NWBbQd9H";');
l.Add('$rcmail_config["locale_string"] = "us";');
l.Add('$rcmail_config["date_short"] = "D H:i";');
l.Add('$rcmail_config["date_long"] = "d.m.Y H:i";');
l.Add('$rcmail_config["date_today"] = "H:i";');
l.Add('$rcmail_config["useragent"] = "RoundCube Webmail/0.1-rc2";');
l.Add('$rcmail_config["product_name"] = "RoundCube Webmail for Artica";');
l.Add('$rcmail_config["imap_root"] = "";');
l.Add('$rcmail_config["drafts_mbox"] = "Drafts";');
l.Add('$rcmail_config["junk_mbox"] = "Junk";');
l.Add('$rcmail_config["sent_mbox"] = "Sent";');
l.Add('$rcmail_config["trash_mbox"] = "Trash";');
l.Add('$rcmail_config["default_imap_folders"] = array("INBOX", "Drafts", "Sent", "Junk", "Trash");');
l.Add('$rcmail_config["protect_default_folders"] = TRUE;');
l.Add('$rcmail_config["skip_deleted"] = FALSE;');
l.Add('$rcmail_config["read_when_deleted"] = TRUE;');
l.Add('$rcmail_config["flag_for_deletion"] = TRUE;');
l.Add('$rcmail_config["enable_spellcheck"] = TRUE;');
l.Add('$rcmail_config["spellcheck_uri"] = "";');
l.Add('$rcmail_config["spellcheck_languages"] = NULL;');
l.Add('$rcmail_config["generic_message_footer"] = "";');
l.Add('$rcmail_config["mail_header_delimiter"] = NULL;');
l.Add('$rcmail_config["enable_htmleditor"] = TRUE;');
l.Add('$rcmail_config["dont_override"] = array();');
l.Add('$rcmail_config["javascript_config"] = array("read_when_deleted", "flag_for_deletion");');
l.Add('$rcmail_config["include_host_config"] = FALSE;');
l.Add('$rcmail_config["pagesize"] = 40;');
l.Add('$rcmail_config["timezone"] = intval(date("O"))/100 - date("I");');
l.Add('$rcmail_config["dst_active"] = (bool)date("I");');
l.Add('$rcmail_config["prefer_html"] = TRUE;');
l.Add('$rcmail_config["prettydate"] = TRUE;');
l.Add('$rcmail_config["message_sort_col"] = "date";');
l.Add('$rcmail_config["message_sort_order"] = "DESC";');
l.Add('$rcmail_config["draft_autosave"] = 300;');
l.Add('$rcmail_config["max_pagesize"] = 200;');
l.Add('?>');
l.SaveToFile('/usr/share/roundcube/config/main.inc.php');
l.free;
writeln('creating main.inc.php done...');
fpsystem('/bin/chown -R'+lighttpd.LIGHTTPD_GET_USER()+' /usr/share/roundcube');
end;

end.
