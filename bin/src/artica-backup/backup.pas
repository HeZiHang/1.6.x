unit backup;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,IniFiles, Process,logs,BaseUnix,unix,RegExpr in 'RegExpr.pas',zsystem,openldap,cyrus,rdiffbackup,samba,
    mysql_daemon,backup_rsync,mount_class;


  type
  tbackup=class


private
     LOGS           :Tlogs;
     openldap       :topenldap;
     cyrus          :Tcyrus;
     dar_results     :tstringList;
     databases_list:TstringList;
     procedure       write_pidfile();
     function        GET_BACKUP_INFO(key:string):string;
     procedure       perform_stop();
     procedure       Backup_cyrus(backup_folder:string);
     function        uuid_mount(uuid:string):boolean;
     procedure       SendNotif(ok:boolean);
     function        ParseSyslog():string;
     procedure       GetProgress(progress:integer;text:string);
     procedure       Backup_artica_config(backup_folder:string);
     procedure       restore_cyrus_map_databases(SourceDirectory:string);


public
    artica_path    :string;
    SYS            :TSystem;
    procedure   Free;
    constructor Create;
    procedure   perform_backup();
    procedure   perform_restore_old(FilePath:string);
    procedure   retranslate_backup();
    procedure   perform_sauvegarde(TargetPath:string);
    procedure   perform_sauvegarde_restore(TargetPath:string);
    procedure   perform_restore();
    function    dar(dev_source:string;target_source:string;uuid:string):boolean;
    function    dar_restore_single(TargetFile:string;Database:string;uuid:string):boolean;
    function    dar_restore_database(Database:string;uuid:string;target_folder:string):boolean;

    procedure      REBUILD_LDAP_DATABASES();
    procedure      REBUILD_ARTICA_BRANCH();
    procedure      INSTANT_RECOVER_LDAP_DATABASES(filename:string);
    procedure      GetMysqlDatabases();
    procedure      restore_cyrus_imap_databases(SourceDirectory:string);
    procedure      restore_from_mysqlhotcopy(SourceDirectory:string);

END;

implementation

constructor tbackup.Create;
begin
       forcedirectories('/etc/artica-postfix');
       LOGS:=tlogs.Create();
       SYS:=Tsystem.Create;
       openldap:=Topenldap.Create;
       cyrus:=tcyrus.Create(SYS);
       SetCurrentDir(ExtractFilePath(Paramstr(0)));
       
       if SYS.PROCESS_EXIST(sys.GET_PID_FROM_PATH('/etc/artica-postfix/artica-backup.pid')) then begin
           logs.Syslogs('Alreay artica-ldap instance executed, killing');
           halt(0);
       end;
       
       
       write_pidfile();
       databases_list:=TstringList.Create;
      GetMysqlDatabases();
       

       

       
       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;
end;
//##############################################################################
procedure tbackup.free();
begin
    logs.Free;
    SYS.Free;
    cyrus.free;
end;
//##############################################################################
procedure tbackup.GetMysqlDatabases();
var
   mysql:tmysql_daemon;
   DataDir:string;
   i:integer;
begin

mysql:=tmysql_daemon.Create(SYS);
DataDir:=mysql.SERVER_PARAMETERS('datadir');
SYS.DirDir(DataDir);
for i:=0 to SYS.DirListFiles.Count-1 do begin
    databases_list.Add(SYS.DirListFiles.Strings[i]);

end;

if ParamStr(1)='--list-mysql-databases' then writeln(databases_list.Text);

end;
//##############################################################################


function tbackup.GET_BACKUP_INFO(key:string):string;
var
  Ini:TMemIniFile;
begin
Ini:=TMemIniFile.Create('/etc/artica-postfix/artica-backup.conf');
result:=trim(Ini.ReadString('backup',key,''));
Ini.Free;
end;
//#############################################################################
procedure tbackup.write_pidfile();
var myFile:Textfile;
begin
   ForceDirectories('/etc/artica-postfix');
      try
      AssignFile(myFile, '/etc/artica-postfix/artica-backup.pid');
      ReWrite(myFile);
      WriteLn(myFile, intTostr(fpgetpid));
      CloseFile(myFile);

      EXCEPT
      logs.Syslogs('write_pidfile()::artica-backup daemon..SavePid-> fatal error writing /etc/artica-postfix/artica-backup.pid');
      halt(0);
      END;
end;
//##############################################################################
procedure tbackup.perform_sauvegarde(TargetPath:string);
var
   ldap_directory:string;
   ldap_conf:string;
   mysql_directory:string;
   cyrus_directory:string;
   mysql:tmysql_daemon;
begin


if length(TargetPath)<3 then begin
   logs.Syslogs('perform_sauvegarde:: ERROR on target path it is not specified...');
   exit;
end;


TargetPath:=TargetPath+'/full-backup';
logs.Syslogs('perform full backup');
logs.Syslogs('analyze your system....');
mysql:=tmysql_daemon.Create(SYS);
mysql_directory:=mysql.SERVER_PARAMETERS('datadir');
cyrus_directory:=cyrus.IMAPD_GET('partition-default');


ldap_directory:=openldap.LDAP_DATABASES_PATH();
ldap_conf:=openldap.SLAPD_CONF_PATH();



logs.Syslogs('Ldap directory......: '+ldap_directory);
logs.Syslogs('Ldap conf file......: '+ldap_conf);
logs.Syslogs('Mysql directory.....: '+mysql_directory);
logs.Syslogs('Imap directory......: '+cyrus_directory);


logs.Syslogs('');

logs.Syslogs('Perform settings backup....');
logs.Syslogs('Create necessary directories in '+ TargetPath);
forceDirectories(TargetPath+'/etc/artica-postfix');
forceDirectories(TargetPath+'/etc/ldap');
forceDirectories(TargetPath+'/mysql-datas');
forceDirectories(TargetPath+'/ldap-datas');
forceDirectories(TargetPath+'/imap-datas');


logs.Syslogs('Copy content of /etc/artica-postfix');
fpsystem('cp -rfv /etc/artica-postfix/* '+ TargetPath+'/etc/artica-postfix/');
fpsystem('cp -fv '+ldap_conf+' '+ TargetPath+'/etc/ldap/slapd.conf');

logs.Syslogs('Perform settings backup done....');

logs.Syslogs('Stopping daemons');
fpsystem('/etc/init.d/artica-postfix stop');
fpsystem('/etc/init.d/cron stop');
fpsystem('/etc/init.d/artica-postfix stop');
fpsystem('/etc/init.d/artica-postfix stop watchdog');

logs.Syslogs('copy all datas');
fpsystem('cp -rfv '+ldap_directory+'/* '+ TargetPath+'/ldap-datas/');
if DirectoryExists(mysql_directory) then begin
   fpsystem('cp -rfv '+mysql_directory+'/* '+ TargetPath+'/mysql-datas/');
end;

if DirectoryExists(cyrus_directory) then begin
   fpsystem('cp -rfv '+cyrus_directory+'/* '+ TargetPath+'/imap-datas/');
end;

logs.Syslogs('Starting all daemons...');
fpsystem('/etc/init.d/artica-postfix start');
fpsystem('/etc/init.d/cron start');



logs.Syslogs('Compress datas.... This should make a long time....');

fpsystem('cd ' + TargetPath + ' && tar -cvf artica-full-backup.tar.gz *');

logs.Syslogs('Delete temporary folders...');
fpsystem('rm -rf '+ TargetPath+'/etc/artica-postfix');
fpsystem('rm -rf '+ TargetPath+'/etc/ldap');
fpsystem('rm -rf '+ TargetPath+'/mysql-datas');
fpsystem('rm -rf '+ TargetPath+'/ldap-datas');
fpsystem('rm -rf '+ TargetPath+'/imap-datas');

