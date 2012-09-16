unit setup_joomla;
{$MODE DELPHI}
//{$mode objfpc}{$H+}
{$LONGSTRINGS ON}
//ln -s /usr/lib/libmilter/libsmutil.a /usr/local/lib/libsmutil.a
//apt-get install libmilter-dev
interface

uses
  Classes, SysUtils,strutils,RegExpr in 'RegExpr.pas',
  unix,IniFiles,setup_libs,distridetect,zsystem,logs,
  install_generic;

  type
  tsetup_joomla=class


private
     libs:tlibs;
     distri:tdistriDetect;
     install:tinstall;
     source_folder,cmd:string;
     SYS:Tsystem;
     myparmas:string;
     logs:tlogs;
     function CheckCorrupt():boolean;

     procedure OrgInstall(org:string);
     function  CheckCorruptOrg(org:string):boolean;
     function  CheckDatabase(database:string):boolean;
     procedure eyeOS_Systems();

     function  SugarCheckCorrupt():boolean;
     function  SugarCheckCorruptOrg(org:string):boolean;
     procedure OrgSugarInstall(org:string);
     function  SugarCheckDatabase(database:string):boolean;


public
      constructor Create();
      procedure Free;
      procedure xinstall();
      procedure SugarCRM_INSTALL();
      procedure piwigo_install();
      procedure eyeOS_install();
      procedure xinstall17();
      procedure xinstall_wordpress();
      procedure concrete5();
      procedure artica_agent();
      procedure APP_SQUID32_REPOS();
      procedure APP_SQUID32_PURGE();
      procedure Ownloud_install();
END;

implementation

constructor tsetup_joomla.Create();
var i:integer;
begin
libs:=tlibs.Create;
install:=tinstall.Create;
source_folder:='';
SYS:=Tsystem.Create();
logs:=tlogs.Create;
if DirectoryExists(ParamStr(2)) then source_folder:=ParamStr(2);


 if ParamCount>0 then begin
     for i:=1 to ParamCount do begin
        myparmas:=myparmas  + ' ' +ParamStr(i);

     end;
     myparmas:=trim(myparmas);
 end;


end;
//#########################################################################################
procedure tsetup_joomla.Free();
begin
  libs.Free;

end;
//#########################################################################################
procedure tsetup_joomla.OrgInstall(org:string);
var
   database:string;
begin

org:=AnsiReplaceText(org,'.','_');
org:=AnsiReplaceText(org,'-','_');
database:='joomla_'+org;

if not CheckCorrupt() then begin
     writeln('Corrupted repository folder.. Unable to install joomla main program');
     exit;
end;

  if not FileExists('/usr/share/artica-postfix/bin/install/joomla/joomla.sql') then begin
     writeln('Unable to stat /usr/share/artica-postfix/bin/install/joomla/joomla.sql');
     exit;
  end;


  if not logs.IF_DATABASE_EXISTS(database) then begin
     writeln('Creating new database "'+database+'"');
     logs.EXECUTE_SQL_FILE('/usr/share/artica-postfix/bin/install/joomla/joomla.sql',database);
     if not CheckDatabase(database) then exit;
  end;

     if not CheckDatabase(database) then exit;

     ForceDirectories('/usr/share/artica-groupware/domains/joomla/'+org);

     if not CheckCorruptOrg(org) then begin
        fpsystem('/bin/cp -rf /usr/local/share/artica/joomla_src/* /usr/share/artica-groupware/domains/joomla/'+org+'/');
     end;

     writeln('done...');



end;
//#########################################################################################
procedure tsetup_joomla.xinstall();
var
   CODE_NAME:string;
   cmd:string;
   RegExpr:TRegExpr;
begin

    CODE_NAME:='APP_JOOMLA';
    SetCurrentDir('/root');

    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='org=(.+?)\s+';
    if RegExpr.Exec(myparmas) then begin
       writeln('Creating new joomla web site for organization: '+RegExpr.Match[1]);
       OrgInstall(RegExpr.Match[1]);
       exit;
    end;


  install.INSTALL_STATUS(CODE_NAME,10);
  install.INSTALL_STATUS(CODE_NAME,30);

  if not FileExists(SYS.LOCATE_APACHE_BIN_PATH()) then begin
     writeln('Install '+CODE_NAME+' failed...');
     install.INSTALL_PROGRESS(CODE_NAME,'{failed} (apache)');
     install.INSTALL_STATUS(CODE_NAME,110);
     exit;
  end;

  if not FileExists(SYS.LOCATE_PHP5_BIN()) then begin
     writeln('Install '+CODE_NAME+' failed...');
     install.INSTALL_PROGRESS(CODE_NAME,'{failed} (php)');
     install.INSTALL_STATUS(CODE_NAME,110);
     exit;
  end;

  if directoryExists('/usr/local/share/artica/joomla_src') then begin
            If not CheckCorrupt() then begin
               fpsystem('/bin/rm -rf /usr/local/share/artica/joomla_src');
            end;
  end;



  if not directoryExists('/usr/local/share/artica/joomla_src') then begin
     install.INSTALL_PROGRESS(CODE_NAME,'{downloading}');
     if length(source_folder)=0 then source_folder:=libs.COMPILE_GENERIC_APPS('joomla');
     if not DirectoryExists(source_folder) then begin
        writeln('Install '+CODE_NAME+' failed...');
        install.INSTALL_STATUS(CODE_NAME,110);
        exit;
     end;

     writeln('Install '+CODE_NAME+' extracted on "'+source_folder+'"');
     install.INSTALL_STATUS(CODE_NAME,50);
     install.INSTALL_PROGRESS(CODE_NAME,'{installing}');

     forceDirectories('/usr/local/share/artica/joomla_src');
     cmd:='/bin/cp -rf ' + source_folder+'/* /usr/local/share/artica/joomla_src/';
     fpsystem(cmd);
     install.INSTALL_PROGRESS(CODE_NAME,'{checking}');
     if not CheckCorrupt() then begin
         writeln('Install '+CODE_NAME+' failed...');
        install.INSTALL_STATUS(CODE_NAME,110);
        exit;
     end else begin
         writeln('Install '+CODE_NAME+' success...');
        install.INSTALL_STATUS(CODE_NAME,100);
        install.INSTALL_PROGRESS(CODE_NAME,'{installed}');
        exit;
     end;

