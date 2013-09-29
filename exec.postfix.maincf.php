<?php
if(posix_getuid()<>0){die("Cannot be used in web server mode\n\n");}
include_once(dirname(__FILE__).'/ressources/class.templates.inc');
include_once(dirname(__FILE__).'/ressources/class.ini.inc');
include_once(dirname(__FILE__).'/ressources/class.mysql.inc');
include_once(dirname(__FILE__).'/ressources/class.ldap.inc');
include_once(dirname(__FILE__).'/ressources/class.main_cf.inc');
include_once(dirname(__FILE__).'/ressources/class.maincf.multi.inc');
include_once(dirname(__FILE__).'/ressources/class.main_cf_filtering.inc');
include_once(dirname(__FILE__).'/ressources/class.policyd-weight.inc');
include_once(dirname(__FILE__).'/ressources/class.main.hashtables.inc');
include_once(dirname(__FILE__).'/framework/class.unix.inc');
include_once(dirname(__FILE__).'/framework/frame.class.inc');
$GLOBALS["RELOAD"]=false;
$GLOBALS["URGENCY"]=false;
$GLOBALS["AS_ROOT"]=true;
$_GET["LOGFILE"]="/usr/share/artica-postfix/ressources/logs/web/interface-postfix.log";
if(!is_file("/usr/share/artica-postfix/ressources/settings.inc")){shell_exec("/usr/share/artica-postfix/bin/process1 --force --verbose");}
if(preg_match("#--verbose#",implode(" ",$argv))){$GLOBALS["DEBUG"]=true;$GLOBALS["VERBOSE"]=true;ini_set('display_errors', 1);ini_set('error_reporting', E_ALL);ini_set('error_prepend_string',null);ini_set('error_append_string',null);}
if(preg_match("#--reload#",implode(" ",$argv))){$GLOBALS["RELOAD"]=true;}
if(preg_match("#--urgency#",implode(" ",$argv))){$GLOBALS["URGENCY"]=true;}

if(!isset($GLOBALS["CLASS_SOCKET"])){$GLOBALS["CLASS_SOCKET"]=new sockets();$sock=$GLOBALS["CLASS_SOCKET"];}else{$sock=$GLOBALS["CLASS_SOCKET"];}
$unix=new unix();

$pidfile="/etc/artica-postfix/".basename(__FILE__)." ". md5(implode("",$argv)).".pid";
if($unix->process_exists(@file_get_contents($pidfile),basename(__FILE__))){echo "Starting......: Postfix configurator already executed PID ". @file_get_contents($pidfile)."\n";die();}
$pid=getmypid();
echo "Starting......: Postfix configurator running $pid\n";
file_put_contents($pidfile,$pid);
if($argv[1]=='--wlscreen'){wlscreen();die();}





$users=new usersMenus();
$GLOBALS["CLASS_USERS_MENUS"]=$users;
if(!$users->POSTFIX_INSTALLED){echo("Postfix is not installed\n");die();}


if(!$unix->IS_OPENLDAP_RUNNING()){echo "Starting......: Postfix openldap is not running, start it\n";system("/etc/init.d/artica-postfix start ldap");}
if(!$unix->IS_OPENLDAP_RUNNING()){echo "Starting......: Postfix openldap is not running, aborting\n";die();}

$ldap=new clladp();
if($ldap->ldapFailed){echo "Starting......: Postfix openldap error, aborting\n";die();	}

if(!$ldap->ExistsDN("dc=organizations,$ldap->suffix")){echo "Starting......: Postfix openldap is not ready, aborting\n";die();}
echo "Starting......: Postfix openldap server success\n";

$q=new mysql();
if(!$q->test_mysql_connection()){echo "Starting......: Postfix mysql is not ready aborting...\n";die();}
echo "Starting......: Postfix mysql server success\n";

if($argv[1]=='--notifs-templates-force'){postfix_templates();die();}


$GLOBALS["EnablePostfixMultiInstance"]=$sock->GET_INFO("EnablePostfixMultiInstance");
$GLOBALS["EnableBlockUsersTroughInternet"]=$sock->GET_INFO("EnableBlockUsersTroughInternet");
$GLOBALS["postconf"]=$unix->find_program("postconf");
$GLOBALS["postmap"]=$unix->find_program("postmap");
$GLOBALS["postfix"]=$unix->find_program("postfix");
if($argv[1]=='--loadbalance'){haproxy_compliance();ReloadPostfix(true);die();}
if($argv[1]=='--ScanLibexec'){ScanLibexec();die();}



if($argv[1]=='--networks'){mynetworks();MailBoxTransport();ReloadPostfix(true);HashTables();die();}
if($argv[1]=='--headers-check'){headers_check();die();}
if($argv[1]=='--headers-checks'){headers_check();die();}
if($argv[1]=='--assp'){ASSP_LOCALDOMAINS();die();}
if($argv[1]=='--artica-filter'){MasterCFBuilder(true);die();}
if($argv[1]=='--ldap-branch'){BuildDefaultBranchs();die();}
if($argv[1]=='--ssl'){MasterCFBuilder(true);die();}
if($argv[1]=='--ssl-on'){MasterCFBuilder(true);die();}
if($argv[1]=='--ssl-off'){MasterCFBuilder(true);die();}
if($argv[1]=='--imap-sockets'){imap_sockets();MailBoxTransport();ReloadPostfix(true);die();}
if($argv[1]=='--policyd-reconfigure'){policyd_weight_reconfigure();die();}
if($argv[1]=='--restricted'){RestrictedForInternet(true);die();}
if($argv[1]=='--others-values'){OthersValues();CleanMyHostname();perso_settings();ReloadPostfix(true);die();}
if($argv[1]=='--mime-header-checks'){mime_header_checks();headers_check();BodyChecks();ReloadPostfix(true);die();}
if($argv[1]=='--interfaces'){inet_interfaces();MailBoxTransport();exec("{$GLOBALS["postfix"]} stop");exec("{$GLOBALS["postfix"]} start");ReloadPostfix(true);die();}
if($argv[1]=='--mailbox-transport'){MailBoxTransport();ReloadPostfix(true);die();}
if($argv[1]=='--disable-smtp-sasl'){disable_smtp_sasl();ReloadPostfix(true);die();}
if($argv[1]=='--perso-settings'){perso_settings();HashTables();die();}
if($argv[1]=='--luser-relay'){luser_relay();die();}
if($argv[1]=='--smtp-sender-restrictions'){smtp_cmdline_restrictions();ReloadPostfix(true);die();}
if($argv[1]=='--postdrop-perms'){fix_postdrop_perms();exit;}
if($argv[1]=='--smtpd-restrictions'){smtp_cmdline_restrictions();die();}
if($argv[1]=='--repair-locks'){repair_locks();exit;}
if($argv[1]=='--smtp-sasl'){SetSALS();SetTLS();smtpd_recipient_restrictions();smtp_sasl_security_options();MasterCFBuilder();MailBoxTransport();ReloadPostfix(true);exit;}
if($argv[1]=='--memory'){memory();exit;}
if($argv[1]=='--postscreen'){postscreen($argv[2]);ReloadPostfix(true);exit;}
if($argv[1]=='--freeze'){ReloadPostfix(true);exit;}
if($argv[1]=='--body-checks'){BodyChecks();ReloadPostfix(true);exit;}
if($argv[1]=='--amavis-internal'){amavis_internal();ReloadPostfix(true);exit;}
if($argv[1]=='--notifs-templates'){postfix_templates();ReloadPostfix(true);exit;}
if($argv[1]=='--restricted-domains'){restrict_relay_domains();exit;}
if($argv[1]=='--debug-peer-list'){debug_peer_list();ReloadPostfix(true);die();}
if($argv[1]=='--badnettr'){badnettr($argv[2],$argv[3],$argv[4]);ReloadPostfix(true);die();}
if($argv[1]=='--milters'){smtpd_milters();RestartPostix();die();}



function SEND_PROGRESS($POURC,$text,$error=null){
	$cache="/usr/share/artica-postfix/ressources/logs/web/POSTFIX_COMPILES";
	if($error<>null){echo "FATAL !!!! $error\n";}
	echo "{$POURC}% $text\n";
	
	$array=unserialize(@file_get_contents($cache));
	$array["POURC"]=$POURC;
	$array["TEXT"]=$text;
	if($error<>null){$array["ERROR"][]=$error;}
	@mkdir(dirname($cache),0755,true);
	@file_put_contents($cache, serialize($array));
	@chmod($cache, 0777);
	
}



if($argv[1]=='--reconfigure'){
	
	$unix=new unix();
	$pidfile="/etc/artica-postfix/pids/postfix.reconfigure2.pid";
	$oldpid=$unix->get_pid_from_file($pidfile);
	if($unix->process_exists($oldpid,basename(__FILE__))){
		$time=$unix->PROCCESS_TIME_MIN($oldpid);
		if($GLOBALS["OUTPUT"]){echo "Starting......: [INIT]: reconfigure2: Postfix Already Artica task running PID $oldpid since {$time}mn\n";}
		die();
	}
	
	$pidfile="/etc/artica-postfix/pids/".basename(__FILE__).".reconfigure.pid";
	$oldpid=$unix->get_pid_from_file($pidfile);
	if($unix->process_exists($oldpid,basename(__FILE__))){
		$time=$unix->PROCCESS_TIME_MIN($oldpid);
		if($GLOBALS["OUTPUT"]){echo "Starting......: [INIT]: Postfix Already Artica task running PID $oldpid since {$time}mn\n";}
		die();
	}
	@file_put_contents($pidfile, getmypid());	
	
	
	if($GLOBALS["EnablePostfixMultiInstance"]==1){
		shell_exec(LOCATE_PHP5_BIN2()." ".dirname(__FILE__)."/exec.postfix-multi.php --from-main-reconfigure");
	}
	
	$t1=time();
	$main=new main_cf();
	SEND_PROGRESS(2,"Writing mainc.cf...");
	$main->save_conf_to_server(1);
	SEND_PROGRESS(4,"Writing mainc.cf done...");
	if(!is_file("/etc/postfix/hash_files/header_checks.cf")){@file_put_contents("/etc/postfix/hash_files/header_checks.cf","#");}
	
	SEND_PROGRESS(5,"Building all settings...");
	_DefaultSettings();
	HashTables();
	$unix->send_email_events("Postfix: postfix compilation done. Took :".$unix->distanceOfTimeInWords($t1,time()), "No content yet...\nShould be an added feature :=)", "postfix");
	SEND_PROGRESS(100,"Configuration done");
	die();
}




_DefaultSettings();



function smtp_cmdline_restrictions(){
		
		
		
	    $sock=new sockets();
	    $disable_vrfy_command=$sock->GET_INFO("disable_vrfy_command");
	    if(!is_numeric($disable_vrfy_command)){$disable_vrfy_command=0;}
	    if($disable_vrfy_command==1){postconf("disable_vrfy_command","yes");}else{postconf("disable_vrfy_command","no");}
	
	
		if($GLOBALS["VERBOSE"]){echo "\n ***\nStarting......: Postfix -> smtpd_recipient_restrictions() function\n ***\n";}
		smtpd_recipient_restrictions();
		if($GLOBALS["VERBOSE"]){echo "\n ***\nStarting......: Postfix -> smtpd_client_restrictions() function\n ***\n";}
		smtpd_client_restrictions();
		if($GLOBALS["VERBOSE"]){echo "\n ***\nStarting......: Postfix -> smtpd_sender_restrictions() function\n ***\n";}
		smtpd_sender_restrictions();
		
		if($GLOBALS["VERBOSE"]){echo "\n ***\nStarting......: Postfix -> smtpd_data_restrictions() function\n ***\n";}
		smtpd_data_restrictions();
		if($GLOBALS["VERBOSE"]){echo "\n ***\nStarting......: Postfix -> smtpd_end_of_data_restrictions() function\n ***\n";}
		smtpd_end_of_data_restrictions();
		if($GLOBALS["RELOAD"]){
			if($GLOBALS["VERBOSE"]){echo "\n ***\nStarting......: Postfix -> ReloadPostfix() function\n ***\n";}
			ReloadPostfix(true);
			
		}	
		HashTables();
	
}

function smtpd_data_restrictions(){
	include_once(dirname(__FILE__)."/ressources/class.smtp_data_restrictions.inc");
	$smtpd_data_restrictions=new smtpd_data_restrictions("master");
	if($GLOBALS["VERBOSE"]){echo "Starting......: Postfix -> smtpd_data_restrictions->compile() function\n";}
	$smtpd_data_restrictions->compile();
	if($GLOBALS["VERBOSE"]){echo "Starting......: Postfix -> compiled \"$smtpd_data_restrictions->restriction_final\"\n";}
	if($smtpd_data_restrictions->restriction_final<>null){
		postconf("smtpd_data_restrictions",$smtpd_data_restrictions->restriction_final);
	}
}

function HashTables($start=0){
	$unix=new unix();
	$php5=$unix->LOCATE_PHP5_BIN();
	$nohup=$unix->find_program("nohup");	
	shell_exec("$php5 /usr/share/artica-postfix/exec.postfix.hashtables.php --pourc=$start");
}

function _DefaultSettings(){
if($GLOBALS["EnablePostfixMultiInstance"]==1){shell_exec(LOCATE_PHP5_BIN2()." ".dirname(__FILE__)."/exec.postfix-multi.php --from-main-null");return;}
	$start=5;
	$functions=array(
		"cleanMultiplesInstances","SetTLS","inet_interfaces","imap_sockets","MailBoxTransport","mynetworks",
		"headers_check","mime_header_checks","smtpd_recipient_restrictions","smtpd_client_restrictions_clean",
		"smtpd_client_restrictions","smtpd_sasl_exceptions_networks","sender_bcc_maps","CleanMyHostname","OthersValues","luser_relay",
		"smtpd_sender_restrictions"	,"smtpd_end_of_data_restrictions","perso_settings","remove_virtual_mailbox_base","postscreen",
		"smtp_sasl_security_options","smtp_sasl_auth_enable","SetSALS","BodyChecks","postfix_templates","debug_peer_list","haproxy_compliance","smtpd_milters",
		"MasterCFBuilder","ReloadPostfix"
			
			
	);
	
	$tot=count($functions);
	$i=0;
	while (list ($num, $func) = each ($functions) ){
		$i++;
		$start++;
		if(!function_exists($func)){
			SEND_PROGRESS($start,$func,"Error $func no such function...");
			continue;
		}
			
			
		try {
			SEND_PROGRESS($start,"Action 1, {$start}% Please wait, executing $func() $i/$tot..");
			call_user_func($func);
		} catch (Exception $e) {
			SEND_PROGRESS($start,$func,"Error on $func ($e)");
		}			
	}
	
	
	
	
	
	if($GLOBALS["URGENCY"]){
		$unix=new unix();
		$php5=$unix->LOCATE_PHP5_BIN();
		$nohup=$unix->find_program("nohup");
		shell_exec("$nohup $php5 /usr/share/artica-postfix/exec.postfix.hashtables.php >/dev/null 2>&1 &");
	}else{
		HashTables($start);
	}
	
}



if($argv[1]=='--write-maincf'){
	$unix=new unix();
	if($GLOBALS["EnablePostfixMultiInstance"]==1){shell_exec(LOCATE_PHP5_BIN2()." ".dirname(__FILE__)."/exec.postfix-multi.php --from-main-write-maincf");return;}
	echo "Starting......: Postfix Postfix Multi Instance disabled, single instance mode\n";
	$main=new main_cf();
	$main->save_conf_to_server(1);
	file_put_contents('/etc/postfix/main.cf',$main->main_cf_datas);
	echo "Starting......: Postfix Building main.cf ". strlen($main->main_cf_datas). "line ". __LINE__." bytes done\n";
	if(!is_file("/etc/postfix/hash_files/header_checks.cf")){@file_put_contents("/etc/postfix/hash_files/header_checks.cf","#");}
	_DefaultSettings();
	perso_settings();
	if($argv[2]=='no-restart'){appliSecu();die();}
	echo "Starting......: restarting postfix\n";
	$unix->send_email_events("Postfix will be restarted","Line: ". __LINE__."\nIn order to apply new configuration file","postfix");
	shell_exec("/etc/init.d/artica-postfix restart postfix-single");
	HashTables();
	die();
}

if($argv[1]=='--maincf'){
	if($GLOBALS["EnablePostfixMultiInstance"]==1){shell_exec(LOCATE_PHP5_BIN2()." ".dirname(__FILE__)."/exec.postfix-multi.php --from-main-maincf");return;}	
	$main=new main_cf();
	$main->save_conf_to_server(1);
	file_put_contents('/etc/postfix/main.cf',$main->main_cf_datas);
	_DefaultSettings();
	perso_settings();
	if($GLOBALS["DEBUG"]){echo @file_get_contents("/etc/postfix/main.cf");}
	HashTables();
	die();
}





function ASSP_LOCALDOMAINS(){
	if($GLOBALS["EnablePostfixMultiInstance"]==1){return null;}
	if(!is_dir("/usr/share/assp/files")){return null;}
	$ldap=new clladp();
	$domains=$ldap->hash_get_all_domains();
	while (list ($num, $ligne) = each ($domains) ){
		$conf=$conf."$ligne\n";
	}
	echo "Starting......: ASSP ". count($domains)." local domains\n"; 
	@file_put_contents("/usr/share/assp/files/localdomains.txt",$conf);
	HashTables();
	
}

function SetSALS(){
	if(!isset($GLOBALS["CLASS_SOCKET"])){$GLOBALS["CLASS_SOCKET"]=new sockets();$sock=$GLOBALS["CLASS_SOCKET"];}else{$sock=$GLOBALS["CLASS_SOCKET"];}
	$PostFixSmtpSaslEnable=$sock->GET_INFO("PostFixSmtpSaslEnable");
	$main=new main_cf();
	if($main->main_array["smtpd_tls_session_cache_timeout"]==null){$main->main_array["smtpd_tls_session_cache_timeout"]='3600s';}
	if($PostFixSmtpSaslEnable==1){
		echo "Starting......: SASL authentication is enabled\n";
		
		$cmd["smtpd_sasl_auth_enable"]="yes";
		$cmd["smtpd_use_tls"]="yes";
		$cmd["smtpd_sasl_path"]="smtpd";
		$cmd["smtpd_sasl_authenticated_header"]="yes";
		$cmd["smtpd_tls_session_cache_database"]="btree:\\\$data_directory/smtpd_tls_cache";
		$cmd["smtpd_tls_key_file"]="/etc/ssl/certs/postfix/ca.key";
		$cmd["smtpd_tls_cert_file"]="/etc/ssl/certs/postfix/ca.crt";
		$cmd["smtpd_tls_CAfile"]="/etc/ssl/certs/postfix/ca.csr";
		$cmd["smtpd_delay_reject"]="yes";
		$cmd["smtpd_tls_session_cache_timeout"]=$main->main_array["smtpd_tls_session_cache_timeout"];
		echo "Starting......: SASL authentication running ". count($cmd)." commands\n";
		while (list ($num, $ligne) = each ($cmd) ){
			postconf($num,$ligne);
			
		}
		
	}else{
		echo "Starting......: SASL authentication is disabled\n";
		postconf("smtpd_sasl_auth_enable","no");
		postconf("smtpd_sasl_authenticated_header","no");
		postconf("smtpd_use_tls","no");
		postconf("smtpd_tls_auth_only" ,"no");
	}
	

}

