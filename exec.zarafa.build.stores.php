<?php
if(posix_getuid()<>0){die("Cannot be used in web server mode\n\n");}
include_once(dirname(__FILE__).'/ressources/class.ldap.inc');
include_once(dirname(__FILE__).'/ressources/class.user.inc');
include_once(dirname(__FILE__).'/ressources/class.ini.inc');
include_once(dirname(__FILE__).'/ressources/class.mysql.inc');
include_once(dirname(__FILE__).'/framework/class.unix.inc');
include_once(dirname(__FILE__).'/framework/frame.class.inc');
include_once(dirname(__FILE__).'/ressources/class.os.system.inc');
$GLOBALS["NOMAIL"]=false;
if(preg_match("#--verbose#",implode(" ",$argv))){$GLOBALS["DEBUG"]=true;$GLOBALS["VERBOSE"]=true;ini_set('display_errors', 1);ini_set('error_reporting', E_ALL);ini_set('error_prepend_string',null);ini_set('error_append_string',null);}
if(preg_match("#--nomail#",implode(" ",$argv))){$GLOBALS["NOMAIL"]=true;}




if($argv[1]=="--relink-to"){relinkto($argv[2],$argv[3]);exit;}
if(system_is_overloaded(basename(__FILE__))){echo "Overloaded, die()";die();}
if($argv[1]=="--orphans"){orphans();die();}
if($argv[1]=="--emergency"){emergency_user($argv[2]);die();}
if($argv[1]=="--export-hash"){export_hash();die();}
if($argv[1]=="--view-hash"){view_hash();die();}
if($argv[1]=="--config"){config();die();}
if($argv[1]=="--ldap-config"){ldap_config();die();}
if($argv[1]=="--exoprhs"){export_orphans();die();}
if($argv[1]=="--remove-database"){remove_database();exit;}
if($argv[1]=="--yaffas"){yaffas();exit;}


die();
sync_users();
function sync_users(){
$unix=new unix();
$zarafaadmin=$unix->find_program("zarafa-admin");

echo "Synchronize external datas\n";
shell_exec("$zarafaadmin --sync");
shell_exec("$zarafaadmin --list-companies");
shell_exec("$zarafaadmin -s");

exec("$zarafaadmin -l",$array);

while (list ($index, $line) = each ($array) ){
	if(preg_match("#\s+(.+?)\s+\s+(.+)#",$line,$re)){
		if(trim($re[1])=="username"){continue;}
		$usernames[]=trim($re[1]);
	}
	
}
if(!is_array($usernames)){return;}


while (list ($index, $user) = each ($usernames) ){
	echo "Create store for $user\n";
	if(system_is_overloaded(basename(__FILE__))){system_admin_events("Task stopped, overloaded system", __FUNCTION__, __FILE__, __LINE__, "zarafa");die();}
	shell_exec("$zarafaadmin --create-store $user");
}

}

