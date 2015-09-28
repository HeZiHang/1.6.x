<?php
session_start ();
include_once ('ressources/class.templates.inc');
include_once ('ressources/class.ldap.inc');
include_once ('ressources/class.users.menus.inc');
if(isset($_GET["verbose"])){$GLOBALS["VERBOSE"]=true;ini_set('display_errors', 1);ini_set('error_reporting', E_ALL);ini_set('error_prepend_string',null);ini_set('error_append_string',null);}


	$user=new usersMenus();
	if(!$user->AsWebStatisticsAdministrator){
		$tpl=new templates();
		echo FATAL_ERROR_SHOW_128("{ERROR_NO_PRIVS}");
		die();exit();
	}
	
	if(isset($_GET["popup"])){popup();exit;}
	if(isset($_GET["search"])){search();exit;}
	if(isset($_GET["sjs"])){js_popup();exit;}
popup();






function popup(){
	
	$page=CurrentPageName();
	$tpl=new templates();
	$date=$tpl->_ENGINE_parse_body("{zDate}");
	$description=$tpl->_ENGINE_parse_body("{description}");
	$context=$tpl->_ENGINE_parse_body("{context}");	
	$events=$tpl->_ENGINE_parse_body("{events}");	
	$empty=$tpl->_ENGINE_parse_body("{empty}");	
	$empty_events_text_ask=$tpl->javascript_parse_text("{empty_events_text_ask}");	
	$service=$tpl->_ENGINE_parse_body("{servicew}");
	$TB_WIDTH=872;
	$TB2_WIDTH=610;
	$TB_HEIGHT=600;
	$TB_EV=574;
	if(is_numeric($_GET["TB_WIDTH"])){$TB_WIDTH=$_GET["TB_WIDTH"];}
	if(is_numeric($_GET["TB_HEIGHT"])){$TB_HEIGHT=$_GET["TB_HEIGHT"];}
	if(is_numeric($_GET["TB_EV"])){$TB_EV=$_GET["TB_EV"];}
	$t=time();
	$SE_SERV="{display: '$service', name : 'service'},";
	
	if($_GET["force-prefix"]<>null){$MasterTitle=$_GET["force-prefix"];$TB_SERV=null;$SE_SERV=null;}
	if($_GET["prepend"]<>null){$MasterTitle=$MasterTitle."&raquo;{$_GET["prepend"]}";}
	$syslogpath=urlencode($_GET["syslog-path"]);
	if($MasterTitle==null){$MasterTitle=$tpl->javascript_parse_text("{events}");}
	
	$buttons="
	buttons : [
	{name: '$empty', bclass: 'Delz', onpress : EmptyEvents},
	
		],	";
	
	$buttons=null;
	
	$html="
	<table class='events-table-$t' style='display: none' id='events-table-$t' style='width:99%'></table>
<script>

$(document).ready(function(){
$('#events-table-$t').flexigrid({
	url: '$page?search=yes&prepend={$_GET["prepend"]}&force-prefix={$_GET["force-prefix"]}&syslog-path=$syslogpath',
	dataType: 'json',
	colModel : [
		{display: '$date', name : 'zDate', width :122, sortable : true, align: 'left'},
		{display: '$service', name : 'zDate', width :163, sortable : false, align: 'left'},
		{display: 'function', name : 'function', width :96, sortable : false, align: 'left'},
		{display: 'line', name : 'line', width :47, sortable : false, align: 'left'},
		{display: '$events', name : 'events', width : 947, sortable : false, align: 'left'},
	],
	$buttons

	searchitems : [
		{display: '$events', name : 'events'},
		$SE_SERV
		],
	sortname: 'zDate',
	sortorder: 'desc',
	usepager: true,
	title: '<strong style=font-size:16px>$MasterTitle</strong>',
	useRp: true,
	rp: 50,
	showTableToggleBtn: false,
	width: '99%',
	height:$TB_HEIGHT ,
	singleSelect: true,
	rpOptions: [10, 20, 30, 50,100,200,500]
	
	});   
});
	
</script>";
	
	echo $html;
	return ;

}

