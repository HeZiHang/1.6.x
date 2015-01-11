<?php
session_start();
include_once('ressources/class.templates.inc');
include_once('ressources/class.users.menus.inc');
include_once('ressources/class.openvpn.inc');
include_once('ressources/class.system.network.inc');
include_once('ressources/class.tcpip.inc');
$users=new usersMenus();
if(!$users->AsSystemAdministrator){die("alert('no access');");}

	if(isset($_GET["popup"])){tabs();exit();}
	if(isset($_GET["popup-main"])){popup();exit;}
	if(isset($_GET["help"])){help();exit;}
	if(isset($_POST["connection_name"])){buildconfig();exit;}
	
js();

function help(){
	$tpl=new templates();
	$page=CurrentPageName();	
	$downloadvinvin=Paragraphe("setup-icon-64.png",
		"{DOWNLOAD_OPENVPN_CLIENT}",
		"{DOWNLOAD_OPENVPN_CLIENT_TEXT}",
		"javascript:s_PopUp('http://www.articatech.net/download/openvpn-2.1.4-install.exe')",
		"{DOWNLOAD_OPENVPN_CLIENT_TEXT}");

$downloadapple=Paragraphe("apple-logo-64.png",
		"{DOWNLOAD_OPENVPN_CLIENT_APPLE}",
		"{DOWNLOAD_OPENVPN_CLIENT_TEXT}",
		"javascript:s_PopUp('http://www.articatech.net/download/Tunnelblick_3.1.7.dmg')",
		"{DOWNLOAD_OPENVPN_CLIENT_TEXT}");


	$html="
	<div class=text-info>{OPENVPN_ADMIN_HELP_TEXT}</div>
	<table style='width:99%' class=form>
	<tbody>
	<tr>
		<td width=1%>$downloadvinvin</td>
	</tr>
	<tr>
		<td width=1%>$downloadapple</td>
	</tr>	
	</tboy>
	</table>
	
	";
	
	echo $tpl->_ENGINE_parse_body($html);
	}

function js(){
	
	$tpl=new templates();
	$page=CurrentPageName();
	$title=$tpl->_ENGINE_parse_body("{BUILD_OPENVPN_CLIENT_CONFIG}");
	$html="YahooWin4('940','$page?popup=yes','$title')";
	echo $html;
	
}

function tabs(){
	$html=GET_CACHED(__FILE__,__FUNCTION__,$_GET["newinterface"],TRUE);
	if($html<>null){echo $html;}
	$page=CurrentPageName();
	$users=new usersMenus();
	
	
	$array["popup-main"]="{BUILD_OPENVPN_CLIENT_CONFIG}";

	
	$array["help"]="{help}";
	
		$font="font-size:18px";
		$newinterface="&newinterface=yes";
	
	
	
	while (list ($num, $ligne) = each ($array) ){
			if($num=="OPENVPN_SCHEDULE_RUN"){
				$tab[]="<li><a href=\"index.openvpn.schedule.php?popup=yes\"><span style='$font'>$ligne</span></a></li>\n";
				continue;
				
			}
		
			$tab[]="<li><a href=\"$page?$num=yes$newinterface\"><span style='$font'>$ligne</span></a></li>\n";
			
		}
	$tpl=new templates();
	
	

	$html=build_artica_tabs($tab, "main_openvpn_builclientconfig");
	$tpl=new templates();
	$html=$tpl->_ENGINE_parse_body($html);
	SET_CACHED(__FILE__,__FUNCTION__,null,$html);
	echo $html;	
	
}


