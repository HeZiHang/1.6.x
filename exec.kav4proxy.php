<?php
if(posix_getuid()<>0){die("Cannot be used in web server mode\n\n");}
$GLOBALS["AS_ROOT"]=true;
include_once(dirname(__FILE__).'/ressources/class.templates.inc');
include_once(dirname(__FILE__).'/ressources/class.ldap.inc');
include_once(dirname(__FILE__).'/ressources/class.mysql.inc');
include_once(dirname(__FILE__).'/ressources/class.ini.inc');
include_once(dirname(__FILE__).'/ressources/class.kav4proxy.inc');
include_once(dirname(__FILE__).'/framework/class.unix.inc');

if($argv[1]=="--reload"){BuilAndReload();die();}
if($argv[1]=="--umount"){umountfs();die();}

build();
function build(){
	$kav=new Kav4Proxy();
	$conf=$kav->build_config();
	echo "Starting......: Kav4proxy building configuration done\n";
	@file_put_contents("/etc/opt/kaspersky/kav4proxy.conf",$conf);
	shell_exec("/bin/chown -R kluser /etc/opt/kaspersky");
	shell_exec("/bin/chown -R kluser /var/log/kaspersky/kav4proxy");
	@mkdir("/tmp/Kav4proxy",0777);
	@chmod("/tmp/Kav4proxy", 0777);
	@chown("/tmp/Kav4Proxy", "kluser");
	@chgrp("/tmp/Kav4Proxy", "kluser");
	}
	
	
function BuilAndReload(){
	build();
	shell_exec("/etc/init.d/kav4proxy reload");
	
}

function umountfs(){
	$unix=new unix();
	$mount=$unix->find_program("mount");
	$umount=$unix->find_program("umount");	
	$kav=new Kav4Proxy();
	if($kav->is_tmpfs_mounted()){
		echo "Starting......: Kav4proxy unmounting filesystem\n";
		shell_exec("$umount -f /tmp/Kav4proxy");
		shell_exec("/bin/rm -rf /tmp/Kav4proxy");
	}
}

?>