function search(){
	$tpl=new templates();
	$MyPage=CurrentPageName();
	
	
	
	
	$table="events";
	$page=1;
	$ORDER="ORDER BY zDate DESC";
	
	$total=0;
	
	
$pattern=base64_encode($_GET["search"]);
	$sock=new sockets();
	$removeService=false;
	
	if (isset($_POST['rp'])) {$rp = $_POST['rp'];}	
	if(isset($_POST["sortname"])){if($_POST["sortname"]<>null){$ORDER="ORDER BY {$_POST["sortname"]} {$_POST["sortorder"]}";}}	
	if(isset($_POST['page'])) {$page = $_POST['page'];}
	
	if($_POST["qtype"]=="service"){
		if($_POST["query"]<>null){
			$_GET["prefix"]=$_POST["query"];
			$_POST["query"]=null;
		}
	}
	
	if($_POST["qtype"]=="service"){
		if($_POST["query"]<>null){
			$_GET["prefix"]=$_POST["query"];
			$_POST["query"]=null;
		}
	}

	if($_GET["force-prefix"]<>null){
		if($_POST["qtype"]=="service"){$_POST["query"]=null;}
		$_GET["prefix"]=$_GET["force-prefix"];
		$removeService=true;
	}
	
	$syslogpath=urlencode("/var/log/artica-parse.hourly.log");

	if($_GET["query"]<>null){

		$search=base64_encode($_POST["query"]);
		$sock->getFrameWork("cmd.php?syslog-query=$search&prepend={$_GET["prepend"]}&rp={$_POST["rp"]}&prefix={$_GET["prefix"]}&syslog-path=$syslogpath");	
		$array=explode("\n", @file_get_contents("/usr/share/artica-postfix/ressources/logs/web/syslog.query"));
		$total = count($array);
		
	}else{
		$sock->getFrameWork("cmd.php?syslog-query=&prepend={$_GET["prepend"]}&rp={$_POST["rp"]}&prefix={$_GET["prefix"]}&syslog-path=$syslogpath");
		$array=explode("\n", @file_get_contents("/usr/share/artica-postfix/ressources/logs/web/syslog.query"));
		$total = count($array);
	}
	
	
	
	$data = array();
	$data['page'] = $page;
	$data['total'] = $total;
	$data['rows'] = array();
	
	if($_POST["sortname"]<>null){
		if($_POST["sortorder"]=="desc"){krsort($array);}else{ksort($array);}
	}
	$today=$tpl->_ENGINE_parse_body("{today}");
	$c=0;
	
	
	if($GLOBALS["VERBOSE"]){echo "<H1>Array of ".count($array)." Lines</H1>\n";}
	
	
	while (list ($key, $line) = each ($array) ){
		if(trim($line)==null){continue;}
			$date=null;
			$host=null;
			$service=null;
			$host="-";
			$color="black";
			if(preg_match("#(ERROR|WARN|FATAL|UNABLE|Failed|not found|denied|OVERLOAD)#i", $line)){$color="#D61010";}
				
			$style="<span style='color:$color'>";
			$styleoff="</span>";
			
		if(preg_match("#^(.+?)\s+\[(.+?)\/(.+?)\/([0-9]+)\]:(.*)#",$line,$re)){
			$date=$re[1];
			$service=$re[2];
			$function=$re[3];
			$linenum=$re[4];
			$line=$tpl->javascript_parse_text($re[5]);
			$strtotime=strtotime($date);
			if(date("Y-m-d",$strtotime)==date("Y-m-d")){
				$date=$today." ".date('H:i:s',strtotime($date));
			}else{
				$date=date('m-d H:i:s',strtotime($date));
			}
			$lines=array();
			$lines[]="$style$date$styleoff";
			$lines[]="$style$service$styleoff";
			$lines[]="$style$function$styleoff";
			$lines[]="$style$linenum$styleoff";
			$lines[]="$style$line$styleoff";
			
			$c++;$data['rows'][] = array('id' => md5($line),'cell' => $lines);
			continue;	
		}
		
		
		
		$c++;$data['rows'][] = array('id' => md5($line),'cell' => $lines);
		

	}
	
	if($c==0){json_error_show("no data");}
	
	$data['total'] = $c;
	
echo json_encode($data);		

}





?>