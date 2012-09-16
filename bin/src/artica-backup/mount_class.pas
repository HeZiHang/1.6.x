unit mount_class;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,IniFiles, Process,md5,logs,BaseUnix,unix,RegExpr in 'RegExpr.pas',zsystem,tcpip,
    mysql_daemon;


  type
  tmount=class


private
     LOGS           :Tlogs;
     verbose        :boolean;
     D              :boolean;
     SYS            :Tsystem;
     TargetFolderMounted:string;
     tcp:ttcpip;
     function       smbmount(pattern:string):boolean;
     function       usbmount(pattern:string):boolean;
     function       StatMounted(TargetFolder:string):boolean;
     function       GetInternalIP(servername:string):string;


public
    artica_path    :string;
    IsMounted:boolean;
    TargetFolderToBackup:string;
    mounted_md5:string;
    procedure   Free;
    constructor Create;


    function mount(pattern:string):boolean;
    function DisMount():boolean;


END;

implementation

constructor tmount.Create;
begin
       forcedirectories('/etc/artica-postfix');
       LOGS:=tlogs.Create();
       SYS:=Tsystem.Create;
       SetCurrentDir(ExtractFilePath(Paramstr(0)));
       tcp:=ttcpip.Create();

      if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;



     verbose:=SYS.COMMANDLINE_PARAMETERS('--verbose');






end;
//##############################################################################
procedure tmount.free();
begin
    DisMount();
    logs.Free;
    SYS.Free;
    tcp.free;
end;
//#############################################################################
function tmount.mount(pattern:string):boolean;
var
   RegExpr:TRegExpr;

begin
 mounted_md5:=logs.MD5FromString(pattern);
 logs.Debuglogs('Mount:: Try to determine local ressource for backup storage width "'+pattern+'"');
 RegExpr:=TRegExpr.Create;

// ------------------------- FileMount ----------------------------------------------
     RegExpr.Expression:='^dir:(.+)';
     if RegExpr.Exec(pattern) then begin
        ForceDirectories(RegExpr.Match[1]);
        TargetFolderToBackup:= RegExpr.Match[1];
        result:=true;
        IsMounted:=true;
        exit;
     end;



// ------------------------- smb mount ----------------------------------------------
   RegExpr.Expression:='^smb:(.+)';
   if RegExpr.Exec(pattern) then begin
          result:=smbmount(pattern);
          exit;
   end;

// ------------------------- usb mount ----------------------------------------------
RegExpr.Expression:='usb:(.+)';
 if RegExpr.Exec(pattern) then begin
          result:=usbmount(pattern);
          exit;
   end;


end;
//#############################################################################
function tmount.GetInternalIP(servername:string):string;
var
   RegExpr:TRegExpr;
   l:TstringList;
   tmpstr:string;
   mount_point:string;
   subpath:string;
   i:integer;
begin
   tmpstr:=logs.FILE_TEMP();
   fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.computer.resolve.php '+ servername+' >'+tmpstr + ' 2>&1');
   if not fileExists(tmpstr) then exit(servername);
   l:=Tstringlist.Create;
   l.LoadFromFile(tmpstr);
   logs.DeleteFile(tmpstr);
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='([0-9]+)\.([0-9]+)\.([0-9]+)';
   for i:=0 to l.count-1 do begin
      if RegExpr.Exec(l.Strings[i]) then begin
         result:=l.Strings[i];
         l.free;
         RegExpr.free;
         exit;
      end;

   end;

 result:=servername;
 l.free;
 RegExpr.free;
 exit;

end;
//#############################################################################

function tmount.smbmount(pattern:string):boolean;
var
   RegExpr:TRegExpr;
   username:string;
   path:string;
   mount_point:string;
   subpath:string;
   servername:string;
begin
result:=false;
RegExpr:=TRegExpr.CReate;
RegExpr.Expression:='smb://(.+?):(.+?)@(.+?)/(.+)';
   if RegExpr.Exec(pattern) then begin
           username:=' -o username='+RegExpr.Match[1]+',password='+RegExpr.Match[2]+' ';
           servername:=RegExpr.Match[3];
           path:=RegExpr.Match[4];
   end else begin
       RegExpr.Expression:='smb://(.+?)/(.+)';
       username:=' -o guest ';
       if RegExpr.Exec(pattern) then begin
          servername:=RegExpr.Match[1];
          path:=RegExpr.Match[2];
       end;

   end;

   servername:=GetInternalIP(servername);

    if length(path)=0 then begin
       logs.Debuglogs('tmount::smbmount() unable to detect path in '+pattern);
       exit;
    end;

    if length(servername)=0 then begin
       logs.Debuglogs('tmount::smbmount() unable to detect hostname in '+pattern);
       exit;
    end;

    if not tcp.isPinged(servername) then begin
        logs.Debuglogs('tmount::smbmount() unable to PING host "'+servername+'"');
        exit;
    end;


    RegExpr.Expression:='^(.+?)/(.+)';
    if RegExpr.Exec(path) then begin
       path:=RegExpr.Match[1];
       subpath:=RegExpr.Match[2];
    end;




    mount_point:='/opt/artica/mount/'+logs.MD5FromString(pattern);
    if SYS.isMountedTargetPath(mount_point) then begin
       if not StatMounted(mount_point) then begin
          logs.OutputCmd('/bin/umount -f '+mount_point);
       end else begin
         logs.Debuglogs('tmount::smbmount()'+ mount_point +' already mounted and not corrupted');
         TargetFolderToBackup:= mount_point;
         TargetFolderMounted:=mount_point;
         IsMounted:=true;
         result:=true;
         exit;
       end;
    end;

    if DirectoryExists(mount_point) then logs.OutputCmd('/bin/rmdir '+ mount_point);
    forceDirectories(mount_point);
    logs.OutputCmd('/bin/mount -t smbfs'+username+'//' + servername+'/'+path +' ' + mount_point);

    if not SYS.isMountedTargetPath(mount_point) then begin
       logs.Debuglogs('tmount::smbmount() Failed to mount '+ path);
       exit;
    end;

    if length(subpath)>0 then begin
       TargetFolderToBackup:=mount_point+'/'+ subpath;
    end else begin
      TargetFolderToBackup:= mount_point;
    end;

    TargetFolderMounted:=mount_point;
    IsMounted:=true;
    result:=true;
    RegExpr.free;

