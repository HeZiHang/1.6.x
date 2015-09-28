unit setup_obm;
{$MODE DELPHI}
//{$mode objfpc}{$H+}
{$LONGSTRINGS ON}
//ln -s /usr/lib/libmilter/libsmutil.a /usr/local/lib/libsmutil.a
//apt-get install libmilter-dev
interface

uses
  Classes, SysUtils,strutils,RegExpr in 'RegExpr.pas',
  unix,IniFiles,setup_libs,distridetect,
  install_generic,logs,obm,zsystem;

  type
  tobm_install=class


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

constructor tobm_install.Create();
begin
distri:=tdistriDetect.Create();
libs:=tlibs.Create;
install:=tinstall.Create;
source_folder:='';
end;
//#########################################################################################
procedure tobm_install.Free();
begin
  libs.Free;
end;
//#########################################################################################
procedure tobm_install.xinstall();
var
source_folder:string;
logs:Tlogs;
SYS:TSystem;
zobm:tobm;
begin

 logs:=Tlogs.Create;
 SYS:=Tsystem.Create();
 zobm:=tobm.Create(SYS);


if DirectoryExists(ParamStr(2)) then source_folder:=ParamStr(2);
install.INSTALL_STATUS('APP_OBM',10);
install.INSTALL_PROGRESS('APP_OBM','{downloading}');
source_folder:=libs.COMPILE_GENERIC_APPS('obm');
  if not DirectoryExists(source_folder) then begin
     writeln('Install obm failed...');
     install.INSTALL_STATUS('APP_OBM',110);
     exit;
  end;
  install.INSTALL_STATUS('APP_OBM',30);
  writeln('Install OBM extracted on "'+source_folder+'"');
  install.INSTALL_STATUS('APP_OBM',50);
  install.INSTALL_PROGRESS('APP_OBM','{installing}');
  forcedirectories('/usr/share/obm');
  fpsystem('/bin/cp -rfv ' + source_folder + '/* /usr/share/obm');

  
  
  writeln('Check OBM database....');
  if not logs.IF_DATABASE_EXISTS('obm') then begin
      writeln('Create OBM database....');
      if not FIleExists('/usr/share/obm/scripts/2.1/create_obmdb_2.1.mysql.sql') then begin
           writeln('Check OBM database failed unable to stat /usr/share/obm/scripts/2.1/create_obmdb_2.1.mysql.sql');
           install.INSTALL_STATUS('APP_OBM',110);
           exit;
      end;
      
      logs.EXECUTE_SQL_FILE('/usr/share/obm/scripts/2.1/create_obmdb_2.1.mysql.sql','obm');
      logs.EXECUTE_SQL_FILE('/usr/share/obm/scripts/2.1/obmdb_default_values_2.1.sql','obm');
      logs.EXECUTE_SQL_FILE('/usr/share/obm/scripts/2.1/obmdb_prefs_values_2.1.sql','obm');
      logs.EXECUTE_SQL_FILE('/usr/share/obm/scripts/2.1/obmdb_test_values_2.1.sql','obm');
      logs.EXECUTE_SQL_FILE('/usr/share/obm/scripts/2.1/data-en/obmdb_nafcode_2.1.sql','obm');
      logs.EXECUTE_SQL_FILE('/usr/share/obm/scripts/2.1/data-en/obmdb_ref_2.1.sql','obm');
      install.INSTALL_STATUS('APP_OBM',60);
      
  end else begin
     writeln('update OBM database....');
     logs.EXECUTE_SQL_FILE('/usr/share/obm/scripts/2.1/update-2.0-2.1.mysql.sql','obm');
     install.INSTALL_STATUS('APP_OBM',60);
  end;
  
  
  SYS.set_INFO('OBMEnabled','1');
  zobm.LIGHTTPD_CONF();
  zobm.SERVICE_START();
  install.INSTALL_STATUS('APP_OBM',100);
  install.INSTALL_PROGRESS('APP_OBM','{installed}');
  
  



end;
//#########################################################################################


end.
