<?php
if(isset($_GET["verbose"])){$GLOBALS["VERBOSE"]=true;$GLOBALS["DEBUG_MEM"]=true;ini_set('display_errors', 1);ini_set('error_reporting', E_ALL);ini_set('error_prepend_string',null);ini_set('error_append_string',null);}
header("Pragma: no-cache");	
	header("Expires: 0");
	header("Last-Modified: " . gmdate("D, d M Y H:i:s") . " GMT");
	header("Cache-Control: no-cache, must-revalidate");
	include_once('ressources/class.templates.inc');
	include_once('ressources/class.ldap.inc');
	include_once('ressources/class.tcpip.inc');
	include_once(dirname(__FILE__) . '/ressources/class.main_cf.inc');
	include_once(dirname(__FILE__) . '/ressources/class.ldap.inc');
	include_once(dirname(__FILE__) . "/ressources/class.sockets.inc");
	include_once(dirname(__FILE__) . "/ressources/class.pdns.inc");
	include_once(dirname(__FILE__) . '/ressources/class.system.network.inc');
	include_once(dirname(__FILE__) . '/ressources/class.squid.inc');
	
	
	
	$user=new usersMenus();
	if($user->AsSquidAdministrator==false){
		header("content-type: application/x-javascript");
		$tpl=new templates();
		echo "alert('". $tpl->javascript_parse_text("{ERROR_NO_PRIVS}")."');";
		die();exit();
	}

if(isset($_GET["popup"])){popup();exit;}
if(isset($_GET["setup-1"])){setup_1();exit;}	
if(isset($_GET["setup-2"])){setup_2();exit;}
if(isset($_GET["setup-3"])){setup_3();exit;}
if(isset($_GET["setup-disk4"])){setup_disk4();exit;}

if(isset($_GET["setup-folder1"])){setup_folder1();exit;}
if(isset($_GET["setup-folder2"])){setup_folder2();exit;}
if(isset($_GET["setup-folder3"])){setup_folder3();exit;}
if(isset($_GET["setup-folder4"])){setup_folder4();exit;}


if(isset($_POST["ArticaHotSpotInterface"])){ArticaHotSpotInterface();exit;}
if(isset($_POST["ArticaHotSpotInterface2"])){ArticaHotSpotInterface2();exit;}
if(isset($_POST["SaveHD"])){SaveHD();exit;}
js();


function ArticaHotSpotInterface(){
	$sock=new sockets();
	$sock->SET_INFO("ArticaHotSpotInterface", $_POST["ArticaHotSpotInterface"]);
	
}
function ArticaHotSpotInterface2(){
	$sock=new sockets();
	$sock->SET_INFO("ArticaHotSpotInterface2", $_POST["ArticaHotSpotInterface2"]);
	
}

function js(){
	$page=CurrentPageName();
	$tpl=new templates();
	header("content-type: application/x-javascript");
	$title=$tpl->javascript_parse_text("{activate_hostpot}");
	echo "YahooWin3('900','$page?popup=yes','$title')";
}

function popup(){
	$page=CurrentPageName();
	$t=time();
	echo "<div id='$t' style='width:100%'></div>
	<script>
		LoadAjax('$t','$page?setup-1=yes&t=$t');
	</script>
	";
}

function setup_1(){
	$page=CurrentPageName();
	$users=new usersMenus();
	$tpl=new templates();
	$net=new networking();
	$sock=new sockets();
	$q=new mysql();
	$interfaces=$net->Local_interfaces();
	$t=$_GET["t"];
	
	
	unset($interfaces["lo"]);
	$ArticaHotSpotInterface=$sock->GET_INFO("ArticaHotSpotInterface");
	
	while (list ($eth, $none) = each ($interfaces) ){
		$nic=new system_nic($eth);
		$array[$eth]="$eth $nic->IPADDR - $nic->NICNAME";
		
	}
	
	
	
	
	$html="
	<div style='font-size:26px;margin-bottom:30px'>{hotspot_network}...</div>
	<div style='font-size:18px' class=explain>{hotspot_interface_explain}</div>
	
	<div style='width:98%' class=form>
	<table style='width:100%'>
	<tr>
		<td class=legend style='font-size:26px'>{network_interface}:</td>
		<td>". Field_array_Hash($array, "ArticaHotSpotInterface-$t",$ArticaHotSpotInterface,"style:font-size:26px")."</td>
	</tr>
	<tr>
		<td colspan=2 align='right' style='padding-top:50px'>". button("{next}","SaveF$t()",26)."</td>
	</tr>		
</table>
</div>
<script>
var xSaveF$t= function (obj) {
	var results=obj.responseText;
	if(results.length>3){alert(results);return;}
	LoadAjax('$t','$page?setup-2=yes&t=$t');
}	
	
function SaveF$t(){
	var XHR = new XHRConnection();
	XHR.appendData('ArticaHotSpotInterface',document.getElementById('ArticaHotSpotInterface-$t').value);
	XHR.sendAndLoad('$page', 'POST',xSaveF$t);
}
</script>
";
echo $tpl->_ENGINE_parse_body($html);	
	
	
}

