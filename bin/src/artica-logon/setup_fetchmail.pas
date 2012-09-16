unit setup_fetchmail;
{$MODE DELPHI}
//{$mode objfpc}{$H+}
{$LONGSTRINGS ON}
//ln -s /usr/lib/libmilter/libsmutil.a /usr/local/lib/libsmutil.a
//apt-get install libmilter-dev
interface

uses
  Classes, SysUtils,strutils,RegExpr in 'RegExpr.pas',
  unix,IniFiles,setup_libs,distridetect,fetchmail,zsystem,
  install_generic;

  type
  install_fetchmail=class


private
     libs:tlibs;
     distri:tdistriDetect;
     install:tinstall;
     source_folder,cmd:string;
     SYS:Tsystem;




public
      constructor Create();
      procedure Free;
      procedure xinstall();
END;

implementation

constructor install_fetchmail.Create();
begin
distri:=tdistriDetect.Create();
libs:=tlibs.Create;
install:=tinstall.Create;
source_folder:='';
sys:=Tsystem.Create();
end;
//#########################################################################################
procedure install_fetchmail.Free();
begin
  libs.Free;
end;
//#########################################################################################
procedure install_fetchmail.xinstall();
var
   ftech:tfetchmail;
begin



if DirectoryExists(ParamStr(2)) then source_folder:=ParamStr(2);
install.INSTALL_STATUS('APP_FETCHMAIL',10);


  SetCurrentDir('/root');
  install.INSTALL_STATUS('APP_FETCHMAIL',30);
  install.INSTALL_PROGRESS('APP_FETCHMAIL','{downloading}');

  if length(source_folder)=0 then source_folder:=libs.COMPILE_GENERIC_APPS('fetchmail');
  if not DirectoryExists(source_folder) then begin
     writeln('Install fetchmail failed...');
     install.INSTALL_STATUS('APP_FETCHMAIL',110);
     exit;
  end;
  writeln('Install fetchmail extracted on "'+source_folder+'"');
  install.INSTALL_STATUS('APP_FETCHMAIL',50);
    install.INSTALL_PROGRESS('APP_FETCHMAIL','{compiling}');
    SetCurrentDir(source_folder);
    fpsystem('./configure  --prefix=/usr --enable-nls --enable-fallback=no  --with-ssl=/usr --with-gssapi=/usr');
    fpsystem('make');


    install.INSTALL_PROGRESS('APP_FETCHMAIL','{installing}');
    fpsystem('make install');

    if FileExists('/usr/bin/fetchmail') then begin
         install.INSTALL_STATUS('APP_FETCHMAIL',100);
         install.INSTALL_PROGRESS('APP_FETCHMAIL','{installed}');
         ftech:=tfetchmail.Create(sys);
         ftech.FETCHMAIL_DAEMON_STOP();
         ftech.FETCHMAIL_START_DAEMON();
         ftech.Free;
         SYS.Free;
    end else begin
         install.INSTALL_PROGRESS('APP_FETCHMAIL','{failed}');
         install.INSTALL_STATUS('APP_FETCHMAIL',110);
    end;

    SetCurrentDir('/root');

end;
//#########################################################################################


end.
