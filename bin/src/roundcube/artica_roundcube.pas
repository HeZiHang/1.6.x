program artica_roundcube;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils
  { you can add units after this }, roundcube_install;
  
var install:troundcubei;

begin
   install:=troundcubei.Create();
   
   
   if ParamStr(1)='--uninstall' then begin
      install.uninstall();
      halt(0);
   end;
   
   if ParamStr(1)='--install' then begin
      install.install();
      halt(0);
   end;
   
   if ParamStr(1)='--configuredb' then begin
      install.ConfigDB();
      halt(0);
   end;
   
   
   writeln('usage :');
   writeln('--uninstall...............: Remove RoundCubeMail');
   writeln('--install.................: Install RoundCubeMail');
   writeln('--configuredb.............: Set DB config');
   halt(0);

end.

