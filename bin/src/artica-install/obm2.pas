unit obm2;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,IniFiles, Process,md5,logs,unix,RegExpr in 'RegExpr.pas',zsystem;

  type
  tobm2=class


private
     LOGS:Tlogs;
     D:boolean;
     GLOBAL_INI:TiniFIle;
     SYS:TSystem;
     artica_path:string;
     OBM2Enabled:integer;


public
    procedure   Free;
    constructor Create(const zSYS:Tsystem);
    function  VERSION():string;
    procedure WRITE_CONFIG();
END;

implementation

constructor tobm2.Create(const zSYS:Tsystem);
begin
       forcedirectories('/etc/artica-postfix');
       LOGS:=tlogs.Create();
       SYS:=zSYS;
       OBM2Enabled:=1;
       if not TryStrToInt(SYS.GET_INFO('OBM2Enabled'),OBM2Enabled) then OBM2Enabled:=1;


       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;
end;
//##############################################################################
procedure tobm2.free();
begin
    FreeAndNil(logs);
end;
//##############################################################################
function tobm2.VERSION():string;
  var
   RegExpr:TRegExpr;
   x:string;
   tmpstr:string;
   l:TstringList;
   i:integer;
   path:string;
begin



     path:='/usr/local/obm-apache/bin/obm-apache';
     if not FileExists(path) then begin
        logs.Debuglogs('tobm2.VERSION():: apache for OBM2 is not installed');
        exit;
     end;


   result:=SYS.GET_CACHE_VERSION('APP_OBM2');
   if length(result)>0 then exit;

if not FileExists('/usr/share/obm2/obminclude/global.inc') then begin
   logs.Debuglogs('Unable to stat /usr/share/obm2/obminclude/global.inc obm seems not be installed');
   exit;
end;
     l:=TstringList.Create;
     RegExpr:=TRegExpr.Create;
     l.LoadFromFile('/usr/share/obm2/obminclude/global.inc');
     RegExpr.Expression:='\$obm_version.+?([0-9\.]+)';
     for i:=0 to l.Count-1 do begin
         if RegExpr.Exec(l.Strings[i]) then begin
            result:=RegExpr.Match[1];
            break;
         end;
     end;
l.Free;
RegExpr.free;
SYS.SET_CACHE_VERSION('APP_OBM2',result);
logs.Debuglogs('APP_OBM2:: -> ' + result);
end;
//#############################################################################
procedure tobm2.WRITE_CONFIG();
var
   l:Tstringlist;
   x:Tstringlist;
   RegExpr:TRegExpr;
   i:integer;
   Obm2ListenPort:string;

