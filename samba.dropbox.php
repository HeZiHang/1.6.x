<?php
	include_once('ressources/class.templates.inc');
	include_once('ressources/class.ldap.inc');
	include_once('ressources/class.users.menus.inc');
	include_once('ressources/class.samba.inc');
	
	
$usersmenus=new usersMenus();
if(!$usersmenus->AsAnAdministratorGeneric){
	$tpl=new templates();
	$alert=$tpl->_ENGINE_parse_body('{ERROR_NO_PRIVS}');
	echo "alert('$alert');";
	die();	
}

if(isset($_GET["popup"])){popup();exit;}
if(isset($_GET["config"])){config();exit;}
if(isset($_GET["EnableDropBox"])){save();exit;}
if(isset($_GET["index"])){status();exit;}
if(isset($_GET["status"])){service_status();exit;}
if(isset($_GET["files"])){files_status();exit;}
if(isset($_GET["service-cmds-peform"])){service_cmds_perform();exit;}
if(isset($_GET["service-cmds"])){service_cmds_js();exit;}

js();
function service_cmds_js(){
	$page=CurrentPageName();
	$tpl=new templates();
	$cmd=$_GET["service-cmds"];
	$mailman=$tpl->_ENGINE_parse_body("{APP_DROPBOX}");
	$html="YahooWin6('650','$page?service-cmds-peform=$cmd','$mailman::$cmd');";
	echo $html;	
}

function js(){
	$tpl=new templates();
	$title=$tpl->_ENGINE_parse_body("{APP_DROPBOX}");
	$page=CurrentPageName();
	$html="YahooWin5('650','$page?popup=yes','$title');";
	echo $html;
	
}

function service_cmds_perform(){
	$sock=new sockets();
	$page=CurrentPageName();
	$tpl=new templates();
	$datas=unserialize(base64_decode($sock->getFrameWork("services.php?service-dropbox-cmds={$_GET["service-cmds-peform"]}")));
	
		$html="
<div style='width:100%;height:350px;overflow:auto'>
<table cellspacing='0' cellpadding='0' border='0' class='tableView' style='width:100%'>
<thead class='thead'>
	<tr>
	<th>{events}</th>
	</tr>
</thead>
<tbody class='tbody'>";	
	
	while (list ($key, $val) = each ($datas) ){
		if(trim($val)==null){continue;}
		if(trim($val=="->")){continue;}
		if(isset($alread[trim($val)])){continue;}
		$alread[trim($val)]=true;
		if($classtr=="oddRow"){$classtr=null;}else{$classtr="oddRow";}
		$val=htmlentities($val);
			$html=$html."
			<tr class=$classtr>
			<td width=99%><code style='font-size:12px'>$val</code></td>
			</tr>
			";
	
	
}

$html=$html."
</tbody>
</table>
</div>
<script>
	RefreshTab('main_dropbox_config');
</script>

";
	echo $tpl->_ENGINE_parse_body($html);
}

function popup(){
	$page=CurrentPageName();
	$users=new usersMenus();
	$array["index"]='{index}';
	$array["config"]="{parameters}";
	$array["files"]="{files_changed}";
	
	
	while (list ($num, $ligne) = each ($array) ){
		$tab[]="<li><a href=\"$page?$num=yes\"><span style='font-size:14px'>$ligne</span></a></li>\n";
			
		}
	$tpl=new templates();
	
	

	$html="
		<div id='main_dropbox_config' style='background-color:white'>
			<ul>
				". implode("\n",$tab). "
			</ul>
		</div>
		<script>
				$(document).ready(function(){
					$('#main_dropbox_config').tabs();
			

			});
		</script>
	
	";
		
	$tpl=new templates();
	$html=$tpl->_ENGINE_parse_body($html);
	echo $html;
	}
	
	