function BodyChecks(){
	$main=new maincf_multi("master","master");
	$datas=$main->body_checks();
	if($datas<>null){
		postconf("body_checks","regexp:/etc/postfix/body_checks");
	}else{
		postconf("body_checks",null);
	}
	
}

function smtp_sasl_security_options(){
	$f=array();
	$main=new maincf_multi("master","master");
	$datas=unserialize($main->GET_BIGDATA("smtp_sasl_security_options"));
	if(!isset($GLOBALS["CLASS_SOCKET"])){$GLOBALS["CLASS_SOCKET"]=new sockets();$sock=$GLOBALS["CLASS_SOCKET"];}else{$sock=$GLOBALS["CLASS_SOCKET"];}
	if($datas["noanonymous"]==1){$f[]="noanonymous";}
	if($datas["noplaintext"]==1){$f[]="noplaintext";}
	if($datas["nodictionary"]==1){$f[]="nodictionary";}
	if($datas["mutual_auth"]==1){$f[]="mutual_auth";}
	if(count($f)==0){$f[]="noanonymous";}
	postconf("smtp_sasl_security_options",@implode(", ",$f));
	postconf("smtp_sasl_tls_security_options",@implode(", ",$f));
	postconf("smtpd_delay_reject","yes");	

	$EnableMechSMTPCramMD5=$sock->GET_INFO("EnableMechSMTPCramMD5");
	$EnableMechSMTPDigestMD5=$sock->GET_INFO("EnableMechSMTPDigestMD5");
	$EnableMechSMTPLogin=$sock->GET_INFO("EnableMechSMTPLogin");
	$EnableMechSMTPPlain=$sock->GET_INFO("EnableMechSMTPPlain");
	if(!is_numeric($EnableMechSMTPCramMD5)){$EnableMechSMTPCramMD5=1;}
	if(!is_numeric($EnableMechSMTPDigestMD5)){$EnableMechSMTPDigestMD5=1;}
	if(!is_numeric($EnableMechSMTPLogin)){$EnableMechSMTPLogin=1;}
	if(!is_numeric($EnableMechSMTPPlain)){$EnableMechSMTPPlain=1;}	
	
	if($EnableMechSMTPLogin==1){$d[]="login";}
	if($EnableMechSMTPPlain==1){$d[]="plain";}
	if($EnableMechSMTPDigestMD5==1){$d[]="digest-md5";}
	if($EnableMechSMTPCramMD5==1){$d[]="cram-md5";}
	$EnableMechSMTPText=$sock->GET_INFO("EnableMechSMTPText");
	if($EnableMechSMTPText==null){$d[]="!gssapi, !external, static:all";}else{$d[]=$EnableMechSMTPText;}	
	postconf("smtp_sasl_mechanism_filter",@implode(", ",$d));
	 
	
}




function SetTLS(){
	
	$main=new maincf_multi("master","master");
	
	if(!isset($GLOBALS["CLASS_SOCKET"])){$GLOBALS["CLASS_SOCKET"]=new sockets();$sock=$GLOBALS["CLASS_SOCKET"];}else{$sock=$GLOBALS["CLASS_SOCKET"];}
	$smtpd_tls_security_level=trim($sock->GET_INFO('smtpd_tls_security_level'));
	if($smtpd_tls_security_level<>null){
		shell_exec("{$GLOBALS["postconf"]} -e \"smtpd_tls_security_level = $smtpd_tls_security_level\" >/dev/null 2>&1");
	}
	
	if($sock->GET_INFO('smtp_sender_dependent_authentication')==1){
		postconf("smtp_sender_dependent_authentication","yes");
		postconf("smtp_sasl_auth_enable","yes");
	
	}
	
	$broken_sasl_auth_clients=$main->GET("broken_sasl_auth_clients");
	$smtpd_tls_auth_only=$main->GET("smtpd_tls_auth_only");
	$smtpd_sasl_authenticated_header=$main->GET("smtpd_sasl_authenticated_header");
	$smtpd_tls_received_header=$main->GET("smtpd_tls_received_header");
	$smtpd_tls_security_level=$main->GET("smtpd_tls_security_level");
	$smtpd_sasl_security_options=$main->GET("smtpd_sasl_security_options");
	
	if(!is_numeric($broken_sasl_auth_clients)){$broken_sasl_auth_clients=1;}
	if(!is_numeric($smtpd_sasl_authenticated_header)){$smtpd_sasl_authenticated_header=1;}
	if(!is_numeric($smtpd_tls_auth_only)){$smtpd_tls_auth_only=0;}
	if(!is_numeric($smtpd_tls_received_header)){$smtpd_tls_received_header=1;}
	if($smtpd_tls_security_level==null){$smtpd_tls_security_level="may";}
	if($smtpd_sasl_security_options==null){$smtpd_sasl_security_options="noanonymous";}
	
	
	
	postconf("broken_sasl_auth_clients",$main->YesNo($broken_sasl_auth_clients));
	postconf("smtpd_sasl_local_domain",$main->GET("smtpd_sasl_local_domain"));
	postconf("smtpd_sasl_authenticated_header",$main->YesNo($smtpd_sasl_authenticated_header));
	postconf("smtpd_tls_security_level",$smtpd_tls_security_level);
	postconf("smtpd_tls_auth_only",$main->YesNo($smtpd_tls_auth_only));
	postconf("smtpd_tls_received_header",$main->YesNo($smtpd_tls_received_header));
	postconf("smtpd_sasl_security_options",$smtpd_sasl_security_options);
}

function mynetworks(){
	
	if($GLOBALS["EnablePostfixMultiInstance"]==1){
		echo "Starting......: Building mynetworks multiple-instances, enabled\n";
		postconf("mynetworks","127.0.0.0/8");
		shell_exec(LOCATE_PHP5_BIN()." ".dirname(__FILE__)."/exec.exec.postfix-multi.php --reload-all");
		return;
	}
	
	$sock=new sockets();
	$MynetworksInISPMode=$sock->GET_INFO("MynetworksInISPMode");
	if(!is_numeric($MynetworksInISPMode)){$MynetworksInISPMode=0;}	
	$dbfile="/etc/artica-postfix/settings/Daemons/PostfixBadNettr";
	$ArrayBadNets=unserialize(base64_decode(@file_get_contents($dbfile)));
	
	
	if($MynetworksInISPMode==1){
		echo "Starting......: Building mynetworks ISP Mode enabled\n";
		postconf("mynetworks","127.0.0.0/24, 127.0.0.0/8, 127.0.0.1");
		return;	
	}
	
	$ldap=new clladp();
	$nets=$ldap->load_mynetworks();
	if(!is_array($nets)){
		if($GLOBALS["DEBUG"]){echo "No networks sets\n";}
		postconf("mynetworks","127.0.0.0/8");
		return;
	}
	$nets[]="127.0.0.0/8";

	while (list ($num, $network) = each ($nets) ){$cleaned[$network]=$network;}
	unset($nets);
	while (list ($network, $network2) = each ($cleaned) ){
		$network=trim($network);
		if(isset($ArrayBadNets[$network])){	
			if($ArrayBadNets[$network]==0){continue;}
			if($ArrayBadNets[$network]<>null){$nets[]=$ArrayBadNets[$network];continue;}
		}
		$nets[]=$network;
	}
	
	
	
	$inline=@implode(", ",$nets);
	$inline=str_replace(',,',',',$inline);
	$config_net=@implode("\n",$nets);
	echo "Starting......: Postfix Building mynetworks ". count($nets)." Networks ($inline)\n";
	@file_put_contents("/etc/artica-postfix/mynetworks",$config_net);
	postconf("mynetworks",$inline);
}


function badnettr($instance,$badentry,$goodentry){
	
	$dbfile="/etc/artica-postfix/settings/Daemons/PostfixBadNettr";
	$array=unserialize(base64_decode(@file_get_contents($dbfile)));
	$array[trim($badentry)]=trim($goodentry);
	@file_put_contents($dbfile, base64_encode(serialize($array)));	
	
	if($instance=="master"){mynetworks();return;}
	
	$unix=new unix();
	$nohup=$unix->find_program("nohup");
	$php5=$unix->LOCATE_PHP5_BIN();
	shell_exec("$nohup $php5 ".dirname(__FILE__)."/exec.postfix-multi.php --instance-reconfigure $instance >/dev/null 2>&1 &");
	die();
}

function remove_virtual_mailbox_base(){
	$f=@explode("\n",@file_get_contents("/etc/postfix/main.cf"));
	$found=false;
	while (list ($num, $line) = each ($f) ){
		if(preg_match("#virtual_mailbox_base#",$line)){
			echo "Starting......: Postfix remove virtual_mailbox_base entry\n";
			unset($f[$line]);
			$found=true;
		}
		
	}
	if($found){@file_put_contents("/etc/postfix/main.cf",@implode("\n",$f));}
	
}

function headers_check($noreload=0){
	
	$main=new maincf_multi("master","master");
	$headers=$main->header_checks();
	$headers=str_replace("header_checks =","",$headers); 
	
	if($headers<>null){
		postconf("header_checks",$headers);
	}else{
		postconf("header_checks",null);
	}
	
	shell_exec(LOCATE_PHP5_BIN2()." /usr/share/artica-postfix/exec.white-black-central.php");
	if($noreload==0){ReloadPostfix(true);}
}

function buildtables_background(){
	$unix=new unix();	
	$php5=$unix->LOCATE_PHP5_BIN();
	$nohup=$unix->find_program("nohup");
	system("$php5 /usr/share/artica-postfix/exec.postfix.hashtables.php");
}

function RestartPostix(){
	$unix=new unix();
	$postfix=$unix->find_program("postfix");
	if(is_file($postfix)){shell_exec("$postfix stop >/dev/null 2>&1");}
	if(is_file($postfix)){shell_exec("$postfix start >/dev/null 2>&1");}
}
function ReloadPostfix($nohastables=false){
	$ldap=new clladp();
	$domains=$ldap->Hash_domains_table();
	$unix=new unix();
	$php5=$unix->LOCATE_PHP5_BIN();
	$myOrigin=null;
	$dom=array();
	if(count($domains)>0){while (list ($num, $ligne) = each ($domains) ){$dom[]=$num;}$myOrigin=$dom[0];}
	
	if($myOrigin==null){
		if(!isset($GLOBALS["CLASS_USERS_MENUS"])){$user=new usersMenus();}else{$user=$GLOBALS["CLASS_USERS_MENUS"];}
		$myOrigin=$user->hostname;
	}
	
	if($myOrigin==null){$myOrigin="localhost.localdomain";}
	$postfix=$unix->find_program("postfix");
	$daemon_directory=$unix->LOCATE_POSTFIX_DAEMON_DIRECTORY();
	echo "Starting......: Postfix daemon directory \"$daemon_directory\"\n";
	postconf("daemon_directory",$daemon_directory);
	
	
	if($myOrigin==null){$myOrigin="localhost.localdomain";}
	
	if(!$nohastables){
		echo "Starting......: Postfix launch datases compilation...\n";
		buildtables_background();
	}
	
	postconf("myorigin","$myOrigin");
	postconf("smtpd_delay_reject","yes");
	$main=new maincf_multi("master","master");
	$freeze_delivery_queue=$main->GET("freeze_delivery_queue");
	if($freeze_delivery_queue==1){
		postconf("master_service_disable","qmgr.fifo");
		postconf("in_flow_delay","0");
	}else{
		postconf("master_service_disable","");
		$in_flow_delay=$main->GET("in_flow_delay");
		if($in_flow_delay==null){$in_flow_delay="1s";}
		postconf("in_flow_delay",$in_flow_delay);		
	}
	
	
	
	postconf_strip_key();
	
	echo "Starting......: Postfix Apply securities issues\n"; 
	appliSecu();
	echo "Starting......: Postfix Reloading ASSP\n"; 
	system("/usr/share/artica-postfix/bin/artica-install --reload-assp");
	echo "Starting......: Postfix reloading postfix master with \"$postfix\"\n";
	ScanLibexec();
	if(is_file($postfix)){shell_exec("$postfix reload >/dev/null 2>&1");return;}
	
	
	
}

function appliSecu(){
	$unix=new unix();
	$chmod=$unix->find_program("chmod");
	echo "Starting......: Postfix verify permissions...\n"; 
	if(is_file("/var/lib/postfix/smtpd_tls_session_cache.db")){shell_exec("/bin/chown postfix:postfix /var/lib/postfix/smtpd_tls_session_cache.db");}
	if(is_file("/var/lib/postfix/master.lock")){@chown("/var/lib/postfix/master.lock","postfix");}
	if(is_dir("/var/spool/postfix/pid")){@chown("/var/spool/postfix/pid", "root");}
	if(is_file("/usr/sbin/postqueue")){
		@chgrp("/usr/sbin/postqueue", "postdrop");
		@chmod("/usr/sbin/postqueue",0755);
		shell_exec("$chmod g+s /usr/sbin/postqueue");
 		
	}
	if(is_file("/usr/sbin/postdrop")){
		@chgrp("/usr/sbin/postdrop", "postdrop");
		@chmod("/usr/sbin/postdrop",0755);
		shell_exec("$chmod g+s /usr/sbin/postdrop");
	}
	if(is_dir("/var/spool/postfix/public")){@chgrp("/var/spool/postfix/public", "postdrop");}
	if(is_dir("/var/spool/postfix/maildrop")){@chgrp("/var/spool/postfix/maildrop", "postdrop");}
	echo "Starting......: Postfix verify permissions done\n";
	
	
	
}


function cleanMultiplesInstances(){
	foreach (glob("/etc/postfix-*",GLOB_ONLYDIR ) as $dirname) {
	    echo "Starting......: Postfix removing old instance ". basename($dirname)."\n";
	    shell_exec("/bin/rm -rf $dirname");
	}
	postconf("multi_instance_directories",null);
	
}


	
	
function BuildDefaultBranchs(){
	
	$main=new main_cf();
	$main->BuildDefaultWhiteListRobots();
	
	$sender=new sender_dependent_relayhost_maps();
	
	if($GLOBALS["RELOAD"]){
		$unix=new unix();
		$postfix=$unix->find_program("postfix");
		shell_exec("$postfix stop && $postfix start");
	}
}



function imap_sockets(){
	if(!is_file("/etc/imapd.conf")){
		echo "Starting......: cyrus transport no available\n";
		return;
	}
	
	shell_exec("/usr/share/artica-postfix/bin/artica-install --reconfigure-cyrus");
	
	
	echo "Starting......: cyrus analyze /etc/imapd.conf\n";
	$f=explode("\n",@file_get_contents("/etc/imapd.conf"));
	while (list ($num, $ligne) = each ($f) ){
		if(preg_match("#lmtpsocket:(.+)#",$ligne,$re)){
			$socket=trim($re[1]);
		}
	}
	
	$f=explode("\n",@file_get_contents("/etc/cyrus.conf"));
	while (list ($num, $ligne) = each ($f) ){
		if(substr($ligne,0,1)=="#"){continue;}
		if(preg_match("#lmtpunix\s+(.+)#",$ligne,$re)){
			echo "Starting......: cyrus lmtpunix: $ligne\n";
			$f[$num]="  lmtpunix	cmd=\"lmtpd\" listen=\"$socket\" prefork=1";
			$write=true;
		}
	}	
	
	if($write){
		@file_put_contents("/etc/cyrus.conf",implode("\n",$f));
		shell_exec("/etc/init.d/artica-postfix restart imap");
	}
	if(!is_file($socket)){
		if(is_file("$socket=")){$socket="$socket=";}
	}
	
	echo "Starting......: cyrus transport: unix: $socket\n";
	if($socket<>null){
		postconf("mailbox_transport","lmtp:unix:$socket");
		shell_exec("postfix stop");
		shell_exec("postfix start");
		shell_exec("postqueue -f");
	}
	
	
	
}

function policyd_weight_reconfigure(){
	$pol=new policydweight();
	$conf=$pol->buildConf();
	@file_put_contents("/etc/artica-postfix/settings/Daemons/PolicydWeightConfig",$conf);
	echo "Starting......: policyd-weight building first config done\n";
}

function mime_header_checks(){
	$f=array();
	$main=new maincf_multi("master","master");
	$enable_attachment_blocking_postfix=$main->GET("enable_attachment_blocking_postfix");
	if(!is_numeric($enable_attachment_blocking_postfix)){$enable_attachment_blocking_postfix=0;}
	$extmime=$main->mime_header_checks();
	$extmime=trim(str_replace("mime_header_checks =","",$extmime)); 	
	
	if($enable_attachment_blocking_postfix==1){
		$sql=new mysql();
		$sql="SELECT * FROM smtp_attachments_blocking WHERE ou='_Global' ORDER BY IncludeByName";
		writelogs("$sql",__FUNCTION__,__FILE__,__LINE__);
		$q=new mysql();
		writelogs("-> Qyery",__FUNCTION__,__FILE__,__LINE__);
		$results=$q->QUERY_SQL($sql,"artica_backup");
		if(!$q->ok){writelogs("Error mysql $q->mysql_error",__FUNCTION__,__FILE__,__LINE__);return null;}
			
		writelogs("-> loop",__FUNCTION__,__FILE__,__LINE__);
		while($ligne=@mysql_fetch_array($results,MYSQL_ASSOC)){
			if($ligne["IncludeByName"]==null){continue;}
			$f[]=$ligne["IncludeByName"];
			
		}

	}else{
		echo "Starting......: Blocking extensions trough postfix is disabled\n";
	}
	
	
	if(count($f)==0){
		echo "Starting......: No extensions blocked\n";
		if($extmime<>null){postconf("mime_header_checks",$extmime);}
		postconf("mime_header_checks",null);
		return;
	}
	
	$strings=implode("|",$f);
	echo "Starting......: ". count($f)." extensions blocked\n";
	$pattern[]="/^\s*Content-(Disposition|Type).*name\s*=\s*\"?(.+\.($strings))\"?\s*$/\tREJECT file attachment types is not allowed. File \"$2\" has the unacceptable extension \"$3\"";
	$pattern[]="";
	@file_put_contents("/etc/postfix/mime_header_checks",implode("\n",$pattern));
	if($extmime<>null){$extmime=",$extmime";}
	postconf("mime_header_checks","regexp:/etc/postfix/mime_header_checks$extmime");
	
}

function smtp_sasl_auth_enable(){
	$ldap=new clladp();
	if($ldap->ldapFailed){
		echo "Starting......: SMTP SALS connection to ldap failed\n";
		return;
	}

	$suffix="dc=organizations,$ldap->suffix";
	$filter="(&(objectclass=SenderDependentSaslInfos)(SenderCanonicalRelayPassword=*))";
	$res=array();
	$search = @ldap_search($ldap->ldap_connection,$suffix,"$filter",array());
	$count=0;		
	if ($search) {
			$hash=ldap_get_entries($ldap->ldap_connection,$search);	
			$count=$hash["count"];
		}
	
	echo "Starting......: SMTP SALS $count account(s)\n"; 	
	if($count>0){
		postconf("smtp_sasl_auth_enable","yes");
		postconf("smtp_sender_dependent_authentication","yes");
		
		
	}else{
		postconf("smtp_sender_dependent_authentication","no");
		
	}

}

