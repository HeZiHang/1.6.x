unit articaldap;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
  Classes, SysUtils,ldapsend,RegExpr in 'RegExpr.pas',IniFiles,logs,openldap,zsystem,linux,tcpip;

type
  TStringDynArray = array of string;

type

  bogofilter_settings=record
        max_rate:integer;
        prepend:string;
        action:string;
        BogoFilterMailType:string;
  end;
  
computer_infos=record
   computername         :string;
   computerip           :string;
   computer_ports       :string;
   running              :string;
   OS                   :string;
   uptime               :string;
   hop                  :string;
   mac                  :string;
   comput_type          :string;

end;

  ActiveDirectoryServer=record
     dn_admin:string;
     password:string;
     server:string;
     server_port:string;
     suffix:string;
  end;

  

  ldapserver=record
      admin:string;
      password:string;
      suffix:string;
      servername:string;
  end;
  
  ou_datas=record
     BOGOFILTER_PARAM                   :bogofilter_settings;
     Organization                       :string;
     AdLinkerConf                       :string;
  end;

  ldapinfos =record
       BlackList:TStringList;
       WhiteList:TStringList;
       user_dn:string;
       user_ou:string;
       uid:string;
       RBL_SERVER_ACTION:string;
       RBL_SERVERS:TStringList;
       BOGOFILTER_ROBOTS:TStringList;
       BOGOFILTER_ACTION:string;
       BOGOFILTER_PARAM:bogofilter_settings;
       TrustMyUsers:string;
       end;

  mailboxesinfos=record
      Users                                 :TstringList;
      Cyrus_password                        :string;
  end;

  http_proxy_settings=record
       ArticaProxyServerName                :string;
       ArticaProxyServerPort                :string;
       ArticaProxyServerUsername            :string;
       ArticaProxyServerUserPassword        :string;
       ArticaProxyServerEnabled             :string;
       IniSettings                          :string;
       ArticaMailAddonsLevel                :string;

  end;


  cyrus_settings=record
       CyrusConf                            :string;
       impadconf                            :string;
  end;


  dansguardian_settings=record
      DansGuardianRulesIndex                :TStringList;
      DansGuardianMasterConf                :string;
      FilterGroupListConf                   :string;

  end;
  
  
  bind9_settings=record
      NamedConf                             :string;
      BindZones                             :TStringList;
      ZoneContent                           :TStringList;

  end;
  
  kav4sambaSettings=record
      kav4sambaConf                         :string;

  end;


  fetchmail_settings=record
       fetchmailrc:string;
       FetchGetLive:string;
  end;

  inadyn_settings=record
        ArticaInadynPoolRule:string;
        ArticaInadynRule:TstringList;
        proxy_settings:http_proxy_settings;
  end;

  miltergreylist_settings=record
    GreyListConf                 :string;
    MilterGreyListEnabled        :string;

  end;




  postfix_settings=record
    PostfixMainCfFile:string;
    PostfixBounceTemplateFile:string;
    PostFixHeadersRegexFile:string;
    PostfixTimeCode:string;
    PostfixMasterCfFile:string;
  end;

  sqlgrey_settings=record
     SqlGreyEnabled                        :integer;
     SqlGreyConf                           :string;
     SqlGreyTimeCode                       :string;
  end;


  KavMilter_settings=record
     kavmilterEnable                       :string;
  end;
  
  
  FDM_settings=record
     FDMConf                               :TstringList;
  end;


  crossroads_settings=record
     PostfixSlaveServersIdentity           :TstringList;
     PostfixMasterServerIdentity           :String;
     CrossRoadsBalancingServerIP           :string;
     CrossRoadsBalancingServerName         :string;
     CrossRoadsPoolingTime                 :string;
  end;


  artica_settings=record
     ArticaMailAddonsLevel                 :string;
     MysqlAdminAccount                     :string;
     ArticaMaxTempLogFilesDay              :string;
     ArticaFoldersSizeConfig               :TstringList;
     ArticaAutoUpdateConfig                :string;
     ArticaPolicyEnabled                   :string;
     ArticaFilterEnabled                   :string;
     KasxFilterEnabled                     :string;
     OBMEnabled                            :string;
     NTPDEnabled                           :string;
     MailFromdEnabled                      :string;
     IptablesEnabled                       :string;
     MysqlMaxEventsLogs                    :string;
     ApacheArticaEnabled                   :string;
     lighttpConfig                         :string;
     ApacheConfig                          :string;
     ClamavMilterEnabled                   :string;
     SpamAssMilterEnabled                  :string;
     spfmilterEnabled                      :string;
     EnableSyslogMysql                     :string;
     MimeDefangEnabled                     :string;
     DkimFilterEnabled                     :string;
     ArticaUsbBackupKeyID                  :string;
     NmapScanEnabled                       :string;
     RoundCubeHTTPEngineEnabled            :string;
     RoundCubeLightHTTPD                   :string;
     RoundCubeConfigurationFile            :string;
     EnableFetchmail                       :string;
     EnableFDMFetch                        :string;
     PostfixSSLCert                        :string;
     MasterCFEnabled                       :string;
     P3ScanEnabled                         :string;
     SmtpNotificationConfig                :string;
     ArticaPerformancesSettings            :string;
     HdBackupConfig                        :string;
     sTunnel4enabled                       :string;
     MailArchiverEnabled                   :string;
     ArticaEnableKav4ProxyInSquid          :string;
     EnableMilterBogom                     :string;
     EnableMysqlFeatures                   :string;
     MysqlServerName                       :string;
     EnableCollectdDaemon                  :string;
     EnableVirtualDomainsInMailBoxes       :string;
     EnableMilterSpyDaemon                 :string;
     EnableAmavisDaemon                    :string;

  end;
  
  nmap_settings=record
     NmapRotateMinutes                     :string;
     NmapNetworkIP                         :TStringList;
  end;

  amavis_settings=record
    AmavisConfigFile                       :string;

  end;
  
  
  mimedefang_settings=record
      MimeDefangFilter                     :string;
  
  end;
  
  
  stunnel4_config=record
      stunnelconf                           :string;

  end;
  
  
  spamassassin_settings=record
     SpamAssassinConfFile                  :string;
  
  end;


  backup_settings=record
      ArticaBackupConf                     :string;
      ArticaBackupEnabled                  :string;
      HdBackupConfig                       :string;
      MountBackupConfig                    :string;
  end;

  shared_folders=record
      SharedFolerConf                       :TstringList;
      gidnumber                             :TstringList;


  end;


  obm_settings=record
      OBMApacheFile                        :string;
      OBMConfIni                           :string;
      OBMConfInc                           :string;
  end;
  
  bightml=record
  
      BigMailHTMLEnabled                   :string;
      BigMailHtmlConfig                    :string;
      BigMailHtmlRules                     :TstringList;
      BigMailHtmlBody                      :string;
 end;
 
 
 HtmlBackup=record
     BackupEnabled                         :string;
     ArticaBackupRules                     :TstringList;
 end;
 
 dkimfilter_settings=record
     DkimFilterConf                        :string;
 end;
  

  users_datas=record
        uid                                :string;
        MailBoxMaxSize                     :string;
        FTPDownloadBandwidth               :string;
        FTPDownloadRatio                   :string;
        FTPQuotaFiles                      :string;
        FTPQuotaMBytes                     :string;
        FTPUploadBandwidth                 :string;
        FTPUploadRatio                     :string;
        homeDirectory                      :string;
        userPassword                       :string;
        Organization                       :string;
        dn                                 :string;
        bightml                            :bightml;
        HtmlBackup                         :HtmlBackup;
        mail                               :string;
        BOGOFILTER_PARAM                   :bogofilter_settings;
        RecipientToAdd                     :string;
        ComputerInfos                      :computer_infos;
        MailboxSecurityParameters          :string;
        AllowedSMTPTroughtInternet         :string;
        EnableUserSpamLearning             :string;

  end;


  kas_groups=record
  KasHexGroupName                          :string;
  kasactiondef                             :string;
  kasallowxml                              :string;
  kasdenyxml                               :string;
  kasipallowxml                            :string;
  kasipdenyxml                             :string;
  kasmembersxml                            :string;
  kasprofilexml                            :string;
  kasruledef                               :string;
  end;


  mailfromd_settings=record
    MailFromdRC                            :string;
    MailFromdUserUpdated                   :string;
    MailFromdUserScript                    :string;
  end;

  iptables_settings=record
       iptablesFile                        :string;
  end;
  
  samba_settings=record
    SambaSMBConf                           :string;
    SambaUsbShare                          :string;

  end;
  

  type
  Tarticaldap=class


  private
       ldap_admin,ldap_password,ldap_suffix,ldap_server:string;
       global_ldap         :TLDAPsend;
       DN_ROOT             :string;
       D                   :boolean;
       logs                :tlogs;
       zldp                :topenldap;
       SYS                 :Tsystem;


       function     get_CONF(key:string):string;
       function     Query_A(Query_string:string;return_attribute:string):TStringDynArray;

       function     ParseResultInStringList(Items:TLDAPAttribute):TStringList;
       function     SearchSingleAttribute(Items:TLDAPAttributeList;SearchAttribute:string):string;
       function     SearchMultipleAttribute(Items:TLDAPResultList;SearchAttribute:string):Tstringlist;
       function     SearchSingleData(Items:TLDAPResultList;SearchAttribute:string):string;
       function     Create_dcObject(dn:string;name:string):boolean;
       procedure    DumpAttributes(LDAPAttributeList:TLDAPAttributeList);
       function     logon():boolean;
       function     GetSingleAttribute(search:TLDAPResultList;attribute:string):string;
       function     GetMultipleAttributes(search:TLDAPResultList;attribute:string):TstringList;
       procedure    CreateDiscoversBranch();
       function     SYSTEM_LOCAL_SID():string;
       function     BlackListedList_string(search:TLDAPAttributeList;First:string;Attr:string):string;
       function     RESOLV_SERVER(servername:string):string;

  public
      constructor   Create();
      destructor    Destroy; override;
       ftplist      :TstringList;
       Logged       :boolean;
      function      Explode(const Separator, S: string; Limit: Integer = 0):TStringDynArray;
      function      EmailFromAliase(email:string):string;
      function      EmailFromUID(UID:string):string;
      procedure     admin_modify();

      function      LoadASRules(email:string):string;
      function      LoadAVRules(email:string):string;
      function      LoadOUASRules(ou:string):string;
      function      ExistsDN(DN:string):boolean;

      function      Load_Kav4proxy_settings():string;
      function      Load_Fetchmail_settings():fetchmail_settings;
      
      ///SQUID
      
      function      Load_squid_settings(servername:string):string;
      function      Load_squidnewbee_settings():string;
      function      Load_squidnewbee_SquidBlockSites():string;
      
      function      Load_inadyn_settings():inadyn_settings;
      function      Load_proxy_settings():http_proxy_settings;
      function      Load_miltergreylist():miltergreylist_settings;
      function      Load_sqlgrey_settings(servername:string):sqlgrey_settings;
      function      ArticaMailAddonsLevel():string;
      function      LoadMailboxes(loadallusers:boolean):mailboxesinfos;
      function      Load_Dansguardian_MainConfiguration():dansguardian_settings;
      function      Load_Dansguardian_fileconfig(ruleindex:string;attribute:string):string;
      function      Load_Dansguardian_categories(ruleindex:string):TstringList;
      function      Load_Dansguardian_BannedPhraseList(ruleindex:string):TstringList;


      function      Load_postfix_main_settings():postfix_settings;
      function      Load_amavis_main_settings():amavis_settings;
      function      Load_crossroads_main_settings():crossroads_settings;
      function      Load_artica_main_settings():artica_settings;
      function      Load_userasdatas(uid:string):users_datas;
      function      Load_OBM_SETTINGS():obm_settings;
      function      Load_iptables_settings():iptables_settings;
      function      Load_backup_settings():backup_settings;
      function      Load_samba():samba_settings;
      procedure     DeleteCyrusUser();
      procedure     CreateMailManBranch();
      function      Load_mimedefang():mimedefang_settings;
      function      Load_OU_DATAS(domain:string):ou_datas;
      function      Allowed_domains():TstringList;
      function      postfix_networks():TstringList;
      procedure     lighttpd_modify_config(config:string);

      
      
      
      //Bind9
      function      load_bind9_settings():bind9_settings;
      function      bind9_Create_master_branch(NamedConf:string):boolean;
      function      bind9_Create_zone_branch(zone:string;FilePath:string):boolean;
      function      load_bind9_zone(zone_name:string):bind9_settings;

      //Kaspersky Groups
      function      Load_KasGroupsList():TstringList;
      function      Load_KasGroupDatas(gidnumber:string):kas_groups;

      // Kaspersky Milter edition
      function     Load_KavMilter_settings():KavMilter_settings;

      //Mailfromd
      function     Load_mailfromd_settings():mailfromd_settings;
      
      //SpamAssassin
      function     Load_spamassassin():spamassassin_settings;
      
      //Stunnel4
      function     load_stunnel4():stunnel4_config;
      
      //DKIM
      function     load_dkim_filter():dkimfilter_settings;

      //ActiveDirectory
      function     TestingADConnection(Settings:ActiveDirectoryServer):boolean;
      function     HomesUsersPath():TstringList;
      
      //NMAP
      function     load_nmap_settings:nmap_settings;
      function     AddScannerComputer(co:computer_infos):boolean;
      function     samba_group_sid_from_gid(gid:string):string;
      function     samba_get_new_uidNumber():string;
      function     ComputerDN_From_MAC(mac:string):string;
      function     Load_ORGANISATION(ORG:string):ou_datas;

      procedure     Load_ftp_users();
      function      pureftpd_settings(servername:string):string;
      function      Ldap_infos(email:string):ldapinfos;
      function      load_Kav4Samba():kav4sambaSettings;

      function COMMANDLINE_PARAMETERS(FoundWhatPattern:string):boolean;
      function Query(Query_string:string;return_attribute:string):string;


      //Dotclear
      function  DotClearUsers():TstringList;

      function  OU_From_eMail(email:string):string;
      function  QuarantineMaxDayByOu(Ou:string):string;
      function  IsOuDomainBlackListed(Ou:string;domain:string):boolean;
      function  FackedSenderParameters(Ou:string):string;
      function  ArticaMaxSubQueueNumberParameter():integer;
      function  ArticaDenyNoMXRecordsOu(Ou:string):string;
      procedure CreateArticaUser();
      function  Get_cyrus_conf():cyrus_settings;
      function  Create_Artica_branch():boolean;

      function OuLists():TStringDynArray;
      function implode(ArrayS:TStringDynArray):string;
      function ParseSuffix():boolean;
      procedure CreateSuffix();
      function CreateCyrusUser():boolean;
      function LoadAllOu():string;
      function UserDataFromMail(email:string):users_datas;
      function load_FDM_settings:FDM_settings;
      
      function BlackListedList():TstringList;
      function SpamAssassinAutoLearnUsers():TstringList;
      
      SEARCH_DN:string;
      TEMP_LIST:TstringList;
      LDAPINFO:ldapserver;

end;

implementation

constructor Tarticaldap.Create();
begin
   SEARCH_DN:='';
   zldp:=Topenldap.Create;
   ldap_admin:=zldp.get_LDAP('admin');
   ldap_password:=zldp.get_LDAP('password');
   ldap_suffix:=zldp.get_LDAP('suffix');
   ldap_server:=zldp.get_LDAP('server');
   if length(ldap_server)=0 then ldap_server:='127.0.0.1';
   if ldap_server='*' then ldap_server:='127.0.0.1';
   SYS:=Tsystem.Create();
   LDAPINFO.admin:=ldap_admin;
   LDAPINFO.password:=ldap_password;
   LDAPINFO.suffix:=ldap_suffix;
   LDAPINFO.servername:=ldap_server;
   logs:=Tlogs.Create;




   global_ldap:=TLDAPsend.Create;
   D:=COMMANDLINE_PARAMETERS('debug');
   if D then writeln('Tarticaldap.Create() -> logon to ldap server ' + ldap_server);
   Logged:=logon();
   if D then writeln('Tarticaldap.Create() -> logon to ldap server end');
   
   
   TEMP_LIST:=TstringList.Create;
end;
//##############################################################################
destructor Tarticaldap.Destroy;
begin

  global_ldap.Logout;
  TEMP_LIST.Free;
  global_ldap.free;
  inherited Destroy;
end;
//##############################################################################
function Tarticaldap.OuLists():TStringDynArray;
var Myquery:string;
resultats:TStringDynArray;
begin
     Myquery:='(&(ObjectClass=organizationalUnit)(ou=*))';
     resultats:=Query_A(MyQuery,'ou');
     exit(resultats);
end;
//##############################################################################
function Tarticaldap.TestingADConnection(Settings:ActiveDirectoryServer):boolean;

var
   AD:TLDAPsend;
   Myquery:string;
   l:TstringList;
   i:integer;
   z:integer;
   f:integer;
   DN:string;
begin
   result:=false;
   AD:=TLDAPSend.Create;
   AD.TargetHost:=settings.server;
   AD.TargetPort := settings.server_port;
   if length(trim(settings.dn_admin))>0 then begin
     AD.UserName := settings.dn_admin;
     AD.Password := settings.password;
   end;
   AD.Version := 3;
   AD.FullSSL := false;
   AD.Timeout:=100;
   
   if not AD.Login then begin
      writeln('ERR Unable to connect to specified server ' +  AD.TargetHost + ':'+ AD.TargetPort);
      exit;
   end;
   
    if not AD.Bind then begin
       writeln('ERR failed bind "' + AD.UserName + '" ',AD.ResultString,' ',AD.FullResult);
       AD.free;
       exit;
    end;
    AD.Logout;
    AD.free;
    result:=true;

end;
//##############################################################################
function Tarticaldap.logon():boolean;
var RegExpr     :TRegExpr;
begin
     result:=false;
     RegExpr:=TRegExpr.Create;

     RegExpr.Expression:='([a-zA-Z]+)';
     if RegExpr.Exec(ldap_server) then begin
          ldap_server:=RESOLV_SERVER(ldap_server);
     end;

     global_ldap :=  TLDAPSend.Create;
     global_ldap.TargetHost := ldap_server;
     global_ldap.TargetPort := '389';
     global_ldap.UserName := 'cn=' +ldap_admin + ',' + ldap_suffix;
     global_ldap.Password := ldap_password;
     global_ldap.Version := 3;
     global_ldap.FullSSL := false;
     global_ldap.Timeout:=10;

 if not global_ldap.Login then begin
    logs.Syslogs('Tarticaldap.logon():: unable to TCP connect...'+global_ldap.ResultString+' "'+global_ldap.FullResult+'"');
    logs.Syslogs('Tarticaldap.logon():: host="'+global_ldap.TargetHost+':'+global_ldap.TargetPort+'"');
    exit();
 end;


    if not global_ldap.Bind then begin
       logs.Syslogs('Tarticaldap.logon():: unable to Bind...'+global_ldap.ResultString) ;
       logs.Syslogs('Tarticaldap.logon():: '+global_ldap.FullResult);
       logs.Syslogs('Tarticaldap.logon():: username='+global_ldap.UserName+' host='+global_ldap.TargetHost);
       exit;
    end;
if D then writeln('logon:: success to connect...');
result:=true;

end;

//##############################################################################
function Tarticaldap.RESOLV_SERVER(servername:string):string;
var
   cache_file:string;
   tcp:ttcpip;
   ttmp:string;