logs.Syslogs('Delete temporary folders done...');
logs.Syslogs('Success create container "' +TargetPath +'/artica-full-backup.tar.gz"');
logs.Syslogs('Size: '+IntToStr(SYS.FileSize_ko(TargetPath +'/artica-full-backup.tar.gz'))+ 'Ko');
logs.Syslogs('');
logs.Syslogs('Copy this file to a new server in a new directory');
logs.Syslogs('with a freshed artica-postfix installation');
logs.Syslogs('and execute /usr/share/artica-postfix/bin/artica-backup --full-restore [directory]');
logs.Syslogs('');
logs.Syslogs('');
halt(0);
end;
//##############################################################################
procedure tbackup.perform_restore();
var
   FolderCible:string;
   FolderOrg:string;
   Tarball:string;
   subfolder:string;
   cmd:string;
   mysql_password:string;
   mysql_user:string;
   db:string;
   i:integer;
   CompressQueue:string;
   HtmlsizeQueue:string;
   InstantImportExternalResource:string;
   TempzFolder:string;
   mount:tmount;
   size:integer;
begin

logs.Debuglogs('perform_restore:: Starting artica restore...');
FolderCible:=GET_BACKUP_INFO('backup_path');

if length(FolderCible)=0 then begin
      logs.Syslogs('perform_restore:: Fatal error, unable to determine [backup] & backup_path data in /etc/artica-postfix/artica-backup.conf... define it to /opt/artica/backup');
      FolderCible:='/opt/artica/backup';
      FolderOrg:=FolderCible;
end;


FolderOrg:=FolderCible;
logs.Debuglogs('perform_restore:: Working directory is : '+FolderCible);
InstantImportExternalResource:=SYS.GET_INFO('InstantImportExternalResource');
mount:=tmount.Create;

 GetProgress(10,'Start task...');

if length(InstantImportExternalResource)>0 then begin
   logs.Debuglogs('perform_restore:: import backup to remote resource');
   if not mount.mount(InstantImportExternalResource) then begin
        GetProgress(110,'unable to mount external ressources');
        logs.Debuglogs('perform_restore:: unable to mount external ressources');
        exit;
   end;
end else begin
    logs.Debuglogs('perform_restore:: No remote resource specified...');
end;

logs.Debuglogs('perform_restore:: Remote ressource is : ' + mount.TargetFolderToBackup);

Tarball:=mount.TargetFolderToBackup+'/artica-export.tar.gz';
TempzFolder:=FolderCible+'/import';

if not FileExists(Tarball) then begin
        GetProgress(110,'unable to stat "'+Tarball+'" external ressources');
        logs.Debuglogs('perform_restore:: unable to to stat "'+Tarball+'" external ressources');
        mount.DisMount();
        exit;
end;

size:=SYS.FileSize_ko(Tarball);
logs.Debuglogs('perform_restore:: Creating temporary folder '+TempzFolder);

if DirectoryExists(TempzFolder) then logs.OutputCmd('/bin/rm -rf '+ TempzFolder);

forceDirectories(TempzFolder);
logs.Debuglogs('perform_restore: Unpack container '+IntToStr(size) +'Ko');
GetProgress(20,'Unpack container '+IntToStr(size) +'Ko');
logs.OutputCmd('/bin/tar -xf '+Tarball +' -C '+TempzFolder+'/');
GetProgress(30,'Unpack container done in '+TempzFolder);

logs.Debuglogs('perform_restore::  testing '+TempzFolder+'/datas/ldap/ldap.ldif');

if FileExists(TempzFolder+'/datas/ldap/ldap.ldif') then begin
        GetProgress(35,'Restore LDAP database...');
        INSTANT_RECOVER_LDAP_DATABASES(TempzFolder+'/datas/ldap/ldap.ldif');
        GetProgress(40,'Restore LDAP database...done.');
end else begin
      logs.Debuglogs('perform_restore:: unable to stat '+TempzFolder+'/datas/ldap/ldap.ldif');
end;

GetProgress(45,'Restore Mysql databases....');
if DirectoryExists(TempzFolder+'/datas/mysql') then begin
   restore_from_mysqlhotcopy(TempzFolder+'/datas/mysql');
end;
GetProgress(60,'Restore Mysql databases done');
restore_cyrus_map_databases(TempzFolder+'/cyrus');

HtmlsizeQueue:=SYS.GET_INFO('HtmlsizeQueue');
CompressQueue:=SYS.GET_INFO('CompressQueue');
ForceDirectories('/opt/artica/share/www/attachments');


GetProgress(77,'Restore Quarantines & attachments');
logs.OutputCmd('cp -rf '+ TempzFolder+'/datas/attachments/* /opt/artica/share/www/attachments/');
logs.OutputCmd('cp -rf '+ TempzFolder+'/datas/original_messages/* /opt/artica/share/www/original_messages/');

if length(CompressQueue)>0 then begin
    logs.OutputCmd('cp -rf '+ TempzFolder+'/datas/CompressQueue/* '+CompressQueue+'/');
end;

if length(HtmlsizeQueue)>0 then begin
    logs.OutputCmd('cp -rf '+ TempzFolder+'/datas/HtmlsizeQueue/* '+HtmlsizeQueue+'/');
end;
GetProgress(77,'Restore Artica parameters');
logs.OutputCmd('cp -rf '+ TempzFolder+'/artica/Daemons/* /etc/artica-postfix/settings/Daemons/');
if DirectoryExists(TempzFolder) then logs.OutputCmd('/bin/rm -rf '+ TempzFolder);
GetProgress(80,'Cleaning directory');
GetProgress(100,'restore operation completed');
mount.DisMount();
end;
//##############################################################################
procedure tbackup.restore_from_mysqlhotcopy(SourceDirectory:string);
var
   i:integer;
   mysql:tmysql_daemon;
   mysql_directory:string;
begin
  mysql:=tmysql_daemon.Create(SYS);
  mysql_directory:=mysql.SERVER_PARAMETERS('datadir');

  if not DirectoryExists(mysql_directory) then begin
     logs.Debuglogs('restore_from_mysqlhotcopy:: unable to stat datadir..aborting');
     exit;
  end;
  logs.Debuglogs('Stopping Mysql server');
  GetProgress(47,'Stopping mysql server...');
  mysql.SERVICE_STOP();

  if FIleExists(SourceDirectory+'/mysql-databases.tgz') then begin
        logs.Debuglogs('Extract '+SourceDirectory+'/mysql-databases.tgz');
        logs.OutputCmd('tar -xjf '+SourceDirectory+'/mysql-databases.tgz -C '+mysql_directory+'/');
        logs.Debuglogs('starting Mysql server');
        mysql.SERVICE_START();
        exit;
  end;

SYS.DirDir(SourceDirectory);
for i:=0 to SYS.DirListFiles.Count-1 do begin
       GetProgress(50,'Restore '+SYS.DirListFiles.Strings[i]+' database....');
       logs.OutputCmd('/bin/cp -rf '+SourceDirectory+'/'+SYS.DirListFiles.Strings[i]+' '+mysql_directory+'/');

end;

  GetProgress(55,'Starting mysql server...');
  mysql.SERVICE_START();



end;
//##############################################################################
procedure tbackup.restore_cyrus_imap_databases(SourceDirectory:string);
var
partitiondefault:string;
configdirectory:string;

begin
  cyrus:=Tcyrus.Create(SYS);
  if not FileExists(cyrus.CYRUS_DAEMON_BIN_PATH()) then begin
       logs.Debuglogs('restore_cyrus_imap_databases:: Cyrus-imap is not installed');
       exit;
  end;

  if not DirectoryExists(SourceDirectory+'/cyrus-imap/configdirectory') then begin
          logs.Debuglogs('restore_cyrus_imap_databases:: unable to stat directory '+SourceDirectory+'/cyrus-imap/configdirectory/cyrus');
          exit;
  end;

  if not DirectoryExists(SourceDirectory+'/cyrus-imap/partitiondefault') then begin
          logs.Debuglogs('restore_cyrus_imap_databases:: unable to stat directory '+SourceDirectory+'/cyrus-imap/partitiondefault/mail');
          exit;
  end;

  if not FileExists(SourceDirectory+'/cyrus-imap/mailboxlist.txt') then begin
          logs.Debuglogs('restore_cyrus_imap_databases:: unable to stat '+SourceDirectory+'/cyrus-imap/mailboxlist.txt');
          exit;
  end;

