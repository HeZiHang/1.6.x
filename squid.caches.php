<?php
	header("Pragma: no-cache");	
	header("Expires: 0");
	header("Last-Modified: " . gmdate("D, d M Y H:i:s") . " GMT");
	header("Cache-Control: no-cache, must-revalidate");
	include_once('ressources/class.templates.inc');
	include_once('ressources/class.ldap.inc');
	include_once('ressources/class.users.menus.inc');
	include_once('ressources/class.groups.inc');
	include_once('ressources/class.artica.inc');
	include_once('ressources/class.ini.inc');
	include_once('ressources/class.squid.inc');
	include_once('ressources/class.system.network.inc');
	
	if(isset($_GET["caches"])){caches_main();exit;}
	if(isset($_GET["caches-list"])){caches_list();exit;}
	if(isset($_GET["fqdncache_size"])){main_save_array();exit;}
	if(isset($_GET["parameters"])){parameters_main();exit;}
	if(isset($_GET["RebduildCaches"])){cache_rebuild();exit;}
	if(isset($_GET["ReConstructCaches"])){cache_reconstruct();exit;}
	if(isset($_GET["DeleteCache"])){cache_delete();exit;}
	if(isset($_GET["add-cache"])){cache_edit();exit();}
	if(isset($_GET["cache_directory"])){cache_save();exit;}
	if(isset($_GET["cache_control"])){cache_control();exit;}
	if(isset($_GET["main_parameters"])){main_parameters();exit;}
	if(isset($_GET["js"])){js();exit;}
	if(isset($_GET["parameters-js"])){main_parameters_js();exit;}
	if(isset($_GET["caches-js"])){caches_js();exit;}
	if(isset($_GET["calculate-mb-size"])){calculate_mb_size();exit;}
	
	
	tabs();
	
	
function main_parameters_js(){
	$page=CurrentPageName();
	$tpl=new templates();	
	$title=$tpl->_ENGINE_parse_body("{cache}::{main_parameters}");
	$html="YahooWin5('600','$page?parameters=yes&byjs=yes','$title');";
	echo $html;
	}	
function caches_js(){
	$page=CurrentPageName();
	$tpl=new templates();	
	$title=$tpl->_ENGINE_parse_body("{cache}::{caches}");
	$html="YahooWin5('600','$page?caches=yes&byjs=yes','$title');";
	echo $html;
	}		
function js(){
	$page=CurrentPageName();
	echo "<script>$('#BodyContent').load('$page');</script>";
}	
	
function tabs(){
	$squid=new squidbee();
	$sock=new sockets();
	$page=CurrentPageName();
	$byminiadm=false;
	$DisableAnyCache=$sock->GET_INFO("DisableAnyCache");
	if(!is_numeric($DisableAnyCache)){$DisableAnyCache=0;}
	$users=new usersMenus();
	$EnableWebProxyStatsAppliance=$sock->GET_INFO("EnableWebProxyStatsAppliance");
	if(!is_numeric($EnableWebProxyStatsAppliance)){$EnableWebProxyStatsAppliance=0;}	
	if($users->WEBSTATS_APPLIANCE){$EnableWebProxyStatsAppliance=1;}
	if(isset($_GET["byminiadm"])){$byminiadm=true;}
	
	$array["caches"]='{caches}';
	if($DisableAnyCache==0){
		$array["parameters"]='{parameters}';
		$array["main_parameters"]='{main_parameters}';
	}
	$uuid=base64_decode($sock->getFrameWork("cmd.php?system-unique-id=yes"));
	$width="700px";
	
	if(isset($_GET["byQuicklinks"])){
		$fontsize="style='font-size:14px'";
		$width="100%";
		unset($array["main_parameters"]);
	}
	
	$page=CurrentPageName();
	$tpl=new templates();	

	
	while (list ($num, $ligne) = each ($array) ){
		
		if($num=="caches"){
			if($EnableWebProxyStatsAppliance==1){
				$html[]= $tpl->_ENGINE_parse_body("<li><a href=\"squid.cache-central.php?uuid=$squid->uuid\" $fontsize><span>$ligne</span></a></li>\n");
				continue;				
				
			}
			
			
			if($squid->IS_32){
				$html[]= $tpl->_ENGINE_parse_body("<li><a href=\"squid.caches32.php?uuid=$squid->uuid\" $fontsize><span>$ligne</span></a></li>\n");
				continue;
			}
			
			
			
		}
		
		if($num=="cache_websites"){
			$html[]= $tpl->_ENGINE_parse_body("<li><a href=\"squid.caches32.caches-www.php\" $fontsize><span>$ligne</span></a></li>\n");
			continue;
			
		}
		
		$html[]= $tpl->_ENGINE_parse_body("<li><a href=\"$page?$num=yes\" $fontsize><span>$ligne</span></a></li>\n");
		
			
		}
	echo build_artica_tabs($html, "squid_main_caches_new");
	
	
}