begin
    cache_file:='/etc/artica-postfix/ldap.'+logs.MD5FromString(servername)+'.cache';
    if SYS.FILE_TIME_BETWEEN_MIN(cache_file)>25 then begin
         logs.Debuglogs('RESOLV_SERVER:: Delete cache');
         logs.DeleteFile(cache_file);
    end;


    if not FIleExists(cache_file) then begin
       tcp:=ttcpip.Create;
       ttmp:=tcp.resolv(servername);
       logs.Debuglogs('RESOLV_SERVER:: '+servername+'='+ttmp);
       logs.WriteToFile(ttmp,cache_file);
    end else begin
      ttmp:=trim(logs.ReadFromFile(cache_file));
    end;

    if length(ttmp)=0 then begin
       logs.Syslogs('RESOLV_SERVER:: unable to resolv '+servername);
       logs.DeleteFile(cache_file);
       exit;
    end;

    result:=ttmp;
end;
//##############################################################################



function Tarticaldap.SYSTEM_LOCAL_SID():string;
var
   FILI        :TstringList;
   RegExpr     :TRegExpr;
   i           :integer;
   tmpfile     :string;
begin
  forceDirectories('/opt/artica/logs');
  tmpfile:=logs.OutputCmdR('/usr/bin/net getlocalsid');
  if not fileExists(tmpfile) then exit;
  FILI:=TstringList.Create;
  FILI.LoadFromFile('/opt/artica/logs/getlocalsid.tmp');
  logs.DeleteFile(tmpfile);
  RegExpr:=TRegExpr.Create;
  RegExpr.Expression:='is:\s+(.+)';
  for i:=0 to FILI.Count-1 do begin
     if RegExpr.Exec(FILI.Strings[i]) then begin
        result:=RegExpr.Match[1];
        break;
     end;
  end;

  RegExpr.Free;
  FILI.free;
end;
//#########################################################################################


function Tarticaldap.Load_artica_main_settings():artica_settings;
var
   F                        :artica_settings;
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t                        :integer;
   AutoUpdateConfig         :string;
begin
result:=f;
f.ArticaFoldersSizeConfig:=TstringList.Create;
  if not Logged then begin
     if D then writeln('Load_artica_main_settings(),Logged -> false, exit...');
     exit(f);
  end;

l:=TstringList.Create;
  DN:='cn=artica,' + ldap_suffix;
  Myquery:='(objectClass=ArticaSettings)';
  ftplist:=TstringList.Create;
  f.ArticaFoldersSizeConfig:=TstringList.Create;

    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Load_artica_main_settings:: Failed search ' + Myquery + ' in ' + DN);
         exit(f);
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('Load_artica_main_settings:: Failed search ' + Myquery + ' in ' + DN);
       exit(f);
    end;

    for i:=0 to global_ldap.SearchResult.Count -1 do begin
         if length(f.ArticaMailAddonsLevel)=0 then f.ArticaMailAddonsLevel:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'ArticaMailAddonsLevel');

         if length(AutoUpdateConfig)=0 then AutoUpdateConfig:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'articaautoupdateconfig');
         f.ArticaFoldersSizeConfig.AddStrings(SearchMultipleAttribute(global_ldap.SearchResult,'ArticaFoldersSizeConfig'));
         if length(f.ArticaPolicyEnabled)=0 then f.ArticaPolicyEnabled:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'ArticaPolicyEnabled');
         if length(f.ArticaFilterEnabled)=0 then f.ArticaFilterEnabled:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'ArticaFilterEnabled');
         if length(f.KasxFilterEnabled)=0 then f.KasxFilterEnabled:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'KasxFilterEnabled');
         if length(f.OBMEnabled)=0 then f.OBMEnabled:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'OBMEnabled');
         if length(f.NTPDEnabled)=0 then f.NTPDEnabled:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'NTPDEnabled');
         if length(f.MailFromdEnabled)=0 then f.MailFromdEnabled:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'MailFromdEnabled');
         if length(f.IptablesEnabled)=0 then f.IptablesEnabled:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'IptablesEnabled');

         
     end;
     
     f.PostfixSSLCert:=GetSingleAttribute(global_ldap.SearchResult,'PostfixSSLCert');
     

DN:='cn=artica,' + ldap_suffix;
Myquery:='(objectClass=ArticaSettings2)';

  if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Load_artica_main_settings:: Failed search ' + Myquery + ' in ' + DN);
         exit(f);
    end;

    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('Load_artica_main_settings:: Failed search ' + Myquery + ' in ' + DN);
       exit(f);
    end;

for i:=0 to global_ldap.SearchResult.Count -1 do begin
      if length(f.MysqlMaxEventsLogs)=0 then f.MysqlMaxEventsLogs:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'MysqlMaxEventsLogs');
      if length(f.ApacheArticaEnabled)=0 then f.ApacheArticaEnabled:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'ApacheArticaEnabled');
      if length(f.lighttpConfig)=0 then f.lighttpConfig:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'lighttpConfig');
      if length(f.ApacheConfig)=0 then f.ApacheConfig:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'ApacheConfig');
      if length(f.MysqlAdminAccount)=0 then f.MysqlAdminAccount:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'MysqlAdminAccount');
      if length(f.ClamavMilterEnabled)=0 then f.ClamavMilterEnabled:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'ClamavMilterEnabled');
      if length(f.SpamAssMilterEnabled)=0 then f.SpamAssMilterEnabled:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'SpamAssMilterEnabled');
      if length(f.spfmilterEnabled)=0 then f.spfmilterEnabled:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'spfmilterEnabled');
      if length(f.EnableSyslogMysql)=0 then f.EnableSyslogMysql:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'EnableSyslogMysql');
      if length(f.MimeDefangEnabled)=0 then f.MimeDefangEnabled:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'MimeDefangEnabled');
      f.DkimFilterEnabled:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'DkimFilterEnabled');
      f.ArticaUsbBackupKeyID:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'ArticaUsbBackupKeyID');
      f.NmapScanEnabled:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'NmapScanEnabled');
      f.RoundCubeHTTPEngineEnabled:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'RoundCubeHTTPEngineEnabled');
      f.RoundCubeLightHTTPD:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'RoundCubeLightHTTPD');
      f.RoundCubeConfigurationFile:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'RoundCubeConfigurationFile');
      f.EnableFetchmail:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'EnableFetchmail');
      f.EnableFDMFetch:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'EnableFDMFetch');
      f.MasterCFEnabled:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'MasterCFEnabled');
      f.P3ScanEnabled:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'P3ScanEnabled');
      f.SmtpNotificationConfig:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'SmtpNotificationConfig');
      f.sTunnel4enabled:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'sTunnel4enabled');
      f.MailArchiverEnabled:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'MailArchiverEnabled');
      f.EnableMilterBogom:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'EnableMilterBogom');
      f.EnableMysqlFeatures:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'EnableMysqlFeatures');
      f.MysqlServerName:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'MysqlServerName');
      f.EnableCollectdDaemon:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'EnableCollectdDaemon');
      f.EnableVirtualDomainsInMailBoxes:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'EnableVirtualDomainsInMailBoxes');
      f.EnableMilterSpyDaemon:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'EnableMilterSpyDaemon');
      f.EnableAmavisDaemon:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'EnableAmavisDaemon');




      
      
      
end;

    DN:='cn=artica,' + ldap_suffix;
    Myquery:='(objectClass=ArticaSettings3)';

    if global_ldap.Search(DN, False, Myquery, l) then begin
       if global_ldap.SearchResult.Count>0 then begin
            for i:=0 to global_ldap.SearchResult.Count -1 do begin
                f.ArticaMaxTempLogFilesDay:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'MaxTempLogFilesDay');
                f.ArticaPerformancesSettings:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'ArticaPerformancesSettings');
            end;
       end;
    end;
    //-----------------------------------------------------------------------------------
    
    
    //SQUID
    DN:='cn=squid-config,cn=artica,' + ldap_suffix;
    Myquery:='(objectClass=SquidProxyClass)';
    if global_ldap.Search(DN, False, Myquery, l) then begin
       if global_ldap.SearchResult.Count>0 then begin
            for i:=0 to global_ldap.SearchResult.Count -1 do begin
                f.ArticaEnableKav4ProxyInSquid:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'ArticaEnableKav4ProxyInSquid');
            end;
       end;
    end;
    //-----------------------------------------------------------------------------------
    


    f.ArticaAutoUpdateConfig:=AutoUpdateConfig;
    if length(F.ArticaMaxTempLogFilesDay)=0 then F.ArticaMaxTempLogFilesDay:='3';
    if length(F.ApacheArticaEnabled)=0 then F.ApacheArticaEnabled:='0';
    if length(f.MysqlMaxEventsLogs)=0 then f.MysqlMaxEventsLogs:='200000';
    if length(f.NmapScanEnabled)=0 then f.NmapScanEnabled:='1';
    result:=f;

end;
//##############################################################################
function Tarticaldap.UserDataFromMail(email:string):users_datas;
var
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t                        :integer;
   AutoUpdateConfig         :string;
   f                        :users_datas;
   uid                      :string;
begin
result:=f;

  if not Logged then begin
     if D then writeln('GetUidFromMail(),Logged -> false, exit...');
     logs.Debuglogs('GetUidFromMail(),Logged -> false, exit...');
     exit;
  end;

  l:=TstringList.Create;
  l.Add('uid');
  DN:='dc=organizations,'+ldap_suffix;

  Myquery:='(&(objectclass=userAccount)(|(mailAlias='+email+')(mail='+email+')(mozillaSecondEmail='+email+')(FetchMailMatchAddresses='+email+')))';
  global_ldap.SearchResult.Clear;

    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('UserDataFromMail:: Failed search ' + Myquery + ' in ' + DN);
              logs.Debuglogs('UserDataFromMail:: Failed search ' + Myquery + ' in ' + DN);
              exit(f);
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('UserDataFromMail:: Failed search ' + Myquery + ' in ' + DN);
       logs.Debuglogs('UserDataFromMail:: Failed search ' + Myquery + ' in ' + DN);
       exit(f);
    end;
    
    
    uid:=GetSingleAttribute(global_ldap.SearchResult,'uid');

    f:=Load_userasdatas(uid);
    result:=f;



end;
//##############################################################################
function Tarticaldap.BlackListedList():TstringList;
var
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t,z                        :integer;
   AutoUpdateConfig         :string;
   f                        :TstringList;
   AttributeName            :string;
   amavisBlacklistSender    :string;
   amavisWhitelistSender    :string;
   KasperkyASDatasDeny      :string;
   
begin
f:=TstringList.CReate;
result:=f;

  if not Logged then begin
     if D then writeln('BlackListedList(),Logged -> false, exit...');
     logs.Debuglogs('BlackListedList(),Logged -> false, exit...');
     exit;
  end;

  l:=TstringList.Create;
  l.Add('mail');
  l.Add('amavisBlacklistSender');
  DN:=ldap_suffix;
  Myquery:='(&(objectClass=ArticaSettings)(mail=*)(amavisBlacklistSender=*))';
  global_ldap.SearchResult.Clear;
  
if global_ldap.Search(DN, False, Myquery, l) then begin
    if D then writeln(Myquery+ ' amavisBlacklistSender count :',global_ldap.SearchResult.Count);
    for i:=0 to global_ldap.SearchResult.Count-1 do begin
    if D then writeln('search ',i,'=',global_ldap.SearchResult.Items[i].ObjectName);
    amavisBlacklistSender:=BlackListedList_string( global_ldap.SearchResult.Items[i].Attributes,'mail','amavisBlacklistSender');
    if length(amavisBlacklistSender)>0 then f.Add('B:'+amavisBlacklistSender);
    end;
end;

  l.Clear;
  global_ldap.SearchResult.Clear;
  l.Add('mail');
  l.Add('amavisWhitelistSender');
  Myquery:='(&(objectClass=ArticaSettings)(mail=*)(amavisWhitelistSender=*))';

if global_ldap.Search(DN, False, Myquery, l) then begin
    if D then writeln(Myquery+ ' amavisWhitelistSender count :',global_ldap.SearchResult.Count);
    for i:=0 to global_ldap.SearchResult.Count-1 do begin
    if D then writeln('search ',i,'=',global_ldap.SearchResult.Items[i].ObjectName);
    amavisWhitelistSender:=BlackListedList_string( global_ldap.SearchResult.Items[i].Attributes,'mail','amavisWhitelistSender');
    if length(amavisWhitelistSender)>0 then f.Add('W:'+amavisWhitelistSender);
    end;
end;

  l.Clear;
  global_ldap.SearchResult.Clear;
  l.Add('cn');
  l.Add('KasperkyASDatasDeny');
  Myquery:='(&(objectClass=ArticaSettings)(objectClass=PostFixStructuralClass)(cn=*)(KasperkyASDatasDeny=*))';
if global_ldap.Search(DN, False, Myquery, l) then begin
    if D then writeln(Myquery+ ' KasperkyASDatasDeny count :',global_ldap.SearchResult.Count);
    for i:=0 to global_ldap.SearchResult.Count-1 do begin
    if D then writeln('search ',i,'=',global_ldap.SearchResult.Items[i].ObjectName);
    amavisWhitelistSender:=BlackListedList_string( global_ldap.SearchResult.Items[i].Attributes,'cn','KasperkyASDatasDeny');
    if length(amavisWhitelistSender)>0 then f.Add('B:'+amavisWhitelistSender);
    end;
end;

  l.Clear;
  global_ldap.SearchResult.Clear;
  l.Add('cn');
  l.Add('KasperkyASDatasAllow');
  Myquery:='(&(objectClass=ArticaSettings)(objectClass=PostFixStructuralClass)(cn=*)(KasperkyASDatasAllow=*))';
if global_ldap.Search(DN, False, Myquery, l) then begin
    if D then writeln(Myquery+ ' KasperkyASDatasAllow count :',global_ldap.SearchResult.Count);
    for i:=0 to global_ldap.SearchResult.Count-1 do begin
    if D then writeln('search ',i,'=',global_ldap.SearchResult.Items[i].ObjectName);
    amavisWhitelistSender:=BlackListedList_string( global_ldap.SearchResult.Items[i].Attributes,'cn','KasperkyASDatasAllow');
    if length(amavisWhitelistSender)>0 then f.Add('W:'+amavisWhitelistSender);
    end;
end;

end;
//##############################################################################
function Tarticaldap.BlackListedList_string(search:TLDAPAttributeList;First:string;Attr:string):string;
var
   A:string;
   list:string;
   i,t:integer;
   AttributeName:string;
   item:string;
begin
    for i:=0 to  search.Count-1 do begin
        AttributeName:=search.Items[i].AttributeName;
        if D then writeln('Attribute[',i,']=',AttributeName);
        if AttributeName=Attr then begin
                for t:=0 to search.Items[i].Count-1 do begin
                  item:=search.Items[i].Strings[t];
                  list:=list+item+';';
                  if D then writeln('Attribute[',i,'][',AttributeName,'][',t,']=',item);
                end;
        end;
        
        if AttributeName=First then begin
              A:=search.Items[i].Strings[0];
        end;
    end;
    
result:=A+'='+list;

end;
//##############################################################################






function Tarticaldap.Get_cyrus_conf():cyrus_settings;
var
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   f                        :cyrus_settings;
begin
result:=f;

  if not Logged then begin
     if D then writeln('Get_cyrus_conf(),Logged -> false, exit...');
     exit;
  end;

  l:=TstringList.Create;
  DN:='cn=cyrus-config,cn=artica,'+ldap_suffix;
  Myquery:='(&(objectclass=CyrusConfigClass))';
  global_ldap.SearchResult.Clear;

    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Get_cyrus_conf:: Failed search ' + Myquery + ' in ' + DN);
         exit(f);
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('Get_cyrus_conf:: Failed search ' + Myquery + ' in ' + DN);
       exit(f);
    end;


    f.CyrusConf:=GetSingleAttribute(global_ldap.SearchResult,'CyrusConf');
    f.impadconf:=GetSingleAttribute(global_ldap.SearchResult,'impadconf');
    result:=f;

end;
//##############################################################################
function Tarticaldap.load_bind9_settings():bind9_settings;
var
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   f                        :bind9_settings;
begin
f.BindZones:=TstringList.Create;
f.ZoneContent:=TStringList.Create;
result:=f;

  if not Logged then begin
     if D then writeln('load_bind9_settings(),Logged -> false, exit...');
     exit;
  end;

  l:=TstringList.Create;
  DN:='cn=bind9,cn=artica,'+ldap_suffix;
  Myquery:='(&(objectclass=Bind))';
  global_ldap.SearchResult.Clear;

    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('load_bind9_settings:: Failed search ' + Myquery + ' in ' + DN);
         exit(f);
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('load_bind9_settings:: Failed search ' + Myquery + ' in ' + DN);
       exit(f);
    end;

    f.NamedConf:=GetSingleAttribute(global_ldap.SearchResult,'NamedConf');
    f.ZoneContent.AddStrings(GetMultipleAttributes(global_ldap.SearchResult,'ZoneContent'));
    f.BindZones.AddStrings(GetMultipleAttributes(global_ldap.SearchResult,'BindZones'));
    result:=f;

end;
//##############################################################################
function Tarticaldap.load_bind9_zone(zone_name:string):bind9_settings;
var
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   f                        :bind9_settings;
begin
f.BindZones:=TstringList.Create;
f.ZoneContent:=TStringList.Create;
result:=f;

  if not Logged then begin
     if D then writeln('load_bind9_zone(),Logged -> false, exit...');
     exit;
  end;

  l:=TstringList.Create;
  DN:='cn='+zone_name+',cn=bind9,cn=artica,'+ldap_suffix;
  Myquery:='(&(objectclass=Bind))';
  global_ldap.SearchResult.Clear;

    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('load_bind9_zone:: Failed search ' + Myquery + ' in ' + DN);
         exit(f);
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('load_bind9_zone:: Failed search ' + Myquery + ' in ' + DN);
       exit(f);
    end;

    f.NamedConf:=GetSingleAttribute(global_ldap.SearchResult,'ZoneContent');
    result:=f;

end;
//##############################################################################


function Tarticaldap.load_stunnel4():stunnel4_config;
var
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   f                        :stunnel4_config;
begin
result:=f;

  if not Logged then begin
     if D then writeln('load_stunnel4(),Logged -> false, exit...');
     exit;
  end;

  l:=TstringList.Create;
  DN:='cn=stunnel4,cn=artica,'+ldap_suffix;
  Myquery:='(&(objectclass=sTunnel4Config))';
  global_ldap.SearchResult.Clear;

    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('load_stunnel4:: Failed search ' + Myquery + ' in ' + DN);
         exit(f);
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('load_stunnel4:: Failed search ' + Myquery + ' in ' + DN);
       exit(f);
    end;


    f.stunnelconf:=GetSingleAttribute(global_ldap.SearchResult,'stunnelconf');

    result:=f;

end;
//##############################################################################
function Tarticaldap.load_Kav4Samba():kav4sambaSettings;
var
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   f                        :kav4sambaSettings;
begin
result:=f;

  if not Logged then begin
     if D then writeln('load_Kav4Samba(),Logged -> false, exit...');
     exit;
  end;

  l:=TstringList.Create;
  DN:='cn=kav4samba,cn=artica,'+ldap_suffix;
  Myquery:='(&(objectclass=kav4samba))';
  global_ldap.SearchResult.Clear;

    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('load_Kav4Samba:: Failed search ' + Myquery + ' in ' + DN);
         exit(f);
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('load_Kav4Samba:: Failed search ' + Myquery + ' in ' + DN);
       exit(f);
    end;


    f.kav4sambaConf:=GetSingleAttribute(global_ldap.SearchResult,'kav4sambaConf');

    result:=f;

end;
//##############################################################################



