unit isoqlog;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,Process,logs,unix,
    RegExpr      in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/RegExpr.pas',
    zsystem      in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/zsystem.pas';



  type
  tisoqlog=class


private
     LOGS:Tlogs;
     SYS:TSystem;
     artica_path:string;

public
    procedure   Free;
    constructor Create(const zSYS:Tsystem);
    function    VERSION():string;
    function    BIN_PATH():string;
    procedure   performStatistics();
END;

implementation

constructor tisoqlog.Create(const zSYS:Tsystem);
begin
       forcedirectories('/etc/artica-postfix');
       LOGS:=tlogs.Create();
       SYS:=zSYS;


       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;
end;
//##############################################################################
procedure tisoqlog.free();
begin
    logs.Free;
end;
//##############################################################################
function tisoqlog.BIN_PATH():string;
begin
   if FileExists('/usr/local/bin/isoqlog') then exit('/usr/local/bin/isoqlog');

end;
//##############################################################################

function tisoqlog.VERSION():string;
var
    RegExpr:TRegExpr;
    FileDatas:TStringList;
    i:integer;
    filetmp:string;
begin
filetmp:=logs.FILE_TEMP();
if not FileExists(BIN_PATH()) then exit;
fpsystem(BIN_PATH()+' -v >'+filetmp+' 2>&1');
    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='Isoqlog\s+([0-9\.]+)';
    FileDatas:=TStringList.Create;
    FileDatas.LoadFromFile(filetmp);
    logs.DeleteFile(filetmp);
    for i:=0 to FileDatas.Count-1 do begin
        if RegExpr.Exec(FileDatas.Strings[i]) then begin
             result:=RegExpr.Match[1];
             break;
        end;
    end;
             RegExpr.free;
             FileDatas.Free;

end;
//#############################################################################
procedure tisoqlog.performStatistics();
var
   l:TstringList;
   maillog:string;
   pid:string;
   cmd:string;
begin
 if not FileExists(BIN_PATH()) then begin
    logs.Debuglogs('tisoqlog.performStatistics():: unable to stat isqlog binary...');
    exit;
 end;
   logs.Debuglogs('tisoqlog.performStatistics():: isoqlog is not longer maintain.');
   exit;

 if not FileExists('/etc/artica-postfix/LocalDomains.conf') then begin
    logs.Debuglogs('tisoqlog.performStatistics():: Unable to stat /etc/artica-postfix/LocalDomains.conf');
    exit;
 end;
 
  pid:=SYS.PIDOF(BIN_PATH());
  logs.Debuglogs('tisoqlog.performStatistics():: pid="'+pid+'"');
  if length(pid)>0 then begin
     logs.Debuglogs('tisoqlog.performStatistics():: Another instance running "'+pid+'"');
     exit;
  end;
 
  l:=TstringList.Create;
  l.LoadFromFile('/etc/artica-postfix/LocalDomains.conf');
  logs.Debuglogs('tisoqlog.performStatistics():: Saving local domains...');
  try
     l.SaveToFile('/usr/local/etc/isoqlog.domains');
  except
     logs.Syslogs('tisoqlog.performStatistics():: Unable to save configuration file /usr/local/etc/isoqlog.domains');
     exit;
  end;
  
  l.Free;
  maillog:=SYS.MAILLOG_PATH();
  if not FileExists(maillog) then begin
       logs.Syslogs('tisoqlog.performStatistics():: Unable to stat maillog postfix path');
       exit;
  end;
  
forceDirectories(artica_path+'/ressources/isoqlog');
forceDirectories('/usr/local/share/isoqlog/htmltemp');
  
l:=TstringList.Create;
l.Add('#isoqlog Configuration file ');
l.Add('logtype     = "postfix" 				# log type qmai-multilog, qmail-syslog, sendmail, postfix');
l.Add('logstore    = "'+maillog+'" 				#');
l.Add('domainsfile = "/usr/local/etc/isoqlog.domains" 		# ');
l.Add('outputdir   = "'+artica_path+'/ressources/isoqlog" 			# html output directory');
l.Add('htmldir     = "/usr/local/share/isoqlog/htmltemp"');
l.Add('langfile    = "/usr/local/share/isoqlog/lang/english"');
l.Add('hostname    = "'+SYS.HOSTNAME_g()+'"');
l.Add('maxsender   = 100');
l.Add('maxreceiver = 100');
l.Add('maxtotal    = 100');
l.Add('maxbyte     = 100');
try
l.SaveToFile('/usr/local/etc/isoqlog.conf');
except
logs.Syslogs('tisoqlog.performStatistics():: unable to write file /usr/local/etc/isoqlog.conf');
exit;
end;
  
l.free;
cmd:=SYS.EXEC_NICE()+BIN_PATH()+' &';
logs.Debuglogs('tisoqlog.performStatistics():: Executing parser "'+cmd+'"....');
fpsystem(cmd);
fpsystem('/bin/chmod -R 755 '+artica_path+'/ressources/isoqlog');

end;






end.