function main_parameters(){
	echo "<center><img src=\"img/wait_verybig.gif\"></center><script>Loadjs('squid.newbee.php?yes');</script>";
}

function cache_control(){
	
	echo "<div id='cached_sites_infos' style='width:100%;height:650px;overflow:auto'><center><img src=\"img/wait_verybig.gif\"></center></div>
<script>LoadAjax('cached_sites_infos','squid.cached.sitesinfos.php?sites-list=yes');</script>";
	
}

function parameters_main(){
	$squid=new squidbee();
	$usermenus=new usersMenus();
	$page=CurrentPageName();	
	$byjs=$_GET["byjs"];							
	$squid_infos=new squid();
	$sock=new sockets();
	$caches_types=unserialize(base64_decode($sock->getFrameWork("squid.php?caches-types=yes")));
	unset($caches_types["rock"]);
	$cache_type=Field_array_Hash($caches_types,'master_cache_type',$squid->CACHE_TYPE,"style:font-size:14px");
	$squidCacheSize=FormatBytes($squid->CACHE_SIZE*1000);
	
	$DisableAnyCache=$sock->GET_INFO("DisableAnyCache");
	if(!is_numeric($DisableAnyCache)){$DisableAnyCache=0;}
	
	
	
	$tr[]="<td width=1% nowrap>". button("{reconstruct_caches}","Loadjs('squid.rebuildcahes.php')",14)."</td>";
	
	if($squid->IS_32){
		$tr[]="<td width=1% nowrap>". button("{disable_smp}","Loadjs('squid.caches.smp.php?disable-js=yes')",14)."</td>";
	}
	
	
	
	$changeCacheJS="Loadjs('squid.caches32.php?add-new-disk-js=yes&chdef=yes')";
	
$cache_settings="
<div id='cachesettingsinfo' style='width:99%' class=form>
<center style='margin:10px'><table style='width:10%'>". @implode("\n", $tr)."</table></center>
<table style='width:100%'>
		<tr>
			<td align='right' class=legend nowrap nowrap style='font-size:14px'>{main_cache_size}:</strong></td>
			<td style='font-size:14px'><a href=\"javascript:blur();\" OnClick=\"javascript:$changeCacheJS\" style='font-size:14px;text-decoration:underline'>{$squid->CACHE_SIZE}</a>" . Field_hidden('cache_size',$squid->CACHE_SIZE)."&nbsp;Mbytes&nbsp;<span style='font-size:12px'>$squidCacheSize</span></td>
			<td></td>
		</tr>
		<tr>
			<td align='right' class=legend nowrap nowrap style='font-size:14px'>{type}:</strong></td>
			<td style='font-size:14px'>{$squid->CACHE_TYPE}</td>
			<td>" . help_icon('{cache_type_text}',false,'squid.index.php')."</td>
		</tr>		
		
		
		
<tr>
		<tr>
		<td align='right' class=legend nowrap style='font-size:14px'>{cache_mem}:</strong></td>
		<td>" . Field_text('cache_mem',$squid->global_conf_array["cache_mem"],'width:70px;font-size:14px')."</td>
		<td>" . help_icon('{cache_mem_text}',false,'squid.index.php')."</td>
		</tr>
<tr>
		<td align='right' class=legend nowrap style='font-size:14px'>{cache_swap_low}:</strong></td>
		<td style='font-size:14px'>" . Field_text('cache_swap_low',$squid->global_conf_array["cache_swap_low"],'width:70px;font-size:14px')."&nbsp;%</td>
		<td>" . help_icon('{cache_swap_low_text}',false,'squid.index.php')."</td>
</tr>
<tr>
		<td align='right' class=legend nowrap style='font-size:14px'>{cache_swap_high}:</strong></td>
		<td style='font-size:14px'>" . Field_text('cache_swap_high',$squid->global_conf_array["cache_swap_high"],'width:70px;font-size:14px')."&nbsp;%</td>
		<td>" . help_icon('{cache_swap_high_text}',false,'squid.index.php')."</td>
</tr>
<tr>
		<td align='right' class=legend nowrap style='font-size:14px'>{maximum_object_size}:</strong></td>
		<td>" . Field_text('maximum_object_size',$squid->global_conf_array["maximum_object_size"],'width:70px;font-size:14px')."</td>
		<td>" . help_icon('{maximum_object_size_text}',false,'squid.index.php')."</td>
		</tr>
<tr>
		<td align='right' class=legend nowrap style='font-size:14px'>{minimum_object_size}:</strong></td>
		<td>" . Field_text('minimum_object_size',$squid->global_conf_array["minimum_object_size"],'width:70px;font-size:14px')."</td>
		<td>" . help_icon('{minimum_object_size_text}',false,'squid.index.php')."</td>
		</tr>
<tr>
		<td align='right' class=legend nowrap style='font-size:14px'>{maximum_object_size_in_memory}:</strong></td>
		<td>" . Field_text('maximum_object_size_in_memory',$squid->global_conf_array["maximum_object_size_in_memory"],'width:70px;font-size:14px')."</td>
		<td>" . help_icon('{maximum_object_size_in_memory_text}',false,'squid.index.php')."</td>
		</tr>			
<tr>
		<td align='right' class=legend nowrap style='font-size:14px'>{ipcache_size}:</strong></td>
		<td>" . Field_text('ipcache_size',$squid->global_conf_array["ipcache_size"],'width:70px;font-size:14px')."</td>
		<td>" . help_icon('{ipcache_size_text}',false,'squid.index.php')."</td>
		</tr>	
<tr>
		<td align='right' class=legend nowrap style='font-size:14px'>{ipcache_low}:</strong></td>
		<td style='font-size:14px'>" . Field_text('ipcache_low',$squid->global_conf_array["ipcache_low"],'width:70px;font-size:14px')."&nbsp;%</td>
		<td>" . help_icon('{ipcache_low_text}',false,'squid.index.php')."</td>
		</tr>
<tr>
		<td align='right' class=legend nowrap style='font-size:14px'>{ipcache_high}:</strong></td>
		<td style='font-size:14px'>" . Field_text('ipcache_high',$squid->global_conf_array["ipcache_high"],'width:70px;font-size:14px')."&nbsp;%</td>
		<td>" . help_icon('{ipcache_high_text}',false,'squid.index.php')."</td>
		</tr>
<tr>
		<td align='right' class=legend nowrap style='font-size:14px'>{fqdncache_size}:</strong></td>
		<td>" . Field_text('fqdncache_size',$squid->global_conf_array["fqdncache_size"],'width:70px;font-size:14px')."</td>
		<td>" . help_icon('{fqdncache_size_text}',false,'squid.index.php')."</td>
		</tr>
		<tr>
			<td align='right' colspan=3><hr>". button('{apply}',"SaveCacheSettingsInfos()","18px")."</td>
		</tr>		
								
</table>
</div>


	<script>
	
	var x_SaveCacheSettingsInfos= function (obj) {
		 	var byjs='$byjs';
			var results=obj.responseText;
			if(results.length>0){alert(results);}
			if(document.getElementById('squid_main_caches_new')){RefreshTab('squid_main_caches_new');}
			if(document.getElementById('squid_main_config')){RefreshTab('squid_main_config');}
			if(byjs=='yes'){Loadjs('$page?parameters-js=yes');}			
			
		}		
	
	function SaveCacheSettingsInfos(){
		var XHR = new XHRConnection();		
		XHR.appendData('cache_mem',document.getElementById('cache_mem').value);
		XHR.appendData('cache_swap_low',document.getElementById('cache_swap_low').value);
		XHR.appendData('cache_swap_high',document.getElementById('cache_swap_high').value);
		XHR.appendData('maximum_object_size',document.getElementById('maximum_object_size').value);
		XHR.appendData('maximum_object_size_in_memory',document.getElementById('maximum_object_size_in_memory').value);
		XHR.appendData('ipcache_size',document.getElementById('ipcache_size').value);
		XHR.appendData('ipcache_low',document.getElementById('ipcache_low').value);
		XHR.appendData('ipcache_high',document.getElementById('ipcache_high').value);
		XHR.appendData('fqdncache_size',document.getElementById('fqdncache_size').value);
		document.getElementById('cachesettingsinfo').innerHTML='<center><img src=\"img/wait_verybig.gif\"></center>';
		XHR.sendAndLoad('$page', 'GET',x_SaveCacheSettingsInfos);
		}
		
		
	$('#section_squidcache32').remove();
	</script>
	

"	;


$html="
<div style='font-size:16px'>{cache_title}</div>$cache_settings";
$tpl=new templates();
echo $tpl->_ENGINE_parse_body($html,'squid.index.php');		

	
}

