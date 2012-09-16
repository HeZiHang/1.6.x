<?php
	include_once('ressources/class.templates.inc');
	include_once('ressources/class.ldap.inc');
	include_once('ressources/class.users.menus.inc');
	
	
$usersmenus=new usersMenus();
if(!$usersmenus->AsPostfixAdministrator){
	$tpl=new templates();
	$alert=$tpl->_ENGINE_parse_body('{ERROR_NO_PRIVS}');
	echo "alert('$alert');";
	die();	
}

if(function_exists($_GET["function"])){call_user_func($_GET["function"]);exit;}
if(isset($_GET["js"])){js();exit;}
if(isset($_GET["start"])){start();exit;}


function js(){
	$page=CurrentPageName();
$html="	
function PostfixQuickLinks(){
	var z = $('#middle').css('display');
	if(z!=='none'){
		$('#middle').slideUp('normal');
		$('#middle').html('');
		$('#quick-links').html('');
		$('#middle').slideDown({
			duration:900,
			easing:'easeOutExpo',
			complete:function(){
				PostfixQuickLinksMainLoad();
				}
			});
		}
	
}
function PostfixQuickLinksMainLoad(){
	LoadAjax('middle','$page?start=yes');
}	
PostfixQuickLinks();
";
echo $html;
	
}

function start(){
	
	
	
$page=CurrentPageName();
$tpl=new templates();
$sock=new sockets();
$users=new usersMenus();
$EnablePostfixMultiInstance=$sock->GET_INFO("EnablePostfixMultiInstance");
$InnoDBFilePerTableAsk=$sock->GET_INFO("InnoDBFilePerTableAsk");
if(!is_numeric($EnablePostfixMultiInstance)){$EnablePostfixMultiInstance=0;}
if(!is_numeric($InnoDBFilePerTableAsk)){$InnoDBFilePerTableAsk=0;}

if(!$users->INNODB_FILE_PER_TABLE_INSTALL){
	if($users->ZARAFA_INSTALLED){
		if($InnoDBFilePerTableAsk==0){
			if(innodb_file_per_table_checks()){return;}
		}
	}
}

$zarafa=$tpl->_ENGINE_parse_body(quicklinks_paragraphe("zarafa-logo-48.png", "APP_ZARAFA",null, "QuickLinkSystems('section_zarafa')"));
$postfix=$tpl->_ENGINE_parse_body(quicklinks_paragraphe("mass-mailing-postfix-48.png", "APP_POSTFIX",null, "QuickLinkSystems('section_postfix')"));
$postfix_multiple=$tpl->_ENGINE_parse_body(quicklinks_paragraphe("postfix-multi-48.png", "multiple_instances",null, "QuickLinkPostfixMulti()"));
$cyrus=$tpl->_ENGINE_parse_body(quicklinks_paragraphe("48-mailbox.png", "mailboxes",null, "QuickLinkCyrus()"));
if(!$users->ZARAFA_INSTALLED){$zarafa=null;}
if($EnablePostfixMultiInstance==0){$postfix_multiple=null;}

if(!$users->cyrus_imapd_installed){$cyrus=null;}

$tr[]=$zarafa;
$tr[]=$cyrus;
$tr[]=$postfix;
$tr[]=$postfix_multiple;
$tr[]=$tpl->_ENGINE_parse_body(quicklinks_paragraphe("48-bouclier.png", "security","", "QuickLinkSystems('section_security')"));
$tr[]=$tpl->_ENGINE_parse_body(quicklinks_paragraphe("folder-queue-48.png", "queue_management","", "QuickLinkSystems('section_queue')"));
$tr[]=$tpl->_ENGINE_parse_body(quicklinks_paragraphe("48-categories-white.png", "white list","", "QuickLinkSystems('section_whitelist')"));



$tr[]=$tpl->_ENGINE_parse_body(quicklinks_paragraphe("web-site-48.png", "main_interface","main_interface_back_interface_text", "QuickLinksHide()"));

$count=1;
while (list ($key, $line) = each ($tr) ){
	if($line==null){continue;}
	$f[]="<li id='kwick1'>$line</li>";
	$count++;
	
}

while (list ($key, $line) = each ($GLOBALS["QUICKLINKS-ITEMS"]) ){
	
	$jsitems[]="\tif(document.getElementById('$line')){document.getElementById('$line').className='QuickLinkTable';}";
}


	$html="
            <div id='QuickLinksTop'>
                <ul class='kwicks'>
					".@implode("\n", $f)."
                    
                </ul>
            </div>
	
	<div id='BodyContent' style='width:900px'></div>
	
	
	<script>
		function LoadQuickTaskBar(){
			$(document).ready(function() {
				$('#QuickLinksTop .kwicks').kwicks({max: 205,spacing:  5});
			});
		}
		
		function QuickLinkPostfixMulti(){
			Loadjs('quicklinks.postfix.multiple.php?js=yes');
		
		}		
		
	
		function QuickLinkSystems(sfunction){
			Set_Cookie('QuickLinkCachePostfix', '$page?function='+sfunction, '3600', '/', '', '');
			LoadAjax('BodyContent','$page?function='+sfunction);
		}
		
		function QuickLinkMemory(){
			var memorized=Get_Cookie('QuickLinkCachePostfix');
			if(memorized=='section_instances'){QuickLinkSystems('section_postfix');return;}
			if(!memorized){QuickLinkSystems('section_postfix');return;}
			if(memorized.length>0){LoadAjax('BodyContent',memorized);}else{QuickLinkSystems('section_mynic');}
		
		}
		
		function QuickLinkShow(id){
			".@implode("\n", $jsitems)."
			if(document.getElementById(id)){document.getElementById(id).className='QuickLinkOverTable';}
			}			
		
		LoadQuickTaskBar();
		QuickLinkMemory();
	</script>
	";
$tpl=new templates();
echo $tpl->_ENGINE_parse_body($html);	
	
}

function section_zarafa(){echo "<script>AnimateDiv('BodyContent');Loadjs('zarafa.index.php?font-size=14');</script>";}
function section_postfix(){echo "<script>AnimateDiv('BodyContent');Loadjs('postfix.index.php?font-size=14')</script>";}
function section_security(){echo "<script>AnimateDiv('BodyContent');Loadjs('postfix.security.php?font-size=14')";}
function section_whitelist(){echo "<script>AnimateDiv('BodyContent');Loadjs('whitelists.admin.php?js=yes&js-in-line=yes&font-size=14');QuickLinkShow('quicklinks-white list');";}
function section_queue(){echo "<script>AnimateDiv('BodyContent');Loadjs('postfix.queue.monitoring.php?inline-js=yes&font-size=14')";}

function innodb_file_per_table_checks(){
	$q=new mysql();
	$array=$q->SHOW_VARIABLES();
	if($array["innodb_file_per_table"]=="ON"){
		$sock=new sockets();
		$sock->SET_INFO("InnoDBFilePerTableAsk",1);
		return false;
	}
	$t=time();
	echo "<div id='$t'></div>
	<script>LoadAjax('$t','mysql.innodb.file.per.table.php');</script>
	
	";
	return true;
}

