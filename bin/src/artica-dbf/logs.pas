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
     PROCEDURE logsModule(zText:string);
     function FormatHeure (value : Int64) : String;
     function SearchAndReplace(sSrc, sLookFor, sReplaceWith: string ): string;

     D:boolean;
public
    constructor Create;
    procedure Free;
    procedure logs(zText:string);
    PROCEDURE logsInstall(zText:string);
    PROCEDURE Debuglogs(zText:string);
    PROCEDURE logsStart(zText:string);
    procedure DeleteLogs();
    Enable_echo:boolean;
    Enable_echo_install:boolean;
    Debug:boolean;
    module_name:string;
    PROCEDURE logsThread(ThreadName:string;zText:string);
    PROCEDURE ERRORS(zText:string);
    PROCEDURE INSTALL_MODULES(application_name:string;zText:string);
    function COMMANDLINE_PARAMETERS(FoundWhatPattern:string):boolean;
    FUNCTION TRANSFORM_DATE_MONTH(zText:string):string;
end;

implementation

//-------------------------------------------------------------------------------------------------------


//##############################################################################
constructor Tlogs.Create;

begin
       forcedirectories('/etc/artica-postfix');
       MaxlogSize:=100;
       if Debug=True then logs('Tlogs.Create [MaxlogSize]=' + IntToStr(MaxlogSize));
       D:=COMMANDLINE_PARAMETERS('-V');

       
end;
//##############################################################################
PROCEDURE Tlogs.Free();
begin
GLOBAL_INI.Free;

end;
//##############################################################################
PROCEDURE Tlogs.logsInstall(zText:string);
      var
        zDate:string;
        myFile : TextFile;
        xText:string;
        TargetPath:string;
        info : stat;
        size:longint;maintenant : Tsystemtime;
      BEGIN
        if Enable_echo=True then writeln(zText);
        if Enable_echo_install then writeln(zText);
        TargetPath:='/var/log/artica-postfix/artica-install.log';

        forcedirectories('/var/log/artica-postfix');
        getlocaltime(maintenant);zDate := FormatHeure(maintenant.Year)+'-' +FormatHeure(maintenant.Month)+ '-' + FormatHeure(maintenant.Day)+ chr(32)+FormatHeure(maintenant.Hour)+':'+FormatHeure(maintenant.minute)+':'+ FormatHeure(maintenant.second);
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
             writeln(xtext + '-> error writing ' +     TargetPath);
          END;
      END;
//#############################################################################
PROCEDURE Tlogs.ERRORS(zText:string);
      var
        zDate:string;
        myFile : TextFile;
        xText:string;
        TargetPath:string;
        info : stat;
        size:longint;maintenant : Tsystemtime;
      BEGIN
        if Enable_echo=True then writeln(zText);
        if Enable_echo_install then writeln(zText);
        TargetPath:='/var/log/artica-postfix/artica-errors.log';

        forcedirectories('/var/log/artica-postfix');
        getlocaltime(maintenant);zDate := FormatHeure(maintenant.Year)+'-' +FormatHeure(maintenant.Month)+ '-' + FormatHeure(maintenant.Day)+ chr(32)+FormatHeure(maintenant.Hour)+':'+FormatHeure(maintenant.minute)+':'+ FormatHeure(maintenant.second);
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
             writeln(xtext + '-> error writing ' +     TargetPath);
          END;
      END;
//#############################################################################
PROCEDURE Tlogs.INSTALL_MODULES(application_name:string;zText:string);
      var
        zDate:string;
        myFile : TextFile;
        xText:string;
        TargetPath:string;
        info : stat;
        size:longint;maintenant : Tsystemtime;

      BEGIN
        D:=COMMANDLINE_PARAMETERS('-verbose');
        if not D then D:=COMMANDLINE_PARAMETERS('setup');
        if not D then D:=COMMANDLINE_PARAMETERS('-install');

        logs(zText);
        TargetPath:='/var/log/artica-postfix/artica-install-' + application_name + '.log';
        if D then writeln(zText);
        forcedirectories('/var/log/artica-postfix');
        getlocaltime(maintenant);zDate := FormatHeure(maintenant.Year)+'-' +FormatHeure(maintenant.Month)+ '-' + FormatHeure(maintenant.Day)+ chr(32)+FormatHeure(maintenant.Hour)+':'+FormatHeure(maintenant.minute)+':'+ FormatHeure(maintenant.second);
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
             writeln(xtext + '-> error writing ' +     TargetPath);
          END;
      END;
//#############################################################################



//##############################################################################
PROCEDURE Tlogs.logsThread(ThreadName:string;zText:string);
      var
        zDate:string;
        myFile : TextFile;
        xText:string;
        TargetPath:string;
        info : stat;
        size:longint;maintenant : Tsystemtime;
      BEGIN

        TargetPath:='/var/log/artica-postfix/artica-thread-' + ThreadName + '.log';

        forcedirectories('/var/log/artica-postfix');
        getlocaltime(maintenant);zDate := FormatHeure(maintenant.Year)+'-' +FormatHeure(maintenant.Month)+ '-' + FormatHeure(maintenant.Day)+ chr(32)+FormatHeure(maintenant.Hour)+':'+FormatHeure(maintenant.minute)+':'+ FormatHeure(maintenant.second);

        if length(module_name)>0 then logsModule(zText);
        xText:=zDate + ' ' + zText;


        if D=True then writeln(zText);


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
PROCEDURE Tlogs.logsStart(zText:string);
      var
        zDate:string;
        myFile : TextFile;
        xText:string;
        TargetPath:string;
        info : stat;
        size:longint;maintenant : Tsystemtime;
      BEGIN

        TargetPath:='/var/log/artica-postfix/start.log';

        forcedirectories('/var/log/artica-postfix');
        getlocaltime(maintenant);zDate := FormatHeure(maintenant.Year)+'-' +FormatHeure(maintenant.Month)+ '-' + FormatHeure(maintenant.Day)+ chr(32)+FormatHeure(maintenant.Hour)+':'+FormatHeure(maintenant.minute)+':'+ FormatHeure(maintenant.second);

        if length(module_name)>0 then logsModule(zText);
        xText:=zDate + ' ' + zText;
        TRY
        EXCEPT
        writeln('unable to write /var/log/artica-postfix/start.log');
        END;

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


