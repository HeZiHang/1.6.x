unit setup_mysql;
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
  tsetup_mysql=class


private
     libs:tlibs;
     distri:tdistriDetect;
     install:tinstall;
     source_folder,cmd:string;




public
      constructor Create();
      procedure Free;
      procedure xinstall();
END;

implementation

constructor tsetup_mysql.Create();
begin
libs:=tlibs.Create;
install:=tinstall.Create;
source_folder:='';
end;
//#########################################################################################
procedure tsetup_mysql.Free();
begin
  libs.Free;
end;
//#########################################################################################
procedure tsetup_mysql.xinstall();
var
   CODE_NAME:string;
   cmd:string;
begin

CODE_NAME:='APP_MYSQL';
SetCurrentDir('/root');



    install.INSTALL_STATUS(CODE_NAME,20);
    install.INSTALL_PROGRESS(CODE_NAME,'{checking}');



if DirectoryExists(ParamStr(2)) then source_folder:=ParamStr(2);
  install.INSTALL_STATUS(CODE_NAME,30);
  install.INSTALL_PROGRESS(CODE_NAME,'{downloading}');

  if length(source_folder)=0 then source_folder:=libs.COMPILE_GENERIC_APPS('mysql-cluster-gpl');
  if not DirectoryExists(source_folder) then begin
     writeln('Install mysql-cluster-gpl failed...');
     install.INSTALL_STATUS(CODE_NAME,110);
     install.INSTALL_PROGRESS(CODE_NAME,'{failed}');
     exit;
  end;

  writeln('Working directory was "'+source_folder+'"');


cmd:='./configure --prefix=/usr';
cmd:=cmd+' --exec-prefix=/usr';
cmd:=cmd+' --libexecdir=/usr/sbin';
cmd:=cmd+' --datadir=/usr/share';
cmd:=cmd+' --localstatedir=/var/lib/mysql';
cmd:=cmd+' --includedir=/usr/include';
cmd:=cmd+' --infodir=/usr/share/info';
cmd:=cmd+' --mandir=/usr/share/man';
cmd:=cmd+' --with-comment="(Artica)"';
cmd:=cmd+' --with-system-type="debian-linux-gnu"';
cmd:=cmd+' --enable-shared';
cmd:=cmd+' --enable-static';
cmd:=cmd+' --enable-thread-safe-client';
cmd:=cmd+' --enable-assembler ';
cmd:=cmd+' --enable-local-infile';
cmd:=cmd+' --with-big-tables';
cmd:=cmd+' --with-unix-socket-path=/var/run/mysqld/mysqld.sock';
cmd:=cmd+' --with-mysqld-user=mysql';
cmd:=cmd+' --with-libwrap';
cmd:=cmd+' --without-docs';
cmd:=cmd+' --with-bench';
cmd:=cmd+' --without-readline';
cmd:=cmd+' --with-extra-charsets=all';
cmd:=cmd+' --with-ndb-ccflags="-fPIC"';
cmd:=cmd+' --with-ndbcluster';
cmd:=cmd+' --without-ndb-sci';
cmd:=cmd+' --without-ndb-test';
cmd:=cmd+' --without-ndb-docs';
  if DirectoryExists('/root/mysql-artica-install') then  fpsystem('/bin/rm -rf /root/mysql-artica-install');
  forceDirectories('/root/mysql-artica-install');
  fpsystem('/bin/cp -rf '+source_folder+'/* /root/mysql-artica-install');

  SetCurrentDir('/root/mysql-artica-install');
  fpsystem(cmd);

  install.INSTALL_STATUS(CODE_NAME,30);
  install.INSTALL_PROGRESS(CODE_NAME,'{compiling}');
  fpsystem('make');
  fpsystem('make install');
  fpsystem('make install');
  SetCurrentDir('/root');
  fpsystem('/bin/rm -rf /root/mysql-artica-install');
  fpsystem('/etc/init.d/artica-postfix restart mysql');
  fpsystem('/usr/share/artica-postfix/bin/artica-install --mysql-upgrade');

  end;
//#########################################################################################


end.
