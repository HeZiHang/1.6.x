unit incremental_backup;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,IniFiles, Process,logs,unix,RegExpr in 'RegExpr.pas',zsystem,rdiffbackup,cyrus,samba,mysql_daemon,openldap,backup_rsync,
    dar_events,mount_class;

  type
  tincrement=class


private
     LOGS:Tlogs;
     D:boolean;
     SYS:Tsystem;
     artica_path:string;
     Enable:integer;
     dar_folder:string;
     dar_bin:string;
     dar_manager:string;
     ddar:trdiffbackup;
     artica_conf:integer;
     exludeCommandFiles:string;
     minimal_compress:integer;
     compress_level:integer;
     slice_size_mb:integer;
     ldap_datas:integer;
     mysql_datas:integer;
     OnFly:integer;
     nice_int:integer;
     mailboxes_datas:integer;
     homes:integer;
     samba:Tsamba;
     user_defined:integer;
     shares_folders:integer;
     ExcludeSambaFolders:TstringList;
     ExcludeHomesFolders:TstringList;
     PersoFoldersList:TstringList;
     external_ressource:string;
     TargetFolderToBackup:string;
     localsubfolder:string;
     use_local_external_failed:integer;
     external_storages:TstringList;
     remote_rsync:tbackup_rsync;
     UseOnlyRsync:Integer;
     events:tdar_events;
     mount:tmount;
     ccyrus:TCyrus;
     procedure ParseConfig();
     procedure WriteProgress(progress:integer);
     procedure Add_user_defined(name_path:string;original_path:string);
     procedure artica_backup_single_path_op(path:string);

     function xmlSingle(database_path:string):string;
     function DetectCatalogError(logspath:string):boolean;
     procedure FindExternalResources();
     function DAR_CHECK_ERRORS(tmpfile:string):boolean;
     function DAR_CHECK_CONSISTENCY(database_path:string):boolean;
     procedure restore_status(progression:integer;status:string);
     function GetDatabaseName(pathToDB:String;numeric:string):string;


     procedure EXECUTE_DAR_OPERATIONS(source_folder:string;database_path:string);


     function  BuildDarCommand(source_backup:string;PathToBackup:string):string;
     function  isSambaExclude(path:string):boolean;
     function  isHomeExclude(path:string):boolean;
     procedure artica_conf_backup();
     procedure artica_mysql_backup();
     function  ifCatalogExists(pathToDB:String;CatalogName:string):boolean;
     procedure RestoreMysql(database:string);
     procedure RestoreLDAP(database:string);
     function  RestoreLDAP_Checkerrors(path:string):integer;
     procedure RestoreCyrusImapDatas(database:string);
     function  TargetMountedFolder():string;
     procedure PerformFullBackupOp();
     function  SelectCollectionStorage(sMD5:string):string;

public
    procedure   Free;
    constructor Create();
    procedure StartBackup();

    procedure artica_cyrus_backup();
    procedure artica_backupMails_backup();
    procedure artica_backup_samba_backup();
    procedure artica_backup_homes_backup();
    procedure artica_backup_perso_backup();
    procedure artica_ldap_backup();
    procedure query_file(pattern:string);
    procedure DAR_FIND_FILE(ressource:string;filepath:string);



    procedure list_collection();
    procedure xml(database:string);
    procedure RefreshCache();
    procedure RestoreDatabase(database:string;target_path:string;sMD5:string);
    procedure RestoreDatabaseSingleFile(file_path_database:string;database:string;sMD5:string;target_path:string);
    procedure artica_backup_single_path(path:string);
    procedure artica_RemoteComputer_backup(computer_name:string;user:string;password:string;remoteshare:string;remote_folder:string);
    procedure GetCollectionsSize();
    procedure BuildSingleCollection(path:string);
    procedure Build_collections(path:string);
    procedure dar_restore_path(inicommand:string);
    procedure dar_populate(resource:string);


END;

implementation

constructor tincrement.Create();
begin
       forcedirectories('/etc/artica-postfix');
       LOGS:=tlogs.Create();
       UseOnlyRsync:=0;
       SYS:=tsystem.Create;
       D:=LOGS.COMMANDLINE_PARAMETERS('debug');
       external_storages:=TStringList.Create;
       remote_rsync:=tbackup_rsync.Create;
       events:=tdar_events.Create;
       mount:=tmount.Create;
       forceDirectories('/var/log/artica-postfix/dar-queue');
       forceDirectories('/var/log/artica-postfix/increment-queue');



       if not TryStrToInt(SYS.GET_INFO('UseOnlyRsync'),UseOnlyRsync) then UseOnlyRsync:=0;

       ddar:=trdiffbackup.Create;
       if D then logs.Debuglogs('tincrement.Create():: debug=true');
       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;
             ParseConfig();
end;
//##############################################################################
procedure tincrement.free();
begin
    logs.Free;
    remote_rsync.free;
    mount.FRee;
end;
//##############################################################################
function tincrement.TargetMountedFolder():string;
begin
   result:=mount.TargetFolderToBackup;
   result:=result;
end;
//##############################################################################
procedure tincrement.query_file(pattern:string);
var collection:string;
begin
  if not mount.IsMounted then begin
     writeln('Unable to mount backup area');
     exit;
  end;
  collection:=TargetFolderToBackup+'/collection.dmd';
  if not FileExists(collection) then begin
      writeln('Unable to stat index file');
      exit;
  end;


  fpsystem(dar_manager +' -B '+collection+' -f '+pattern);



end;
//##############################################################################
procedure tincrement.xml(database:string);
var
   xmlfile:string;
   dbfilestr:string;
   dbint:string;
   cmd:string;
begin
  if not mount.IsMounted then begin
     writeln('Unable to mount backup area');
     exit;
  end;

  writeln(database);
  logs.Debuglogs('xml::Listing xml content for ' + database);
  xmlfile:=TargetFolderToBackup+'/'+database+'-md-'+mount.mounted_md5+'.ls';
  forceDirectories('/var/log/artica-postfix/increment-queue');
  logs.Debuglogs('xml::Listing xml file for ' + xmlfile);


 if sys.FileSize_ko(xmlfile)<5 then begin
    logs.Debuglogs('Delete ' +xmlfile+ ' ');
    logs.DeleteFile(xmlfile);
 end;

 if not FileExists(xmlfile) then begin
   cmd:=SYS.EXEC_NICE()+dar_bin +' -l '+TargetFolderToBackup+'/'+database+' >'+xmlfile+ ' 2>&1';
   logs.Debuglogs(cmd);
   fpsystem(cmd);
   logs.OutputCmd('/bin/cp '+xmlfile+' /var/log/artica-postfix/increment-queue/');
   logs.Debuglogs('xml::Listing size file for ' + IntToStr(sys.FileSize_ko(xmlfile)) + ' ko');
end;


end;
//##############################################################################
function tincrement.xmlSingle(database_path:string):string;
var
   xmlfile:string;
   dbfilestr:string;
   dbint:string;
   cmd:string;
   logPath:string;
begin
  if not mount.IsMounted then begin
     writeln('xmlSingle:: Unable to mount backup area');
     exit;
  end;

   logs.Debuglogs('xmlSingle:: database source.: ' + database_path);
   xmlfile:=extractFileName(database_path)+'-md-'+mount.mounted_md5+'.ls';
   logPath:='/var/log/artica-postfix/increment-queue/'+xmlfile;

   logs.Debuglogs('xmlSingle:: destination Path: '+logPath);

   cmd:=SYS.EXEC_NICE()+dar_bin +' -Q --noconf -l '+database_path+' >'+logPath+ ' 2>&1';
   logs.Debuglogs(cmd);
   fpsystem(cmd);
   logs.Debuglogs('xmlSingle::Listing size file for ' + IntToStr(sys.FileSize_ko(xmlfile)) + ' ko');


   if DAR_CHECK_ERRORS(xmlfile) then exit;
   if sys.FileSize_ko(xmlfile)=0 then logs.Debuglogs(logs.ReadFromFile(xmlfile));

   forceDirectories('/var/log/artica-postfix/increment-queue');
   logs.OutputCmd('/bin/cp ' + xmlfile+' /var/log/artica-postfix/increment-queue/');
   result:=xmlfile;
   logs.Debuglogs('xmlSingle::end..');
end;
//##############################################################################



procedure tincrement.ParseConfig();
var
   cf:TiniFile;
   l:TstringList;
   i:integer;
begin
     Enable:=0;
  if not FileExists('/etc/artica-postfix/settings/Daemons/DarBackupConfig') then begin
     logs.Debuglogs('tincrement.ParseConfig():: File is not saved expected /etc/artica-postfix/settings/Daemons/DarBackupConfig');
     exit;
  end;
  dar_bin:=ddar.dar_bin_path();
  dar_manager:=ddar.dar_manager_bin_path();
  cf:=TiniFile.Create('/etc/artica-postfix/settings/Daemons/DarBackupConfig');
  Enable:=cf.ReadInteger('GLOBAL','enable',0);
  dar_folder:=cf.ReadString('GLOBAL','dar_file','/home/artica/increment/backup');


  artica_conf:=cf.ReadInteger('BACKUP','artica_conf',0);
  ldap_datas:=cf.ReadInteger('BACKUP','ldap_datas',0);
  mysql_datas:=cf.ReadInteger('BACKUP','mysql_datas',0);
  OnFly:=cf.ReadInteger('BACKUP','OnFly',0);
  minimal_compress:=cf.ReadInteger('BACKUP','minimal_compress',512000);
  compress_level:=cf.ReadInteger('BACKUP','compress_level',6);
  slice_size_mb:=cf.ReadInteger('BACKUP','slice_size_mb',750);
  nice_int:=cf.ReadInteger('BACKUP','nice_int',15);
  shares_folders:=cf.ReadInteger('BACKUP','shares_folders',0);
  homes:=cf.ReadInteger('BACKUP','homes',0);
  user_defined:=cf.ReadInteger('BACKUP','user_defined',0);
  use_local_external_failed:=cf.ReadInteger('GLOBAL','use_local_external_failed',0);
  mailboxes_datas:=cf.ReadInteger('BACKUP','mailboxes',0);
  external_ressource:=cf.ReadString('GLOBAL','external_ressource','dir:'+dar_folder);


  l:=TstringList.Create;

  if Fileexists('/etc/artica-postfix/settings/Daemons/DarBackupExcludeFiles') then begin

     l.LoadFromFile('/etc/artica-postfix/settings/Daemons/DarBackupExcludeFiles');
     for i:=0 to l.Count-1 do begin
         if length(trim(l.Strings[i]))=0 then continue;
         exludeCommandFiles:=exludeCommandFiles+' -Z "'+l.Strings[i]+'"';

     end;
  end;
  l.Clear;
  ExcludeSambaFolders:=TStringList.Create;
  if Fileexists('/etc/artica-postfix/settings/Daemons/DarBackupExcludeSmbShares') then begin
     l.LoadFromFile('/etc/artica-postfix/settings/Daemons/DarBackupExcludeSmbShares');
     for i:=0 to l.Count-1 do begin
         if length(trim(l.Strings[i]))=0 then continue;
         ExcludeSambaFolders.Add(trim(l.Strings[i]));
     end;
  end;

  l.Clear;
  ExcludeHomesFolders:=TStringList.Create;
  if Fileexists('/etc/artica-postfix/settings/Daemons/DarBackupExcludeHomeShares') then begin
     l.LoadFromFile('/etc/artica-postfix/settings/Daemons/DarBackupExcludeHomeShares');
     for i:=0 to l.Count-1 do begin
         if length(trim(l.Strings[i]))=0 then continue;
         ExcludeHomesFolders.Add(trim(l.Strings[i]));
     end;
  end;

  l.Clear;
  PersoFoldersList:=TStringList.Create;
  if Fileexists('/etc/artica-postfix/settings/Daemons/DarBackupPersoShares') then begin
     l.LoadFromFile('/etc/artica-postfix/settings/Daemons/DarBackupPersoShares');
     for i:=0 to l.Count-1 do begin
         if length(trim(l.Strings[i]))=0 then continue;
         PersoFoldersList.Add(trim(l.Strings[i]));
     end;
  end;

  if Fileexists('/etc/artica-postfix/settings/Daemons/DarBackupStoragesList') then begin
     l.LoadFromFile('/etc/artica-postfix/settings/Daemons/DarBackupStoragesList');
     for i:=0 to l.Count-1 do begin
         if length(trim(l.Strings[i]))=0 then continue;
         external_storages.Add(trim(l.Strings[i]));
     end;
  end;

  if length(dar_folder)>0 then begin
     if use_local_external_failed=1 then external_storages.Add('dir:'+ dar_folder);
  end;



