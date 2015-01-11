<?php
	if(isset($_GET["verbose"])){$GLOBALS["VERBOSE"]=true;ini_set('display_errors', 1);ini_set('error_reporting', E_ALL);ini_set('error_prepend_string',null);ini_set('error_append_string',null);}
	$GLOBALS["ICON_FAMILY"]="POSTFIX";
	if(posix_getuid()==0){die();}
	session_start();
	if($_SESSION["uid"]==null){echo "window.location.href ='logoff.php';";die();}
	include_once('ressources/class.templates.inc');
	include_once('ressources/class.ldap.inc');
	include_once('ressources/class.users.menus.inc');
	include_once('ressources/class.main_cf.inc');
	include_once('ressources/class.ejabberd.inc');
	
	$user=new usersMenus();
	if($user->AsPostfixAdministrator==false){
		$tpl=new templates();
		echo "alert('". $tpl->javascript_parse_text("{ERROR_NO_PRIVS}")."');";
		die();exit();
	}
	
	if(isset($_GET["hosts"])){hosts();exit;}
	if(isset($_GET["servers-list"])){servers_list();exit;}
	if(isset($_POST["enable_host"])){enable_host();exit;}
	if(isset($_GET["softwares-client"])){softwares_client();exit;}
	if(isset($_GET["config-file"])){main_config_ejabberdfile();exit;}
	if(isset($_GET["global-parameters"])){global_parameters_popup();exit;}
	if(isset($_POST["ejabberdEnabled"])){global_parameters_save();exit;}
tabs();




function tabs(){
	
	$tpl=new templates();
	$users=new usersMenus();
	$page=CurrentPageName();
	$sock=new sockets();
	$fontsize=16;
	$users=new usersMenus();
	
	$array["hosts"]="{domains}";
	$array["status"]="{status}";
	$array["softwares-client"]="{jabber_clients}";
	
	
	while (list ($num, $ligne) = each ($array) ){
		
		
		if($num=="status"){
			$html[]= $tpl->_ENGINE_parse_body("<li><a href=\"ejabberd.status.php\" style='font-size:$fontsize;font-weight:normal'><span>$ligne</span></a></li>\n");
			continue;
		}
		
		
		
		
		$html[]= $tpl->_ENGINE_parse_body("<li><a href=\"$page?$num=yes\" style='font-size:$fontsize;font-weight:normal'><span>$ligne</span></a></li>\n");
	}
	
	
	
	echo "
	<div id=main_ejabberd_tabs style='width:99%;overflow:auto'>
		<ul>". implode("\n",$html)."</ul>
	</div>
		<script>
			$(document).ready(function(){
				$('#main_ejabberd_tabs').tabs();
			});
		</script>";	

}