function smtpd_client_restrictions_clean(){
	$f=@explode("\n",@file_get_contents("/etc/postfix/main.cf"));
	while (list ($num, $ligne) = each ($f) ){
		if(preg_match("#smtpd_client_restrictions_#",$ligne)){continue;}
		if(preg_match("#smtpd_helo_restrictions_#",$ligne)){continue;}
		if(preg_match("#check_client_access ldap_#",$ligne)){continue;}
		$ligne=str_replace("check_client_access ldap:smtpd_client_restrictions_check_client_access","",$ligne);
		$ligne=str_replace("main.cf=\'my_domain\'=","",$ligne);
		
		$newarray[]=$ligne;
		
	}
	@file_put_contents("/etc/postfix/main.cf",@implode("\n",$newarray));
	
}


function smtpd_client_restrictions(){
	exec("{$GLOBALS["postconf"]} -h smtpd_client_restrictions",$datas);
	$tbl=explode(",",implode(" ",$datas));
	
if(!isset($GLOBALS["CLASS_SOCKET"])){$GLOBALS["CLASS_SOCKET"]=new sockets();$sock=$GLOBALS["CLASS_SOCKET"];}else{$sock=$GLOBALS["CLASS_SOCKET"];}
	$EnablePostfixAntispamPack=$sock->GET_INFO("EnablePostfixAntispamPack");
	$EnableArticaPolicyFilter=$sock->GET_INFO("EnableArticaPolicyFilter");
	$EnableArticaPolicyFilter=0;
	$EnableAmavisInMasterCF=$sock->GET_INFO('EnableAmavisInMasterCF');
	$EnableAmavisDaemon=$sock->GET_INFO('EnableAmavisDaemon');		
	$amavis_internal=null;
	if(is_array($tbl)){
		while (list ($num, $ligne) = each ($tbl) ){
		$ligne=trim($ligne);
		if(trim($ligne)==null){continue;}
		if($ligne=="Array"){continue;}
		$newHash[$ligne]=$ligne;
		}
	}

	$hashToDelete[]="check_client_access hash:/etc/postfix/check_client_access";
	$hashToDelete[]="check_client_access \"hash:/etc/postfix/postfix_allowed_connections\"";
	$hashToDelete[]="check_client_access hash:/etc/postfix/postfix_allowed_connections";
	$hashToDelete[]="reject_non_fqdn_hostname";
	$hashToDelete[]="reject_unknown_sender_domain";
	$hashToDelete[]="reject_non_fqdn_sender";
	$hashToDelete[]="reject_unauth_pipelining";
	$hashToDelete[]="reject_invalid_hostname";
	$hashToDelete[]="reject_unknown_client_hostname";
	$hashToDelete[]="reject_unknown_reverse_client_hostname";
	$hashToDelete[]="reject_invalid_hostname";
	$hashToDelete[]="reject_rbl_client zen.spamhaus.org";
	$hashToDelete[]="reject_rbl_client sbl.spamhaus.org";
	$hashToDelete[]="reject_rbl_client cbl.abuseat.org";
	$hashToDelete[]="reject_unauth_pipelining";
	$hashToDelete[]="reject_unauth_pipelining";
	$hashToDelete[]="reject_rbl_client=zen.spamhaus.org";
	$hashToDelete[]="reject_rbl_client=sbl.spamhaus.org";
	$hashToDelete[]="reject_rbl_client=sbl.spamhaus.org";
	$hashToDelete[]="check_client_access hash:/etc/postfix/amavis_internal";	
	
	while (list ($num, $ligne) = each ($hashToDelete) ){
		if(isset($newHash[$ligne])){unset($newHash[$ligne]);}
	}

	
	
	if($GLOBALS["VERBOSE"]){
		echo "Starting......: smtpd_client_restrictions: origin:".@implode(",",$newHash)."\n";
	}
	
	$main=new maincf_multi("master","master");
	$check_client_access=$main->check_client_access();
	if($check_client_access<>null){
		$newHash[$check_client_access]=$check_client_access;
	}
	$smtpd_client_restrictions=array();
	if(isset($newHash)){
		if(is_array($newHash)){	
			while (list ($num, $ligne) = each ($newHash) ){
				if(preg_match("#hash:(.+)$#",$ligne,$re)){
					$path=trim($re[1]);
					if(!is_file($path)){
						echo "Starting......: smtpd_client_restrictions: bungled \"$ligne\"\n"; 
						continue;
					}
				}
				
				if(preg_match("#reject_rbl_client=(.+?)$#",$ligne,$re)){
					$rbl=trim($re[1]);
						echo "Starting......: reject_rbl_client: bungled \"$ligne\" fix it\n"; 
						$num="reject_rbl_client $rbl";
						continue;
					}
				}			
				$smtpd_client_restrictions[]=$num;
			}
	}
	
if(!isset($GLOBALS["CLASS_SOCKET"])){$GLOBALS["CLASS_SOCKET"]=new sockets();$sock=$GLOBALS["CLASS_SOCKET"];}else{$sock=$GLOBALS["CLASS_SOCKET"];}
	$reject_unknown_client_hostname=$sock->GET_INFO('reject_unknown_client_hostname');
	$reject_unknown_reverse_client_hostname=$sock->GET_INFO('reject_unknown_reverse_client_hostname');
	
	$reject_invalid_hostname=$sock->GET_INFO('reject_invalid_hostname');
	if($reject_unknown_client_hostname==1){$smtpd_client_restrictions[]="reject_unknown_client_hostname";}
	if($reject_unknown_reverse_client_hostname==1){$smtpd_client_restrictions[]="reject_unknown_reverse_client_hostname";}
	if($reject_invalid_hostname==1){$smtpd_client_restrictions[]="reject_invalid_hostname";}
	
	if($EnablePostfixAntispamPack==1){
		echo "Starting......: smtpd_client_restrictions:Anti-spam Pack is enabled\n";
		if(!is_file("/etc/postfix/postfix_allowed_connections")){@file_put_contents("/etc/postfix/postfix_allowed_connections","#");}
		$smtpd_client_restrictions[]="check_client_access \"hash:/etc/postfix/postfix_allowed_connections\"";
		$smtpd_client_restrictions[]="reject_non_fqdn_hostname";
		$smtpd_client_restrictions[]="reject_invalid_hostname";
		$smtpd_client_restrictions[]="reject_rbl_client zen.spamhaus.org";
		$smtpd_client_restrictions[]="reject_rbl_client sbl.spamhaus.org";
		$smtpd_client_restrictions[]="reject_rbl_client cbl.abuseat.org";		
	}	
	
	
	
	if($EnableArticaPolicyFilter==1){
		array_unshift($smtpd_client_restrictions,"check_policy_service inet:127.0.0.1:54423");
	}

	echo "Starting......: smtpd_client_restrictions: ". count($smtpd_client_restrictions)." rule(s)\n";
	
	
	if($EnableAmavisInMasterCF==1){
		if($EnableAmavisDaemon==1){
			$count=amavis_internal();
			if($count>0){
				echo "Starting......: $count addresses bypassing amavisd new\n";
				$amavis_internal="check_client_access hash:/etc/postfix/amavis_internal,";
			}
		}
	}	
	
	if(is_array($smtpd_client_restrictions)){
		
		
		//CLEAN engine ---------------------------------------------------------------------------------------
		while (list ($num, $ligne) = each ($smtpd_client_restrictions) ){
			$array_cleaned[trim($ligne)]=trim($ligne);
		}
		
		
		
		if(isset($array_cleaned["permit_mynetworks"])){unset($array_cleaned["permit_mynetworks"]);};
		if(isset($array_cleaned["permit_sasl_authenticated"])){unset($array_cleaned["permit_sasl_authenticated"]);}
		
		
		unset($smtpd_client_restrictions);
		$smtpd_client_restrictions=array();
		
		
		if(is_array($smtpd_client_restrictions)){
			while (list ($num, $ligne) = each ($smtpd_client_restrictions) ){
				echo "Starting......: smtpd_client_restrictions : $ligne\n";
				$smtpd_client_restrictions[]=trim($ligne);}
		}
	   //CLEAN engine ---------------------------------------------------------------------------------------
	}else{
		echo "Starting......: smtpd_client_restrictions: Not an array\n";
	}	
	
	$newval=null;
	
	

	if(count($smtpd_client_restrictions)>1){
			$newval=implode(",",$smtpd_client_restrictions);
			$newval="{$amavis_internal}permit_mynetworks,permit_sasl_authenticated,reject_unauth_pipelining,$newval";
	}else{
		
		if($amavis_internal<>null){
			echo "Starting......: smtpd_client_restrictions: adding amavis internal\n";
			$newval="check_client_access hash:/etc/postfix/amavis_internal";
		}
	}
	
			
	postconf("smtpd_client_restrictions",$newval);
	
	
	
}

function restrict_relay_domains(){
	$unix=new unix();
	$php5=$unix->LOCATE_PHP5_BIN();
	system("$php5 /usr/share/artica-postfix/exec.postfix.hashtables.php --restricted-relais");
		
	
}



function smtpd_recipient_restrictions(){
	if(!isset($GLOBALS["CLASS_USERS_MENUS"])){$users=new usersMenus();$GLOBALS["CLASS_USERS_MENUS"]=$users;}else{$users=$GLOBALS["CLASS_USERS_MENUS"];}
	if(!isset($GLOBALS["CLASS_SOCKET"])){$GLOBALS["CLASS_SOCKET"]=new sockets();$sock=$GLOBALS["CLASS_SOCKET"];}else{$sock=$GLOBALS["CLASS_SOCKET"];}
	$newHash=array();
	$EnableCluebringer=$sock->GET_INFO("EnableCluebringer");
	$EnablePostfixAntispamPack=$sock->GET_INFO("EnablePostfixAntispamPack");
	$EnableArticaPolicyFilter=$sock->GET_INFO("EnableArticaPolicyFilter");
	$EnableArticaPolicyFilter=0;
	if($GLOBALS["DEBUG"]){echo "EnableCluebringer=$EnableCluebringer\n";}
	$EnableAmavisInMasterCF=$sock->GET_INFO('EnableAmavisInMasterCF');
	$EnableAmavisDaemon=$sock->GET_INFO('EnableAmavisDaemon');	
	$TrustMyNetwork=$sock->GET_INFO("TrustMyNetwork");
	if(!is_numeric($TrustMyNetwork)){$TrustMyNetwork=1;}
	exec("{$GLOBALS["postconf"]} -h smtpd_recipient_restrictions",$datas);
	$tbl=explode(",",implode(" ",$datas));
	$permit_mynetworks_remove=false;

	if(is_array($tbl)){
		while (list ($num, $ligne) = each ($tbl) ){
		if(trim($ligne)==null){continue;}
		$newHash[trim($ligne)]=trim($ligne);
		}
	}
	
	unset($newHash["check_client_access hash:/etc/postfix/amavis_internal"]);
	unset($newHash["check_recipient_access hash:/etc/postfix/relay_domains_restricted"]);
	unset($newHash["permit"]);
	unset($newHash["check_sender_access hash:/etc/postfix/disallow_my_domain"]);
	unset($newHash["check_sender_access hash:/etc/postfix/unrestricted_senders"]);
	unset($newHash["check_recipient_access hash:/etc/postfix/amavis_bypass_rcpt"]);
	unset($newHash["reject_unauth_destination"]);
	unset($newHash["permit_mynetworks"]);
	unset($newHash["check_client_access pcre:/etc/postfix/fqrdns.pcre"]);
	unset($newHash["check_policy_service inet:127.0.0.1:54423"]);
	unset($newHash["check_policy_service inet:127.0.0.1:13331"]);
	
	
	if(is_array($newHash)){	
		while (list ($num, $ligne) = each ($newHash) ){
		if(preg_match("#hash:(.+)$#",$ligne,$re)){
				$path=trim($re[1]);
				if(!is_file($path)){
					echo "Starting......: smtpd_recipient_restrictions: bungled \"$ligne\"\n"; 
					continue;
				}
			}
			$smtpd_recipient_restrictions[]=$num;
		}
	}
	
	if($GLOBALS["DEBUG"]){echo "CLUEBRINGER_INSTALLED=$users->CLUEBRINGER_INSTALLED\n";}
	
	if($users->CLUEBRINGER_INSTALLED){
		if($EnableCluebringer==1){$smtpd_recipient_restrictions[]="check_policy_service inet:127.0.0.1:13331";}
	}
					
	postconf("smtpd_restriction_classes","artica_restrict_relay_domains");
	postconf("artica_restrict_relay_domains","reject_unverified_recipient");
	$MynetworksInISPMode=$sock->GET_INFO("MynetworksInISPMode");
	if(!is_numeric($MynetworksInISPMode)){$MynetworksInISPMode=0;}		
	if($TrustMyNetwork==0 && $MynetworksInISPMode==1){$TrustMyNetwork=1;}
	
	if($TrustMyNetwork==1){$smtpd_recipient_restrictions[]="permit_mynetworks";}else{
		echo "Starting......: **** TrustMyNetwork is disabled, outgoing messages should be not allowed... **** \n";
		
	}
	$smtpd_recipient_restrictions[]="permit_sasl_authenticated";
	$smtpd_recipient_restrictions[]="check_recipient_access hash:/etc/postfix/relay_domains_restricted";
	$smtpd_recipient_restrictions[]="check_recipient_access hash:/etc/postfix/amavis_bypass_rcpt";
	$smtpd_recipient_restrictions[]="permit_auth_destination";
	
	
	amavis_bypass_byrecipients();
	restrict_relay_domains();
	
	
	postconf("auth_relay",null);
	
	
	

		
		
	if(!isset($GLOBALS["CLASS_SOCKET"])){$GLOBALS["CLASS_SOCKET"]=new sockets();$sock=$GLOBALS["CLASS_SOCKET"];}else{$sock=$GLOBALS["CLASS_SOCKET"];}
	$reject_forged_mails=$sock->GET_INFO("reject_forged_mails");
	if($reject_forged_mails==1){
		if(smtpd_recipient_restrictions_reject_forged_mails()){
			echo "Starting......: Reject Forged mails enabled\n"; 	
			$smtpd_recipient_restrictions[]="check_sender_access hash:/etc/postfix/disallow_my_domain";
		}
	}else{
		echo "Starting......: Reject Forged mails disabled\n"; 			
	}
	
	$EnableGenericrDNSClients=$sock->GET_INFO("EnableGenericrDNSClients");
	if(!$users->POSTFIX_PCRE_COMPLIANCE){$EnableGenericrDNSClients=0;}
	
	if($EnableGenericrDNSClients==1){
		echo "Starting......: Reject Public ISP reverse DNS patterns enabled\n"; 
		$smtpd_recipient_restrictions[]="check_client_access pcre:/etc/postfix/fqrdns.pcre";
		shell_exec("/bin/cp /usr/share/artica-postfix/bin/install/postfix/fqrdns.pcre /etc/postfix/fqrdns.pcre");
	}else{
		echo "Starting......: Reject Public ISP reverse DNS patterns disabled\n";
	}
	
	
	
	if($EnableArticaPolicyFilter==1){
		array_unshift($smtpd_recipient_restrictions,"check_policy_service inet:127.0.0.1:54423");
	}
	

	
	$smtpd_recipient_restrictions[]="reject_unauth_destination";
	$smtpd_recipient_restrictions[]="permit";


	if($GLOBALS["EnableBlockUsersTroughInternet"]==1){
		echo "Starting......: Restricted users are enabled\n"; 	
		if(RestrictedForInternet()){
 			postconf("auth_relay","check_recipient_access hash:/etc/postfix/local_domains, reject");
			 array_unshift($smtpd_recipient_restrictions,"check_sender_access hash:/etc/postfix/unrestricted_senders");
			__ADD_smtpd_restriction_classes("auth_relay");
		}else{__REMOVE_smtpd_restriction_classes("auth_relay");}
	}
	else{__REMOVE_smtpd_restriction_classes("auth_relay");}	
	
	
	
	//CLEAN engine ---------------------------------------------------------------------------------------
	while (list ($num, $ligne) = each ($smtpd_recipient_restrictions) ){
		$smtpd_recipient_restrictions_cleaned[trim($ligne)]=trim($ligne);
	}
	
	
	
	unset($smtpd_recipient_restrictions);
	while (list ($num, $ligne) = each ($smtpd_recipient_restrictions_cleaned) ){$smtpd_recipient_restrictions[]=trim($ligne);}

   //CLEAN engine ---------------------------------------------------------------------------------------
	
	
	if(is_array($smtpd_recipient_restrictions)){$newval=implode(",",$smtpd_recipient_restrictions);}
	if($GLOBALS["DEBUG"]){echo "smtpd_recipient_restrictions = $newval\n";}
	postconf("smtpd_recipient_restrictions",$newval);
	
	
	}
	
function amavis_bypass_byrecipients(){
	$f=array();
	$count=0;
	$users=new usersMenus();
	$q=new mysql();
	$unix=new unix();
	$sock=new sockets();
	$EnableAmavisDaemon=$sock->GET_INFO('EnableAmavisDaemon');
	$EnableAmavisInMasterCF=$sock->GET_INFO('EnableAmavisInMasterCF');
	if(!$users->AMAVIS_INSTALLED){$EnableAmavisDaemon=0;}
	if($EnableAmavisDaemon==1){
		if($EnableAmavisInMasterCF==1){
			$sql="SELECT * FROM amavis_bypass_rcpt ORDER BY `pattern`";
			$results=$q->QUERY_SQL($sql,"artica_backup");
			if(!$q->ok){echo $q->mysql_error."\n";return 0;}	
			$count=0;
			$f=array();
			while($ligne=@mysql_fetch_array($results,MYSQL_ASSOC)){
				$ligne["pattern"]=trim($ligne["pattern"]);
				$ip=trim($ligne["pattern"]);
				if($ip==null){continue;}
				if(is_array($ip)){continue;}
				$count++;
				$f[]="{$ligne["pattern"]}\tFILTER smtp:[127.0.0.1]:10025";
			}
		}
	}
	$postmap=$unix->find_program("postmap");
	echo "Starting......: ". count($f) ." bypass recipient(s) for amavisd new\n"; 	
	
	$f[]="";
	@file_put_contents("/etc/postfix/amavis_bypass_rcpt",@implode("\n",$f));
	shell_exec("$postmap hash:/etc/postfix/amavis_bypass_rcpt");
	return $count;
	}	
	
