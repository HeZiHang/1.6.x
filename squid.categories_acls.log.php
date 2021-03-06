<?php
include_once('ressources/class.templates.inc');
include_once('ressources/class.ldap.inc');
include_once('ressources/class.user.inc');
include_once('ressources/class.langages.inc');
include_once('ressources/class.sockets.inc');
include_once('ressources/class.mysql.inc');
include_once('ressources/class.privileges.inc');
include_once('ressources/class.ChecksPassword.inc');
include_once(dirname(__FILE__)."/ressources/class.logfile_daemon.inc");

session_start();
if($_SESSION["uid"]==null){ AskPasswordAuth("{realtime_requests}"); }


$users=new usersMenus();
if(!$users->AsWebStatisticsAdministrator){
	$tpl=new templates();
	echo "<script> alert('". $tpl->javascript_parse_text("`{$_SERVER['PHP_AUTH_USER']}/{$_SERVER['PHP_AUTH_PW']}` {ERROR_NO_PRIVS}")."'); </script>";
	die();
}
//ini_set('display_errors', 1);ini_set('error_reporting', E_ALL);ini_set('error_prepend_string',null);ini_set('error_append_string',null);

if(isset($_GET["js"])){js();exit;}
if(isset($_GET["popup"])){popup();exit;}
if(isset($_GET["events-list"])){events_list();exit;}

popup();


function js(){
	header("content-type: application/x-javascript");
	$tpl=new templates();
	$page=CurrentPageName();
	if(isset($_GET["wpad"])){$wpad="&wpad=yes";}
	$title=$tpl->_ENGINE_parse_body("{realtime_requests}::{$_GET["SearchString"]}");
	$html="YahooWin('1200','$page?popup=yes&SearchString={$_GET["SearchString"]}&minsize=1','$title')";
	echo $html;
	
	
}

function page(){
	$tpl=new templates();
	$page=CurrentPageName();
	$sock=new sockets();
	$hostname=trim($sock->GET_INFO("myhostname"));
	$events=$tpl->_ENGINE_parse_body("{realtime_requests}");
	$please_wait=$tpl->_ENGINE_parse_body("{please_wait}");
echo "<!DOCTYPE html>
<html lang=\"en\">
<head>
	<meta http-equiv=\"X-UA-Compatible\" content=\"IE=9; IE=8\">
	<meta content=\"text/html; charset=utf-8\" http-equiv=\"Content-type\" />
	<link rel=\"stylesheet\" type=\"text/css\" href=\"/css/artica-theme/jquery-ui.custom.css\" />
	<link rel=\"stylesheet\" type=\"text/css\" href=\"/css/jquery.jgrowl.css\" />
	<link rel=\"stylesheet\" type=\"text/css\" href=\"/css/jquery.cluetip.css\" />
	<link rel=\"stylesheet\" type=\"text/css\" href=\"/css/jquery.treeview.css\" />
	<link rel=\"stylesheet\" type=\"text/css\" href=\"/css/flexigrid.pack.css\" />
	<link rel=\"stylesheet\" type=\"text/css\" href=\"/fonts.css.php\" />
	
	<title>$hostname $events</title>
	<link rel=\"icon\" href=\"/ressources/templates/Squid/favicon.ico\" type=\"image/x-icon\" />
	<link rel=\"shortcut icon\" href=\"/ressources/templates/Squid/favicon.ico\" type=\"image/x-icon\" />
	<script type=\"text/javascript\" language=\"javascript\" src=\"/mouse.js\"></script>
	<script type=\"text/javascript\" language=\"javascript\" src=\"/XHRConnection.js\"></script>
	<script type=\"text/javascript\" language=\"javascript\" src=\"/js/cookies.js\"></script>
	<script type=\"text/javascript\" language=\"javascript\" src=\"/default.js\"></script>
	<script type=\"text/javascript\" language=\"javascript\" src=\"/js/jquery-1.8.3.js\"></script>
	<script type=\"text/javascript\" language=\"javascript\" src=\"/js/jquery-ui-1.8.22.custom.min.js\"></script>
	<script type=\"text/javascript\" language=\"javascript\" src=\"/js/jqueryFileTree.js\"></script>
	<script type=\"text/javascript\" language=\"javascript\" src=\"/js/jquery.simplemodal-1.3.3.min.js\"></script>
	<script type=\"text/javascript\" language=\"javascript\" src=\"/js/jquery.tools.min.js\"></script>
	<script type=\"text/javascript\" language=\"javascript\" src=\"/js/flexigrid.pack.js\"></script>
	<script type=\"text/javascript\" language=\"javascript\" src=\"/js/ui.selectmenu.js\"></script>
	<script type=\"text/javascript\" language=\"javascript\" src=\"/js/jquery.cookie.js\"></script>
	<script type=\"text/javascript\" language=\"javascript\" src=\"/js/jquery.blockUI.js\"></script>
</head>

<body style='background-color:white;margin:0px;padding:0px'>
<div id='mainaccess'>
	<center style='font-size:50px'>$please_wait</center>
	</div>
<script>
	LoadAjax('mainaccess','$page?popup=yes',true);
</script>
</body>
</html>";

}