function hosts(){
	$page=CurrentPageName();
	$users=new usersMenus();
	$tpl=new templates();
	$t=time();
	$date=$tpl->_ENGINE_parse_body("{zDate}");
	$description=$tpl->_ENGINE_parse_body("{description}");
	$context=$tpl->_ENGINE_parse_body("{context}");	
	$events=$tpl->_ENGINE_parse_body("{events}");	
	$empty=$tpl->_ENGINE_parse_body("{empty}");	
	$empty_events_text_ask=$tpl->javascript_parse_text("{empty_events_text_ask}");	
	
	$jabberdhostname=$tpl->_ENGINE_parse_body("{jabberdhostname}");
	$enable=$tpl->_ENGINE_parse_body("{enable}");
	$administrator=$tpl->_ENGINE_parse_body("{administrator}");
	$add_domain=$tpl->_ENGINE_parse_body("{add_domain}");
	$add_default_www=$tpl->_ENGINE_parse_body("{add_default_www}");
	$delete_freeweb_text=$tpl->javascript_parse_text("{delete_freeweb_text}");
	$delete_freeweb_dnstext=$tpl->javascript_parse_text("{delete_freeweb_dnstext}");	
	$WebDavPerUser=$tpl->_ENGINE_parse_body("{WebDavPerUser}");
	$rebuild_items=$tpl->_ENGINE_parse_body("{rebuild_items}");
	$config_file=$tpl->_ENGINE_parse_body("{config_file}");
	$choose_your_zarafa_webserver_type=$tpl->_ENGINE_parse_body("{choose_your_zarafa_webserver_type}");
	$parameters=$tpl->_ENGINE_parse_body("{global_parameters}");
	$bt_default_www="{name: '$add_default_www', bclass: 'add', onpress : FreeWebAddDefaultVirtualHost},";
	$bt_webdav="{name: '$WebDavPerUser', bclass: 'add', onpress : FreeWebWebDavPerUsers},";
	//$bt_rebuild="{name: '$rebuild_items', bclass: 'Reconf', onpress : RebuildFreeweb},";
	$bt_config=",{name: '$config_file', bclass: 'Script', onpress : config_file}";					
	$bt_parameters=",{name: '$parameters', bclass: 'Settings', onpress : ParametersMain$t}";	
	$member=$tpl->javascript_parse_text("{member}");
	$online_help=$tpl->_ENGINE_parse_body("{online_help}");
	$tablewidth=874;
	$servername_size=409;
	$bt_function_add="AddNewejabberServer";
	$PYMSNT_INSTALLED=0;
	if($users->PYMSNT_INSTALLED){
		$PYMSNT_INSTALLED=1;
		$bt_msn=",{name: 'MSN', bclass: 'MyMSN', onpress : MyMSN},";
	}else{
		$bt_msn=",{name: 'MSN', bclass: 'MyMSNOff', onpress : MyMSN},";
		
	}
	
	$PYICQT_INSTALLED=0;
	if($users->PYICQT_INSTALLED){
		$PYICQT_INSTALLED=1;
		$bt_icq=",{name: 'ICQ', bclass: 'MyIcqOn', onpress : MyICQ},";
	}else{
		$bt_icq=",{name: 'ICQ', bclass: 'MyIcqOff', onpress : MyICQ},";
		
	}	
	$bt_msn=null;
	$bt_icq=null;
		
	
	
	$buttons="
	buttons : [
	{name: '<b>$add_domain</b>', bclass: 'add', onpress : $bt_function_add}$bt_msn$bt_icq$bt_config$bt_parameters
	,{name: '$online_help', bclass: 'Help', onpress : ItemHelp$t},
	
		],";
	$html="
	<table class='jabberd-table-$t' style='display: none' id='jabberd-table-$t' style='width:100%;margin:-10px'></table>
<script>
FreeWebIDJBB='';
$(document).ready(function(){
$('#jabberd-table-$t').flexigrid({
	url: '$page?servers-list=yes&t=$t',
	dataType: 'json',
	colModel : [
		{display: '&nbsp;', name : 'icon', width : 31, sortable : false, align: 'center'},
		{display: '$jabberdhostname', name : 'hostname', width :$servername_size, sortable : true, align: 'left'},
		{display: '$enable', name : 'enabled', width :31, sortable : true, align: 'center'},
		{display: '$administrator', name : 'uid', width : 256, sortable : true, align: 'false'},
		{display: '&nbsp;', name : 'none1', width : 31, sortable : false, align: 'left'},
	],
	$buttons

	searchitems : [
		{display: '$jabberdhostname', name : 'hostname'},
		{display: '$member', name : 'uid'},
		],
	sortname: 'hostname',
	sortorder: 'asc',
	usepager: true,
	title: '',
	useRp: true,
	rp: 50,
	showTableToggleBtn: false,
	width: $tablewidth,
	height: 420,
	singleSelect: true
	
	});   
});
function ItemHelp$t(){
	s_PopUpFull('http://mail-appliance.org/index.php?cID=375','1024','900');
}

	function HelpSection(){
		LoadHelp('freewebs_explain','',false);
	}
	
	function config_file(){
		YahooWin(650,'$page?config-file=yes','$config_file');
	}

	function AddNewejabberServer(){
		 Loadjs('DomainsBrowse.php?callback=AddNewJabberDomain')
	}
	
	function ParametersMain$t(){
		YahooWin2(650,'$page?global-parameters=yes&t=$t','$parameters');
	}
	
	function MyMSN(){
		var PYMSNT_INSTALLED=$PYMSNT_INSTALLED;
		if(PYMSNT_INSTALLED==1){
			Loadjs('ejabberd.msn.php');
		}else{
			alert('Fatal:Plugin not detected');
		}
	}
	
	function MyICQ(){
		var PYMSNT_INSTALLED=$PYICQT_INSTALLED;
		if(PYMSNT_INSTALLED==1){
			Loadjs('ejabberd.icq.php');
		}else{
			alert('Fatal:Plugin not detected');
		}
	}	
	
	
	
	var x_EmptyEvents$t= function (obj) {
		var results=obj.responseText;
		if(results.length>3){alert(results);return;}
		$('#jabberd-table-$t').flexReload();
		//$('#grid_list').flexOptions({url: 'newurl/'}); 
		// $('#fgAllPatients').flexOptions({ query: 'blah=qweqweqwe' }).flexReload();
	}
	
	var x_EmptyEvents2$t= function (obj) {
		var results=obj.responseText;
		if(results.length>3){alert(results);return;}
		$('#row'+FreeWebIDJBB).remove();
		//$('#grid_list').flexOptions({url: 'newurl/'}); 
		// $('#fgAllPatients').flexOptions({ query: 'blah=qweqweqwe' }).flexReload();
	}	
	
		function AddNewJabberDomain(domain){
			var XHR = new XHRConnection();
			XHR.appendData('hostname',domain);
			XHR.sendAndLoad('ejabberd.edit.php', 'POST',x_EmptyEvents$t);	
		}

		function JabberdDelete(domain,id){
			FreeWebIDJBB=id;
			var XHR = new XHRConnection();
			XHR.appendData('delete-hostname',domain);
			XHR.sendAndLoad('ejabberd.edit.php', 'POST',x_EmptyEvents2$t);			
		}
	
	function AddNewFreeWebServerZarafa(){
		YahooWin('650','$page?freeweb-zarafa-choose=yes&t=$t','$choose_your_zarafa_webserver_type');
	}
	
	function FreeWebWebDavPerUsers(){
		Loadjs('freeweb.webdavusr.php?t=$t')
	}
	
	

	var x_PostedNothing= function (obj) {
		var results=obj.responseText;
		if(results.length>3){alert(results);return;}
	}		
	
	var x_FreeWebDelete=function (obj) {
			var results=obj.responseText;
			if(results.length>10){alert(results);return;}	
			$('#row'+FreeWebIDMEM).remove();
			if(document.getElementById('container-www-tabs')){	RefreshTab('container-www-tabs');}
		}


		
		function FreeWebDelete(server,dns,md){
			FreeWebIDMEM=md;
			if(confirm('$delete_freeweb_text')){
				var XHR = new XHRConnection();
				if(dns==1){if(confirm('$delete_freeweb_dnstext')){XHR.appendData('delete-dns',1);}else{XHR.appendData('delete-dns',0);}}
				XHR.appendData('delete-servername',server);
    			XHR.sendAndLoad('freeweb.php', 'GET',x_FreeWebDelete);
			}
		}	
		
		function FreeWebAddDefaultVirtualHost(){
			var XHR = new XHRConnection();
			XHR.appendData('AddDefaultOne','yes');
    		XHR.sendAndLoad('freeweb.php', 'POST',x_FreeWebRefresh);		
		}
		
		function eJabberdEnableHost(id,hostname){
			var value=0;
			if(document.getElementById(id).checked){value=1;}else{value=0;}
			var XHR = new XHRConnection();
			XHR.appendData('enable_host',value);
			XHR.appendData('hostname',hostname);
    		XHR.sendAndLoad('$page', 'POST',x_PostedNothing);					
		
		}
		
		function FreeWeCheckVirtualHost(){
			var XHR = new XHRConnection();
			XHR.appendData('CheckAVailable','yes');
    		XHR.sendAndLoad('freeweb.php', 'POST',x_FreeWebDelete);			
		}
	
</script>";
	
	echo $html;	
	
}

