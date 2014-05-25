unit install_generic;
{$MODE DELPHI}
//{$mode objfpc}{$H+}
{$LONGSTRINGS ON}

interface

uses
  Classes, SysUtils,strutils,unix,
  RegExpr in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/RegExpr.pas',
  logs in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/logs.pas',
  zsystem in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/zsystem.pas',
  lighttpd in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/lighttpd.pas',
  openldap in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/openldap.pas',

  
  IniFiles;

  type
  tinstall=class


private

       artica_path:string;
       DirListFiles:TstringList;
       function DirDir(FilePath: string):TstringList;

public
      CHEK_LOCAL_VERSION_BEFORE:integer;
      lighttpd:tlighttpd;
      openldap:topenldap;
      SYS:Tsystem;
      LOGS:Tlogs;
      constructor Create();
      procedure Free;
      function COMPILE_GENERIC(package_name:string):string;

      function INSTALL_STATUS(APP_NAME:string;POURC:integer):string;
      function INSTALL_PROGRESS(APP_NAME:string;info:string):string;
      function IS_USER_EXISTS(username:string):boolean;
      function INSTALL_SERVICE(service:string):boolean;
      procedure EMPTY_CACHE();

END;

implementation

constructor tinstall.Create();
begin
       forcedirectories('/etc/artica-postfix');
       LOGS:=tlogs.Create();
       SYS:=Tsystem.Create;
       lighttpd:=tlighttpd.Create(SYS);
       openldap:=topenldap.Create;

       DirListFiles:=TstringList.Create;
       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;
end;
//############################################################################
procedure tinstall.Free();
begin
   SYS.Free;
   logs.Free;
end;
//############################################################################
procedure tinstall.EMPTY_CACHE();
var ArticaMetaEnabled:integer;
begin
 fpsystem('/bin/rm -f /usr/share/artica-postfix/ressources/logs/cache/*');
 fpsystem('/bin/rm -rf /usr/share/artica-postfix/ressources/logs/web/cache/*');
 fpsystem('/bin/rm -f /usr/share/artica-postfix/ressources/logs/jGrowl-new-versions.txt');
 fpsystem('/bin/rm -f /etc/artica-postfix/versions.cache');
 fpsystem('/bin/rm -f /usr/share/artica-postfix/ressources/logs/global.versions.conf');
 fpsystem('/usr/share/artica-postfix/bin/artica-install --write-versions');
 fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.setup-center.php --force');
 fpsystem('/usr/share/artica-postfix/bin/process1 --force &');
 fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.shm.php --remove &');
 fpsystem('/etc/init.d/artica-status restart');
 fpsystem('rm -rf /usr/share/artica-postfix/ressources/web/logs/*.cache');
 if not TryStrToInt(SYS.GET_INFO('ArticaMetaEnabled'),ArticaMetaEnabled) then ArticaMetaEnabled:=0;
 if ArticaMetaEnabled=1 then begin
    fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.artica.meta.php --status --force &');
 end;

end;


function tinstall.COMPILE_GENERIC(package_name:string):string;
var
   LOG                                  :Tlogs;
   gcc_path,make_path,wget_path,compile_source:string;
   auto:TiniFile;
   tmp:string;
   sys:Tsystem;
   FILE_TEMP:TstringList;
   FILE_EXT:string;
   package_version:string;
   DECOMPRESS_OPT:string;
   www_prefix:string;
   uri_download:string;
   target_file:string;
   RegExpr:TRegExpr;
   int_version                          :integer;
   FileNamePrefix                       :string;
   local_folder                         :string;
   autoupdate_path                      :string;
   remote_uri                           :string;
   index_file                           :string;
   i                                    :integer;
   package_name_suffix                  :string;
   label                                 myEnd;



