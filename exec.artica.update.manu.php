<?php
if(posix_getuid()<>0){die("Cannot be used in web server mode\n\n");}
include_once(dirname(__FILE__).'/ressources/class.templates.inc');
include_once(dirname(__FILE__).'/ressources/class.ldap.inc');
include_once(dirname(__FILE__).'/ressources/class.computers.inc');
include_once(dirname(__FILE__).'/ressources/class.system.network.inc');
include_once(dirname(__FILE__).'/ressources/class.ccurl.inc');
include_once(dirname(__FILE__)."/framework/class.unix.inc");
include_once(dirname(__FILE__)."/framework/frame.class.inc");

if(preg_match("#--verbose#",implode(" ",$argv))){$GLOBALS["VERBOSE"]=true;ini_set('display_errors', 1);ini_set('error_reporting', E_ALL);ini_set('error_prepend_string',null);ini_set('error_append_string',null);}
install($argv[1]);exit;



function install($filename){
	$GLOBALS["PROGRESS_FILE"]="/usr/share/artica-postfix/ressources/logs/artica.install.progress";
	$GLOBALS["LOG_FILE"]="/usr/share/artica-postfix/ressources/logs/web/artica.install.progress.txt";
	
	$unix=new unix();
	$LINUX_CODE_NAME=$unix->LINUX_CODE_NAME();
	$LINUX_DISTRIBUTION=$unix->LINUX_DISTRIBUTION();
	$LINUX_VERS=$unix->LINUX_VERS();
	$LINUX_ARCHITECTURE=$unix->LINUX_ARCHITECTURE();
	$APACHEUSER=$unix->APACHE_SRC_ACCOUNT();
	$DebianVer="debian{$LINUX_VERS[0]}";
	$TMP_DIR=$unix->TEMP_DIR();
	$ORGV=@file_get_contents("/usr/share/artica-postfix/VERSION");
	
	$tarballs_file="/usr/share/artica-postfix/ressources/conf/upload/$filename";
	echo "Package $tarballs_file\n";
	$size=filesize($tarballs_file);
	echo "Size....................: ".FormatBytes($size/1024)."\n";
	echo "Current version.........: $ORGV\n";
		
	build_progress("Analyze...",10);
		
	echo "Current system..........: $LINUX_CODE_NAME $LINUX_DISTRIBUTION {$LINUX_VERS[0]}/{$LINUX_VERS[1]} $LINUX_ARCHITECTURE\n";
	echo "Package.................: $filename\n";
	echo "Temp dir................: $TMP_DIR\n";
	echo "Apache User.............: $APACHEUSER\n";
	
	
	
	if(!is_file($tarballs_file)){
		echo "$tarballs_file no such file...\n";
		build_progress("No such file...",110);
		return;
	}
	echo "Uncompressing $tarballs_file...\n";
	build_progress("{extracting} $filename...",20);
	
	
	$chown=$unix->find_program("chown");
	$chmod=$unix->find_program("chmod");
	$tar=$unix->find_program("tar");
	$rm=$unix->find_program("rm");
	$nohup=$unix->find_program("nohup");
	$php=$unix->LOCATE_PHP5_BIN();
	$squid=$unix->LOCATE_SQUID_BIN();
	build_progress("{extracting} $filename...",50);
	
	system("$tar xf $tarballs_file -C /usr/share/");
	@unlink($tarballs_file);
	shell_exec("$rm -rf /usr/share/artica-postfix/ressources/conf/upload/*");
	build_progress("Apply permissions...",55);
	shell_exec("$chown -R $APACHEUSER /usr/share/artica-postfix");
	shell_exec("$chmod -R 0755 /usr/share/artica-postfix");
	$ORGD=@file_get_contents("/usr/share/artica-postfix/VERSION");
	echo "Old version.............: $ORGV\n";
	echo "Current version.........: $ORGD\n";
	sleep(2);
	if($ORGV==$ORGD){
		build_progress("{operation_failed} Same version $filename...",110);
		return;
	}
	
	build_progress("{restarting} Artica...",60);
	$unix->THREAD_COMMAND_SET("$php /usr/share/artica-postfix/exec.web-community-filter.php --register");
	build_progress("{restarting} Artica...",65);
	build_progress("building init scripts...",70);
	system("$php /usr/share/artica-postfix/exec.initslapd.php --force >/dev/null 2>&1");
	build_progress("updating network...",75);
	system("$php /usr/share/artica-postfix/exec.virtuals-ip.php >/dev/null 2>&1");
	system("$php /usr/share/artica-postfix/exec.monit.php --build >/dev/null 2>&1");
	echo "Starting......: ".date("H:i:s")." Purge and clean....\n";
	build_progress("{restarting} Artica...",80);
	if(is_file("/etc/init.d/nginx")){shell_exec("$nohup /etc/init.d/nginx reload >/dev/null 2>&1 &");}
	build_progress("{restarting} Artica...",81);
	shell_exec("$nohup /etc/init.d/auth-tail restart >/dev/null 2>&1 &");
	build_progress("{restarting} Artica...",82);
	shell_exec("$nohup /etc/init.d/artica-framework restart >/dev/null 2>&1 &");
	build_progress("{restarting} Artica...",83);
	shell_exec("$nohup /usr/share/artica-postfix/bin/process1 --force --verbose ".time()." >/dev/null 2>&1 &");
	build_progress("{restarting} Artica...",84);
	shell_exec("$nohup /usr/share/artica-postfix/bin/artica-make --empty-cache >/dev/null 2>&1 &");
	build_progress("{restarting} Artica...",85);
	shell_exec("$nohup /etc/init.d/monit restart >/dev/null 2>&1 &");
	build_progress("{restarting} Artica...",86);
	shell_exec("$nohup /etc/init.d/artica-status restart --force >/dev/null 2>&1 &");
	build_progress("{restarting} Artica...",87);
	shell_exec("$nohup $php /usr/share/artica-postfix/exec.squid.php --build-schedules >/dev/null 2>&1 &");
	build_progress("{restarting} Artica...",88);
	shell_exec("$nohup $php /usr/share/artica-postfix/exec.schedules.php --defaults >/dev/null 2>&1 &");
	build_progress("{restarting} Artica...",90);
	build_progress("{restarting} Artica...",100);
	echo "Starting......: ".date("H:i:s")." Done you can close the screen....\n";
		
	
	
	
}

function build_progress($text,$pourc){
	$array["POURC"]=$pourc;
	$array["TEXT"]=$text;
	@file_put_contents($GLOBALS["PROGRESS_FILE"], serialize($array));
	@chmod($GLOBALS["PROGRESS_FILE"],0755);

}
?>