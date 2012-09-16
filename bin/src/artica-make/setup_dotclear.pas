unit setup_dotclear;
{$MODE DELPHI}
//{$mode objfpc}{$H+}
{$LONGSTRINGS ON}
//ln -s /usr/lib/libmilter/libsmutil.a /usr/local/lib/libsmutil.a
//apt-get install libmilter-dev
interface

uses
  Classes, SysUtils,strutils,RegExpr in 'RegExpr.pas',
  unix,IniFiles,setup_libs,distridetect,
  setup_suse_class,
  install_generic,
  setup_ubuntu_class,logs;

  type
  dotclear=class


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

public
      constructor Create();
      procedure Free;
      procedure xinstall();
END;

implementation

constructor dotclear.Create();
begin
distri:=tdistriDetect.Create();
libs:=tlibs.Create;
install:=tinstall.Create;
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
procedure dotclear.Free();
begin
  libs.Free;
end;
//#########################################################################################
procedure dotclear.xinstall();
var
   logs:Tlogs;
begin

  SetCurrentDir('/tmp');

if DirectoryExists(ParamStr(2)) then source_folder:=ParamStr(2);
install.INSTALL_STATUS('APP_DOTCLEAR',10);
install.INSTALL_STATUS('APP_DOTCLEAR',30);

  if length(source_folder)=0 then source_folder:=libs.COMPILE_GENERIC_APPS('dotclear');
  if not DirectoryExists(source_folder) then begin
     writeln('Install dotclear failed...');
     install.INSTALL_STATUS('APP_DOTCLEAR',110);
     exit;
  end;
  SetCurrentDir(source_folder);
  if DirectoryExists('/usr/share/dotclear') then fpsystem('/bin/rm -rf /usr/share/dotclear');
  forceDirectories('/usr/share/dotclear');
  fpsystem('/bin/cp -rfv '+source_folder+'/* /usr/share/dotclear/');
  
  fpsystem('/bin/chmod -R 777 /usr/share/dotclear/cache');
  fpsystem('/bin/chmod -R 777 /usr/share/dotclear/public');
  install.INSTALL_STATUS('APP_DOTCLEAR',100);

end;
//#########################################################################################


end.