function Tarticaldap.load_dkim_filter():dkimfilter_settings;
var
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   f                        :dkimfilter_settings;
begin
result:=f;

  if not Logged then begin
     if D then writeln('load_dkim_filter(),Logged -> false, exit...');
     exit;
  end;

  l:=TstringList.Create;
  DN:='cn=dkim-filter,cn=artica,'+ldap_suffix;
  Myquery:='(&(objectclass=DkimFilterConfig))';
  global_ldap.SearchResult.Clear;

    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('load_dkim_filter:: Failed search ' + Myquery + ' in ' + DN);
         exit(f);
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('load_dkim_filter:: Failed search ' + Myquery + ' in ' + DN);
       exit(f);
    end;


    f.DkimFilterConf:=GetSingleAttribute(global_ldap.SearchResult,'DkimFilterConf');

    result:=f;

end;
//##############################################################################
function Tarticaldap.Allowed_domains():TstringList;
var
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   f                        :TstringList;
begin
f:=TstringList.Create;
result:=f;

  if not Logged then begin
     if D then writeln('Allowed_domains(),Logged -> false, exit...');
     exit;
  end;

  l:=TstringList.Create;
  DN:=ldap_suffix;
  l.Add('associatedDomain');
  Myquery:='(objectclass=domainRelatedObject)';
  global_ldap.SearchResult.Clear;

    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Allowed_domains:: Failed search ' + Myquery + ' in ' + DN);
         exit(f);
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count>0 then begin
       f.AddStrings(GetMultipleAttributes(global_ldap.SearchResult,'associatedDomain'));
    end;
    
    
    global_ldap.SearchResult.Clear;
    l.Clear;
    l.Add('cn');
    Myquery:='(objectclass=transportTable)';
    
   if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Allowed_domains:: Failed search ' + Myquery + ' in ' + DN);
         exit(f);
    end;
    
    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count>0 then begin
       f.AddStrings(GetMultipleAttributes(global_ldap.SearchResult,'cn'));
    end;
    
    result:=f;

end;
//##############################################################################
function Tarticaldap.DotClearUsers():TstringList;
var
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   f                        :TstringList;
begin
f:=TstringList.Create;
result:=f;

  if not Logged then begin
     if D then writeln('DotClearUsers(),Logged -> false, exit...');
     exit;
  end;

  l:=TstringList.Create;
  DN:=ldap_suffix;
  l.Add('uid');
  Myquery:='(&(objectclass=ArticaSettings)(DotClearUserEnabled=1))';
  global_ldap.SearchResult.Clear;

    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('DotClearUsers:: Failed search ' + Myquery + ' in ' + DN);
         exit(f);
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count>0 then begin
       f.AddStrings(GetMultipleAttributes(global_ldap.SearchResult,'uid'));
    end;

    result:=f;

end;
//##############################################################################
function Tarticaldap.HomesUsersPath():TstringList;
var
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   f                        :TstringList;
   z                        :TstringList;
   i:Integer                ;
begin
f:=TstringList.Create;
result:=f;

  if not Logged then begin
     if D then writeln('HomesUsersPath(),Logged -> false, exit...');
     exit;
  end;

  l:=TstringList.Create;
  DN:=ldap_suffix;
  l.Add('homeDirectory');
  l.Add('uid');
  Myquery:='(&(objectclass=posixAccount)(homeDirectory=*))';
  global_ldap.SearchResult.Clear;

    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('HomesUsersPath:: Failed search ' + Myquery + ' in ' + DN);
         exit(f);
    end;

    z:=tstringlist.Create;
    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    f.AddStrings(GetMultipleAttributes(global_ldap.SearchResult,'homeDirectory'));
    z.AddStrings(GetMultipleAttributes(global_ldap.SearchResult,'uid'));

    for i:=0 to z.Count-1 do begin
        try
           f.Strings[i]:=z.Strings[i]+';'+f.Strings[i];
        except
        writeln('FATAL ERROR  Tarticaldap.HomesUsersPath() for i failed on ' + IntToStr(i));
        break;
       end;

    end;


    result:=f;

end;
//##############################################################################
function Tarticaldap.SpamAssassinAutoLearnUsers():TstringList;
var
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   f                        :TstringList;
begin
f:=TstringList.Create;
result:=f;

  if not Logged then begin
     if D then writeln('AutoLearnUsers(),Logged -> false, exit...');
     exit;
  end;

  l:=TstringList.Create;
  DN:=ldap_suffix;
  l.Add('uid');
  Myquery:='(&(objectclass=UserArticaClass)(EnableUserSpamLearning=1))';
  global_ldap.SearchResult.Clear;

    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('AutoLearnUsers:: Failed search ' + Myquery + ' in ' + DN);
         exit(f);
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count>0 then begin
       f.AddStrings(GetMultipleAttributes(global_ldap.SearchResult,'uid'));
    end;

    result:=f;

end;
//##############################################################################
function Tarticaldap.load_nmap_settings:nmap_settings;
var
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   f                        :nmap_settings;
begin
   f.NmapNetworkIP:=TstringList.Create;
   result:=f;
if not Logged then begin
     if D then writeln('load_nmap_settings(),Logged -> false, exit...');
     exit;
  end;

  l:=TstringList.Create;
  DN:=ldap_suffix;
  Myquery:='(objectclass=NmapSettings)';
  global_ldap.SearchResult.Clear;

    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('load_nmap_settings:: Failed search ' + Myquery + ' in ' + DN);
         exit(f);
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count>0 then begin
       f.NmapNetworkIP.AddStrings(GetMultipleAttributes(global_ldap.SearchResult,'NmapNetworkIP'));
    end;

    f.NmapRotateMinutes:=GetSingleAttribute(global_ldap.SearchResult,'NmapRotateMinutes');


    result:=f;

end;

//##############################################################################
function Tarticaldap.load_FDM_settings:FDM_settings;
var
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   f                        :FDM_settings;
begin
   f.FDMConf:=TstringList.Create;
   result:=f;
if not Logged then begin
     if D then writeln('load_FDM_settings(),Logged -> false, exit...');
     exit;
  end;

  l:=TstringList.Create;
  DN:=ldap_suffix;
  Myquery:='(&(objectclass=FDMClass)(FDMConf=*))';
  global_ldap.SearchResult.Clear;

    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('load_FDM_settings:: Failed search ' + Myquery + ' in ' + DN);
         exit(f);
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count>0 then begin
       f.FDMConf.AddStrings(GetMultipleAttributes(global_ldap.SearchResult,'FDMConf'));
    end;

    result:=f;

end;

//##############################################################################
function Tarticaldap.postfix_networks():TstringList;
var
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   f                        :TstringList;
begin
f:=TstringList.Create;
result:=f;

  if not Logged then begin
     if D then writeln('postfix_networks(),Logged -> false, exit...');
     exit;
  end;

  l:=TstringList.Create;
  DN:='cn=mynetworks_maps,cn=artica,'+ldap_suffix;
  l.Add('mynetworks');
  Myquery:='(objectclass=PostfixMynetworks)';
  global_ldap.SearchResult.Clear;

    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('postfix_networks:: Failed search ' + Myquery + ' in ' + DN);
         exit(f);
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count>0 then begin
       f.AddStrings(GetMultipleAttributes(global_ldap.SearchResult,'mynetworks'));
    end;


    global_ldap.SearchResult.Clear;
    result:=f;

end;
//##############################################################################
function Tarticaldap.ExistsDN(DN:string):boolean;
var
   Myquery                  :string;
   l                        :Tstringlist;
   f                        :TstringList;
begin
f:=TstringList.Create;
result:=false;
Myquery:='(objectclass=*)';
  if not Logged then begin
     if D then writeln('ExistsDN(),Logged -> false, exit...');
     exit;
  end;
  
 l:=TstringList.Create;
 if not global_ldap.Search(DN,False, Myquery, l) then begin
    if D then writeln('ExistsDN():: ',DN,' ',false);
    exit(false);
 end;
     if D then writeln('ExistsDN():: ',DN,' ',true);
     exit(true);
  
end;
//##############################################################################

function Tarticaldap.GetSingleAttribute(search:TLDAPResultList;attribute:string):string;
var
   i:integer;
   Attributes:integer;
   OrgAttribute:String;

begin

   if D then writeln('GetSingleAttribute....: Search =',search.Count,' results');
   attribute:=LowerCase(attribute);
   
   
   for i:=0 to search.Count-1 do begin
   
      if ParamStr(1)='-userinfo' then writeln(i,')' ,search.Items[i].ObjectName,' ***************************************');
      
      if attribute=LowerCase('ObjectName') then begin
         if D then writeln('GetSingleAttribute:: ObjectName query ->' +search.Items[i].ObjectName);
         result:=search.Items[i].ObjectName;
         exit;
      end;
      

      if D then writeln('GetSingleAttribute.... Search['+IntToStr(i)+'].count=',search.Items[i].Attributes.Count);
        for Attributes:=0 to search.Items[i].Attributes.Count-1 do begin
                OrgAttribute:=LowerCase(search.Items[i].Attributes[Attributes].AttributeName);
                
                if ParamStr(1)='-userinfo' then writeln(OrgAttribute,'=','"',search.Items[i].Attributes[Attributes].Strings[0],'"');
                
                if OrgAttribute=attribute then begin
                   if D then writeln('GetSingleAttribute.... search.Items['+IntToStr(i)+'].Attributes['+IntToStr(Attributes)+']=',Attribute);
                   if D then writeln('GetSingleAttribute.... search.Items['+IntToStr(i)+'].Attributes['+IntToStr(Attributes)+'][0]=',search.Items[i].Attributes[Attributes].Strings[0]);
                   result:=search.Items[i].Attributes[Attributes].Strings[0];
                end;
        end;
        
            if ParamStr(1)='-userinfo' then writeln('***************************************');
   end;
end;

//##############################################################################
function Tarticaldap.GetMultipleAttributes(search:TLDAPResultList;attribute:string):TstringList;
var
   i:integer;
   Attributes:integer;
   OrgAttribute:String;
   t:integer;
   f:TstringList;
begin
   f:=TstringList.Create;
   if D then writeln('GetMultipleAttributes....: Search =',search.Count,' results');
   attribute:=LowerCase(attribute);


   for i:=0 to search.Count-1 do begin

      if ParamStr(1)='-userinfo' then writeln(i,')' ,search.Items[i].ObjectName,' ***************************************');

      if D then writeln(i,') GetMultipleAttributes.... Search['+IntToStr(i)+'].count=',search.Items[i].Attributes.Count);
        for Attributes:=0 to search.Items[i].Attributes.Count-1 do begin
        
                OrgAttribute:=LowerCase(search.Items[i].Attributes[Attributes].AttributeName);
                if D then writeln('GetMultipleAttributes.... OrgAttribute=',OrgAttribute);

                if ParamStr(1)='-userinfo' then writeln(OrgAttribute,'=','"',search.Items[i].Attributes[Attributes].Strings[0],'"');

                if OrgAttribute=attribute then begin
                   for t:=0 to search.Items[i].Attributes[Attributes].Count -1 do begin
                       if D then writeln('GetMultipleAttributes.... search.Items['+IntToStr(i)+'].Attributes['+IntToStr(Attributes)+'][',t,']=',search.Items[i].Attributes[Attributes].Strings[t]);
                       f.Add(search.Items[i].Attributes[Attributes].Strings[t]);
                   end;
                end;
        end;
     end;
result:=f;
end;

//##############################################################################
function Tarticaldap.Load_OU_DATAS(domain:string):ou_datas;
var
   F                        :ou_datas;
   tmpstr                   :string;
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t                        :integer;
   AutoUpdateConfig         :string;
   LDAPsend                 :TLDAPsend;
   RegExpr                  :TRegExpr;
begin
 f.BOGOFILTER_PARAM.max_rate:=80;
 f.BOGOFILTER_PARAM.action:='prepend';
 f.BOGOFILTER_PARAM.prepend:='*** SPAM *** (bogo)';
 
 

 if not Logged then begin
     if D then writeln('Load_OU_DATAS(),Logged -> false, exit...');
     exit(f);
  end;
  
  l:=TstringList.Create;
  DN:=ldap_suffix;
  Myquery:='(&(objectClass=organizationalUnit)(associatedDomain='+ domain+'))';
  global_ldap.SearchResult.Clear;
  
 if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Load_OU_DATAS:: Failed search ' + Myquery + ' in ' + DN);
         exit(f);
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('Load_OU_DATAS:: Failed search ' + Myquery + ' in ' + DN);
       exit(f);
    end;
    
     tmpstr:=GetSingleAttribute(global_ldap.SearchResult,'BogoFilterAction');
     f.Organization:=GetSingleAttribute(global_ldap.SearchResult,'ou');
     
     RegExpr:=TRegExpr.Create;
     RegExpr.Expression:='([0-9\.]+);(.+?);(.+)';

     if RegExpr.Exec(tmpstr) then begin
         f.BOGOFILTER_PARAM.max_rate:=StrToInt(RegExpr.Match[1]);
         f.BOGOFILTER_PARAM.action:=RegExpr.Match[2];
         f.BOGOFILTER_PARAM.prepend:=RegExpr.Match[3];
     end;
     
     exit(f);
     
end;
//##############################################################################

function Tarticaldap.Load_userasdatas(uid:string):users_datas;
var
   F                        :users_datas;
   tmpstr                   :string;
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t                        :integer;
   AutoUpdateConfig         :string;
   LDAPsend                 :TLDAPsend;
   RegExpr                  :TRegExpr;
begin

f.bightml.BigMailHtmlRules:=TstringList.Create;
f.HtmlBackup.ArticaBackupRules:=TstringList.Create;
f.BOGOFILTER_PARAM.max_rate:=80;
f.BOGOFILTER_PARAM.action:='prepend';
f.BOGOFILTER_PARAM.prepend:='*** SPAM *** (bogo)';
f.uid:=uid;
result:=f;

  if not Logged then begin
     if D then writeln('Load_artica_main_settings(),Logged -> false, exit...');
     exit(f);
  end;


  l:=TstringList.Create;
  DN:=ldap_suffix;
  Myquery:='(uid='+ uid+')';
  global_ldap.SearchResult.Clear;



    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Load_userasdatas:: Failed search ' + Myquery + ' in ' + DN);
         exit(f);
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('Load_userasdatas:: Failed search ' + Myquery + ' in ' + DN);
       global_ldap.SearchResult.Clear;
       exit(f);
    end;

          f.MailBoxMaxSize:=GetSingleAttribute(global_ldap.SearchResult,'MailBoxMaxSize');
          f.FTPDownloadBandwidth:=  GetSingleAttribute(global_ldap.SearchResult,'FTPDownloadBandwidth');
          f.FTPDownloadRatio:=GetSingleAttribute(global_ldap.SearchResult,'FTPDownloadRatio');
          f.FTPQuotaFiles:=GetSingleAttribute(global_ldap.SearchResult,'FTPQuotaFiles');
          f.FTPQuotaMBytes:=GetSingleAttribute(global_ldap.SearchResult,'FTPQuotaMBytes');
          f.homeDirectory:=GetSingleAttribute(global_ldap.SearchResult,'homeDirectory');
          f.userPassword:=GetSingleAttribute(global_ldap.SearchResult,'userPassword');
          f.FTPUploadBandwidth:=GetSingleAttribute(global_ldap.SearchResult,'FTPUploadBandwidth');
          f.FTPUploadRatio:=GetSingleAttribute(global_ldap.SearchResult,'FTPUploadRatio');
          f.dn:=GetSingleAttribute(global_ldap.SearchResult,'ObjectName');
          f.mail:=GetSingleAttribute(global_ldap.SearchResult,'mail');
          f.RecipientToAdd:=GetSingleAttribute(global_ldap.SearchResult,'RecipientToAdd');
          f.BOGOFILTER_PARAM.BogoFilterMailType:=GetSingleAttribute(global_ldap.SearchResult,'BogoFilterMailType');
          f.MailboxSecurityParameters:=GetSingleAttribute(global_ldap.SearchResult,'MailboxSecurityParameters');
          f.AllowedSMTPTroughtInternet:=GetSingleAttribute(global_ldap.SearchResult,'AllowedSMTPTroughtInternet');
          f.EnableUserSpamLearning:=GetSingleAttribute(global_ldap.SearchResult,'EnableUserSpamLearning');
          
          
          F.ComputerInfos.computerip:=GetSingleAttribute(global_ldap.SearchResult,'ComputerIP');
          F.ComputerInfos.mac:=GetSingleAttribute(global_ldap.SearchResult,'ComputerMacAddress');
          

  RegExpr:=TRegExpr.Create;
  RegExpr.Expression:=',ou=(.+?),';
  RegExpr.Exec(f.dn);
  f.Organization:=RegExpr.Match[1];
  if ParamStr(1)='-userinfo' then writeln('Organization=',f.Organization);
  global_ldap.SearchResult.Clear;
  


  DN:='cn=html_blocker,ou=' + f.Organization+','+ldap_suffix;
  Myquery:='(ObjectClass=ArticaOuBigMailHTML)';
 
  if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Load_userasdatas:: Failed search ' + Myquery + ' in ' + DN);
         exit(f);
    end;
    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('Load_userasdatas:: Failed search ' + Myquery + ' in ' + DN);
       exit(f);
    end;
  
  f.bightml.BigMailHtmlConfig:=GetSingleAttribute(global_ldap.SearchResult,'BigMailHtmlConfig');
  f.bightml.BigMailHTMLEnabled:=GetSingleAttribute(global_ldap.SearchResult,'BigMailHTMLEnabled');
  f.bightml.BigMailHtmlBody:=GetSingleAttribute(global_ldap.SearchResult,'BigMailHtmlBody');
  f.bightml.BigMailHtmlRules.AddStrings(GetMultipleAttributes(global_ldap.SearchResult,'BigMailHtmlRules'));


  DN:='cn=backup-config,ou=' + f.Organization+','+ldap_suffix;
  Myquery:='(ObjectClass=OrganizationBackupSettings)';

  if global_ldap.Search(DN, False, Myquery, l) then begin
     if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
     if global_ldap.SearchResult.Count>0 then begin
          if D then writeln('Load_userasdatas:: Failed search ' + Myquery + ' in ' + DN);
          f.HtmlBackup.BackupEnabled:=GetSingleAttribute(global_ldap.SearchResult,'BackupEnabled');;
          f.HtmlBackup.ArticaBackupRules.AddStrings(GetMultipleAttributes(global_ldap.SearchResult,'ArticaBackupRules'));
     end;
  end;
    
    
 // ----------------------------------------------------------------------------------------------------------------
    
    
     global_ldap.SearchResult.Clear;
     DN:='ou=' + f.Organization+','+ldap_suffix;
     Myquery:='(ObjectClass=organizationalUnit)';
  if global_ldap.Search(DN, False, Myquery, l) then begin
     if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
     if global_ldap.SearchResult.Count>0 then begin
          if D then writeln('Load_userasdatas:: Failed search ' + Myquery + ' in ' + DN);
          tmpstr:=GetSingleAttribute(global_ldap.SearchResult,'BogoFilterAction');
          RegExpr:=TRegExpr.Create;
          RegExpr.Expression:='([0-9\.]+);(.+?);(.+)';
          if RegExpr.Exec(tmpstr) then begin
             f.BOGOFILTER_PARAM.max_rate:=StrToInt(RegExpr.Match[1]);
             f.BOGOFILTER_PARAM.action:=RegExpr.Match[2];
             f.BOGOFILTER_PARAM.prepend:=RegExpr.Match[3];
          end;
     end;
  end;
    

     if ParamStr(1)='-userinfo' then begin
          for i:=0 to  f.bightml.BigMailHtmlRules.Count-1 do begin
          
              writeln('BigMailHtmlRules=' +f.bightml.BigMailHtmlRules.Strings[i]);
          end;
         writeln('BOGOFILTER_PARAM.max_rate=' ,f.BOGOFILTER_PARAM.max_rate);
         writeln('BOGOFILTER_PARAM.action=' ,f.BOGOFILTER_PARAM.action);
         writeln('BOGOFILTER_PARAM.prepend=' ,f.BOGOFILTER_PARAM.prepend);
      end;
      
      
      
      

  
