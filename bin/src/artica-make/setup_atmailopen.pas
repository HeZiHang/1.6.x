unit setup_atmailopen;
{$MODE DELPHI}
//{$mode objfpc}{$H+}
{$LONGSTRINGS ON}
//ln -s /usr/lib/libmilter/libsmutil.a /usr/local/lib/libsmutil.a
interface

uses
  Classes, SysUtils,strutils,RegExpr in 'RegExpr.pas',
  unix,IniFiles,setup_libs,distridetect,
  setup_suse_class,
  install_generic,
  setup_ubuntu_class,zsystem;

  type
  tatmail=class


private
     libs:tlibs;
     distri:tdistriDetect;
     install:tinstall;
   source_folder,cmd:string;
   webserver_port:string;
   artica_admin:string;
   artica_password:string;
   ldap_suffix:string;
   mysql_server:string;
   mysql_admin:string;
   mysql_password:string;
   ldap_server:string;
   SYS:Tsystem;
   function SetConfigValues(key:string;value:string):boolean;



public
      constructor Create();
      procedure Free;
      procedure xinstall();
      procedure PatchingLogonForm();
      function  SetConfig():boolean;
      function  CreateDatabase():boolean;
END;

implementation

constructor tatmail.Create();
begin
distri:=tdistriDetect.Create();
libs:=tlibs.Create;
install:=tinstall.Create;
SYS:=TSystem.Create();
source_folder:='';
webserver_port:=install.lighttpd.LIGHTTPD_LISTEN_PORT();
   artica_admin:=install.openldap.get_LDAP('admin');
   artica_password:=install.openldap.get_LDAP('password');
   ldap_suffix:=install.openldap.get_LDAP('suffix');
   ldap_server:=install.openldap.get_LDAP('server');
   mysql_server:=install.SYS.MYSQL_INFOS('mysql_server');
   mysql_admin:=install.SYS.MYSQL_INFOS('database_admin');
   mysql_password:=install.SYS.MYSQL_INFOS('password');
end;
//#########################################################################################
procedure tatmail.Free();
begin
  libs.Free;
end;
//#########################################################################################
procedure tatmail.xinstall();
var
   CODE_NAME:string;
begin


     CODE_NAME:='APP_ATOPENMAIL';
     if DirectoryExists(ParamStr(2)) then source_folder:=ParamStr(2);
     install.INSTALL_STATUS('APP_ATOPENMAIL',10);



  install.INSTALL_STATUS('APP_ATOPENMAIL',30);

   install.INSTALL_STATUS(CODE_NAME,40);
  install.INSTALL_PROGRESS(CODE_NAME,'{downloading}');
  if length(source_folder)=0 then source_folder:=libs.COMPILE_GENERIC_APPS('atmailopen');
  if not DirectoryExists(source_folder) then begin
     writeln('Install atmailopen failed...');
     install.INSTALL_PROGRESS(CODE_NAME,'{failed}');
     install.INSTALL_STATUS('APP_ATOPENMAIL',110);
     exit;
  end;
  writeln('Install simple atmailopen extracted on "'+source_folder+'"');
  install.INSTALL_STATUS('APP_ATOPENMAIL',50);

     install.INSTALL_PROGRESS(CODE_NAME,'{installing}');
     install.INSTALL_STATUS('APP_ATOPENMAIL',60);

  writeln('Installing in /usr/share/atmailopen ....');
  ForceDirectories('/usr/share/atmailopen');

  fpsystem('/bin/cp -rf ' + source_folder + '/* /usr/share/atmailopen/');

  if not FileExists('/usr/share/atmailopen/libs/Atmail/Config.php.default') then begin
     writeln('Installing failed to stat /usr/share/atmailopen/libs/Atmail/Config.php.default');
     install.INSTALL_STATUS('APP_ATOPENMAIL',110);
     exit;
  end;

  fpsystem('/bin/chown -R www-data:www-data /usr/share/atmailopen');
  fpsystem('/bin/chmod -R 744 /usr/share/atmailopen');
  if DirectoryExists('/usr/share/artica-postfix/mail') then fpsystem('/bin/rm -f /usr/share/artica-postfix/mail');
  fpsystem('/bin/ln -s /usr/share/atmailopen /usr/share/artica-postfix/mail');
  PatchingLogonForm();
  
  if not SetConfig then begin
       install.INSTALL_STATUS('APP_ATOPENMAIL',110);
       exit;
  end;
  install.INSTALL_STATUS('APP_ATOPENMAIL',90);
  writeln('Creating database and table on '+ mysql_server + ' mysql server');

if not CreateDatabase() then begin
   writeln('failed...');
    install.INSTALL_PROGRESS(CODE_NAME,'{failed}');
   install.INSTALL_STATUS('APP_ATOPENMAIL',110);
   exit;
end;

writeln('success');
    install.INSTALL_PROGRESS(CODE_NAME,'{installed}');
install.INSTALL_STATUS('APP_ATOPENMAIL',100);

end;
//#########################################################################################
procedure tatmail.PatchingLogonForm();
var
   targetfile:string;
   l:TstringList;
   i:integer;
   found:boolean;
   tofind:string;
