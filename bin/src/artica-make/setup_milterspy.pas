unit setup_milterspy;
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
  setup_ubuntu_class;

  type
  milterspy=class


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

constructor milterspy.Create();
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
procedure milterspy.Free();
begin
  libs.Free;
end;
//#########################################################################################
procedure milterspy.xinstall();
begin



if DirectoryExists(ParamStr(2)) then source_folder:=ParamStr(2);
install.INSTALL_STATUS('APP_MAILSPY',10);



  install.INSTALL_STATUS('APP_MAILSPY',30);
  install.INSTALL_PROGRESS('APP_MAILSPY','{downloading}');

  if length(source_folder)=0 then source_folder:=libs.COMPILE_GENERIC_APPS('mailspy');
  if not DirectoryExists(source_folder) then begin
     writeln('Install mailspy failed...');
     install.INSTALL_STATUS('APP_MAILSPY',110);
     exit;
  end;
  writeln('Install simple mailspy extracted on "'+source_folder+'"');
  install.INSTALL_STATUS('APP_MAILSPY',50);
    install.INSTALL_PROGRESS('APP_MAILSPY','{compiling}');
  fpsystem('cd ' + source_folder + ' && make CFLAGS="-L/usr/lib/libmilter -L/lib -L/usr/lib -L/usr/local/lib" && make install');

  if FileExists('/usr/local/bin/mailspy') then begin
      install.INSTALL_STATUS('APP_MAILSPY',100);
      writeln('Success');
    install.INSTALL_PROGRESS('APP_MAILSPY','{installing}');
      fpsystem('/etc/init.d/artica-postfix restart mailspy');
      fpsystem('/etc/init.d/artica-postfix restart mailspy');
    install.INSTALL_PROGRESS('APP_MAILSPY','{installed}');
  end else begin
      install.INSTALL_PROGRESS('APP_MAILSPY','{failed}');
      install.INSTALL_STATUS('APP_MAILSPY',110);
      writeln('Failed');
  end;

end;
//#########################################################################################


end.