function export_orphans(){
if(system_is_overloaded(basename(__FILE__))){system_admin_events("Task stopped, overloaded system", __FUNCTION__, __FILE__, __LINE__, "zarafa");die();}
$unix=new unix();
$q=new mysql();
$q->BuildTables();
$q->QUERY_SQL("TRUNCATE TABLE `zarafa_orphaned`","artica_backup");
$zarafaadmin=$unix->find_program("zarafa-admin");
exec("$zarafaadmin --list-orphans 2>&1",$array);
while (list ($index, $line) = each ($array) ){
	$store=null;
	
	
	if(preg_match("#([A-Z0-9]+)\s+(.+)\s+([0-9\/]+)\s+([0-9:]+)\s+([A-Z]+)\s+([0-9]+)\s+([A-Z]+)#", $line,$re)){
		$store=$re[1];
		$user=$re[2];
		
		$date=strtotime("{$re[3]} {$re[4]} {$re[5]}");
		$distanceOfTimeInWords=$unix->distanceOfTimeInWords($date,time());
		$size=$re[6];
		$unit=$re[7];		
	}

	if($store==null){
		if(preg_match("#([A-Z0-9]+)\s+(.+?)\s+([0-9\/]+)\s+([0-9:]+)\s+([0-9]+)\s+([A-Z]+)#", $line,$re)){
			$store=$re[1];
			$user=$re[2];
			$date=strtotime("{$re[3]} {$re[4]}");	
			$size=$re[5];
			$unit=$re[6];	
		}			
		
	}
	
	if($store==null){
		if(preg_match("#([A-Z0-9]+)\s+(.+?)\s+([0-9\/]+)\s+([0-9:]+)\s+unlimited#", $line,$re)){
			$store=$re[1];
			$user=$re[2];
			$date=strtotime("{$re[3]} {$re[4]}");	
			$size="10240000000000";
			$unit="B";
		}
	}
	
	if($store==null){
		$arraylo[]="No match $line";
		continue;
	}
	
		$distanceOfTimeInWords=$unix->distanceOfTimeInWords($date,time());
		if($unit=="MB"){$size=$size*1000;$size=$size*1024;$unit="B";}
		if($unit=="KB"){$size=$size*1024;$unit="B";}
		if($unit=="GB"){$size=$size*1000;$size=$size*1000;$size=$size*1024;}
		$date=date("Y-m-d H:i:s",$date);
		$textsize=FormatBytes($size/1024);
		$textsize=str_replace("&nbsp;", "", $textsize);
		$f[]="Store $store ($textsize) for user $user is unlinked since $date ($distanceOfTimeInWords)";
		$sql="INSERT IGNORE INTO zarafa_orphaned (storeid,size,zDate,uid) VALUES ('$store','$size','$date','$user')";
		$arraylo[]=$sql;
		$q->QUERY_SQL($sql,"artica_backup");
		if(!$q->ok){
			$unix->send_email_events("Zarafa orphaned status mysql error", $q->mysql_error." will wait a new cycle", "mailbox");
			echo $q->mysql_error."\n";
			return;
		}
		

	
	@file_put_contents("/tmp/zarafa.scan.txt", @implode("\n", $array)."\n".@implode("\n", $arraylo));
}



if(!$GLOBALS["NOMAIL"]){
	if(count($f)>0){
		$timefile="/etc/artica-postfix/pids/".basename(__FILE__).".".__FUNCTION__.".time";
		if($unix->file_time_min($timefile)<300){return;}
		@unlink($timefile);
		@file_put_contents($timefile, time());		
		$unix->send_email_events(count($f)." orphaned store(s)", @implode("\n", $f), "mailbox");
	}
}
	
}



function orphans(){
$unix=new unix();
$zarafaadmin=$unix->find_program("zarafa-admin");
if(!is_file($zarafaadmin)){return ;}
exec("$zarafaadmin --list-orphans 2>&1",$array);
$users=array();
$ff=false;
while (list ($index, $line) = each ($array) ){
	if(preg_match("#Users without stores#",$line)){$ff=true;}
	if(!$ff){continue;}
	if(preg_match("#\s+[0-9+\.\-a-zA-Z@]+$#",$line,$re)){
		$re[1]==trim($re[1]);
		if($re[1]=="Username"){continue;}
		if(strpos($re[1],"---")>0){continue;}
		if($re[1]=="--------------------------------------------------------"){continue;}
		if($re[1]=="---------------"){continue;}
		if($re[1]=="without stores:"){continue;}
		if($GLOBALS["VERBOSE"]){echo "found \"{$re[1]}\"\n";}
		
		$users[$re[1]]=$re[1];
	}
	
}


if(count($users)>1){
	while (list ($uid, $line) = each ($users) ){
		exec("$zarafaadmin --create-store $uid",$results);
		$logs[]="Create store for $uid";
		while (list ($a, $b) = each ($results) ){$logs[]="$b";}
		unset($results);
	}
	
	if($GLOBALS["VERBOSE"]){
		echo @implode("\n",$logs);
	}
	send_email_events("Creating store for ". count($users),"Artica has successfully created store in zarafa server:\n".@implode("\n",$logs));
	
}

	
}