end;
//##############################################################################
procedure tincrement.WriteProgress(progress:integer);
var
   t:TiniFile;


begin
    t:=Tinifile.Create(localsubfolder+'/dar_backup_status.conf');
    t.WriteInteger('STATUS','progress',progress);
    fpsystem('/bin/chmod 777 '+localsubfolder+'/dar_backup_status.conf');
    t.free;
end;


//##############################################################################
procedure tincrement.StartBackup();
var
   i:integer;
   tot:integer;

begin
     tot:=0;
    FindExternalResources();
    logs.Debuglogs('StartBackup:: external storage=' +TargetFolderToBackup);
    if length(TargetFolderToBackup)=0 then begin
        logs.Debuglogs('StartBackup:: No external resources available');
        WriteProgress(110);
        exit;
    end;

    PerformFullBackupOp();
end;

//##############################################################################
procedure tincrement.FindExternalResources();
var
   i:integer;
   tot:integer;

begin
     tot:=0;

    logs.Debuglogs('FindExternalResources:: external storages number=' +IntToStr(external_storages.Count));

    for i:=0 to external_storages.Count-1 do begin
       if length(trim(external_storages.Strings[i]))>0 then begin
          logs.Debuglogs('Starting External ressource number '+IntToStr(i));
           external_ressource:=external_storages.Strings[i];
           localsubfolder:='/usr/share/artica-postfix/ressources/dar_collection/'+logs.MD5FromString(external_ressource);
           ForceDirectories(localsubfolder);
           if mount.mount(external_ressource) then begin
                logs.Debuglogs('FindExternalResources:: Success connect to external ressource with target path='+mount.TargetFolderToBackup);
                TargetFolderToBackup:=mount.TargetFolderToBackup;
                inc(tot);
                break;
           end;

       end;
    end;
end;

//##############################################################################



procedure tincrement.PerformFullBackupOp();
var
   t:TiniFile;
   foldersize:string;
   StartDate:string;
   EndDate:string;
   text:string;