function global_parameters_save(){
	$sock=new sockets();
	if(isset($_POST["ejabberdInsideZarafa"])){
		if($_POST["ejabberdEnabled"]==0){$_POST["ejabberdInsideZarafa"]=0;}
		$sock->SET_INFO("ejabberdInsideZarafa", $_POST["ejabberdInsideZarafa"]);
	}
	$sock->SET_INFO("ejabberdEnabled", $_POST["ejabberdEnabled"]);
	$sock->getFrameWork("services.php?restart-artica-status=yes");
	$sock->getFrameWork("services.php?restart-instant-messaging=yes");
	if(isset($_POST["ejabberdInsideZarafa"])){
		$sock->getFrameWork("freeweb.php?reconfigure-webapp=yes");
	}
	
}

function global_parameters_popup(){
	$sock=new sockets();
	$page=CurrentPageName();
	$tpl=new templates();	
	$users=new usersMenus();
	$t=$_GET["t"];
	$ejabberdEnabled=$sock->GET_INFO("ejabberdEnabled");
	$ejabberdInsideZarafa=$sock->GET_INFO("ejabberdInsideZarafa");
	if(!is_numeric($ejabberdEnabled)){$ejabberdEnabled=1;}
	if(!is_numeric($ejabberdInsideZarafa)){$ejabberdInsideZarafa=0;}
	
	$paragraph=Paragraphe_switch_img("{activate_instant_messaging}","{APP_EJABBERD_ABOUT}","ejabberdEnabled-$t",$ejabberdEnabled,null,550);
	
	$paragraph2=Paragraphe_switch_img("{activate_instant_messaging_Zarafa}","{activate_instant_messaging_Zarafa_explain}","ejabberdInsideZarafa-$t",$ejabberdInsideZarafa,null,550);
	
	if(!$users->ZARAFA_INSTALLED){
		$paragraph2=Paragraphe_switch_disable("{activate_instant_messaging_Zarafa}","{activate_instant_messaging_Zarafa_explain}",null,550);	}
	
	$html="
		<div id='$t-div'></div>
		$paragraph<hr>
		$paragraph2
		<hr>
		<div style='text-align:right'>". button("{apply}","SaveejabberdEnabled()",18)."</div>
				
<script>
	var x_SaveejabberdEnabled= function (obj) {
		document.getElementById('$t-div').innerHTML='';
		var res=obj.responseText;
		if (res.length>3){alert(res);return;}
		$('#jabberd-table-$t').flexReload();
		YahooWin2Hide();
	}			
		
	function SaveejabberdEnabled(){
		var valuz=document.getElementById('ejabberdEnabled-$t').value;
		var XHR = new XHRConnection();
		XHR.appendData('ejabberdEnabled',valuz);
		if(document.getElementById('ejabberdInsideZarafa-$t')){
			XHR.appendData('ejabberdInsideZarafa',document.getElementById('ejabberdInsideZarafa-$t').value);
		}
		AnimateDiv('$t-div');
		XHR.sendAndLoad('$page', 'POST',x_SaveejabberdEnabled);	
	}	
</script>			
	";
	
	echo $tpl->_ENGINE_parse_body($html);
	
	
}


