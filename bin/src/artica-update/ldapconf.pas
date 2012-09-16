unit ldapconf;
{$MODE DELPHI}
//{$mode objfpc}{$H+}
{$LONGSTRINGS ON}

interface

uses
Classes, ldap,SysUtils,Process,unix,global_conf,Logs,RegExpr in 'RegExpr.pas',IniFiles,zsystem,articaldap;

  type
  tldapconf=class


private
       GLOBAL_INI:myconf;
       LDAP:tldap;
       LOGS:Tlogs;
       PROCEDURE DansGuardian_verif_groupfile(group_path:string);
       PROCEDURE DansGuardian_verif_globalConfig();
public
      constructor Create();
      procedure Free;

      PROCEDURE      FoldersSizeConfig();
      PROCEDURE      Squid(servername:string);
      PROCEDURE      Dansguardian(servername:string);
      PROCEDURE      ApplySecuLevel();
      PROCEDURE      FtpUsers();
      PROCEDURE      SqlGrey(servername:string);
      PROCEDURE      maincf();
      PROCEDURE      crossroads_sync();
      PROCEDURE      crossroads_apply(path:string);
      PROCEDURE      maintenance();
      PROCEDURE      Amavis();
      procedure      ZuluConfig();

END;

implementation

constructor tldapconf.Create();
begin
  GLOBAL_INI:=myconf.Create;
  ldap:=tldap.Create();
  LOGS:=Tlogs.Create;
end;
PROCEDURE tldapconf.Free();
begin
  GLOBAL_INI.free;
  ldap.free;
end;
//#############################################################################
PROCEDURE tldapconf.Squid(servername:string);
 var FileS:TstringList;
begin
  if not FileExists(GLOBAL_INI.SQUID_CONFIG_PATH()) then begin
     writeln('Could not stat squid.conf');
     exit;
  end;
  Files:=TstringList.Create;
  FileS.Add(ldap.Load_squid_settings(servername));
  LOGS.logs('Squid:: save squid config file in ' + GLOBAL_INI.SQUID_CONFIG_PATH());
  files.SaveToFile(GLOBAL_INI.SQUID_CONFIG_PATH());
  LOGS.logs('Squid:: restart squid process');
  GLOBAL_INI.SQUID_STOP();
  GLOBAL_INI.SQUID_START();
end;

//#############################################################################
PROCEDURE tldapconf.ApplySecuLevel();
var
   ArticaMailAddonsLevel:string;
   D:boolean;
begin
  ArticaMailAddonsLevel:=ldap.ArticaMailAddonsLevel();
  
  D:=GLOBAL_INI.COMMANDLINE_PARAMETERS('--verbose');
  LOGS.logs('ApplySecuLevel:: Email level=' + ArticaMailAddonsLevel);
  if D then writeln('ApplySecuLevel:: Email level=' + ArticaMailAddonsLevel);
  GLOBAL_INI.set_INFOS('ArticaMailAddonsLevel',ArticaMailAddonsLevel);
end;
//#############################################################################
PROCEDURE tldapconf.maincf();
var
   i                      :integer;
   Confd                  :postfix_settings;
   l                      :TstringList;
   restart                :boolean;
   LocalPostfixTimeCode   :string;
   header_check_path      :string;
   D                      :boolean;
   RegExpr                :TRegExpr;
begin

   if not FileExists(GLOBAL_INI.POSFTIX_POSTCONF_PATH()) then begin
      if D then writeln('maincf:: POSFTIX_POSTCONF_PATH() return a corrupted path or Postfix is not installed...');
      exit;
   end;
   Confd:=ldap.Load_postfix_main_settings();
   restart:=false;
   D:=GLOBAL_INI.COMMANDLINE_PARAMETERS('--verbose');

   LocalPostfixTimeCode:=GLOBAL_INI.get_INFOS('PostfixTimeCode');
   if D then writeln('maincf:: PostfixTimeCode :"' + Confd.PostfixTimeCode + '"<>"' + LocalPostfixTimeCode + '"');
   
   if length(LocalPostfixTimeCode)=0 then LocalPostfixTimeCode:='0';
   if length(Confd.PostfixTimeCode)=0 then Confd.PostfixTimeCode:='0';
   
   
   if Confd.PostfixTimeCode=LocalPostfixTimeCode then begin
       if D then writeln('maincf:: PostfixTimeCode is the same as local PostFixTimeCode, aborting...');
       exit;
   end;
  LOGS.logs('maincf:: PostfixTimeCode :' + Confd.PostfixTimeCode + '<>' + LocalPostfixTimeCode);
   
   if length(confd.PostfixMainCfFile)>0 then begin
      LOGS.logs('maincf:: Save "/etc/postfix/main.cf"');
      l:=TstringList.Create;
      l.Add(confd.PostfixMainCfFile);
      l.SaveToFile('/etc/postfix/main.cf');
      l.Free;
      restart:=true;
   end;
   
if length(confd.PostfixBounceTemplateFile)>0 then begin
      LOGS.logs('maincf:: Save "/etc/postfix/bounce.template.cf"');
      l:=TstringList.Create;
      l.Add(confd.PostfixBounceTemplateFile);
      l.SaveToFile('/etc/postfix/bounce.template.cf');
      fpsystem('/bin/chown root:root /etc/postfix/bounce.template.cf >/dev/null 2>&1');
      l.Free;
      restart:=true;
   end else begin
    LOGS.logs('maincf:: bounce_template disabled...');