function amavis_internal(){
	$users=new usersMenus();
	$q=new mysql();
	$unix=new unix();
	$sock=new sockets();
	$EnableAmavisDaemon=$sock->GET_INFO('EnableAmavisDaemon');
	$EnableAmavisInMasterCF=$sock->GET_INFO('EnableAmavisInMasterCF');
	if(!$users->AMAVIS_INSTALLED){$EnableAmavisDaemon=0;}
	if($EnableAmavisDaemon==1){
		if($EnableAmavisInMasterCF==1){
			$sql="SELECT * FROM amavisd_bypass ORDER BY ip_addr";
			$results=$q->QUERY_SQL($sql,"artica_backup");
			if(!$q->ok){echo $q->mysql_error."\n";return 0;}	
			$count=0;
			$f=array();
			while($ligne=@mysql_fetch_array($results,MYSQL_ASSOC)){
				$ligne["ip_addr"]=trim($ligne["ip_addr"]);
				$ip=trim($ligne["ip_addr"]);
				if($ip==null){continue;}
				if(is_array($ip)){continue;}
				$count++;
				$f[]="{$ligne["ip_addr"]}\tFILTER smtp:[127.0.0.1]:10025";
			}
		}
	}
	
	$postmap=$unix->find_program("postmap");
	$f[]="";
	@file_put_contents("/etc/postfix/amavis_internal",@implode("\n",$f));
	shell_exec("$postmap hash:/etc/postfix/amavis_internal");
	return $count;
}	




	
function __ADD_smtpd_restriction_classes($classname){
exec("{$GLOBALS["postconf"]} -h smtpd_restriction_classes",$datas);
	$tbl=explode(",",implode(" ",$datas));
	

	if(is_array($tbl)){
		while (list ($num, $ligne) = each ($tbl) ){
		if(trim($ligne)==null){continue;}
		$newHash[$ligne]=$ligne;
		}
	}
	
	unset($newHash[$classname]);
	
	if(is_array($newHash)){	
		while (list ($num, $ligne) = each ($newHash) ){	
			$smtpd_restriction_classes[]=$num;
		}
	}
	
	$smtpd_restriction_classes[]=$classname;
	if(is_array($smtpd_restriction_classes)){$newval=implode(",",$smtpd_restriction_classes);}
	
	postconf("smtpd_restriction_classes",$newval);
		
	
}

function __REMOVE_smtpd_restriction_classes($classname){
	exec("{$GLOBALS["postconf"]} -h smtpd_restriction_classes",$datas);
	$tbl=explode(",",implode(" ",$datas));
	$newHash=array();

	if(is_array($tbl)){
		while (list ($num, $ligne) = each ($tbl) ){
		if(trim($ligne)==null){continue;}
		$newHash[$ligne]=$ligne;
		}
	}
	
	unset($newHash[$classname]);
	
	if(is_array($newHash)){	
		while (list ($num, $ligne) = each ($newHash) ){	
			$smtpd_restriction_classes[]=$num;
		}
	}
	
	if(is_array($smtpd_restriction_classes)){$newval=implode(",",$smtpd_restriction_classes);}
	postconf("smtpd_restriction_classes",$newval);
}
	
	
function smtpd_recipient_restrictions_reject_forged_mails(){
	$ldap=new clladp();
	$unix=new unix();
	$postmap=$unix->find_program("postmap");
	$hash=$ldap->hash_get_all_domains();
	if(!is_array($hash)){return false;}
	while (list ($domain, $ligne) = each ($hash) ){
		$f[]="$domain\t 554 $domain FORGED MAIL"; 
		
	}
	
	if(!is_array($f)){return false;}
	@file_put_contents("/etc/postfix/disallow_my_domain",@implode("\n",$f));
	echo "Starting......: compiling domains against forged messages\n";
	shell_exec("$postmap hash:/etc/postfix/disallow_my_domain");
	return true;
}

function RestrictedForInternet($reload=false){
	$main=new main_cf();
	$unix=new unix();
	$GLOBALS["postmap"]=$unix->find_program("postmap");
	$restricted_users=$users=$main->check_sender_access();
	if(!$reload){echo "Starting......: Restricted users ($restricted_users)\n";}
	if($restricted_users>0){
		@copy("/etc/artica-postfix/settings/Daemons/unrestricted_senders","/etc/postfix/unrestricted_senders");
		@copy("/etc/artica-postfix/settings/Daemons/unrestricted_senders_domains","/etc/postfix/local_domains");
		echo "Starting......: Compiling unrestricted users ($restricted_users)\n";
		shell_exec("{$GLOBALS["postmap"]} hash:/etc/postfix/unrestricted_senders");
		echo "Starting......: Compiling local domains\n";
		shell_exec("{$GLOBALS["postmap"]} hash:/etc/postfix/local_domains");
		if($reload){shell_exec("{$GLOBALS["postfix"]} reload >/dev/null 2>&1");}
		return true;
		}
	return false;
	
}

function CleanMyHostname(){
	exec("{$GLOBALS["postconf"]} -h myhostname",$results);
	if(!isset($GLOBALS["CLASS_SOCKET"])){$GLOBALS["CLASS_SOCKET"]=new sockets();$sock=$GLOBALS["CLASS_SOCKET"];}else{$sock=$GLOBALS["CLASS_SOCKET"];}
	$myhostname=trim(implode("",$results));
	$myhostname=str_replace("header_checks =","",$myhostname);
	exec("{$GLOBALS["postconf"]} -h relayhost",$results);
	
	if(is_array($results)){
		$relayhost=trim(@implode("",$results));
	}
	
	if($myhostname=="Array.local"){
		if(!isset($GLOBALS["CLASS_USERS_MENUS"])){$users=new usersMenus();$GLOBALS["CLASS_USERS_MENUS"]=$users;}else{$users=$GLOBALS["CLASS_USERS_MENUS"];}
		$myhostname=$users->hostname;
	}
	
	if($relayhost<>null){
		if($myhostname==$relayhost){
			$myhostname="$myhostname.local";
		}
	}
	
	//fix bug with extension.
	
	$myhostname=str_replace(".local.local.",".local",$myhostname);
	$myhostname=str_replace(".locallocal.locallocal.",".",$myhostname);
	$myhostname=str_replace(".locallocal",".local",$myhostname);
	$myhostname=str_replace(".local.local",".local",$myhostname);
	
	$myhostname2=trim($sock->GET_INFO("myhostname"));
	if(strlen($myhostname2)>0){
		$myhostname=$myhostname2;
	}
	

	echo "Starting......: Hostname=$myhostname\n";
	
	postconf("myhostname",$myhostname);
	
}

function smtpd_sasl_exceptions_networks(){
	$nets=array();
	if(!isset($GLOBALS["CLASS_SOCKET"])){$GLOBALS["CLASS_SOCKET"]=new sockets();$sock=$GLOBALS["CLASS_SOCKET"];}else{$sock=$GLOBALS["CLASS_SOCKET"];}
	$smtpd_sasl_exceptions_networks_list=unserialize(base64_decode($sock->GET_INFO("smtpd_sasl_exceptions_networks")));
	$smtpd_sasl_exceptions_mynet=$sock->GET_INFO("smtpd_sasl_exceptions_mynet");	
	if($smtpd_sasl_exceptions_mynet==1){$nets[]="\\\$mynetworks";}
	
	if(is_array($smtpd_sasl_exceptions_networks_list)){
		while (list ($num, $val) = each ($smtpd_sasl_exceptions_networks_list) ){
			if($val==null){continue;}
			$nets[]=$val;
		}
	}
	
	
	if(count($nets)>0){
		$final_nets=implode(",",$nets);
		echo "Starting......: SASL exceptions enabled\n";
		postconf("smtpd_sasl_exceptions_networks",$final_nets);
		
	}else{
		echo "Starting......: SASL exceptions disabled\n";
		postconf("smtpd_sasl_exceptions_networks",null);
		
	}
}

function sender_bcc_maps(){
if(!isset($GLOBALS["CLASS_SOCKET"])){$GLOBALS["CLASS_SOCKET"]=new sockets();$sock=$GLOBALS["CLASS_SOCKET"];}else{$sock=$GLOBALS["CLASS_SOCKET"];}
	$sender_bcc_maps_path=$sock->GET_INFO("sender_bcc_maps_path");
	if(is_file($sender_bcc_maps_path)){
		echo "Starting......: Sender BCC \"$sender_bcc_maps_path\"\n";
		postconf("sender_bcc_maps","hash:$sender_bcc_maps_path");
		shell_exec("{$GLOBALS["postmap"]} hash:$sender_bcc_maps_path");
	}
	
}

function OthersValues(){
	if(!isset($GLOBALS["CLASS_SOCKET"])){$GLOBALS["CLASS_SOCKET"]=new sockets();$sock=$GLOBALS["CLASS_SOCKET"];}else{$sock=$GLOBALS["CLASS_SOCKET"];}
	if($sock->GET_INFO("EnablePostfixMultiInstance")==1){return;}	
	$main=new main_cf();
	$mainmulti=new maincf_multi("master","master");
	$main->FillDefaults();	
	echo "Starting......: Fix others settings\n";
	
	$message_size_limit=$sock->GET_INFO("message_size_limit");
	if(!is_numeric($message_size_limit)){
		$message_size_limit=0;
		
	}
	$main->main_array["message_size_limit"]=$sock->GET_INFO("message_size_limit");
	
	
	$minimal_backoff_time=$mainmulti->GET("minimal_backoff_time");
	$maximal_backoff_time=$mainmulti->GET("maximal_backoff_time");
	$bounce_queue_lifetime=$mainmulti->GET("bounce_queue_lifetime");
	$maximal_queue_lifetime=$mainmulti->GET("maximal_queue_lifetime");
	
	$smtp_connection_cache_on_demand=$mainmulti->GET("smtp_connection_cache_on_demand");
	$smtp_connection_cache_time_limit=$mainmulti->GET("smtp_connection_cache_time_limit");
	$smtp_connection_reuse_time_limit=$mainmulti->GET("smtp_connection_reuse_time_limit");
	$connection_cache_ttl_limit=$mainmulti->GET("connection_cache_ttl_limit");
	$connection_cache_status_update_time=$mainmulti->GET("connection_cache_status_update_time");
	$smtp_connection_cache_destinations=unserialize(base64_decode($mainmulti->GET_BIGDATA("smtp_connection_cache_destinations")));	
	
	$address_verify_map=$mainmulti->GET("address_verify_map");
	$address_verify_negative_cache=$mainmulti->GET("address_verify_negative_cache");
	$address_verify_poll_count=$mainmulti->GET("address_verify_poll_count");
	$address_verify_poll_delay=$mainmulti->GET("address_verify_poll_delay");
	$address_verify_sender=$mainmulti->GET("address_verify_sender");
	$address_verify_negative_expire_time=$mainmulti->GET("address_verify_negative_expire_time");
	$address_verify_negative_refresh_time=$mainmulti->GET("address_verify_negative_refresh_time");
	$address_verify_positive_expire_time=$mainmulti->GET("address_verify_positive_expire_time");
	$address_verify_positive_refresh_time=$mainmulti->GET("address_verify_positive_refresh_time");
	if($address_verify_map==null){$address_verify_map="btree:/var/lib/postfix/verify";}
	
	$smtpd_error_sleep_time=$mainmulti->GET("smtpd_error_sleep_time");
	$smtpd_soft_error_limit=$mainmulti->GET("smtpd_soft_error_limit");
	$smtpd_hard_error_limit=$mainmulti->GET("smtpd_hard_error_limit");
	$smtpd_client_connection_count_limit=$mainmulti->GET("smtpd_client_connection_count_limit");
	$smtpd_client_connection_rate_limit=$mainmulti->GET("smtpd_client_connection_rate_limit");
	$smtpd_client_message_rate_limit=$mainmulti->GET("smtpd_client_message_rate_limit");
	$smtpd_client_recipient_rate_limit=$mainmulti->GET("smtpd_client_recipient_rate_limit");
	$smtpd_client_new_tls_session_rate_limit=$mainmulti->GET("smtpd_client_new_tls_session_rate_limit");
	$smtpd_client_event_limit_exceptions=$mainmulti->GET("smtpd_client_event_limit_exceptions");
	$in_flow_delay=$mainmulti->GET("in_flow_delay");
	$smtp_connect_timeout=$mainmulti->GET("smtp_connect_timeout");
	$smtp_helo_timeout=$mainmulti->GET("smtp_helo_timeout");
	$initial_destination_concurrency=$mainmulti->GET("initial_destination_concurrency");
	$default_destination_concurrency_limit=$mainmulti->GET("default_destination_concurrency_limit");
	$local_destination_concurrency_limit=$mainmulti->GET("local_destination_concurrency_limit");
	$smtp_destination_concurrency_limit=$mainmulti->GET("smtp_destination_concurrency_limit");
	$default_destination_recipient_limit=$mainmulti->GET("default_destination_recipient_limit");
	$smtpd_recipient_limit=$mainmulti->GET("smtpd_recipient_limit");
	$queue_run_delay=$mainmulti->GET("queue_run_delay");  
	$minimal_backoff_time =$mainmulti->GET("minimal_backoff_time");
	$maximal_backoff_time =$mainmulti->GET("maximal_backoff_time");
	$maximal_queue_lifetime=$mainmulti->GET("maximal_queue_lifetime"); 
	$bounce_queue_lifetime =$mainmulti->GET("bounce_queue_lifetime");
	$qmgr_message_recipient_limit =$mainmulti->GET("qmgr_message_recipient_limit");
	$default_process_limit=$mainmulti->GET("default_process_limit");	
	$smtp_fallback_relay=$mainmulti->GET("smtp_fallback_relay");
	$smtpd_reject_unlisted_recipient=$mainmulti->GET("smtpd_reject_unlisted_recipient");
	$smtpd_reject_unlisted_sender=$mainmulti->GET("smtpd_reject_unlisted_sender");

	$ignore_mx_lookup_error=$mainmulti->GET("ignore_mx_lookup_error");
	$disable_dns_lookups=$mainmulti->GET("disable_dns_lookups");
	$smtpd_banner=$mainmulti->GET('smtpd_banner');
	
	$detect_8bit_encoding_header=$mainmulti->GET("detect_8bit_encoding_header");
	$disable_mime_input_processing=$mainmulti->GET("disable_mime_input_processing");
	$disable_mime_output_conversion=$mainmulti->GET("disable_mime_output_conversion");
	
	
	if(!is_numeric($detect_8bit_encoding_header)){$detect_8bit_encoding_header=1;}
	if(!is_numeric($disable_mime_input_processing)){$disable_mime_input_processing=0;}
	if(!is_numeric($disable_mime_output_conversion)){$disable_mime_output_conversion=0;}
	
	
	if(!is_numeric($ignore_mx_lookup_error)){$ignore_mx_lookup_error=0;}
	if(!is_numeric($disable_dns_lookups)){$disable_dns_lookups=0;}
	if(!is_numeric($smtpd_reject_unlisted_recipient)){$smtpd_reject_unlisted_recipient=1;}
	if(!is_numeric($smtpd_reject_unlisted_sender)){$smtpd_reject_unlisted_sender=0;}
	
		
	


	
	
	if(!is_numeric($smtp_connection_cache_on_demand)){$smtp_connection_cache_on_demand=1;}
	if($smtp_connection_cache_time_limit==null){$smtp_connection_cache_time_limit="2s";}
	if($smtp_connection_reuse_time_limit==null){$smtp_connection_reuse_time_limit="300s";}
	if($connection_cache_ttl_limit==null){$connection_cache_ttl_limit="2s";}
	if($connection_cache_status_update_time==null){$connection_cache_status_update_time="600s";}	
	if($smtp_connection_cache_on_demand==1){$smtp_connection_cache_on_demand="yes";}else{$smtp_connection_cache_on_demand="no";}
	
	if(count($smtp_connection_cache_destinations)>0){
		while (list ($host, $none) = each ($smtp_connection_cache_destinations) ){$smtp_connection_cache_destinationsR[]=$host;}
		$smtp_connection_cache_destinationsF=@implode(",", $smtp_connection_cache_destinationsR);
	}
	

	if(!is_numeric($address_verify_negative_cache)){$address_verify_negative_cache=1;}
	if(!is_numeric($address_verify_poll_count)){$address_verify_poll_count=3;}
	if($address_verify_poll_delay==null){$address_verify_poll_delay="3s";}
	if($address_verify_sender==null){$address_verify_sender="double-bounce";}
	if($address_verify_negative_expire_time==null){$address_verify_negative_expire_time="3d";}
	if($address_verify_negative_refresh_time==null){$address_verify_negative_refresh_time="3h";}
	if($address_verify_positive_expire_time==null){$address_verify_positive_expire_time="31d";}
	if($address_verify_positive_refresh_time==null){$address_verify_positive_refresh_time="7d";}
	if($smtpd_error_sleep_time==null){$smtpd_error_sleep_time="1s";}
	if(!is_numeric($smtpd_soft_error_limit)){$smtpd_soft_error_limit=10;}
	if(!is_numeric($smtpd_hard_error_limit)){$smtpd_hard_error_limit=20;}
	if(!is_numeric($smtpd_client_connection_count_limit)){$smtpd_client_connection_count_limit=50;}
	if(!is_numeric($smtpd_client_connection_rate_limit)){$smtpd_client_connection_rate_limit=0;}
	if(!is_numeric($smtpd_client_message_rate_limit)){$smtpd_client_message_rate_limit=0;}
	if(!is_numeric($smtpd_client_recipient_rate_limit)){$smtpd_client_recipient_rate_limit=0;}
	if(!is_numeric($smtpd_client_new_tls_session_rate_limit)){$smtpd_client_new_tls_session_rate_limit=0;}
	if(!is_numeric($initial_destination_concurrency)){$initial_destination_concurrency=5;}
	if(!is_numeric($default_destination_concurrency_limit)){$default_destination_concurrency_limit=20;}
	if(!is_numeric($smtp_destination_concurrency_limit)){$smtp_destination_concurrency_limit=20;}
	if(!is_numeric($local_destination_concurrency_limit)){$local_destination_concurrency_limit=2;}
	if(!is_numeric($default_destination_recipient_limit)){$default_destination_recipient_limit=50;}
	if(!is_numeric($smtpd_recipient_limit)){$smtpd_recipient_limit=1000;}
	if(!is_numeric($default_process_limit)){$default_process_limit=100;}
	if(!is_numeric($qmgr_message_recipient_limit)){$qmgr_message_recipient_limit=20000;}
	if($smtpd_client_event_limit_exceptions==null){$smtpd_client_event_limit_exceptions="\$mynetworks";}
	if($in_flow_delay==null){$in_flow_delay="1s";}
	if($smtp_connect_timeout==null){$smtp_connect_timeout="30s";}
	if($smtp_helo_timeout==null){$smtp_helo_timeout="300s";}
	if($bounce_queue_lifetime==null){$bounce_queue_lifetime="5d";}
	if($maximal_queue_lifetime==null){$maximal_queue_lifetime="5d";}
	if($maximal_backoff_time==null){$maximal_backoff_time="4000s";}
	if($minimal_backoff_time==null){$minimal_backoff_time="300s";}
	if($queue_run_delay==null){$queue_run_delay="300s";}	
	if($smtpd_banner==null){$smtpd_banner="\$myhostname ESMTP \$mail_name";}
	
	
	
	$detect_8bit_encoding_header=$mainmulti->YesNo($detect_8bit_encoding_header);
	$disable_mime_input_processing=$mainmulti->YesNo($disable_mime_input_processing);
	$disable_mime_output_conversion=$mainmulti->YesNo($disable_mime_output_conversion);
	$smtpd_reject_unlisted_sender=$mainmulti->YesNo($smtpd_reject_unlisted_sender);
	$smtpd_reject_unlisted_recipient=$mainmulti->YesNo($smtpd_reject_unlisted_recipient);
	$ignore_mx_lookup_error=$mainmulti->YesNo($ignore_mx_lookup_error);
	$disable_dns_lookups=$mainmulti->YesNo($disable_dns_lookups);
	
	
	
	
	$mime_nesting_limit=$mainmulti->GET("mime_nesting_limit");
	if(!is_numeric($mime_nesting_limit)){
		$mime_nesting_limit=$sock->GET_INFO("mime_nesting_limit");
	}
	
	if(!is_numeric($mime_nesting_limit)){$mime_nesting_limit=100;}
	
	$main->main_array["default_destination_recipient_limit"]=$sock->GET_INFO("default_destination_recipient_limit");
	$main->main_array["smtpd_recipient_limit"]=$sock->GET_INFO("smtpd_recipient_limit");
	
	$main->main_array["header_address_token_limit"]=$sock->GET_INFO("header_address_token_limit");
	$main->main_array["virtual_mailbox_limit"]=$sock->GET_INFO("virtual_mailbox_limit");
	
	if($main->main_array["message_size_limit"]==null){$main->main_array["message_size_limit"]=102400000;}
	if($main->main_array["virtual_mailbox_limit"]==null){$main->main_array["virtual_mailbox_limit"]=102400000;}
	if($main->main_array["default_destination_recipient_limit"]==null){$main->main_array["default_destination_recipient_limit"]=50;}
	if($main->main_array["smtpd_recipient_limit"]==null){$main->main_array["smtpd_recipient_limit"]=1000;}
	
	if($main->main_array["header_address_token_limit"]==null){$main->main_array["header_address_token_limit"]=10240;}
	
	echo "Starting......: message_size_limit={$main->main_array["message_size_limit"]}\n";
	echo "Starting......: default_destination_recipient_limit={$main->main_array["default_destination_recipient_limit"]}\n";
	echo "Starting......: smtpd_recipient_limit={$main->main_array["smtpd_recipient_limit"]}\n";
	echo "Starting......: *** MIME PROCESSING ***\n";
	echo "Starting......: mime_nesting_limit=$mime_nesting_limit\n";
	echo "Starting......: detect_8bit_encoding_header=$detect_8bit_encoding_header\n";
	echo "Starting......: disable_mime_input_processing=$disable_mime_input_processing\n";
	echo "Starting......: disable_mime_output_conversion=$disable_mime_output_conversion\n";
	
	
	
	echo "Starting......: header_address_token_limit={$main->main_array["header_address_token_limit"]}\n";
	echo "Starting......: minimal_backoff_time=$minimal_backoff_time\n";
	echo "Starting......: maximal_backoff_time=$maximal_backoff_time\n";
	echo "Starting......: maximal_queue_lifetime=$maximal_queue_lifetime\n";
	echo "Starting......: bounce_queue_lifetime=$bounce_queue_lifetime\n";
	echo "Starting......: ignore_mx_lookup_error=$ignore_mx_lookup_error\n";
	echo "Starting......: disable_dns_lookups=$disable_dns_lookups\n";
	echo "Starting......: smtpd_banner=$smtpd_banner\n";
	
	
	
	
	if($minimal_backoff_time==null){$minimal_backoff_time="300s";}
	if($maximal_backoff_time==null){$maximal_backoff_time="4000s";}
	if($bounce_queue_lifetime==null){$bounce_queue_lifetime="5d";}
	if($maximal_queue_lifetime==null){$maximal_queue_lifetime="5d";}

	$postfix_ver=$mainmulti->postfix_version();
	if(preg_match("#^([0-9]+)\.([0-9]+)#", $postfix_ver,$re)){$MAJOR=$re[1];$MINOR=$re[2];}
	if($MAJOR>1){
		if($MINOR>9){
			postconf("smtpd_relay_restrictions","permit_mynetworks, reject_unauth_destination");
		}
	}

	
	$address_verify_negative_cache=$mainmulti->YesNo($address_verify_negative_cache);

	postconf("smtpd_reject_unlisted_sender","$smtpd_reject_unlisted_sender");
	postconf("smtpd_reject_unlisted_recipient","$smtpd_reject_unlisted_recipient");
	postconf("address_verify_map","$address_verify_map");
	postconf("address_verify_negative_cache","$address_verify_negative_cache");
	postconf("address_verify_poll_count","$address_verify_poll_count");
	postconf("address_verify_poll_delay","$address_verify_poll_delay");
	postconf("address_verify_sender","$address_verify_sender");
	postconf("address_verify_negative_expire_time","$address_verify_negative_expire_time");
	postconf("address_verify_negative_refresh_time","$address_verify_negative_refresh_time");
	postconf("address_verify_positive_expire_time","$address_verify_positive_expire_time");
	postconf("address_verify_positive_refresh_time","$address_verify_positive_refresh_time");	
	postconf("message_size_limit","$message_size_limit");
	postconf("virtual_mailbox_limit","$message_size_limit");
	postconf("mailbox_size_limit","$message_size_limit");
	postconf("default_destination_recipient_limit","{$main->main_array["default_destination_recipient_limit"]}");
	postconf("smtpd_recipient_limit","{$main->main_array["smtpd_recipient_limit"]}");
	
	postconf("mime_nesting_limit","$mime_nesting_limit");
	postconf("detect_8bit_encoding_header","$detect_8bit_encoding_header");
	postconf("disable_mime_input_processing","$disable_mime_input_processing");
	postconf("disable_mime_output_conversion","$disable_mime_output_conversion");
		
	postconf("minimal_backoff_time","$minimal_backoff_time");
	postconf("maximal_backoff_time","$maximal_backoff_time");
	postconf("maximal_queue_lifetime","$maximal_queue_lifetime");
	postconf("bounce_queue_lifetime","$bounce_queue_lifetime");
	postconf("smtp_connection_cache_on_demand","$smtp_connection_cache_on_demand");
	postconf("smtp_connection_cache_time_limit","$smtp_connection_cache_time_limit");
	postconf("smtp_connection_reuse_time_limit","$smtp_connection_reuse_time_limit");
	postconf("connection_cache_ttl_limit","$connection_cache_ttl_limit");
	postconf("connection_cache_status_update_time","$connection_cache_status_update_time");	
	postconf("smtp_connection_cache_destinations","$smtp_connection_cache_destinationsF");
	postconf("smtpd_error_sleep_time",$smtpd_error_sleep_time);
	postconf("smtpd_soft_error_limit",$smtpd_soft_error_limit);
	postconf("smtpd_hard_error_limit",$smtpd_hard_error_limit);
	postconf("smtpd_client_connection_count_limit",$smtpd_client_connection_count_limit);
	postconf("smtpd_client_connection_rate_limit",$smtpd_client_connection_rate_limit);
	postconf("smtpd_client_message_rate_limit",$smtpd_client_message_rate_limit);
	postconf("smtpd_client_recipient_rate_limit",$smtpd_client_recipient_rate_limit);
	postconf("smtpd_client_new_tls_session_rate_limit",$smtpd_client_new_tls_session_rate_limit);
	postconf("initial_destination_concurrency",$initial_destination_concurrency);
	postconf("default_destination_concurrency_limit",$default_destination_concurrency_limit);
	postconf("smtp_destination_concurrency_limit",$smtp_destination_concurrency_limit);
	postconf("local_destination_concurrency_limit",$local_destination_concurrency_limit);
	postconf("default_destination_recipient_limit",$default_destination_recipient_limit);
	postconf("smtpd_recipient_limit",$smtpd_recipient_limit);
	postconf("default_process_limit",$default_process_limit);
	postconf("qmgr_message_recipient_limit",$qmgr_message_recipient_limit);
	postconf("smtpd_client_event_limit_exceptions",$smtpd_client_event_limit_exceptions);
	postconf("in_flow_delay",$in_flow_delay);
	postconf("smtp_connect_timeout",$smtp_connect_timeout);
	postconf("smtp_helo_timeout",$smtp_helo_timeout);
	postconf("bounce_queue_lifetime",$bounce_queue_lifetime);
	postconf("maximal_queue_lifetime",$maximal_queue_lifetime);
	postconf("maximal_backoff_time",$maximal_backoff_time);
	postconf("minimal_backoff_time",$minimal_backoff_time);
	postconf("queue_run_delay",$queue_run_delay);	
	postconf("smtp_fallback_relay",$smtp_fallback_relay);
	postconf("ignore_mx_lookup_error",$ignore_mx_lookup_error);
	postconf("disable_dns_lookups",$disable_dns_lookups);
	postconf("smtpd_banner",$smtpd_banner);
	
	

	
	
	
	if(!isset($GLOBALS["POSTFIX_HEADERS_CHECK_BUILDED"])){headers_check(1);}
	
	
	$HashMainCf=unserialize(base64_decode($sock->GET_INFO("HashMainCf")));
	if(is_array($HashMainCf)){
		while (list ($key, $val) = each ($HashMainCf) ){
			system("{$GLOBALS["postconf"]} -e \"$key = $val\" >/dev/null 2>&1");
		}
	}
	
	$hashT=new main_hash_table();
	$hashT->mydestination();	
	
	perso_settings();
}

