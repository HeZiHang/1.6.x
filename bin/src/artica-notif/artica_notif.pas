program artica_notif;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils
  { you can add units after this },zsystem,unix,logs;

  var
  SYS:TSystem;
  zlogs:Tlogs;
  D:boolean;
begin
sys:=Tsystem.Create;

if SYS.BuildPids() then begin
   zlogs:=Tlogs.Create;
   zlogs.OutputCmd(SYS.EXEC_NICE()+SYS.LOCATE_PHP5_BIN() + ' /usr/share/artica-postfix/cron.notifs.php');
end;


end.