end;
   
   
if length(confd.PostFixHeadersRegexFile)>0 then begin
      header_check_path:=GLOBAL_INI.POSTFIX_EXTRACT_MAINCF('header_checks');
      RegExpr:=TRegExpr.Create;

      RegExpr.Expression:='(.+?):(.+)';
      if RegExpr.Exec(header_check_path) then begin
         header_check_path:=RegExpr.Match[2];
      end;
      
      LOGS.logs('maincf:: Save "'+header_check_path+'"');
      
      l:=TstringList.Create;
      l.Add(confd.PostFixHeadersRegexFile);
      ForceDirectories(ExtractFilePath(header_check_path));
      l.SaveToFile(header_check_path);
      fpsystem('/bin/chown root:root '+ header_check_path + ' >/dev/null 2>&1');
      l.Free;
      restart:=true;
end else begin
    LOGS.logs('maincf:: header_check disabled...');
end;
   
   
   if D then writeln('maincf:: restart=',restart);
   if restart then begin
         GLOBAL_INI.POSTFIX_CHECK_POSTMAP();
         LOGS.logs('maincf:: restart postfix');
         GLOBAL_INI.POSFTIX_VERIFY_MAINCF();
   end;
   GLOBAL_INI.set_INFOS('PostfixTimeCode',Confd.PostfixTimeCode);
end;
//#############################################################################

PROCEDURE tldapconf.FtpUsers();
var
   i:integer;
   Confd:string;
   l:TstringList;
begin

ldap.Load_ftp_users();
  if FileExists('/opt/artica/var/pureftpd/pureftpd.pdb') then fpsystem('/bin/rm -rf /opt/artica/var/pureftpd/pureftpd.pdb');
  if FileExists('/opt/artica/etc/pureftpd.passwd') then fpsystem('/bin/rm -rf /opt/artica/etc/pureftpd.passwd');


if ldap.ftplist.Count>0 then begin
   for i:=0 to ldap.ftplist.Count-1 do begin
     LOGS.logs('->' + ldap.ftplist.Strings[i] + ' >/dev/null 2>&1');
     fpsystem(ldap.ftplist.Strings[i] + ' >/dev/null 2>&1');
   end;
   fpsystem('/opt/artica/bin/pure-pw mkdb /opt/artica/var/pureftpd/pureftpd.pdb -f /opt/artica/etc/pureftpd.passwd');
end;


if length(ParamStr(2))>0 then begin
       Confd:=ldap.pureftpd_settings(ParamStr(2));
       if length(Confd)>0 then begin
          l:=TstringList.Create;
          l.Add(Confd);
          l.SaveToFile('/opt/artica/etc/pure-ftpd.conf');
          l.free;
          GLOBAL_INI.PURE_FTPD_STOP();
          GLOBAL_INI.PURE_FTPD_PREPARE_LDAP_CONFIG();
          GLOBAL_INI.PURE_FTPD_START()
       end;
       
end;

end;

//#############################################################################
PROCEDURE tldapconf.FoldersSizeConfig();
var
D:Boolean;
L:TstringList;
Z:Tsystem;
F:artica_settings;
Execute:boolean;
path:string;
i:integer;
conf_path:string;
sAge:integer;
begin
 D:=GLOBAL_INI.COMMANDLINE_PARAMETERS('--verbose');
 sAge:=0;
 conf_path:='/etc/artica-postfix/FoldersSize.conf';
 sAge:=GLOBAL_INI.SYSTEM_FILE_MIN_BETWEEN_NOW(conf_path);
 if D then writeln('FoldersSizeConfig::',conf_path,' Age=',sAge);
 
 
 if not FileExists(conf_path) then begin
    sAge:=1000;
    if D then writeln('FoldersSizeConfig:: file:',conf_path,' does not exists, assume age as ',sAge);
 end;
 
 
 if sAge<5 then begin
    if D then writeln('FoldersSizeConfig:: Age is to young, aborting =>',sAge);
    exit;
 end;
 
 GLOBAL_INI.DeleteFile(conf_path);
 F:=ldap.Load_artica_main_settings();
 L:=TstringList.Create;
 for i:=0 to f.ArticaFoldersSizeConfig.Count-1 do begin
     path:=f.ArticaFoldersSizeConfig.Strings[i];
     if D then writeln('FoldersSizeConfig(): verify size of :', path);
     l.Add('[' + path + ']');
     l.Add('Size=' + IntToStr(GLOBAL_INI.SYSTEM_FOLDER_SIZE(path)));
 end;
 l.SaveToFile(conf_path);
 l.free;

end;


PROCEDURE tldapconf.maintenance();
var
D:Boolean;
L:TstringList;
Z:Tsystem;
F:artica_settings;
Execute:boolean;
touch_path:string;
i:integer;
begin
Execute:=false;
D:=GLOBAL_INI.COMMANDLINE_PARAMETERS('--verbose');
Z:=Tsystem.Create();
l:=TstringList.Create;
F:=ldap.Load_artica_main_settings();

if length(f.ArticaMaxTempLogFilesDay)=0 then f.ArticaMaxTempLogFilesDay:='3';

if GLOBAL_INI.COMMANDLINE_PARAMETERS('--delete') then GLOBAL_INI.DeleteFile('/etc/artica-postfix/cron.maintenance');

if FileExists('/bin/touch') then touch_path:='/bin/touch';
if FileExists('/usr/bin/touch') then touch_path:='/usr/bin/touch';
if Length(touch_path)=0 then begin
   LOGS.logs('maintenance():: unable to find touch tool');
   exit;
end;
if Not FileExists('/etc/artica-postfix/cron.maintenance') then begin
   Execute:=true;