function LoadIpAddresses($nic){
	$unix=new unix();
	$ifconfig=$unix->find_program("ifconfig");
	exec("$ifconfig 2>&1",$results);
	while (list ($index, $line) = each ($results) ){
		if(preg_match("#inet adr:([0-9\.]+)#", $line,$re)){
			$array[trim($re[1])]=trim($re[1]);
		}
	}
	
	return $array;
}

function inet_interfaces(){
	$newarray=array();
	include_once(dirname(__FILE__)."/ressources/class.system.network.inc");
	if(!isset($GLOBALS["CLASS_SOCKET"])){$GLOBALS["CLASS_SOCKET"]=new sockets();$sock=$GLOBALS["CLASS_SOCKET"];}else{$sock=$GLOBALS["CLASS_SOCKET"];}
	if($sock->GET_INFO("EnablePostfixMultiInstance")==1){return;}
	$table=explode("\n",$sock->GET_INFO("PostfixBinInterfaces"));	
	$unix=new unix();
	
	$interfacesexists=$unix->NETWORK_ALL_INTERFACES();
	while (list ($num, $myarray) = each ($interfacesexists) ){
		$INTERFACE[$myarray["IPADDR"]]=$myarray["IPADDR"];
	}
	
	while (list ($num, $val) = each ($table) ){
		$val=trim($val);
		if($val==null){continue;}
		if($val=="all"){
			echo "Starting......: Postfix skip $val\n";
			continue;
		}
		if(isset($already[$val])){continue;}
		echo "Starting......: Postfix checking interface : `$val`\n";
		if($val=="127.0.0.1"){
			$newarray[]=$val;
			$already[$val]=true;
			continue;
		}
		if(preg_match("#^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+#", $val)){
			if(!isset($INTERFACE[$val])){
				echo "Starting......: Postfix $val interface not found\n";
				continue;
			}
		}
		
		$already[$val]=true;
		if(preg_match("#[a-zA-Z]+[0-9]+#", $val)){
			$ipsaddrs=LoadIpAddresses($val);
			while (list ($a, $b) = each ($ipsaddrs) ){
				echo "Starting......: Postfix found interface '$b'\n";
				$newarray[]=$b;
			}
		continue;
		}
		
		if($val=="all"){continue;}
		
		echo "Starting......: Postfix add $val interface in settings\n";
		$newarray[]=$val;
	}
	
	if(count($newarray)>0){
		while (list ($a, $b) = each ($newarray) ){$testinets[$b]=$b;}
		$users=new usersMenus();
		if(($users->roundcube_installed) OR ($users->ZARAFA_INSTALLED)){
			if(!isset($testinets["127.0.0.1"])){
				echo "Starting......: Postfix Listen interface Roundcube or Zarafa installed, force to listen 127.0.0.1\n";
				$newarray[]="127.0.0.1";
			}
		}		
	}
	

	if(count($newarray)>0){
		$finale=implode(",",$newarray);
		$finale=str_replace(',,',',',$finale);
	}else{
		$unix=new unix();
		$INT=$unix->NETWORK_ALL_INTERFACES(true);
		$INT["127.0.0.1"]="127.0.0.1";
		while (list ($a, $b) = each ($INT) ){$INTS[]=$a;}
		$finale=@implode(",", $INTS);
	}
	
	echo "Starting......: Postfix Listen interface(s) \"$finale\"\n";
	
	
	postconf("inet_interfaces",$finale);
	postconf("artica-filter_destination_recipient_limit",1);
	postconf("inet_protocols","ipv4");
	postconf("smtp_bind_address6","");
	
	
	 
	
	$smtp_bind_address6=$sock->GET_INFO("smtp_bind_address6");
	$PostfixEnableIpv6=$sock->GET_INFO("PostfixEnableIpv6");
	if($PostfixEnableIpv6==null){$PostfixEnableIpv6=0;}
	if($PostfixEnableIpv6=1){
		if(trim($smtp_bind_address6)<>null){
			echo "Starting......: Postfix Listen ipv6 \"$smtp_bind_address6\"\n";
			postconf("inet_protocols","all");
			postconf("smtp_bind_address6",$smtp_bind_address6);
		}
	}
	
	
	
}

function MailBoxTransport(){
	$main=new maincf_multi("master","master");
	if(!isset($GLOBALS["CLASS_SOCKET"])){$GLOBALS["CLASS_SOCKET"]=new sockets();$sock=$GLOBALS["CLASS_SOCKET"];}else{$sock=$GLOBALS["CLASS_SOCKET"];}
	if(!isset($GLOBALS["CLASS_USERS_MENUS"])){$users=new usersMenus();$GLOBALS["CLASS_USERS_MENUS"]=$users;}else{$users=$GLOBALS["CLASS_USERS_MENUS"];}
	
	$mailbox_transport=trim($main->GET("mailbox_transport"));
	
	if($mailbox_transport<>null){
		postconf("mailbox_transport",$mailbox_transport);
		postconf("zarafa_destination_recipient_limit",1);
		return;	
	}
	
	

	$default=$main->getMailBoxTransport();
	postconf("zarafa_destination_recipient_limit",1);
	echo "Starting......: Postfix mailbox_transport $default\n";
	postconf("mailbox_transport",$default);
	

	
	if(preg_match("#lmtp:(.+?):[0-9]+#",$default)){
		if(!$users->ZARAFA_INSTALLED){
			if(!$users->cyrus_imapd_installed){
				echo "Starting......: Postfix None of Zarafa or cyrus imap installed on this server\n";
				disable_lmtp_sasl();
				return null;
			}
			echo "Starting......: Postfix \"LMTP\" is enabled ($default)\n";
			$ldap=new clladp();
			$CyrusLMTPListen=trim($sock->GET_INFO("CyrusLMTPListen"));
			$cyruspass=$ldap->CyrusPassword();
			if($CyrusLMTPListen<>null){
				@file_put_contents("/etc/postfix/lmtpauth","$CyrusLMTPListen\tcyrus:$cyruspass");
				shell_exec("{$GLOBALS["postmap"]} hash:/etc/postfix/lmtpauth");
				postconf("lmtp_sasl_auth_enable","yes");
				postconf("lmtp_sasl_password_maps","hash:/etc/postfix/lmtpauth");
				postconf("lmtp_sasl_mechanism_filter","plain, login");
				postconf("lmtp_sasl_security_options",null);	
			}		
		}
	}else{
		disable_lmtp_sasl();
	}
	
	
	}
	
function disable_lmtp_sasl(){
	echo "Starting......: Postfix LMTP is disabled\n";
	postconf("lmtp_sasl_auth_enable","no");
	
			
}
	
function disable_smtp_sasl(){
	postconf("smtp_sasl_password_maps","");
	postconf("smtp_sasl_auth_enable","no");
	
}

function perso_settings(){
	$main=new main_perso();
	$main->replace_conf("/etc/postfix/main.cf");
	if($GLOBALS["RELOAD"]){exec("{$GLOBALS["postfix"]} reload >/dev/null 2>&1");}
	
}

function luser_relay(){
	if(!isset($GLOBALS["CLASS_SOCKET"])){$GLOBALS["CLASS_SOCKET"]=new sockets();$sock=$GLOBALS["CLASS_SOCKET"];}else{$sock=$GLOBALS["CLASS_SOCKET"];}
	$luser_relay=trim($sock->GET_INFO("luser_relay"));
	if($luser_relay==null){
		echo "Starting......: Postfix no Unknown user recipient set\n";
		system("{$GLOBALS["postconf"]} -e \"luser_relay = \" >/dev/null 2>&1");
		return;
	}
	echo "Starting......: Postfix Unknown user set to $luser_relay\n";
	postconf("luser_relay",$luser_relay);
	postconf("local_recipient_maps",null);
	if($GLOBALS["RELOAD"]){shell_exec("{$GLOBALS["postfix"]} reload >/dev/null 2>&1");}
	
}
function smtpd_sender_restrictions(){
	if(!isset($GLOBALS["CLASS_SOCKET"])){$GLOBALS["CLASS_SOCKET"]=new sockets();$sock=$GLOBALS["CLASS_SOCKET"];}else{$sock=$GLOBALS["CLASS_SOCKET"];}
	$main=new maincf_multi("master","master");
	$smtpd_sender_restrictions_black=$main->Blacklist_generic();
	
	
	$RestrictToInternalDomains=$sock->GET_INFO("RestrictToInternalDomains");
	$EnablePostfixInternalDomainsCheck=$sock->GET_INFO("EnablePostfixInternalDomainsCheck");
	$reject_non_fqdn_sender=$sock->GET_INFO('reject_non_fqdn_sender');	
	$reject_unknown_sender_domain=$sock->GET_INFO('reject_unknown_sender_domain');
	
	if($EnablePostfixInternalDomainsCheck==1){
			$smtpd_sender_restrictions[]="reject_unknown_sender_domain";
			$reject_unknown_sender_domain=0;
	
	}
	
	
	
	if($RestrictToInternalDomains==1){
		BuildAllWhitelistedServer();
		BuildAllMyDomains();
		$smtpd_sender_restrictions[]="check_client_access hash:/etc/postfix/all_whitelisted_servers";
		$smtpd_sender_restrictions[]="check_sender_access hash:/etc/postfix/all_internal_domains";
		if($reject_unknown_sender_domain==1){$smtpd_sender_restrictions[]="reject_unknown_sender_domain";}
		if($reject_non_fqdn_sender==1){$smtpd_sender_restrictions[]="reject_non_fqdn_sender";}
		if($smtpd_sender_restrictions_black<>null){$smtpd_sender_restrictions[]=$smtpd_sender_restrictions_black;}
		$smtpd_sender_restrictions[]="reject";
	}else{
		if($reject_unknown_sender_domain==1){$smtpd_sender_restrictions[]="reject_unknown_sender_domain";}
		if($reject_non_fqdn_sender==1){$smtpd_sender_restrictions[]="reject_non_fqdn_sender";}
		if($smtpd_sender_restrictions_black<>null){$smtpd_sender_restrictions[]=$smtpd_sender_restrictions_black;}
	}
	
	if(!isset($smtpd_sender_restrictions)){postconf("smtpd_sender_restrictions");return;}
	if(!is_array($smtpd_sender_restrictions)){postconf("smtpd_sender_restrictions");return;}
	
	$final=@implode(",",$smtpd_sender_restrictions);
	postconf("smtpd_sender_restrictions",$final);
	postconf("smtpd_helo_restrictions",$final);
	
	
	
}