function servers_list(){
	$search=$_GET["search"];
	$MyPage=CurrentPageName();
	$page=1;
	$users=new usersMenus();
	$tpl=new templates();	
	$sock=new sockets();	
	$q=new mysql();
	$table="ejabberd";
	$database="artica_backup";
	$t=$_GET["t"];
	if($q->COUNT_ROWS($table,$database)==0){$data['page'] = $page;$data['total'] = $total;$data['rows'] = array();echo json_encode($data);return ;}
	
	if(isset($_POST["sortname"])){
		if($_POST["sortname"]<>null){
			$ORDER="ORDER BY {$_POST["sortname"]} {$_POST["sortorder"]}";
		}
	}	
	
	if (isset($_POST['page'])) {$page = $_POST['page'];}
	

	if($_POST["query"]<>null){
		$_POST["query"]=str_replace("*", "%", $_POST["query"]);
		$search=$_POST["query"];
		$searchstring="AND (`{$_POST["qtype"]}` LIKE '$search')";
		$sql="SELECT COUNT(*) as TCOUNT FROM `$table` WHERE 1 $searchstring";
		$ligne=mysql_fetch_array($q->QUERY_SQL($sql,$database));
		$total = $ligne["TCOUNT"];
		
	}else{
		$sql="SELECT COUNT(*) as TCOUNT FROM `$table`";
		$ligne=mysql_fetch_array($q->QUERY_SQL($sql,$database));
		$total = $ligne["TCOUNT"];
	}
	
	if (isset($_POST['rp'])) {$rp = $_POST['rp'];}	
	

	
	$pageStart = ($page-1)*$rp;
	$limitSql = "LIMIT $pageStart, $rp";
	if($OnlyEnabled){$limitSql=null;}
	$sql="SELECT *  FROM `$table` WHERE 1 $searchstring $FORCE_FILTER $ORDER $limitSql";	
	writelogs($sql,__FUNCTION__,__FILE__,__LINE__);
	$results = $q->QUERY_SQL($sql,$database);
	
	
	
	$data = array();
	$data['page'] = $page;
	$data['total'] = $total;
	$data['rows'] = array();
	if(mysql_num_rows($results)==0){$data['rows'][] = array('id' => $ligne[time()],'cell' => array($sql,"", "",""));}
	$ldap=new clladp();
	while ($ligne = mysql_fetch_assoc($results)) {

		$color=black;
		$groupware=$tpl->_ENGINE_parse_body($groupware);
		$forward_text=$tpl->_ENGINE_parse_body($forward_text);
		$servername_text=$tpl->_ENGINE_parse_body($servername_text);
		$ServerAlias=$tpl->_ENGINE_parse_body($ServerAlias);
		$uptime=$tpl->_ENGINE_parse_body($uptime);
		$memory=$tpl->_ENGINE_parse_body($memory);
		$requests_second=$tpl->_ENGINE_parse_body("$requests_second");
		$traffic_second=$tpl->_ENGINE_parse_body($traffic_second);
		$checkResolv=$tpl->_ENGINE_parse_body($checkResolv);
		$checkDNS=$tpl->_ENGINE_parse_body($checkDNS);
		$checkMember=$tpl->_ENGINE_parse_body($checkMember);
		$delete=$tpl->_ENGINE_parse_body($delete);
		
		$md5S=md5($ligne["hostname"]);
		$icon="jabberd-24.png";
		$servername_text=$ligne["hostname"];
		
		$enabled=Field_checkbox("enabled_$md5S", 1,$ligne["enabled"],"eJabberdEnableHost('enabled_$md5S','{$ligne["hostname"]}')");
		$href="<a href=\"javascript:blur();\" OnClick=\"javascript:Loadjs('ejabberd.edit.php?hostname={$ligne["hostname"]}&t=$t')\" style='text-decoration:underline'>";
		
		$spanStyle1="<span style='font-size:13px;font-weight:bold;color:#5F5656;'>";
		
		$ou=$ldap->ou_by_smtp_domain($ligne["hostname"]);
		
		
		$delete="<a href=\"javascript:blur();\" OnClick=\"javascript:JabberdDelete('{$ligne["hostname"]}','$md5S');\"><img src='img/delete-24.png'></a>";
		
			$data['rows'][] = array(
				'id' => $md5S,
				'cell' => array(
					"<img src='img/$icon'>", 
					"<strong style='font-size:14px;style='color:$color'>$href$servername_text</a>$groupware$forward_text</strong>",
					"$spanStyle1$enabled</span>",
					"$spanStyle1$ou/{$ligne["uid"]}</span>",
					$delete
					)
				);		
		

		}

	echo json_encode($data);		
}