begin
x:=Tstringlist.Create;
forceDirectories('/var/lib/obm2');
l:=Tstringlist.Create;
l.clear;
l.add('[global]');
l.add('title = OBM');
l.add('external-url = obm');
l.add('external-protocol = http');
l.add('obm-prefix = /');
l.add('');
l.add('host = '+SYS.MYSQL_INFOS('server'));
l.add('dbtype = MYSQL');
l.add('db = obm2');
l.add('user = '+SYS.MYSQL_INFOS('root'));
l.add('password = "'+SYS.MYSQL_INFOS('password')+'"');
l.add('lang = en');
l.add('');
l.add('');
l.add('obm-ldap = false');
l.add('obm-mail = true');
l.add('obm-samba = false');
l.add('obm-web = false');
l.add('obm-contact = true');
l.add('');
l.add('; singleNameSpace mode allow only one domain');
l.add('; login are ''login'' and not ''login@domain''');
l.add('; Going multi-domain from mono domain needs system work (ldap, cyrus,...)');
l.add('; Multi-domain disabled by default');
l.add('singleNameSpace = false');
l.add('');
l.add('backupRoot = "/var/lib/obm2/backup"');
l.add('');
l.add('documentRoot="/var/lib/obm2/documents"');
l.add('documentDefaultPath="/"');
l.add('');
l.add('; LDAP Authentification for obm-sync & ui');
l.add('; ldap authentication server (specify :port if different than default)');
l.add(';auth-ldap-server = ldap://localhost');
l.add('; base dn for search (search are performed with scope sub, of not specified, use the server default)');
l.add(';auth-ldap-basedn = "dc=local"');
l.add('; filter used for the search part of the authentication');
l.add('; See http://www.faqs.org/rfcs/rfc2254.html for filter syntax');
l.add(';  - %u will be replace with user login');
l.add(';  - %d will be replace with user OBM domain name');
l.add('; ie: toto@domain.foo : %u=toto, %d=domain.foo');
l.add('; auth-ldap-filter = "(&(uid=%u)(obmDomain=%d))"');
l.add('');
l.add('[automate]');
l.add('; Automate specific parameters');
l.add(';');
l.add('; Log level');
l.add('logLevel = 2');
l.add(';');
l.add('; LDAP server address');
l.add('ldapServer = ldap://localhost');
l.add(';');
l.add('; LDAP use TLS [none|may|encrypt]');
l.add('ldapTls = may');
l.add(';');
l.add('; LDAP Root');
l.add('; Exemple : aliasource,local means that the root DN is: dc=aliasource,dc=local');
l.add('ldapRoot = local');
l.add('');
l.add('; Enable Cyrus partition support');
l.add('; if cyrusPartition is enable, a dedicated Cyrus partition is created for each OBM domain');
l.add('; Going cyrusPartition enabled from cyrusPartition disabled needs system work');
l.add('cyrusPartition = false');
l.add(';');
l.add('; ldapAllMainMailAddress :');
l.add(';    false : publish user mail address only if mail right is enable - default');
l.add(';    true : publish main user mail address, even if mail right is disable');
l.add('ldapAllMainMailAddress = false');
l.add(';');
l.add('; userMailboxDefaultFolders are IMAP folders who are automaticaly created');
l.add('; at user creation ( must be enclosed with " and in IMAP UTF-7 modified encoding)');
l.add('; Small convertion table');
l.add('; é -> &AOk-');
l.add('; è -> &AOg-');
l.add('; à -> &AOA-');
l.add('; & -> &');
l.add('; Example : userMailboxDefaultFolders = "Envoy&AOk-s,Corbeille,Brouillons,El&AOk-ments ind&AOk-sirables"');
l.add('userMailboxDefaultFolders = ""');
l.add(';');
l.add('; shareMailboxDefaultFolders are IMAP folders who are automaticaly created');
l.add('; at share creation ( must be enclosed with " and in IMAP UTF-7 modified');
l.add('; encoding)');
l.add('shareMailboxDefaultFolders = ""');
l.add(';');
l.add('; oldSidMapping mode is for compatibility with Aliamin and old install');
l.add('; Modifying this on a running system need Samba domain work (re-register host,');
l.add('; ACL...) ');
l.add('; For new one, leave this to ''false''');
l.add('oldSidMapping = false');
l.add(';');
l.add(';');
l.add('; Settings use by OBM Thunderbird autoconf');
l.add('[autoconf]');
l.add(';');
l.add('ldapHostname = ldap.aliacom.local');
l.add('ldapHost = 127.0.0.1');
l.add('ldapPort = 389');
l.add('ldapSearchBase = "dc=local"');
l.add('ldapAtts = cn,mail,mailAlias,mailBox,obmDomain,uid');
l.add('ldapFilter = "mail"');
l.add('configXml = /usr/lib/obm-autoconf/config.xml');
l.add(';');
l.add('; EOF');