function caches_list(){
	$squid=new squidbee();
	$page=CurrentPageName();
	$tpl=new templates();	
	$sock=new sockets();		
	
	$html="
<table cellspacing='0' cellpadding='0' border='0' class='tableView' style='width:100%'>
<thead class='thead'>
	<tr>
	<th colspan=2>{cache}</th>
	<th>{type}</th>
	<th>{size}</th>
	<th>&nbsp;</th>
	<th>&nbsp;</th>
	</tr>
</thead>
<tbody class='tbody'>";	
	$classtr="oddRow";
	$unit="&nbsp;MB";
	$cacheinfo=unserialize(base64_decode($sock->getFrameWork("cmd.php?squid-cache-infos=yes")));
	if($squid->CACHE_SIZE>1000){
		$squid->CACHE_SIZE=$squid->CACHE_SIZE/1000;
		$unit="&nbsp;GB";
	}	
		
	
		$html=$html."
			<tr class=$classtr>
			<td width=1%>". imgtootltip("database-32.png","{apply}","AddCache('$squid->CACHE_PATH')")."</td>
			<td nowrap><strong style='font-size:14px'>". basename($squid->CACHE_PATH)."</strong><div style='font-size:11px'><i>$squid->CACHE_PATH</i></div></td>
			<td width=1%><strong style='font-size:14px'>$squid->CACHE_TYPE</strong></td>
			<td width=1%><strong style='font-size:14px'>$squid->CACHE_SIZE$unit</strong></td>
			<td>". caches_infos($cacheinfo[$squid->CACHE_PATH])."</td>
			<td width=1%>&nbsp;</td>
			</tr>
			";	
	
		while (list ($path, $array) = each ($squid->cache_list) ){
			if($classtr=="oddRow"){$classtr=null;}else{$classtr="oddRow";}
			$unit="&nbsp;MB";
			$maxcachesize=null;
			if($array["cache_type"]=="rock"){
				$maxcachesize="&nbsp;({max_objects_size} {$array["cache_maxsize"]}$unit)";
			}
			
			
			
			if(is_numeric($array["cache_size"])){
				if($array["cache_size"]>1000){
					$array["cache_size"]=$array["cache_size"]/1000;
					$unit="&nbsp;GB";
					}
			}
					
	
		$html=$html."
			<tr class=$classtr>
			<td width=1%>". imgtootltip("database-32.png","{apply}","AddCache('$path')")."</td>
			<td nowrap><strong style='font-size:14px'>". basename($path)."</strong><div style='font-size:11px'><i>$path&nbsp;$maxcachesize</i></div></td>
			<td width=1%><strong style='font-size:14px'>{$array["cache_type"]}</strong></td>
			<td width=1%><strong style='font-size:14px'>{$array["cache_size"]}$unit</strong></td>
			<td>". caches_infos($cacheinfo[$path])."</td>
			<td width=1%>". imgtootltip("delete-32.png","{delete}","DeleteCache('$path')")."</td>
			</tr>
			";				
			
		}
		$html=$html."
	</tbody>
	</table>";
	
	echo $tpl->_ENGINE_parse_body($html);
	
}