function emergency_user($uid){
	if($uid==null){return;}
	if($GLOBALS["VERBOSE"]){echo "Checking uid:$uid\n";}
	$user=new user($uid);
	$ou=$user->ou;
	if($GLOBALS["VERBOSE"]){echo "Checking OU:$ou\n";}
	if($ou==null){echo "Checking $uid no such organization\n";return;}
	$ldap=new clladp();
	
	$info=$ldap->OUDatas($ou);
	$zarafaEnabled=1;
	if(!$info["objectClass"]["zarafa-company"]){
		$dn="ou=$ou,dc=organizations,$ldap->suffix";
		$upd["objectClass"]="zarafa-company";
		if(!$ldap->Ldap_add_mod("$dn",$upd)){
			echo $ldap->ldap_last_error;
			return;
		}
	}
	
	sync_users();
	orphans();
	
}


function export_hash(){
	
	
	
	$unix=new unix();
	$time=$unix->file_time_min("/etc/artica-postfix/zarafa-export.db");
	
	if($time<240){$unix->events(basename(__FILE__).": /etc/artica-postfix/zarafa-export.db $time Minutes < 240 aborting...");return;}
	
	
	
	$pidfile="/etc/artica-postfix/cron.2/".basename(__FILE__).".".__FUNCTION__.".pid";
	if($unix->process_exists(@file_get_contents($pidfile,basename(__FILE__)))){
		$unix->events(basename(__FILE__).":Already executed, aborting");
		return;
	}
	@file_get_contents($pidfile,getmypid());
	
	
	
	$GLOBALS["zarafa_admin"]=$unix->find_program("zarafa-admin");
	if(!is_file($GLOBALS["zarafa_admin"])){return;}
	$companies=array();
	
	exec("{$GLOBALS["zarafa_admin"]} --list-companies 2>&1",$results);
	while (list ($index, $line) = each ($results) ){
		if($line==null){continue;}
		if(preg_match("#------#",$line)){continue;}
		if(preg_match("#companyname#",$line)){continue;}
		if(preg_match("#list\s+\(#",$line)){continue;}
		if(preg_match("#\s+(.+?)\s+(.+?)$#",$line,$re)){
			$companies[$re[1]]["ADMIN"]=$re[2];
		}
		
		
	}
	
	if(!is_array($companies)){return;}
	while (list ($company, $array) = each ($companies) ){
		$companies[$company]["USERS"]=export_hash_users($company);
		
	}
	
	@unlink("/etc/artica-postfix/zarafa-export.db");
	@file_put_contents("/etc/artica-postfix/zarafa-export.db",base64_encode(serialize($companies)));
	
	
}

function view_hash(){
	
	print_r(unserialize(base64_decode(@file_get_contents("/etc/artica-postfix/zarafa-export.db"))));
	
}

function export_hash_users($company){
	$array=array();
	exec("{$GLOBALS["zarafa_admin"]} -l -I \"$company\" 2>&1",$results);
	while (list ($index, $line) = each ($results) ){
		usleep(5000);
		if($line==null){continue;}
		if(preg_match("#------#",$line)){continue;}
		if(preg_match("#User.+?list#",$line)){continue;}
		if(preg_match("#username\s+fullname#",$line)){continue;}
		if(preg_match("#\s+(.+?)\s+(.+?)$#",$line,$re)){
			$username=trim($re[1]);
			exec("{$GLOBALS["zarafa_admin"]} --details \"$username\" 2>&1",$users_results);
			while (list ($num, $user_line) = each ($users_results) ){
				if(preg_match("#(.+?):(.+?)$#",$user_line,$ri)){
					$field=trim($ri[1]);
					$field=str_replace(" ","_",$field);
					$field=strtoupper($field);
					$array[$username][$field]=trim($ri[2]);
				}
				
			}
			
			
		}
		
		
	}

	return $array;
	
}


