unit setup_bacula;
{$MODE DELPHI}
//{$mode objfpc}{$H+}
{$LONGSTRINGS ON}
//ln -s /usr/lib/libmilter/libsmutil.a /usr/local/lib/libsmutil.a
//apt-get install libmilter-dev
interface

uses
  Classes, SysUtils,strutils,RegExpr in 'RegExpr.pas',
  unix,IniFiles,setup_libs,distridetect,zsystem,
  install_generic;

  type
  install_bacula=class


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



public
      constructor Create();
      procedure Free;
      procedure xinstall();

END;

implementation

constructor install_bacula.Create();
begin
libs:=tlibs.Create;
install:=tinstall.Create;
source_folder:='';
SYS:=Tsystem.Create();
if DirectoryExists(ParamStr(2)) then source_folder:=ParamStr(2);
end;
//#########################################################################################
procedure install_bacula.Free();
begin
  libs.Free;

end;

//#########################################################################################
procedure install_bacula.xinstall();
var
   CODE_NAME:string;
   cmd,mysql_root,mysql_password:string;
begin

    CODE_NAME:='APP_BACULA';


  SetCurrentDir('/root');
  install.INSTALL_STATUS(CODE_NAME,10);
  install.INSTALL_STATUS(CODE_NAME,30);
  install.INSTALL_PROGRESS(CODE_NAME,'{downloading}');

  if length(source_folder)=0 then source_folder:=libs.COMPILE_GENERIC_APPS('bacula');



  if not DirectoryExists(source_folder) then begin
     writeln('Install '+CODE_NAME+' failed...');
     install.INSTALL_STATUS(CODE_NAME,110);
     exit;
  end;

  mysql_root    :=SYS.MYSQL_INFOS('database_admin');
  mysql_password:=SYS.MYSQL_INFOS('database_password');

  if length(mysql_password)>0 then mysql_password:=' --with-db-password='+mysql_password;

  writeln('Install '+CODE_NAME+' extracted on "'+source_folder+'"');
  install.INSTALL_STATUS(CODE_NAME,50);
  install.INSTALL_PROGRESS(CODE_NAME,'{compiling}');

  SetCurrentDir(source_folder);

  cmd:='./configure --config-cache --prefix=/usr --sysconfdir=/etc/bacula --with-scriptdir=/etc/bacula/scripts --sharedstatedir=/var/lib/bacula';
  cmd:=cmd+' --localstatedir=/var/lib/bacula --with-pid-dir=/var/run/bacula --with-smtp-host=localhost --with-working-dir=/var/lib/bacula --with-subsys-dir=/var/lock';
  cmd:=cmd+' --mandir=\${prefix}/share/man --infodir=\${prefix}/share/info --enable-smartalloc --with-tcp-wrappers --with-libiconv-prefix=/usr/include --with-readline=yes';
  cmd:=cmd+' --with-libintl-prefix=/usr/include --without-x';
  cmd:=cmd+' --with-readline=yes --with-mysql --without-postgresql --without-sqlite3 --enable-bwx-console --without-sqlite --with-db-user='+mysql_root+mysql_password;

  writeln(cmd);
  fpsystem(cmd);

  install.INSTALL_PROGRESS(CODE_NAME,'{installing}');
  install.INSTALL_STATUS(CODE_NAME,80);
  fpsystem('make && make install');
  fpsystem('/bin/rm -f /etc/artica-postfix/versions.cache');
  SetCurrentDir('/root');

  if FileExists('/usr/sbin/bacula') then begin
     install.INSTALL_PROGRESS(CODE_NAME,'{installed}');
     install.INSTALL_STATUS(CODE_NAME,100);
     exit;
  end;


     writeln('Install '+CODE_NAME+' failed...');
     install.INSTALL_STATUS(CODE_NAME,110);
     exit;



end;
//#########################################################################################


end.
