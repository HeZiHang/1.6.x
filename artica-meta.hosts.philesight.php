<?php
if(isset($_GET["verbose"])){$GLOBALS["VERBOSE"]=true;ini_set('display_errors', 1);ini_set('error_reporting', E_ALL);ini_set('error_prepend_string',null);ini_set('error_append_string',null);}
include_once('ressources/class.templates.inc');
include_once('ressources/class.mysql-meta.inc');
include_once('ressources/class.system.network.inc');
include_once('ressources/class.system.nics.inc');


$users=new usersMenus();
if(!$users->AsArticaMetaAdmin){
	$tpl=new templates();
	echo "alert('".$tpl->javascript_parse_text("{ERROR_NO_PRIVS}")."')";;die();

}
if(isset($_GET["table"])){table();exit;}
if(isset($_GET["getlist"])){table_list();exit;}
if(isset($_GET["graph-js"])){graph_js();exit;}
if(isset($_GET["delete-js"])){delete_js();exit;}
if(isset($_GET["disks"])){disks();exit;}
if(isset($_GET["show-devices-js"])){show_devices_js();exit;}
if(isset($_GET["graph-popup"])){graph_popup();exit;}
if(isset($_GET["directory-js"])){directory_js();exit;}
if(isset($_GET["directory-popup"])){directory_popup();exit;}
if(isset($_POST["directory"])){directory_save();exit;}
if(isset($_POST["delete"])){directory_delete();exit;}
if(isset($_GET["png"])){png();exit;}

js();
function js(){
	header("content-type: application/x-javascript");
	$tpl=new templates();
	$page=CurrentPageName();
	$meta=new mysql_meta();
	$hostname=$meta->uuid_to_host($_GET["uuid"]);
	$title=$tpl->javascript_parse_text("{directories_monitor}");
	echo "YahooWin(900,'$page?table=yes&uuid={$_GET["uuid"]}','$hostname:$title')";

}

function graph_js(){
	header("content-type: application/x-javascript");
	$tpl=new templates();
	$page=CurrentPageName();
	$dir=$_GET["graph-js"];
	$dir2=urlencode($dir);
	echo "YahooWin3(845,'$page?graph-popup=yes&directory=$dir2&uuid={$_GET["uuid"]}&md5={$_GET["md5"]}','$dir')";

}

function delete_js(){
	header("content-type: application/x-javascript");
	$tpl=new templates();
	$page=CurrentPageName();
	$t=time();
	$title=$tpl->javascript_parse_text("{delete} {item}: {$_GET["delete-js"]} ?");
	echo "
	var xSave$t=function (obj) {
	var results=obj.responseText;
	if(results.length>0){alert(results);return;}
	$('#WATCHDOG_FOLDERS_TABLE').flexReload();
}


function Save$t(){
if(!confirm('$title')){return;}
var XHR = new XHRConnection();
var directory=encodeURIComponent('{$_GET["delete-js"]}');
XHR.appendData('delete',directory);
XHR.sendAndLoad('$page', 'POST',xSave$t);
}

Save$t()";
}

function directory_delete(){
$q=new mysql();
$directory=url_decode_special_tool($_POST["delete"]);
$md5=md5($directory);
$directory=mysql_escape_string2($directory);
$q->QUERY_SQL("DELETE FROM philesight WHERE `directory`='$directory'","artica_backup");
	if(!$q->ok){echo $q->mysql_error;return;}
	$time=time();
@unlink("/usr/share/artica-postfix/img/philesight/$md5.png");

}

function directory_js(){
header("content-type: application/x-javascript");
	$tpl=new templates();
	$title=$tpl->_ENGINE_parse_body("{new_directory}");
	$page=CurrentPageName();
	$dir=$_GET["directory"];
	if($dir<>null){
	$title=$dir;
	$dir2=urlencode($dir);
	}

	echo "YahooWin2(850,'$page?directory-popup=yes&directory=$dir2&uuid={$_GET["uuid"]}','$title')";

}