result:=f;
global_ldap.SearchResult.Clear;
end;
//##############################################################################




function Tarticaldap.Load_amavis_main_settings():amavis_settings;
var
   F                        :amavis_settings;
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
begin

result:=f;

  if not Logged then begin
     if D then writeln('Logged -> false, exit...');
     exit;
  end;

l:=TstringList.Create;
  DN:='cn=amavis,cn=artica,' + ldap_suffix;
  Myquery:='(objectClass=AmavisGlobalSettings)';


    if not global_ldap.Search(DN, False, Myquery, l) then begin
         logs.Debuglogs('Load_amavis_main_settings:: Failed search ' + Myquery + ' in ' + DN);
         exit;
    end;


    logs.Debuglogs('Load_amavis_main_settings():: '+Myquery+ ' count :'+IntToStr(global_ldap.SearchResult.Count));
    if global_ldap.SearchResult.Count=0 then begin
       logs.Debuglogs('Load_amavis_main_settings:: Failed search ' + Myquery + ' in ' + DN);
       exit;
    end;
    f.AmavisConfigFile:=GetSingleAttribute(global_ldap.SearchResult,'AmavisConfigFile');

    result:=f;

end;
//
//##############################################################################
function Tarticaldap.Load_mailfromd_settings():mailfromd_settings;
var
   F                        :mailfromd_settings;
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t                        :integer;
begin
result:=f;

  if not Logged then begin
     if D then writeln('Logged -> false, exit...');
     exit;
  end;

l:=TstringList.Create;
  DN:='cn=mailfromd,cn=artica,' + ldap_suffix;
  Myquery:='(objectClass=mailfromd)';


    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Load_mailfromd_settings:: Failed search ' + Myquery + ' in ' + DN);
         exit;
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('Load_mailfromd_settings:: Failed search ' + Myquery + ' in ' + DN);
       exit;
    end;


    for i:=0 to global_ldap.SearchResult.Count -1 do begin
         f.MailFromdRC:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'MailFromdRC');
         f.MailFromdUserUpdated:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'MailFromdUserUpdated');
         f.MailFromdUserScript:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'MailFromdUserScript');
     end;

    result:=f;

end;
//#############################################################################
function Tarticaldap.Load_mimedefang():mimedefang_settings;
var
   F                        :mimedefang_settings;
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t                        :integer;
begin

result:=f;

  if not Logged then begin
     if D then writeln('Logged -> false, exit...');
     exit;
  end;

l:=TstringList.Create;
  DN:='cn=mimedefang,cn=artica,' + ldap_suffix;
  Myquery:='(objectClass=MimeDefangClass)';


    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Load_mimedefang:: Failed search ' + Myquery + ' in ' + DN);
         exit;
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('Load_mimedefang:: Failed search ' + Myquery + ' in ' + DN);
       exit;
    end;


    for i:=0 to global_ldap.SearchResult.Count -1 do begin
        f.MimeDefangFilter:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'MimeDefangFilter');
     end;

    result:=f;

end;


//##############################################################################
function Tarticaldap.Load_samba():samba_settings;
var
   F                        :samba_settings;
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t                        :integer;
begin

result:=f;

  if not Logged then begin
     if D then writeln('Logged -> false, exit...');
     exit;
  end;

l:=TstringList.Create;
  DN:='cn=samba-config,cn=artica,' + ldap_suffix;
  Myquery:='(objectClass=SambaArticaClass)';


    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Load_samba:: Failed search ' + Myquery + ' in ' + DN);
         exit;
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('Load_samba:: Failed search ' + Myquery + ' in ' + DN);
       exit;
    end;


    for i:=0 to global_ldap.SearchResult.Count -1 do begin
        f.SambaSMBConf:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'SambaSMBConf');
        f.SambaUsbShare:=GetSingleAttribute(global_ldap.SearchResult,'SambaUsbShare');
     end;

    result:=f;

end;
//#############################################################################
function Tarticaldap.Load_spamassassin():spamassassin_settings;
var
   F                        :spamassassin_settings;
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t                        :integer;
begin

result:=f;

  if not Logged then begin
     if D then writeln('Logged -> false, exit...');
     exit;
  end;

l:=TstringList.Create;
  DN:='cn=spamassassin,cn=artica,' + ldap_suffix;
  Myquery:='(objectClass=SpamAssassinClass)';


    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Load_spamassassin:: Failed search ' + Myquery + ' in ' + DN);
         exit;
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('Load_spamassassin:: Failed search ' + Myquery + ' in ' + DN);
       exit;
    end;


    for i:=0 to global_ldap.SearchResult.Count -1 do begin
        f.SpamAssassinConfFile:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'SpamAssassinConfFile');
     end;

    result:=f;

end;
//#############################################################################

function Tarticaldap.Load_KasGroupsList():TstringList;
var
   F                        :TstringList;
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t                        :integer;
   att                      :TLDAPAttributeList;
begin
f:=TstringList.Create;
result:=f;

  if not Logged then begin
     if D then writeln('Logged -> false, exit...');
     exit;
  end;

l:=TstringList.Create;
l.Add('cn');
  DN:=ldap_suffix;
  Myquery:='(objectClass=KasFiles)';


    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Load_KasGroupsList:: Failed search ' + Myquery + ' in ' + DN);
         exit;
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('Load_KasGroupsList:: Failed search ' + Myquery + ' in ' + DN);
       exit;
    end;


    for i:=0 to global_ldap.SearchResult.Count -1 do begin
        att:=global_ldap.SearchResult.Items[i].Attributes;
        for t:= 0 to att.Count-1 do begin
            if LowerCase(att.Items[t].AttributeName)=LowerCase('cn') then begin
                    f.Add(att.Items[t].Strings[0]);
            end;
        end;

     end;

    result:=f;

end;


//#############################################################################
function Tarticaldap.Load_KavMilter_settings():KavMilter_settings;
var
   F                        :KavMilter_settings;
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t                        :integer;
   att                      :TLDAPAttributeList;
begin
result:=f;

  if not Logged then begin
     if D then writeln('Logged -> false, exit...');
     exit;
  end;

l:=TstringList.Create;
  DN:='cn=kavmilterd,cn=artica,'+ldap_suffix;
  Myquery:='(objectClass=ArticaKavMilterd)';


    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Load_KavMilter_settings:: Failed search ' + Myquery + ' in ' + DN);
         exit;
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('Load_KavMilter_settings:: Failed search ' + Myquery + ' in ' + DN);
       exit;
    end;


    for i:=0 to global_ldap.SearchResult.Count -1 do begin
        att:=global_ldap.SearchResult.Items[i].Attributes;
        for t:= 0 to att.Count-1 do begin
            if LowerCase(att.Items[t].AttributeName)=LowerCase('kavmilterEnable') then begin
                    f.kavmilterEnable:=att.Items[t].Strings[0];
            end;
        end;

     end;

    result:=f;

end;
//#############################################################################
function Tarticaldap.Load_KasGroupDatas(gidnumber:string):kas_groups;
 var
   F                        :kas_groups;
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t                        :integer;
   att                      :TLDAPAttributeList;
   D                        :boolean;
begin
result:=f;
D:=COMMANDLINE_PARAMETERS('debug');
  if not Logged then begin
     if D then writeln('Logged -> false, exit...');
     exit;
  end;

l:=TstringList.Create;
  DN:='cn='+gidnumber+',cn=kaspersky Antispam 3 rules,cn=artica,'+ldap_suffix;
  Myquery:='(objectClass=KasFiles)';


    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Load_KasGroupDatas:: Failed search ' + Myquery + ' in ' + DN);
         exit;
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('Load_KasGroupDatas:: Failed search ' + Myquery + ' in ' + DN);
       exit;
    end;


    for i:=0 to global_ldap.SearchResult.Count -1 do begin
        att:=global_ldap.SearchResult.Items[i].Attributes;
        for t:= 0 to att.Count-1 do begin
            if D then writeln(t,'->',att.Items[t].AttributeName);
            if LowerCase(att.Items[t].AttributeName)=LowerCase('KasHexGroupName') then f.KasHexGroupName:=att.Items[t].Strings[0];
            if LowerCase(att.Items[t].AttributeName)=LowerCase('kasactiondef') then f.kasactiondef:=att.Items[t].Strings[0];
            if LowerCase(att.Items[t].AttributeName)=LowerCase('kasallowxml') then f.kasallowxml:=att.Items[t].Strings[0];
            if LowerCase(att.Items[t].AttributeName)=LowerCase('kasdenyxml') then f.kasdenyxml:=att.Items[t].Strings[0];
            if LowerCase(att.Items[t].AttributeName)=LowerCase('kasipallowxml') then f.kasipallowxml:=att.Items[t].Strings[0];
            if LowerCase(att.Items[t].AttributeName)=LowerCase('kasipdenyxml') then f.kasipdenyxml:=att.Items[t].Strings[0];
            if LowerCase(att.Items[t].AttributeName)=LowerCase('kasmembersxml') then f.kasmembersxml:=att.Items[t].Strings[0];
            if LowerCase(att.Items[t].AttributeName)=LowerCase('kasprofilexml') then f.kasprofilexml:=att.Items[t].Strings[0];
            if LowerCase(att.Items[t].AttributeName)=LowerCase('kasruledef') then f.kasruledef:=att.Items[t].Strings[0];
        end;

     end;

    result:=f;


end;

function Tarticaldap.Load_backup_settings():backup_settings;
var
   F                        :backup_settings;
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t                        :integer;
begin

result:=f;

  if not Logged then begin
     if D then writeln('Logged -> false, exit...');
     exit;
  end;

l:=TstringList.Create;
  DN:='cn=artica-backup,cn=artica,' + ldap_suffix;
  Myquery:='(objectClass=ArticaBackup)';


    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Load_backup_settings:: Failed search ' + Myquery + ' in ' + DN);
         exit;
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('Load_backup_settings:: Failed search ' + Myquery + ' in ' + DN);
       exit;
    end;


    for i:=0 to global_ldap.SearchResult.Count -1 do begin
        f.ArticaBackupConf:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'ArticaBackupConf');
        f.ArticaBackupEnabled:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'ArticaBackupEnabled');
        f.HdBackupConfig:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'HdBackupConfig');
        f.MountBackupConfig:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'MountBackupConfig');
     end;

    result:=f;

end;
//#############################################################################



function Tarticaldap.Load_iptables_settings():iptables_settings;
var
   F                        :iptables_settings;
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t                        :integer;
begin

result:=f;

  if not Logged then begin
     if D then writeln('Logged -> false, exit...');
     exit;
  end;

l:=TstringList.Create;
  DN:='cn=iptables,cn=artica,' + ldap_suffix;
  Myquery:='(objectClass=iptables)';


    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Load_iptables_settings:: Failed search ' + Myquery + ' in ' + DN);
         exit;
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('Load_iptables_settings:: Failed search ' + Myquery + ' in ' + DN);
       exit;
    end;


    for i:=0 to global_ldap.SearchResult.Count -1 do begin
        f.iptablesFile:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'iptablesFile');
     end;

    result:=f;

end;
//#############################################################################


function Tarticaldap.Load_miltergreylist():miltergreylist_settings;
var
   F                        :miltergreylist_settings;
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t                        :integer;
begin
;
result:=f;

  if not Logged then begin
     if D then writeln('Logged -> false, exit...');
     exit;
  end;

l:=TstringList.Create;
  DN:='cn=milter-greyist,cn=artica,' + ldap_suffix;
  Myquery:='(objectClass=MilterGreyList)';


    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Load_miltergreylist:: Failed search ' + Myquery + ' in ' + DN);
         exit;
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('Load_miltergreylist:: Failed search ' + Myquery + ' in ' + DN);
       exit;
    end;


    for i:=0 to global_ldap.SearchResult.Count -1 do begin
        f.GreyListConf:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'GreyListConf');
        f.MilterGreyListEnabled:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'MilterGreyListEnabled');
     end;

    result:=f;

end;
//#############################################################################
function Tarticaldap.Load_OBM_SETTINGS():obm_settings;
var
   F                        :obm_settings;
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t                        :integer;
begin
;
result:=f;

  if not Logged then begin
     if D then writeln('Load_OBM_SETTINGS:: Logged -> false, exit...');
     exit;
  end;

l:=TstringList.Create;
  DN:='cn=obm,cn=artica,' + ldap_suffix;
  Myquery:='(objectClass=OBMSystem)';


    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Load_OBM_SETTINGS:: Failed search ' + Myquery + ' in ' + DN);
         exit;
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('Load_OBM_SETTINGS:: Failed search ' + Myquery + ' in ' + DN);
       exit;
    end;


    for i:=0 to global_ldap.SearchResult.Count -1 do begin
        f.OBMApacheFile:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'OBMApacheFile');
        f.OBMConfIni:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'OBMConfIni');
        f.OBMConfInc:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'OBMConfInc');
     end;

    result:=f;

end;
//#############################################################################
function Tarticaldap.Load_ORGANISATION(ORG:string):ou_datas;
var
   F                        :ou_datas;
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t                        :integer;
begin
;
result:=f;

  if not Logged then begin
     if D then writeln('Load_ORGANISATION:: Logged -> false, exit...');
     exit;
  end;

  l:=TstringList.Create;
  DN:='cn=adlinker,ou='+ORG+',' + ldap_suffix;
  Myquery:='(objectClass=AdLinker)';


    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Load_ORGANISATION:: Failed search ' + Myquery + ' in ' + DN);
         exit;
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('Load_ORGANISATION:: Failed search ' + Myquery + ' in ' + DN);
       exit;
    end;
    f.AdLinkerConf:=GetSingleAttribute(global_ldap.SearchResult,'AdLinkerConf');
    result:=f;

end;
//#############################################################################


function Tarticaldap.Load_crossroads_main_settings():crossroads_settings;
var
   F                        :crossroads_settings;
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t                        :integer;
begin
result:=f;
f.PostfixSlaveServersIdentity:=Tstringlist.Create;
  if not Logged then begin
     if D then writeln('Logged -> false, exit...');
     exit;
  end;

l:=TstringList.Create;
  DN:='cn=artica,' + ldap_suffix;
  Myquery:='(objectClass=BalancePostfixServers)';


    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Load_crossroads_main_settings:: Failed search ' + Myquery + ' in ' + DN);
         exit;
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('Load_crossroads_main_settings:: Failed search ' + Myquery + ' in ' + DN);
       exit;
    end;

    for i:=0 to global_ldap.SearchResult.Count -1 do begin
         f.PostfixMasterServerIdentity:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'PostfixMasterServerIdentity');
         f.CrossRoadsBalancingServerIP:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'CrossRoadsBalancingServerIP');
         F.CrossRoadsBalancingServerName:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'CrossRoadsBalancingServerName');
         F.CrossRoadsPoolingTime:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'CrossRoadsPoolingTime');
         F.PostfixSlaveServersIdentity.AddStrings(SearchMultipleAttribute(global_ldap.SearchResult,'PostfixSlaveServersIdentity'));

     end;
    if length(F.CrossRoadsPoolingTime)=0 then F.CrossRoadsPoolingTime:='300';
    result:=f;

end;
//##############################################################################
function Tarticaldap.Load_postfix_main_settings():postfix_settings;
var
   F                        :postfix_settings;
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t                        :integer;
begin
result:=f;
  if not Logged then begin
     if D then writeln('Logged -> false, exit...');
     exit;
  end;

l:=TstringList.Create;
  DN:='cn=PostfixFilesStorage,cn=artica,' + ldap_suffix;
  Myquery:='(objectClass=PostfixStoreFiles)';


    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Load_postfix_main_settings:: Failed search ' + Myquery + ' in ' + DN);
         exit;
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('Load_postfix_main_settings:: Failed search ' + Myquery + ' in ' + DN);
       exit;
    end;

    for i:=0 to global_ldap.SearchResult.Count -1 do begin
         f.PostfixBounceTemplateFile:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'PostfixBounceTemplateFile');
         f.PostfixMainCfFile:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'PostfixMainCfFile');
         f.PostfixTimeCode:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'PostfixTimeCode');
         f.PostFixHeadersRegexFile:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'PostFixHeadersRegexFile');
         f.PostfixMasterCfFile:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'PostfixMasterCfFile');
     end;
    if D then writeln('Load_postfix_main_settings:: PostfixTimeCode=' +  f.PostfixTimeCode);
    result:=f;

end;
//##############################################################################
function Tarticaldap.Load_squidnewbee_settings():string;
var
   F                        :fetchmail_settings;
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t                        :integer;
begin
  result:='';
  if not Logged then begin
     if D then writeln('Logged -> false, exit...');
     exit;
  end;
  l:=TstringList.Create;
  DN:='cn=squid-config,cn=artica,' + ldap_suffix;
  Myquery:='(objectClass=SquidProxyClass)';


    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Load_squidnewbee_settings:: Failed search ' + Myquery + ' in ' + DN);
         exit;
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('Load_squidnewbee_settings:: Failed search ' + Myquery + ' in ' + DN);
       exit;
    end;


    for i:=0 to global_ldap.SearchResult.Count -1 do begin
         result:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'GlobalSquidConf');
     end;

end;
//##############################################################################
function Tarticaldap.Load_squidnewbee_SquidBlockSites():string;
var
   F                        :fetchmail_settings;
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t                        :integer;
begin
  result:='';
  if not Logged then begin
     if D then writeln('Logged -> false, exit...');
     exit;
  end;
  l:=TstringList.Create;
  DN:='cn=squid-config,cn=artica,' + ldap_suffix;
  Myquery:='(objectClass=SquidProxyClass)';


    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Load_squidnewbee_settings:: Failed search ' + Myquery + ' in ' + DN);
         exit;
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('Load_squidnewbee_settings:: Failed search ' + Myquery + ' in ' + DN);
       exit;
    end;


    for i:=0 to global_ldap.SearchResult.Count -1 do begin
         result:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'SquidBlockSites');
     end;

end;
//##############################################################################




function Tarticaldap.Load_squid_settings(servername:string):string;
var
   F                        :fetchmail_settings;
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t                        :integer;
begin
  result:='';
  if not Logged then begin
     if D then writeln('Logged -> false, exit...');
     exit;
  end;
  l:=TstringList.Create;
  DN:='cn=squid,cn=' + servername + ',cn=artica,' + ldap_suffix;
  Myquery:='(objectClass=SquidProxyClass)';


    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Load_squid_settings:: Failed search ' + Myquery + ' in ' + DN);
         exit;
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('Load_squid_settings:: Failed search ' + Myquery + ' in ' + DN);
       exit;
    end;


    for i:=0 to global_ldap.SearchResult.Count -1 do begin
         result:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'GlobalSquidConf');
     end;

end;
//##############################################################################
function Tarticaldap.Load_sqlgrey_settings(servername:string):sqlgrey_settings;
var
   F                        :fetchmail_settings;
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t                        :integer;
   z                        :sqlgrey_settings;
   SqlGreyEnabled           :string;
begin

  if not Logged then begin
     if D then writeln('Logged -> false, exit...');
     exit;
  end;
  l:=TstringList.Create;
  DN:='cn=sqlgrey,cn=' + servername + ',cn=artica,' + ldap_suffix;
  Myquery:='(objectClass=SqlGreyClass)';


    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Load_sqlgrey_settings:: Failed search ' + Myquery + ' in ' + DN);
         exit;
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('Load_sqlgrey_settings:: Failed search ' + Myquery + ' in ' + DN);
       exit;
    end;


    for i:=0 to global_ldap.SearchResult.Count -1 do begin

         SqlGreyEnabled:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'SqlGreyEnabled');
         z.SqlGreyConf:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'SqlGreyConf');
         z.SqlGreyTimeCode:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'SqlGreyTimeCode');
     end;

     if length(SqlGreyEnabled)=0 then SqlGreyEnabled:='0';
     z.SqlGreyEnabled:=StrToInt(SqlGreyEnabled);
     result:=z;