end;

if not Execute then begin
   if D then writeln('maintenance():: cron.maintenance=',GLOBAL_INI.SYSTEM_FILE_MIN_BETWEEN_NOW('/etc/artica-postfix/cron.maintenance'));
   if GLOBAL_INI.SYSTEM_FILE_MIN_BETWEEN_NOW('/etc/artica-postfix/cron.maintenance')>10 then begin
        Execute:=true;
   end;
end;

if Execute=false then exit;
   GLOBAL_INI.DeleteFile('/etc/artica-postfix/cron.maintenance');
   l.AddStrings(z.RecusiveListFiles('/var/log'));
   l.AddStrings(z.RecusiveListFiles('/opt/artica/logs'));
   
   for i:=0 to l.Count -1 do begin
     if FileExists(l.Strings[i]) then begin
       if  GLOBAL_INI.SYSTEM_FILE_DAYS_BETWEEN_NOW(l.Strings[i])>StrToInt(f.ArticaMaxTempLogFilesDay) then begin
           if D then writeln(l.Strings[i], ' Days=Delete ' , GLOBAL_INI.SYSTEM_FILE_DAYS_BETWEEN_NOW(l.Strings[i]));
           GLOBAL_INI.DeleteFile(l.Strings[i]);
       end;
     end;

   end;
   
   
fpsystem(touch_path + ' /etc/artica-postfix/cron.maintenance');

end;
//#############################################################################

PROCEDURE tldapconf.crossroads_apply(path:string);
var
   D        :boolean;

begin
  if not FileExists(path) then exit;
  D:=GLOBAL_INI.COMMANDLINE_PARAMETERS('--verbose');
  logs.logs('crossroads_apply() -> move ' + path + ' to /etc/artica-postfix');
  fpsystem('/bin/mv ' + path + ' /etc/artica-postfix');
  GLOBAL_INI.ARTICA_STOP();
  GLOBAL_INI.LDAP_STOP();
  GLOBAL_INI.LDAP_VERIFY_SCHEMA();
  GLOBAL_INI.LDAP_START();
  GLOBAL_INI.ARTICA_START();
end;
//#############################################################################
PROCEDURE tldapconf.crossroads_sync();
var
 confs                :crossroads_settings;
 D                    :boolean;
 i                    :integer;
 IsIsMaster           :boolean;
 order                :TIniFile;
 ldap_server          :string;
 ldap_admin           :string;
 ldap_suffix          :string;
 ldap_password        :string;
 uri                  :string;
 cmdline              :string;
 
 
begin
   D:=GLOBAL_INI.COMMANDLINE_PARAMETERS('--verbose');
   logs.logs('Loading settings stored in database...');
   confs:=ldap.Load_crossroads_main_settings();
   IsIsMaster:=False;
   if D then begin

       
       writeln('crossroads_sync():: CrossRoadsBalancingServerIP........',confs.CrossRoadsBalancingServerIP);
       writeln('crossroads_sync():: PostfixMasterServerIdentity........',confs.PostfixMasterServerIdentity);
       writeln('crossroads_sync():: CrossRoadsBalancingServerName......',confs.CrossRoadsBalancingServerName);
       for i:=0 to confs.PostfixSlaveServersIdentity.Count-1 do begin
       
       writeln('Slave..............................[',i,']: ',confs.PostfixSlaveServersIdentity.Strings[i]);
       end;
   
   end;
   logs.logs('crossroads_sync():: CrossRoadsBalancingServerIP........'+confs.CrossRoadsBalancingServerIP);
   logs.logs('crossroads_sync():: PostfixMasterServerIdentity........'+confs.PostfixMasterServerIdentity);
   logs.logs('crossroads_sync():: CrossRoadsBalancingServerName......'+confs.CrossRoadsBalancingServerName);
   
   


   IsIsMaster:=GLOBAL_INI.SYSTEM_ISIP_LOCAL(confs.PostfixMasterServerIdentity);


   if not IsIsMaster then begin
        logs.logs('crossroads_sync():: This computer is not a master');
        if D then writeln('crossroads_sync():: This computer is not a master ');
        exit;
   end;
   
   
   
     ldap_server:=trim(GLOBAL_INI.get_LDAP('server'));
     ldap_admin:=trim(GLOBAL_INI.get_LDAP('admin'));
     ldap_suffix:=trim(GLOBAL_INI.get_LDAP('suffix'));
     ldap_password:=trim(GLOBAL_INI.get_LDAP('password'));

     logs.logs('crossroads_sync() this computer is a master ip (' + confs.PostfixMasterServerIdentity + ')');
     logs.logs('Creating file configuration....:/opt/artica/etc/crossroads.indentities.conf');

   
for i:=0 to confs.PostfixSlaveServersIdentity.Count-1 do begin
       uri:='https://'+confs.PostfixSlaveServersIdentity.Strings[i] +':9000/listener.balance.php';
       
       order:=TIniFile.Create('/opt/artica/etc/crossroads.indentities.conf');
       if D then writeln('Creating file configuration....:/opt/artica/etc/crossroads.indentities.conf');
       order.WriteString('INFOS','suffix',ldap_suffix);
       order.WriteString('INFOS','admin',ldap_admin);
       order.WriteString('INFOS','password',ldap_password);
       order.WriteString('INFOS','mastr_ip',confs.PostfixMasterServerIdentity);
       order.WriteString('INFOS','master_name',confs.CrossRoadsBalancingServerName);
       order.WriteString('INFOS','slave_ip',confs.PostfixSlaveServersIdentity.Strings[i]);
       order.WriteString('INFOS','pol_time', confs.CrossRoadsPoolingTime);
       order.UpdateFile;
       order.Free;

       cmdline:='/opt/artica/bin/curl -k -A artica --connect-timeout 5  -F "crossroads=@/opt/artica/etc/crossroads.indentities.conf" ' + uri;
       logs.logs(cmdline);
       writeln('Send requests to ' + confs.PostfixSlaveServersIdentity.Strings[i]);
       if D then writeln(cmdline);
       fpsystem(cmdline);
       end;
   
   
   