function caches_infos($array){
	if(!is_array($array)){return "<img src='img/cache-warning-48.png'>";}
			$pourc=pourcentage($array["POURC"]);
			$currentsize=FormatBytes($array["CURRENT"]);
			$max=FormatBytes($array["MAX"]);	
			
	$html="
	<table>
	<tr style='background-color:transparent'>
		<td style='border:0px'>$pourc</td>
	</tr>
	<tr style='background-color:transparent;border:0px'>
	<td align='right' style='border:0px'><i>{used}:$currentsize</i>&nbsp;</td>
	</tr>
	</table>		
	";
	return $html;
	
}

function cache_edit(){
	$tpl=new templates();
	$squid=new squid();
	$page=CurrentPageName();
	$cache=$_GET["cache"];
	
	$s=new squidbee();
	if($s->cache_list[$cache]["cache_size"]==null){$s->cache_list[$cache]["cache_size"]="2000";}
	if($s->cache_list[$cache]["cache_type"]==null){$s->cache_list[$cache]["cache_type"]="aufs";}	
	if($s->cache_list[$cache]["cache_dir_level1"]==null){$s->cache_list[$cache]["cache_dir_level1"]="16";}	
	if($s->cache_list[$cache]["cache_dir_level2"]==null){$s->cache_list[$cache]["cache_dir_level2"]="256";}			
	
	$sock=new sockets();
	$caches_types=unserialize(base64_decode($sock->getFrameWork("squid.php?caches-types=yes")));
	
	
	$caches_types[null]='{select}';

	
	if($cache==$s->CACHE_PATH){
		$main_add="XHR.appendData('main-is-cache','yes');";
		$s->cache_list[$cache]["cache_size"]=$s->CACHE_SIZE;
		$s->cache_list[$cache]["cache_type"]=$s->CACHE_TYPE;
		$s->cache_list[$cache]["cache_dir_level1"]=16;
		$s->cache_list[$cache]["cache_dir_level2"]=256;
		$main_load="HideLevels();";
	}
	
	if(!is_numeric($s->cache_list[$cache]["cache_maxsize"])){$s->cache_list[$cache]["cache_maxsize"]=1;}
	
	$type=$tpl->_ENGINE_parse_body(Field_array_Hash($caches_types,'cache_type',
	$s->cache_list[$cache]["cache_type"],"CheckCachesTypes()",null,0,"font-size:16px;padding:3px"));	
	
	$html="
	<div id='waitcache'></div>
	<form name='FFMCACHE'>
	<table style='width:99%' class=form>
		<tr>
		<td class=legend style='font-size:16px' nowrap>{directory}:</td>
		<td>" . Field_text('cache_directory',$cache,'width:270px;font-size:16px;padding:3px')."</td>
		<td><input type='button' value='{browse}...' OnClick=\"Loadjs('SambaBrowse.php?no-shares=yes&field=cache_directory')\"></td>
		</tr>
		<tr>
			<td class=legend style='font-size:16px' nowrap>{type}:</td>
			<td>$type</td>
			<td>&nbsp;</td>
		</tr>
		<tr>
			<td class=legend style='font-size:16px' nowrap>{cache_size}:</td>
			<td style='font-size:16px'>" . Field_text('squid-cache-size',$s->cache_list[$cache]["cache_size"],'width:100px;font-size:16px;padding:3px',null,"calculateSize()",null,false,null)."&nbsp;Mbytes&nbsp;<span id='squid-size-vals'></span></td>
			<td>" . help_icon('{cache_size_text}',false,'squid.index.php')."</td>
		</tr>		

		<tr>
			<td class=legend nowrap style='font-size:16px'>{cache_dir_level1}:</td>
			<td>" . Field_text('cache_dir_level1',$s->cache_list[$cache]["cache_dir_level1"],'width:50px;font-size:16px;padding:3px')."</td>
			<td>" . help_icon('{cache_dir_level1_text}',false,'squid.index.php')."</td>
		</tr>			
		<tr>
			<td class=legend nowrap style='font-size:16px'>{cache_dir_level2}:</td>
			<td>" . Field_text('cache_dir_level2',$s->cache_list[$cache]["cache_dir_level2"],'width:50px;font-size:16px;padding:3px')."</td>
			<td>" . help_icon('{cache_dir_level2_text}',false,'squid.index.php')."</td>
		</tr>
		<tr>
			<td class=legend nowrap style='font-size:16px'>{max_objects_size}:</td>
			<td  style='font-size:16px'>" . Field_text('cache_maxsize',$s->cache_list[$cache]["cache_maxsize"],'width:50px;font-size:16px;padding:3px',null,"calculateSize()",null,false,null)."&nbsp;Mbytes&nbsp;<span id='squid-maxsize-vals'></span></td>
			<td>" . help_icon('{squid_rock_maxsize}',false,'squid.index.php')."</td>
		</tr>
		
		<tr>
		<td align='right' colspan=3><hr>". button('{apply}','AddNewCacheSave()',14)."</td>
		</tr>
	</table>
	<script>
	
	var x_AddNewCacheSave= function (obj) {
			var results=obj.responseText;
			if(results.length>0){
				alert(results);
				document.getElementById('waitcache').innerHTML='';
				}
			RefreshCaches();
			YahooWinHide();
		}		
	
	function AddNewCacheSave(){
		var XHR = new XHRConnection();
		XHR.appendData('cache_directory',document.getElementById('cache_directory').value);
		XHR.appendData('cache_type',document.getElementById('cache_type').value);
		XHR.appendData('size',document.getElementById('squid-cache-size').value);
		XHR.appendData('cache_dir_level1',document.getElementById('cache_dir_level1').value);
		XHR.appendData('cache_dir_level2',document.getElementById('cache_dir_level2').value);
		XHR.appendData('cache_maxsize',document.getElementById('cache_maxsize').value);
		$main_add
		AnimateDiv('waitcache');
		XHR.sendAndLoad('$page', 'GET',x_AddNewCacheSave);
		}
		
		function HideLevels(){
			document.getElementById('cache_dir_level1').disabled=true;
			document.getElementById('cache_dir_level2').disabled=true;
			document.getElementById('cache_maxsize').disabled=false;
		}
		
		function Showlevels(){
			document.getElementById('cache_dir_level1').disabled=false;
			document.getElementById('cache_dir_level2').disabled=false;
			document.getElementById('cache_maxsize').disabled=true;
		}
				
		
		function CheckCachesTypes(){
			Showlevels();
			cachetypes=document.getElementById('cache_type').value;
			if(cachetypes=='rock'){
				HideLevels();
			}
		
		}
		
		function calculateSize(e){
			LoadAjaxTiny('squid-maxsize-vals','$page?calculate-mb-size='+document.getElementById('cache_maxsize').value);
			LoadAjaxTiny('squid-size-vals','$page?calculate-mb-size='+document.getElementById('squid-cache-size').value);
			return true;
		}
		
		
		$main_load
		CheckCachesTypes();
		calculateSize();
	</script>
	
	
	";
	echo $tpl->_ENGINE_parse_body($html,'squid.index.php');
	
}