end;
//##############################################################################


function Tarticaldap.pureftpd_settings(servername:string):string;
var
   F                        :fetchmail_settings;
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t                        :integer;
begin
  result:='';
  if not Logged then begin
     if D then writeln('Logged -> false, exit...');
     exit;
  end;
  l:=TstringList.Create;
  DN:='cn=pure-ftpd,cn=' + servername + ',cn=artica,' + ldap_suffix;
  Myquery:='(objectClass=PureFtpdClass)';


    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('pureftpd_settings:: Failed search ' + Myquery + ' in ' + DN);
         exit;
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('pureftpd_settings:: Failed search ' + Myquery + ' in ' + DN);
       exit;
    end;


    for i:=0 to global_ldap.SearchResult.Count -1 do begin
         result:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'PureFtpdConf');
     end;

end;
//##############################################################################
procedure Tarticaldap.Load_ftp_users();
var
   F                        :fetchmail_settings;
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t                        :integer;
   u                        :integer;
   user                     :users_datas;
   linz                     :string;
   global_Search            : TLDAPsend;
   UserList                 :TstringList;
   value_result,uid,FTPDownloadBandwidth,FTPDownloadRatio,FTPQuotaFiles,FTPQuotaMBytes,FTPUploadBandwidth,FTPUploadRatio,homeDirectory,userPassword             :string;
begin

  if not Logged then begin
     if D then writeln('Logged -> false, exit...');
     exit;
  end;
  l:=TstringList.Create;
  ftplist:=TstringList.Create;
  DN:=ldap_suffix;
  Myquery:='(&(objectClass=PureFTPdUser)(FTPStatus=TRUE))';

l.Add('uid');



    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Load_ftp_users:: Failed search ' + Myquery + ' in ' + DN);
         exit;
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('Load_ftp_users:: Failed search ' + Myquery + ' in ' + DN);
       exit;
    end;

    global_Search:=TLDAPsend.Create;
    global_Search:=global_ldap;


 UserList:=TstringList.Create;
for i:=0 to global_Search.SearchResult.Count -1 do begin
       for t:=0 to global_Search.SearchResult.Items[i].Attributes.Count -1 do begin
                AttributeNameQ:=LowerCase(global_Search.SearchResult.Items[i].Attributes[t].AttributeName);
                if AttributeNameQ='uid' then begin
                  UserList.Add(global_Search.SearchResult.Items[i].Attributes.Items[t].Strings[0]);
                end;
        end;
     end;


for i:=0 to UserList.Count-1 do begin
    uid:=UserList.Strings[i];
    user:=Load_userasdatas(uid);

                      homeDirectory:=user.homeDirectory;
                      FTPDownloadBandwidth:=user.FTPDownloadBandwidth;
                      FTPDownloadRatio:=user.FTPDownloadRatio;
                      FTPQuotaFiles:=user.FTPQuotaFiles;
                      FTPQuotaMBytes:=user.FTPQuotaMBytes;
                      FTPUploadBandwidth:=user.FTPUploadBandwidth;
                      FTPUploadRatio:=user.FTPUploadRatio;
                      userPassword:=user.userPassword;

                       if length(FTPDownloadBandwidth)=0 then FTPDownloadBandwidth:='0';
                       if length(FTPDownloadRatio)=0 then FTPDownloadRatio:='0';
                       if length(FTPQuotaFiles)=0 then FTPQuotaFiles:='0';
                       if length(FTPQuotaMBytes)=0 then FTPQuotaMBytes:='0';
                       if length(FTPUploadBandwidth)=0 then FTPUploadBandwidth:='0';
                       if length(FTPUploadRatio)=0 then FTPUploadRatio:='0';
                       if length(homeDirectory)=0 then homeDirectory:='/home/' + uid;

                       if FTPDownloadBandwidth='none' then FTPDownloadBandwidth:='0';
                       if FTPDownloadRatio='none' then FTPDownloadRatio:='0';
                       if FTPQuotaFiles='none' then FTPQuotaFiles:='0';
                       if FTPQuotaMBytes='none' then FTPQuotaMBytes:='0';
                       if FTPUploadBandwidth='none' then FTPUploadBandwidth:='0';
                       if FTPUploadRatio='none' then FTPUploadRatio:='0';
                       if homeDirectory='non' then homeDirectory:='/home/' + uid;
                       if homeDirectory='none' then homeDirectory:='/home/' + uid;

                       linz:='(echo '+userPassword+';echo '+userPassword+') |';
                       linz:=linz + '<pwdpath> useradd '+ uid;
                       linz:=linz + ' -u ftpuser -g ftpuser -d '+ homeDirectory;


                       if StrToInt(FTPDownloadBandwidth)>0 then linz:=linz + ' -t '+ FTPDownloadBandwidth;
                       if StrToInt(FTPUploadBandwidth)>0 then linz:=linz + ' -T '+ FTPUploadBandwidth;
                       if StrToInt(FTPQuotaFiles)>0 then linz:=linz + ' -n '+ FTPQuotaFiles;
                       if StrToInt(FTPQuotaMBytes)>0 then linz:=linz + ' -N '+ FTPQuotaMBytes;
                       if StrToInt(FTPUploadRatio)>0 then linz:=linz + ' -q '+ FTPUploadRatio;
                       if StrToInt(FTPDownloadRatio)>0 then linz:=linz + ' -Q '+ FTPDownloadRatio;
                       ftplist.Add(linz);
end;
     
     
     
end;
//##############################################################################


function Tarticaldap.Load_Dansguardian_MainConfiguration():dansguardian_settings;
var
   F                        :dansguardian_settings;
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t                        :integer;
begin
  result:=F;
  if not Logged then begin
     if D then writeln('Logged -> false, exit...');
     exit;
  end;
  l:=TstringList.Create;
  DN:='cn=dansguardian,cn=artica,' + ldap_suffix;
  Myquery:='(objectClass=DansGuardianConf)';


    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Load_Dansguardian_MainConfiguration:: Failed search ' + Myquery + ' in ' + DN);
         exit;
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('Load_Dansguardian_MainConfiguration:: Failed search ' + Myquery + ' in ' + DN);
       exit;
    end;

    F.DansGuardianRulesIndex:=TstringList.Create;
    F.DansGuardianRulesIndex.AddStrings(SearchMultipleAttribute(global_ldap.SearchResult,'DansGuardianRulesIndex'));



    for i:=0 to global_ldap.SearchResult.Count -1 do begin
         F.DansGuardianMasterConf:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'DansGuardianMasterConf');
         F.FilterGroupListConf:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'FilterGroupListConf');
    end;



     result:=F;

end;
//##############################################################################
function Tarticaldap.Load_Dansguardian_fileconfig(ruleindex:string;attribute:string):string;
var
   F                        :fetchmail_settings;
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t                        :integer;
begin
  result:='';
  if not Logged then begin
     if D then writeln('Logged -> false, exit...');
     exit;
  end;
  l:=TstringList.Create;
  DN:='cn=' + ruleindex + ',cn=dansguardian,cn=artica,' + ldap_suffix;
  Myquery:='(objectClass=DansGuardianRules)';


    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Load_Dansguardian_fileconfig:: Failed search ' + Myquery + ' in ' + DN);
         exit;
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('Load_Dansguardian_fileconfig:: Failed search ' + Myquery + ' in ' + DN);
       exit;
    end;


    for i:=0 to global_ldap.SearchResult.Count -1 do begin
         result:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,attribute);
     end;

end;
//##############################################################################
function  Tarticaldap.Load_Dansguardian_categories(ruleindex:string):TstringList;
var
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t                        :integer;
   p                        :TstringList;

begin
  p:=TstringList.Create;
  result:=p;
  if not Logged then begin
     if D then writeln('Load_Dansguardian_categories:: Logged -> false, exit...');
     exit;
  end;

  l:=TstringList.Create;
  DN:='cn=' + ruleindex + ',cn=dansguardian,cn=artica,' + ldap_suffix;
  Myquery:='(objectClass=DansGuardianRules)';


    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Load_Dansguardian_categories:: Failed search ' + Myquery + ' in ' + DN);
         exit;
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('Load_Dansguardian_categories:: Failed search ' + Myquery + ' in ' + DN);
       exit;
    end;


    P.AddStrings(SearchMultipleAttribute(global_ldap.SearchResult,'DansGuardianCategories'));
    result:=P;
end;
//##############################################################################
function  Tarticaldap.Load_Dansguardian_BannedPhraseList(ruleindex:string):TstringList;
var
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t                        :integer;
   p                        :TstringList;

begin
  p:=TstringList.Create;
  result:=p;
  if not Logged then begin
     if D then writeln('Load_Dansguardian_BannedPhraseList:: Logged -> false, exit...');
     exit;
  end;

  l:=TstringList.Create;
  DN:='cn=' + ruleindex + ',cn=dansguardian,cn=artica,' + ldap_suffix;
  Myquery:='(objectClass=DansGuardianRules)';


    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Load_Dansguardian_BannedPhraseList:: Failed search ' + Myquery + ' in ' + DN);
         exit;
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('Load_Dansguardian_BannedPhraseList:: Failed search ' + Myquery + ' in ' + DN);
       exit;
    end;


    P.AddStrings(SearchMultipleAttribute(global_ldap.SearchResult,'DansGuardianCategoriesBannedPhraseList'));
    result:=P;
end;
//##############################################################################


function Tarticaldap.Load_Fetchmail_settings():fetchmail_settings;
var
   F                        :fetchmail_settings;
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t                        :integer;
begin
  result:=F;
  if not Logged then begin
     if D then writeln('Logged -> false, exit...');
     exit;
  end;
  
  
if SYS.GET_INFO('EnableFetchmail')='0' then begin
   if D then writeln('Load_Fetchmail_settings:: Fetchmail is disabled.. Abort');
   exit;
end;

  
  l:=TstringList.Create;
  DN:='cn=fetchmail,cn=artica,' + ldap_suffix;
  Myquery:='(objectClass=ArticaFetchmail)';


    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Load_Fetchmail_settings:: Failed search ' + Myquery + ' in ' + DN);
         exit;
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('Load_Fetchmail_settings:: Failed search ' + Myquery + ' in ' + DN);
       exit;
    end;


    for i:=0 to global_ldap.SearchResult.Count -1 do begin
         F.fetchmailrc:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'fetchmailrc');
         F.FetchGetLive:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'FetchGetLive');
     end;
     result:=F;
end;
//##############################################################################
function Tarticaldap.samba_group_sid_from_gid(gid:string):string;
var
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t                        :integer;
begin
  result:='';
  if not Logged then begin
     if D then writeln('Logged -> false, exit...');
     exit;
  end;
  l:=TstringList.Create;
  l.Add('sambaSID');
  DN:=ldap_suffix;
  Myquery:='(&(objectClass=sambaGroupMapping)(gidNumber='+gid+'))';


    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then logs.Debuglogs('samba_group_sid_from_gid:: Failed search ' + Myquery + ' in ' + DN);
         exit;
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then logs.Debuglogs('samba_group_sid_from_gid:: Failed search ' + Myquery + ' in ' + DN);
       exit;
    end;


   result:=GetSingleAttribute(global_ldap.SearchResult,'sambaSID');
end;
//##############################################################################
function Tarticaldap.samba_get_new_uidNumber():string;
var
   Myquery                  :string;
   DN                       :string;
   l,m                      :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t,a                      :integer;
begin
  result:='';
  if not Logged then begin
     if D then writeln('Logged -> false, exit...');
     exit;
  end;
  l:=TstringList.Create;
  l.Add('uidnumber');
  DN:=ldap_suffix;
  Myquery:='uidnumber=*';


    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then logs.Debuglogs('samba_get_new_uidNumber:: Failed search ' + Myquery + ' in ' + DN);
         exit;
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then logs.Debuglogs('samba_get_new_uidNumber:: Failed search ' + Myquery + ' in ' + DN);
       exit;
    end;
   m:=TStringlist.Create;
   a:=0;
   m.AddStrings(GetMultipleAttributes(global_ldap.SearchResult,'uidnumber'));
   for i:=0  to m.Count-1 do begin
      try
         t:=StrToInt(m.Strings[i]);
      except
      end;
      if t>a then a:=t;
   end;
   a:=a+1;
   result:=IntToStr(a);
end;
//##############################################################################
function Tarticaldap.ComputerDN_From_MAC(mac:string):string;
var
   Myquery                  :string;
   DN                       :string;
   l,m                      :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t,a                      :integer;
begin
  result:='';
  if not Logged then begin
     if D then writeln('ComputerDN_From_MAC() Logged -> false, exit...');
     exit;
  end;
  l:=TstringList.Create;

  DN:='dc=samba,'+ldap_suffix;
  Myquery:='(&(objectClass=ArticaComputerInfos)(ComputerMacAddress='+mac+'))';


    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then logs.Debuglogs('ComputerDN_From_MAC:: Failed search ' + Myquery + ' in ' + DN);
         exit;
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then logs.Debuglogs('ComputerDN_From_MAC:: Failed search ' + Myquery + ' in ' + DN);
       exit;
    end;

     exit(GetSingleAttribute(global_ldap.SearchResult,'ObjectName'))

end;
//##############################################################################




function Tarticaldap.Load_inadyn_settings():inadyn_settings;
var
   F                        :inadyn_settings;
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t                        :integer;
begin
 F.ArticaInadynPoolRule:='0';
 F.proxy_settings:=Load_proxy_settings();
 F.ArticaInadynRule:=TstringList.Create;
 result:=F;
  if not Logged then begin
     if D then writeln('Load_inadyn_settings::Logged -> false, exit...');
     exit;
  end;
  l:=TstringList.Create;
  DN:='cn=inadyn,cn=artica,' + ldap_suffix;
  Myquery:='(objectClass=ArticaInadyn)';


    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Load_inadyn_settings:: Failed search ' + Myquery + ' in ' + DN);
         exit;
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('Load_inadyn_settings:: Failed search ' + Myquery + ' in ' + DN);
       exit;
    end;

    F.ArticaInadynRule.AddStrings(SearchMultipleAttribute(global_ldap.SearchResult,'ArticaInadynRule'));

    for i:=0 to global_ldap.SearchResult.Count -1 do begin
         F.ArticaInadynPoolRule:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'ArticaInadynPoolRule');

     end;
     result:=F;

end;


//##############################################################################
function Tarticaldap.Load_Kav4proxy_settings():string;
var
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t                        :integer;
begin


 result:='';
  if not Logged then begin
     if D then writeln('Logged -> false, exit...');
     exit;
  end;
  l:=TstringList.Create;
  DN:='cn=kav4proxy,cn=artica,' + ldap_suffix;
  Myquery:='(objectClass=Kav4ProxyClass)';

    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Load_Kav4proxy_settings:: Failed search ' + Myquery + ' in ' + DN);
         exit;
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('Load_Kav4proxy_settings:: Failed search ' + Myquery + ' in ' + DN);
       exit;
    end;



    for i:=0 to global_ldap.SearchResult.Count -1 do begin
         result:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'Kav4ProxyMainConf');

     end;
end;

//##############################################################################
function Tarticaldap.ArticaMailAddonsLevel():string;
var
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;

begin

 result:='';
  if not Logged then begin
     if D then writeln('Logged -> false, exit...');
     exit;
  end;


 l:=TstringList.Create;
  DN:='cn=artica,' + ldap_suffix;
  Myquery:='(objectClass=ArticaSettings)';


    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('ArticaMailAddonsLevel:: Failed search ' + Myquery + ' in ' + DN);
         exit;
    end;

 if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('ArticaMailAddonsLevel:: Failed search ' + Myquery + ' in ' + DN);
       exit;
    end;

    for i:=0 to global_ldap.SearchResult.Count -1 do begin
         result:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'ArticaMailAddonsLevel');
    end;
    logs.logs('ArticaMailAddonsLevel:: result:=' +result);
    if length(result)=0 then result:='0';

end;
//##############################################################################
function Tarticaldap.Load_proxy_settings():http_proxy_settings;
         const
            CR = #$0d;
            LF = #$0a;
            CRLF = CR + LF;
var
   F                        :http_proxy_settings;
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   t                        :integer;
begin

 result:=F;
  if not Logged then begin
     if D then writeln('Logged -> false, exit...');
     exit(f);
  end;
  l:=TstringList.Create;
  DN:='cn=http_proxy,cn=artica,' + ldap_suffix;
  Myquery:='(objectClass=ArticaProxySettings)';


    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('Load_proxy_settings:: Failed search ' + Myquery + ' in ' + DN);
         exit;
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('Load_proxy_settings:: Failed search ' + Myquery + ' in ' + DN);
       exit;
    end;

    for i:=0 to global_ldap.SearchResult.Count -1 do begin
         if D then writeln('############# Entry :',i);
         F.ArticaProxyServerName:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'ArticaProxyServerName');
         F.ArticaProxyServerPort:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'ArticaProxyServerPort');
         F.ArticaProxyServerUsername:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'ArticaProxyServerUsername');
         F.ArticaProxyServerUserPassword:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'ArticaProxyServerUserPassword');
         F.ArticaProxyServerEnabled:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'ArticaProxyServerEnabled');
         F.ArticaMailAddonsLevel:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'ArticaMailAddonsLevel');


     end;
if F.ArticaProxyServerUsername='nil' then F.ArticaProxyServerUsername:='';
if F.ArticaProxyServerUserPassword='nil' then F.ArticaProxyServerUserPassword:='';

F.IniSettings:=CRLF+'[PROXY]' + CRLF + 'servername=' +F.ArticaProxyServerName + CRLF;
F.IniSettings:=F.IniSettings+ 'serverport=' +F.ArticaProxyServerPort + CRLF;
F.IniSettings:=F.IniSettings+ 'username=' +F.ArticaProxyServerUsername + CRLF;
F.IniSettings:=F.IniSettings+ 'password=' +F.ArticaProxyServerUserPassword + CRLF;
F.IniSettings:=F.IniSettings+ 'enabled=' +F.ArticaProxyServerEnabled + CRLF;

result:=F;

end;

//##############################################################################
procedure Tarticaldap.CreateMailManBranch();
  var
  ldap: TLDAPsend;
  LDAPAttributeList: TLDAPAttributeList;
  LDAPAttribute: TLDAPAttribute;
  attr: TLDAPAttribute;
begin

 ldap :=  TLDAPSend.Create;
     ldap.TargetHost := ldap_server;
     ldap.TargetPort := '389';
     ldap.UserName := 'cn=' +ldap_admin + ',' + ldap_suffix;
     ldap.Password := ldap_password;
     ldap.Version := 3;
     ldap.FullSSL := false;


     if not ldap.Login then begin
        ldap.Free;
        exit();
     end;

    if not ldap.Bind then begin
       logs.Debuglogs('CreateMailManBranch:: failed bind "' + ldap.UserName + '"');
       ldap.free;
       exit;
    end;
            LDAPAttributeList := TLDAPAttributeList.Create;
            LDAPAttribute:= LDAPAttributeList.Add;
            LDAPAttribute.AttributeName:='cn';
            LDAPAttribute.Add('mailman');

            LDAPAttribute:= LDAPAttributeList.Add;
            LDAPAttribute.AttributeName:='ObjectClass';
            LDAPAttribute.Add('top');
            LDAPAttribute.Add('PostFixStructuralClass');


            if not ldap.Add('cn=mailman,cn=artica,'+ldap_suffix,LDAPAttributeList) then begin
               if ldap.ResultCode<>68 then begin
                  logs.Debuglogs('CreateMailManBranch:: Create_mailmain_list() -> Error unable to create branch cn=artica,cn=mailman,'+ldap_suffix);
                  logs.Debuglogs('CreateMailManBranch:: Error number ' + IntToStr(ldap.ResultCode) + ' ' +  ldap.ResultString);
               end;

            end;

  ldap.Logout;
     ldap.free;