end;
//#############################################################################


PROCEDURE tldapconf.SqlGrey(servername:string);
   var big_conf         :string;
   D                    :boolean;
   l                    :TStringList;
   confs                :sqlgrey_settings;
   i                    :integer;
   folder_name          :string;
   folder_index         :integer;
   tmpfile              :string;
   order                :TIniFile;
   LocalTimeCode        :string;

begin
  D:=GLOBAL_INI.COMMANDLINE_PARAMETERS('--verbose');
  LOGS.logs('SqlGrey:: load SqlGrey main settings');
  confs:=ldap.Load_sqlgrey_settings(servername);
  GLOBAL_INI.set_INFOS('SqlGreyIsActive',IntToStr(confs.SqlGreyEnabled));


  if length(confs.SqlGreyConf)>0 then begin
   LocalTimeCode:=GLOBAL_INI.get_INFOS('SqlGreyTimeCode');
   if D then writeln('SqlGrey:: SqlGreyTimeCode :"' + confs.SqlGreyTimeCode + '"<>"' + LocalTimeCode + '"');

   if length(LocalTimeCode)=0 then LocalTimeCode:='0';
   if length(confs.SqlGreyTimeCode)=0 then confs.SqlGreyTimeCode:='0';


   if confs.SqlGreyTimeCode=LocalTimeCode then begin
       if D then writeln('SqlGrey:: SqlGreyTimeCodeimeCode is the same as local LocalTimeCode, aborting...');
       exit;
   end;
  LOGS.logs('SqlGrey:: SqlGreyTimeCode :' + confs.SqlGreyTimeCode + '<>' + LocalTimeCode);
  
      GLOBAL_INI.SQLGREY_STOP();
      l:=TStringList.Create;
      l.Add(confs.SqlGreyConf);
      l.SaveToFile('/opt/artica/etc/sqlgrey.conf');
      l.free;
      GLOBAL_INI.set_INFOS('SqlGreyTimeCode',confs.SqlGreyTimeCode);

  if confs.SqlGreyEnabled=1 then begin
         GLOBAL_INI.SQLGREY_START();
     end else begin
         GLOBAL_INI.SQLGREY_STOP();
   end;
  
  end;

end;

//#############################################################################
PROCEDURE tldapconf.DansGuardian(servername:string);
   var DansGuardian_conf:string;
   D                    :boolean;
   l                    :TStringList;
   confs                :dansguardian_settings;
   i                    :integer;
   folder_name          :string;
   folder_index         :integer;
   tmpfile              :string;