partitiondefault:=cyrus.IMAPD_GET('partition-default');
configdirectory:=cyrus.IMAPD_GET('configdirectory');

if length(partitiondefault)=0 then begin
   logs.Debuglogs('restore_cyrus_imap_databases:: unable to get "partition-default" path');
end;

if length(configdirectory)=0 then begin
   logs.Debuglogs('restore_cyrus_imap_databases:: unable to get "configdirectory" path');
end;

cyrus.CYRUS_DAEMON_STOP();
logs.OutputCmd('/bin/rm -rf '+partitiondefault+'/*');
logs.OutputCmd('/bin/rm -rf '+configdirectory+'/*');
if not FileExists(partitiondefault) then forceDirectories(partitiondefault);
if not FileExists(configdirectory) then forceDirectories(configdirectory);

logs.Debuglogs('restore_cyrus_imap_databases:: copy cyrus databases');
logs.OutputCmd('/bin/cp -rf '+SourceDirectory+'/cyrus-imap/configdirectory/cyrus/* '+ configdirectory+'/');
logs.OutputCmd('/bin/cp -rf '+SourceDirectory+'/cyrus-imap/partitiondefault/mail/* '+ partitiondefault+'/');
 logs.Debuglogs('restore_cyrus_imap_databases:: Apply security permissions');


logs.OutputCmd('/bin/chown -R cyrus:mail '+configdirectory);
logs.OutputCmd('/bin/chown -R cyrus:mail '+partitiondefault);
logs.OutputCmd('su - cyrus -c "'+sys.LOCATE_ctl_mboxlist()+' -u" < '+SourceDirectory+'/cyrus-imap/mailboxlist.txt');
cyrus.CYRUS_DAEMON_START();
end;

//##############################################################################
procedure tbackup.restore_cyrus_map_databases(SourceDirectory:string);
var
partitiondefault:string;
configdirectory:string;

begin
  cyrus:=Tcyrus.Create(SYS);
  if not FileExists(cyrus.CYRUS_DAEMON_BIN_PATH()) then begin
       logs.Debuglogs('restore_cyrus_map_databases:: Cyrus-imap is not installed');
       exit;
  end;

  if not FileExists(SourceDirectory+'/configdirectory.tar.gz') then begin
          logs.Debuglogs('restore_cyrus_map_databases:: unable to stat '+SourceDirectory+'/configdirectory.tar.gz');
          exit;
  end;

  if not FileExists(SourceDirectory+'/partition-default.tar.gz') then begin
          logs.Debuglogs('restore_cyrus_map_databases:: unable to stat '+SourceDirectory+'/partition-default.tar.gz');
          exit;
  end;

partitiondefault:=cyrus.IMAPD_GET('partition-default');
configdirectory:=cyrus.IMAPD_GET('configdirectory');

if length(partitiondefault)=0 then begin
   logs.Debuglogs('restore_cyrus_map_databases:: unable to get "partition-default" path');
end;

if length(configdirectory)=0 then begin
   logs.Debuglogs('restore_cyrus_map_databases:: unable to get "configdirectory" path');
end;

GetProgress(65,'Delete cyrus databases');
cyrus.CYRUS_DAEMON_STOP();
logs.OutputCmd('/bin/rm -rf '+partitiondefault+'/*');
logs.OutputCmd('/bin/rm -rf '+configdirectory+'/*');
GetProgress(70,'Unpack cyrus databases');

if not FileExists(partitiondefault) then forceDirectories(partitiondefault);
if not FileExists(configdirectory) then forceDirectories(configdirectory);


logs.OutputCmd('/bin/tar -xf '+SourceDirectory+'/configdirectory.tar.gz -C '+configdirectory+'/');
logs.OutputCmd('/bin/tar -xf '+SourceDirectory+'/partition-default.tar.gz -C '+partitiondefault+'/');
logs.OutputCmd('/bin/chown -R cyrus:mail '+configdirectory);
logs.OutputCmd('/bin/chown -R cyrus:mail '+partitiondefault);
GetProgress(75,'building cyrus databases');
logs.OutputCmd('su - cyrus -c "'+sys.LOCATE_ctl_mboxlist()+' -u" < '+configdirectory+'/mailboxlist.txt');
GetProgress(75,'Starting cyrus');
cyrus.CYRUS_DAEMON_START();


end;
//##############################################################################


procedure tbackup.perform_sauvegarde_restore(TargetPath:string);
var
   ldap_directory:string;
   ldap_conf:string;
   mysql_directory:string;
   cyrus_directory:string;
   mysql:tmysql_daemon;
   DirectoryTemp:string;
   FileName:string;
   l:TstringList;
   noextract:boolean;
   i:integer;
begin
  noextract:=false;
  
  l:=TstringList.Create;
  l.Add('etc');
  l.Add('ldap');
  l.Add('mysql-datas');
  l.Add('ldap-datas');
  l.Add('imap-datas');

if length(TargetPath)<3 then begin
   logs.Syslogs('ERROR on target path...');
   exit;
end;

if not FileExists(TargetPath) then begin
   logs.Syslogs('Unable to stat '+TargetPath);
   exit;
end;

DirectoryTemp:=ExtractFilePath(TargetPath);
FileName:=ExtractFileName(TargetPath);
logs.Syslogs('Using '+DirectoryTemp + ' as the temporary folder...');

logs.Syslogs('perform full restoration');
logs.Syslogs('analyze your system....');
mysql:=tmysql_daemon.Create(SYS);
mysql_directory:=mysql.SERVER_PARAMETERS('datadir');
cyrus_directory:=cyrus.IMAPD_GET('partition-default');


ldap_directory:=openldap.LDAP_DATABASES_PATH();
ldap_conf:=openldap.SLAPD_CONF_PATH();
logs.Syslogs('Ldap directory......: '+ldap_directory);
logs.Syslogs('Ldap conf file......: '+ldap_conf);
logs.Syslogs('Mysql directory.....: '+mysql_directory);
logs.Syslogs('Imap directory......: '+cyrus_directory);


for i:=0 to l.Count-1 do begin
    if DirectoryExists(DirectoryTemp+l.Strings[i]) then begin
       writeln(DirectoryTemp+l.Strings[i],' exists skip extracting operation');
       noextract:=true;
       break;
    end;
end;

if not noextract then begin
   logs.Syslogs('Extracting container....');
   logs.Syslogs('This should take a long time....');
   fpsystem('cd ' + DirectoryTemp + ' && tar -xf ' + FileName);
   logs.Syslogs('Extracting done....');
end;

logs.Syslogs('Stopping artica....');
fpsystem('/etc/init.d/artica-postfix stop');
fpsystem('/etc/init.d/cron stop');
fpsystem('/etc/init.d/artica-postfix stop');
logs.Syslogs('restoring datas now...');


logs.Syslogs('restoring settings...');
if DirectoryExists(DirectoryTemp+'etc/artica-postfix') then begin
   fpsystem('cp -rfv '+ DirectoryTemp+'etc/artica-postfix/* /etc/artica-postfix/');
end;

if FileExists(DirectoryTemp+'etc/ldap/slpad.conf') then begin
   fpsystem('cp -fv '+ DirectoryTemp+'etc/ldap/slpad.conf '+ldap_conf);
end;


if DirectoryExists(DirectoryTemp+'mysql-datas') then begin
   if DirectoryExists(mysql_directory) then begin
      logs.Syslogs('restoring Mysql...');
      fpsystem('cp -rfv '+ DirectoryTemp+'mysql-datas/* '+mysql_directory+'/');
   end;
end;

if DirectoryExists(DirectoryTemp+'ldap-datas') then begin
   if DirectoryExists(ldap_directory) then begin
      logs.Syslogs('restoring ldap databases...');
      fpsystem('cp -rfv '+ DirectoryTemp+'ldap-datas/* '+ldap_directory+'/');
   end;