function smtpd_end_of_data_restrictions(){
	if(!isset($GLOBALS["CLASS_SOCKET"])){$GLOBALS["CLASS_SOCKET"]=new sockets();$sock=$GLOBALS["CLASS_SOCKET"];}else{$sock=$GLOBALS["CLASS_SOCKET"];}
	if(!isset($GLOBALS["CLASS_USERS_MENUS"])){$users=new usersMenus();$GLOBALS["CLASS_USERS_MENUS"]=$users;}else{$users=$GLOBALS["CLASS_USERS_MENUS"];}
	$EnableArticaPolicyFilter=$sock->GET_INFO("EnableArticaPolicyFilter");
	$EnableArticaPolicyFilter=0;
	$EnableCluebringer=$sock->GET_INFO("EnableCluebringer");
	
	$main=new maincf_multi("master");
	$array_filters=unserialize(base64_decode($main->GET_BIGDATA("PluginsEnabled")));
	$ENABLE_POSTFWD2=$array_filters["APP_POSTFWD2"];
	if(!is_numeric($ENABLE_POSTFWD2)){$ENABLE_POSTFWD2=0;}
	
	if($ENABLE_POSTFWD2==1){
		echo "Starting......: Postfix Postfwd2 is enabled\n";
		$smtpd_end_of_data_restrictions[]="check_policy_service inet:127.0.0.1:10040";
	}
	
	
	
	if($users->CLUEBRINGER_INSTALLED){
		if($EnableCluebringer==1){
			echo "Starting......: Postfix ClueBringer is enabled\n";
			$smtpd_end_of_data_restrictions[]="check_policy_service inet:127.0.0.1:13331";
		}
	}
	
	
	if($EnableArticaPolicyFilter==1){
		$smtpd_end_of_data_restrictions[]="check_policy_service inet:127.0.0.1:54423";
		
	}
	if(isset($smtpd_end_of_data_restrictions)){	
		if(!is_array($smtpd_end_of_data_restrictions)){
			system("{$GLOBALS["postconf"]} -e \"smtpd_end_of_data_restrictions =\" >/dev/null 2>&1");
			return;
		}
	}
	$final=@implode(",",$smtpd_end_of_data_restrictions);
	postconf("smtpd_end_of_data_restrictions",$final);
	
}

function BuildAllMyDomains(){
	$ldap=new clladp();
	$hash=$ldap->AllDomains();
	while (list ($num, $ligne) = each ($hash) ){	
		$ligne=trim($ligne);
		if($ligne==null){continue;}
		$doms[]="$ligne\tOK";
	}
	
	@file_put_contents("/etc/postfix/all_internal_domains",@implode("\n",$doms));
	shell_exec("{$GLOBALS["postmap"]} hash:/etc/postfix/all_internal_domains");
	
	
}
function BuildAllWhitelistedServer(){
	if(!isset($GLOBALS["CLASS_SOCKET"])){$GLOBALS["CLASS_SOCKET"]=new sockets();$sock=$GLOBALS["CLASS_SOCKET"];}else{$sock=$GLOBALS["CLASS_SOCKET"];}
	
	$q=new mysql();
	$sql="SELECT * FROM postfix_whitelist_con";
	$results=$q->QUERY_SQL($sql,"artica_backup");
	if(!$q->ok){echo "$q->mysql_error\n";}
	
	while($ligne=mysql_fetch_array($results,MYSQL_ASSOC)){	
		$f[]="{$ligne["ipaddr"]}\tOK";
		$f[]="{$ligne["hostname"]}\tOK";
		
		
	}		
	
	@file_put_contents("/etc/postfix/all_whitelisted_servers",@implode("\n",$f));
	shell_exec("{$GLOBALS["postmap"]} hash:/etc/postfix/all_whitelisted_servers");

}

function fix_postdrop_perms(){
	$unix=new unix();
	$postfix_bin=$unix->find_program("postfix");
	$chgrp_bin=$unix->find_program("chgrp");
	$killall_bin=$unix->find_program("killall");
	shell_exec("$postfix_bin stop 2>&1");
	shell_exec("$killall_bin -9 postdrop 2>&1");
	shell_exec("$chgrp_bin -R postdrop /var/spool/postfix/public 2>&1");
	shell_exec("$chgrp_bin -R postdrop /var/spool/postfix/maildrop/ 2>&1");
	shell_exec("$postfix_bin check 2>&1");
	shell_exec("$postfix_bin start 2>&1");
	
	
}

function postscreen($hostname=null){
	
	if($GLOBALS["EnablePostfixMultiInstance"]==1){
		echo "Starting......: PostScreen multiple instances, running for -> $hostname\n";
		shell_exec(LOCATE_PHP5_BIN2()." ".dirname(__FILE__)."/exec.postfix-multi.php --postscreen $hostname");
	}	
	$permit_mynetworks=null;
	$user=new usersMenus();
	if(!$user->POSTSCREEN_INSTALLED){echo "Starting......: PostScreen is not installed, you should upgrade to 2.8 postfix version\n";return;}
	$main=new maincf_multi("master","master");
	$EnablePostScreen=$main->GET("EnablePostScreen");
	$sock=new sockets();
	$TrustMyNetwork=$sock->GET_INFO("TrustMyNetwork");
	if(!is_numeric($TrustMyNetwork)){$TrustMyNetwork=1;}
	
	if($EnablePostScreen<>1){echo "Starting......: PostScreen is not enabled\n";return;}
	echo "Starting......: PostScreen configuring....\n";
	if(!is_file("/etc/postfix/postscreen_access.cidr")){@file_put_contents("/etc/postfix/postscreen_access.cidr","#");}
	if(!is_file("/etc/postfix/postscreen_access.hosts")){@file_put_contents("/etc/postfix/postscreen_access.hosts"," ");}
	if($TrustMyNetwork==1){$permit_mynetworks="permit_mynetworks,";}
	
	postconf("postscreen_access_list","{$permit_mynetworks}cidr:/etc/postfix/postscreen_access.cidr");
	
	
	$postscreen_bare_newline_action=$main->GET("postscreen_bare_newline_action");
	$postscreen_bare_newline_enable=$main->GET("postscreen_bare_newline_enable");
	
	$postscreen_bare_newline_ttl=$main->GET("postscreen_bare_newline_ttl");
	$postscreen_cache_cleanup_interval=$main->GET("postscreen_cache_cleanup_interval");
	$postscreen_cache_retention_time=$main->GET("postscreen_cache_retention_time");
	$postscreen_client_connection_count_limit=$main->GET("postscreen_client_connection_count_limit");
	$postscreen_pipelining_enable=$main->GET("postscreen_pipelining_enable");
	$postscreen_pipelining_action=$main->GET("postscreen_pipelining_action");
	$postscreen_pipelining_ttl=$main->GET("postscreen_pipelining_ttl");
	$postscreen_post_queue_limit=$main->GET("postscreen_post_queue_limit");
	$postscreen_pre_queue_limit=$main->GET("postscreen_pre_queue_limit");
	$postscreen_non_smtp_command_enable=$main->GET("postscreen_non_smtp_command_enable");
	$postscreen_non_smtp_command_action=$main->GET("postscreen_non_smtp_command_action");
	$postscreen_non_smtp_command_ttl=$main->GET("postscreen_non_smtp_command_ttl");
	$postscreen_forbidden_commands=$main->GET("postscreen_forbidden_command");
	$postscreen_dnsbl_action=$main->GET("postscreen_dnsbl_action");
	$postscreen_dnsbl_ttl=$main->GET("postscreen_dnsbl_ttl");
	$postscreen_dnsbl_threshold=$main->GET("postscreen_dnsbl_threshold");	
	
	
	if($postscreen_bare_newline_action==null){$postscreen_bare_newline_action="ignore";}
	if(!is_numeric($postscreen_bare_newline_enable)){$postscreen_bare_newline_enable="0";}
	if($postscreen_bare_newline_ttl==null){$postscreen_bare_newline_ttl="30d";}
	if($postscreen_cache_cleanup_interval==null){$postscreen_cache_cleanup_interval="12h";}
	if($postscreen_cache_retention_time==null){$postscreen_cache_retention_time="7d";}
	if($postscreen_client_connection_count_limit==null){$postscreen_client_connection_count_limit="50";}
	if($postscreen_pipelining_enable==null){$postscreen_pipelining_enable="0";}
	if($postscreen_pipelining_action==null){$postscreen_pipelining_action="ignore";}
	if($postscreen_pipelining_ttl==null){$postscreen_pipelining_ttl="30d";}			
	if($postscreen_post_queue_limit==null){$postscreen_post_queue_limit="100";}
	if($postscreen_pre_queue_limit==null){$postscreen_pre_queue_limit="100";}
	
	if($postscreen_non_smtp_command_enable==null){$postscreen_non_smtp_command_enable="0";}
	if($postscreen_non_smtp_command_action==null){$postscreen_non_smtp_command_action="drop";}
	if($postscreen_non_smtp_command_ttl==null){$postscreen_non_smtp_command_ttl="30d";}
	if($postscreen_forbidden_commands==null){$postscreen_forbidden_commands="CONNECT, GET, POST";}
	if($postscreen_dnsbl_action==null){$postscreen_dnsbl_action="ignore";}
	if($postscreen_dnsbl_action==null){$postscreen_dnsbl_action="ignore";}
	if($postscreen_dnsbl_ttl==null){$postscreen_dnsbl_ttl="1h";}
	if($postscreen_dnsbl_threshold==null){$postscreen_dnsbl_threshold="1";}
	
	if($postscreen_bare_newline_enable==1){$postscreen_bare_newline_enable="yes";}else{$postscreen_bare_newline_enable="no";}
	if($postscreen_pipelining_enable==1){$postscreen_pipelining_enable="yes";}else{$postscreen_pipelining_enable="no";}
	if($postscreen_non_smtp_command_enable==1){$postscreen_non_smtp_command_enable="yes";}else{$postscreen_non_smtp_command_enable="no";}
	
	
	postconf("postscreen_bare_newline_action",$postscreen_bare_newline_action);
	postconf("postscreen_bare_newline_enable",$postscreen_bare_newline_enable);
	postconf("postscreen_bare_newline_ttl",$postscreen_bare_newline_ttl);
	postconf("postscreen_cache_cleanup_interval",$postscreen_cache_cleanup_interval);
	postconf("postscreen_cache_retention_time",$postscreen_cache_retention_time);
	postconf("postscreen_client_connection_count_limit",$postscreen_client_connection_count_limit);
	postconf("postscreen_client_connection_count_limit",$postscreen_client_connection_count_limit);
	postconf("postscreen_pipelining_enable",$postscreen_pipelining_enable);
	postconf("postscreen_pipelining_action",$postscreen_pipelining_action);
	postconf("postscreen_pipelining_ttl",$postscreen_pipelining_ttl);
	postconf("postscreen_post_queue_limit",$postscreen_post_queue_limit);
	postconf("postscreen_pre_queue_limit",$postscreen_pre_queue_limit);
	postconf("postscreen_non_smtp_command_enable",$postscreen_non_smtp_command_enable);
	postconf("postscreen_non_smtp_command_action",$postscreen_non_smtp_command_action);
	postconf("postscreen_non_smtp_command_ttl",$postscreen_non_smtp_command_ttl);
	postconf("postscreen_forbidden_command",$postscreen_forbidden_commands);
	postconf("postscreen_dnsbl_action",$postscreen_dnsbl_action);
	postconf("postscreen_dnsbl_ttl",$postscreen_dnsbl_ttl);
	postconf("postscreen_dnsbl_threshold",$postscreen_dnsbl_threshold);
	postconf("postscreen_cache_map","btree:\\\$data_directory/postscreen_master_cache");
	
	
	
	
	$dnsbl_array=unserialize(base64_decode($main->GET_BIGDATA("postscreen_dnsbl_sites")));
	if(is_array($dnsbl_array)){
		while (list ($site, $threshold) = each ($dnsbl_array) ){if($site==null){continue;}$dnsbl_array_compiled[]="$site*$threshold";}
	}
		
	$final_dnsbl=null;
	if(is_array($dnsbl_array_compiled)){$final_dnsbl=@implode(",",$dnsbl_array_compiled);}
	postconf("postscreen_dnsbl_sites",$final_dnsbl);
	
	if(!isset($GLOBALS["CLASS_SOCKET"])){$GLOBALS["CLASS_SOCKET"]=new sockets();$sock=$GLOBALS["CLASS_SOCKET"];}else{$sock=$GLOBALS["CLASS_SOCKET"];}
	
	$q=new mysql();
	$sql="SELECT * FROM postfix_whitelist_con";
	$results=$q->QUERY_SQL($sql,"artica_backup");
	if(!$q->ok){echo "$q->mysql_error\n";}
	$nets=array();
	$hostsname=array();
	$ldap=new clladp();
	$ipClass=new IP();	
	
	while($ligne=mysql_fetch_array($results,MYSQL_ASSOC)){	
		
		$ligne["ipaddr"]=trim($ligne["ipaddr"]);
		$ligne["hostname"]=trim($ligne["hostname"]);
			
		if($ligne["hostname"]==null){continue;}
		if($ligne["ipaddr"]==null){continue;}
			
		if(!$ipClass->isIPAddress($ligne["hostname"])){
			$hostsname[]="{$ligne["hostname"]}\tOK";
		}else{
			if(preg_match("#^[0-9]+\.[0-9]+\.[0-9]+#", $ligne["hostname"])){
				$nets[]="{$ligne["hostname"]}\tdunno";
			}
		}
		
		if(!$ipClass->isIPAddress($ligne["ipaddr"])){
			$hostsname[]="{$ligne["ipaddr"]}\tOK";
		}else{
			if(preg_match("#^[0-9]+\.[0-9]+\.[0-9]+#", $ligne["ipaddr"])){
				$nets[]="{$ligne["ipaddr"]}\tdunno";
			}
		}		
		
	}		
	

		
		
	

	$networks=$ldap->load_mynetworks();	
	if(is_array($networks)){
		while (list ($num, $ligne) = each ($networks) ){
			$ligne=trim($ligne);
			if($ligne==null){continue;}
			if(!$ipClass->isIPAddress($ligne)){
				$hostsname[]="$ligne\tOK";
			}else{
				if(preg_match("#^[0-9]+\.[0-9]+\.[0-9]+#", $ligne)){
					$nets[]="$ligne\tdunno";
				}
			}
		}
	}
	
	$postfix_global_whitelist_to_mx=$main->postfix_global_whitelist_to_mx();
	if(count($postfix_global_whitelist_to_mx)>0){
		while (list ($num, $ligne) = each ($postfix_global_whitelist_to_mx) ){
			$nets[]="$ligne\tdunno";
		}
		
	}
	
	@unlink("/etc/postfix/postscreen_access.hosts");
	@unlink("/etc/postfix/postscreen_access.cidr");
	
	if(count($hostsname)>0){
		@file_put_contents("/etc/postfix/postscreen_access.hosts",@implode("\n",$hostsname));
		$postscreen_access=",hash:/etc/postfix/postscreen_access.hosts";
	}
	if(!is_file("/etc/postfix/postscreen_access.hosts")){@file_put_contents("/etc/postfix/postscreen_access.hosts", "\n");}
	
	shell_exec("{$GLOBALS["postmap"]} hash:/etc/postfix/postscreen_access.hosts >/dev/null 2>&1");
	
	if(count($nets)>0){@file_put_contents("/etc/postfix/postscreen_access.cidr",@implode("\n",$nets));}
	postconf("postscreen_access_list","permit_mynetworks,cidr:/etc/postfix/postscreen_access.cidr$postscreen_access");
	
	MasterCFBuilder();
	}
	
function MasterCF_DOMAINS_THROTTLE_SMTP_CONNECTION_CACHE_DESTINATIONS($uuid){	
	$main=new maincf_multi("master","master");
	$array=unserialize(base64_decode($main->GET_BIGDATA("domain_throttle_daemons_list")));	
	$caches=$array[$uuid]["smtp-instance-cache-destinations"];
	if(count($caches)==0){return null;}
	while (list ($domain, $none) = each ($caches) ){if(trim($domain)<>null){$f[]="$domain\tOK";}}
	@file_put_contents("/etc/postfix/{$uuid}_CONNECTION_CACHE_DESTINATIONS", implode("\n", $f));
	shell_exec("{$GLOBALS["postmap"]} hash:/etc/postfix/{$uuid}_CONNECTION_CACHE_DESTINATIONS >/dev/null 2>&1");
	return "smtp_connection_cache_destinations=hash:/etc/postfix/{$uuid}_CONNECTION_CACHE_DESTINATIONS";
}
	
function MasterCF_DOMAINS_THROTTLE(){
	$main=new maincf_multi("master","master");
	$array=unserialize(base64_decode($main->GET_BIGDATA("domain_throttle_daemons_list")));	
	
	$f=explode("\n",@file_get_contents("/etc/postfix/main.cf"));
	if(!is_array($f)){$f=array();}
	while (list ($index, $line) = each ($f) ){
		if(preg_match("#^[0-9]+_destination#",$line)){continue;}
		if(preg_match("#^[0-9]+_delivery_#",$line)){continue;}
		if(preg_match("#^[0-9]+_initial_#",$line)){continue;}
		$new[]=$line;
	}
	if($GLOBALS["VERBOSE"]){echo "MasterCF_DOMAINS_THROTTLE():: Cleaning main.cf done..\n";}
	@file_put_contents("/etc/postfix/main.cf",@implode("\n",$new));
	unset($new);
	
	
	if(!is_array($array)){
		if($GLOBALS["VERBOSE"]){echo "MasterCF_DOMAINS_THROTTLE():: Not An Array line ". __LINE__."\n";}
		return null;
	}
	
	while (list ($uuid, $conf) = each ($array) ){
		if($conf["ENABLED"]<>1){continue;}
		if(count($conf["DOMAINS"])==0){continue;}
		$maps=array();
		if($conf["transport_destination_concurrency_failed_cohort_limit"]==null){$conf["transport_destination_concurrency_failed_cohort_limit"]=1;}
		if($conf["transport_delivery_slot_loan"]==null){$conf["transport_delivery_slot_loan"]=3;}
		if($conf["transport_delivery_slot_discount"]==null){$conf["transport_delivery_slot_discount"]=50;}
		if($conf["transport_delivery_slot_cost"]==null){$conf["transport_delivery_slot_cost"]=5;}
		if($conf["transport_extra_recipient_limit"]==null){$conf["transport_extra_recipient_limit"]=1000;}
		if($conf["transport_initial_destination_concurrency"]==null){$conf["transport_initial_destination_concurrency"]=5;}
		if($conf["transport_destination_recipient_limit"]==null){$conf["transport_destination_recipient_limit"]=50;}		
		if($conf["transport_destination_concurrency_limit"]==null){$conf["transport_destination_concurrency_limit"]=20;}
		if($conf["transport_destination_rate_delay"]==null){$conf["transport_destination_rate_delay"]="0s";}
		if(!is_numeric($conf["default_process_limit"])){$conf["default_process_limit"]=100;}
		$moinso["{$uuid}_destination_concurrency_failed_cohort_limit"]="{$conf["transport_destination_concurrency_failed_cohort_limit"]}";
		$moinso["{$uuid}_delivery_slot_loan"]="{$conf["transport_delivery_slot_loan"]}";
		$moinso["{$uuid}_delivery_slot_discount"]="{$conf["transport_delivery_slot_discount"]}";
		$moinso["{$uuid}_delivery_slot_cost"]="{$conf["transport_delivery_slot_cost"]}";
		$moinso["{$uuid}_initial_destination_concurrency"]="{$conf["transport_initial_destination_concurrency"]}";
		$moinso["{$uuid}_destination_recipient_limit"]="{$conf["transport_destination_recipient_limit"]}";
		$moinso["{$uuid}_destination_concurrency_limit"]="{$conf["transport_destination_concurrency_limit"]}";
		$moinso["{$uuid}_destination_rate_delay"]="{$conf["transport_destination_rate_delay"]}";
		
		
		$moinsoMasterText=null;
		if(is_numeric($conf["smtp_connection_cache_on_demand"])){
			if($conf["smtp_connection_cache_on_demand"]==0){
				$moinsoMaster[]="smtp_connection_cache_on_demand=no";
			}else{
				$moinsoMaster[]="smtp_connection_cache_on_demand=yes";
				$moinsoMaster[]="smtp_connection_cache_time_limit={$conf["smtp_connection_cache_time_limit"]}";
				$moinsoMaster[]="smtp_connection_reuse_time_limit={$conf["smtp_connection_reuse_time_limit"]}";
				$cache_destinations=MasterCF_DOMAINS_THROTTLE_SMTP_CONNECTION_CACHE_DESTINATIONS($uuid);
				if($cache_destinations<>null){$moinsoMaster[]=$cache_destinations;}
			}
			
		}else{
			if($GLOBALS["VERBOSE"]){echo "DOMAINS_THROTTLE:: smtp_connection_cache_on_demand \"{$conf["smtp_connection_cache_on_demand"]}\" is not a numeric\n";}
		}
		
		if($GLOBALS["VERBOSE"]){echo "DOMAINS_THROTTLE:: smtp_connection_cache_on_demand \"". count($moinsoMaster)." value(s)\n";}
		if(count($moinsoMaster)>0){$moinsoMasterText=" -o ".@implode(" -o ", $moinsoMaster);}		
		
		
		$instances[]="\n# THROTTLE {$conf["INSTANCE_NAME"]}\n$uuid\tunix\t-\t-\tn\t-\t{$conf["default_process_limit"]}\tsmtp$moinsoMasterText";
		while (list ($domain, $null) = each ($conf["DOMAINS"]) ){$maps[$domain]="$uuid:";}
		while (list ($a, $b) = each ($maps) ){$maps_final[]="$a\t$b";}
	}
	
	if($GLOBALS["VERBOSE"]){echo "MasterCF_DOMAINS_THROTTLE():: ". count($moinso)." main.cf command lines\n";}
	if(is_array($moinso)){
		while (list ($key, $val) = each ($moinso) ){
			postconf($key,$val);
		}
	}
	
	if(!is_array($instances)){return null;}
	@file_put_contents("/etc/postfix/transport.throttle",@implode("\n",$maps_final)."\n");
	return @implode("\n",$instances)."\n";
	
	
}