function config(){
	$page=CurrentPageName();
	$tpl=new templates();	
	$sock=new sockets();
	$EnableDropBox=$sock->GET_INFO("EnableDropBox");
	$EnableShareDropBox=$sock->GET_INFO("EnableShareDropBox");
	if($EnableDropBox==null){$EnableDropBox=0;}
	if($EnableShareDropBox==null){$EnableShareDropBox=0;}
	
	$DropBoxShareProperties=unserialize(base64_decode($sock->GET_INFO("DropBoxShareProperties")));
	if($DropBoxShareProperties["ShareDropBoxName"]==null){$DropBoxShareProperties["ShareDropBoxName"]="dropbox";}	
	$enableShare=Paragraphe_switch_disable("{share_dropbox_path}","{share_dropbox_path_text}",null,300);
	$enable=Paragraphe_switch_img("{enable_dropbox_service}","{dropbox_service_text}","EnableDropBox",$EnableDropBox,null,500);
	
	$users=new usersMenus();
	if($users->SAMBA_INSTALLED){
		
		$samba=new samba();
		$folder_name=$samba->GetShareName("/home/dropbox");
		if($folder_name<>null){
			$EnableShareDropBox=1;
			//$share=Paragraphe("disk_share_enable-64.png","{smb_infos}","{folder_properties}","javascript:FolderProp('$folder_name');");	
			if($folder_name<>$DropBoxShareProperties["ShareDropBoxName"]){$DropBoxShareProperties["ShareDropBoxName"]=$folder_name;}
		}else{
			$EnableShareDropBox=0;
		}
		$enableShare=Paragraphe_switch_img("{share_dropbox_path}","{share_dropbox_path_text}","EnableShareDropBox",$EnableShareDropBox,null,500);
	}
	
	
	$html="
	<table style='width:99%' class=form>
	<tr>
	<td valign='top'>$enable</td>
	<td valign='top'>&nbsp;</td>
	</tr>
	<tr>
	<td colspan=2><hr></td>
	<tr>
	<td valign='top'>$enableShare</td>
	<td valign='top'>$share</td>
	</tr>
	</table>
	<table style='width:99%' class=form>
	<tr>
		<td class=legend style='font-size:16px'>{share_name}:</td>
		<td>". Field_text("ShareDropBoxName",$DropBoxShareProperties["ShareDropBoxName"],"font-size:16px;padding:3px;width:190px")."</td>
	</tr>
	</table>
	
	
	<div style='text-align:right'><hr>". button("{apply}","SaveDropBoxConfig()","18px")."</div>
	
	<script>
	
	var X_SaveDropBoxConfig= function (obj) {
		var results=obj.responseText;
		if(results.length>0){alert(results);}
		RefreshTab('main_dropbox_config');
	}	
	function SaveDropBoxConfig(){
			var XHR = new XHRConnection();
			XHR.appendData('ShareDropBoxName',document.getElementById('ShareDropBoxName').value);
			XHR.appendData('EnableDropBox',document.getElementById('EnableDropBox').value);
			document.getElementById('img_EnableDropBox').src='img/wait_verybig.gif';
			if(document.getElementById('EnableShareDropBox')){
				XHR.appendData('EnableShareDropBox',document.getElementById('EnableDropBox').value);
				document.getElementById('img_EnableShareDropBox').src='img/wait_verybig.gif';
			}
			XHR.sendAndLoad('$page', 'GET',X_SaveDropBoxConfig);	
	}
	</script>
	
	";	
	
	echo $tpl->_ENGINE_parse_body($html);
	

}

function save(){
	$sock=new sockets();
	$sock->SET_INFO("EnableDropBox",$_GET["EnableDropBox"]);
	$sock->SET_INFO("EnableShareDropBox",$_GET["EnableShareDropBox"]);
	$sock->SaveConfigFile(base64_encode(serialize($_GET)),"DropBoxShareProperties");
	
	$users=new usersMenus();
	if($users->SAMBA_INSTALLED){
		$samba=new samba();
		$folder_name=$samba->GetShareName("/home/dropbox");
		if($_GET["EnableShareDropBox"]==1){
			if($folder_name==null){
				$samba->main_array[$_GET["ShareDropBoxName"]]["path"]="/home/dropbox";
				$samba->main_array[$_GET["ShareDropBoxName"]]["create mask"]= "0660";
				$samba->main_array[$_GET["ShareDropBoxName"]]["directory mask"] = "0770";
				$samba->SaveToLdap();
			}else{
				if($folder_name<>$_GET["ShareDropBoxName"]){
					$oldarray=$samba->main_array[$folder_name];
					unset($samba->main_array[$folder_name]);
					$samba->main_array[$_GET["ShareDropBoxName"]]=$oldarray;
					$samba->SaveToLdap();
				}
			}	
		}else{
			if($folder_name<>null){
				unset($samba->main_array[$folder_name]);
				$samba->SaveToLdap();
			}
			
		}
	}
	
}

