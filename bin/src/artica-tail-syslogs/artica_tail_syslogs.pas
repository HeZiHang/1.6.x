program artica_tail_syslogs;

{$mode objfpc}{$H+}

uses
  libc,Classes, SysUtils
  { you can add units after this }, wthread, wthread3,logs,zsystem;


var
   tt:TSampleThread;
   ti:TSampleThread3;
   zlogs:Tlogs;
   SYS:Tsystem;
begin
        halt(0);

SYS:=Tsystem.Create();
if SYS.BuildPids() then begin
   zlogs:=Tlogs.Create;
   ti:=TSampleThread3.Create();
   tt:=TSampleThread.Create();
   zlogs.Debuglogs('END thread3...');
end;
   halt(0);

end.