end;

if DirectoryExists(DirectoryTemp+'ldap-datas') then begin
   if DirectoryExists(cyrus_directory) then begin
      logs.Syslogs('restoring imap databases...');
      fpsystem('cp -rfv '+ DirectoryTemp+'imap-datas/* '+cyrus_directory+'/');
   end;
end;

logs.Syslogs('restoring settings done...');

end;
//##############################################################################
procedure tbackup.GetProgress(progress:integer;text:string);
var
TmpINI:TiniFile;
begin
       TmpINI:=TiniFile.Create('/usr/share/artica-postfix/ressources/logs/export.status.conf');
       TmpINI.WriteString('STATUS','progress',IntToStr(progress));
       TmpINI.WriteString('STATUS','text',text);
       TmpINI.UpdateFile;
       TmpINI.free;
end;
//##############################################################################
procedure tbackup.perform_backup();
var
   FolderCible:string;
   FolderOrg:string;
   subfolder:string;
   cmd:string;
   mysql_password:string;
   mysql_user:string;
   db:string;
   i:integer;
   CompressQueue:string;
   HtmlsizeQueue:string;
   InstantExportExternalResource:string;
   mount:tmount;
begin

logs.Syslogs('Starting artica backup...');
FolderCible:=GET_BACKUP_INFO('backup_path');
InstantExportExternalResource:=SYS.GET_INFO('InstantExportExternalResource');
mount:=tmount.Create;

FolderOrg:=FolderCible;
if length(InstantExportExternalResource)>0 then begin
   logs.Debuglogs('export backup to remote resource');
   if not mount.mount(InstantExportExternalResource) then begin
        GetProgress(110,'unable to mount external ressources');
        exit;
   end;
end;





 GetProgress(10,'Starting backup');

if not FileExists(SYS.LOCATE_SLAPCAT()) then begin
        logs.Syslogs('Fatal error, unable to locate slapcat binary... halt');
        GetProgress(110,'unable to locate slapcat binary');
        SendNotif(false);
        exit;
end;

if not FileExists(openldap.SLAPD_CONF_PATH()) then begin
        logs.Syslogs('Fatal error, unable to locate ldap daemon configuration file... halt');
        GetProgress(110,'unable to locate ldap daemon configuration file');
        SendNotif(false);
        exit;
end;




if length(FolderCible)=0 then begin
      logs.Syslogs('Fatal error, unable to determine [backup] & backup_path data in /etc/artica-postfix/artica-backup.conf... define it to /opt/artica/backup');
      FolderCible:='/opt/artica/backup';
      FolderOrg:=FolderCible;
end;

subfolder:=FormatDateTime('yyyy-mm-dd-hh-nn-ss', Now);
FolderCible:=FolderCible+'/'+subfolder;

logs.Debuglogs('Backup will be stored temporary in '+FolderCible);
logs.Syslogs('Stopping watchdog daemons');
fpsystem('/etc/init.d/artica-postfix stop watchdog');


 GetProgress(20,'backup LDAP Database');

logs.Syslogs('#################################');
logs.Syslogs('#                               #');
logs.Syslogs('#          LDAP backup          #');
logs.Syslogs('#                               #');
logs.Syslogs('#################################');
logs.Syslogs('Stopping ldap server');

openldap.LDAP_STOP();

forceDirectories(FolderCible+'/datas/ldap');
forceDirectories(FolderCible+'/datas/mysql');
forceDirectories(FolderCible+'/datas/artica');
forceDirectories(FolderCible+'/datas/attachments');
forceDirectories(FolderCible+'/datas/original_messages');
forceDirectories(FolderCible+'/datas/CompressQueue');
forceDirectories(FolderCible+'/datas/HtmlsizeQueue');



cmd:=SYS.LOCATE_SLAPCAT() + ' -v -f '+openldap.SLAPD_CONF_PATH()+' -l '+FolderCible+'/datas/ldap/ldap.ldif';
logs.OutputCmd(cmd);

if not FileExists(FolderCible+'/datas/ldap/ldap.ldif') then begin
       logs.Syslogs('Error while backup ldap datas...');
       SendNotif(false);
       exit;
end;

logs.OutputCmd('/bin/cp '+ openldap.SLAPD_CONF_PATH() + ' ' + FolderCible+'/datas/ldap/slapd.conf');
logs.OutputCmd('/bin/cp -rf /etc/artica-postfix/* ' + FolderCible+'/datas/artica');

logs.Syslogs('New ldap backup performed with ' +IntTOStr(logs.GetFileSizeMo(FolderCible+'/datas/ldap/ldap.ldif')) + ' Mb size');
openldap.LDAP_START();

 GetProgress(15,'backup IMAP/POP3 Mailboxes');

Backup_cyrus(FolderCible);


 GetProgress(20,'backup Mysql Databases');

logs.Syslogs('#################################');
logs.Syslogs('#                               #');
logs.Syslogs('#          Mysql backup         #');
logs.Syslogs('#                               #');
logs.Syslogs('#################################');


if FileExists(SYS.LOCATE_MYSHOTCOPY()) then begin
        mysql_password:=SYS.MYSQL_INFOS('database_password');
        mysql_user:=SYS.MYSQL_INFOS('database_admin');
        if length(mysql_password)>0 then mysql_password:=' --password='+mysql_password;
        
        for i:=0 to databases_list.Count-1 do begin
            db:=databases_list.Strings[i];
            cmd:=SYS.LOCATE_MYSHOTCOPY()+' --quiet --user='+mysql_user+mysql_password +' '+db+' '+FolderCible+'/datas/mysql';
            logs.OutputCmd(cmd);
        end;


end else begin
    logs.Syslogs('could not locate mysqlhotcopy...mysql database will be not backuped...');
end;


GetProgress(30,'backup quarantines/backup mail Databases');


logs.Syslogs('#################################');
logs.Syslogs('#                               #');
logs.Syslogs('#          Quarantine           #');
logs.Syslogs('#         Backuped mails        #');
logs.Syslogs('#                               #');
logs.Syslogs('#################################');


HtmlsizeQueue:=SYS.GET_INFO('HtmlsizeQueue');
CompressQueue:=SYS.GET_INFO('CompressQueue');

SetCurrentDir('/opt/artica/share/www/attachments');
logs.OutputCmd('cp -rf /opt/artica/share/www/attachments/*  ' + FolderCible+'/datas/attachments/');
SetCurrentDir('/opt/artica/share/www/original_messages');
logs.OutputCmd('cp -rf /opt/artica/share/www/original_messages/*  ' + FolderCible+'/datas/original_messages/');

if length(CompressQueue)>0 then begin
    SetCurrentDir(CompressQueue);
    logs.OutputCmd('cp -rf '+CompressQueue+'/*  ' + FolderCible+'/datas/CompressQueue/');
end;

if length(HtmlsizeQueue)>0 then begin
    SetCurrentDir(HtmlsizeQueue);
    logs.OutputCmd('cp -rf '+HtmlsizeQueue+'/*  ' + FolderCible+'/datas/HtmlsizeQueue/');
end;

GetProgress(40,'backup mail Databases');

Backup_cyrus(FolderCible);

GetProgress(50,'backup artica configuration');

Backup_artica_config(FolderCible);



logs.Syslogs('Compress datafiles in ' + FolderCible);

GetProgress(70,'Build container from '+ subfolder+'...');

SetCurrentDir(FolderCible);

cmd:='cd '+ FolderCible +' && tar -czf ' + subfolder+'.tar.gz *';
logs.OutputCmd(cmd);
SetCurrentDir('/root');

GetProgress(70,'Cleaning temporary datas '+ subfolder+'...');

cmd:='/bin/mv '+FolderCible+'/'+ subfolder+'.tar.gz ' +FolderOrg+'/artica-export.tar.gz';
logs.OutputCmd(cmd);

GetProgress(75,'New container  ' + FolderOrg+'/artica-export.tar.gz');
logs.Syslogs('New container  ' + FolderOrg+'/artica-export.tar.gz');

