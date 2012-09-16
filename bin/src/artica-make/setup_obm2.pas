unit setup_obm2;
{$MODE DELPHI}
//{$mode objfpc}{$H+}
{$LONGSTRINGS ON}
//ln -s /usr/lib/libmilter/libsmutil.a /usr/local/lib/libsmutil.a
//apt-get install libmilter-dev
interface

uses
  Classes, SysUtils,strutils,RegExpr in 'RegExpr.pas',
  unix,IniFiles,setup_libs,distridetect,postfix_class,zsystem,logs,
  install_generic;

  type
  setupobm2=class


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
   LOGS:Tlogs;
   CountInstall:integer;
   function VERSION(directory:string):string;


public
      constructor Create();
      procedure Free;
      procedure xinstall();


END;

implementation

constructor setupobm2.Create();
begin
libs:=tlibs.Create;
install:=tinstall.Create;
source_folder:='';
logs:=Tlogs.CReate;
SYS:=Tsystem.Create();
if DirectoryExists(ParamStr(2)) then source_folder:=ParamStr(2);
CountInstall:=0;
end;
//#########################################################################################
procedure setupobm2.Free();
begin
  libs.Free;

end;

//#########################################################################################
procedure setupobm2.xinstall();
var
   CODE_NAME:string;
   cmd:string;
   mysql_server,root,password:string;
   xversion:string;
begin

    CODE_NAME:='APP_OBM2';
    xversion:=VERSION('/opt/artica/install/sources/obm');
    writeln('Current version is :'+ xversion);
    xversion:='';
  SetCurrentDir('/root');
  install.INSTALL_STATUS(CODE_NAME,10);
  install.INSTALL_STATUS(CODE_NAME,30);
  install.INSTALL_PROGRESS(CODE_NAME,'{downloading}');
  install.INSTALL_STATUS(CODE_NAME,70);
if length(source_folder)=0 then source_folder:=libs.COMPILE_GENERIC_APPS('obm2');

if not DirectoryExists(source_folder) then begin
    install.INSTALL_PROGRESS(CODE_NAME,'{failed}');
     writeln('Install '+CODE_NAME+' failed...');
     install.INSTALL_STATUS(CODE_NAME,110);
     exit;
end;

install.INSTALL_STATUS(CODE_NAME,75);
install.INSTALL_PROGRESS(CODE_NAME,'{downloading}');
writeln('Source path is :'+ source_folder);
forceDirectories('/opt/artica/install/sources/obm');


fpsystem('/bin/cp -rf '+source_folder+'/* /opt/artica/install/sources/obm');
xversion:=VERSION('/opt/artica/install/sources/obm');
if length(xversion)>0 then begin
   writeln('OBM ',xversion,' correctly installed on repository');
   install.INSTALL_STATUS(CODE_NAME,100);
   install.INSTALL_PROGRESS(CODE_NAME,'{installed}');
end;


end;
//#########################################################################################
function setupobm2.VERSION(directory:string):string;
  var
   RegExpr:TRegExpr;
   x:string;
   tmpstr:string;
   l:TstringList;
   i:integer;
   path:string;
begin


if not FileExists(directory+'/obminclude/global.inc') then begin
   writeln('Unable to stat '+directory+'/obminclude/global.inc obm seems not be installed');
   exit;
end;
     l:=TstringList.Create;
     RegExpr:=TRegExpr.Create;
     l.LoadFromFile(directory+'/obminclude/global.inc');
     RegExpr.Expression:='\$obm_version.+?([0-9\.]+)';
     for i:=0 to l.Count-1 do begin
         if RegExpr.Exec(l.Strings[i]) then begin
            result:=RegExpr.Match[1];
            break;
         end;
     end;
l.Free;
RegExpr.free;
end;
//#############################################################################

end.