function config(){
	$unix=new unix();
	$sock=new sockets();
	$ZarafaAspellEnabled=$sock->GET_INFO("ZarafaAspellEnabled");
	$ZarafaWebNTLM=$sock->GET_INFO("ZarafaWebNTLM");
	$ZarafaEnablePlugins=$sock->GET_INFO("ZarafaEnablePlugins");
	
	if(!is_numeric($ZarafaAspellEnabled)){$ZarafaAspellEnabled=0;}
	if(!is_numeric($ZarafaWebNTLM)){$ZarafaWebNTLM=0;}
	if(!is_numeric($ZarafaEnablePlugins)){$ZarafaEnablePlugins=0;}
	
	
	
	$users=new usersMenus();
	
	if(!$users->ASPELL_INSTALLED){$ZarafaAspellEnabled=0;}
	

	
	
	
$f[]="<?php";
$f[]="ini_set(\"zend.ze1_compatibility_mode\", false);";
$f[]="ini_set(\"max_execution_time\", 300); // 5 minutes";
$f[]="ini_set(\"display_errors\", false);";
$f[]="define(\"CONFIG_CHECK\", TRUE);";
$f[]="define(\"DEFAULT_SERVER\",\"file:///var/run/zarafa\");";
$f[]="define(\"SSLCERT_FILE\", NULL);";
$f[]="define(\"SSLCERT_PASS\", NULL);";
if($ZarafaWebNTLM==1){
	$f[]="define(\"LOGINNAME_STRIP_DOMAIN\", true);";
}else{
	$f[]="define(\"LOGINNAME_STRIP_DOMAIN\", false);";
}
$f[]="if (isset(\$_GET[\"external\"]) && preg_match(\"/[a-z][a-z0-9_]+/i\",\$_GET[\"external\"])){define(\"COOKIE_NAME\",\$_GET[\"external\"]);}else{define(\"COOKIE_NAME\",\"ZARAFA_WEBACCESS\");}";
$f[]="define(\"THEME_COLOR\", \"default\");\$base_url = dirname(\$_SERVER[\"PHP_SELF\"]);if(substr(\$base_url,-1)!=\"/\") \$base_url .=\"/\";";
$f[]="define(\"BASE_URL\", \$base_url);";
$f[]="define(\"BASE_PATH\", dirname(\$_SERVER[\"SCRIPT_FILENAME\"]) . \"/\");";
$f[]="define(\"MIME_TYPES\", BASE_PATH . \"server/mimetypes.dat\");";
$f[]="define(\"TMP_PATH\", \"/var/lib/zarafa-webaccess/tmp\");";
$f[]="set_include_path(BASE_PATH. PATH_SEPARATOR . BASE_PATH.\"server/PEAR/\" .  PATH_SEPARATOR . \"/usr/share/php/\");";
$f[]="define(\"DIALOG_URL\", \"index.php?load=dialog&\");";
$f[]="define(\"DND_FILEUPLOAD_URL\", \"index.php?load=upload_attachment&\");";
$f[]="define(\"PATH_PLUGIN_DIR\", \"plugins\");";
if($ZarafaEnablePlugins==1){
$f[]="define(\"ENABLE_PLUGINS\", false);";
}else{
$f[]="define(\"ENABLE_PLUGINS\", true);";	
}
$f[]="define(\"DISABLED_PLUGINS_LIST\", \"\");";
$f[]="define(\"DISABLE_FULL_GAB\", false);";
$f[]="define(\"DISABLE_FULL_CONTACTLIST_THRESHOLD\", -1);";
$f[]="define(\"ENABLE_GAB_ALPHABETBAR\", false);";
$f[]="define(\"FREEBUSY_DAYBEFORE_COUNT\", 7);";
$f[]="define(\"FREEBUSY_NUMBEROFDAYS_COUNT\", 90);";
$f[]="define(\"BLOCK_SIZE\", 1048576);";
$f[]="define(\"CLIENT_TIMEOUT\", 5*60*1000);";
$f[]="define(\"EXPIRES_TIME\", 60*60*24*7*13);";
$f[]="define(\"UPLOADED_ATTACHMENT_MAX_LIFETIME\", 6*60*60);";
$f[]="define(\"FCKEDITOR_PATH\",dirname(\$_SERVER[\"SCRIPT_FILENAME\"]).\"/client/widgets/fckeditor\");";
$f[]="define(\"FCKEDITOR_JS_PATH\",\"client/widgets/fckeditor\");";

	if($ZarafaAspellEnabled==1){
		$asspellbin=$unix->find_program("aspell");
		$f[]="define(\"FCKEDITOR_SPELLCHECKER_ENABLED\", true);";
		$f[]="define(\"FCKEDITOR_SPELLCHECKER_PATH\", \"$asspellbin\");";	
		echo "Starting zarafa..............: Aspell checker is enabled\n";		
		
	}else{
		$f[]="define(\"FCKEDITOR_SPELLCHECKER_ENABLED\", false);";	
		$f[]="define(\"FCKEDITOR_SPELLCHECKER_PATH\", \"/usr/bin/aspell\");";
		echo "Starting zarafa..............: Aspell checker is disabled\n";
	}

$f[]="define(\"FCKEDITOR_SPELLCHECKER_LANGUAGE\", FALSE); // set FALSE to use the language chosen by the user, but make sure that these languages are installed with aspell!";
$f[]="define(\"LANGUAGE_DIR\", \"server/language/\");";
$f[]="if (isset(\$_ENV[\"LANG\"]) && \$_ENV[\"LANG\"]!=\"C\"){";
$f[]="	define(\"LANG\", \$_ENV[\"LANG\"]); // This means the server environment language determines the web client language.";
$f[]="	}else{";
$f[]="define(\"LANG\", \"en_EN\"); // default fallback language";
$f[]="	}";
$f[]="";
$f[]="if (function_exists(\"date_default_timezone_set\")){date_default_timezone_set(\"Europe/London\");}";
$f[]="error_reporting(0);";
$f[]="if (file_exists(\"debug.php\")){include(\"debug.php\");}else{function dump(){}}";
$f[]="?>";	

@file_put_contents("/usr/share/zarafa-webaccess/config.php",@implode("\n",$f));
echo "Starting zarafa..............: web config.php done\n";	
}