fpsystem('/bin/rm -rf '+FolderCible);
SendNotif(true);
logs.NOTIFICATION('[ARTICA]: ('+SYS.HOSTNAME_g()+') backup task success','New backup container '+ FolderOrg+'/artica-export.tar.gz performed with ' +IntTOStr(logs.GetFileSizeMo(FolderOrg+'/artica-export.tar.gz')) + ' Mb size','backup');
logs.Syslogs('New backup container '+ FolderOrg+'/artica-export.tar.gz performed with ' +IntTOStr(logs.GetFileSizeMo(FolderOrg+'/artica-export.tar.gz')) + ' Mb size');
logs.OutputCmd('/etc/init.d/artica-postfix start daemon');

logs.Debuglogs('move to ressource');
GetProgress(90,'move to ressource...');
if mount.IsMounted then begin
      logs.OutputCmd('/bin/cp -f '+ FolderOrg+'/artica-export.tar.gz '+mount.TargetFolderToBackup+'/artica-export.tar.gz');
      if FileExists(mount.TargetFolderToBackup+'/artica-export.tar.gz') then begin
         logs.Syslogs('New container  ' + mount.TargetFolderToBackup+'/artica-export.tar.gz success');
         logs.DeleteFile(FolderOrg+'/artica-export.tar.gz');
          mount.DisMount();
      end else begin
          logs.Syslogs('Error while move container to target source...');
          GetProgress(110,'Error while move container to target source...');
          mount.DisMount();
         exit;
      end;
end else begin
    logs.Debuglogs('mount:: is not mounted...');
end;
GetProgress(100,'{success}');
mount.free;
end;


//##############################################################################
procedure tbackup.Backup_cyrus(backup_folder:string);
var cyrus_path,cmd,configdirectory:string;
begin
   if not FileExists(cyrus.CYRUS_DAEMON_BIN_PATH()) then exit;

logs.Syslogs('Backup_cyrus:: Stopping cyrus in order to perform backup');
cyrus_path:=cyrus.IMAPD_GET('partition-default');
configdirectory:=cyrus.IMAPD_GET('configdirectory');

if not FileExists(cyrus_path) then begin
   logs.Syslogs('Backup_cyrus:: Unable to stat partition-default');
   exit;
end;
logs.Syslogs('#################################');
logs.Syslogs('#                               #');
logs.Syslogs('#          Cyrus backup         #');
logs.Syslogs('#                               #');
logs.Syslogs('#################################');
forceDirectories(backup_folder+'/cyrus');
logs.Debuglogs('Stopping cyrus');
cyrus.CYRUS_DAEMON_STOP();
SetCurrentDir(cyrus_path);
cmd:='tar -czf ' + backup_folder+'/cyrus/partition-default.tar.gz *';
logs.OutputCmd(cmd);
logs.Syslogs('New cyrus backup performed with ' +IntTOStr(logs.GetFileSizeMo(cyrus_path+'/cyrus/partition-default.tar.gz')) + ' Mb size');
   
   logs.Debuglogs('Exporting mailboxlist');
//   logs.Debuglogs('su - cyrus -c "'+SYS.LOCATE_ctl_mboxlist()+' -d" >'+configdirectory+'/mailboxlist.txt');
   logs.OutputCmd('su - cyrus -c "'+SYS.LOCATE_ctl_mboxlist()+' -d" >'+configdirectory+'/mailboxlist.txt');
   SetCurrentDir(configdirectory);
   cmd:='/bin/tar -czf ' + backup_folder+'/cyrus/configdirectory.tar.gz *';
   logs.OutputCmd(cmd);
   SetCurrentDir('/root');
   logs.Debuglogs('Executing backup...');
   logs.Debuglogs('starting cyrus');
 cyrus.CYRUS_DAEMON_START();
end;

//##############################################################################
procedure tbackup.Backup_artica_config(backup_folder:string);
var cyrus_path,cmd:string;
begin

logs.Syslogs('#################################');
logs.Syslogs('#                               #');
logs.Syslogs('#      Artica parameters        #');
logs.Syslogs('#                               #');
logs.Syslogs('#################################');
       forceDirectories(backup_folder+'/artica/Daemons');
       logs.OutputCmd('/bin/cp /etc/artica-postfix/settings/Daemons/* '+backup_folder+'/artica/Daemons');




end;

//##############################################################################


procedure tbackup.perform_stop();
begin
logs.DeleteFile('/etc/artica-postfix/artica-backup.pid');
end;

//##############################################################################
procedure tbackup.perform_restore_old(FilePath:string);
var
   cmd:string;
   ldap_databases:string;
   temp_folder:string;
   filename:string;
   db:string;
   mysql_password:string;
   mysql_user:string;
   mysql_port:string;
   mysql_host:string;
   i:integer;
begin

temp_folder:='/home/artica/restore';

if not FileExists(FilePath) then begin
   logs.Debuglogs('perform_restore:: unable to stat ' + filepath);
   halt(0);
   exit;
end;
if DirectoryExists(temp_folder) then fpsystem('/bin/rm -rf '+temp_folder);
forceDirectories(temp_folder);

if not FileExists(SYS.LOCATE_SLAPADD()) then begin
        logs.Debuglogs('perform_restore:: Fatal error, unable to locate slapadd binary... halt');
        halt(0);
        exit;
end;

if not FileExists(openldap.SLAPD_CONF_PATH()) then begin
        logs.Debuglogs('Fatal error, unable to locate ldap daemon configuration file... halt');
        halt(0);
        exit;
end;

cmd:='tar -xf ' + FilePath +' -C '+temp_folder;
logs.OutputCmd(cmd);
if FileExists(temp_folder+'/datas/ldap/ldap.ldif') then begin
   if FileExists(temp_folder+'/datas/ldap/slapd.conf') then begin
      logs.Debuglogs('perform_restore:: restoring ldap database...');
      logs.OutputCmd('/bin/mv '+temp_folder+'/datas/ldap/slapd.conf '+ openldap.SLAPD_CONF_PATH());
      logs.OutputCmd('/bin/mv '+temp_folder+'/datas/ldap/artica-postfix-ldap.conf  /etc/artica-postfix/artica-postfix-ldap.conf');
      
      ldap_databases:=openldap.LDAP_DATABASES_PATH();
      logs.Debuglogs('perform_restore:: ldap database is ' + ldap_databases);
      if DirectoryExists(ldap_databases) then begin
         logs.Syslogs('Stopping ldap server');
         openldap.LDAP_STOP();
         logs.OutputCmd('/bin/rm -rf '+ldap_databases+'/*');
         cmd:=SYS.LOCATE_SLAPADD()+' -v -c -l '+temp_folder+'/datas/ldap/ldap.ldif -f ' + openldap.SLAPD_CONF_PATH();
         logs.OutputCmd(cmd);
         cmd:=SYS.LOCATE_SLAPINDEX();
         logs.OutputCmd(cmd);
         perform_stop();
      end else begin
        logs.Debuglogs('perform_restore:: unable to stat '+ldap_databases);
      end;
   end else begin
      logs.Debuglogs('perform_restore:: unable to stat '+temp_folder+'/datas/ldap/slpad.conf');
   end;
end else begin
    logs.Debuglogs('perform_restore:: unable to stat '+temp_folder+'/datas/ldap/ldap.ldif');

end;

        mysql_password:=SYS.MYSQL_INFOS('database_password');
        mysql_user:=SYS.MYSQL_INFOS('database_admin');
        mysql_host:=SYS.MYSQL_INFOS('mysql_server');
        mysql_port:=SYS.MYSQL_INFOS('port');


for i:=0 to databases_list.Count-1 do begin
         db:=databases_list.Strings[i];
         filename:=temp_folder+'/datas/mysql/'+db+'.sql';
         if FileExists(filename) then begin
            cmd:=SYS.LOCATE_mysql_bin() +' --host='+mysql_host+' --port='+ mysql_port +' --user='+mysql_user+'  --password='+mysql_password;
            cmd:=cmd+ ' <'+filename;
            logs.Debuglogs('Restoring mysql database ' +db);
            logs.OutputCmd(cmd);
         end else begin
            logs.Debuglogs('!! Unable to stat ' + filename);
         end;
