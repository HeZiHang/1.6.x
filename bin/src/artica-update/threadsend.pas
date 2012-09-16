unit ThreadSend;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,variants, oldlinux,Process,strutils,logs,dateutils;
type
  TTFilter=class(TThread)
  private
    LOGS:Tlogs;
    procedure ScanQueue();
    function DirFiles(FilePath: string;pattern:string):TstringList;
    function get_ARTICA_PHP_PATH():string;
    DirListFiles:TStringList;
    debug:boolean;
    PHP_PATH:string;
    function GetFileSizeKo(path:string):longint;
  protected
    procedure Execute; override;



  public

    constructor Create;
    end;

implementation

//##############################################################################
procedure TTFilter.Execute;
var count:integer;
CacheQueue:integer;
IpInterface:integer;
begin

         LOGS.logs('Thread1:: Initialized');
     while not terminated do begin

              Select(0,nil,nil,nil,10*100);
              ScanQueue();


           end;


     LOGS.logs('Terminating thread 1...');

end;

//##############################################################################
constructor TTFilter.Create;
begin
   inherited Create(False);
   forcedirectories('/etc/artica-postfix');

   LOGS:=Tlogs.Create;

   FreeOnTerminate := True;
    LOGS.logs('TTFilter:: Starting Thread Number 1..');
end;

//##############################################################################
procedure TTFilter.ScanQueue();
var
   AProcess: TProcess;
   ToolPath:string;
begin
     DirFiles('/usr/share/artica-filter/queue','*.queue');
     ToolPath:=get_ARTICA_PHP_PATH() + '/bin/artica-send';
     if DirListFiles.Count>0 then begin
       if FileExists(ToolPath) then begin
        AProcess := TProcess.Create(nil);
        AProcess.CommandLine := ToolPath;
        AProcess.Options := AProcess.Options + [poWaitOnExit];
        AProcess.Execute;
        AProcess.Free;
        end;
     end;

end;
//##############################################################################
function TTFilter.GetFileSizeKo(path:string):longint;
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
function TTFilter.DirFiles(FilePath: string;pattern:string):TstringList;
Var Info : TSearchRec;
    Count : Longint;
    D:boolean;
Begin

  Count:=0;
  If FindFirst (FilePath+'/'+ pattern,faAnyFile,Info)=0 then begin
    Repeat
      if Info.Name<>'..' then begin
         if Info.Name <>'.' then begin
           DirListFiles.Add(FilePath + '/' + Info.Name);

         end;
      end;

    Until FindNext(info)<>0;
    end;
  FindClose(Info);
  exit();
end;
//#########################################################################################
function TTFilter.get_ARTICA_PHP_PATH():string;
var path:string;
begin
  if not DirectoryExists('/usr/share/artica-postfix') then begin
  path:=ParamStr(0);
  path:=ExtractFilePath(path);
  path:=AnsiReplaceText(path,'/bin/','');
  exit(path);
  end else begin
  exit('/usr/share/artica-postfix');
  end;

end;
end.

