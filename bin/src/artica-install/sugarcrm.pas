unit sugarcrm;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,IniFiles, Process,md5,logs,unix,RegExpr in 'RegExpr.pas',zsystem;

  type
  tsugarcrm=class


private
     LOGS:Tlogs;
     D:boolean;
     GLOBAL_INI:TiniFIle;
     SYS:TSystem;
     artica_path:string;
     ApacheGroupware:integer;


public
    procedure   Free;
    constructor Create(const zSYS:Tsystem);
    function    VERSION(rootpath:string):string;
END;

implementation

constructor tsugarcrm.Create(const zSYS:Tsystem);
begin
       forcedirectories('/etc/artica-postfix');
       LOGS:=tlogs.Create();
       SYS:=zSYS;
       ApacheGroupware:=1;
       if not TryStrToInt(SYS.GET_INFO('ApacheGroupware'),ApacheGroupware) then ApacheGroupware:=1;


       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;
end;
//##############################################################################
procedure tsugarcrm.free();
begin
    FreeAndNil(logs);
end;
//##############################################################################

function tsugarcrm.VERSION(rootpath:string):string;
 var
   RegExpr:TRegExpr;
   x:string;
   tmpstr:string;
   l:TstringList;
   i:integer;
   path:string;
   key:string;
begin



     path:=rootpath+'/sugar_version.php';
     key:=logs.MD5FromString(path);
     if not FileExists(path) then begin
        logs.Debuglogs('tsugarcrm.VERSION():: unable to stat '+ path);
        exit;
     end;


   result:=SYS.GET_CACHE_VERSION(key);
   if length(result)>0 then exit;

   tmpstr:=path;
   if not FileExists(tmpstr) then exit;
   l:=TstringList.Create;
   RegExpr:=TRegExpr.Create;
   l.LoadFromFile(tmpstr);
   RegExpr.Expression:='\$sugar_version.+?([0-9\.a-z]+)';


    logs.Debuglogs('tsugarcrm.VERSION:: '+intToStr(l.Count) + ' lines');
    for i:=0 to l.Count-1 do begin
         if RegExpr.Exec(l.Strings[i]) then begin
            result:=RegExpr.Match[1];
            break;
         end;
     end;
l.Free;
RegExpr.free;
SYS.SET_CACHE_VERSION(key,result);
logs.Debuglogs('tsugarcrm.VERSION:: -> ' + result);
end;
//##############################################################################


end.