function debug_peer_list(){
	$main=new maincf_multi("master");
	$datas=unserialize(base64_decode($main->GET_BIGDATA("debug_peer_list")));
	
	if(count($datas)==0){
		postconf("debug_peer_list",null);
		return;
	}
	while (list ($index, $file) = each ($datas)){
			if(trim($index)==null){continue;}
			$f[]=$index;
		}
		
		if(count($f)>0){
			postconf("debug_peer_level",3);
			postconf("debug_peer_list",@implode(",", $f));
			
		}	
	
	
}

function haproxy_compliance(){
	$main=new maincf_multi("master");
	$EnablePostfixHaProxy=$main->GET("EnablePostfixHaProxy");
	if(!is_numeric($EnablePostfixHaProxy)){$EnablePostfixHaProxy=0;}	
	
	$users=new usersMenus();
	if(preg_match("#^([0-9]+)\.([0-9]+)#", $users->POSTFIX_VERSION,$re)){
		$major=intval($re[1]);
		$minor=intval($re[2]);
		$binver="{$major}{$minor}";
		if($EnablePostfixHaProxy==1){
			if($binver<210){echo "Starting......: HaProxy compliance: require 2.10 minimal.\n";return;}
		}
		
	}
	
	if($EnablePostfixHaProxy==0){
		echo "Starting......: HaProxy compliance: disabled\n";
		postconf("postscreen_upstream_proxy_protocol",null);
		postconf("smtpd_upstream_proxy_protocol",null);
		return;
	}
	
	echo "Starting......: HaProxy compliance: enabled\n";
	$EnablePostScreen=$main->GET("EnablePostScreen");
	if(!is_numeric($EnablePostScreen)){$EnablePostScreen=0;}	
	if(!$users->POSTSCREEN_INSTALLED){$EnablePostScreen=0;}
	
	if($EnablePostScreen==1){
		echo "Starting......: HaProxy compliance: enabled + PostScreen\n";
		postconf("postscreen_upstream_proxy_protocol","haproxy");
		postconf("smtpd_upstream_proxy_protocol",null);
	}else{
		echo "Starting......: HaProxy compliance: enabled + SMTPD\n";
		postconf("postscreen_upstream_proxy_protocol",null);
		postconf("smtpd_upstream_proxy_protocol","haproxy");
	}

}


function ScanLibexec(){
	if(!is_dir("/usr/lib/postfix")){return;}
	if(!is_dir("/usr/libexec/postfix")){return;}
	$unix=new unix();
	$ln=$unix->find_program("ln");
	
	$files=$unix->DirFiles("/usr/libexec/postfix");
	while (list ($filename, $MFARRY) = each ($files) ){
		if(!is_link("/usr/lib/postfix/$filename")){
			if(!is_link("/usr/libexec/postfix/$filename")){
				@unlink("/usr/lib/postfix/$filename");
				echo "Starting......: linking $filename\n";
				shell_exec("$ln -sf /usr/libexec/postfix/$filename /usr/lib/postfix/$filename");
			}
		}
		
	}
	
	
	
	
}


function MasterCFBuilder($restart_service=false){
	$smtp_ssl=null;
	if(!isset($GLOBALS["CLASS_SOCKET"])){$GLOBALS["CLASS_SOCKET"]=new sockets();$sock=$GLOBALS["CLASS_SOCKET"];}else{$sock=$GLOBALS["CLASS_SOCKET"];}
	if(!is_object($GLOBALS["CLASS_SOCKET"])){$GLOBALS["CLASS_SOCKET"]=new sockets();$sock=$GLOBALS["CLASS_SOCKET"];}else{$sock=$GLOBALS["CLASS_SOCKET"];}
	$EnableArticaSMTPFilter=$sock->GET_INFO("EnableArticaSMTPFilter");
	$EnableArticaSMTPFilter=0;
	$EnableAmavisInMasterCF=$sock->GET_INFO('EnableAmavisInMasterCF');
	$EnableAmavisDaemon=$sock->GET_INFO('EnableAmavisDaemon');
	$PostfixEnableMasterCfSSL=$sock->GET_INFO("PostfixEnableMasterCfSSL");
	$ArticaFilterMaxProc=$sock->GET_INFO("ArticaFilterMaxProc");
	$PostfixEnableSubmission=$sock->GET_INFO("PostfixEnableSubmission");
	$EnableASSP=$sock->GET_INFO('EnableASSP');
	$PostfixBindInterfacePort=$sock->GET_INFO("PostfixBindInterfacePort");
	$TrustMyNetwork=$sock->GET_INFO("TrustMyNetwork");
	if(!is_numeric($TrustMyNetwork)){$TrustMyNetwork=1;}
	
	$user=new usersMenus();
	$main=new maincf_multi("master","master");
	$EnablePostScreen=$main->GET("EnablePostScreen");
	$postscreen_line=null;
	$tlsproxy=null;
	$dnsblog=null;
	$re_cleanup_infos=null;
	$smtp_submission=null;
	$pre_cleanup_addons=null;
	$master=new master_cf(1,"master");
	
	$ver210=false;
	$users=new usersMenus();
	echo "Starting......: Postfix master version: $users->POSTFIX_VERSION\n";
	if(preg_match("#^([0-9]+)\.([0-9]+)#", $users->POSTFIX_VERSION,$re)){
		$major=intval($re[1]);
		$minor=intval($re[2]);
		$binver=intval("{$major}{$minor}");
		if($binver >= 210){
			echo "Starting......: Postfix master version: 2.10 [$binver] OK\n";
			$ver210=true;}
	}	
	
	
	$MASTER_CF_DEFINED=$master->GetArray();
	
	if($EnablePostScreen==null){$EnablePostScreen=0;}	
	if(!$user->POSTSCREEN_INSTALLED){$EnablePostScreen=0;}
	
	if($EnablePostScreen==1){$PostfixEnableSubmission=1;}
	
	
	$ADD_PRECLEANUP=false;
	$TLSSET=false;
	
	if($GLOBALS["EnablePostfixMultiInstance"]==1){
		$EnableAmavisDaemon=0;
		$PostfixEnableMasterCfSSL=0;
	}
	
	if(!is_numeric($PostfixBindInterfacePort)){	$PostfixBindInterfacePort=25;}
	if(!is_numeric($EnableAmavisInMasterCF)){$EnableAmavisInMasterCF=0;}
	if(!is_numeric($PostfixEnableSubmission)){$PostfixEnableSubmission=0;}
	if(!is_numeric($EnableAmavisInMasterCF)){$EnableAmavisInMasterCF=0;}
	if(!is_numeric($ArticaFilterMaxProc)){$ArticaFilterMaxProc=20;}
	if(!is_numeric($EnableASSP)){$EnableASSP=0;}
	
	
	shell_exec("{$GLOBALS["postconf"]} -e \"artica-filter_destination_recipient_limit = 1\" >/dev/null 2>&1");
	if($EnableArticaSMTPFilter==0){shell_exec("{$GLOBALS["postconf"]} -e \"content_filter =\" >/dev/null 2>&1");}
		

	
	if($EnableAmavisInMasterCF==1){
		$MasterCFAmavisInstancesCount=$sock->GET_INFO("MasterCFAmavisInstancesCount");
		if(!is_numeric($MasterCFAmavisInstancesCount)){
				include_once(dirname(__FILE__).'/ressources/class.amavis.inc');
				$amavisClass=new amavis();
				$max_servers=$amavisClass->main_array["BEHAVIORS"]["max_servers"];
				$MasterCFAmavisInstancesCount=$max_servers-1;	
		}
		if($MasterCFAmavisInstancesCount==0){$MasterCFAmavisInstancesCount="-";}
		$ADD_PRECLEANUP=true;
		echo "Starting......: Amavis is enabled using post-queue mode\n";
		echo "Starting......: artica-filter enable=$EnableArticaSMTPFilter\n";
		shell_exec("{$GLOBALS["postconf"]} -e \"content_filter = amavis:[127.0.0.1]:10024\" >/dev/null 2>&1");
		if($EnableArticaSMTPFilter==1){
			$artica_filter_amavis_option=" -o content_filter=artica-filter:";
			$amavis_cleanup_infos  =" -o cleanup_service_name=pre-cleanup";
			echo "Starting......: Artica-filter max process: $ArticaFilterMaxProc\n";	
		}
		if($EnableArticaSMTPFilter==0){$artica_filter_amavis_option=" -o content_filter=";}
		
		echo "Starting......: Amavis max process: $MasterCFAmavisInstancesCount\n";	
		
		if(isset($MASTER_CF_DEFINED["amavis"])){unset($MASTER_CF_DEFINED["amavis"]);}
		
		$amavis[]="amavis\tunix\t-\t-\t-\t-\t$MasterCFAmavisInstancesCount\tsmtp";
		if($amavis_cleanup_infos<>null){$amavis[]=$amavis_cleanup_infos;}
		$amavis[]=" -o smtp_data_done_timeout=1200";
		$amavis[]=" -o smtp_send_xforward_command=yes";
		$amavis[]=" -o disable_dns_lookups=yes";
		$amavis[]=" -o smtp_generic_maps=";
		$amavis[]=" -o smtpd_sasl_auth_enable=no"; 
		$amavis[]=" -o smtpd_use_tls=no";
		$amavis[]=" -o max_use=20";				
		$amavis[]="";
		$amavis[]="";
		
		if(isset($MASTER_CF_DEFINED["127.0.0.1:10025"])){unset($MASTER_CF_DEFINED["127.0.0.1:10025"]);}
		$amavis[]="127.0.0.1:10025\tinet\tn\t-\tn\t-\t-\tsmtpd";
		if($amavis_cleanup_infos<>null){$amavis[]=$amavis_cleanup_infos;}
		if($artica_filter_amavis_option<>null){$amavis[]=$artica_filter_amavis_option;}
		$amavis[]=" -o local_recipient_maps=";
		$amavis[]=" -o relay_recipient_maps=";
		$amavis[]=" -o smtpd_restriction_classes=";
		$amavis[]=" -o smtpd_client_restrictions=";
		$amavis[]=" -o smtpd_helo_restrictions=";
		$amavis[]=" -o smtpd_sender_restrictions=";
		$artica[]=" -o smtpd_end_of_data_restrictions=";
		$amavis[]=" -o smtp_generic_maps=";
		$amavis[]=" -o smtpd_recipient_restrictions=permit_mynetworks,reject";
		$amavis[]=" -o mynetworks=127.0.0.0/8";
		$amavis[]=" -o mynetworks_style=host";
		$amavis[]=" -o strict_rfc821_envelopes=yes";
		$amavis[]=" -o smtpd_error_sleep_time=0";
		$amavis[]=" -o smtpd_soft_error_limit=1001";
		$amavis[]=" -o smtpd_hard_error_limit=1000";
		$amavis[]=" -o receive_override_options=no_header_body_checks";	
		$amavis[]="	-o smtpd_sasl_auth_enable=no"; 
		if($ver210){
		$amavis[]="	-o smtpd_upstream_proxy_protocol=";
		}
		$amavis[]="	-o smtpd_use_tls=no";
		$master_amavis=@implode("\n",$amavis);

	}ELSE{
		$master_amavis="";
		if($EnableArticaSMTPFilter==1){
			$ADD_PRECLEANUP=true;
			echo "Starting......: Enable Artica-filter globaly\n"; 
			echo "Starting......: Artica-filter max process: $ArticaFilterMaxProc\n";	
			shell_exec("{$GLOBALS["postconf"]} -e \"content_filter = artica-filter:\" >/dev/null 2>&1");
		}else{
			shell_exec("{$GLOBALS["postconf"]} -e \"content_filter =\" >/dev/null 2>&1");
		}
	}		
	
	if($ADD_PRECLEANUP){
		echo "Starting......: Enable pre-cleanup service...\n";
		$pre_cleanup_addons=" -o smtp_generic_maps= -o canonical_maps= -o sender_canonical_maps= -o recipient_canonical_maps= -o masquerade_domains= -o recipient_bcc_maps= -o sender_bcc_maps=";
		$re_cleanup_infos  =" -o cleanup_service_name=pre-cleanup";
	}	
	$permit_mynetworks=null;
	
	if($PostfixEnableMasterCfSSL==1){
		if($TrustMyNetwork==1){$permit_mynetworks="permit_mynetworks,";}
		echo "Starting......: Enabling SSL (465 port)\n";
		SetTLS();
		$TLSSET=true;
		if(isset($MASTER_CF_DEFINED["smtps"])){unset($MASTER_CF_DEFINED["smtps"]);}
		$SSL_INSTANCE[]="smtps\tinet\tn\t-\tn\t-\t-\tsmtpd";
		if($re_cleanup_infos<>null){$SSL_INSTANCE[]=$re_cleanup_infos;}
		$SSL_INSTANCE[]=" -o smtpd_tls_wrappermode=yes";
		$SSL_INSTANCE[]=" -o smtpd_delay_reject=yes";
		$SSL_INSTANCE[]=" -o smtpd_client_restrictions={$permit_mynetworks}permit_sasl_authenticated,reject\n";
		$SSL_INSTANCE[]=" -o smtpd_sender_restrictions=permit_sasl_authenticated,reject";
		$SSL_INSTANCE[]=" -o smtpd_helo_restrictions=permit_sasl_authenticated,reject";
		$SSL_INSTANCE[]=" -o smtpd_recipient_restrictions=permit_sasl_authenticated,reject";		
		$smtp_ssl=@implode("\n",$SSL_INSTANCE);
	}else{
		echo "Starting......: SSL (465 port) Disabled\n";
	}

	if($PostfixEnableSubmission==1){
		echo "Starting......: Enabling submission (587 port)\n";
		if(isset($MASTER_CF_DEFINED["submission"])){unset($MASTER_CF_DEFINED["submission"]);}
		if(!$TLSSET){SetTLS();}
		$TLSSET=true;
		$SUBMISSION_INSTANCE[]="submission\tinet\tn\t-\tn\t-\t-\tsmtpd";
		if($re_cleanup_infos<>null){$SUBMISSION_INSTANCE[]=$re_cleanup_infos;}
		$SUBMISSION_INSTANCE[]=" -o smtpd_etrn_restrictions=reject";
		$SUBMISSION_INSTANCE[]=" -o smtpd_enforce_tls=yes";
		$SUBMISSION_INSTANCE[]=" -o smtpd_sasl_auth_enable=yes";
		$SUBMISSION_INSTANCE[]=" -o smtpd_delay_reject=yes";
		$SUBMISSION_INSTANCE[]=" -o smtpd_client_restrictions=permit_sasl_authenticated,reject";
		$SUBMISSION_INSTANCE[]=" -o smtpd_sender_restrictions=permit_sasl_authenticated,reject";
		$SUBMISSION_INSTANCE[]=" -o smtpd_helo_restrictions=permit_sasl_authenticated,reject";
		$SUBMISSION_INSTANCE[]=" -o smtpd_recipient_restrictions=permit_sasl_authenticated,reject";
		$SUBMISSION_INSTANCE[]=" -o smtp_generic_maps=";
		$SUBMISSION_INSTANCE[]=" -o sender_canonical_maps=";
		$smtp_submission=@implode("\n",$SUBMISSION_INSTANCE);
		
	}else{
		echo "Starting......: submission (587 port) Disabled\n";
	}
	
	if($PostfixBindInterfacePort==25){
		$postfix_listen_port="smtp";
		$postscreen_listen_port="smtp";		
	}else{
		$postfix_listen_port=$PostfixBindInterfacePort;
		$postscreen_listen_port=$PostfixBindInterfacePort;		
	}
	
	
	echo "Starting......: Postfix intended to listen SMTP Port $postfix_listen_port\n";
	$smtp_in_proto="inet";
	$smtp_private="n";
	
	
	
	if($EnableASSP==1){
		echo "Starting......: ASSP is enabled change postfix listen port to 127.0.0.1:26\n";
		$postfix_listen_port="127.0.0.1:6000";
		$postscreen_listen_port="127.0.0.1:6000";
	}
	
	
	if($EnablePostScreen==1){
		if(isset($MASTER_CF_DEFINED["tlsproxy"])){unset($MASTER_CF_DEFINED["tlsproxy"]);}
		if(isset($MASTER_CF_DEFINED["dnsblog"])){unset($MASTER_CF_DEFINED["dnsblog"]);}
		echo "Starting......: PostScreen is enabled, users should use 587 port to send mails internally\n"; 
		$smtp_in_proto="pass";
		$smtp_private="-";
		if($postfix_listen_port=="smtp"){$postfix_listen_port="smtpd";}
		$postscreen_line="$postscreen_listen_port\tinet\tn\t-\tn\t-\t1\tpostscreen -o soft_bounce=yes";
		$tlsproxy="tlsproxy\tunix\t-\t-\tn\t-\t0\ttlsproxy";
		$dnsblog="dnsblog\tunix\t-\t-\tn\t-\t0\tdnsblog";
		}else{
			echo "Starting......: PostScreen is disabled\n";
		}
	
if($GLOBALS["VERBOSE"]){echo "Starting......: run MasterCF_DOMAINS_THROTTLE()\n";}	
$smtp_throttle=MasterCF_DOMAINS_THROTTLE();

// http://www.ijs.si/software/amavisd/README.postfix.html	
$conf[]="#";
$conf[]="# Postfix master process configuration file.  For details on the format";
$conf[]="# of the file, see the master(5) manual page (command: \"man 5 master\").";
$conf[]="#";
$conf[]="# ==========================================================================";
$conf[]="# service type  private unpriv  chroot  wakeup  maxproc command + args";
$conf[]="#               (yes)   (yes)   (yes)   (never) (100)";
$conf[]="# ==========================================================================";
if(isset($MASTER_CF_DEFINED[$postfix_listen_port])){unset($MASTER_CF_DEFINED[$postfix_listen_port]);}
if($postscreen_line<>null){$conf[]=$postscreen_line;}
if($tlsproxy<>null){$conf[]=$tlsproxy;}
if($dnsblog<>null){$conf[]=$dnsblog;}
$conf[]="$postfix_listen_port\t$smtp_in_proto\t$smtp_private\t-\tn\t-\t-\tsmtpd$re_cleanup_infos";
if($smtp_ssl<>null){$conf[]=$smtp_ssl;}
if($smtp_submission<>null){$conf[]=$smtp_submission;}
if($smtp_throttle<>null){$conf[]=$smtp_throttle;}
if(isset($MASTER_CF_DEFINED["pickup"])){unset($MASTER_CF_DEFINED["pickup"]);}
if(isset($MASTER_CF_DEFINED["cleanup"])){unset($MASTER_CF_DEFINED["cleanup"]);}
if(isset($MASTER_CF_DEFINED["mailman"])){unset($MASTER_CF_DEFINED["mailman"]);}
if(count($MASTER_CF_DEFINED)==0){
	$conf[]="pickup\tfifo\tn\t-\tn\t60\t1\tpickup$re_cleanup_infos";
	$conf[]="cleanup\tunix\tn\t-\tn\t-\t0\tcleanup";
	$conf[]="pre-cleanup\tunix\tn\t-\tn\t-\t0\tcleanup$pre_cleanup_addons";
	$conf[]="qmgr\tfifo\tn\t-\tn\t300\t1\tqmgr";
	$conf[]="tlsmgr\tunix\t-\t-\tn\t1000?\t1\ttlsmgr";
	$conf[]="rewrite\tunix\t-\t-\tn\t-\t-\ttrivial-rewrite";
	$conf[]="bounce\tunix\t-\t-\tn\t-\t0\tbounce";
	$conf[]="defer\tunix\t-\t-\tn\t-\t0\tbounce";
	$conf[]="trace\tunix\t-\t-\tn\t-\t0\tbounce";
	$conf[]="verify\tunix\t-\t-\tn\t-\t1\tverify";
	$conf[]="flush\tunix\tn\t-\tn\t1000?\t0\tflush";
	$conf[]="proxymap\tunix\t-\t-\tn\t-\t-\tproxymap";
	$conf[]="proxywrite\tunix\t-\t-\tn\t-\t1\tproxymap";
	$conf[]="smtp\tunix\t-\t-\tn\t-\t-\tsmtp";
	
	$conf[]="relay\tunix\t-\t-\tn\t-\t-\tsmtp -o fallback_relay=";
	$conf[]="showq\tunix\tn\t-\tn\t-\t-\tshowq";
	$conf[]="error\tunix\t-\t-\tn\t-\t-\terror";
	$conf[]="discard\tunix\t-\t-\tn\t-\t-\tdiscard";
	$conf[]="local\tunix\t-\tn\tn\t-\t-\tlocal";
	$conf[]="virtual\tunix\t-\tn\tn\t-\t-\tvirtual";
	$conf[]="lmtp\tunix\t-\t-\tn\t-\t-\tlmtp";
	$conf[]="anvil\tunix\t-\t-\tn\t-\t1\tanvil";
	$conf[]="scache\tunix\t-\t-\tn\t-\t1\tscache";
	$conf[]="scan\tunix\t-\t-\tn\t\t-\t10\tsm -v";
	$conf[]="maildrop\tunix\t-\tn\tn\t-\t-\tpipe ";
	$conf[]="retry\tunix\t-\t-\tn\t-\t-\terror ";
	$conf[]="uucp\tunix\t-\tn\tn\t-\t-\tpipe flags=Fqhu user=uucp argv=uux -r -n -z -a\$sender - \$nexthop!rmail (\$recipient)";
	$conf[]="ifmail\tunix\t-\tn\tn\t-\t-\tpipe flags=F user=ftn argv=/usr/lib/ifmail/ifmail -r \$nexthop (\$recipient)";
	$conf[]="bsmtp\tunix\t-\tn\tn\t-\t-\tpipe flags=Fq. user=bsmtp argv=/usr/lib/bsmtp/bsmtp -t\$nexthop -f\$sender \$recipient";
}

while (list ($service, $MFARRY) = each ($MASTER_CF_DEFINED) ){
	$conf[]="$service\t{$MFARRY["TYPE"]}\t{$MFARRY["PRIVATE"]}\t{$MFARRY["UNIPRIV"]}\t{$MFARRY["CHROOT"]}\t{$MFARRY["WAKEUP"]}\t{$MFARRY["MAXPROC"]}\t{$MFARRY["COMMAND"]}";
	echo "Starting......: master.cf adding $service ({$MFARRY["TYPE"]})\n";
	
}

$conf[]="mailman\tunix\t-\tn\tn\t-\t-\tpipe flags=FR user=mail:mail argv=/etc/mailman/postfix-to-mailman.py \${nexthop} \${mailbox}";
$conf[]="artica-whitelist\tunix\t-\tn\tn\t-\t-\tpipe flags=F  user=mail argv=/usr/share/artica-postfix/bin/artica-whitelist -a \${nexthop} -s \${sender} --white";
$conf[]="artica-blacklist\tunix\t-\tn\tn\t-\t-\tpipe flags=F  user=mail argv=/usr/share/artica-postfix/bin/artica-whitelist -a \${nexthop} -s \${sender} --black";
$conf[]="artica-reportwbl\tunix\t-\tn\tn\t-\t-\tpipe flags=F  user=mail argv=/usr/share/artica-postfix/bin/artica-whitelist -a \${nexthop} -s \${sender} --report";
$conf[]="artica-reportquar\tunix\t-\tn\tn\t-\t-\tpipe flags=F  user=mail argv=/usr/share/artica-postfix/bin/artica-whitelist -a \${nexthop} -s \${sender} --quarantines";
$conf[]="artica-spam\tunix\t-\tn\tn\t-\t-\tpipe flags=F  user=mail argv=/usr/share/artica-postfix/bin/artica-whitelist -a \${nexthop} -s \${sender} --spam";
$conf[]="zarafa\tunix\t-\tn\tn\t-\t-\tpipe	user=mail argv=/usr/bin/zarafa-dagent \${user}";
$conf[]="artica-filter\tunix\t-\tn\tn\t-\t$ArticaFilterMaxProc\tpipe flags=FOh  user=www-data argv=/usr/share/artica-postfix/exec.artica-filter.php -f \${sender} --  -s \${sender} -r \${recipient} -c \${client_address}";
$conf[]="";
$conf[]=$master_amavis;
$conf[]="";
$conf[]="127.0.0.1:33559\tinet\tn\t-\tn\t-\t-\tsmtpd";
$conf[]="    -o notify_clases=protocol,resource,software";
$conf[]="    -o header_checks=";
$conf[]="    -o content_filter=";
$conf[]="    -o smtpd_restriction_classes=";
$conf[]="    -o smtpd_delay_reject=no";
$conf[]="    -o smtpd_client_restrictions=permit_mynetworks,reject";
$conf[]="    -o smtpd_helo_restrictions=";
$conf[]="    -o smtpd_sender_restrictions=";
$conf[]="    -o smtpd_recipient_restrictions=permit_mynetworks,reject";
$conf[]="    -o smtpd_data_restrictions=reject_unauth_pipelining";
$conf[]="    -o smtpd_end_of_data_restrictions=";
$conf[]="    -o mynetworks=127.0.0.0/8";
$conf[]="    -o strict_rfc821_envelopes=yes";
$conf[]="    -o smtpd_error_sleep_time=0";
$conf[]="    -o smtpd_soft_error_limit=1001";
$conf[]="    -o smtpd_hard_error_limit=1000";
$conf[]="    -o smtpd_client_connection_count_limit=0";
$conf[]="    -o smtpd_client_connection_rate_limit=0";
$conf[]="    -o receive_override_options=no_header_body_checks,no_unknown_recipient_checks";
$conf[]="    -o smtp_send_xforward_command=yes";
$conf[]="    -o disable_dns_lookups=yes";
$conf[]="    -o local_header_rewrite_clients=";
$conf[]="    -o smtp_generic_maps=";
$conf[]="    -o sender_canonical_maps=";
$conf[]="    -o smtpd_milters=";
$conf[]="    -o smtpd_sasl_auth_enable=no";
$conf[]="    -o smtpd_use_tls=no";
if($ver210){
$conf[]="	 -o smtpd_upstream_proxy_protocol=";
}	
$conf[]="";	
$conf[]="";
@file_put_contents("/etc/postfix/master.cf",@implode("\n",$conf));
echo "Starting......: master.cf done\n";
if($GLOBALS["RELOAD"]){shell_exec("/usr/sbin/postfix reload >/dev/null 2>&1");}	

if($restart_service){
	shell_exec("{$GLOBALS["postfix"]} stop");
	shell_exec("{$GLOBALS["postfix"]} start");
}

}