end;





end;
//#########################################################################################
procedure tsetup_joomla.xinstall17();
var
   CODE_NAME:string;
   cmd:string;
   RegExpr:TRegExpr;
begin

    CODE_NAME:='APP_JOOMLA17';
    SetCurrentDir('/root');

   install.INSTALL_STATUS(CODE_NAME,10);
  install.INSTALL_STATUS(CODE_NAME,30);

  if not FileExists(SYS.LOCATE_APACHE_BIN_PATH()) then begin
     writeln('Install '+CODE_NAME+' failed...');
     install.INSTALL_PROGRESS(CODE_NAME,'{failed} (apache)');
     install.INSTALL_STATUS(CODE_NAME,110);
     exit;
  end;

  if not FileExists(SYS.LOCATE_PHP5_BIN()) then begin
     writeln('Install '+CODE_NAME+' failed...');
     install.INSTALL_PROGRESS(CODE_NAME,'{failed} (php)');
     install.INSTALL_STATUS(CODE_NAME,110);
     exit;
  end;

  if directoryExists('/usr/local/share/artica/joomla17_src') then begin
     fpsystem('/bin/rm -rf /usr/local/share/artica/joomla17_src');
  end;



 install.INSTALL_PROGRESS(CODE_NAME,'{downloading}');
 if length(source_folder)=0 then source_folder:=libs.COMPILE_GENERIC_APPS('joomla17');
    if not DirectoryExists(source_folder) then begin
        writeln('Install '+CODE_NAME+' failed...');
        install.INSTALL_STATUS(CODE_NAME,110);
        exit;
     end;

     writeln('Install '+CODE_NAME+' extracted on "'+source_folder+'"');
     install.INSTALL_STATUS(CODE_NAME,50);
     install.INSTALL_PROGRESS(CODE_NAME,'{installing}');

     forceDirectories('/usr/local/share/artica/joomla17_src');
     cmd:='/bin/cp -rf ' + source_folder+'/* /usr/local/share/artica/joomla17_src/';
     fpsystem(cmd);
     install.INSTALL_PROGRESS(CODE_NAME,'{checking}');
     if not fileExists('/usr/local/share/artica/joomla17_src/index.php') then begin
         writeln('Install '+CODE_NAME+' failed...');
        install.INSTALL_STATUS(CODE_NAME,110);
        exit;
     end else begin
         writeln('Install '+CODE_NAME+' success...');
        install.INSTALL_STATUS(CODE_NAME,100);
        install.INSTALL_PROGRESS(CODE_NAME,'{installed}');
        exit;
     end;

end;
//#########################################################################################
procedure tsetup_joomla.concrete5();
var
   CODE_NAME:string;
   cmd:string;
   RegExpr:TRegExpr;
begin

    CODE_NAME:='APP_CONCRETE5';
    SetCurrentDir('/root');

   install.INSTALL_STATUS(CODE_NAME,10);
  install.INSTALL_STATUS(CODE_NAME,30);

  if not FileExists(SYS.LOCATE_APACHE_BIN_PATH()) then begin
     writeln('Install '+CODE_NAME+' failed...');
     install.INSTALL_PROGRESS(CODE_NAME,'{failed} (apache)');
     install.INSTALL_STATUS(CODE_NAME,110);
     exit;
  end;

  if not FileExists(SYS.LOCATE_PHP5_BIN()) then begin
     writeln('Install '+CODE_NAME+' failed...');
     install.INSTALL_PROGRESS(CODE_NAME,'{failed} (php)');
     install.INSTALL_STATUS(CODE_NAME,110);
     exit;
  end;

  if directoryExists('/usr/share/concrete5') then begin
     fpsystem('/bin/rm -rf /usr/share/concrete5');
  end;



 install.INSTALL_PROGRESS(CODE_NAME,'{downloading}');
 if length(source_folder)=0 then source_folder:=libs.COMPILE_GENERIC_APPS('concrete5');
    if not DirectoryExists(source_folder) then begin
        writeln('Install '+CODE_NAME+' failed...');
        install.INSTALL_STATUS(CODE_NAME,110);
        exit;
     end;

     writeln('Install '+CODE_NAME+' extracted on "'+source_folder+'"');
     install.INSTALL_STATUS(CODE_NAME,50);
     install.INSTALL_PROGRESS(CODE_NAME,'{installing}');

     forceDirectories('/usr/share/concrete5');
     cmd:='/bin/cp -rf ' + source_folder+'/* /usr/share/concrete5/';
     fpsystem(cmd);
     install.INSTALL_PROGRESS(CODE_NAME,'{checking}');
     if not fileExists('/usr/share/concrete5/index.php') then begin
         writeln('Install '+CODE_NAME+' failed...');
        install.INSTALL_STATUS(CODE_NAME,110);
        exit;
     end else begin
         writeln('Install '+CODE_NAME+' success...');
        install.INSTALL_STATUS(CODE_NAME,100);
        install.INSTALL_PROGRESS(CODE_NAME,'{installed}');
        exit;
     end;