end;

//#############################################################################
function tmount.usbmount(pattern:string):boolean;
var
   RegExpr:TRegExpr;
   username:string;
   uuid:string;
   usb_already_mounted:string;
   usb_type:string;
   devpoint:string;
   mount_point:string;
   subpath:string;
begin
result:=false;
RegExpr:=TRegExpr.CReate;
RegExpr.Expression:='usb:(.+)';
   if RegExpr.Exec(pattern) then begin
        uuid:=RegExpr.Match[1]
   end else begin
       RegExpr.Expression:='usb://(.+?)';
       if RegExpr.Exec(pattern) then uuid:=RegExpr.Match[1];
   end;

    if length(uuid)=0 then begin
       logs.Debuglogs('tmount::usbmount() unable to detect pattern in '+pattern);
       exit;
    end;

    RegExpr.Expression:='(.+?)/(.+)';
    if RegExpr.Exec(uuid) then begin
       uuid:=RegExpr.Match[1];
       subpath:=RegExpr.Match[2];
    end;

    if not SYS.DISK_USB_EXISTS(uuid) then begin
         logs.Debuglogs('Device ' + uuid + ' is not plugged');
         exit(false);
    end;


      logs.Debuglogs('Device ' + uuid + ' is plugged');


    mount_point:='/opt/artica/mount/'+logs.MD5FromString(pattern);
    devpoint:=SYS.usbMountPoint(uuid);
    usb_type:=SYS.usbExtType(uuid);
    usb_already_mounted:=SYS.usb_mount_point(devpoint);

      logs.Debuglogs('mount source :"'+devpoint+'" type '+ usb_type);
      logs.Debuglogs('mounted on.. :"'+usb_already_mounted+'" type '+ usb_type);

      if length(usb_already_mounted)>0 then begin
             logs.Debuglogs('Dismount...');
             logs.OutputCmd('/bin/umount -f '+usb_already_mounted);
      end;



      if not SYS.isMountedTargetPath(mount_point) then begin
           if DirectoryExists(mount_point) then logs.OutputCmd('/bin/rmdir '+ mount_point);
           forceDirectories(mount_point);
           logs.OutputCmd('/bin/mount -t '+usb_type+' '+devpoint+' '+mount_point);
      end;

      if not SYS.isMountedTargetPath(mount_point) then begin
           logs.Debuglogs('Unable to mount target ressource');
           result:=false;
           exit;
      end;

      if not StatMounted(mount_point) then begin
         logs.Syslogs('Corrupted mounted path, disconnect...');
         logs.OutputCmd('/bin/umount -f '+mount_point);
         if DirectoryExists(mount_point) then logs.OutputCmd('/bin/rmdir '+ mount_point);
         forceDirectories(mount_point);
         logs.OutputCmd('/bin/mount -t '+usb_type+' '+devpoint+' '+mount_point);
      end;


      if not SYS.isMountedTargetPath(mount_point) then begin
           logs.Debuglogs('Unable to mount target ressource');
           result:=false;
           exit;
      end;


    if length(subpath)>0 then begin
       TargetFolderToBackup:=mount_point+'/'+ subpath;
    end else begin
      TargetFolderToBackup:= mount_point;
    end;

    TargetFolderMounted:=mount_point;
    IsMounted:=true;
    result:=true;
    RegExpr.free;

end;

//#############################################################################
function tmount.StatMounted(TargetFolder:string):boolean;
var
    info : stat;
    S    : TDateTime;
    fa   : Longint;
    maint:TDateTime;
begin
   result:=false;
   if Not DirectoryExists(TargetFolder) then begin
      logs.Debuglogs('tmount::StatMounted() Unable to stat ' + TargetFolder);
      exit;
    end;

  if fpstat(TargetFolder,info)<>0 then begin
       logs.Debuglogs('tmount::StatMounted() Fstat failed. Errno : '+IntToStr(fpgeterrno));
       exit;
  end;

   result:=true;
end;
//##############################################################################
function tmount.DisMount():boolean;
var TargetFolder:string;
begin
if length(TargetFolderMounted)=0 then exit(true);
logs.Debuglogs('mount::DisMount order to dismount "'+TargetFolderMounted+'"');
TargetFolder:=TargetFolderMounted;
if length(TargetFolder)=0 then exit(true);

if not SYS.isMountedTargetPath(TargetFolder) then begin
   logs.Debuglogs('tmount::Dismount: ressource ' + TargetFolder + ' is not mounted');
   exit;
end;

logs.OutputCmd('/bin/umount '+ TargetFolder);
if not SYS.isMountedTargetPath(TargetFolder) then begin
     logs.Debuglogs('tmount::Dismount: ressource ' + TargetFolder + ' {success}');
     exit;
end;
logs.OutputCmd('/bin/umount -f '+ TargetFolder);
end;
//##############################################################################

end.
