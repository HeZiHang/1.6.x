program setup_ubuntu;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils
  { you can add units after this }, setup_ubuntu_class;

  var
     install:tubuntu;
begin

  install:=tubuntu.Create;

end.

