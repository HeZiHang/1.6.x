program artica_du;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils,zsystem
  { you can add units after this };


var sys:tSystem;
    l:Tstringlist;
    i:integer;
    Size:integer;
begin


if not DirectoryExists(paramstr(1)) then begin
    writeln('not a directoy');
end;


sys:=tsystem.Create();

l:=TstringList.Create;
sys.SearchSize:=0;
sys.DirDirRecursive(paramstr(1));
Size:=sys.SearchSize div 1024;

writeln('size:',Size,' ko');


end.

