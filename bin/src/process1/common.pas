unit common;

{$mode objfpc}{$H+}
interface

uses
Classes, SysUtils,variants, Process,unix,logs,
RegExpr in 'RegExpr.pas',
global_conf in 'global_conf.pas';

  type
  Tcommon=class


private
     GLOBAL_INI:MyConf;
     LOGS:Tlogs;

public
    debug:boolean;
    Enable_echo:boolean;
    procedure Free;
    constructor Create;
    function ls(folder:string):string;
    function lsqueue(folder:string):string;
    function ReadFileIntoString(path:string):string;
    procedure killfile(path:string);
    function ExecPipe(commandline:string;ShowOut:boolean):string;
    function BuildArtica():string;
    function mail_log_path():string;

END;

implementation

constructor Tcommon.Create;

begin
       forcedirectories('/etc/artica-postfix');
       GLOBAL_INI:=MyConf.Create();
       LOGS:=tlogs.Create();
       LOGS.Enable_echo:=Enable_echo;
       LOGS.module_name:='common';

end;

PROCEDURE Tcommon.Free();
begin
GLOBAL_INI.Free;
LOGS.Free;

end;
//##############################################################################
function Tcommon.ls(folder:string):string;
var
  SearchRec: TSearchRec;
  list:string;
  sRes:longint;
  nextt:boolean;
