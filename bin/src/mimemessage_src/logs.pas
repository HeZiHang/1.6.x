unit logs;

{$mode objfpc}{$H+}

interface

uses
Classes, SysUtils,variants, Process,IniFiles,oldlinux,md5,RegExpr in 'RegExpr.pas';

  type
  Tlogs=class


private
     GLOBAL_INI:TIniFile;
     function GetFileSizeKo(path:string):longint;
     function MaxSizeLimit:integer;
     MaxlogSize:longint;
     procedure DeleteLogs();
     function SearchAndReplace(sSrc, sLookFor, sReplaceWith: string ): string;

public
    constructor Create;
    procedure Free;
    procedure logs(zText:string);
    function COMMANDLINE_PARAMETERS(FoundWhatPattern:string):boolean;
    Enable_echo:boolean;
    Enable_echo_install:boolean;
    D:boolean;
    module_name:string;
    function FormatHeure (value : Int64) : String;

    PROCEDURE ERRORS(zText:string);
end;

implementation

//-------------------------------------------------------------------------------------------------------


//##############################################################################
constructor Tlogs.Create;

begin
       forcedirectories('/etc/artica-postfix');
       MaxlogSize:=100;
       D:=false;
       D:=COMMANDLINE_PARAMETERS('-V');
       

end;
//##############################################################################
PROCEDURE Tlogs.Free();
begin

end;
//##############################################################################
PROCEDURE Tlogs.ERRORS(zText:string);
      var
        zDate:string;
        myFile : TextFile;
        xText:string;
        TargetPath:string;
        info : stat;
        size:longint;
      BEGIN

        TargetPath:='/var/log/artica-postfix/artica-filter.errors.log';

        forcedirectories('/var/log/artica-postfix');
        zDate:=DateToStr(Date)+ chr(32)+TimeToStr(Time);

        if D then writeln(xText);
        xText:=zDate + ' ' + zText;



        TRY
           if GetFileSizeKo(TargetPath)>MaxlogSize then begin
              ExecuteProcess('/bin/rm','-f ' +  TargetPath);
              xText:=xText + ' (log file was killed before)';
              end;
              EXCEPT
              exit;
        end;

        TRY

           AssignFile(myFile, TargetPath);
           if FileExists(TargetPath) then Append(myFile);
           if not FileExists(TargetPath) then ReWrite(myFile);
            WriteLn(myFile, xText);
           CloseFile(myFile);
        EXCEPT
             //writeln(xtext + '-> error writing ' +     TargetPath);
          END;
      END;
//##############################################################################

function Tlogs.SearchAndReplace(sSrc, sLookFor, sReplaceWith: string ): string;
var
  nPos,
  nLenLookFor : integer;
begin
  nPos        := Pos( sLookFor, sSrc );
  nLenLookFor := Length( sLookFor );
  while(nPos > 0)do
  begin
    Delete( sSrc, nPos, nLenLookFor );
    Insert( sReplaceWith, sSrc, nPos );
    nPos := Pos( sLookFor, sSrc );
  end;
  Result := sSrc;
end;

//##############################################################################
PROCEDURE Tlogs.logs(zText:string);
      var
        zDate:string;
        myFile : TextFile;
        xText:string;
        TargetPath:string;
        info : stat;
        size:longint;
        MyTime:string;
        MyDate:string;
        n:integer;
        PID:string;
        today : TDateTime;
        maintenant : Tsystemtime;
        maintenant_day:String;
        maintenant_day_hour:string;
      BEGIN
        PID:=intTostr(getpid);

        getlocaltime(maintenant);
        maintenant_day:=FormatHeure(maintenant.Year)+'-' +FormatHeure(maintenant.Month)+ '-' + FormatHeure(maintenant.Day);
        maintenant_day_hour:=FormatHeure(maintenant.Hour);
        zDate := maintenant_day+ chr(32)+maintenant_day_hour+':'+FormatHeure(maintenant.minute)+':'+ FormatHeure(maintenant.second);
        today := Now;
        forcedirectories('/var/log/artica-postfix');
        try
        if D then writeln(zText);
        finally
        end;


        TargetPath:='/var/log/artica-postfix/artica-filter.' + maintenant_day + '-' + maintenant_day_hour+'.log';
        xText:=zDate + ' [' + PID + '] ' + zText;
        TRY

           AssignFile(myFile, TargetPath);
           if FileExists(TargetPath) then Append(myFile);
           if not FileExists(TargetPath) then ReWrite(myFile);
            WriteLn(myFile, xText);
           CloseFile(myFile);
        EXCEPT
             writeln(xtext + '-> error writing ' +     TargetPath);
          END;
      END;
      
//##############################################################################

function Tlogs.FormatHeure (value : Int64) : String;
var minus : boolean;
begin
result := '';
if value = 0 then
result := '0';
Minus := value <0;
if minus then
value := -value;
while value >0 do begin
      result := char((value mod 10) + integer('0'))+result;
      value := value div 10;
end;
 if minus then
 result := '-' + result;
 if length(result)=1 then result := '0'+result;
end;
 //##############################################################################

procedure Tlogs.DeleteLogs();
var
        TargetPath:string;
        val_GetFileSizeKo:integer;
begin
   TargetPath:='/var/log/artica-postfix/artica-postfix.log';
  val_GetFileSizeKo:=GetFileSizeKo(TargetPath);
  if D then logs('Tlogs.DeleteLogs() -> ' + IntToStr(val_GetFileSizeKo) + '>? -> ' + IntToStr(MaxlogSize));
  if val_GetFileSizeKo>MaxlogSize then  Shell('/bin/rm -f ' +  TargetPath);

end;
//##############################################################################


function Tlogs.GetFileSizeKo(path:string):longint;
Var
L : File Of byte;
size:longint;
ko:longint;

begin
if not FileExists(path) then begin
   result:=0;
   exit;
end;
   TRY
  Assign (L,path);
  Reset (L);
  size:=FileSize(L);
   Close (L);
  ko:=size div 1024;
  result:=ko;
  EXCEPT

  end;
end;
//##############################################################################
function Tlogs.MaxSizeLimit:integer;
var
     Myini:TIniFile;
     confPath:string;
     SizeLimit:integer;
begin
exit(100);
end;
//##############################################################################
function Tlogs.COMMANDLINE_PARAMETERS(FoundWhatPattern:string):boolean;
var
   i:integer;
   s:string;
   RegExpr:TRegExpr;

begin
 result:=false;
 if ParamCount>0 then begin
     for i:=1 to ParamCount do begin
        s:=s  + ' ' +ParamStr(i);
     end;
 end;
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:=FoundWhatPattern;
   if RegExpr.Exec(s) then begin
      RegExpr.Free;
      result:=True;
   end;


end;

end.