function setup_2(){
	$page=CurrentPageName();
	$users=new usersMenus();
	$tpl=new templates();
	$net=new networking();
	$sock=new sockets();
	$q=new mysql();
	$interfaces=$net->Local_interfaces();
	$t=$_GET["t"];
	
	
	unset($interfaces["lo"]);
	$ArticaHotSpotInterface=$sock->GET_INFO("ArticaHotSpotInterface");
	$ArticaHotSpotInterface2=$sock->GET_INFO("ArticaHotSpotInterface2");
	
	while (list ($eth, $none) = each ($interfaces) ){
		if($eth==$ArticaHotSpotInterface){continue;}
		$nic=new system_nic($eth);
		$array[$eth]="$eth $nic->IPADDR - $nic->NICNAME";
	
	}
	
	
	
	
$html="
<div style='font-size:26px;margin-bottom:30px'>{hotspot_wan_network}...</div>
<div style='font-size:18px' class=explain>{hotspot_wan_network_explain}</div>
	
<div style='width:98%' class=form>
	<table style='width:100%'>
	<tr>
		<td class=legend style='font-size:26px'>{network_interface}:</td>
		<td>". Field_array_Hash($array, "ArticaHotSpotInterface2-$t",$ArticaHotSpotInterface2,"style:font-size:26px")."</td>
	</tr>
	<tr>
		<td colspan=2 align='right' style='padding-top:50px'>". button("{next}","SaveF$t()",26)."</td>
	</tr>
</table>
</div>
<script>
var xSaveF$t= function (obj) {
	var results=obj.responseText;
	if(results.length>3){alert(results);return;}
	LoadAjax('$t','$page?setup-3=yes&t=$t');
}
	
function SaveF$t(){
	var XHR = new XHRConnection();
	XHR.appendData('ArticaHotSpotInterface2',document.getElementById('ArticaHotSpotInterface2-$t').value);
	XHR.sendAndLoad('$page', 'POST',xSaveF$t);
}
</script>
";
	echo $tpl->_ENGINE_parse_body($html);	
	
	
}

function setup_3(){
	$dev=$_GET["dev"];
	$page=CurrentPageName();
	$tpl=new templates();
	$users=new usersMenus();
	$t=$_GET["t"];

	$html="	
<div style='font-size:26px;margin-bottom:30px'>{finish}...</div>
<div style='font-size:18px' class=explain>{hotspot_wizard_final}</div>	
<center style='margin:30px'>". button("{run_hotspot}", "SaveF$t()",40)."</center>	
<script>
function SaveF$t(){
	YahooWin3Hide();
	Loadjs('squid.webauth.progress.php');
}
</script>
	";
	
	echo $tpl->_ENGINE_parse_body($html);
	
}