//##############################################################################
PROCEDURE Tlogs.logs(zText:string);
      var
        zDate:string;
        myFile : TextFile;
        xText:string;
        TargetPath:string;
        info : stat;
        size:longint;maintenant : Tsystemtime;
      BEGIN

        TargetPath:='/var/log/artica-postfix/artica-postfix.log';

        forcedirectories('/var/log/artica-postfix');
        getlocaltime(maintenant);zDate := FormatHeure(maintenant.Year)+'-' +FormatHeure(maintenant.Month)+ '-' + FormatHeure(maintenant.Day)+ chr(32)+FormatHeure(maintenant.Hour)+':'+FormatHeure(maintenant.minute)+':'+ FormatHeure(maintenant.second);

        if length(module_name)>0 then logsModule(zText);
        xText:=zDate + ' ' + zText;

        TRY
        if Enable_echo=True then writeln(zText);
        EXCEPT
        END;
        
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
//##############################################################################
PROCEDURE Tlogs.Debuglogs(zText:string);
      var
        zDate:string;
        myFile : TextFile;
        xText:string;
        TargetPath:string;
        info : stat;
        size:longint;maintenant : Tsystemtime;
      BEGIN

        TargetPath:='/var/log/artica-postfix/artica-postfix-debug.log';

        forcedirectories('/var/log/artica-postfix');
        getlocaltime(maintenant);zDate := FormatHeure(maintenant.Year)+'-' +FormatHeure(maintenant.Month)+ '-' + FormatHeure(maintenant.Day)+ chr(32)+FormatHeure(maintenant.Hour)+':'+FormatHeure(maintenant.minute)+':'+ FormatHeure(maintenant.second);

        if length(module_name)>0 then logsModule(zText);
        xText:=zDate + ' ' + zText;

        TRY
        if Enable_echo=True then writeln(zText);
        EXCEPT
        END;

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
FUNCTION Tlogs.TRANSFORM_DATE_MONTH(zText:string):string;
begin
  zText:=UpperCase(zText);
  zText:=StringReplace(zText, 'JAN', '01',[rfReplaceAll, rfIgnoreCase]);
  zText:=StringReplace(zText, 'FEB', '02',[rfReplaceAll, rfIgnoreCase]);
  zText:=StringReplace(zText, 'MAR', '03',[rfReplaceAll, rfIgnoreCase]);
  zText:=StringReplace(zText, 'APR', '04',[rfReplaceAll, rfIgnoreCase]);
  zText:=StringReplace(zText, 'MAY', '05',[rfReplaceAll, rfIgnoreCase]);
  zText:=StringReplace(zText, 'JUN', '06',[rfReplaceAll, rfIgnoreCase]);
  zText:=StringReplace(zText, 'JUL', '07',[rfReplaceAll, rfIgnoreCase]);
  zText:=StringReplace(zText, 'AUG', '08',[rfReplaceAll, rfIgnoreCase]);
  zText:=StringReplace(zText, 'SEP', '09',[rfReplaceAll, rfIgnoreCase]);
  zText:=StringReplace(zText, 'OCT', '10',[rfReplaceAll, rfIgnoreCase]);
  zText:=StringReplace(zText, 'NOV', '11',[rfReplaceAll, rfIgnoreCase]);
  zText:=StringReplace(zText, 'DEC', '12',[rfReplaceAll, rfIgnoreCase]);
  result:=zText;
end;


PROCEDURE Tlogs.logsModule(zText:string);
      var
        zDate:string;
        myFile : TextFile;
        xText:string;
        TargetPath:string;
        info : stat;
        size:longint;
        maintenant : Tsystemtime;
      BEGIN

        TargetPath:='/var/log/artica-postfix/' + module_name + '.log';

        forcedirectories('/var/log/artica-postfix');
        getlocaltime(maintenant);zDate := FormatHeure(maintenant.Year)+'-' +FormatHeure(maintenant.Month)+ '-' + FormatHeure(maintenant.Day)+ chr(32)+FormatHeure(maintenant.Hour)+':'+FormatHeure(maintenant.minute)+':'+ FormatHeure(maintenant.second);
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
             writeln(xtext + '-> error writing ' +     TargetPath);
          END;
      END;
//#############################################################################
procedure Tlogs.DeleteLogs();
var
        TargetPath:string;
        val_GetFileSizeKo:integer;
begin
   TargetPath:='/var/log/artica-postfix/artica-postfix.log';
  val_GetFileSizeKo:=GetFileSizeKo(TargetPath);
  if debug then logs('Tlogs.DeleteLogs() -> ' + IntToStr(val_GetFileSizeKo) + '>? -> ' + IntToStr(MaxlogSize));
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
//##############################################################################
end.