begin
  D:=GLOBAL_INI.COMMANDLINE_PARAMETERS('--verbose');
  LOGS.logs('DansGuardian:: load dansguardian main settings');
  confs:=ldap.Load_Dansguardian_MainConfiguration(servername);
  if length(confs.DansGuardianMasterConf)=0 then begin
       if D then writeln('DansGuardian:: Failed no datas found...');
       LOGS.logs('DansGuardian:: Failed no datas found...');
       exit;
  end;
  
  logs.Debuglogs('DansGuardian:: DansGuardianMasterConf:: ' + IntToStr(length(confs.DansGuardianMasterConf)) + ' bytes lenght');

  l:=TstringList.Create;
  l.Add(confs.DansGuardianMasterConf);
  l.SaveToFile('/opt/artica/etc/dansguardian/dansguardian.conf');
  l.Clear;
  DansGuardian_verif_globalConfig();
  logs.Debuglogs('DansGuardian:: /opt/artica/etc/dansguardian/dansguardian.conf saved');
  
  
  logs.Debuglogs('DansGuardian:: FilterGroupListConf:: ' + IntToStr(length(confs.FilterGroupListConf)) + ' bytes lenght');
  l:=TstringList.Create;
  l.Add(confs.DansGuardianMasterConf);
  l.SaveToFile('/opt/artica/etc/dansguardian/lists/filtergroupslist');
  l.Clear;
  
  
  logs.Debuglogs('DansGuardian:: load DansGuardianRulesIndex=',confs.DansGuardianRulesIndex.Count);
  
  For i:=0 to confs.DansGuardianRulesIndex.Count-1 do begin
       folder_index:=i+1;
       folder_name:='/opt/artica/etc/dansguardian/group_' + IntToStr(folder_index) ;
       if D then writeln('DansGuardian:: preparing Group ',folder_name);
       forcedirectories(folder_name);
       tmpfile:=ldap.Load_Dansguardian_fileconfig(servername,IntToStr(folder_index),'DansGuardianMainGroupeRule');
       logs.Debuglogs('DansGuardian:: DansGuardianMainGroupeRule=' + IntToStr(length(tmpfile)) + ' bytes lenght');
       if length(tmpfile)>0 then begin
          logs.Debuglogs('DansGuardian:: /opt/artica/etc/dansguardian/dansguardianf' + IntToStr(folder_index)+ '.conf');
          l.Add(tmpfile);
          l.SaveToFile('/opt/artica/etc/dansguardian/dansguardianf' + IntToStr(folder_index)+ '.conf');
          l.Clear;
       end;

       tmpfile:=ldap.Load_Dansguardian_fileconfig(servername,IntToStr(folder_index),'ExceptionFileSiteListConf');
       logs.Debuglogs('DansGuardian:: ' + folder_name + '/exceptionfilesitelist (' + intToStr(length(tmpfile)) + ')');
       l.Add(tmpfile);
       l.SaveToFile(folder_name + '/exceptionfilesitelist');
       l.Clear;

       tmpfile:='';
       logs.Debuglogs('DansGuardian:: ' + folder_name + '/exceptionfileurllist (' + intToStr(length(tmpfile)) + ')');
       l.Add(tmpfile);
       l.SaveToFile(folder_name + '/exceptionfileurllist');
       l.Clear;
       
       tmpfile:=ldap.Load_Dansguardian_fileconfig(servername,IntToStr(folder_index),'ExceptionSiteListConf');
       logs.Debuglogs('DansGuardian:: ' + folder_name + '/exceptionsitelist (' + intToStr(length(tmpfile)) + ')');
       l.Add(tmpfile);
       l.SaveToFile(folder_name + '/exceptionsitelist');
       l.Clear;
       
       tmpfile:=ldap.Load_Dansguardian_fileconfig(servername,IntToStr(folder_index),'WeightedPhraseListConf');
       logs.Debuglogs('DansGuardian:: ' + folder_name + '/weightedphraselist (' + intToStr(length(tmpfile)) + ')');
       l.Add(tmpfile);
       l.SaveToFile(folder_name + '/weightedphraselist');
       l.Clear;
       
       tmpfile:=ldap.Load_Dansguardian_fileconfig(servername,IntToStr(folder_index),'BannedSiteListConf');
       logs.Debuglogs('DansGuardian:: ' + folder_name + '/bannedsitelist (' + intToStr(length(tmpfile)) + ')');
       l.Add(tmpfile);
       l.SaveToFile(folder_name + '/bannedsitelist');
       l.Clear;
       
       tmpfile:=ldap.Load_Dansguardian_fileconfig(servername,IntToStr(folder_index),'BannedRegexPurListConf');
       logs.Debuglogs('DansGuardian:: ' + folder_name + '/bannedregexpurllist (' + intToStr(length(tmpfile)) + ')');
       l.Add(tmpfile);
       l.SaveToFile(folder_name + '/bannedregexpurllist');
       l.Clear;
       
       tmpfile:=ldap.Load_Dansguardian_fileconfig(servername,IntToStr(folder_index),'BannedPhraseListConf');
       logs.Debuglogs('DansGuardian:: ' + folder_name + '/bannedphraselist (' + intToStr(length(tmpfile)) + ')');
       l.Add(tmpfile);
       l.SaveToFile(folder_name + '/bannedphraselist');
       l.Clear;
       
       tmpfile:=ldap.Load_Dansguardian_fileconfig(servername,IntToStr(folder_index),'BannedMimetypeConf');
       logs.Debuglogs('DansGuardian:: ' + folder_name + '/bannedmimetypelist (' + intToStr(length(tmpfile)) + ')');
       l.Add(tmpfile);
       l.SaveToFile(folder_name + '/bannedmimetypelist');
       l.Clear;
       
       tmpfile:=ldap.Load_Dansguardian_fileconfig(servername,IntToStr(folder_index),'bannedextensionlist');
       logs.Debuglogs('DansGuardian:: ' + folder_name + '/bannedextensionlist (' + intToStr(length(tmpfile)) + ')');
       l.Add(tmpfile);
       l.SaveToFile(folder_name + '/bannedextensionlist');
       l.Clear;
       
       DansGuardian_verif_groupfile('/opt/artica/etc/dansguardian/dansguardianf' + IntToStr(folder_index)+ '.conf');
  end;
  
         logs.Debuglogs('DansGuardian:: reload DansGuardian....');
         fpsystem('/opt/artica/sbin/dansguardian -r');
  
  
end;
 //#############################################################################
