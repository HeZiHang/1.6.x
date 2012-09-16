unit setup_lmb;
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
  tsetup_lmb=class


private
     libs:tlibs;
     distri:tdistriDetect;
     install:tinstall;
     source_folder,cmd:string;




public
      constructor Create();
      procedure Free;
      procedure xinstall();
      procedure sogo_xinstall();
END;

implementation

constructor tsetup_lmb.Create();
begin
libs:=tlibs.Create;
install:=tinstall.Create;
source_folder:='';
end;
//#########################################################################################
procedure tsetup_lmb.Free();
begin
  libs.Free;
end;
//#########################################################################################
procedure tsetup_lmb.xinstall();
var
   CODE_NAME:string;
   cmd:string;
begin

CODE_NAME:='APP_LMB';
SetCurrentDir('/root');
    install.INSTALL_STATUS(CODE_NAME,20);
    install.INSTALL_PROGRESS(CODE_NAME,'{checking}');

if DirectoryExists(ParamStr(2)) then source_folder:=ParamStr(2);
  install.INSTALL_STATUS(CODE_NAME,30);
  install.INSTALL_PROGRESS(CODE_NAME,'{downloading}');

  if length(source_folder)=0 then source_folder:=libs.COMPILE_GENERIC_APPS('lmb');
  if not DirectoryExists(source_folder) then begin
     writeln('Install '+CODE_NAME+' failed...');
     install.INSTALL_STATUS(CODE_NAME,110);
     install.INSTALL_PROGRESS(CODE_NAME,'{failed}');
     exit;
  end;

  writeln('Working directory was "'+source_folder+'"');

  forcedirectories('/usr/local/share/artica/lmb_src');
  fpsystem('/bin/cp -rf '+source_folder+'/* /usr/local/share/artica/lmb_src/');
  install.INSTALL_STATUS(CODE_NAME,100);
  install.INSTALL_PROGRESS(CODE_NAME,'{installed}');
  fpsystem('/usr/share/artica-postfix/bin/process1 --force setup-lmb');


  end;
//#########################################################################################
procedure tsetup_lmb.sogo_xinstall();
var
   CODE_NAME:string;
   cmd:string;
begin

CODE_NAME:='APP_SOGO';
SetCurrentDir('/root');
    install.INSTALL_STATUS(CODE_NAME,20);
    install.INSTALL_PROGRESS(CODE_NAME,'{checking}');

if DirectoryExists(ParamStr(2)) then source_folder:=ParamStr(2);
  install.INSTALL_STATUS(CODE_NAME,30);
  install.INSTALL_PROGRESS(CODE_NAME,'{downloading}');

  if length(source_folder)=0 then source_folder:=libs.COMPILE_GENERIC_APPS('sogo');
  if not DirectoryExists(source_folder) then begin
     writeln('Install '+CODE_NAME+' failed...');
     install.INSTALL_STATUS(CODE_NAME,110);
     install.INSTALL_PROGRESS(CODE_NAME,'{failed}');
     exit;
  end;

  writeln('Working directory was "'+source_folder+'"');

  forcedirectories('/usr/local/share/artica/lmb_src');
  fpsystem('/bin/cp -rf '+source_folder+'/* /usr/local/share/artica/sogo_src/');
  install.INSTALL_STATUS(CODE_NAME,100);
  install.INSTALL_PROGRESS(CODE_NAME,'{installed}');
  fpsystem('/usr/share/artica-postfix/bin/process1 --force setup-sogo');


  end;
//#########################################################################################


end.