logs.WriteToFile(l.text,'/usr/share/obm2/conf/obm_conf.ini');
l.clear;
l.add('<script language="php">');
l.add('///////////////////////////////////////////////////////////////////////////////');
l.add('// OBM - File : obm_conf.inc.sample                                          //');
l.add('//     - Desc : OBM specific site configuration Sample file                  //');
l.add('// 2005-04-04 Pierre Baudracco                                               //');
l.add('///////////////////////////////////////////////////////////////////////////////');
l.add('// $Id: obm_conf.inc.sample 4339 2009-06-09 17:44:02Z pierre $ //');
l.add('///////////////////////////////////////////////////////////////////////////////');
l.add('');
l.add('');
l.add('');
l.add('// Global parameters --------------------------------------------------------//');
l.add('');
l.add('// OBM host (for mail links)');
l.add('// CGP_HOST IS DEPRECATED. See external-url,..');
l.add('');
l.add('// Resources alias absolute path. (default value is ''/images'')');
l.add('// $resources_path = "$cgp_host/images"; ');
l.add('');
l.add('// Home page redirection');
l.add('//$c_home_redirect = "$cgp_host" . ''calendar/calendar_index.php'';');
l.add('');
l.add('// Use specific langs (was $cgp_site_include)');
l.add('//$conf_lang = true;');
l.add('');
l.add('// Use specific check controls (see conf/modules/module.inc)');
l.add('//$conf_modules = true;');
l.add('');
l.add('// Todo lines to display');
l.add('$cgp_todo_nb = 5;');
l.add('');
l.add('// Maximum rows allowed to display');
l.add('$conf_display_max_rows = 200;');
l.add('');
l.add('// Allow * in search field');
l.add('$cgp_sql_star = true;');
l.add('// archive checkbox return only archived results');
l.add('//$cgp_archive_only = true;');
l.add('');
l.add('// Tuning constants');
l.add('$ctu_sql_limit = true;');
l.add('');
l.add('// MySQL (only 4.1+) charset used (for database and files !)');
l.add('//$cmy_character_set = ''_latin1'';');
l.add('');
l.add('// MySQL (only 4.1+) charset collation used (for database and files !)');
l.add('//$cmy_charset_collation = ''latin1_general_ci'';');
l.add('');
l.add('// is Mail enabled for OBM ? (eg: calendar)');
l.add('$cgp_mail_enabled = true;');
l.add('');
l.add('// is Demo enabled (login screen array with default account)');
l.add('$cgp_demo_enabled = false;');
l.add('');
l.add('// Session Cookie lifetime (in seconds, 0=session cookie)');
l.add('$cs_lifetime = 0;');
l.add('');
l.add('// Use Database sessions');
l.add('$cgp_sess_db = false;');
l.add('//$cgp_sess_db = true;');
l.add('');
l.add('// Cookie name and domain');
l.add('$cgp_cookie_name = ''OBM_Session'';');
l.add('$cgp_cookie_domain = ''aliacom.local'';');
l.add('');
l.add('// authentification : ''CAS'' (SSO AliaSuite), ''ldap'' (LDAP authentication) or ''standalone'' (default)');
l.add('//$auth_kind = ''CAS'';');
l.add('//$cas_server = ''sso.aliacom.local'';');
l.add('//$cas_server_port = 8443;');
l.add('//$cas_server_uri = '''';');
l.add('//$auth_kind=''ldap'';');
l.add('');
l.add('// encyption used to store password : ''PLAIN'', ''MD5SUM'' or ''CRYPT''');
l.add('$password_encryption = ''PLAIN'';');
l.add('');
l.add('// Modules specific parameters ----------------------------------------------//');
l.add('');
l.add('// Company : Auto format fields');
l.add('$caf_company_name = true;');
l.add('$caf_town = true;');
l.add('');
l.add('// Company + Contact : Advanced search enabled by default');
l.add('$csearch_advanced_default = false;');
l.add('');
l.add('// Contact : is mailing enabled by default for a new contact');
l.add('$cgp_mailing_default = true;');
l.add('');
l.add('// Contact : is a new contact private by default');
l.add('$ccontact_private_default = true;');
l.add('');
l.add('// Calendar : show public groups');
l.add('$ccalendar_public_groups = true;');
l.add('');
l.add('// Calendar: generic E-mail resource admin for calendar module');
l.add('//$ccalendar_resource_admin = ''resource@mydomain'';');
l.add('');
l.add('// Calendar first ay of week, first and last hour display');
l.add('//$ccalendar_weekstart = ''monday'';');
l.add('$ccalendar_first_hour = 8;');
l.add('$ccalendar_last_hour = 20;');
l.add('');
l.add('// Calendar max user displayed in the calendar');
l.add('//$ccalendar_max_users = 25;');
l.add('');
l.add('// Calendar Resource usage');
l.add('$ccalendar_resource = true;');
l.add('');
l.add('// Set this to false if you want to forbid the insertion/update');
l.add('// of a event when a resource is one of the reasons of the conflict.');
l.add('// $ccalendar_resource_overbooking = false;');
l.add('');
l.add('// Calendar send ics file');
l.add('$ccalendar_send_ics = true;');
l.add('');
l.add('// Calendar hour fraction (minutes select granularity)');
l.add('$ccalendar_hour_fraction = 4;');
l.add('');
l.add('// Time : Worked days in a week (start at sunday)');
l.add('$c_working_days = array(0,1,1,1,1,1,0);');
l.add('');
l.add('// Generic E-mail for Incident module');
l.add('//$cmail_incident = ''support@mydomain'';');
l.add('');
l.add('// Time : activity report logo');
l.add('$cimage_logo = ''linagora.jpg'';');
l.add('');
l.add('// Document : $cdocument_root and $default_path are deprecated');
l.add('// see obm_conf.ini');
l.add('');
l.add('// Group : is a new group private by default');
l.add('$cgroup_private_default = true;');
l.add('');
l.add('// default taxes values');
l.add('$cdefault_tax = array (''TVA 19,6'' => 1.196, ''TVA 5,5'' => 1.055, ''Pas de TVA'' => 1);');
l.add('');
l.add('// default Right values; -1 = do not display');
l.add('$cgp_default_right = array (');
l.add('  ''resource'' => array (');
l.add('      ''public'' => array(');
l.add('        ''access'' => 1,');
l.add('        ''read'' => 0,');
l.add('        ''write'' => 0,');
l.add('        ''admin'' => 0');
l.add('      )');
l.add('    ),');
l.add('  ''mailshare'' => array (');
l.add('      ''public'' => array(');
l.add('        ''access'' => 1,');
l.add('        ''read'' => 0,');
l.add('        ''write'' => 0,');
l.add('        ''admin'' => 0');
l.add('      )');
l.add('    ),');
l.add('  ''mailbox'' => array (');
l.add('      ''public'' => array(');
l.add('        ''access'' => 1,');
l.add('        ''read'' => 0,');
l.add('        ''write'' => 0,');
l.add('        ''admin'' => 0');
l.add('      )');
l.add('    ),');
l.add('  ''calendar'' => array (');
l.add('      ''public'' => array(');
l.add('        ''access'' => 1,');
l.add('        ''read'' => 1,');
l.add('        ''write'' => 0,');
l.add('        ''admin'' => 0');
l.add('      )');
l.add('    )');
l.add('  );');
l.add('');
l.add('$profiles[''admin''] = array (');
l.add('  ''section'' => array (');
l.add('    ''default'' => 1');
l.add('  ),');
l.add('  ''module'' => array (');
l.add('    ''default'' => $perm_admin,');
l.add('    ''domain'' => 0),');
l.add('  ''properties'' => array (');
l.add('    ''admin_realm'' => array (''user'', ''delegation'', ''domain'')');
l.add('    ),');
l.add('  ''level'' => 1,');
l.add('  ''level_managepeers'' => 1,');
l.add('  ''access_restriction'' => ''ALLOW_ALL''');
l.add('');
l.add(');');
l.add('');
l.add('//-----------------//');
l.add('// Displayed Infos //');
l.add('//-----------------//');
l.add('// --- sections --- Default is true');
l.add('//$cgp_show[''section''] = ''''; // Needed if module order to change');
l.add('//$cgp_show[''section''][''com''][''url''] = "$path/calendar/calendar_index.php";');
l.add('//$cgp_show[''section''][''webmail''][''url''] = ''http://webmail'';');
l.add('//$cgp_show[''section''][''webmail''][''url''] = $path."/horde3";');
l.add('//$cgp_show[''section''][''webmail''][''target''] = ''_blank'';');
l.add('');
l.add('$cgp_show[''section''][''com''] = false;');
l.add('$cgp_show[''section''][''prod''] = false;');
l.add('$cgp_show[''section''][''compta''] = false;');
l.add('');
l.add('// --- modules --- false to hide, otherwise section');
l.add('//$cgp_show[''module''] = ''''; // Needed if module order to change');
l.add('//$cgp_show[''module''][''company''] = ''com'';');
l.add('//$cgp_show[''module''][''campaign''] = ''com'';');
l.add('');
l.add('// Groupware configuration by default');
l.add('$cgp_show[''module''][''company''] = false;');
l.add('$cgp_show[''module''][''lead''] = false;');
l.add('$cgp_show[''module''][''deal''] = false;');
l.add('$cgp_show[''module''][''cv''] = false;');
l.add('$cgp_show[''module''][''publication''] = false;');
l.add('$cgp_show[''module''][''statistic''] = false;');
l.add('$cgp_show[''module''][''time''] = false;');
l.add('$cgp_show[''module''][''project''] = false;');
l.add('$cgp_show[''module''][''contract''] = false;');
l.add('$cgp_show[''module''][''incident''] = false;');
l.add('$cgp_show[''module''][''invoice''] = false;');
l.add('$cgp_show[''module''][''payment''] = false;');
l.add('$cgp_show[''module''][''account''] = false;');
l.add('$cgp_show[''module''][''document''] = ''com'';');
l.add('');
l.add('// --- fields ---');
l.add('// References fields');
l.add('//$cgp_hide[''''][''region''] = true;');
l.add('');
l.add('// Company module');
l.add('//$cgp_hide[''company''][''company_number''] = true;');
l.add('//$cgp_hide[''company''][''company_vat''] = true;');
l.add('//$cgp_hide[''company''][''company_siret''] = true;');
l.add('//$cgp_hide[''company''][''type''] = true;');
l.add('//$cgp_hide[''company''][''activity''] = true;');
l.add('//$cgp_hide[''company''][''nafcode''] = true;');
l.add('');
l.add('// Contact module');
l.add('//$cgp_hide[''contact''][''function''] = true;');
l.add('//$cgp_hide[''contact''][''contact_title''] = true;');
l.add('//$cgp_hide[''contact''][''responsible''] = true;');
l.add('//$cgp_hide[''contact''][''contact_service''] = true;');
l.add('//$cgp_hide[''contact''][''contact_comment2''] = true;');
l.add('//$cgp_hide[''contact''][''contact_comment3''] = true;');
l.add('//$cgp_hide[''contact''][''contact_date''] = true;');
l.add('');
l.add('//--------------------//');
l.add('// User specific data //');
l.add('//--------------------//');
l.add('// Categories available for modules :');
l.add('// company, contact, incident, document');
l.add('// Lang var definitions here for example : Put these in conf/lang/');
l.add('//$l_companycategory1 = ''Category1'';');
l.add('//$cgp_user[''company''][''category''][''companycategory1''] = array(''mode''=>''multi'');');
l.add('//$l_contactcategory1 = ''Contact category1'';');
l.add('//$cgp_user[''contact''][''category''][''contactcategory1''] = array(''mode''=>''multi'');');
l.add('//$l_contactcategory2 = ''Contact category2'';');
l.add('//$cgp_user[''contact''][''category''][''contactcategory2''] = array(''mode''=>''multi'');');
l.add('//$l_documentcategory1 = ''Doc cat1'';');
l.add('//$cgp_user[''document''][''category''][''documentcategory1''] = array(''mode''=>''mono'');');
l.add('');
l.add('');
l.add('');
l.add('</script>');
logs.WriteToFile(l.text,'/usr/share/obm2/conf/obm_conf.inc');

x.free;
RegExpr.free;
l.free;

end;
//#############################################################################

end.