end;
//#########################################################################################
procedure tsetup_joomla.artica_agent();
var
   CODE_NAME:string;
   cmd:string;
   RegExpr:TRegExpr;
begin

    CODE_NAME:='APP_ARTICA_AGENT';
    SetCurrentDir('/root');

  install.INSTALL_STATUS(CODE_NAME,10);
  install.INSTALL_STATUS(CODE_NAME,30);

 install.INSTALL_PROGRESS(CODE_NAME,'{downloading}');
 if length(source_folder)=0 then source_folder:=libs.COMPILE_GENERIC_APPS('artica-agent',true);
 writeln('source_folder:',source_folder);
 ForceDirectories('/usr/share/artica-postfix/ressources/artica-agent');
 fpsystem('/bin/chmod 755 /usr/share/artica-postfix/ressources/artica-agent');
 fpsystem('/bin/cp -f '+source_folder+' /usr/share/artica-postfix/ressources/artica-agent/');
 install.INSTALL_STATUS(CODE_NAME,100);
 install.INSTALL_PROGRESS(CODE_NAME,'{installed}');

end;
//#########################################################################################
procedure tsetup_joomla.APP_SQUID32_REPOS();
var
   CODE_NAME:string;
   cmd:string;
   RegExpr:TRegExpr;
begin

  CODE_NAME:='APP_SQUID32_REPOS';
  SetCurrentDir('/root');
  install.INSTALL_STATUS(CODE_NAME,10);
  install.INSTALL_STATUS(CODE_NAME,30);
  install.INSTALL_PROGRESS(CODE_NAME,'{downloading}');
 ForceDirectories('/usr/share/artica-postfix/ressources/artica-agent');
 fpsystem('/bin/chmod 755 /usr/share/artica-postfix/ressources/artica-agent');
 source_folder:=libs.COMPILE_GENERIC_APPS('squid32-i386',true);
 fpsystem('/bin/cp -f '+source_folder+' /usr/share/artica-postfix/ressources/artica-agent/');
 source_folder:=libs.COMPILE_GENERIC_APPS('squid32-x64',true);
 fpsystem('/bin/cp -f '+source_folder+' /usr/share/artica-postfix/ressources/artica-agent/');
end;
//#########################################################################################
procedure tsetup_joomla.APP_SQUID32_PURGE();
var
   CODE_NAME:string;
   cmd:string;
   RegExpr:TRegExpr;
begin

  CODE_NAME:='APP_SQUID32_PURGE';
  if not FileExists('/usr/share/artica-postfix/bin/install/purge-1.17.tar.gz') then begin
     writeln('/usr/share/artica-postfix/bin/install/purge-1.17.tar.gz no such file');
         exit;
  end;

  install.INSTALL_STATUS(CODE_NAME,10);
  install.INSTALL_STATUS(CODE_NAME,30);
  install.INSTALL_PROGRESS(CODE_NAME,'{downloading}');
 ForceDirectories('/root/purge');
 fpsystem(SYS.LOCATE_GENERIC_BIN('tar')+' -xf /usr/share/artica-postfix/bin/install/purge-1.17.tar.gz -C /root/purge/');
 if not FileExists('/root/purge/Makefile') then begin
    writeln('/root/purge/Makefile no such file');
    fpsystem('/bin/rm -rf /root/purge');
    exit;
 end;
 SetCurrentDir('/root/purge');
 fpsystem('make');
 if not FileExists('/root/purge/purge') then begin
    writeln('/root/purge/purge no such file');
    fpsystem('/bin/rm -rf /root/purge');
    exit;
 end;

 fpsystem('/bin/cp /root/purge/purge /usr/sbin/purge');
 fpsystem('/bin/chmod 755 /usr/sbin/purge');
 writeln('success');
 fpsystem('/bin/rm -rf /root/purge');

end;
//#########################################################################################
procedure tsetup_joomla.piwigo_install();
var
   CODE_NAME:string;
   cmd:string;
   RegExpr:TRegExpr;
   DirectoryDest:string;