function popup(){
	$tpl=new templates();
	$page=CurrentPageName();	
	
	$os["windowsXP"]="Windows XP";
	$os["windows2003"]="Windows 2003/7";
	$os["linux"]="Linux";
	$os["mac"]="OS X 10.4, 10.5, 10.6";
	$os["Windows7"]="Windows 7 (Seven)";
	$os[null]="{select}";
	
	$os=Field_array_Hash($os,"ComputerOS",null,"style:font-size:32px;padding:3px");
	
	$html="<div class=text-info id='buildclientconfigdiv'>{BUILD_OPENVPN_CLIENT_CONFIG_TEXT}</div>
	
	<center style='width:98%' class=form>
		<table style='width:100%'>
		<tr>
			<td class=legend style='font-size:32px'>{connection_name}:</td>
			<td class=legend style='font-size:32px'>". Field_text("connection_name",null,"padding:20px;font-size:32px")."</td>
		</tr>
		<tr>
			<td class=legend style='font-size:32px'>{ComputerOS}:</td>
			<td class=legend style='font-size:32px'>$os</td>
		</tr>		
		<tr>
			<td colspan=2 align='right'><div style='margin-top:100px'><hr>". button("{generate_parameters}","GenerateVPNConfig()",32)."</div></td>
		</tr>
		</table>
	</center>
	<div id='generate-vpn-events'></div>
	<script>
			
	var x_GenerateVPNConfig= function (obj) {
			var tempvalue=obj.responseText;
			if(tempvalue.length>3){document.getElementById('generate-vpn-events').innerHTML=tempvalue;}
			}

	function GenerateVPNConfig(){
		var XHR = new XHRConnection();
		XHR.appendData('connection_name',document.getElementById('connection_name').value);
		XHR.appendData('ComputerOS',document.getElementById('ComputerOS').value);		
		AnimateDiv('generate-vpn-events');
		XHR.sendAndLoad('$page', 'POST',x_GenerateVPNConfig);				
	}
	</script>
	";
	echo $tpl->_ENGINE_parse_body($html);
	
	
}


function buildconfig(){
	$vpn=new openvpn();
	$connection_name=trim(strtolower($_POST["connection_name"]));
	if($connection_name==null){$connection_name=time();}
	$connection_name=str_replace(" ", "-", $connection_name);
	$connection_name=replace_accents($connection_name);
	$connection_name=str_replace("/", "-", $connection_name);
	$connection_name=str_replace('\\', "-", $connection_name);
	$tools=new htmltools_inc();
	$connection_name=$tools->StripSpecialsChars($connection_name);
	$vpn->ComputerOS=$_POST["ComputerOS"];
	$html_logs[]="<div><code style='font-size:10px;color:black;'>Operating system : $config->ComputerOS</div>";
	$html_logs[]="<div><code style='font-size:10px;color:black;'>Connection name. : $connection_name</div>";
	
	
	$config=$vpn->BuildClientconf($connection_name);
	$tbconfig=explode("\n",$config);
	$html_logs[]=htmlentities("VPN config -> ". strlen($config)." bytes length (".count($tbconfig)." lines)");
	$uid=$_SESSION["uid"];
	writelogs("VPN config -> ". strlen($config)." bytes length (".count($tbconfig)." lines)",__FUNCTION__,__FILE__,__LINE__);
	$sock=new sockets();
	if(!$sock->SaveConfigFile($config,"$connection_name.ovpn")){
		$html_logs[]=htmlentities("Framework error while saving  -> $connection_name.ovpn;". strlen($config)." bytes length (".count($tbconfig)." lines)");
	}
	
	writelogs("sockets() OK",__FUNCTION__,__FILE__,__LINE__);
	
	//$datas=$sock->getfile('OpenVPNGenerate:'.$uid);	
	$datas=$sock->getFrameWork("openvpn.php?build-vpn-user=$connection_name&basepath=".dirname(__FILE__));
	$tbl=explode("\n",$datas);
	$tbl=array_reverse($tbl);
	while (list ($num, $line) = each ($tbl) ){
		if(trim($line)==null){continue;}
		$html_logs[]="<div><code style='font-size:10px;color:black;'>" . htmlentities($line)."</code></div>";
		
	}
	
	if(is_file('ressources/logs/'.$connection_name.'.zip')){
		$download="
		<center>
		<div style='width:320px;border:2px solid #CCCCCC;padding:5px;margin:10px'>
			<div style='font-size:14px'>{click_here}</div>
			<a href='ressources/logs/".$connection_name.".zip'>
				<img src='img/download-64.png' title=\"{DOWNLOAD_CONFIG_FILES}\" style='padding:8Px;border:1px solid #055447;margin:3px'></a>
				<br>
				<a href='ressources/logs/".$connection_name.".zip' style='font-size:16px;text-decoration:underline'>$connection_name.zip</a>
		</div>		
				
		</center>
		";
		
	}	
	
	$html="
	
	$download
	<div style='font-size:16px'>{events}</div>
	<div style='width:100%;height:200px;overflow:auto'>". implode("\n",$html_logs)."</div>";
	
	$tpl=new templates();
	echo $tpl->_ENGINE_parse_body($html);	
	
	
}