end;



fpsystem('/bin/rm -rf ' + temp_folder);
logs.OutputCmd(' /usr/share/artica-postfix/bin/artica-apt');
logs.OutputCmd('/etc/init.d/artica-postfix restart');
logs.OutputCmd(' /usr/share/artica-postfix/bin/process1 --verbose');
retranslate_backup();
halt(0);


end;

//##############################################################################
procedure tbackup.retranslate_backup();
var
   bcktool:trdiffbackup;
   l:TstringList;
   d:TstringList;
   i:integer;
   dev_source:string;
   vtype:string;
   target_mount:string;
begin
   if not FileExists('/etc/artica-postfix/artica-hd-backup.conf') then exit;
   
   l:=TStringList.Create;
   d:=TstringList.Create;
   l.LoadFromFile('/etc/artica-postfix/artica-hd-backup.conf');
   for i:=0 to l.Count-1 do begin
       if length(l.Strings[i])>0 then d.Add(l.Strings[i]);
   end;
   
   if d.Count=0 then exit;
   

   bcktool:=trdiffbackup.Create;

   if not FileExists(bcktool.dar_bin_path()) then begin
      logs.Syslogs('Unable to stat "dar" tool, the backup translation task cannot be performed without this tool...');
      exit;
   end;
   

   
   for i:=0 to d.Count-1 do begin
        if SYS.DISK_USB_EXISTS(d.Strings[i]) then begin
             dev_source:=SYS.DISK_USB_DEV_SOURCE(d.Strings[i]);
             vtype:=SYS.DISK_USB_TYPE(d.Strings[i]);
             if length(dev_source)=0 then begin
                logs.Syslogs('unable to locate /dev/*  source for '+d.Strings[i] +' device..');
                continue;
             end;

             if length(vtype)=0 then begin
                logs.Syslogs('unable to determine type source for '+d.Strings[i] +' device..');
                continue;
             end;
             target_mount:='/opt/artica/hdbackup/' + d.Strings[i];
             forceDirectories(target_mount);
             logs.Syslogs(d.Strings[i] + '('+vtype+') is plugged on ' + dev_source);
             if not SYS.DISK_USB_IS_MOUNTED(dev_source,target_mount) then begin
                logs.Syslogs('mount it on '+target_mount);
                logs.OutputCmd('mount -t ' + vtype + ' ' + dev_source + ' ' +target_mount);
             end;
             
             if not SYS.DISK_USB_IS_MOUNTED(dev_source,target_mount) then begin
                 logs.Syslogs('unable to mount '+dev_source+ ' abort...');
                 continue;
             end else begin
                 logs.Syslogs('mounted '+dev_source+ ' on ' + target_mount);
             end;
             
             
              logs.Syslogs('running backup process...');
              dar(dev_source,target_mount,d.Strings[i]);
              fpsystem('umount ' + target_mount);
              logs.OutputCmd('/bin/rmdir ' + target_mount);

             
             
        end else begin
            logs.Syslogs(d.Strings[i] + ' device is not plugged');
        end;
   
   end;
end;
//##############################################################################
function tbackup.dar(dev_source:string;target_source:string;uuid:string):boolean;
var
  bcktool:trdiffbackup;
  backup_path:string;
  cmd:string;
  attachmentdir:string;
  fullmessagesdir:string;
  tempstr:string;
  smb:tsamba;
  smblist:TstringList;
  i:integer;
  header:string;
  RegExpr:TRegExpr;
begin
  result:=false;
  bcktool:=trdiffbackup.Create;
  backup_path:=GET_BACKUP_INFO('backup_path');
  
  
  if not SYS.DISK_USB_IS_MOUNTED(dev_source,target_source) then begin
      logs.Syslogs('unable to mount '+dev_source+ ' abort...');
      exit;
  end;
  
  if not FileExists(bcktool.dar_bin_path()) then begin
     logs.Syslogs('tbackup.dar():: Unable to stat "dar" tool, the backup translation task cannot be performed without this tool...');
     exit;
  end;
  forceDirectories(target_source+'/artica-backup-storage');
  dar_results:=TstringList.Create;
  tempstr:=logs.FILE_TEMP();
  logs.Syslogs('running backup process on ldap/mysql/cyrus storages...');
  
  
  dar_results.Add(backup_path+':');
  cmd:= bcktool.build_dar_command(target_source+'/artica-backup-storage/main',backup_path)+ ' >'+tempstr+' 2>&1';
  logs.Debuglogs(cmd);
  fpsystem(cmd);
  dar_results.Add(logs.ReadFromFile(tempstr));
  logs.Syslogs('running backup process on artica backup storages...');
  
  if not SYS.DISK_USB_IS_MOUNTED(dev_source,target_source) then begin
      logs.Syslogs('unable to mount '+dev_source+ ' abort...');
      exit;
  end;
  
   attachmentdir:='/opt/artica/share/www/attachments';
   fullmessagesdir:='/opt/artica/share/www/original_messages';



   //---------------------------------------------------------------------------------------------------------------------
   cmd:= bcktool.build_dar_command(target_source+'/artica-backup-storage/attachments',attachmentdir) + ' >'+tempstr+' 2>&1';
   logs.Debuglogs(cmd);
   fpsystem(cmd);
   dar_results.Add(attachmentdir+':');
   dar_results.Add(logs.ReadFromFile(tempstr));

  

   //---------------------------------------------------------------------------------------------------------------------
   cmd:= bcktool.build_dar_command(target_source+'/artica-backup-storage/original_messages',fullmessagesdir)+ ' >'+tempstr+' 2>&1';
   logs.Debuglogs(cmd);
   fpsystem(cmd);
   dar_results.Add(fullmessagesdir+':');
   dar_results.Add(logs.ReadFromFile(tempstr));
   
   smb:=Tsamba.Create;
   if FileExists(smb.SMBD_PATH()) then begin
       smblist:=TstringList.Create;
       smblist.AddStrings(smb.ParseSharedDirectories());
       smblist.Addstrings(bcktool.PERSO_BACKUPS_LIST());
       
       logs.Syslogs('running backup process on '+ IntToStr(smblist.Count)+' shared samba folder(s)...');
       for i:=0 to smblist.Count-1 do begin
           if smblist.Strings[i]='/media' then begin
             logs.Syslogs(smblist.Strings[i] + ' skipped');
             continue;
           end;
           
           if smblist.Strings[i]='/etc' then begin
             logs.Syslogs(smblist.Strings[i] + ' skipped');
             continue;
           end;
           
           if smblist.Strings[i]='/usr' then begin
             logs.Syslogs(smblist.Strings[i] + ' skipped');
             continue;
           end;
           
           if smblist.Strings[i]='/var' then begin
             logs.Syslogs(smblist.Strings[i] + ' skipped');
             continue;
           end;
           
           if length(smblist.Strings[i])<3 then continue;
           
           logs.Syslogs('running backup process on '+smblist.Strings[i]);
           header:=AnsiReplaceText(smblist.Strings[i],'/','-');
           header:=AnsiReplaceText(header,' ','-');
           header:=AnsiReplaceText(header,'.','-');
           
           if Copy(header,0,1)='-' then header:=Copy(header,2,length(header));
           cmd:= bcktool.build_dar_command(target_source+'/artica-backup-storage/'+header,smblist.Strings[i])+ ' >'+tempstr+' 2>&1';
           logs.Debuglogs(cmd);
           fpsystem(cmd);
           dar_results.Add(smblist.Strings[i]+':');
           dar_results.Add(logs.ReadFromFile(tempstr));
       end;
   end;
       
  logs.NOTIFICATION('[ARTICA]: backup/retranslation performed on "'+target_source+'"',dar_results.Text,'backup');
  dar_results.Clear;
  dar_results.AddStrings(sys.DirFiles(target_source+'/artica-backup-storage','*.dar'));
  RegExpr:=TRegExpr.Create;
  RegExpr.Expression:='(.+?)\.';
  
  for i:=0 to dar_results.Count-1 do begin
      header:=ExtractFileName(dar_results.Strings[i]);
      if RegExpr.Exec(header) then header:=RegExpr.Match[1];
      if not bcktool.DAR_DATABASE_EXISTS(header,uuid) then begin
         logs.OutputCmd('/usr/bin/dar_manager -A '+target_source+'/artica-backup-storage/'+header + ' -B /opt/artica/share/dar/'+uuid+'.db');
      end;
  end;
  
  

  
  logs.Syslogs('success backup ' + backup_path);
   dar_results.Free;