begin

     if Enable=0 then begin
        logs.Debuglogs('PerformFullBackupOp:: Incremental backup is disabled...Abort...');
        WriteProgress(110);
        exit;

     end;

     if not FileExists(dar_bin) then begin
          logs.Debuglogs('PerformFullBackupOp:: dar tool is not installed...Abort...');
          WriteProgress(110);
          exit;
     end;

     if not FileExists(dar_manager) then begin
          logs.Debuglogs('PerformFullBackupOp:: dar_manager tool is not installed...Abort...');
          WriteProgress(110);
          exit;
     end;

     if not Mount.IsMounted then begin
         logs.Debuglogs('PerformFullBackupOp:: Unable to connect to a valid ressource...Abort...');
         logs.EVENTS('Unable to to connect to a valid ressource','artica-backup was unable to mount a valid ressource','backup','');
         WriteProgress(110);
         exit;
     end;

     if not DirectoryExists(TargetFolderToBackup) then begin
           logs.Debuglogs('PerformFullBackupOp:: Unable to connect to a valid ressource...Abort...');
           logs.EVENTS('Unable to to connect to a valid ressource','artica-backup was unable to stat '+TargetFolderToBackup,'backup','');
           WriteProgress(110);
           exit;
     end;


     forceDirectories(TargetFolderToBackup);
     StartDate:=FormatDateTime('yyyy-mm-dd hh:nn:ss', Now);
     t:=Tinifile.Create(localsubfolder+'/dar_backup_status.conf');
     t.WriteString('STATUS','start_date',FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
     fpsystem('/bin/chmod 777 '+localsubfolder+'/dar_backup_status.conf');

     WriteProgress(10);
      t.WriteString('STATUS','current','{artica_conf}');
     artica_conf_backup();

     WriteProgress(20);
     t.WriteString('STATUS','current','{ldap_datas}');
     artica_ldap_backup();

     WriteProgress(30);
     t.WriteString('STATUS','current','{mysql_datas}');
     artica_mysql_backup();

     WriteProgress(40);
     t.WriteString('STATUS','current','{mailboxes}');
     artica_cyrus_backup();

     t.WriteString('STATUS','current','{OnFly}');
     WriteProgress(50);
     artica_backupMails_backup();

     WriteProgress(60);
     t.WriteString('STATUS','current','{shares_folders}');
     artica_backup_samba_backup();


     WriteProgress(70);
     t.WriteString('STATUS','current','{homes}');
     artica_backup_homes_backup();

     WriteProgress(80);
     t.WriteString('STATUS','current','{user_defined}');
     artica_backup_perso_backup();

     WriteProgress(90);
     t.WriteString('STATUS','current','{indexing}');

     logs.DeleteFile(localsubfolder+'/collections.dmd');
     list_collection();

     forcedirectories('/var/log/artica-postfix/increment-queue');
     logs.OutputCmd('/bin/cp '+TargetFolderToBackup+'/user_defined.conf /var/log/artica-postfix/increment-queue/user_defined.conf');
     GetCollectionsSize();
     WriteProgress(100);

    EndDate:=FormatDateTime('yyyy-mm-dd hh:nn:ss', Now);
     t.WriteString('STATUS','end_date',EndDate);
     fpsystem('/bin/chmod 777 '+localsubfolder+'/dar_backup_status.conf');
     t.free;
     fpsystem('swapoff -a && swapon -a');
     foldersize:=SYS.FOLDER_SIZE_HUMAN(TargetFolderToBackup);

      text:=text+ 'Folder size............:'+foldersize+'[br]';
      text:=text+ 'Start Time.............:'+StartDate+'[br]';
      text:=text+ 'End Time...............:'+EndDate+'[br]';
      logs.EVENTS('Incremental backup completed (' +foldersize + ' size)',text,'backup','');


end;
//##############################################################################
procedure tincrement.RefreshCache();
var targetCollection:string;
begin
    if not mount.IsMounted then begin
       logs.Debuglogs('RefreshCache:: Unable to mount !!');
       exit;
    end;
    targetCollection:=localsubfolder+'/collections.dmd';
    logs.OutputCmd('/bin/cp -f '+TargetFolderToBackup+'/user_defined.conf /var/log/artica-postfix/increment-queue/user_defined.conf');
    logs.OutputCmd('/bin/cp -f '+TargetFolderToBackup+'/collection.lst ' + targetCollection);
    logs.OutputCmd('/bin/chmod -R 777 '+localsubfolder);
    GetCollectionsSize();
end;

//##############################################################################
procedure tincrement.GetCollectionsSize();
var
   tFile:TiniFIle;
   RegExpr:TRegExpr;
   i:integer;
   collection_name:string;
begin
   if not mount.IsMounted then begin
      logs.Debuglogs('GetCollectionsSize:: Unable to mount');
      exit;
   end;

   tFile:=TiniFIle.Create(localsubfolder+'/collections.size');
   SYS.DirFiles(TargetFolderToBackup,'*.dar');
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='(.+?)\.[0-9]+\.dar';
   for i:=0 to SYS.DirListFiles.Count-1 do begin
       if RegExpr.Exec(sys.DirListFiles.Strings[i]) then begin
           collection_name:=RegExpr.Match[1];
           tfile.WriteInteger('SIZE',collection_name,SYS.FileSize_ko(TargetFolderToBackup+'/'+sys.DirListFiles.Strings[i]));
       end;
   end;

end;
//##############################################################################
procedure  tincrement.Build_collections(path:string);
var
i:integer;
tmpstr:string;
RegExpr:TRegExpr;
collection:string;
cmdline:string;
begin

tmpstr:=logs.FILE_TEMP();
fpsystem(dar_manager +' -B '+path+'/collection.dmd -l >'+path+'/collection.lst');
RegExpr:=TRegExpr.Create;
RegExpr.Expression:='(.+?)\/\.1\.dar$';

//ifCatalogExists(path,jjjj)

sys.DirFiles(path,'*.1.dar');
for i:=0 to sys.DirListFiles.Count-1 do begin
        if RegExpr.Exec(sys.DirListFiles.Strings[i]) then collection:=RegExpr.Match[1];
        if length(collection)=0 then collection:=AnsiReplaceTExt(sys.DirListFiles.Strings[i],'.1.dar','');

        if not ifCatalogExists(path,collection) then begin
         cmdline:=dar_manager +' -B '+path+'/collection.dmd -o --noconf -Q -A '+path+'/'+collection;
         fpsystem(cmdline);
        end;

        collection:='';
end;


end;
//##############################################################################
procedure  tincrement.list_collection();
var
cmd:string;
targetCollection:string;
begin
    if not mount.IsMounted then exit;
    if not FileExists('/var/log/artica-postfix/increment-queue/user_defined.conf') then begin
         logs.OutputCmd('/bin/cp '+TargetFolderToBackup+'/user_defined.conf /var/log/artica-postfix/increment-queue/user_defined.conf');
    end;

    targetCollection:=localsubfolder+'/collections.dmd';
    if not FileExists(TargetFolderToBackup+'/collection.dmd') then begin
       logs.Debuglogs('unable to display ' + TargetFolderToBackup+'/collection.dmd');
       exit;
    end;
    if FileExists(targetCollection) then begin
       if sys.FileSize_ko(targetCollection)=0 then begin
          logs.Debuglogs('Delete '+targetCollection + ' too low size');
          logs.DeleteFile(targetCollection);
       end;
    end;

   if FileExists(targetCollection) then begin
       logs.Debuglogs(targetCollection+ 'already exists with ' +IntToStr(sys.FileSize_ko(targetCollection))+' .. abort');
       exit;
    end;

    cmd:='/bin/cp ' +TargetFolderToBackup+'/collection.lst ' + targetCollection;
    logs.OutputCmd(cmd);
    logs.OutputCmd('/bin/chmod 777 '+localsubfolder+'/collections.dmd');
end;
//##############################################################################
procedure tincrement.BuildSingleCollection(path:string);
var
   list:tstringList;
   i:integer;
   RegExpr:TRegExpr;
   cmd,command,cmdline:string;
   DirecName:string;
   tmpstr:string;
begin

if length(path)=0 then begin
   if not mount.IsMounted then exit;
   path:=TargetFolderToBackup;
end;


if not DirectoryExists(path) then begin
    if not mount.IsMounted then exit;
   path:=TargetFolderToBackup;
end;

if not DirectoryExists(path) then begin
   exit;
end;

if not FileExists(path+'/collection.dmd') then begin
   logs.Debuglogs('BuildSingleCollection:: WARNING !! "'+path+'/collection.dmd" did not exists.... Creating collection...');
   logs.OutputCmd(SYS.EXEC_NICE()+dar_manager +' -C '+path+'/collection.dmd');
   logs.Debuglogs('BuildSingleCollection:: done...');
end;

logs.Debuglogs('BuildSingleCollection:: listing catalogues...');
list:=TstringList.Create;
SYS.DirFiles(path,'*.1.dar');
RegExpr:=TRegExpr.Create;

for i:=0 to SYS.DirListFiles.Count-1 do begin
       RegExpr.Expression:='(.+?)\.[0-9]+\.dar';
       if RegExpr.Exec(SYS.DirListFiles.Strings[i]) then list.Add(RegExpr.Match[1]);
end;

DirecName:=path+ '/collection.lst';
logs.Debuglogs('BuildSingleCollection:: '+IntToStr(list.Count)+' catalogue(s)...');
for i:=0 to list.Count-1 do begin

       xml(list.Strings[i]);


       if ifCatalogExists(path+'/collection.dmd',list.Strings[i]) then begin
          logs.Debuglogs(list.Strings[i]+' Already added');
          continue;
       end;


          logs.Debuglogs('');
          logs.Debuglogs('');
          logs.Debuglogs('**************************************************************');
          logs.Debuglogs('BuildSingleCollection:: Add catalogue number: '+IntToStr(i)+' ('+list.Strings[i]+')...');

          tmpstr:=logs.FILE_TEMP();
          cmdline:=dar_manager +' -B '+path+'/collection.dmd -A '+path+'/'+list.Strings[i];
          if SYS.PROCESS_EXIST(SYS.PIDOF_PATTERN(cmdline)) then begin
             logs.Debuglogs('Process already exists...');
             continue;
          end;

          command:=SYS.EXEC_NICE()+cmdline+' >'+tmpstr+' 2>&1';
          logs.Debuglogs(command);
          fpsystem(command);

          if DetectCatalogError(tmpstr) then begin
                logs.Debuglogs('BuildSingleCollection:: !!!!! corrupted database "'+path+'/'+list.Strings[i]+'" !!!! (delete it)');
                if DirectoryExists(path) then  begin
                   logs.OutputCmd('/bin/rm '+path+'/'+list.Strings[i]+'*.dar');
                   logs.OutputCmd('/bin/rm '+path+'/'+list.Strings[i]+'*.ls');
                end;
                continue;
          end;




          command:=SYS.EXEC_NICE()+dar_manager +' -l -B '+path+'/collection.dmd >'+DirecName;
          logs.Debuglogs(command);
          fpsystem(command);
          xmlSingle(path+'/'+list.Strings[i]);
          logs.Debuglogs('**************************************************************');


end;

logs.Debuglogs('BuildSingleCollection:: listing catalogues '+ DirecName+' done...');
logs.Debuglogs('BuildSingleCollection:: '+path+' finish');


end;
//##############################################################################
function tincrement.DetectCatalogError(logspath:string):boolean;
var
   l:tstringList;
   i:integer;
   RegExpr:TRegExpr;
begin
    result:=false;
    if not FileExists(logspath) then exit(false);
    l:=Tstringlist.Create;
    l.LoadFromFile(logspath);
    RegExpr:=TRegExpr.Create;

    for i:=0 to l.Count-1 do begin
        RegExpr.Expression:='Corrupted database';
        if RegExpr.Exec(l.Strings[i]) then begin
           result:=true;
           break;
        end;

    end;


    logs.Debuglogs(l.Text);
    logs.DeleteFile(logspath);
    RegExpr.free;
    l.free;

end;
//##############################################################################
function tincrement.GetDatabaseName(pathToDB:String;numeric:string):string;
var
   list:tstringList;
   i:integer;
   RegExpr:TRegExpr;
   DirecName:string;
begin

  DirecName:=pathToDB+ '/collection.lst';
  if not FileExists(DirecName) then  Build_collections(pathToDB);
  if not FileExists(DirecName) then begin
     logs.Debuglogs('GetDatabaseName:: unable to stat '+DirecName);
     exit;
  end;
   list:=TstringList.Create;
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='\s+'+numeric+'\s+.+?\s+(.+?)$';
 list.LoadFromFile(DirecName);
   for i:=0 to list.Count-1 do begin
      if RegExpr.Exec(list.Strings[i]) then begin
            logs.Debuglogs('GetDatabaseName:: found catalog '+RegExpr.Match[1]);
            result:=RegExpr.Match[1];
            break;
       end else begin
           //writeln(list.Strings[i]);
       end;
   end;


   list.Free;
   RegExpr.free;
end;
//##############################################################################




function tincrement.ifCatalogExists(pathToDB:String;CatalogName:string):boolean;
var
   list:tstringList;
   i:integer;
   RegExpr:TRegExpr;
   DirecName:string;
   DirecName_size:integer;
   cmdline:string;
   BaseDir:string;
begin
   if DirectoryExists(pathToDB) then BaseDir:=pathToDB+'/' else BaseDir:=ExtractFilePath(pathToDB);
   DirecName:=BaseDir+ 'collection.lst';

   result:=false;

   if FileExists(DirecName) then begin
      DirecName_size:=sys.FileSize_bytes(DirecName);
      if DirecName_size=0 then begin
         logs.Debuglogs('ifCatalogExists:: path:"'+DirecName +'" is 0bytes delete it');
         logs.DeleteFile(DirecName);
      end else begin

      end;
   end;

   if not FileExists(DirecName) then begin
      logs.Debuglogs('ifCatalogExists:: Building catalog from '+pathToDB+' to ' + DirecName);
       cmdline:=dar_manager +' -l -B '+BaseDir+'collection.dmd';
       if not SYS.PROCESS_EXIST(SYS.PIDOF_PATTERN(cmdline)) then begin
          logs.Debuglogs(SYS.EXEC_NICE()+cmdline + ' >'+DirecName);
          fpsystem(SYS.EXEC_NICE()+cmdline + ' >'+DirecName);
       end;
   end;



   if not FileExists(Direcname) then begin
      logs.Debuglogs('ifCatalogExists:: Warning, unable to stat ' + DirecName);
      exit(true);
   end;

   list:=TstringList.Create;
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='\s+([0-9]+)\s+(.+?)\s+'+CatalogName+'$';
   list.LoadFromFile(DirecName);
   for i:=0 to list.Count-1 do begin
      if RegExpr.Exec(list.Strings[i]) then begin
            logs.Debuglogs('ifCatalogExists:: '+CatalogName+' is already added index [' + RegExpr.Match[1]+'] (size of catalog list:'+IntToStr(DirecName_size)+' bytes)');
            result:=true;
            break;
       end else begin
           //writeln(list.Strings[i]);
       end;
   end;


   list.Free;
   RegExpr.free;
end;
//##############################################################################

procedure tincrement.artica_conf_backup();
var
   table_path:string;
   cmd:string;
begin
   if artica_conf=0 then begin
       logs.Debuglogs('Backup artica configuration file is disabled');
       exit;
   end;

   cmd:=BuildDarCommand(TargetFolderToBackup+'/artica_conf','/etc/artica-postfix');
   if length(cmd)=0 then exit;
   logs.OutputCmd(cmd);
end;
//##############################################################################
procedure tincrement.artica_ldap_backup();
var
   cmd:string;
   ldap:Topenldap;
   suffix:string;
begin
   if artica_conf=0 then begin
       logs.Debuglogs('Backup ldap datas is disabled');
       exit;
   end;

   logs.Debuglogs('#############################');
   logs.Debuglogs('##                         ##');
   logs.Debuglogs('##          LDAP           ##');
   logs.Debuglogs('##                         ##');
   logs.Debuglogs('#############################');

   ldap:=topenldap.Create;
   suffix:=ldap.get_LDAP('suffix');

   forceDirectories('/opt/artica/backup/ldap_datas');
   fpsystem('slapcat -l /opt/artica/backup/ldap_datas/artica_ldap.ldif');
   logs.Debuglogs('Saving suffix ' + suffix);
   logs.WriteToFile(suffix,TargetFolderToBackup+'/ldap.suffix');


   remote_rsync.RsyncRemoteFolder('/opt/artica/backup/ldap_datas');
   if UseOnlyRsync=1 then begin
      logs.Debuglogs('artica_mysql_backup:: Only rsync method is selected for /opt/artica/backup/ldap_datas');
      logs.DeleteFile('/opt/artica/backup/ldap_datas/artica_ldap.ldif');
      exit;
   end;

   EXECUTE_DAR_OPERATIONS(TargetFolderToBackup+'/ldap_datas','/opt/artica/backup/ldap_datas');
   logs.DeleteFile('/opt/artica/backup/ldap_datas/artica_ldap.ldif');
end;
//##############################################################################
procedure tincrement.artica_mysql_backup();
var
   cmd:string;
   admin:string;
   server:string;
   password:string;
   port:string;
   tmpstr:string;
   databases:TstringList;
   i:integer;
begin
   if mysql_datas=0 then begin
       logs.Debuglogs('Backup mysql datas is disabled');
       exit;
   end;

   logs.Debuglogs('#############################');
   logs.Debuglogs('##                         ##');
   logs.Debuglogs('##          MYSQL          ##');
   logs.Debuglogs('##                         ##');
   logs.Debuglogs('#############################');


   admin:=SYS.MYSQL_INFOS('database_admin');
   password:=SYS.MYSQL_INFOS('database_password');
   server:=SYS.MYSQL_INFOS('mysql_server');
   port:=SYS.MYSQL_INFOS('port');
   if FileExists('/etc/artica-postfix/backup-mysql-completed') then begin
      logs.Debuglogs('/etc/artica-postfix/backup-mysql-completed=' + IntToStr(SYS.FILE_TIME_BETWEEN_MIN('/etc/artica-postfix/backup-mysql-completed'))+' min');
      if SYS.FILE_TIME_BETWEEN_MIN('/etc/artica-postfix/backup-mysql-completed')<60 then begin
           logs.Debuglogs('Already backup is performed under 60 minutes... skip it');
           exit;
      end;
   end;

   if not FileExists('/usr/bin/mysqlhotcopy') then begin
      logs.Debuglogs('Unable to locate /usr/bin/mysqlhotcopy');
      exit;
   end;

   logs.Debuglogs('artica_mysql_backup:: '+admin+'@'+server+':'+port);


   forceDirectories('/opt/artica/backup/mysql_datas');
   tmpstr:=logs.FILE_TEMP();

   databases:=TstringList.Create;
   databases.AddSTrings(logs.LIST_MYSQL_DATABASES());
   for i:=0 to databases.Count-1 do begin
       if length(trim(databases.Strings[i]))=0 then continue;
       logs.Debuglogs('Dumping database '+trim(databases.Strings[i]));
       cmd:='/usr/bin/mysqlhotcopy  '+trim(databases.Strings[i])+' --user=' +admin;
       cmd:=cmd+' --password='+password+' --host='+server + ' --port='+port+' /opt/artica/backup/mysql_datas';
       fpsystem(cmd);
   end;

   logs.Debuglogs('Executing backup...');



   remote_rsync.RsyncRemoteFolder('/opt/artica/backup/mysql_datas');
   if UseOnlyRsync=1 then begin
      logs.Debuglogs('artica_mysql_backup:: Only rsync method is selected');
      fpsystem('/bin/rm -rf /opt/artica/backup/mysql_datas');
      logs.DeleteFile('/etc/artica-postfix/backup-mysql-completed');
      fpsystem('/bin/touch /etc/artica-postfix/backup-mysql-completed');
      exit;
   end;

   EXECUTE_DAR_OPERATIONS('/opt/artica/backup/mysql_datas',TargetFolderToBackup+'/mysql_datas');
   fpsystem('/bin/rm -rf /opt/artica/backup/mysql_datas');
   logs.DeleteFile('/etc/artica-postfix/backup-mysql-completed');
   fpsystem('/bin/touch /etc/artica-postfix/backup-mysql-completed');

end;
//##############################################################################
function tincrement.SelectCollectionStorage(sMD5:string):string;
var
   i:integer;
   mdString:string;
begin

if length(sMD5)=0 then exit;

for i:=0 to external_storages.Count-1 do begin
        mdString:=logs.MD5FromString(external_storages.Strings[i]);
        logs.Debuglogs('SelectCollectionStorage:: Checking:'+external_storages.Strings[i] + '('+mdString+') against ' +sMD5  );

        if sMD5=mdString then begin
           logs.Debuglogs('SelectCollectionStorage:: Found '+external_storages.Strings[i]);
           external_ressource:=external_storages.Strings[i];
           exit;
        end;
end;

logs.Debuglogs('SelectCollectionStorage:: no external storages match ' + sMD5);
if sMD5=logs.MD5FromString(dar_folder) then begin
   logs.Debuglogs('SelectCollectionStorage:: local folder  ' + dar_folder + ' match storage index');
   external_ressource:='dir:'+dar_folder;
   exit;
end;

end;
//##############################################################################
procedure tincrement.RestoreDatabaseSingleFile(file_path_database:string;database:string;sMD5:string;target_path:string);
var
   cmd:string;
begin


  SelectCollectionStorage(sMD5);
  logs.Debuglogs('RestoreDatabaseSingleFile:: Restoring database........:'+database);
  logs.Debuglogs('RestoreDatabaseSingleFile:: Restoring Target directory:'+target_path);
  logs.Debuglogs('RestoreDatabaseSingleFile:: Selected collection.......:'+sMD5 +'('+external_ressource+')');
  logs.Debuglogs('RestoreDatabaseSingleFile:: File in database..........:'+file_path_database);

 if length(external_ressource)=0 then begin
     logs.Debuglogs('RestoreDatabaseSingleFile:: unable to define an external storage entry..');
     exit;
  end;

  if length(target_path)=0 then begin
     logs.Debuglogs('RestoreDatabaseSingleFile:: no target path given !');
     exit;
  end;

  if length(file_path_database)=0 then begin
     logs.Debuglogs('RestoreDatabaseSingleFile:: no path in database given "file_path_database"');
     exit;
  end;

localsubfolder:='/usr/share/artica-postfix/ressources/dar_collection/'+logs.MD5FromString(dar_folder);
ForceDirectories(localsubfolder);
if not mount.IsMounted then begin
   logs.Debuglogs('RestoreDatabaseSingleFile:: unable to mount an external storage entry..');
end;

logs.Debuglogs('RestoreDatabaseSingleFile:: Local mounted path........:'+TargetFolderToBackup);

  logs.Debuglogs('Creating ' + target_path);
  ForceDirectories(target_path);
  target_path:=AnsiReplaceText(target_path,'\''','''');
  logs.Debuglogs('Creating directory "'+target_path+'"');

  try
     ForceDirectories(target_path);
  except
        logs.Debuglogs('RestoreDatabase:: Fatal error while creating directory');
        exit;
  end;

  cmd:=SYS.EXEC_NICE() +dar_bin + ' -x '+TargetFolderToBackup+'/'+database+' -R "' + target_path+'" -r -v -g "'+file_path_database+'"';
  logs.OutputCmd(cmd);
  mount.DisMount();

end;


//##############################################################################

procedure tincrement.restore_status(progression:integer;status:string);
var

TmpINI:TiniFile;
begin
      TmpINI:=TiniFIle.Create('/usr/share/artica-postfix/ressources/logs/exec.dar.find.restore.ini');
      TmpINI.WriteString('STATUS','progress',IntToStr(progression));
      TmpINI.WriteString('STATUS','text',status);
      TmpINI.UpdateFile;
      TmpINI.Free;
      fpsystem('/bin/chmod 755 /usr/share/artica-postfix/ressources/logs/exec.dar.find.restore.ini');

end;
//##############################################################################
procedure tincrement.dar_populate(resource:string);
var
l:Tstringlist;
i:integer;
cmd:string;
rsrc:integer;
database:string;
begin
rsrc:=0;
logs.Debuglogs('dar_populate:: order to populate resource number '+resource +' in ' + IntTostr(external_storages.Count) +' resources');
if not TryStrToInt(resource,rsrc) then begin
       logs.Debuglogs('dar_populate:: unable to populate resource number is false:'+resource);
       exit;
end;

logs.Debuglogs('dar_populate:: unable to populate resource number: '+ IntTostr(rsrc));
mount:=tmount.Create;
if not mount.mount(external_storages.Strings[rsrc]) then begin
      logs.Debuglogs('dar_populate:: unable to mount resource number :'+resource);
      exit;
end;



 SYS.DirFiles(mount.TargetFolderToBackup,'*.1.dar');
  logs.Debuglogs('dar_populate:: parsing folder ' + mount.TargetFolderToBackup+' ' + IntTostr(sys.DirListFiles.Count)+' databases');
 for i:=0 to sys.DirListFiles.Count-1 do begin

      database:=AnsiReplaceText(sys.DirListFiles.Strings[i],'.1.dar','');
      logs.Debuglogs('dar_populate:: analyze '+sys.DirListFiles.Strings[i] +' ('+database+')');
      xmlSingle(mount.TargetFolderToBackup+'/'+database);
 end;



mount.DisMount();
fpsystem(SYS.LOCATE_PHP5_BIN()+ ' /usr/share/artica-postfix/exec.parse.dar-xml.php &');


end;
//##############################################################################

procedure tincrement.dar_restore_path(inicommand:string);
var
TmpINI:TiniFile;
backup_resource,target_resource,database,database_name,source_path:string;
mount:tmount;
mount2:tmount;
cmd:string;
begin

TmpINI:=TiniFIle.Create(inicommand);
backup_resource:=TmpINI.ReadString('INFO','backup_resource','');
target_resource:=TmpINI.ReadString('INFO','target_resource','');
database:=TmpINI.ReadString('INFO','database','');
source_path:=TmpINI.ReadString('INFO','source_path','');
mount:=tmount.Create;
mount2:=tmount.Create;

logs.Debuglogs('dar_restore_path:: mount resources');

if not mount.mount(backup_resource) then begin
         restore_status(110,'{failed} {mount} N.1');
         logs.Debuglogs('dar_restore_path:: failed to mount '+backup_resource);
         exit;
end;

if not mount2.mount(target_resource) then begin
         logs.Debuglogs('dar_restore_path:: failed to mount '+target_resource);
         restore_status(110,'{failed} {mount} N.2');
         exit;
end;
database_name:=GetDatabaseName(mount.TargetFolderToBackup,database);
logs.Debuglogs('Find database id=' + database +' name='+database_name);
if length(database_name)=0 then begin
    restore_status(110,'{failed} unable to find database name');
    logs.Debuglogs('dar_restore_path:: failed to find database name for id='+database);
    mount2.free;
    mount.free;
    exit;
end;

 restore_status(50,'{extracting}');
 cmd:=SYS.EXEC_NICE() +dar_bin + ' --extract '+mount.TargetFolderToBackup+'/'+database_name+' --fs-root '+mount2.TargetFolderToBackup+' -g '+source_path+' -r -v';
 logs.OutputCmd(cmd);


restore_status(100,'{success}');
mount2.free;
mount.free;

end;
//##############################################################################

procedure tincrement.RestoreDatabase(database:string;target_path:string;sMD5:string);
var
   cmd:string;
   RegExpr:TRegExpr;
begin

{ utilise valeur globale TargetFolderToBackup et external_ressource
}

  SelectCollectionStorage(sMD5);
  logs.Debuglogs('Restoring database........:'+database);
  logs.Debuglogs('Restoring Target directory:'+target_path);
  logs.Debuglogs('Selected collection.......:'+sMD5 +'('+external_ressource+')');

  if length(external_ressource)=0 then begin
     logs.Debuglogs('RestoreDatabase:: unable to define an external storage entry..');
     exit;
  end;

localsubfolder:='/usr/share/artica-postfix/ressources/dar_collection/'+logs.MD5FromString(dar_folder);
ForceDirectories(localsubfolder);
if not mount.IsMounted then begin
   logs.Debuglogs('RestoreDatabase:: unable to mount an external storage entry..');
end;


logs.Debuglogs('Local mounted path........:'+TargetFolderToBackup);

  RegExpr:=TRegExpr.Create;
  RegExpr.Expression:='mysql_datas';
  if RegExpr.Exec(database) then begin
       logs.Debuglogs('Restoring Target directory:'+target_path);
       logs.Debuglogs('Restoring Mysql datas...');
       RestoreMysql(database);
       exit;
 end;
 RegExpr.Expression:='ldap_datas';
  if RegExpr.Exec(database) then begin
       logs.Debuglogs('Restoring Target directory:'+target_path);
       logs.Debuglogs('Restoring ldap server datas...');
       RestoreLDAP(database);
       exit;
 end;

  RegExpr.Expression:='cyrus_imap_datas';
  if RegExpr.Exec(database) then begin
       logs.Debuglogs('Restoring Target directory:'+target_path);
       logs.Debuglogs('Restoring cyrus_imap_datas server datas...');
       RestoreCyrusImapDatas(database);
       exit;
 end;


  if not mount.IsMounted then begin
     logs.Debuglogs('RestoreDatabase() unable to mount !!');
     exit;
  end;

  if length(target_path)=0 then begin
     logs.Debuglogs('RestoreDatabase() no target path given !');
     exit;
  end;

  logs.Debuglogs('Creating ' + target_path);
  ForceDirectories(target_path);
  target_path:=AnsiReplaceText(target_path,'\''','''');
  logs.Debuglogs('Creating directory "'+target_path+'"');
  try
     ForceDirectories(target_path);
  except
        logs.Debuglogs('RestoreDatabase:: Fatal error while creating directory');
        exit;
  end;
  cmd:=SYS.EXEC_NICE() +dar_bin + ' -x '+TargetFolderToBackup+'/'+database+' -R "' + target_path+'" -r -v ';
  logs.OutputCmd(cmd);
  mount.Dismount();
end;
//##############################################################################
procedure tincrement.RestoreMysql(database:string);
var
mysql:tmysql_daemon;
datadir:string;
cmd:string;
user:string;
begin
   database:=trim(database);
   if not mount.IsMounted then begin
     logs.Debuglogs('RestoreMysql() unable to mount !!');
     exit;
  end;

  mysql:=tmysql_daemon.Create(SYS);
  if not FileExists(mysql.daemon_bin_path()) then begin
      logs.Debuglogs('RestoreMysql():: mysql.daemon_bin_path() report null');
      logs.Debuglogs('RestoreMysql():: it seems that mysql is not installed on this server');
      exit;
  end;


   datadir:=mysql.SERVER_PARAMETERS('datadir');
   if length(datadir)=0 then begin
       logs.Debuglogs('RestoreMysql():: mysql.SERVER_PARAMETERS(datadir) report null');
       logs.Debuglogs('RestoreMysql():: Unable to locate directory that store mysql datas');
   end;

  logs.Debuglogs('RestoreMysql() stopping mysql server');
  mysql.SERVICE_STOP();

  logs.Debuglogs('Creating ' + datadir);
  ForceDirectories(datadir);

  if(database)<>'mysql_datas' then begin
      cmd:=cmd +dar_bin + ' -x '+TargetFolderToBackup+'/mysql_datas -R "' + datadir+'" -r -v ';
      logs.OutputCmd(cmd);
  end;

  cmd:=SYS.EXEC_NICE() +dar_bin + ' -x '+TargetFolderToBackup+'/'+database+' -R "' + datadir+'" -r -v ';
  logs.OutputCmd(cmd);
  user:=mysql.SERVER_PARAMETERS('user');
  logs.OutputCmd('/bin/chown -R '+user+':'+user+' '+datadir);
  logs.Debuglogs('RestoreMysql() starting mysql server');
  mysql.SERVICE_START();


end;
//##############################################################################
procedure tincrement.RestoreCyrusImapDatas(database:string);
var
  ccyrus:TCyrus;
  configdirectory:string;
  partitiondefault:string;
  cyrus_imap_mail:string;
  RegExpr:TRegExpr;
  cmd:string;
  nice:string;
begin


logs.Debuglogs('RestoreCyrusImapDatas():: #######################################################');
  database:=trim(database);


   if not mount.IsMounted then begin
     logs.Debuglogs('RestoreCyrusImapDatas() unable to mount !!');
     exit;
  end;

 ccyrus:=TCyrus.Create(SYS);
 configdirectory:=ccyrus.IMAPD_GET('configdirectory');
 partitiondefault:=ccyrus.IMAPD_GET('partition-default');
 RegExpr:=TRegExpr.Create;
 RegExpr.Expression:='cyrus_imap_datas-(.+?)-diff';
if  RegExpr.Exec(database) then begin
      cyrus_imap_mail:='cyrus_imap_mail-'+RegExpr.Match[1]+'-diff';
end else begin
     cyrus_imap_mail:='cyrus_imap_mail';
end;

   logs.Debuglogs('RestoreCyrusImapDatas(): cyrus_imap_mail='+cyrus_imap_mail);


   if length(configdirectory)=0 then begin
         logs.Debuglogs('RestoreCyrusImapDatas(): unable to stat configdirectory !!');
         exit;
   end;


   if length(partitiondefault)=0 then begin
         logs.Debuglogs('RestoreCyrusImapDatas():: unable to stat partitiondefault !!');
         exit;
   end;
   SetCurrentDir('/root');
   logs.Debuglogs('configdirectory='+configdirectory);
   logs.Debuglogs('partitiondefault='+partitiondefault);

   logs.Debuglogs('Stopping cyrus');
   ccyrus.CYRUS_DAEMON_STOP();
   SetCurrentDir('/root');



logs.Debuglogs('RestoreCyrusImapDatas() Executing restore original...');

cmd:=SYS.EXEC_NICE() +dar_bin + ' -x '+TargetFolderToBackup+'/cyrus_imap_datas -R "' + configdirectory+'" -r -v ';
logs.OutputCmd(cmd);

cmd:='';
cmd:=SYS.EXEC_NICE() +dar_bin + ' -x '+TargetFolderToBackup+'/cyrus_imap_mail -R "' + partitiondefault+'" -r -v ';
logs.OutputCmd(cmd);


if database <>'cyrus_imap_datas' then begin
   logs.Debuglogs('RestoreCyrusImapDatas() Executing restore incremental...');
   cmd:=SYS.EXEC_NICE() +dar_bin + ' -x '+TargetFolderToBackup+'/'+database+' -R "' + configdirectory+'" -r -v ';
   logs.OutputCmd(cmd);
   cmd:='';


   cmd:=SYS.EXEC_NICE() +dar_bin + ' -x '+TargetFolderToBackup+'/'+cyrus_imap_mail+' -R "' + partitiondefault+'" -r -v ';
   logs.OutputCmd(cmd);
end;

logs.Debuglogs('RestoreCyrusImapDatas() Starting cyrus');
   ccyrus.CYRUS_DAEMON_STOP();
   ccyrus.CYRUS_DAEMON_START();

end;
//##############################################################################



procedure tincrement.RestoreLDAP(database:string);
var
ldap:topenldap;
database_path:string;
suffix:string;
cmd:string;
ldapcf_path:string;
tmpstr:string;
error:integer;
count:integer;
begin
logs.Debuglogs('RestoreLDAP():: #######################################################');
  database:=trim(database);
   if not mount.IsMounted then begin
     logs.Debuglogs('RestoreLDAP() unable to mount !!');
     exit;
  end;

ldap:=Topenldap.Create;
if not FileExists(ldap.DAEMON_PATH()) then begin
    logs.Debuglogs('RestoreLDAP():: ldap.DAEMON_PATH() report null');
    logs.Debuglogs('RestoreLDAP():: it seems that ldap server is not installed on this server');
    exit;
end;
   if FileExists('/etc/artica-postfix/ldap.restored') then begin
      logs.Debuglogs('locked operation: /etc/artica-postfix/ldap.restored:' + IntToStr(SYS.FILE_TIME_BETWEEN_SEC('/etc/artica-postfix/ldap.restored'))+ ' seconds');
      if SYS.FILE_TIME_BETWEEN_SEC('/etc/artica-postfix/ldap.restored')<60 then begin
         logs.Debuglogs('To short time to restore ldap server');
         exit;
      end;
   end;


  database_path:=ldap.LDAP_DATABASES_PATH();
  suffix:=logs.ReadFromFile(TargetFolderToBackup+'/ldap.suffix');
  ldapcf_path:=ldap.SLAPD_CONF_PATH();


  if length(database_path)=0 then begin
     logs.Debuglogs('RestoreLDAP():: unable to find ldap databases path..');
     exit;
  end;

  if length(suffix)=0 then begin
     logs.Debuglogs('RestoreLDAP():: unable to get suffix');
     logs.Debuglogs('RestoreLDAP():: usualy stored in '+TargetFolderToBackup+'/ldap.suffix file');
     exit;
  end;

  if length(ldapcf_path)=0 then begin
     logs.Debuglogs('RestoreLDAP():: unable to get slapd.conf');
     exit;
  end;

  logs.WriteToFile('#','/etc/artica-postfix/STOP-LDAP');
  logs.Debuglogs('RestoreLDAP() stopping ldap server');
  ldap.LDAP_STOP();



  forceDirectories('/opt/artica/backup/restore/ldap');


 logs.OutputCmd('killall slapadd');
 cmd:=SYS.EXEC_NICE() +dar_bin + ' -x '+TargetFolderToBackup+'/'+database+' -R "/opt/artica/backup/restore/ldap" -r -v ';
 logs.OutputCmd(cmd);
 if not FileExists('/opt/artica/backup/restore/ldap/artica_ldap.ldif') then begin
      logs.Debuglogs('RestoreLDAP() unable to stat restore file "/opt/artica/backup/restore/ldap/artica_ldap.ldif"');
      logs.DeleteFile('/etc/artica-postfix/STOP-LDAP');
      ldap.LDAP_START();
      exit;
 end;

  logs.Debuglogs('RestoreLDAP():: Change suffix to '+suffix);
  ldap.set_LDAP('suffix',suffix);
  logs.Debuglogs('RestoreLDAP():: remove content of '+database_path+'/');
  logs.OutputCmd('/bin/rm -f '+database_path+'/*');

  logs.Debuglogs('RestoreLDAP() importing ldap content...');
  tmpstr:=logs.FILE_TEMP();
  cmd:='slapadd -s -l /opt/artica/backup/restore/ldap/artica_ldap.ldif -f '+ldapcf_path+' -b "'+suffix+'" >'+tmpstr+' 2>&1';
  logs.Debuglogs(cmd);
  fpsystem(cmd);

  error:=RestoreLDAP_Checkerrors(tmpstr);
  count:=0;
  while error>0 do begin
      inc(count);
      if(count>20) then break;
      logs.Debuglogs('RestoreLDAP() Found one error line '+intToStr(error));
      ldap.LDAP_STOP();
      cmd:='slapadd -s -j ' + IntToStr(error+1)+' -l /opt/artica/backup/restore/ldap/artica_ldap.ldif -f '+ldapcf_path+' -b "'+suffix+'" >'+tmpstr+' 2>&1 &';
      logs.Debuglogs(cmd);
      fpsystem(cmd);
      sleep(5000);
      error:=RestoreLDAP_Checkerrors(tmpstr);
      if(count>20) then break;
  end;

  if error>0 then begin
       logs.Debuglogs('RestoreLDAP() Found one error line '+intToStr(error));
       logs.OutputCmd('slapadd -s -j ' + IntToStr(error)+' -l /opt/artica/backup/restore/ldap/artica_ldap.ldif -f '+ldapcf_path+' -b "'+suffix+'" >'+tmpstr+' 2>&1');
  end;

  logs.Debuglogs('RestoreLDAP() indexing ldap server');
  logs.Debuglogs('RestoreLDAP() stopping ldap server');
  logs.WriteToFile('#','/etc/artica-postfix/STOP-LDAP');
  ldap.LDAP_STOP();

  logs.OutputCmd('slapindex');
  logs.Debuglogs('RestoreLDAP() starting openldap server');
  logs.DeleteFile('/etc/artica-postfix/STOP-LDAP');
  ldap.LDAP_START();
  logs.Debuglogs('RestoreLDAP() ldap server successfully restored...');
  logs.WriteToFile('#','/etc/artica-postfix/ldap.restored');


end;
//##############################################################################
function tincrement.RestoreLDAP_Checkerrors(path:string):integer;
var
    RegExpr:TRegExpr;
    l:TstringList;
    i:integer;
begin

result:=0;
if not FileExists(path) then exit;
l:=TstringList.Create;
l.LoadFromFile(path);
RegExpr:=TRegExpr.Create;
logs.DeleteFile(path);
RegExpr.Expression:='could not parse entry.+?line=([0-9]+)';
for i:=0 to l.Count-1 do begin
    logs.Debuglogs('RestoreLDAP_Checkerrors: Check ' +l.Strings[i] );
   if RegExpr.Exec(l.Strings[i]) then begin
      TryStrToInt(RegExpr.Match[1],result);
      break;
   end;
end;

l.free;
RegExpr.free;
end;
//##############################################################################
procedure tincrement.DAR_FIND_FILE(ressource:string;filepath:string);
var
    RegExpr:TRegExpr;
    l:TstringList;
    i:integer;
begin

   if not mount.mount(ressource) then begin
      writeln('Failed to mount resource');
      exit;
   end;
   logs.Debuglogs(dar_manager +' -B '+mount.TargetFolderToBackup+'/collection.dmd -f "'+filepath+'"');
   fpsystem(dar_manager +' -B '+mount.TargetFolderToBackup+'/collection.dmd -f "'+filepath+'"');
   mount.DisMount();

end;
//##############################################################################





procedure tincrement.artica_cyrus_backup();
var
   cmd:string;
   tmpstr:string;
   databases:TstringList;
   i:integer;
   configdirectory:string;
   partitiondefault:string;
   database_path:string;
begin
   if mailboxes_datas=0 then begin
       logs.Debuglogs('Backup Cyrus imap mailbox datas is disabled');
       exit;
   end;

   logs.Debuglogs('#############################');
   logs.Debuglogs('##                         ##');
   logs.Debuglogs('##          cyrus          ##');
   logs.Debuglogs('##                         ##');
   logs.Debuglogs('#############################');


   events.SetStart();
   events.SetRessource('Mailboxes');


   if not FileExists(SYS.LOCATE_ctl_mboxlist()) then begin
      events.SetError('unable to stat ctl_mboxlist !!');
      exit;
   end;

   if FileExists('/etc/artica-postfix/backup-cyrus-completed') then begin
      logs.Debuglogs('/etc/artica-postfix/backup-cyrus-completed=' + IntToStr(SYS.FILE_TIME_BETWEEN_MIN('/etc/artica-postfix/backup-cyrus-completed'))+' min');
      if SYS.FILE_TIME_BETWEEN_MIN('/etc/artica-postfix/backup-cyrus-completed')<60 then begin
           events.SetError('Already backup is performed under 60 minutes... skip it');
           exit;
      end;
   end;

   ccyrus:=TCyrus.Create(SYS);
   configdirectory:=ccyrus.IMAPD_GET('configdirectory');
   partitiondefault:=ccyrus.IMAPD_GET('partition-default');


   if length(configdirectory)=0 then begin
      events.SetError('unable to stat configdirectory !!');
      exit;
   end;


   if length(partitiondefault)=0 then begin
     events.SetError('unable to stat partitiondefault !!');
     exit;
   end;


   SetCurrentDir('/root');
   logs.Debuglogs('configdirectory='+configdirectory);

   logs.Debuglogs('Exporting mailboxlist');
   fpsystem('su - cyrus -c "'+SYS.LOCATE_ctl_mboxlist()+' -d" >'+configdirectory+'/mailboxlist.txt');
   logs.Debuglogs('Stopping cyrus');
   ccyrus.CYRUS_DAEMON_STOP();
   SetCurrentDir('/root');

   logs.Debuglogs('Executing backup...');

   events.SetRessource('dir:'+configdirectory);
   database_path:=TargetFolderToBackup+'/cyrus_imap_datas';

   remote_rsync.RsyncRemoteFolder(configdirectory);
   if UseOnlyRsync=0 then begin
       EXECUTE_DAR_OPERATIONS(configdirectory,database_path);
   end else begin
      events.SetError('Only rsync technology is defined... aborting dar for "'+configdirectory+'"');
  end;

   events.SetStart();
   events.SetRessource('dir:'+partitiondefault);

   remote_rsync.RsyncRemoteFolder(partitiondefault);
   if UseOnlyRsync=0 then begin
      EXECUTE_DAR_OPERATIONS(partitiondefault,TargetFolderToBackup+'/cyrus_imap_mail');
   end else begin
      events.SetError('Only rsync technology is defined... aborting dar for "'+partitiondefault+'"');
  end;

   ccyrus.CYRUS_DAEMON_START();
   logs.DeleteFile('/etc/artica-postfix/backup-cyrus-completed');
   fpsystem('/bin/touch /etc/artica-postfix/backup-cyrus-completed');

end;
//##############################################################################
procedure tincrement.EXECUTE_DAR_OPERATIONS(source_folder:string;database_path:string);
var
   cmd:string;
   fileTmp:string;
   
begin

     logs.Debuglogs('');
     logs.Debuglogs('');
     logs.Debuglogs('************************************************************************');
     logs.Debuglogs('*********************** EXECUTE_DAR_OPERATIONS *************************');
     logs.Debuglogs('************************************************************************');
     logs.Debuglogs('EXECUTE_DAR_OPERATIONS:: Path to backup...........: '+source_folder);
     logs.Debuglogs('EXECUTE_DAR_OPERATIONS:: Database path............: '+database_path);
     cmd:=BuildDarCommand(database_path,source_folder);

       if length(cmd)=0 then begin
           events.SetError('Error while build dar command');
           logs.Debuglogs('************************************************************************');
           logs.Debuglogs('************************************************************************');
           logs.Debuglogs('');
           exit;
       end;
       fileTmp:=logs.FILE_TEMP();
       logs.Debuglogs('EXECUTE_DAR_OPERATIONS:: '+cmd);
       logs.Debuglogs('EXECUTE_DAR_OPERATIONS:: Execute...');
       fpsystem(cmd +' > '+fileTmp+' 2>&1');
       logs.Debuglogs('EXECUTE_DAR_OPERATIONS:: Backup "'+source_folder+'" terminated');

       if not DAR_CHECK_ERRORS(fileTmp) then begin
             logs.Debuglogs('EXECUTE_DAR_OPERATIONS:: Error detected, retry ');
             cmd:=BuildDarCommand(database_path,source_folder);
             fileTmp:=logs.FILE_TEMP();
             logs.Debuglogs('EXECUTE_DAR_OPERATIONS:: '+cmd);
             fpsystem(cmd +' > '+fileTmp+' 2>&1');
             logs.Debuglogs('EXECUTE_DAR_OPERATIONS:: Backup "'+source_folder+'" after one error terminated');
             if not DAR_CHECK_ERRORS(fileTmp) then begin
                logs.Debuglogs('EXECUTE_DAR_OPERATIONS:: Aborting operation');
                logs.Debuglogs('************************************************************************');
                logs.Debuglogs('************************************************************************');
                logs.Debuglogs('');
                exit;
             end;
      end;


       if not DAR_CHECK_CONSISTENCY(database_path) then begin
               logs.Debuglogs('EXECUTE_DAR_OPERATIONS:: Aborting operation');
                logs.Debuglogs('************************************************************************');
                logs.Debuglogs('************************************************************************');
                logs.Debuglogs('');
                exit;
       end;

       logs.Debuglogs('EXECUTE_DAR_OPERATIONS:: Backup "'+source_folder+'" Success');
       events.SetDatabasePath(database_path);
       Add_user_defined(source_folder,database_path);
       Add_user_defined(source_folder,ExtractFileName(database_path));
       events.SetXML(xmlSingle(database_path));
       Build_collections(database_path);
       events.Build();
           logs.Debuglogs('************************************************************************');
           logs.Debuglogs('************************************************************************');
       logs.Debuglogs('');

end;
//##############################################################################
function tincrement.DAR_CHECK_CONSISTENCY(database_path:string):boolean;
var
   cmd:string;
   i:integer;
   tmpfile:string;
begin

    if not FileExists(database_path+'.1.dar') then begin
      logs.Debuglogs('DAR_CHECK_CONSISTENCY:: unable to stat '+database_path+'.1.dar');
      exit(true);
    end;


     cmd:=SYS.EXEC_NICE()+ dar_bin+' -Q --noconf -t '+database_path;
     tmpfile:=logs.FILE_TEMP();
     logs.Debuglogs('DAR_CHECK_CONSISTENCY:: check '+database_path);
     logs.Debuglogs('DAR_CHECK_CONSISTENCY:: '+cmd);
     fpsystem(cmd+' >'+tmpfile+' 2>&1');
     if not DAR_CHECK_ERRORS(tmpfile) then begin
       logs.Debuglogs('DAR_CHECK_CONSISTENCY:: FALSE');
       logs.OutputCmd('/bin/rm '+database_path+'*.dar');
       exit;
     end;

     exit(true);


end;
//##############################################################################







function tincrement.DAR_CHECK_ERRORS(tmpfile:string):boolean;
var
   RegExpr:TRegExpr;
   l:Tstringlist;
   i:integer;
begin

    if not FileExists(tmpfile) then begin
      logs.Debuglogs('DAR_CHECK_ERRORS:: unable to stat '+tmpfile);
      exit(true);
    end;
    result:=false;

    if SYS.FileSize_ko(tmpfile)>0 then begin
         logs.Debuglogs('DAR_CHECK_ERRORS:: this is a data file...');
         exit(true);
    end;

    l:=Tstringlist.Create ;
    try
       l.LoadFromFile(tmpfile);
    except
      logs.Debuglogs('DAR_CHECK_ERRORS:: FATAL ERROR while reading '+tmpfile);
      exit;
    end;
    RegExpr:=TRegExpr.Create;
    for i:=0 to l.Count-1 do begin

        logs.Debuglogs('DAR_CHECK_ERRORS:: '+l.Strings[i]);
        RegExpr.Expression:='asking:\s+(.+?)\s+has a bad or corrupted header';
        if RegExpr.Exec(l.Strings[i]) then begin
          logs.Debuglogs('DAR_CHECK_ERRORS:: Corrupted file '+RegExpr.Match[1]+' delete it');
          logs.DeleteFile(RegExpr.Match[1]);
          logs.DeleteFile(tmpfile);
          RegExpr.free;
          l.free;
          exit;
       end;

       RegExpr.Expression:='Badly formatted terminator, cannot extract catalogue location';
       if RegExpr.Exec(l.Strings[i]) then begin
        logs.Debuglogs('DAR_CHECK_ERRORS:: Corrupted file report was "Badly formatted terminator, cannot extract catalogue location"');
        RegExpr.free;
        l.free;
        exit;
       end;


    end;
logs.Debuglogs('DAR_CHECK_ERRORS:: No error reported...');
result:=true;
RegExpr.free;
logs.DeleteFile(tmpfile);
l.free;

end;
//##############################################################################

procedure tincrement.artica_backup_homes_backup();
var
   cmd:string;
   tmpstr:string;
   FolderList:TstringList;
   i:integer;
   Md5name:string;

begin
   if homes=0 then begin
       logs.Debuglogs('Backup homes folders datas is disabled');
       exit;
   end;

   logs.Debuglogs('#############################');
   logs.Debuglogs('##                         ##');
   logs.Debuglogs('##           homes         ##');
   logs.Debuglogs('##                         ##');
   logs.Debuglogs('#############################');


   FolderList:=TStringList.Create;
   FolderList.AddStrings(SYS.DirDir('/home'));
   logs.Debuglogs('Starting executing backup on ' +IntToStr(FolderList.Count) +' homes folders');

   for i:=0 to FolderList.Count-1 do begin
       if length(trim(FolderList.Strings[i]))=0 then continue;
       if not isHomeExclude(FolderList.Strings[i]) then begin
             logs.Debuglogs('artica_backup_homes_backup:: start backup of "/home/'+FolderList.Strings[i]+'"');
             if FolderList.Strings[i]='artica' then begin
                logs.Debuglogs('denied /home/artica loop to myself !');
                continue;
             end;


             logs.Debuglogs('******************************************************');
             logs.Debuglogs('***');
             logs.Debuglogs('***');
             logs.Debuglogs('*** /home/'+FolderList.Strings[i]);
             logs.Debuglogs('***');
             logs.Debuglogs('***');
             logs.Debuglogs('******************************************************');

             remote_rsync.RsyncRemoteFolder('/home/'+FolderList.Strings[i]);
             if UseOnlyRsync=1 then begin
                logs.Debuglogs('Only rsync technology is defined... aborting dar for "/home/'+FolderList.Strings[i]+'"');
                continue;
             end;

             Md5name:=logs.MD5FromString(FolderList.Strings[i]);

             EXECUTE_DAR_OPERATIONS('/home/'+FolderList.Strings[i],TargetFolderToBackup+'/homes_'+Md5name);
             SetCurrentDir('/root');
       end else begin
            logs.Debuglogs('artica_backup_homes_backup:: excluded "/home/'+FolderList.Strings[i]+'" from backup');
      end;
   end;

end;

//##############################################################################
function tincrement.isHomeExclude(path:string):boolean;
var i:integer;
begin
   result:=false;
   if Lowercase('artica')=Lowercase(trim(path)) then exit(true);
   for i:=0 to ExcludeHomesFolders.Count-1 do begin
        if Lowercase(ExcludeHomesFolders.Strings[i])=Lowercase(path) then begin
           result:=true;
           break;
        end;
   end;
end;
//##############################################################################


//##############################################################################
procedure tincrement.artica_backup_perso_backup();
var
   cmd:string;
   tmpstr:string;
   FolderList:TstringList;
   i:integer;
   Md5name:string;

begin
   if user_defined=0 then begin
       logs.Debuglogs('Backup user defined folders datas is disabled');
       exit;
   end;

   logs.Debuglogs('#############################');
   logs.Debuglogs('##                         ##');
   logs.Debuglogs('##      user defined       ##');
   logs.Debuglogs('##                         ##');
   logs.Debuglogs('#############################');

     logs.Debuglogs('Starting executing backup on ' +IntToStr(PersoFoldersList.Count) +' folders');

   for i:=0 to PersoFoldersList.Count-1 do begin
       if length(trim(PersoFoldersList.Strings[i]))=0 then continue;
       logs.Debuglogs('artica_backup_perso_backup:: start backup of "'+PersoFoldersList.Strings[i]+'"');
       Md5name:=logs.MD5FromString(PersoFoldersList.Strings[i]);
       Add_user_defined('userdef_'+Md5name,PersoFoldersList.Strings[i]);

       remote_rsync.RsyncRemoteFolder(PersoFoldersList.Strings[i]);
       if UseOnlyRsync=1 then begin
            logs.Debuglogs('Only rsync technology is defined... aborting dar for "'+PersoFoldersList.Strings[i]+'"');
            continue;
       end;

        EXECUTE_DAR_OPERATIONS(PersoFoldersList.Strings[i],TargetFolderToBackup+'/userdef_'+Md5name);
        SetCurrentDir('/root');
   end;
end;

//##############################################################################
procedure tincrement.artica_backup_single_path(path:string);
var
   i:integer;
   tot:integer;

begin

remote_rsync.RsyncRemoteFolder(path);
if UseOnlyRsync=1 then exit;

     tot:=0;
    for i:=0 to external_storages.Count-1 do begin
       if length(trim(external_storages.Strings[i]))>0 then begin
           if mount.IsMounted then begin
                artica_backup_single_path_op(path);
                inc(tot);
                mount.Dismount();
           end;

       end;
    end;

    if tot=0 then begin
           if use_local_external_failed=1 then begin
                external_ressource:='dir:'+ path;
                if mount.IsMounted then begin
                artica_backup_single_path_op(path);
                mount.Dismount();
                end;
           end;
    end;

end;
//##############################################################################
procedure tincrement.artica_backup_single_path_op(path:string);
var
   cmd:string;
   tmpstr:string;
   Md5name:string;

begin
   if user_defined=0 then begin
       logs.Debuglogs('Backup user defined folders datas is disabled');
       exit;
   end;

   if not mount.IsMounted then begin
       logs.Syslogs('artica_backup_single_path:: Unable to mount a storage media...');
       exit;
   end;

   if length(path)=0 then begin
        logs.Debuglogs('artica_backup_single_path:: no path specified');
        exit;
  end;


   logs.Debuglogs('#############################');
   logs.Debuglogs('##                         ##');
   logs.Debuglogs('##      user defined       ##');
   logs.Debuglogs('##                         ##');
   logs.Debuglogs('#############################');

    logs.Debuglogs('Starting executing backup on ' +path+' folder');


 remote_rsync.RsyncRemoteFolder(path);
 if UseOnlyRsync=1 then begin
    logs.Debuglogs('artica_backup_single_path_op:: excluded dar technology for '+path);
    exit;
  end;


    Md5name:=logs.MD5FromString(path);
    Add_user_defined('userdef_'+Md5name,path);
    EXECUTE_DAR_OPERATIONS(path,TargetFolderToBackup+'/userdef_'+Md5name);
    SetCurrentDir('/root');


end;

//##############################################################################
procedure tincrement.Add_user_defined(name_path:string;original_path:string);
var
      IniPerso:TiniFile;
begin
   forceDirectories('/var/log/artica-postfix/increment-queue');
   IniPerso:=TiniFile.Create('/var/log/artica-postfix/increment-queue/user_defined.conf');
   IniPerso.WriteString(name_path,'TargetFolder',original_path);
   iniperso.UpdateFile;
   iniperso.Free;

end;
//##############################################################################


procedure tincrement.artica_backup_samba_backup();
var
   FolderList:TstringList;
   i:integer;
   Md5name:string;

begin
   if shares_folders=0 then begin
       logs.Debuglogs('Backup shares folder datas is disabled');
       exit;
   end;

   logs.Debuglogs('#############################');
   logs.Debuglogs('##                         ##');
   logs.Debuglogs('##           Samba         ##');
   logs.Debuglogs('##                         ##');
   logs.Debuglogs('#############################');

   samba:=Tsamba.Create;
   FolderList:=TStringList.Create;
   FolderList.AddStrings(samba.ParseSharedDirectories());
   logs.Debuglogs('Starting executing backup on ' +IntToStr(FolderList.Count) +' folders');

   for i:=0 to FolderList.Count-1 do begin
       if length(trim(FolderList.Strings[i]))=0 then continue;
       if not isSambaExclude(FolderList.Strings[i]) then begin
             logs.Debuglogs('artica_backup_samba_backup:: start backup of "'+FolderList.Strings[i]+'"');


             remote_rsync.RsyncRemoteFolder(FolderList.Strings[i]);
             if UseOnlyRsync=1 then begin
                logs.Debuglogs('artica_backup_samba_backup:: excluded dar technology');
                continue;
             end;

             Md5name:=logs.MD5FromString(FolderList.Strings[i]);
             Add_user_defined('smb_'+Md5name,FolderList.Strings[i]);
             EXECUTE_DAR_OPERATIONS(FolderList.Strings[i],TargetFolderToBackup+'/smb_'+Md5name);

             SetCurrentDir('/root');
       end else begin
            logs.Debuglogs('artica_backup_samba_backup:: excluded "'+FolderList.Strings[i]+'" from backup');
      end;
   end;

end;

//##############################################################################
function tincrement.isSambaExclude(path:string):boolean;
var i:integer;
begin
   result:=false;

   for i:=0 to ExcludeSambaFolders.Count-1 do begin
        if Lowercase(ExcludeSambaFolders.Strings[i])=Lowercase(path) then begin
           result:=true;
           break;
        end;
   end;
end;
//##############################################################################
procedure tincrement.artica_RemoteComputer_backup(computer_name:string;user:string;password:string;remoteshare:string;remote_folder:string);
var
   cmd:string;
   cmd_username:string;
   cmd_password:string;
   mounted_dir:string;
   dar_backup_folder:string;
   FullRemotePath:string;
   l:TstringList;
   queue_file:string;
   xmlfile:string;
begin

   logs.Debuglogs('#############################');
   logs.Debuglogs('##                         ##');
   logs.Debuglogs('## '+computer_name+'##');
   logs.Debuglogs('##           backup        ##');
   logs.Debuglogs('##                         ##');
   logs.Debuglogs('#############################');
   remote_folder:=trim(remote_folder);
   queue_file:='/var/log/artica-postfix/dar-queue/'+ logs.MD5FromString(logs.DateTimeNowSQL())+'.queue';


   l:=Tstringlist.Create;
   l.Add('[INCREMENTAL]');
   l.Add('ressource=smb://'+computer_name+'/'+remoteshare+'/'+remote_folder);
   l.Add('started_on='+logs.DateTimeNowSQL());



   if not FileExists('/usr/bin/smbmount') then begin
       logs.Debuglogs('unable to stat /usr/bin/smbmount');
        l.Add('failed=1');
        l.Add('error=unable to stat /usr/bin/smbmount');
        logs.WriteToFile(l.Text,queue_file);
        l.free;
       exit;
   end;


   mounted_dir:='/opt/artica/mount/'+logs.MD5FromString(computer_name+user+password+remoteshare+remote_folder);

   if not SYS.isMountedTargetPath(mounted_dir) then begin
      ForceDirectories(mounted_dir);
      if(length(user)>0) then cmd_username:='username='+user;
      if(length(password)>0) then cmd_password:=',password='+password+',';
      cmd:='/usr/bin/smbmount //'+computer_name+'/'+remoteshare+' '+mounted_dir+' -o '+cmd_username+cmd_password+'rw';
      logs.Debuglogs('Mount '+computer_name);
      logs.Debuglogs(cmd);
      fpsystem(cmd);
   end;



   if not SYS.isMountedTargetPath(mounted_dir) then begin
       logs.Debuglogs('Mount '+computer_name+' failed');
       logs.Debuglogs('unable to stat /usr/bin/smbmount');
        l.Add('failed=1');
        l.Add('error=Mount '+computer_name+' failed');
        logs.WriteToFile(l.Text,queue_file);
        l.free;
       exit;
   end;





   if length(remote_folder)>0 then begin
      FullRemotePath:=mounted_dir+'/'+ remote_folder
   end else begin
      FullRemotePath:=mounted_dir;
   end;

   logs.Debuglogs(computer_name+' is Mounted on..."'+mounted_dir+'"');

   if DirectoryExists(FullRemotePath) then begin
          remote_rsync.RsyncRemoteFolder(FullRemotePath,computer_name);
          if UseOnlyRsync=1 then begin
             logs.Debuglogs('Remotesync is only the backup used..');
             fpsystem('/bin/umount -f '+mounted_dir);
             exit;
          end;
   end;



   dar_backup_folder:=logs.MD5FromString(remoteshare+'/'+remote_folder);

   if not Mount.IsMounted then begin
      logs.Debuglogs('Local ressources is not mounted ');
      fpsystem('/bin/umount -f '+mounted_dir);
        l.Add('failed=1');
        l.Add('error=Local ressource is not mounted');
        logs.WriteToFile(l.Text,queue_file);
        l.free;
      exit;
   end;

   forceDirectories(TargetFolderToBackup+'/'+computer_name);
   cmd:=BuildDarCommand(TargetFolderToBackup+'/'+computer_name+'/'+dar_backup_folder,FullRemotePath);


   l.Add('db_path='+TargetFolderToBackup+'/'+computer_name+'/'+dar_backup_folder);


   logs.Debuglogs(cmd);
   logs.Debuglogs('Launching dar backup...');
   fpsystem(cmd);
   logs.Debuglogs('dismount '+computer_name);
   fpsystem('/bin/umount -f '+mounted_dir);
   fpsystem('/bin/rmdir '+mounted_dir);
   logs.Debuglogs('Building collection...');
   BuildSingleCollection(TargetFolderToBackup+'/'+computer_name);
   logs.Debuglogs('Building xml file...');
   xmlSingle(TargetFolderToBackup+'/'+computer_name+'/'+dar_backup_folder);
   xmlfile:=TargetFolderToBackup+'/'+computer_name+'/'+dar_backup_folder+'.ls';

   l.Add('xml='+xmlfile);
   l.Add('finish_on='+logs.DateTimeNowSQL());
   l.Add('failed=0');
   logs.WriteToFile(l.Text,queue_file);
   l.free;

end;



procedure tincrement.artica_backupMails_backup();
var
   cmd:string;
   HtmlsizeQueue:string;
   CompressQueue:string;
begin
   if OnFly=0 then begin
       logs.Debuglogs('Backup artica mails datas is disabled');
       exit;
   end;

   logs.Debuglogs('#############################');
   logs.Debuglogs('##                         ##');
   logs.Debuglogs('##          backuped       ##');
   logs.Debuglogs('##           mails         ##');
   logs.Debuglogs('##                         ##');
   logs.Debuglogs('#############################');



   if FileExists('/etc/artica-postfix/backup-OnFly-completed') then begin
      logs.Debuglogs('/etc/artica-postfix/backup-OnFly-completed=' + IntToStr(SYS.FILE_TIME_BETWEEN_MIN('/etc/artica-postfix/backup-OnFly-completed'))+' min');
      if SYS.FILE_TIME_BETWEEN_MIN('/etc/artica-postfix/backup-OnFly-completed')<60 then begin
           logs.Debuglogs('Already backup is performed under 60 minutes... skip it');
           exit;
      end;
   end;
   SetCurrentDir('/root');


   remote_rsync.RsyncRemoteFolder('/opt/artica/share/www/attachments');
   if UseOnlyRsync=0 then begin
     Add_user_defined('attachments_datas','/opt/artica/share/www/attachments');
     cmd:=BuildDarCommand(TargetFolderToBackup+'/attachments_datas','/opt/artica/share/www/attachments');
     if length(cmd)>0 then logs.OutputCmd(cmd);
   end;


   SetCurrentDir('/root');

    remote_rsync.RsyncRemoteFolder('/opt/artica/share/www/attachments');
     if UseOnlyRsync=0 then begin
        Add_user_defined('original_messages_datas','/opt/artica/share/www/original_messages');
        cmd:=BuildDarCommand(TargetFolderToBackup+'/original_messages_datas','/opt/artica/share/www/original_messages');
        if length(cmd)>0 then logs.OutputCmd(cmd);
     end;


   SetCurrentDir('/root');

   HtmlsizeQueue:=SYS.GET_INFO('HtmlsizeQueue');
   CompressQueue:=SYS.GET_INFO('CompressQueue');



   if DirectoryExists(HtmlsizeQueue) then begin
          remote_rsync.RsyncRemoteFolder(HtmlsizeQueue);
          if UseOnlyRsync=0 then begin
              Add_user_defined('HtmlsizeQueue_datas',HtmlsizeQueue);
              cmd:=BuildDarCommand(TargetFolderToBackup+'/HtmlsizeQueue_datas',HtmlsizeQueue);
              if length(cmd)>0 then logs.OutputCmd(cmd);
          end;
   end;


    SetCurrentDir('/root');

   if DirectoryExists(CompressQueue) then begin
          remote_rsync.RsyncRemoteFolder(CompressQueue);
          if UseOnlyRsync=0 then begin
              Add_user_defined('CompressQueue_datas',CompressQueue);
              cmd:=BuildDarCommand(TargetFolderToBackup+'/CompressQueue_datas',CompressQueue);
              if length(cmd)>0 then logs.OutputCmd(cmd);
          end;
   end;

    SetCurrentDir('/root');

end;

//##############################################################################

function tincrement.BuildDarCommand(source_backup:string;PathToBackup:string):string;
var
cmd:string;
increment:boolean;
source_backup_diff:string;
RegExpr:TRegExpr;
pid:string;
begin

PathToBackup:=AnsiReplaceText(PathToBackup,'\''','''');
if Not DirectoryExists(PathToBackup) then begin
     logs.Debuglogs('BuildDarCommand:: Folder to backup "' + PathToBackup +'" Does not exists');
     exit;
end;

RegExpr:=TRegExpr.Create;
RegExpr.Expression:='^/(.+?)/(.+)$';
if not RegExpr.Exec(source_backup) then begin
     FindExternalResources();
     source_backup:=TargetFolderToBackup+source_backup;
end;

if not RegExpr.Exec(source_backup) then begin
     logs.Debuglogs('BuildDarCommand:: corrupted Backup container path '+source_backup);
     exit;
end;


logs.Debuglogs('BuildDarCommand:: Backup folder "' + PathToBackup +'"');
logs.Debuglogs('BuildDarCommand:: Backup container path will be  "'+source_backup+'"(' + RegExpr.Match[1] +') ');

increment:=false;
  if FileExists(source_backup+'.1.dar') then begin
     logs.Debuglogs(source_backup+'.1.dar exists, runing into incremental');
     increment:=true;
  end;



  if increment then begin
     source_backup_diff:=source_backup+'-'+FormatDateTime('yyyy-mm-dd-hh-nn', Now)+'-diff';
     if FileExists(source_backup_diff+'.1.dar') then begin
            logs.Debuglogs(source_backup_diff+'.1.dar exists, skipping');
            exit;
     end;
  end else begin
      source_backup_diff:=source_backup;
  end;



  cmd:=cmd +dar_bin;
  cmd:=cmd + ' -c '+source_backup_diff;
  cmd:=cmd + ' -m ' + intToStr(minimal_compress);
  cmd:=cmd + ' -z' + intToStr(compress_level);
  cmd:=cmd + ' -s ' + intToStr(slice_size_mb)+'M';
  cmd:=cmd + ' -X "*.dar"';
  cmd:=cmd + ' ' + exludeCommandFiles;
  cmd:=cmd + ' --noconf -Q';
  cmd:=cmd + ' -D';
  cmd:=cmd + ' -R "'+PathToBackup+'"';
  if increment then cmd:=cmd + ' -A "'+source_backup+'"';

  pid:=SYS.PIDOF_PATTERN(dar_bin+'.+?'+source_backup_diff);
  logs.Debuglogs('BuildDarCommand: PID of '+dar_bin+' -c '+source_backup_diff +' is "' +pid+'"');

  if SYS.PROCESS_EXIST(pid) then begin
     logs.Debuglogs('BuildDarCommand:: backup '+PathToBackup +' is already running with previous instance..');
     exit;
  end;

  result:=SYS.EXEC_NICE()+cmd;


end;
//##############################################################################




end.