begin
   writeln('Patching logon form for single imap server');
   targetfile:='/usr/share/atmailopen/html/login-light.html';
   tofind:='<input name="MailServer" type="text" class="logininput" id="MailServer">';
   found:=false;
   if not FileExists(targetfile) then begin
      writeln('unable to sat '+targetfile);
      exit;
   end;
   
   tofind:='<input name="MailServer" type="text" class="logininput" id="MailServer">';
   l:=TstringList.Create;
   l.LoadFromFile(targetfile);
   For i:=0 to l.Count-1 do begin
     if pos(tofind,l.Strings[i])>0 then begin
           writeln('Patching line ' + IntToStr(i));
           l.Strings[i]:=AnsiReplaceText(l.Strings[i],tofind,'<input name="MailServer" type="hidden" class="logininput" id="MailServer" value="127.0.0.1"><strong>Local</strong');
           found:=true;
           break;
     end;
   end;

    if found then l.SaveToFile(targetfile);
    l.free;
end;
//#########################################################################################
function tatmail.SetConfig():boolean;
var
   EnableVirtualDomainsInMailBoxes:integer;
begin
result:=false;
EnableVirtualDomainsInMailBoxes:=0;
if Not FileExists('/usr/share/atmailopen/libs/Atmail/Config.php') then begin
   if Not FileExists('/usr/share/atmailopen/libs/Atmail/Config.php.default') then begin
      writeln('Unable to stat /usr/share/atmailopen/libs/Atmail/Config.php.default');
      exit;
   end;
   
   fpsystem('/bin/cp -r /usr/share/atmailopen/libs/Atmail/Config.php.default /usr/share/atmailopen/libs/Atmail/Config.php');
   fpsystem('/bin/chown www-data:www-data /usr/share/atmailopen/libs/Atmail/Config.php');
end;

if Not FileExists('/usr/share/atmailopen/libs/Atmail/Config.php') then begin
   writeln('Unable to stat /usr/share/atmailopen/libs/Atmail/Config.php');
   exit;
end;

if not TryStrToInt(SYS.GET_INFO('EnableVirtualDomainsInMailBoxes'),EnableVirtualDomainsInMailBoxes) then EnableVirtualDomainsInMailBoxes:=0;



writeln('Set default settings on Config.php');
if not SetConfigValues('installed','1') then exit;
if not SetConfigValues('ldap_server',ldap_server) then exit;
if not SetConfigValues('base_dn',ldap_suffix) then exit;
if not SetConfigValues('ldap_passwd',artica_password) then exit;
if not SetConfigValues('sql_type','mysql') then exit;
if not SetConfigValues('sql_user',mysql_admin) then exit;
if not SetConfigValues('sql_pass',mysql_password) then exit;
if not SetConfigValues('sql_host',mysql_server) then exit;
if not SetConfigValues('install_dir','/usr/share/atmailopen') then exit;
if not SetConfigValues('user_dir','/usr/share/atmailopen') then exit;
if not SetConfigValues('GlobalAbook','1') then exit;
if not SetConfigValues('mailserver','127.0.0.1') then exit;
if not SetConfigValues('smtphost','127.0.0.1') then exit;
if not SetConfigValues('login_rememberme','0') then exit;
if not SetConfigValues('mailserver_auth',IntToStr(EnableVirtualDomainsInMailBoxes)) then exit;
SetConfigValues('footer_msg',SYS.GET_INFO('ATMailFooterMsg'));

result:=true;

end;
//#########################################################################################
function tatmail.SetConfigValues(key:string;value:string):boolean;
var
   targetfile:string;
   l:TstringList;
   i:integer;
   found:boolean;
   RegExpr:TRegExpr;
   newConfig:string;
begin
result:=false;
found:=false;

if not FileExists('/usr/share/atmailopen/libs/Atmail/Config.php') then exit;
l:=TstringList.Create;
RegExpr:=TRegExpr.Create;
RegExpr.Expression:=key+'''\s+=>.+';


newConfig:=''''+key+''' => '''+ value+''',';
l.LoadFromFile('/usr/share/atmailopen/libs/Atmail/Config.php');
For i:=0 to l.Count-1 do begin
    if RegExpr.Exec(l.Strings[i]) then begin
       l.Strings[i]:=newConfig;
       writeln('Starting......: @Mail Editing line ',i, ' for ',key);
       found:=true;
       break;
    end;

end;

if found then begin
   l.SaveToFile('/usr/share/atmailopen/libs/Atmail/Config.php');
end else begin
   writeln('Unable to find ' + key);
end;

 l.free;
 RegExpr.free;
 result:=found;
end;
//#########################################################################################
function tatmail.CreateDatabase():boolean;
var mysql_text:string;
begin
 mysql_text:='/usr/share/atmailopen/install/atmail.mysql';
 if not FileExists(mysql_text) then begin
    writeln('Unable to stat '+ mysql_text);
 end;
 

install.LOGS.Enable_echo:=true;
  if install.LOGS.IF_DATABASE_EXISTS('atmail') then begin
     writeln('Delete Database atmail');
        install.LOGS.QUERY_SQL(pChar('DROP DATABASE atmail;'),'');
   end;
writeln('Creating database atmail and associated tables....');
install.LOGS.EXECUTE_SQL_FILE(mysql_text,'atmail');
result:=true;

end;

end.
