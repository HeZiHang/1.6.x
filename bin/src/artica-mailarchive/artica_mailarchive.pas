program artica_mailarchive;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils,
  mailarchive,
  zsystem in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/zsystem.pas',
  logs in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/logs.pas',
  amavisquar;

{$IFDEF WINDOWS}{$R artica_mailarchive.rc}{$ENDIF}

var
arch:   tmailarchive;
amavis :tamavisquar;
zamavisquar:tamavisquar;
SYS:    Tsystem;
zlogs   :tlogs;

begin



if ParamStr(1)='--release' then begin
    arch:=tmailarchive.Create;
    arch.ReleaseMail(ParamStr(2));
    
end;

halt(0);

if ParamStr(1)='--standard-queue' then begin
   zamavisquar:=tamavisquar.Create();
   zamavisquar.SCAN_AMAVIS_STANDARD_QUEUE();
   halt(0);
end;


if ParamStr(1)='--dup-fw' then begin
 arch:=tmailarchive.Create;
 arch.ForwardMessage(ParamStr(2));
 halt(0);
end;

SYS:=Tsystem.Create;
zlogs:=Tlogs.Create;
if not SYS.MYSQL_STATUS() then begin
  zlogs.Debuglogs('Mysql problem reported...');
  halt(0);
end;


if not SYS.BuildPids() then begin
     zlogs.Debuglogs('Other instance running...');
     halt(0);
end;

if SYS.PROCESS_NUMBER('artica-mailarchive')>2 then begin
      zlogs.Debuglogs('too many instances "2", exiting...');
      halt(0);
end;

     
arch:=tmailarchive.Create;
arch.ParseQueue();
arch.ParseCopyToDomain();
arch.RecipientToAdd();
//amavis:=tamavisquar.Create();
//amavis.ParseQueue();
//amavis.SCAN_AMAVIS_STANDARD_QUEUE();
end.

