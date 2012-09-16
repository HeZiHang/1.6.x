unit class_backup_share;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,IniFiles, Process,logs,unix,RegExpr in 'RegExpr.pas',zsystem,rdiffbackup,backup;



  type
  tbackupshare=class


private
     LOGS:Tlogs;
     D:boolean;
     SYS:TSystem;
     artica_path:string;
     dar:trdiffbackup;
     backup:tbackup;
     inif:TiniFile;
     function TestIfBackupCanWork():boolean;
     function ParseSyslog():string;
     procedure SendNotif(ok:boolean);
     function MountTarget(server:string;share:string;account:string;password:string;domain:string;mount_path:string):boolean;


public
    procedure   Free;
    constructor Create;
    function ParsingRemoteFolders():boolean;
    procedure SigleMount(number:string);


END;

implementation

constructor tbackupshare.Create;
begin
       forcedirectories('/etc/artica-postfix');
       LOGS:=tlogs.Create();
       SYS:=Tsystem.Create;
       dar:=trdiffbackup.Create;
       backup:=tbackup.Create;


       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;
end;
//##############################################################################
procedure tbackupshare.free();
begin
    logs.Free;
    SYS.Free;
    dar.free;
    backup.free;
end;
//##############################################################################
function tbackupshare.TestIfBackupCanWork():boolean;
begin

result:=false;

  if not FileExists('/etc/artica-postfix/artica-netshares-backup.conf') then begin
     logs.Syslogs('unable to stat /etc/artica-postfix/artica-netshares-backup.conf function is not implemented' );
     exit;
  end;
  
  
  if SYS.GET_INFO('ArticaBackupEnabled')<>'1' then begin
     logs.Syslogs('Artica Backup main function is disabled.. aborting...' );
     exit;
  end;

  if not FileExists(SYS.LOCATE_SMBMOUNT()) then begin
     logs.Syslogs('sbmount tool is not installed or could not stat it''s path...');
     exit;
  end;
  
  if not FileExists(dar.dar_bin_path()) then begin
     logs.Syslogs('unable to stat DAR (Disk Archive) Tool... Aborting');
     exit;
  end;

  logs.Syslogs('Running smbount version ' + SYS.SMBMOUNT_VERSION());
  logs.Syslogs('Running DAR version ' + dar.dar_version());
  
result:=True;
end;
//##############################################################################
function tbackupshare.ParsingRemoteFolders():boolean;
var
l:TstringList;
RegExpr:TRegExpr;
i:integer;
mount_path:string;
server:string;
share:string;
account:string;
password:string;
domain:string;
uuid:string;
dev_source:string;
begin

logs.Syslogs('Starting backup from netshares configuration...');
logs.Syslogs('Testing environnement');
if not TestIfBackupCanWork() then begin
      SendNotif(false);
      exit;
end;


l:=TstringList.Create;
RegExpr:=TRegExpr.Create;
l.LoadFromFile('/etc/artica-postfix/artica-netshares-backup.conf');
RegExpr.Expression:='(.+?);(.+?);(.+?);(.+?);(.*)';

for i:=0 to l.Count-1 do begin
     logs.Debuglogs('parsing server (' + IntToStr(i)+')');
     if RegExpr.Exec(l.Strings[i]) then begin
         server:=RegExpr.Match[1];
         share:=RegExpr.Match[2];
         account:=RegExpr.Match[3];
         password:=RegExpr.Match[4];
         domain:=RegExpr.Match[5];
         uuid:=SYS.MD5FromString(server+share);
         dev_source:='//'+ server + '/' + share;
         
         mount_path:='/opt/artica/' + uuid;

         
         if not MountTarget(server,share,account,password,domain,mount_path) then begin
            logs.Debuglogs('Failed...');
            SendNotif(false);
         end;
         
         if not backup.dar(dev_source,mount_path,uuid) then begin
           logs.Debuglogs('Failed...');
           SendNotif(false);
         end;
         
         SendNotif(true);
         
     end;

end;

end;
//##############################################################################
function tbackupshare.MountTarget(server:string;share:string;account:string;password:string;domain:string;mount_path:string):boolean;
var
   filetemp:string;
   mount_domain:string;
   cmd:string;