function calculate_mb_size(){
	$size=$_GET["calculate-mb-size"];
	if($size<1024){return;}
	$size=$size*1024;
	echo "(".FormatBytes($size).")";
	
}

function cache_save(){
if($_GET["cache_directory"]==null){echo "False:cache directory is null\n";exit;}

$squid=new squidbee();
if(isset($_GET["main-is-cache"])){
	$squid->CACHE_PATH=$_GET["cache_directory"];
	$squid->CACHE_SIZE=$_GET["size"];
	$squid->CACHE_TYPE=$_GET["cache_type"];

	
}else{
	$squid->cache_list[$_GET["cache_directory"]]=array(
	"cache_type"=>$_GET["cache_type"],
	"cache_dir_level1"=>$_GET["cache_dir_level1"],
	"cache_dir_level2"=>$_GET["cache_dir_level2"],
	"cache_size"=>$_GET["size"],
	"cache_maxsize"=>$_GET["cache_maxsize"]
	);
}
$sock=new sockets();
$_GET["OP"]="{apply}/{add}";
$SquidCacheTasks=unserialize(base64_decode($sock->GET_INFO("SquidCacheTask")));
$SquidCacheTasks[$_GET["cache_directory"]]=$_GET;
$sock->SaveConfigFile(base64_encode(serialize($SquidCacheTasks)),"SquidCacheTask");
$squid->SaveToLdap(true);
$squid->SaveToServer(true);
$sock->getFrameWork("cmd.php?squid-build-caches=yes");

}