PROCEDURE tldapconf.DansGuardian_verif_groupfile(group_path:string);
var
D                    :boolean;
RegExpr              :TRegExpr;
l                    :TstringList;
i                    :integer;
filepath             :string;
begin
   D:=GLOBAL_INI.COMMANDLINE_PARAMETERS('--verbose');
   if not FileExists(group_path) then exit;
   l:=TstringList.Create;
   l.LoadFromFile(group_path);
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^([a-z0-9_\-]+)[\s='']+(.+?)''';
   
   
   for i:=0 to l.Count-1 do begin
       if RegExpr.Exec(l.Strings[i]) then begin
          filepath:=RegExpr.Match[2];
          if DirectoryExists(ExtractFilePath(filepath)) then begin
             if not FileExists(filepath) then begin
                 logs.Debuglogs('"' + filepath + '" not exists perhaps not supported yet..');
                 if FileExists('/opt/artica/etc/dansguardian/lists/' + ExtractFileName(filepath) )then begin
                       logs.Debuglogs('copy source file from "/opt/artica/etc/dansguardian/lists/' + ExtractFileName(filepath) + '"');
                       fpsystem('/bin/cp /opt/artica/etc/dansguardian/lists/' + ExtractFileName(filepath) + ' ' + filepath);
                 end else begin
                     fpsystem('/bin/touch ' + filepath);

                 end;
             end;
             
          end;
          
       end;
   end;
   

end;
 //#############################################################################
PROCEDURE tldapconf.DansGuardian_verif_globalConfig();
var
   tmpstr          :string;
   D               :boolean;
   maxsparechildren:string;
   minsparechildren:string;
   minchildren     :string;
begin
  D:=GLOBAL_INI.COMMANDLINE_PARAMETERS('--verbose');
  minchildren:=GLOBAL_INI.DANSGUARDIAN_CONFIG_VALUE('minchildren');
  minsparechildren:=GLOBAL_INI.DANSGUARDIAN_CONFIG_VALUE('minsparechildren');
  maxsparechildren:=GLOBAL_INI.DANSGUARDIAN_CONFIG_VALUE('maxsparechildren');
  
  
  logs.Debuglogs('minchildren=' + minchildren);
  logs.Debuglogs('maxsparechildren=' + maxsparechildren);


  if length(minchildren)=0 then begin
     GLOBAL_INI.DANSGUARDIAN_CONFIG_VALUE_SET('minchildren','8');
     minchildren:='8';
  end;
  
  if length(maxsparechildren)=0 then begin
     GLOBAL_INI.DANSGUARDIAN_CONFIG_VALUE_SET('maxsparechildren','32');
     maxsparechildren:='32';
  end;

  if length(minsparechildren)=0 then begin
     GLOBAL_INI.DANSGUARDIAN_CONFIG_VALUE_SET('minsparechildren','4');
     maxsparechildren:='4';
  end;
  
  if StrToInt(minchildren)=0 then begin
     GLOBAL_INI.DANSGUARDIAN_CONFIG_VALUE_SET('minchildren','8');
     minchildren:='8';
  end;

  if StrToInt(maxsparechildren)=0 then begin
     GLOBAL_INI.DANSGUARDIAN_CONFIG_VALUE_SET('maxsparechildren','32');
     maxsparechildren:='32';
  end;

  if StrToInt(minsparechildren)=0 then begin
     GLOBAL_INI.DANSGUARDIAN_CONFIG_VALUE_SET('minsparechildren','4');
     maxsparechildren:='4';
  end;

  if StrToInt(minsparechildren)>StrToInt(maxsparechildren) then begin
     GLOBAL_INI.DANSGUARDIAN_CONFIG_VALUE_SET('minsparechildren','4');
     minsparechildren:='4';
  end;

end;
 //#############################################################################

PROCEDURE tldapconf.Amavis();
var
   F:amavis_settings;
   l:TstringList;
   logs:Tlogs;
   GLOBAL_INI:myconf;
   mysql_port,mysql_bindaddr:string;
begin
     l:=TstringList.Create;
     f:=ldap.Load_amavis_main_settings();
     logs:=Tlogs.Create;
     GLOBAL_INI:=myconf.Create();
     
  mysql_port    :=GLOBAL_INI.MYSQL_SERVER_PARAMETERS_CF('port');
  mysql_bindaddr:=GLOBAL_INI.MYSQL_SERVER_PARAMETERS_CF('bind-address');

     
     
if length(f.FinalBadHeaderDestiny)=0 then f.FinalBadHeaderDestiny:='D_PASS';
if length(f.FinalBannedDestiny)=0 then f.FinalBannedDestiny:='D_BOUNCE';
if length(f.FinalSpamDestiny)=0 then f.FinalSpamDestiny:='D_BOUNCE';
if length(f.FinalVirusDestiny)=0 then f.FinalVirusDestiny:='D_BOUNCE';
      logs.logs('tldapconf.Amavis() ->FinalVirusDestiny=' +f.FinalVirusDestiny );
      logs.logs('tldapconf.Amavis() ->FinalSpamDestiny=' +f.FinalSpamDestiny );

l.Add('$MYHOME   = "/opt/artica/amavis";');
l.Add('$myhostname   = "127.0.0.1";');
l.Add('$enable_ldap  = 1;');
l.Add('');
l.Add('$default_ldap = {');
l.Add('  hostname      => [ "' + ldap.LDAPINFO.servername+'" ],');
l.Add('  timeout       => 5,');
l.Add('  tls           => 0,');
l.Add('  base          => "' + ldap.LDAPINFO.suffix+'",');
l.Add('  query_filter  => "(&(objectClass=amavisAccount)(mail=%m))",');
l.Add('};');
l.Add('');
l.Add('');
l.Add('$TEMPBASE = "$MYHOME/tmp";');
l.Add('$db_home  = "/opt/artica/amavis/db";');
l.Add('@inet_acl = qw(127/8);');
l.Add('$path = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/sbin:/usr/bin:/bin:/opt/artica/bin";');
l.Add('$unrar="/opt/artica/bin/unrar";');
l.Add('$doc="/opt/artica/bin/ripole";');
l.Add('$LOGFILE = "/opt/artica/logs/amavis/amavis.log";');
l.Add('$log_level = 10;');
l.Add('$MAXLEVELS = 14;');
l.Add('$MAXFILES = 1500;');
l.Add('$MIN_EXPANSION_QUOTA =      100*1024;');
l.Add('$MAX_EXPANSION_QUOTA = 300*1024*1024;');
l.Add('$MIN_EXPANSION_FACTOR =   5;');
l.Add('$MAX_EXPANSION_FACTOR = 500;');
l.Add('$enable_db = 1;');
l.Add('$enable_global_cache = 1;');
l.Add('$inet_socket_bind = "127.0.0.1";');
l.Add('$inet_socket_port =[9029,9028];');
l.Add('$interface_policy{"9029"} = "MX01";');
l.Add('$interface_policy{"9028"} = "AM.PDP";');

if FileExists('/opt/artica/sbin/p0f') then begin
   if FileExists('/opt/artica/bin/p0f-analyzer.pl') then begin
      logs.logs('tldapconf.Amavis() ->p0f enabled...' );
      l.Add('$os_fingerprint_method = ''p0f:127.0.0.1:2345'';');
      l.Add('$policy_bank{''MX01''}={forward_method => ''smtp:[127.0.0.1]:9030'',os_fingerprint_method => ''p0f:127.0.0.1:2345'',};');
      l.Add('$policy_bank{''AM.PDP''} = {protocol => ''AM.PDP'',inet_acl => [qw( 127.0.0.1 [::1])],};');
      l.Add('');
   end;
end;

if FileExists('/opt/artica/mysql/libexec/mysqld') then begin
    logs.logs('tldapconf.Amavis() ->Mysql enabled...' );
    l.Add('@storage_sql_dsn =( [''DBI:mysql:amavis;host=' +mysql_bindaddr + ';port=' + mysql_port + ''', ''root'', '''']);');
end;


l.Add('#$policy_bank{"BYPASS"} = { bypass_spam_checks_maps   => [1],  bypass_banned_checks_maps => [1],  bypass_header_checks_maps => [1]};');
l.Add('$notify_method = "smtp:[127.0.0.1]:9030";');
l.Add('$forward_method = "smtp:[127.0.0.1]:9030";');
l.Add('$insert_received_line = 1;');
l.Add('$QUARANTINEDIR = "/opt/artica/var/virusmail";');
l.Add('@mynetworks = qw( 127.0.0.0/8 ::1);');
l.Add('');
l.Add('@av_scanners = ([''ClamAV-clamd'',\&ask_daemon, ["CONTSCAN {}\n", "/opt/artica/clamav/clamd.socket"],qr/\bOK$/, qr/\bFOUND$/,qr/^.*?: (?!Infected Archive)(.*) FOUND$/ ]);');
l.Add('');
l.Add('$final_virus_destiny = ' + f.FinalVirusDestiny + ';');
l.Add('$final_banned_destiny = ' + f.FinalBannedDestiny + ';');
l.Add('$final_spam_destiny  = ' + f.FinalSpamDestiny + ';');
l.Add('');
l.Add('%final_destiny_by_ccat = (');
l.Add('  CC_VIRUS,      ' + f.FinalVirusDestiny + ',');
l.Add('  CC_BANNED,     ' + f.FinalBannedDestiny + ',');
l.Add('  CC_UNCHECKED,  D_PASS,');
l.Add('  CC_SPAM,       ' + f.FinalSpamDestiny + ',');
l.Add('  CC_BADH,       ' + f.FinalBadHeaderDestiny + ',');
l.Add('  CC_OVERSIZED,  D_BOUNCE,');
l.Add('  CC_CLEAN,      D_PASS,');
l.Add('  CC_CATCHALL,   D_PASS,');
l.Add(');');
l.Add('');
l.Add('');
l.Add('$bypass_virus_checks_ldap = {res_at => ''amavisBypassVirusChecks''};');
l.Add('$bypass_spam_checks_ldap = {res_at => ''amavisBypassSpamChecks''};');
l.Add('$sa_spam_modifies_subj_ldap = {res_at => ''amavisSpamModifiesSubj''};');
l.Add('$spam_tag_level_ldap = {res_at => ''amavisSpamTagLevel''};');
l.Add('$spam_tag2_level_ldap = {res_at => ''amavisSpamTag2Level''};');
l.Add('$spam_kill_level_ldap = {res_at => ''amavisSpamKillLevel''};');
l.Add('');
l.Add('');
l.Add('#notify virus sender');
l.Add('$warnvirussender                = 0;');
l.Add('');
l.Add('#notify spam sender');
l.Add('$warnspamsender                 = 0;');
l.Add('');
l.Add('#notify banned attached file sender');
l.Add('$warnbannedsender               = 0;');
l.Add('');
l.Add('#Notify recepient virus');
l.Add('$warnvirusrecip                 = 1;');
l.Add('');
l.Add('#Notify banned file recipient');
l.Add('$warnbannedrecip                = 1;');
l.Add('');
l.Add('$virus_quarantine_method        = "sql:";');
l.Add('$banned_files_quarantine_method = "local:banned-%i-%n.gz";');
l.Add('$bad_header_quarantine_method   = undef;');
l.Add('$spam_quarantine_method         = undef;');
l.Add('$clean_quarantine_method        = undef;');
l.Add('$archive_quarantine_method      = undef;');
l.Add('');
l.Add('$virus_quarantine_to            = undef;');
l.Add('$banned_quarantine_to           = "banned-quarantine";');
l.Add('$bad_header_quarantine_to       = undef;');
l.Add('$spam_quarantine_to             = undef;');
l.Add('$spam_quarantine_bysender_to    = undef;');
l.Add('$clean_quarantine_to            = undef;');
l.Add('$archive_quarantine_to          = undef;');
l.Add('');
l.Add('$X_HEADER_TAG                   = "X-Virus-Scanned";');
l.Add('$X_HEADER_LINE                  = "by amavis";');
l.Add('');
l.Add('$sa_local_tests_only            = 0;');
l.Add('$sa_timeout                     = 60;');
l.Add('');
l.Add('');
l.Add('1;');

forcedirectories('/opt/artica/etc/amavis');
l.SaveToFile('/opt/artica/etc/amavis/amavisd.conf');
l.free;
ZuluConfig();
end;

procedure tldapconf.ZuluConfig();
var
   mysql_port      :string;
   mysql_bindaddr  :string;
   artica_path     :string;
   mailtmp         :string;
   l               :TstringList;
   F               :amavis_settings;
   QuarantineMailZuAdmin:string;
   QuarantineMailZuAdminE:string;
   i               :integer;
begin
  f:=ldap.Load_amavis_main_settings();
  mysql_port    :=GLOBAL_INI.MYSQL_SERVER_PARAMETERS_CF('port');
  mysql_bindaddr:=GLOBAL_INI.MYSQL_SERVER_PARAMETERS_CF('bind-address');
  artica_path:=GLOBAL_INI.get_ARTICA_PHP_PATH();
l:=TstringList.Create;
l.Add('<?php');
l.Add('$conf["amavisd"]["spam_release_port"] = "9028";');
l.Add('$conf["db"]["dbType"] = "mysql";');
l.Add('$conf["db"]["dbUser"] = "root";');
l.Add('$conf["db"]["dbPass"] = "";');
l.Add('$conf["db"]["dbName"] = "amavis";');
l.Add('$conf["db"]["hostSpec"] = "' + mysql_bindaddr + ':' + mysql_port + '";');
l.Add('$conf["db"]["binquar"] = True;');
l.Add('');
l.Add('$conf["auth"]["serverType"] = "ldap";');
l.Add('$conf["auth"]["ldap_hosts"] = array( "127.0.0.1" );');
l.Add('$conf["auth"]["ldap_ssl"] = false;');
l.Add('$conf["auth"]["ldap_basedn"] = "' + ldap.LDAPINFO.suffix + '";');
l.Add('$conf["auth"]["ldap_user_identifier"] = "uid";');
l.Add('$conf["auth"]["ldap_user_container"] = "";');
l.Add('$conf["auth"]["ldap_login"] = "uid";');
l.Add('$conf["auth"]["ldap_mailAttr"] = array("mail","mailAlias");');
l.Add('$conf["auth"]["ldap_searchUsername"] = "' + ldap.LDAPINFO.admin + '";');
l.Add('$conf["auth"]["ldap_searchPassword"] = "'+ ldap.LDAPINFO.password +'";');
l.Add('$conf["auth"]["ldap_name"] = "givenName";');

for i:=0 to F.QuarantineMailZuAdmin.Count-1 do begin
     QuarantineMailZuAdmin:=QuarantineMailZuAdmin + '"' + F.QuarantineMailZuAdmin.Strings[i] + '",';
     mailtmp:=ldap.EmailFromUID(F.QuarantineMailZuAdmin.Strings[i]);
     if length(mailtmp)>0 then begin
        QuarantineMailZuAdminE:=QuarantineMailZuAdminE + '"' + mailtmp + '",';
     end;
end;
  QuarantineMailZuAdmin:=Copy(QuarantineMailZuAdmin,0,length(QuarantineMailZuAdmin)-1);
  QuarantineMailZuAdminE:=Copy(QuarantineMailZuAdminE,0,length(QuarantineMailZuAdminE)-1);


l.Add('$conf["auth"]["s_admins"] = array (' + QuarantineMailZuAdmin + ');');
l.Add('$conf["auth"]["m_admins"] = array (' + QuarantineMailZuAdmin + ');');
l.Add('$conf["auth"]["login_restriction"] = false;');
l.Add('$conf["auth"]["restricted_users"] = array();');

l.Add('$conf["ui"]["logoImage"] = "img/mailzu.gif";');
l.Add('$conf["ui"]["welcome"] = "Welcome to MailZu! for Artica";');
l.Add('$conf["app"]["weburi"] = "https://" .$_SERVER["SERVER_ADDR"] .":".$_SERVER["SERVER_PORT"] . "/quarantine";');
l.Add('$conf["app"]["emailType"] = "mail";');

l.Add('$conf["app"]["smtpHost"] = "";');
l.Add('$conf["app"]["smtpPort"] = 25;');
l.Add('$conf["app"]["sendmailPath"] = "/usr/sbin/sendmail";');
l.Add('$conf["app"]["qmailPath"] = "/var/qmail/bin/sendmail";');
l.Add('$conf["recipient_delimiter"] = "";');
l.Add('$conf["app"]["adminEmail"] = array(' + QuarantineMailZuAdminE + ');');
l.Add('$conf["app"]["notifyAdmin"] = 0;');
l.Add('$conf["app"]["showEmailAdmin"] = 1;');
l.Add('$conf["app"]["siteSummary"] = 1;');
l.Add('$conf["app"]["searchOnly"] = 1;');
l.Add('$conf["app"]["defaultLanguage"] = "en_US";');
l.Add('$conf["app"]["selectLanguage"] = "1";');
l.Add('$conf["app"]["safeMode"] = 0;');
l.Add('$conf["app"]["timeFormat"] = 24;');
l.Add('$conf["app"]["title"] = "MailZu for Artica";');
l.Add('$conf["app"]["use_log"] = 1;');
l.Add('$conf["app"]["debug"] = 0;');
l.Add('$conf["app"]["logfile"] = "' + artica_path  + '/ressources/logs/mailzu.log";');
l.Add('$conf["app"]["displaySizeLimit"] = 50;');
l.Add('$conf["app"]["allowBadHeaders"] = 1;');
l.Add('$conf["app"]["allowViruses"] = 1;');
l.Add('$conf["app"]["allowMailid"] = 1;');
l.Add('include_once("init.php");');
l.Add('?>');
if directoryexists(artica_path  + '/quarantine') then begin
   forcedirectories(artica_path + '/quarantine/config');
   l.SaveToFile(artica_path + '/quarantine/config/config.php');
end;


end;



end.