end;
//##############################################################################
procedure Tarticaldap.CreateDiscoversBranch();
  var
  LDAPAttributeList: TLDAPAttributeList;
  LDAPAttribute: TLDAPAttribute;
  attr: TLDAPAttribute;
  DN:string;
begin
 if not Logged then begin
     if D then writeln('CreateDiscoversBranch() not logged  -> false, exit...');
     exit();
  end;
  
  
    DN:='dc=samba,'+ldap_suffix;
    if not ExistsDN(DN) then begin
          LDAPAttributeList := TLDAPAttributeList.Create;
          LDAPAttribute:= LDAPAttributeList.Add;
          LDAPAttribute.AttributeName:='ObjectClass';
          LDAPAttribute.Add('top');
          LDAPAttribute.Add('organization');
          LDAPAttribute.Add('dcObject');

          LDAPAttribute:= LDAPAttributeList.Add;
          LDAPAttribute.AttributeName:='o';
          LDAPAttribute.Add('samba');

          LDAPAttribute:= LDAPAttributeList.Add;
          LDAPAttribute.AttributeName:='dc';
          LDAPAttribute.Add('samba');

          if not global_ldap.Add(DN,LDAPAttributeList) then begin
             if global_ldap.ResultCode<>68 then begin
                logs.Debuglogs('CreateDiscoversBranch():: Error number ' + IntToStr(global_ldap.ResultCode) + ' ' +  global_ldap.ResultString);
                exit;
             end;
          end;

    end;
  

    DN:='ou=Computer,dc=samba,'+ldap_suffix;
    if not ExistsDN(DN) then begin
          LDAPAttributeList := TLDAPAttributeList.Create;
          LDAPAttribute:= LDAPAttributeList.Add;
          LDAPAttribute.AttributeName:='ObjectClass';
          LDAPAttribute.Add('top');
          LDAPAttribute.Add('organizationalUnit');
          
          LDAPAttribute:= LDAPAttributeList.Add;
          LDAPAttribute.AttributeName:='ou';
          LDAPAttribute.Add('Computer');
          
          if not global_ldap.Add(DN,LDAPAttributeList) then begin
             if global_ldap.ResultCode<>68 then begin
                logs.Debuglogs('CreateDiscoversBranch():: Error number ' + IntToStr(global_ldap.ResultCode) + ' ' +  global_ldap.ResultString);
                exit;
             end;
          end;
          
    end;
end;
//##############################################################################
procedure Tarticaldap.admin_modify();
var
  LDAPAttributeList: TLDAPAttributeList;
  LDAPAttribute: TLDAPAttribute;
  attr: TLDAPAttribute;
  DN,tmpdn:string;
  SambaGetSid:integer;
  uidNumber:integer;
  localsid:string;
  ExDN:boolean;

begin
DN:='cn='+LDAPINFO.admin+','+ldap_suffix;
ExDN:=ExistsDN(DN);
logs.Debuglogs('admin_modify()::'+ DN);
LDAPAttributeList := TLDAPAttributeList.Create;
if not ExDN then begin
   LDAPAttribute:= LDAPAttributeList.Add;
   LDAPAttribute.AttributeName:='ObjectClass';
   LDAPAttribute.Add('organizationalRole');
   LDAPAttribute.Add('UserArticaClass');
   LDAPAttribute.Add('simpleSecurityObject');
end;

     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='cn';
     LDAPAttribute.Add(LDAPINFO.admin);
     

     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='ArticaInterfaceLogon';
     LDAPAttribute.Add(LDAPINFO.admin);
     if ExDN then global_ldap.Modify(DN,MO_Replace,LDAPAttribute);
     
     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='userPassword';
     LDAPAttribute.Add(LDAPINFO.password);
     if ExDN then global_ldap.Modify(DN,MO_Replace,LDAPAttribute);

     if not ExDN then begin
          if not global_ldap.Add(DN,LDAPAttributeList) then begin
             {if global_ldap.ResultCode<>68 then begin}
                logs.Debuglogs('admin_modify():: ldap_add Error number ' + IntToStr(global_ldap.ResultCode) + ' ' +  global_ldap.ResultString);
                {exit;}
             {end;}
          end;
     end;
end;
//##############################################################################
function Tarticaldap.Create_Artica_branch():boolean;
var
  LDAPAttributeList: TLDAPAttributeList;
  LDAPAttribute: TLDAPAttribute;
  attr: TLDAPAttribute;
  DN,tmpdn:string;
  SambaGetSid:integer;
  uidNumber:integer;
  localsid:string;
  ExDN:boolean;
begin
result:=false;
DN:='cn=artica,'+ldap_suffix;
ExDN:=ExistsDN(DN);
if ExDN then exit(true);
LDAPAttributeList := TLDAPAttributeList.Create;
LDAPAttribute:= LDAPAttributeList.Add;
LDAPAttribute.AttributeName:='ObjectClass';
LDAPAttribute.Add('organizationalRole');
LDAPAttribute.Add('ArticaSettings');
LDAPAttribute.Add('top');

LDAPAttribute:= LDAPAttributeList.Add;
LDAPAttribute.AttributeName:='cn';
LDAPAttribute.Add('artica');
if not global_ldap.Add(DN,LDAPAttributeList) then begin
   logs.Debuglogs('Create_Artica_branch():: ldap_add Error number ' + IntToStr(global_ldap.ResultCode) + ' ' +  global_ldap.ResultString);
   exit(false);
end;

exit(true);

end;
//##############################################################################


function Tarticaldap.bind9_Create_master_branch(NamedConf:string):boolean;
var
  LDAPAttributeList: TLDAPAttributeList;
  LDAPAttribute    : TLDAPAttribute;
  attr             : TLDAPAttribute;
  DN               :string;
  ExDN             :boolean;
begin
result:=false;
DN:='cn=artica,'+ldap_suffix;
ExDN:=ExistsDN(DN);

if not ExDN then begin
   logs.Debuglogs('Starting......: Bind9 Master dn '+DN +' Does not exists...');
   if not Create_Artica_branch() then begin
      logs.Debuglogs('Starting......: Bind9 unable to create master branch');
      exit;
   end;
end;


DN:='cn=bind9,cn=artica,'+ldap_suffix;

ExDN:=ExistsDN(DN);
LDAPAttributeList := TLDAPAttributeList.Create;

if not ExDN then begin
   LDAPAttribute:= LDAPAttributeList.Add;
   LDAPAttribute.AttributeName:='ObjectClass';
   LDAPAttribute.Add('bind');
   LDAPAttribute.Add('top');
   
   LDAPAttribute:= LDAPAttributeList.Add;
   LDAPAttribute.AttributeName:='cn';
   LDAPAttribute.Add('bind9');
end;

LDAPAttribute:= LDAPAttributeList.Add;
LDAPAttribute.AttributeName:='NamedConf';
LDAPAttribute.Add(NamedConf);
if ExDN then global_ldap.Modify(DN,MO_Replace,LDAPAttribute);

if not ExDN then begin
   if not global_ldap.Add(DN,LDAPAttributeList) then begin
      logs.Debuglogs('bind9_Create_master_branch():: ldap_add Error number ' + IntToStr(global_ldap.ResultCode) + ' ' +  global_ldap.ResultString);
      exit(false);
   end;
end;

exit(true);


end;

//##############################################################################
function Tarticaldap.bind9_Create_zone_branch(zone:string;FilePath:string):boolean;
var
  LDAPAttributeList: TLDAPAttributeList;
  LDAPAttribute    : TLDAPAttribute;
  attr             : TLDAPAttribute;
  DN               : string;
  ExDN             : boolean;
begin
result:=false;
DN:='cn='+zone+',cn=bind9,cn=artica,'+ldap_suffix;
ExDN:=ExistsDN(DN);
LDAPAttributeList := TLDAPAttributeList.Create;
if not ExDN then begin
   LDAPAttribute:= LDAPAttributeList.Add;
   LDAPAttribute.AttributeName:='ObjectClass';
   LDAPAttribute.Add('bind');
   LDAPAttribute.Add('top');

   LDAPAttribute:= LDAPAttributeList.Add;
   LDAPAttribute.AttributeName:='cn';
   LDAPAttribute.Add(zone);
end;

   LDAPAttribute:= LDAPAttributeList.Add;
   LDAPAttribute.AttributeName:='ZoneContent';
   LDAPAttribute.Add(logs.ReadFromFile(FilePath));


if ExDN then global_ldap.Modify(DN,MO_Replace,LDAPAttribute);

if not ExDN then begin
   if not global_ldap.Add(DN,LDAPAttributeList) then begin
      logs.Debuglogs('bind9_Create_zone_branch():: ldap_add Error number ' + IntToStr(global_ldap.ResultCode) + ' ' +  global_ldap.ResultString);
      exit(false);
   end;
end;

exit(true);

end;


function Tarticaldap.AddScannerComputer(co:computer_infos):boolean;
var
  LDAPAttributeList: TLDAPAttributeList;
  LDAPAttribute: TLDAPAttribute;
  attr: TLDAPAttribute;
  DN,tmpdn:string;
  SambaGetSid:integer;
  uidNumber:integer;
  localsid:string;
  ExDN:boolean;

begin

if length(co.computername)=0 then begin
   if length(co.computerip)>0 then co.computername:=co.computerip;
end;

if length(co.computername)=0 then begin
    logs.Debuglogs('AddScannerComputer() unable to determine computer name');
    exit;
end;


 if not Logged then begin
     if D then writeln('AddScannerComputer() not logged  -> false, exit...');
     exit();
  end;
  CreateDiscoversBranch();
  
  if length(co.mac)>0 then begin
    tmpdn:=ComputerDN_From_MAC(co.mac);
    logs.Debuglogs('AddScannerComputer():: '+co.mac+' ="'+tmpdn+'"');
    if length(tmpdn)>0 then DN:=tmpdn;
  end;
  
  
  DN:='cn='+co.computername+'$,ou=Computer,dc=samba,dc=organizations,'+ldap_suffix;
  LDAPAttributeList := TLDAPAttributeList.Create;
  
  ExDN:=ExistsDN(DN);
  
  
  if not ExDN then begin
     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='ObjectClass';
     LDAPAttribute.Add('top');
     LDAPAttribute.Add('ArticaComputerInfos');
     LDAPAttribute.Add('posixAccount');
     LDAPAttribute.Add('sambaSamAccount');
     LDAPAttribute.Add('shadowAccount');
  end;

     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='cn';
     LDAPAttribute.Add(co.computername+'$');

     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='uid';
     LDAPAttribute.Add(co.computername+'$');
     
     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='homeDirectory';
     LDAPAttribute.Add(co.computername+'/tmp');
     
     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='gecos';
     LDAPAttribute.Add('Computer');
     
     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='shadowMax';
     LDAPAttribute.Add('20000');

     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='shadowLastChange';
     LDAPAttribute.Add('-1');
     

     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='loginShell';
     LDAPAttribute.Add('/bin/false');
     
     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='description';
     LDAPAttribute.Add('Computer');
     
     
     
     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='sambaAcctFlags';
     LDAPAttribute.Add('[W          ]');

     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='sambaLogonTime';
     LDAPAttribute.Add('0');
     
     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='sambaLogoffTime';
     LDAPAttribute.Add('2147483647');
     
     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='sambaKickoffTime';
     LDAPAttribute.Add('2147483647');

     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='sambaPwdCanChange';
     LDAPAttribute.Add('0');

     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='gidNumber';
     LDAPAttribute.Add('515');

     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='sambaPwdMustChange';
     LDAPAttribute.Add('2147483647');

     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='sambaPrimaryGroupSID';
     LDAPAttribute.Add(samba_group_sid_from_gid('515'));

     
     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='uidNumber';
     
     uidNumber:=strToInt(samba_get_new_uidNumber());
     LDAPAttribute.Add(IntToStr(uidNumber));
     
     localsid:=SYSTEM_LOCAL_SID();
     SambaGetSid:=(2*uidNumber)+1000;
     
     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='sambaSID';
     LDAPAttribute.Add(localsid+'-'+IntToStr(SambaGetSid));

//ComputerIP $ ComputerOpenPorts $ ComputerOS $ ComputerUpTime $ ComputerMachineType $ ComputerRunning $ ComputerMacAddress $ ComputerHopCount

     if length(co.computerip)=0 then co.computerip:='0.0.0.0';
     if length(co.computer_ports)=0 then co.computer_ports:='NO';
     if length(co.OS)=0 then co.OS:='Unknown';
     if length(co.uptime)=0 then co.uptime:='0';
     if length(co.comput_type)=0 then co.comput_type:='Unknown';
     if length(co.running)=0 then co.running:='Unknown';
     if length(co.mac)=0 then co.mac:='00:00:00:00:00';
     if length(co.hop)=0 then co.hop:='0';
     
     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='ComputerIP';
     LDAPAttribute.Add(co.computerip);
     if ExDN then global_ldap.Modify(DN,MO_Replace,LDAPAttribute);


     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='ComputerOpenPorts';
     LDAPAttribute.Add(co.computer_ports);
     if ExDN then global_ldap.Modify(DN,MO_Replace,LDAPAttribute);
     
     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='ComputerOS';
     LDAPAttribute.Add(co.OS);
     if ExDN then global_ldap.Modify(DN,MO_Replace,LDAPAttribute);
     
     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='ComputerUpTime';
     LDAPAttribute.Add(co.uptime);
     if ExDN then global_ldap.Modify(DN,MO_Replace,LDAPAttribute);
     
     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='ComputerMachineType';
     LDAPAttribute.Add(co.comput_type);
     if ExDN then global_ldap.Modify(DN,MO_Replace,LDAPAttribute);
     
     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='ComputerRunning';
     LDAPAttribute.Add(co.running);
     if ExDN then global_ldap.Modify(DN,MO_Replace,LDAPAttribute);
     
     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='ComputerMacAddress';
     LDAPAttribute.Add(co.mac);
     if ExDN then global_ldap.Modify(DN,MO_Replace,LDAPAttribute);
     
     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='ComputerHopCount';
     LDAPAttribute.Add(co.hop);
     if ExDN then global_ldap.Modify(DN,MO_Replace,LDAPAttribute);

     if not ExDN then begin
          if not global_ldap.Add(DN,LDAPAttributeList) then begin
             {if global_ldap.ResultCode<>68 then begin}
                logs.Debuglogs('AddScannerComputer():: ldap_add Error number ' + IntToStr(global_ldap.ResultCode) + ' ' +  global_ldap.ResultString);
                {exit;}
             {end;}
          end;
     end;
     
end;
//#############################################################################
procedure Tarticaldap.lighttpd_modify_config(config:string);
var
  LDAPAttributeList: TLDAPAttributeList;
  LDAPAttribute: TLDAPAttribute;
  attr: TLDAPAttribute;
  DN,tmpdn:string;
  SambaGetSid:integer;
  uidNumber:integer;
  localsid:string;
  ExDN:boolean;

begin
   DN:='cn=artica-settings,cn=artica,'+ldap_suffix;
   LDAPAttributeList := TLDAPAttributeList.Create;
   LDAPAttribute:= LDAPAttributeList.Add;
   LDAPAttribute.AttributeName:='lighttpConfig';
   LDAPAttribute.Add(config);
   if not global_ldap.Modify(DN,MO_Replace,LDAPAttribute) then begin
     writeln('lighttpd_modify_config():: ldap_add Error number ' + DN+' ' +IntToStr(global_ldap.ResultCode) + ' ' +  global_ldap.ResultString);
   end;
end;
//#############################################################################

procedure Tarticaldap.CreateArticaUser();
  var
  ldap: TLDAPsend;
  LDAPAttributeList: TLDAPAttributeList;
  LDAPAttribute: TLDAPAttribute;
  attr: TLDAPAttribute;
  dn:string;
  i:integer;
  z:integer;
  RegExpr:TRegExpr;
begin
     ldap :=  TLDAPSend.Create;
     ldap.TargetHost := ldap_server;
     ldap.TargetPort := '389';
     ldap.UserName := 'cn=' +ldap_admin + ',' + ldap_suffix;
     ldap.Password := ldap_password;
     ldap.Version := 3;
     ldap.FullSSL := false;


     if not ldap.Login then begin
        ldap.Free;
        exit();
     end;

    if not ldap.Bind then begin
       logs.Debuglogs('CreateArticaUser:: failed bind "' + ldap.UserName + '"');
       ldap.free;
       exit;
    end;
      dn:='cn=artica,' +  ldap_suffix;


     LDAPAttributeList := TLDAPAttributeList.Create;


     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='ObjectClass';
     LDAPAttribute.Add('organizationalRole');
     LDAPAttribute.Add('ArticaSettings');
     LDAPAttribute.Add('top');


     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='cn';
     LDAPAttribute.Add('artica');

     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='ArticaWebRootURI';
     LDAPAttribute.Add('http://127.0.0.1/artica-postfix');

     RegExpr:=TRegExpr.Create;
     RegExpr.Expression:='already exists';
     if not ldap.Add(dn,LDAPAttributeList) then begin
        if not RegExpr.Exec(ldap.ResultString) then begin
        logs.Debuglogs('CreateArticaUser() -> ' +dn);
        logs.Debuglogs('CreateArticaUser() -> ' +ldap.ResultString);
        //DumpAttributes(LDAPAttributeList);
        end;
     end;
     RegExpr.free;
     ldap.Logout;
     ldap.free;

end;



//##############################################################################
procedure Tarticaldap.DumpAttributes(LDAPAttributeList:TLDAPAttributeList);
var i,z:integer;
begin

     for i:=0 to LDAPAttributeList.Count -1 do begin
         for z:=0 to  LDAPAttributeList.Items[i].Count -1 do begin
         writeln(LDAPAttributeList.Items[i].AttributeName + '[' + intToStr(z) + ']=' + LDAPAttributeList.Items[i].Strings[z]);
         end;
     end;
end;
//##############################################################################
procedure Tarticaldap.DeleteCyrusUser();
  var
  ldap: TLDAPsend;
  LDAPAttributeList: TLDAPAttributeList;
  LDAPAttribute: TLDAPAttribute;
  attr: TLDAPAttribute;
  dn:string;
  i:integer;
  z:integer;
  RegExpr:TRegExpr;
  cyrus_admin:string;
  cyrus_password:string;
begin
ldap :=  TLDAPSend.Create;
     ldap.TargetHost := ldap_server;
     ldap.TargetPort := '389';
     ldap.UserName := 'cn=' +ldap_admin + ',' + ldap_suffix;
     ldap.Password := ldap_password;
     ldap.Version := 3;
     ldap.FullSSL := false;

     cyrus_admin:=zldp.get_LDAP('cyrus_admin');
     cyrus_password:=zldp.get_LDAP('cyrus_password');

     if length(cyrus_admin)=0 then cyrus_admin:='cyrus';
     if length(cyrus_password)=0 then cyrus_password:=ldap_password;



     if not ldap.Login then begin
        ldap.Free;
        exit();
     end;

    if not ldap.Bind then begin
       writeln('failed bind');
       exit;
    end;
     dn:='cn=' + cyrus_admin + ',' +  ldap_suffix;

     if ldap.Delete(dn) then writeln('success delete "' + cyrus_admin + '" cyrus-imapd admin');


end;
//##############################################################################
function Tarticaldap.LoadMailboxes(loadallusers:boolean):mailboxesinfos;
var
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   AttributeNameQ           :string;
   i                        :integer;
   f                        :mailboxesinfos;