function ldap_config(){
	
	$sock=new sockets();
	$CyrusToAD=$sock->GET_INFO("CyrusToAD");
	$prefix="dc=organizations,";
	$ldap_user_type_attribute_value="posixAccount";
	$ldap_user_search_filter="(objectClass=userAccount)";
	$ldap_user_unique_attribute="uidNumber";
	$ldap_user_unique_attribute_type = "text";
	$ldap=new clladp();
	$user="cn=$ldap->ldap_admin,$ldap->suffix";
	$ldap_loginname_attribute="uid";
	$ldap_password_attribute="userPassword";
	$ldap_nonactive_attribute="zarafaSharedStoreOnly";
	//$ldap_group_search_filter = "(objectClass=posixGroup)";
	$ldap_group_unique_attribute = "gidNumber";
	$ldap_group_unique_attribute_type="text";
	$ldap_groupname_attribute="cn";	
	$ldap_addresslist_search_filter = "(objectClass=zarafaAddressList)";
	$ldap_contact_type_attribute_value="zarafa-contact";
	$ldap_groupmembers_attribute="memberUid";
	$ldap_groupmembers_attribute_type="text";
	$ldap_groupmembers_relation_attribute="uid";
	$ldap_emailaliases_attribute="mailAlias";
	$ldap_user_sendas_relation_attribute="uidNumber";
	
	if($CyrusToAD==1){
		$ldap=new ldapAD();
		$prefix=null;
		$user="$ldap->ldap_admin,$ldap->suffix";
		$ldap_user_type_attribute_value="sAMAccountName";
		$ldap_user_sendas_relation_attribute="sAMAccountName";
		$ldap_user_search_filter="(zarafaAccount=1)";
		$ldap_user_unique_attribute="objectGUID";
		$ldap_user_unique_attribute_type = "binary";
		$ldap_loginname_attribute="sAMAccountName";
		$ldap_password_attribute=null;
		$ldap_group_search_filter=null;
		$ldap_group_unique_attribute="objectSid";
		$ldap_group_unique_attribute_type="binary";
		$ldap_groupname_attribute="dn";
		$ldap_addresslist_search_filter=null;
		$ldap_contact_type_attribute_value="Contact";
		$ldap_groupmembers_attribute="member";
		$ldap_groupmembers_attribute_type="dn";
		$ldap_groupmembers_relation_attribute=null;
		$ldap_emailaliases_attribute ="otherMailbox";
		
	}
	
	
	
$f[]="# ---------- GENERAL ------------#";
$f[]="ldap_host = $ldap->ldap_host";
$f[]="ldap_port = $ldap->ldap_port";
$f[]="ldap_search_base = $prefix$ldap->suffix";
$f[]="ldap_protocol = ldap";
$f[]="ldap_server_charset = utf-8";
$f[]="ldap_bind_user = $user";
$f[]="ldap_bind_passwd = $ldap->ldap_password";
$f[]="ldap_network_timeout = 30";
$f[]="ldap_object_type_attribute = objectClass";
$f[]="";
if($CyrusToAD==1){
	$f[]="ldap_user_type_attribute_value = User";
	$f[]="ldap_group_type_attribute_value = Group";
	$f[]="ldap_company_type_attribute_value = ou";
	$f[]="ldap_addresslist_type_attribute_value = zarafa-addresslist";
	$f[]="ldap_dynamicgroup_type_attribute_value = zarafa-dynamicgroup";
}
$f[]="ldap_contact_type_attribute_value = $ldap_contact_type_attribute_value";
$f[]="# ---------- USERS ------------#";
$f[]="ldap_user_search_base =  $prefix$ldap->suffix";
$f[]="ldap_user_scope = sub";
$f[]="ldap_user_type_attribute_value = $ldap_user_type_attribute_value";
$f[]="ldap_user_search_filter = $ldap_user_search_filter";
$f[]="";
$f[]="ldap_user_unique_attribute = $ldap_user_unique_attribute";
$f[]="ldap_user_unique_attribute_type = $ldap_user_unique_attribute_type";
$f[]="";
$f[]="ldap_user_sendas_attribute = zarafaSendAsPrivilege";
$f[]="ldap_user_sendas_attribute_type = text";
$f[]="ldap_user_sendas_relation_attribute =";
$f[]="";
$f[]="ldap_user_certificate_attribute = userCertificate";
$f[]="ldap_fullname_attribute = displayName";
$f[]="ldap_authentication_method = password";
$f[]="ldap_loginname_attribute = $ldap_loginname_attribute";
$f[]="ldap_password_attribute = $ldap_password_attribute";
$f[]="ldap_emailaddress_attribute = mail";
$f[]="ldap_emailaliases_attribute = $ldap_emailaliases_attribute";

$f[]="ldap_isadmin_attribute = zarafaAdmin";
$f[]="ldap_nonactive_attribute =$ldap_nonactive_attribute";
$f[]="";
$f[]="# ---------- GROUPS ------------#";
$f[]="ldap_group_search_base = $prefix$ldap->suffix";
$f[]="ldap_group_scope = sub";
$f[]="ldap_group_search_filter = $ldap_group_search_filter";
$f[]="ldap_group_unique_attribute = $ldap_group_unique_attribute";
$f[]="ldap_group_unique_attribute_type = $ldap_group_unique_attribute_type";
$f[]="ldap_groupname_attribute = $ldap_groupname_attribute";
if($CyrusToAD==0){
	$f[]="ldap_group_type_attribute_value = posixGroup";
}else{
	$f[]="ldap_group_security_attribute = groupType";
	$f[]="ldap_group_security_attribute_type = ads";
}
$f[]="ldap_groupmembers_attribute = $ldap_groupmembers_attribute";
$f[]="ldap_groupmembers_attribute_type = $ldap_groupmembers_attribute_type";
$f[]="ldap_groupmembers_relation_attribute =$ldap_groupmembers_relation_attribute";

$f[]="";
$f[]="";
$f[]="# ---------- COMPAGNIES ------------#";
$f[]="ldap_company_unique_attribute = ou";
$f[]="ldap_company_search_base = $prefix$ldap->suffix";
$f[]="ldap_company_scope = base";
$f[]="ldap_company_search_filter =(&(objectclass=organizationalUnit)(objectClass=zarafa-company))";
$f[]="ldap_company_type_attribute_value = organizationalUnit";
$f[]="";
$f[]="ldap_companyname_attribute = ou";
$f[]="";
$f[]="ldap_company_view_attribute = zarafaViewPrivilege";
$f[]="ldap_company_view_attribute_type = text";
$f[]="ldap_company_view_relation_attribute =";
$f[]="";
$f[]="ldap_company_admin_attribute = zarafaAdminPrivilege";
$f[]="ldap_company_admin_attribute_type = text";
$f[]="ldap_company_admin_relation_attribute = $ldap_user_sendas_relation_attribute ";
$f[]="";
$f[]="ldap_company_system_admin_attribute = zarafaSystemAdmin";
$f[]="ldap_company_system_admin_attribute_type = text";
$f[]="ldap_company_system_admin_relation_attribute =";
$f[]="";
$f[]="";


$f[]="ldap_quota_userwarning_recipients_attribute = zarafaQuotaUserWarningRecipients";
$f[]="ldap_quota_userwarning_recipients_attribute_type = text";
$f[]="ldap_quota_userwarning_recipients_relation_attribute =";
$f[]="ldap_quota_companywarning_recipients_attribute = zarafaQuotaCompanyWarningRecipients";
$f[]="ldap_quota_companywarning_recipients_attribute_type = text";
$f[]="ldap_quota_companywarning_recipients_relation_attribute=";
$f[]="";
$f[]="";
$f[]="ldap_quotaoverride_attribute = zarafaQuotaOverride";
$f[]="ldap_warnquota_attribute = zarafaQuotaWarn";
$f[]="ldap_softquota_attribute = zarafaQuotaSoft";
$f[]="ldap_hardquota_attribute = zarafaQuotaHard";
$f[]="ldap_userdefault_quotaoverride_attribute = zarafaUserDefaultQuotaOverride";
$f[]="ldap_userdefault_warnquota_attribute = zarafaUserDefaultQuotaWarn";
$f[]="ldap_userdefault_softquota_attribute = zarafaUserDefaultQuotaSoft";
$f[]="ldap_userdefault_hardquota_attribute = zarafaUserDefaultQuotaHard";
$f[]="";
$f[]="";
$f[]="ldap_quota_multiplier = 1048576";
$f[]="";
$f[]="";
$f[]="ldap_user_department_attribute = departmentNumber";
$f[]="ldap_user_location_attribute = physicalDeliveryOfficeName";
$f[]="ldap_user_telephone_attribute = telephoneNumber";
$f[]="ldap_user_fax_attribute = facsimileTelephoneNumber";
$f[]="ldap_last_modification_attribute = modifyTimestamp";
$f[]="ldap_object_search_filter =(|(mail=%s*)(uid=%s*)(cn=*%s*)(sAMAccountName=*%s*)(fullname=*%s*)(givenname=*%s*)(lastname=*%s*)(sn=*%s*)) ";
$f[]="ldap_filter_cutoff_elements = 1000";
$f[]="ldap_addresslist_search_base = $prefix$ldap->suffix";
$f[]="ldap_addresslist_scope = sub";
$f[]="ldap_addresslist_search_filter = $ldap_addresslist_search_filter";
$f[]="ldap_addresslist_unique_attribute = cn";
$f[]="ldap_addresslist_unique_attribute_type = text";
$f[]="ldap_addresslist_filter_attribute = zarafaFilter";
$f[]="ldap_addresslist_name_attribute = cn";

if(is_file('/etc/zarafa/ldap.propmap.cfg')){
	$f[]="";
	$f[]="!propmap /etc/zarafa/ldap.propmap.cfg";
}
      


$f[]="";
$f[]="";
if(!is_dir("/etc/zarafa")){@mkdir("/etc/zarafa");}
@file_put_contents("/etc/zarafa/ldap.openldap.cfg",@implode("\n",$f));
echo "Starting zarafa..............: LDAP config done (".basename(__FILE__).")\n";

	
}
function remove_database(){
	shell_exec("/bin/rm -f /var/lib/mysql/ib_logfile*");
	shell_exec("/bin/rm -f /var/lib/mysql/ibdata*");
	shell_exec("/bin/rm -rf /var/lib/mysql/zarafa");
	shell_exec("/etc/init.d/artica-postfix restart mysql >/tmp/zarafa_removedb 2>&1");
	shell_exec("/etc/init.d/artica-postfix restart zarafa-server >>/tmp/zarafa_removedb 2>&1");
	$unix=new unix();
	$unix->send_email_events("Success removing zarafa databases", 
	"removed /var/lib/mysql/ib_logfile*\nremoved /var/lib/mysql/ibdata*\nremoved /var/lib/mysql/zarafa\n\n".@file_get_contents("/tmp/zarafa_removedb"), "mailbox");
}

