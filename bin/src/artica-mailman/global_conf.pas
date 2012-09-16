unit global_conf;
{$MODE DELPHI}
//{$mode objfpc}{$H+}
{$LONGSTRINGS ON}

interface

uses
//depreciated oldlinux -> linux
Classes, SysUtils,Process,strutils,IniFiles,RegExpr in 'RegExpr.pas',unix,libc,logs,dateutils,zsystem,uHashList,ldapsend,Geoip,BaseUnix,md5;
type
  TStringDynArray = array of string;
  
  type

  { MyConf }

  MyConf=class


private
       GLOBAL_INI:TIniFile;


       procedure  killfile(path:string);
       function   GetIPAddressOfInterface( if_name:ansistring):ansistring;
       procedure  ShowScreen(line:string);
       function   LDAP_IS_FILE_IN_SCHEMA(filename_to_search:string):boolean;
       procedure  LDAP_ADDSHEMAS();
       procedure  LDAP_REMOVESCHEMAS();
       function   POSTFIX_EXTRAINFOS_PATH(filename:string):string;
       LOGS                :tlogs;
       notdebug2           :boolean;
       download_silent     :boolean;
       function FileSize_ko(path:string):longint;


public

      function ARTICA_AutomaticConfig():boolean;
      function CGI_ALL_APPLIS_INSTALLED():string;
      function INYADIN_VERSION():string;
      PROCEDURE BuildDeb(targetfile:string;targetversion:string);
      
      procedure THREAD_COMMAND_SET(zcommands:string);
      function CheckInterface( if_name:string):boolean;
      function GetIPInterface( if_name:string):string;
       
      function  ReadFileIntoString(path:string):string;
      procedure set_INFOS(key:string;val:string);
      function  get_INFOS(key:string):string;
      procedure set_LDAP(key:string;val:string);
      function  get_LDAP(key:string):string;
      procedure ExecProcess(commandline:string);
      procedure MonShell(cmd:string;sh:boolean);
      
      function  KAS_INIT():string;
      function  KAS_GET_VALUE(key:string):string;
      procedure KAS_WRITE_VALUE(key:string;datas:string);
      function  KAS_STATUS():string;
      function  KAS_VERSION():string;
      procedure KAS_DELETE_VALUE(key:string);
      function  KAS_APPLY_RULES(path:string):boolean;
      FUNCTION  KAS_AP_SPF_PID():string;
      FUNCTION  KAS_AP_PROCESS_SERVER_PID():string;
      FUNCTION  KAS_LICENCE_PID():string;
      FUNCTION  KAS_THTTPD_PID():string;
      
      procedure KAV6_STOP();
      procedure KAV6_START();
      function  KAV_MILTER_PID():string;
      function  KAV_MILTER_MEMORY():string;
      function  KAVMILTER_GET_VALUE(KEY:string;VALUE:string):string;
      function  KAVMILTER_PATTERN_DATE():string;
      function  KAVMILTERD_GET_LASTLOGS():string;
      function  KAVMILTERD_GET_LOGS_PATH():string;
      
      function PERL_VERSION():string;
      function PERL_BIN_PATH():string;
      function PERL_INCFolders():TstringList;
      
      function LDAP_GET_CONF_PATH():string;
      function LDAP_READ_VALUE_KEY( key:string):string;
      function LDAP_READ_ADMIN_NAME():string;
      function LDAP_WRITE_VALUE_KEY( key:string;value:string):string;
      function LDAP_GET_INITD():string;
      function LDAP_GET_SCHEMA_PATH():string;
      function LDAP_READ_SCHEMA_POSTFIX_PATH():string;
      function LDAP_ADDSCHEMA( schema:string):string;
      function LDAP_VERSION():string;
      function LDAP_GET_DAEMON_USERNAME():string;
      function LDAP_USE_SUSE_SCHEMA():boolean;
      function LDAP_PID():string;
      function LDAP_GET_BIN_PATH:string;
      function LDAP_START():string;
      function LDAP_STOP():string;
      procedure LDAP_VERIFY_SCHEMA();
      procedure LDAP_SET_DB_CONFIG();

      
      function AWSTATS_GET_VALUE(key:string):string;
      function AWSTATS_SET_VALUE(key:string;value:string):string;
      function AWSTATS_SET_PLUGIN(value:string):string;
      function AWSTATS_MAILLOG_CONVERT_PATH_SOURCE():string;
      function AWSTATS_PATH():string;
      function AWSTATS_VERSION():string;
      procedure AWSTATS_GENERATE();
      
      function       CYRUS_VERSION():string;
      function       CYRUS_IMAPD_BIN_PATH():string;
      function       CYRUS_PID_PATH():string;
      procedure      CYRUS_SET_V2(val:string);
      function       CYRUS_GET_V2():string;
      procedure      CYRUS_DAEMON_START();
      function       CYRUS_PID():string;
      function       CYRUS_IMAPD_CONFIGURE():boolean;
      function       CYRUS_IMAPD_SATUS():string;
      
      
      //dansguardian
      function       DANSGUARDIAN_VERSION():string;
      procedure      DANSGUARDIAN_START();
      FUNCTION       DANSGUARDIAN_PID():string;
      procedure      DANSGUARDIAN_STOP();
      function       DANSGUARDIAN_CONFIG_VALUE(key:string):string;
      procedure      DANSGUARDIAN_CONFIG_VALUE_SET(key:string;value:string);
      
      //pure-ftpd
      function       PURE_FTPD_VERSION():string;
      procedure      PURE_FTPD_PREPARE_LDAP_CONFIG();
      procedure      PURE_FTPD_SETCONFIG(key:string;value:string);
      function       PURE_FTPD_PID():string;
      procedure      PURE_FTPD_START();
      procedure      PURE_FTPD_STOP();
      
      
      function  MAILMAN_GET_PID():string;
      function  MAILMAN_VERSION():string;

      function  RRDTOOL_SecondsBetween(longdate:string):string;
      function  RRDTOOL_VERSION():string;
      function  RRDTOOL_TIMESTAMP(longdate:string):string;
      function  RRDTOOL_LOAD_AVERAGE():string;
      function  RRDTOOL_BIN_PATH():string;
      
      function RRDTOOL_STAT_LOAD_AVERAGE_DATABASE_PATH():string;
      function RRDTOOL_STAT_LOAD_CPU_DATABASE_PATH():string;
      function RRDTOOL_STAT_LOAD_MEMORY_DATABASE_PATH():string;
      function RRDTOOL_STAT_POSTFIX_MAILS_SENT_DATABASE_PATH():string;

      procedure RDDTOOL_POSTFIX_MAILS_SENT_STATISTICS();
      procedure RDDTOOL_POSTFIX_MAILS_CREATE_DATABASE();
      
      procedure RDDTOOL_LOAD_AVERAGE_GENERATE();
      procedure RDDTOOL_LOAD_CPU_GENERATE();
      procedure RDDTOOL_LOAD_MEMORY_GENERATE();
      function  RRDTOOL_GRAPH_HEIGHT():string;
      function  RRDTOOL_GRAPH_WIDTH():string;
      procedure RDDTOOL_POSTFIX_MAILS_SENT_GENERATE();
      
      function  DSPAM_GET_PARAM(key:string):string;
      procedure DSPAM_EDIT_PARAM(key:string;value:string);
      function  DSPAM_IS_PARAM_EXISTS(key:string;value:string):boolean;
      procedure DSPAM_EDIT_PARAM_MULTI(key:string;value:string);
      procedure DSPAM_REMOVE_PARAM(key:string);
      function  DSPAM_BIN_PATH():string;
      
      function       FETCHMAIL_VERSION():string;
      function       FETCHMAIL_STATUS():string;
      function       FETCHMAIL_DAEMON_POOL():string;
      function       FETCHMAIL_DAEMON_POSTMASTER():string;
      function       FETCHMAIL_BIN_PATH():string;
      function       FETCHMAIL_START_DAEMON():boolean;
      function       FETCHMAIL_PID():string;
      procedure      FETCHMAIL_APPLY_CONF(conf_datas:string);
      procedure      FETCHMAIL_APPLY_GETLIVE(conf_datas:string);
      procedure      FETCHMAIL_APPLY_GETLIVE_CONF();
      function       GETLIVE_VERSION():string;

      function       INADYN_PERFORM(IniData:String;UpdatePeriod:integer):string;
      function       INADYN_PID():string;
      procedure      INADYN_PERFORM_STOP();
      
      function       XINETD_BIN():string;
      function       XINETD_PID():string;
      procedure      HOTWAYD_START();
      function       HOTWAYD_VERSION():string;
      
      
      function RENATTACH_VERSION():string;
      function FETCHMAIL_SERVER_PARAMETERS(param:string):string;
      function FETCHMAIL_COUNT_SERVER():integer;
      function FETCHMAIL_DAEMON_STOP():string;
      function get_repositories_librrds_perl():boolean;
      
      function  CRON_CREATE_SCHEDULE(ProgrammedTime:string;Croncommand:string;name:string):boolean;
      function  CRON_PID():string;
      function  CROND_INIT_PATH():string;
      
      function PHP5_LIB_MODULES_PATH():string;
      
      function CERTIFICATE_PASS(path:string):string;
      function CERTIFICATE_PATH(path:string):string;
      function CERTIFICATE_CA_FILENAME(path:string):string;
      function CERTIFICATE_KEY_FILENAME(path:string):string;
      function CERTIFICATE_CERT_FILENAME(path:string):string;
      
      function PROCMAIL_VERSION():string;
      function PROCMAIL_INSTALLED():boolean;
      function PROCMAIL_LOGS_PATH():string;
      function PROCMAIL_USER():string;
      function PROCMAIL_QUARANTINE_PATH():string;
      function PROCMAIL_QUARANTINE_SIZE(username:string):string;
      function PROCMAIL_QUARANTINE_USER_FILE_NUMBER(username:string):string;
      function PROCMAIL_READ_QUARANTINE(fromFileNumber:integer;tofilenumber:integer;username:string):TstringList;
      function PROCMAIL_READ_QUARANTINE_FILE(file_to_read:string):string;
      
      function  DNSMASQ_SET_VALUE(key:string;value:string):string;
      function  DNSMASQ_GET_VALUE(key:string):string;
      function  DNSMASQ_BIN_PATH():string;
      function  DNSMASQ_VERSION:string;
      procedure DNSMASQ_START_DAEMON();
      procedure DNSMASQ_STOP_DAEMON();
      function  DNSMASQ_PID():string;
      
      
      
      function  BOGOFILTER_VERSION():string;
      function  LIB_GSL_VERSION():string;

      function OPENSSL_TOOL_PATH():string;
      function OPENSSL_VERSION():string;
      
      function ROUNDCUBE_VERSION():string;
      
      function GetAllApplisInstalled():string;
      
      procedure         SQUID_SET_CONFIG(key:string;value:string);
      function          SQUID_GET_SINGLE_VALUE(key:string):string;
      function          SQUID_VERSION():string;
      function          SQUID_PID():string;
      procedure         SQUID_START();
      procedure         SQUID_STOP();
      function          SQUID_CONFIG_PATH():string;
      procedure         SQUID_VERIFY_CACHE();
      function          SQUID_BIN_PATH():string;
      PROCEDURE         SQUID_RRD_INIT();
      PROCEDURE         SQUID_RRD_INSTALL();
      PROCEDURE         SQUID_RRD_EXECUTE();
      
      
      function          KAV4PROXY_VERSION():string;
      function          KAV4PROXY_PID():string;
      procedure         KAV4PROXY_START();
      procedure         KAV4PROXY_STOP();
      function          KAV4PROXY_GET_VALUE(KEY:string;VALUE:string):string;
      function          KAV4PROXY_PATTERN_DATE():string;

      function  get_repositories_Checked():boolean;
      function  POSTFIX_PID_PATH():string;
      function  POSTFIX_PID():string;
      function  POSTFIX_STATUS():string;
      function  POSTFIX_VERSION():string;
      function  POSTFIX_HEADERS_CHECKS():string;
      procedure POSTFIX_CHECK_POSTMAP();
      function  POSTFIX_QUEUE_FILE_NUMBER(directory_name:string):string;
      function  POSFTIX_READ_QUEUE_FILE_LIST(fromFileNumber:integer;tofilenumber:integer;queuepath:string;include_source:boolean):TstringList;
      function  POSTFIX_READ_QUEUE_MESSAGE(MessageID:string):string;
      function  POSFTIX_CACHE_QUEUE_FILE_LIST(QueueName:string):boolean;
      function  POSFTIX_CACHE_QUEUE():boolean;
      function  POSFTIX_DELETE_FILE_FROM_CACHE(MessageID:string):boolean;
      procedure POSTFIX_REPLICATE_MAIN_CF(mainfile:string);
      procedure POSTFIX_RELOAD_DAEMON();
      procedure POSTFIX_RESTART_DAEMON();
      procedure POSFTIX_VERIFY_MAINCF();
      function  POSTFIX_EXPORT_LOGS():boolean;
      function  POSTFIX_LAST_ERRORS():string;
      function  POSTFIX_LDAP_COMPLIANCE():boolean;
      function  POSTFIX_EXTRACT_MAINCF(key:string):string;
      procedure POSTFIX_STOP();
      procedure POSTFIX_CONFIGURE_MAIN_CF();
      function  POSFTIX_MASTER_CF_PATH:string;
      function  POSFTIX_POSTCONF_PATH:string;
      procedure POSTFIX_INITIALIZE_FOLDERS();

      function  APACHE_GET_INITD_PATH:string;
      procedure APACHE_ARTICA_START();
      procedure APACHE_ARTICA_STOP();
      function  APACHE2_DirectoryAddOptions(Change:boolean;WichOption:string):string;
      function  APACHE_PID():string;
      function  APACHE_VERSION():string;
      
      function QUEUEGRAPH_TEMP_PATH():string;

      
      function  AVESERVER_GET_VALUE(KEY:string;VALUE:string):string;
      function  AVESERVER_GET_PID():string;
      function  AVESERVER_GET_VERSION():string;
      function  AVESERVER_GET_LICENCE():string;
      function  AVESERVER_STATUS():string;
      function  AVESERVER_PATTERN_DATE():string;
      function  AVESERVER_GET_KEEPUP2DATE_LOGS_PATH():string;
      function  AVESERVER_SET_VALUE(KEY:string;VALUE:string;DATA:string):string;
      function  AVESERVER_GET_DAEMON_PORT():string;
      function  AVESERVER_GET_TEMPLATE_DATAS(family:string;ztype:string):string;
      procedure AVESERVER_REPLICATE_TEMPLATES();
      procedure AVESERVER_REPLICATE_kav4mailservers(mainfile:string);
      function  AVESERVER_GET_LOGS_PATH():string;
      
      
      function get_repositories_openssl():boolean;
      
      function  Cyrus_get_sasl_pwcheck_method:string;
      procedure Cyrus_set_sasl_pwcheck_method(val:string);
      function  Cyrus_get_servername:string;
      procedure Cyrus_set_value(info:string;val:string);
      function  Cyrus_get_admins:string;
      function  Cyrus_get_unixhierarchysep:string;
      function  Cyrus_get_virtdomain:string;
      function  Cyrus_get_adminpassword:string;
      function  Cyrus_get_admin_name():string;
      procedure Cyrus_set_admin_name(val:string);
      procedure Cyrus_set_adminpassword(val:string);
      function  Cyrus_get_lmtpsocket:string;
      function  Cyrus_get_value(value:string):string;
      function  CYRUS_REPLICATION_MINUTES():integer;
      function  CYRUS_LAST_REPLIC_TIME():integer;
      procedure CYRUS_RESET_REPLIC_TIME();
      function  CYRUS_GET_INITD_PATH:string;
      function  CYRUS_STATUS():string;
      function  CYRUS_DELIVER_BIN_PATH():string;
      function  CYRUS_IMAPD_CONF_GET_INFOS(value:string):string;
      procedure CYRUS_DAEMON_STOP();
      function  CYRUS_enabled_in_master_cf():boolean;
      
      function  KAV_LAST_REPLIC_TIME():integer;
      procedure KAV_RESET_REPLIC_TIME();
      function  KAV_REPLICATION_MINUTES():integer;
      
      procedure KEEPUP2DATE_RESET_REPLIC_TIME();
      function  KEEPUP2DATE_LAST_REPLIC_TIME():integer;
      function  KEEPUP2DATE_REPLICATION_MINUTES():integer;

      function  SYSTEM_GMT_SECONDS():string;
      function  SYSTEM_GET_ALL_LOCAL_IP():string;
      function  SYSTEM_GET_LOCAL_IP(ifname:string):string;
      function  SYSTEM_DAEMONS_STATUS():TstringList;
      function  SYSTEM_DAEMONS_STOP_START(APPS:string;mode:string;return_string:boolean):string;

      //start the service
      function  SYSTEM_START_ARTICA_DAEMON():boolean;
      procedure LDAP_VERIFY_PASSWORD();

      function  SYSTEM_PROCESS_EXISTS(processname:string):boolean;
      function  SYSTEM_KERNEL_VERSION():string;
      function  SYSTEM_LIBC_VERSION():string;
      function  SYSTEM_LD_SO_CONF_ADD(path:string):string;
      function  SYSTEM_CRON_TASKS():TstringList;
      function  SYSTEM_USER_LIST():string;
      function  SYSTEM_CRON_REPLIC_CONFIGS():string;
      function  SYSTEM_ADD_NAMESERVER(nameserver:string):boolean;
      function  SYSTEM_NETWORK_INITD():string;
      function  SYSTEM_NETWORK_LIST_NICS():string;
      function  SYSTEM_NETWORK_INFO_NIC_DEBIAN(nicname:string):string;
      function  SYSTEM_NETWORK_INFO_NIC_REDHAT(nicname:string):string;
      function  SYSTEM_NETWORK_INFO_NIC(nicname:string):string;
      function  SYSTEM_NETWORK_IFCONFIG():string;
      function  SYSTEM_NETWORK_IFCONFIG_ETH(ETH:string):string;
      function  SYSTEM_NETWORK_RECONFIGURE():string;
      function  SYSTEM_PROCESS_PS():string;
      function  SYSTEM_PROCESS_INFO(PID:string):string;
      function  SYSTEM_ALL_IPS():string;
      function  SYSTEM_PROCESS_EXIST(pid:string):boolean;
      function  SYSTEM_PROCESS_MEMORY(PID:string):integer;
      function  SYSTEM_GET_PID(pidPath:string):string;
      function  SYSTEM_MAKE_PATH():string;
      function  SYSTEM_GCC_PATH():string;
      function  SYSTEM_ENV_PATHS():string;
      procedure SYSTEM_ENV_PATH_SET(path:string);
      function  SYSTEM_VERIFY_CRON_TASKS():string;
      function  SYSTEM_GET_SYS_DATE():string;
      function  SYSTEM_GET_HARD_DATE():string;
      function  SYSTEM_FQDN():string;
      function  SYSTEM_IS_HOSTNAME_VALID():boolean;
      function  SYSTEM_MARK_DEB_CDROM():string;
      procedure SYSTEM_SET_HOSTENAME(hostname:string);
      function  SYSTEM_IP_OVERINTERNET():string;
      function  SYSTEM_GET_HTTP_PROXY:string;
      function  SYSTEM_REMOVE_HTTP_PROXY:string;
      procedure SYSTEM_SET_HTTP_PROXY(proxy_string:string);
      function  SYSTEM_GET_FOLDERSIZE(folderpath:string):string;
      function  SYSTEM_FILE_BETWEEN_NOW(filepath:string):LongInt;
      function  SYSTEM_FILE_DAYS_BETWEEN_NOW(filepath:string):LongInt;
      
      function  ExecPipe(commandline:string):string;
      function  WGET_DOWNLOAD_FILE(uri:string;file_path:string):boolean;
      function  MD5FromFile(path:string):string;

      //BOA
      function         BOA_SET_CONFIG():boolean;
      function         BOA_DAEMON_GET_PID():string;
      procedure        BOA_STOP();
      procedure        BOA_START();
      
      function GEOIP_VERSION():string;

      function  SASLAUTHD_PATH_GET():string;
      function  SASLAUTHD_VALUE_GET(key:string):string;
      function  SASLAUTHD_TEST_INITD():boolean;
      function  SASLAUTHD_PID():string;
      procedure SASLAUTHD_START();
      procedure SASLAUTHD_STOP();
      procedure SASLAUTHD_CONFIGURE();

      function  postfix_get_virtual_mailboxes_maps():string;
      
      function  YOREL_RECONFIGURE(database_path:string):string;
      
      function get_MYSQL_INSTALLED():boolean;
      function get_POSTFIX_DATABASE():string;
      function get_POSTFIX_HASH_FOLDER():string;
      
      
      function get_www_root():string;
      function get_www_userGroup():string;
      function get_httpd_conf():string;
      
      function get_MANAGE_MAILBOXES():string;
      function get_MANAGE_MAILBOX_SERVER():string;

      function get_INSTALL_PATH():string;
      function get_DISTRI():string;
      function get_UPDATE_TOOLS():string;

      procedure set_FileStripDiezes(filepath:string);
      function set_repositories_checked(val:boolean):string;
      procedure set_MYSQL_INSTALLED(val:boolean);
      function set_POSTFIX_DATABASE(val:string):string;
      function set_POSTFIX_HASH_FOLDER(val:string):string;
      
      function set_MANAGE_MAILBOXES(val:string):string;
      procedure set_MANAGE_MAILBOX_SERVER(val:string);
      function get_MANAGE_SASL_TLS():boolean;
      procedure set_MANAGE_SASL_TLS(val:boolean);

      function set_INSTALL_PATH(val:string):string;
      function set_DISTRI(val:string):string;
      function set_UPDATE_TOOLS(val:string):string;
      
      procedure set_LINUX_DISTRI(val:string);
      
      
      function get_LINUX_DISTRI():string;
      function get_LINUX_MAILLOG_PATH():string;
      function get_LINUX_INET_INTERFACES():string;
      function get_LINUX_DOMAIN_NAME():string;
      function get_SELINUX_ENABLED():boolean;
      procedure set_SELINUX_DISABLED();
      
      function LINUX_GET_HOSTNAME:string;
      function LINUX_DISTRIBUTION():string;
      function LINUX_CONFIG_INFOS():string;
      function LINUX_APPLICATION_INFOS(inikey:string):string;
      function LINUX_INSTALL_INFOS(inikey:string):string;
      function LINUX_CONFIG_PATH():string;
      function LINUX_REPOSITORIES_INFOS(inikey:string):string;
      function LINUX_LDAP_INFOS(inikey:string):string;

      


      function LDAP_TESTS():string;


      function MYSQL_ACTION_TESTS_ADMIN():boolean;
      function MYSQL_ACTION_CREATE_ADMIN(username:string;password:string):boolean;
      function MYSQL_ACTION_IF_DATABASE_EXISTS(database_name:string):boolean;
      function MYSQL_ACTION_IMPORT_DATABASE(filenname:string;database:string):boolean;
      function MYSQL_ACTION_COUNT_TABLES(database_name:string):integer;
      function MYSQL_ACTION_QUERY(sql:string):boolean;
      function MYSQL_PASSWORD():string;
      function MYSQL_ROOT():string;
      function MYSQL_ENABLED:boolean;
      function MYSQL_SERVER():string;
      function MYSQL_VERSION:string;
      function MYSQL_BIN_PATH:string;
      function MYSQL_INIT_PATH:string;
      function MYSQL_MYCNF_PATH:string;
      function MYSQL_PID_PATH():string;
      function MYSQL_STATUS():string;
      function MYSQL_EXEC_BIN_PATH():string;
      function MYSQL_SERVER_PARAMETERS_CF(key:string):string;
      
      procedure MYSQL_ARTICA_STOP();
      procedure MYSQL_ARTICA_START();
      function  MYSQL_ARTICA_PID():string;

      function set_ARTICA_PHP_PATH(val:string):string;
      function set_ARTICA_DAEMON_LOG_MaxSizeLimit(val:integer):integer;
      function get_ARTICA_LISTEN_IP():string;
      function get_ARTICA_LOCAL_PORT():integer;
      procedure SET_ARTICA_LOCAL_SECOND_PORT(val:integer);
      function get_ARTICA_LOCAL_SECOND_PORT():integer;
      function ARTICA_MYSQL_INFOS(val:string):string;
      function ARTICA_MYSQL_SET_INFOS(val:string;value:string):boolean;
      function ARTICA_POLICY_GET_PID():string;
      
       //Mailgraph operations
      function   get_MAILGRAPH_TMP_PATH():string;
      function   MAILGRAPH_BIN():string;
      function   get_MAILGRAPH_RRD():string;
      procedure  set_MAILGRAPH_RRD_VIRUS(rrd_path:string);
      function   get_MAILGRAPH_RRD_VIRUS():string;
      function   MAILGRAPH_VERSION():string;
      function   MAILGRAPGH_STATUS():string;
      function   MAILGRAPGH_PID_PATH():string;
      procedure  MAILGRAPH_START();
      function   MAILGRAPH_PID():string;
      procedure  MAILGRAPH_RECONFIGURE();
      procedure  MAILGRAPH_STOP();
      
      function  get_ARTICA_PHP_PATH():string;
      function  get_ARTICA_DAEMON_LOG_MaxSizeLimit():integer;
      function  get_DEBUG_DAEMON():boolean;
      
      
      function  ARTICA_DAEMON_GET_PID():string;
      function  ARTICA_FILTER_GET_PID():string;
      function  ARTICA_FILTER_GET_ALL_PIDS():string;
      procedure ARTICA_FILTER_WATCHDOG();
      function  ARTICA_SEND_QUEUE_PATH():string;
      function  ARTICA_SEND_SUBQUEUE_NUMBER(QueueNumber:string):integer;
      function  ARTICA_SEND_MAX_SUBQUEUE_NUMBER:integer;
      function  ARTICA_FILTER_CHECK_PERMISSIONS():string;
      function  ARTICA_SEND_PID(QueueNumber:String):string;
      function  ARTICA_SEND_QUEUE_NUMBER():integer;
      procedure ARTICA_SEND_WATCHDOG_QUEUE();

      function  ARTICA_FILTER_QUEUEPATH():string;
      procedure ARTICA_FILTER_CLEAN_QUEUE();
      function  ARTICA_SQL_QUEUE_NUMBER():integer;
      function  ARTICA_SQL_PID():string;
      function  ARTICA_VERSION():string;
      
      function EMAILRELAY_PID():string;
      function EMAILRELAY_VERSION():string;
      procedure WATCHDOG_PURGE_BIGHTML();
      PROCEDURE RRD_MAILGRAPH_INSTALL();
      function ARTICA_FILTER_PID():string;


      function  get_kaspersky_mailserver_smtpscanner_logs_path():string;
      function  ExecStream(commandline:string;ShowOut:boolean):TMemoryStream;
      function  GetMonthNumber(MonthName:string):integer;
      function  Explode(const Separator, S: string; Limit: Integer = 0):TStringDynArray;
      procedure StripDiezes(filepath:string);
      function  PHP5_INI_PATH:string;
      procedure PHP5_ENABLE_GD_LIBRARY();
      function  PHP5_INI_SET_EXTENSION(librari:string):string;
      function  PHP5_IS_MODULE_EXISTS(modulename:string):boolean;
      
      
      function COMMANDLINE_PARAMETERS(FoundWhatPattern:string):boolean;
      function COMMANDLINE_EXTRACT_PARAMETERS(pattern:string):string;
      procedure DeleteFile(Path:string);
      procedure StatFile(path:string);
      function  FileSymbolicExists(path:string):boolean;
      function  StatFileSymbolic(Path:string):string;
      debug:boolean;
      echo_local:boolean;
      ArrayList:TStringList;
      constructor Create();
      destructor Destroy;virtual;

END;

implementation

constructor MyConf.Create();
var myFile:TextFile;
begin
       LOGS:=tlogs.Create;
       ArrayList:=TStringList.Create;
       download_silent:=false;
       if Not DirectoryExists('/opt/artica/logs') then begin
          forceDirectories('/opt/artica/logs');
          fpsystem('/bin/chmod 755 /opt/artica/logs');
       end;
end;

destructor MyConf.Destroy;
begin
  LOGS.Free;
  inherited Destroy;
end;
//##############################################################################
function myconf.SYSTEM_MARK_DEB_CDROM():string;
 var

    A:Boolean;
    l:TstringList;
    i:integer;
    RegExpr:TRegExpr;

begin
    A:=false;

    if not FileExists('/etc/apt/sources.list') then exit;
    
    l:=TstringList.Create;
    l.LoadFromFile('/etc/apt/sources.list');
    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='^deb cdrom';
    
    
    for i:=0 to l.Count-1 do begin
        if RegExpr.Exec(l.Strings[i]) then begin
           l.Strings[i]:='#' + l.Strings[i];
           A:=True;
        end;
    
    end;
    
    if A then l.SaveToFile('/etc/apt/sources.list');
    l.free;
    RegExpr.Free;
    
    result:='';
end;
//##############################################################################
procedure myconf.SYSTEM_SET_HOSTENAME(hostname:string);
 var
    F:boolean;
    l:TStringList;
    RegExpr:TRegExpr;
    i:integer;
begin

    fpsystem('/bin/echo "'+ hostname + '"  >/etc/hostname');
    fpsystem('/bin/echo "'+ hostname + '"  >/proc/sys/kernel/hostname');
    l:=TStringList.Create;
    F:=false;
    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='127\.0\.1\.1';;
    l.LoadFromFile('/etc/hosts');
     RegExpr.Expression:='127\.0\.1\.1';;
    for i:=0 to l.Count-1 do begin

      if RegExpr.Exec(l.Strings[i]) then begin
         l.Strings[i]:='127.0.1.1' + chr(9) + hostname;
         F:=true;
      end;
    end;

  if not F then begin
  RegExpr.Expression:='127\.0\.0\.1';;
    for i:=0 to l.Count-1 do begin

      if RegExpr.Exec(l.Strings[i]) then begin
         l.Strings[i]:='127.0.0.1' + chr(9) + hostname;
      end;
    end;
    
end;
l.SaveToFile('/etc/hosts');
    
end;
//##############################################################################

function myconf.SYSTEM_FQDN():string;
 var D:boolean;
begin
    D:=COMMANDLINE_PARAMETERS('debug');
    fpsystem('/bin/hostname >/opt/artica/logs/hostname.txt');
    result:=ReadFileIntoString('/opt/artica/logs/hostname.txt');
    result:=trim(result);
    if D then writeln('hostname=',result);
end;
//##############################################################################
function myconf.PURE_FTPD_VERSION():string;
var
   l:TstringList;
   i:integer;
   RegExpr:TRegExpr;
begin
    if Not Fileexists('/opt/artica/sbin/pure-ftpd') then exit;
    
    fpsystem('/opt/artica/sbin/pure-ftpd -h >/opt/artica/logs/pure.ftpd.h.txt');
    l:=TstringList.Create;
    l.LoadFromFile('/opt/artica/logs/pure.ftpd.h.txt');
    
    
    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='pure-ftpd v([0-9\.]+)';
    for i:=0 to l.Count-1 do begin
         if RegExpr.Exec(l.Strings[i]) then begin
            result:=RegExpr.Match[1];
            break;
         end;
    end;
    
l.free;
RegExpr.free;

    
end;
//##############################################################################
procedure  myconf.PURE_FTPD_SETCONFIG(key:string;value:string);
var
   l:TstringList;
   i:integer;
   RegExpr:TRegExpr;
   Found:boolean;
begin
  if not FileExists('/opt/artica/etc/pure-ftpd.conf') then exit;
  Found:=false;
  l:=TstringList.Create;
  l.LoadFromFile('/opt/artica/etc/pure-ftpd.conf');
  RegExpr:=TRegExpr.Create;
  RegExpr.Expression:='^' + key + '\s+';
  for i:=0 to l.Count -1 do begin
      if RegExpr.Exec(l.Strings[i]) then begin
          l.Strings[i]:=key + chr(9) + value;
          Found:=true;
          break;
      end;
  
  end;

  if Found=false then begin
  l.Add(key + chr(9) + value);
  l.SaveToFile('/opt/artica/etc/pure-ftpd.conf');
  end;
  l.Free;
  RegExpr.Free;

end;


//##############################################################################
procedure myconf.PURE_FTPD_PREPARE_LDAP_CONFIG();
var
   artica_admin            :string;
   artica_password         :string;
   artica_suffix           :string;
   ldap_server             :string;
   ldap_server_port        :string;
   l                       :TstringList;
begin

    artica_admin:=get_LDAP('admin');
    artica_password:=get_LDAP('password');
    artica_suffix:=get_LDAP('suffix');
    ldap_server:=Get_LDAP('server');
    ldap_server_port:=Get_LDAP('port');
    
    if length(ldap_server)=0 then ldap_server:='127.0.0.1';
    if length(ldap_server_port)=0 then ldap_server_port:='389';
    l:=TstringList.Create;

L.Add('LDAPServer ' + ldap_server);
L.Add('LDAPPort   ' + ldap_server_port);
L.Add('LDAPBaseDN ' + artica_suffix);
L.Add('LDAPBindDN cn=' + artica_admin + ',' + artica_suffix);
L.Add('LDAPBindPW ' + artica_password);
L.Add('LDAPFilter (&(objectClass=userAccount)(uid=\L)(FTPStatus=TRUE))');
L.Add('# LDAPHomeDir homeDirectory');
L.Add('LDAPVersion 3');
L.SaveToFile('/opt/artica/etc/pure-ftpd.ldap.conf');
l.free;
PURE_FTPD_SETCONFIG('PIDFile','/var/run/pure-ftpd.pid');
PURE_FTPD_SETCONFIG('AltLog','w3c:/opt/artica/logs/pureftpd.log');
PURE_FTPD_SETCONFIG('CreateHomeDir','yes');
PURE_FTPD_SETCONFIG('LDAPConfigFile','/opt/artica/etc/pure-ftpd.ldap.conf');

end;
//##############################################################################

function myconf.SYSTEM_IS_HOSTNAME_VALID() :boolean;
var
   hostname:string;
   exp:TStringDynArray;
   D:Boolean;
begin
    result:=false;
    hostname:=SYSTEM_FQDN();
     D:=COMMANDLINE_PARAMETERS('debug');
    exp:=Explode('.',hostname);
    
     if D then writeln(hostname + '=',length(exp));

    
    if length(exp)<2 then begin
       if D then writeln(intTostr(length(exp)) + '<2');
       result:=false;
       exit;
    end;
    result:=true;

end;
//##############################################################################
function myconf.POSFTIX_MASTER_CF_PATH:string;
var path:string;
begin
    path:=POSTFIX_EXTRAINFOS_PATH('main.cf');
    if FileExists(path) then exit(path);
    if FileExists('/etc/postfix/master.cf') then begin
       exit('/etc/postfix/master.cf');
    end;
end;
//##############################################################################
function myconf.POSFTIX_POSTCONF_PATH:string;
var
   path:string;
   D:Boolean;
begin
    D:=COMMANDLINE_PARAMETERS('debug');
    path:=POSTFIX_EXTRAINFOS_PATH('postconf');
    if D then writeln('POSFTIX_POSTCONF_PATH -> path:=' + path);
    if FileExists(path) then exit(path);
    if FileExists('/usr/sbin/postconf') then begin
           exit('/usr/sbin/postconf');
    end;

    if D then writeln('POSFTIX_POSTCONF_PATH -> unable to stat /usr/sbin/postconf');
           
end;
//##############################################################################
procedure myconf.ARTICA_SEND_WATCHDOG_QUEUE();
var
   QueuePath     :String;
   SYS           :TSystem;
   i             :integer;
   D             :boolean;
begin
  D:=COMMANDLINE_PARAMETERS('debug');
  SYS:=TSystem.Create;
  QueuePath:=ARTICA_FILTER_QUEUEPATH();
  if not DirectoryExists(QueuePath) then exit;
  SYS.DirFiles(QueuePath , '*.eml');
  if SYS.DirListFiles.Count=0 then begin
     SYS.Free;
     exit;
  end;
  
  for i:=0 to SYS.DirListFiles.Count -1 do begin
      if D then writeln('File....:',SYS.DirListFiles.Strings[i],' ',SYSTEM_FILE_BETWEEN_NOW(SYS.DirListFiles.Strings[i]));
      if SYSTEM_FILE_BETWEEN_NOW(SYS.DirListFiles.Strings[i])>5 then begin
          if D then writeln('File....:'+SYS.DirListFiles.Strings[i] + ' as more than 5 minutes on ' + QueuePath + ' dir, release it');
          logs.logs('ARTICA_SEND_WATCHDOG_QUEUE::'+ SYS.DirListFiles.Strings[i] + ' as more than 5 minutes on ' + QueuePath + ' dir, release it' );
          if D then writeln(ExtractFilePath(Paramstr(0)) + 'artica-send --release ' + SYS.DirListFiles.Strings[i]);
          fpsystem(ExtractFilePath(Paramstr(0)) + 'artica-send --release ' + SYS.DirListFiles.Strings[i]);
      end;
  end;
  SYS.Free;
end;
//##############################################################################

function myconf.LDAP_TESTS():string;
var  ldap:TLDAPSend;
l:TStringList;
i:integer;
begin
     ldap :=  TLDAPSend.Create;
     ldap.TargetHost := '127.0.0.1';
     ldap.TargetPort := '389';
     ldap.UserName := 'admin';
     ldap.Password := '180872';
     ldap.Version := 3;
     ldap.FullSSL := false;
     if ldap.Login then begin;
     writeln('logged');
        ldap.Bind;
        writeln('binded');
     end;
     
    l:=TstringList.Create;
    l.Add('displayname');
    l.Add('description');
    l.Add('givenName');
    l.Add('*');
    ldap.Search('dc=nodomain', False, '(objectclass=*)', l);
    //writeln(LDAPResultdump(ldap.SearchResult));
     showScreen('count=' + IntToStr(ldap.SearchResult.Count));
     for i:=0 to ldap.SearchResult.Count -1 do begin
       showscreen( ldap.SearchResult.Items[i].ObjectName);
       showscreen( 'attributes:=' +IntToStr(ldap.SearchResult.Items[i].Attributes.Count));
     
     end;
     writeln('logout');
     
     ldap.Logout;
     ldap.Free;
     result:='';
end;

//##############################################################################
function myconf.SYSTEM_GCC_PATH():string;
 begin
     if FileExists('/usr/bin/gcc') then exit('/usr/bin/gcc');
 end;
//##############################################################################
function myconf.SYSTEM_MAKE_PATH():string;
 begin
     if FileExists('/usr/bin/make') then exit('/usr/bin/make');
 end;
//##############################################################################
function  myconf.SYSTEM_GET_HTTP_PROXY:string;
var
   l:TStringList;
   i:integer;
   RegExpr:TRegExpr;

 begin
  if not FileExists('/etc/environment') then begin
     writeln('Unable to find /etc/environment');
     exit;
  end;
  
  
  l:=TStringList.Create;
  RegExpr:=TRegExpr.Create;
  RegExpr.Expression:='(http_proxy|HTTP_PROXY)=(.+)';
  
  l.LoadFromFile('/etc/environment');
  for i:=0 to l.Count -1 do begin
      if RegExpr.Exec(l.Strings[i]) then result:=RegExpr.Match[2];
  
  end;
 l.FRee;
 RegExpr.free;

end;
//##############################################################################
function  myconf.SYSTEM_REMOVE_HTTP_PROXY:string;
var
   l:TStringList;
   i:integer;
   RegExpr:TRegExpr;

 begin
  if not FileExists('/etc/environment') then begin
     writeln('Unable to find /etc/environment');
     exit;
  end;


  l:=TStringList.Create;
  RegExpr:=TRegExpr.Create;
  RegExpr.Expression:='(http_proxy|HTTP_PROXY)=(.+)';

  l.LoadFromFile('/etc/environment');
  for i:=0 to l.Count -1 do begin
      if RegExpr.Exec(l.Strings[i]) then begin
          l.Delete(i);
          break;
      end;
  end;
  l.SaveToFile('/etc/environment');
  
  
  if FileExists('/etc/wgetrc') then begin
      RegExpr:=TRegExpr.Create;
      RegExpr.Expression:='^http_proxy(.+)';
      l.LoadFromFile('/etc/wgetrc');
      For i:=0 to l.Count-1 do begin
          if RegExpr.Exec(l.Strings[i]) then begin
             l.Strings[i]:='#' + l.Strings[i];
             l.SaveToFile('/etc/wgetrc');
             break;
          end;
      end;
  end;

  
  l.free;
  RegExpr.free;
  result:='';
end;



function myconf.WGET_DOWNLOAD_FILE(uri:string;file_path:string):boolean;
var
   RegExpr:TRegExpr;
   ProxyString:string;
   ProxyCommand:string;
   ProxyUser:string;
   ProxyPassword:string;
   ProxyName:string;
   commandline_artica:string;
   command_line_curl:string;
   command_line_wget:string;

   D:boolean;
 begin
   D:=COMMANDLINE_PARAMETERS('debug');
   command_line_curl:='';
   RegExpr:=TRegExpr.Create;
   ProxyString:=SYSTEM_GET_HTTP_PROXY();
   ProxyString:=AnsiReplaceStr(ProxyString,'"','');
   ProxyString:=AnsiReplaceStr(ProxyString,'http://','');
   if download_silent then command_line_curl:=' --silent ';
   command_line_curl:= command_line_curl + ' --progress-bar --output ' + file_path + ' ' + uri;
   
   
   if length(ProxyString)>0 then begin

       RegExpr.Expression:='(.+?):(.+?)@(.+)';
       if RegExpr.Exec(ProxyString) then begin
            ProxyUser:=RegExpr.Match[1];
            ProxyPassword:=RegExpr.Match[2];
            ProxyName:=RegExpr.Match[3];
       end;
       RegExpr.Expression:='(.+?)@(.+)';
       if RegExpr.Exec(ProxyString) then begin
           ProxyUser:=RegExpr.Match[1];
           ProxyName:=RegExpr.Match[3];
       end;
   end;

   if length(ProxyName)=0 then ProxyName:=ProxyString;
   
   if length(ProxyName)>0 then begin
      ProxyCommand:='--proxy ' +  ProxyName;
      if length(ProxyUser)>0 then begin
         if length(ProxyPassword)>0 then begin
            ProxyCommand:='--proxy ' +  ProxyName + ' --proxy-user ' + ProxyUser + ':' + ProxyPassword;
         end else begin
            ProxyCommand:='--proxy ' +  ProxyName + ' --proxy-user ' + ProxyUser;
         end;
      end;
     command_line_curl:=ProxyCommand + ' --progress-bar --output ' + file_path + ' ' + uri;
      
   end;


   command_line_wget:=uri + '  -q --output-document=' + file_path;

   
   if FileExists('/opt/artica/bin/curl') then begin
       command_line_curl:='/opt/artica/bin/curl ' + command_line_curl;
         if D then writeln(command_line_curl);
         fpsystem(command_line_curl);
         exit;
   
   end;
   
   
   
   if FileExists('/usr/local/bin/curl') then begin
         command_line_curl:='/usr/local/bin/curl ' + command_line_curl;
         if D then writeln(command_line_curl);
         fpsystem(command_line_curl);
         exit;
   end;
   
   if FileExists('/usr/bin/curl') then begin
      command_line_curl:='/usr/bin/curl ' + command_line_curl;
         if D then writeln(command_line_curl);
         fpsystem(command_line_curl);
         exit;
   end;
   
  if FileExists('/usr/bin/wget') then begin
     if length(ProxyName)>0 then begin
         SYSTEM_SET_HTTP_PROXY(SYSTEM_GET_HTTP_PROXY());
     end;
     command_line_wget:='/usr/bin/wget ' + command_line_wget;
     if D then writeln(command_line_wget);
        fpsystem(command_line_wget);
     exit;
  end;
   
   

     if length(ProxyName)>0 then ProxyCommand:='--proxy=on --proxy-name=' + ProxyName;
     if length(ProxyUser)>0 then ProxyCommand:='--proxy=on --proxy-name=' + ProxyName  + ' --proxy-user=' + ProxyUser;
     if length(ProxyPassword)>0 then ProxyCommand:='--proxy=on --proxy-name=' + ProxyName  + ' --proxy-user=' + ProxyUser + ' --proxy-passwd=' + ProxyPassword;
     commandline_artica:=ExtractFilePath(ParamStr(0)) + 'artica-get  '+ uri + ' ' + ProxyCommand + ' -q --output-document=' + file_path;
     if D then writeln(commandline_artica);
     fpsystem(commandline_artica);
     result:=true;





end;
//##############################################################################


procedure  myconf.SYSTEM_SET_HTTP_PROXY(proxy_string:string);
var
   l:TStringList;
   i:integer;
   RegExpr:TRegExpr;
   found_proxy:boolean;

 begin
  if not FileExists('/etc/environment') then begin
     writeln('Unable to find /etc/environment');
     exit;
  end;
 SYSTEM_REMOVE_HTTP_PROXY();

  l:=TStringList.Create;
  l.LoadFromFile('/etc/environment');
  l.Add('http_proxy="'+ proxy_string + '"');
  l.SaveToFile('/etc/environment');
  writeln('export http_proxy="'+ proxy_string + '" --> done');
  fpsystem('export http_proxy="'+ proxy_string + '"');
  writeln('env http_proxy='+ proxy_string + '" --> done');
  fpsystem('env http_proxy='+ proxy_string);

  
  if FileExists('/etc/wgetrc') then begin
      RegExpr:=TRegExpr.Create;
      RegExpr.Expression:='^http_proxy(.+)';
      l.LoadFromFile('/etc/wgetrc');
      For i:=0 to l.Count-1 do begin
          if RegExpr.Exec(l.Strings[i]) then begin
             found_proxy:=true;
             l.Strings[i]:='http_proxy = ' + proxy_string;
             l.SaveToFile('/etc/wgetrc');
             break;
          end;
      end;
      
     if found_proxy=false then begin
          l.Add('http_proxy = ' + proxy_string);
          l.SaveToFile('/etc/wgetrc');
     end;
     
  end;

   l.free;
  
end;
//##############################################################################


FUNCTION myconf.SYSTEM_ENV_PATHS():string;
var
   Path:string;
   res:string;

 begin
     if FileExists('/usr/bin/printenv') then Path:='/usr/bin/printenv';
     if length(Path)=0 then exit;
     res:=ExecPipe(Path + ' PATH');
     result:=res;
end;
//##############################################################################
procedure Myconf.SYSTEM_ENV_PATH_SET(path:string);
var
 Table:TStringDynArray;
 datas:string;
 i:integer;
 newpath:string;
 D:Boolean;
begin
     D:=COMMANDLINE_PARAMETERS('debug');
     datas:=SYSTEM_ENV_PATHS();
     if length(datas)>1 then begin
        Table:=Explode(':',SYSTEM_ENV_PATHS());
        For i:=0 to Length(Table)-1 do begin
                 if D then writeln('SYSTEM_ENV_PATH_SET -> ' + path + ' already exists in env');
                 LOGS.logs('SYSTEM_ENV_PATH_SET -> ' + path + ' already exists in env');
                if Table[i]=path then exit;
        end;
     end;

    LOGS.logs('SYSTEM_ENV_PATH_SET -> ' + path);
    newpath:=SYSTEM_ENV_PATHS() + ':' + path;
    fpsystem('/usr/bin/env PATH=' + newpath + ' >/opt/artica/logs/env.tmp');

end;
//##############################################################################


function myconf.SYSTEM_VERIFY_CRON_TASKS();
var
   l:Tstringlist;

begin
  l:=TStringList.Create;

  if Not FileExists('/etc/cron.d/artica-cron-quarantine') then begin
      writeln('Create quarantine maintenance task in background;...');
      l.Add('#{artica-cron-quarantine_text}');
      l.Add('0 3 * * *  root ' +get_ARTICA_PHP_PATH() +'/bin/artica-quarantine -maintenance >/dev/null');
      l.SaveToFile('/etc/cron.d/artica-cron-quarantine');
  end;
  
l.Free;

if not FileExists('/etc/cron.d/artica_yorel') then YOREL_RECONFIGURE('');

result:='';

end;
//##############################################################################


function myconf.COMMANDLINE_PARAMETERS(FoundWhatPattern:string):boolean;
var
   i:integer;
   s:string;
   RegExpr:TRegExpr;

begin
 result:=false;
 s:='';
 if ParamCount>1 then begin
     for i:=2 to ParamCount do begin
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
function myconf.COMMANDLINE_EXTRACT_PARAMETERS(pattern:string):string;
var
   i:integer;
   s:string;
   RegExpr:TRegExpr;

begin
s:='';
 result:='';
 if ParamCount>1 then begin
     for i:=2 to ParamCount do begin
        s:=s  + ' ' +ParamStr(i);
     end;
 end;

         RegExpr:=TRegExpr.Create;
         RegExpr.Expression:=pattern;
         RegExpr.Exec(s);
         Result:=RegExpr.Match[1];
         RegExpr.Free;
end;
//##############################################################################
procedure myconf.DSPAM_EDIT_PARAM(key:string;value:string);
var
   i:integer;
   s:string;
   RegExpr:TRegExpr;
   l:TstringList;
   D:boolean;
begin
D:=COMMANDLINE_PARAMETERS('debug');
if not FileExists('/etc/dspam/dspam.conf') then exit;
l:=TstringList.Create;
l.LoadFromFile('/etc/dspam/dspam.conf');
s:=DSPAM_GET_PARAM(key);
   if length(s)=0 then begin
        if D then writeln('DSPAM_EDIT_PARAM:: Add the value "'+value+'"');
        l.Add(key + ' ' + value);
        l.SaveToFile('/etc/dspam/dspam.conf');
        l.free;
        exit();
   end;
   
RegExpr:=TRegExpr.Create;
RegExpr.Expression:='^' + key + '\s+(.+)';
for i:=0 to l.Count -1 do begin
   if RegExpr.Exec(l.Strings[i]) then begin
       l.Strings[i]:=key + ' ' + value;
       l.SaveToFile('/etc/dspam/dspam.conf');
       break;
   end;
end;
 RegExpr.Free;
 l.Free;

end;
//##############################################################################
function myconf.DSPAM_BIN_PATH():string;
begin
if FileExists('/usr/local/bin/dspam') then exit('/usr/local/bin/dspam');
if FileExists('/usr/bin/dspam') then exit('/usr/bin/dspam');
end;


//##############################################################################
procedure myconf.DSPAM_EDIT_PARAM_MULTI(key:string;value:string);
var

   s:string;
   l:TstringList;
   D:boolean;
begin
s:='';
D:=COMMANDLINE_PARAMETERS('debug');
if not FileExists('/etc/dspam/dspam.conf') then exit;
if DSPAM_IS_PARAM_EXISTS(key,value) then exit;
l:=TstringList.Create;
l.LoadFromFile('/etc/dspam/dspam.conf');



   if length(s)=0 then begin
        if D then writeln('DSPAM_EDIT_PARAM:: Add the value "'+value+'"');
        l.Add(key + ' ' + value);
        l.SaveToFile('/etc/dspam/dspam.conf');
        l.free;
        exit();
   end;

 l.Free;

end;

//##############################################################################
procedure myconf.DSPAM_REMOVE_PARAM(key:string);
var
   i:integer;
   RegExpr:TRegExpr;
   l:TstringList;
   D:boolean;
begin
D:=COMMANDLINE_PARAMETERS('debug');
if not FileExists('/etc/dspam/dspam.conf') then exit;
l:=TstringList.Create;
l.LoadFromFile('/etc/dspam/dspam.conf');


RegExpr:=TRegExpr.Create;
RegExpr.Expression:='^' + key + '\s+(.+)';
for i:=0 to l.Count -1 do begin
   if RegExpr.Exec(l.Strings[i]) then begin
      if D then writeln('remove line:',i);
       l.Delete(i);
       l.SaveToFile('/etc/dspam/dspam.conf');
       RegExpr.Free;
       l.Free;
       DSPAM_REMOVE_PARAM(key);
       exit;
   end;
end;


 l.SaveToFile('/etc/dspam/dspam.conf');
 RegExpr.Free;
 l.Free;

end;

//##############################################################################
function myconf.DSPAM_GET_PARAM(key:string):string;
var
   i:integer;
   RegExpr:TRegExpr;
   l:TStringList;

begin
if not FileExists('/etc/dspam/dspam.conf') then exit;
l:=TStringList.Create;
l.LoadFromFile('/etc/dspam/dspam.conf');
RegExpr:=TRegExpr.Create;
RegExpr.Expression:='^' + key + '\s+(.+)';
for i:=0 to l.Count -1 do begin
   if RegExpr.Exec(l.Strings[i]) then begin
       result:=trim(RegExpr.Match[1]);
       break;
   end;

end;
 RegExpr.Free;
 l.Free;


end;
//##############################################################################
function myconf.DSPAM_IS_PARAM_EXISTS(key:string;value:string):boolean;
var
   i:integer;
   RegExpr:TRegExpr;
   l:TStringList;

begin
result:=false;
if not FileExists('/etc/dspam/dspam.conf') then exit;
l:=TStringList.Create;
l.LoadFromFile('/etc/dspam/dspam.conf');
RegExpr:=TRegExpr.Create;
RegExpr.Expression:='^' + key + '\s+(.+)';
for i:=0 to l.Count -1 do begin
   if RegExpr.Exec(l.Strings[i]) then begin
       if value=RegExpr.Match[1] then begin
          result:=true;
          break;
       end;
   end;

end;
 RegExpr.Free;
 l.Free;


end;
//##############################################################################


function MyConf.get_SELINUX_ENABLED():boolean;
var filedatas:string;
RegExpr:TRegExpr;
begin
result:=false;
if not FileExists('/etc/selinux/config') then exit(False);
 filedatas:=ReadFileIntoString('/etc/selinux/config');
  RegExpr:=TRegExpr.create;
  RegExpr.Expression:='SELINUX=(enforcing|permissive|disabled)';
  if RegExpr.Exec(filedatas) then begin
         if RegExpr.Match[1]='permissive' then result:=True;
         if RegExpr.Match[1]='enforcing' then result:=True;
         if RegExpr.Match[1]='disabled' then result:=false;
       end
       else begin
          result:=False;
  end;
 end;
//##############################################################################
procedure Myconf.PHP5_ENABLE_GD_LIBRARY();
var
     RegExpr:TRegExpr;
     php_ini,apache_init:string;
     logs:Tlogs;
     FileData:TStringList;
     i:integer;
begin
logs:=Tlogs.Create();
php_ini:=PHP5_INI_PATH();
apache_init:=APACHE_GET_INITD_PATH();

if length(php_ini)=0 then begin
  logs.logsInstall('PHP5_ENABLE_GD_LIBRARY:: WARNING unable to locate php.ini file !!!');
  writeln('WARNING unable to locate php.ini file !!!');
  exit;
end;

if length(apache_init)=0 then begin
  logs.logsInstall('PHP5_ENABLE_GD_LIBRARY:: WARNING unable to locate apache init !!!');
  writeln('WARNING unable to locate apache init !!!');
  exit;
end;


    if debug then writeln('Enable GD Library for PHP');
    FileData:=TStringList.Create;
    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='^extension=gd.so';
    
    if debug then begin
       writeln('Reading file "' + php_ini + '"');
       logs.logsInstall('PHP5_ENABLE_GD_LIBRARY::Reading file "' + php_ini + '"');
    end;
    
    FileData.LoadFromFile(php_ini);
    
    for i:=0 to FileData.Count -1 do begin
        if RegExpr.exec(FileData.Strings[i]) then begin
            logs.logsInstall('PHP5_ENABLE_GD_LIBRARY:: gd library is already set');
            writeln('GD Library already set...nothing to do');
            RegExpr.Free;
            FileData.Free;
            exit();
        end;
    end;
    
 logs.logsInstall('PHP5_ENABLE_GD_LIBRARY:: adding gd library');
 if debug then writeln('Set GD Library..');
 FileData.Add('extension=gd.so');
 FileData.SaveToFile(php_ini);
  if debug then writeln('Restarting apache');
  fpsystem(apache_init + ' restart');
    

end;
//#############################################################################

procedure MyConf.set_SELINUX_DISABLED();
var list:TstringList;
begin

if fileExists('/etc/rc.d/boot.apparmor') then begin
      ShowScreen('set_SELINUX_DISABLED:: Disable AppArmor...');
      fpsystem('/etc/init.d/boot.apparmor stop');
      fpsystem('/sbin/chkconfig -d boot.apparmor');
end;

if fileExists('/sbin/SuSEfirewall2') then begin
   ShowScreen('set_SELINUX_DISABLED:: Disable SuSEfirewall2...');
   fpsystem('/sbin/SuSEfirewall2 off');
end;
if FileExists('/etc/selinux/config') then begin
   killfile('/etc/selinux/config');
   list:=TstringList.Create;
   list.Add('SELINUX=disabled');
   list.SaveToFile('/etc/selinux/config');
   list.Free;
end;
end;
//#############################################################################
function MyConf.ARTICA_MYSQL_INFOS(val:string):string;
var ini:TIniFile;
begin
if not FileExists('/etc/artica-postfix/artica-mysql.conf') then exit();
ini:=TIniFile.Create('/etc/artica-postfix/artica-mysql.conf');
result:=ini.ReadString('MYSQL',val,'');
ini.Free;
end;
//#############################################################################
function MyConf.MYSQL_INIT_PATH:string;
var path:string;
begin
  path:=LINUX_APPLICATION_INFOS('mysql_init');
  if length(path)>0 then begin
           if FileExists(path) then exit(path);
  end;
  
  if FileExists('/etc/init.d/mysql') then exit('/etc/init.d/mysql');
  if FileExists('/etc/init.d/mysqld') then exit('/etc/init.d/mysqld');
  
end;
//#############################################################################
function MyConf.MYSQL_MYCNF_PATH:string;
var path:string;
begin
  if FileExists('/opt/artica/etc/my.cnf') then exit('/opt/artica/etc/my.cnf');
  path:=LINUX_APPLICATION_INFOS('my_cnf');
  if length(path)>0 then begin
           if FileExists(path) then exit(path);
  end;

  if FileExists('/etc/mysql/my.cnf') then exit('/etc/mysql/my.cnf');
  if FileExists('/etc/my.cnf') then exit('/etc/my.cnf');

end;
//#############################################################################
function Myconf.MYSQL_SERVER_PARAMETERS_CF(key:string):string;
var ini:TiniFile;
begin
  result:='';
  if not FileExists(MYSQL_MYCNF_PATH()) then exit();
  ini:=TIniFile.Create(MYSQL_MYCNF_PATH());
  result:=ini.ReadString('mysqld',key,'');
  ini.free;
end;
//#############################################################################
function MyConf.MYSQL_BIN_PATH:string;
var path:string;
begin

  if FileExists('/opt/artica/bin/mysql') then exit('/opt/artica/bin/mysql');
  
  path:=LINUX_APPLICATION_INFOS('mysql_bin');
  if length(path)>0 then begin
           if FileExists(path) then exit(path);
  end;
  if FileExists('/usr/bin/mysql') then exit('/usr/bin/mysql');

end;
//#############################################################################
function MyConf.MYSQL_VERSION:string;
var mysql_bin,returned:string;
    RegExpr:TRegExpr;
begin
   mysql_bin:=MYSQL_BIN_PATH();
   if not FileExists(mysql_bin) then exit;
   returned:=ExecPipe(mysql_bin + ' -V');
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='([0-9]+\.[0-9]+\.[0-9]+)';
   if RegExpr.Exec(returned) then result:=RegExpr.Match[1];
   RegExpr.Free;

end;
//#############################################################################
function MyConf.AWSTATS_MAILLOG_CONVERT_PATH_SOURCE():string;
begin
if FileExists('/usr/share/doc/awstats/examples/maillogconvert.pl') then exit('/usr/share/doc/awstats/examples/maillogconvert.pl');
if FileExists('/usr/share/awstats/tools/maillogconvert.pl') then exit('/usr/share/awstats/tools/maillogconvert.pl');
if FileExists('/usr/share/doc/packages/awstats/tools/maillogconvert.pl') then exit('/usr/share/doc/packages/awstats/tools/maillogconvert.pl');
end;
//#############################################################################
function MyConf.AWSTATS_PATH():string;
begin
if FileExists('/usr/lib/cgi-bin/awstats.pl') then exit('/usr/lib/cgi-bin/awstats.pl');
if FileExists('/srv/www/cgi-bin/awstats.pl') then exit('/srv/www/cgi-bin/awstats.pl');
if FileExists('/var/www/awstats/awstats.pl') then exit('/var/www/awstats/awstats.pl');
if FileExists('/usr/share/awstats/wwwroot/cgi-bin/awstats.pl') then exit('/usr/share/awstats/wwwroot/cgi-bin/awstats.pl');
end;

//#############################################################################
function MyConf.AWSTATS_GET_VALUE(key:string):string;
var
    RegExpr:TRegExpr;
    FileDatas:TStringList;
    i:integer;
    ValueResulted:string;
begin
   if not FileExists('/etc/awstats/awstats.mail.conf') then  begin
      showscreen('AWSTATS_GET_VALUE:: unable to stat /etc/awstats/awstats.mail.conf');
      exit;
   end;
   FileDatas:=TStringList.Create;
   FileDatas.LoadFromFile('/etc/awstats/awstats.mail.conf');
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^'+key+'([="''\s]+)(.+)';
   for i:=0 to FileDatas.Count -1 do begin
           if RegExpr.Exec(FileDatas.Strings[i]) then begin
              FileDatas.Free;
              ValueResulted:=RegExpr.Match[2];
              if ValueResulted='"' then ValueResulted:='';
              RegExpr.Free;
              exit(ValueResulted);
           end;
   
   end;
   FileDatas.Free;
   RegExpr.Free;

end;
//#############################################################################

function MyConf.AWSTATS_SET_VALUE(key:string;value:string):string;
var
    RegExpr:TRegExpr;
    FileDatas:TStringList;
    i:integer;
begin
   if not FileExists('/etc/awstats/awstats.mail.conf') then  begin
      showscreen('AWSTATS_GET_VALUE:: unable to stat /etc/awstats/awstats.mail.conf');
      exit;
   end;
   FileDatas:=TStringList.Create;
   FileDatas.LoadFromFile('/etc/awstats/awstats.mail.conf');
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^'+key+'([="''\s]+)(.+)';
   for i:=0 to FileDatas.Count -1 do begin
           if RegExpr.Exec(FileDatas.Strings[i]) then begin
                FileDatas.Strings[i]:=key + '=' + value;
                FileDatas.SaveToFile('/etc/awstats/awstats.mail.conf');
                FileDatas.Free;
                RegExpr.Free;
                exit;

           end;

   end;

  FileDatas.Add(key + '=' + value);
  FileDatas.SaveToFile('/etc/awstats/awstats.mail.conf');
  FileDatas.Free;
  RegExpr.Free;
  result:='';

end;
//#############################################################################
function MyConf.DNSMASQ_GET_VALUE(key:string):string;
var
    RegExpr:TRegExpr;
    FileDatas:TStringList;
    i:integer;
    ValueResulted:string;
begin
   if not FileExists('/etc/dnsmasq.conf') then  exit;
   FileDatas:=TStringList.Create;
   FileDatas.LoadFromFile('/etc/dnsmasq.conf');
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^'+key+'([="''\s]+)(.+)';
   for i:=0 to FileDatas.Count -1 do begin
           if RegExpr.Exec(FileDatas.Strings[i]) then begin
              FileDatas.Free;
              ValueResulted:=RegExpr.Match[2];
              if ValueResulted='"' then ValueResulted:='';
              RegExpr.Free;
              exit(ValueResulted);
           end;

   end;
   FileDatas.Free;
   RegExpr.Free;

end;
//#############################################################################
function MyConf.DNSMASQ_SET_VALUE(key:string;value:string):string;
var
    RegExpr:TRegExpr;
    FileDatas:TStringList;
    i:integer;
    FileToEdit:string;
begin
   FileToEdit:='/etc/dnsmasq.conf';
   if not FileExists(FileToEdit) then  fpsystem('/bin/touch ' + FileToEdit);
   FileDatas:=TStringList.Create;
   FileDatas.LoadFromFile(FileToEdit);
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^'+key+'([="''\s]+)(.+)';
   for i:=0 to FileDatas.Count -1 do begin
           if RegExpr.Exec(FileDatas.Strings[i]) then begin
                FileDatas.Strings[i]:=key + '=' + value;
                FileDatas.SaveToFile(FileToEdit);
                FileDatas.Free;
                RegExpr.Free;
                exit;

           end;

   end;

  FileDatas.Add(key + '=' + value);
  FileDatas.SaveToFile(FileToEdit);
  FileDatas.Free;
  RegExpr.Free;
  result:='';

end;
//#############################################################################
function MyConf.SYSTEM_ADD_NAMESERVER(nameserver:string):boolean;
var
   FileDatas:Tstringlist;
   RegExpr:TRegExpr;
   FileToEdit:string;
   i:integer;
begin
   FileToEdit:='/etc/resolv.conf';
   if not FileExists(FileToEdit) then  begin
      showscreen('SYSTEM_ADD_NAMESERVER:: unable to stat ' + FileToEdit);
      exit(false);
   end;
   
   FileDatas:=TStringList.Create;
   FileDatas.LoadFromFile(FileToEdit);
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^nameserver\s+' +nameserver;
   for i:=0 to FileDatas.Count -1 do begin
       if RegExpr.Exec(FileDatas.Strings[i]) then begin
          RegExpr.free;
          FileDatas.free;
          exit(true);
       end;
   end;
   
   FileDatas.Insert(0,'nameserver ' + nameserver);
   FileDatas.SaveToFile(FileToEdit);
   RegExpr.free;
   FileDatas.free;
   exit(true);
end;

//#############################################################################
function MyConf.DNSMASQ_BIN_PATH():string;
begin
    if FileExists('/usr/sbin/dnsmasq') then exit('/usr/sbin/dnsmasq');
    if FileExists('/usr/local/sbin/dnsmasq') then exit('/usr/local/sbin/dnsmasq');
end;
//#############################################################################
function MyConf.SYSTEM_LD_SO_CONF_ADD(path:string):string;
var
 FileDatas:TStringList;
 i:integer;
begin
     FileDatas:=TStringList.Create;
    FileDatas.LoadFromFile('/etc/ld.so.conf');
    for i:=0 to FileDatas.Count -1 do begin
      if trim(FileDatas.Strings[i])=path then begin
         ShowScreen('SYSTEM_LD_SO_CONF_ADD:: "' + path + '" already added to /etc/ld.so.conf');
         FileDatas.Free;
         exit;
      end;
    end;
    
     FileDatas.Add(path);
     FileDatas.SaveToFile('/etc/ld.so.conf');
     FileDatas.Free;
     ShowScreen('SYSTEM_LD_SO_CONF_ADD:: -> ldconfig ... Please wait...');
     fpsystem('ldconfig');
     result:='';
    
   
   

end;

//#############################################################################
function MyConf.AWSTATS_VERSION():string;
var
    RegExpr,RegExpr2:TRegExpr;
    FileDatas:TStringList;
    i:integer;
    Major,minor,awstats_root:string;
    D:boolean;
begin
     D:=COMMANDLINE_PARAMETERS('debug');
    awstats_root:=AWSTATS_PATH();

    
    
    if length(awstats_root)=0 then begin
       if D then ShowScreen('AWSTATS_VERSION::unable to locate awstats.pl');
      exit;
   end;
   
    if D then ShowScreen('AWSTATS_VERSION:: ->'+ awstats_root);
   
   FileDatas:=TStringList.Create;
   FileDatas.LoadFromFile(awstats_root);
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^\$VERSION="([0-9\.]+)';
   
   RegExpr2:=TRegExpr.Create;
   RegExpr2.Expression:='^\$REVISION=''\$Revision:\s+([0-9\.]+)';
   
   for i:=0 to FileDatas.Count -1 do begin
           if RegExpr.Exec(FileDatas.Strings[i]) then begin
              if D then ShowScreen('AWSTATS_VERSION:: found ->'+ FileDatas.Strings[i] + '(' +RegExpr.Match[1]  + ')' );
              Major:=RegExpr.Match[1];
           end;
           if RegExpr2.Exec(FileDatas.Strings[i]) then begin
              if D then ShowScreen('AWSTATS_VERSION:: found ->'+ FileDatas.Strings[i] + '(' +RegExpr2.Match[1]  + ')' );
              minor:=RegExpr2.Match[1];
           end;
           if length(Major)>0 then begin
                  if length(minor)>0 then begin
                  AWSTATS_VERSION:=major + ' rev ' + minor;
                  FileDatas.Free;
                  RegExpr.Free;
                  RegExpr2.Free;
                  exit;
                  end;
           end;

   end;
                  FileDatas.Free;
                  RegExpr.Free;
                  RegExpr2.Free;
                  AWSTATS_VERSION:=major;

end;

//#############################################################################

procedure MyConf.AWSTATS_GENERATE();
var maintool,artica_path:string;
 FileDatas:TStringList;
 D:boolean;
 i:integer;
 Zcommand,zConfig:string;
begin
     D:=COMMANDLINE_PARAMETERS('debug');
    if not D then D:=COMMANDLINE_PARAMETERS('generate');
    if not D then D:=COMMANDLINE_PARAMETERS('reconfigure');
     
    artica_path:=get_INSTALL_PATH();
    maintool:=AWSTATS_PATH();
    FileDatas:=TStringList.Create;
    FileDatas.LoadFromFile(artica_path + '/ressources/databases/awstats.pages.db');
    
    if length(maintool)=0 then begin
       if D then ShowScreen('AWSTATS_GENERATE:: unable to locate awstats.pl');
       exit;
    end;

    fpsystem(maintool + ' -update -config=mail');
    for i:=0 to FileDatas.Count -1 do begin
          zConfig:=trim(FileDatas.Strings[i]);
          if zConfig='index' then begin
             Zcommand:=maintool + ' -config=mail -staticlinks -output >' + artica_path + '/ressources/logs/awstats.' + zConfig + '.tmp';
          end else begin
              Zcommand:=maintool + ' -config=mail -output=' + zConfig + ' -staticlinks >' + artica_path + '/ressources/logs/awstats.' + zConfig + '.tmp';
          end;
          if D then ShowScreen('AWSTATS_GENERATE::' + Zcommand);
          fpsystem(Zcommand);
    end;
   FileDatas.Free;

end;



//#############################################################################
function MyConf.AWSTATS_SET_PLUGIN(value:string):string;
var
    RegExpr:TRegExpr;
    FileDatas:TStringList;
    i:integer;
begin
   result:='';
   AWSTATS_SET_PLUGIN:='';
   if not FileExists('/etc/awstats/awstats.mail.conf') then  begin
      showscreen('AWSTATS_SET_PLUGIN:: unable to stat /etc/awstats/awstats.mail.conf');
      exit;
   end;
   FileDatas:=TStringList.Create;
   FileDatas.LoadFromFile('/etc/awstats/awstats.mail.conf');
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^LoadPlugin="' + value + '"';
   for i:=0 to FileDatas.Count -1 do begin
           if RegExpr.Exec(FileDatas.Strings[i]) then begin
                ShowScreen('AWSTATS_SET_PLUGIN:: Plugin ' + value + ' already added');
                FileDatas.Free;
                RegExpr.Free;
                exit;

           end;

   end;
  ShowScreen('AWSTATS_SET_PLUGIN:: Add Plugin ' + value);
  FileDatas.Add('LoadPlugin="' + value + '"');
  FileDatas.SaveToFile('/etc/awstats/awstats.mail.conf');
  FileDatas.Free;
  RegExpr.Free;


end;

//#############################################################################


function MyConf.ARTICA_MYSQL_SET_INFOS(val:string;value:string):boolean;
var ini:TIniFile;
begin
result:=true;
ini:=TIniFile.Create('/etc/artica-postfix/artica-mysql.conf');
ini.WriteString('MYSQL',val,value);
ini.Free;
end;
//#############################################################################
function MyConf.MYSQL_ROOT():string;
begin
   result:=ARTICA_MYSQL_INFOS('database_admin');
   if length(result)=0 then result:='root';
end;
//#############################################################################
function MyConf.MYSQL_PASSWORD():string;
begin
   result:=ARTICA_MYSQL_INFOS('database_password');
   if length(result)=0 then result:='';
end;
//#############################################################################
function MyConf.MYSQL_SERVER():string;
begin
   result:=ARTICA_MYSQL_INFOS('mysql_server');
   if length(result)=0 then result:='localhost';
end;
//#############################################################################
function MyConf.MYSQL_ENABLED():boolean;
var s:string;
begin
   result:=true;
   s:=ARTICA_MYSQL_INFOS('use_mysql');
   s:=LowerCase(s);
   if s='yes' then result:=true;
   if s='no' then result:=false;
end;
//#############################################################################
function MyConf.ARTICA_VERSION():string;
var
   l:string;
   F:TstringList;
   
begin
   l:=get_ARTICA_PHP_PATH() + '/VERSION';
   if not FileExists(l) then exit('0.00');
   F:=TstringList.Create;
   F.LoadFromFile(l);
   result:=trim(F.Text);
   F.Free;
end;
//#############################################################################
function MyConf.MYSQL_ACTION_TESTS_ADMIN():boolean;
    var root,password,commandline,cmd_result:string;
begin
  root:=MYSQL_ROOT();
  password:=MYSQL_PASSWORD();
  if not fileExists('/usr/bin/mysql') then exit(false);
  if length(password)>0 then password:=' -p'+password;
  commandline:=MYSQL_EXEC_BIN_PATH() + ' -e ''select User,Password from user'' -u '+ root +password+' mysql';
  cmd_result:=ExecPipe(commandline);
  if length(cmd_result)>0 then exit(true) else exit(false);
end;
//#############################################################################
function MyConf.MYSQL_ACTION_COUNT_TABLES(database_name:string):integer;
    var root,commandline,password:string;
    list:TStringList;
    i:integer;
    XDebug:boolean;
    RegExpr:TRegExpr;
    count:integer;
begin
  count:=0;
  root:=MYSQL_ROOT();
  password:=MYSQL_PASSWORD();
  XDebug:=COMMANDLINE_PARAMETERS('debug');
  if length(password)>0 then password:=' -p'+password;
  if not fileExists('/usr/bin/mysql') then exit(0);
  commandline:=MYSQL_EXEC_BIN_PATH() + ' -N -s -X -e ''show tables'' -u '+ root +password + ' ' + database_name;
  if XDebug then ShowScreen('MYSQL_ACTION_COUNT_TABLES::'+commandline);
  list:=TStringList.Create;
  list.LoadFromStream(ExecStream(commandline,false));
  if list.Count<2 then begin
    list.free;
    exit(0);
  end;

RegExpr:=TRegExpr.Create;
  RegExpr.Expression:='<field name="Tables_in_' +database_name + '">(.+)<\/field>';
  //ShowScreen('MYSQL_ACTION_COUNT_TABLES::'+RegExpr.Expression);
  for i:=0 to list.count-1 do begin
      if RegExpr.Exec(list.Strings[i]) then inc(count);

  end;
  
list.free;
RegExpr.free;
exit(count);

end;
//#############################################################################
function MyConf.MYSQL_ACTION_IF_DATABASE_EXISTS(database_name:string):boolean;
    var root,commandline,password:string;
    list:TStringList;
    i:integer;
    XDebug:boolean;
    RegExpr:TRegExpr;
begin
  root:=MYSQL_ROOT();
  password:=MYSQL_PASSWORD();
  XDebug:=COMMANDLINE_PARAMETERS('debug');
  if length(password)>0 then password:=' -p'+password;
  if not fileExists('/usr/bin/mysql') then exit(false);
  commandline:=MYSQL_EXEC_BIN_PATH() + ' -N -s -X -e ''show databases'' -u '+ root +password;
  if XDebug then ShowScreen('MYSQL_ACTION_IF_DATABASE_EXISTS::' + commandline);
  list:=TStringList.Create;
  list.LoadFromStream(ExecStream(commandline,false));
  
RegExpr:=TRegExpr.Create;
  RegExpr.Expression:='<field name="Database">(.+)<\/field>';
  for i:=0 to list.count-1 do begin
      if RegExpr.Exec(list.Strings[i]) then begin
          if RegExpr.Match[1]=database_name then begin
                RegExpr.free;
                list.free;
                if XDebug then ShowScreen('MYSQL_ACTION_IF_DATABASE_EXISTS::' + database_name + ' exists');
                exit(true);
          end;
      end;
  end;
if XDebug then ShowScreen('MYSQL_ACTION_IF_DATABASE_EXISTS::' + database_name + ' not exists');
exit(false);
  
end;
//#############################################################################
function MyConf.MYSQL_ACTION_IMPORT_DATABASE(filenname:string;database:string):boolean;
    var
    root,commandline,password,port,socket:string;
    Logs:Tlogs;
begin
  root:=MYSQL_ROOT();
  password:=MYSQL_PASSWORD();;
  port    :=MYSQL_SERVER_PARAMETERS_CF('port');
  Logs    :=Tlogs.Create;
  socket  :=MYSQL_SERVER_PARAMETERS_CF('socket');
  
  
  if length(password)>0 then password:=' -p'+password;
  if not fileExists(MYSQL_EXEC_BIN_PATH()) then begin
     ShowScreen('MYSQL_ACTION_IMPORT_DATABASE:: Unable to locate mysql binary');
     exit(false);
  end;
  
  if not FileExists(filenname) then begin
     ShowScreen('MYSQL_ACTION_IMPORT_DATABASE:: Unable to stat ' +filenname);
     exit;
  end;

   commandline:=MYSQL_EXEC_BIN_PATH() + ' --port=' + port + ' --socket=' +socket+ ' --skip-column-names --database=' + database + ' --silent --xml --user='+ root +password + ' <' + filenname;
 logs.INSTALL_MODULES('APP_MYSQL','query sql "' + commandline + '"');
   Logs.logs('MYSQL_ACTION_IMPORT_DATABASE::'+commandline);
  fpsystem(commandline);
end;
//#############################################################################
function MyConf.MYSQL_ACTION_QUERY(sql:string):boolean;
    var
       root,commandline,password,port,socket:string;
       Logs:Tlogs;
    
begin
  root    :=MYSQL_ROOT();
  password:=MYSQL_PASSWORD();
  port    :=MYSQL_SERVER_PARAMETERS_CF('port');
  socket  :=MYSQL_SERVER_PARAMETERS_CF('socket');
  Logs    :=Tlogs.Create;
  
  if length(password)>0 then password:=' -p'+password;
  if not fileExists(MYSQL_EXEC_BIN_PATH()) then begin
     ShowScreen('MYSQL_ACTION_QUERY:: Unable to locate mysql binary');
     exit(false);
  end;
  commandline:=MYSQL_EXEC_BIN_PATH() + ' --port=' + port + ' --socket=' +socket+ ' --skip-column-names --silent --xml --execute=''' + sql + ''' --user='+ root +password;
   logs.INSTALL_MODULES('APP_MYSQL','query sql "' + commandline + '"');
   Logs.logs('MYSQL_ACTION_QUERY::'+commandline);
  fpsystem(commandline);
end;
//#############################################################################
function Myconf.MYSQL_EXEC_BIN_PATH():string;
begin
   if FileExists('/opt/artica/bin/mysql') then exit('/opt/artica/bin/mysql');
   if FileExists('/usr/bin/mysql') then exit('/usr/bin/mysql');
end;
//#############################################################################
function MyConf.MYSQL_ACTION_CREATE_ADMIN(username:string;password:string):boolean;
    var root,commandline,pass:string;
    list:TStringList;
    i:integer;
    XDebug:boolean;
    RegExpr:TRegExpr;
    found:boolean;
begin
  if length(password)=0 then begin
     writeln('please, set a password...');
     exit(false);
  end;
  pass:=password;
  found:=false;
  if ParamStr(2)='setadmin' then XDebug:=true;
  root:=MYSQL_ROOT();
  password:=MYSQL_PASSWORD();
   if not fileExists('/usr/bin/mysql') then begin
     ShowScreen('MYSQL_ACTION_IMPORT_DATABASE:: Unable to locate mysql binary (usually in  /usr/bin/mysql)');
     exit(false);
  end;
  if length(password)>0 then password:=' -p'+password;
  commandline:=MYSQL_EXEC_BIN_PATH() + ' -N -s -X -e ''select User from user'' -u '+ root +password+' mysql';
  if XDebug then ShowScreen(commandline);
  list:=TStringList.Create;
  list.LoadFromStream(ExecStream(commandline,false));
  if list.Count<2 then begin
    list.free;
    exit(false);
  end;
  RegExpr:=TRegExpr.Create;
  RegExpr.Expression:='<field name="User">(.+)<\/field>';
  for i:=0 to list.count-1 do begin
      if RegExpr.Exec(list.Strings[i]) then begin
          if RegExpr.Match[1]=username then found:=True;
      end;
  end;
  if found=true then begin
     ShowScreen('MYSQL_ACTION_CREATE_ADMIN:: updating ' + username + ' password');
     commandline:=MYSQL_EXEC_BIN_PATH() + ' -N -s -X -e ''UPDATE user SET Password=PASSWORD("' + pass + '") WHERE User="'+username+'"; FLUSH PRIVILEGES;'' -u '+ root +password+' mysql';
     if XDebug then ShowScreen('MYSQL_ACTION_CREATE_ADMIN::' + commandline);
     fpsystem(commandline);
  end else begin
  
  commandline:=MYSQL_EXEC_BIN_PATH() + ' -N -s -X -e ''INSERT INTO user';
  commandline:=commandline + ' (Host,User,Password,Select_priv,Insert_priv,Update_priv,Delete_priv,Create_priv,Drop_priv,Reload_priv,Shutdown_priv,Process_priv,File_priv,Grant_priv,References_priv,Index_priv,';
  commandline:=commandline + ' Alter_priv,Show_db_priv,Super_priv,Create_tmp_table_priv,Lock_tables_priv,Execute_priv,Repl_slave_priv,Repl_client_priv,Create_view_priv,Show_view_priv,Create_routine_priv,'; //11
  commandline:=commandline + ' Alter_routine_priv,Create_user_priv)';
  commandline:=commandline + ' VALUES("localhost","'+ username +'",PASSWORD("'+ pass+'"),';
  commandline:=commandline + '"Y","Y","Y","Y","Y","Y","Y","Y","Y","Y","Y","Y","Y",';
  commandline:=commandline + '"Y","Y","Y","Y","Y","Y","Y","Y","Y","Y","Y","Y","Y");FLUSH PRIVILEGES;'' -u '+ root +password+' mysql';
  if XDebug then ShowScreen('MYSQL_ACTION_CREATE_ADMIN::' + commandline);
  fpsystem(commandline);
  end;
  
  list.free;

end;
//#############################################################################

procedure MyConf.set_LINUX_DISTRI(val:string);
var ini:TIniFile;
begin
ini:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
ini.WriteString('LINUX','distribution-name',val);
ini.Free;
end;
function MyConf.OPENSSL_TOOL_PATH():string;
begin
if FileExists('/opt/artica/bin/openssl') then exit('/opt/artica/bin/openssl');
if FileExists('/usr/local/ssl/bin/openssl') then exit('/usr/local/ssl/bin/openssl');
if FileExists('/usr/bin/openssl') then exit('/usr/bin/openssl');
end;

//#############################################################################
function MyConf.CERTIFICATE_PASS(path:string):string;
var ini:TIniFile;
begin
ini:=TIniFile.Create(path);
result:=ini.ReadString('req','input_password','secret');
ini.Free;
end;
//#############################################################################
function MyConf.CERTIFICATE_PATH(path:string):string;
var ini:TIniFile;
begin
ini:=TIniFile.Create(path);
result:=ini.ReadString('default_db','dir','/etc/postfix/certificates');
ini.Free;
end;
//#############################################################################
function MyConf.CERTIFICATE_CA_FILENAME(path:string):string;
var ini:TIniFile;
begin
ini:=TIniFile.Create(path);
result:=ini.ReadString('postfix','smtpd_tls_CAfile','cacert.pem');
ini.Free;
end;
//#############################################################################
function MyConf.CERTIFICATE_KEY_FILENAME(path:string):string;
var ini:TIniFile;
begin
ini:=TIniFile.Create(path);
result:=ini.ReadString('postfix','smtpd_tls_key_file','smtpd.key');
ini.Free;
end;
//#############################################################################
function MyConf.CERTIFICATE_CERT_FILENAME(path:string):string;
var ini:TIniFile;
begin
ini:=TIniFile.Create(path);
result:=ini.ReadString('postfix','smtpd_tls_cert_file','smtpd.crt');
ini.Free;
end;
//#############################################################################
function MyConf.PROCMAIL_QUARANTINE_PATH():string;
var ini:TIniFile;
begin
if not fileExists('/etc/artica-postfix/artica-procmail.conf') then begin
   result:='/var/quarantines/procmail';
   exit;
end;
ini:=TIniFile.Create('/etc/artica-postfix/artica-procmail.conf');
result:=ini.ReadString('path','quarantine_path','/var/quarantines/procmail');
ini.Free;
end;

//#############################################################################
procedure MyConf.set_INFOS(key:string;val:string);
var ini:TIniFile;
begin
ini:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
ini.WriteString('INFOS',key,val);
ini.Free;
end;
//#############################################################################
procedure MyConf.set_LDAP(key:string;val:string);
var ini:TIniFile;
begin
ini:=TIniFile.Create('/etc/artica-postfix/artica-postfix-ldap.conf');
ini.WriteString('LDAP',key,val);
ini.Free;
end;
//#############################################################################
function MyConf.get_LDAP(key:string):string;
var value:string;
begin
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix-ldap.conf');
value:=GLOBAL_INI.ReadString('LDAP',key,'');
result:=value;
GLOBAL_INI.Free;
end;
//#############################################################################
function MyConf.ARTICA_FILTER_QUEUEPATH():string;
var ini:TIniFile;
begin
 ini:=TIniFile.Create('/etc/artica-postfix/artica-filter.conf');
 result:=ini.ReadString('INFOS','QueuePath','');
 if length(trim(result))=0 then result:='/var/spool/artica-filter';
end;
//##############################################################################


function MyConf.get_INFOS(key:string):string;
var value:string;
begin
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
value:=GLOBAL_INI.ReadString('INFOS',key,'');
result:=value;
GLOBAL_INI.Free;
end;
//#############################################################################
function MyConf.RRDTOOL_STAT_LOAD_AVERAGE_DATABASE_PATH():string;
var value,phppath,path:string;
ini:TIniFile;
begin
ini:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
value:=ini.ReadString('ARTICA','STAT_LOAD_PATH','');
if length(value)=0 then  begin
   if debug then writeln('STAT_LOAD_PATH is not set in ini path');
   phppath:=get_ARTICA_PHP_PATH();
   path:=phppath+'/ressources/rrd/process.rdd';
   if debug then writeln('set STAT_LOAD_PATH to '+path);
   value:=path;
   ini.WriteString('ARTICA','STAT_LOAD_PATH',path);
   if debug then writeln('done..'+path);
end;
result:=value;
ini.Free;
end;
//#############################################################################
function MyConf.ARTICA_SEND_MAX_SUBQUEUE_NUMBER:integer;
var
ini:TIniFile;
begin
ini:=TIniFile.Create('/etc/artica-postfix/artica-filter.conf');
result:=ini.ReadInteger('INFOS','MAX_QUEUE_NUMBER',5);
ini.free;
end;
//#############################################################################


//#############################################################################
function MyConf.ARTICA_SEND_SUBQUEUE_NUMBER(QueueNumber:string):integer;
var
   QueuePath:string;
   SYS:TSystem;
   NumbersIntoQueue:integer;
   D:boolean;
begin
  result:=0;
  NumbersIntoQueue:=0;
  SYS:=TSystem.Create;
  D:=COMMANDLINE_PARAMETERS('debug');
  QueuePath:=ARTICA_FILTER_QUEUEPATH() + '/queue';
  if D then writeln('ARTICA_SEND_SUBQUEUE_NUMBER: QueuePath=' + QueuePath);
     if DirectoryExists(QueuePath + '/' +QueueNumber) then begin
        SYS.DirFiles(QueuePath + '/' + QueueNumber,'*.queue');
        NumbersIntoQueue:=SYS.DirListFiles.Count;
     end;
  if D then writeln('ARTICA_SEND_SUBQUEUE_NUMBER: Number=' + IntToStr(NumbersIntoQueue) + ' Objects');
  //logs.logs('ARTICA_SEND_SUBQUEUE_NUMBER:: NumbersIntoQueue:=' + IntToStr(NumbersIntoQueue));
  SYS.Free;
  exit(NumbersIntoQueue);
end;
//#############################################################################
function MyConf.ARTICA_SEND_QUEUE_NUMBER():integer;
var
   QueuePath:string;
   SYS:TSystem;
begin
  result:=0;
  SYS:=TSystem.Create;
     QueuePath:=ARTICA_FILTER_QUEUEPATH();
     if DirectoryExists(QueuePath) then SYS.DirFiles(QueuePath , '*.eml');
     exit(SYS.DirListFiles.Count);
  SYS.Free;
end;
//#############################################################################
function MyConf.ARTICA_SQL_QUEUE_NUMBER():integer;
var
   QueuePath:string;
   SYS:TSystem;
begin
  QueuePath:=ARTICA_FILTER_QUEUEPATH();
  SYS:=TSystem.Create;
  SYS.DirFiles(QueuePath,'*.sql');
  result:=SYS.DirListFiles.Count;
  SYS.Free;
  exit;
end;
//#############################################################################
procedure MyConf.ARTICA_FILTER_CLEAN_QUEUE();
var
   QueuePath:string;
   SourceFile:string;
   DestFile:string;
   SYS:TSystem;
   i:integer;
   D:boolean;
   pid,body:string;
   mailpid:string;
   RegExpr:TRegExpr;
   Strpos:integer;
   DeleteFile:boolean;
begin
   D:=COMMANDLINE_PARAMETERS('--verbose');
   QueuePath:=ARTICA_FILTER_QUEUEPATH();
   pid:=EMAILRELAY_PID();
   SYS:=TSystem.Create;
   SYS.DirFiles(QueuePath,'*.new');
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='emailrelay\.([0-9]+)\.[0-9]+\.[0-9]+\.envelope';
   for i:=0 to SYS.DirListFiles.Count-1 do begin
        SourceFile:=QueuePath + '/' + SYS.DirListFiles.Strings[i];
        if RegExpr.Exec(SourceFile) then mailpid:=RegExpr.Match[1];

        Strpos:=pos('.new',SourceFile);
        DestFile:=Copy(SourceFile,0,Strpos-1);
        if D then writeln('ARTICA_FILTER_CLEAN_QUEUE: "' + DestFile + '" saved by process number ' + mailpid + '->(' + pid+')');
        if pid<>mailpid then begin
           LOGS.logs('ARTICA_FILTER_CLEAN_QUEUE:: Flush ' + DestFile + ' in new mode');
           if D then writeln('ARTICA_FILTER_CLEAN_QUEUE:  Flush ' + DestFile + ' in new mode');
           fpsystem('/bin/mv ' + SourceFile + ' ' + DestFile);
        end;

   end;
   SYS.DirListFiles.Clear;
   SYS.DirFiles(QueuePath,'*.busy');
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='emailrelay\.([0-9]+)\.[0-9]+\.[0-9]+\.envelope';
   for i:=0 to SYS.DirListFiles.Count-1 do begin
        SourceFile:=QueuePath + '/' + SYS.DirListFiles.Strings[i];
        if RegExpr.Exec(SourceFile) then mailpid:=RegExpr.Match[1];

        Strpos:=pos('.busy',SourceFile);
        DestFile:=Copy(SourceFile,0,Strpos-1);
        if D then writeln('ARTICA_FILTER_CLEAN_QUEUE: "' + DestFile + '" saved by process number ' + mailpid + '->(' + pid+')');
        if pid<>mailpid then begin
           LOGS.logs('ARTICA_FILTER_CLEAN_QUEUE:: Flush ' + DestFile + ' in busy mode');
           if D then writeln('ARTICA_FILTER_CLEAN_QUEUE:  Flush ' + DestFile + ' in busy mode');
           fpsystem('/bin/mv ' + SourceFile + ' ' + DestFile);
        end;

   end;


   RegExpr.Free;
   SYS.free;
   exit;

      
   SYS.DirListFiles.Clear;
   SYS.DirFiles(QueuePath,'*.content');
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='emailrelay\.([0-9\.]+)\.content';
   for i:=0 to SYS.DirListFiles.Count-1 do begin
        SourceFile:=QueuePath + '/' + SYS.DirListFiles.Strings[i];
        if RegExpr.Exec(SourceFile) then begin
           body:=RegExpr.Match[1];
           DeleteFile:=true;
           if FileExists(QueuePath + '/' + 'emailrelay.' + body + '.envelope') then DeleteFile:=false;
           if FileExists(QueuePath + '/' + 'emailrelay.' + body + '.envelope.new') then DeleteFile:=false;
           if FileExists(QueuePath + '/' + 'emailrelay.' + body + '.envelope.busy') then DeleteFile:=false;
           if FileExists(QueuePath + '/' + 'emailrelay.' + body + '.envelope.bad') then DeleteFile:=false;
           if FileExists(QueuePath + '/' + 'emailrelay.' + body + '.envelope.local') then DeleteFile:=false;

        

        if DeleteFile then begin
           if D then writeln('ARTICA_FILTER_CLEAN_QUEUE: Delete ' + SourceFile);
           LOGS.logs('ARTICA_FILTER_CLEAN_QUEUE:: Delete old file ' + SourceFile);
           fpsystem('/bin/rm ' + SourceFile);
        end;
       end;

   end;
   

   RegExpr.Free;
   SYS.free;
end;
//#############################################################################
function MyConf.SYSTEM_PROCESS_EXIST(pid:string):boolean;
begin
  result:=false;
  if pid='0' then exit(false);
  
  if not fileExists('/proc/' + pid + '/exe') then begin
     exit(false)
  end else begin
      exit(true);
  end;
end;
//#############################################################################
function MyConf.PHP5_IS_MODULE_EXISTS(modulename:string):boolean;
var
   RegExpr:TRegExpr;
   Files:TStringList;
   i    :integer;
   D    :boolean;
begin
     result:=false;
     D:=COMMANDLINE_PARAMETERS('debug');
     if Not FileExists('/opt/artica/bin/php') then begin
        if D then writeln('Unable to stat /opt/artica/bin/php');
        exit;
     end;
     fpsystem('/opt/artica/bin/php -m >/opt/artica/logs/php5.modules.txt 2>&1');
     Files:=TStringList.Create;
     Files.LoadFromFile('/opt/artica/logs/php5.modules.txt');
     RegExpr:=TRegExpr.Create;
     RegExpr.Expression:='^' + modulename;
     For i:=0 to Files.Count-1 do begin
     
         if RegExpr.Exec(Files.Strings[i]) then begin
            result:=true;
            break;
         end else begin
            if D then writeln(Files.Strings[i] + ' -> Not Match ' + RegExpr.Expression);
         end;
     end;
     
RegExpr.Free;
Files.Free;

end;
//#############################################################################

function MyConf.SYSTEM_GET_PID(pidPath:string):string;
var
   RegExpr:TRegExpr;
   Files:TStringList;
begin
 RegExpr:=TRegExpr.Create;
 RegExpr.Expression:='([0-9]+)';
result:='0';
if not FileExists(pidPath) then exit;
Files:=TStringList.Create;
Files.LoadFromFile(pidPath);

if RegExpr.Exec(Files.Strings[0]) then result:=RegExpr.Match[1];
RegExpr.Free;
Files.Free;
end;
//#############################################################################
function MyConf.ARTICA_FILTER_PID():string;
begin
result:=SYSTEM_GET_PID('/etc/artica-postfix/artica-filter.pid');
exit;
end;
//#############################################################################
function MyConf.ARTICA_SEND_PID(QueueNumber:String):string;
begin
result:=SYSTEM_GET_PID('/etc/artica-postfix/artica-send.' + QueueNumber + 'pid');
exit;
end;
//#############################################################################
function MyConf.ARTICA_SQL_PID():string;
begin
result:=SYSTEM_GET_PID('/etc/artica-postfix/artica-sql.pid');
exit;
end;
//############################################################################# #
function MyConf.EMAILRELAY_PID():string;
begin
result:=SYSTEM_GET_PID('/etc/artica-postfix/emailrelay.pid');
exit;
end;
//############################################################################# #

function MyConf.ARTICA_SEND_QUEUE_PATH():string;
var
   value:string;
   S_INI:TIniFile;
begin
S_INI:=TIniFile.Create('/etc/artica-postfix/artica-send.conf');
value:=S_INI.ReadString('QUEUE','QueuePath','/usr/share/artica-filter/queue');
if length(value)=0 then value:='/usr/share/artica-filter/queue';
result:=value;
S_INI.Free;
end;
//#############################################################################

procedure MyConf.ARTICA_FILTER_WATCHDOG();
var
   D:boolean;
   articapolicy_pid,dnsmasqpid:string;
   fetchmailpid:string;
   damon_path2,dnsmasqbin,pidlists:string;
   LOGS2:TLogs;
   P:TProcess;
begin

    damon_path2:=get_ARTICA_PHP_PATH() + '/bin/artica-policy';
    D:=COMMANDLINE_PARAMETERS('debug');
    LOGS2:=Tlogs.Create;
    dnsmasqbin:=DNSMASQ_BIN_PATH();
    articapolicy_pid:=ARTICA_POLICY_GET_PID();
    fetchmailpid:=FETCHMAIL_PID();

    if D then writeln('fetchmail pid='  +fetchmailpid);
    if FileExists(FETCHMAIL_BIN_PATH()) then begin
           if not SYSTEM_PROCESS_EXIST(fetchmailpid) then begin
            LOGS2.ERRORS('ARTICA_FILTER_WATCHDOG:: running fetchmail process (' + fetchmailpid + ') doesn''t exists');

            FETCHMAIL_START_DAEMON();
            fetchmailpid:=FETCHMAIL_PID();
            if StrToInt(fetchmailpid)=0 then LOGS2.ERRORS('ARTICA_FILTER_WATCHDOG:: Failed....New PID is (' + fetchmailpid + ')');
           end;
    
    end;
    
    
    if FileExists('/opt/kav/5.6/kavmilter/bin/kavmilter') then begin

         pidlists:=KAV_MILTER_PID();
         if length(pidlists)=0 then begin
             LOGS2.ERRORS('ARTICA_FILTER_WATCHDOG:: running kavmilter doesn''t exists, try to start it');
             KAV6_START();
         end;
    
    end;
    
    if DirectoryExists('/usr/local/ap-mailfilter3/bin') then begin
       if not FileExists('/usr/local/ap-mailfilter3/etc/filter.conf') then fpsystem('/bin/cp '+ ExtractFilePath(ParamStr(0)) + 'install/filter.conf /usr/local/ap-mailfilter3/etc/filter.conf');
       if not FileExists('/usr/local/ap-mailfilter3/etc/keepup2date.conf') then fpsystem('/bin/cp '+ ExtractFilePath(ParamStr(0)) + 'install/kas.keepup2date.conf /usr/local/ap-mailfilter3/etc/keepup2date.conf');
    end;

    
    if not SYSTEM_PROCESS_EXIST(articapolicy_pid) then begin
          LOGS2.ERRORS('ARTICA_FILTER_WATCHDOG:: running artica-policy process ({' + articapolicy_pid + '} "' + damon_path2 + '") doesn''t exists');
          try
             P:=TProcess.Create(nil);
             P.CommandLine:=damon_path2;
             P.Execute;
          Except
             LOGS2.ERRORS('ARTICA_FILTER_WATCHDOG:: FATAL ERROR WHILE RUNNING ' +  damon_path2);
          end;
          Select(0,nil,nil,nil,10*500);
    end;
    
    if fileexists(dnsmasqbin) then begin
          dnsmasqpid:=DNSMASQ_PID();
          if not SYSTEM_PROCESS_EXIST(dnsmasqpid) then begin
             LOGS2.ERRORS('ARTICA_FILTER_WATCHDOG:: running dnsmasq process ({' + dnsmasqpid + '} "' + dnsmasqbin + '") doesn''t exists');
             DNSMASQ_START_DAEMON();
          end;
    end;
    
    if FileExists('/opt/artica/libexec/mysqld') then begin
      if not SYSTEM_PROCESS_EXIST(MYSQL_ARTICA_PID()) then begin
              MYSQL_ARTICA_START();
        end;
    end;
    
    if not SYSTEM_PROCESS_EXIST(BOA_DAEMON_GET_PID()) then BOA_START();
    
    
    if FileExists('/opt/artica/bin/slapd') then begin
            if not SYSTEM_PROCESS_EXIST(LDAP_PID()) then begin
             LOGS2.ERRORS('ARTICA_FILTER_WATCHDOG:: running slapd process doesn''t exists... Try to start it');
             LDAP_START();
            end;
    end;
    
    
   LOGS2.Free;
end;
//##############################################################################
function MyConf.CGI_ALL_APPLIS_INSTALLED():string;
var
   AVE_VER,KASVER,SQUID_VER,DANS_VER,PUREFTP:string;

begin
    AVE_VER:=AVESERVER_GET_VERSION();
    DANS_VER:=DANSGUARDIAN_VERSION();
    KASVER:=KAS_VERSION();
    SQUID_VER:=SQUID_VERSION();
    PUREFTP:=PURE_FTPD_VERSION();
    
    ArrayList.Clear;
    result:='';

    ArrayList.Add('<SECURITY_MODULES>');
    ArrayList.Add('[APP_AVESERVER] "' + AVE_VER + '"');
    ArrayList.Add('[APP_KAS3] "' + KASVER + '"');
    ArrayList.Add('[APP_BOGOFILTER] "' + BOGOFILTER_VERSION() + '"');
    if length(SQUID_VER)>0  then ArrayList.Add('[APP_KAV4PROXY] "' + KAV4PROXY_VERSION() + '"');
    if length(DANS_VER)>0  then ArrayList.Add('[APP_DANSGUARDIAN] "' + DANS_VER + '"');

    ArrayList.Add('</SECURITY_MODULES>');

    ArrayList.Add('<CORE_MODULES>');
    ArrayList.Add('[APP_POSTFIX] "' + POSTFIX_VERSION() + '"');
    if length(SQUID_VER)>0 then ArrayList.Add('[APP_SQUID] "'+ SQUID_VERSION() + '"');
    if length(PUREFTP)>0 then ArrayList.Add('[APP_PUREFTPD] "'+ PUREFTP + '"');
       
       
    ArrayList.Add('[APP_LDAP] "' + LDAP_VERSION() + '"');
    ArrayList.Add('[APP_RENATTACH] "' + RENATTACH_VERSION() + '"');
    ArrayList.Add('[APP_GEOIP] "' + GEOIP_VERSION() + '"');
    ArrayList.Add('[APP_DNSMASQ] "' + DNSMASQ_VERSION() + '"');
    ArrayList.Add('[APP_INADYN] "' + INYADIN_VERSION() + '"');

    ArrayList.Add('</CORE_MODULES>');
    
    ArrayList.Add('<STAT_MODULES>');
    ArrayList.Add('[APP_RRDTOOL] "' + RRDTOOL_VERSION() + '"');
    ArrayList.Add('[APP_AWSTATS] "' + AWSTATS_VERSION() + '"');
    ArrayList.Add('[APP_MAILGRAPH] "' + MAILGRAPH_VERSION() + '"');
    ArrayList.Add('</STAT_MODULES>');
    
    ArrayList.Add('<MAIL_MODULES>');
    ArrayList.Add('[APP_CYRUS] "' +    CYRUS_VERSION() + '"');
    ArrayList.Add('[APP_FETCHMAIL] "' +FETCHMAIL_VERSION() + '"');
    ArrayList.Add('[APP_GETLIVE] "' +  GETLIVE_VERSION() + '"');
    ArrayList.Add('[APP_HOTWAYD] "' +  HOTWAYD_VERSION() + '"');
    ArrayList.Add('[APP_PROCMAIL] "' + PROCMAIL_VERSION() + '"');
    ArrayList.Add('[APP_ROUNDCUBE] "' +ROUNDCUBE_VERSION() + '"');
    ArrayList.Add('[APP_MAILMAN] "' +  MAILMAN_VERSION() + '"');
    ArrayList.Add('</MAIL_MODULES>');
    
    

    
    ArrayList.Add('<LIB_MODULES>');
    ArrayList.Add('[APP_LIBGSL] "' + LIB_GSL_VERSION() + '"');
    ArrayList.Add('[APP_OPENSSL] "' + OPENSSL_VERSION() + '"');
    ArrayList.Add('[APP_PERL] "' + PERL_VERSION() + '"');
    ArrayList.Add('[APP_MYSQL] "' + MYSQL_VERSION() + '"');

    
    ArrayList.Add('</LIB_MODULES>');

 end;
 //#############################################################################
function myconf.DANSGUARDIAN_CONFIG_VALUE(key:string):string;
var
   l           :TstringList;
   RegExpr     :TRegExpr;
   i           :integer;
begin

    if not FileExists('/opt/artica/etc/dansguardian/dansguardian.conf') then exit;
    RegExpr:=TRegExpr.Create;
    l:=TstringList.create;
    
    RegExpr.Expression:='^'+key+'[\s=]+(.*)';
    l.LoadFromFile('/opt/artica/etc/dansguardian/dansguardian.conf');
    For i:=0 to l.Count-1 do begin
        if RegExpr.Exec(l.Strings[i]) then begin
               result:=trim(RegExpr.Match[1]);
         end;
    
    end;
    RegExpr.free;
    l.free;

end;
 //#############################################################################
 
procedure myconf.DANSGUARDIAN_CONFIG_VALUE_SET(key:string;value:string);
var
   l           :TstringList;
   RegExpr     :TRegExpr;
   i           :integer;
   found       :boolean;
   D           :boolean;
begin
    found:=false;
    D:=COMMANDLINE_PARAMETERS('--verbose');
    if not D then D:=COMMANDLINE_PARAMETERS('debug');
    if not FileExists('/opt/artica/etc/dansguardian/dansguardian.conf') then exit;
    RegExpr:=TRegExpr.Create;
    l:=TstringList.create;
    
    RegExpr.Expression:='^'+key+'[\s=]+(.*)';
    l.LoadFromFile('/opt/artica/etc/dansguardian/dansguardian.conf');
    For i:=0 to l.Count-1 do begin
      if RegExpr.Exec(l.Strings[i]) then begin
              found:=true;
              if D then writeln(ExtractFileName(ParamStr(0)) + ':: Dansguardian:: Found ' + key);
              if D then writeln(ExtractFileName(ParamStr(0)) + ':: Dansguardian:: set as ' + key + ' = ' + value);
              l.Strings[i]:=key + ' = ' + value;
              break;
         end;

    end;
    
    if not found then begin
        l.Add(key + ' = ' + value);
        if D then writeln(ExtractFileName(ParamStr(0)) + '::Dansguardian:: Add new key: ' + key + ' = ' + value);
    end;
    
    l.SaveToFile('/opt/artica/etc/dansguardian/dansguardian.conf');
    RegExpr.free;
    l.free;

end;
 
 
 
function myconf.KAV4PROXY_VERSION():string;
var
   RegExpr:TRegExpr;
begin
   if not FileExists('/opt/kaspersky/kav4proxy/sbin/kav4proxy-kavicapserver') then exit;
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='Server version ([0-9\.]+)';
   if RegExpr.Exec(ExecPipe('/opt/kaspersky/kav4proxy/sbin/kav4proxy-kavicapserver -v')) then begin
      result:=RegExpr.Match[1];
   end;

   RegExpr.Free;

end;
 //#############################################################################
 
 
function MyConf.GETLIVE_VERSION():string;
var
   RegExpr            :TRegExpr;
   tempstr            :string;
   f                  :TstringList;
   i                  :integer;
begin
   result:='';
   tempstr:=get_ARTICA_PHP_PATH() + '/bin/GetLive.pl';
   if not FileExists(tempstr) then exit;
   f:=TstringList.Create;
   f.LoadFromFile(tempstr);
   RegExpr:=tRegExpr.Create;
   RegExpr.Expression:='my \$Revision\s+=.+?([0-9\.]+)';
   For i:=0 to f.Count -1 do begin
       if RegExpr.Exec(f.Strings[i]) then begin
           result:=RegExpr.Match[1];
           break;
       end;
   
   end;
 // my $Revision
 
   f.free;
   RegExpr.Free;

end;
 //#############################################################################
 function MyConf.BOGOFILTER_VERSION():string;
var
   RegExpr:TRegExpr;
begin
   if not FileExists('/usr/local/bin/bogofilter') then exit;
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='bogofilter version ([0-9\.]+)';
   if RegExpr.Exec(ExecPipe('/usr/local/bin/bogofilter -V')) then begin
      result:=RegExpr.Match[1];
   end;
   
   RegExpr.Free;

end;
//#############################################################################
function MyConf.GEOIP_VERSION():string;
var
   RegExpr:TRegExpr;
   database_path,tempstr:string;
   GeoIP:TGeoIP;
begin
 database_path:='/usr/local/share/GeoIP';
   ForceDirectories(database_path);
   RegExpr:=TRegExpr.Create;
   if FileExists(database_path + '/GeoIP.dat') then begin
      GeoIP := TGeoIP.Create(database_path + '/GeoIP.dat');
      tempstr:=GeoIP.GetDatabaseInfo;
      RegExpr.expression:='\s+([0-9]+)\s+';
      try
         if RegExpr.Exec(tempstr) then result:=RegExpr.Match[1];
      finally
      GeoIP.Free;
      RegExpr.free;
      end;
   end;

end;
//#############################################################################
function MyConf.EMAILRELAY_VERSION():string;
var
   RegExpr:TRegExpr;
   TMP:string;
begin
   if not FileExists('/usr/local/sbin/emailrelay') then exit('0.0.0');
   TMP:=ExecPipe('/usr/local/sbin/emailrelay -V');
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='E-MailRelay V([0-9\.]+)';
   if RegExpr.Exec(TMP) then result:=RegExpr.Match[1];
   RegExpr.free;
   
end;
//#############################################################################
function MyConf.RENATTACH_VERSION():string;
var
   RegExpr:TRegExpr;
   TMP:string;
begin
   if not FileExists(get_ARTICA_PHP_PATH() + '/bin/renattach') then exit('0.0.0');
   TMP:=ExecPipe(get_ARTICA_PHP_PATH() + '/bin/renattach -V');
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='renattach\s+([0-9\.]+)';
   if RegExpr.Exec(TMP) then result:=RegExpr.Match[1];
   RegExpr.free;

end;
//#############################################################################


function MyConf.GetAllApplisInstalled():string;
begin
 result:='';
 CGI_ALL_APPLIS_INSTALLED();
 writeln(ArrayList.Text);
 end;
//#############################################################################
function MyConf.ROUNDCUBE_VERSION():string;
var
   filepath:string;
   RegExpr:TRegExpr;
   List:TstringList;
   i:integer;
   D:boolean;
begin
     result:='';
     D:=COMMANDLINE_PARAMETERS('debug');

     if not DirectoryExists('/usr/share/roundcubemail') then begin
        if D then showScreen('ROUNDCUBE_VERSION:: /usr/share/roundcube doesn''t exists...');
        exit();
     end else begin
         if D then showScreen('ROUNDCUBE_VERSION:: /usr/share/roundcube is detected as a directory');
     end;
     

      filepath:='/usr/share/roundcubemail/index.php';

      
     if not fileExists(filepath) then begin
        if D then showScreen('ROUNDCUBE_VERSION:: unable to locate ' + filepath);
        exit('');
     end;
     
     
     List:=TstringList.Create;
     List.LoadFromFile(filepath);
     RegExpr:=TRegExpr.Create;
     RegExpr.Expression:='define\(''RCMAIL_VERSION[\s,'']+([0-9\-\.a-z]+)';
     for i:=0 to List.Count-1 do begin
          if RegExpr.Exec(list.Strings[i]) then begin
             result:=RegExpr.Match[1];
             break;
          end;
     
     end;

          list.Free;
          RegExpr.free;
end;
//#############################################################################


function MyConf.FETCHMAIL_DAEMON_POOL():string;
var value:string;
begin
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
value:=GLOBAL_INI.ReadString('ARTICA','fetchmail_daemon_pool','600');
result:=value;
GLOBAL_INI.Free;
end;
//#############################################################################
function MyConf.PHP5_INI_PATH():string;
begin
if fileExists('/etc/php5/apache2/php.ini') then exit('/etc/php5/apache2/php.ini');
if fileExists('/etc/php.ini') then exit('/etc/php.ini');
end;
//#############################################################################
function MyConf.PHP5_INI_SET_EXTENSION(librari:string):string;
var
   php_path:string;
   RegExpr:TRegExpr;
   D:Boolean;
   F:TstringList;
   I:integer;
begin
   result:='';
   D:=COMMANDLINE_PARAMETERS('debug');
   php_path:=PHP5_INI_PATH();
   if not FileExists(php_path) then begin
       if D then writeln('Unable to stat ' + php_path);
       exit;
   end;
    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='^extension=' + librari;
    F:=TstringList.Create;
    F.LoadFromFile(php_path);
    for i:=0 to F.Count -1 do begin
       if RegExpr.Exec(f.Strings[i]) then begin
          if D then writeln('Already updated.. : ' + php_path);
           f.Free;
           RegExpr.Free;
           exit;
       end;
    end;
   f.Add('extension=' + librari);
   f.SaveToFile(php_path);
   f.free;
   RegExpr.free;
   
end;
//#############################################################################


function MyConf.FETCHMAIL_DAEMON_POSTMASTER():string;
var value:string;
begin
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
value:=GLOBAL_INI.ReadString('ARTICA','fetchmail_daemon_postmaster','root');
result:=value;
GLOBAL_INI.Free;
end;
//#############################################################################
function MyConf.FETCHMAIL_BIN_PATH():string;
begin
    if FileExists('/opt/artica/bin/fetchmail') then exit('/opt/artica/bin/fetchmail');
    if FileExists('/usr/bin/fetchmail') then exit('/usr/bin/fetchmail');
    if FileExists('/usr/local/bin/fetchmail') then exit('/usr/local/bin/fetchmail');

end;
//#############################################################################
procedure MyConf.FETCHMAIL_APPLY_CONF(conf_datas:string);
var value:TstringList;
begin
   if length(conf_datas)=0 then exit;
   if not fileexists(FETCHMAIL_BIN_PATH) then exit;
   value:=TstringList.Create;
   value.Add(conf_datas);
   value.SaveToFile('/etc/fetchmailrc');
   value.free;
   fpsystem('/bin/chown root:root /etc/fetchmailrc');
   fpsystem('/bin/chmod 0710 /etc/fetchmailrc');
   FETCHMAIL_DAEMON_STOP();
   FETCHMAIL_START_DAEMON();
   FETCHMAIL_APPLY_GETLIVE_CONF();
   
end;
//#############################################################################
function MyConf.INADYN_PERFORM(IniData:String;UpdatePeriod:integer):string;
var
   Ini      :TiniFile;
   l        :TStringList;
   aliasList:TStringDynArray;
   list     :string;
   cmd      :string;
   proxy    :string;
   i        :integer;
   D:boolean;
begin
    result:='';
    D:=COMMANDLINE_PARAMETERS('debug');
    if length(IniData)=0 then exit;
    l:=TStringList.Create;
    l.Add(IniData);
    l.SaveToFile('/opt/artica/logs/inadyn.rule.cf');
    ini:=TiniFile.Create('/opt/artica/logs/inadyn.rule.cf');
    cmd:='';
    cmd:=cmd + 'inadyn --username ' +  ini.ReadString('inadyn','username','');
    cmd:=cmd + ' --password ' +  ini.ReadString('inadyn','password','');
    cmd:=cmd + ' --dyndns_system ' +  ini.ReadString('inadyn','dyndns_system','');
    list:=ini.ReadString('inadyn','alias','');
    if length(list)>0 then begin
       aliasList:=Explode(',',list);
       for i:=0 to length(aliasList)-1 do begin
              cmd:=cmd + ' --alias ' + aliasList[i];
       end;
    end;
    UpdatePeriod:=UpdatePeriod*60;
    if ini.ReadString('PROXY','enabled','')='yes' then begin
       proxy:= ' --proxy_server ' + ini.ReadString('PROXY','servername','') + ':' + ini.ReadString('PROXY','serverport','');
    end;
    
    
    
    writeln('Starting......: inadyn daemon...' + ini.ReadString('inadyn','dyndns_system','') + ' ' + ini.ReadString('inadyn','username',''));
    if D then writeln(get_ARTICA_PHP_PATH() + '/bin/' + cmd + ' --log_file /opt/artica/logs/inadyn.log --update_period_sec ' + IntToStr(UpdatePeriod) + proxy + ' --background');
    fpsystem(get_ARTICA_PHP_PATH() + '/bin/' + cmd + ' --log_file /opt/artica/logs/inadyn.log --update_period_sec ' + IntToStr(UpdatePeriod) + proxy + ' --background');

end;
//#############################################################################
procedure MyConf.INADYN_PERFORM_STOP();
var
pids      :string;
begin
    pids:=trim(INADYN_PID());
    if length(pids)>0 then begin
         writeln('Stopping inadyn..........: ' + pids + ' PID');
         fpsystem('/bin/kill ' + pids);
    end;

end;



//#############################################################################
procedure MyConf.FETCHMAIL_APPLY_GETLIVE_CONF();
var
   RegExpr       :TRegExpr;
   TmpFile       :TstringList;
   i             :integer;
   DaemonPool    :integer;
   Hour          :integer;
   list          :string;
   D             :Boolean;
begin
D:=COMMANDLINE_PARAMETERS('debug');
    if not FileExists('/etc/fetchmailrc') then begin
       if FileExists('/etc/cron.d/GetLive') then DeleteFile('/etc/cron.d/GetLive');
       exit;
    end;
    DaemonPool:=0;
    TmpFile:=TstringList.Create;
    TmpFile.LoadFromFile('/etc/fetchmailrc');
    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='set daemon\s+([0-9]+)';
    for i:=0 to TmpFile.Count -1 do begin
        if RegExpr.Exec(TmpFile.Strings[i]) then begin
           DaemonPool:=StrToInt(RegExpr.Match[1]);
           break;
        end;
    
    end;
    TmpFile.Clear;
    list:='';
    Hour:=0;
    if DaemonPool=0 then exit;
    DaemonPool:=DaemonPool div 60;
    if DaemonPool>60 then DaemonPool:=60;
    writeln('pool=' + IntToStr(DaemonPool));
    for i:=1 to 60 do begin
      Hour:=Hour+DaemonPool;
      if(Hour>60) then break;
      list:=list + IntToStr(Hour) + ',';
    end;
    writeln('copy='+Copy(list,length(list),1));
    if Copy(list,length(list),1)=',' then list:=Copy(list,0,length(list)-1);
    
    

   list:=list+' * * * * root ' + get_ARTICA_PHP_PATH() + '/bin/artica-ldap -getlive >>/var/log/fetchmail.log 2>&1';
   if D then  writeln('FETCHMAIL_APPLY_GETLIVE_CONF:: cron=' + list);
   TmpFile.Add(list);
   TmpFile.SaveToFile('/etc/cron.d/GetLive');
   if D then  writeln('FETCHMAIL_APPLY_GETLIVE_CONF:: /etc/cron.d/GetLive -> saved');

end;
//#############################################################################

procedure MyConf.FETCHMAIL_APPLY_GETLIVE(conf_datas:string);
var
   value         :TstringList;
   RegExpr       :TRegExpr;
   RegExpr2      :TRegExpr;
   i             :integer;
   Config        :TstringList;
   GetLiveCf     :TstringList;
   RemoteMail    :string;
   user          :string;
   domain        :string;
   Password      :string;
   SendMailuser  :string;
   CommandLine   :string;
   
begin
   if length(conf_datas)=0 then exit;
   
   
   ForceDirectories('/opt/artica/var/getlive/cache');
   value:=TstringList.Create;
   value.Add(conf_datas);
   value.SaveToFile('/opt/artica/logs/getlive');
   value.LoadFromFile('/opt/artica/logs/getlive');
   Config:=TstringList.Create;
   RegExpr:=TRegExpr.Create;
   RegExpr2:=TRegExpr.Create;
   RegExpr.Expression:='poll (.+)';
   for i:=0 to value.Count -1 do begin
       if RegExpr.Exec(value.Strings[i]) then Config.Add('hotmail');
       RegExpr2.Expression:='user\s+"(.+?)\"';
       if RegExpr2.Exec(value.Strings[i]) then Config.Strings[Config.Count-1]:=Config.Strings[Config.Count-1] + ';user="' +RegExpr2.Match[1] + '"';
       RegExpr2.Expression:='pass\s+"(.+?)\"';
       if RegExpr2.Exec(value.Strings[i]) then Config.Strings[Config.Count-1]:=Config.Strings[Config.Count-1] + ';pass="' +RegExpr2.Match[1]+ '"';
       RegExpr2.Expression:='is\s+"(.+?)\"';
       if RegExpr2.Exec(value.Strings[i]) then Config.Strings[Config.Count-1]:=Config.Strings[Config.Count-1] + ';targeted="' +RegExpr2.Match[1]+ '"';
   end;
   
   
   
   GetLiveCf:=TstringList.Create;
   for i:=0 to Config.Count -1 do begin
       RegExpr.Expression:='user="(.+?)"';
       if RegExpr.Exec(Config.Strings[i]) then begin
              RemoteMail:=RegExpr.Match[1];
              RegExpr.Expression:='(.+?)@(.+)';
              if RegExpr.Exec(RemoteMail) then begin
                  user:=RegExpr.Match[1];
                  domain:=RegExpr.Match[2];
              end;
              
        RegExpr.Expression:='pass="(.+?)"';
        if RegExpr.Exec(Config.Strings[i]) then Password:=RegExpr.Match[1];
       
        RegExpr.Expression:='targeted="(.+?)"';
        if RegExpr.Exec(Config.Strings[i]) then SendMailuser:=RegExpr.Match[1];
        GetLiveCf.Add('UserName=' + user);
        GetLiveCf.Add('Password=' + Password);
        GetLiveCf.Add('Domain=' + domain);
        GetLiveCf.Add('Downloaded=/opt/artica/var/getlive/cache/' + RemoteMail);
        GetLiveCf.Add('CurlBin=/opt/artica/bin/curl -k');
        GetLiveCf.Add('Processor=/usr/sbin/sendmail -i ' + SendMailuser);
        GetLiveCf.SaveToFile('/opt/artica/logs/getlive.' + user + '-'+ domain+'.cf');
        CommandLine:=get_ARTICA_PHP_PATH() + '/bin/GetLive.pl --config-file /opt/artica/logs/getlive.'  + user + '-'+ domain + '.cf';
        writeln(CommandLine);
        fpsystem(CommandLine);
        GetLiveCf.Clear;

       
       
       end;
       
   
   end;
   
   
   //Processor = /usr/sbin/sendmail -i <yourusername>
   
//   writeln(Config.text);
   

end;
//#############################################################################



function MyConf.FETCHMAIL_DAEMON_STOP():string;
begin
    result:='';
    fpsystem(FETCHMAIL_BIN_PATH() + ' -q');
end;
//#############################################################################
function MyConf.PROCMAIL_INSTALLED():boolean;
var
    procmail_bin:string;
    mem:TStringList;
     RegExpr:TRegExpr;
     i:integer;
     xzedebug:boolean;
begin

     if not FileExists(POSFTIX_MASTER_CF_PATH()) then begin
        exit;
     end;

     xzedebug:=false;
     if ParamStr(2)='status' then xzedebug:=true;
     
     if xzedebug then writeln('Version............:',PROCMAIL_VERSION());
     
     procmail_bin:=LINUX_APPLICATION_INFOS('procmail_bin');
     if length(procmail_bin)=0 then procmail_bin:='/usr/bin/procmail';
     if not FileExists(procmail_bin) then begin
        if xzedebug then writeln('Path...............:','unable to locate');
        exit(false);
      end;

     if xzedebug then writeln('Path...............:',procmail_bin);
     if xzedebug then writeln('logs Path..........:',PROCMAIL_LOGS_PATH());
     if xzedebug then writeln('user...............:',PROCMAIL_USER());
     if xzedebug then writeln('quarantine path....: ',PROCMAIL_QUARANTINE_PATH());
     if xzedebug then writeln('quarantine size....: ',PROCMAIL_QUARANTINE_SIZE(''));
     if xzedebug then writeln('cyrdeliver path....: ',CYRUS_DELIVER_BIN_PATH());

     mem:=TStringList.Create;
     mem.LoadFromFile(POSFTIX_MASTER_CF_PATH());
     RegExpr:=TRegExpr.Create;
     RegExpr.Expression:='procmail\s+unix.*pipe';
     for i:=0 to mem.Count-1 do begin
         if RegExpr.Exec(mem.Strings[i]) then begin
             mem.Free;
             RegExpr.free;
             if xzedebug then writeln('master.cf..........:','yes');
             exit(true);
         end;
     end;
     exit(false);

end;

 //#############################################################################
function MyConf.PROCMAIL_READ_QUARANTINE(fromFileNumber:integer;tofilenumber:integer;username:string):TstringList;
Var Info  : TSearchRec;
    Count : Longint;
    path  :string;
    Line:TstringList;
    return_line:string;

Begin
  Count:=0;
  Line:=TstringList.Create;
  if tofilenumber=0 then tofilenumber:=100;
if length(username)=0 then  exit(line);
     if length(username)>0  then path:=PROCMAIL_QUARANTINE_PATH() + '/' + username + '/new';
     
  If FindFirst (path+'/*',faAnyFile and faDirectory,Info)=0 then
    begin
    Repeat
      if Info.Name<>'..' then begin
         if Info.Name <>'.' then begin
              Inc(Count);
              if Count>=fromFileNumber then begin
                 return_line:='<file>'+Info.name+'</file>' +  PROCMAIL_READ_QUARANTINE_FILE(path + '/' + info.name);
                 Line.Add(return_line);
                 if ParamStr(1)='-quarantine' then writeln(return_line);
              end;
              if count>=tofilenumber then break;
              //Writeln (Info.Name:40,Info.Size:15);
         end;
      end;

    Until FindNext(info)<>0;
    end;
  FindClose(Info);
  exit(line);
end;
//#############################################################################
function MyConf.PROCMAIL_READ_QUARANTINE_FILE(file_to_read:string):string;
var

    mem:TStringList;
    from,subj,tim:string;
     RegExpr,RegExpr2,RegExpr3:TRegExpr;
     i:integer;
begin
    mem:=TStringList.Create;
    mem.LoadFromFile(file_to_read);
    RegExpr:=TRegExpr.Create;
    RegExpr2:=TRegExpr.Create;
    RegExpr3:=TRegExpr.Create;
    RegExpr.Expression:='^From:\s+(.+)';
    RegExpr2.expression:='Subject:\s+(.+)';
    RegExpr3.expression:='Date:\s+(.+)';
    for i:=0 to mem.Count -1 do begin
        if RegExpr.Exec(mem.Strings[i]) then from:=RegExpr.Match[1];
        if RegExpr2.Exec(mem.Strings[i]) then subj:=RegExpr2.Match[1];
        if RegExpr3.Exec(mem.Strings[i]) then tim:=RegExpr3.Match[1];
        if length(from)+length(subj)+length(tim)>length(from)+length(subj) then break;
    
    end;
    
    RegExpr.free;
    RegExpr2.free;
    mem.free;
    result:='<from>' + from + '</from><time>' + tim + '</time><subject>' + subj + '</subject>';

end;





//#############################################################################
function MyConf.PROCMAIL_QUARANTINE_SIZE(username:string):string;
var
    RegExpr:TRegExpr;
    path:string;
begin
     if not fileexists('/usr/bin/du') then begin
        writeln('warning, unable to locate /usr/bin/du tool');
        exit;
     end;
     if length(username)=0 then  path:=PROCMAIL_QUARANTINE_PATH();
     if length(username)>0  then path:=PROCMAIL_QUARANTINE_PATH() + '/' + username;
     
     RegExpr:=TRegExpr.Create;
     RegExpr.Expression:='([0-9]+)';
     if RegExpr.Exec(trim(ExecPipe('/usr/bin/du -s ' + path))) then begin
     result:=RegExpr.Match[1];
     RegExpr.free;
     exit();
     end;
end;

//#############################################################################
function MyConf.PROCMAIL_QUARANTINE_USER_FILE_NUMBER(username:string):string;
var
   sys:Tsystem;
   count:integer;
   path:string;
begin
     sys:=Tsystem.Create;
     if length(username)=0 then  exit('0');
     if length(username)>0  then path:=PROCMAIL_QUARANTINE_PATH() + '/' + username + '/new';
     count:=sys.DirectoryCountFiles(path);
     sys.free;
     exit(intTostr(count));

end;
//#############################################################################
function MyConf.PROCMAIL_LOGS_PATH():string;
var
    mem:TStringList;
    RegExpr:TRegExpr;
    i:integer;
begin

     if not fileExists('/etc/procmailrc') then exit;
     mem:=TStringList.Create;
      mem.LoadFromFile('/etc/procmailrc');
     RegExpr:=TRegExpr.Create;
     RegExpr.Expression:='LOGFILE=("|\s|)([a-z\.\/]+)';

     for i:=0 to mem.Count-1 do begin

         if RegExpr.Exec(mem.Strings[i]) then begin
            result:=regExpr.Match[2];
            break;
         end;
     
     end;
      
     regExpr.Free;
     mem.Free;
end;
//#############################################################################
function MyConf.PROCMAIL_USER():string;
var
    mem:TStringList;
     RegExpr:TRegExpr;
     i:integer;

begin
   if not FileExists(POSFTIX_MASTER_CF_PATH()) then exit;
   mem:=TStringList.Create;
   mem.LoadFromFile(POSFTIX_MASTER_CF_PATH());
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='flags=([A-Za-z]+)\s+user=([a-zA-Z]+)\s+argv=.+procmail.+';
   for i:=0 to mem.Count-1 do begin
       if RegExpr.Exec(mem.Strings[i]) then begin
          result:=RegExpr.Match[2];
          break;
       end;

     end;
     mem.Free;
     RegExpr.Free;

end;
//#############################################################################
function Myconf.PROCMAIL_VERSION():string;
var
    procmail_bin:string;
    mem:TStringList;
    commandline:string;
     RegExpr:TRegExpr;
     i:integer;
     D:boolean;
begin
 D:=COMMANDLINE_PARAMETERS('debug');
   if D then ShowScreen('PROCMAIL_VERSION:: is there procmail here ???');
    D:=COMMANDLINE_PARAMETERS('debug');
     procmail_bin:=LINUX_APPLICATION_INFOS('procmail_bin');
     if length(procmail_bin)=0 then procmail_bin:='/usr/bin/procmail';
     if not FileExists(procmail_bin) then exit;


     mem:=TStringList.Create;
     commandline:='/bin/cat -v ' +procmail_bin ;

     mem.LoadFromStream(ExecStream(commandline,false));
     RegExpr:=TRegExpr.Create;
     RegExpr.Expression:='v([0-9\.]+)\s+[0-9]{1,4}';

     for i:=0 to mem.Count-1 do begin
       if RegExpr.Exec(mem.Strings[i]) then begin
          result:=RegExpr.Match[1];
          break;
       end;
     
     end;
     mem.Free;
     RegExpr.Free;
end;
//#############################################################################
function MyConf.DNSMASQ_VERSION:string;
var
   binPath:string;
    mem:TStringList;
    commandline:string;
    RegExpr:TRegExpr;
    i:integer;
    D:boolean;
begin
    D:=COMMANDLINE_PARAMETERS('debug');
    binPath:=DNSMASQ_BIN_PATH;

    if not FileExists(binpath) then begin
       if D then ShowScreen('DNSMASQ_VERSION:: unable to stat '+binpath);
       exit;
    end;
    
    commandline:='/bin/cat -v ' +binPath;
    mem:=TStringList.Create;
    mem.LoadFromStream(ExecStream(commandline,false));
    
    
    if D then ShowScreen('DNSMASQ_VERSION:: receive ' + IntToStr(mem.Count) + ' lines');
    
    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='dnsmasq-([0-9\.]+)';

     for i:=0 to mem.Count-1 do begin
//     ShowScreen(mem.Strings[i]);
       if RegExpr.Exec(mem.Strings[i]) then begin
          if D then ShowScreen('DNSMASQ_VERSION:: dnsmasq-([0-9\.]+) => ' + RegExpr.Match[1]);
          result:=RegExpr.Match[1];
          break;
       end;

     end;
     mem.Free;
     RegExpr.Free;

end;
//#############################################################################
function myConf.SQUID_VERSION():string;
var
   tmp            :string;
   RegExpr        :TRegExpr;

begin
   result:='';
   if not FileExists('/opt/artica/sbin/squid') then exit;
   tmp:=ExecPipe('/opt/artica/sbin/squid -v');
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='Squid Cache: Version ([0-9\.A-Za-z]+)';
   if RegExpr.Exec(tmp) then result:=RegExpr.Match[1];
   RegExpr.Free;
   
end;
//#############################################################################
function myConf.DANSGUARDIAN_VERSION():string;
var
   tmp            :string;
   RegExpr        :TRegExpr;
   D              :boolean;
begin
   result:='';
   D:=COMMANDLINE_PARAMETERS('debug');
   if not FileExists('/opt/artica/sbin/dansguardian') then begin
      if D then writeln('DANSGUARDIAN_VERSION -> unable to stat /opt/artica/sbin/dansguardian');
      exit;
   end;
   tmp:=ExecPipe('/opt/artica/sbin/dansguardian -v');
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='DansGuardian\s+([0-9\.A-Za-z]+)';
   if RegExpr.Exec(tmp) then result:=RegExpr.Match[1];
   RegExpr.Free;

end;
//#############################################################################


function Myconf.FETCHMAIL_VERSION():string;
var
    path:string;
    RegExpr:TRegExpr;
    FileData:TStringList;
    i:integer;
    D:Boolean;
begin
      D:=COMMANDLINE_PARAMETERS('debug');
      
      if D then ShowScreen('FETCHMAIL_VERSION:: is there fetchmail here ???');
     path:=FETCHMAIL_BIN_PATH();
     if not FileExists(path) then exit;
     if D then ShowScreen('FETCHMAIL_VERSION:: /bin/cat -v ' + path + '|grep ''This is fetchmail'' >/opt/artica/logs/ftech_ver');
     fpsystem('/bin/cat -v ' + path + '|grep ''This is fetchmail'' >/opt/artica/logs/ftech_ver');

     
     FileData:=TStringList.Create;
     RegExpr:=TRegExpr.Create;
     FileData.LoadFromFile('/opt/artica/logs/ftech_ver');
     RegExpr.Expression:='([0-9\.]+)';
     for i:=0 to FileData.Count -1 do begin
          if RegExpr.Exec(FileData.Strings[i]) then  begin
            result:=RegExpr.Match[1];
            FileData.Free;
            RegExpr.Free;
            exit;
          end;
     end;
end;
//#############################################################################
function myconf.RRDTOOL_BIN_PATH():string;
begin
  if FileExists('/opt/artica/bin/rrdtool') then exit('/opt/artica/bin/rrdtool');
  if FileExists('/usr/bin/rrdtool') then exit('/usr/bin/rrdtool');
  if FileExists('/usr/local/bin/rrdtool') then exit ('/usr/local/bin/rrdtool');
end;
//#############################################################################
function Myconf.RRDTOOL_VERSION():string;
var
    path:string;
    RegExpr:TRegExpr;
    FileData:TStringList;
    D:boolean;
begin
     D:=COMMANDLINE_PARAMETERS('debug');
     path:=RRDTOOL_BIN_PATH();
     if not FileExists(path) then begin
        if D then ShowScreen('RRDTOOL_VERSION:: Unable to stat ' + path);
        exit;
     end;
     FileData:=TStringList.Create;
     FileData.LoadFromStream(ExecStream(path,false));
     RegExpr:=TRegExpr.Create;
     RegExpr.Expression:='([0-9\.]+)';
     if RegExpr.Exec(FileData.Strings[0]) then result:=RegExpr.Match[1];
      RegExpr.Free;
      FileData.Free;
end;
//#############################################################################
function Myconf.SYSTEM_GMT_SECONDS():string;
var value:string;
ini:TIniFile;
begin
ini:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
value:=ini.ReadString('ARTICA','GMT_TIME','');
if length(value)=0 then begin
   value:=trim(ExecPipe('/bin/date +%:::z'));
   ini.WriteString('ARTICA','GMT_TIME',value);
end;
result:=value;
ini.Free;
end;
//#############################################################################
function Myconf.SYSTEM_GET_SYS_DATE():string;
var
   value:string;
begin
   value:=trim(ExecPipe('/bin/date +"%Y-%m-%d;%H:%M:%S"'));
   result:=value;
end;
//#############################################################################
function Myconf.SYSTEM_GET_HARD_DATE():string;
var
   value:string;
begin
   value:=trim(ExecPipe('/sbin/hwclock --show'));
   result:=value;
end;
//#############################################################################


//#############################################################################
function Myconf.RRDTOOL_TIMESTAMP(longdate:string):string;
Begin
result:=RRDTOOL_SecondsBetween(longdate);
End ;
//#############################################################################

function Myconf.RRDTOOL_SecondsBetween(longdate:string):string;
var ANow,AThen : TDateTime;
 gmt,commut:string;
 RegExpr:TRegExpr;
 second,seconds:integer;
 parsed:boolean;
 
begin
     gmt:=SYSTEM_GMT_SECONDS();
     parsed:=False;
     //([0-9]+)[\/\-]([0-9]+)[\/\-]([0-9]+) ([0-9]+)\:([0-9]+)\:([0-9]+)
     if notdebug2=false then if debug then writeln('gmt:',gmt);
     RegExpr:=TRegExpr.Create;
     RegExpr.Expression:='(\+|\-)([0-9]+)';
     RegExpr.Exec(gmt);
     second:=StrToInt(RegExpr.Match[2]);
     seconds:=(second*60)*60;
     if notdebug2=false then begin
        if debug then writeln('GMT seconds:',seconds);
        if debug then writeln('GMT (+-) :('+ RegExpr.Match[1]+ ')');
        if debug then writeln('LONG DATE:('+ longdate+ ')');
     end;
     commut:=RegExpr.Match[1];
     
    if length(longdate)=0 then ANow:=now;
    
    
    
    if length(longdate)>0 then begin
        RegExpr.Expression:='([0-9]+)[\/\-]([0-9]+)[\/\-]([0-9]+)\s+([0-9]+)\:([0-9]+)\:([0-9]+)';
        if RegExpr.exec(longdate) then begin
           if notdebug2=false then if debug then writeln('parse (1): Year (' + RegExpr.Match[1] + ') month(' + RegExpr.Match[2] + ') day(' + RegExpr.Match[3] + ') time: ' +RegExpr.Match[4] + '-' + RegExpr.Match[5] + '-' + RegExpr.Match[6]);
           ANow:=EncodeDateTime(StrToInt(RegExpr.Match[1]), StrToInt(RegExpr.Match[2]), StrToInt(RegExpr.Match[3]), StrToInt(RegExpr.Match[4]), StrToInt(RegExpr.Match[5]), StrToInt(RegExpr.Match[6]), 0);
           parsed:=true;
        end;

        if parsed=false then begin
           RegExpr.Expression:='([0-9]+)[\/\-]([0-9]+)[\/\-]([0-9]+)';
               if RegExpr.exec(longdate) then begin
                  if notdebug2=false then if debug then writeln('parse (2): ' + RegExpr.Match[1] + '-' + RegExpr.Match[2] + '-' + RegExpr.Match[3]);
                  ANow:=EncodeDateTime(StrToInt(RegExpr.Match[1]), StrToInt(RegExpr.Match[2]), StrToInt(RegExpr.Match[3]), 0, 0, 0, 0);
                  parsed:=true;
               end;
       end;
        if parsed=false then begin
           writeln('ERROR : unable to determine date : ' + longdate + ' must be yyyy/mm/dd hh:ii:ss');
           exit;
        end;
      end;
       
       
      AThen:=EncodeDateTime(1970, 1, 1, 0, 0, 0, 0);
      if commut='-' then begin
         if notdebug2=false then if debug then writeln('(-)' + DateTostr(Anow) + ' <> ' + DateTostr(AThen) );
         result:=IntTostr(SecondsBetween(ANow,AThen)+seconds);
      end;

      if commut='+' then begin
         if notdebug2=false then if debug then writeln('(+)' + DateTostr(Anow) + ' <> s' + DateTostr(AThen) );
         result:=IntTostr(SecondsBetween(ANow,AThen)-seconds);
      end;
      if notdebug2=false then if debug then writeln('result:',result);

end;
//#############################################################################

function myconf.ARTICA_FILTER_GET_ALL_PIDS():string;
var
   ps:TStringList;
   articafilter_path,commandline:string;
   i:integer;
   RegExpr:TRegExpr;
   D:boolean;
begin
   result:='';
   ps:=TStringList.CReate;
   D:=COMMANDLINE_PARAMETERS('debug');
articafilter_path:=get_ARTICA_PHP_PATH() + '/bin/artica-filter';
commandline:='/bin/ps -aux';
if D then writeln('ARTICA_FILTER_GET_ALL_PIDS::' +commandline);
   ps.LoadFromStream(ExecStream(commandline,false));
   if ps.Count>0 then begin
       RegExpr:=TRegExpr.Create;
       RegExpr.Expression:='([a-z0-9A-Z]+)\s+([0-9]+).+?'+articafilter_path;
       for i:=0 to ps.count-1 do begin
             //if D then writeln('ARTICA_FILTER_GET_ALL_PIDS::' +ps.Strings[i]);
             if RegExpr.Exec(ps.Strings[i]) then result:=result + RegExpr.Match[2] + ' ';

       end;
       RegExpr.FRee;
   end;
    ps.Free;
end;
//#############################################################################

function Myconf.RRDTOOL_LOAD_AVERAGE():string;
 var filedatas:string;
  RegExpr:TRegExpr;
 Begin
      RegExpr:=TRegExpr.Create;
      
      RegExpr.Expression:='([0-9]+)\.([0-9]+)\s+([0-9]+)\.([0-9]+)\s+([0-9]+)\.([0-9]+)';
      filedatas:=ReadFileIntoString('/proc/loadavg');
      if RegExpr.Exec(filedatas) then begin
         if debug then writeln('RRDTOOL_LOAD_AVERAGE:',RegExpr.Match[1]+RegExpr.Match[2]+';' +RegExpr.Match[3]+RegExpr.Match[4] + ';' +RegExpr.Match[5]+RegExpr.Match[6]);
          result:=RegExpr.Match[1]+RegExpr.Match[2]+';' +RegExpr.Match[3]+RegExpr.Match[4] + ';' +RegExpr.Match[5]+RegExpr.Match[6];
      
      end;
      RegExpr.Free;


end;



//#############################################################################
function Myconf.YOREL_RECONFIGURE(database_path:string):string;
var      artica_path,create_path,upd_path,image_path,du_path,cron_command,andalemono_path:string;
         list:TStringList;
         RegExpr:TRegExpr;
         i:integer;
         sys:Tsystem;
begin
   result:='';
   if not FileExists(RRDTOOL_BIN_PATH()) then begin
         ShowScreen('YOREL_RECONFIGURE:: WARNING !!! unable to locate rrdtool : usually in /usr/bin/rrdtool, found "'+RRDTOOL_BIN_PATH()+'" process cannot continue...');
         exit;
   end;



 artica_path:=get_ARTICA_PHP_PATH() + '/bin/install/rrd';
 image_path:='/opt/artica/share/www/system/rrd';
 forcedirectories(image_path);
 andalemono_path:=artica_path;
 create_path:=artica_path + '/yorel-create';
 upd_path:=artica_path+'/yorel-upd';
 du_path:='/usr/bin/du';
 if length(database_path)=0 then database_path:='/opt/artica/var/rrd/yorel';
 
 forcedirectories(database_path);
 
 if not DirectoryExists(artica_path) then begin
      ShowScreen('YOREL_RECONFIGURE::Unable to stat ' + artica_path);
      exit;
 end;
  if not DirectoryExists(database_path) then begin
      ShowScreen('YOREL_RECONFIGURE::Create ' + database_path);
      ForceDirectories(database_path);
 end;
 
  if not FileExists(andalemono_path) then begin
      ShowScreen('YOREL_RECONFIGURE::Unable to stat ' + andalemono_path);
      exit;
 end;
 
  if not FileExists(create_path) then begin
      ShowScreen('YOREL_RECONFIGURE::Unable to stat ' + create_path);
      exit;
 end;
 
   if not FileExists(du_path) then begin
      ShowScreen('YOREL_RECONFIGURE::Unable to stat ' + du_path);
      exit;
 end;
 
   if not FileExists(upd_path) then begin
      ShowScreen('YOREL_RECONFIGURE::Unable to stat ' + upd_path);
      exit;
 end;


   list:=TStringList.create;
   RegExpr:=TRegExpr.Create;
   
   list.LoadFromFile(create_path);
   for i:=0 to  list.Count-1 do begin
      RegExpr.Expression:='my \$path[\s= ]+';
      if RegExpr.Exec(list.Strings[i]) then begin
         list.Strings[i]:='my $path=''' +  database_path + ''';';
         writeln('Starting......: yorel installation Change path in "' + database_path + '" in [my $path] ' +ExtractFileName(create_path));
      end;
      
      RegExpr.Expression:='RRDp::start';
      if RegExpr.Exec(list.Strings[i]) then begin
          writeln('Starting......: yorel installation Change path in "' + RRDTOOL_BIN_PATH() + '" in line ' + intToStr(i) + ' [RRDp::start] ' +ExtractFileName(create_path));
           list.Strings[i]:=' RRDp::start "' + RRDTOOL_BIN_PATH() + '";';
      end;
      
      
   end;
   writeln('Starting......: yorel installation saving ' + create_path);
   list.SaveToFile(create_path);

  
   
   RegExpr.Expression:='^my \$rdir';
    list.LoadFromFile(upd_path);
       for i:=0 to  list.Count-1 do begin
      if RegExpr.Exec(list.Strings[i]) then begin
         writeln('Starting......: yorel installation Change path "' + database_path + '" in ' +ExtractFileName(upd_path) );
         list.Strings[i]:='my $rdir=''' +  database_path + ''';';
         list.SaveToFile(upd_path);
         break;
      end;
   end;
   




    list.LoadFromFile(upd_path);
       for i:=0 to  list.Count-1 do begin
           RegExpr.Expression:='^my \$gdir';
       
           if RegExpr.Exec(list.Strings[i]) then begin
              writeln('Starting......: yorel installation Change path in "' + image_path + '" in line ' + intToStr(i) + ' [$gdir] ' +ExtractFileName(create_path));
              list.Strings[i]:='my $gdir=''' +  image_path + ''';';
           end;
              
           RegExpr.Expression:='RRDp::start';
           if RegExpr.Exec(list.Strings[i]) then begin
              writeln('Starting......: yorel installation Change path in "' + RRDTOOL_BIN_PATH() + '" in line ' + intToStr(i) + ' [RRDp::start] ' +ExtractFileName(upd_path));
              list.Strings[i]:=' RRDp::start "' + RRDTOOL_BIN_PATH() + '";';
           end;

   end;

     list.SaveToFile(upd_path);
     RegExpr.Free;
     list.free;
   
   sys:=Tsystem.Create();
   if sys.DirectoryCountFiles(database_path)=0 then begin
       writeln('Starting......: yorel installation Create rrd databases in "' + database_path + '"');
       writeln('Starting......: yorel installation "'+create_path+'"');
       fpsystem(create_path);
   
   end;
  if sys.DirectoryCountFiles(database_path)=0 then begin
       sys.Free;
       ShowScreen('YOREL_RECONFIGURE::Error, there was a problem while creating rrd databases in "' + database_path + '"');
       exit;
  end;
  writeln('Starting......: yorel installation Creating the cron script in order automically generate statistics');
  list:=TstringList.Create;
  list.Add('#!/bin/bash');
  list.Add('');
  list.Add('# HDD usage is collected with the following command,');
  list.Add('#  which can only be run as root');
  list.Add('/bin/chmod 644 '+database_path);
  list.Add('/bin/rm -rf ' + image_path + '/*');
  list.Add(upd_path);
  list.SaveToFile(database_path + '/yorel_cron');
  fpsystem('/bin/chmod 777 ' + database_path + '/yorel_cron');
  list.free;
  
  cron_command:='1,3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33,35,37,39,41,43,45,47,49,51,53,55,57,59 * * * *' + chr(9) + 'root' + chr(9) + database_path + '/yorel_cron >/dev/null';
if DirectoryExists('/etc/cron.d') then begin
     list:=TstringList.Create;
     list.Add(cron_command);
     list.SaveToFile('/etc/cron.d/artica_yorel');
     list.Free;
end;

  fpsystem('/bin/cp ' + andalemono_path + '/andalemono ' + database_path+'/andalemono');
  writeln('Starting......: yorel installation Done...');
     
end;

//#############################################################################
function Myconf.QUEUEGRAPH_TEMP_PATH():string;
var debugC:boolean;
list:TStringList;
cgi_path:string;
  RegExpr:TRegExpr;
  i:integer;
begin
debugC:=false;
if ParamStr(1)='-queuegraph' then debugC:=true;
cgi_path:=get_ARTICA_PHP_PATH() + '/bin/queuegraph/queuegraph1.cgi';

if not FileExists(cgi_path) then begin
   if debugC then ShowScreen('QUEUEGRAPH_TEMP_PATH::unable to locate ' + cgi_path);
   exit;
end;
list:=TStringList.Create;
list.LoadFromFile(cgi_path);
RegExpr:=TRegExpr.Create;
RegExpr.Expression:='my \$tmp_dir[=''"\s+]+([a-zA-Z\/_\-0-9]+)';
  for i:=0 to list.Count-1 do begin
        if RegExpr.Exec(list.Strings[i]) then begin
             result:=RegExpr.Match[1];
             break;
        end;
  
  end;
  if debugC then ShowScreen('QUEUEGRAPH_TEMP_PATH:: Path="' + result + '"');
  list.free;
  RegExpr.free;
end;
//#############################################################################
procedure Myconf.RDDTOOL_POSTFIX_MAILS_CREATE_DATABASE();
var
   database_path,date,command:string;
   sday:integer;
begin
     database_path:=RRDTOOL_STAT_POSTFIX_MAILS_SENT_DATABASE_PATH();
     if debug then writeln('RDDTOOL_POSTFIX_MAILS_CREATE_DATABASE');
     if debug then writeln('Testing database "' + database_path + '"');

     if not fileexists(database_path) then begin
        sday:=DayOf(now);
        sday:=sday-2;
        date:=IntTostr(YearOf(now)) + '-' +IntToStr(MonthOf(now)) + '-' + intTostr(sday) + ' 00:00:00';
                if debug then writeln('Creating database..start yesterday ' + date);
        date:=RRDTOOL_SecondsBetween(date);
        command:=RRDTOOL_BIN_PATH() + '  create ' + database_path + ' --start ' + date + ' DS:mails:ABSOLUTE:60:0:U RRA:AVERAGE:0.5:1:60';
        if debug then writeln(command);
        fpsystem(command);

        if debug then writeln('Creating database..done..');
     end;
end;


//#############################################################################
procedure Myconf.RDDTOOL_POSTFIX_MAILS_SENT_STATISTICS();
  var filedatas:TstringList;
  var maillog_path,rdd_sent_path,formated_date,new_formated_date,mem_formated_date:string;
  RegExpr:TRegExpr;
  i:integer;
  month,year,countlines:integer;
  
begin
     mem_formated_date:='';
     maillog_path:=get_LINUX_MAILLOG_PATH();
     if length(maillog_path)=0  then begin
           logs.logs('RDDTOOL_POSTFIX_MAILS_SENT_STATISTICS:: unable to stat maillog...aborting');
           if debug then writeln('unable to locate maillog path');
           exit;
     end;
     notdebug2:=true;
     if debug then writeln('reading ' +  maillog_path);
     rdd_sent_path:=RRDTOOL_STAT_POSTFIX_MAILS_SENT_DATABASE_PATH();
     countlines:=1;
     year:=YearOf(now);
     RegExpr:=TRegExpr.Create;
     filedatas:=TstringList.Create;
     filedatas.LoadFromFile(maillog_path);
     if debug then writeln('starting parsing lines number ',filedatas.Count);
     RegExpr.Expression:='([a-zA-Z]+)\s+([0-9]+)\s+([0-9\:]+).+postfix/(smtp|lmtp).+to=<(.+)>,\s+relay=(.+),.+status=sent.+';
     
     
     for i:=0 to filedatas.Count -1 do begin
         if RegExpr.Exec(filedatas.Strings[i]) then begin
               month:=GetMonthNumber(RegExpr.Match[1]);
               if debug then writeln(filedatas.Strings[i]);
                formated_date:=intTostr(year) + '-' + intTostr(month) + '-' + RegExpr.Match[2] + ' ' + RegExpr.Match[3];
                new_formated_date:=RRDTOOL_SecondsBetween(formated_date);
                if debug then writeln( new_formated_date + '/' +  mem_formated_date);
                if mem_formated_date=new_formated_date then begin
                    countlines:=countlines+1;
                    if debug then writeln( formated_date +  ' increment 1 ('+IntToStr(countlines)+')');
                end else begin
                    if debug then writeln( formated_date +' ' + new_formated_date + ' ' + RegExpr.Match[5] +  '('+IntToStr(countlines)+')->ADD');
                    fpsystem(RRDTOOL_BIN_PATH() + '  update ' + rdd_sent_path + ' ' + new_formated_date+ ':' + IntToStr(countlines));
                    mem_formated_date:=new_formated_date;
                    countlines:=1;
                end;
                
         end;
     
     end;
     RegExpr.Free;
     filedatas.Free;

     

end;
//#############################################################################

procedure Myconf.RDDTOOL_POSTFIX_MAILS_SENT_GENERATE();
var
   commandline:string;
   database_path:string;
   php_path,gif_path,gwidth,gheight:string;
begin
  php_path:=get_ARTICA_PHP_PATH();
  gwidth:=RRDTOOL_GRAPH_WIDTH();
  gheight:=RRDTOOL_GRAPH_HEIGHT();
  database_path:=RRDTOOL_STAT_POSTFIX_MAILS_SENT_DATABASE_PATH();

  gif_path:=php_path + '/img/LOAD_MAIL-SENT-1.gif';
commandline:=RRDTOOL_BIN_PATH() + '  graph ' + gif_path + ' -t "Mails sent pear day" -v "Mails number" -w '+gwidth+' -h '+gheight+' --start -1day ';
commandline:=commandline + 'DEF:mem_ram_libre='+database_path+':mem_ram_libre:AVERAGE  ';
///usr/bin/rrdtool graph /home/touzeau/developpement/artica-postfix/img/LOAD_MAIL-SENT-1.gif -t "Mails sent pear day" -v "Mails number" -w 550 -h 550 --start -1day DEF:mails=/home/touzeau/developpement/artica-postfix/ressources/rrd/postfix-mails-sent.rdd:mails:AVERAGE LINE1:mails\#FFFF00:"Emails number"
           if debug then writeln(commandline);

fpsystem(commandline + ' >/opt/artica/logs/rrd.generate.dustbin');
  if FileExists(gif_path) then fpsystem('/bin/chmod 755 ' + gif_path);

end;

//###########################################################################



//#############################################################################
function Myconf.GetMonthNumber(MonthName:string):integer;
begin
 if MonthName='Jan' then exit(1);
 if MonthName='Feb' then exit(2);
 if MonthName='Mar' then exit(3);
 if MonthName='Apr' then exit(4);
 if MonthName='May' then exit(5);
 if MonthName='Jun' then exit(6);
 if MonthName='Jul' then exit(7);
 if MonthName='Aug' then exit(8);
 if MonthName='Sep' then exit(9);
 if MonthName='Oct' then exit(10);
 if MonthName='Nov'  then exit(11);
 if MonthName='Dec'  then exit(12);
 if MonthName='jan' then exit(1);
 if MonthName='feb' then exit(2);
 if MonthName='mar' then exit(3);
 if MonthName='apr' then exit(4);
 if MonthName='may' then exit(5);
 if MonthName='jun' then exit(6);
 if MonthName='jul' then exit(7);
 if MonthName='aug' then exit(8);
 if MonthName='sep' then exit(9);
 if MonthName='oct' then exit(10);
 if MonthName='nov'  then exit(11);
 if MonthName='dec'  then exit(12);
end;
//#############################################################################


procedure Myconf.RDDTOOL_LOAD_MEMORY_GENERATE();
var
   commandline:string;
   database_path:string;
   php_path,gif_path,gwidth,gheight:string;
begin
  php_path:=get_ARTICA_PHP_PATH();
  gwidth:=RRDTOOL_GRAPH_WIDTH();
  gheight:=RRDTOOL_GRAPH_HEIGHT();
  database_path:=RRDTOOL_STAT_LOAD_MEMORY_DATABASE_PATH();

  gif_path:=php_path + '/img/LOAD_MEMORY-1.gif';
commandline:=RRDTOOL_BIN_PATH() + '  graph ' + gif_path + ' -t "SYSTEM memory pear day" -v "memory bytes" -w '+gwidth+' -h '+gheight+' --start -1day ';
commandline:=commandline + 'DEF:mem_ram_libre='+database_path+':mem_ram_libre:AVERAGE  ';
commandline:=commandline + 'DEF:mem_ram_util='+database_path+':mem_ram_util:AVERAGE  ';
commandline:=commandline + 'DEF:mem_virtu_libre='+database_path+':mem_virtu_libre:AVERAGE  ';
commandline:=commandline + 'DEF:mem_virtu_util='+database_path+':mem_virtu_util:AVERAGE ';
commandline:=commandline + 'CDEF:mem_virtu_libre_tt=mem_virtu_util,mem_virtu_libre,+,1024,* ';
commandline:=commandline + 'CDEF:mem_virtu_util_tt=mem_virtu_util,1024,* ';
commandline:=commandline + 'CDEF:mem_ram_tt=mem_ram_util,mem_ram_libre,+,1024,* ';
commandline:=commandline + 'CDEF:mem_ram_util_tt=mem_ram_util,1024,* ';
commandline:=commandline + 'LINE3:mem_ram_util_tt\#FFFF00:"RAM used" ';
commandline:=commandline + 'LINE2:mem_virtu_util_tt\#FF0000:"Virtual RAM used\n" ';
commandline:=commandline + 'GPRINT:mem_ram_tt:LAST:"RAM  Free %.2lf %s |" ';
commandline:=commandline + 'GPRINT:mem_ram_util_tt:MAX:"RAM  MAX used %.2lf %s |" ';
commandline:=commandline + 'GPRINT:mem_ram_util_tt:AVERAGE:"RAM average util %.2lf %s |" ';
commandline:=commandline + 'GPRINT:mem_ram_util_tt:LAST:"RAM  CUR util %.2lf %s\n" ';
commandline:=commandline + 'GPRINT:mem_virtu_libre_tt:LAST:"Swap Free %.2lf %s |" ';
commandline:=commandline + 'GPRINT:mem_virtu_util_tt:MAX:"Swap MAX used %.2lf %s |" ';
commandline:=commandline + 'GPRINT:mem_virtu_util_tt:AVERAGE:"Swap AVERAGE used %.2lf %s |" \';
commandline:=commandline + 'GPRINT:mem_virtu_util_tt:LAST:"Swap Current used %.2lf %s"';
           if debug then writeln(commandline);

fpsystem(commandline + ' >/opt/artica/logs/rrd.generate.dustbin');
  if FileExists(gif_path) then fpsystem('/bin/chmod 755 ' + gif_path);

end;

//#############################################################################




//#############################################################################
procedure Myconf.RDDTOOL_LOAD_AVERAGE_GENERATE();
var
   commandline:string;
   database_path:string;
   php_path,gif_path,gwidth,gheight:string;
begin
  php_path:=get_ARTICA_PHP_PATH();
  gwidth:=RRDTOOL_GRAPH_WIDTH();
  gheight:=RRDTOOL_GRAPH_HEIGHT();
  database_path:=RRDTOOL_STAT_LOAD_AVERAGE_DATABASE_PATH();
  
  gif_path:=php_path + '/img/LOAD_AVERAGE-1.gif';
  commandline:=RRDTOOL_BIN_PATH() + '  graph ' + gif_path + ' -t "SYSTEM LOAD pear day" -v "Charge x 100" -w '+gwidth+' -h '+gheight+' --start -1day ';
  commandline:=commandline + 'DEF:charge_1min=' + database_path + ':charge_1min:AVERAGE ';
  commandline:=commandline + 'DEF:charge_5min=' + database_path + ':charge_5min:AVERAGE ';
  commandline:=commandline + 'DEF:charge_15min=' + database_path + ':charge_15min:AVERAGE ';
  commandline:=commandline + 'LINE2:charge_1min\#FF0000:"Load 1 minute" ';
  commandline:=commandline + 'LINE2:charge_5min\#00FF00:"load 5 minute" ';
  commandline:=commandline + 'LINE2:charge_15min\#0000FF:"load 15 minute \n" ';
  commandline:=commandline + 'GPRINT:charge_1min:MAX:"System load  1 minute  \: MAX %.2lf %s |" ';
  commandline:=commandline + 'GPRINT:charge_1min:AVERAGE:"AVERAGE %.2lf %s |" ';
  commandline:=commandline + 'GPRINT:charge_1min:LAST:"CUR %.2lf %s \n" ';
  commandline:=commandline + 'GPRINT:charge_5min:MAX:"System load  5 minutes \: MAX %.2lf %s |" ';
  commandline:=commandline + 'GPRINT:charge_5min:AVERAGE:"AVERAGE %.2lf %s |" ';
  commandline:=commandline + 'GPRINT:charge_5min:LAST:"CUR %.2lf %s \n" ';
  commandline:=commandline + 'GPRINT:charge_15min:MAX:"System Load 15 minutes \: MAX %.2lf %s |" ';
  commandline:=commandline + 'GPRINT:charge_15min:AVERAGE:"AVERAGE %.2lf %s |" ';
  commandline:=commandline + 'GPRINT:charge_15min:LAST:"CUR %.2lf %s \n"';
  fpsystem(commandline + ' >/opt/artica/logs/rrd.generate.dustbin');
  if FileExists(gif_path) then fpsystem('/bin/chmod 755 ' + gif_path);

end;

//#############################################################################
procedure Myconf.RDDTOOL_LOAD_CPU_GENERATE();
var
   commandline:string;
   database_path:string;
   php_path,gif_path,gwidth,gheight:string;
begin
  php_path:=get_ARTICA_PHP_PATH();
  gwidth:=RRDTOOL_GRAPH_WIDTH();
  gheight:=RRDTOOL_GRAPH_HEIGHT();
  database_path:=RRDTOOL_STAT_LOAD_CPU_DATABASE_PATH();
  gif_path:=php_path + '/img/LOAD_CPU-1.gif';
  
commandline:=RRDTOOL_BIN_PATH() + ' graph ' + gif_path + ' -t "CPU on day" -v "Util CPU 1/100 Seconds" -w '+gwidth+' -h '+gheight+' --start -1day ';
  commandline:=commandline + 'DEF:utilisateur='+ database_path+':utilisateur:AVERAGE ';
  commandline:=commandline + 'DEF:nice='+ database_path+':nice:AVERAGE ';
  commandline:=commandline + 'DEF:systeme='+ database_path+':systeme:AVERAGE ';
  commandline:=commandline + 'CDEF:vtotale=utilisateur,systeme,+ ';
  commandline:=commandline + 'CDEF:vutilisateur=vtotale,1,GT,0,utilisateur,IF ';
  commandline:=commandline + 'CDEF:vnice=vtotale,1,GT,0,nice,IF ';
  commandline:=commandline + 'CDEF:vsysteme=vtotale,1,GT,0,systeme,IF ';
  commandline:=commandline + 'CDEF:vtotalectrl=vtotale,1,GT,0,vtotale,IF ';
  commandline:=commandline + 'LINE2:vutilisateur\#FF0000:"User" ';
  commandline:=commandline + 'LINE2:vnice\#0000FF:"Nice" ';
  commandline:=commandline + 'LINE2:vsysteme\#00FF00:"system" ';
  commandline:=commandline + 'LINE2:vtotalectrl\#FFFF00:"sum \n" ';
  commandline:=commandline + 'GPRINT:vutilisateur:MAX:"CPU user \: MAX %.2lf %s |" ';
  commandline:=commandline + 'GPRINT:vutilisateur:AVERAGE:"AVERAGE %.2lf %s |" ';
  commandline:=commandline + 'GPRINT:vutilisateur:LAST:"CUR %.2lf %s \n" ';
  commandline:=commandline + 'GPRINT:vnice:MAX:"CPU nice  \: MAX %.2lf %s |" ';
  commandline:=commandline + 'GPRINT:vnice:AVERAGE:"AVERAGE %.2lf %s |" ';
  commandline:=commandline + 'GPRINT:vnice:LAST:"CUR %.2lf %s \n" ';
  commandline:=commandline + 'GPRINT:vsysteme:MAX:"CPU  system   \: MAX %.2lf %s |" ';
  commandline:=commandline + 'GPRINT:vsysteme:AVERAGE:"AVERAGE %.2lf %s |" ';
  commandline:=commandline + 'GPRINT:vsysteme:LAST:"CUR %.2lf %s \n" ';
  commandline:=commandline + 'GPRINT:vtotalectrl:MAX:"Total  CPU    \: MAX %.2lf %s |" ';
  commandline:=commandline + 'GPRINT:vtotalectrl:AVERAGE:"AVERAGE %.2lf %s |" ';
  commandline:=commandline + 'GPRINT:vtotalectrl:LAST:"CUR %.2lf %s \n"';

  if debug then writeln(commandline);
  fpsystem(commandline + ' >/opt/artica/logs/rrd.generate.dustbin');

  if FileExists(gif_path) then fpsystem('/bin/chmod 755 ' + gif_path);
end;
//#############################################################################
function Myconf.RRDTOOL_GRAPH_WIDTH():string;
var value:string;
ini:TIniFile;
begin
ini:=TIniFile.Create('/etc/artica-postfix/artica-postfix-rdd.conf');
value:=ini.ReadString('ARTICA','RRDTOOL_GRAPH_WIDTH','');
if length(value)=0 then  begin
   if debug then writeln('RRDTOOL_GRAPH_WIDTH is not set in ini');
   if debug then writeln('set RRDTOOL_GRAPH_WIDTH to 450');
   value:='550';
   ini.WriteString('ARTICA','RRDTOOL_GRAPH_WIDTH','450');
end;
result:=value;
ini.Free;
end;
//#############################################################################
function Myconf.RRDTOOL_GRAPH_HEIGHT():string;
var value:string;
ini:TIniFile;
begin
ini:=TIniFile.Create('/etc/artica-postfix/artica-postfix-rdd.conf');
value:=ini.ReadString('ARTICA','RRDTOOL_GRAPH_HEIGHT','');
if length(value)=0 then  begin
   if debug then writeln('RRDTOOL_GRAPH_WIDTH is not set in ini');
   if debug then writeln('set RRDTOOL_GRAPH_HEIGHT to 170');
   value:='550';
   ini.WriteString('ARTICA','RRDTOOL_GRAPH_HEIGHT','170');
end;
result:=value;
ini.Free;
end;
//#############################################################################
function MyConf.RRDTOOL_STAT_LOAD_CPU_DATABASE_PATH():string;
var value,phppath,path:string;
ini:TIniFile;
begin
ini:=TIniFile.Create('/etc/artica-postfix/artica-postfix-rdd.conf');
value:=ini.ReadString('ARTICA','STAT_CPU_PATH','');
if length(value)=0 then  begin
   if debug then writeln('STAT_LOAD_PATH is not set in ini path');
   phppath:=get_ARTICA_PHP_PATH();
   path:=phppath+'/ressources/rrd/cpu.rdd';
   if debug then writeln('set STAT_CPU_PATH to '+path);
   value:=path;
   ini.WriteString('ARTICA','STAT_CPU_PATH',path);
   if debug then writeln('done..'+path);
end;
result:=value;
ini.Free;
end;
//#############################################################################
function MyConf.RRDTOOL_STAT_LOAD_MEMORY_DATABASE_PATH():string;
var value,phppath,path:string;
ini:TIniFile;
begin
ini:=TIniFile.Create('/etc/artica-postfix/artica-postfix-rdd.conf');
value:=ini.ReadString('ARTICA','STAT_MEM_PATH','');
if length(value)=0 then  begin
   if debug then writeln('STAT_LOAD_PATH is not set in ini path');
   phppath:=get_ARTICA_PHP_PATH();
   path:=phppath+'/ressources/rrd/mem.rdd';
   if debug then writeln('set STAT_MEM_PATH to '+path);
   value:=path;
   ini.WriteString('ARTICA','STAT_MEM_PATH',path);
   if debug then writeln('done..'+path);
end;
result:=value;
ini.Free;
end;
//#############################################################################
function MyConf.RRDTOOL_STAT_POSTFIX_MAILS_SENT_DATABASE_PATH():string;
var value,phppath,path:string;
ini:TIniFile;
begin
ini:=TIniFile.Create('/etc/artica-postfix/artica-postfix-rdd.conf');
value:=ini.ReadString('ARTICA','STAT_MAIL_SENT_PATH','');
if length(value)=0 then  begin
   if debug then writeln('STAT_MAIL_PATH is not set in ini path');
   phppath:=get_ARTICA_PHP_PATH();
   path:=phppath+'/ressources/rrd/postfix-mails-sent.rdd';
   if debug then writeln('set STAT_MAIL_SENT_PATH to '+path);
   value:=path;
   ini.WriteString('ARTICA','STAT_MAIL_SENT_PATH',path);
   if debug then writeln('done..'+path);
end;
result:=value;
ini.Free;
end;
//#############################################################################
function Myconf.KAS_VERSION():string;
var
    path:string;
    RegExpr:TRegExpr;
    FileData:TStringList;
    i:integer;
begin
     path:='/usr/local/ap-mailfilter3/bin/curvers';
     if not FileExists('/usr/local/ap-mailfilter3/bin/curvers') then exit;
     FileData:=TStringList.Create;
     RegExpr:=TRegExpr.Create;
     FileData.LoadFromFile(path);
     RegExpr.Expression:='CUR_PRODUCT_VERSION="([0-9\.]+)"';
     for i:=0 to FileData.Count -1 do begin
          if RegExpr.Exec(FileData.Strings[i]) then  begin
            result:=RegExpr.Match[1];
            FileData.Free;
            RegExpr.Free;
            exit;
          end;
     end;
end;

//#############################################################################
function Myconf.POSTFIX_VERSION():string;
var
    path,ver:string;
begin
   if not FileExists(POSFTIX_POSTCONF_PATH()) then exit;
   path:=POSFTIX_POSTCONF_PATH();
   if not FileExists(path) then exit;
   ver:=ExecPipe(path + ' -h mail_version');
   exit(trim(ver));
   
end;
//#############################################################################
function myconf.LDAP_GET_BIN_PATH:string;
begin
   if FileExists('/opt/artica/bin/slapd') then exit('/opt/artica/bin/slapd');
end;
//#############################################################################
function Myconf.LDAP_VERSION():string;
var
    path,ver:string;
    RegExpr:TRegExpr;
    commandline:string;
    D:Boolean;
begin
   D:=COMMANDLINE_PARAMETERS('debug');
   
   path:=LDAP_GET_BIN_PATH();

   
   if not FileExists(path) then begin
      if D then ShowScreen('LDAP_VERSION:: Unable to locate slapd bin');
      exit;
   end;
   
   commandline:='/bin/cat -v ' + path + '|grep ''$OpenLDAP:'' >/opt/artica/logs/ldap_ver 2>&1';
   if D then ShowScreen('LDAP_VERSION:: ' + commandline);
   
   fpsystem(commandline);
   ver:=ReadFileIntoString('/opt/artica/logs/ldap_ver');
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='\$OpenLDAP:\s+slapd\s+([0-9\.]+)';
   if RegExpr.Exec(ver) then begin
      ver:=RegExpr.Match[1];
      RegExpr.Free;
      exit(ver);
   end;

end;
//#############################################################################
function Myconf.CYRUS_IMAPD_BIN_PATH():string;
begin
    if FileExists('/opt/artica/cyrus/bin/imapd') then exit('/opt/artica/cyrus/bin/imapd');
end;
//#############################################################################
function Myconf.CYRUS_DELIVER_BIN_PATH():string;
var path:string;
begin
    path:=LINUX_APPLICATION_INFOS('cyrus_deliver_bin');
    if length(path)>0 then exit(path);
    if FileExists('/opt/artica/cyrus/bin/deliver') then exit('/opt/artica/cyrus/bin/deliver');
end;
//#############################################################################
function MyConf.POSFTIX_DELETE_FILE_FROM_CACHE(MessageID:string):boolean;
var FileSource,FileDatas:TStringList;
    php_path,commandline:string;
    RegExpr:TRegExpr;
    D:boolean;
    i:integer;
begin
   D:=COMMANDLINE_PARAMETERS('debug');
  FileSource:=TStringList.Create;
  php_path:=get_ARTICA_PHP_PATH() +'/ressources/databases/*.cache';
  commandline:='/bin/grep -l ' + MessageID + ' ' + php_path;
  if D then ShowScreen('POSFTIX_DELETE_FILE_FROM_CACHE:: EXEC -> ' + commandLine);
  //grep -l 8680973402E /home/touzeau/developpement/artica-postfix/ressources/databases/*.cache
  fpsystem(commandline + ' >/opt/artica/logs/artica_tmp');
  FileSource.LoadFromFile('/opt/artica/logs/artica_tmp');
  
  if FileSource.Count>0 then begin
     if D then ShowScreen('POSFTIX_DELETE_FILE_FROM_CACHE:: Found file : ' +FileSource.Strings[0]);
  end else begin
           if D then ShowScreen('POSFTIX_DELETE_FILE_FROM_CACHE:: no Found file : ');
            FileSource.Free;
            exit(false);
  end;
  FileDatas:=TStringList.Create;
  FileDatas.LoadFromFile(trim(FileSource.Strings[0]));
  RegExpr:=TRegExpr.Create;
  RegExpr.Expression:=MessageID;
  for i:=0 to FileDatas.Count-1 do begin
       if RegExpr.Exec(FileDatas.Strings[i]) then begin
             if D then ShowScreen('POSFTIX_DELETE_FILE_FROM_CACHE:: Pattern found line : ' + IntToStr(i));
            FileDatas.Delete(i);
       
       end;
       if i>=FileDatas.Count-1 then break;
  end;
  FileDatas.SaveToFile(trim(FileSource.Strings[0]));
  RegExpr.free;
  FileDatas.free;
  FileSource.Free;
  exit(true);
end;




//#############################################################################
function MyConf.POSFTIX_CACHE_QUEUE():boolean;
var
   D:boolean;
begin

    D:=COMMANDLINE_PARAMETERS('debug');
    if COMMANDLINE_PARAMETERS('queue=') then begin
           if D then ShowScreen('POSFTIX_CACHE_QUEUE:: Extract a single queue ->' + COMMANDLINE_EXTRACT_PARAMETERS('queue=([a-z]+)'));
           POSFTIX_CACHE_QUEUE_FILE_LIST(COMMANDLINE_EXTRACT_PARAMETERS('queue=([a-z]+)'));
           exit(true);
    
    end;
    logs.logs('POSFTIX_CACHE_QUEUE:: Starting to cache queues directories');

    POSFTIX_CACHE_QUEUE_FILE_LIST('incoming');
    POSFTIX_CACHE_QUEUE_FILE_LIST('active');
    POSFTIX_CACHE_QUEUE_FILE_LIST('deferred');
    POSFTIX_CACHE_QUEUE_FILE_LIST('bounce');
    POSFTIX_CACHE_QUEUE_FILE_LIST('defer');
    POSFTIX_CACHE_QUEUE_FILE_LIST('trace');
    POSFTIX_CACHE_QUEUE_FILE_LIST('maildrop');


end;
//#############################################################################
function MyConf.POSFTIX_CACHE_QUEUE_FILE_LIST(QueueName:string):boolean;
var
   Conf:TiniFile;
   ConfPath,php_path:string;
   FileFiles:TStringList;
   D:boolean;
   WritePath:string;
   FilesNumber:integer;
   FilesNumberCache:integer;
   PagesNumber,start:integer;
   i:integer;

begin
    D:=COMMANDLINE_PARAMETERS('debug');
    if D then ShowScreen('POSFTIX_CACHE_QUEUE_FILE_LIST:: Starting to cache "' + QueueName + '" folder');
    logs.logs('POSFTIX_CACHE_QUEUE_FILE_LIST:: Starting to cache "' + QueueName + '" folder');
    php_path:=get_ARTICA_PHP_PATH();
    ConfPath:=php_path + '/ressources/databases/postfix-queue-cache.conf';
    Conf:=TiniFile.Create(ConfPath);

    if COMMANDLINE_PARAMETERS('flush') then begin
      if D then ShowScreen('POSFTIX_CACHE_QUEUE_FILE_LIST:: flush the cache');
      Conf.WriteInteger(QueueName,'FileNumber',0);
       
    end;

    FilesNumber:=StrToInt(POSTFIX_QUEUE_FILE_NUMBER(QueueName));
    if D then ShowScreen('POSFTIX_CACHE_QUEUE_FILE_LIST:: ' + QueueName + '="' + IntToStr(FilesNumber) +'"');
    
    
    

    
    if FilesNumber=0 then begin
       if D then ShowScreen('POSFTIX_CACHE_QUEUE_FILE_LIST:: no files for '+QueueName);
       exit(true);
    end;
    
    FilesNumberCache:=Conf.ReadInteger(QueueName,'FileNumber',0);
    if FilesNumber=FilesNumberCache then begin
       if D then ShowScreen('Number of files didn''t changed..');
       exit(true);
    end;


    PagesNumber:= FilesNumber div 250;
    if D then ShowScreen('POSFTIX_CACHE_QUEUE_FILE_LIST::Pages number: ' + IntToStr(PagesNumber));
    Conf.WriteInteger(QueueName,'FileNumber',FilesNumber);
    Conf.WriteInteger(QueueName,'PagesNumber',PagesNumber);
    
    
    start:=0;
    for i:=0 to  PagesNumber do begin
        FileFiles:=TStringList.Create;
        FileFiles.AddStrings(POSFTIX_READ_QUEUE_FILE_LIST(start,start+250,QueueName,true));
        WritePath:=php_path + '/ressources/databases/queue.list.'+ IntToStr(i) +'.'+ QueueName + '.cache';
        if D then ShowScreen('POSFTIX_CACHE_QUEUE_FILE_LIST::writing page cache in : ' + WritePath);
        FileFiles.SaveToFile(WritePath);
        FileFiles.Free;
        fpsystem('/bin/chmod 755 ' + WritePath);
        start:=start+300;
    
    end;
    
   Conf.Free;



end;





//#############################################################################
function MyConf.POSFTIX_READ_QUEUE_FILE_LIST(fromFileNumber:integer;tofilenumber:integer;queuepath:string;include_source:boolean):TstringList;
Var Info  : TSearchRec;
    Count : Longint;
    path  :string;
    Line:TstringList;
    return_line,queue_source_path:string;
    D:boolean;
Begin
  if Not FileExists(POSFTIX_POSTCONF_PATH()) then exit;
  queue_source_path:=trim(ExecPipe(POSFTIX_POSTCONF_PATH()+ ' -h queue_directory'));
  Count:=0;
  Line:=TstringList.Create;
  D:=COMMANDLINE_PARAMETERS('debug');
  
  if tofilenumber-fromFileNumber>500 then begin
     if D then ShowScreen('POSFTIX_READ_QUEUE_FILE_LIST::eMail number is too large reduce it to 300');
      Logs.logs('POSFTIX_READ_QUEUE_FILE_LIST::eMail number is too large reduce it to 300');
      tofilenumber:=300;
  end;
  

  if tofilenumber=0 then tofilenumber:=100;
  if length(queuepath)=0 then  begin
     Logs.logs('POSFTIX_READ_QUEUE_FILE_LIST::Queue path is null');
     if D then ShowScreen('POSFTIX_READ_QUEUE_FILE_LIST::Queue path is null');
     exit(line);
  end;


  if include_source then begin
    if length(queuepath)>0  then path:=queue_source_path + '/' + queuepath;
  end else begin

         path:=queuepath;
  end;

  if D then ShowScreen('POSFTIX_READ_QUEUE_FILE_LIST:: ' + queuepath + '::-> ' +path + '/*' );
  Logs.logs('POSFTIX_READ_QUEUE_FILE_LIST::-> ' + queuepath + ':: '+path + ' Read from file number ' + IntTostr(fromFileNumber) + ' to file number ' + IntToStr(tofilenumber) );
  If FindFirst (path+'/*',faAnyFile and faDirectory,Info)=0 then
    begin
    Repeat
      if Info.Name<>'..' then begin
         if Info.Name <>'.' then begin

              if Info.Attr=48 then begin
                 if D then ShowScreen(' -> ' +path + '/' +Info.Name );
                 Line.AddStrings(POSFTIX_READ_QUEUE_FILE_LIST(fromFileNumber,tofilenumber,path + '/' +Info.Name,false));
                 count:=count + Line.Count;
              end;
              
              if Info.Attr=16 then begin
                 if D then ShowScreen(' -> ' +path + '/' +Info.Name );
                 Line.AddStrings(POSFTIX_READ_QUEUE_FILE_LIST(fromFileNumber,tofilenumber,path + '/' +Info.Name,false));
                 count:=count + Line.Count;
              end;

              if Info.Attr=32 then begin
                 Inc(Count);
                 if Count>=fromFileNumber then begin
                    return_line:='<file>'+Info.name+'</file><path>' +path + '/' +Info.Name + '</path>' + POSTFIX_READ_QUEUE_MESSAGE(info.name);
                    if ParamStr(2)='queuelist' then begin
                       if length(ParamStr(6))=0 then ShowScreen(return_line);
                    end;
                    Line.Add(return_line);
                 end;
              end;
              if count>=tofilenumber then break;
              //Writeln (Info.Name:40,Info.Size:15);   postcat -q 3C7F17340B1
         end;
      end;

    Until FindNext(info)<>0;
    end;
    
  FindClose(Info);
  Logs.logs('POSFTIX_READ_QUEUE_FILE_LIST:: ' + queuepath + ':: ->'  +IntToStr(line.Count) + ' line(s)');

  exit(line);
end;
//#############################################################################


function myConf.POSTFIX_READ_QUEUE_MESSAGE(MessageID:string):string;
var
    RegExpr,RegExpr2,RegExpr3,RegExpr4,RegExpr5:TRegExpr;
    FileData:TStringList;
    i:integer;
    m_Time,named_attribute,sender,recipient,Subject:string;
begin
   if not fileExists('/usr/sbin/postcat') then begin
      logs.logs('POSTFIX_READ_QUEUE_MESSAGE:: unable to stat /usr/sbin/postcat');
      exit;
   end;
   

   fpsystem('/usr/sbin/postcat -q ' + MessageID + ' >/opt/artica/logs/' + MessageID + '.tmp');

   if not fileExists('/opt/artica/logs/' + MessageID + '.tmp') then begin
       logs.logs('unable to stat ' + '/opt/artica/logs/' + MessageID + '.tmp');
       exit;
   end;
   FileData:=TStringList.Create;
   FileData.LoadFromFile('/opt/artica/logs/' + MessageID + '.tmp');
   RegExpr:=TRegExpr.Create;
   RegExpr2:=TRegExpr.Create;
   RegExpr3:=TRegExpr.Create;
   RegExpr4:=TRegExpr.Create;
   RegExpr5:=TRegExpr.Create;
   RegExpr.Expression:='message_arrival_time: (.+)';
   RegExpr2.Expression:='named_attribute: (.+)';
   RegExpr3.Expression:='sender: ([a-zA-Z0-9\.@\-_]+)';
   RegExpr4.Expression:='recipient: ([a-zA-Z0-9\.@\-_]+)';
   RegExpr5.Expression:='Subject: (.+)';
   For i:=0 to FileData.Count-1 do begin
        if RegExpr.Exec(FileData.Strings[i]) then m_Time:=RegExpr.Match[1];
        if RegExpr2.Exec(FileData.Strings[i]) then named_attribute:=RegExpr2.Match[1];
        if RegExpr3.Exec(FileData.Strings[i]) then sender:=RegExpr3.Match[1];
        if RegExpr4.Exec(FileData.Strings[i]) then recipient:=RegExpr4.Match[1];
        if RegExpr5.Exec(FileData.Strings[i]) then Subject:=RegExpr5.Match[1];

        if length(m_Time)>0 then begin
           if  length(named_attribute)>0 then begin
               if length(sender)>0 then begin
                  if length(recipient)>0 then begin
                     if length(subject)>0 then begin
                        break
                     end;
                  end;
               end;
           end;
        end;
        
            
   
   end;
   fpsystem('/bin/rm /opt/artica/logs/' + MessageID + '.tmp');
   RegExpr.Free;
   RegExpr2.Free;
   RegExpr3.Free;
   RegExpr4.Free;
   RegExpr5.Free;
   FileData.Free;
   
  exit('<time>' + m_Time + '</time><named_attr>' + named_attribute + '</named_attr><sender>' + sender + '</sender><recipient>' + recipient + '</recipient><subject>' + subject + '</subject>');
   


end;
//#############################################################################
function myconf.POSTFIX_EXPORT_LOGS():boolean;
 var maillog,PHP_PATH:string;
 D:boolean;
 A:boolean;
 begin
   D:=COMMANDLINE_PARAMETERS('debug');
   A:=COMMANDLINE_PARAMETERS('alllogs');
   maillog:=get_LINUX_MAILLOG_PATH();
   PHP_PATH:=get_ARTICA_PHP_PATH();
  if  COMMANDLINE_PARAMETERS('silent') then begin
      A:=false;D:=false;
  end;
   
   if D then Showscreen('POSTFIX_EXPORT_LOGS:: -> receive command to parse logs :"' + maillog + '"');
   if length(maillog)=0 then begin
        Showscreen('POSTFIX_EXPORT_LOGS -> Error, unable to obtain maillog path :"' + maillog + '"');
        exit(true);
   end;

         if not FileExists(maillog) then exit(true);

   if D OR A then Showscreen('POSTFIX_EXPORT_LOGS:: -> get ' + '/usr/bin/tail '+ maillog + ' -n 100' +PHP_PATH + '/ressources/logs/postfix-all-events.log');
   fpsystem('/usr/bin/tail '+ maillog + ' -n 100 >' + PHP_PATH + '/ressources/logs/postfix-all-events.log');
   fpsystem('/usr/bin/tail '+ maillog + ' -n 100|grep postfix >' + PHP_PATH + '/ressources/logs/postfix-events.log');
   fpsystem('/bin/chmod 0755 '+PHP_PATH + '/ressources/logs/postfix*');
   
end;


//#############################################################################
function Myconf.POSTFIX_QUEUE_FILE_NUMBER(directory_name:string):string;
         const
            CR = #$0d;
            LF = #$0a;
            CRLF = CR + LF;

var filepath:string;
system:Tsystem;
sCount:integer;
count_incoming,count_active,count_deferred,count_bounce,count_defer,count_trace,count_maildrop:integer;
fef:boolean;
begin

if not FileExists(POSFTIX_POSTCONF_PATH()) then exit;

fef:=false;
    directory_name:=trim(directory_name);
    if length(directory_name)=0 then fef:=false;
    if directory_name='incoming' then fef:=true;
    if directory_name='active' then fef:=true;
    if directory_name='deferred' then fef:=true;
    if directory_name='bounce' then fef:=true;
    if directory_name='defer' then fef:=true;
    if directory_name='trace' then fef:=true;
    if directory_name='maildrop' then fef:=true;
    if directory_name='all' then fef:=true;


  if fef=false then begin
     writeln('must third parameters muste be: all or specific: incoming,active,deferred,bounce,trace,defer or maildrop');
     exit('0');
  end;




    system:=Tsystem.Create;
    filepath:=trim(ExecPipe(POSFTIX_POSTCONF_PATH()+ ' -h queue_directory'));

    
    if directory_name='all' then begin
        count_incoming:=system.DirectoryCountFiles(filepath + '/incoming');
        count_active:=system.DirectoryCountFiles(filepath + '/active');
        count_deferred:=system.DirectoryCountFiles(filepath + '/deferred');
        count_bounce:=system.DirectoryCountFiles(filepath + '/bounce');
        count_defer:=system.DirectoryCountFiles(filepath + '/defer');
        count_trace:=system.DirectoryCountFiles(filepath + '/trace');
        count_maildrop:=system.DirectoryCountFiles(filepath + '/maildrop');


        result:='incoming:' + IntToStr(count_incoming) + CRLF;
        result:=result +  'active:' + IntToStr(count_active) + CRLF;
        result:=result +  'deferred:' + IntToStr(count_deferred) + CRLF;
        result:=result +  'bounce:' + IntToStr(count_bounce) + CRLF;
        result:=result +  'defer:' + IntToStr(count_defer) + CRLF;
        result:=result +  'trace:' + IntToStr(count_trace) + CRLF;
        result:=result +  'maildrop:' + IntToStr(count_maildrop) + CRLF;
        system.free;
        exit();
    
    end;
    
    
    sCount:=system.DirectoryCountFiles(filepath + '/'+directory_name);
    system.Free;
    exit(IntTostr(sCount));
end;

//#############################################################################
function myconf.INYADIN_VERSION():string;
var
   RegExpr        :TRegExpr;
   tmpstring      :string;
begin
   tmpstring:=ExecPipe(get_ARTICA_PHP_PATH()+ '/bin/inadyn --version');
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='([0-9\.]+)';
   if RegExpr.Exec(tmpstring) then result:=RegExpr.Match[1];
   RegExpr.free;

end;
//#############################################################################


function Myconf.CYRUS_VERSION():string;
var
    path,ver,netcat:string;
    RegExpr:TRegExpr;
    D:boolean;
    zini:TStringList;
    cyrver:string;
    cyrcount:integer;
begin
   path:=CYRUS_IMAPD_BIN_PATH();
   D:=COMMANDLINE_PARAMETERS('debug');
   if D then ShowScreen('CYRUS_VERSION:: Imapd bin path is ' + path);
   cyrcount:=0;

   
   if not FileExists(path) then begin
      if D then ShowScreen('CYRUS_VERSION::Unable to stat path');
      exit;
   end;
   
   zini:=TStringList.Create;
   if FileExists('/etc/artica-postfix/cyrusversion.conf') then begin
   zini.LoadFromFile('/etc/artica-postfix/cyrusversion.conf');
   cyrver:=zini.Strings[0];
   if length(zini.Strings[1])>0 then cyrcount:=StrToInt(zini.Strings[1]);
   
   
   if D then ShowScreen('CYRUS_VERSION:: CONF= ' + cyrver);
   
   if length(cyrver)>1 then begin
      cyrcount:=cyrcount+1;
      if cyrcount>20 then begin
         zini.Strings[1]:='0';
         zini.SaveToFile('/etc/artica-postfix/cyrusversion.conf');
         result:=cyrver;
         zini.Free;
         exit;
      end;
      result:=cyrver;
      zini.Strings[1]:=IntTostr(cyrcount);
      zini.SaveToFile('/etc/artica-postfix/cyrusversion.conf');
      zini.Free;
      exit;
   
   end;
   end;
   
   netcat:='/bin/nc';
   if FileExists('/usr/bin/netcat') then netcat:='/usr/bin/netcat';
   if FileExists('/usr/bin/nc') then  netcat:='/usr/bin/nc';
   
   if zini.Count=0 then begin
      zini.Add(netcat);
      zini.Add('0');
   end;
   

   if D then ShowScreen('CYRUS_VERSION:: netcat is "' + netcat + '"');

   if D then ShowScreen('CYRUS_VERSION::/bin/echo . logout|'+netcat+' localhost 143|grep server >/opt/artica/logs/cyrus_ver');
   fpsystem('/bin/echo . logout|'+netcat+' localhost 143|grep server >/opt/artica/logs/cyrus_ver');
   ver:=ReadFileIntoString('/opt/artica/logs/cyrus_ver');
   if D then ShowScreen('CYRUS_VERSION:: ver "' + ver + '"');
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:=' v([0-9A-Za-z\.\-]+)';
   if RegExpr.Exec(ver) then begin
      if D then ShowScreen('CYRUS_VERSION:: -> ' + RegExpr.Match[1]);
      ver:=RegExpr.Match[1];
      if D then ShowScreen('CYRUS_VERSION:: ver "' + RegExpr.Match[1] + '"');
      RegExpr.Free;
      cyrcount:=cyrcount+1;
       zini.Strings[1]:=IntTostr(cyrcount);
       zini.Strings[0]:=ver;
       zini.SaveToFile('/etc/artica-postfix/cyrusversion.conf');
       zini.Free;
      exit(ver);
   end;
   RegExpr.Free;
   
   zini.Strings[1]:=IntTostr(cyrcount);
   zini.Strings[0]:=result;
   zini.SaveToFile('/etc/artica-postfix/cyrusversion.conf');
   zini.Free;
   result:='0.0.0';
   if D then ShowScreen('CYRUS_VERSION:: -> ' + result);

   
end;

//#############################################################################
function MyConf.get_LINUX_DISTRI():string;
var value:string;
begin
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
value:=GLOBAL_INI.ReadString('LINUX','distribution-name','');
result:=value;
GLOBAL_INI.Free;
end;
//#############################################################################
function MyConf.get_MANAGE_MAILBOX_SERVER():string;
var value:string;
begin
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
value:=GLOBAL_INI.ReadString('COURIER','server-type','cyrus');
result:=value;
GLOBAL_INI.Free;
end;
//#############################################################################
procedure MyConf.set_MANAGE_MAILBOX_SERVER(val:string);
var ini:TIniFile;
begin
ini:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
ini.WriteString('COURIER','server-type',val);
ini.Free;
end;
//#############################################################################
function MyConf.get_DEBUG_DAEMON():boolean;
var value:string;
begin
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
value:=GLOBAL_INI.ReadString('LOGS','Debug','0');
if value='0' then result:=False;
if value='1' then result:=True;
GLOBAL_INI.Free;
end;
//#############################################################################
function MyConf.CYRUS_REPLICATION_MINUTES():integer;
var value:integer;
begin
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
value:=GLOBAL_INI.ReadInteger('CYRUS','REPLICATE_MIN',0);
if value=0 then begin
   result:=5;
   GLOBAL_INI.WriteInteger('CYRUS','REPLICATE_MIN',5);
end;
result:=value;
GLOBAL_INI.Free;
end;
//#############################################################################
function MyConf.CYRUS_LAST_REPLIC_TIME():integer;
var tDate,tdate2:TDateTime;
value:string;
begin
tdate2:=Now;
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
value:=GLOBAL_INI.ReadString('CYRUS','CYRUS_LAST_REPLIC_TIME','');
if length(value)=0 then begin
        tDate:=Now;
        value:=DateTimeToStr(tdate);
        GLOBAL_INI.WriteDateTime('CYRUS','CYRUS_LAST_REPLIC_TIME',tDate);
end;
if length(value)>0 then begin
   tDate:=StrToDateTime(value);
   result:=Round(MinuteSpan(tDate,tdate2));
end;
   GLOBAL_INI.Free;
end;
//#############################################################################
procedure myconf.CYRUS_RESET_REPLIC_TIME();
var tDate:TDateTime;
begin
   tDate:=now;
   GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
   GLOBAL_INI.WriteDateTime('CYRUS','CYRUS_LAST_REPLIC_TIME',tDate);
   GLOBAL_INI.Free;
end;
//#############################################################################
procedure myconf.KEEPUP2DATE_RESET_REPLIC_TIME();
var tDate:TDateTime;
begin
   tDate:=now;
   GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
   GLOBAL_INI.WriteDateTime('KAV','KEEPUP2DATE_LAST_REPLIC_TIME',tDate);
   GLOBAL_INI.Free;
end;
//#############################################################################
procedure myconf.KAV_RESET_REPLIC_TIME();
var tDate:TDateTime;
begin
   tDate:=now;
   GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
   GLOBAL_INI.WriteDateTime('KAV','LAST_REPLIC_TIME',tDate);
   GLOBAL_INI.Free;
end;
//#############################################################################
function MyConf.KEEPUP2DATE_LAST_REPLIC_TIME():integer;
var tDate,tdate2:TDateTime;
value:string;
begin
tdate2:=Now;
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
value:=GLOBAL_INI.ReadString('KAV','KEEPUP2DATE_LAST_REPLIC_TIME','');
if length(value)=0 then begin
        tDate:=Now;
        value:=DateTimeToStr(tdate);
        GLOBAL_INI.WriteDateTime('KAV','KEEPUP2DATE_LAST_REPLIC_TIME',tDate);
end;
if length(value)>0 then begin
   tDate:=StrToDateTime(value);
   result:=Round(MinuteSpan(tDate,tdate2));
end;
   GLOBAL_INI.Free;
end;
//#############################################################################

function MyConf.KAV_LAST_REPLIC_TIME():integer;
var tDate,tdate2:TDateTime;
value:string;
begin
tdate2:=Now;
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
value:=GLOBAL_INI.ReadString('KAV','LAST_REPLIC_TIME','');
if length(value)=0 then begin
        tDate:=Now;
        value:=DateTimeToStr(tdate);
        GLOBAL_INI.WriteDateTime('KAV','LAST_REPLIC_TIME',tDate);
end;
if length(value)>0 then begin
   tDate:=StrToDateTime(value);
   result:=Round(MinuteSpan(tDate,tdate2));
end;
   GLOBAL_INI.Free;
end;
//#############################################################################
function MyConf.KEEPUP2DATE_REPLICATION_MINUTES():integer;
var value:integer;
begin
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
value:=GLOBAL_INI.ReadInteger('KAV','KEEPUP2DATE_REPLICATE_MIN',0);
if value=0 then begin
   result:=60;
   GLOBAL_INI.WriteInteger('KAV','KEEPUP2DATE_REPLICATE_MIN',60);
end;
result:=value;
GLOBAL_INI.Free;
end;
//#############################################################################
function MyConf.KAV_REPLICATION_MINUTES():integer;
var value:integer;
begin
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
value:=GLOBAL_INI.ReadInteger('KAV','REPLICATE_MIN',0);
if value=0 then begin
   result:=5;
   GLOBAL_INI.WriteInteger('KAV','REPLICATE_MIN',5);
end;
result:=value;
GLOBAL_INI.Free;
end;
//#############################################################################
function MyConf.get_MANAGE_SASL_TLS():boolean;
var value:string;
begin
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
value:=GLOBAL_INI.ReadString('POSTFIX','sasl-tls','0');
if value='0' then result:=False;
if value='1' then result:=True;
GLOBAL_INI.Free;
end;
//#############################################################################
procedure MyConf.set_MANAGE_SASL_TLS(val:boolean);
var ini:TIniFile;
begin
ini:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
if val=True then ini.WriteString('POSTFIX','sasl-tls','1');
if val=False then ini.WriteString('POSTFIX','sasl-tls','0');
ini.Free;
end;
//#############################################################################
function MyConf.get_repositories_librrds_perl():boolean;
var value:string;
begin
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
value:=GLOBAL_INI.ReadString('REPOSITORIES','librrds-perl','0');
if value='0' then result:=False;
if value='1' then result:=True;
GLOBAL_INI.Free;
end;
//#############################################################################
function MyConf.ARTICA_AutomaticConfig():boolean;
var value:string;
begin
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
value:=GLOBAL_INI.ReadString('ARTICA','AutomaticConfig','no');
if value='no' then result:=False;
if value='yes' then result:=True;
GLOBAL_INI.Free;
end;
//#############################################################################


function MyConf.get_repositories_openssl():boolean;
var value:string;
begin
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
value:=GLOBAL_INI.ReadString('REPOSITORIES','openssl','0');
if value='0' then result:=False;
if value='1' then result:=True;
GLOBAL_INI.Free;
end;
//#############################################################################
function MyConf.AVESERVER_GET_VALUE(KEY:string;VALUE:string):string;
begin
  if not FileExists('/etc/kav/5.5/kav4mailservers/kav4mailservers.conf') then exit;
  GLOBAL_INI:=TIniFile.Create('/etc/kav/5.5/kav4mailservers/kav4mailservers.conf');
  result:=GLOBAL_INI.ReadString(KEY,VALUE,'');
  GLOBAL_INI.Free;
end;

//#############################################################################
function MyConf.KAV4PROXY_GET_VALUE(KEY:string;VALUE:string):string;
begin
  if not FileExists('/etc/opt/kaspersky/kav4proxy.conf') then exit;
  GLOBAL_INI:=TIniFile.Create('/etc/opt/kaspersky/kav4proxy.conf');
  result:=GLOBAL_INI.ReadString(KEY,VALUE,'');
  GLOBAL_INI.Free;
end;
//#############################################################################
function MyConf.KAVMILTER_GET_VALUE(KEY:string;VALUE:string):string;
begin
  if not FileExists('/etc/kav/5.6/kavmilter/kavmilter.conf') then exit;
  GLOBAL_INI:=TIniFile.Create('/etc/kav/5.6/kavmilter/kavmilter.conf');
  result:=GLOBAL_INI.ReadString(KEY,VALUE,'');
  GLOBAL_INI.Free;
end;

//#############################################################################

function MyConf.AVESERVER_SET_VALUE(KEY:string;VALUE:string;DATA:string):string;
begin
result:='';
  if not FileExists('/etc/kav/5.5/kav4mailservers/kav4mailservers.conf') then exit;
  GLOBAL_INI:=TIniFile.Create('/etc/kav/5.5/kav4mailservers/kav4mailservers.conf');
  GLOBAL_INI.WriteString(KEY,VALUE,DATA);
  GLOBAL_INI.Free;
end;
//#############################################################################
function MyConf.CROND_INIT_PATH():string;
begin
   if FileExists('/etc/init.d/crond') then exit('/etc/init.d/crond');
   if FileExists('/etc/init.d/cron') then exit('/etc/init.d/cron');
end;

function MyConf.AVESERVER_GET_TEMPLATE_DATAS(family:string;ztype:string):string;
var
   key_name:string;
   file_name:string;
   template:string;
   subject:string;
begin
  if not FileExists('/etc/kav/5.5/kav4mailservers/kav4mailservers.conf') then exit;
  
  key_name:='smtpscan.notify.' + ztype + '.' + family;
  GLOBAL_INI:=TIniFile.Create('/etc/kav/5.5/kav4mailservers/kav4mailservers.conf');
  file_name:=GLOBAL_INI.ReadString(key_name,'Template','');
  subject:=GLOBAL_INI.ReadString(key_name,'Subject','');
  
  if not FileExists(file_name) then exit;


  template:=ReadFileIntoString(file_name);
  
  
  
  result:='<subject>' + subject + '</subject><template>' + template + '</template>';
  
  
end;
 //#############################################################################

procedure MyConf.AVESERVER_REPLICATE_TEMPLATES();
var phpath,ressources_path:string;
Files:string;
SYS:TSystem;
i:integer;
D:boolean;
RegExpr:TRegExpr;
DirFile:string;
key:string;
begin
  D:=COMMANDLINE_PARAMETERS('debug');
  phpath:=get_ARTICA_PHP_PATH();
  SYS:=TSystem.Create;
  ressources_path:=phpath + '/ressources/conf';
  SYS.DirFiles(ressources_path,'notify_*');
  if SYS.DirListFiles.Count=0 then begin
     SYS.Free;
     exit;
  end;
  
  RegExpr:=TRegExpr.Create;
  RegExpr.Expression:='notify_([a-z]+)_([a-z]+)';
  For i:=0 to SYS.DirListFiles.Count -1 do begin
     if RegExpr.Exec(SYS.DirListFiles.Strings[i]) then begin;
        key:='smtpscan.notify.' + RegExpr.Match[2] + '.' +  RegExpr.Match[1];
        DirFile:=AVESERVER_GET_VALUE(key,'Template');
        Files:=ressources_path + '/' + SYS.DirListFiles.Strings[i];
        if length(DirFile)>0 then begin
           if D then ShowScreen('AVESERVER_REPLICATE_TEMPLATES:: replicate ' + Files + ' to "'+ DirFile + '"');
           fpsystem('/bin/mv ' + Files + ' ' + DirFile);
        end;
     end;
  
  end;
 RegExpr.Free;
 SYS.Free;

 
end;
 //#############################################################################
 

function MyConf.AVESERVER_GET_KEEPUP2DATE_LOGS_PATH():string;
begin
  result:=AVESERVER_GET_VALUE('updater.report','ReportFileName');
end;
 //#############################################################################
function MyConf.AVESERVER_GET_LOGS_PATH():string;
begin
  result:=AVESERVER_GET_VALUE('aveserver.report','ReportFileName');
end;
 //#############################################################################
function MyConf.KAVMILTERD_GET_LOGS_PATH():string;
         var path:string;
begin
  path:=KAVMILTER_GET_VALUE('kavmilter.log','LogFacility');
  if path='syslog' then begin
     if FileExists('/var/log/syslog') then exit('/var/log/syslog');
     exit;
  end;
  
  exit(KAVMILTER_GET_VALUE('kavmilter.log','LogFilepath'));
end;
 //#############################################################################
function MyConf.KAVMILTERD_GET_LASTLOGS():string;
var
   cmd,grep:string;
begin
  grep:='';
  if KAVMILTER_GET_VALUE('kavmilter.log','LogFacility')='syslog' then grep:='|grep -E "kavmilter\[[0-9]+\]"';
  cmd:='/usr/bin/tail -n 500 ' + KAVMILTERD_GET_LOGS_PATH() + grep + ' '+' >/opt/artica/logs/kavmilter.last.logs';
  logs.logs('KAVMILTERD_GET_LASTLOGS:: ' + cmd);
  fpsystem(cmd);
  result:=ReadFileIntoString('/opt/artica/logs/kavmilter.last.logs');

end;


 //#############################################################################
function MyConf.AVESERVER_GET_DAEMON_PORT():string;
var
   master_cf:Tstringlist;
   RegExpr:TRegExpr;
   i:integer;
   master_line:string;
begin
    master_cf:=TStringList.create;
    master_cf.LoadFromFile(POSFTIX_MASTER_CF_PATH());
    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='user=kluser\s+argv=\/opt\/kav\/.+';
    for i:=0 to master_cf.Count-1 do begin
        if RegExpr.Exec(master_cf.Strings[i]) then begin
                   master_line:=master_cf.Strings[i-1];
        end;
    end;
    
    RegExpr.Expression:='^.+:([0-9]+)\s+inet';
    if RegExpr.Exec(master_line) then result:=RegExpr.Match[1];
    RegExpr.Free;
    master_cf.free;
    

end;
 //#############################################################################
 
function MyConf.AVESERVER_GET_PID():string;
var pidpath:string;
begin
  pidpath:=AVESERVER_GET_VALUE('path','AVSpidPATH');
  if length(pidpath)=0 then exit;
  result:=trim(ReadFileIntoString(pidpath));
end;
//#############################################################################
function MyConf.AVESERVER_GET_VERSION():string;
var licensemanager,datas:string;
   RegExpr:TRegExpr;
   D:boolean;
begin
 D:=COMMANDLINE_PARAMETERS('debug');
if D then LOGS.logs('AVESERVER_GET_VERSION:: IS there any kasprsky here ???');

    if FileExists('/opt/kav/5.6/kavmilter/bin/kavmilter') then begin
         datas:=ExecPipe('/opt/kav/5.6/kavmilter/bin/kavmilter -v');
         RegExpr:=TRegExpr.Create();
         RegExpr.expression:='([0-9\.]+)';
         if RegExpr.Exec(datas) then begin
            result:=RegExpr.Match[1];
         end;
         RegExpr.Free;
         exit;
    end;


    if not FileExists('/etc/init.d/aveserver') then exit;
    licensemanager:='/opt/kav/5.5/kav4mailservers/bin/licensemanager';
    if not FileExists(licensemanager) then exit;
    datas:=ExecPipe('/opt/kav/5.5/kav4mailservers/bin/aveserver -v');
    RegExpr:=TRegExpr.Create();
    RegExpr.expression:='([0-9\.]+).+RELEASE.+build.+#([0-9]+)';

    if RegExpr.Exec(datas) then begin
       if Debug=true then LOGS.logs('MyConf.ExportLicenceInfos -> ' + RegExpr.Match[1] + ' build ' + RegExpr.Match[2]);
        result:=RegExpr.Match[1] + ' build ' + RegExpr.Match[2];
     end;

     if not RegExpr.Exec(datas) then begin
         if Debug=true then LOGS.logs('MyConf.ExportLicenceInfos -> unable to catch version');
    end;
     RegExpr.Free;

end;
//##############################################################################
function MyConf.AVESERVER_GET_LICENCE():string;
var licensemanager:string;
begin
    if not FileExists('/etc/init.d/aveserver') then exit;
    licensemanager:='/opt/kav/5.5/kav4mailservers/bin/licensemanager';
    if not FileExists(licensemanager) then exit;
    result:=ExecPipe(licensemanager + ' -s');
end;
//##############################################################################


function MyConf.get_repositories_Checked():boolean;
var value:string;
begin
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
value:=GLOBAL_INI.ReadString('REPOSITORIES','Checked','0');
if value='0' then result:=False;
if value='1' then result:=True;
GLOBAL_INI.Free;
end;

//#############################################################################
function MyConf.set_repositories_checked(val:boolean):string;
var ini:TIniFile;
begin
result:='';
ini:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
if val=True then ini.WriteString('REPOSITORIES','Checked','1');
if val=False then ini.WriteString('REPOSITORIES','Checked','0');
ini.Free;
end;
//#############################################################################
function MyConf.get_kaspersky_mailserver_smtpscanner_logs_path():string;
begin
GLOBAL_INI:=TIniFile.Create('/etc/kav/5.5/kav4mailservers/kav4mailservers.conf');
result:=GLOBAL_INI.ReadString('smtpscan.report','ReportFileName','/var/log/kav/5.5/kav4mailservers/smtpscanner.log');
GLOBAL_INI.Free;
end;
//#############################################################################

procedure MyConf.set_MYSQL_INSTALLED(val:boolean);
begin
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
if val=True then GLOBAL_INI.WriteString('LINUX','MYSQL_INSTALLED','1');
if val=False then GLOBAL_INI.WriteString('LINUX','MYSQL_INSTALLED','0');
GLOBAL_INI.Free;
end;
function MyConf.get_MYSQL_INSTALLED():boolean;
var value:string;
begin
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
value:=GLOBAL_INI.ReadString('LINUX','MYSQL_INSTALLED','0');
if value='0' then result:=False;
if value='1' then result:=True;
GLOBAL_INI.Free;
end;
function MyConf.get_POSTFIX_DATABASE():string;
var xres:string;
begin
result:='ldap';
exit;
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
xres:=GLOBAL_INI.ReadString('INSTALL','POSTFIX_DATABASE','hash');
if length(xres)=0 then xres:='ldap';
result:='ldap';
GLOBAL_INI.Free;
end;
function MyConf.get_MANAGE_MAILBOXES():string;
begin
result:='';
if not fileExists('/etc/artica-postfix/artica-postfix.conf') then begin
    if debug then writeln('unable to stat /etc/artica-postfix/artica-postfix.conf');
    exit;
end;
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
result:=GLOBAL_INI.ReadString('ARTICA','MANAGE_MAILBOXES','');
result:=trim(result);
if length(result)=0 then begin
    result:=GLOBAL_INI.ReadString('INSTALL','MANAGE_MAILBOXES','');
    if length(result)>0 then GLOBAL_INI.WriteString('ARTICA','MANAGE_MAILBOXES',result);
end;
result:=trim(result);
if length(result)=0 then result:='no';
if result='FALSE' then result:='no';
if result='TRUE' then result:='yes';
if debug then writeln('get_MANAGE_MAILBOXES=' + result);
GLOBAL_INI.Free;
end;
function MyConf.set_POSTFIX_DATABASE(val:string):string;
begin
result:='';
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
 GLOBAL_INI.WriteString('INSTALL','POSTFIX_DATABASE',val);
GLOBAL_INI.Free;
end;
function MyConf.set_MANAGE_MAILBOXES(val:string):string;
begin
result:='';
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
 GLOBAL_INI.WriteString('ARTICA','MANAGE_MAILBOXES',val);
GLOBAL_INI.Free;
end;

function MyConf.set_INSTALL_PATH(val:string):string;
begin
result:='';
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
 GLOBAL_INI.WriteString('INSTALL','INSTALL_PATH',val);
GLOBAL_INI.Free;
end;
function MyConf.get_INSTALL_PATH():string;
begin
result:='';
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
result:=GLOBAL_INI.ReadString('INSTALL','INSTALL_PATH','');
GLOBAL_INI.Free;
end;


function MyConf.set_DISTRI(val:string):string;
begin
result:='';
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
 GLOBAL_INI.WriteString('LINUX','DISTRI',val);
GLOBAL_INI.Free;
end;
function MyConf.get_DISTRI():string;
begin
result:='';
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
result:=GLOBAL_INI.ReadString('LINUX','DISTRI','');
GLOBAL_INI.Free;
end;
function MyConf.get_UPDATE_TOOLS():string;
begin
result:='';
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
result:=GLOBAL_INI.ReadString('LINUX','UPDATE_TOOLS','');
GLOBAL_INI.Free;
end;
//##################################################################################
function MyConf.set_UPDATE_TOOLS(val:string):string;
begin
result:='';
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
 GLOBAL_INI.WriteString('LINUX','UPDATE_TOOLS',val);
GLOBAL_INI.Free;
end;
//##################################################################################
function MyConf.get_ARTICA_PHP_PATH():string;
var path:string;
begin
  if not DirectoryExists('/usr/share/artica-postfix') then begin
  path:=ParamStr(0);
  path:=ExtractFilePath(path);
  path:=AnsiReplaceText(path,'/bin/','');
  exit(path);
  end else begin
  exit('/usr/share/artica-postfix');
  end;
  
end;
//##################################################################################
function MyConf.set_ARTICA_PHP_PATH(val:string):string;
begin
result:='';
if length(val)=0 then exit;
TRY
   GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
   GLOBAL_INI.WriteString('ARTICA','PHP_PATH',val);
   GLOBAL_INI.Free;
EXCEPT
  writeln('FATAL ERROR set_ARTICA_PHP_PATH function !!!');
end;
end;
//##################################################################################
function MyConf.get_ARTICA_LOCAL_PORT():integer;
begin
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
result:=GLOBAL_INI.ReadInteger('ARTICA','LOCALPORT',0);

if result=0 then begin
   result:=47979;
   GLOBAL_INI.WriteInteger('ARTICA','LOCALPORT',47979);
end;

    GLOBAL_INI.Free

end;
function MyConf.get_ARTICA_LOCAL_SECOND_PORT():integer;
begin
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
result:=GLOBAL_INI.ReadInteger('ARTICA','SECOND_LOCAL_PORT',0);
GLOBAL_INI.Free;
end;
procedure MyConf.SET_ARTICA_LOCAL_SECOND_PORT(val:integer);
begin
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
GLOBAL_INI.WriteInteger('ARTICA','SECOND_LOCAL_PORT',val);
GLOBAL_INI.Free;
end;
function MyConf.get_ARTICA_LISTEN_IP():string;
begin
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
result:=GLOBAL_INI.ReadString('ARTICA','LISTEN_IP','0.0.0.0');
GLOBAL_INI.Free;
end;
//##################################################################################
function MyConf.POSTFIX_EXTRAINFOS_PATH(filename:string):string;
begin
if not FileExists('/etc/artica-postfix/postfix-extra.conf') then exit;
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/postfix-extra.conf');
result:=GLOBAL_INI.ReadString('POSTFIX',filename,'');
GLOBAL_INI.Free;
end;
//##################################################################################
function MyConf.get_ARTICA_DAEMON_LOG_MaxSizeLimit():integer;
begin
result:=0;
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
result:=GLOBAL_INI.ReadInteger('ARTICA','DAEMON_LOG_MAX_SIZE',1000);
GLOBAL_INI.Free;
end;
//##################################################################################
function MyConf.set_ARTICA_DAEMON_LOG_MaxSizeLimit(val:integer):integer;
begin
result:=0;
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
 GLOBAL_INI.WriteInteger('ARTICA','DAEMON_LOG_MAX_SIZE',val);
GLOBAL_INI.Free;
end;
//##################################################################################
function MyConf.get_POSTFIX_HASH_FOLDER():string;
begin
result:='';
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
result:=GLOBAL_INI.ReadString('POSTFIX','HASH_FOLDER','/etc/postfix/hash_files');
GLOBAL_INI.Free;
end;
//##################################################################################
function MyConf.set_POSTFIX_HASH_FOLDER(val:string):string;
begin
result:='';
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
 GLOBAL_INI.WriteString('POSTFIX','HASH_FOLDER',val);
GLOBAL_INI.Free;
end;
//##############################################################################
procedure MyConf.CYRUS_SET_V2(val:string);
begin
     GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
     GLOBAL_INI.WriteString('CYRUS','CYRUS_SET_V2',val);
     GLOBAL_INI.Free;
end;
//##############################################################################
function MyConf.CYRUS_GET_V2():string;
begin
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
result:=GLOBAL_INI.ReadString('CYRUS','CYRUS_SET_V2','no');
GLOBAL_INI.Free;
end;
//##############################################################################

function Myconf.KAS_GET_VALUE(key:string):string;
var
   RegExpr,RegExpr2:TRegExpr;
   filter_conf:TstringList;
   i:integer;
begin
  if not fileexists('/usr/local/ap-mailfilter3/etc/filter.conf') then exit;
  filter_conf:=TstringList.Create;
  filter_conf.LoadFromFile('/usr/local/ap-mailfilter3/etc/filter.conf');
  RegExpr:=TRegExpr.Create;
  RegExpr2:=TRegExpr.Create;
  RegExpr2.Expression:='#';
  RegExpr.Expression:=key + '(.+)';
  for i:=0 to filter_conf.Count -1 do begin
        if not RegExpr2.Exec(filter_conf.Strings[i]) then begin
            if  RegExpr.Exec(filter_conf.Strings[i]) then begin
                result:=trim(RegExpr.Match[1]);
                break;
            end;
        end;
  end;
  
  RegExpr.Free;
  RegExpr2.Free;
  filter_conf.Free;

end;
//##############################################################################
procedure Myconf.KAS_DELETE_VALUE(key:string);
var
   RegExpr,RegExpr2:TRegExpr;
   filter_conf:TstringList;
   i:integer;

begin
    if not fileexists('/usr/local/ap-mailfilter3/etc/filter.conf') then exit;
  filter_conf:=TstringList.Create;
  filter_conf.LoadFromFile('/usr/local/ap-mailfilter3/etc/filter.conf');
  RegExpr:=TRegExpr.Create;
  RegExpr2:=TRegExpr.Create;
  RegExpr2.Expression:='#';
  RegExpr.Expression:=key + '(.+)';
 for i:=0 to filter_conf.Count -1 do begin
        if not RegExpr2.Exec(filter_conf.Strings[i]) then begin
            if  RegExpr.Exec(filter_conf.Strings[i]) then begin
                filter_conf.Delete(i);
                filter_conf.SaveToFile('/usr/local/ap-mailfilter3/etc/filter.conf');
                break;
            end;
        end;
  end;
  filter_conf.Free;
  RegExpr2.Free;
  RegExpr.free;

end;


//##############################################################################
procedure Myconf.KAS_WRITE_VALUE(key:string;datas:string);
var
   RegExpr,RegExpr2:TRegExpr;
   filter_conf:TstringList;
   i:integer;
   found:boolean;
begin
  found:=false;
  if not fileexists('/usr/local/ap-mailfilter3/etc/filter.conf') then exit;
  filter_conf:=TstringList.Create;
  filter_conf.LoadFromFile('/usr/local/ap-mailfilter3/etc/filter.conf');
  RegExpr:=TRegExpr.Create;
  RegExpr2:=TRegExpr.Create;
  RegExpr2.Expression:='#';
  RegExpr.Expression:=key + '(.+)';
  for i:=0 to filter_conf.Count -1 do begin
        if not RegExpr2.Exec(filter_conf.Strings[i]) then begin
            if  RegExpr.Exec(filter_conf.Strings[i]) then begin
                filter_conf.Strings[i]:=key + ' ' + datas;
                filter_conf.SaveToFile('/usr/local/ap-mailfilter3/etc/filter.conf');
                found:=True;
                break;
            end;
        end;
  end;
  
  if found=false then begin
          filter_conf.Add(key + ' ' + datas);
          filter_conf.SaveToFile('/usr/local/ap-mailfilter3/etc/filter.conf');
  end;
  

  RegExpr.Free;
  RegExpr2.Free;
  filter_conf.Free;

end;

//##############################################################################
function MyConf.MAILGRAPH_VERSION():string;
var
   RegExpr:TRegExpr;
   cgi_path:string;
   FileDatas:TStringList;
   i:integer;
begin
  cgi_path:=MAILGRAPH_BIN();
  if not FileExists(cgi_path) then exit;
  RegExpr:=TRegExpr.create;
  RegExpr.expression:='my\s+\$VERSION[\s=''"]+([0-9\.]+).+;';
  FileDatas:=TStringList.Create;
  
  FileDatas.LoadFromFile(cgi_path);
  for i:=0 to FileDatas.Count-1 do begin
      if  RegExpr.Exec(filedatas.Strings[i]) then begin
          result:=RegExpr.Match[1];
          RegExpr.Free;
          exit;
      end;
  end;

  RegExpr.Free;
  
end;


//##############################################################################
function MyConf.get_MAILGRAPH_TMP_PATH():string;
var
   RegExpr:TRegExpr;
   cgi_path,filedatas:string;
begin
 cgi_path:=MAILGRAPH_BIN();
 if not FileExists(cgi_path) then exit;
 RegExpr:=TRegExpr.create;
  RegExpr.expression:='my \$tmp_dir[|=| ]+[''|"]([a-zA-Z0-9\/\.]+)[''|"];';
 filedatas:=ReadFileIntoString(cgi_path);
  if  RegExpr.Exec(filedatas) then begin
  result:=RegExpr.Match[1];
  end;
  RegExpr.Free;
end;


//##############################################################################
function MyConf.MAILGRAPH_BIN():string;
var
   php_path:string;
begin

 php_path:=get_ARTICA_PHP_PATH();
 result:=php_path + '/bin/install/rrd/mailgraph1.cgi';

end;
//##############################################################################
function myconf.LDAP_GET_DAEMON_USERNAME():string;
   var get_ldap_user,get_ldap_user_regex:string;
   RegExpr:TRegExpr;
   FileDatas:TStringList;
   i:integer;
begin
       get_ldap_user_regex:=LINUX_LDAP_INFOS('get_ldap_user_regex');
       get_ldap_user:=LINUX_LDAP_INFOS('get_ldap_user');
       
       if length(get_ldap_user)=0 then begin
           writeln('LDAP_GET_USERNAME::unable to give infos from get_ldap_user key in infos.conf');
           exit;
       end;
       
       if length(get_ldap_user_regex)=0 then begin
           writeln('LDAP_GET_USERNAME::unable to give infos from get_ldap_user_regex key in infos.conf');
           exit;
       end;
       
       if not FileExists(get_ldap_user) then begin
          writeln('LDAP_GET_USERNAME::There is a problem to stat ',get_ldap_user);
          exit;
       end;
      FileDatas:=TStringList.Create;
      RegExpr:=TRegExpr.Create;
      RegExpr.Expression:=get_ldap_user_regex;
      FileDatas.LoadFromFile(get_ldap_user);
      for i:=0 to FileDatas.Count-1 do begin
          if RegExpr.Exec(FileDatas.Strings[i]) then begin
             result:=RegExpr.Match[1];
             RegExpr.Free;
             FileDatas.free;
             exit;
          end;
      
      end;
end;
//##############################################################################


//##############################################################################
function myconf.LDAP_GET_CONF_PATH():string;
begin
   if FileExists('/opt/artica/etc/openldap/slapd.conf') then exit('/opt/artica/etc/openldap/slapd.conf');
end;
//##############################################################################
function myconf.LDAP_GET_SCHEMA_PATH():string;
begin
   if FileExists('/opt/artica/etc/openldap/schema') then exit('/opt/artica/etc/openldap/schema');
end;
//##############################################################################
function myconf.LDAP_USE_SUSE_SCHEMA():boolean;
var schema_path:string;
begin
  schema_path:=LDAP_GET_SCHEMA_PATH();
  if not DirectoryExists(schema_path) then exit(false);
  schema_path:=schema_path + '/rfc2307bis.schema';
  if not fileExists(schema_path) then exit(false);
  exit(true);
end;
//##############################################################################
function myconf.LDAP_STOP():string;
var pid:string;
count:integer;
D:boolean;
begin
  result:='';
  d:=COMMANDLINE_PARAMETERS('debug');
  pid:=LDAP_PID();
  count:=0;
  if SYSTEM_PROCESS_EXIST(pid) then begin
     writeln('Stopping openLdap server.....: ' + PID + ' PID');
     if D then writeln('/bin/kill ' + pid);
     fpsystem('/bin/kill ' + pid);
     while SYSTEM_PROCESS_EXIST(pid) do begin
           Inc(count);
           if D then writeln('Stopping openLdap server pid.: ' + PID + '(count)',count);
           sleep(100);
           if count>20 then begin
                  writeln('killing OpenLdap server......: ' + PID + ' PID (timeout)');
                  fpsystem('/bin/kill -9 ' + PID);
                  break;
           end;
     end;
  end;
  
end;
//##############################################################################

function myconf.LDAP_START():string;
var
   pid:string;
   ck:integer;
begin
  result:='';
  ck:=0;
  pid:=LDAP_PID();
  if SYSTEM_PROCESS_EXIST(pid) then begin
     writeln('Starting......: OpenLDAP is already running using PID ' + LDAP_PID() + '...');
     exit();
  end;

 if FileExists('/opt/artica/bin/slapd') then begin
     LDAP_VERIFY_SCHEMA();
     LDAP_SET_DB_CONFIG();
     fpsystem('/opt/artica/bin/slapd -f /opt/artica/etc/openldap/slapd.conf');
     pid:=LDAP_PID();
     while not SYSTEM_PROCESS_EXIST(pid) do begin
           pid:=LDAP_PID();
           sleep(100);
           inc(ck);
           if ck>40 then begin
                writeln('Starting......: OpenLDAP server failed !!!');
                exit;
           end;
     end;
     writeln('Starting......: OpenLDAP server with new pid ' + pid + ' PID...');
 end;

end;
//##############################################################################
procedure MyConf.MYSQL_ARTICA_START();
var
   cmd   :string;
   logs  :Tlogs;
   i     :integer;
   Port  :string;
   pidfile:string;
   bindaddr:string;
   datadir:string;
begin
logs:=Tlogs.Create;
i:=0;
if not FileExists('/opt/artica/libexec/mysqld') then exit;

if SYSTEM_PROCESS_EXIST(MYSQL_ARTICA_PID()) then begin
     writeln('Starting......: Mysql artica is already running using PID ' + MYSQL_ARTICA_PID() + '...');
     exit();
  end;
  
if not DirectoryExists('/var/run/mysqld') then forcedirectories('/var/run/mysqld');
if not DirectoryExists('/opt/artica/logs/mysql') then forcedirectories('/opt/artica/logs/mysql');

     fpsystem('/bin/chown -R mysql:mysql /var/run/mysqld');
     fpsystem('/bin/chmod -R 0755 /var/run/mysqld');
     fpsystem('/bin/chown -R mysql:mysql /opt/artica/share/mysql');
     fpsystem('/bin/chown -R mysql:mysql /opt/artica/logs/mysql');
     fpsystem('/bin/chmod -R 0755 /opt/artica/logs/mysql');
     fpsystem('/bin/chown mysql:mysql /opt/artica/share/mysql-data');
     fpsystem('/bin/chmod 0755 /var/run/mysqld');
     fpsystem('/bin/chown mysql:mysql /var/run/mysqld');

  port    :=MYSQL_SERVER_PARAMETERS_CF('port');
  bindaddr:=MYSQL_SERVER_PARAMETERS_CF('bind-address');
  pidfile :=MYSQL_SERVER_PARAMETERS_CF('pid-file');
  datadir :=MYSQL_SERVER_PARAMETERS_CF('datadir');
cmd:='/opt/artica/libexec/mysqld --basedir=/opt/artica ';
cmd:=cmd + ' --datadir=' + datadir;
cmd:=cmd + ' --user=mysql';
cmd:=cmd + ' --log-error=/opt/artica/logs/mysql/mysql.err';
cmd:=cmd + ' --pid-file=' +pidfile;
cmd:=cmd + ' --port=' + port + ' --bind-address=' + bindaddr + ' &';
  logs.logs('starting artica mysql with ' + cmd);
  fpsystem(cmd);
  while not SYSTEM_PROCESS_EXIST(MYSQL_ARTICA_PID()) do begin
        sleep(100);
           inc(i);
           if i>40 then begin
                writeln('Starting......: Mysql artica failed !!!');
                writeln(cmd);
                exit;
           end;
  end;
  
  writeln('Starting......: Mysql artica PID ' + MYSQL_ARTICA_PID() + ' PID... port 47900');

end;
//############################################################################# #
procedure myconf.MYSQL_ARTICA_STOP();
var pid:string;
count:integer;
D:boolean;
begin
  if not FileExists('/opt/artica/libexec/mysqld') then exit;
  d:=COMMANDLINE_PARAMETERS('debug');
  pid:=MYSQL_ARTICA_PID();
  count:=0;
  if SYSTEM_PROCESS_EXIST(pid) then begin
     writeln('Stopping Mysql artica pid....: ' + MYSQL_ARTICA_PID() + ' PID...');
     if D then writeln('/bin/kill ' + pid);
     fpsystem('/bin/kill ' + pid);
     while SYSTEM_PROCESS_EXIST(MYSQL_ARTICA_PID()) do begin
           Inc(count);
           if D then writeln('Stopping Mysql artica pid....: ' + MYSQL_ARTICA_PID() + ' PID.. (count)',count);
           sleep(100);
           if count>60 then begin
                  writeln('killing Mysql artica.........: ' + MYSQL_ARTICA_PID() + ' PID.. (timeout)');
                  fpsystem('/bin/kill -9 ' + MYSQL_ARTICA_PID());
                  break;
           end;
     end;
  end;

end;
//##############################################################################
function MyConf.MYSQL_ARTICA_PID():string;
begin
result:=SYSTEM_GET_PID(MYSQL_SERVER_PARAMETERS_CF('pid-file'));
exit;
end;
//############################################################################# #
function myConf.LDAP_IS_FILE_IN_SCHEMA(filename_to_search:string):boolean;
var
   RegExpr:TRegExpr;
   FileS:TstringList;
   FilesList:TStringList;
   i:Integer;
   D:boolean;
   FileName:string;
begin
   D:=COMMANDLINE_PARAMETERS('debug');
   if D then writeln('LDAP_IS_FILE_IN_SCHEMA *** ' + filename_to_search + ' ***');
   result:=false;
   FileS:=TstringList.Create;
   FilesList:=TstringList.Create;
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^include\s+(.+)';
   FileS.LoadFromFile(LDAP_GET_CONF_PATH());

   for i:=0 to FileS.Count -1 do begin
     if RegExpr.Exec(FileS.Strings[i]) then begin
           FileName:=ExtractFileName(RegExpr.Match[1]);
          if d then  writeln('LDAP_IS_FILE_IN_SCHEMA -> ' + FileName);
           FilesList.Add(FileName);
     end;
   end;
   
  for i:=0 to FilesList.Count -1 do begin
      if LowerCase(FilesList.Strings[i])=LowerCase(filename_to_search) then begin
         result:=true;
         if d then  writeln('LDAP_IS_FILE_IN_SCHEMA -> ' + filename_to_search + '=true');
         break;
      end;
  end;
 FilesList.Free;
 FileS.Free;
 RegExpr.free;
end;


//##############################################################################
procedure myConf.LDAP_REMOVESCHEMAS();
var
   RegExpr:TRegExpr;
   FileS:TstringList;
   i:Integer;
   D:boolean;
begin
     D:=COMMANDLINE_PARAMETERS('debug');

   FileS:=TstringList.Create;
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^include\s+(.+)';
   FileS.LoadFromFile(LDAP_GET_CONF_PATH());
   if D then writeln('Parsing ' +IntToStr(Files.Count) + ' lines in '  + LDAP_GET_CONF_PATH());
   for i:=0 to FileS.Count-1 do begin
    if D then writeln('Parsing line ('  +IntToStr(i) + ')' + FileS.Strings[i]);
     if RegExpr.Exec(FileS.Strings[i]) then begin
        if D then writeln('Remove line ' + IntToStr(i));
         FileS.Delete(i);
         FileS.SaveToFile(LDAP_GET_CONF_PATH());
         RegExpr.Free;
         FileS.free;
         LDAP_REMOVESCHEMAS();
         break;
     end;
   end;
   if D then writeln('Parsing end...');
   RegExpr.free;
   FileS.free;
   if D then writeln('Parsing exit...');
end;
//##############################################################################
procedure myConf.LDAP_ADDSHEMAS();
 const
            CR = #$0d;
            LF = #$0a;
            CRLF = CR + LF;
var
   FileS:TstringList;
   D:boolean;
   str:string;
begin
   D:=COMMANDLINE_PARAMETERS('debug');
   if D then writeln('LDAP_ADDSHEMAS:: adding includes all schemas');
   if D then writeln('LDAP_ADDSHEMAS:: initilize');
   FileS:=TStringList.Create;
   if D then writeln('LDAP_ADDSHEMAS:: loading');
   FileS.LoadFromFile(LDAP_GET_CONF_PATH());
    if D then writeln('LDAP_ADDSHEMAS:: writing');

   str:=CRLF + 'include         ' + LDAP_GET_SCHEMA_PATH() + '/core.schema' + CRLF;
   str:=str+ 'include         ' + LDAP_GET_SCHEMA_PATH() + '/cosine.schema' +CRLF;
   str:=str+ 'include         ' + LDAP_GET_SCHEMA_PATH() + '/nis.schema' +CRLF;
   str:=str+ 'include         ' + LDAP_GET_SCHEMA_PATH() + '/inetorgperson.schema' +CRLF;
   str:=str+ 'include         ' + LDAP_GET_SCHEMA_PATH() + '/postfix.schema' +CRLF;
   
   if D then writeln('LDAP_ADDSHEMAS:: inserting');

   files.Insert(1,str);

   if D then writeln('LDAP_ADDSHEMAS:: Save to file');
   FileS.SaveToFile(LDAP_GET_CONF_PATH());
   FileS.free;
   if D then writeln('LDAP_ADDSHEMAS:: done...');
end;
//##############################################################################


function myConf.OPENSSL_VERSION():string;
var
   openssl_path,str:string;
   RegExpr:TRegExpr;
   D:Boolean;
begin
  D:=COMMANDLINE_PARAMETERS('debug');
  openssl_path:=OPENSSL_TOOL_PATH();
  if FileExists(openssl_path) then exit('0.0');
  if D then writeln('OPENSSL_VERSION() -> '+ openssl_path);
  str:=trim(ExecPipe(openssl_path + ' version 2>&1'));
  RegExpr:=TRegExpr.Create;
  RegExpr.Expression:='.+?([0-9\.]+)';
  if RegExpr.Exec(str) then result:=RegExpr.Match[1];
  RegExpr.Free;
  exit;
  
  
end;
//##############################################################################
function MyConf.LIB_GSL_VERSION():string;
begin
   IF NOT FILEeXISTS('/usr/local/bin/gsl-config') THEN EXIT('0.0');
   result:=trim(ExecPipe('/usr/local/bin/gsl-config --version 2>&1'));
end;
//##############################################################################





procedure myConf.LDAP_VERIFY_SCHEMA();
var
   FileS:TstringList;
   filedatas:TStringList;
   sf:boolean;
   D:boolean;
begin
   D:=COMMANDLINE_PARAMETERS('debug');
   if not FileExists(LDAP_GET_SCHEMA_PATH() + '/postfix.schema') then begin
    writeln('Starting......: LDAP installing postfix.schema');
    fpsystem('/bin/cp ' + ExtractFilePath(ParamStr(0)) + 'install/postfix.schema ' + LDAP_GET_SCHEMA_PATH() + '/postfix.schema');
    fpsystem( LDAP_GET_INITD() + ' stop');
    fpsystem( LDAP_GET_INITD() + ' start');
   end else begin
        writeln('Starting......: LDAP postfix.schema OK');
   end;
   
 if not FileExists(LDAP_GET_SCHEMA_PATH() + '/inetorgperson.schema') then begin
    writeln('Starting......: LDAP installing inetorgperson.schema');
    fpsystem('/bin/cp ' + ExtractFilePath(ParamStr(0)) + 'install/inetorgperson.schema ' + LDAP_GET_SCHEMA_PATH() + '/inetorgperson.schema');
    fpsystem( LDAP_GET_INITD() + ' stop');
    fpsystem( LDAP_GET_INITD() + ' start');
   end else begin
    writeln('Starting......: LDAP inetorgperson.schema OK');
 end;
 
 if not FileExists(LDAP_GET_SCHEMA_PATH() + '/cosine.schema') then begin
    writeln('Starting......: LDAP installing cosine.schema');
    fpsystem('/bin/cp ' + ExtractFilePath(ParamStr(0)) + 'install/cosine.schema ' + LDAP_GET_SCHEMA_PATH() + '/cosine.schema');
    fpsystem( LDAP_GET_INITD() + ' stop');
    fpsystem( LDAP_GET_INITD() + ' start');
   end else begin
    writeln('Starting......: LDAP cosine.schema OK');
 end;
 
 if not FileExists(LDAP_GET_SCHEMA_PATH() + '/nis.schema') then begin
    writeln('Starting......: LDAP installing nis.schema');
    fpsystem('/bin/cp ' + ExtractFilePath(ParamStr(0)) + 'install/nis.schema ' + LDAP_GET_SCHEMA_PATH() + '/nis.schema');
    fpsystem( LDAP_GET_INITD() + ' stop');
    fpsystem( LDAP_GET_INITD() + ' start');
   end else begin
    writeln('Starting......: LDAP nis.schema OK');
 end;
   
  if D then writeln('Loading ' + LDAP_GET_CONF_PATH());
  FileS:=TStringList.create;
  FileS.LoadFromFile(LDAP_GET_CONF_PATH());
  sf:=false;

  if D then writeln('check cosine.schema in ' + LDAP_GET_CONF_PATH());
  if not LDAP_IS_FILE_IN_SCHEMA('cosine.schema') then sf:=true;
  if D then writeln('check inetorgperson.schema in ' + LDAP_GET_CONF_PATH());
  if not LDAP_IS_FILE_IN_SCHEMA('inetorgperson.schema') then sf:=true;
  if D then writeln('check postfix.schema in ' + LDAP_GET_CONF_PATH());
  if not LDAP_IS_FILE_IN_SCHEMA('postfix.schema') then sf:=true;
  if D then writeln('check nis.schema in ' + LDAP_GET_CONF_PATH());
  if not LDAP_IS_FILE_IN_SCHEMA('nis.schema') then sf:=true;

   if sf then begin
    if D then writeln('Remove all schemas');
    LDAP_REMOVESCHEMAS();
    LDAP_ADDSHEMAS();

   end;
   

if DirectoryExists('/usr/local/var/openldap-data') then begin
      if not FileExists('/usr/local/var/openldap-data/DB_CONFIG') then begin
         filedatas:=TstringList.Create;
         filedatas.Add('set_cachesize 0 268435456 1');
         filedatas.Add('set_lg_regionmax 262144');
         filedatas.Add('set_lg_bsize 2097152');
         filedatas.SaveToFile('/usr/local/var/openldap-data/DB_CONFIG');
         filedatas.free;
         LDAP_STOP();
         LDAP_START();
      end;
   end;
   
   if DirectoryExists('/var/lib/ldap') then begin
      if not FileExists('/var/lib/ldap/DB_CONFIG') then begin
         filedatas:=TstringList.Create;
         filedatas.Add('set_cachesize 0 268435456 1');
         filedatas.Add('set_lg_regionmax 262144');
         filedatas.Add('set_lg_bsize 2097152');
         filedatas.SaveToFile('/var/lib/ldap/DB_CONFIG');
         filedatas.free;
         LDAP_STOP();
         LDAP_START();
      end;
   end;
   if FileExists(ExtractFilePath(ParamStr(0)) + 'artica-ldap') then fpsystem(ExtractFilePath(ParamStr(0)) + 'artica-ldap');
   
end;
//##############################################################################


function myconf.LDAP_GET_INITD():string;
begin
   if FileExists('/opt/artica/bin/slapd') then begin
        result:=ExtractFilePath(ParamStr(0));
        result:=result + 'artica-install slapd';
        exit();
   end;
   
   if FileExists('/etc/init.d/ldap') then result:='/etc/init.d/ldap';
   if FileExists('/etc/init.d/slapd') then result:='/etc/init.d/slapd';
end;
//##############################################################################
function MyConf.SASLAUTHD_PATH_GET():string;
begin

    if FileExists('/etc/default/saslauthd') then result:='/etc/default/saslauthd';
    if FileExists('/etc/sysconfig/saslauthd') then  result:='/etc/sysconfig/saslauthd';
    if Debug then ShowScreen('SASLAUTHD_PATH_GET -> "' + result + '"');
end;
//##############################################################################
function MyConf.SASLAUTHD_VALUE_GET(key:string):string;
var Msaslauthd_path,mdatas:string;
   RegExpr:TRegExpr;
begin
Msaslauthd_path:=SASLAUTHD_PATH_GET();
    if length(Msaslauthd_path)=0 then begin
        if Debug then writeln('SASLAUTHD_VALUE_GET -> NULL!!!');
        exit;
    end;
    
     RegExpr:=TRegExpr.Create;
     RegExpr.Expression:=key + '=[\s"]+([a-z\/]+)(?)';
     if Debug then writeln('SASLAUTHD_VALUE_GET -> Read ' + Msaslauthd_path);
     mdatas:=ReadFileIntoString(Msaslauthd_path);

     if RegExpr.Exec(mdatas) then begin
        result:=RegExpr.Match[1];
        if Debug then writeln('SASLAUTHD_VALUE_GET -> regex ' + result);
     end;
     RegExpr.Free;
end;
//##############################################################################
function myconf.SASLAUTHD_TEST_INITD():boolean;
var List:TStringList;
   RegExpr:TRegExpr;
   i:integer;
begin
   ShowScreen('SASLAUTHD_TEST_INITD:: Prevent false mechanism in init.d for saslauthd');
   if not fileExists('/etc/init.d/saslauthd') then begin
      showScreen('SASLAUTHD_TEST_INITD:: Error stat etc/init.d/saslauthd');
   end;
     List:=TStringList.Create;
     List.LoadFromFile('/etc/init.d/saslauthd');
     RegExpr:=TRegExpr.Create;
     RegExpr.Expression:='SASLAUTHD_AUTHMECH=([a-z]+)';
     for i:=0 to List.Count-1 do begin
          if RegExpr.Exec(list.Strings[i]) then begin
             showScreen('SASLAUTHD_TEST_INITD:: Read: "' + RegExpr.Match[1]+'"');
             if  RegExpr.Match[1]<>'ldap' then begin
                  showScreen('SASLAUTHD_TEST_INITD:: change to "ldap" mode');
                  list.Strings[i]:='SASLAUTHD_AUTHMECH=ldap';
                  list.SaveToFile('/etc/init.d/saslauthd');
                  showScreen('SASLAUTHD_TEST_INITD:: done..');
                  fpsystem('/etc/init.d/saslauthd restart');
                  list.Free;
                  RegExpr.free;
                  exit(true);
             end;
          end;
     
     end;
 showScreen('SASLAUTHD_TEST_INITD:: nothing to change...');
 list.Free;
 RegExpr.free;
 exit(true);
end;
//##############################################################################
function MyConf.BOA_SET_CONFIG();
var
   List:TstringList;
   LocalPort:integer;
   BoaLOGS:Tlogs;
begin
result:=true;
LocalPort:=get_ARTICA_LOCAL_PORT();
BoaLOGS:=Tlogs.Create;
forcedirectories('/opt/artica/share/www');
forcedirectories('/opt/artica/share/www/squid/rrd');
List:=TstringList.Create;
BoaLOGS.logs('Writing httpd.conf for artica-postfix listener on ' + IntToStr(LocalPort) + ' port');
writeln('Starting......: Boa will listen on '+ IntToStr(LocalPort) + ' port');


List.Add('Port ' + IntToStr(LocalPort));
List.Add('Listen 127.0.0.1');
List.Add('User root');
List.Add('Group root');
List.Add('PidFile /etc/artica-postfix/boa.pid');
List.Add('ErrorLog /var/log/artica-postfix/boa_error.log');
List.Add('AccessLog /var/log/artica-postfix/boa_access_log');
List.Add('CGILog /var/log/artica-postfix/boa_cgi_log');
List.Add('DocumentRoot /opt/artica/share/www');
List.Add('DirectoryIndex index.html');
List.Add('#DirectoryMaker /usr/lib/boa/boa_indexer');
List.Add('KeepAliveMax 1000');
List.Add('KeepAliveTimeout 5');
List.Add('#MimeTypes /etc/mime.types');
List.Add('DefaultType text/plain');
List.Add('CGIPath /bin:/usr/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/sbin:/sbin:/bin:/usr/X11R6/bin');
List.Add('AddType application/x-executable cgi');
List.Add('ScriptAlias /cgi/ ' + get_ARTICA_PHP_PATH() + '/bin/');
List.Add('Alias /queue ' + ARTICA_FILTER_QUEUEPATH());
list.SaveToFile('/etc/artica-postfix/httpd.conf');
list.Free;
BoaLOGS.free;
end;
//##############################################################################
procedure MyConf.LDAP_VERIFY_PASSWORD();
var admin,password,artica_admin,artica_password,suffix,artica_suffix:string;
    change:boolean;
    tfile:Tstringlist;
    i:integer;


begin
    admin:=LDAP_READ_ADMIN_NAME();
    password:=LDAP_READ_VALUE_KEY('rootpw');
    suffix:=LDAP_READ_VALUE_KEY('suffix');
    change:=false;


    artica_admin:=get_LDAP('admin');
    artica_password:=get_LDAP('password');
    artica_suffix:=get_LDAP('suffix');
    
    writeln('Starting......: LDAP ' + artica_admin + ':' + artica_password + '//' + artica_suffix);
    
    
    if admin<>artica_admin then begin
       writeln('Starting......: LDAP Change admin to ' + admin);
       set_LDAP('admin',admin);
       change:=true;
    end;
    
    
    if password<>artica_password then begin
        writeln('Starting......: LDAP Change password to ' + password);
       set_LDAP('password',password);
       change:=true;
    end;
    
    if suffix<>artica_suffix then begin
       writeln('Starting......: LDAP Change suffix to ' + suffix);
       set_LDAP('suffix',suffix);
       change:=true;
    end;
    
    LDAP_WRITE_VALUE_KEY('password-hash','{CLEARTEXT}');
    
    tfile:=TStringList.Create;
    tfile.Add('dn: dc=my-domain,dc=com');
    tfile.Add('objectClass: top');
    tfile.Add('objectClass: organization');
    tfile.Add('objectClass: dcObject');
    tfile.Add('o: my-domain');
    tfile.Add('dc: my-domain');
    tfile.SaveToFile('/opt/artica/logs/_init.ldif');
    tfile.Free;
    

    fpsystem('/opt/artica/sbin/slapadd  -l /opt/artica/logs/_init.ldif >/opt/artica/logs/_init.ldif.resp 2>&1');
    
    

    tfile:=TStringList.Create;
    if FileExists('/opt/artica/logs/_init.ldif.resp') then begin
       tfile.LoadFromFile('/opt/artica/logs/_init.ldif.resp');
       for i:=0 to tfile.Count-1 do begin
             if pos('DB_KEYEXIST',tfile.Strings[i])=0 then begin
                writeln('Starting......: LDAP '+ tfile.Strings[i]);
             end;
       end;
    end;
     writeln('Starting......: LDAP tests suffix ' + suffix + ' ok');
     
     If FileExists(ExtractFilePath(ParamStr(0)) + 'install/postfix.schema') then begin
           if MD5FromFile(ExtractFilePath(ParamStr(0)) + 'install/postfix.schema') <>MD5FromFile('/opt/artica/etc/openldap/schema/postfix.schema') then begin
               fpsystem('/bin/cp ' + ExtractFilePath(ParamStr(0)) + 'install/postfix.schema /opt/artica/etc/openldap/schema/postfix.schema');
               writeln('Starting......: LDAP Updating postfix.schema');
           end;

     end;
     
    
     if fileexists('/usr/bin/newaliases') then begin
        fpsystem('/usr/bin/newaliases >/dev/null 2>&1');
        writeln('Starting......: newaliases OK');
     end;
        
        
     if FileExists('/opt/artica/cyrus/bin/reconstruct') then begin
        fpsystem('/opt/artica/cyrus/bin/reconstruct >/dev/null 2>&1');
        writeln('Starting......: reconstruct cyrus database ok');
     end;
     
    
    
     if FileExists('/opt/artica/db/lib/libdb-4.6.so') then begin
        if Not FileExists('/usr/local/lib/libdb-4.6.so') then begin
           fpsystem('/bin/ln -s /opt/artica/db/lib/libdb-4.6.so /usr/local/lib/libdb-4.6.so');
           writeln('Starting......: Linking /opt/artica/db/lib/libdb-4.6.so -> /usr/local/lib/libdb-4.6.so');
        end;
     end;
     
     if FileExists('/opt/artica/db/lib/libdb-4.6.so') then begin
        if Not FileExists('/lib/libdb-4.6.so') then begin
           fpsystem('/bin/ln -s /opt/artica/db/lib/libdb-4.6.so /lib/libdb-4.6.so');
           writeln('Starting......: Linking /opt/artica/db/lib/libdb-4.6.so -> /lib/libdb-4.6.so');
        end;
           
     end;
     
     if FileExists('/opt/artica/lib/libiconv.so.2.4.0') then begin
        if Not FileExists('/lib/libiconv.so.2') then begin
           fpsystem('/bin/ln -s --force /opt/artica/lib/libiconv.so.2.4.0 /lib/libiconv.so.2');
           writeln('Starting......: Linking /opt/artica/lib/libiconv.so.2.4.0 -> /lib/libiconv.so.2');
        end;

     end;
      PURE_FTPD_PREPARE_LDAP_CONFIG();
    
    
    if change=true then begin
       writeln('Starting......: ldap password as changed fix settings...');
       POSTFIX_CONFIGURE_MAIN_CF();
       CYRUS_IMAPD_CONFIGURE();
       SASLAUTHD_CONFIGURE();
       
       POSTFIX_STOP();
       CYRUS_DAEMON_STOP();
       SASLAUTHD_STOP();
       
       POSTFIX_RESTART_DAEMON();
       CYRUS_DAEMON_START();
       SASLAUTHD_START();
       
    end;
    

end;
//##############################################################################
procedure MyConf.WATCHDOG_PURGE_BIGHTML();
var
   queue_path:string;
   SYS       :Tsystem;
   Dirs      :TstringList;
   FileList  :TstringList;
   D         :boolean;
   i         :integer;
   mIni      :TiniFile;
   dayMax    :Integer;
begin

   D:=COMMANDLINE_PARAMETERS('debug');
   queue_path:=ARTICA_FILTER_QUEUEPATH() + '/bightml';
   SYS:=Tsystem.Create();
   Dirs:=TstringList.Create;
   Dirs.AddStrings(SYS.DirDirRecursive(queue_path));
   if D then writeln('WATCHDOG_PURGE_BIGHTML: ' + IntToStr(Dirs.Count) + ' folders');
   if Dirs.Count=0 then exit;
   FileList:=TStringlist.Create;
   for i:=0 to Dirs.Count-1 do begin
         if D then writeln('WATCHDOG_PURGE_BIGHTML: find conf files in ' + Dirs.Strings[i]+ ' dir');
         FileList.AddStrings(SYS.SearchFilesInPath(Dirs.Strings[i],'*.conf'));
   
   end;
   if D then writeln('WATCHDOG_PURGE_BIGHTML: ' + IntToStr(FileList.Count) + ' files');
   if FileList.Count=0 then exit;
   
    for i:=0 to FileList.Count-1 do begin
         if D then writeln('WATCHDOG_PURGE_BIGHTML: ' + FileList.Strings[i]);
         mIni:=TiniFile.Create(FileList.Strings[i]);
         
         dayMax:=mIni.ReadInteger('GENERAL','maxday',2);
         if SYSTEM_FILE_DAYS_BETWEEN_NOW(FileList.Strings[i])>dayMax then begin
            logs.logs('WATCHDOG_PURGE_BIGHTML:: Delete ' + ExtractFilePath(FileList.Strings[i]));
            fpsystem('/bin/rm -rf ' + ExtractFilePath(FileList.Strings[i]));
         end;
         
    end;
end;
//##############################################################################
function MyConf.SYSTEM_START_ARTICA_DAEMON():boolean;
var
   Rootpath,ArticaPath,PolicyFilterPath:string;
   D:boolean;
   artica_pid,ldap_pidn,postfix_pidn,crond_pid,artica_policy_pid,mailman_pid:string;
   knel:integer;
   kernel_version:string;
   
begin
     kernel_version:=trim(SYSTEM_KERNEL_VERSION());
     kernel_version:=Copy(kernel_version,0,3);
     result:=true;
     knel:=StrToInt(AnsiReplaceStr(kernel_version,'.',''));
     if knel<26 then begin
        writeln('Your kernel version '+ kernel_version + ' is not supported');
        writeln('You need to upgrade your system to the newest version (>=2.6)');
        writeln('aborting...');
        halt(0);
     end;

     if FileExists('/opt/artica/license.expired.conf') then DeleteFile('/opt/artica/license.expired.conf');
     writeln('Starting......: Kernel version ' + kernel_version);

     D:=COMMANDLINE_PARAMETERS('debug');
     Rootpath:=get_ARTICA_PHP_PATH();
     articaPath:=Rootpath + '/bin/artica-postfix';

     PolicyFilterPath:=Rootpath+ '/bin/artica-policy';
     
     if not DirectoryExists('/opt/artica/share/perl5') then begin
        writeln('Starting......: Linking /opt/artica/lib/perl/5.8.8 -> /opt/artica/share/perl5');
        fpsystem('/bin/ln -s /opt/artica/lib/perl/5.8.8 /opt/artica/share/perl5');
     end;
     
     
     ForceDirectories('/opt/artica/etc/lire/converters');
     
     if not FileExists('/lib/libsqlite3.so.0') then begin
        if FileExists('/opt/artica/lib/libsqlite3.so.0') then begin
            writeln('Starting......: Linking /opt/artica/lib/libsqlite3.so.0 -> /lib/libsqlite3.so.0');
            fpsystem('/bin/ln -s /opt/artica/lib/libsqlite3.so.0 /lib/libsqlite3.so.0');
        end;
     end;
     
     if not FileExists('/lib/libldap-2.4.so.2') then begin
     if FileExists('/opt/artica/lib/libldap-2.4.so.2') then begin
          writeln('Starting......: Linking /opt/artica/lib/libldap-2.4.so.2 -> /lib/libldap-2.4.so.2');
          fpsystem('/bin/ln -s /opt/artica/lib/libldap-2.4.so.2 /lib/libldap-2.4.so.2');
     END;
     END;
     
if not FileExists('/lib/liblber-2.4.so.2') then begin
     if FileExists('/opt/artica/lib/liblber-2.4.so.2') then begin
          writeln('Starting......: Linking /opt/artica/lib/liblber-2.4.so.2 -> /lib/liblber-2.4.so.2');
          fpsystem('/bin/ln -s /opt/artica/lib/liblber-2.4.so.2 /lib/liblber-2.4.so.2');
     END;
     END;
     


     if not FileExists('/etc/aliases') then begin
        if FileExists('/usr/bin/newaliases') then begin
            writeln('Starting......: create /etc/aliases file...');
            fpsystem('/bin/touch /etc/aliases');
            fpsystem('/usr/bin/newaliases');
        end;
     end;


     LDAP_VERIFY_PASSWORD();

     if D then showscreen('SYSTEM_START_ARTICA_DAEMON:: Rootpath='+ Rootpath);
     artica_policy_pid:=ARTICA_POLICY_GET_PID();
     if D then showscreen('SYSTEM_START_ARTICA_DAEMON:: get artica-postfix pid');
     artica_pid:=ARTICA_DAEMON_GET_PID();
     
     if D then showscreen('SYSTEM_START_ARTICA_DAEMON:: get ldap pid');
     ldap_pidn:=LDAP_PID();
     if D then showscreen('SYSTEM_START_ARTICA_DAEMON:: get postfix pid');
     postfix_pidn:=POSTFIX_PID();
     if D then showscreen('SYSTEM_START_ARTICA_DAEMON:: get cron pid');
     crond_pid:=CRON_PID();
     if D then showscreen('SYSTEM_START_ARTICA_DAEMON:: get email Relay pid');

     mailman_pid:=MAILMAN_GET_PID();

     SYSTEM_VERIFY_CRON_TASKS();
     fpsystem('/bin/chmod -R 777 /etc/cron.d/');

     if FileExists('/etc/artica-postfix/shutdown') then begin
        if D then showscreen('SYSTEM_START_ARTICA_DAEMON:: remove /etc/artica-postfix/shutdown');
        fpsystem('/bin/rm /etc/artica-postfix/shutdown');
     end;
     
     if not SYSTEM_PROCESS_EXIST(crond_pid) then begin
        writeln('Starting......: Cron daemon...');
        if D then showscreen('SYSTEM_START_ARTICA_DAEMON:: Start cron service server "' + CROND_INIT_PATH()+'"');
        MonShell(CROND_INIT_PATH() + ' start',true);
      end else begin
        writeln('Starting......: crond daemon is already running using PID ' + crond_pid + '...');
     end;


     

     if not SYSTEM_PROCESS_EXIST(ldap_pidn) then begin
        if D then showscreen('SYSTEM_START_ARTICA_DAEMON:: Start LDAP service server "' + LDAP_GET_INITD() + '"');
        LDAP_START();
        fpsystem(get_ARTICA_PHP_PATH() + '/bin/artica-ldap');
      end else begin
        writeln('Starting......: LDAP daemon is already running using PID ' + ldap_pidn + '...');
        fpsystem(get_ARTICA_PHP_PATH() + '/bin/artica-ldap');
     end;
     
     SASLAUTHD_START();
     CYRUS_DAEMON_START();
     MYSQL_ARTICA_START();
     if FileExists(POSFTIX_POSTCONF_PATH()) then begin
     if not SYSTEM_PROCESS_EXIST(postfix_pidn) then begin
        if D then showscreen('SYSTEM_START_ARTICA_DAEMON:: Start POSTFIX service server ');
        fpsystem('/etc/init.d/postfix start');
      end else begin
        writeln('Starting......: Postfix daemon is already running using PID ' + postfix_pidn + '...');
     end;
     end;
     MAILGRAPH_START();
     RRD_MAILGRAPH_INSTALL();
     
     if FileExists('/opt/artica/mailman/mail/mailman') then begin
        if not SYSTEM_PROCESS_EXIST(mailman_pid) then begin

           if D then showscreen('SYSTEM_START_ARTICA_DAEMON:: Start mailman service server ');
           fpsystem('/opt/artica/mailman/bin/mailmanctl start >/dev/null 2>&1');
           writeln('Starting......: mailman daemon pid ' + MAILMAN_GET_PID());
           fpsystem(ExtractFilePath(ParamStr(0)) + 'artica-mailman -css-patch');
           end else begin
               writeln('Starting......: mailman daemon is already running using PID ' + mailman_pid + '...');
           end;
     end;
     

     
     APACHE_ARTICA_START();
     ARTICA_FILTER_CHECK_PERMISSIONS();
     if D then showscreen('SYSTEM_START_ARTICA_DAEMON:: ->FETCHMAIL_START_DAEMON() function  ');
     FETCHMAIL_START_DAEMON();
     if D then showscreen('SYSTEM_START_ARTICA_DAEMON:: ->HOTWAYD_START() function  ');
     HOTWAYD_START();
     if D then showscreen('SYSTEM_START_ARTICA_DAEMON:: ->DNSMASQ_START_DAEMON() function  ');
     DNSMASQ_START_DAEMON();
     if D then showscreen('SYSTEM_START_ARTICA_DAEMON:: ->SQUID_START() function  ');
     SQUID_START();
     DANSGUARDIAN_START();
     if D then showscreen('SYSTEM_START_ARTICA_DAEMON:: ->KAV6_START() function  ');
     KAV6_START();
     if D then showscreen('SYSTEM_START_ARTICA_DAEMON:: ->KAV4PROXY_START() function  ');
     KAV4PROXY_START();
     if D then showscreen(get_ARTICA_PHP_PATH() + '/bin/artica-ldap -inadyn');
     fpsystem(get_ARTICA_PHP_PATH() + '/bin/artica-ldap -inadyn');
     if D then showscreen(get_ARTICA_PHP_PATH() + '/bin/artica-dbf -install');
     fpsystem(get_ARTICA_PHP_PATH() + '/bin/artica-dbf -install');

     if FileExists(POSFTIX_POSTCONF_PATH()) then begin
        RRD_MAILGRAPH_INSTALL();
        if not SYSTEM_PROCESS_EXIST(artica_policy_pid) then begin
           MonShell(PolicyFilterPath,false);
           writeln('Starting......: artica-policy daemon pid '+ARTICA_POLICY_GET_PID());
           end else begin
               writeln('Starting......: artica-policy daemon is already running using PID ' + artica_policy_pid + '...');
           end;
     end;
     
     PURE_FTPD_START();
     
     
     if not SYSTEM_PROCESS_EXIST(artica_pid) then begin
        writeln('Starting......: artica-postfix daemon...');
        if D then showscreen('SYSTEM_START_ARTICA_DAEMON:: Start artica service server "' + articaPath + '"');
        MonShell(articaPath,false);
      end else begin
        writeln('Starting......: artica-postfix daemon is already running using PID ' + artica_pid + '...');
     end;
     
     BOA_START();

end;



//##############################################################################
function myconf.CYRUS_enabled_in_master_cf():boolean;
var
   RegExpr:TRegExpr;
   list:TstringList;
   i:Integer;
begin
   result:=false;
   if not FileExists('/etc/postfix/master.cf') then exit;
   list:=TStringList.Create;
   list.LoadFromFile('/etc/postfix/master.cf');
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='flags= user=cyrus argv=(.+)';
   for i:=0 to list.Count-1 do begin
        if RegExpr.Exec(list.Strings[i]) then begin
            result:=true;
            break;
        end;
   end;
   RegExpr.free;
   list.free;
end;
//##############################################################################


procedure myconf.BOA_STOP();
var count:integer;
 begin
 count:=0;
 if SYSTEM_PROCESS_EXIST(BOA_DAEMON_GET_PID()) then begin
        writeln('Stopping BOA.................: ' + BOA_DAEMON_GET_PID() + ' PID..');
        fpsystem('/bin/kill '+BOA_DAEMON_GET_PID());

        while SYSTEM_PROCESS_EXIST(BOA_DAEMON_GET_PID()) do begin
              sleep(100);
              inc(count);
              if count>20 then begin
                 fpsystem('/bin/kill -9 ' + BOA_DAEMON_GET_PID());
                 break;
              end;
        end;
        if SYSTEM_PROCESS_EXIST(BOA_DAEMON_GET_PID()) then begin
           writeln('Stopping BOA.................: Failed to stop PID ' + BOA_DAEMON_GET_PID());
        end;
  end else begin
     writeln('Stopping BOA.................: Already stopped');
  end;
end;
//##############################################################################
procedure myconf.APACHE_ARTICA_STOP();
 var
    count      :integer;
    D          :boolean;
begin
      if not FileExists(APACHE_GET_INITD_PATH()) then begin
         writeln('Stopping Apache artica.......: Not installed, are you sure that artica is really installed ???');
         exit;
     end;
     count:=0;
     D:=COMMANDLINE_PARAMETERS('debug');
     
     if SYSTEM_PROCESS_EXIST(APACHE_PID()) then begin
        writeln('Stopping Apache artica.......: ' + APACHE_PID() + ' PID..');
        if D then showscreen('SYSTEM_START_ARTICA_DAEMON:: stop apache service server "' + APACHE_GET_INITD_PATH() + '"');
        fpsystem(APACHE_GET_INITD_PATH() + ' stop');
        while SYSTEM_PROCESS_EXIST(APACHE_PID()) do begin
              sleep(100);
              inc(count);
              if count>100 then begin
                 writeln('Stopping Apache artica.......: Failed');
                 exit;
              end;
        end;
        
      end else begin
        writeln('Stopping Apache artica.......: Already stopped');
     end;

end;
//##############################################################################
procedure myconf.APACHE_ARTICA_START();
 var
    count      :integer;
    D          :boolean;
begin

     count:=0;
     D:=COMMANDLINE_PARAMETERS('debug');

     if not FileExists(APACHE_GET_INITD_PATH()) then begin
         writeln('Starting......: Apache daemon... Not installed, are you sure that artica is really installed ???');
         exit;
     end;

     if not SYSTEM_PROCESS_EXIST(APACHE_PID()) then begin

        if D then showscreen('SYSTEM_START_ARTICA_DAEMON:: Start apache service server "' + APACHE_GET_INITD_PATH() + '"');
        fpsystem(APACHE_GET_INITD_PATH() + ' start');
        while not SYSTEM_PROCESS_EXIST(APACHE_PID()) do begin
              sleep(100);
              inc(count);
              if count>200 then begin
                 writeln('Starting......: Apache daemon... (failed!!!)');
                 exit;
              end;
        end;

      end else begin
        writeln('Starting......: Apache daemon is already running using PID ' + APACHE_PID() + '...');
        exit;
     end;
     
     writeln('Starting......: Apache daemon with new PID ' + APACHE_PID() + '...');
     

end;
//##############################################################################
procedure myconf.PURE_FTPD_START();
 var
    count      :integer;
    D          :boolean;
begin

     count:=0;

     D:=COMMANDLINE_PARAMETERS('debug');

     if not FileExists('/opt/artica/sbin/pure-config.pl') then begin
         if D then writeln('Starting......: pure-ftpd unable to stat /opt/artica/sbin/pure-config.pl');
         exit;
     end;

     if not SYSTEM_PROCESS_EXIST(PURE_FTPD_PID()) then begin

        fpsystem('/opt/artica/sbin/pure-config.pl /opt/artica/etc/pure-ftpd.conf >/dev/null 2>&1');
        while not SYSTEM_PROCESS_EXIST(PURE_FTPD_PID()) do begin
              sleep(100);
              inc(count);
              if count>200 then begin
                 writeln('Starting......: pure-ftpd... (failed!!!)');
                 exit;
              end;
        end;

      end else begin
        writeln('Starting......: pure-ftpd daemon is already running using PID ' + PURE_FTPD_PID() + '...');
        exit;
     end;

     writeln('Starting......: pure-ftpd daemon with new PID ' + PURE_FTPD_PID() + '...');
end;
//##############################################################################



procedure myconf.BOA_START();
var
   D:boolean;
   BoaPath:string;
   Rootpath:string;
begin

D:=COMMANDLINE_PARAMETERS('debug');
Rootpath:=get_ARTICA_PHP_PATH();
BoaPath:=Rootpath + '/bin/boa -c /etc/artica-postfix -f /etc/artica-postfix/httpd.conf -l 4';

if not SYSTEM_PROCESS_EXIST(BOA_DAEMON_GET_PID()) then begin
        BOA_SET_CONFIG();
        writeln('Starting......: BOA daemon...');
        if D then showscreen('SYSTEM_START_ARTICA_DAEMON:: Start boa http server "' + BoaPath + '"');
        fpsystem(BoaPath +' >/dev/null 2>&1');
   end else begin
        writeln('Starting......: BOA daemon is already running using PID ' + BOA_DAEMON_GET_PID()+ '...');
     end;
     
if not SYSTEM_PROCESS_EXIST(BOA_DAEMON_GET_PID()) then begin
   writeln('Starting......: BOA failed to start');
end;

end;
//##############################################################################

procedure Myconf.MAILGRAPH_START();
var
   pid   :string;
   path  :string;
   cmd   :string;
   count :integer;
begin
count:=0;
if not FileExists(POSFTIX_POSTCONF_PATH()) then exit;
forcedirectories('/opt/artica/logs');
forcedirectories('/opt/artica/var/rrd/mailgraph');

path:=get_ARTICA_PHP_PATH() + '/bin/install/rrd/mailgraph.pl';
if not FileExists(path) then begin
    writeln('Starting......: Mailgraph statistics generator doesn''t exists (' + path + ')...');
    exit;
end;

pid:=MAILGRAPH_PID();
if not SYSTEM_PROCESS_EXIST(pid) then begin
   MAILGRAPH_RECONFIGURE();
   fpsystem('/bin/chmod 755 ' + path);
   if not FileExists('/opt/artica/logs/mailgraph.log') then fpsystem('/bin/touch /opt/artica/logs/mailgraph.log');
   cmd:=path + ' --daemon-log=/opt/artica/logs/mailgraph.log -d --daemon-pid=/var/run/mailgraph.pid --daemon-rrd=/opt/artica/var/rrd/mailgraph -v';

  fpsystem(cmd);
  while not SYSTEM_PROCESS_EXIST(MAILGRAPH_PID()) do begin
        sleep(100);
        inc(count);
        if count>20 then break;
  end;


  pid:=MAILGRAPH_PID();
  if SYSTEM_PROCESS_EXIST(pid) then begin
     writeln('Starting......: Mailgraph statistics generator pid ' + pid);
  end else begin
      writeln('Starting......: Mailgraph statistics generator failed');
  end;

end else begin
    writeln('Starting......: Mailgraph statistics generator is already running using PID ' + pid);
end;
end;
//##############################################################################
procedure myConf.MAILGRAPH_STOP();
var
   pid   :string;
   count :integer;
begin
  count:=0;
  if not FileExists(POSFTIX_POSTCONF_PATH()) then exit;
  pid:=MAILGRAPH_PID();
  if not SYSTEM_PROCESS_EXIST(pid) then begin
      writeln('Stopping mailgraph...........: Already stopped');
      exit;
  end;
  

  writeln('Stopping mailgraph...........: ' + pid + ' PID');
  fpsystem('/bin/kill ' + pid);
   while SYSTEM_PROCESS_EXIST(MAILGRAPH_PID()) do begin
     sleep(100);
        inc(count);
        if count>20 then begin
           fpsystem('/bin/kill -9 ' + pid);
           break;
        end;
  end;
  if SYSTEM_PROCESS_EXIST(MAILGRAPH_PID()) then begin
        writeln('Stopping mailgraph...........: Failed to stop PID ' + MAILGRAPH_PID());
  end;
  
end;
//##############################################################################
procedure MyConf.MAILGRAPH_RECONFIGURE();
var
   RegExpr:TRegExpr;
   list:TstringList;
   i:Integer;

   mailgraph_pl,mailgraph_rrd,mailgraph_cgi,images_path,rrd_path,mailgraph_virus:string;
begin
   list:=TstringList.Create;
   rrd_path:='/opt/artica/var/rrd/mailgraph/mailgraph.rrd';
   mailgraph_rrd:=rrd_path;
   mailgraph_virus:='/opt/artica/var/rrd/mailgraph/mailgraph_virus.rrd';
   mailgraph_pl:=get_ARTICA_PHP_PATH() + '/bin/install/rrd/mailgraph.pl';
   mailgraph_cgi:=MAILGRAPH_BIN();
   images_path:='/opt/artica/share/www/mailgraph';
   
if not FileExists('/etc/cron.d/artica.cron.mailgraph') then begin
writeln('Starting......: Mailgraph statistics, Create anacron images generator..');
list.Add('1,3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33,35,37,39,41,43,45,47,49,51,53,55,57,59 * * * *    root    ' + get_ARTICA_PHP_PATH() + '/bin/install/rrd/mailgraph1.cgi');
list.SaveToFile('/etc/cron.d/artica.cron.mailgraph');
end;

forcedirectories('/opt/artica/var/rrd/mailgraph');
forcedirectories(images_path);

    if not fileexists(mailgraph_cgi) then begin
       writeln('Starting......: Mailgraph statistics, error unable to stat '+ mailgraph_cgi);
       exit;
    end;
    
   list.LoadFromFile(mailgraph_cgi);
   RegExpr:=TRegExpr.create;

   if list.Count<10 then exit;
   For i:=0 to  list.Count-1 do begin

       RegExpr.expression:='my\s+\$rrd_virus';
       if  RegExpr.Exec(list.Strings[i]) then begin
           writeln('Starting......: Mailgraph statistics, change [$rrd_virus] in '+ExtractFileName(mailgraph_cgi));
           list[i]:='my $rrd_virus = ''' + mailgraph_virus+''';';
       end;

      RegExpr.expression:='my\s+\$tmp_dir';
      if  RegExpr.Exec(list.Strings[i]) then begin
          writeln('Starting......: Mailgraph statistics, change [$tmp_dir] images path in ' +ExtractFileName(mailgraph_cgi));
          list[i]:='my $tmp_dir = ''' + images_path+''';';
      end;
      
       RegExpr.Expression:='my\s+\$rrd[\s=]';
        if  RegExpr.Exec(list.Strings[i]) then begin
          list[i]:='my $rrd ="' + mailgraph_rrd+'";';
          writeln('Starting......: Mailgraph statistics, change [my $rrd] in ' +  ExtractFileName(mailgraph_cgi));
        end;


   end;

   list.SaveToFile(mailgraph_cgi);
   fpsystem('/bin/chmod 755 ' + mailgraph_cgi);




    if not fileexists(mailgraph_pl) then begin
       writeln('Starting......: Mailgraph statistics, error unable to stat ' + ExtractFileName(mailgraph_pl));
       exit;
    end;

    list.LoadFromFile(mailgraph_pl);

    For i:=0 to  list.Count-1 do begin
        RegExpr.Expression:='my\s+\$rrd\s+=["\s]+.+";';
        if  RegExpr.Exec(list.Strings[i]) then begin
          list[i]:='my $rrd ="' + mailgraph_rrd+'";';
          writeln('Starting......: Mailgraph statistics, change [my $rrd] in ' +  ExtractFileName(mailgraph_pl));
        end;
       RegExpr.expression:='my \$rrd_virus';
       if  RegExpr.Exec(list.Strings[i]) then begin
           writeln('Starting......: Mailgraph statistics, change [$rrd_virus] to '+ExtractFileName(mailgraph_pl));
           list[i]:='my $rrd_virus = ''' + mailgraph_virus+''';';
           continue;
       end;
        
    end;
    list.SaveToFile(mailgraph_pl);
     fpsystem('/bin/chmod 755 ' + mailgraph_pl);
    list.Free;
    RegExpr.Free;
end;
//##############################################################################



function MyConf.ARTICA_FILTER_CHECK_PERMISSIONS():string;
var
   queuePath:string;
   ZSYS:TSystem;
begin
     result:='';
     ZSYS:=TSystem.Create();
     QueuePath:=ARTICA_FILTER_QUEUEPATH();
     if not ZSYS.IsUserExists('artica') then begin
        ZSYS.CreateGroup('artica');
        ZSYS.AddUserToGroup('artica','artica','','');
     end;
     forcedirectories('/var/log/artica-postfix');
     forcedirectories('/usr/share/artica-postfix/LocalDatabases');
     forcedirectories('/var/quarantines');
     
     if not FileExists(QueuePath) then begin
        writeln('creating folder ' +  QueuePath);
        forcedirectories(QueuePath);
        fpsystem('/bin/chown -R artica:root ' + QueuePath + ' >/dev/null 2>&1');
     end;
        
     
    fpsystem('/bin/chmod 755 /var/log/artica-postfix');
    fpsystem('/bin/chown -R artica:root /var/log/artica-postfix  >/dev/null 2>&1');
    fpsystem('/bin/chown -R artica:root /usr/share/artica-postfix/LocalDatabases  >/dev/null 2>&1');
    fpsystem('/bin/chown -R artica:root /var/quarantines  >/dev/null 2>&1');
    fpsystem('/bin/chown -R artica:root ' + QueuePath + ' >/dev/null 2>&1');

    if FileExists('/usr/local/bin/dspam') then begin
         fpsystem('/bin/chown artica:root /usr/local/bin/dspam >/dev/null 2>&1');
         fpsystem('/bin/chown -R artica:root /etc/dspam >/dev/null 2>&1');
         ForceDirectories('/usr/local/var/dspam/data >/dev/null 2>&1');
         ForceDirectories('/var/spool/dspam >/dev/null 2>&1');
         fpsystem('/bin/chown -R artica:root /var/spool/dspam >/dev/null 2>&1');
         fpsystem('/bin/chown -R artica:root /usr/local/var/dspam >/dev/null 2>&1');
    end;



end;
//##############################################################################

function MyConf.FETCHMAIL_START_DAEMON():boolean;
var
 fetchmail_daemon_pool,fetchmailpid,fetchmailpath:string;
 fetchmail_count:integer;
 D:boolean;
begin
     result:=true;
     D:=COMMANDLINE_PARAMETERS('debug');
     fetchmailpid:=FETCHMAIL_PID();
     fetchmailpath:=FETCHMAIL_BIN_PATH();
     fetchmail_daemon_pool:=FETCHMAIL_SERVER_PARAMETERS('daemon');
     if FileExists('/opt/artica/logs/fetchmail.daemon.started') then DeleteFile('/opt/artica/logs/fetchmail.daemon.started');
     if length(fetchmail_daemon_pool)=0 then fpsystem('/bin/echo "Artica...No config saved /etc/fetchmailrc" > /opt/artica/logs/fetchmail.daemon.started');
     
     fetchmail_count:=FETCHMAIL_COUNT_SERVER();

    if fetchmail_count>0 then begin
     if length(fetchmailpath)>0 then begin
        if length(fetchmail_daemon_pool)>0 then begin
           if not SYSTEM_PROCESS_EXIST(fetchmailpid) then begin
              writeln('Starting......: fetchmail daemon...');
              if D then showscreen('SYSTEM_START_ARTICA_DAEMON:: Start FETCHMAIL service server ' + IntToStr(fetchmail_count) + ' server(s)');
              if FileExists('/opt/artica/logs/fetchmail.daemon.started') then DeleteFile('/opt/artica/logs/fetchmail.daemon.started');
              logs.logs(fetchmailpath + ' --daemon ' + fetchmail_daemon_pool + ' --pidfile /var/run/fetchmail.pid --fetchmailrc /etc/fetchmailrc > /opt/artica/logs/fetchmail.daemon.started 2>&1');
              fpsystem(fetchmailpath + ' --daemon ' + fetchmail_daemon_pool + ' --pidfile /var/run/fetchmail.pid --fetchmailrc /etc/fetchmailrc > /opt/artica/logs/fetchmail.daemon.started 2>&1');
           end else begin
               writeln('Starting......: fetchmail is already running using PID ' + fetchmailpid + '...');
           end;
        end;
     end;
    end;
end;
//##############################################################################

procedure myConf.DNSMASQ_START_DAEMON();
var bin_path,pid,cache,cachecmd:string;
begin
    cache:=DNSMASQ_GET_VALUE('cache-size');
    bin_path:=DNSMASQ_BIN_PATH();
    if not FileExists(bin_path) then begin
      // writeln('Starting......: dnsmasq is not installed ('+bin_path+')...');
       exit;
    end;
    pid:=DNSMASQ_PID();
    if SYSTEM_PROCESS_EXIST(pid) then begin
       writeln('Starting......: dnsmasq already exists using pid ' + pid+ '...');
       exit;
    end;
    
    if FileExists('/etc/init.d/dnsmasq') then begin
       fpsystem('/etc/init.d/dnsmasq start');
       exit;
    end;
    
    if length(cache)=0 then begin
       cachecmd:=' --cache-size=1000';
    end;
    forceDirectories('/var/log/dnsmasq');
    writeln('Starting......: dnsmasq daemon...');
    fpsystem(bin_path + ' --pid-file=/var/run/dnsmasq.pid --conf-file=/etc/dnsmasq.conf --log-facility=/var/log/dnsmasq/dnsmasq.log' + cachecmd);
end;
//##############################################################################
function myConf.DNSMASQ_PID():string;
var
   RegExpr:TRegExpr;
   filedatas:TStringList;
   i:Integer;
begin

result:='';
     if not FileExists('/var/run/dnsmasq.pid') then exit();
     filedatas:=TStringList.Create;
     filedatas.LoadFromFile('/var/run/dnsmasq.pid');
     RegExpr:=TRegExpr.Create;
     RegExpr.Expression:='([0-9]+)';
     For i:=0 to filedatas.Count-1 do begin
         if RegExpr.Exec(filedatas.Strings[i]) then begin
               result:=RegExpr.Match[1];
               break;
         end;
     
     end;
     
    RegExpr.Free;
    filedatas.Free;

end;
//##############################################################################
procedure myconf.KAV4PROXY_START();
 var
    pid:string;
    count:integer;
begin
  count:=0;
  if not FileExists('/opt/kaspersky/kav4proxy/sbin/kav4proxy-kavicapserver') then begin
      writeln('Starting......: Kaspersky Antivirus for SQUID is not installed... skip');
      exit;
  end;
  pid:=KAV4PROXY_PID();
  if SYSTEM_PROCESS_EXIST(pid) then begin
   writeln('Starting......: Kaspersky Antivirus for SQUID already running using pid ' + pid+ '...');
   
   exit;
  end;
  forceDirectories('/var/run/kav4proxy');
  fpsystem('/bin/chown kluser:klusers /var/run/kav4proxy');
  fpsystem('/etc/init.d/kav4proxy start >/dev/null 2>&1');

  
  while not SYSTEM_PROCESS_EXIST(KAV4PROXY_PID()) do begin

        sleep(100);
        inc(count);
        if count>20 then break;
  end;
  
   pid:=KAV4PROXY_PID();
  if SYSTEM_PROCESS_EXIST(pid) then begin
   writeln('Starting......: Kaspersky Antivirus for SQUID started with new pid ' + pid+ '...');
  end else begin
   writeln('Starting......: Kaspersky Antivirus for SQUID Failed to start...');
  end;
end;
//##############################################################################
procedure myconf.DANSGUARDIAN_START();
var count:integer;
begin
count:=0;
if not FileExists('/opt/artica/sbin/dansguardian') then exit;
if not FileExists('/opt/artica/lib/libpcreposix.so.0.0.0') then exit;
if not FileExists('/opt/artica/lib/libpcre.so.0.0.1') then exit;

if not FileExists('/lib/libpcreposix.so.0') then begin
   writeln('Starting......: DansGuardian linking /opt/artica/lib/libpcreposix.so.0.0.0 -> /lib/libpcreposix.so.0');
   fpsystem('/bin/ln -s /opt/artica/lib/libpcreposix.so.0.0.0 /lib/libpcreposix.so.0');
end;

if not FileExists('/lib/libpcre.so.0') then begin
   writeln('Starting......: DansGuardian linking /opt/artica/lib/libpcre.so.0.0.1 -> /lib/libpcre.so.0');
   fpsystem('/bin/ln -s /opt/artica/lib/libpcre.so.0.0.1 /lib/libpcre.so.0');
end;

if not DirectoryExists('/var/run/dansguardian') then begin
     writeln('Starting......: creating /var/run/dansguardian');
     forcedirectories('/var/run/dansguardian');
     fpsystem('/bin/chown squid:squid /var/run/dansguardian');
     fpsystem('/bin/chmod 755 /var/run/dansguardian');
end;

 if SYSTEM_PROCESS_EXIST(DANSGUARDIAN_PID()) then begin
    writeln('Starting......: DansGuardian already running using pid ' + DANSGUARDIAN_PID()+ '...');
    exit;
 end;
 
 fpsystem('/opt/artica/sbin/dansguardian');
 
 while not SYSTEM_PROCESS_EXIST(DANSGUARDIAN_PID()) do begin

        sleep(100);
        inc(count);
        if count>100 then begin
           writeln('Starting......: DansGuardian (failed)');
           exit;
        end;
  end;
  
 writeln('Starting......: DansGuardian started with new pid ' + DANSGUARDIAN_PID());
 


end;
//##############################################################################
procedure myconf.DANSGUARDIAN_STOP();
 var
    pid:string;
    count:integer;
begin
count:=0;
  if not FileExists('/opt/artica/sbin/dansguardian') then exit;
  pid:=DANSGUARDIAN_PID();
  if SYSTEM_PROCESS_EXIST(pid) then begin
   writeln('Stopping DansGuardian........: ' + pid + ' PID');
   fpsystem('/opt/artica/sbin/dansguardian -q >/dev/null 2>&1');

  while SYSTEM_PROCESS_EXIST(DANSGUARDIAN_PID()) do begin
        sleep(100);
        inc(count);
        fpsystem('/opt/artica/sbin/dansguardian -q >/dev/null 2>&1');
        if count>30 then break;
  end;
   exit;
  end;

  if not SYSTEM_PROCESS_EXIST(DANSGUARDIAN_PID()) then begin
     writeln('Stopping DansGuardian........: Already stopped');
  end;
end;
//##############################################################################
procedure myconf.PURE_FTPD_STOP();
 var
    pid:string;
    count:integer;
begin
count:=0;
  if not FileExists('/opt/artica/sbin/pure-config.pl') then exit;
  pid:=PURE_FTPD_PID();
  if SYSTEM_PROCESS_EXIST(pid) then begin
   writeln('Stopping pure-ftpd...........: ' + pid + ' PID');
   fpsystem('/bin/kill ' + pid + ' >/dev/null 2>&1');

  while SYSTEM_PROCESS_EXIST(PURE_FTPD_PID()) do begin
        sleep(100);
        inc(count);
        fpsystem('/bin/kill ' + PURE_FTPD_PID() + ' >/dev/null 2>&1');
        if count>30 then break;
  end;
   exit;
  end;

  if not SYSTEM_PROCESS_EXIST(PURE_FTPD_PID()) then begin
     writeln('Stopping pure-ftpd...........: Already stopped');
  end;
end;
//##############################################################################

procedure myconf.SQUID_START();
 var
    pid:string;
    count:integer;
    SYS:Tsystem;
begin
count:=0;
SYS:=Tsystem.Create;
  if not FileExists(SQUID_BIN_PATH()) then exit;
  
       if not SYS.IsUserExists('squid') then begin
           writeln('Starting......: Squid user "squid" doesn''t exists... reconfigure squid');
           fpsystem(Paramstr(0) + ' -squid-configure');
       end else begin
           writeln('Starting......: Squid user "squid" exists OK');
       end;


  if not DirectoryExists('/opt/artica/var/cache') then begin
      writeln('Starting......: Creating directory /opt/artica/var/cache');
      forcedirectories('/opt/artica/var/cache');
      fpsystem('/bin/chown squid:squid /opt/artica/var/cache');
  end;
  

  SQUID_RRD_INIT();
  SQUID_RRD_INSTALL();

  pid:=SQUID_PID();
  if SYSTEM_PROCESS_EXIST(pid) then begin
   writeln('Starting......: Squid already running with pid ' + pid+ '...');
   exit;
  end;
  SQUID_VERIFY_CACHE();
  fpsystem(SQUID_BIN_PATH() + ' -z >/dev/null 2>&1');
  writeln('Starting......: Squid restore cache OK');
  fpsystem(SQUID_BIN_PATH() + ' -D >/opt/artica/logs/squid.start.daemon 2>&1');
  while not SYSTEM_PROCESS_EXIST(SQUID_PID()) do begin
        sleep(100);
        inc(count);
        if count>20 then break;
  end;
  
  
  pid:=SQUID_PID();
  if SYSTEM_PROCESS_EXIST(pid) then begin
   writeln('Starting......: Squid with new pid ' + pid+ '...');
   if FileExists('/opt/artica/logs/squid.start.daemon') then killfile('/opt/artica/logs/squid.start.daemon');
  end else begin
   writeln('Starting......: Squid Failed to start...');
  end;
  SYS.free;
end;
//##############################################################################
procedure myconf.SQUID_STOP();
 var
    pid:string;
    count:integer;
begin
count:=0;
  if not FileExists(SQUID_BIN_PATH()) then exit;
  pid:=SQUID_PID();
  if SYSTEM_PROCESS_EXIST(pid) then begin
   writeln('Stopping Squid...............: ' + pid + ' PID');
   fpsystem(SQUID_BIN_PATH() + ' -k kill');
   
  while SYSTEM_PROCESS_EXIST(SQUID_PID()) do begin
        sleep(100);
        inc(count);
         fpsystem(SQUID_BIN_PATH() + ' -k kill');
        if count>30 then break;
  end;
   exit;
  end;

  if not SYSTEM_PROCESS_EXIST(pid) then begin
     writeln('Stopping Squid...............: Already stopped');
  end;
end;
//##############################################################################
PROCEDURE myconf.SQUID_VERIFY_CACHE();
 var
    FileS    :TstringList;
    RegExpr  :TRegExpr;
    path     :string;
    i        :integer;
begin
   Files:=TstringList.Create;
   Files.LoadFromFile(SQUID_CONFIG_PATH());
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^cache_dir\s+(.+?)\s+(.+?)\s+';
   For i:=0 to Files.Count-1 do begin
       if RegExpr.Exec(Files.Strings[i]) then begin
           path:=RegExpr.Match[2];
           if not FileExists(path) then begin
              writeln('Starting......: Building new folder ' + path);
              forcedirectories(path);
              fpsystem('/bin/chown -R squid:squid ' + path);
              fpsystem('/bin/chmod 0755 ' + path);
           end;
       end;
   end;



end;
//#############################################################################
function myconf.SQUID_BIN_PATH():string;
begin
  if FileExists('/opt/artica/sbin/squid') then exit('/opt/artica/sbin/squid');
  if FileExists('/usr/sbin/squid') then exit('/usr/sbin/squid');
  if FileExists('/usr/local/sbin/squid') then exit('/usr/local/sbin/squid');
  if FileExists('/sbin/squid') then exit('/sbin/squid');
end;



procedure myconf.KAV4PROXY_STOP();
 var
    pid:string;
    count:integer;
begin
count:=0;
  if not FileExists('/opt/kaspersky/kav4proxy/sbin/kav4proxy-kavicapserver') then exit;
  pid:=KAV4PROXY_PID();
  if SYSTEM_PROCESS_EXIST(pid) then begin
   writeln('Stopping KAV antivirus SQUID.: ' + pid + ' PID');
   fpsystem('/etc/init.d/kav4proxy stop >/dev/null 2>&1');
  while SYSTEM_PROCESS_EXIST(KAV4PROXY_PID()) do begin
        sleep(100);
        inc(count);
        fpsystem('/etc/init.d/kav4proxy stop >/dev/null 2>&1');
        if count>20 then break;
  end;
   exit;
  end;

  if not SYSTEM_PROCESS_EXIST(pid) then begin
     writeln('Stopping KAV antivirus SQUID.: Already stopped');
  end;
end;
//##############################################################################
function myConf.KAV4PROXY_PID():string;
var
   RegExpr:TRegExpr;
   filedatas:TStringList;
   i:Integer;
begin
    result:='';
    if not FileExists('/opt/kaspersky/kav4proxy/sbin/kav4proxy-kavicapserver') then exit;
    if not FileExists('/var/run/kav4proxy/kavicapserver.pid') then exit;
filedatas:=TStringList.Create;
     filedatas.LoadFromFile('/var/run/kav4proxy/kavicapserver.pid');
     RegExpr:=TRegExpr.Create;
     RegExpr.Expression:='([0-9]+)';
     For i:=0 to filedatas.Count-1 do begin
         if RegExpr.Exec(filedatas.Strings[i]) then begin
               result:=RegExpr.Match[1];
               break;
         end;

     end;

    RegExpr.Free;
    filedatas.Free;

end;
//##############################################################################
function myConf.SQUID_PID():string;
var
   RegExpr:TRegExpr;
   filedatas:TStringList;
   i:Integer;
begin
    result:='';
    if not FileExists('/opt/artica/sbin/squid') then exit;
    if not FileExists('/opt/artica/var/squid/run/squid.pid') then exit;
filedatas:=TStringList.Create;
     filedatas.LoadFromFile('/opt/artica/var/squid/run/squid.pid');
     RegExpr:=TRegExpr.Create;
     RegExpr.Expression:='([0-9]+)';
     For i:=0 to filedatas.Count-1 do begin
         if RegExpr.Exec(filedatas.Strings[i]) then begin
               result:=RegExpr.Match[1];
               break;
         end;

     end;

    RegExpr.Free;
    filedatas.Free;

end;
//##############################################################################


procedure myconf.KAV6_STOP();
var
   filedatas:TStringList;
   RegExpr:TRegExpr;
   i:Integer;
begin
  if not FileExists('/opt/kav/5.6/kavmilter/bin/kavmilter') then exit;
  fpsystem('/bin/ps ax | awk ''{if (match($5, ".*/kavmilter$") || $5 == "$KAV_MILTER") print $1}'' >/opt/artica/logs/kav6.pids');
  if not FileExists('/opt/artica/logs/kav6.pids') then exit;
  filedatas:=TStringList.Create;
  filedatas.LoadFromFile('/opt/artica/logs/kav6.pids');
  RegExpr:=TRegExpr.Create;
  RegExpr.Expression:='([0-9]+)';
  if filedatas.Count=0 then begin
     logs.logs('KAV6_STOP:: already stopped...');
     writeln('Stopping KAV antivirus milter: Already stopped');
     exit;
     filedatas.free;
     RegExpr.free;
  end;
  For i:=0 to filedatas.Count-1 do begin
     if RegExpr.Exec(filedatas.Strings[i]) then begin
          logs.logs('KAV6_STOP:: /bin/kill ' + RegExpr.Match[1]);
          writeln('Stopping KAV antivirus milter: ' + RegExpr.Match[1] + ' PID');
          fpsystem('/bin/kill ' + RegExpr.Match[1]);
     end;

  end;
  


end;
//##############################################################################
function MyConf.KAV_MILTER_MEMORY():string;
var
   filedatas:TstringList;
   i:integer;
   pidlists:string;
   RegExpr:TRegExpr;
   D:Boolean;
begin
  pidlists:='';
  D:=COMMANDLINE_PARAMETERS('debug');

  if D then writeln('KAV_MILTER_PID:: Is There any kavmilter here ???');
  if not FileExists('/opt/kav/5.6/kavmilter/bin/kavmilter') then exit;
  fpsystem('/bin/ps ax | awk ''{if (match($5, ".*/kavmilter$") || $5 == "$KAV_MILTER") print $1}'' >/opt/artica/logs/kav6.pids');
  if not FileExists('/opt/artica/logs/kav6.pids') then begin
  if D then writeln('KAV_MILTER_PID:: unable to stat /opt/artica/logs/kav6.pids');
  exit;
  end;
  filedatas:=TStringList.Create;
  RegExpr:=TRegExpr.Create;
  RegExpr.Expression:='([0-9]+)';
  if FileExists('/opt/artica/logs/kav6.pids') then   filedatas.LoadFromFile('/opt/artica/logs/kav6.pids');
  For i:=0 to filedatas.Count-1 do begin
     if RegExpr.Exec(filedatas.Strings[i]) then begin
        if SYSTEM_PROCESS_EXIST(RegExpr.Match[1]) then begin
           pidlists:=pidlists + RegExpr.Match[1] + '=' + IntToStr(SYSTEM_PROCESS_MEMORY(RegExpr.Match[1])) + ';';
           if D then writeln('KAV_MILTER_PID:: PID: ' + RegExpr.Match[1] );
        end;
     end;
  end;

  result:=trim(pidlists);
end;
//##############################################################################

function Myconf.KAV_MILTER_PID():string;
var
   filedatas:TstringList;
   i:integer;
   pidlists:string;
   RegExpr:TRegExpr;
   D:Boolean;
begin
  pidlists:='';
  D:=COMMANDLINE_PARAMETERS('debug');
  
  if D then writeln('KAV_MILTER_PID:: Is There any kavmilter here ???');
  if not FileExists('/opt/kav/5.6/kavmilter/bin/kavmilter') then exit;
  fpsystem('/bin/ps ax | awk ''{if (match($5, ".*/kavmilter$") || $5 == "$KAV_MILTER") print $1}'' >/opt/artica/logs/kav6.pids');
  if not FileExists('/opt/artica/logs/kav6.pids') then begin
  if D then writeln('KAV_MILTER_PID:: unable to stat /opt/artica/logs/kav6.pids');
  exit;
  end;
  filedatas:=TStringList.Create;
  RegExpr:=TRegExpr.Create;
  RegExpr.Expression:='([0-9]+)';
  if FileExists('/opt/artica/logs/kav6.pids') then   filedatas.LoadFromFile('/opt/artica/logs/kav6.pids');
  For i:=0 to filedatas.Count-1 do begin
     if RegExpr.Exec(filedatas.Strings[i]) then begin
        if SYSTEM_PROCESS_EXIST(RegExpr.Match[1]) then begin
           pidlists:=pidlists + RegExpr.Match[1] + ' ';
           if D then writeln('KAV_MILTER_PID:: PID: ' + RegExpr.Match[1] );
        end;
     end;
  end;
  
  result:=trim(pidlists);
  
end;
//##############################################################################

function Myconf.INADYN_PID():string;
var
   filedatas:TstringList;
   i:integer;
   pidlists:string;
   RegExpr:TRegExpr;
   D:Boolean;
begin
  pidlists:='';
  D:=COMMANDLINE_PARAMETERS('debug');


  fpsystem('/bin/ps ax | awk ''{if (match($5, ".*/bin/inadyn")) print $1}'' >/opt/artica/logs/inadyn.pids');
  if not FileExists('/opt/artica/logs/inadyn.pids') then begin
  if D then writeln('INADYN_PID:: unable to stat /opt/artica/logs/inadyn.pids');
  exit;
  end;
  filedatas:=TStringList.Create;
  RegExpr:=TRegExpr.Create;
  RegExpr.Expression:='([0-9]+)';
  if FileExists('/opt/artica/logs/inadyn.pids') then   filedatas.LoadFromFile('/opt/artica/logs/inadyn.pids');
  For i:=0 to filedatas.Count-1 do begin
     if RegExpr.Exec(filedatas.Strings[i]) then begin
        if SYSTEM_PROCESS_EXIST(RegExpr.Match[1]) then begin
           pidlists:=pidlists + RegExpr.Match[1] + ' ';
           if D then writeln('INADYN_PID:: PID: ' + RegExpr.Match[1] );
        end;
     end;
  end;

  result:=trim(pidlists);

end;
//##############################################################################
procedure myconf.KAV6_START();
var
    pidlists:string;
    RegExpr:TRegExpr;
    l:TstringList;
    i:Integer;
    Expired:boolean;
begin
Expired:=false;
if not FileExists('/opt/kav/5.6/kavmilter/bin/kavmilter') then exit;
if FileExists('/opt/artica/license.expired.conf') then exit;
pidlists:='';
pidlists:=KAV_MILTER_PID();

   if length(pidlists)>0 then begin
       logs.logs('KAV6_START:: Already exists.....');
       writeln('Starting......: Kaspersky Mail server already running using pid ' + pidlists+ '...');
       exit;
   end;
   logs.logs('KAV6_START:: /etc/init.d/kavmilterd start >/opt/artica/logs/kav6.start 2>&1');
   fpsystem('/etc/init.d/kavmilterd start >/opt/artica/logs/kav6.start 2>&1');

   l:=TstringList.create;
   l.LoadFromFile('/opt/artica/logs/kav6.start');
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='Active key expired';
   for i:=0 to l.Count-1 do begin
      if RegExpr.Exec(l.Strings[i]) then begin
         Expired:=true;
         break;
      end;
   
   end;
   if Expired=true then begin
       l.SaveToFile('/opt/artica/license.expired.conf');
       writeln('Starting......: Kaspersky Mail server (License expired !)');
   end else begin
      writeln('Starting......: Kaspersky Mail server (' + KAV_MILTER_PID() + ')');
   end;

  
end;
//##############################################################################


procedure myConf.DNSMASQ_STOP_DAEMON();
var bin_path,pid:string;
begin

    bin_path:=DNSMASQ_BIN_PATH();
    if not FileExists(bin_path) then exit;
    pid:=DNSMASQ_PID();
    if not SYSTEM_PROCESS_EXIST(pid) then begin
       writeln('Stopping dnsmasq.........: Already stopped');
       exit;
    end;

    if FileExists('/etc/init.d/dnsmasq') then begin
       fpsystem('/etc/init.d/dnsmasq stop');
       exit;
    end;
    writeln('Stopping dnsmasq.........: ' + pid + ' PID');
    fpsystem('kill ' + pid);
end;
//##############################################################################
function MyConf.POSTFIX_LDAP_COMPLIANCE():boolean;
var
   LIST:TstringList;
   i:integer;
   D:Boolean;
begin
 D:=COMMANDLINE_PARAMETERS('debug');
 if D then writeln('POSTFIX_LDAP_COMPLIANCE -> POSFTIX_POSTCONF_PATH() ->' +POSFTIX_POSTCONF_PATH());
 result:=false;
 if not FileExists(POSFTIX_POSTCONF_PATH()) then exit;
 fpsystem(POSFTIX_POSTCONF_PATH()+' -m >/opt/artica/logs/postconfm.txt');
 LIST:=TStringList.Create;
 LIST.LoadFromFile('/opt/artica/logs/postconfm.txt');
 for i:=0 to LIST.Count -1 do begin
     if D then writeln('POSTFIX_LDAP_COMPLIANCE ->' + list.Strings[i]);
     if trim(list.Strings[i])='ldap' then begin
        if D then writeln('POSTFIX_LDAP_COMPLIANCE ->TRUE');
        result:=true;
        list.free;
        exit;
     end;
 
 end;
end;
//##############################################################################
function MyConf.FETCHMAIL_SERVER_PARAMETERS(param:string):string;
var
   RegExpr:TRegExpr;
   filedatas:TStringList;
   i:integer;
begin
  if not FileExists('/etc/fetchmailrc') then exit;
  filedatas:=TStringList.Create;
  RegExpr:=TRegExpr.Create;
  RegExpr.Expression:='^set\s+' + param + '\s+(.+)';
  filedatas.LoadFromFile('/etc/fetchmailrc');
   for i:=0 to filedatas.Count -1 do begin
      if RegExpr.Exec(filedatas.Strings[i]) then begin
         result:=trim(RegExpr.Match[1]);
         break;
      end;
   end;
   
   RegExpr.Free;
   filedatas.free;
end;
//##############################################################################
function MyConf.FETCHMAIL_COUNT_SERVER():integer;
var
   RegExpr:TRegExpr;
   filedatas:TStringList;
   i:integer;
begin
  result:=0;
  if not FileExists('/etc/fetchmailrc') then exit;
  filedatas:=TStringList.Create;
  RegExpr:=TRegExpr.Create;
  RegExpr.Expression:='^poll\s+(.+)';
  filedatas.LoadFromFile('/etc/fetchmailrc');
   for i:=0 to filedatas.Count -1 do begin
      if RegExpr.Exec(filedatas.Strings[i]) then begin
         inc(result);
         break;
      end;
   end;

   RegExpr.Free;
   filedatas.free;
end;
//##############################################################################


function MyConf.get_MAILGRAPH_RRD():string;
var
   RegExpr:TRegExpr;
   php_path,cgi_path,filedatas:string;
begin

 php_path:=get_ARTICA_PHP_PATH();
 cgi_path:=php_path + '/bin/mailgraph/mailgraph1.cgi';
 if not FileExists(cgi_path) then exit;
 RegExpr:=TRegExpr.create;
 RegExpr.expression:='my \$rrd[|=| ]+[''|"]([\/a-zA-Z0-9-\._]+)[''|"];';
 filedatas:=ReadFileIntoString(cgi_path);
  if  RegExpr.Exec(filedatas) then begin
  result:=RegExpr.Match[1];
  end;
  RegExpr.Free;
end;
//##############################################################################
function MyConf.get_LINUX_DOMAIN_NAME():string;
var data:string;
begin
if not FileExists('/bin/hostname') then exit;
fpsystem('/bin/hostname -d >/opt/artica/logs/hostname.txt');
data:=ReadFileIntoString('tmp/hostname.txt');
result:=trim(data);
end;

//##############################################################################
function MyConf.get_MAILGRAPH_RRD_VIRUS():string;
var
   RegExpr:TRegExpr;
   php_path,cgi_path,filedatas:string;
begin

 php_path:=get_ARTICA_PHP_PATH();
 cgi_path:=php_path + '/bin/mailgraph/mailgraph1.cgi';
 if not FileExists(cgi_path) then exit;
 RegExpr:=TRegExpr.create;
 RegExpr.expression:='my \$rrd_virus[|=| ]+[''|"]([\/a-zA-Z0-9-\._]+)[''|"];';
 filedatas:=ReadFileIntoString(cgi_path);
  if  RegExpr.Exec(filedatas) then begin
  result:=RegExpr.Match[1];
  end;
  RegExpr.Free;
end;

//##############################################################################
procedure MyConf.set_MAILGRAPH_RRD_VIRUS(rrd_path:string);
var
list:TstringList;
i:integer;
RegExpr:TRegExpr;
mailgraph_pl,mailgraph_virus_rrd:string;
begin
   list:=TstringList.Create;
   RegExpr:=TRegExpr.create;
   
   RegExpr.expression:='my \$rrd_virus';
   if length(rrd_path)=0 then rrd_path:=get_ARTICA_PHP_PATH() + '/bin/mailgraph/mailgraph_virus.rrd';
   mailgraph_virus_rrd:=rrd_path;
   
   list.LoadFromFile(MAILGRAPH_BIN());
   if list.Count<10 then exit;
   ShowScreen('------------------------------------------------------------------');
   ShowScreen('Open ' + MAILGRAPH_BIN() + ' in order to change $rrd_virus settings ');
   ShowScreen('to ' + mailgraph_virus_rrd);

   For i:=0 to  list.Count-1 do begin
       if  RegExpr.Exec(list.Strings[i]) then begin
           list[i]:='my $rrd_virus = ''' + mailgraph_virus_rrd+''';';
           ShowScreen('CHANGE ! Save file  ' + MAILGRAPH_BIN());
           list.SaveToFile(MAILGRAPH_BIN());
           fpsystem('/bin/chmod 755 ' + MAILGRAPH_BIN());
       end;
   end;
   
    mailgraph_pl:=get_ARTICA_PHP_PATH() + '/bin/mailgraph/mailgraph.pl';
    if not fileexists(mailgraph_pl) then begin
       ShowScreen('WARNING !!! unable to stat ' + mailgraph_pl);
       exit;
    end;
    
    ShowScreen('------------------------------------------------------------------');
    ShowScreen('Open ' + mailgraph_pl + ' in order to change $rrd_virus settings');
    ShowScreen('to ' + mailgraph_virus_rrd);
    
    
    list.LoadFromFile(mailgraph_pl);
    RegExpr.Expression:='my\s+\$rrd_virus\s+=["\s]+.+";';
    For i:=0 to  list.Count-1 do begin
        if  RegExpr.Exec(list.Strings[i]) then begin
          list[i]:='my $rrd_virus ="' + mailgraph_virus_rrd+'";';
          writeln('CHANGE ! Save file  ' + mailgraph_pl);
          list.SaveToFile(mailgraph_pl);
          fpsystem('/bin/chmod 755 ' + mailgraph_pl);
        end
    end;
       
    ShowScreen('------------------------------------------------------------------');
    
    
    list.Free;
    RegExpr.Free;
    exit;
    


end;
//##############################################################################
procedure MyConf.StripDiezes(filepath:string);
begin
    set_FileStripDiezes(filepath);
end;
procedure MyConf.set_FileStripDiezes(filepath:string);
var
list,list2:TstringList;
i,n:integer;
line:string;
RegExpr:TRegExpr;
begin
 RegExpr:=TRegExpr.create;
 RegExpr.expression:='#';
    if not FileExists(filepath) then exit;
    list:=TstringList.Create();
    list2:=TstringList.Create();
    list.LoadFromFile(filepath);
    n:=-1;
    For i:=0 to  list.Count-1 do begin
        n:=n+1;
         line:=list.Strings[i];
         if length(line)>0 then begin

            if not RegExpr.Exec(list.Strings[i])  then begin
               list2.Add(list.Strings[i]);
            end;
         end;
    end;

     killfile(filepath);
     list2.SaveToFile(filepath);

    RegExpr.Free;
    list2.Free;
    list.Free;
end;
 //##############################################################################
function MyConf.get_httpd_conf():string;
begin
    result:='';
    if fileExists('/opt/artica/conf/artica-www.conf') then exit('/opt/artica/conf/artica-www.conf');

end;
 //##############################################################################
 function MyConf.APACHE_VERSION():string;
var
   RegExpr:TRegExpr;
   l:TstringList;
begin
    if not fileExists('/opt/artica/bin/artica-www') then exit();
    fpsystem('/opt/artica/bin/artica-www -v >/opt/artica/logs/apache.version 2>&1');
    l:=TstringList.Create;
    l.LoadFromFile('/opt/artica/logs/apache.version');
    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='Server version: Apache/([0-9\.]+)';
    if RegExpr.Exec(l.Text) then result:=RegExpr.Match[1];
    RegExpr.Free;
    l.free;
end;
 //##############################################################################
function MyConf.PHP5_LIB_MODULES_PATH():string;
begin
  if not FileExists('/opt/artica/bin/php-config') then exit;
  fpsystem('/opt/artica/bin/php-config  --extension-dir >/opt/artica/logs/tmp_php5_ext_dir');
  result:=trim(ReadFileIntoString('/opt/artica/logs/tmp_php5_ext_dir'));
end;



 //##############################################################################
function MyConf.APACHE_PID():string;
var
   httpdconf:string;
   RegExpr:TRegExpr;
   FileData:TStringList;
   PidFile:string;
   i:integer;
   D:boolean;
begin
  result:='';
  D:=COMMANDLINE_PARAMETERS('debug');
  FileData:=TStringList.Create;
  RegExpr:=TRegExpr.Create;
   
  if not DirectoryExists('/opt/artica/logs') then begin
     if D then writeln('/opt/artica/logs -> doesnt'' exists');
     httpdconf:=get_httpd_conf();
     if D then writeln('Load ->',httpdconf);
     if not FileExists(httpdconf) then exit('0');

     FileData.LoadFromFile(httpdconf);
     RegExpr.Expression:='PidFile\s+(.+)';
     For i:=0 TO FileData.Count -1 do begin
         if RegExpr.Exec(FileData.Strings[i]) then begin
            PidFile:=RegExpr.Match[1];
            break;
         end;
     end;

  end else begin
      PiDFile:='/opt/artica/logs/httpd.pid';
  end;
  if D then writeln('Pid file ->',PiDFile);
  if not FileExists(PidFile) then exit('');
  FileData.LoadFromFile(PiDFile);
  RegExpr.Expression:='([0-9]+)';
  if RegExpr.exec(FileData.Text) then result:=RegExpr.Match[1];
  if result='0' then result:='';
  FileData.Free;
  RegExpr.Free;
end;
 //##############################################################################
 function MyConf.POSTFIX_PID():string;
var
   conffile:string;
   RegExpr:TRegExpr;
   FileData:TStringList;
   i:integer;
begin
   result:='0';
  conffile:=POSTFIX_PID_PATH();
  if not FileExists(conffile) then exit('0');
  RegExpr:=TRegExpr.Create;
  FileData:=TStringList.Create;
  FileData.LoadFromFile(conffile);
  RegExpr.Expression:='([0-9]+)';
  For i:=0 TO FileData.Count -1 do begin
      if RegExpr.Exec(FileData.Strings[i]) then begin
           result:=RegExpr.Match[1];
           break;
      end;
  end;
  FileData.Free;
  RegExpr.Free;
end;
 //##############################################################################
procedure MyConf.POSTFIX_STOP();
var pid:string;
begin
pid:=POSTFIX_PID();
if SYSTEM_PROCESS_EXIST(pid) then begin
   writeln('Stopping Postfix.............: ' + pid + ' PID..');
   if fileExists('/usr/sbin/postfix') then fpsystem('/usr/sbin/postfix stop >/dev/null 2>&1');
   if fileExists('/etc/init.d/postfix') then fpsystem('/etc/init.d/postfix stop >/dev/null 2>&1');
  end;

end;
 //##############################################################################
 function MyConf.SASLAUTHD_PID():string;
var
   conffile:string;
   RegExpr:TRegExpr;
   FileData:TStringList;

   i:integer;
begin
   result:='0';
   if FileExists('/var/run/saslauthd/saslauthd.pid') then conffile:='/var/run/saslauthd/saslauthd.pid';
   if FileExists('/var/run/saslauthd.pid') then conffile:='/var/run/saslauthd.pid';
   if length(conffile)=0 then exit();

  if not FileExists(conffile) then exit();
  RegExpr:=TRegExpr.Create;
  FileData:=TStringList.Create;
  FileData.LoadFromFile(conffile);
  RegExpr.Expression:='([0-9]+)';
  For i:=0 TO FileData.Count -1 do begin
      if RegExpr.Exec(FileData.Strings[i]) then begin
           result:=RegExpr.Match[1];
           break;
      end;
  end;
  FileData.Free;
  RegExpr.Free;
end;
 //##############################################################################
 function MyConf.MAILGRAPH_PID():string;
var
   conffile:string;
   RegExpr:TRegExpr;
   FileData:TStringList;
   i:integer;
begin
   result:='0';
   if FileExists('/var/run/mailgraph.pid') then conffile:='/var/run/mailgraph.pid';
   if length(conffile)=0 then exit();

  if not FileExists(conffile) then exit();
  RegExpr:=TRegExpr.Create;
  FileData:=TStringList.Create;
  FileData.LoadFromFile(conffile);
  RegExpr.Expression:='([0-9]+)';
  For i:=0 TO FileData.Count -1 do begin
      if RegExpr.Exec(FileData.Strings[i]) then begin
           result:=RegExpr.Match[1];
           break;
      end;
  end;
  FileData.Free;
  RegExpr.Free;
end;
 //##############################################################################
 
 function MyConf.CRON_PID():string;
var
   conffile:string;
   RegExpr:TRegExpr;
   FileData:TStringList;

   i:integer;
begin
   result:='0';
  conffile:='/var/run/crond.pid';
  if not FileExists(conffile) then exit('0');
  RegExpr:=TRegExpr.Create;
  FileData:=TStringList.Create;
  FileData.LoadFromFile(conffile);
  RegExpr.Expression:='([0-9]+)';
  For i:=0 TO FileData.Count -1 do begin
      if RegExpr.Exec(FileData.Strings[i]) then begin
           result:=RegExpr.Match[1];
           break;
      end;
  end;
  FileData.Free;
  RegExpr.Free;
end;
 //##############################################################################
function MyConf.LDAP_PID():string;
var
   conffile:string;
   RegExpr:TRegExpr;
   FileData:TStringList;
   PidFile:string;
   i:integer;
begin
  result:='0';
  conffile:=LDAP_GET_CONF_PATH();
  if not FileExists(conffile) then exit('0');
  RegExpr:=TRegExpr.Create;
  FileData:=TStringList.Create;
  FileData.LoadFromFile(conffile);
  RegExpr.Expression:='pidfile\s+(.+)';
  For i:=0 TO FileData.Count -1 do begin
      if RegExpr.Exec(FileData.Strings[i]) then begin
           PidFile:=RegExpr.Match[1];
           break;
      end;
  end;
  
  if not FileExists(PidFile) then exit('0');
  FileData.LoadFromFile(PiDFile);
  RegExpr.Expression:='([0-9]+)';
  if RegExpr.exec(FileData.Text) then result:=RegExpr.Match[1];
  
  
  FileData.Free;
  RegExpr.Free;
  // pidfile         /var/run/slapd/slapd.pid
end;
 //##############################################################################
function MyConf.CYRUS_PID():string;
var
   conffile:string;



   D:boolean;
begin
  result:='0';
  conffile:=CYRUS_PID_PATH();
  D:=COMMANDLINE_PARAMETERS('debug');
  if D then writeln('PID path -> ',conffile);
  if not FileExists(conffile) then begin
     if D then writeln('unable to stat path -> exit(0)');
     exit('0');
  end;
  
  
  result:=SYSTEM_GET_PID(conffile);
end;
 //##############################################################################
 

 
procedure MyConf.Cyrus_set_sasl_pwcheck_method(val:string);
var RegExpr:TRegExpr;
list:TstringList;
i:integer;
begin
 RegExpr:=TRegExpr.create;
    list:=TstringList.Create();
    list.LoadFromFile('/etc/imapd.conf');
    for i:=0 to list.Count-1 do begin
          RegExpr.expression:='sasl_pwcheck_method';
          if RegExpr.Exec(list.Strings[i]) then begin
               list.Strings[i]:='sasl_pwcheck_method: ' + val;
          end;
          
    end;
   list.SaveToFile('/etc/imapd.conf');
   list.Free;
   RegExpr.Free;
end;
 //##############################################################################
function MyConf.CYRUS_IMAPD_CONF_GET_INFOS(value:string):string;
var
   RegExpr:TRegExpr;
   list:TstringList;
   i:integer;
   D:boolean;
begin
D:=COMMANDLINE_PARAMETERS('debug');
 if not FileExists('/etc/imapd.conf') then begin
      if D then ShowScreen('IMAPD_CONF_GET_INFOS::Unable to locate /etc/imapd.conf');
      exit;
 end;

 RegExpr:=TRegExpr.create;
 RegExpr.expression:=value+'[:\s]+([a-z]+)';
 list:=TstringList.Create;
 for i:=0 to list.Count -1 do begin
       if RegExpr.exec(list.Strings[i]) then begin
              result:=Trim(RegExpr.Match[1]);
              if D then ShowScreen('IMAPD_CONF_GET_INFOS::found ' +list.Strings[i] + ' -> ' + result);
              break;
       end;
 end;
 List.Free;
 RegExpr.Free;
end;
 //##############################################################################
function MyConf.Cyrus_get_sasl_pwcheck_method;
var RegExpr:TRegExpr;
datas:string;
begin
 RegExpr:=TRegExpr.create;
 datas:=ReadFileIntoString('/etc/imapd.conf');
 RegExpr.expression:='sasl_pwcheck_method[:\s]+([a-z]+)';
 if RegExpr.Exec(datas) then begin
     result:=Trim(RegExpr.Match[1]);
 end;
 RegExpr.Free;
end;
 //##############################################################################
function MyConf.Cyrus_get_lmtpsocket;
var RegExpr:TRegExpr;
datas:string;
begin
 RegExpr:=TRegExpr.create;
 datas:=ReadFileIntoString('/etc/imapd.conf');
 RegExpr.expression:='lmtpsocket[:\s]+([a-z\/]+)';
 if RegExpr.Exec(datas) then begin
     result:=Trim(RegExpr.Match[1]);
 end;
 RegExpr.Free;
end;
 //##############################################################################

function MyConf.Cyrus_get_admins:string;
var RegExpr:TRegExpr;
datas:string;
begin
 RegExpr:=TRegExpr.create;
 datas:=ReadFileIntoString('/etc/imapd.conf');
 RegExpr.expression:='admins[:\s]+([a-z\.\-_0-9]+)';
 if RegExpr.Exec(datas) then begin
     result:=Trim(RegExpr.Match[1]);
 end;
 RegExpr.Free;
end;
 //##############################################################################
function MyConf.Cyrus_get_value(value:string):string;
var RegExpr:TRegExpr;
datas:string;
begin
 RegExpr:=TRegExpr.create;
 datas:=ReadFileIntoString('/etc/imapd.conf');
 RegExpr.expression:=value+'[:\s]+([a-z\.\-_0-9\s]+)';
 if RegExpr.Exec(datas) then begin
     result:=Trim(RegExpr.Match[1]);
 end;
 RegExpr.Free;
end;
 //##############################################################################
function MyConf.Cyrus_get_adminpassword():string;
begin
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
result:=GLOBAL_INI.ReadString('CYRUS','ADMIN_PASSWORD','');
GLOBAL_INI.Free;
end;
 //##############################################################################
procedure MyConf.Cyrus_set_adminpassword(val:string);
var ini:TIniFile;
begin
ini:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
ini.WriteString('CYRUS','ADMIN_PASSWORD',val);
ini.Free;
end;
//#############################################################################
function MyConf.Cyrus_get_admin_name():string;
begin
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
result:=GLOBAL_INI.ReadString('CYRUS','ADMIN','');
GLOBAL_INI.Free;
end;
 //##############################################################################
procedure MyConf.Cyrus_set_admin_name(val:string);
var ini:TIniFile;
begin
ini:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
ini.WriteString('CYRUS','ADMIN',val);
ini.Free;
end;
 //##############################################################################
function MyConf.KAS_INIT():string;
begin
if FileExists('/etc/init.d/kas3') then result:='/etc/init.d/kas3';
end;
 //##############################################################################

function myConf.KAS_APPLY_RULES(path:string):boolean;
var commands:string;
begin
result:=false;
if fileExists(path) then begin
           LOGS.logs('KAS_APPLY_RULES:: -> replicate Kaspersky Anti-Spam rules files : ' +path);
           commands:='/bin/mv ' + path + '/* /usr/local/ap-mailfilter3/conf/def/group/';
           LOGS.logs('KAS_APPLY_RULES:: ' +commands);
           fpsystem(commands);
           commands:='/usr/local/ap-mailfilter3/bin/sfupdates -s -f';
           LOGS.logs('KAS_APPLY_RULES:: ' +commands);
           ExecProcess(commands);
           result:=true;
        end;
end;



//#############################################################################
procedure MyConf.Cyrus_set_value(info:string;val:string);
var RegExpr:TRegExpr;
list:TstringList;
i:integer;
added:boolean;
begin
LOGS.Enable_echo:=echo_local;
if length(val)=0 then exit;
added:=false;
 RegExpr:=TRegExpr.create;
    list:=TstringList.Create();
    list.LoadFromFile('/etc/imapd.conf');
    for i:=0 to list.Count-1 do begin
          RegExpr.expression:=info;
          if RegExpr.Exec(list.Strings[i]) then begin
               if Debug then LOGS.logs('MyConf.Cyrus_set_value -> found "' + info + '"');
               if Debug then LOGS.logs('MyConf.Cyrus_set_value -> set line "' + IntTostr(i) + '" to "' + val + '"');
               list.Strings[i]:=info+ ': ' + val;
               added:=True;
          end;

    end;
    if added=False then begin
      list.Add(info+ ': ' +val);
    
    end;

   list.SaveToFile('/etc/imapd.conf');
   list.Free;
   RegExpr.Free;
end;
 //##############################################################################
procedure MyConf.SASLAUTHD_START();
var
   ldap_admin,ldap_password,ldap_server,ldap_suffix:string;
   list2:TStringList;
   D:Boolean;
   
begin

   d:=COMMANDLINE_PARAMETERS('debug');

   if D then  writeln('Starting......: saslauthd -> SASLAUTHD_START' );
   ldap_admin:=get_LDAP('admin');
   ldap_password:=get_LDAP('password');
   ldap_server:=Get_LDAP('server');
   ldap_suffix:=Get_LDAP('suffix');
   
   
   list2:=TstringList.Create;
   list2.Add('ldap_servers: ldap://' + ldap_server + '/');
   list2.Add('ldap_version: 3');
   list2.Add('ldap_search_base: '+ ldap_suffix);
   list2.Add('ldap_scope: sub');
   list2.Add('ldap_filter: uid=%u');
   list2.Add('ldap_auth_method: bind');
   list2.Add('ldap_bind_dn: cn=' +ldap_admin+ ',' + ldap_suffix);
   list2.Add('ldap_password: ' + ldap_password);
   list2.Add('ldap_timeout: 10');

    if D then  writeln('Starting......: saslauthd -> save conf -> /opt/artica/etc/saslauthd.conf' );
   list2.SaveToFile('/opt/artica/etc/saslauthd.conf');
   list2.free;







if SYSTEM_PROCESS_EXIST(SASLAUTHD_PID()) then begin
   writeln('Starting......: saslauthd already running using PID ' +SASLAUTHD_PID()+ '...');
   exit;
end;

if FileExists('/etc/init.d/saslauthd') then begin
     fpsystem('/etc/init.d/saslauthd stop >/dev/null 2>&1');
end;

if FileExists('/opt/artica/bin/saslauthd') then begin
     writeln('Starting......: saslauthd');
     fpsystem('/opt/artica/bin/saslauthd -a ldap -n 0 -c -O /opt/artica/etc/saslauthd.conf');
     exit;
end else begin
   if FileExists('/etc/init.d/saslauthd') then begin
     writeln('Starting......: saslauthd');
     fpsystem('/etc/init.d/saslauthd start >/dev/null 2>&1');
   end;
end;


end;
 //##############################################################################
procedure MyConf.SASLAUTHD_STOP();
begin
if SYSTEM_PROCESS_EXIST(SASLAUTHD_PID()) then begin
   writeln('Stopping SaslAuthd...........: ' + SASLAUTHD_PID() + ' PID..');
   fpsystem('/bin/kill ' + SASLAUTHD_PID());
end;
end;
 //##############################################################################
procedure MyConf.HOTWAYD_START();
begin
    if not FileExists('/opt/artica/sbin/hotwayd') then exit;
    if SYSTEM_PROCESS_EXIST(XINETD_PID()) then begin
      writeln('Starting......: xinetd already running using PID ' +XINETD_PID()+ '...');
      exit;
    end;
    writeln('Starting......: xinetd');
    If FileExists('/etc/init.d/xinetd') then fpsystem('/etc/init.d/xinetd start >/dev/null 2>&1');
end;
 //##############################################################################
function MyConf.HOTWAYD_VERSION():string;
var RegExpr:TRegExpr;
datas:string;
begin
if not FileExists('/opt/artica/sbin/hotwayd') then exit;
datas:=ExecPipe('/opt/artica/sbin/hotwayd -v');
RegExpr:=TRegExpr.create;
RegExpr.expression:='hotwayd v([0-9\.]+)';
if RegExpr.Exec(datas) then result:=RegExpr.Match[1];
RegExpr.free;
end;
 //##############################################################################
 
function MyConf.XINETD_PID();
begin
   if FileExists('/var/run/xinetd.pid') then begin
      result:=trim(ReadFileIntoString('/var/run/xinetd.pid'));
      exit;
   end;

end;
 //##############################################################################

function MyConf.Cyrus_get_servername:string;
var RegExpr:TRegExpr;
datas:string;
begin
 RegExpr:=TRegExpr.create;
 datas:=ReadFileIntoString('/etc/imapd.conf');
 RegExpr.expression:='servername[:\s]+([a-z\.\-_]+)';
 if RegExpr.Exec(datas) then begin
     result:=Trim(RegExpr.Match[1]);
 end;
 RegExpr.Free;
end;
 //#############################################################################
 
function MyConf.Cyrus_get_unixhierarchysep:string;
var RegExpr:TRegExpr;
datas:string;
begin
 RegExpr:=TRegExpr.create;
 datas:=ReadFileIntoString('/etc/imapd.conf');
 RegExpr.expression:='unixhierarchysep[:\s]+([a-z\.\-_]+)';
 if RegExpr.Exec(datas) then begin
     result:=Trim(RegExpr.Match[1]);
 end;
 RegExpr.Free;
end;
 //#############################################################################
function MyConf.Cyrus_get_virtdomain:string;
var RegExpr:TRegExpr;
datas:string;
begin
 RegExpr:=TRegExpr.create;
 datas:=ReadFileIntoString('/etc/imapd.conf');
 RegExpr.expression:='virtdomains[:\s]+([a-z\.\-_]+)';
 if RegExpr.Exec(datas) then begin
     result:=Trim(RegExpr.Match[1]);
 end;
 RegExpr.Free;
end;
 //#############################################################################
function MyConf.LINUX_GET_HOSTNAME:string;
var datas:string;
begin
 fpsystem('/bin/hostname >/opt/artica/logs/hostname.txt');
 datas:=ReadFileIntoString('/opt/artica/logs/hostname.txt');
 result:=Trim(datas);
end;
 //#############################################################################
function MyConf.CYRUS_GET_INITD_PATH:string;
begin
   if FileExists('/etc/init.d/cyrus') then result:='/etc/init.d/cyrus';
   if FileExists('/etc/init.d/cyrus-imapd') then result:='/etc/init.d/cyrus-imapd';
   if FileExists('/etc/init.d/cyrus21') then result:='/etc/init.d/cyrus21';
   if FileExists('/etc/init.d/cyrus2.2') then result:='/etc/init.d/cyrus2.2';
   if FileExists('/opt/artica/cyrus/bin/master') then result :=ExtractFilePath(ParamStr(0)) + 'artica-install cyrus-master';
   if FileExists('/usr/cyrus/bin/master') then result :=ExtractFilePath(ParamStr(0)) + 'artica-install cyrus-master';
end;
 //#############################################################################
procedure MyConf.CYRUS_DAEMON_START();
var
   m_cyrus_pid:string;
   D:boolean;
   count:integer;
   L_CYR:Tlogs;
begin
   m_cyrus_pid:=CYRUS_PID();
   count:=0;
   D:=COMMANDLINE_PARAMETERS('debug');
   l_CYR:=Tlogs.Create;
   if D then writeln('CYRUS_DAEMON_START:: PID-> ',m_cyrus_pid);
   if SYSTEM_PROCESS_EXIST(CYRUS_PID()) then begin
      writeln('Starting......: cyrus-imapd already running using PID ' +m_cyrus_pid+ '...');
      exit;
   end;

   if FileExists('/opt/artica/cyrus/bin/master') then begin
      if Not FileExists('/etc/imapd.conf') then begin
         writeln('Starting......: reconfigure cyrus-imapd (impad.conf and cyrus.conf)');
         CYRUS_IMAPD_CONFIGURE();
      end;
      
      if Not DirectoryExists('/var/run/cyrus/socket') then begin
         writeln('Starting......: cyrus-imapd building /var/run/cyrus/socket');
         ForceDirectories('/var/run/cyrus/socket');
         fpsystem('/bin/chmod 755 /var/run/cyrus/socket');
      end;
      
      if not CYRUS_enabled_in_master_cf() then begin
          l_CYR.logs('CYRUS_DAEMON_START:: -reconfigure-master');
          fpsystem(ExtractFilePath(ParamStr(0)) + 'artica-install -reconfigure-master');
      end;


      fpsystem('/opt/artica/cyrus/bin/master -d');
      while not SYSTEM_PROCESS_EXIST(CYRUS_PID()) do begin
            sleep(100);
            if count>20 then begin
               writeln('Starting......: cyrus-imapd (failed)');
               break;
            end;
      end;
       writeln('Starting......: cyrus-imapd with new PID '+ CYRUS_PID() + '...');
         exit;
   
   end;


end;
 //#############################################################################
procedure MyConf.CYRUS_DAEMON_STOP();
var
   count:integer;
begin
   if not FileExists(CYRUS_DELIVER_BIN_PATH()) then exit;
   count:=0;

   
   if SYSTEM_PROCESS_EXIST(CYRUS_PID()) then begin
      writeln('Stopping cyrus-imap..........: ' + CYRUS_PID() + ' PID..');
   end else begin
   exit;
   end;

   if FileExists('/opt/artica/cyrus/bin/master') then begin
         fpsystem('/bin/kill ' + CYRUS_PID());
         while SYSTEM_PROCESS_EXIST(CYRUS_PID()) do begin
                        sleep(100);
                        fpsystem('/bin/kill ' + CYRUS_PID());
                        Inc(count);
                        if count>20 then begin
                           writeln('killing cyrus-imap...........: ' + CYRUS_PID() + ' PID.. (timeout)');
                           fpsystem('/bin/kill -9 ' + CYRUS_PID());
                           break;
                        end;
                  end;
         exit;

   end;

   if FileExists(CYRUS_GET_INITD_PATH()) then begin
         fpsystem(CYRUS_GET_INITD_PATH() + ' stop >/dev/null 2>&1');
   end;

end;
 
 //#############################################################################
function MyConf.APACHE_GET_INITD_PATH:string;
begin
   if FileExists('/opt/artica/bin/apachectl') then exit('/opt/artica/bin/apachectl');
end;
 //#############################################################################
function MyConf.APACHE2_DirectoryAddOptions(Change:boolean;WichOption:string):string;

var
   httpd_path:string;
   RegExpr:TRegExpr;
   RegExpr2:TRegExpr;
   D,start, LineISFound:Boolean;
   list:TstringList;
   i,FoundLine:integer;
begin

     D:=COMMANDLINE_PARAMETERS('debug');
     LineISFound:=false;

     httpd_path:=get_httpd_conf();
     if D then showScreen('APACHE2_DirectoryAddOptions: Load file "' +  httpd_path + '"');
     list:=TstringList.Create();
     list.LoadFromFile(httpd_path);

     RegExpr2:=TRegExpr.create;
     RegExpr:=TRegExpr.Create;
     
     RegExpr2.expression:='#';
     start:=False;

         RegExpr.Expression:='<Directory "' + get_www_root + '">';
         if D then showScreen('APACHE2_DirectoryAddOptions: try to found line <Directory "' + get_www_root + '">');
         if D then showScreen('APACHE2_DirectoryAddOptions: file "' +  IntToStr(list.Count) + '" lines..');
         For i:=0 to  list.Count-1 do begin
             if not RegExpr2.Exec(list.Strings[i]) then begin
                if RegExpr.Exec(list.Strings[i]) then begin
                   if start=false then begin
                      start:=True;
                      if D then ShowScreen('APACHE2_DirectoryAddOption:: Found start line ' + IntToStr(i));
                      RegExpr.Expression:='Options(.+)';
                   end;
                end;
                if RegExpr.Exec(list.Strings[i]) then begin
                   if Start=true then
                       FoundLine:=i;
                       LineISFound:=True;
                       if D then ShowScreen('APACHE2_DirectoryAddOption:: Found Options in line ' + IntToStr(i));
                       if D then ShowScreen('APACHE2_DirectoryAddOption:: ' + trim(RegExpr.Match[1]));
                       break;
                   end;
                end;
                      
         end;

      if LineISFound=false then begin
          if D then ShowScreen('Unable to found matched pattern');
          exit();
      end;
      if trim(RegExpr.Match[1])='None' then begin
           list.Strings[FoundLine]:=chr(9)+chr(9)+ 'Options ' + WichOption;
           result:='no';
      end;
      
      if trim(RegExpr.Match[1])='none' then begin
         list.Strings[FoundLine]:=chr(9)+chr(9)+ 'Options ' + WichOption;
         result:='no';
      end;
      
      if D then ShowScreen('APACHE2_DirectoryAddOption:: FoundLine=' + IntToStr(FoundLine));
      RegExpr.Expression:=WichOption;
      if not RegExpr.Exec(list.Strings[FoundLine]) then begin
            result:='no';
            list.Strings[FoundLine]:=list.Strings[FoundLine]+ ' ' + WichOption;
      end;

      if Change then list.SaveToFile(httpd_path);
      list.Free;
      

         
         
end;

 //#############################################################################


function MyConf.get_www_userGroup():string;
var
user,group:string;
RegExpr:TRegExpr;
RegExpr2:TRegExpr;
list:TstringList;
i:integer;
httpd_path:string;
begin

          httpd_path:=get_httpd_conf();
         if FileExists('/etc/apache2/uid.conf') then httpd_path:='/etc/apache2/uid.conf';
         if length(httpd_path)=0 then exit();

         list:=TstringList.Create();
         list.LoadFromFile(httpd_path);
         
          RegExpr2:=TRegExpr.create;
          RegExpr2.expression:='#';
         
         RegExpr:=TRegExpr.Create;

         
         For i:=0 to  list.Count-1 do begin
             if not RegExpr2.Exec(list.Strings[i])  then begin

                RegExpr.Expression:='Group\s+([a-zA-Z0-9\.\-_]+)';
                if RegExpr.Exec(list.Strings[i]) then begin
                   group:=RegExpr.Match[1];
                end;

                RegExpr.Expression:='User\s+([a-zA-Z0-9\.\-_]+)';
                if RegExpr.Exec(list.Strings[i]) then begin
                   user:=RegExpr.Match[1];
                end;
             
             end;
        end;
         
         RegExpr.Free;
         RegExpr2.Free;
         list.Free;
         result:=user +':' + group;
         
    end;
//##############################################################################
function MyConf.get_www_root():string;
var
mDatas   :TstringList;
RegExpr  :TRegExpr;
i        :integer;
D        :Boolean;
begin

    if not FileExists(get_httpd_conf()) then exit;
    
    D:=COMMANDLINE_PARAMETERS('debug');
    mDatas:=TstringList.create;
    mDatas.LoadFromFile(get_httpd_conf());
    
    
    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='DocumentRoot[''|"|\s]+(.+?)["|''|\s|\n]+';
    
    For i:=0 to mDatas.Count-1 do begin
    if Copy(mDatas.Strings[i],0,1)<>'#' then begin
       if RegExpr.Exec(mDatas.Strings[i]) then begin
          Result:=RegExpr.Match[1];
          if Result[length(Result)]='/' then Result:=Copy(Result,0,length(Result)-1);
          break;
          end else begin
              if D then writeln('get_www_root() -> ' + mDatas.Strings[i] + ' does not match ' + RegExpr.Expression);
          end;
       end;
    end;
    RegExpr.free;
    mDatas.free;
    
end;

//##############################################################################
function MyConf.postfix_get_virtual_mailboxes_maps():string;
var
mDatas:string;
RegExpr:TRegExpr;
begin
    mDatas:=ReadFileIntoString(POSFTIX_MASTER_CF_PATH());
    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='virtual_mailbox_maps.+(hash:|mysql:)([0-9a-zA-Z\.\-_/]+)';
    if RegExpr.Exec(mDatas) then begin
       Result:=RegExpr.Match[2];
       RegExpr.free;
       exit;
    end;
end;
//##############################################################################
function MyConf.POSTFIX_HEADERS_CHECKS():string;
var
mDatas:string;
RegExpr:TRegExpr;
begin
    mDatas:=ExecPipe(POSFTIX_POSTCONF_PATH()+' -h header_checks');

    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='regexp:([0-9a-zA-Z\.\-_/]+)';
    if RegExpr.Exec(mDatas) then begin
       Result:=RegExpr.Match[1];
       RegExpr.free;
       exit;
    end;
end;
//##############################################################################
procedure MyConf.POSTFIX_CHECK_POSTMAP();
var
mDatas:TstringList;
RegExpr:TRegExpr;
local_path,FilePathName, FilePathNameTO:string;
i:integer;
xLOGS:Tlogs;
begin
    xLOGS:=Tlogs.Create;
    if not FileExists(POSFTIX_MASTER_CF_PATH()) then begin
       xLOGS.logs('MYCONF::POSTFIX_CHECK_POSTMAP:: /etc/postfix/main.cf doesn''t exists !!!???');
       exit;
    end;
    
    local_path:=get_ARTICA_PHP_PATH() + '/ressources/conf';
    if debug then writeln('Use ' + local_path + ' as detected config ');
    xLOGS.logs('MYCONF::POSTFIX_CHECK_POSTMAP:: Use ' + local_path + ' as detected config');
    
    mDatas:=TstringList.Create;
    mDatas.LoadFromFile(POSFTIX_MASTER_CF_PATH());
    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='hash:([0-9a-zA-Z\.\-_/]+)';
    xLOGS.logs('MYCONF::POSTFIX_CHECK_POSTMAP:: FIND hash:([0-9a-zA-Z\.\-_/]+)');
    for i:=0 to  mDatas.Count -1 do begin
         if RegExpr.Exec(mDatas.Strings[i]) then begin
            FilePathName:=local_path + '/' +  ExtractFileName(RegExpr.Match[1]);
            FilePathNameTO:=RegExpr.Match[1];
            xLOGS.logs('MYCONF::POSTFIX_CHECK_POSTMAP:: Found "' + RegExpr.Match[1] + '" => "' +FilePathName + '" => "'+ FilePathNameTO + '"');
            
            
            if fileExists(local_path + '/' +  ExtractFileName(RegExpr.Match[1])) then begin
                    if debug then writeln('Update ' +ExtractFileName(RegExpr.Match[1]));
                    xLOGS.logs('MYCONF::POSTFIX_CHECK_POSTMAP:: /bin/mv ' + FilePathName + ' ' + FilePathNameTO);
                    fpsystem('/bin/mv ' + FilePathName + ' ' + FilePathNameTO);
                     if debug then writeln('postmap ' +FilePathNameTO);

                     xLOGS.logs('MYCONF::POSTFIX_CHECK_POSTMAP:: /bin/chmod 640 ' + FilePathNameTO);
                     fpsystem('/bin/chmod 640 ' + FilePathNameTO);
                     fpsystem('/bin/chown root ' + FilePathNameTO + ' >/dev/null 2>&1');
                     xLOGS.logs('MYCONF::POSTFIX_CHECK_POSTMAP:: /usr/sbin/postmap ' + FilePathNameTO);
                     fpsystem('/usr/sbin/postmap ' + FilePathNameTO);
                     
                     
            end else begin
                 if debug then writeln('No update operation for ' + RegExpr.Match[1] + ' (' + ExtractFileName(RegExpr.Match[1]) + ')');
            end;
            
            
         end;
    end;
    RegExpr.Free;
    mDatas.Free;
end;
//##############################################################################
function MyConf.ARTICA_DAEMON_GET_PID():string;
begin
    result:=SYSTEM_GET_PID('/etc/artica-postfix/artica-agent.pid');
end;
//##############################################################################
function MyConf.ARTICA_FILTER_GET_PID():string;
begin
     result:=SYSTEM_GET_PID('/etc/artica-postfix/artica-filter.pid');
end;
//##############################################################################
function MyConf.BOA_DAEMON_GET_PID():string;
begin
     result:=SYSTEM_GET_PID('/etc/artica-postfix/boa.pid');
end;
//##############################################################################
function MyConf.ARTICA_POLICY_GET_PID():string;
begin
     result:=SYSTEM_GET_PID('/etc/artica-postfix/artica-policy.pid');
end;
//##############################################################################
function MyConf.MAILMAN_GET_PID():string;
begin
     result:=SYSTEM_GET_PID('/opt/artica/var/mailman/data/master-qrunner.pid');
end;
//##############################################################################
function myconf.PURE_FTPD_PID() :string;
begin
result:=SYSTEM_GET_PID('/var/run/pure-ftpd.pid');
end;
//##############################################################################


function MyConf.MAILMAN_VERSION():string;
var
   line:string;
   RegExpr:TRegExpr;
   D:Boolean;
begin
     D:=COMMANDLINE_PARAMETERS('debug');
     if not FileExists('/opt/artica/mailman/bin/version') then begin
       if D then  writeln('MAILMAN_VERSION() -> unable to stat /opt/artica/mailman/bin/version');
        exit;
     end;
     
     
     
     line:=ExecPipe('/opt/artica/mailman/bin/version');
    if D then  writeln('MAILMAN_VERSION() ->' + line);
     RegExpr:=TRegExpr.Create;
     RegExpr.Expression:='([0-9\.]+)';
     if RegExpr.Exec(line) then begin
        result:=RegExpr.Match[1];
        if D then  writeln('MAILMAN_VERSION() -> ' + result);
     end else begin
          if D then  writeln('MAILMAN_VERSION() does''t match ->' + RegExpr.Expression);
     end;
     RegExpr.Free;
end;
//##############################################################################
function MyConf.ReadFileIntoString(path:string):string;
var
   List:TstringList;
begin

      if not FileExists(path) then begin
        exit;
      end;

      List:=Tstringlist.Create;
      List.LoadFromFile(path);
      result:=List.Text;
      List.Free;
end;
//##############################################################################
procedure MyConf.killfile(path:string);
Var F : Text;
begin

 if not FileExists(path) then exit;
 if Debug then LOGS.logs('MyConf.killfile -> remove "' + path + '"');
TRY
 Assign (F,path);
 Erase (f);
 EXCEPT
 end;
end;
//##############################################################################
function MyConf.get_LINUX_MAILLOG_PATH():string;
var filedatas,logconfig,ExpressionGrep:string;
D:boolean;
RegExpr:TRegExpr;
begin
 D:=COMMANDLINE_PARAMETERS('debug');
if FileExists('/etc/syslog.conf') then logconfig:='/etc/syslog.conf';
if FileExists('/etc/syslog-ng/syslog-ng.conf') then logconfig:='/etc/syslog-ng/syslog-ng.conf';
if FileExists('/etc/rsyslog.conf') then logconfig:='/etc/rsyslog.conf';

if D then ShowScreen('');
if D then ShowScreen('get_LINUX_MAILLOG_PATH:: Master config is :"'+logconfig+'"');

filedatas:=ReadFileIntoString(logconfig);
   ExpressionGrep:='mail\.=info.+?-([\/a-zA-Z_0-9\.]+)?';
   RegExpr:=TRegExpr.create;
   RegExpr.ModifierI:=True;
   RegExpr.expression:=ExpressionGrep;
   if RegExpr.Exec(filedatas) then  begin
     result:=RegExpr.Match[1];
     RegExpr.Free;
     exit;
   end;


   ExpressionGrep:='mail\.\*.+?-([\/a-zA-Z_0-9\.]+)?';
   RegExpr.expression:=ExpressionGrep;
   if RegExpr.Exec(filedatas) then   begin
     result:=RegExpr.Match[1];
     RegExpr.Free;
     exit;
   end;
   
   ExpressionGrep:='destination mailinfo[\s\{a-z]+\("(.+?)"';
   RegExpr.expression:=ExpressionGrep;
   if RegExpr.Exec(filedatas) then   begin
     result:=RegExpr.Match[1];
     RegExpr.Free;
     exit;
   end;

  RegExpr.Free;
end;
//##############################################################################
function MyConf.POSTFIX_LAST_ERRORS():string;
var logPath,cmdline:string;
D,A:boolean;
RegExpr:TRegExpr;
FileData:TstringList;
i:integer;
begin
  D:=COMMANDLINE_PARAMETERS('debug');
  result:='';
  logPath:=get_LINUX_MAILLOG_PATH();
  logs.logs('POSTFIX_LAST_ERRORS() -> ' + logpath);
  if not FileExists(logpath) then begin
     if D then ShowScreen('POSTFIX_LAST_ERRORS:: Error unable to stat "' + logPath + '"');
     exit;
  end;
  A:=COMMANDLINE_PARAMETERS('errors');
  D:=COMMANDLINE_PARAMETERS('debug');
   RegExpr:=TRegExpr.Create;
   FileData:=TstringList.CReate;
   ArrayList:=TstringList.CReate;
   RegExpr.Expression:='(fatal|failed|failure|deferred|Connection timed out|expired|rejected|warning)';
   cmdline:='/usr/bin/tail -n 2000 ' + logPath;
   logs.logs('POSTFIX_LAST_ERRORS() -> ' + cmdline);
   
   if D then ShowScreen('POSTFIX_LAST_ERRORS:: "'+cmdline+'"');
   FileData.LoadFromStream(ExecStream(cmdline,false));
   
   logs.logs('POSTFIX_LAST_ERRORS() ->tail -> ' + IntToStr(FileData.count) + ' lines');
   
   if D then ShowScreen('POSTFIX_LAST_ERRORS:: tail -> ' + IntToStr(FileData.count) + ' lines');
   For i:=0 to FileData.count-1 do begin
       RegExpr.Expression:='(postfix\/|cyrus\/)';
       if RegExpr.Exec(FileData.Strings[i]) then begin
          RegExpr.Expression:='(fatal|failed|failure|deferred|Connection timed out|expired|rejected)';
            if RegExpr.Exec(FileData.Strings[i]) then begin
               if A then writeln(FileData.Strings[i]);
               ArrayList.Add(FileData.Strings[i]);
            end;
       end;
   
   end;

   RegExpr.free;
   FileData.Free;
   

end;
//##############################################################################
function MyConf.GetIPAddressOfInterface( if_name:ansistring):ansistring;
var
 ifr : ifreq;
 sock : longint;
 p:pChar;

begin
 Result:='0.0.0.0';
 strncpy( ifr.ifr_ifrn.ifrn_name, pChar(if_name), IF_NAMESIZE-1 );
 ifr.ifr_ifru.ifru_addr.sa_family := AF_INET;
 sock := socket(AF_INET, SOCK_DGRAM, IPPROTO_IP);
 if ( sock >= 0 ) then begin
   if ( ioctl( sock, SIOCGIFADDR, @ifr ) >= 0 ) then begin
     p:=inet_ntoa( ifr.ifr_ifru.ifru_addr.sin_addr );
     if ( p <> nil ) then Result :=  p;
   end;
   libc.__close(sock);
 end;
end;
//##############################################################################
function MyConf.CheckInterface( if_name:string):boolean;
var
RegExpr:TRegExpr;
 datas : string;
begin
 Result:=False;
 if not FileExists('/sbin/ifconfig') then exit;
 
     fpsystem('/sbin/ifconfig ' + if_name + ' >/opt/artica/logs/ifconfig_' + if_name);
     datas:= ReadFileIntoString('/opt/artica/logs/ifconfig_' + if_name);
     RegExpr:=TRegExpr.create;
     RegExpr.expression:='adr\:([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)';
     if RegExpr.Exec(datas) then begin
       RegExpr.Free;
       Result:=True;
       exit;
   end;
end;
//##############################################################################
function MyConf.GetIPInterface( if_name:string):string;
var
RegExpr:TRegExpr;
 datas : string;
begin

 if not FileExists('/sbin/ifconfig') then exit;

     fpsystem('/sbin/ifconfig ' + if_name + ' >/opt/artica/logs/ifconfig_' + if_name);
     datas:= ReadFileIntoString('/opt/artica/logs/ifconfig_' + if_name);
     RegExpr:=TRegExpr.create;
     RegExpr.expression:='adr\:([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)';
     if RegExpr.Exec(datas) then begin
       RegExpr.Free;
       if length(RegExpr.Match[1])>0 then Result:=RegExpr.Match[1];
       exit;
   end;
end;
//##############################################################################




function MyConf.LDAP_READ_VALUE_KEY( key:string):string;
var
RegExpr:TRegExpr;
RegExprD:TRegExpr;
 datas : TstringList;
 path:string;
 i:integer;
begin
     path:=LDAP_GET_CONF_PATH();
     if length(path)=0 then exit;
     datas:=Tstringlist.Create;
     datas.LoadFromFile(path);
     RegExpr:=TRegExpr.create;
     RegExprD:=TRegExpr.create;
     
     RegExpr.expression:=key + '["\s]+([a-z0-9\.=,\-]+)';
     RegExprD.expression:='#';

       for i:=0 to datas.count-1 do begin
           if not RegExprD.Exec(datas.Strings[i]) then begin
                 if RegExpr.Exec(datas.Strings[i]) then begin
                      result:=RegExpr.Match[1];
                      break;
                 end;
           
           end;
       end;
       RegExprD.Free;
       RegExpr.Free;
       datas.Free;
       exit;

end;
//##############################################################################
function MyConf.LDAP_READ_SCHEMA_POSTFIX_PATH():string;
var
   RegExpr:TRegExpr;
   RegExprD:TRegExpr;
   datas : TstringList;
   path:string;
   i:integer;
begin
     path:=LDAP_GET_CONF_PATH();
     if not fileExists(path) then begin
        writeln('unable to stat ' + path);
        exit;
     end;
     datas:=Tstringlist.Create;

     datas.LoadFromFile(path);
     RegExpr:=TRegExpr.create;
     RegExprD:=TRegExpr.create;

     RegExpr.expression:='include\s+([a-z\/0-9\-_]+postfix.schema)';
     RegExprD.expression:='#';

       for i:=0 to datas.count-1 do begin
           if not RegExprD.Exec(datas.Strings[i]) then begin
                 if RegExpr.Exec(datas.Strings[i]) then begin
                      result:=RegExpr.Match[1];
                      break;
                 end;

           end;
       end;
       RegExprD.Free;
       RegExpr.Free;
       datas.Free;
       exit;

end;
//##############################################################################
procedure MyConf.POSTFIX_REPLICATE_MAIN_CF(mainfile:string);
var
   conf_path,bounce_template_cf:string;
begin

     if not fileExists(mainfile) then begin
       ShowScreen('POSTFIX_REPLICATE_MAIN_CF:: Unable to stat ' + mainfile);
       exit;
     end;

        conf_path:=ExtractFilePath(mainfile);
        ShowScreen('POSTFIX_REPLICATE_MAIN_CF:: conf directory=' + conf_path);
        bounce_template_cf:=conf_path+ '/bounce.template.cf';
        ShowScreen('POSTFIX_REPLICATE_MAIN_CF:: -> ' + bounce_template_cf + ' ?');
        if FileExists(bounce_template_cf) then begin
            fpsystem('/bin/mv ' + bounce_template_cf + ' /etc/postfix');
            ShowScreen('POSTFIX_REPLICATE_MAIN_CF::  move ' + bounce_template_cf + ' (ok)');
            fpsystem('/bin/chown root:root /etc/postfix/bounce.template.cf >/dev/null 2>&1');
        end;


        logs.logsPostfix('replicate: ' + mainfile +' to /etc/postfix' );
        
        fpsystem('/bin/mv ' + mainfile + ' /etc/postfix');
        

        
        POSTFIX_CHECK_POSTMAP();
        logs.logsPostfix('replicate:restart postfix');
        POSFTIX_VERIFY_MAINCF();

        
        
end;
//#####################################################################################
procedure myconf.POSTFIX_INITIALIZE_FOLDERS();
begin

   forcedirectories('/var/spool/postfix/pid');
   forcedirectories('/var/spool/postfix/corrupt');
   forcedirectories('/var/spool/postfix/trace');
   forcedirectories('/var/spool/postfix/saved');
   forcedirectories('/var/spool/postfix/private');
   forcedirectories('/var/spool/postfix/etc');
   forcedirectories('/var/spool/postfix/incoming');
   forcedirectories('/var/spool/postfix/defer');
   forcedirectories('/var/spool/postfix/maildrop');
   forcedirectories('/var/spool/postfix/public');
   forcedirectories('/var/spool/postfix/active');
   forcedirectories('/var/spool/postfix/hold');
   forcedirectories('/var/spool/postfix/flush');
   forcedirectories('/var/spool/postfix/bounce');
   forcedirectories('/var/spool/postfix/public');

   fpsystem('/bin/chmod -R 0700 /var/spool/postfix');
   fpsystem('/bin/chown -R postfix:root /var/spool/postfix');
   fpsystem('/bin/chmod -R 0755 /var/spool/postfix/etc');
   fpsystem('/bin/chown -R root:root /var/spool/postfix/etc');

   fpsystem('/bin/chown -R root:root /usr/libexec/postfix');
   fpsystem('/bin/chmod -R 0755 /usr/libexec/postfix/*');
   fpsystem('/bin/chmod -R 0730 /var/spool/postfix/maildrop');

   fpsystem('/bin/chown -R postfix:postdrop /var/spool/postfix/maildrop');
   fpsystem('/bin/chown -R postfix:postdrop /var/spool/postfix/public');


   fpsystem('/bin/chown -R root:root /var/spool/postfix/pid');
   fpsystem('/bin/chmod -R 0755 /var/spool/postfix/pid');


   fpsystem('/bin/chown root:postdrop /usr/sbin/postqueue');
   fpsystem('/bin/chmod 2755 /usr/sbin/postqueue');

   fpsystem('/bin/chown root:postdrop /usr/sbin/postdrop');
   fpsystem('/bin/chmod 2755 /usr/sbin/postdrop');
   
if DirectoryExists('/var/spool/postfix') then begin
            if Not DirectoryExists('/var/spool/postfix/etc') then forceDirectories('/var/spool/postfix/etc');
            fpsystem('/bin/cp /etc/services /var/spool/postfix/etc/services >/dev/null 2>&1');
            fpsystem('/bin/cp /etc/resolv.conf /var/spool/postfix/etc/resolv.conf >/dev/null 2>&1');
            fpsystem('/bin/cp /etc/hosts /var/spool/postfix/etc/hosts >/dev/null 2>&1');
            fpsystem('/bin/cp /etc/localtime /var/spool/postfix/etc/localtime >/dev/null 2>&1');
            fpsystem('/bin/cp /etc/nsswitch.conf /var/spool/postfix/etc/nsswitch.conf >/dev/null 2>&1');

        end;
        
end;



procedure myConf.POSFTIX_VERIFY_MAINCF();


var
   inet_interfaces,mailbox_transport:string;
   PostfixLogs:Tlogs;
   
begin
        POSTFIX_INITIALIZE_FOLDERS();
        if FileExists('/etc/postfix/post-install') then fpsystem('/etc/postfix/post-install create-missing');
        PostfixLogs:=Tlogs.Create;
        if not FileExists(POSFTIX_POSTCONF_PATH()) then exit;
        inet_interfaces:=POSTFIX_EXTRACT_MAINCF('inet_interfaces');
        PostfixLogs.logsPostfix('POSFTIX_VERIFY_MAINCF:inet_interfaces=' + inet_interfaces);

        if length(inet_interfaces)=0 then begin
           PostfixLogs.logsPostfix('POSFTIX_VERIFY_MAINCF:inet_interfaces is null change to "inet_interfaces=all"');
           fpsystem(POSFTIX_POSTCONF_PATH() + ' -e "inet_interfaces=all"');
        end;
        
        if inet_interfaces=', localhost' then begin
           PostfixLogs.logsPostfix('POSFTIX_VERIFY_MAINCF:inet_interfaces is null change to "inet_interfaces=all"');
           fpsystem(POSFTIX_POSTCONF_PATH() +' -e "inet_interfaces=all"');
        end;
        
        if FileExists('/etc/postfix/bounce.template.cf') then fpsystem('/bin/chown root:root /etc/postfix/bounce.template.cf >/dev/null 2>&1');
        
        
        mailbox_transport:=POSTFIX_EXTRACT_MAINCF('mailbox_transport');
        PostfixLogs.logsPostfix('POSFTIX_VERIFY_MAINCF:mailbox_transport=' + mailbox_transport);
        if FileExists(CYRUS_DELIVER_BIN_PATH()) then begin
           if not CYRUS_enabled_in_master_cf() then begin
              PostfixLogs.logs('POSFTIX_VERIFY_MAINCF -> artica-install -reconfigure-master');
              fpsystem(ExtractFilePath(ParamStr(0)) + 'artica-install -reconfigure-master');
           end;
        end;
        


 PostfixLogs.Free;

end;
//#####################################################################################
function MyConf.POSTFIX_EXTRACT_MAINCF(key:string):string;
var
   List:TstringList;
   RegExpr:TRegExpr;
   i:integer;
begin
    list:=TstringList.Create;
    RegExpr:=TRegExpr.Create;
    
    RegExpr.Expression:='^' + key + '([=\s]+)(.+)';
    list.LoadFromFile(POSFTIX_MASTER_CF_PATH());
    For i:=0 to list.Count -1 do begin
         if RegExpr.Exec(list.Strings[i]) then begin
            result:=RegExpr.Match[2];
            break;
         end;
    end;
    RegExpr.Free;
    List.free;

end;
//#####################################################################################

procedure MyConf.POSTFIX_RELOAD_DAEMON();
var pid:string;
begin

pid:=POSTFIX_PID();
POSFTIX_VERIFY_MAINCF();

if SYSTEM_PROCESS_EXIST(pid) then begin
   if fileExists('/usr/sbin/postfix') then fpsystem('/usr/sbin/postfix reload >/dev/null 2>&1');
   if fileExists('/etc/init.d/postfix') then fpsystem('/etc/init.d/postfix reload >/dev/null 2>&1');
   end
   else begin
       if fileExists('/usr/sbin/postfix') then fpsystem('/usr/sbin/postfix start >/dev/null 2>&1');
       if fileExists('/etc/init.d/postfix') then fpsystem('/etc/init.d/postfix start >/dev/null 2>&1');
end;

end;
//#####################################################################################
function myConf.PERL_VERSION():string;
var
   version:string;
   RegExpr:TRegExpr;
begin
    if not FileExists(PERL_BIN_PATH()) then exit;
    RegExpr:=TRegExpr.Create;
    version:=ExecPipe(PERL_BIN_PATH()+' -v 2>&1');
    RegExpr.Expression:=' v([0-9\.]+)';
    if RegExpr.Exec(version) then result:=RegExpr.Match[1];
    RegExpr.free;
end;
//#####################################################################################�
function myConf.PERL_BIN_PATH():string;
begin
    if FileExists('/usr/local/bin/perl') then exit('/usr/local/bin/perl');
    if FileExists('/opt/artica/bin/perl') then exit('/opt/artica/bin/perl');
end;
//#################################################################################
function myConf.PERL_INCFolders():TstringList;
const
  CR = #$0d;
  LF = #$0a;
  CRLF = CR + LF;

var
    datas:string;
    F:TstringList;
    RegExpr:TRegExpr;
    L:TStringDynArray;
    i:integer;
begin
     datas:=ExecPipe('/opt/artica/bin/perl -V 2>&1');
     RegExpr:=TRegExpr.Create;

     RegExpr.Expression:='@INC:(.+)';
     if RegExpr.Exec(datas) then begin
        l:=Explode(CRLF,RegExpr.Match[1]);
        F:=TstringList.Create;
        
        For i:=0 to length(l)-1 do begin
            if length(trim(l[i]))>3 then F.Add(trim(l[i]));
        end;
     end;
   
   result:=F;
   if ParamStr(1)='@INC' then begin
        For i:=0 to F.Count -1 do begin
            writeln(F.Strings[i]);
        end;
   end;
   
end;

//#####################################################################################
procedure MyConf.POSTFIX_RESTART_DAEMON();
var pid:string;
begin
pid:=POSTFIX_PID();
POSFTIX_VERIFY_MAINCF();
if SYSTEM_PROCESS_EXIST(pid) then begin
   if fileExists('/usr/sbin/postfix') then fpsystem('/usr/sbin/postfix stop >/dev/null 2>&1 && /usr/sbin/postfix start >/dev/null 2>&1');
   if fileExists('/etc/init.d/postfix') then fpsystem('/etc/init.d/postfix stop >/dev/null 2>&1 && /etc/init.d/postfix start >/dev/null 2>&1');
   end
   else begin
       if fileExists('/usr/sbin/postfix') then fpsystem('/usr/sbin/postfix start >/dev/null 2>&1');
       if fileExists('/etc/init.d/postfix') then fpsystem('/etc/init.d/postfix start >/dev/null 2>&1');
end;

end;
//#####################################################################################


function MyConf.LDAP_ADDSCHEMA( schema:string):string;
var
RegExpr:TRegExpr;
RegExprD:TRegExpr;
 datas : TstringList;
 path:string;
 i:integer;
 sfound:boolean;
 schema_path,value:string;
begin
     path:=LDAP_GET_CONF_PATH();
     result:='';
     sfound:=False;
     datas:=Tstringlist.Create;
     datas.LoadFromFile(path);
     RegExpr:=TRegExpr.create;
     RegExprD:=TRegExpr.create;
     schema_path:=LDAP_GET_SCHEMA_PATH();
     RegExpr.expression:='include\s+' + schema_path + '/' +schema;
     RegExprD.expression:='#';
     value:='include' + chr(9) +  schema_path + '/' + schema;
     
 for i:=0 to datas.count-1 do begin
           if not RegExprD.Exec(datas.Strings[i]) then begin
                 if RegExpr.Exec(datas.Strings[i]) then begin
                      datas.Strings[i]:=value;
                      sfound:=True;
                      break;
                 end;

           end;
       end;
       if sfound=False then datas.Add(value);
       datas.SaveToFile(path);
       RegExprD.Free;
       RegExpr.Free;
       datas.Free;
       exit;
end;


//##############################################################################




function MyConf.LDAP_WRITE_VALUE_KEY( key:string;value:string):string;
var
RegExpr:TRegExpr;
RegExprD:TRegExpr;
 datas : TstringList;
 path:string;
 i:integer;
 sfound:boolean;
begin
     path:=LDAP_GET_CONF_PATH();
     result:='';
     sfound:=False;
     datas:=Tstringlist.Create;
     datas.LoadFromFile(path);
     RegExpr:=TRegExpr.create;
     RegExprD:=TRegExpr.create;

     RegExpr.expression:=key;
     RegExprD.expression:='#';

       for i:=0 to datas.count-1 do begin
           if not RegExprD.Exec(datas.Strings[i]) then begin
                 if RegExpr.Exec(datas.Strings[i]) then begin
                      datas.Strings[i]:=key + ' ' + value;
                      sfound:=True;
                      break;
                 end;

           end;
       end;
       if sfound=False then datas.Add(key+ ' ' + value);
       
       datas.SaveToFile(path);
       RegExprD.Free;
       RegExpr.Free;
       datas.Free;
       exit;

end;
//##############################################################################
function MyConf.LDAP_READ_ADMIN_NAME():string;
var
RegExpr:TRegExpr;
 datas :string;
 path:string;
begin
     path:=LDAP_GET_CONF_PATH();
     datas:=ReadFileIntoString(path);
     RegExpr:=TRegExpr.create;
     RegExpr.Expression:='rootdn[\s]+"cn=([a-zA-Z0-9\-_]+),';
     RegExpr.Exec(datas);
     result:=RegExpr.Match[1];
     RegExpr.Free;


end;
//##############################################################################



procedure MyConf.THREAD_COMMAND_SET(zcommands:string);
var  FileDataCommand:TstringList;
begin
  FileDataCommand:=TstringList.Create;
  if fileExists('/etc/artica-postfix/background') then FileDataCommand.LoadFromFile('/etc/artica-postfix/background');
  FileDataCommand.Add(zcommands);
  FileDataCommand.SaveToFile('/etc/artica-postfix/background');
  FileDataCommand.Free;
  
end;




function MyConf.get_LINUX_INET_INTERFACES():string;
var
 s:shortstring;
 f:text;
 p:LongInt;
 xInterfaces:string;
begin
 xInterfaces:='';
 assign(f,'/proc/net/dev');
 reset(f);
 while not eof(f) do begin
   readln(f,s);
   p:=pos(':',s);
   if ( p > 0 ) then begin
     delete(s, p, 255);
     while ( s <> '' ) and (s[1]=#32) do delete(s,1,1);
       if CheckInterface(s) then xInterfaces:=xInterfaces + ';'+ s + ':[' + GetIPAddressOfInterface(s) + ']';
   end;
 end;
 exit(xInterfaces);
 close(f);
 end;
//##############################################################################

function MyConf.POSTFIX_PID_PATH():string;
var queue:string;
begin
   if not FileExists(POSFTIX_POSTCONF_PATH()) then exit;
   fpsystem(POSFTIX_POSTCONF_PATH() + ' -h queue_directory >/opt/artica/logs/queue_directory');
   queue:=trim(ReadFileIntoString('/opt/artica/logs/queue_directory'));
   result:=queue+'/pid/master.pid';
end;
//##############################################################################
function MyConf.CYRUS_STATUS():string;
var path,pid,res,init:string;D:boolean;
begin
    D:=COMMANDLINE_PARAMETERS('debug');

   init:=CYRUS_GET_INITD_PATH();
   if length(init)=0 then begin
       if D then ShowScreen('CYRUS_STATUS:: no init.d path probably not installed');
       result:='-1;0.0.0;0';
       exit;
   end;
   res:='0';

   if FileExists('/var/run/cyrus-master.pid') then path:='/var/run/cyrus-master.pid';
   if FileExists('/var/run/cyrmaster.pid') then path:='/var/run/cyrmaster.pid';
   if FileExists('/var/run/cyrus.pid') then path:='/var/run/cyrus.pid';
   
   
   
   if D then ShowScreen('CYRUS_STATUS:: pid path is "' + path + '"');
   
   if length(path)=0 then begin
         if D then ShowScreen('CYRUS_STATUS:: No pid path, probably stopped...');
         result:='0;0.0.0;0';
         exit;
   end;
   res:='0';
   pid:=ReadFileIntoString(path);
   pid:=trim(pid);
   if length(pid)=0 then exit('0;' +   CYRUS_VERSION() + ';0');
   if FileExists('/proc/' + pid + '/exe') then res:='1' ;
   result:=res + ';' + CYRUS_VERSION() + ';' +pid


end;
//##############################################################################
function myConf.CYRUS_PID_PATH():string;
var  path:string;
begin
   if FileExists('/var/run/cyrus-master.pid') then path:='/var/run/cyrus-master.pid';
   if FileExists('/var/run/cyrmaster.pid') then path:='/var/run/cyrmaster.pid';
   if FileExists('/var/run/cyrus.pid') then path:='/var/run/cyrus.pid';
   result:=path;
end;
//##############################################################################

function MyConf.MAILGRAPGH_STATUS():string;
var pid,pid_path,status:string;D:boolean;
begin

   D:=COMMANDLINE_PARAMETERS('debug');
   if not FileExists('/etc/init.d/mailgraph-init') then begin
      if D then writeln('MAILGRAPGH_STATUS() -> /etc/init.d/mailgraph-init not installed...');
      status:='-1;0;0';
      exit(status);
      end else begin
          status:='0;'+MAILGRAPH_VERSION() +';0';
      end;
      

   pid_path:=MAILGRAPGH_PID_PATH();
   if D then writeln('MAILGRAPGH_STATUS() -> pid_path->' + pid_path);
   if length(pid_path)=0 then begin
      status:='-1;0;0';
      exit(status);
   end;

   pid:=ReadFileIntoString(pid_path);
   pid:=trim(pid);
   if FileExists('/proc/' + pid + '/exe') then status:='1' ;
   result:=status + ';' + MAILGRAPH_VERSION() + ';' +pid;
   exit(result);


end;
//##############################################################################
function MyConf.SYSTEM_NETWORK_INITD():string;
begin
if FileExists('/etc/init.d/networking') then exit('/etc/init.d/networking');
if FileExists('/etc/init.d/network') then exit('/etc/init.d/network');
logs.logs('SYSTEM_NETWORK_INITD:: unable to locate init.d daemon');
end;



//##############################################################################
function MyConf.MAILGRAPGH_PID_PATH():string;
var
   RegExpr:TRegExpr;
   list:TstringList;
   i:integer;
begin
if not FileExists('/etc/init.d/mailgraph-init') then exit('');
list:=TstringList.Create;
 RegExpr:=TRegExpr.create;
 RegExpr.Expression:='^PID_FILE[\s''"=]([a-z0-9\-\/\.]+)';
 list.LoadFromFile('/etc/init.d/mailgraph-init');
 for i:=0 to list.Count-1 do begin
     if RegExpr.Exec(list.Strings[i]) then begin
         result:=RegExpr.Match[1];
         RegExpr.free;
         list.free;
         exit;
     end;
 end;
end;
//##############################################################################
function MyConf.SYSTEM_CRON_TASKS():TstringList;
const
  CR = #$0d;
  LF = #$0a;
  CRLF = CR + LF;

var
   list:TstringList;
   LineDatas:string;
   i:integer;
   SYS:TSystem;
   D:boolean;
   C:boolean;
begin
   D:=COMMANDLINE_PARAMETERS('debug');
   C:=COMMANDLINE_PARAMETERS('list');
   SYS:=TSystem.Create;
   list:=TstringList.Create;
   list.AddStrings(SYS.DirFiles('/etc/cron.d','*'));
   ArrayList:=TstringList.Create;
    for i:=0 to list.Count-1 do begin
          if D then ShowScreen('SYSTEM_CRON_TASKS:: File [' + list.Strings[i] + ']');
          LineDatas:='<cron>' + CRLF  +'<filename>/etc/cron.d/' + list.Strings[i] + '</filename>' + CRLF + '<filedatas>' + ReadFileIntoString('/etc/cron.d/' + list.Strings[i])+CRLF + '</filedatas>' + CRLF + '</cron>';
           ArrayList.Add(LineDatas);
           if C then showscreen(CRLF+'------------------------------------------------------------' + CRLF+LineDatas+CRLF + '------------------------------------------------------------'+CRLF);
          
    end;
   Result:=ArrayList;
   list.free;
   SYS.free;
   
end;
//##############################################################################
function MyConf.FETCHMAIL_PID():string;
Var
   RegExpr:TRegExpr;
   list:TstringList;
   i:integer;
   PidPath:string;
   D:boolean;

begin
 D:=COMMANDLINE_PARAMETERS('debug');
  if not fileExists('/etc/init.d/fetchmail') then begin
      if D then writeln('FETCHMAIL_PID:: not fileExists=/etc/init.d/fetchmail assign it by default on /var/run/fetchmail.pid');
      result:=SYSTEM_GET_PID('/var/run/fetchmail.pid');
      exit;
  end;
  list:=TstringList.Create;
  list.LoadFromFile('/etc/init.d/fetchmail');
  RegExpr:=TRegExpr.Create;
  RegExpr.Expression:='PIDFILE="(.+?)"';
  for i:=0 to list.Count-1 do begin
       if RegExpr.Exec(list.Strings[i]) then begin
          PidPath:=RegExpr.Match[1];
          break;
       end;
  end;

  list.Free;
  if D then writeln('FETCHMAIL_PID:: PidPath=' + PidPath);
  RegExpr.Free;
  result:=SYSTEM_GET_PID(PidPath);
end;
//##############################################################################


function MyConf.FETCHMAIL_STATUS():string;
var res,version,firstStat:string;
d:boolean;
binpath,fetchmailpid:string;
begin

       binpath:=FETCHMAIL_BIN_PATH();
       d:=COMMANDLINE_PARAMETERS('debug');
       if d then ShowScreen('FETCHMAIL_STATUS::-> Reading /etc/init.d/fetchmail script');
       firstStat:='-1';
       
       if length(binpath)=0 then begin
          result:=firstStat+';0.0.0;0';
          exit;
       end;

       version:=FETCHMAIL_VERSION();
       if length(version)>0 then firstStat:='0';
       
       fetchmailpid:=FETCHMAIL_PID();
       if not SYSTEM_PROCESS_EXIST(fetchmailpid) then begin
          exit(firstStat+';' + version + ';0');
       end else begin
           res:='1' ;
           result:=res + ';' + version + ';' +fetchmailpid;
       end;
           if d then ShowScreen('FETCHMAIL_STATUS::Result -> was status;version;pid ->[' + result + ']');


end;




//##############################################################################
function MyConf.POSTFIX_STATUS():string;
var pid,mail_version:string;
begin
result:='-1;0.0.0;' ;
pid:=POSTFIX_PID();
if not FileExists('/etc/init.d/postfix') then exit;
if not FileExists(POSFTIX_POSTCONF_PATH()) then exit;

if FileExists('/proc/' + pid + '/exe') then result:='1' else result:='0';
mail_version:=trim(ExecPipe(POSFTIX_POSTCONF_PATH() + ' -h mail_version'));
result:=result + ';' + mail_version + ';' +pid
end;
//##############################################################################
function MyConf.CYRUS_IMAPD_SATUS():string;
var pid,mail_version:string;
begin
result:='-1;0.0.0;' ;
if not FileExists(CYRUS_DELIVER_BIN_PATH()) then exit();
pid:=CYRUS_PID();
if FileExists('/proc/' + pid + '/exe') then result:='1' else result:='0';
mail_version:=CYRUS_VERSION();
result:=result + ';' + mail_version + ';' +pid
end;
//##############################################################################
function MyConf.SYSTEM_IP_OVERINTERNET():string;
var
   F      :TstringList;
   RegExpr:TRegExpr;
begin
     result:='0.0.0.0';
     download_silent:=true;
     WGET_DOWNLOAD_FILE('http://checkip.dyndns.org/','/opt/artica/logs/dyndns.ip.org');
     if not FileExists('/opt/artica/logs/dyndns.ip.org') then exit;
     f:=TstringList.Create;
     f.LoadFromFile('/opt/artica/logs/dyndns.ip.org');
     RegExpr:=TRegExpr.Create;
     RegExpr.Expression:='([0-9\.]+)';
     if RegExpr.Exec(f.Text) then result:=trim(RegExpr.Match[1]);
     RegExpr.free;
     f.free;
     
     
end;
//##############################################################################


function MyConf.MYSQL_STATUS():string;
var mysql_init,pid_path,pid,status:string;
D:boolean;

begin
      D:=COMMANDLINE_PARAMETERS('debug');
      pid:='0';
      pid_path:=MYSQL_PID_PATH();
      pid:=SYSTEM_GET_PID(pid_path);
      mysql_init:=MYSQL_INIT_PATH();
      if D then logs.logs('pid_path=' + pid_path + ' mysql_init=' + mysql_init + ' pid=' + pid);
      if length(mysql_init)=0 then begin
         result:='-1;0;0';
      end else begin
          if length(pid_path)=0 then result:='-1;0;0';
          if length(pid)=0 then result:='0;' + MYSQL_VERSION() + ';0';
          if SYSTEM_PROCESS_EXIST(pid) then begin
              status:='1';
              end else begin
                  status:='0';
              end;
       end;
              
      result:=status + ';' + MYSQL_VERSION() + ';' +pid;
            if D then  logs.logs('Mysql result=' + result);

end;
//##############################################################################

function MyConf.MYSQL_PID_PATH():string;
var
   mycnf_path:string;
   RegExpr:TRegExpr;
   list:TstringList;
   i:integer;
   D:boolean;
begin
  D:=COMMANDLINE_PARAMETERS('debug');
  
  mycnf_path:=MYSQL_MYCNF_PATH();
  if D then ShowScreen('MYSQL_PID_PATH::mycnf_path->' + mycnf_path);
  if length(mycnf_path)=0 then exit('');
  list:=TstringList.create;
  list.LoadFromFile(mycnf_path);
  RegExpr:=TRegExpr.create;
  RegExpr.Expression:='pid-file[\s=]+([\/a-z\.A-Z0-9]+)';
  for i:=0 to list.Count-1 do begin
          if RegExpr.Exec(list.Strings[i]) then begin
                result:=RegExpr.Match[1];
                list.Free;
                RegExpr.Free;
                if D then ShowScreen('MYSQL_PID_PATH::success->' + result);
                exit;
          end;
  end;
  if D then ShowScreen('MYSQL_PID_PATH::failed->');
end;
//##############################################################################
function MyConf.SYSTEM_USER_LIST():string;
var RegExpr:TRegExpr;
list:TstringList;
i:integer;
D:boolean;
begin
   result:='';
   RegExpr:=TRegExpr.Create;
   list:=TstringList.Create;
   ArrayList:=TstringList.Create;
   list.LoadFromFile('/etc/shadow');
   if ParamStr(1)='-userslist' then D:=true;

   RegExpr.Expression:='([a-zA-Z0-9\.\-\_\s]+):';
   for i:=0 to list.Count-1 do begin
         if D then ShowScreen('USER:' + RegExpr.Match[1]);
         if RegExpr.Exec(trim(list.Strings[i])) then begin
             if length(trim(RegExpr.Match[1]))>0 then ArrayList.Add(RegExpr.Match[1]);
         end;
   
   
   end;
list.free;
RegExpr.free;
end;


//##############################################################################
procedure MyConf.AVESERVER_REPLICATE_kav4mailservers(mainfile:string);
var pid,ForwardMailer:string;
stat:integer;
begin
pid:=AVESERVER_GET_PID();
     if not FileExists('/etc/init.d/aveserver') then begin
        lOGS.logs('AVESERVER_REPLICATE_kav4mailservers:: unable to stat /etc/init.d/aveserver');
        exit;
     end;

     if FileExists('/proc/' + pid + '/exe') then stat:=1 else stat:=0;

     if fileExists(mainfile) then begin
        fpsystem('/bin/mv ' + mainfile + ' /etc/kav/5.5/kav4mailservers/kav4mailservers.conf');
        if FileExists('/etc/init.d/kas3') then begin
                 lOGS.logs('AVESERVER_REPLICATE_kav4mailservers:: Kaspersky anti-spam exists in this system..');
                 ForwardMailer:=AVESERVER_GET_VALUE('smtpscan.general','ForwardMailer');
                 if ForwardMailer<>'smtp:127.0.0.1:9025' then begin
                    AVESERVER_SET_VALUE('smtpscan.general','ForwardMailer','smtp:127.0.0.1:9025');
                    AVESERVER_SET_VALUE('smtpscan.general','Protocol','smtp');
                 end;
        end;
        LOGS.logs('AVESERVER_REPLICATE_kav4mailservers::  -> AVESERVER_REPLICATE_TEMPLATES()');
        AVESERVER_REPLICATE_TEMPLATES();

        if stat=0 then fpsystem('/etc/init.d/aveserver start 2>&1');
        if stat=1 then fpsystem('/etc/init.d/aveserver reload 2>&1');
     end
        else begin
          LOGS.logs('AVESERVER_REPLICATE_kav4mailservers::  -> ' + mainfile + ' does not exists');
     end;

end;


//##############################################################################
function MyConf.SYSTEM_CRON_REPLIC_CONFIGS():string;
var
CronTaskPath:string;
CronTaskkDelete:string;
FileToDelete:string;
list:TstringList;
i:integer;
D:boolean;
SYS:Tsystem;
FileCount:integer;
begin
     result:='';
     D:=COMMANDLINE_PARAMETERS('debug');
     if ParamStr(1)='-replic_cron'then D:=true;
     
     
    CronTaskPath:=get_ARTICA_PHP_PATH() + '/ressources/conf/cron';
    SYS:=Tsystem.Create;
    FileCount:=SYS.DirectoryCountFiles(CronTaskPath);
    if D then ShowScreen('SYSTEM_CRON_REPLIC_CONFIGS: ' + CronTaskPath + ' store ' + IntTOStr(FileCount) + ' files' );
    lOGS.logs('SYSTEM_CRON_REPLIC_CONFIGS:: ' + CronTaskPath + ' store ' + IntTOStr(FileCount) + ' files');
    if FileCount=0 then begin
       SYS.Free;
       exit;
    end;

 

 CronTaskkDelete:=CronTaskPath+ '/CrontaskToDelete';
 if FileExists(CronTaskkDelete) then begin
       list:=TstringList.Create;
       list.LoadFromFile(CronTaskkDelete);
       if D then ShowScreen('SYSTEM_CRON_REPLIC_CONFIGS: ' + IntToStr(list.Count) + ' files to delete');

       
       for i:=0 to list.Count -1 do begin
            FileToDelete:='/etc/cron.d/' + trim(list.Strings[i]);
             if D then ShowScreen('SYSTEM_CRON_REPLIC_CONFIGS: "'+ FileToDelete + '"');
             lOGS.logs('SYSTEM_CRON_REPLIC_CONFIGS:: Delete "'+ FileToDelete + '"');
             if fileExists(FileToDelete) then begin
                  if D then ShowScreen('SYSTEM_CRON_REPLIC_CONFIGS: delete: ' + FileToDelete );
                  fpsystem('/bin/rm ' + FileToDelete);
             end;
       end;
  if D then ShowScreen('SYSTEM_CRON_REPLIC_CONFIGS: delete: ' + CronTaskkDelete );
  fpsystem('/bin/rm ' + CronTaskkDelete);

 end;
  if FileExists(CronTaskPath + '/artica.cron.kasupdate') then fpsystem('/usr/local/ap-mailfilter3/bin/enable-updates.sh');

   fpsystem('/bin/mv '  + CronTaskPath + '/* ' + '/etc/cron.d/');
   fpsystem('/bin/chown root:root /etc/cron.d/* >/dev/null 2>&1');
   fpsystem('/etc/init.d/cron reload');
   if D then ShowScreen('SYSTEM_CRON_REPLIC_CONFIGS: Done...' );
  lOGS.logs('SYSTEM_CRON_REPLIC_CONFIGS:: Replicate cron task list done...');
end;
//##############################################################################
function MyConf.SYSTEM_DAEMONS_STATUS():TstringList;
var RegExpr:TRegExpr;
mstr:string;
list:TstringList;
i:integer;
D:boolean;
begin
  RegExpr:=TRegExpr.Create;
  list:=TstringList.Create;
  mstr:=KAS_STATUS();
  D:=COMMANDLINE_PARAMETERS('debug');
  
  
  RegExpr.Expression:='([0-9\-]+)-([0-9\-]+);([0-9\-]+)-([0-9\-]+);([0-9\-]+)-([0-9\-]+);([0-9\-]+)-([0-9\-]+)';
  if RegExpr.Exec(mstr) then begin
      list.Add('[APP_KAS3]');
      list.Add('ap-process-server='+RegExpr.Match[1]+ ';' +RegExpr.Match[2]);
      list.Add('ap-spfd='+RegExpr.Match[3]+ ';' +RegExpr.Match[4]);
      list.Add('kas-license='+RegExpr.Match[5]+ ';' +RegExpr.Match[6]);
      list.Add('kas-thttpd='+RegExpr.Match[7]+ ';' +RegExpr.Match[8]);
  end;
   list.Add('');
   mstr:=POSTFIX_STATUS();
   RegExpr.Expression:='([0-9\-]+);([0-9\.]+);([0-9\-]+)';
   if RegExpr.Exec(mstr) then begin
      list.Add('[APP_POSTFIX]');
      list.Add('postfix='+RegExpr.Match[3]+ ';' +RegExpr.Match[1]);
   end;



   list.Add('');
   mstr:=AVESERVER_STATUS();
   RegExpr.Expression:='([0-9\-]+);([0-9\.\sa-zA-Z]+);([0-9\-]+);([0-9\-]+)';
   if RegExpr.Exec(mstr) then begin
      list.Add('[APP_AVESERVER]');
      list.Add('aveserver='+RegExpr.Match[3]+ ';' +RegExpr.Match[1]);
//      list.Add('patternDate='+RegExpr.Match[4]);
   end;

   list.Add('');
   mstr:=FETCHMAIL_STATUS();
   if D then ShowScreen('SYSTEM_DAEMONS_STATUS:: FETCHMAIL=' + mstr);
   RegExpr.Expression:='([0-9\-]+);([0-9\.\sa-zA-Z]+);([0-9\-]+)';
   if RegExpr.Exec(mstr) then begin
      list.Add('[APP_FETCHMAIL]');
      list.Add('fetchmail='+RegExpr.Match[3]+ ';' +RegExpr.Match[1]);
   end;

   list.Add('');
   mstr:=CYRUS_STATUS();
   RegExpr.Expression:='([0-9\-]+);([0-9\.\sa-zA-Z]+);([0-9\-]+)';
   if RegExpr.Exec(mstr) then begin
      list.Add('[APP_CYRUS]');
      list.Add('cyrmaster='+RegExpr.Match[3]+ ';' +RegExpr.Match[1]);
   end;

   list.Add('');
   mstr:=MAILGRAPGH_STATUS();
   RegExpr.Expression:='([0-9\-]+);([0-9\.\sa-zA-Z]+);([0-9\-]+)';
   if RegExpr.Exec(mstr) then begin
      list.Add('[APP_MAILGRAPH]');
      list.Add('mailgraph='+RegExpr.Match[3]+ ';' +RegExpr.Match[1]);
   end;

   list.Add('');
   mstr:=MYSQL_STATUS();
   if D then ShowScreen('SYSTEM_DAEMONS_STATUS:: MYSQL_STATUS=' + mstr);
   RegExpr.Expression:='([0-9\-]+);([0-9\.\sa-zA-Z]+);([0-9\-]+)';
   if RegExpr.Exec(mstr) then begin
      list.Add('[APP_MYSQL]');
      list.Add('mysqld='+RegExpr.Match[3]+ ';' +RegExpr.Match[1]);
   end;



    if ParamStr(2)='all' then begin
          for i:=0 to list.Count-1 do begin
              ShowScreen(list.Strings[i]);

          end;

    end;

    RegExpr.free;
    exit(list);
    list.free;


end;
FUNCTION myConf.KAS_AP_PROCESS_SERVER_PID():string;
begin
  result:=SYSTEM_GET_PID('/usr/local/ap-mailfilter3/run/ap-process-server.pid');
end;
FUNCTION myConf.KAS_AP_SPF_PID():string;
begin
  result:=SYSTEM_GET_PID('/usr/local/ap-mailfilter3/run/ap-spfd.pid');
end;
FUNCTION myConf.KAS_LICENCE_PID():string;
begin
  result:=SYSTEM_GET_PID('/usr/local/ap-mailfilter3/run/kas-license.pid');
end;
FUNCTION myConf.KAS_THTTPD_PID():string;
begin
  result:=SYSTEM_GET_PID('/usr/local/ap-mailfilter3/run/kas-thttpd.pid');
end;
FUNCTION myConf.DANSGUARDIAN_PID():string;
var
  l:TstringList;
  RegExpr:TRegExpr;
  i:integer;
begin
  if FileExists('/opt/artica/sbin/dansguardian') then begin
     fpsystem('/opt/artica/sbin/dansguardian -s >/opt/artica/logs/dansgardian.pid.txt 2>&1');
  end;
  
  l:=TstringList.create;
  RegExpr:=TRegExpr.Create;
  RegExpr.expression:='([0-9]+)';
  l.LoadFromFile('/opt/artica/logs/dansgardian.pid.txt');
  for i:=0 to l.Count-1 do begin
       if RegExpr.Exec(l.Strings[i]) then begin
          result:=RegExpr.Match[1];
          break;
       end;
  end;
     
 RegExpr.Free;
 l.free;
 
end;

//##############################################################################
function MyConf.KAS_STATUS():string;
var
   pid,one,two,three,four:string;
begin
   pid:=KAS_AP_PROCESS_SERVER_PID();
   if length(pid)=0 then one:='0-0';
   if FileExists('/proc/' + pid + '/exe') then one:=pid+'-1' else one:=pid+'-0';
   
   pid:=KAS_AP_SPF_PID();
   if length(pid)=0 then two:='0-0';
   if FileExists('/proc/' + pid + '/exe') then two:=pid+'-1' else two:=pid+'-0';

   pid:=KAS_LICENCE_PID();
   if length(pid)=0 then three:='0-0';
   if FileExists('/proc/' + pid + '/exe') then three:=pid+'-1' else three:=pid+'-0';

   pid:=KAS_THTTPD_PID();
   if length(pid)=0 then four:='0-0';
   if FileExists('/proc/' + pid + '/exe') then four:=pid+'-1' else four:=pid+'-0';

   result:=one + ';' + two + ';' + three + ';' + four;
end;
//##############################################################################
function MyConf.AVESERVER_STATUS():string;
var pid:string;
begin
   pid:=AVESERVER_GET_PID();

   if length(pid)=0 then begin
       if FileExists('/etc/init.d/aveserver') then begin
          result:='0;'+ AVESERVER_GET_VERSION()+ ';0;0';
          exit;
       end;
       result:='-1;' + AVESERVER_GET_VERSION() + ';' + pid + ';' + AVESERVER_PATTERN_DATE();
       exit;
   end;
   if FileExists('/proc/' + pid + '/exe') then begin
      result:='1;' + AVESERVER_GET_VERSION() + ';' + pid + ';' + AVESERVER_PATTERN_DATE();
      exit;
   end;

end;
//##############################################################################
function MyConf.KAV4PROXY_PATTERN_DATE():string;
var
   BasesPath:string;
   xml:string;
   RegExpr:TRegExpr;
begin
//#UpdateDate="([0-9]+)\s+([0-9]+)"#
 BasesPath:=KAV4PROXY_GET_VALUE('path','BasesPath');
 if not FileExists(BasesPath + '/master.xml') then exit;
 xml:=ReadFileIntoString(BasesPath + '/master.xml');
 RegExpr:=TRegExpr.Create;
 RegExpr.Expression:='UpdateDate="([0-9]+)\s+([0-9]+)"';
 if RegExpr.Exec(xml) then begin

 //date --date "$dte 3 days 5 hours 10 sec ago"

    result:=RegExpr.Match[1] + ';' + RegExpr.Match[2];
 end;
 RegExpr.Free;
end;
//##############################################################################

function MyConf.AVESERVER_PATTERN_DATE():string;
var
   BasesPath:string;
   xml:string;
   RegExpr:TRegExpr;
begin
//#UpdateDate="([0-9]+)\s+([0-9]+)"#
 BasesPath:=AVESERVER_GET_VALUE('path','BasesPath');
 if not FileExists(BasesPath + '/master.xml') then exit;
 xml:=ReadFileIntoString(BasesPath + '/master.xml');
 RegExpr:=TRegExpr.Create;
 RegExpr.Expression:='UpdateDate="([0-9]+)\s+([0-9]+)"';
 if RegExpr.Exec(xml) then begin
 
 //date --date "$dte 3 days 5 hours 10 sec ago"
 
    result:=RegExpr.Match[1] + ';' + RegExpr.Match[2];
 end;
 RegExpr.Free;
end;
//##############################################################################
function MyConf.KAVMILTER_PATTERN_DATE():string;
var
   BasesPath:string;
   xml:string;
   RegExpr:TRegExpr;
begin
//#UpdateDate="([0-9]+)\s+([0-9]+)"#
 BasesPath:=KAVMILTER_GET_VALUE('path','BasesPath');
 if not FileExists(BasesPath + '/master.xml') then exit;
 xml:=ReadFileIntoString(BasesPath + '/master.xml');
 RegExpr:=TRegExpr.Create;
 RegExpr.Expression:='UpdateDate="([0-9]+)\s+([0-9]+)"';
 if RegExpr.Exec(xml) then begin

 //date --date "$dte 3 days 5 hours 10 sec ago"

    result:=RegExpr.Match[1] + ';' + RegExpr.Match[2];
 end;
 RegExpr.Free;
end;
//##############################################################################

procedure MyConf.SQUID_SET_CONFIG(key:string;value:string);
var
   tmp          :TstringList;
   RegExpr      :TRegExpr;
   Found        :boolean;
   i            :integer;
begin
 found:=false;
 if not FileExists(SQUID_CONFIG_PATH()) then exit;
 tmp:=TstringList.Create;
 tmp.LoadFromFile(SQUID_CONFIG_PATH());
 RegExpr:=TRegExpr.Create;
 RegExpr.Expression:='^' + key;
 
 for i:=0 to tmp.Count-1 do begin
       if RegExpr.Exec(tmp.Strings[i]) then begin
         found:=true;
         tmp.Strings[i]:=key + chr(9) + value;
         break;
       end;
 
 end;

 if not found then begin
     tmp.Add(key + chr(9) + value);
 
 end;
 tmp.SaveToFile(SQUID_CONFIG_PATH());
 tmp.free;

 RegExpr.Free;
end;
//##############################################################################
function MyConf.SQUID_GET_SINGLE_VALUE(key:string):string;
var
   RegExpr      :TRegExpr;
   tmp          :TstringList;
   i            :integer;
begin
     result:='';
     if not FileExists(SQUID_CONFIG_PATH()) then begin
        LOGS.logs('SQUID_GET_SINGLE_VALUE() -> unable to get squid.conf');
        exit;
     end;
   tmp:=TstringList.Create;
   tmp.LoadFromFile(SQUID_CONFIG_PATH());
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^' + key+'\s+(.+)';
   
   
 for i:=0 to tmp.Count-1 do begin
      if RegExpr.Exec(tmp.Strings[i]) then begin
         result:=trim(RegExpr.Match[1]);
         break;
      end;
 end;
    tmp.free;

end;



//##############################################################################
function myConf.SQUID_CONFIG_PATH():string;
begin
   if FileExists('/opt/artica/etc/squid.conf') then exit('/opt/artica/etc/squid.conf');
   if FileExists('/etc/squid/squid.conf') then exit('/etc/squid/squid.conf');
end;


procedure MyConf.ExecProcess(commandline:string);
var
  P: TProcess;
 begin

  P := TProcess.Create(nil);
  P.CommandLine := commandline  + ' &';
  if debug then LOGS.Logs('MyConf.ExecProcess -> ' + commandline);
  P.Execute;
  P.Free;
end;
//##############################################################################
procedure MyConf.MonShell(cmd:string;sh:boolean);
var
  AProcess: TProcess;
 begin
      if sh then cmd:='sh -c "' + cmd + '"';
 
      try
        AProcess := TProcess.Create(nil);
        AProcess.CommandLine := cmd;
        AProcess.Execute;
     finally
        AProcess.Free;
     end;
end;
//##############################################################################
function MyConf.ExecPipe(commandline:string):string;
const
  READ_BYTES = 2048;
  CR = #$0d;
  LF = #$0a;
  CRLF = CR + LF;

var
  S: TStringList;
  M: TMemoryStream;
  P: TProcess;
  n: LongInt;
  BytesRead: LongInt;
  xRes:string;

begin
  // writeln(commandline);
  if length(trim(commandline))=0 then exit;
  M := TMemoryStream.Create;
  xRes:='';
  BytesRead := 0;
  P := TProcess.Create(nil);
  P.CommandLine := commandline;
  P.Options := [poUsePipes];
  if debug then LOGS.Logs('MyConf.ExecPipe -> ' + commandline);

  P.Execute;
  while P.Running do begin
    M.SetSize(BytesRead + READ_BYTES);
    n := P.Output.Read((M.Memory + BytesRead)^, READ_BYTES);
    if n > 0 then begin
      Inc(BytesRead, n);
    end
    else begin
      Sleep(100);
    end;

  end;

  repeat
    M.SetSize(BytesRead + READ_BYTES);
    n := P.Output.Read((M.Memory + BytesRead)^, READ_BYTES);
    if n > 0 then begin
      Inc(BytesRead, n);
    end;
  until n <= 0;
  M.SetSize(BytesRead);
  S := TStringList.Create;
  S.LoadFromStream(M);
  if debug then LOGS.Logs('Tprocessinfos.ExecPipe -> ' + IntTostr(S.Count) + ' lines');
  for n := 0 to S.Count - 1 do
  begin
    if length(S[n])>1 then begin

      xRes:=xRes + S[n] +CRLF;
    end;
  end;
  if debug then LOGS.Logs('Tprocessinfos.ExecPipe -> exit');
  S.Free;
  P.Free;
  M.Free;
  exit( xRes);
end;
//##############################################################################
function MyConf.SYSTEM_PROCESS_MEMORY(PID:string):integer;
var
   S:string;
   RegExpr:TRegExpr;
   MA,MB,MC,ME,MF,MG,MT:Integer;
begin
     if not FileExists('/proc/' + trim(PID) + '/statm') then exit(0);
     S:=ReadFileIntoString('/proc/' + trim(PID) + '/statm');
     S:=trim(S);
     RegExpr:=TRegExpr.Create;
     RegExpr.Expression:='([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)';
     if RegExpr.Exec(S) then begin
        MA:=StrToInt(RegExpr.Match[1]);
        MB:=StrToInt(RegExpr.Match[2]);
        MC:=StrToInt(RegExpr.Match[3]);
        ME:=StrToInt(RegExpr.Match[4]);
        MF:=StrToInt(RegExpr.Match[5]);
        MG:=StrToInt(RegExpr.Match[6]);
        MT:=MA+MB+MC+ME+MF+MG;
        result:=MT div 1024;
     end;
end;
//##############################################################################
function MyConf.ExecStream(commandline:string;ShowOut:boolean):TMemoryStream;
const READ_BYTES=1024;
var
  M: TMemoryStream;
  P: TProcess;
  n: LongInt;
  BytesRead: LongInt;
begin
  commandline:=commandline + ' 2>&1';
  M := TMemoryStream.Create;
  BytesRead := 0;
  P := TProcess.Create(nil);
  P.CommandLine := commandline;
  P.Options := [poUsePipes];
  if ShowOut then WriteLn('-- executing ' + commandline + ' --');
  if debug then LOGS.Logs('Tprocessinfos.ExecPipe -> ' + commandline);
  TRY
     P.Execute;
     while P.Running do begin
           M.SetSize(BytesRead + READ_BYTES);
           n := P.Output.Read((M.Memory + BytesRead)^, READ_BYTES);
           if n > 0 then begin
              Inc(BytesRead, n);
              end else begin
              Sleep(100);
           end;
     end;
  EXCEPT
        P.Free;
        exit;
  end;
  

  repeat
    M.SetSize(BytesRead + READ_BYTES);
    n := P.Output.Read((M.Memory + BytesRead)^, READ_BYTES);
    if n > 0 then begin
      Inc(BytesRead, n);
    end;
  until n <= 0;
  M.SetSize(BytesRead);
  exit(M);
end;

//##############################################################################
function MyConf.LINUX_REPOSITORIES_INFOS(inikey:string):string;
var ConfFile:string;
ini:TiniFile;
begin

  ConfFile:=LINUX_CONFIG_INFOS();
  if length(ConfFile)=0 then exit;
  ini:=TIniFile.Create(ConfFile);
  result:=ini.ReadString('REPOSITORIES',inikey,'');
  ini.Free;
end;

//##############################################################################
function MyConf.LINUX_APPLICATION_INFOS(inikey:string):string;
var ConfFile:string;
ini:TiniFile;
begin

  ConfFile:=LINUX_CONFIG_INFOS();
  if length(ConfFile)=0 then exit;
  ini:=TIniFile.Create(ConfFile);
  result:=ini.ReadString('APPLICATIONS',inikey,'');
  ini.Free;
end;
//##############################################################################
function MyConf.LINUX_CONFIG_PATH():string;
var
   Distri,path,fullPath:string;
   D:Boolean;
begin
   D:=false;
   D:=COMMANDLINE_PARAMETERS('debug');
   Distri:=LINUX_DISTRIBUTION();
   if D then writeln('LINUX_CONFIG_PATH ->LINUX_DISTRIBUTION=' + Distri);
   path:=ExtractFileDir(ParamStr(0));
   fullPath:=path + '/install/distributions/' + Distri;
   if D then writeln('LINUX_CONFIG_PATH is path ? (' + fullPath + ')');
   if not DirectoryExists(fullpath) then begin
      writeln('Unable to locate necessary folder:"' + fullPath + '"');
      exit();
   end;
   result:=fullpath;
end;
//##############################################################################
function MyConf.LINUX_CONFIG_INFOS():string;
var
   Distri,path,fullPath,include:string;
   sini:TiniFile;

begin
   Distri:=LINUX_DISTRIBUTION();
   path:=ExtractFileDir(ParamStr(0));
   fullPath:=path + '/install/distributions/' + Distri + '/infos.conf';
   if not FileExists(fullpath) then begin
      writeln('Unable to locate necessary file:"' + fullPath + '"');
      exit();
   end;
    sini:=TiniFile.Create(fullPath);
    include:=sini.ReadString('INCLUDE','config','');
    sini.Free;
    if length(include)>0 then begin
          fullPath:=path + '/install/distributions/' + include + '/infos.conf';
          if not FileExists(fullpath) then begin
             writeln('Unable to locate include file:"' + fullPath + '"');
             exit();
          end;
    
    end;

   
   
   result:=fullpath;
end;
//##############################################################################
function Myconf.SYSTEM_DAEMONS_STOP_START(APPS:string;mode:string;return_string:boolean):string;
var commandline:string;log:Tlogs;
begin
     if APPS='APP_POSTFIX' then commandline:='/etc/init.d/postfix '+mode;
     if APPS='APP_AVESERVER' then CommandLine:='/etc/init.d/aveserver '+mode;
     if APPS='APP_KAS3' then CommandLine:='/etc/init.d/kas3 ' +mode;
     if APPS='APP_FETCHMAIL' then CommandLine:='/etc/init.d/fetchmail ' +mode;
     if APPS='APP_CYRUS' then CommandLine:=CYRUS_GET_INITD_PATH() + ' '+mode;
     if APPS='APP_MAILGRAPH' then CommandLine:='/etc/init.d/mailgraph-init ' + mode;
     if APPS='APP_MYSQL' then CommandLine:=MYSQL_INIT_PATH() + ' '+mode;
     if return_string=true then exit(CommandLine);
     log:=Tlogs.Create;
     log.logs('SYSTEM_DAEMONS_STOP_START::Perform operation ' + CommandLine);
     fpsystem(CommandLine);
     
end;
//##############################################################################
function MyConf.CRON_CREATE_SCHEDULE(ProgrammedTime:string;Croncommand:string;name:string):boolean;
 var FileDatas:TstringList;
begin
  result:=true;
  FileDatas:=TstringList.Create;
  FileDatas.Add(ProgrammedTime + ' ' + ' root ' + Croncommand + ' >/dev/null');
  ShowScreen('CRON_CREATE_SCHEDULE:: saving /etc/cron.d/artica.'+name + '.scheduled');
  FileDatas.SaveToFile('/etc/cron.d/artica.'+name + '.scheduled');
  FileDatas.free;
  

end;




function MyConf.LINUX_INSTALL_INFOS(inikey:string):string;
var ConfFile:string;
ini:TiniFile;
D:boolean;
begin
  D:=COMMANDLINE_PARAMETERS('debug');
  ConfFile:=LINUX_CONFIG_INFOS();
  if D then ShowScreen('LINUX_INSTALL_INFOS:: ConfFile="' + ConfFile + '"');
  
  if length(ConfFile)=0 then begin
     ShowScreen('LINUX_INSTALL_INFOS(' + inikey + ') unable to get configuration file path');
     exit;
  end;
  ini:=TIniFile.Create(ConfFile);
  result:=ini.ReadString('INSTALL',inikey,'');
  if length(result)=0 then ShowScreen('LINUX_INSTALL_INFOS([INSTALL]::' + inikey + ') this key has no datas');
  ini.Free;
  exit(result);
end;
//##############################################################################
function MyConf.LINUX_LDAP_INFOS(inikey:string):string;
var ConfFile:string;
ini:TiniFile;
begin

  ConfFile:=LINUX_CONFIG_INFOS();
  if length(ConfFile)=0 then begin
     writeln('LINUX_LDAP_INFOS(' + inikey + ') unable to get configuration file path');
     exit;
  end;
  ini:=TIniFile.Create(ConfFile);
  result:=ini.ReadString('LDAP',inikey,'');
  ini.Free;
  exit(result);
end;
//##############################################################################


//##############################################################################
function MyConf.LINUX_DISTRIBUTION():string;
var
   RegExpr:TRegExpr;
   FileTMP:TstringList;
   Filedatas:TstringList;
   i:integer;
   distri_name,distri_ver,distri_provider:string;
   D:boolean;
begin
  D:=COMMANDLINE_PARAMETERS('debug');
  RegExpr:=TRegExpr.Create;
  if FileExists('/etc/lsb-release') then begin
      if not FileExists('/etc/redhat-release') then begin
             if D then Writeln('/etc/lsb-release detected (not /etc/redhat-release detected)');
             fpsystem('/bin/cp /etc/lsb-release /opt/artica/logs/lsb-release');
             FileTMP:=TstringList.Create;
             FileTMP.LoadFromFile('/opt/artica/logs/lsb-release');
             for i:=0 to  FileTMP.Count-1 do begin
                 RegExpr.Expression:='DISTRIB_ID=(.+)';
                 if RegExpr.Exec(FileTMP.Strings[i]) then distri_provider:=trim(RegExpr.Match[1]);
                 RegExpr.Expression:='DISTRIB_RELEASE=([0-9\.]+)';
                 if RegExpr.Exec(FileTMP.Strings[i]) then distri_ver:=trim(RegExpr.Match[1]);
                 RegExpr.Expression:='DISTRIB_CODENAME=(.+)';
                 if RegExpr.Exec(FileTMP.Strings[i]) then distri_name:=trim(RegExpr.Match[1]);
             end;


             result:=distri_provider + ' ' +  distri_ver + ' ' +  distri_name;
             RegExpr.Free;
             FileTMP.Free;
             exit();
      end;
  end;
  Filedatas:=TstringList.Create;
  if FileExists('/etc/debian_version') then begin
       if D then Writeln('/etc/debian_version detected');
       Filedatas:=TstringList.Create;
       Filedatas.LoadFromFile('/etc/debian_version');
       RegExpr.Expression:='([0-9\.]+)';
       if RegExpr.Exec(Filedatas.Strings[0]) then begin
          result:='Debian ' + RegExpr.Match[1] +' Gnu-linux';
          RegExpr.Free;
          Filedatas.Free;
          exit();
       end;
  end;
  //Fedora
  if FileExists('/etc/redhat-release') then begin
     Filedatas:=TstringList.Create;
     Filedatas.LoadFromFile('/etc/redhat-release');
     if D then Writeln('/etc/redhat-release detected -> ' + Filedatas.Strings[0]);
     
     RegExpr.Expression:='Fedora Core release\s+([0-9]+)';
     if RegExpr.Exec(Filedatas.Strings[0]) then begin
          result:='Fedora Core release ' + RegExpr.Match[1];
          RegExpr.Free;
          Filedatas.Free;
          exit();
       end;
      RegExpr.Expression:='Fedora release\s+([0-9]+)';
      if RegExpr.Exec(Filedatas.Strings[0]) then begin
         result:='Fedora release ' + RegExpr.Match[1];
         RegExpr.Free;
         Filedatas.Free;
         exit();
      end;
      
      //Mandriva
      RegExpr.Expression:='Mandriva Linux release\s+([0-9]+)';
      if RegExpr.Exec(Filedatas.Strings[0]) then begin
         result:='Mandriva Linux release ' + RegExpr.Match[1];
         RegExpr.Free;
         Filedatas.Free;
         exit();
      end;
      //CentOS
      RegExpr.Expression:='CentOS release\s+([0-9]+)';
      if RegExpr.Exec(Filedatas.Strings[0]) then begin
         result:='CentOS release ' + RegExpr.Match[1];
         RegExpr.Free;
         Filedatas.Free;
         exit();
      end;
       
    end;
    
   //Suse
   if FileExists('/etc/SuSE-release') then begin
       Filedatas:=TstringList.Create;
       Filedatas.LoadFromFile('/etc/SuSE-release');
       result:=trim(Filedatas.Strings[0]);
       Filedatas.Free;
       exit;
   end;
    
    

end;
//##############################################################################
procedure MyConf.ShowScreen(line:string);
 begin
   writeln(line);
    logs.logs('MYCONF::' + line);
 END;
//##############################################################################
function MyConf.SYSTEM_KERNEL_VERSION():string;
begin
    exit(ExecPipe('/bin/uname -r'));
end;
//##############################################################################
function MyConf.SYSTEM_LIBC_VERSION():string;
var
   head,returned,command:string;
   D:boolean;
   RegExpr:TRegExpr;
begin
///lib/libc.so.6 | /usr/bin/head -1

     D:=COMMANDLINE_PARAMETERS('debug');
     if FileExists('/usr/bin/head') then head:='/usr/bin/head';
     if length(head)=0 then begin
        if D then ShowScreen('SYSTEM_LIBC_VERSION:: unable to locate head tool');
        exit;
     end;

     if not fileExists('/lib/libc.so.6') then begin
        if D then ShowScreen('SYSTEM_LIBC_VERSION:: unable to stat /lib/libc.so.6');
        exit;
     end;
 command:='/lib/libc.so.6 | ' + head + ' -1';
 if D then ShowScreen('SYSTEM_LIBC_VERSION:: command="'+ command + '"');
 returned:=ExecPipe('/lib/libc.so.6 | ' + head + ' -1');
 if D then ShowScreen('SYSTEM_LIBC_VERSION:: returned="'+ returned + '"');
 RegExpr:=TRegExpr.Create;
 RegExpr.Expression:='version ([0-9\.]+)';
 if RegExpr.Exec(returned) then SYSTEM_LIBC_VERSION:=RegExpr.Match[1] else begin
      if D then ShowScreen('SYSTEM_LIBC_VERSION:: unable to match pattern');
      exit;
      end;
end;
 
//##############################################################################
function MyConf.SYSTEM_NETWORK_LIST_NICS():string;
var
   list:TStringList;
   RegExpr,RegExprH,RegExprF,RegExprG:TRegExpr;
   i:integer;
   D,A:boolean;
begin
   result:='';
   A:=false;
   D:=COMMANDLINE_PARAMETERS('debug');
   if ParamStr(1)='-nics' then A:=true;

   list:=TStringList.Create;
   ArrayList:=TStringList.Create;
   fpsystem('/sbin/ifconfig -a >/opt/artica/logs/ifconfig.a');
   
   list.LoadFromFile('/opt/artica/logs/ifconfig.a');
   logs.logs('SYSTEM_NETWORK_LIST_NICS:: include ' +INtToStr(list.Count) + ' parameters' );
      RegExpr:=TRegExpr.Create;
      RegExprH:=TRegExpr.Create;
      RegExprG:=TRegExpr.Create;
      RegExprF:=TRegExpr.Create;
      RegExpr.Expression:='^([a-z0-9\:]+)\s+';
      RegExprF.Expression:='^vmnet([0-9\:]+)';
      RegExprG.Expression:='^sit([0-9\:]+)';
      RegExprH.Expression:='^([a-zA-Z0-9]+):avah';

      for i:=0 to list.Count -1 do begin
        if D then ShowScreen('SYSTEM_NETWORK_LIST_NICS::"'+ list.Strings[i] + '"');
        if RegExpr.Exec(list.Strings[i]) then begin
           if not RegExprF.Exec(RegExpr.Match[1]) then begin
              if not RegExprH.Exec(RegExpr.Match[1]) then begin
                 if not RegExprG.Exec(RegExpr.Match[1]) then begin
                    if RegExpr.Match[1]<>'lo' then begin
                       if D then ShowScreen('SYSTEM_NETWORK_LIST_NICS:: ^([a-z0-9\:]+)\s+=>"'+ list.Strings[i] + '"');
                       ArrayList.Add(RegExpr.Match[1]);
                       if A then writeln(RegExpr.Match[1]);
                    end;
                 end;
              end;
           end;
        end;
   end;
   
    List.Free;
    RegExpr.free;
    RegExprF.free;
    RegExprH.free;
    RegExprG.free;

end;
 
//##############################################################################
function MyConf.SYSTEM_NETWORK_INFO_NIC(nicname:string):string;
var      D:boolean;
begin
    result:='';
     D:=COMMANDLINE_PARAMETERS('debug');
     if FileExists('/etc/network/interfaces') then begin
         if D then ShowScreen('SYSTEM_NETWORK_INFO_NIC :: Debian system');
         SYSTEM_NETWORK_INFO_NIC_DEBIAN(nicname);
         exit;
     end;
     
     if DirectoryExists('/etc/sysconfig/network-scripts') then begin
      if D then ShowScreen('SYSTEM_NETWORK_INFO_NIC :: redhat system');
      SYSTEM_NETWORK_INFO_NIC_REDHAT(nicname);
      exit;
     end;
      

end;
//##############################################################################
function MyConf.SYSTEM_NETWORK_INFO_NIC_REDHAT(nicname:string):string;
var
   CatchList:TstringList;
   list:Tstringlist;
   i:Integer;
begin
  result:='';
  CatchList:=TStringList.create;
  CatchList.Add('METHOD=redhat');
  list:=TStringList.Create;
  if fileExists('/etc/sysconfig/network-scripts/ifcfg-' + nicname) then begin
        list.LoadFromFile('/etc/sysconfig/network-scripts/ifcfg-' + nicname);
        for i:=0 to list.Count-1 do begin
             CatchList.Add(list.Strings[i]);
        
        end;
  
  end;
 ArrayList:=TStringList.create;
 for i:=0 to CatchList.Count-1 do begin
         if ParamStr(1)='-nic-info' then  writeln(CatchList.Strings[i]);
          ArrayList.Add(CatchList.Strings[i]);
    end;
  CatchList.free;
  list.free;


end;

//##############################################################################
function MyConf.SYSTEM_NETWORK_IFCONFIG():string;
         const
            CR = #$0d;
            LF = #$0a;
            CRLF = CR + LF;

var
   D:boolean;
   resultats:string;
   i:integer;
begin
 SYSTEM_NETWORK_LIST_NICS();
 D:=COMMANDLINE_PARAMETERS('debug');
 resultats:='';
 
 for i:=0 to ArrayList.Count-1 do begin
    if D then ShowScreen('SYSTEM_NETWORK_IFCONFIG:: Parse ' + ArrayList.Strings[i]);
       resultats:=resultats + '[' + ArrayList.Strings[i] + ']'+CRLF;
       resultats:=resultats + SYSTEM_NETWORK_IFCONFIG_ETH(ArrayList.Strings[i]) + CRLF;
 end;
   exit(resultats);

end;
//#############################################################################
function MyConf.SYSTEM_ALL_IPS():string;
var
   A,D:boolean;
   LIST:TstringList;
   i:integer;
   RegExpr:TRegExpr;
   LINE:String;

begin
   A:=False;
   D:=False;
   D:=COMMANDLINE_PARAMETERS('debug');
   result:='';
   if ParamStr(1)='-allips' then A:=True;
   LIST:=TstringList.Create;
   ArrayList:=TstringList.Create;


   list.LoadFromStream(ExecStream('/sbin/ifconfig -a',false));
   if D then ShowScreen('SYSTEM_ALL_IPS:: return '+ IntToStr(list.Count) + ' lines');
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='inet (adr|addr):([0-9\.]+)';
   for i:=0 to list.Count-1 do begin
           if RegExpr.Exec(list.Strings[i]) then begin
              LINE:=RegExpr.Match[2];
              IF A then writeln(LINE);
              ArrayList.Add(LINE);
           end;
    end;
    RegExpr.free;
    LIST.Free;
end;
//#############################################################################
function MyConf.SYSTEM_PROCESS_PS():string;
var
   A,D:boolean;
   LIST:TstringList;
   i:integer;
   RegExpr:TRegExpr;
   LINE:String;

begin
   result:='';
   A:=False;
   D:=False;
   D:=COMMANDLINE_PARAMETERS('debug');
   if ParamStr(1)='-ps' then A:=True;
   LIST:=TstringList.Create;
   ArrayList:=TstringList.Create;
   
   
   list.LoadFromStream(ExecStream('/bin/ps --no-heading -eo user:80,pid,pcpu,vsz,nice,etime,time,stime,args',false));
   if D then ShowScreen('SYSTEM_PROCESS_PS:: return '+ IntToStr(list.Count) + ' lines');
   RegExpr:=TRegExpr.Create;
   RegExpr.expression:='^(.+?)\s+(.+?)\s+(.+?)\s+(.+?)\s+(.+?)\s+(.+?)\s+(.+?)\s+(.+?)\s+(.+)';
   for i:=0 to list.Count-1 do begin
           if RegExpr.Exec(list.Strings[i]) then begin
              LINE:=RegExpr.Match[1]+';'+RegExpr.Match[2]+';'+RegExpr.Match[3]+';'+RegExpr.Match[4]+';'+RegExpr.Match[5]+';'+RegExpr.Match[6]+';'+RegExpr.Match[7]+';'+RegExpr.Match[8]+';'+RegExpr.Match[9] + ';'+SYSTEM_PROCESS_INFO(RegExpr.Match[2]);
              IF A then writeln(LINE);
              ArrayList.Add(LINE);
           end;
    end;
    RegExpr.free;
    LIST.Free;
end;



//#############################################################################
function MyConf.SYSTEM_PROCESS_INFO(PID:string):string;
var
   LIST:TstringList;
   i:integer;
   RegExpr:TRegExpr;
   Resultats:string;
begin
 Resultats:='';
 if not FileExists('/proc/' + trim(PID) + '/status') then exit;
 LIST:=TstringList.Create;
 LIST.LoadFromFile('/proc/' + trim(PID) + '/status');
   RegExpr:=TRegExpr.Create;
   RegExpr.expression:='(.+?):\s+(.+)';
 for i:=0 to list.Count-1 do begin
     if RegExpr.Exec(list.Strings[i]) then begin
       Resultats:=Resultats +trim(RegExpr.Match[1])+'=' + trim(RegExpr.Match[2])+',';
     end;
 end;
     RegExpr.free;
    LIST.Free;
 exit(resultats);
end;
//#############################################################################

function MyConf.SYSTEM_NETWORK_IFCONFIG_ETH(ETH:string):string;
         const
            CR = #$0d;
            LF = #$0a;
            CRLF = CR + LF;

var
   D:boolean;
   RegExpr:TRegExpr;
   list:Tstringlist;
   resultats:string;
   i:integer;
begin
 D:=COMMANDLINE_PARAMETERS('debug');
 list:=TstringList.Create;
 list.LoadFromStream(ExecStream('/sbin/ifconfig -a ' + ETH,false));
 RegExpr:=TRegExpr.Create;
 resultats:='';
 for i:=0 to list.Count-1 do begin
    if D then ShowScreen('SYSTEM_NETWORK_IFCONFIG_ETH:: '+ ETH + 'parse '  + list.Strings[i]);
    RegExpr.Expression:='HWaddr\s+([0-9A-Z]{1,2}:[0-9A-Z]{1,2}:[0-9A-Z]{1,2}:[0-9A-Z]{1,2}:[0-9A-Z]{1,2}:[0-9A-Z]{1,2})';
    if RegExpr.Exec(list.Strings[i]) then resultats:=resultats + 'MAC='+ RegExpr.Match[1] + CRLF;
    
    RegExpr.Expression:='(Masque|Mask):([0-9\.]+)';
    if RegExpr.Exec(list.Strings[i]) then resultats:=resultats + 'NETMASK='+ RegExpr.Match[2] + CRLF;
    
    RegExpr.Expression:='inet (adr|addr):([0-9\.]+)';
    if RegExpr.Exec(list.Strings[i]) then resultats:=resultats + 'IPADDR='+ RegExpr.Match[2] + CRLF;
    
 end;
 if not FileExists('/usr/sbin/ethtool') then ShowScreen('SYSTEM_NETWORK_IFCONFIG_ETH:: unable to stat /usr/sbin/ethtool');
 list.LoadFromStream(ExecStream('/usr/sbin/ethtool ' + ETH,false));
 if D then ShowScreen('SYSTEM_NETWORK_IFCONFIG_ETH:: ' + ETH + ' ethtool report ' + IntToStr(list.Count) + ' lines');
 RegExpr.Expression:='\s+([a-zA-Z0-9\s+]+):\s+(.+)';
  for i:=0 to list.Count-1 do begin
       if RegExpr.Exec(list.Strings[i]) then resultats:= resultats+ RegExpr.Match[1] + '='+ RegExpr.Match[2] + CRLF;
  end;

 exit(resultats);
end;
//#############################################################################
function MyConf.SYSTEM_NETWORK_RECONFIGURE():string;
var
    D:boolean;
    list:Tstringlist;
    i:integer;
begin
   D:=COMMANDLINE_PARAMETERS('debug');
   result:='';
   if FileExists('/etc/network/interfaces') then begin
        if D Then ShowScreen('SYSTEM_NETWORK_RECONFIGURE:: SYSTEM DEBIAN');
        if not FileExists(get_ARTICA_PHP_PATH() + '/ressources/conf/debian.interfaces') then begin
              if D Then ShowScreen('SYSTEM_NETWORK_RECONFIGURE:: WARNING !!! unable to stat ' + get_ARTICA_PHP_PATH() + '/ressources/conf/debian.interfaces');
        end;
        
        fpsystem('/bin/mv  ' + get_ARTICA_PHP_PATH() + '/ressources/conf/debian.interfaces /etc/network/interfaces');
        fpsystem('/etc/init.d/networking force-reload');
        
   end;
   
   if DirectoryExists('/etc/sysconfig/network-scripts') then begin
      if D Then ShowScreen('SYSTEM_NETWORK_RECONFIGURE:: SYSTEM REDHAT');
      if not FileExists(get_ARTICA_PHP_PATH() + '/ressources/conf/eth.list') then begin
         if D Then ShowScreen('SYSTEM_NETWORK_RECONFIGURE:: WARNING !! unable to stat "'+ get_ARTICA_PHP_PATH() + '/ressources/conf/eth.list"');
      end;
      
      list:=Tstringlist.Create;
      List.LoadFromFile(get_ARTICA_PHP_PATH() + '/ressources/conf/eth.list');
      for i:=0 to list.Count-1 do begin
           if D Then ShowScreen('SYSTEM_NETWORK_RECONFIGURE:: -> Modifyl/add ' +list.Strings[i]);
           fpsystem('/bin/mv ' + get_ARTICA_PHP_PATH() + '/ressources/conf/' + list.Strings[i] + ' /etc/sysconfig/network-scripts/');
      
      end;
      fpsystem('/bin/rm ' + get_ARTICA_PHP_PATH() + '/ressources/conf/eth.list');
      
      if FileExists(get_ARTICA_PHP_PATH() + '/ressources/conf/eth.del') then begin
          List.LoadFromFile(get_ARTICA_PHP_PATH() + '/ressources/conf/eth.del');
         for i:=0 to list.Count-1 do begin
             if D Then ShowScreen('SYSTEM_NETWORK_RECONFIGURE:: -> Delete ' +list.Strings[i]);
             if FileExists('/etc/sysconfig/network-scripts/' + list.Strings[i]) then fpsystem('/bin/rm /etc/sysconfig/network-scripts/' + list.Strings[i]);
         end;
         fpsystem('/bin/rm ' + get_ARTICA_PHP_PATH() + '/ressources/conf/eth.del');
      end;
      

      fpsystem('/etc/init.d/network restart');
   end;
   
end;
//#############################################################################




function MyConf.SYSTEM_NETWORK_INFO_NIC_DEBIAN(nicname:string):string;
var
   D,A:boolean;
   RegExpr:TRegExpr;
   RegExprEnd:TRegExpr;
   RegExprValues:TRegExpr;
   list:Tstringlist;
   CatchList:TstringList;
   expression,key:string;
   i:integer;
begin
        D:=COMMANDLINE_PARAMETERS('debug');
        list:=TStringList.Create;
        CatchList:=TStringList.create;
        RegExprValues:=TRegExpr.Create;
        ArrayList:=TStringList.create;
        result:='';
        RegExpr:=TRegExpr.Create;
        RegExprEnd:=TRegExpr.Create;
        expression:='iface\s+'+nicname+'\s+inet\s+(static|dhcp)';
        RegExprEnd.Expression:='^iface';
        RegExprValues.Expression:='^([a-zA-Z\-\_0-9\:]+)\s+(.+)';
        RegExpr.Expression:=expression;

        list.LoadFromFile('/etc/network/interfaces');
        A:=false;
        for i:=0 to list.Count -1 do begin
           if RegExpr.Exec(list.Strings[i]) then begin
              A:=true;
              if D then ShowScreen('SYSTEM_NETWORK_INFO_NIC_DEBIAN:: detect ' + expression + '=' + list.Strings[i] + ' "' + RegExpr.Match[1] +'"');
              list.Strings[i]:='';
              CatchList.Add('BOOTPROTO=' +  RegExpr.Match[1]);
              CatchList.Add('METHOD=debian');
              CatchList.Add('DEVICE='+nicname);
           
           end;
           
           if A=true then begin
              if not RegExprEnd.Exec(list.Strings[i]) then begin
                 if length(trim(list.Strings[i]))>0 then begin
                    if RegExprValues.Exec(list.Strings[i]) then begin
                       key:=RegExprValues.Match[1];
                       if key='address' then key:='IPADDR';
                       if key='netmask' then key:='NETMASK';
                       if key='gateway' then key:='GATEWAY';
                       if key='broadcast' then key:='BROADCAST';
                       if key='network' then key:='NETWORK';
                       if key='metric' then key:='METRIC';
                       CatchList.Add(key + '=' + RegExprValues.Match[2]);
                    end;
                 end;
                 end else begin
                  break;
              end;
           end;
           
        
        end;
    for i:=0 to CatchList.Count-1 do begin
         if ParamStr(1)='-nic-infos' then  writeln(CatchList.Strings[i]);
          ArrayList.Add(CatchList.Strings[i]);
    end;
    RegExpr.free;
    RegExprEnd.free;
    RegExprValues.free;
    
    CatchList.free;
    list.free;

end;
//##############################################################################


function MyConf.SYSTEM_GET_ALL_LOCAL_IP():string;
var
   list:TStringList;
   hash: THashStringList;
   RegExpr:TRegExpr;
   i:integer;
   D:boolean;
   virgule:string;
begin

   result:='';
   D:=COMMANDLINE_PARAMETERS('debug');
   list:=TStringList.Create;
   list.LoadFromStream(ExecStream('/sbin/ifconfig -a',false));
   hash:=  THashStringList.Create;
   for i:=1 to list.Count -1 do begin
      RegExpr:=TRegExpr.Create;
      RegExpr.Expression:='^([a-z0-9\:]+)\s+';
      if RegExpr.Exec(list.Strings[i]) then begin
         if D then ShowScreen('SYSTEM_GET_ALL_LOCAL_IP:: Found NIC "' + RegExpr.Match[1] + '"');
         hash[RegExpr.Match[1]] :=SYSTEM_GET_LOCAL_IP(RegExpr.Match[1]);
      end;
      RegExpr.Free;
   
   end;

    list.free;
    for i:=0 to hash.Count-1 do begin

        if length(hash[hash.HashCodes[i]])>0 then begin
           if ParamStr(1)='-iplocal' then writeln('NIC -> ',hash.HashCodes[i] + ':' + hash[hash.HashCodes[i]] + ':',i);
           virgule:=',';
           result:=result + hash[hash.HashCodes[i]] + virgule;
        end;

    end;

  if Copy(result,length(result),1)=',' then begin
     result:=Copy(result,1,length(result)-1);
  end;
  hash.Free;

end;
//##############################################################################
function MyConf.SYSTEM_GET_LOCAL_IP(ifname:string):string;
var
 ifr : ifreq;
 sock : longint;
 p:pChar;


begin
 Result:='';

 strncpy( ifr.ifr_ifrn.ifrn_name, pChar(ifname), IF_NAMESIZE-1 );
 ifr.ifr_ifru.ifru_addr.sa_family := AF_INET;
 sock := socket(AF_INET, SOCK_DGRAM, IPPROTO_IP);
 if ( sock >= 0 ) then begin
   if ( ioctl( sock, SIOCGIFADDR, @ifr ) >= 0 ) then begin
     p:=inet_ntoa( ifr.ifr_ifru.ifru_addr.sin_addr );
     if ( p <> nil ) then Result :=  p;
   end;
   libc.__close(sock);
 end;
end;
//##############################################################################
function MyConf.SYSTEM_PROCESS_EXISTS(processname:string):boolean;
var
   S:TStringList;
   RegExpr:TRegExpr;
   i:integer;
   D:boolean;
begin
     D:=COMMANDLINE_PARAMETERS('debug');
     if not fileexists('/bin/ps') then begin
        writeln('Unable to locate /bin/ps');
        end;

     RegExpr:=TRegExpr.create;
     S:=TstringList.Create;
     if D then showscreen('SYSTEM_PROCESS_EXISTS:: /bin/ps -eww -orss,vsz,comm');
    // S.LoadFromStream(ExecStream('/bin/ps -eww -orss,vsz,comm',false));
     S.LoadFromStream(ExecStream('/bin/ps -x',false));
     RegExpr.expression:=processname;
     for i:=0 to S.Count -1 do begin
         if RegExpr.Exec(S.Strings[i]) then begin
                if D then showscreen('SYSTEM_PROCESS_EXISTS:: ' + processname + '=' + S.Strings[i]);
                RegExpr.Free;
                S.free;
                exit(true);
         end;

     end;

RegExpr.Free;
S.free;
exit(false);
end;
//##############################################################################
function MyConf.Explode(const Separator, S: string; Limit: Integer = 0):TStringDynArray;
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
//####################################################################################
procedure myconf.POSTFIX_CONFIGURE_MAIN_CF();
var
  main_cf:TStringList;
  ldap_server,ldap_admin,ldap_password,ldap_suffix:string;


begin

     if not FileExists(POSFTIX_MASTER_CF_PATH()) then exit;
     ldap_server:=trim(get_LDAP('server'));
     ldap_admin:=trim(get_LDAP('admin'));
     ldap_suffix:=trim(get_LDAP('suffix'));
     ldap_password:=trim(get_LDAP('password'));


     if length(ldap_server)=0 then ldap_server:='127.0.0.1';
     main_cf:=TStringList.Create;



	main_cf.add('bounce_service_name=bounce');
	main_cf.add('bounce_size_limit=50000');
	main_cf.add('bounce_notice_recipient=postmaster');
	main_cf.add('double_bounce_sender=double-bounce');
	main_cf.add('message_size_limit=102400000');
	main_cf.add('mime_nesting_limit=100');
	main_cf.add('header_address_token_limit=10240');
	main_cf.add('smtpd_reject_unlisted_recipient=yes');
	main_cf.add('smtp_connection_cache_on_demand=yes');
	main_cf.add('smtp_connection_cache_time_limit=2s');
	main_cf.add('smtp_connection_reuse_time_limit=300s');
	main_cf.add('connection_cache_ttl_limit=2s');
	main_cf.add('connection_cache_status_update_time=600s');
	main_cf.add('address_verify_sender=double-bounce');
	main_cf.add('address_verify_negative_cache=yes');
	main_cf.add('address_verify_negative_expire_time=3d');
	main_cf.add('address_verify_negative_refresh_time=3h');
	main_cf.add('address_verify_poll_count=3');
	main_cf.add('address_verify_poll_delay=3s');
	main_cf.add('address_verify_positive_expire_time=31d');
	main_cf.add('address_verify_positive_refresh_time=7d');
	main_cf.add('smtpd_error_sleep_time=1s');
	main_cf.add('smtpd_soft_error_limit=10');
	main_cf.add('smtpd_hard_error_limit=20');
	main_cf.add('smtpd_client_connection_count_limit=50');
	main_cf.add('smtpd_client_connection_rate_limit=0');
	main_cf.add('smtpd_client_message_rate_limit=0');
	main_cf.add('smtpd_client_recipient_rate_limit=0');
	main_cf.add('smtpd_client_new_tls_session_rate_limit=0');
	main_cf.add('smtpd_client_event_limit_exceptions=$mynetworks');
	main_cf.add('in_flow_delay=1s');
	main_cf.add('smtp_helo_timeout=300s');
	main_cf.add('smtp_connect_timeout=30s');
	main_cf.add('default_destination_recipient_limit=50');
	main_cf.add('smtpd_recipient_limit=1000');
	main_cf.add('queue_run_delay=300s');
	main_cf.add('minimal_backoff_time=300s');
	main_cf.add('maximal_backoff_time=4000s');
	main_cf.add('maximal_queue_lifetime=5d');
	main_cf.add('bounce_queue_lifetime=5d');
	main_cf.add('qmgr_message_recipient_limit=20000');
	main_cf.add('qmgr_message_recipient_minimum=10');
	main_cf.add('default_process_limit=100');
	main_cf.add('initial_destination_concurrency=5');
	main_cf.add('default_destination_concurrency_limit=20');
	main_cf.add('local_destination_concurrency_limit=2');
	main_cf.add('artica_destination_recipient_limit = 1');
        main_cf.add('smtp_destination_concurrency_limit=$default_destination_concurrency_limit');
	main_cf.add('smtp_tls_session_cache_database=btree:${queue_directory}/smtp_tls_session_cache');
	main_cf.add('bounce_template_file=/etc/postfix/bounce.template.cf');

        if FileExists(CYRUS_DELIVER_BIN_PATH()) then begin
           main_cf.add('mailbox_transport=cyrus');
	   main_cf.add('virtual_transport=cyrus');
       end;
	main_cf.add('mailbox_command=/usr/bin/procmail -t -a "$EXTENSION"');
	main_cf.add('inet_interfaces=all');
	main_cf.add('mailbox_size_limit=102400000');
	main_cf.add('smtp_sasl_auth_enable=yes');
	main_cf.add('relayhost=[smtp.laposte.net]');
	main_cf.add('smtp_sasl_mechanism_filter=plain, login');
	main_cf.add('smtp_sasl_exceptions_networks=$mynetworks');
	main_cf.add('mynetworks=127.0.0.0/24');
	main_cf.add('smtpd_helo_restrictions = check_policy_service inet:127.0.0.1:29001');
	main_cf.add('mydestination=localhost,localhost.$mydomain,$myhostname,ldap:mydestinationTable');
	main_cf.add('');
	main_cf.add('');
	main_cf.add('#LDAP mydestinationTable --------------------------------------------------------------------');
	main_cf.add('mydestinationTable_server_host=' + ldap_server );
	main_cf.add('mydestinationTable_server_port =389');
	main_cf.add('mydestinationTable_bind = yes');
	main_cf.add('mydestinationTable_bind_dn =cn=' + ldap_admin +','+ ldap_suffix);
	main_cf.add('mydestinationTable_bind_pw =' + ldap_password );
	main_cf.add('mydestinationTable_search_base =' + ldap_suffix );
	main_cf.add('mydestinationTable_timeout = 10');
	main_cf.add('mydestinationTable_query_filter =(&(objectclass=organizationalUnit)(associatedDomain=%s))');
	main_cf.add('mydestinationTable_version =3');
	main_cf.add('mydestinationTable_result_attribute =associatedDomain');
	main_cf.add('#----------------------------------------------------------------------');
	main_cf.add('');
	main_cf.add('transport_maps=ldap:TransportMapsTable');
	main_cf.add('');
	main_cf.add('');
	main_cf.add('#LDAP TransportMapsTable --------------------------------------------------------------------');
	main_cf.add('TransportMapsTable_server_host=' + ldap_server );
	main_cf.add('TransportMapsTable_server_port =389');
	main_cf.add('TransportMapsTable_bind = yes');
	main_cf.add('TransportMapsTable_bind_dn =cn=' + ldap_admin +','+ ldap_suffix);
	main_cf.add('TransportMapsTable_bind_pw =' + ldap_password );
	main_cf.add('TransportMapsTable_search_base =' + ldap_suffix );
	main_cf.add('TransportMapsTable_timeout = 10');
	main_cf.add('TransportMapsTable_query_filter =(&(objectClass=transportTable)(cn=%d))');
	main_cf.add('TransportMapsTable_version =3');
	main_cf.add('TransportMapsTable_result_attribute =transport');
	main_cf.add('#----------------------------------------------------------------------');
	main_cf.add('');
	main_cf.add('mynetworks=' + ldap_server + ',ldap:mynetworksTable');
	main_cf.add('');
	main_cf.add('');
	main_cf.add('#LDAP mynetworksTable --------------------------------------------------------------------');
	main_cf.add('mynetworksTable_server_host=' + ldap_server );
	main_cf.add('mynetworksTable_server_port =389');
	main_cf.add('mynetworksTable_bind = yes');
	main_cf.add('mynetworksTable_bind_dn =cn=' + ldap_admin +','+ ldap_suffix);
	main_cf.add('mynetworksTable_bind_pw =' + ldap_password );
	main_cf.add('mynetworksTable_search_base =cn=mynetworks_maps,cn=artica,' + ldap_suffix );
	main_cf.add('mynetworksTable_timeout = 10');
	main_cf.add('mynetworksTable_query_filter =(&(objectClass=PostfixMynetworks)(mynetworks=%s))');
	main_cf.add('mynetworksTable_version =3');
	main_cf.add('mynetworksTable_result_attribute =mynetworks');
	main_cf.add('#----------------------------------------------------------------------');
	main_cf.add('');
	main_cf.add('relais_domain=ldap:RelaisDomainsTable');
	main_cf.add('');
	main_cf.add('');
	main_cf.add('#LDAP RelaisDomainsTable --------------------------------------------------------------------');
	main_cf.add('RelaisDomainsTable_server_host=' + ldap_server );
	main_cf.add('RelaisDomainsTable_server_port =389');
	main_cf.add('RelaisDomainsTable_bind = yes');
	main_cf.add('RelaisDomainsTable_bind_dn =cn=' + ldap_admin +','+ ldap_suffix);
	main_cf.add('RelaisDomainsTable_bind_pw =' + ldap_password );
	main_cf.add('RelaisDomainsTable_search_base =' + ldap_suffix );
	main_cf.add('RelaisDomainsTable_timeout = 10');
	main_cf.add('RelaisDomainsTable_query_filter =(&(objectclass=PostFixRelayDomains)(cn=%s))');
	main_cf.add('RelaisDomainsTable_version =3');
	main_cf.add('RelaisDomainsTable_result_attribute =cn');
	main_cf.add('#----------------------------------------------------------------------');
	main_cf.add('');
	main_cf.add('relay_recipient_maps=ldap:RelaisRecipientTable');
	main_cf.add('');
	main_cf.add('');
	main_cf.add('#LDAP RelaisRecipientTable --------------------------------------------------------------------');
	main_cf.add('RelaisRecipientTable_server_host=' + ldap_server );
	main_cf.add('RelaisRecipientTable_server_port =389');
	main_cf.add('RelaisRecipientTable_bind = yes');
	main_cf.add('RelaisRecipientTable_bind_dn =cn=' + ldap_admin +','+ ldap_suffix);
	main_cf.add('RelaisRecipientTable_bind_pw =' + ldap_password );
	main_cf.add('RelaisRecipientTable_search_base =' + ldap_suffix );
	main_cf.add('RelaisRecipientTable_timeout = 10');
	main_cf.add('RelaisRecipientTable_query_filter =(&(objectclass=PostfixRelayRecipientMaps)(cn=%s))');
	main_cf.add('RelaisRecipientTable_version =3');
	main_cf.add('RelaisRecipientTable_result_attribute =cn');
	main_cf.add('#----------------------------------------------------------------------');
	main_cf.add('');
	main_cf.add('virtual_alias_maps=ldap:VirtualAliasMapsTable,ldap:VirtualMailManMaps');
	main_cf.add('');
	main_cf.add('');
	main_cf.add('#LDAP VirtualAliasMapsTable --------------------------------------------------------------------');
	main_cf.add('VirtualAliasMapsTable_server_host=' + ldap_server );
	main_cf.add('VirtualAliasMapsTable_server_port =389');
	main_cf.add('VirtualAliasMapsTable_bind = yes');
	main_cf.add('VirtualAliasMapsTable_bind_dn =cn=' + ldap_admin +','+ ldap_suffix);
	main_cf.add('VirtualAliasMapsTable_bind_pw =' + ldap_password );
	main_cf.add('VirtualAliasMapsTable_search_base =' + ldap_suffix );
	main_cf.add('VirtualAliasMapsTable_timeout = 10');
	main_cf.add('VirtualAliasMapsTable_query_filter =(&(objectClass=userAccount)(mailAlias=%s))');
	main_cf.add('VirtualAliasMapsTable_version =3');
	main_cf.add('VirtualAliasMapsTable_result_attribute =mail');
	main_cf.add('#----------------------------------------------------------------------');
	main_cf.add('');
	main_cf.add('');
	main_cf.add('#LDAP VirtualMailManMaps --------------------------------------------------------------------');
	main_cf.add('VirtualMailManMaps_server_host=' + ldap_server );
	main_cf.add('VirtualMailManMaps_server_port =389');
	main_cf.add('VirtualMailManMaps_bind = yes');
	main_cf.add('VirtualMailManMaps_bind_dn =cn=' + ldap_admin +','+ ldap_suffix);
	main_cf.add('VirtualMailManMaps_bind_pw =' + ldap_password );
	main_cf.add('VirtualMailManMaps_search_base =cn=mailman,cn=artica,' + ldap_suffix );
	main_cf.add('VirtualMailManMaps_timeout = 10');
	main_cf.add('VirtualMailManMaps_query_filter =(&(objectClass=ArticaMailManRobots)(cn=%s))');
	main_cf.add('VirtualMailManMaps_version =3');
	main_cf.add('VirtualMailManMaps_result_attribute =cn');
	main_cf.add('#----------------------------------------------------------------------');


	main_cf.add('');
	main_cf.add('virtual_mailbox_maps=ldap:VirtualMailboxMapsTable');
	main_cf.add('alias_maps=ldap:VirtualMailboxMapsTable,ldap:VirtualMailManMaps');
	main_cf.add('');
	main_cf.add('');
	main_cf.add('#LDAP VirtualMailboxMapsTable --------------------------------------------------------------------');
	main_cf.add('VirtualMailboxMapsTable_server_host=' + ldap_server );
	main_cf.add('VirtualMailboxMapsTable_server_port =389');
	main_cf.add('VirtualMailboxMapsTable_bind = yes');
	main_cf.add('VirtualMailboxMapsTable_bind_dn =cn=' + ldap_admin +','+ ldap_suffix);
	main_cf.add('VirtualMailboxMapsTable_bind_pw =' + ldap_password );
	main_cf.add('VirtualMailboxMapsTable_search_base =' + ldap_suffix );
	main_cf.add('VirtualMailboxMapsTable_timeout = 10');
	main_cf.add('VirtualMailboxMapsTable_query_filter =(&(objectClass=userAccount)(mail=%s))');
	main_cf.add('VirtualMailboxMapsTable_version =3');
	main_cf.add('VirtualMailboxMapsTable_result_attribute =uid');
	main_cf.add('#----------------------------------------------------------------------');
	main_cf.add('');
	main_cf.add('smtp_sasl_password_maps=ldap:SmtpSaslPasswordMaps');
	main_cf.add('');
	main_cf.add('');
	main_cf.add('#LDAP SmtpSaslPasswordMaps --------------------------------------------------------------------');
	main_cf.add('SmtpSaslPasswordMaps_server_host=' + ldap_server );
	main_cf.add('SmtpSaslPasswordMaps_server_port =389');
	main_cf.add('SmtpSaslPasswordMaps_bind = yes');
	main_cf.add('SmtpSaslPasswordMaps_bind_dn =cn=' + ldap_admin +','+ ldap_suffix);
	main_cf.add('SmtpSaslPasswordMaps_bind_pw =' + ldap_password );
	main_cf.add('SmtpSaslPasswordMaps_search_base =cn=smtp_sasl_password_maps,cn=artica,' + ldap_suffix );
	main_cf.add('SmtpSaslPasswordMaps_timeout = 10');
	main_cf.add('SmtpSaslPasswordMaps_query_filter =(&(objectClass=PostfixSmtpSaslPaswordMaps)(cn=%s))');
	main_cf.add('SmtpSaslPasswordMaps_version =3');
	main_cf.add('SmtpSaslPasswordMaps_result_attribute =SmtpSaslPasswordString');
	main_cf.add('#----------------------------------------------------------------------');
	main_cf.add('');
	main_cf.add('sender_canonical_maps=ldap:senderCanonicalTable');
	main_cf.add('');
	main_cf.add('');
	main_cf.add('#LDAP senderCanonicalTable --------------------------------------------------------------------');
	main_cf.add('senderCanonicalTable_server_host=' + ldap_server );
	main_cf.add('senderCanonicalTable_server_port =389');
	main_cf.add('senderCanonicalTable_bind = yes');
	main_cf.add('senderCanonicalTable_bind_dn =cn=' + ldap_admin +','+ ldap_suffix);
	main_cf.add('senderCanonicalTable_bind_pw =' + ldap_password );
	main_cf.add('senderCanonicalTable_search_base =' + ldap_suffix );
	main_cf.add('senderCanonicalTable_timeout = 10');
	main_cf.add('senderCanonicalTable_query_filter =(&(objectClass=userAccount)(uid=%s))');
	main_cf.add('senderCanonicalTable_version =3');
	main_cf.add('senderCanonicalTable_result_attribute =SenderCanonical');
	main_cf.add('#----------------------------------------------------------------------');
        main_cf.add('');
        if FileExists('/opt/kav/5.6/kavmilter/bin/kavmilter') then begin
           main_cf.add('smtpd_milters=inet:127.0.0.1:1052');
           main_cf.add('milter_connect_macros = j _ {daemon_name} {if_name} {if_addr}');
           main_cf.add('milter_helo_macros = {tls_version} {cipher} {cipher_bits} {cert_subject} {cert_issuer}');
           main_cf.add('milter_mail_macros = i {auth_type} {auth_authen} {auth_ssf} {auth_author} {mail_mailer} {mail_host} {mail_addr}');
           main_cf.add('milter_rcpt_macros = {rcpt_mailer} {rcpt_host} {rcpt_addr}');
           main_cf.add('milter_default_action = tempfail');
           main_cf.add('milter_protocol = 3');
           main_cf.add('milter_connect_timeout=180');
           main_cf.add('milter_command_timeout=180');
           main_cf.add('milter_content_timeout=600');
           main_cf.add('');
        end;
 
        main_cf.SaveToFile(POSFTIX_MASTER_CF_PATH());
        fpsystem('/bin/chown root:root '+POSFTIX_MASTER_CF_PATH());
        POSTFIX_RESTART_DAEMON();



 end;
//##############################################################################
function myconf.CYRUS_IMAPD_CONFIGURE():boolean;
var
   ldap_server,ldap_suffix:string;
   LOG:Tlogs;
   sys:TSystem;
   list2:TstringList;
   cyrus_bin_path:string;
begin
   result:=false;
   LOG:=TLogs.Create;

       if not FileExists(CYRUS_DELIVER_BIN_PATH()) then exit;
       LOG.INSTALL_MODULES('APP_CYRUSIMAP','configure cyrus-imapd');

       ldap_server:=Get_LDAP('server');
       ldap_suffix:=Get_LDAP('suffix');



       sys:=TSystem.Create();
       sys.CreateGroup('mail');
       sys.AddUserToGroup('cyrus','mail','','');


       ForceDirectories('/var/lib/cyrus/srvtab');
       ForceDirectories('/var/lib/cyrus/db');
       ForceDirectories('/var/spool/cyrus/mail');
       ForceDirectories('/var/spool/cyrus/news');
       ForceDirectories('/var/run/cyrus/socket');
       ForceDirectories('/var/lib/cyrus/socket');
       ForceDirectories('/var/lib/cyrus/proc');
       ForceDirectories('/var/run/cyrus/socket');


       fpsystem('/bin/chmod 750 /var/run/cyrus');
       fpsystem('chmod -R 755 /var/lib/cyrus');
       fpsystem('chmod -R 755 /var/spool/cyrus');

       fpsystem('/bin/chown -R cyrus:mail /var/lib/cyrus >/dev/null 2>&1');
       fpsystem('/bin/chown -R cyrus:mail /var/spool/cyrus >/dev/null 2>&1');
       fpsystem('/bin/chown -R cyrus:mail /var/run/cyrus >/dev/null 2>&1');




   list2:=TstringList.Create;
   list2.Add('configdirectory: /var/lib/cyrus');
   list2.Add('defaultpartition: default');
   list2.Add('partition-default: /var/spool/cyrus/mail');
   list2.Add('partition-news: /var/spool/cyrus/news');
   list2.Add('srvtab: /var/lib/cyrus/srvtab');
   list2.Add('newsspool: /var/spool/cyrus/news');
   list2.Add('altnamespace: no');
   list2.Add('unixhierarchysep: yes');
   list2.Add('lmtp_downcase_rcpt: yes');
   list2.Add('allowanonymouslogin: no');
   list2.Add('popminpoll: 1');
   list2.Add('autocreatequota: 0');
   list2.Add('umask: 077');
   list2.Add('sieveusehomedir: false');
   list2.Add('sievedir: /var/spool/cyrus/sieve');
   list2.Add('hashimapspool: true');
   list2.Add('allowplaintext: yes');
   list2.Add('sasl_pwcheck_method: saslauthd');
   list2.Add('sasl_auto_transition: no');
   list2.Add('tls_ca_path:/opt/artica/ssl/certs');
   list2.Add('tls_session_timeout: 1440');
   list2.Add('tls_cipher_list: TLSv1+HIGH:!aNULL:@STRENGTH');
   list2.Add('lmtpsocket: /var/run/cyrus/socket/lmtp');
   list2.Add('idlemethod: poll');
   list2.Add('idlesocket: /var/run/cyrus/socket/idle');
   list2.Add('notifysocket: /var/run/cyrus/socket/notify');
   list2.Add('syslog_prefix: cyrus');
   list2.Add('servername: ' + LINUX_GET_HOSTNAME());
   list2.Add('virtdomains: no');
   list2.Add('admins: cyrus');
   list2.Add('username_tolower: 1');
   list2.Add('ldap_uri: ldap://' + ldap_server);
   list2.Add('ldap_member_base:' + ldap_suffix);
   list2.Add('sasl_mech_list: PLAIN LOGIN');
   list2.Add('sieve_maxscriptsize: 1024');
   list2.Add('sasl_saslauthd_path:/var/run/mux');
   list2.SaveToFile('/etc/imapd.conf');
   LOG.INSTALL_MODULES('APP_CYRUSIMAP','saving /etc/imapd.conf');
   LOG.INSTALL_MODULES('APP_CYRUSIMAP','Creating user for cyrus...');
   list2.Clear;

   if FileExists('/usr/cyrus/bin/ctl_cyrusdb') then cyrus_bin_path:='/usr/cyrus/bin';
   if FileExists('/usr/sbin/ctl_cyrusdb') then cyrus_bin_path:='/usr/sbin';
   if FileExists('/opt/artica/cyrus/bin/ctl_cyrusdb') then cyrus_bin_path:='/opt/artica/cyrus/bin';

list2.Add('');
list2.Add('START {');
list2.Add('	recover		cmd="' + cyrus_bin_path + '/ctl_cyrusdb -r"');
list2.Add('');
list2.Add('	delprune	cmd="'+ cyrus_bin_path + '/cyr_expire -E 3"');
list2.Add('#	tlsprune	cmd="' + cyrus_bin_path + '/tls_prune"');
list2.Add('}');
list2.Add('');
list2.Add('SERVICES {');
list2.Add('	imap		cmd="imapd -U 30" listen="imap" prefork=0 maxchild=100');
list2.Add('	pop3		cmd="pop3d -U 30" listen="pop3" prefork=0 maxchild=50');
list2.Add('#	nntp		cmd="nntpd -U 30" listen="nntp" prefork=0 maxchild=100');
list2.Add('	lmtpunix	cmd="lmtpd" listen="/var/run/cyrus/socket/lmtp" prefork=0 maxchild=20');
list2.Add('  	sieve		cmd="timsieved" listen="localhost:sieve" prefork=0 maxchild=100');
list2.Add('	notify		cmd="notifyd" listen="/var/run/cyrus/socket/notify" proto="udp" prefork=1');
list2.Add('}');
list2.Add('');
list2.Add('EVENTS {');
list2.Add('	checkpoint	cmd="' + cyrus_bin_path + '/ctl_cyrusdb -c" period=30');
list2.Add('	delprune	cmd="' + cyrus_bin_path + '/cyr_expire -E 3" at=0401');
list2.Add('#	tlsprune	cmd="' + cyrus_bin_path + '/tls_prune" at=0401');
list2.Add('');
list2.Add('}');
list2.Add('');
LOG.INSTALL_MODULES('APP_CYRUSIMAP','saving /etc/cyrus.conf');
list2.SaveToFile('/etc/cyrus.conf');

end;
//##############################################################################
procedure myconf.SASLAUTHD_CONFIGURE();
var
   ldap_admin,ldap_password,ldap_server,ldap_suffix:string;
   LOG:Tlogs;
   list2:TstringList;
begin

   LOG:=TLogs.Create;
///usr/local/sbin/saslauthd
///usr/local/etc/saslauthd.conf

       LOG.INSTALL_MODULES('APP_SASLAUTHD','configure saslauthd');
       ldap_admin:=get_LDAP('admin');
       ldap_password:=get_LDAP('password');
       ldap_server:=Get_LDAP('server');
       ldap_suffix:=Get_LDAP('suffix');

       LOG.INSTALL_MODULES('APP_SASLAUTHD','using ' + ldap_admin + ':' +ldap_password + '@' + ldap_server + ':/' +ldap_suffix);

                 list2:=TstringList.Create;
                 list2.Add('ldap_servers: ldap://' + ldap_server + '/');
                 list2.Add('ldap_version: 3');
                 list2.Add('ldap_search_base: '+ ldap_suffix);
                 list2.Add('ldap_scope: sub');
                 list2.Add('ldap_filter: uid=%u');
                 list2.Add('ldap_auth_method: bind');
                 list2.Add('ldap_bind_dn: cn=' +ldap_admin+ ',' + ldap_suffix);
                 list2.Add('ldap_password: ' + ldap_password);
                 list2.Add('ldap_timeout: 10');

                 LOG.INSTALL_MODULES('APP_SASLAUTHD','writing /opt/artica/etc/saslauthd.conf');
                 list2.SaveToFile('/opt/artica/etc/saslauthd.conf');
                 list2.clear;

                 list2.Add('pwcheck_method: saslauthd');
                 forcedirectories('/opt/artica/lib/sasl2');
                 list2.SaveToFile('/opt/artica/lib/sasl2/smtpd.conf');


                 SASLAUTHD_START();






end;

//##############################################################################
function myconf.XINETD_BIN():string;
begin
    if FileExists('/usr/sbin/xinetd') then exit('/usr/sbin/xinetd');
end;
//##############################################################################
function myconf.SYSTEM_GET_FOLDERSIZE(folderpath:string):string;
var
   RegExpr      :TRegExpr;
   s1Logs       :Tlogs;
begin
   RegExpr:=TRegExpr.Create;
   s1Logs:=TLogs.Create;
   if not FileExists('/usr/bin/du') then begin
      s1Logs.logs('SYSTEM_GET_FOLDERSIZE:: unable to stat any "du" tool');
   end;
 RegExpr.Expression:='(.+)\s+'+folderpath;
 if RegExpr.Exec(ExecPipe('/usr/bin/du -c -s -h ' + folderpath)) then result:=RegExpr.Match[1];
 RegExpr.Free;
 s1Logs.free;

   
end;
//##############################################################################


procedure myconf.LDAP_SET_DB_CONFIG();
var
filedatas:TstringList;
ldap_conf_path:string;

begin

    if FileExists('/opt/artica/var/openldap-data/DB_CONFIG') then exit;
    ldap_conf_path:=LDAP_GET_CONF_PATH();
    ldap_conf_path:=ExtractFilePath(ldap_conf_path);
    forceDirectories('/opt/artica/var/openldap-data');
    filedatas:=TstringList.Create;
    filedatas.Add('set_cachesize 0 268435456 1');
    filedatas.Add('set_lg_regionmax 262144');
    filedatas.Add('set_lg_bsize 2097152');
    writeln('Starting......: OpenLDAP server writing DB_CONFIG');
    filedatas.SaveToFile('/opt/artica/var/openldap-data/DB_CONFIG');
    filedatas.Free;
end;
//##############################################################################
procedure myconf.DeleteFile(Path:string);
Var F : Text;
begin
   if FileExists(Path) then begin
      Assign (F,Path);
       Erase (f);
   end;

end;
//##############################################################################
PROCEDURE myconf.BuildDeb(targetfile:string;targetversion:string);
var
   RegExpr      :TRegExpr;
   L            :TstringList;
   i            :integer;
begin
  if Not FileExists(targetfile) then exit;
  L:=TStringList.Create;
  L.LoadFromFile(targetfile);
  RegExpr:=TRegExpr.Create;
  RegExpr.Expression:='Version:';
  for i:=0 to L.Count-1 do begin
   if RegExpr.Exec(l.Strings[i]) then begin
      l.Strings[i]:='Version: ' + targetversion;
      l.SaveToFile(targetfile);
      break;
   end;
  end;
end;
//##############################################################################
PROCEDURE myconf.SQUID_RRD_INIT();
var
   TL     :TstringList;
   i      :integer;
   stop   :boolean;
   RegExpr:TRegExpr;
   script_path:string;
begin
     if not FileExists(SQUID_BIN_PATH()) then exit;
     stop:=true;
     script_path:=get_ARTICA_PHP_PATH()+ '/bin/install/rrd/squid-builder.sh';
     
     if not FileExists(get_ARTICA_PHP_PATH()+ '/bin/install/rrd/squid-builder.info') then begin
        Logs.logs('SQUID_RRD_INIT():: unable to stat '+get_ARTICA_PHP_PATH()+ '/bin/install/rrd/squid-builder.info');
        exit;
     end;
     
     if not FileExists(script_path) then begin
        Logs.logs('SQUID_RRD_INIT():: unable to stat '+script_path);
        exit;
     end;
     

     TL:=TStringList.Create;
     TL.LoadFromFile(get_ARTICA_PHP_PATH()+ '/bin/install/rrd/squid-builder.info');
     
     For i:=0 to TL.Count-1 do begin
          if not FileExists('/opt/artica/var/rrd/' + TL.Strings[i]) then begin
             stop:=false;
             break;
          end;
     end;

     SQUID_RRD_INSTALL();
     if stop=true then exit;
     Logs.logs('SQUID_RRD_INIT():: Set settings');
     RegExpr:=TRegExpr.Create;

     
     TL.LoadFromFile(script_path);
     
     For i:=0 to TL.Count-1 do begin
         RegExpr.Expression:='PATH="(.+)';
         if RegExpr.Exec(TL.Strings[i]) then TL.Strings[i]:='PATH="/opt/artica/var/rrd"';
     
         RegExpr.Expression:='RRDTOOL="(.+)';
         if RegExpr.Exec(TL.Strings[i]) then TL.Strings[i]:='RRDTOOL="' + RRDTOOL_BIN_PATH()+'"';

     end;
     
    TL.SaveToFile(script_path);
    writeln('Starting......: Creating and set rrd parameters for squid OK');
    TL.Free;
    fpsystem('/bin/chmod 777 ' + script_path);
    forcedirectories('/opt/artica/var/rrd');
    fpsystem(script_path);
     
     
end;
//##############################################################################
PROCEDURE myconf.SQUID_RRD_INSTALL();
var
   TL     :TstringList;
   i      :integer;
   RegExpr:TRegExpr;
   script_path:string;
   script_path_bak:string;
begin
  //usr/local/bin/rrdcgi
  script_path:=get_ARTICA_PHP_PATH()+ '/bin/install/rrd/squid-rrd.pl';
  script_path_bak:=get_ARTICA_PHP_PATH()+ '/bin/install/rrd/squid-rrd.bak';
  
  
  if not FileExists(script_path) then begin
      if FileExists(script_path_bak) then fpsystem('/bin/cp ' + script_path_bak + ' ' +  script_path);
  end;

  if not FileExists(script_path) then exit;
  if FileSize_ko(script_path)<5 then fpsystem('/bin/cp ' + script_path_bak + ' ' +  script_path);


  TL:=TStringList.Create;
  if not FileExists(script_path) then exit;
  RegExpr:=TRegExpr.Create;

  TL.LoadFromFile(script_path);
  for i:=0 to TL.Count-1 do begin
      RegExpr.Expression:='my \$rrdtool';
      if RegExpr.Exec(TL.Strings[i]) then TL.Strings[i]:='my $rrdtool = "' + RRDTOOL_BIN_PATH() + '";';
      RegExpr.Expression:='my \$rrd_database_path';
      if RegExpr.Exec(TL.Strings[i]) then TL.Strings[i]:='my $rrd_database_path = "/opt/artica/var/rrd";';
  end;

  TL.SaveToFile(script_path);
  TL.Free;
  fpsystem('/bin/chmod 777 ' + script_path);

end;
//##############################################################################
PROCEDURE myconf.SQUID_RRD_EXECUTE();
var
   TL            :TstringList;
   http_port     :string;
   script_path   :string;
begin
     if not FileExists(SQUID_BIN_PATH()) then exit;
     http_port:=SQUID_GET_SINGLE_VALUE('http_port');
     if length(http_port)=0 then begin
         Logs.logs('SQUID_RRD_EXECUTE():: unable to stat http_port in squid.conf');
     end;
     script_path:=get_ARTICA_PHP_PATH()+ '/bin/install/rrd/squid-rrd.pl';
     if not FileExists(script_path) then begin
        Logs.logs('SQUID_RRD_EXECUTE():: unable to stat http_port in squid.conf');
        exit;
     end;
     
     fpsystem(script_path + ' 127.0.0.1:' + http_port + ' >>/opt/artica/logs/squid-rrd.log 2>&1');
     if FileExists(get_ARTICA_PHP_PATH() + '/bin/install/rrd/squid-rrdex.pl') then begin
        ForceDirectories('/opt/artica/share/www/squid/rrd');
        if not FileExists('/etc/cron.d/artica-squidRRD0') then begin
         TL:=TstringList.Create;
         TL.Add('#This generate rrd pictures from squid statistics');
         TL.Add('1,2,6,8,10,12,14,16,18,20,22,24,26,28,30,32,34,36,38,40,42,44,46,48,50,52,54,56,58 * * * * root ' + get_ARTICA_PHP_PATH() + '/bin/install/rrd/squid-rrdex.pl >/dev/null 2>&1');
         Logs.logs('SQUID_RRD_EXECUTE():: Restore /etc/crond.d/artica-squid-cron-rrd-0');
         TL.SaveToFile('/etc/cron.d/artica-squidRRD0');
         TL.free;
        end;
    end;

     //
     
     
end;
//##############################################################################
PROCEDURE myconf.RRD_MAILGRAPH_INSTALL();
var
   TL            :TstringList;
   script_path   :string;
begin
    if not FileExists(POSFTIX_POSTCONF_PATH()) then exit;
    
    script_path:=get_ARTICA_PHP_PATH() + '/bin/install/rrd/queuegraph-rrd.sh';
    if not FileExists('/opt/artica/var/rrd/queuegraph.rrd') then fpsystem(script_path);
    
    if not FileExists('/etc/cron.d/artica-queuegraph') then begin
       ForceDirectories('/opt/artica/share/www/mailgraph');
        fpsystem(script_path);
        script_path:=get_ARTICA_PHP_PATH() + '/bin/install/rrd/queuegraph-upd.pl';
        fpsystem('chmod 755 ' + script_path);
        TL:=TstringList.Create;
        TL.Add('#This generate rrd pictures from postfix queue statistics');
        TL.Add('* * * * * root ' + script_path + ' >/dev/null 2>&1');
        Logs.logs('SQUID_RRD_EXECUTE():: Restore /etc/cron.d/artica-queuegraph');
        TL.SaveToFile('/etc/cron.d/artica-queuegraph');
        TL.free;
   end;
    

end;
//##############################################################################


function myconf.FileSize_ko(path:string):longint;
Var
L : File Of byte;
size:longint;
ko:longint;

begin
if not FileExists(path) then begin
   result:=0;
   exit;
end;
   TRY
  Assign (L,path);
  Reset (L);
  size:=FileSize(L);
   Close (L);
  ko:=size div 1024;
  result:=ko;
  EXCEPT

  end;
end;
//##############################################################################
function myconf.SYSTEM_FILE_BETWEEN_NOW(filepath:string):LongInt;
var
   fa   : Longint;
   S    : TDateTime;
   maint:TDateTime;
begin
if not FileExists(filepath) then exit(0);
    fa:=FileAge(filepath);
    maint:=Now;
    S:=FileDateTodateTime(fa);
    result:=MinutesBetween(maint,S);
end;
//##############################################################################
function myconf.SYSTEM_FILE_DAYS_BETWEEN_NOW(filepath:string):LongInt;
var
   fa   : Longint;
   S    : TDateTime;
   maint:TDateTime;
begin
if not FileExists(filepath) then exit(0);
    fa:=FileAge(filepath);
    maint:=Now;
    S:=FileDateTodateTime(fa);
    result:=DaysBetween(maint,S);
end;
//##############################################################################

procedure myconf.StatFile(path:string);
var
    info : stat;
    S    : TDateTime;
    fa   : Longint;
    maint:TDateTime;
begin
if not FileExists(path) then exit;
  if fpstat(path,info)<>0 then
     begin
       writeln('Fstat failed. Errno : ',fpgeterrno);
       halt (1);
     end;
  writeln;
  writeln ('Result of fstat on file ' + path);
  writeln ('Inode   : ',info.st_ino);
  writeln ('Mode    : ',info.st_mode);
  writeln ('nlink   : ',info.st_nlink);
  writeln ('uid     : ',info.st_uid);
  writeln ('gid     : ',info.st_gid);
  writeln ('rdev    : ',info.st_rdev);
  writeln ('Size    : ',info.st_size);
  writeln ('Blksize : ',info.st_blksize);
  writeln ('Blocks  : ',info.st_blocks);
  writeln ('atime   : ',info.st_atime);
  writeln ('mtime   : ',info.st_mtime);
  writeln ('ctime   : ',info.st_ctime);
  if FileSymbolicExists(path) then begin
  writeln ('Symbolic: ','Yes');
  StatFileSymbolic(path);
  end else begin
  writeln ('Symbolic: ','No');
  end;
  

  
   fa:=FileAge(path);
   maint:=Now;
  If Fa<>-1 then begin
    S:=FileDateTodateTime(fa);
    writeln ('From    : ',DateTimeToStr(S));
  end;
  writeln ('Between : ',MinutesBetween(maint,S),' minutes');
    
end;
function myconf.MD5FromFile(path:string):string;
var
Digest:TMD5Digest;
begin
Digest:=MD5File(path);
exit(MD5Print(Digest));
end;
//##############################################################################
function myconf.FileSymbolicExists(path:string):boolean;
var
info :stat;
begin
result:=false;
 if fpLStat (path,@info)=0 then
    begin
    if fpS_ISLNK(info.st_mode) then exit(true);
    exit;
      Writeln ('File is a link');
    if fpS_ISREG(info.st_mode) then
      Writeln ('File is a regular file');
    if fpS_ISDIR(info.st_mode) then
      Writeln ('File is a directory');
    if fpS_ISCHR(info.st_mode) then
      Writeln ('File is a character device file');
    if fpS_ISBLK(info.st_mode) then
      Writeln ('File is a block device file');
    if fpS_ISFIFO(info.st_mode) then
      Writeln ('File is a named pipe (FIFO)');
    if fpS_ISSOCK(info.st_mode) then
      Writeln ('File is a socket');
    end else begin
    writeln('FileSymbolicExists:: Fstat failed. Errno : ',fpgeterrno);
    end;
    
end;

function myconf.StatFileSymbolic(Path:string):string;
var
   info : stat;
begin

if  fplstat (Path,@info)<>0 then
     begin
     writeln('LStat failed. Errno : ',fpgeterrno);
     halt (1);
     end;
  writeln ('Inode   : ',info.st_ino);
  writeln ('Mode    : ',info.st_mode);
  writeln ('nlink   : ',info.st_nlink);
  writeln ('uid     : ',info.st_uid);
  writeln ('gid     : ',info.st_gid);
  writeln ('rdev    : ',info.st_rdev);
  writeln ('Size    : ',info.st_size);
  writeln ('Blksize : ',info.st_blksize);
  writeln ('Blocks  : ',info.st_blocks);
  writeln ('atime   : ',info.st_atime);
  writeln ('mtime   : ',info.st_mtime);
  writeln ('ctime   : ',info.st_ctime);
  
end;
     

end.