function popup(){
	
	$page=CurrentPageName();
	$tpl=new templates();
	$t=time();
	$events=$tpl->_ENGINE_parse_body("{events}");
	$zdate=$tpl->_ENGINE_parse_body("{zDate}");
	$proto=$tpl->_ENGINE_parse_body("{proto}");
	$uri=$tpl->_ENGINE_parse_body("{url}");
	$member=$tpl->_ENGINE_parse_body("{member}");
	if(function_exists("date_default_timezone_get")){$timezone=" - ".date_default_timezone_get();}
	$title=$tpl->_ENGINE_parse_body("{realtime_requests}: {artica_categories}");
	$zoom=$tpl->_ENGINE_parse_body("{zoom}");
	$button1="{name: 'Zoom', bclass: 'Search', onpress : ZoomSquidAccessLogs},";
	$stopRefresh=$tpl->javascript_parse_text("{stop_refresh}");
	$logs_container=$tpl->javascript_parse_text("{logs_container}");
	$refresh=$tpl->javascript_parse_text("{refresh}");
	
	$items=$tpl->_ENGINE_parse_body("{items}");
	$size=$tpl->_ENGINE_parse_body("{size}");
	$SaveToDisk=$tpl->_ENGINE_parse_body("{SaveToDisk}");
	$addCat=$tpl->_ENGINE_parse_body("{add} {category}");
	$date=$tpl->_ENGINE_parse_body("{zDate}");
	$task=$tpl->_ENGINE_parse_body("{task}");
	$new_schedule=$tpl->_ENGINE_parse_body("{new_rotate}");
	$explain=$tpl->_ENGINE_parse_body("{explain_squid_tasks}");
	$domain=$tpl->_ENGINE_parse_body("{domain}");
	$task=$tpl->_ENGINE_parse_body("{task}");
	$size=$tpl->_ENGINE_parse_body("{size}");
	$filename=$tpl->_ENGINE_parse_body("{filename}");
	$empty=$tpl->_ENGINE_parse_body("{empty}");
	$askdelete=$tpl->javascript_parse_text("{empty_store} ?");
	$duration=$tpl->_ENGINE_parse_body("{duration}");
	$ext=$tpl->_ENGINE_parse_body("{extension}");
	$back_to_events=$tpl->_ENGINE_parse_body("{back_to_events}");
	$Compressedsize=$tpl->_ENGINE_parse_body("{compressed_size}");
	$realsize=$tpl->_ENGINE_parse_body("{realsize}");
	$action=$tpl->javascript_parse_text("{action}");
	$object=$tpl->javascript_parse_text("{object}");
	$MAC=$tpl->_ENGINE_parse_body("{MAC}");
	$ipaddr=$tpl->_ENGINE_parse_body("{ipaddr}");
	$reload_proxy_service=$tpl->_ENGINE_parse_body("{reload_proxy_service}");
	$server=$tpl->javascript_parse_text("{server}");
	$table_size=855;
	$url_row=505;
	$member_row=276;
	$table_height=420;
	$distance_width=230;
	$tableprc="100%";
	$margin="-10";
	$margin_left="-15";
	$ip_field=161;
	$date_field=150;

	$cod_field=233;
	$size_field=258;
	$duration_field=106;
	$table_size=1019;
	$uri_field=345;
	$ip_field=438;
	$cod_field=203;
	$member_row=333;
	$distance_width=352;
	$proto_field=232;
	$server_field=175;
	$margin=0;
	$margin_left="-5";
	$tableprc="99%";
	$button1="{name: '<strong id=refresh-$t>$stopRefresh</stong>', bclass: 'Reload', onpress : StartStopRefresh$t},";
	$table_height=590;
	$Start="StartRefresh$t()";
	$all=$tpl->javascript_parse_text("{all}");
	
	
	//$buttons[]="{name: '<strong>$autorefresh OFF</stong>', bclass: 'Reload', onpress : AutoRefresh$t},";
	
	
	$html="
	<div id='SQUID_ACCESS_LOGS_DIV'>		
	<table class='SQUID_SQUIDTAIL_ARTCAT_RT' style='display: none' id='SQUID_SQUIDTAIL_ARTCAT_RT' style='width:99%'></table>
	<input type='hidden' id='refreshenabled$t' value='0'>
	<input type='hidden' id='refresh$t' value='0'>
	</div>
	<script>
	var mem$t='';
	function StartLogsSquidTable$t(){
		$('#SQUID_SQUIDTAIL_ARTCAT_RT').flexigrid({
			url: '$page?events-list=yes&minsize={$_GET["minsize"]}&SearchString={$_GET["SearchString"]}',
			dataType: 'json',
			colModel : [
			
			{display: '<span style=font-size:18px>$zdate</span>', name : 'zDate', width :$date_field, sortable : true, align: 'left'},
			{display: '<span style=font-size:18px>$object</span>', name : 'zDate', width :$server_field, sortable : true, align: 'left'},
			{display: '<span style=font-size:18px>$member</span>', name : 'events', width : $ip_field, sortable : false, align: 'left'},
			{display: '<span style=font-size:18px>$domain</span>', name : 'events', width : $uri_field, sortable : false, align: 'left'},
			{display: '<span style=font-size:18px>$action</span>', name : 'size', width : $size_field, sortable : false, align: 'left'},
			
			],
				
			buttons : [
				
			],
				
	
			searchitems : [
			{display: '$all', name : 'sitename'},
			
			],
			sortname: 'zDate',
			sortorder: 'desc',
			usepager: true,
			title: '<span style=\"font-size:22px\">$title {$_GET["SearchString"]}</span>',
			useRp: true,
			rp: 50,
			showTableToggleBtn: false,
			width: '98.5%',
			height: 500,
			singleSelect: true,
			rpOptions: [10, 20, 30, 50,100,200,500]
	
		});
		
	if(document.getElementById('SQUID_INFLUDB_TABLE_DIV')){
		document.getElementById('SQUID_INFLUDB_TABLE_DIV').innerHTML='';
	}		
	
	}
	
function AutoRefreshAction$t(){
	if(!document.getElementById('refreshenabled$t')){return;}
	var enabled$t=parseInt(document.getElementById('refreshenabled$t').value);
	if(enabled$t==0){
		setTimeout('AutoRefreshAction$t()',1000);
		return;
	}
	var Count=parseInt(document.getElementById('refresh$t').value);
	
	if(Count<5){
		Count=Count+1;
		document.getElementById('refresh$t').value=Count;
		setTimeout('AutoRefreshAction$t()',1000);
		return;
	}
	document.getElementById('refresh$t').value=0;
	$('#SQUID_SQUIDTAIL_ARTCAT_RT').flexReload();
	setTimeout('AutoRefreshAction$t()',1000);
	
}
	
function AutoRefresh$t(){
	var enabled=parseInt(document.getElementById('refreshenabled$t').value);
	if( enabled ==0){
		document.getElementById('refreshenabled$t').value=1;
		document.getElementById('SQUIDLOGS_REFRESH_LABEL').innerHTML='$autorefresh ON';
		}
	if( enabled ==1){
		document.getElementById('refreshenabled$t').value=0;
		document.getElementById('SQUIDLOGS_REFRESH_LABEL').innerHTML='$autorefresh OFF';
	}
}

StartLogsSquidTable$t();
setTimeout('AutoRefreshAction$t()',1000);
</script>";
echo $html;
}