function graph_popup(){
	$page=CurrentPageName();
	$dir=$_GET["directory"];
	$md5=md5($dir);
	$time=microtime();
	$direnc=urlencode($dir);
	echo "<center style='width:98%;padding:10px' class=form>
	<img src='$page?png=yes&md5={$_GET["md5"]}'>
	</center>
		
	";
}
function png(){
	$q=new mysql_meta();
	$sql="SELECT image FROM philesight WHERE zmd5='{$_GET["md5"]}'";
	$ligne=mysql_fetch_array($q->QUERY_SQL($sql));
	header("Content-type: image/png");
	header("Content-Disposition: attachment; filename=\"{$_GET["md5"]}.png\";" );
	header("Content-Transfer-Encoding: binary");
	header("Content-Length: ".strlen($ligne["image"]));
	echo $ligne["image"];
	ob_clean();
	flush();
}

	function directory_save(){
	$q=new mysql();
	$directory=url_decode_special_tool($_POST["directory"]);
	$directory=mysql_escape_string2($directory);
	$ligne=mysql_fetch_array($q->QUERY_SQL("SELECT directory FROM philesight WHERE directory='$directory'","artica_backup"));
	if($ligne["directory"]==null){
	$q->QUERY_SQL("INSERT IGNORE INTO philesight (`directory`,`enabled`,`maxtime`)
	VALUES ('$directory','{$_POST["enabled"]}','{$_POST["maxtime"]}')","artica_backup");
	if(!$q->ok){echo $q->mysql_error;}
	return;
	}

	$q->QUERY_SQL("UPDATE philesight SET maxtime='{$_POST["maxtime"]}',
	enabled='{$_POST["enabled"]}' WHERE directory='$directory'","artica_backup");
	if(!$q->ok){echo $q->mysql_error;}


	}


	function directory_popup(){
	$t=time();
	$page=CurrentPageName();
	$tpl=new templates();
	$title=$tpl->_ENGINE_parse_body("{new_directory}");
	$directory=$_GET["directory"];
	$q=new mysql();
	$maxtime=420;
	$enabled=1;
	$maxtime_array[0]="{never}";
	$maxtime_array[60]="1 {hour}";
	$maxtime_array[120]="2 {hours}";
	$maxtime_array[380]="3 {hours}";
	$maxtime_array[420]="4 {hours}";
	$maxtime_array[480]="8 {hours}";
	$maxtime_array[720]="12 {hours}";
	$maxtime_array[1440]="1 {day}";
	$maxtime_array[2880]="1 {days}";
	$maxtime_array[10080]="1 {week}";
	$btname="{add}";
	$directory_field="<tr>
	<td class=legend style='font-size:18px'>{directory}:</td>
			<td>". Field_text("directory-$t",null,"font-size:18px;width:98%'")."</td>
			<td>".button_browse("directory-$t")."</td>
			</tr>";


			if($directory<>null){
		$ligne=mysql_fetch_array($q->QUERY_SQL("SELECT * FROM philesight WHERE directory='$directory'","artica_backup"));
		$directory_field="<input type='hidden' name='directory-$t' id='directory-$t' value='$directory'>";
		$title=basename($directory);
		$maxtime=$ligne["maxtime"];
		$enabled=$ligne["enabled"];
		$btname="{apply}";
	}




	$html="
	<div style='font-size:22px;margin-bottom:20px'>$title</div>
	<div style='width:98%' class=form>

	<table style='width:100%'>
	$directory_field
	<tr>
	<td class=legend style='font-size:18px'>{enabled}:</td>
	<td colspan=2>". Field_checkbox("enabled-$t", 1,$enabled)."</td>
	</tr>
	<tr>
	<td class=legend style='font-size:18px'>{scan_period}:</td>
			<td colspan=2>". Field_array_Hash($maxtime_array, "maxtime-$t",$maxtime,"style:font-size:18px")."</td>
			</tr>
			<tr>
			<td colspan=3 align='right'>". button($btname,"Save$t();",30)."</td>
		</tr>
		</table>
					</div>
					<script>
					var xSave$t=function (obj) {
					var results=obj.responseText;
					if(results.length>0){alert(results);return;}
					$('#WATCHDOG_FOLDERS_TABLE').flexReload();
	}


	function Save$t(){
	var XHR = new XHRConnection();
	var directory=encodeURIComponent(document.getElementById('directory-$t').value);
	XHR.appendData('directory',directory);
	XHR.appendData('maxtime',document.getElementById('maxtime-$t').value);
	if(document.getElementById('enabled-$t').checked){
	XHR.appendData('enabled',1);
	}else{
	XHR.appendData('enabled',0);
	}
	XHR.sendAndLoad('$page', 'POST',xSave$t);
	}
	</script>
	";
	echo $tpl->_ENGINE_parse_body($html);

	}

function table(){
	$t=time();
	$page=CurrentPageName();
	$tpl=new templates();
	$directory=$tpl->_ENGINE_parse_body("{directory}");
	$partition=$tpl->_ENGINE_parse_body("{partition}");
	$date=$tpl->_ENGINE_parse_body("{date}");
	$new_directory=$tpl->_ENGINE_parse_body("{new_directory}");
	$used=$tpl->javascript_parse_text("{used}");
	$hard_drive=$tpl->javascript_parse_text("{disk}");
	$free=$tpl->javascript_parse_text("{free}");
	$TABLE_WIDTH=705;
	$title=$tpl->javascript_parse_text("{directories_monitor} {$_GET["dev"]}");
	$rescan=$tpl->javascript_parse_text("{rescan}");

	$dir_size=153;
	$partition_size=83;
	$hd_size=125;
		if(isset($_GET["bypopup"])){
		$dir_size=111;
		$partition_size=83;
		$hd_size=83;
	}
	
	$newdir="{name: '$new_directory', bclass: 'add', onpress : AddShared$t},";
	
$buttons="
	buttons : [
	
	{name: '$rescan', bclass: 'Reconf', onpress : Refresh$t},
	],";

	$html="
	<table class='WATCHDOG_FOLDERS_TABLE' style='display: none' id='WATCHDOG_FOLDERS_TABLE' style='width:100%;'></table>
	<script>
	var IDTMP=0;
	$(document).ready(function(){
	$('#WATCHDOG_FOLDERS_TABLE').flexigrid({
	url: '$page?getlist=yes&dev={$_GET["dev"]}&uuid={$_GET["uuid"]}',
	dataType: 'json',
	colModel : [
	{display: '$date', name : 'lastscan', width :155, sortable : true, align: 'left'},
	{display: '$directory', name : 'directory', width :$dir_size, sortable : true, align: 'left'},
	{display: '$partition', name : 'partition', width :$partition_size, sortable : true, align: 'left'},
	{display: '$hard_drive', name : 'hd', width : $hd_size, sortable : true, align: 'left'},
	{display: '$used', name : 'USED', width : 85, sortable : true, align: 'right'},
	{display: '$free', name : 'FREEMB', width : 85, sortable : true, align: 'right'},
	{display: '&nbsp;', name : 'icon', width : 56, sortable : false, align: 'center'},
	
	],
	$buttons
	searchitems : [
	{display: '$directory', name : 'directory'},
	{display: '$partition', name : 'partition'},
	{display: '$hard_drive', name : 'hd'},

	],
	sortname: 'FREEMB',
	sortorder: 'asc',
	usepager: true,
	title: '<span style=font-size:18px>$title</span>',
	useRp: false,
	rp: 50,
	showTableToggleBtn: false,
	width: '99%',
	height: 450,
	singleSelect: true,
	rpOptions: [10, 20, 30, 50,100,200]

	});
	});

	function AddShared$t(){
		Loadjs('$page?directory-js=yes&directory=');
	}

	function Refresh$t(){
		Loadjs('artica-meta.menus.php?philesight-js=yes&uuid={$_GET["uuid"]}');
	}

	</script>
	";

	echo $html;

	}
	function table_list(){
	$tpl=new templates();
	$MyPage=CurrentPageName();
	$q=new mysql_meta();

	$fontsize="16px";
	$cs=0;
	$page=1;

	if (isset($_POST['rp'])) {$rp = $_POST['rp'];}
	if(!is_numeric($rp)){$rp=50;}
	$pageStart = ($page-1)*$rp;
	$limitSql = "LIMIT $pageStart, $rp";
	$_POST["query"]=trim($_POST["query"]);
	$FORCE="uuid='{$_GET["uuid"]}'";
	$search='%';
	$table="philesight";

	if($_GET["dev"]<>null){
	$FORCE=" ((partition='{$_GET["dev"]}') OR (hd='{$_GET["dev"]}')) AND (uuid='{$_GET["uuid"]}')";

	}

	$page=1;

	if(!$q->TABLE_EXISTS($table,"artica_backup")){
			$q->check_storage_table();
			}
			if(!$q->TABLE_EXISTS($table,"artica_backup")){
			json_error_show("$table no such table",1);
			}
			$total=0;
	if($q->COUNT_ROWS($table,"artica_backup")==0){json_error_show("no data",1);}

	$searchstring=string_to_flexquery();

	if($searchstring<>null){
	$sql="SELECT COUNT(*) as TCOUNT FROM `$table` WHERE $FORCE  $searchstring";
	$ligne=mysql_fetch_array($q->QUERY_SQL($sql,"artica_backup"));
	if(!$q->ok){ if(preg_match("#marked as crashed#", $q->mysql_error)){ $q->QUERY_SQL("DROP TABLE `$table`","artica_events"); } }

	$total = $ligne["TCOUNT"];

	}else{
	$total = $q->COUNT_ROWS($table, "artica_backup");
	}




	if (isset($_POST['rp'])) {$rp = $_POST['rp'];}
	if(!is_numeric($rp)){$rp=50;}
	$pageStart = ($page-1)*$rp;
	$limitSql = "LIMIT $pageStart, $rp";
	if(isset($_POST["sortname"])){if($_POST["sortname"]<>null){$ORDER="ORDER BY {$_POST["sortname"]} {$_POST["sortorder"]}";}}

	$sql="SELECT *  FROM `$table` WHERE $FORCE $searchstring $ORDER $limitSql";

	$results = $q->QUERY_SQL($sql,"artica_backup");
	if(!$q->ok){ if(preg_match("#marked as crashed#", $q->mysql_error)){ $q->QUERY_SQL("DROP TABLE `$table`","artica_events"); } }
	if(!$q->ok){json_error_show($q->mysql_error."<br>$sql",0);}

	$data = array();
	$data['page'] = $page;
	$data['total'] = $total;
	$data['rows'] = array();

	$CurrentPage=CurrentPageName();

	if(mysql_num_rows($results)==0){json_error_show("no data");}

	$uuid=urlencode($_GET["uuid"]);
	while($ligne=mysql_fetch_array($results,MYSQL_ASSOC)){
	$color="black";
	$icon="&nbsp;";
	$directory=$ligne["directory"];
	$md5=md5($directory);
	$partition=$ligne["partition"];
	$hd=$ligne["hd"];
	$maxtime=$ligne["maxtime"];
	$lastscan=$ligne["lastscan"];
	$USED=$ligne["USED"];
	$md5=$ligne["zmd5"];
	$FREEMB=$ligne["FREEMB"];
	if($lastscan>0){
		$lastscan=date("Y-m-d H:i:s",$lastscan);
	}
	
	$FREEMB=FormatBytes($FREEMB*1024);
	$directoryenc=urlencode($directory);
	$jslink="<a href=\"javascript:blur();\"
	OnClick=\"javascript:Loadjs('$MyPage?directory-js=yes&directory=$directoryenc');\"
	style='font-size:$fontsize;text-decoration:underline;color:$color'>";

	$distance=$tpl->_ENGINE_parse_body(distanceOfTimeInWords($ligne["lastscan"],time(),true));
	$icon=imgsimple("graph-32.png",null,"Loadjs('$MyPage?graph-js=$directoryenc&uuid={$_GET["uuid"]}&md5=$md5')");
	

	$delete=imgsimple("delete-32.png",null,"Loadjs('$MyPage?delete-js=$directoryenc&uuid={$_GET["uuid"]}')");

	$data['rows'][] = array(
			'id' => md5(serialize($ligne)),
			'cell' => array(
			"<span style='font-size:$fontsize;color:$color'>$jslink{$lastscan}</a></span><br><i>$distance</i>",
			"<span style='font-size:$fontsize;color:$color'>$jslink{$directory}</a></span>",
			"<span style='font-size:$fontsize;color:$color'>$jslink{$partition}</a></span>",
			"<span style='font-size:$fontsize;color:$color'>$jslink{$hd}</a></span>",
			"<span style='font-size:$fontsize;color:$color'>$jslink{$USED}%</a></span>",
			"<span style='font-size:$fontsize;color:$color'>$jslink{$FREEMB}</a></span>",
			"<span style='font-size:$fontsize;color:$color'>$icon</a></span>",
			
	)
	);

	}

	echo json_encode($data);

	}