function yaffas(){
	if(!is_file("/opt/yaffas/lib/perl5/Yaffas/Constant.pm")){return;}
	echo "Starting Yaffas..............: Checking Constant.pm\n";	
	$patch=false;
	$f=explode("\n", @file_get_contents("/opt/yaffas/lib/perl5/Yaffas/Constant.pm"));
	while (list ($num, $line) = each ($f) ){	
		if(preg_match("#case.+?Debian#", $line,$re)){echo "Starting Yaffas..............: Already patched\n";break;}
		
		if(preg_match("#case qr\/Ubuntu\/#", $line,$re)){
			echo "Starting Yaffas..............: Patching Constant.pm\n";	
			$patch=true;
			$f[$num]="\tcase qr/Ubuntu|Debian/ { return \"Ubuntu\"; }";
		}
		
	}
	
	if($patch){@file_get_contents("/opt/yaffas/lib/perl5/Yaffas/Constant.pm",@implode("\n", $f));}
	$unix=new unix();
	$ln=$unix->find_program("ln");
	echo "Starting Yaffas..............: checking symbolic links...\n";
	shell_exec("$ln -s /opt/yaffas/webmin/theme-core/assets /opt/yaffas/webmin/yaffastheme/assets >/dev/null 2>&1");
	shell_exec("$ln -s /opt/yaffas/webmin/theme-core/config /opt/yaffas/webmin/yaffastheme/config  >/dev/null 2>&1");
	shell_exec("$ln -s /opt/yaffas/webmin/theme-core/globals.cgi /opt/yaffas/webmin/yaffastheme/globals.cgi  >/dev/null 2>&1");
	shell_exec("$ln -s /opt/yaffas/webmin/theme-core/index.cgi /opt/yaffas/webmin/yaffastheme/index.cgi >/dev/null 2>&1");
	shell_exec("$ln -s /opt/yaffas/webmin/theme-core/javascript /opt/yaffas/webmin/yaffastheme/javascript >/dev/null 2>&1");
	shell_exec("$ln -s /opt/yaffas/webmin/theme-core/session_login.cgi /opt/yaffas/webmin/yaffastheme/session_login.cgi >/dev/null 2>&1");
	echo "Starting Yaffas..............: Config done...\n";
	
	
	
}