function caches_main(){
	$page=CurrentPageName();
	$tpl=new templates();	
	$reconstruct_caches_explain=$tpl->javascript_parse_text("{reconstruct_caches_explain}");
	$add_cache=$tpl->_ENGINE_parse_body("{APP_SQUID}");
	
	$html="
		<table style='width:100%'>
		<tr>
			<td align='center' valign='middle' style='padding:0px;margin:0px'>". imgtootltip("cache-rebuild-48.png","{rebuild_squid_caches}","RebduildCaches();")."</td>
			<td align='center' valign='middle' style='padding:0px;margin:0px'>". imgtootltip("cache-refresh-48.png","{refresh}","RefreshCachesList();")."</td>
			<td align='center' valign='middle' style='padding:0px;margin:0px'>". imgtootltip("database-48-add.png","{add_cache_dir}","AddCache('');")."</td>
			<td align='center' valign='middle' style='padding:0px;margin:0px'>". imgtootltip("caches-rebuild-48.png","{reconstruct_caches}","ReConstructCaches();")."</td>
			
			
			
		</tr>		
		</table>	
	
	
	<div id='squid-main-caches-list'></div>
	
	
	
	<script>
		function RefreshCaches(){RefreshCachesList();}
	
	
		function RefreshCachesList(){
			LoadAjax('squid-main-caches-list','$page?caches-list=yes');
		
		}
		
	function RebduildCaches(){
		var XHR = new XHRConnection();
		XHR.appendData('RebduildCaches','yes');
		AnimateDiv('squid-main-caches-list');
		XHR.sendAndLoad('$page', 'GET',x_DeleteCache);
	}

	function ReConstructCaches(){
		if(confirm('$reconstruct_caches_explain')){
			var XHR = new XHRConnection();
			XHR.appendData('ReConstructCaches','yes');
			AnimateDiv('squid-main-caches-list');
			XHR.sendAndLoad('$page', 'GET',x_DeleteCache);
		}
	}	

var x_DeleteCache= function (obj) {
	var tempvalue=obj.responseText;
	if(tempvalue.length>3){alert(tempvalue)};
   	RefreshCachesList();
	}	
	
	function AddCache(folder){
		YahooWin(690,'$page?add-cache=yes&cache='+folder,'$add_cache:'+folder);
		}	

	
function DeleteCache(folder){
	    if(folder.length<5){return;}
		var XHR = new XHRConnection();
		XHR.appendData('DeleteCache',folder);
		AnimateDiv('squid-main-caches-list');
		XHR.sendAndLoad('$page', 'GET',x_DeleteCache);
}	
		
		
	RefreshCachesList();
	</script>
	";
	echo $tpl->_ENGINE_parse_body($html);
	
}

