unit setup_postfix;
{$MODE DELPHI}
//{$mode objfpc}{$H+}
{$LONGSTRINGS ON}
//ln -s /usr/lib/libmilter/libsmutil.a /usr/local/lib/libsmutil.a
//apt-get install libmilter-dev
interface

uses
  Classes, SysUtils,strutils,RegExpr in 'RegExpr.pas',
  unix,IniFiles,setup_libs,distridetect,
  setup_suse_class,postfix_class,zsystem,
  install_generic;

  type
  tpostfix_install=class


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
   postfix:tpostfix;
   SYS:Tsystem;



public
      constructor Create();
      procedure Free;
      procedure xinstall();
END;

implementation

constructor tpostfix_install.Create();
begin
libs:=tlibs.Create;
install:=tinstall.Create;
source_folder:='';
SYS:=Tsystem.Create();
end;
//#########################################################################################
procedure tpostfix_install.Free();
begin
  libs.Free;
end;
//#########################################################################################
procedure tpostfix_install.xinstall();
var
   CODE_NAME:string;
   intversion:integer;
   remoteversion:string;
   remoteint:integer;
   include_openssl:string;
   include_sasl:string;
   include_cdb:string;
begin


    CODE_NAME:='APP_POSTFIX';
    postfix:=Tpostfix.Create(SYS);
    intversion:=postfix.POSTFIX_INT_VERSION(postfix.POSTFIX_VERSION());
    remoteversion:=libs.COMPILE_VERSION_STRING('postfix');
    if length(remoteversion)=0 then remoteversion:='0';
    remoteint:=postfix.POSTFIX_INT_VERSION(remoteversion);

    writeln('Current Postfix version ',intversion);
    writeln('remote Postfix version ',remoteint);



  if remoteint<intversion then begin
     writeln('Install '+CODE_NAME+' up-to-date...');
     install.INSTALL_STATUS(CODE_NAME,100);
     exit;
  end;

  SetCurrentDir('/root');

  if FileExists('/usr/include/openssl/ssl.h') then  include_openssl:='/usr/include/openssl';
  if FileExists('/usr/include/sasl/sasl.h') then include_sasl:='/usr/include/sasl';
  if FileExists('/usr/include/cdb.h') then include_cdb:='/usr/include';



  if length(include_openssl)=0 then fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
  if length(include_sasl)=0 then fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
  if length(include_cdb)=0 then fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');

  if FileExists('/usr/include/openssl/ssl.h') then  include_openssl:='/usr/include/openssl';
  if FileExists('/usr/include/sasl/sasl.h') then include_sasl:='/usr/include/sasl';
  if FileExists('/usr/include/cdb.h') then include_cdb:='/usr/include';

 if length(include_openssl)=0 then begin
     writeln('Failed to find ssl.h');
     install.INSTALL_STATUS(CODE_NAME,110);
     exit;
  end;

  if length(include_sasl)=0 then begin
     writeln('Failed to find sasl.h');
     install.INSTALL_STATUS(CODE_NAME,110);
     exit;
  end;


  if DirectoryExists(ParamStr(2)) then source_folder:=ParamStr(2);

  install.INSTALL_STATUS(CODE_NAME,10);
  install.INSTALL_STATUS(CODE_NAME,30);
  install.INSTALL_PROGRESS(CODE_NAME,'{downloading}');

  if length(source_folder)=0 then source_folder:=libs.COMPILE_GENERIC_APPS('postfix');



  if not DirectoryExists(source_folder) then begin
     writeln('Install '+CODE_NAME+' failed...');
     install.INSTALL_STATUS(CODE_NAME,110);
     exit;
  end;





  writeln('Install '+CODE_NAME+' extracted on "'+source_folder+'"');
  install.INSTALL_STATUS(CODE_NAME,50);
  install.INSTALL_PROGRESS(CODE_NAME,'{compiling}');

  SetCurrentDir(source_folder);
  fpsystem('make tidy');


  fpsystem('/bin/mv /usr/sbin/sendmail /usr/sbin/sendmail.OFF >/dev/null');
  fpsystem('/bin/mv /usr/bin/newaliases /usr/bin/newaliases.OFF >/dev/null');
  fpsystem('/bin/mv /usr/bin/mailq /usr/bin/mailq.OFF >/dev/null');
  fpsystem('/bin/chmod 755 /usr/sbin/sendmail.OFF /usr/bin/newaliases.OFF /usr/bin/mailq.OFF >/dev/null');


  cmd:='/usr/bin/make makefiles CCARGS="-I/usr/include/libmilter -I/usr/include -I/usr/local/include -I/usr/include/sm/os';
  cmd:=cmd+' -DMAX_DYNAMIC_MAPS';
  cmd:=cmd+' -DMYORIGIN_FROM_FILE';
  cmd:=cmd+' -D_LARGEFILE_SOURCE';
  cmd:=cmd+' -D_FILE_OFFSET_BITS=64';
//  if length(include_cdb)>0 then cmd:=cmd+' -DHAS_CDB';
  cmd:=cmd+' -DHAS_LDAP';
  cmd:=cmd+' -DHAS_SSL -I'+include_openssl;
  cmd:=cmd+' -DUSE_SASL_AUTH -I'+include_sasl;
  cmd:=cmd+' -DUSE_CYRUS_SASL';
  cmd:=cmd+' -DUSE_TLS"';
  cmd:=cmd+' DEBUG=';
  cmd:=cmd+' AUXLIBS="-L/lib -L/usr/local/lib -L/usr/lib/libmilter -L/usr/lib -lldap -L/usr/lib -llber -lssl -lcrypto -lsasl2" OPT="-O2"';

  writeln(cmd);

  fpsystem(cmd);

  install.INSTALL_PROGRESS(CODE_NAME,'{installing}');
  install.INSTALL_STATUS(CODE_NAME,80);
  fpsystem('make upgrade');
  fpsystem('/bin/rm -f /etc/artica-postfix/versions.cache');
  if postfix.POSTFIX_INT_VERSION(postfix.POSTFIX_VERSION())=remoteint then begin
       install.INSTALL_STATUS(CODE_NAME,100);
       install.INSTALL_PROGRESS(CODE_NAME,'{success}');
       writeln('');
       writeln('');
       writeln('');
       writeln('success');
       writeln('');
  end else begin
      install.INSTALL_STATUS(CODE_NAME,110);
       install.INSTALL_PROGRESS(CODE_NAME,'{failed}');
       writeln('');
       writeln('');
       writeln('');
       writeln('failed');
       writeln('');
  end;

  SetCurrentDir('/root');
  fpsystem('/etc/init.d/artica-postfix restart postfix');

end;
//#########################################################################################


end.