begin

    CODE_NAME:='APP_PIWIGO';
    SetCurrentDir('/root');




  install.INSTALL_STATUS(CODE_NAME,10);
  install.INSTALL_STATUS(CODE_NAME,30);

  if not FileExists(SYS.LOCATE_APACHE_BIN_PATH()) then begin
     writeln('Install '+CODE_NAME+' failed...');
     install.INSTALL_PROGRESS(CODE_NAME,'{failed} (apache)');
     install.INSTALL_STATUS(CODE_NAME,110);
     exit;
  end;

  if not FileExists(SYS.LOCATE_PHP5_BIN()) then begin
     writeln('Install '+CODE_NAME+' failed...');
     install.INSTALL_PROGRESS(CODE_NAME,'{failed} (php)');
     install.INSTALL_STATUS(CODE_NAME,110);
     exit;
  end;

  if directoryExists('/usr/local/share/artica/piwigo_src') then begin
            If not CheckCorrupt() then begin
               fpsystem('/bin/rm -rf /usr/local/share/artica/piwigo_src');
            end;
  end;



  if not directoryExists('/usr/local/share/artica/piwigo_src') then begin
     install.INSTALL_PROGRESS(CODE_NAME,'{downloading}');
     if length(source_folder)=0 then source_folder:=libs.COMPILE_GENERIC_APPS('piwigo');
     if not DirectoryExists(source_folder) then begin
        writeln('Install '+CODE_NAME+' failed...');
        install.INSTALL_STATUS(CODE_NAME,110);
        exit;
     end;

     writeln('Install '+CODE_NAME+' extracted on "'+source_folder+'"');
     install.INSTALL_STATUS(CODE_NAME,50);
     install.INSTALL_PROGRESS(CODE_NAME,'{installing}');

     forceDirectories('/usr/local/share/artica/piwigo_src');
     cmd:='/bin/cp -rf ' + source_folder+'/* /usr/local/share/artica/piwigo_src/';
     fpsystem(cmd);
     install.INSTALL_PROGRESS(CODE_NAME,'{checking}');
     if not FileExists('/usr/local/share/artica/piwigo_src/include/constants.php') then begin
         writeln('Install '+CODE_NAME+' failed...');
        install.INSTALL_STATUS(CODE_NAME,110);
        exit;
     end else begin
         writeln('Install '+CODE_NAME+' success...');
        install.INSTALL_STATUS(CODE_NAME,100);
        install.INSTALL_PROGRESS(CODE_NAME,'{installed}');
        exit;
     end;


     writeln('Install '+CODE_NAME+' extracted on "'+source_folder+'"');
     install.INSTALL_STATUS(CODE_NAME,50);
     install.INSTALL_PROGRESS(CODE_NAME,'{installing}');

end;

     forceDirectories(DirectoryDest);
     cmd:='/bin/cp -rf ' + source_folder+'/* '+DirectoryDest+'/';
     writeln(cmd);
     fpsystem(cmd);
     install.INSTALL_PROGRESS(CODE_NAME,'{checking}');
     if not FileExists(DirectoryDest+'/index.php') then begin
         writeln('Install '+CODE_NAME+' failed...');
        install.INSTALL_STATUS(CODE_NAME,110);
        exit;
     end else begin
         writeln('Install '+CODE_NAME+' success...');
        install.INSTALL_STATUS(CODE_NAME,100);
        install.INSTALL_PROGRESS(CODE_NAME,'{installed}');
        exit;
     end;



end;
//#########################################################################################

procedure tsetup_joomla.Ownloud_install();
var
   CODE_NAME:string;
   cmd:string;
   RegExpr:TRegExpr;
   DirectoryDest:string;
begin
    CODE_NAME:='APP_OWNCKOUD';
    DirectoryDest:='/usr/local/share/artica/owncloud_src';
    SetCurrentDir('/root');
    install.INSTALL_STATUS(CODE_NAME,10);
    install.INSTALL_STATUS(CODE_NAME,30);


  if not FileExists(SYS.LOCATE_APACHE_BIN_PATH()) then begin
     writeln('Install '+CODE_NAME+' failed...');
     install.INSTALL_PROGRESS(CODE_NAME,'{failed} (apache)');
     install.INSTALL_STATUS(CODE_NAME,110);
     exit;
  end;

  if not FileExists(SYS.LOCATE_PHP5_BIN()) then begin
     writeln('Install '+CODE_NAME+' failed...');
     install.INSTALL_PROGRESS(CODE_NAME,'{failed} (php)');
     install.INSTALL_STATUS(CODE_NAME,110);
     exit;
  end;

     install.INSTALL_PROGRESS(CODE_NAME,'{downloading}');
     if length(source_folder)=0 then source_folder:=libs.COMPILE_GENERIC_APPS('owncloud');
     if not DirectoryExists(source_folder) then begin
        writeln('Install '+CODE_NAME+' failed...');
        install.INSTALL_STATUS(CODE_NAME,110);
        exit;
     end;

     if DirectoryExists(DirectoryDest) then fpsystem('/bin/rm -rf '+DirectoryDest);
     forceDirectories(DirectoryDest);
     cmd:='/bin/cp -rf ' + source_folder+'/* '+DirectoryDest+'/';
     writeln(cmd);
     fpsystem(cmd);
     install.INSTALL_PROGRESS(CODE_NAME,'{checking}');
     if not FileExists(DirectoryDest+'/index.php') then begin
         writeln('Install '+CODE_NAME+' failed...');
        install.INSTALL_STATUS(CODE_NAME,110);
        exit;
     end else begin
         writeln('Install '+CODE_NAME+' success...');
        install.INSTALL_STATUS(CODE_NAME,100);
        install.INSTALL_PROGRESS(CODE_NAME,'{installed}');
        exit;
     end;