begin
 f.Users:=TstringList.Create;
 result:=f;
  if not Logged then begin
     if D then writeln('Logged -> false, exit...');
     exit(f);
  end;


  l:=TstringList.Create;
  DN:='cn=cyrus,' + ldap_suffix;
  Myquery:='(objectClass=inetOrgPerson)';


    if not global_ldap.Search(DN, False, Myquery, l) then begin
         logs.Debuglogs('LoadMailboxes:: Failed search ' + Myquery + ' in ' + DN);
         CreateCyrusUser();
         exit(f);
    end;

 if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       CreateCyrusUser();
       logs.Debuglogs('LoadMailboxes:: Failed search ' + Myquery + ' in ' + DN);
       exit(f);
    end;

    for i:=0 to global_ldap.SearchResult.Count -1 do begin
         f.Cyrus_password:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'userPassword');
    end;

    if length(f.Cyrus_password)=0 then begin
          DeleteCyrusUser();
          CreateCyrusUser();
    end;

if  loadallusers then begin

DN:=ldap_suffix;
  Myquery:='(&(objectClass=userAccount)(MailboxActive=TRUE))';


    if not global_ldap.Search(DN, False, Myquery, l) then begin
         logs.Debuglogs('LoadMailboxes:: Failed search ' + Myquery + ' in ' + DN);
         CreateCyrusUser();
         exit(f);
    end;

 if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       CreateCyrusUser();
       logs.Debuglogs('LoadMailboxes:: Failed search ' + Myquery + ' in ' + DN);
       exit(f);
    end;

  for i:=0 to global_ldap.SearchResult.Count -1 do begin
         f.Users.AddStrings(SearchMultipleAttribute(global_ldap.SearchResult,'uid'));
    end;
    logs.Debuglogs('LoadMailboxes:: Found '+  intTostr(f.Users.Count) +' mailboxes');
end;


   exit(f);

end;




//#############################################################################"
function Tarticaldap.CreateCyrusUser():boolean;
  var
  ldap: TLDAPsend;
  LDAPAttributeList: TLDAPAttributeList;
  LDAPAttribute: TLDAPAttribute;
  attr: TLDAPAttribute;
  dn:string;
  i:integer;
  z:integer;
  RegExpr:TRegExpr;
  cyrus_admin:string;
  cyrus_password:string;
begin
     ldap :=  TLDAPSend.Create;
     ldap.TargetHost := ldap_server;
     ldap.TargetPort := '389';
     ldap.UserName := 'cn=' +ldap_admin + ',' + ldap_suffix;
     ldap.Password := ldap_password;
     ldap.Version := 3;
     ldap.FullSSL := false;

     cyrus_admin:=zldp.get_LDAP('cyrus_admin');
     cyrus_password:=zldp.get_LDAP('cyrus_password');

     if length(cyrus_admin)=0 then cyrus_admin:='cyrus';
     if length(cyrus_password)=0 then cyrus_password:=ldap_password;



     if not ldap.Login then begin
        ldap.Free;
        exit();
     end;

    if not ldap.Bind then begin
       writeln('failed bind');
       exit;
    end;
     dn:='cn=' + cyrus_admin + ',' +  ldap_suffix;



     LDAPAttributeList := TLDAPAttributeList.Create;


     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='ObjectClass';
     LDAPAttribute.Add('top');
     LDAPAttribute.Add('inetOrgPerson');


     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='cn';
     LDAPAttribute.Add(cyrus_admin);

     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='sn';
     LDAPAttribute.Add(cyrus_admin);

     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='userPassword';
     LDAPAttribute.Add(ldap_password);


     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='uid';
     LDAPAttribute.Add(cyrus_admin);

     RegExpr:=TRegExpr.Create;
     RegExpr.Expression:='already exists';
     if not ldap.Add(dn,LDAPAttributeList) then begin
        if not RegExpr.Exec(ldap.ResultString) then begin
        logs.Debuglogs('CreateCyrusUser() -> '+ldap.ResultString);
        //DumpAttributes(LDAPAttributeList);
        end;
     end else begin
          writeln('Starting......: Create cyrus-imapd admin "' + cyrus_admin + '" success');
     end;

     ldap.Logout;
     ldap.free;




end;
//##############################################################################
function Tarticaldap.ParseSuffix():boolean;
var
   ldap:TLDAPSend;
   l:TStringList;
   i,t,u:integer;
   D,Z:boolean;
   value_result:string;
   AttributeNameQ:string;
   USER_DN:string;
   RES:ldapinfos;
   Query_string:string;
   return_attribute:string;
   DN_ROOT:string;
   RegExpr:TRegExpr;
begin
  D:=false;
  result:=false;
     D:=COMMANDLINE_PARAMETERS('debug');
     ldap :=  TLDAPSend.Create;
     ldap.TargetHost := '127.0.0.1';
     ldap.TargetPort := '389';
     ldap.UserName := 'cn=' + ldap_admin + ',' + ldap_suffix;
     ldap.Password := ldap_password;
     ldap.Version := 3;
     ldap.FullSSL := false;

     if not ldap.Login then begin
        ldap.Free;
        exit();
     end;


   if not ldap.Bind then begin
      writeln('failed logon with "' + ldap.UserName + '"');
      exit;
   end;
    l:=TstringList.Create;
    l.Add('*');


    // ***************************************************************** user

   result:=false;
    if ldap.Search(ldap_suffix, False, '(objectclass=dcObject)', l) then begin
       if ldap.SearchResult.Count>0 then result:=true;

    end;


end;





//##############################################################################
procedure Tarticaldap.CreateSuffix();
var
   ldap:TLDAPSend;
   l:TStringList;
   i,t,u:integer;
   D,Z:boolean;
   value_result:string;
   AttributeNameQ:string;
   USER_DN:string;
   RES:ldapinfos;
   Query_string:string;
   newdn:string;
   RegExpr:TRegExpr;
   tbl:TStringDynArray;

begin
   USER_DN:=ldap_suffix;


   if ParseSuffix() then exit;
   tbl:=Explode(',',USER_DN);
   newdn:=tbl[0]+ ','+ tbl[1];
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='dc=(.+)';
   RegExpr.Exec(tbl[0]);

   for i:=1 to  length(tbl)-1 do begin
         LOGS.logs('CreateSuffix() ->Create ' +newdn );

          if not Create_dcObject(newdn,RegExpr.Match[1]) then begin
             writeln('CreateSuffix() FAILED create ' + newdn);
             break;
          end;
          newdn:=newdn + ',' + tbl[i];
   end;








end;
//##############################################################################
function Tarticaldap.Create_dcObject(dn:string;name:string):boolean;
  var
  ldap: TLDAPsend;
  LDAPAttributeList: TLDAPAttributeList;
  LDAPAttribute: TLDAPAttribute;
  attr: TLDAPAttribute;

begin



     ldap :=  TLDAPSend.Create;
     ldap.TargetHost := ldap_server;
     ldap.TargetPort := '389';
     ldap.UserName := 'cn=' +ldap_admin + ',' + ldap_suffix;
     ldap.Password := ldap_password;
     ldap.Version := 3;
     ldap.FullSSL := false;


     if not ldap.Login then begin
        ldap.Free;
        exit();
     end;

    if not ldap.Bind then begin
       writeln('failed bind "' + ldap.UserName + '"');
       exit;
    end;

{dn: dc=my-domain,dc=com
objectClass: top
objectClass: organization
objectClass: dcObject
o: my-domain
dc: my-domain
}

     LDAPAttributeList := TLDAPAttributeList.Create;


     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='ObjectClass';
     LDAPAttribute.Add('top');
     LDAPAttribute.Add('dcObject');
     LDAPAttribute.Add('organization');


     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='o';
     LDAPAttribute.Add(name);

     LDAPAttribute:= LDAPAttributeList.Add;
     LDAPAttribute.AttributeName:='dc';
     LDAPAttribute.Add(name);

     result:=ldap.Add(dn,LDAPAttributeList);
     if not result then writeln(name + ': ' + ldap.ResultString);
     ldap.free;

end;




function Tarticaldap.LoadAllOu():string;
var
right_email,Myquery,resultats:string;
i,t,u:integer;

begin

   Myquery:='(&(ObjectClass=organizationalUnit)(ou=*))';
   resultats:=Query(MyQuery,'ou');
   exit(resultats);
end;
//##############################################################################
function Tarticaldap.ArticaDenyNoMXRecordsOu(Ou:string):string;
var
Myquery,resultats:string;
begin

   Myquery:='(&(ObjectClass=organizationalUnit)(ou=' + ou + '))';
   resultats:=Query(MyQuery,'ArticaDenyNoMXRecords');
   resultats:=trim(resultats);
   if length(resultats)=0 then resultats:='pass';
   exit(resultats);

end;
//##############################################################################
function Tarticaldap.QuarantineMaxDayByOu(Ou:string):string;
var
right_email,Myquery,resultats:string;
i,t,u:integer;

begin

   Myquery:='(&(ObjectClass=organizationalUnit)(ou=' + ou + '))';
   resultats:=Query(MyQuery,'ArticaMaxDayQuarantine');
   exit(trim(resultats));
end;
//##############################################################################
function Tarticaldap.IsOuDomainBlackListed(Ou:string;domain:string):boolean;
var
right_email,Myquery,resultats:string;
begin
   result:=false;
   SEARCH_DN:='cn=blackListedDomains,ou=' + ou + ',' + ldap_suffix;
   Myquery:='(&(ObjectClass=DomainsBlackListOu)(cn='+domain+'))';
   resultats:=trim(Query(MyQuery,'cn'));
   if length(resultats)>0 then exit(true);

end;
//##############################################################################
function Tarticaldap.FackedSenderParameters(Ou:string):string;
var
resultats,Myquery:string;
begin
   result:='pass';
   SEARCH_DN:='ou=' + ou + ',' + ldap_suffix;
   Myquery:='(&(ObjectClass=ArticaSettings)(ArticaFakedMailFrom=*))';
   resultats:=trim(Query(MyQuery,'ArticaFakedMailFrom'));
   if length(resultats)=0 then result:='pass' else result:=resultats;

end;
//##############################################################################
function Tarticaldap.ArticaMaxSubQueueNumberParameter():integer;
var
resultats,Myquery:string;
begin
   result:=5;
   SEARCH_DN:='cn=artica,' + ldap_suffix;
   Myquery:='(&(ObjectClass=ArticaSettings)(ArticaMaxSubQueueNumber=*))';
   resultats:=trim(Query(MyQuery,'ArticaMaxSubQueueNumber'));
   if length(resultats)=0 then resultats:='5';
   result:=StrToInt(resultats);
end;
//##############################################################################






function Tarticaldap.LoadASRules(email:string):string;
         const
            CR = #$0d;
            LF = #$0a;
            CRLF = CR + LF;
var
RegExpr:TRegExpr;
right_email,Myquery,resultats:string;
begin
     right_email:=EmailFromaliase(email);
     D:=COMMANDLINE_PARAMETERS('asrules=');
     if D then writeln('Get list of Kaspersky antispam rules for "' + right_email + '"');
     Myquery:='(&(ObjectClass=ArticaSettings)(mail=' +right_email + '))';
     resultats:=Query(MyQuery,'KasperkyASDatasRules');
     if trim(resultats)='DEFAULT' then begin
          RegExpr:=TRegExpr.Create;
          RegExpr.Expression:='ou=(.+?),.+';
          if RegExpr.Exec(DN_ROOT) then resultats:=LoadOUASRules(RegExpr.Match[1]);
     end;
     if trim(resultats)='DEFAULT' then begin
            resultats:='detection_rate="45"' + CRLF;
            resultats:=resultats+ 'action_quarantine="1"' + CRLF;
            resultats:=resultats+ 'action_killmail="1"' + CRLF;
            resultats:=resultats+ 'action_prepend="0"' + CRLF;
            resultats:=resultats+ 'second_rate="90"' + CRLF;
            resultats:=resultats+ 'second_quarantine="0"' + CRLF;
            resultats:=resultats+ 'second_killmail="1"' + CRLF;
            resultats:=resultats+ 'second_prepend="0"' + CRLF;


     end;

     if D then writeln(resultats);
     exit(resultats);
end;
//##############################################################################
function Tarticaldap.OU_From_eMail(email:string):string;
var
   RegExpr:TRegExpr;
   right_email,Myquery,resultats:string;
   i,t,u:integer;

   F:boolean;
begin
     D:=COMMANDLINE_PARAMETERS('whereis=');
     F:=COMMANDLINE_PARAMETERS('debug');

    if F then writeln('OU_From_eMail: ' + email );
    right_email:=EmailFromaliase(email);
    if D then writeln('Where is "' + right_email + '" ?');
    Myquery:='(&(ObjectClass=userAccount)(mail=' +right_email + '))';
    if F then writeln('OU_From_eMail: ' + Myquery );
    resultats:=Query(MyQuery,'ObjectName');
    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='ou=(.+?),.+';
    if RegExpr.Exec(resultats) then result:=RegExpr.Match[1];
end;


//##############################################################################
function Tarticaldap.LoadAVRules(email:string):string;
         const
            CR = #$0d;
            LF = #$0a;
            CRLF = CR + LF;
var
RegExpr:TRegExpr;
right_email,Myquery,resultats,ou:string;
i,t,u:integer;

begin
     right_email:=EmailFromaliase(email);
     ou:=OU_From_eMail(right_email);
     D:=COMMANDLINE_PARAMETERS('avrules=');
     if D then writeln('Get list of Kaspersky antivirus rules for "' + ou + '"');
     Myquery:='(&(ObjectClass=ArticaSettings)(ou=' +ou + '))';
     resultats:=Query(MyQuery,'KasperkyAVScanningDatas');
     if trim(resultats)='DEFAULT' then begin
     resultats:='NotifyFromAddress="postmaster"' + CRLF;
     resultats:=resultats+ 'DeleteDetectedVirus="1"' + CRLF;
     resultats:=resultats+ 'NotifyFrom="1"' + CRLF;
     resultats:=resultats+ 'NotifyTo="1"' + CRLF;
     resultats:=resultats+ 'ArchiveMail="1"' + CRLF;
     resultats:=resultats+ 'NotifyMessageSubject="%SUBJECT%"' + CRLF;
     resultats:=resultats+ '<NotifyMessageTemplate><p><font face="arial,helvetica,sans-serif" size="4" color="#ff0000">Warning !!</font></p>';
     resultats:=resultats+ '<p>The message %SUBJECT% sended by %SENDER% For %MAILTO% was infected please, try to send your messages without any viruses.</p><p><strong>Virus detected</strong> :</p><blockquote><p>%VIRUS% !!!<br /> </p></blockquote></NotifyMessageTemplate>' + CRLF;
     end;

     if D then writeln(resultats);
     exit(resultats);
end;
//##############################################################################
function Tarticaldap.LoadOUASRules(ou:string):string;
var

right_email,Myquery,resultats:string;


begin

     D:=COMMANDLINE_PARAMETERS('asrules=');
     if D then writeln('Get list of Kaspersky antispam rules for "' + ou + '"');
     Myquery:='(&(ObjectClass=ArticaSettings)(ou=' +ou + '))';
     resultats:=Query(MyQuery,'KasperkyASDatasRules');
     exit(resultats);
end;


 function Tarticaldap.Ldap_infos(email:string):ldapinfos;
         const
            CR = #$0d;
            LF = #$0a;
            CRLF = CR + LF;
var
   ldap:TLDAPSend;
   l:TStringList;
   i,t:integer;
   D,Z:boolean;
   value_result:string;
   AttributeNameQ:string;
   USER_DN:string;
   RES:ldapinfos;
   Query_string:string;
   return_attribute:string;
   DN_ROOT:string;
   RegExpr:TRegExpr;
begin
     D:=false;
     D:=COMMANDLINE_PARAMETERS('debug');
     Z:=COMMANDLINE_PARAMETERS('q=');
     ldap :=  TLDAPSend.Create;
     ldap.TargetHost := '127.0.0.1';
     ldap.TargetPort := '389';
     ldap.UserName := ldap_admin;
     ldap.Password := ldap_password;
     ldap.Version := 3;
     ldap.FullSSL := false;

     if not ldap.Login then begin
        ldap.Free;
        exit();
     end;

    RES.RBL_SERVERS:=TStringList.Create;
    RES.BOGOFILTER_ROBOTS:=TStringList.Create;
    RES.WhiteList:=TStringList.Create;



    result:=RES;
    ldap.Bind;
    l:=TstringList.Create;



    // ***************************************************************** user


    ldap.Search(ldap_suffix, False, '(&(objectclass=userAccount)(mailAlias=' + email+'))', l);
    if D then writeln('(&(objectclass=userAccount)(mailAlias=' + email+')) count :',ldap.SearchResult.Count);
    if ldap.SearchResult.Count>0 then begin
       if D then writeln('ldap.SearchResult.Items[0].ObjectName=',ldap.SearchResult.Items[0].ObjectName);
       RES.user_dn:=ldap.SearchResult.Items[0].ObjectName;
    end else begin
        ldap.Search(ldap_suffix, False, '(&(objectclass=userAccount)(mail=' + email+'))', l);
        if ldap.SearchResult.Count>0 then RES.user_dn:=ldap.SearchResult.Items[0].ObjectName;
    end;

    if length(RES.user_dn)=0 then begin
          ldap.Search(ldap_suffix, False, '(&(objectclass=userAccount)(SenderCanonical=' + email+'))', l);
          if ldap.SearchResult.Count>0 then RES.user_dn:=ldap.SearchResult.Items[0].ObjectName;
    end;


    if length(RES.user_dn)=0 then begin
        ldap.Logout;
       ldap.Free;
       exit(res);
    end;

    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='.+?ou=(.+?),';
    if RegExpr.Exec(RES.user_dn) then RES.user_ou:=RegExpr.Match[1];

    if length(RES.user_ou)=0 then begin
        ldap.Logout;
       ldap.Free;
       exit(res);
    end;

    RES.uid:=SearchSingleAttribute(ldap.SearchResult.Items[0].Attributes,'uid');

     for i:=0 to ldap.SearchResult.Count -1 do begin
       for t:=0 to ldap.SearchResult.Items[i].Attributes.Count -1 do begin
                AttributeNameQ:=LowerCase(ldap.SearchResult.Items[i].Attributes[t].AttributeName);
                if AttributeNameQ=LowerCase('KasperkyASDatasAllow') then RES.WhiteList.AddStrings(ParseResultInStringList(ldap.SearchResult.Items[i].Attributes.Items[t]));
        end;

     end;


    // *****************************************************************




    SEARCH_DN:='ou='+RES.user_ou + ',' + ldap_suffix;


    if ldap.Search(SEARCH_DN, False, '(&(objectclass=ArticaBogoFilterAdmin)(BogoFilterMailType=*))', l) then begin
        for i:=0 to ldap.SearchResult.Count -1 do begin
             RES.BOGOFILTER_ROBOTS.Add(SearchSingleAttribute(ldap.SearchResult.Items[i].Attributes,'mail') + ';' +SearchSingleAttribute(ldap.SearchResult.Items[i].Attributes,'BogoFilterMailType'));
        end;
    end;





    l.Add('*');
    Query_string:='(&(ObjectClass=ArticaSettings)(ou=' + RES.user_ou + '))';


    if not ldap.Search(SEARCH_DN, False, Query_string, l) then begin
       if D then writeln('Ldap_infos::  failed "' + ldap.FullResult + '"');
       ldap.Logout;
       ldap.Free;
       exit;
    end;

 if D then writeln('Ldap_infos:: Results Count :' + IntToStr(ldap.SearchResult.Count));




 if ldap.SearchResult.Count=0 then begin
     if D then writeln('Ldap_infos::  no results...');
       ldap.Logout;
       ldap.Free;
       exit();
 end;

 if Z then writeln(CRLF +CRLF +'************************************************');


 for i:=0 to ldap.SearchResult.Count -1 do begin
      if D then writeln('QUERY:: ObjectName.......: "' +ldap.SearchResult.Items[i].ObjectName + '"');
      DN_ROOT:=ldap.SearchResult.Items[i].ObjectName;
      if D then writeln('QUERY:: Count attributes.: ' +IntToStr(ldap.SearchResult.Items[i].Attributes.Count));


      RES.RBL_SERVER_ACTION:=SearchSingleAttribute(ldap.SearchResult.Items[i].Attributes,'rblserversaction');

      //----------- bogofilter ------------------------------------------------------------------------------
      RES.BOGOFILTER_ACTION:=SearchSingleAttribute(ldap.SearchResult.Items[i].Attributes,'BogoFilterAction');
      if length(RES.BOGOFILTER_ACTION)=0 then RES.BOGOFILTER_ACTION:='90;prepend;*** SPAM ***';
      //-----------------------------------------------------------------------------------------------------

      //----------- Trust users ------------------------------------------------------------------------------
      RES.TrustMyUsers:=SearchSingleAttribute(ldap.SearchResult.Items[i].Attributes,'OuTrustMyUSers');
      if length(RES.TrustMyUsers)=0 then RES.TrustMyUsers:='yes';
      //-----------------------------------------------------------------------------------------------------



      for t:=0 to ldap.SearchResult.Items[i].Attributes.Count -1 do begin

               AttributeNameQ:=LowerCase(ldap.SearchResult.Items[i].Attributes[t].AttributeName);
               if D then writeln('QUERY:: Attribute name[' + IntToStr(t) + '].......: "' + AttributeNameQ + '"');

               if AttributeNameQ='rblservers' then RES.RBL_SERVERS.AddStrings(ParseResultInStringList(ldap.SearchResult.Items[i].Attributes.Items[t]));



      end;

 end;

     if Z then writeln();
     if Z then writeln('************************************************');
     if D then writeln('QUERY:: logout');


     RegExpr.Expression:='([0-9]+);([a-z]+);(.+)';
     if RegExpr.Exec(RES.BOGOFILTER_ACTION) then begin
           RES.BOGOFILTER_PARAM.max_rate:=StrToInt(RegExpr.Match[1]);
           RES.BOGOFILTER_PARAM.action:=RegExpr.Match[2];
           RES.BOGOFILTER_PARAM.prepend:=RegExpr.Match[3];
     end;

     result:=RES;
     RegExpr.Free;
     ldap.Logout;
     ldap.Free;