function relinkto($from,$to){
	if($from==null){system_admin_events("Unhooking store failed, from is not specified", __FUNCTION__, __FILE__, __LINE__, "zarafa");return;}
	if($to==null){system_admin_events("Unhooking store failed, recipient is not specified", __FUNCTION__, __FILE__, __LINE__, "zarafa");return;}
	$unix=new unix();
	$zarafaadmin=$unix->find_program("zarafa-admin");
	$fromRegex=$from;
	$fromRegex=str_replace(".", "\.", $fromRegex);
	$store_guid=array();
	exec("$zarafaadmin --unhook-store \"$from\" 2>&1",$results);
	system_admin_events("Unhooking store for $from:\n".@implode("\n", $results), __FUNCTION__, __FILE__, __LINE__, "zarafa");
	$pattern="#([A-Z0-9]+)\s+$fromRegex\s+#";
	exec("$zarafaadmin --list-orphans 2>&1",$array);	
	while (list ($num, $line) = each ($array) ){
		if(preg_match($pattern, $line,$re)){
			$store_guid[]=$re[1];
			break;
		}
	}	
	
	if(count($store_guid)==0){
		system_admin_events("Failed, Unable to get unhooked store from $from !!!", __FUNCTION__, __FILE__, __LINE__, "zarafa");
		return;
	}
	while (list ($index, $storeid) = each ($store_guid) ){
		$results=array();
		exec("$zarafaadmin --hook-store $storeid -u $to --copyto-public 2>&1",$results);
		system_admin_events("hook store $storeid for $from to public folder of $to:\n".@implode("\n", $results), __FUNCTION__, __FILE__, __LINE__, "zarafa");
	}

}



?>