function postfix_templates(){
	$mainTPL=new bounces_templates();
	$main=new maincf_multi("master");
	$mainTemplates=new bounces_templates();
	$conf=null;
	
	$double_bounce_sender=$main->GET("double_bounce_sender");
	$address_verify_sender=$main->GET("address_verify_sender");
	$twobounce_notice_recipient=$main->GET("2bounce_notice_recipient");
	$error_notice_recipient=$main->GET("error_notice_recipient");
	$delay_notice_recipient=$main->GET("delay_notice_recipient");
	$empty_address_recipient=$main->GET("empty_address_recipient");
	
	$sock=new sockets();
	$PostfixPostmaster=$sock->GET_INFO("PostfixPostmaster");
	if(trim($PostfixPostmaster)==null){$PostfixPostmaster="postmaster";}
	
	if($double_bounce_sender==null){$double_bounce_sender="double-bounce";};
	if($address_verify_sender==null){$address_verify_sender="\$double_bounce_sender";}
	if($twobounce_notice_recipient==null){$twobounce_notice_recipient="postmaster";}
	if($error_notice_recipient==null){$error_notice_recipient=$PostfixPostmaster;}
	if($delay_notice_recipient==null){$delay_notice_recipient=$PostfixPostmaster;}
	if($empty_address_recipient==null){$empty_address_recipient=$PostfixPostmaster;}	
	if(is_array($mainTemplates->templates_array)){
		while (list ($template, $nothing) = each ($mainTemplates->templates_array) ){
			$array=unserialize(base64_decode($main->GET_BIGDATA($template)));
			if(!is_array($array)){$array=$mainTemplates->templates_array[$template];}
				$tp=explode("\n",$array["Body"]);
				$Body=null;
				while (list ($a, $line) = each ($tp) ){if(trim($line)==null){continue;}$Body=$Body.$line."\n";}
				$conf=$conf ."\n$template = <<EOF\n";
				$conf=$conf ."Charset: {$array["Charset"]}\n";
				$conf=$conf ."From:  {$array["From"]}\n";
				$conf=$conf ."Subject: {$array["Subject"]}\n";
				$conf=$conf ."\n";
				$conf=$conf ."$Body";
				$conf=$conf ."\n\n";
				$conf=$conf ."EOF\n";
				
			}
	}


	@file_put_contents("/etc/postfix/bounce.template.cf",$conf);
	
	$notify_class=unserialize(base64_decode($main->GET_BIGDATA("notify_class")));
	if($notify_class["notify_class_software"]==1){$not[]="software";}
	if($notify_class["notify_class_resource"]==1){$not[]="resource";}
	if($notify_class["notify_class_policy"]==1){$not[]="policy";}
	if($notify_class["notify_class_delay"]==1){$not[]="delay";}
	if($notify_class["notify_class_2bounce"]==1){$not[]="2bounce";}
	if($notify_class["notify_class_bounce"]==1){$not[]="bounce";}
	if($notify_class["notify_class_protocol"]==1){$not[]="protocol";}
	
	
	postconf("notify_class",@implode(",",$not));
	postconf("double_bounce_sender","$double_bounce_sender");
	postconf("address_verify_sender","$address_verify_sender");	
	postconf("2bounce_notice_recipient",$twobounce_notice_recipient);	
	postconf("error_notice_recipient",$error_notice_recipient);	
	postconf("delay_notice_recipient",$delay_notice_recipient);
	postconf("empty_address_recipient",$empty_address_recipient);
	postconf("bounce_template_file","/etc/postfix/bounce.template.cf");				

	}


function memory(){
	$unix=new unix();
	$sock=new sockets();
	if($GLOBALS["VERBOSE"]){$cmd_verbose=" --verbose";}
	$PostFixEnableQueueInMemory=$sock->GET_INFO("PostFixEnableQueueInMemory");
	$PostFixQueueInMemory=$sock->GET_INFO("PostFixQueueInMemory");
	$directory="/var/spool/postfix";
	if($PostFixEnableQueueInMemory==1){
		echo "Starting......: Postfix Queue in memory is enabled for {$PostFixQueueInMemory}M\n";
		echo "Starting......: Postfix executing exec.postfix-multi.php\n";
		shell_exec(LOCATE_PHP5_BIN()." ".dirname(__FILE__)."/exec.postfix-multi.php --instance-memory master $PostFixQueueInMemory$cmd_verbose");
		return;
	}else{
		$MOUNTED_TMPFS_MEM=$unix->MOUNTED_TMPFS_MEM($directory);
		if($MOUNTED_TMPFS_MEM>0){
			shell_exec(LOCATE_PHP5_BIN()." ".dirname(__FILE__)."/exec.postfix-multi.php --instance-memory-kill master$cmd_verbose");
			return;
		}
		echo "Starting......: Postfix Queue in memory is not enabled\n"; 
	}	
	
}

function repair_locks(){
	$Myfile=basename(__FILE__);
	$timeFile="/etc/artica-postfix/pids/$Myfile.".__FUNCTION__.".time";
	$pidFile="/etc/artica-postfix/pids/$Myfile.".__FUNCTION__.".pid";
	$unix=new unix();
	$oldpid=$unix->get_pid_from_file($pidFile);
	
	if($unix->process_exists($oldpid,$Myfile)){writelogs("Die, already process $oldpid running ",__FUNCTION__,__FILE__,__LINE__);return;}
	
	$time=$unix->file_time_min($timeFile);
	if($time<5){writelogs("Die, No more than 5mn ",__FUNCTION__,__FILE__,__LINE__);return;}
	@unlink($timeFile);
	@mkdir(dirname($timeFile),0755,true);
	@file_put_contents($timeFile, time());
	@file_put_contents($pidFile, getmypid());
	
	echo "Starting......: Stopping postfix\n";
	shell_exec("{$GLOBALS["postfix"]} stop");
	$daemon_directory=$unix->POSTCONF_GET("daemon_directory");
	$queue_directory=$unix->POSTCONF_GET("queue_directory");
	echo "Starting......: Daemon directory: $daemon_directory\n";
	echo "Starting......: Queue directory.: $queue_directory\n";
	$pid=$unix->PIDOF("$daemon_directory/master",true);
	echo "Starting......: Process \"$daemon_directory/master\" PID:\"$pid\"\n";
	
	for($i=0;$i<10;$i++){
		if(is_numeric($pid)){
			if($pid>5){
				echo "Starting......: Killing bad pid $pid\n";
				$unix->KILL_PROCESS($pid,9);
				sleep(1);
				
			}
		}else{
			echo "Starting......: No $daemon_directory/master ghost process\n";
			break;
		}
		$pid=$unix->PIDOF("$daemon_directory/master");
		
		echo "Starting......: Process \"$daemon_directory/master\" PID:\"$pid\"\n";
	}
	
	if(file_exists("$daemon_directory/master.lock")){
		echo "Starting......: Delete $daemon_directory/master.lock\n";
		@unlink("$daemon_directory/master.lock");
	
	}
	if(file_exists("$queue_directory/pid/master.pid")){
		echo "Starting......: Delete $queue_directory/pid/master.pid\n";
		@unlink("$queue_directory/pid/master.pid");
	}
	
	if(file_exists("$queue_directory/pid/inet.127.0.0.1:33559")){
		echo "Starting......: $queue_directory/pid/inet.127.0.0.1:33559\n";
		@unlink("$queue_directory/pid/inet.127.0.0.1:33559");
	}
	
	
	echo "Starting......: Starting postfix\n";
	exec("{$GLOBALS["postfix"]} start -v 2>&1",$results);
	while (list ($template, $nothing) = each ($results) ){echo "Starting......: Starting postfix $nothing\n";}
}

function postconf($key,$value=null){
	if($GLOBALS["VERBOSE"]){echo "set key $key = $value\n";}
	shell_exec("{$GLOBALS["postconf"]} -e \"$key = $value\" >/dev/null 2>&1");
	
}

function postconf_strip_key(){
	$t=array();
	$f=file("/etc/postfix/main.cf");
	while (list ($index, $line) = each ($f) ){
		$line=str_replace("\r", "", $line);
		$line=str_replace("\n", "", $line);
		if(trim($line)==null){
			echo "Starting......: Starting postfix cleaning line $index (unused line)\n";
			continue;
		}
		
		if(preg_match("#alias_maps.*?=#", $line)){
			if(!preg_match("#virtual_alias_maps.*?=#", $line)){
			$line=str_replace("alias_maps", "\nalias_maps", $line);}
		}
		
		if(preg_match("#^(.*?)=(.*)#", $line,$re)){$value=trim($re[2]);if($value==null){
			echo "Starting......: Starting postfix cleaning {$re[1]} (unused value `$line`)\n";
			continue;}}
			
		$t[]=$line;
	}
	@file_put_contents("/etc/postfix/main.cf", @implode("\n", $t)."\n");
	
}

function smtpd_milters(){
	if($GLOBALS["EnablePostfixMultiInstance"]==1){
		echo "Starting......: Postfix EnablePostfixMultiInstance is enabled...\n";
		shell_exec(LOCATE_PHP5_BIN2()." ".dirname(__FILE__)."/exec.postfix-multi.php --from-main-reconfigure");return;}	
	
	$main=new main_cf();
	echo "Starting......: Postfix building milters...\n";
	$milter_array=$main->BuildMilters(true);
	while (list ($key, $value) = each ($milter_array) ){
		echo "Starting......: Postfix setting key `$key`...\n";
		postconf($key,$value);
	}
}

function wlscreen(){
	echo "wlscreen()\n";
	$f=new maincf_multi();
	$f->postfix_global_whitelist_to_mx();
	
	
}


?>