begin




    local_folder:='';
    remote_uri:='http://www.articatech.net/download';
    index_file:='http://www.articatech.net/auto.update.php';
    LOG:=Tlogs.Create;
    FILE_TEMP:=TStringList.Create;
    RegExpr:=TRegExpr.Create;
    package_name_suffix:=package_name;


 if ParamCount>0 then begin
     for i:=0 to ParamCount do begin
       RegExpr.Expression:='--remote-path=(.+)';
       if RegExpr.Exec(ParamStr(i)) then begin
           remote_uri:=RegExpr.Match[1];
       end;

       RegExpr.Expression:='--remote-index=(.+)';
       if RegExpr.Exec(ParamStr(i)) then begin
           index_file:=RegExpr.Match[1];
       end;

       RegExpr.Expression:='--folder=(.+)';
       if RegExpr.Exec(ParamStr(i)) then begin
          local_folder:=RegExpr.Match[1];
          logs.Debuglogs('Starting installation of ' + package_name + ' application using local folder ...'+local_folder);
       end;

    end;
 end;

    fpsystem('cd ' + ExtractFilePath(ParamStr(0)));

    forcedirectories('/opt/artica/install/sources');
    if FileExists('/opt/artica/install/sources/' + package_name) then fpsystem('/bin/rm -rf /opt/artica/install/sources/' + package_name);


    logs.Debuglogs('Checking last supported version of ' + package_name + ' from ' + remote_uri+'/'+index_file);

    if local_folder='' then SYS.WGET_DOWNLOAD_FILE(index_file,'/opt/artica/install/sources/autoupdate.ini');
    if local_folder='' then begin
       autoupdate_path:='/opt/artica/install/sources/autoupdate.ini';
    end else begin
        autoupdate_path:=local_folder + '/autoupdate.ini';
        if not FileExists(autoupdate_path) then begin
             logs.Debuglogs('unable to stat ' + autoupdate_path);
             exit;
        end;
    end;
    auto:=TIniFile.Create(autoupdate_path);

    FILE_EXT:=auto.ReadString('NEXT',package_name + '_ext','tar.gz');
    www_prefix:=auto.ReadString('NEXT',package_name + '_prefix','');
    FileNamePrefix:=auto.ReadString('NEXT',package_name + '_filename_prefix',package_name  + '-');



    package_version:=auto.ReadString('NEXT',package_name,'');
    target_file:=FileNamePrefix + package_version + '.' + FILE_EXT;



    auto.Free;

    if local_folder='' then begin
       uri_download:=remote_uri + '/' + target_file;
       if length(www_prefix)>0 then uri_download:=remote_uri+'/' + www_prefix + '/' + target_file;
    end else begin
       uri_download:=local_folder + '/' + target_file;
       if length(www_prefix)>0 then uri_download:=local_folder + '/' + www_prefix + '/' + target_file;
    end;

    logs.Debuglogs('');
    logs.Debuglogs('');
    logs.Debuglogs('###################################################################');
    logs.Debuglogs(chr(9)+'version..............:"' +package_version+'"');
    logs.Debuglogs(chr(9)+'extension............:"' +FILE_EXT+'"');
    logs.Debuglogs(chr(9)+'prefix...............:"' +www_prefix+'"');
    logs.Debuglogs(chr(9)+'FileName Prefix......:"' +FileNamePrefix+'"');
    logs.Debuglogs(chr(9)+'Target file..........:"' +target_file+'"');
    logs.Debuglogs(chr(9)+'uri..................:"' +uri_download + '"');





    if length(package_version)=0 then begin
         logs.Debuglogs('http source problem [NEXT]\' + package_name +  ' is null...aborting');
         exit;
    end;

    if CHEK_LOCAL_VERSION_BEFORE>0 then begin
       RegExpr.Expression:='([0-9\.]+)';
       if RegExpr.Exec(package_version) then begin
              tmp:=AnsiReplaceText(RegExpr.Match[1],'.','');
              int_version:=StrToInt(tmp);
              logs.Debuglogs(chr(9)+'Check version........:remote=' +IntToStr(int_version) + '<> local=' + IntToStr(CHEK_LOCAL_VERSION_BEFORE));
       end else begin
            exit;
       end;

       if CHEK_LOCAL_VERSION_BEFORE>=int_version then begin
          logs.Debuglogs(chr(9)+'Checked..............:updated, nothing to do');
          exit;
       end;
    end;

    logs.Debuglogs('###################################################################');
    logs.Debuglogs('');
    logs.Debuglogs('');

    if FILE_EXT='tar.bz2' then DECOMPRESS_OPT:='xjf' else DECOMPRESS_OPT:='xf';

     if DirectoryExists('/opt/artica/install/sources/' + package_name_suffix) then logs.OutputCmd('/bin -rm -rf /opt/artica/install/sources/' + package_name);
     logs.Debuglogs('Creating directory ' + '/opt/artica/install/sources/' + package_name);
     forcedirectories('/opt/artica/install/sources/' + package_name);

    logs.Debuglogs('Get: ' + uri_download);

    if local_folder='' then begin
       SYS.WGET_DOWNLOAD_FILE(uri_download,'/opt/artica/install/sources/' + target_file);
    end else begin
        fpsystem('/bin/cp -fv ' + uri_download + ' ' +  '/opt/artica/install/sources/' + target_file);
    end;

    if not FileExists('/opt/artica/install/sources/' + target_file) then begin
        logs.Debuglogs('Unable to stat /opt/artica/install/sources/' + target_file);
        exit;
    end;

    logs.Debuglogs('Uncompress the package...');
    logs.OutputCmd('/bin/tar -' + DECOMPRESS_OPT + ' /opt/artica/install/sources/' + target_file + ' -C /opt/artica/install/sources/' + package_name);
    DirDir('/opt/artica/install/sources/' + package_name);


    if DirListFiles.Count=0 then begin
       logs.OutputCmd('/bin/rm -rf /opt/artica/install/sources/'+package_name);
       logs.OutputCmd('/bin/rm /opt/artica/install/sources/'+target_file);
       goto myEnd;
    end;
    compile_source:='/opt/artica/install/sources/' + package_name + '/' + DirListFiles.Strings[0];
    logs.Debuglogs('SUCCESS: "' + compile_source + '"');
    result:=compile_source;
 goto myEnd;

myEnd:
    FILE_TEMP.free;


end;

//##############################################################################
function tinstall.DirDir(FilePath: string):TstringList;
Var Info : TSearchRec;
    D:boolean;
Begin


   DirListFiles.Clear;
  If FindFirst (FilePath+'/*',faDirectory,Info)=0 then begin
    Repeat
      if Info.Name<>'..' then begin
         if Info.Name <>'.' then begin
           if info.Attr=48 then begin
              DirListFiles.Add(Info.Name);
           end;

         end;
      end;

    Until FindNext(info)<>0;
    end;
  FindClose(Info);
  DirDir:=DirListFiles;
end;
//#########################################################################################
function tinstall.INSTALL_STATUS(APP_NAME:string;POURC:integer):string;
var ini:TiniFile;
begin
  result:='';
  forceDirectories('/usr/share/artica-postfix/ressources/install');
  try
     ini:=TIniFile.Create('/usr/share/artica-postfix/ressources/install/'+APP_NAME+'.ini');
     ini.WriteString('INSTALL','STATUS',IntToStr(POURC));
  except
   writeln('INSTALL_STATUS():: FATAL ERROR STAT /usr/share/artica-postfix/ressources/install/'+APP_NAME+'.ini');
   exit;
  end;
  ini.free;
    fpsystem('/bin/chmod -R 777 /usr/share/artica-postfix/ressources/install');
    fpsystem('/bin/chown -R www-data:www-data /usr/share/artica-postfix/ressources/install');
end;
//#############################################################################
function tinstall.INSTALL_PROGRESS(APP_NAME:string;info:string):string;
var ini:TiniFile;
begin
  result:='';
  forceDirectories('/usr/share/artica-postfix/ressources/install');
  try
     ini:=TIniFile.Create('/usr/share/artica-postfix/ressources/install/'+APP_NAME+'.ini');
     ini.WriteString('INSTALL','INFO',info);
  except
   writeln('INSTALL_STATUS():: FATAL ERROR STAT /usr/share/artica-postfix/ressources/install/'+APP_NAME+'.ini');
   exit;
  end;
  ini.free;
end;
//#############################################################################
function tinstall.INSTALL_SERVICE(service:string):boolean;
begin

 if FileExists('/usr/sbin/update-rc.d') then begin
    fpsystem('/usr/sbin/update-rc.d -f '+service+' defaults >/dev/null 2>&1');
 end;

  if FileExists('/sbin/chkconfig') then begin
     fpsystem('/sbin/chkconfig --add '+service+' >/dev/null 2>&1');
     fpsystem('/sbin/chkconfig --level 2345 '+service+' on >/dev/null 2>&1');
  end;

end;
//#############################################################################

function tinstall.IS_USER_EXISTS(username:string):boolean;
var
   ini:TstringList;
   RegExpr:TRegExpr;

begin
     result:=false;
     fpsystem('id ' + username + ' >/tmp/'+username);
     if not FileExists('/tmp/'+username) then exit;
     ini:=TstringList.Create;
     ini.LoadFromFile('/tmp/'+username);
     RegExpr:=TRegExpr.Create;
     RegExpr.Expression:='^uid=([0-9]+)';
     
     if RegExpr.Exec(ini.Text) then begin
        writeln('found user:' +RegExpr.Match[1]);
        result:=true;
     end;
     RegExpr.free;
     ini.free;

end;
//#############################################################################

end.