end;
//##############################################################################
function tbackup.dar_restore_single(TargetFile:string;Database:string;uuid:string):boolean;
var
  bcktool:trdiffbackup;
  database_path:string;
  restore_path:string;
  target_mount:string;
  l:TstringList;
  tmpstr:string;
  cmd:string;
begin

  l:=TstringList.Create;
  tmpstr:=logs.FILE_TEMP();
  if not uuid_mount(uuid) then begin

      l.Add('Unable to mount ' + uuid);
      l.SaveToFile(ParamStr(5));
      halt(0);
  end;
  bcktool:=trdiffbackup.Create;
  target_mount:='/opt/artica/hdbackup/' + uuid;
  restore_path:='/opt/artica/restore';

  database_path:=bcktool.DAR_DATABASE_PATH(uuid,Database);
  l.Add('Restore from '+database_path + ' database...');
  l.Add('Restore to '+restore_path);
  
  SetCurrentDir(restore_path);
  l.Add('Current directory ' + GetCurrentDir());
  
  ForceDirectories(restore_path);
  
  
  cmd:=bcktool.dar_bin_path() +' -Q -wa -x '+database_path+' -g '+TargetFile +' >'+tmpstr +' 2>&1';
  logs.Debuglogs(cmd);
  fpsystem(cmd);
  l.Add(logs.ReadFromFile(tmpstr));

  fpsystem('umount ' + target_mount);
  logs.OutputCmd('/bin/rmdir ' + target_mount);
  if FileExists(restore_path+'/'+TargetFile) then begin
        l.Add(restore_path+'/'+TargetFile+' restored success...');
  end else begin
        l.Add('Unable to stat ' + restore_path+'/'+TargetFile+' failed');
  end;
  
  l.SaveToFile(ParamStr(5));
end;
//##############################################################################
function tbackup.dar_restore_database(Database:string;uuid:string;target_folder:string):boolean;
var
  bcktool:trdiffbackup;
  database_path:string;
  restore_path:string;
  target_mount:string;
  l:TstringList;
  tmpstr:string;
  cmd:string;
  db_path:string;
begin


  l:=TstringList.Create;
  tmpstr:=logs.FILE_TEMP();
  if not uuid_mount(uuid) then begin
      l.Add('Unable to mount ' + uuid);
      l.SaveToFile(ParamStr(5));
      logs.Debuglogs(l.Text);
      halt(0);
  end;
  bcktool:=trdiffbackup.Create;
  target_mount:='/opt/artica/hdbackup/' + uuid;
  database_path:=bcktool.DAR_DATABASE_PATH(uuid,Database);
  restore_path:=target_folder;
  
  l.Add('Restore from '+database_path + ' database...');
  l.Add('Restore to '+restore_path);

  SetCurrentDir(restore_path);
  l.Add('Current directory ' + GetCurrentDir());

  ForceDirectories(restore_path);


  cmd:=bcktool.dar_bin_path() +' -Q -wa -x '+database_path+' >'+tmpstr +' 2>&1';
  logs.Debuglogs(cmd);
  fpsystem(cmd);
  l.Add(logs.ReadFromFile(tmpstr));

  fpsystem('umount ' + target_mount);
  logs.OutputCmd('/bin/rmdir ' + target_mount);
  l.SaveToFile(ParamStr(5));
  logs.Debuglogs(l.Text);
end;
//##############################################################################



function tbackup.uuid_mount(uuid:string):boolean;
var
    dev_source,vtype,target_mount:string;
begin
  result:=false;
  if not SYS.DISK_USB_EXISTS(uuid) then begin
     logs.Syslogs(uuid+' is not plugged, aborting');
     exit;
  end;
   dev_source:=SYS.DISK_USB_DEV_SOURCE(uuid);
   vtype:=SYS.DISK_USB_TYPE(uuid);
   if length(dev_source)=0 then begin
      logs.Syslogs('unable to locate /dev/*  source for '+uuid +' device..');
      exit;
   end;

   if length(vtype)=0 then begin
      logs.Syslogs('unable to determine type source for '+uuid +' device..');
      exit;
   end;

target_mount:='/opt/artica/hdbackup/' + uuid;
forceDirectories(target_mount);
writeln(uuid + '('+vtype+') is plugged on ' + dev_source);
 if not SYS.DISK_USB_IS_MOUNTED(dev_source,target_mount) then begin
    logs.Syslogs('mount it on '+target_mount);
    logs.OutputCmd('mount -t ' + vtype + ' ' + dev_source + ' ' +target_mount);
 end;

 if not SYS.DISK_USB_IS_MOUNTED(dev_source,target_mount) then begin
    logs.Syslogs('unable to mount '+dev_source+ ' abort...');
    exit;
 end else begin
     logs.Syslogs('mounted '+dev_source+ ' on ' + target_mount);
 end;
 
 result:=true;
 exit(true);

end;
//##############################################################################

procedure tbackup.SendNotif(ok:boolean);
begin
if ok then begin
   logs.Debuglogs('Send Notifications...result=OK');
   logs.NOTIFICATION('[ARTICA]: ('+SYS.HOSTNAME_g()+') success backup (main)',ParseSyslog(),'backup');
end else begin
       logs.Debuglogs('Send Notifications...result=NO');
    logs.NOTIFICATION('[ARTICA]: ('+SYS.HOSTNAME_g()+') failed backup (main)',ParseSyslog(),'backup');
end;
end;
//##############################################################################
function tbackup.ParseSyslog():string;
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
procedure tbackup.REBUILD_LDAP_DATABASES();
var
   tempfile,cmd:string;
   databases_path,s:string;
   RegExpr:TRegExpr;
   i:Integer;
begin
  RegExpr:=TRegExpr.Create;

    s:='';

 if ParamCount>0 then begin
     for i:=1 to ParamCount do begin
        s:=s  + ' ' +ParamStr(i);

     end;
     s:=trim(s);
 end;
 tempfile:=logs.FILE_TEMP();
 RegExpr.Expression:='--file=(.+?)\s+';
 if RegExpr.Exec(s) then tempfile:=RegExpr.Match[1];




databases_path:=openldap.LDAP_DATABASES_PATH();

logs.Syslogs('Ldap conf file......: '+openldap.SLAPD_CONF_PATH());
logs.Syslogs('Ldap databases......: '+databases_path);

if length(databases_path)=0 then begin
    logs.Syslogs('Unable to stat database path !');
    exit;
end;


logs.Syslogs('Rebuild the local LDAP database');
if not FileExists(tempfile) then begin
   logs.Syslogs('Backup database in "'+tempfile+'"');
   cmd:=SYS.LOCATE_SLAPCAT() + ' -v -f '+openldap.SLAPD_CONF_PATH()+' -l '+tempfile;
   logs.OutputCmd(cmd);
end;

logs.Syslogs('Stopping ldap');
logs.OutputCmd('/etc/init.d/artica-postfix stop ldap');
logs.Syslogs('Delete old database files');
logs.RemoveFilesAndDirectories(databases_path,'/*.*');
logs.Syslogs('importing datas');
cmd:=SYS.LOCATE_SLAPADD()+' -v -c -l '+tempfile+' -f ' + openldap.SLAPD_CONF_PATH();
logs.OutputCmd(cmd);