function status(){
	$page=CurrentPageName();
	$tpl=new templates();	
	$sock=new sockets();	
	$html="<table style='width:100%'>
	<tr>
		<td valign='top'><img src='img/dropbox-128.png'></td>
		<td valign='top'><div id=dropbox-status></div>
	</tr>
	</table>
	<script>
		function DropBoxStatus(){
			LoadAjax('dropbox-status','$page?status=yes');
		}
		DropBoxStatus();
	</script>
	
	";
	echo $tpl->_ENGINE_parse_body($html);
}
function service_status(){
	$page=CurrentPageName();
	$ini=new Bs_IniHandler();
	$sock=new sockets();
	$ini->loadString($sock->getFrameWork("cmd.php?dropbox-status=yes"));
	$text_status=$sock->getFrameWork("cmd.php?dropbox-service-status=yes");
	$uri=$sock->GET_INFO("DropBoxUri");
	if(strlen($uri)<10){
		$uri=$sock->getFrameWork("cmd.php?dropbox-service-uri=yes");
	}		
	$status=DAEMON_STATUS_ROUND("APP_DROPBOX",$ini);
	$tpl=new templates();
	

	$link="<br>
	<span style='font-size:14px;color:#AA1F1F;padding:5px;font-weight:bolder'>
		<a href='#' style='font-size:14px;color:#AA1F1F;text-decoration:underline' OnClick=\"javascript:s_PopUp('$uri',800,800);\">
			&laquo;&laquo;&nbsp;{link_this_server_to_an_account}&raquo;&raquo;&nbsp;</a></span>
	";
	
	if(strlen($uri)<10){
		$link="<br><span style='font-size:14px;color:red;padding:5px;font-weight:bolder'>{unable_to_obtain_uri}</span>";
		
	}
	
	if($text_status=="Idle"){$link=null;}
	
	echo $tpl->_ENGINE_parse_body(
	"
	$status
	
		<center style='margin-top:-25px;margin-bottom:10px;width:100%' >
		<table style='width:30%' class=form>
		<tbody>
		<tr>
			<td width=10% align='center;'>". imgtootltip("32-stop.png","{stop}","Loadjs('$page?service-cmds=stop')")."</td>
			<td width=10% align='center'>". imgtootltip("32-run.png","{start}","Loadjs('$page?service-cmds=start')")."</td>
		</tr>
		</tbody>
		</table>
		</center>	
	
	<div style='float:right'>". imgtootltip("refresh-32.png","{refresh}","DropBoxStatus()")."</div>
	<span style='font-size:14px;color:#AA1F1F;padding:5px'>{status}:$text_status</span>
	$link
	
	
	
	<div style='font-size:13px' class=text-info>{dropbox_service_text}</div>
	");
}

function files_status(){
	$sock=new sockets();
	$array=unserialize(base64_decode($sock->getFrameWork("cmd.php?dropbox-service-dump=yes")));
	if(!is_array($array)){return null;}
	
$html="

<table cellspacing='0' cellpadding='0' border='0' class='tableView'>
<thead class='thead'>
	<tr>
	<th>&nbsp;</th>
	<th>{file_path}</th>
	<th>{status}</th>
	
	</tr>
</thead>
<tbody class='tbody'>

";	
	
	if(preg_match_all("#\(([a-z])'(.+?)',([\s0-9A-Za-z]+)\)#",$array["recently_changed3"],$re)){
		while (list($index,$filename)=each($re[2])){
			$filename=str_replace("{$array["root_ns"]}:/","",$filename);
			if($classtr=="oddRow"){$classtr=null;}else{$classtr="oddRow";}
			$html=$html."<tr class=$classtr>
			<td width=1%><img src='img/fw_bold.gif'></td>
			<td><code style='font-size:13px'>$filename</code></td>
			<td width=1% align='center'>{$re[1][$index]}</td>
			
			</tr>
			
			";
			
		}
		
		
	}
	
	$html=$html."</tbody></table>";
	$tpl=new templates();
	echo $tpl->_ENGINE_parse_body($html);
}

?>