function enable_host(){
	$jb=new ejabberd($_POST["hostname"]);
	$jb->enabled=$_POST["enable_host"];
	$jb->SaveHostname();
	
}
function softwares_client(){
	
	$html="<div class=text-info>{JABBER_SOFT_CLIENTS}</div>
	
	<div style='font-size:16px;margin:10px'>{resources}:</div>
	<table style='width:99%' class=form>
	
	<tr>
		<td class=legend style='font-size:14px'>XMPP:</td>
		<td><a href='http://xmpp.org/xmpp-software/clients/' style='font-size:14px;text-decoration:underline' target=_new>Clients List</a></td>
	</tr>		
	<tr>
		<td class=legend style='font-size:14px'>Wikipedia:</td>
		<td><a href='http://en.wikipedia.org/wiki/Comparison_of_instant_messaging_clients#XMPP-related_features' style='font-size:14px;text-decoration:underline' target=_new>Comparison of instant messaging clients</a></td>
	</tr>	
	<tr>
		<td class=legend style='font-size:14px'>Softpedia:</td>
		<td><a href='http://news.softpedia.com/news/Best-5-Jabber-Clients-for-Windows-in-Pictures-86636.shtml' style='font-size:14px;text-decoration:underline' target=_new>Best 5 Jabber Clients for Windows in Pictures</a></td>
	</tr>
	<tr>
		<td class=legend style='font-size:14px'>http://www.worldsiteindex.com:</td>
		<td><a href='http://www.worldsiteindex.com/chat/winclients.html' target=_new style='font-size:14px;text-decoration:underline'>Jabber Clients for Windows</a></td>
	</tr>	
	<tr>
		<td class=legend style='font-size:14px'>Generation NT:</td>
		<td><a href='http://www.generation-nt.com/comparatif-clients-jabber-test-messagerie-instantanee-msn-wlm-article-24991-4.html' style='font-size:14px;text-decoration:underline' target=_new>Comparatif et Test des clients de messagerie instantanée Jabber</a></td>
	</tr>		
	</table>
<div style='font-size:16px;margin:10px'>{softwares_clients}:</div>
	<table style='width:99%' class=form>
	
	<tr>
		<td class=legend style='font-size:14px'>Psi:</td>
		<td><a href='http://psi-im.org/' style='font-size:14px;text-decoration:underline' target=_new>Psi - The Cross-Platform XMPP Client For Power Users</a></td>
	</tr>			
	<tr>
		<td class=legend style='font-size:14px'>safetyjabber:</td>
		<td><a href='http://safetyjabber.com/' style='font-size:14px;text-decoration:underline' target=_new>Free jabber instant messenger client for windows</a></td>
	</tr>
	<tr>
		<td class=legend style='font-size:14px'>Spark:</td>
		<td><a href='http://www.igniterealtime.org/downloads/index.jsp' style='font-size:14px;text-decoration:underline' target=_new>Spark XMPP Clients</a></td>
	</tr>			
	<tr>
		<td class=legend style='font-size:14px'>Coccinella:</td>
		<td><a href='http://thecoccinella.org/' style='font-size:14px;text-decoration:underline' target=_new>Coccinella - Chat client with whiteboard</a></td>
	</tr>	
	<tr>
		<td class=legend style='font-size:14px'>Gajim:</td>
		<td><a href='http://gajim.org/downloads.php/' style='font-size:14px;text-decoration:underline' target=_new>Gajim, a Jabber/XMPP client</a></td>
	</tr>		
	</table>
	";
		$tpl=new templates();	
	echo $tpl->_ENGINE_parse_body($html);
	
	
	
	
}
function main_config_ejabberdfile(){
	$sock=new sockets();
	$tbl=unserialize(base64_decode($sock->getFrameWork("jabber.php?configuration-file=yes")));
	
	$html="<div style='background-color:white;width:100%;height:490px;overflow:auto;font-size:11px;margin-top:7px;margin-left:-10px' class=form>
	
	<table style='width:99%' class='tableView'><tbody class='tbody'>
	
	";
	while (list ($num, $ligne) = each ($tbl) ){
		if(trim($ligne)==null){continue;}
		if(preg_match("#password.*?\"(.*?)\"#", $ligne,$re)){$ligne=str_replace($re[1], "*******", $ligne);}
		$ligne=htmlentities($ligne);
		$ligne=str_replace("\t","&nbsp;&nbsp;&nbsp;&nbsp;",$ligne);
		$ligne=str_replace(' ',"&nbsp;",$ligne);
		if(preg_match("#^\##",$ligne)){continue;}
		if($classtr=="oddRow"){$classtr=null;}else{$classtr="oddRow";}	
		$html=$html . "<tr class=$classtr style='height:auto'>
		<td width=1% style='font-size:10px;height:auto;font-family: monospace, sans-serif;'><strong>$num.</strong></td>
		<td width=99% style='font-size:10px;height:auto;font-family: monospace, sans-serif;'>$ligne</td>
		</tr>";
		
	}
	
	$html=$html . "</tbody></table></div>";
	$tpl=new templates();
	echo $tpl->_ENGINE_parse_body($html);	
	}