function events_list(){
	$sock=new sockets();
	if(!isset($_POST["rp"])){$_POST["rp"]=50;}
	$q=new mysql_squid_builder();
	$sock->getFrameWork("squid.php?category_tail=yes&rp={$_POST["rp"]}&query=".urlencode($_POST["query"])."&SearchString={$_GET["SearchString"]}");
	$filename="/usr/share/artica-postfix/ressources/logs/categoriestail.log.tmp";
	$dataZ=explode("\n",@file_get_contents($filename));
	$tpl=new templates();
	$data = array();
	$data['page'] = 1;
	$data['total'] = count($data);
	$data['rows'] = array();
	$today=date("Y-m-d");
	$tcp=new IP();
	
	
	$cachedT=$tpl->_ENGINE_parse_body("{cached}");
	$c=0;
	$fontsize=14;
	if(count($dataZ)==0){json_error_show("no data");}
	$logfileD=new logfile_daemon();
	krsort($dataZ);
	$c=0;
	while (list ($num, $line) = each ($dataZ)){
		$xusers=array();
		$line=trim($line);
		if($line==null){continue;}
		$c++;
		$re=explode(";", $line);
		
		//1442651393;Group69;administrateur;192.168.1.9;00:26:b9:78:8f:0a;au.v4.download.windowsupdate.com;69;QUERY;PASS
		
		$color="black";
		$mac=trim(strtolower($re[4]));
		if($mac=="-"){$mac==null;}
		$mac=str_replace("-", ":", $mac);
		if($mac=="00:00:00:00:00:00"){$mac=null;}
		$ipaddr=trim($re[1]);
		if(!isset($GLOBALS["USER_MEM"])){$GLOBALS["USER_MEM"]=0;}
		$uid=$re[2];
		
		if($uid=="-"){$uid=null;}
		
		$xtime=$re[0];
		$GroupName=$re[1];
		$logzdate=date("Y-m-d H:i:s",$xtime);
		$ipaddr=$re[3];
		$sitename=$re[5];
		$gpid=$re[6];
		$MEM=$re[7];
		$results=$re[8];
		
		$uid=trim(strtolower(str_replace("%20", " ", $uid)));
		$uid=str_replace("%25", "-", $uid);
		if($uid=="-"){$uid=null;}
		
		
		if(strpos($uid, '$')>0){
			if(substr($uid, strlen($uid)-1,1)=="$"){
				$uid=null;
			}
		}
		
		if(strpos($sitename, ":")>0){
			$XA=explode(":",$sitename);
			$sitename=$XA[0];
		}

		
		$ipaddr=str_replace("%25", "-", $ipaddr);
		$mac=str_replace("%25", "-", $mac);
		if($mac=="-"){$mac=null;}
		if($mac=="00:00:00:00:00:00"){$mac=null;}
		$ligne2=mysql_fetch_array($q->QUERY_SQL("SELECT GroupName FROM webfilters_sqgroups WHERE ID='$gpid'"));
		$GroupName=$ligne2["GroupName"];
		if(preg_match("#([0-9:a-z]+)$#", $mac,$z)){$mac=$z[1];}
		
		$xusers[]=$ipaddr;
		if($mac<>null){$xusers[]="$mac";}
		if($uid<>null){$xusers[]="$uid";}
		
		$date=str_replace($today." ", "", $date);
		$data['rows'][] = array(
				'id' => md5($line),
				'cell' => array(
						"<span style='font-size:{$fontsize}px;color:$color'>$logzdate</span>",
						"<span style='font-size:{$fontsize}px;color:$color'>$GroupName</span>",
						"<span style='font-size:{$fontsize}px;color:$color'>". @implode("&nbsp;|&nbsp;", $xusers)."</span>",
						"<span style='font-size:{$fontsize}px;color:$color'>{$sitename}</span>",
						"<span style='font-size:{$fontsize}px;color:$color'>$MEM/$results</span>",
						
						
				)
		);
		
	}
	
	
	$data['total'] = $c;
	echo json_encode($data);
	
}
