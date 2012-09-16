unit roundcube_install;
{$MODE DELPHI}
//{$mode objfpc}{$H+}
{$LONGSTRINGS ON}

interface

uses
  Classes, SysUtils,strutils,
  RegExpr in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/RegExpr.pas',
  logs in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/logs.pas',
  zsystem in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/zsystem.pas',
  roundcube ,
  install_generic,
  lighttpd;
  type
  troundcubei=class


private
       LOGS:Tlogs;
       SYS:Tsystem;
       artica_path:string;
       roundcube:troundcube;
       lighttpd:Tlighttpd;
       procedure main_inc_php();


public
      constructor Create();
      procedure Free;
      procedure uninstall();
      procedure install();
      procedure ConfigDB();

END;

implementation

constructor troundcubei.Create();
begin
       forcedirectories('/etc/artica-postfix');
       LOGS:=tlogs.Create();
       SYS:=Tsystem.Create;
       roundcube:=troundcube.Create(SYS);
       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;
end;
//############################################################################
procedure troundcubei.Free();
begin
   SYS.Free;
   logs.Free;
   roundcube.Free;
end;
//############################################################################
procedure troundcubei.uninstall();
var
   l:TstringList;
   i:integer;

begin
 if FileExists('/var/log/artica-postfix/artica-roundcube.debug') then logs.DeleteFile('/var/log/artica-postfix/artica-roundcube.debug');
l:=TstringList.Create;

 logs.Debuglogs('-------- Deleting files & directories --------');

l.Add('/usr/share/roundcube');
l.add('/var/log/roundcube');
l.add('/usr/share/dbconfig-common/data/roundcube');
l.add('/usr/share/doc/roundcube-core');
l.add('/usr/share/doc/roundcube');
l.add('/var/lib/roundcube');
l.add('/etc/roundcube');
l.add(artica_path+'/webmail');

for i:=0 to l.Count-1 do begin
    logs.OutputCmd('/bin/rm -rf ' + l.Strings[i]);
end;
 logs.Debuglogs('-------- updating Artica --------');
 logs.OutputCmd(artica_path+'/bin/process1 --checkout');
logs.Debuglogs('Success delete RoundCube eMail System');
logs.OutputCmd('/bin/chmod 755 /var/log/artica-postfix/artica-roundcube.debug');
end;
//############################################################################
procedure troundcubei.ConfigDB();
begin
roundcube.DEBIAN_CONFIG();
end;


procedure troundcubei.install();
var
   zinstall:tinstall;
   Path:string;
   filenname:string;
begin
 if FileExists('/var/log/artica-postfix/artica-roundcube.debug') then logs.DeleteFile('/var/log/artica-postfix/artica-roundcube.debug');
 zinstall:=tinstall.Create();
 lighttpd:=Tlighttpd.Create(SYS);
 logs.INSTALL_STATUS('APP_ROUNDCUBE',50);
 Path:=zinstall.COMPILE_GENERIC('roundcubemail');
 logs.INSTALL_STATUS('APP_ROUNDCUBE',60);
 logs.Debuglogs('Sources was stored in '+Path);
 if not DirectoryExists(Path) then begin
   logs.Debuglogs('Installation failed, unable to stat sources...');
 end;
 ForceDirectories('/usr/share/roundcube');
 logs.OutputCmd('/bin/cp -rf '+Path+'/* /usr/share/roundcube/');
 
 logs.Debuglogs('');
 logs.Debuglogs('-------- Creating folder security settings --------');
 logs.OutputCmd('/bin/chmod -R 0755 /usr/share/roundcube/temp');
 logs.OutputCmd('/bin/chmod -R 0755 /usr/share/roundcube/logs');
 logs.OutputCmd('/bin/chown -R www-data:www-data /usr/share/roundcube');
 logs.Debuglogs('');
 roundcube.DEBIAN_CONFIG();
 
 
 
 logs.Debuglogs('');
 logs.Debuglogs('-------- Creating Databases and Tables in Mysql --------');
 filenname:='/usr/share/roundcube/SQL/mysql.initial.sql';
 if not FileExists('/usr/share/roundcube/SQL/mysql.initial.sql') then begin
    logs.Debuglogs('install()::unable to stat ' + filenname );
     logs.INSTALL_STATUS('APP_ROUNDCUBE',110);
    exit;
 end;
 
 if not logs.EXECUTE_SQL_FILE(filenname,'roundcubemail') then begin
    logs.Debuglogs('install():: there is a problem while creating tables with '+filenname);
    logs.INSTALL_STATUS('APP_ROUNDCUBE',110);
    exit;
 end;
 
 filenname:='/usr/share/roundcube/SQL/mysql.update.sql';
 if FileExists(filenname) then begin
    if not logs.EXECUTE_SQL_FILE(filenname,'roundcubemail') then begin
       logs.Debuglogs('install():: there is a problem while creating tables with '+filenname);
       logs.INSTALL_STATUS('APP_ROUNDCUBE',110);
       exit;
    end;
 end;
 logs.INSTALL_STATUS('APP_ROUNDCUBE',70);
 logs.Debuglogs('');
 logs.Debuglogs('-------- Linking RoundCube to Artica --------');
 logs.OutputCmd('/bin/ln -s /usr/share/roundcube /usr/share/artica-postfix/webmail');
 logs.OutputCmd('/bin/ln -s --force /usr/share/roundcube /var/lib/roundcube');
 logs.OutputCmd('/bin/ln -s --force /usr/share/roundcube/config/db.inc.php /etc/roundcube/debian-db.php');
 logs.Debuglogs('');
 
 main_inc_php();
 
 logs.Debuglogs('-------- Rebuild settings --------');
 logs.OutputCmd(artica_path+'/bin/artica-ldap -modules --verbose');
 logs.Debuglogs('-------- Updating Artica --------');
 logs.INSTALL_STATUS('APP_ROUNDCUBE',80);
 logs.OutputCmd(artica_path+'/bin/process1 --checkout');
 logs.OutputCmd('/bin/chmod 755 /var/log/artica-postfix/artica-roundcube.debug');
 logs.INSTALL_STATUS('APP_ROUNDCUBE',100);
end;
//############################################################################

procedure troundcubei.main_inc_php();
var
l:TstringList;
begin

l:=TstringList.Create;
logs.Debuglogs('creating main.inc.php...');
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
logs.Debuglogs('creating main.inc.php done...');
logs.OutputCmd('/bin/chown -R www-data:www-data /usr/share/roundcube');
end;

end.
