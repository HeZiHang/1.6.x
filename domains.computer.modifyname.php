<?php
$GLOBALS["VERBOSE"]=false;
if(isset($_GET["verbose"])){$GLOBALS["VERBOSE"]=true;ini_set('display_errors', 1);ini_set('error_reporting', E_ALL);}
session_start ();
include_once ('ressources/class.templates.inc');
include_once ('ressources/class.ldap.inc');
include_once ('ressources/class.users.menus.inc');
include_once ('ressources/class.artica.inc');
include_once ('ressources/class.user.inc');
include_once ('ressources/class.computers.inc');
include_once ('ressources/class.ini.inc');
include_once ('ressources/class.ocs.inc');


$usersprivs = new usersMenus ( );
$change_aliases = GetRights_aliases();

if ($change_aliases == 0) {
	$tpl=new templates();
	echo "alert('".$tpl->javascript_parse_text( "{ERROR_NO_PRIVILEGES_OR_PLUGIN_DISABLED}" )."');";
	return;
}
if(isset($_POST["NewHostname"])){changecomputername();exit;}
if(isset($_GET["show-config"])){showConfig();exit;}


function showConfig(){
	echo MEMBER_JS($_GET["userid"],1,1);
	
}

js();

function js(){
	
	$comp=new computers($_GET["userid"]);
	$page=CurrentPageName();
	$tpl=new templates();
	$text=$tpl->javascript_parse_text("$comp->uid:{change_computer_text}");
	$t=time();
	$html="
	var x_$t='';
	
var x_ChangeComputerName= function (obj) {
	var results=obj.responseText;
	if(results.length>0){alert(results);return;}
	if(document.getElementById('computerlist')){BrowsComputersRefresh();}
	if(document.getElementById('main_config_browse_computers')){RefreshTab('main_config_browse_computers');}
	if(document.getElementById('container-computer-tabs')){RefreshTab('container-computer-tabs');}
	if(document.getElementById('main_dansguardiangroups_tabs')){RefreshTab('main_dansguardiangroups_tabs');}
	RTMMailHide();
	YahooUserHide();
	YahooUser(1051,'domains.edit.user.php?userid='+x_$t+'&ajaxmode=yes',x_$t);	
	
	}		
	
	
	
	function ChangeComputerName(){
		var newhostname=prompt('$text');	
		if(!newhostname){return;}
		var XHR = new XHRConnection();
		x_$t=newhostname+'$';
		XHR.appendData('NewHostname',newhostname);
		XHR.appendData('userid','{$_GET["userid"]}');
		XHR.sendAndLoad('$page', 'POST',x_ChangeComputerName);	
		
	}	
	
	ChangeComputerName();
	";
	
	echo $html;
}


function changecomputername(){
	if(substr($_POST["userid"], strlen($_POST["userid"])-1,1)<>"$"){$_POST["userid"]=$_POST["userid"]."$";}
	$comp=new computers($_POST["userid"]);
	$MAC=$comp->ComputerMacAddress;
	$_POST["NewHostname"]=trim(strtolower($_POST["NewHostname"]));
	$_POST["NewHostname"]=str_replace('$', '', $_POST["NewHostname"]);
	$actualdn=$comp->dn;
	$newrdn="cn={$_POST["NewHostname"]}$";
	$ldap=new clladp();
	if(!preg_match("#^cn=(.+?),[a-zA-Z\s]+#" ,$actualdn,$re)){echo "Unable to preg_match $actualdn\n";return;}
	
	$newDN=str_replace($re[1], $_POST["NewHostname"].'$', $actualdn);

	
	if($newDN==null){
		echo "Unable to preg_match $actualdn -> {$re[1]}\n";return;
	}
	
	if($ldap->ExistsDN("$newrdn,ou=Computer,dc=samba,dc=organizations,$ldap->suffix")){$ldap->ldap_delete("$newrdn,ou=Computer,dc=samba,dc=organizations,$ldap->suffix");}
	$newParent="ou=Computer,dc=samba,dc=organizations,$ldap->suffix";
	if(!$ldap->Ldap_rename_dn($newrdn,$actualdn,$newParent)){
		echo "Rename failed $ldap->ldap_last_error\nFunction:".__FUNCTION__."\nFile:".__FILE__."\nLine".__LINE__."\n\nActual DN:$actualdn\nExpected DN:$newrdn";
		return;
	}	
	
	
	$upd["uid"][0]=$_POST["NewHostname"].'$';
	if(!$ldap->Ldap_modify($newDN, $upd)){
		echo "Update UID {$upd["uid"][0]} failed:\n$ldap->ldap_last_error\nFunction:".__FUNCTION__."\nFile:".__FILE__."\nLine".__LINE__."\nExpected DN:$newDN\nExpected value:{$_POST["NewHostname"]}";
		return;
	}
	
	$ocs=new ocs($MAC);
	$ocs->ComputerName=$_POST["NewHostname"];
	$ocs->ComputerIP=$comp->ComputerIP;
	$ocs->EditComputer();
	
	
	if(IsPhysicalAddress($comp->ComputerMacAddress)){
		include_once(dirname(__FILE__)."/ressources/class.mysql.inc");
		$uid=$comp->ComputerIDFromMAC($comp->ComputerMacAddress);
		$comp=new computers($uid);
		$sql="UPDATE dhcpd_fixed SET `hostname`='$comp->ComputerRealName' WHERE `mac`='$comp->ComputerMacAddress'";
		$q=new mysql();
		$q->QUERY_SQL($sql,"artica_backup");
	}
	
	
	
	
	
	
}
