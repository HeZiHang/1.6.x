unit protocol;

{$mode objfpc}{$H+}

interface

uses
Classes, SysUtils,variants, Process,IniFiles,oldlinux,md5,RegExpr in 'RegExpr.pas';

  type
  Tprotocol=class


private
     GLOBAL_INI:TIniFile;

public
    constructor Create;
    procedure Free;


end;

implementation

//-------------------------------------------------------------------------------------------------------


//##############################################################################
constructor Tprotocol.Create;

begin
       forcedirectories('/etc/artica-postfix');


end;
//##############################################################################
PROCEDURE Tlogs.Free();
begin

end;
//##############################################################################
function Parse.protocols(receive:string):string;
      var
        RegExpr:TRegExpr;
BEGIN

     RegExpr:=TRegExpr.Create;


END;


end.

