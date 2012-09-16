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
function PostfixQuickLinksMultiple(){
	var z = $('#middle').css('display');
	if(z!=='none'){
		$('#middle').slideUp('normal');
		$('#middle').html('');
		$('#quick-links').html('');
		$('#middle').slideDown({
			duration:900,
			easing:'easeOutExpo',
			complete:function(){
				PostfixQuickLinksMainMultipleLoad();
				}
			});
		}
	
}
function PostfixQuickLinksMainMultipleLoad(){
	LoadAjax('middle','$page?start=yes');
}	
PostfixQuickLinksMultiple();
";
echo $html;
	
}



function start(){
	
$page=CurrentPageName();
$tpl=new templates();
$sock=new sockets();
$users=new usersMenus();
$tr[]=$tpl->_ENGINE_parse_body(quicklinks_paragraphe("postfix-multi-48.png", "instances",null, "QuickLinkSystemsM('section_instances')"));
$tr[]=$tpl->_ENGINE_parse_body(quicklinks_paragraphe("mass-mailing-postfix-48.png", "APP_POSTFIX",null, "QuickLinkPostfix()"));
$tr[]=$tpl->_ENGINE_parse_body(quicklinks_paragraphe("48-bouclier.png", "security","", "QuickLinkSystems('section_security')"));
$tr[]=$tpl->_ENGINE_parse_body(quicklinks_paragraphe("folder-queue-48.png", "queue_management","", "QuickLinkSystems('section_queue')"));
$tr[]=$tpl->_ENGINE_parse_body(quicklinks_paragraphe("web-site-48.png", "main_interface","main_interface_back_interface_text", "QuickLinksHide()"));

$count=1;
while (list ($key, $line) = each ($tr) ){
	if($line==null){continue;}
	$f[]="<li id='kwick1'>$line</li>";
	$count++;
	
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
		
		function QuickLinkPostfix(){
			Loadjs('quicklinks.postfix.php?js=yes');		
		}		
		
	
		function QuickLinkSystemsM(sfunction){
			Set_Cookie('QuickLinkCachePostfixM', '$page?function='+sfunction, '3600', '/', '', '');
			LoadAjax('BodyContent','$page?function='+sfunction);
		}
		
		function QuickLinkMemory(){
			var memorized=Get_Cookie('QuickLinkCachePostfixM');
			if(!memorized){QuickLinkSystemsM('section_instances');return;}
			if(memorized.length>0){LoadAjax('BodyContent',memorized);}else{QuickLinkSystemsM('section_instances');}
		
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
function section_whitelist(){echo "<script>AnimateDiv('BodyContent');Loadjs('whitelists.admin.php?js=yes&js-in-line=yes&font-size=14')";}
function section_queue(){echo "<script>AnimateDiv('BodyContent');Loadjs('postfix.queue.monitoring.php?inline-js=yes&font-size=14')";}
function section_instances(){echo "<script>AnimateDiv('BodyContent');javascript:Loadjs('postfix.multiples.php?font-size=14')";}

