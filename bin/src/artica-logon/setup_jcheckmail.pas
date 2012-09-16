unit setup_jcheckmail;
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
  setup_ubuntu_class,jcheckmail,zSystem;

  type
  jcheckmail=class


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
   jchk:tjcheckmail;
    SYS:Tsystem;

public
      constructor Create();
      procedure Free;
      procedure xinstall();
END;

implementation

constructor jcheckmail.Create();
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
   SYS:=Tsystem.Create();
end;
//#########################################################################################
procedure jcheckmail.Free();
begin
  libs.Free;
end;
//#########################################################################################
procedure jcheckmail.xinstall();
var
   intver1:integer;
   intver2:integer;
begin
  jchk:=tjcheckmail.Create(SYS);
  SetCurrentDir('/tmp');

if FileExists('/usr/sbin/j-chkmail') then begin
   intver1:=jchk.INT_VERSION();
   intver2:=libs.COMPILE_VERSION('jchkmail');
   if intver1<intver2 then begin
      install.INSTALL_STATUS('APP_JCHKMAIL',100);
      writeln('Install j-chkmail already installed...');
      exit;
   end;
end;
if DirectoryExists(ParamStr(2)) then source_folder:=ParamStr(2);
install.INSTALL_STATUS('APP_JCHKMAIL',10);
install.INSTALL_STATUS('APP_JCHKMAIL',30);

  if length(source_folder)=0 then source_folder:=libs.COMPILE_GENERIC_APPS('jchkmail');
  if not DirectoryExists(source_folder) then begin
     writeln('Install jchkmail failed...');
     install.INSTALL_STATUS('APP_JCHKMAIL',110);
     exit;
  end;
  SetCurrentDir(source_folder);
  fpsystem('./configure --with-user=postfix --with-group=postfix && make && make install');
  if FileExists('/usr/sbin/j-chkmail') then begin
       install.INSTALL_STATUS('APP_JCHKMAIL',100);
       SetCurrentDir('/var/jchkmail/cdb');
       fpsystem('make');
       fpsystem('/etc/init.d/artica-postfix restart jcheckmail');
       writeln('');writeln('');writeln('');writeln('');writeln('Success...');writeln('');

  end else begin
       install.INSTALL_STATUS('APP_JCHKMAIL',110);
       writeln('failed');
  end;



end;
//#########################################################################################


end.