end;

procedure tsetup_joomla.xinstall_wordpress();
var
   CODE_NAME:string;
   cmd:string;
   RegExpr:TRegExpr;
   DirectoryDest:string;
begin

    CODE_NAME:='APP_WORDPRESS';
    DirectoryDest:='/usr/local/share/artica/wordpress_src';
    SetCurrentDir('/root');
    ForceDirectories(DirectoryDest);



  install.INSTALL_STATUS(CODE_NAME,10);
  install.INSTALL_STATUS(CODE_NAME,30);

  if not FileExists(SYS.LOCATE_APACHE_BIN_PATH()) then begin
     writeln('Install '+CODE_NAME+' failed...');
     install.INSTALL_PROGRESS(CODE_NAME,'{failed} (apache)');
     install.INSTALL_STATUS(CODE_NAME,110);
     exit;
  end;

  if not FileExists(SYS.LOCATE_PHP5_BIN()) then begin
     writeln('Install '+CODE_NAME+' failed...');
     install.INSTALL_PROGRESS(CODE_NAME,'{failed} (php)');
     install.INSTALL_STATUS(CODE_NAME,110);
     exit;
  end;



     install.INSTALL_PROGRESS(CODE_NAME,'{downloading}');
     if length(source_folder)=0 then source_folder:=libs.COMPILE_GENERIC_APPS('wordpress');
     if not DirectoryExists(source_folder) then begin
        writeln('Install '+CODE_NAME+' failed...');
        install.INSTALL_STATUS(CODE_NAME,110);
        exit;
     end;


     writeln('Install '+CODE_NAME+' extracted on "'+source_folder+'"');
     install.INSTALL_STATUS(CODE_NAME,50);
     install.INSTALL_PROGRESS(CODE_NAME,'{installing}');

     forceDirectories(DirectoryDest);
     cmd:='/bin/cp -rf ' + source_folder+'/* '+DirectoryDest+'/';
     fpsystem(cmd);
     install.INSTALL_PROGRESS(CODE_NAME,'{checking}');
     if not FileExists(DirectoryDest+'/index.php') then begin
         writeln('Install '+CODE_NAME+' failed...');
        install.INSTALL_STATUS(CODE_NAME,110);
        exit;
     end else begin
         writeln('Install '+CODE_NAME+' success...');
        install.INSTALL_STATUS(CODE_NAME,100);
        install.INSTALL_PROGRESS(CODE_NAME,'{installed}');
        exit;
     end;

end;
//#########################################################################################
function tsetup_joomla.CheckDatabase(database:string):boolean;
var
l:Tstringlist;
i:integer;
begin
result:=true;
l:=Tstringlist.Create;
l.add('jos_banner');
l.add('jos_bannerclient');
l.add('jos_bannertrack');
l.add('jos_categories');
l.add('jos_components');
l.add('jos_contact_details');
l.add('jos_content');
l.add('jos_content_frontpage');
l.add('jos_content_rating');
l.add('jos_core_acl_aro');
l.add('jos_core_acl_aro_groups');
l.add('jos_core_acl_aro_map');
l.add('jos_core_acl_aro_sections');
l.add('jos_core_acl_groups_aro_map');
l.add('jos_core_log_items');
l.add('jos_core_log_searches');
l.add('jos_groups');
l.add('jos_menu');
l.add('jos_menu_types');
l.add('jos_messages');
l.add('jos_messages_cfg');
l.add('jos_migration_backlinks');
l.add('jos_modules');
l.add('jos_modules_menu');
l.add('jos_newsfeeds');
l.add('jos_plugins');
l.add('jos_polls');
l.add('jos_poll_data');
l.add('jos_poll_date');
l.add('jos_poll_menu');
l.add('jos_sections');
l.add('jos_session');
l.add('jos_stats_agents');
l.add('jos_templates_menu');
l.add('jos_users');
l.add('jos_weblinks');

for i:=0 to l.Count-1 do begin
    if not logs.IF_TABLE_EXISTS(l.Strings[i],database) then begin
       writeln('unable to stat table "'+l.Strings[i]+'" in database ' +database);
       l.free;
       exit(false);
    end;

end;

exit(true);