end;
 //##############################################################################




function Tarticaldap.ParseResultInStringList(Items:TLDAPAttribute):TStringList;
var

   i:integer;
   A:TstringList;
begin
     D:=false;
     D:=COMMANDLINE_PARAMETERS('debug');
   A:=TstringList.Create;

   if D then writeln('ParseResultInStringList:: Count items......: ' +IntToStr(Items.Count));
   for i:=0 to Items.Count -1 do begin
       A.Add(Items.Strings[i]);
   end;
exit(A);

end;
 //##############################################################################
function Tarticaldap.SearchSingleAttribute(Items:TLDAPAttributeList;SearchAttribute:string):string;
var

   i:integer;
   AttributeName:string;
begin
     D:=false;
     D:=COMMANDLINE_PARAMETERS('debug');
   if D then writeln('...................................................................');
   if D then writeln('SearchSingleAttribute:: Count items......: ' +IntToStr(Items.Count));
   if D then writeln('SearchSingleAttribute:: Must found.......: ', SearchAttribute);

   for i:=0 to Items.Count -1 do begin
            AttributeName:=LowerCase(Items[i].AttributeName);
            if D then writeln('SearchSingleAttribute:: AttributeName......: ' +AttributeName,'?=>',LowerCase(SearchAttribute));
            if LowerCase(SearchAttribute)=AttributeName then begin

                    result:=Items[i].Strings[0];
                    if D then writeln('FOUND !!! "',SearchAttribute,'" ', chr(9) + result);
                    break;
            end;


   end;

end;
 //##############################################################################
 function Tarticaldap.SearchSingleData(Items:TLDAPResultList;SearchAttribute:string):string;
var

   i,z,u             :integer;
   AttributeName     :string;
   l                 :TstringList;
begin
     D:=false;
     D:=COMMANDLINE_PARAMETERS('debug');
     l:=TstringList.Create;


   if D then writeln('SearchMultipleAttribute:: Count items......: ' +IntToStr(Items.Count));
   for i:=0 to Items.Count -1 do begin
       for z:=0 to Items[i].Attributes.Count -1 do begin
            AttributeName:=LowerCase(Items.Items[i].Attributes[z].AttributeName);
            if D then writeln('SearchMultipleAttribute:: AttributeName......: ' +AttributeName);

            if LowerCase(SearchAttribute)=AttributeName then begin
              result:=Items.Items[i].Attributes[z].Strings[0];
              break;
            end;
        end;
   end;

end;
 //##############################################################################

 //##############################################################################
 function Tarticaldap.SearchMultipleAttribute(Items:TLDAPResultList;SearchAttribute:string):Tstringlist;
var

   i,z,u             :integer;
   AttributeName     :string;
   l                 :TstringList;
begin
     D:=false;
     D:=COMMANDLINE_PARAMETERS('debug');
     l:=TstringList.Create;


   if D then writeln('SearchMultipleAttribute:: Count items......: ' +IntToStr(Items.Count));
   for i:=0 to Items.Count -1 do begin
       for z:=0 to Items[i].Attributes.Count -1 do begin
            AttributeName:=LowerCase(Items.Items[i].Attributes[z].AttributeName);
            if D then writeln('SearchMultipleAttribute:: AttributeName......: ' +AttributeName);

            if LowerCase(SearchAttribute)=AttributeName then begin
               for u:=0 to Items.Items[i].Attributes[z].Count-1 do begin
                    if D then writeln('SearchMultipleAttribute::' + AttributeName + '=' + Items.Items[i].Attributes[z].Strings[u]);
                    l.Add(Items.Items[i].Attributes[z].Strings[u]);
               end;
            end;
        end;
   end;

result:=l;
exit();

end;
 //##############################################################################
function Tarticaldap.Query(Query_string:string;return_attribute:string):string;
         const
            CR = #$0d;
            LF = #$0a;
            CRLF = CR + LF;
var  ldap:TLDAPSend;
l:TStringList;
i,t,u:integer;
D,Z:boolean;
value_result:string;
AttributeNameQ:string;
begin
D:=false;
D:=COMMANDLINE_PARAMETERS('debug');
Z:=COMMANDLINE_PARAMETERS('q=');
ldap :=  TLDAPSend.Create;
     ldap.TargetHost := '127.0.0.1';
     ldap.TargetPort := '389';
     ldap.UserName := ldap_admin;
     ldap.Password := ldap_password;
     ldap.Version := 3;
     ldap.FullSSL := false;

     if not ldap.Login then begin
        ldap.Free;
        exit();
     end;

    return_attribute:=LowerCase(return_attribute);
    ldap.Bind;
    l:=TstringList.Create;
    l.Add('*');
    if length(SEARCH_DN)=0 then SEARCH_DN:=ldap_suffix;

    if D then writeln('QUERY:: "' + Query_string  + '" find attr:' + return_attribute);
    if D then writeln('QUERY:: IN DN "' + SEARCH_DN  + '"');

    if not ldap.Search(SEARCH_DN, False, Query_string, l) then begin
       if D then writeln('QUERY::  failed "' + ldap.FullResult + '"');
       ldap.Logout;
       ldap.Free;
       exit;
    end;

 if D then writeln('QUERY:: Results Count :' + IntToStr(ldap.SearchResult.Count));


 if ldap.SearchResult.Count=0 then begin
     if D then writeln('QUERY::  no results...');
       ldap.Logout;
       ldap.Free;
       exit();
 end;

 if Z then writeln(CRLF +CRLF +'************************************************');


 for i:=0 to ldap.SearchResult.Count -1 do begin
      if D then writeln('QUERY:: ObjectName.......: "' +ldap.SearchResult.Items[i].ObjectName + '"');
      DN_ROOT:=ldap.SearchResult.Items[i].ObjectName;
      if return_attribute='objectname' then begin
         ldap.Logout;
         ldap.Free;
         if D then writeln('QUERY:: RETURN ObjectName.......: "' +DN_ROOT + '"');
         exit(DN_ROOT);
      end;

      if D then writeln('QUERY:: Count attributes.: ' +IntToStr(ldap.SearchResult.Items[i].Attributes.Count));

      for t:=0 to ldap.SearchResult.Items[i].Attributes.Count -1 do begin

      AttributeNameQ:=LowerCase(ldap.SearchResult.Items[i].Attributes[t].AttributeName);
      if D then writeln('QUERY:: Attribute name[' + IntToStr(t) + '].......: "' + AttributeNameQ + '"');

     TEMP_LIST.Clear;
     if AttributeNameQ=return_attribute then begin
              if D then writeln('QUERY:: Count items......: ' +IntToStr(ldap.SearchResult.Items[i].Attributes.Items[t].Count));
              for u:=0 to ldap.SearchResult.Items[i].Attributes.Items[t].Count-1 do begin
                  value_result:=ldap.SearchResult.Items[i].Attributes.Items[t].Strings[u];
                  if D then writeln('QUERY:: ADD item[' + IntToStr(t) + ']"............:'+value_result+ '"');
                  TEMP_LIST.Add(trim(value_result));
                  Result:=Result + value_result+CRLF;
              end;
        end;
     end;

 end;

     if Z then writeln(Result);
      if Z then writeln('************************************************');
     if D then writeln('QUERY:: logout');

     ldap.Logout;
     ldap.Free;

end;
//##############################################################################
function Tarticaldap.implode(ArrayS:TStringDynArray):string;
var
   i:integer;

begin
D:=COMMANDLINE_PARAMETERS('debug');
if D then writeln('Arrays:', length(ArrayS));
    for i:=0 to length(ArrayS) -1 do begin
     if length(ArrayS[i])>0 then result:=result + '|' + ArrayS[i];
    end;
end;


//##############################################################################
function Tarticaldap.Query_A(Query_string:string;return_attribute:string):TStringDynArray;
         const
            CR = #$0d;
            LF = #$0a;
            CRLF = CR + LF;
var  ldap:TLDAPSend;
l:TStringList;
i,t,u,r:integer;
D,Z:boolean;
value_result:string;
AttributeNameQ:string;
begin
D:=false;
D:=COMMANDLINE_PARAMETERS('debug');
Z:=COMMANDLINE_PARAMETERS('q=');
ldap :=  TLDAPSend.Create;
     ldap.TargetHost := '127.0.0.1';
     ldap.TargetPort := '389';
     ldap.UserName := ldap_admin;
     ldap.Password := ldap_password;
     ldap.Version := 3;
     ldap.FullSSL := false;

     if not ldap.Login then begin
        ldap.Free;
        exit();
     end;

    return_attribute:=LowerCase(return_attribute);
    ldap.Bind;
    l:=TstringList.Create;
    l.Add('*');
    if length(SEARCH_DN)=0 then SEARCH_DN:=ldap_suffix;

    if D then writeln('QUERY:: "' + Query_string  + '" find attr:' + return_attribute);
    if D then writeln('QUERY:: IN DN "' + SEARCH_DN  + '"');

    if not ldap.Search(SEARCH_DN, False, Query_string, l) then begin
       if D then writeln('QUERY::  failed "' + ldap.FullResult + '"');
       ldap.Logout;
       ldap.Free;
       exit;
    end;

 if D then writeln('QUERY:: Results Count :' + IntToStr(ldap.SearchResult.Count));


 if ldap.SearchResult.Count=0 then begin
     if D then writeln('QUERY::  no results...');
       ldap.Logout;
       ldap.Free;
       exit();
 end;

 if Z then writeln(CRLF +CRLF +'************************************************');


 for i:=0 to ldap.SearchResult.Count -1 do begin
      if D then writeln('QUERY:: ObjectName.......: "' +ldap.SearchResult.Items[i].ObjectName + '"');
      DN_ROOT:=ldap.SearchResult.Items[i].ObjectName;
      if return_attribute='objectname' then begin
         ldap.Logout;
         ldap.Free;
      end;

      if D then writeln('QUERY:: Count attributes.: ' +IntToStr(ldap.SearchResult.Items[i].Attributes.Count));

      for t:=0 to ldap.SearchResult.Items[i].Attributes.Count -1 do begin

      AttributeNameQ:=LowerCase(ldap.SearchResult.Items[i].Attributes[t].AttributeName);
      if D then writeln('QUERY:: Attribute name[' + IntToStr(t) + '].......: "' + AttributeNameQ + '"');

     TEMP_LIST.Clear;
     if AttributeNameQ=return_attribute then begin
              if D then writeln('QUERY:: Count items......: ' +IntToStr(ldap.SearchResult.Items[i].Attributes.Items[t].Count));
              SetLength(result, 0);
              for u:=0 to ldap.SearchResult.Items[i].Attributes.Items[t].Count-1 do begin

                  value_result:=ldap.SearchResult.Items[i].Attributes.Items[t].Strings[u];
                  if D then writeln('QUERY:: ADD item[' + IntToStr(t) + ']"............:'+value_result+ '"[' + intToStr(r) + ']"');
                  SetLength(result, length(result)+1);
                  result[length(result)-1]:=value_result;
              end;
        end;
     end;

 end;

     if Z then writeln('rows:',length(result));
      if Z then writeln('************************************************');
     if D then writeln('QUERY:: logout');

     ldap.Logout;
     ldap.Free;

end;



//##############################################################################
function Tarticaldap.EmailFromaliase(email:string):string;
var  ldap:TLDAPSend;
l:TStringList;
i,t,u:integer;
F:boolean;
begin
      F:=COMMANDLINE_PARAMETERS('debug');
      if F then writeln('EmailFromaliase:' + email);
     ldap :=  TLDAPSend.Create;
     if F then writeln('EmailFromaliase:init engine success');
     ldap.TargetHost := '127.0.0.1';
     ldap.TargetPort := '389';
     ldap.UserName := ldap_admin;
     ldap.Password := ldap_password;
     ldap.Version := 3;
     ldap.FullSSL := false;
     if F then writeln('EmailFromaliase:Login "' + ldap_admin + '"');
     if not ldap.Login then begin
        if F then writeln('EmailFromaliase:Error connection');
        ldap.Free;
        exit(email);
     end;

     if F then writeln('EmailFromaliase: Bind');
     ldap.Bind;
     if F then writeln('EmailFromaliase: Binded');
     D:=COMMANDLINE_PARAMETERS('aliases');


    l:=TstringList.Create;
    l.Add('mail');
    if F then writeln('EmailFromaliase:(&(objectclass=userAccount)(mailAlias=' + email+'))');
    ldap.Search(ldap_suffix, False, '(&(objectclass=userAccount)(mailAlias=' + email+'))', l);
    //writeln(LDAPResultdump(ldap.SearchResult));

    if D then writeln('Count:' + IntToStr(ldap.SearchResult.Count));

    if ldap.SearchResult.Count>0 then begin
         result:=ldap.SearchResult.Items[0].Attributes.Items[0].Strings[0];
         if D then writeln(email+'="' + result + '"');
         ldap.Logout;
         ldap.Free;
         exit;
    end else begin
        result:=email;
         if D then writeln(email+'="' + result + '"');
         ldap.Logout;
         ldap.Free;
        exit;
    end;


     writeln('count=' + IntToStr(ldap.SearchResult.Count));
     for i:=0 to ldap.SearchResult.Count -1 do begin
       writeln( ldap.SearchResult.Items[i].ObjectName);
       writeln( 'attributes:=' +IntToStr(ldap.SearchResult.Items[i].Attributes.Count));
       writeln('ObjectName:'+ldap.SearchResult.Items[i].ObjectName);


        for t:=0 to ldap.SearchResult.Items[i].Attributes.Count -1 do begin
              for u:=0 to ldap.SearchResult.Items[i].Attributes.Items[t].Count-1 do begin
                  writeln(ldap.SearchResult.Items[i].Attributes.Items[t].Strings[u]);
              end;
        end;

     end;
     writeln('logout');

     ldap.Logout;
     ldap.Free;

end;
//##############################################################################
function Tarticaldap.EmailFromUID(uid:string):string;
var
   F                        :artica_settings;
   Myquery                  :string;
   DN                       :string;
   l                        :Tstringlist;
   i                        :integer;
   t                        :integer;

begin

  if not Logged then begin
     if D then writeln('Logged -> false, exit...');
     exit;
  end;

  l:=TstringList.Create;
  DN:=ldap_suffix;
  Myquery:='(&(objectclass=userAccount)(uid=' +uid+'))';
  l.Add('mail');

    if not global_ldap.Search(DN, False, Myquery, l) then begin
         if D then writeln('EmailFromUID:: Failed search ' + Myquery + ' in ' + DN);
         exit;
    end;


    if D then writeln(Myquery+ ' count :',global_ldap.SearchResult.Count);
    if global_ldap.SearchResult.Count=0 then begin
       if D then writeln('EmailFromUID:: Failed search ' + Myquery + ' in ' + DN);
       exit;
    end;


 for i:=0 to global_ldap.SearchResult.Count -1 do begin
        result:=SearchSingleAttribute(global_ldap.SearchResult.Items[i].Attributes,'mail');
     end;

end;
//##############################################################################
function Tarticaldap.COMMANDLINE_PARAMETERS(FoundWhatPattern:string):boolean;
var
   i:integer;
   s:string;
   RegExpr:TRegExpr;

begin
 result:=false;
 if ParamCount>0 then begin
     for i:=0 to ParamCount do begin
        s:=s  + ' ' +ParamStr(i);
     end;
 end;
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:=FoundWhatPattern;
   if RegExpr.Exec(s) then begin
      RegExpr.Free;
      result:=True;
   end;


end;
//##############################################################################
function Tarticaldap.get_CONF(key:string):string;
var value:string;
GLOBAL_INI:TMemIniFile;

begin

if not fileExists('/etc/artica-postfix/artica-postfix.conf') then begin
   logs.logs('unable to stat /etc/artica-postfix/artica-postfix.conf !!!');
   exit;
end;
GLOBAL_INI:=TMemIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
value:=GLOBAL_INI.ReadString('ARTICA',key,'');
result:=value;
GLOBAL_INI.Free;
end;

//##############################################################################

function Tarticaldap.Explode(const Separator, S: string; Limit: Integer = 0):TStringDynArray;
var
  SepLen       : Integer;
  F, P         : PChar;
  ALen, Index  : Integer;
begin
  SetLength(Result, 0);
  if (S = '') or (Limit < 0) then
    Exit;
  if Separator = '' then
  begin
    SetLength(Result, 1);
    Result[0] := S;
    Exit;
  end;
  SepLen := Length(Separator);
  ALen := Limit;
  SetLength(Result, ALen);

  Index := 0;
  P := PChar(S);
  while P^ <> #0 do
  begin
    F := P;
    P := StrPos(P, PChar(Separator));
    if (P = nil) or ((Limit > 0) and (Index = Limit - 1)) then
      P := StrEnd(F);
    if Index >= ALen then
    begin
      Inc(ALen, 5); // mehrere auf einmal um schneller arbeiten zu können
      SetLength(Result, ALen);
    end;
    SetString(Result[Index], F, P - F);
    Inc(Index);
    if P^ <> #0 then
      Inc(P, SepLen);
  end;
  if Index < ALen then
    SetLength(Result, Index); // wirkliche Länge festlegen
end;
//##############################################################################

end.