function cache_reconstruct(){
	$sock=new sockets();
	$sock->getFrameWork("cmd.php?squid-reconstruct-caches=yes");
	
}

function cache_delete(){
	$_GET["OP"]="{delete}";
	$squid=new squidbee();
	unset($squid->cache_list[$_GET["DeleteCache"]]);
	$squid->SaveToLdap();
	$squid->SaveToServer();
	$sock=new sockets();
	
	$SquidCacheTasks=unserialize(base64_decode($sock->GET_INFO("SquidCacheTask")));
	$SquidCacheTasks[$_GET["DeleteCache"]]=$_GET;
	$sock->SaveConfigFile(base64_encode(serialize($SquidCacheTasks)),"SquidCacheTask");	
	$sock->getFrameWork("cmd.php?squid-build-caches=yes");
	
}

function cache_rebuild(){
	$_GET["OP"]="{rebuild_caches}";
	$sock=new sockets();
	$SquidCacheTasks=unserialize(base64_decode($sock->GET_INFO("SquidCacheTask")));
	$SquidCacheTasks["{all_caches}"]=$_GET;
	$sock->SaveConfigFile(base64_encode(serialize($SquidCacheTasks)),"SquidCacheTask");
	$sock->getFrameWork("cmd.php?squid-build-caches=yes");
	
}

function main_save_array(){
	$squid=new squidbee();
	
	if(isset($_GET["cache_size"])){
		$squid->CACHE_SIZE=$_GET["cache_size"];
		unset($_GET["cache_size"]);
	}
	if(isset($_GET["cache_type"])){
		$squid->CACHE_TYPE=$_GET["cache_type"];
		unset($_GET["cache_type"]);
	}
	
	
	while (list ($num, $val) = each ($_GET) ){
		$squid->global_conf_array[$num]=$val;
	}
	$squid->SaveToLdap();
}