begin
result:=false;
if not FileExists(SYS.LOCATE_SMBMOUNT()) then begin
   logs.Syslogs('unable to stat smbmount...');
   exit;
end;
  logs.Syslogs('mounting smb://'+server+'/'+share+ ' ('+account+') in ' + mount_path);
  filetemp:='/opt/artica/tmp/' + SYS.MD5FromString(mount_path);
  
  
  if SYS.DISK_USB_IS_MOUNTED('//'+ server + '/' + share,mount_path) then begin
     result:=true;
     logs.Syslogs(mount_path + ' already mounted');
     exit;
  end;
  
  
  if length(domain)>0 then begin
     mount_domain:=',domain=' + domain;
  end;
  
  forceDirectories(mount_path);
  
  cmd:=SYS.LOCATE_SMBMOUNT() + ' //'+ server + '/' + share + ' ' + mount_path + ' -o user=' + account +',password=' + password + mount_domain + ',rw >'+ filetemp + ' 2>&1';
  logs.Debuglogs(cmd);
  fpsystem(cmd);

  logs.Debuglogs(logs.ReadFromFile(filetemp));
  logs.DeleteFile(filetemp);



  if SYS.DISK_USB_IS_MOUNTED('//'+ server + '/' + share,mount_path) then begin
     result:=true;
     logs.Syslogs(mount_path + ' is now mounted');
     exit;
  end;
  
  logs.Debuglogs('MountTarget::exit()');
  
end;
//##############################################################################
procedure tbackupshare.SigleMount(number:string);
var
l:TstringList;
snumber:integer;
RegExpr:TRegExpr;
i:integer;
mount_path:string;
server:string;
share:string;
account:string;
password:string;
domain:string;
uuid:string;
dev_source:string;
begin

if not TestIfBackupCanWork() then begin
      exit;
end;


if not TryStrToInt(number,snumber) then exit;


l:=TstringList.Create;
RegExpr:=TRegExpr.Create;
l.LoadFromFile('/etc/artica-postfix/artica-netshares-backup.conf');
RegExpr.Expression:='(.+?);(.+?);(.+?);(.+?);(.*)';
if RegExpr.Exec(l.Strings[snumber]) then begin
         server:=RegExpr.Match[1];
         share:=RegExpr.Match[2];
         account:=RegExpr.Match[3];
         password:=RegExpr.Match[4];
         domain:=RegExpr.Match[5];
         uuid:=SYS.MD5FromString(server+share);
         dev_source:='//'+ server + '/' + share;
         mount_path:='/opt/artica/' + uuid;

        if not MountTarget(server,share,account,password,domain,mount_path) then begin
            logs.Debuglogs('SigleMount::Failed...');
         end;
end;

end;
//##############################################################################




procedure tbackupshare.SendNotif(ok:boolean);
begin
if ok then begin
   logs.Debuglogs('Send Notifications...result=OK');
   logs.NOTIFICATION('[ARTICA]: ('+SYS.HOSTNAME_g()+') success backup to network shares',ParseSyslog(),'system');
end else begin
       logs.Debuglogs('Send Notifications...result=NO');
    logs.NOTIFICATION('[ARTICA]: ('+SYS.HOSTNAME_g()+') failed backup to network shares',ParseSyslog(),'system');
end;
end;
//##############################################################################
function tbackupshare.ParseSyslog():string;
var
   syslog_path:string;
   tmplogs:string;
   cmd:string;
begin

syslog_path:=SYS.LOCATE_SYSLOG_PATH();
if not FileExists(syslog_path) then begin
   logs.Syslogs('Unable to stat syslog path...');
   exit;
end;

tmplogs:=LOGS.FILE_TEMP();
cmd:='/usr/bin/tail -n 1000 ' + syslog_path + '|grep artica-backup >' + tmplogs + ' 2>&1';
logs.Debuglogs('ParseSyslog() ' + cmd);
fpsystem(cmd);
if not fileExists(tmplogs) then exit;
result:=logs.ReadFromFile(tmplogs);
end;
//##############################################################################



end.