end;
//#########################################################################################
function tsetup_joomla.SugarCheckDatabase(database:string):boolean;
var
l:Tstringlist;
i:integer;
begin
result:=true;
l:=Tstringlist.Create;
l.add('accounts');
l.add('accounts_audit');
l.add('accounts_bugs');
l.add('accounts_cases');
l.add('accounts_contacts');
l.add('accounts_opportunities');
l.add('acl_actions');
l.add('acl_roles');
l.add('acl_roles_actions');
l.add('acl_roles_users');
l.add('address_book');
l.add('bugs');
l.add('bugs_audit');
l.add('calls');
l.add('calls_contacts');
l.add('calls_leads');
l.add('calls_users');
l.add('campaign_log');
l.add('campaign_trkrs');
l.add('campaigns');
l.add('campaigns_audit');
l.add('cases');
l.add('cases_audit');
l.add('cases_bugs');
l.add('config');
l.add('contacts');
l.add('contacts_audit');
l.add('contacts_bugs');
l.add('contacts_cases');
l.add('contacts_users');
l.add('currencies');
l.add('custom_fields');
l.add('dashboards');
l.add('document_revisions');
l.add('documents');
l.add('email_addr_bean_rel');
l.add('email_addresses');
l.add('email_cache');
l.add('email_marketing');
l.add('email_marketing_prospect_lists');
l.add('email_templates');
l.add('emailman');
l.add('emails');
l.add('emails_beans');
l.add('emails_email_addr_rel');
l.add('emails_text');
l.add('feeds');
l.add('fields_meta_data');
l.add('folders');
l.add('folders_rel');
l.add('folders_subscriptions');
l.add('iframes');
l.add('import_maps');
l.add('inbound_email');
l.add('inbound_email_autoreply');
l.add('inbound_email_cache_ts');
l.add('leads');
l.add('leads_audit');
l.add('linked_documents');
l.add('meetings');
l.add('meetings_contacts');
l.add('meetings_leads');
l.add('meetings_users');
l.add('notes');
l.add('opportunities');
l.add('opportunities_audit');
l.add('opportunities_contacts');
l.add('outbound_email');
l.add('project');
l.add('project_task');
l.add('project_task_audit');
l.add('projects_accounts');
l.add('projects_bugs');
l.add('projects_cases');
l.add('projects_contacts');
l.add('projects_opportunities');
l.add('projects_products');
l.add('prospect_list_campaigns');
l.add('prospect_lists');
l.add('prospect_lists_prospects');
l.add('prospects');
l.add('relationships');
l.add('releases');
l.add('roles');
l.add('roles_modules');
l.add('roles_users');
l.add('saved_search');
l.add('schedulers');
l.add('schedulers_times');
l.add('sugarfeed');
l.add('tasks');
l.add('tracker');
l.add('upgrade_history');
l.add('user_preferences');
l.add('users');
l.add('users_feeds');
l.add('users_last_import');
l.add('users_signatures');
l.add('vcals');
l.add('versions');

for i:=0 to l.Count-1 do begin
    if not logs.IF_TABLE_EXISTS(l.Strings[i],database) then begin
       writeln('SugarCheckDatabase:: unable to stat table "'+l.Strings[i]+'" in database ' +database);
       l.free;
       exit(false);
    end;

end;

exit(true);


end;
//#########################################################################################


function tsetup_joomla.SugarCheckCorrupt():boolean;
var
   l:Tstringlist;
   i:Integer;
   files:string;
begin
    result:=true;
    files:='/usr/share/artica-postfix/bin/install/SugarCRM/files.txt';
     if not FileExists(files) then begin
        writeln('Unable to stat '+files);
        exit;
     end;
     l:=TstringList.Create;
     l.LoadFromFile(files);
     for i:=0 to l.Count-1 do begin

         if not FileExists('/usr/local/share/artica/sugarcrm_src/'+l.Strings[i]) then begin
            writeln('Unable to stat /usr/local/share/artica/sugarcrm_src/'+l.Strings[i]+' installation corrupted');
            result:=false;
         end;

     end;
end;
//#########################################################################################

function tsetup_joomla.CheckCorrupt():boolean;
var
   l:Tstringlist;
   i:Integer;
begin
    result:=false;

     if not FileExists('/usr/share/artica-postfix/bin/install/joomla/files.txt') then begin
        writeln('Unable to stat /usr/share/artica-postfix/bin/install/joomla/files.txt');
        exit;
     end;
     l:=TstringList.Create;
     l.LoadFromFile('/usr/share/artica-postfix/bin/install/joomla/files.txt');
     for i:=0 to l.Count-1 do begin

         if not FileExists('/usr/local/share/artica/joomla_src/'+l.Strings[i]) then begin
            writeln('Unable to stat /usr/local/share/artica/joomla_src/'+l.Strings[i]+' installation corrupted');
            L.free;
            result:=false;
            exit;
         end;

     end;


    result:=true;
end;
//#########################################################################################
function tsetup_joomla.SugarCheckCorruptOrg(org:string):boolean;
var
   l:Tstringlist;
   i:Integer;
   files:string;
begin
    result:=false;
     files:='/usr/share/artica-postfix/bin/install/SugarCRM/files.txt';
     if not FileExists(files) then begin
        writeln(files);
        exit;
     end;
     l:=TstringList.Create;
     l.LoadFromFile(files);
     for i:=0 to l.Count-1 do begin

         if not FileExists('/usr/share/artica-groupware/domains/sugarcrm/'+org+'/'+l.Strings[i]) then begin
            writeln('unable to stat '+l.Strings[i]);
            result:=false;
            exit;
         end;

     end;


    result:=true;
end;
//#########################################################################################
function tsetup_joomla.CheckCorruptOrg(org:string):boolean;
var
   l:Tstringlist;
   i:Integer;
