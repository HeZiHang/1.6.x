unit lvm;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils, Process,logs,unix,RegExpr,zsystem,openldap;



  type
  tlvm=class


private
     LOGS:Tlogs;
     SYS:TSystem;
     artica_path:string;
     zldap:Topenldap;

public
    procedure   Free;
    constructor Create(const zSYS:Tsystem);
    function    VERSION():string;
    function    BIN_PATH():string;
    function    PID_NUM():string;
    procedure   START();
    procedure   STOP();
    function    STATUS:string;
    function    INITD_PATH():string;
    function    SCAN_DISKS():string;
    function    SCAN_DEV():string;
    function    SCAN_VG():string;
    procedure   RELOAD();
    procedure   pvcreate_dev(dev:string);
    procedure   vgcreate_dev(dev:string;groupname:string);

END;

implementation

constructor tlvm.Create(const zSYS:Tsystem);
begin
       forcedirectories('/etc/artica-postfix');
       LOGS:=tlogs.Create();
       SYS:=zSYS;
       zldap:=Topenldap.Create;


       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;
end;
//##############################################################################
procedure tlvm.free();
begin
    logs.Free;
    zldap.Free;
end;
//##############################################################################
function tlvm.BIN_PATH():string;
begin
   if FileExists('/usr/sbin/rpc.nfsd') then exit('/usr/sbin/rpc.nfsd');
end;
//##############################################################################
function tlvm.INITD_PATH():string;
begin
if FileExists('/etc/init.d/nfs-kernel-server') then exit('/etc/init.d/nfs-kernel-server');
if FileExists('/etc/init.d/nfs-server') then exit('/etc/init.d/nfs-server');
if FileExists('/etc/init.d/nfsserver') then exit('/etc/init.d/nfsserver');
if FileExists('/etc/init.d/nfs') then exit('/etc/init.d/nfs');
end;
//##############################################################################
function tlvm.PID_NUM():string;
begin
    if not FIleExists(BIN_PATH()) then exit;
    result:=SYS.PIDOF('nfsd');
end;
//##############################################################################
function tlvm.VERSION():string;
var
    RegExpr:TRegExpr;
    FileDatas:TStringList;
    i:integer;
    filetmp:string;
begin

result:=SYS.GET_CACHE_VERSION('APP_NFS');
if length(result)>0 then exit;

filetmp:=logs.FILE_TEMP();
if not FileExists(BIN_PATH()) then exit;
fpsystem('/usr/sbin/rpc.mountd -v >'+filetmp+' 2>&1');
    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='s+([0-9\.]+)';
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
SYS.SET_CACHE_VERSION('APP_NFS',result);

end;
//#############################################################################
procedure tlvm.RELOAD();
begin
    if not FileExists('/etc/artica-postfix/settings/Daemons/NFSExportConfig') then exit;
    fpsystem('/bin/cp /etc/artica-postfix/settings/Daemons/NFSExportConfig /etc/exports');
    fpsystem(INITD_PATH()+' reload');
end;

procedure tlvm.START();
var
   count:integer;
   pid:string;
begin
    pid:=PID_NUM();
    IF sys.PROCESS_EXIST(pid) then begin
       logs.DebugLogs('Starting......: NFS server Already running PID '+ pid);
       exit;
    end;

    if not FileExists(INITD_PATH()) then begin
       logs.DebugLogs('Starting......: NFS server is not installed');
       exit;
    end;



    fpsystem(INITD_PATH()+' start');
    if FileExists('/etc/init.d/nfs-common') then fpsystem('/etc/init.d/nfs-common start');

count:=0;
 while not SYS.PROCESS_EXIST(PID_NUM()) do begin

        sleep(100);
        inc(count);
        if count>10 then begin
           logs.DebugLogs('Starting......: NFS server (timeout)');
           break;
        end;
  end;

pid:=PID_NUM();
    IF sys.PROCESS_EXIST(pid) then begin
       logs.DebugLogs('Starting......: NFS server successfully started and running PID '+ pid);
       exit;
    end;

logs.DebugLogs('Starting......: NFS server failed');

end;


//#############################################################################
procedure tlvm.STOP();
begin
  fpsystem(INITD_PATH()+' stop');
  if FileExists('/etc/init.d/nfs-common') then fpsystem('/etc/init.d/nfs-common stop');


end;
//#############################################################################
procedure tlvm.pvcreate_dev(dev:string);
var
   mounted:Tstringlist;
   i:integer;
begin
   if SYS.isMounteddev(dev) then begin
      mounted:=Tstringlist.Create;
      mounted.AddStrings(SYS.GetMountedDev(dev));
      for i:=0 to mounted.Count -1 do begin
      logs.Debuglogs('umount ' + mounted.Strings[i]);
      fpsystem('/bin/umount -l '+ mounted.Strings[i]);
      end;
   end else begin
      logs.Debuglogs(dev+' is not mounted continue;');
   end;

   if SYS.isMounteddev(dev) then begin
       logs.Debuglogs('failed to umount ' + dev);
       exit;
   end;

   logs.OutputCmd(SYS.LOCATE_PVCREATE()+' '+ dev+' -ff -y');


end;
//#############################################################################
procedure tlvm.vgcreate_dev(dev:string;groupname:string);
begin
   if not FileExists(SYS.LOCATE_VGCREATE()) then exit;
   logs.OutputCmd(SYS.LOCATE_VGCREATE()+' "'+groupname+'" '+dev);
end;
//#############################################################################
function tlvm.SCAN_DISKS():string;
var
   l:Tstringlist;
   php:tstringlist;
   tmpstr:string;
   RegExpr:TRegExpr;
   i:integer;