function setup_folder3(){
	$page=CurrentPageName();
	$tpl=new templates();
	$users=new usersMenus();
	$t=$_GET["t"];
	$DISKS=array();
	$datas=unserialize(@file_get_contents("/usr/share/artica-postfix/ressources/usb.scan.serialize"));
	$sock=new sockets();
	$dev=$_GET["dev"];
	$DEV_enc=urlencode($dev);
	$size_enc=urlencode($size_enc);
	$OCT=urlencode($_GET["oct"]);
	$CPU_FIELD=null;
	$cpunumber=$users->CPU_NUMBER-1;
	if($cpunumber<1){$cpunumber=1;}
	if($cpunumber>1){
		for($i=1;$i<$cpunumber+1;$i++){
			$CPUZ[$i]="CPU $i";
		}
		
	}

	
	$PARTITIONS=$datas[$dev]["PARTITIONS"];
	
	while (list ($DEV, $PART_DATA) = each ($PARTITIONS) ){
		$MOUNTED=$PART_DATA["MOUNTED"];
		$ID_FS_LABEL=$PART_DATA["ID_FS_LABEL"];
		if($MOUNTED==null){continue;}
		
		$SIZE=FormatBytes($PART_DATA["INFO"]["SIZE"]);
		$FREE=FormatBytes($PART_DATA["INFO"]["FREE"]);
		$MOUNTED_enc=urlencode($MOUNTED);
		$DEV_enc=urlencode($DEV);
		$size=$PART_DATA["INFO"]["SIZE"];
		$curs="OnMouseOver=\"this.style.cursor='pointer';\"
		OnMouseOut=\"this.style.cursor='auto'\"
		OnClick=\"javascript:LoadAjax('$t','$page?setup-folder4=yes&t=$t&dev=$DEV_enc&size=$size&free={$PART_DATA["INFO"]["FREE"]}&mounted=$MOUNTED_enc');\"";
		
				
		
	$tr[]="
	<div style='margin:15px'>
	<div style='width:98%;min-height:116px' class=form $curs>
	<table style='width:100%'>
	<tr>
	<td valign='top'><img src='img/disk-128.png'></td>
	<td style='font-size:22px;vertical-align:middle'>
		<table style='width:100%'>
			<tr>
				<td style='font-size:18px' class=legend>{partition}:</td>
				<td style='font-size:18px;font-weight:bold'>$DEV</td>
			</tr>
			<tr>
				<td style='font-size:18px' class=legend>{type}:</td>
				<td style='font-size:18px'>$ID_FS_LABEL</td>
			</tr>
			<tr>
				<td style='font-size:18px' class=legend>{size}:</td>
				<td style='font-size:18px'>$SIZE</td>
			</tr>
			<tr>
				<td style='font-size:18px' class=legend>{free}:</td>
				<td style='font-size:18px'>$FREE</td>
			</tr>
			</table>
			</td>
		</td>
		</tr>
		</table>
	</div>
	</div>

			";	
	
	}
	$html=CompileTr4($tr,true);
	echo $tpl->_ENGINE_parse_body(
			"<center style='font-size:26px;margin-bottom:20px'>{select_your_partition}</center>
			$html");
		
}


function setup_folder2(){
	$page=CurrentPageName();
	$tpl=new templates();
	$users=new usersMenus();
	$t=$_GET["t"];
	$DISKS=array();
	$datas=unserialize(@file_get_contents("/usr/share/artica-postfix/ressources/usb.scan.serialize"));
	
	
	
	
	if(count($datas)==0){
		echo FATAL_ERROR_SHOW_128("{no_free_disk_found");
		return;
	}
	
	
	
	while (list ($DEV, $MAIN_HD) = each ($datas) ){
		if($DEV=="UUID"){continue;}
	
	
		$SIZEZ=intval($datas[$DEV]["SIZE"]);
		if($SIZEZ==0){continue;}
	
		$OCT=$datas["$DEV"]["OCT"];
		$ID_VENDOR=$datas[$DEV]["ID_VENDOR"];
	
		$PARTITIONS=$MAIN_HD["PARTITIONS"];
		$_COUNTPARTITIONS=count($PARTITIONS);
		$TOADD=true;
		if(count($PARTITIONS)>0){
			while (list ($part, $PART_DATA) = each ($PARTITIONS) ){
				$MOUNTED=$PART_DATA["MOUNTED"];
				$ID_VENDOR=$PART_DATA["ID_VENDOR"];
				if($MOUNTED=="/boot"){$TOADD=false;break;}
				if($MOUNTED=="/tmp"){$TOADD=false;break;}
				if($MOUNTED=="/"){$TOADD=false;break;}
				if($MOUNTED=="/var/log"){$TOADD=false;break;}
				if($MOUNTED=="/usr/share/artica-postfix"){$TOADD=false;break;}
			}
				
		}
		if(!$TOADD){continue;}
	
	
	
	
		$DEV_enc=urlencode($DEV);
		$size_enc=urlencode($datas[$DEV]["SIZE"]);
	
		$curs="OnMouseOver=\"this.style.cursor='pointer';\"
		OnMouseOut=\"this.style.cursor='auto'\"
		OnClick=\"javascript:LoadAjax('$t','$page?setup-folder3=yes&t=$t&dev=$DEV_enc&size=$size_enc&oct=$OCT');\"";
	
	
		$tr[]="
		<div style='margin:15px'>
		<div style='width:98%;min-height:116px' class=form $curs>
		<table style='width:100%'>
		<tr>
		<td valign='top'><img src='img/disk-128.png'></td>
		<td style='font-size:22px;vertical-align:middle'>
		<table style='width:100%'>
		<tr>
		<td style='font-size:18px' class=legend>{disk}:</td>
		<td style='font-size:18px'>$DEV</td>
		</tr>
		<tr>
		<td style='font-size:18px' class=legend>{type}:</td>
		<td style='font-size:18px'>$ID_VENDOR</td>
		</tr>
		<tr>
		<td style='font-size:18px' class=legend>{size}:</td>
		<td style='font-size:18px'>{$datas[$DEV]["SIZE"]}</td>
		<tr>
		<td style='font-size:18px' class=legend>{partitions}:</td>
		<td style='font-size:18px'>$_COUNTPARTITIONS</td>
		</tr>
		</table>
	
		</td>
		</tr>
		</table>
		</div>
		</div>
		
		";
	
	
	}
	$html=CompileTr4($tr,true);
	echo $tpl->_ENGINE_parse_body(
			"<div style='font-size:26px;margin-bottom:20px'>{select_your_disk}</div>
			$html");
		
	
	
}


function setup_disk1(){
	$page=CurrentPageName();
	$tpl=new templates();
	$users=new usersMenus();
	$t=$_GET["t"];
	
	$html="
	<div style='font-size:26px;margin-bottom:30px'>{scanning_your_hardware}...</div>
	<center id='scan-$t'></center>				
	
	<script>LoadAjax('scan-$t','$page?setup-disk2=yes&t=$t');</script>
	
	";
	echo $tpl->_ENGINE_parse_body($html);
	
}
function setup_disk2(){
	$page=CurrentPageName();
	$tpl=new templates();
	$users=new usersMenus();
	$t=$_GET["t"];	
	$sock=new sockets();
	$sock->getFrameWork("cmd.php?usb-scan-write=yes&tenir=yes");
	echo "<script>LoadAjax('$t','$page?setup-disk3=yes&t=$t');</script>";
}	
function setup_disk3(){
	$page=CurrentPageName();
	$tpl=new templates();
	$users=new usersMenus();
	$t=$_GET["t"];
	$DISKS=array();
	$datas=unserialize(@file_get_contents("/usr/share/artica-postfix/ressources/usb.scan.serialize"));
	
	

	
	if(count($datas)==0){
		echo FATAL_ERROR_SHOW_128("{no_free_disk_found");
		return;
	}
	
	

	while (list ($DEV, $MAIN_HD) = each ($datas) ){
		if($DEV=="UUID"){continue;}
		
		
		$SIZEZ=intval($datas[$DEV]["SIZE"]);
		if($SIZEZ==0){continue;}
		
		$OCT=$datas["$DEV"]["OCT"];
		$ID_VENDOR=$datas[$DEV]["ID_VENDOR"];
		
		$PARTITIONS=$MAIN_HD["PARTITIONS"];
		$_COUNTPARTITIONS=count($PARTITIONS);
		$TOADD=true;
		if(count($PARTITIONS)>0){
			while (list ($part, $PART_DATA) = each ($PARTITIONS) ){
				$MOUNTED=$PART_DATA["MOUNTED"];
				$ID_VENDOR=$PART_DATA["ID_VENDOR"];
				if($MOUNTED=="/boot"){$TOADD=false;break;}
				if($MOUNTED=="/tmp"){$TOADD=false;break;}
				if($MOUNTED=="/"){$TOADD=false;break;}
				if($MOUNTED=="/var/log"){$TOADD=false;break;}
				if($MOUNTED=="/usr/share/artica-postfix"){$TOADD=false;break;}
			}
			
		}
		if(!$TOADD){continue;}
		
		
		
		
		$DEV_enc=urlencode($DEV);
		$size_enc=urlencode($datas[$DEV]["SIZE"]);
		
		$curs="OnMouseOver=\"this.style.cursor='pointer';\"
		OnMouseOut=\"this.style.cursor='auto'\"
		OnClick=\"javascript:LoadAjax('$t','$page?setup-disk4=yes&t=$t&dev=$DEV_enc&size=$size_enc&oct=$OCT');\"";
		
		
		$tr[]="
		<div style='margin:15px'>
		<div style='width:98%;min-height:116px' class=form $curs>
		<table style='width:100%'>		
		<tr>
			<td valign='top'><img src='img/disk-128.png'></td>
			<td style='font-size:22px;vertical-align:middle'>
				<table style='width:100%'>
				<tr>
					<td style='font-size:18px' class=legend>{disk}:</td>
					<td style='font-size:18px'>$DEV</td>
				</tr>
				<tr>
					<td style='font-size:18px' class=legend>{type}:</td>
					<td style='font-size:18px'>$ID_VENDOR</td>
				</tr>
				<tr>
					<td style='font-size:18px' class=legend>{size}:</td>
					<td style='font-size:18px'>{$datas[$DEV]["SIZE"]}</td>
				<tr>
					<td style='font-size:18px' class=legend>{partitions}:</td>
					<td style='font-size:18px'>$_COUNTPARTITIONS</td>
				</tr>				
				</table>
				
				</td>
		</tr>
		</table>
		</div>
		</div>
		";
		
		
	}
	$html=CompileTr4($tr,true);
	echo $tpl->_ENGINE_parse_body(
			"<div style='font-size:26px;margin-bottom:20px'>{select_your_free_disk}</div>
			$html");
	
}	

function setup_disk4(){
	$page=CurrentPageName();
	$tpl=new templates();
	$users=new usersMenus();
	$t=$_GET["t"];
	$sock=new sockets();
	$dev=$_GET["dev"];
	$CPU_FIELD=null;
	$cpunumber=$users->CPU_NUMBER-1;
	if($cpunumber<1){$cpunumber=1;}
	if($cpunumber>1){
		for($i=1;$i<$cpunumber+1;$i++){
			$CPUZ[$i]="CPU $i";
		}
		
		$CPU_FIELD="<table style='width:100%;margin:20px'>
			<tr>
				<td class=legend style='font-size:20px'>{affect_cache_to}:</td>
				<td>". Field_array_Hash($CPUZ, "CPU-$t","style:font-size:20px")."</td>
			</tr>
			</table>
			";
		
	}
	
	
	$size=$_GET["size"];
	$html="<div style='font-size:26px;margin-bottom:20px'>{confirm}...( CPU(s) $cpunumber)</div>
			<div style='font-size:24px;margin-bottom:20px'>{this_format_data_lost}</div>
	<center style='margin:50px'>
			
		 			
			
			$CPU_FIELD
		". button("{create_cache_on} $dev ($size)","SaveHD$t()",24)."</center>
	
	<script>
	
	var xSaveHD$t= function (obj) {
			var results=obj.responseText;
			if(results.length>3){alert(results);return;}
			Loadjs('squid.caches.center.wizard.progress.php');
		}	
	
		function SaveHD$t(){
			var XHR = new XHRConnection();
			var cpu=1;
			if( document.getElementById('CPU-$t') ){
				cpu=document.getElementById('CPU-$t').value;
			}
			
			XHR.appendData('CPU',cpu);
			XHR.appendData('SaveHD','yes');
			XHR.appendData('dev','$dev');
			XHR.appendData('size','$size');
			XHR.appendData('oct','{$_GET["oct"]}');
			XHR.sendAndLoad('$page', 'POST',xSaveHD$t);
		
		}
</script>
	";
	echo $tpl->_ENGINE_parse_body($html);
}

function SaveHD(){
	
	$sock=new sockets();
	$sock->SaveConfigFile(serialize($_POST),"NewCacheCenterWizard");
}	