begin
    result:=false;

     if not FileExists('/usr/share/artica-postfix/bin/install/joomla/files.txt') then begin
        writeln('Unable to stat /usr/share/artica-postfix/bin/install/joomla/files.txt');
        exit;
     end;
     l:=TstringList.Create;
     l.LoadFromFile('/usr/share/artica-postfix/bin/install/joomla/files.txt');
     for i:=0 to l.Count-1 do begin

         if not FileExists('/usr/share/artica-groupware/domains/joomla/'+org+'/'+l.Strings[i]) then begin
            result:=false;
            exit;
         end;

     end;


    result:=true;
end;
//#########################################################################################




procedure tsetup_joomla.OrgSugarInstall(org:string);
var
   database:string;
begin

org:=AnsiReplaceText(org,'.','_');
org:=AnsiReplaceText(org,'-','_');
database:='sugarcrm_'+org;

if not SugarCheckCorrupt() then begin
     writeln('Corrupted repository folder.. Unable to install SugarCRM main program');
     exit;
end;

  if not FileExists('/usr/share/artica-postfix/bin/install/SugarCRM/sugarcrm.sql') then begin
     writeln('Unable to stat /usr/share/artica-postfix/bin/install/SugarCRM/sugarcrm.sql');
     exit;
  end;


  if not logs.IF_DATABASE_EXISTS(database) then begin
     writeln('Creating new database "'+database+'"');
     logs.EXECUTE_SQL_FILE('/usr/share/artica-postfix/bin/install/SugarCRM/sugarcrm.sql',database);
     if not SugarCheckDatabase(database) then exit;
  end else begin
      writeln('Database ' + database +' exists');
  end;

     if not SugarCheckDatabase(database) then begin
        writeln('Database ' + database +' check failed');
        exit;
     end else begin
          writeln('Database ' + database +' check success');
     end;


     ForceDirectories('/usr/share/artica-groupware/domains/sugarcrm/'+org);

     if not SugarCheckCorruptOrg(org) then begin
        writeln('Copy source to /usr/share/artica-groupware/domains/sugarcrm/'+org+'/...');
        logs.OutputCmd('/bin/cp -rf /usr/local/share/artica/sugarcrm_src/* /usr/share/artica-groupware/domains/sugarcrm/'+org+'/',true);
     end;

     if not SugarCheckCorruptOrg(org) then begin
         writeln('failed');
         exit;

     end;

     writeln('done.../usr/share/artica-groupware/domains/sugarcrm/'+org);



end;
//#########################################################################################
procedure tsetup_joomla.SugarCRM_INSTALL();
var
   CODE_NAME:string;
   cmd:string;
   RegExpr:TRegExpr;
begin

    CODE_NAME:='APP_SUGARCRM';
    SetCurrentDir('/root');

RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='org=(.+?)\s+';
    if RegExpr.Exec(myparmas) then begin
       writeln('Creating new SugarCRM web site for organization: '+RegExpr.Match[1]);
       OrgSugarInstall(RegExpr.Match[1]);
       exit;
    end;



  install.INSTALL_STATUS(CODE_NAME,10);
  install.INSTALL_STATUS(CODE_NAME,30);

  if not FileExists(SYS.LOCATE_APACHE_BIN_PATH()) then begin
     writeln('Install '+CODE_NAME+' failed...');
     install.INSTALL_PROGRESS(CODE_NAME,'{failed} (could not find apache)');
     install.INSTALL_STATUS(CODE_NAME,110);
     exit;
  end;

  if not FileExists(SYS.LOCATE_PHP5_BIN()) then begin
     writeln('Install '+CODE_NAME+' failed...');
     install.INSTALL_PROGRESS(CODE_NAME,'{failed} (could not find php)');
     install.INSTALL_STATUS(CODE_NAME,110);
     exit;
  end;

  if directoryExists('/usr/local/share/artica/sugarcrm_src') then begin
    If not SugarCheckCorrupt() then begin
       fpsystem('/bin/rm -rf /usr/local/share/artica/sugarcrm_src');
    end;
  end;




     install.INSTALL_PROGRESS(CODE_NAME,'{downloading}');
     if length(source_folder)=0 then source_folder:=libs.COMPILE_GENERIC_APPS('SugarCE');


     if not DirectoryExists(source_folder) then begin
        writeln('Install '+CODE_NAME+' failed...');
        writeln('Install '+CODE_NAME+' unable to stat source_folder: '+source_folder);
        install.INSTALL_STATUS(CODE_NAME,110);
        exit;
     end;


     writeln('Install '+CODE_NAME+' extracted on "'+source_folder+'"');
     install.INSTALL_STATUS(CODE_NAME,50);
     install.INSTALL_PROGRESS(CODE_NAME,'{installing}');

     forceDirectories('/usr/local/share/artica/sugarcrm_src');
     cmd:='/bin/cp -rf ' + source_folder+'/* /usr/local/share/artica/sugarcrm_src/';
     fpsystem(cmd);
     install.INSTALL_PROGRESS(CODE_NAME,'{checking}');



     if not FileExists('/usr/local/share/artica/sugarcrm_src/sugar_version.php') then begin
         writeln('Install '+CODE_NAME+' failed... Sugar Check Corrupt report corrupted installation');
        install.INSTALL_STATUS(CODE_NAME,110);
     end else begin
        writeln('Install '+CODE_NAME+' success...');
        install.INSTALL_STATUS(CODE_NAME,100);
        install.INSTALL_PROGRESS(CODE_NAME,'{installed}');
     end;