begin
   if not FileExists(SYS.LOCATE_PVS()) then exit;
   tmpstr:=logs.FILE_TEMP();
   fpsystem(SYS.LOCATE_PVS()+' --aligned --separator ";" --nosuffix --units g --noheadings >'+tmpstr+' 2>&1');
   RegExpr:=TRegExpr.Create;
   l:=Tstringlist.Create;
   l.LoadFromFile(tmpstr);
   RegExpr.Expression:='(.+?);(.*?);(.*?);(.*?);(.*?);(.*)';
   php:=Tstringlist.Create;
   for i:=0 to l.Count-1 do begin
      if RegExpr.Exec(l.Strings[i]) then begin
          php.Add('$lvm_dev["'+trim(RegExpr.Match[1])+'"]=Array("GROUP"=>"'+trim(RegExpr.Match[2])+'","PSize"=>"'+trim(RegExpr.Match[5])+'","PFree"=>"'+trim(RegExpr.Match[6])+'");');
      end;

   end;

   result:=php.Text;
   php.free;
   l.free;
   RegExpr.free;
   logs.DeleteFile(tmpstr);


end;
//#############################################################################
function tlvm.SCAN_VG():string;
var
   l:Tstringlist;
   php:tstringlist;
   tmpstr:string;
   RegExpr:TRegExpr;
   cmd:string;
   i:integer;
begin
   if not FileExists(SYS.LOCATE_LVS()) then begin
      logs.Debuglogs('tlvm.SCAN_VG():: Unable to stat lvs');
      exit;
   end;
   tmpstr:=logs.FILE_TEMP();
   cmd:=SYS.LOCATE_LVS()+' --aligned --separator ";" --nosuffix --units g --noheadings >'+tmpstr+' 2>&1';
   logs.Debuglogs(cmd);
   fpsystem(cmd);
   RegExpr:=TRegExpr.Create;
   l:=Tstringlist.Create;
   l.LoadFromFile(tmpstr);
   RegExpr.Expression:='(.+?);(.*?);(.*?);(.*?);';
   php:=Tstringlist.Create;
   for i:=0 to l.Count-1 do begin
      if RegExpr.Exec(l.Strings[i]) then begin
          logs.Debuglogs('Match[1]='+trim(RegExpr.Match[1])+' Match[2]='+trim(RegExpr.Match[2])+' Match[3]='+trim(RegExpr.Match[3])+' Match[4]='+trim(RegExpr.Match[4]));
          php.Add('$lvm_gdev["'+trim(RegExpr.Match[2])+'"]["'+trim(RegExpr.Match[1])+'"]="'+trim(RegExpr.Match[4])+'";');
      end;

   end;

   result:=php.Text;
   php.free;
   l.free;
   RegExpr.free;
   logs.DeleteFile(tmpstr);


end;

//#############################################################################
function tlvm.SCAN_DEV():string;
var
   l:Tstringlist;
   php:tstringlist;
   tmpstr:string;
   RegExpr:TRegExpr;
   cmd:string;
   i:integer;
begin
   if not FileExists(SYS.LOCATE_LVMDISKSCAN()) then begin
      logs.Debuglogs('tlvm.SCAN_VG():: Unable to stat lvmdiskscan');
      exit;
   end;
   tmpstr:=logs.FILE_TEMP();
   cmd:=SYS.LOCATE_LVMDISKSCAN()+' -l >'+tmpstr+' 2>&1';
   logs.Debuglogs(cmd);
   fpsystem(cmd);
   RegExpr:=TRegExpr.Create;
   l:=Tstringlist.Create;
   l.LoadFromFile(tmpstr);
   RegExpr.Expression:='(.+?)\s+.+?\[([0-9A-Z\s]+)\]\s+LVM';
   php:=Tstringlist.Create;
   for i:=0 to l.Count-1 do begin
      if RegExpr.Exec(l.Strings[i]) then begin
          logs.Debuglogs('Match[1]='+trim(RegExpr.Match[1])+' Match[2]='+trim(RegExpr.Match[2]));
          php.Add('$lvm_disks["'+trim(RegExpr.Match[1])+'"]["'+trim(RegExpr.Match[2])+'"]=True;');
      end;

   end;

   result:=php.Text;
   php.free;
   l.free;
   RegExpr.free;
   logs.DeleteFile(tmpstr);


end;

//#############################################################################




function tlvm.STATUS:string;
var
ini:TstringList;
pid:string;
begin
   ini:=TstringList.Create;
   ini.Add('[APP_NFS]');
   if not fileExists(BIN_PATH()) then begin
      ini.Add('application_installed=0');
      ini.Add('service_disabled=0');
      result:=ini.Text;
      ini.free;
      exit;
   end;


   if fileExists(BIN_PATH()) then begin
      pid:=PID_NUM();
      if SYS.PROCESS_EXIST(pid) then ini.Add('running=1') else  ini.Add('running=0');
      ini.Add('application_installed=1');
      ini.Add('application_enabled=1');
      ini.Add('master_pid='+ pid);
      ini.Add('master_memory=' + IntToStr(SYS.PROCESS_MEMORY(pid)));
      ini.Add('master_version='+VERSION());
      ini.Add('status='+SYS.PROCESS_STATUS(pid));
      ini.Add('service_name=APP_NFS');
      ini.Add('service_cmd=nfs');
      ini.Add('service_disabled=1');
   end;

   result:=ini.Text;
   ini.free;

end;
//##############################################################################


end.