begin
list:='';
   if not (folder[Length(folder)] in ['\', '/']) then folder := folder + '/';
   if Debug=True then LOGS.logs('Tcommon.ls():: -> init(' + folder + ')');

   sRes:=FindFirst(folder+'*', faAnyFile,SearchRec);
   if Debug=True then LOGS.logs('Tcommon.ls():: -> Result ' +IntToStr(sRes));

   repeat
           nextt:=false;

              if (SearchRec.Name = '.') then  nextt:=true;
              if (SearchRec.Name = '..') then  nextt:=true;
              if (trim(SearchRec.Name) = '') then  nextt:=true;
              if (SearchRec.Name[1]='.') then  nextt:=true;
              if nextt=false then begin
                 if Debug=True then LOGS.logs('thProcThread.ls():: ->' +SearchRec.Name);
                 list:=list +  '|' + folder   + SearchRec.Name + '|;';
              end;
    until (FindNext(SearchRec) <> 0);
    FindClose(SearchRec);
    exit(list);
end;
//##############################################################################
function Tcommon.lsqueue(folder:string):string;
var
  SearchRec: TSearchRec;
  list:string;
  sRes:longint;
  nextt:boolean;

begin
list:='';
   if not (folder[Length(folder)] in ['\', '/']) then folder := folder + '/';
   if Debug=True then LOGS.logs('Tcommon.lsqueue():: -> init(' + folder + ')');

   sRes:=FindFirst(folder+'*.tmp', faAnyFile,SearchRec);
   if Debug=True then LOGS.logs('Tcommon.lsqueue():: -> Result ' +IntToStr(sRes));
   if sRes=-1 then exit;

   repeat
           nextt:=false;

              if (SearchRec.Name = '.') then  nextt:=true;
              if (SearchRec.Name = '..') then  nextt:=true;
              if (trim(SearchRec.Name) = '') then  nextt:=true;
              if (SearchRec.Name[1]='.') then  nextt:=true;
              if nextt=false then begin
                 if Debug=True then LOGS.logs('Tcommon.lsqueue():: ->' +SearchRec.Name);
                 list:=list +  '|' + folder   + SearchRec.Name + '|;';
              end;
    until (FindNext(SearchRec) <> 0);
    FindClose(SearchRec);
    exit(list);
end;
//##############################################################################
function Tcommon.ReadFileIntoString(path:string):string;
         const
            CR = #$0d;
            LF = #$0a;
            CRLF = CR + LF;
var
   Afile:text;
   datas:string;
   datas_file:string;
begin
      datas_file:='';
      if not FileExists(path) then begin
        LOGS.logs('Error:thProcThread.ReadFileIntoString -> file not found (' + path + ')');
        exit;

      end;
      TRY
     assign(Afile,path);
     reset(Afile);
     while not EOF(Afile) do
           begin
           readln(Afile,datas);
           datas_file:=datas_file + datas +CRLF;
           end;

close(Afile);
             EXCEPT
              LOGS.logs('Error:thProcThread.ReadFileIntoString -> unable to read (' + path + ')');
           end;
result:=datas_file;


end;
//##############################################################################

procedure Tcommon.killfile(path:string);
Var F : Text;
begin
  LOGS.logs('thProcThread.killfile -> Deleting (' + path + ')');
 if not FileExists(path) then begin
        LOGS.logs('Error:thProcThread.killfile -> file not found (' + path + ')');
        exit;
 end;
TRY
 Assign (F,path);
 Erase (f);
 EXCEPT
 LOGS.logs('Error:thProcThread.killfile -> unable to delete (' + path + ')');
 end;
end;
//##############################################################################

function Tcommon.ExecPipe(commandline:string;ShowOut:boolean):string;
const
  READ_BYTES = 2048;
  CR = #$0d;
  LF = #$0a;
  CRLF = CR + LF;

var
  S: TStringList;
  M: TMemoryStream;
  P: TProcess;
  n: LongInt;
  BytesRead: LongInt;
  xRes:string;

begin
  xRes:='';
  result:='';
  M := TMemoryStream.Create;
  BytesRead := 0;
  P := TProcess.Create(nil);
  P.CommandLine := commandline;
  P.Options := [poUsePipes];
  if ShowOut then WriteLn('-- executing ' + commandline + ' --');
  P.Execute;
  while P.Running do
  begin
    M.SetSize(BytesRead + READ_BYTES);
    n := P.Output.Read((M.Memory + BytesRead)^, READ_BYTES);
    if n > 0
    then begin
      Inc(BytesRead, n);
    end
    else begin
      Sleep(100);
    end;
  end;

  repeat
    M.SetSize(BytesRead + READ_BYTES);
    n := P.Output.Read((M.Memory + BytesRead)^, READ_BYTES);
    if n > 0
    then begin
      Inc(BytesRead, n);
    end;
  until n <= 0;
  if BytesRead > 0 then WriteLn;
  M.SetSize(BytesRead);
  S := TStringList.Create;
  S.LoadFromStream(M);
 if ShowOut then WriteLn('-- linecount = ', S.Count, ' --');
  for n := 0 to S.Count - 1 do
  begin
    if length(S[n])>1 then begin
      //if ShowOut  then WriteLn(IntToStr(n+1) + '.', S[n]);
      xRes:=xRes + S[n] +CRLF;
    end;
  end;
  if ShowOut  then WriteLn(xRes + '-- end --');
  S.Free;
  P.Free;
  M.Free;
end;
//##############################################################################

function Tcommon.BuildArtica():string;
var

   source_directories,version:string;

begin
    writeln('Building artica...');
    result:='';

    source_directories:=GLOBAL_INI.get_ARTICA_PHP_PATH();
    writeln('Specify the source directory [' + source_directories + ']');
    readln(source_directories);
    if length(source_directories)=0 then source_directories:=GLOBAL_INI.get_ARTICA_PHP_PATH();
    if FileExists('/usr/bin/strip') then begin
        writeln('Strip files...');
        fpsystem('/usr/bin/strip -s ' + source_directories + '/bin/artica-install >/tmp/null');
        fpsystem('/usr/bin/strip -s ' + source_directories + '/bin/artica-postfix >/tmp/null');
        fpsystem('/usr/bin/strip -s ' + source_directories + '/bin/install-sql >/tmp/null');
        fpsystem('/bin/rm -rf ' + source_directories + '/bin/*.o >/tmp/null');
        fpsystem('/bin/rm -rf ' + source_directories + '/bin/*.ppu >/tmp/null');
        fpsystem('/bin/rm -rf ' + source_directories + '/ressources/backup');
        fpsystem('/bin/rm -rf ' + source_directories + '/ressources/userdb');
        fpsystem('/bin/rm -rf ' + source_directories + '/ressources/logs/*');
        fpsystem('/bin/rm -rf ' + source_directories + '/ressources/conf/*');
        fpsystem('/bin/rm -rf ' + source_directories + '/aliases');
    end;
    writeln('Specify the version ? [0.0.0]');
    readln(version);
    fpsystem('/bin/tar --force-local -v -p -C ' +source_directories + '/ -rf artica-postfix-' + version + '.tar . >/tmp/null');
    GLOBAL_INI.Free;
    

end;
function Tcommon.mail_log_path():string;
var filedatas,ExpressionGrep:string;
RegExpr:TRegExpr;
begin

if not FileExists('/etc/syslog.conf') then exit;
filedatas:=ReadFileIntoString('/etc/syslog.conf');
   ExpressionGrep:='mail\.=info.+?-([\/a-zA-Z_0-9\.]+)?';
   RegExpr:=TRegExpr.create;
   RegExpr.ModifierI:=True;
   RegExpr.expression:=ExpressionGrep;
   if RegExpr.Exec(filedatas) then  begin
     result:=RegExpr.Match[1];
     RegExpr.Free;
     exit;
   end;
   
   
   ExpressionGrep:='mail\.\*.+?-([\/a-zA-Z_0-9\.]+)?';
   RegExpr.expression:=ExpressionGrep;
   if RegExpr.Exec(filedatas) then   begin
     result:=RegExpr.Match[1];
     RegExpr.Free;
     exit;
   end;
   
  RegExpr.Free;
///usr/bin/rrdtool
end;




end.