end;
//#########################################################################################
procedure tsetup_joomla.eyeOS_install();
var
   CODE_NAME:string;
   cmd:string;
   RegExpr:TRegExpr;
begin

    CODE_NAME:='APP_EYEOS';
    SetCurrentDir('/root');
    if distri.DISTRINAME_CODE<>'DEBIAN' then begin
     if distri.DISTRINAME_CODE<>'UBUNTU' then begin
        writeln('Install '+CODE_NAME+' failed...');
        install.INSTALL_PROGRESS(CODE_NAME,distri.DISTRINAME_CODE+' not supported');
        install.INSTALL_STATUS(CODE_NAME,110);
        exit;
    end;
    end;
  eyeOS_Systems();
  install.INSTALL_STATUS(CODE_NAME,10);
  install.INSTALL_STATUS(CODE_NAME,30);

  if not FileExists(SYS.LOCATE_APACHE_BIN_PATH()) then begin
     writeln('Install '+CODE_NAME+' failed...');
     install.INSTALL_PROGRESS(CODE_NAME,'{failed} (apache)');
     install.INSTALL_STATUS(CODE_NAME,110);
     exit;
  end;

  if not FileExists(SYS.LOCATE_PHP5_BIN()) then begin
     writeln('Install '+CODE_NAME+' failed...');
     install.INSTALL_PROGRESS(CODE_NAME,'{failed} (php)');
     install.INSTALL_STATUS(CODE_NAME,110);
     exit;
  end;

  if directoryExists('/usr/local/share/artica/eyeos_src') then fpsystem('/bin/rm -rf /usr/local/share/artica/eyeos_src');


  if not directoryExists('/usr/local/share/artica/eyeos_src') then begin
     install.INSTALL_PROGRESS(CODE_NAME,'{downloading}');
     if length(source_folder)=0 then source_folder:=libs.COMPILE_GENERIC_APPS('eyeOS');
     if not DirectoryExists(source_folder) then begin
        writeln('Install '+CODE_NAME+' failed "'+source_folder+'" no such directory');
        install.INSTALL_STATUS(CODE_NAME,110);
        exit;
     end;
     forcedirectories('/usr/local/share/artica/eyeos_src');
     writeln('Install '+CODE_NAME+' extracted on "'+source_folder+'"');
     install.INSTALL_STATUS(CODE_NAME,60);
     install.INSTALL_PROGRESS(CODE_NAME,'{installing}');
     writeln('Install '+CODE_NAME+' Creating directory  "/usr/local/share/artica/eyeos_src"');
     forceDirectories('/usr/local/share/artica/eyeos_src');
     if not FileExists(source_folder+'/index.php') then begin
            writeln(source_folder+'/index.php no such file');
            source_folder:=extractFilePath(source_folder);
            if source_folder[length (source_folder)] ='/' then source_folder:=Copy(source_folder,0,length (source_folder)-1);

             if not FileExists(source_folder+'/index.php') then begin
                 writeln(source_folder+'/index.php no such file');
                  install.INSTALL_STATUS(CODE_NAME,110);
                  exit;
             end;

     end;

     if DirectoryExists('/usr/local/share/artica/eyeos_src') then fpsystem('/bin/rm -rf /usr/local/share/artica/eyeos_src/*');

     writeln('Install '+CODE_NAME+' Copy "'+source_folder+'/*" -> "/usr/local/share/artica/eyeos_src"');
     cmd:='/bin/cp -rf ' + source_folder+'/* /usr/local/share/artica/eyeos_src/';
     fpsystem(cmd);
     writeln('Install '+CODE_NAME+' Copy done...');


     writeln('Install '+CODE_NAME+' checking /usr/local/share/artica/eyeos_src/index.php');
     install.INSTALL_PROGRESS(CODE_NAME,'{checking}');

     if FileExists(SYS.LOCATE_GENERIC_BIN('pecl')) then begin
        fpsystem(SYS.LOCATE_GENERIC_BIN('pecl')+' install uploadprogress');
     end;


     if not FileExists('/usr/local/share/artica/eyeos_src/index.php') then begin
         writeln('Install '+CODE_NAME+' /usr/local/share/artica/eyeos_src/index.php no such file');
         writeln('Install '+CODE_NAME+' failed...');
        install.INSTALL_STATUS(CODE_NAME,110);
        exit;
     end else begin
         writeln('Install '+CODE_NAME+' success...');
        install.INSTALL_STATUS(CODE_NAME,100);
        install.INSTALL_PROGRESS(CODE_NAME,'{installed}');
        exit;
     end;

end;





end;
//#########################################################################################
procedure tsetup_joomla.eyeOS_Systems();
var cmd:string;
begin
cmd:='DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy install openoffice.org php5 libapache2-mod-php5 php5-gd php5-mysql php5-imagick libimage-exiftool-perl ';
cmd:=cmd+'php5-sqlite php-pear php5-dev python-uno php5-mcrypt php5-curl zip unzip build-essential';
writeln(cmd);
fpsystem(cmd);

end;










end.