logs.Syslogs('Starting LDAP');
logs.OutputCmd('/etc/init.d/artica-postfix start ldap');
logs.Syslogs('Done...');

end;
//##############################################################################
procedure tbackup.REBUILD_ARTICA_BRANCH();
var
   tempfile_a,tempfile_b,cmd:string;
   databases_path,s:string;
   RegExpr:TRegExpr;
   time:string;
   i:Integer;
begin
  RegExpr:=TRegExpr.Create;
  time:=FormatDateTime('yyyy-mm-dd-hh', Now);

 databases_path:=openldap.LDAP_DATABASES_PATH();

logs.Syslogs('Ldap conf file......: '+openldap.SLAPD_CONF_PATH());
logs.Syslogs('Ldap databases......: '+databases_path);
logs.Syslogs('suffix..............: '+openldap.ldap_settings.suffix);

if length(databases_path)=0 then begin
    logs.Syslogs('Unable to stat database path !');
    exit;
end;


logs.Syslogs('Rebuild the local LDAP database');

forceDirectories('/opt/artica/ldap-repair');

tempfile_a:='/opt/artica/ldap-repair/ldap-full-'+time+'.ldif';
tempfile_b:='/opt/artica/ldap-repair/ldap-artica-'+time+'.ldif';

if not FileExists(tempfile_a) then begin
   logs.Syslogs('Backup full database in "'+tempfile_a+'"');
   cmd:=SYS.LOCATE_SLAPCAT() + ' -a "(!(entryDN:dnSubtreeMatch:=cn=artica,'+openldap.ldap_settings.suffix+'))"  -v -f '+openldap.SLAPD_CONF_PATH()+' -l '+tempfile_a;
   logs.OutputCmd(cmd);
end;


if not FileExists(tempfile_b) then begin
   logs.Syslogs('Backup full database in "'+tempfile_b+'"');
   cmd:=SYS.LOCATE_SLAPCAT() + ' -a "(entryDN:dnSubtreeMatch:=cn=artica,'+openldap.ldap_settings.suffix+')"  -v -f '+openldap.SLAPD_CONF_PATH()+' -l '+tempfile_b;
   logs.OutputCmd(cmd);
end;

logs.Syslogs('Stopping ldap');
logs.OutputCmd('/etc/init.d/artica-postfix stop ldap');
logs.OutputCmd('/etc/init.d/artica-postfix stop ldap');
logs.Syslogs('Delete old database files');
logs.RemoveFilesAndDirectories(databases_path,'/*.*');
logs.Syslogs('importing datas');

cmd:=SYS.LOCATE_SLAPADD()+' -v -c -l '+tempfile_a+' -f ' + openldap.SLAPD_CONF_PATH();
logs.OutputCmd(cmd);
logs.Syslogs('Starting LDAP');
logs.OutputCmd('/etc/init.d/artica-postfix start ldap');
logs.Syslogs('Creating artica branch');
fpsystem(SYS.LOCATE_PHP5_BIN() +' /usr/share/artica-postfix/exec.buildartica.php');
logs.Syslogs('Stopping ldap');
logs.OutputCmd('/etc/init.d/artica-postfix stop ldap');
logs.OutputCmd('/etc/init.d/artica-postfix stop ldap');
logs.Syslogs('importing datas');
cmd:=SYS.LOCATE_SLAPADD()+' -v -c -l '+tempfile_b+' -f ' + openldap.SLAPD_CONF_PATH();
logs.Syslogs('Done...');
logs.Syslogs('Starting LDAP');
logs.OutputCmd('/etc/init.d/artica-postfix start ldap');
fpsystem(SYS.LOCATE_PHP5_BIN() +' /usr/share/artica-postfix/exec.postfix.maincf.php --ldap-branch --reload');


end;
//##############################################################################
procedure tbackup.INSTANT_RECOVER_LDAP_DATABASES(filename:string);
var
   tempfile,cmd:string;
   ldifFile:string;
   databases_path,s:string;
   RegExpr:TRegExpr;
   MustDecompress:boolean;
   remote_slpad_conf:string;
begin
  RegExpr:=TRegExpr.Create;
  ldifFile:=filename;
  MustDecompress:=false;
  ldifFile:=AnsiReplaceText(ldifFile,'.tar.gz','.ldif');
  databases_path:=openldap.LDAP_DATABASES_PATH();

  if not FileExists(filename) then begin
     logs.Debuglogs('INSTANT_RECOVER_LDAP_DATABASES:: '+filename+' is not available, try "/opt/artica/ldap-backup/' + filename+'"');
     tempfile:='/opt/artica/ldap-backup/' + filename;
  end else begin
     tempfile:=filename;
  end;

if not FileExists(tempfile) then begin
   logs.debuglogs('INSTANT_RECOVER_LDAP_DATABASES:: Unable to stat '+tempfile);
   exit;
end;

remote_slpad_conf:=ExtractFileDir(tempfile)+'/slapd.conf';
if FileExists(remote_slpad_conf) then begin
       logs.debuglogs('INSTANT_RECOVER_LDAP_DATABASES:: Replicate configuration file '+remote_slpad_conf+' in ' +openldap.SLAPD_CONF_PATH());
       logs.WriteToFile(logs.ReadFromFile(remote_slpad_conf),openldap.SLAPD_CONF_PATH());
end else begin
      logs.Debuglogs('unable to stat '+remote_slpad_conf);
end;

RegExpr:=TRegExpr.Create;
RegExpr.Expression:='\.(tar|gz)$';
if RegExpr.Exec(filename) then begin
   MustDecompress:=true;
   logs.debuglogs('INSTANT_RECOVER_LDAP_DATABASES:: '+ExtractFileName(filename)+' ('+RegExpr.Match[1]+') must be unpack');
end;

logs.debuglogs('INSTANT_RECOVER_LDAP_DATABASES:: Ldap conf file......: '+openldap.SLAPD_CONF_PATH());
logs.debuglogs('INSTANT_RECOVER_LDAP_DATABASES:: Ldap ldif file......: '+ldifFile);
logs.debuglogs('INSTANT_RECOVER_LDAP_DATABASES:: Ldap backup file....: '+tempfile);
logs.debuglogs('INSTANT_RECOVER_LDAP_DATABASES:: Ldap Databases path.: '+databases_path);

if MustDecompress then begin
   logs.debuglogs('INSTANT_RECOVER_LDAP_DATABASES:: Extract file '+filename);
   ForceDirectories('/opt/artica/ldap-backup');
   fpsystem('/bin/tar -xf '+tempfile+' -C /opt/artica/ldap-backup/');

   if not FileExists('/opt/artica/ldap-backup/' + ldifFile) then begin
      logs.debuglogs('Unable to stat decompressed file !');
      exit;
   end;

   ldifFile:='/opt/artica/ldap-backup/' + ExtractFileName(ldifFile);

end;



if length(databases_path)=0 then begin
    logs.debuglogs('Unable to stat database path !');
    exit;
end;

if not DirectoryExists(databases_path) then begin
   logs.debuglogs('Unable to stat Directory "'+databases_path+'"');
    exit;
end;


logs.debuglogs('Delete old database files');
logs.RemoveFilesAndDirectories(databases_path,'/*.*');
logs.debuglogs('Stopping ldap');
logs.OutputCmd('/etc/init.d/artica-postfix stop ldap');
logs.debuglogs('********************************************************');
logs.debuglogs('importing datas');
openldap.SET_DB_CONFIG();
cmd:=SYS.LOCATE_SLAPADD()+' -v -s -c -l '+ldifFile+' -f ' + openldap.SLAPD_CONF_PATH();
logs.OutputCmd(cmd);
logs.debuglogs('********************************************************');
logs.debuglogs('Starting LDAP');
logs.OutputCmd('/etc/init.d/artica-postfix start ldap >/dev/null 2&>1');
logs.debuglogs('********************************************************');
logs.debuglogs('Done...');
logs.debuglogs('********************************************************');
if MustDecompress then  logs.DeleteFile(ldifFile);

end;
//##############################################################################




end.
