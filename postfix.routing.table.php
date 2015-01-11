<?php
	include_once('ressources/class.templates.inc');
	include_once('ressources/class.ldap.inc');
	include_once('ressources/class.users.menus.inc');
	include_once('ressources/class.main_cf.inc');
	include_once('ressources/class.maincf.multi.inc');
	if(isset($_GET["verbose"])){$GLOBALS["VERBOSE"]=true;ini_set('display_errors', 1);ini_set('error_reporting', E_ALL);ini_set('error_prepend_string',null);ini_set('error_append_string',null);}
	
$usersmenus=new usersMenus();
if(!$usersmenus->AsPostfixAdministrator){
	$tpl=new templates();
	echo "alert('".$tpl->javascript_parse_text("{ERROR_NO_PRIVS}")."');";
	die();
	}	
	
	
if(isset($_GET["buttons"])){echo popup_index();exit;}
if(isset($_GET["transport-table"])){routingTable(1);exit;}
if(isset($_GET["local-domain-table"])){LocalTable(1);exit;}
if(isset($_GET["relay-domain-table"])){RelayDomainsTable(1);exit;}
if(isset($_GET["relay-recipient-table"])){RelayRecipientsTable(1);exit;}


if(isset($_GET["artica-sender-table-list"])){ArticaSyncTable_list();exit();}


	
if(isset($_GET["PostfixAddRoutingRuleTableSave"])){PostfixAddRoutingRuleTableSave();exit;}
if(isset($_GET["PostfixAddRoutingTable"])){PostfixAddRoutingRuleTable();exit();}
if(isset($_GET["PostfixAddRoutingTableSave"])){PostfixAddRoutingTableSave();exit;}
if(isset($_GET["PostfixAddRoutingLoadTable"])){echo routingTable();exit;}
if(isset($_GET["LoadRelayDomainsTable"])){echo RelayDomainsTable();exit;}
if(isset($_GET["PostFixDeleteRoutingTable"])){PostFixDeleteRoutingTable();exit;}

if(isset($_GET["relayhost"])){relayhost_tabs();exit;}
if(isset($_GET["relayhost-popup"])){relayhost();exit;}
if(isset($_GET["relayhost-sasl-auth"])){relayhost_sasl_auth();exit;}
if(isset($_GET["relayhost-sasl-config"])){relayhost_sasl_config();exit;}
if(isset($_POST["relayhostSave"])){relayhostSave();exit;}
if(isset($_GET["noanonymous"])){smtp_sasl_security_options_save();exit;}


if(isset($_GET["RelayHostDelete"])){RelayHostDelete();exit;}
if(isset($_GET["PostfixLocalLoadTable"])){echo LocalTable();exit;}
if(isset($_GET["PostfixSenderLoadTable"])){echo SenderTableLoad();exit;}

if(isset($_GET["SenderTable"])){SenderTable();exit();}
if(isset($_GET["SenderTableSave"])){SenderTableSave();exit;}
if(isset($_GET["SenderTableDelete-js"])){SenderTable_js();exit;}

if(isset($_GET["SenderTableDelete"])){SenderTableDelete();exit;}

if(isset($_GET["PostfixDeleteRelayDomain"])){PostfixDeleteRelayDomain();exit;}
if(isset($_GET["PostfixAddRelayTable"])){PostfixAddRelayTable();exit;}

if(isset($_GET["PostfixDeleteRelayRecipient"])){PostfixDeleteRelayRecipient();exit;}
if(isset($_GET["PostfixRefreshRelayRecipient"])){echo RelayRecipientsTable();exit;}
if(isset($_GET["PostfixAddRelayRecipientTable"])){echo PostfixAddRelayRecipientTable();exit;}
if(isset($_GET["PostfixAddRelayRecipientTableSave"])){PostfixAddRelayRecipientTableSave();exit;}
if(isset($_GET["ArticaSyncTableDelete"])){ArticaSyncTableDelete();exit;}


if(isset($_GET["js"])){js();exit;}
if(isset($_GET["popup"])){popup();exit;}
MainRouting();


function relayhost_tabs(){
	
	
	$page=CurrentPageName();
	
	$array["relayhost-popup"]='{config}';
	$array["relayhost-sasl"]="{SASL_STATUS}";
	$array["relayhost-sasl-auth"]="{usable_mechanisms}";
	$array["relayhost-sasl-config"]="{security_options}";
	while (list ($num, $ligne) = each ($array) ){
		if($num=="relayhost-sasl"){
			$tab[]="<li><a href=\"postfix.index.php?popup-auth-status=yes\"><span>$ligne</span></a></li>\n";
			continue;
		}
		$tab[]="<li><a href=\"$page?$num=yes\"><span>$ligne</span></a></li>\n";
			
		}
	$tpl=new templates();
	
	$html="
		<div id='main_relayhost_config' style='background-color:white'>
		<ul>
		". implode("\n",$tab). "
		</ul>
	</div>
		<script>
				$(document).ready(function(){
					$('#main_relayhost_config').tabs({
				    load: function(event, ui) {
				        $('a', ui.panel).click(function() {
				            $(ui.panel).load(this.href);
				            return false;
				        });
				    }
				});
			

			});
		</script>
	
	";
		
	$tpl=new templates();
	$html=$tpl->_ENGINE_parse_body($html);
	
echo $html;	
	
	
}

function smtp_sasl_security_options_save(){
	$main=new maincf_multi("master","master");
	$main->SET_BIGDATA("smtp_sasl_security_options",serialize($_GET));
	$sock=new sockets();
	$sock->getFrameWork("cmd.php?postfix-smtp-sasl=yes");
	}

function relayhost_sasl_config(){
	$page=CurrentPageName();
	$tpl=new templates();
	$main=new maincf_multi("master","master");
	$datas=unserialize($main->GET_BIGDATA("smtp_sasl_security_options"));
	
	if($datas["noanonymous"]==null){$datas["noanonymous"]=1;}
	
	
	
	$html="
	<div id='smtp_sasl_security_options_div'>
	<div class=text-info>{smtp_sasl_security_options_text}</div>
	<table style='width:99%' class=form>
	<tr>
		<td class=legend>{smtp_sasl_security_options_noanonymous}</td>
		<td>". Field_checkbox("noanonymous",1,$datas["noanonymous"])."</td>
	</tr>
	<tr>
		<td class=legend>{smtp_sasl_security_options_noplaintext}</td>
		<td>". Field_checkbox("noplaintext",1,$datas["noplaintext"])."</td>
	</tr>	
	<tr>
		<td class=legend>{smtp_sasl_security_options_nodictionary}</td>
		<td>". Field_checkbox("nodictionary",1,$datas["nodictionary"])."</td>
	</tr>			
	<tr>
		<td class=legend>{smtp_sasl_security_options_nodictionary}</td>
		<td>". Field_checkbox("mutual_auth",1,$datas["mutual_auth"])."</td>
	</tr>			
	<tr>
		<td align='right'><hr>". button("{apply}","smtp_sasl_security_options_save()")."</td>
	</tr>
	</table>
	</div>
	<script>
	var X_smtp_sasl_security_options_save= function (obj) {
			RefreshTab('main_relayhost_config');
		}	
	
		function smtp_sasl_security_options_save(){
			var XHR=XHRParseElements('smtp_sasl_security_options_div');
			document.getElementById('smtp_sasl_security_options_div').innerHTML='<center style=\"margin:20px;padding:20px\"><img src=\"img/wait_verybig.gif\"></center>';
			XHR.sendAndLoad('$page', 'GET',X_smtp_sasl_security_options_save);
		}
	
	</script>
	
	";
	
	echo $tpl->_ENGINE_parse_body($html);	
}


function relayhost_sasl_auth(){
	$sock=new sockets();
	$tbl=unserialize(base64_decode($sock->getFrameWork("cmd.php?pluginviewer=yes")));
	
while (list ($num, $ligne) = each ($tbl)){
		if(trim($ligne)==null){continue;}
		$ligne=str_replace(" ","&nbsp;",$ligne);
		$ligne=str_replace("\t","<span style='padding-left:40px;'>&nbsp;</span>",$ligne);
		$t=$t."<div><code>$ligne</code></div>\n";
		
	}
	
	
	$html="
	<div style='width:100%;height:300px;overflow:auto'>$t</div>";
	
	$tpl=new templates();
	echo $tpl->_ENGINE_parse_body($html);	
}


function js(){
	
$tpl=new templates();
$title=$tpl->_ENGINE_parse_body('{transport_table}');	
$include=file_get_contents("js/postfix-transport.js");
$page=CurrentPageName();
$html="
	$include
	function LoadPostfixRountingTable(){
		YahooWinS(889,'$page?popup=yes','$title');
	
	}
	
var X_PostFixDeleteRoutingTable= function (obj) {
	$('#container-tabs').tabs( 'load' , 1 );
	}

var X_PostfixDeleteRelayDomain= function (obj) {
	$('#container-tabs').tabs( 'load' , 3 );
	}	
var X_PostfixDeleteRelayRecipient= function (obj) {
	$('#container-tabs').tabs( 'load' , 4 );
	}	
	
var X_SenderTableDelete= function (obj) {
	$('#container-tabs').tabs( 'load' , 5 );
	}

	

	
function PostFixDeleteRoutingTable(Routingdomain){
			var XHR = new XHRConnection();
			XHR.appendData('PostFixDeleteRoutingTable',Routingdomain);
			document.getElementById('routing-table').innerHTML='<center style=\"margin:20px;padding:20px\"><img src=\"img/wait_verybig.gif\"></center>';
			XHR.sendAndLoad('$page', 'GET',X_PostFixDeleteRoutingTable);	
		}

function PostfixDeleteRelayDomain(DomainToDelete){
		var XHR = new XHRConnection();
		XHR.appendData('PostfixDeleteRelayDomain',DomainToDelete);
		document.getElementById('routing-table').innerHTML='<center style=\"margin:20px;padding:20px\"><img src=\"img/wait_verybig.gif\"></center>';
		XHR.sendAndLoad('$page', 'GET',X_PostfixDeleteRelayDomain);	
		}	
		
function SenderTableDelete(Routingdomain){
		var XHR = new XHRConnection();
		XHR.appendData('SenderTableDelete',Routingdomain);
		document.getElementById('routing-table').innerHTML='<center style=\"margin:20px;padding:20px\"><img src=\"img/wait_verybig.gif\"></center>';
		XHR.sendAndLoad('$page', 'GET',X_SenderTableDelete);
		}
		

	
var X_PostfixAddNewSenderTable= function (obj) {
		var results=obj.responseText;
		if (results.length>0){alert(results);}
		$('#container-tabs').tabs( 'load' , 5 );
		YahooWinHide();
	}		
function PostfixAddNewSenderTable(){
		var XHR = new XHRConnection();
		XHR.appendData('SenderTableSave','yes');
		XHR.appendData('email',document.getElementById('email').value);
		XHR.appendData('domain',document.getElementById('domain').value);
		XHR.appendData('relay_address',document.getElementById('relay_address').value);
		XHR.appendData('MX_lookups',document.getElementById('MX_lookups').value);
		XHR.sendAndLoad('$page', 'GET',X_PostfixAddNewSenderTable);
		
	}

	

		
	
	LoadPostfixRountingTable();
	
";
	
	echo $html;
}

function popup(){
	
	echo MainRouting(1);
	
}


function popup_index(){
	
	
	
$add_routing_rule=Paragraphe("routing-rule.png","{add_routing_rule}","{add_routing_rule}","javascript:PostfixAddRoutingRuleTable()");	
$add_global_routing_rule=Paragraphe("relayhost.png","{add_global_routing_rule}","{add_global_routing_rule}","javascript:relayhost()");
$add_routing_relay_domain_rule=Paragraphe("routing-domain-relay.png","{add_routing_relay_domain_rule}","{add_routing_relay_domain_rule}","javascript:PostfixAddRelayTable()");

$add_sender_routing_rule=Paragraphe("sender-relay-table.png","{add_sender_routing_rule}","{add_sender_routing_rule}","javascript:SenderTable()");
$sync_artica=Paragraphe("sync-64.png","{smtp_sync_artica}","{smtp_sync_artica_text}","javascript:Loadjs('postfix.artica.smtp-sync.php')");




	$html="<table style='width:100%'>
			<tr>
				<td valign='top'><img src='img/bg_routing-250.png'></td>
				<td valign='top'><div class=text-info>{transport_table_explain}</div></td>
			</tr>
			<tr>
			<td colspan=2>
				<table style='width:100%'>
				<tr>
					<td valign='top'>$add_routing_rule</td>
					<td valign='top'>$add_global_routing_rule</td>
					<td valign='top'>$add_routing_relay_domain_rule</td>
				</tr>
				<tr>
					<td valign='top'>$add_routing_relay_recipient_rule</td>
					<td valign='top'>$add_sender_routing_rule</td>
					<td valign='top'>$sync_artica</td>
				</tr>								
				</table>
		</table>";
	$tpl=new templates();
	echo $tpl->_ENGINE_parse_body($html);	
		
}


function MainRouting($return=0){
$page=CurrentPageName();
$users=new usersMenus();
if($users->cyrus_imapd_installed){
	$local=" <li><a href=\"$page?local-domain-table=yes\"><span>{local_domains_table}</span></a></li>";	
}

$tabbarr="
<div id='container-tabs' style='width:99%;background-color:white'>
			<ul>
			<li><a href=\"$page?buttons=yes\"><span>{index}</span></a></li>
            <li><a href=\"$page?transport-table=yes\"><span>{transport_table}</span></a></li>
           	$local
			<li><a href=\"$page?relay-domain-table=yes\"><span>{relay_domains_table}</span></a></li>
			<li><a href=\"$page?relay-recipient-table=yes\"><span>{routing_relay_recipient2}</span></a></li>
			<li><a href=\"$page?relay-sender-table=yes\"><span>{sender_dependent_relayhost_maps_title2}</span></a></li>
			
			
			
			</ul>
		</div>
				<script>
				$(document).ready(function(){
					$('#container-tabs').tabs({
						load: function(event, ui) {\$('a', ui.panel).click(function() {\$(ui.panel).load(this.href);return false;});}
					});
				
				$('#container-tabs').tabs({ spinner: '{loading}' });

			});</script>		

";
			$tpl=new templates();
			echo $tpl->_ENGINE_parse_body($tabbarr);
			exit;

$rightbarr="
<div style='text-align:center'>" . RoundedLightWhite("

<table style='width:100%'>

<tr " . CellRollOver("PostfixAddRoutingRuleTable()").">
<td valign='top'>" . imgtootltip('routing-rule.png','{add_routing_rule}',"blur()")."</td>
<td valign='top'><h3 style='font-size:14px'>{add_routing_rule}</h3></td>
</tr>
<tr><td colspan=2><hr></td></tr>
<tr " . CellRollOver("relayhost()").">
<td valign='top'>" . imgtootltip('relayhost.png','{add_global_routing_rule}',"blur()")."</td>
<td valign='top'><h3 style='font-size:14px'>{add_global_routing_rule}</h3></td>
</tr>
<tr><td colspan=2><hr></td></tr>
<tr " . CellRollOver("PostfixAddRelayTable()").">
<td valign='top'>" . imgtootltip('routing-domain-relay.png','{add_routing_relay_domain_rule}',"blur()")."</td>
<td valign='top'><h3 style='font-size:14px'>{add_routing_relay_domain_rule}</h3></td>
</tr>
<tr><td colspan=2><hr></td></tr>
<tr " . CellRollOver("PostfixAddRelayRecipientTable()").">
<td valign='top'>" . imgtootltip('acl-add-64.png','{add_routing_relay_recipient_rule}',"blur()")."</td>
<td valign='top'><h3 style='font-size:14px'>{add_routing_relay_recipient_rule}</h3></td>
</tr>
<tr><td colspan=2><hr></td></tr>
<tr " . CellRollOver("SenderTable()").">
<td valign='top'>" . imgtootltip('sender-relay-table.png','{add_sender_routing_rule}',"blur()")."</td>
<td valign='top'><h3 style='font-size:14px'>{add_sender_routing_rule}</h3></td>
</tr>
</table>")."
</div>";	
	

$sender_table_title="
<table style='width:100%'>
<tr  ". CellRollOver("RtableExCol('sender_table')").">
<td width=1%><img src='img/link_a1.gif' id='img_sender_table'></td>
	<td style='text-align:left;font-size:14px;font-weight:bold'>{sender_dependent_relayhost_maps_title}</td>
</tr>
</table>
";

$routing_table_title="
<table style='width:100%'>
<tr  ". CellRollOver("RtableExCol('routing_table')").">
<td width=1%><img src='img/link_a1.gif' id='img_routing_table'></td>
	<td style='text-align:left;font-size:14px;font-weight:bold;overflow:auto;'>{transport_table}</td>
</tr>
</table>";


$local_domains_table_title="
<table style='width:100%'>
<tr  ". CellRollOver("RtableExCol('local_table')").">
<td width=1%><img src='img/link_a2.gif'  id='img_local_table'></td>
	<td style='text-align:left;font-size:14px;font-weight:bold;overflow:auto;'>{local_domains_table}</td>
</tr>
</table>";


$relay_domains_title="
<table style='width:100%'>
<tr  ". CellRollOver("RtableExCol('relay_domains')").">
<td width=1%><img src='img/link_a1.gif'  id='img_relay_domains'></td>
	<td style='text-align:left;font-size:14px;font-weight:bold'>{relay_domains_table}</td>
</tr>
</table>";

$relay_recipient_title="
<table style='width:100%'>

<tr  ". CellRollOver("RtableExCol('relay_recipient')").">
	<td width=1%><img src='img/link_a1.gif'  id='img_relay_recipient'></td>
	<td style='text-align:left;font-size:14px;font-weight:bold'>{routing_relay_recipient}</td>
</tr>
</table>";


$maintable="
<table width=100%'>
<tr>
<td valign='top'>


$sender_table_title
	<div id='sender_table' style='padding:5px;width:0px;height:0px;visibility:hidden;overflow:auto;'>
		".SenderTableLoad() . "
	</div>

$routing_table_title
	<div id='routing_table' style='margin:5px;width:0px;height:0px;visibility:hidden;;overflow:auto;'>
		".routingTable() . "
	</div>

$local_domains_table_title
	<div id='local_table' style='margin:5px;width:490px;overflow:auto;'>".LocalTable() . "</div>


$relay_domains_title
	<div id='relay_domains' style='margin:5px;width:0px;height:0px;visibility:hidden;overflow:auto;'>".RelayDomainsTable() . "</div>

$relay_recipient_title
	<div id='relay_recipient' style='margin:5px;width:0px;height:0px;visibility:hidden;overflow:auto;'>
		".RelayRecipientsTable() . "
	</div>
</center>
</td>
<td valign='top'>
</td>
</tr>
</table>";

	
$html="
<table style='width:100%'>
<td valign='top'>
		<table style='width:100%'>
			<tr>
				<td valign='top'><img src='img/bg_routing-250.png'></td>
				<td valign='top'><p class=caption>{transport_table_explain}</p></td>
			</tr>
		</table>" . RoundedLightWhite($maintable)."
</td>
<td valign='top'>
	$rightbarr
</td>
</tr>
</table>";



if($return==1){
	$tpl=new templates();
	return $tpl->_ENGINE_parse_body($html);
}


$cfg ["JS"][]='js/postfix-transport.js';
$tpl=new template_users('{transport_table}',$html,0,0,0,0,$cfg);
echo $tpl->web_page;
}


function SenderTableLoad_old($echo=1){
$page=CurrentPageName();	
$style="style='border-bottom:2px dotted #8E8785;'";

$html="
<div style='text-align:right;margin:5px;margin-top:0px'>". button("{add_sender_routing_rule}","SenderTable()")."</div>
<table style='width:99%;padding:5px;border:1px dotted #8E8785;' align='center' class=form>
	<tr style='background-color:#CCCCCC'>
		<th>&nbsp;</th>
		<th><strong nowrap>{domain}</strong></th>
		<th><strong nowrap>&nbsp;</strong></td>
		<th align='center' nowrap><strong>{service}</strong></th>
		<th nowrap><strong>{relay}</strong></th>
		<th align='center' nowrap><strong>{port}</strong></th>
		<th align='center' nowrap><strong>{MX_lookups}</strong></th>
		<th>&nbsp;</td>
	</tr>";	

	$main=new main_cf();
	if($main->main_array["relayhost"]<>null){
		$tools=new DomainsTools();
		$main->main_array["relayhost"]="smtp:".$main->main_array["relayhost"];
		$relayT=$tools->transport_maps_explode($main->main_array["relayhost"]);
		$html=$html . "<tr>	
		<td width=1%><img src='img/icon_mini_read.gif'></td>
		<td style='font-size:12px'><code $roll><a href=\"javascript:relayhost();\">{others} (*)</a></strong></code></td>
		<td width=1%><img src='img/fw_bold.gif'></td>
		<td align='center' style='font-size:12px' $roll><a href=\"javascript:relayhost();\">{$relayT[0]}</a></td>
		<td $roll style='font-size:12px'><code><a href=\"javascript:relayhost();\">{$relayT[1]}</a></code></td>
		<td align='center' style='font-size:12px'><code>{$relayT[2]}</code></td>
		<td align='center' style='font-size:12px'><code>{$relayT[3]}</code></td>
		<td align='center' style='font-size:12px' width=1%>" . imgtootltip('ed_delete.gif','{delete}',"RelayHostDelete();PostfixAddRoutingLoadTable()") . "</td>
		</tr>";
	}
	
	$sender=new sender_dependent_relayhost_maps();
	$h=$sender->sender_dependent_relayhost_maps_hash;
	$Tdomain=new DomainsTools();
	if(is_array($h)){
	while (list ($domain, $server) = each ($h) ){
		$array=$Tdomain->transport_maps_explode($server);
		if(substr($domain,0,1)=="@"){$domain=str_replace('@','',$domain);}
		$roll=CellRollOver(null,'{apply}');
		$html=$html . "<tr>
		<td width=1%><img src='img/icon_mini_read.gif'></td>
		<td style='font-size:12px'><code $roll><a href=\"javascript:SenderTable('$domain');\">$domain</a></strong></code></td>
		<td width=1%><img src='img/fw_bold.gif'></td>
		<td align='center' style='font-size:12px' $roll><a href=\"javascript:SenderTable('$domain');\">{$array[0]}</a></td>
		<td $roll style='font-size:12px'><code><a href=\"javascript:SenderTable('$domain');\">{$array[1]}</a></code></td>
		<td align='center' style='font-size:12px'><code>{$array[2]}</code></td>
		<td align='center' style='font-size:12px'><code>{$array[3]}</code></td>
		<td align='center' style='font-size:12px' width=1%>" . imgtootltip('ed_delete.gif','{delete}',"SenderTableDelete('$domain');PostfixAddRoutingLoadTable()") . "</td>
		</tr>";
	}
	
	
	}
	$html=$html . "</table>";
	$html=RoundedLightWhite("<div style='width:99%;height:350px;overflow:auto' id='routing-table'>$html</div>");
	$tpl=new templates();
	if($echo==1){echo $tpl->_ENGINE_parse_body($html);exit;}
	return $tpl->_ENGINE_parse_body($html);		
	
}

function LocalTable($echo=0){
$page=CurrentPageName();	
$ldap=new clladp();
$h=$ldap->hash_get_local_domains();
if(!is_array($h)){return null;}

$html="

	<table cellspacing='0' cellpadding='0' border='0' class='tableView' style='width:100%'>
		<thead class='thead'>
			<tr>
				<th >&nbsp;</th>
				<th ><strong>{domain}</strong></th>
				<th ><strong>&nbsp;</strong></th>
				<th align='center' ><strong>-</strong></th>
				<th ><strong>-</strong></th>
				<th ><strong>-</strong></th>
				<th ><strong-</strong></th>
				<th style='font-size:12px'>&nbsp;</th>
			</tr>
		</thead>
		<tbody class='tbody'>";

while (list ($domain, $ligne) = each ($h) ){
		if($classtr=="oddRow"){$classtr=null;}else{$classtr="oddRow";}
		
		$html=$html . "<tr class=$classtr>
		<td style='font-size:14px' width=1%><img src='img/internet.png'></td>
		<td style='font-size:14px'><code>$domain</a></strong></code></td>
		<td style='font-size:14px' width=1%><img src='img/fw_bold.gif'></td>
		<td style='font-size:14px' align='center'>local</td>
		<td ><code></td>
		<td align='center' style='font-size:14px'><code></code></td>
		<td align='center' style='font-size:14px'><code></code></td>
		<td align='center' style='font-size:14px' width=1%></td>
		</tr>";
	}
$html=$html . "</tbody></table>";
$html=RoundedLightWhite("<div style='width:99%;height:350px;overflow:auto' id='routing-table'>$html</div>");
$tpl=new templates();
if($echo==1){echo $tpl->_ENGINE_parse_body($html);exit;}
return $tpl->_ENGINE_parse_body($html);		
}

function routingTable($echo=0){
	$page=CurrentPageName();	

	$ldap=new clladp();
	$transport=new DomainsTools();
$h=$ldap->hash_load_transport();
if(!is_array($h)){return null;}




$html="

<div style='text-align:right;margin:5px;margin-top:0px'>". button("{add_routing_rule}","PostfixAddRoutingRuleTable()")."</div>

	<table cellspacing='0' cellpadding='0' border='0' class='tableView' style='width:100%'>
		<thead class='thead'>
			<tr>
				<th>&nbsp;</th>
				<th><strong nowrap>{domain}</strong></th>
				<th><strong nowrap>&nbsp;</strong></th>
				<th align='center' nowrap><strong>&nbsp;</strong></th>
				<th nowraph><strong>{relay}</strong></th>
				<th align='center' nowrap><strong>{port}</strong></th>
				<th align='center' nowrap><strong>{MX_lookups}</strong></th>
				<th>&nbsp;</td>
			</tr>
		</thead>
		<tbody class='tbody'>";


	



	while (list ($domain, $ligne) = each ($h) ){
		if($classtr=="oddRow"){$classtr=null;}else{$classtr="oddRow";}
		$array=$transport->transport_maps_explode($ligne);
		$delete= imgtootltip('delete-24.png','{delete}',"PostFixDeleteRoutingTable('$domain');");
		$edit="PostfixAddRoutingTable('$domain');";
		$edit=CellRollOver($edit,'{apply}');
		if($domain=="xspam@localhost.localdomain"){$delete="&nbsp;";$edit=null;}
		if($domain=="localhost.localdomain"){$delete="&nbsp;";$edit=null;}		
		
		$html=$html . "<tr class=$classtr>
		<td width=1%><img src='img/internet.png'></td>
		<td style='font-size:14px'><code $edit>$domain</strong></code></td>
		<td width=1%><img src='img/fw_bold.gif'></td>
		<td align='center' style='font-size:14px' $edit>{$array[0]}</td>
		<td $edit style='font-size:14px'><code>{$array[1]}</code></td>
		<td align='center' style='font-size:14px'><code>{$array[2]}</code></td>
		<td align='center' style='font-size:14px'><code>{$array[3]}</code></td>
		<td align='center' style='font-size:14px' width=1%>$delete</td>
		</tr>";
	}
	
	LoadLDAPDBs();
	if(is_array($GLOBALS["REMOTE_SMTP_LDAPDB_ROUTING"])){
		while (list ($domain, $ligne) = each ($GLOBALS["REMOTE_SMTP_LDAPDB_ROUTING"]) ){
			if($classtr=="oddRow"){$classtr=null;}else{$classtr="oddRow";}
			$array=$transport->transport_maps_explode($ligne);
				$html=$html . "<tr class=$classtr>
				<td width=1%><img src='img/internet.png'></td>
				<td style='font-size:14px'><code style='color:#676767'>$domain</strong></code></td>
				<td width=1%><img src='img/fw_bold.gif'></td>
				<td align='center' style='font-size:14px;color:#676767' >{$array[0]}</td>
				<td style='font-size:14px;color:#676767'><code>{$array[1]}</code></td>
				<td align='center' style='font-size:14px;color:#676767'><code>{$array[2]}</code></td>
				<td align='center' style='font-size:14px;color:#676767'><code>{$array[3]}</code></td>
				<td align='center' style='font-size:14px' width=1%>&nbsp;</td>
				</tr>";			
		}
		
		
	}
	
	
	
	

$html=$html . "</table>";
$html="<div style='width:99%;height:350px;overflow:auto' id='routing-table'>$html</div>";

$tpl=new templates();
if($echo==1){echo $tpl->_ENGINE_parse_body($html);exit;}
return $tpl->_ENGINE_parse_body($html);
	
}

function LoadLDAPDBs(){
	$main=new maincf_multi("master","master");
	$databases_list=unserialize(base64_decode($main->GET_BIGDATA("ActiveDirectoryDBS")));	
	if(is_array($databases_list)){
		while (list ($dbindex, $array) = each ($databases_list) ){
			if($array["enabled"]<>1){continue;}
			if($array["resolv_domains"]==1){$domains=$main->buidLdapDBDomains($array);}
			$GLOBALS["LDAPDBS"][$array["database_type"]][]="ldap:$targeted_file";
		}	
	}
}


function PostfixAddRoutingRuleTable(){
	$page=CurrentPageName();
	$main=new main_cf();
	$users=new usersMenus();
	$tpl=new templates();
	if(!$users->AsPostfixAdministrator){echo "<script>alert('".$tpl->javascript_parse_text("{ERROR_NO_PRIVS}")."');</script>";die();}
	
	$service=$main->HashGetMasterCfServices();
	$service["smtp"]="smtp";
	$ldap=new clladp();
	$ORG=$ldap->hash_get_ou(true);
	ksort($service);
	$ORG[null]='{select}';
	
	if(isset($_GET["domainName"])){
		
		$Table=$ldap->hash_load_transport();
		$t=new DomainsTools();
		$domainName=$_GET["domainName"];
		$line=$Table[$domainName];
		writelogs("LINE=$line for $domainName",__FUNCTION__,__FILE__);
		$conf=$t->transport_maps_explode($Table[$domainName]);		
		$relay_address=$conf[1];
		$smtp_port=$conf[2];
		$MX_lookups=$conf[3];
		$relay_service=$conf[0];
		$orgfound=$ldap->organization_name_from_transporttable($domainName);
	}
	
	$organization=Field_array_Hash($ORG,'org',$orgfound,"style:font-size:14px;padding:3px");
	
	
	if($relay_service==null){$relay_service="smtp";}
	
$html="
	<div style='font-size:16px'>{routing_rule}::$domainName</div>
	";
$form="
	
	<form name='FFM3'>
	<input type='hidden' name='PostfixAddRoutingRuleTableSave' value='yes'>
	<table style='width:99%' class=form>
	<tr>
	<td align='right' class=legend>{organization}:</strong></td>
	<td style='font-size:14px'>$organization</td>
	</tr>	
	<tr>
	<td align='right' class=legend>{pattern}:</strong></td>
	<td style='font-size:14px'>" . Field_text('domain',$domainName,'font-size:14px;width:50%',null,null,'{transport_maps_pattern_explain}') . "</td>
	</tr>
	<tr>
	<td align='right' class=legend>{service}:</strong></td>
	<td style='font-size:14px'>" . Field_array_Hash($service,'service',$relay_service,"style:font-size:14px") . "</td>
	</tr>	
	<td align='right' nowrap class=legend>{address}:</strong></td>
	<td style='font-size:14px'>" . Field_text('relay_address',$relay_address,"font-size:16px;width:120px") . "</td>	
	</tr>
	</tr>
	<td align='right' nowrap class=legend>{port}:</strong></td>
	<td style='font-size:14px'>" . Field_text('relay_port',$smtp_port,"font-size:16px;width:55px") . "</td>	
	</tr>	
	<tr>
	<td align='right' nowrap>" . Field_yesno_checkbox_img('MX_lookups',$MX_lookups,'{enable_disable}')."</td>
	<td style='font-size:14px'>{MX_lookups}</td>	
	</tr>
	$sasl
	<tr>
	<td align='right' colspan=2>". button("{apply}","PostfixAddNewRoutingTable()")."</td>
	</tr>		
	<tr>
	<td align='left' colspan=2><hr><div class=text-info><strong>{MX_lookups}</strong><br>{MX_lookups_text}</div></td>
	</tr>			
		
	</table>
	</FORM>
<script>
var X_PostfixAddNewRoutingTable= function (obj) {
		var results=obj.responseText;
		if (results.length>0){alert(results);}
		if(document.getElementById('container-tabs')){
			$('#container-tabs').tabs( 'load' ,1 );
		}
		YahooWinHide();
	}		
function PostfixAddNewRoutingTable(){
		var XHR = new XHRConnection();
		XHR.appendData('PostfixAddRoutingRuleTableSave','yes');
		XHR.appendData('org',document.getElementById('org').value);
		XHR.appendData('domain',document.getElementById('domain').value);
		XHR.appendData('service',document.getElementById('service').value);
		XHR.appendData('relay_address',document.getElementById('relay_address').value);
		XHR.appendData('relay_port',document.getElementById('relay_port').value);
		XHR.appendData('MX_lookups',document.getElementById('MX_lookups').value);				
		XHR.sendAndLoad('$page', 'GET',X_PostfixAddNewRoutingTable);
	}		
	
</script>	
	
	";
	
	
	echo $tpl->_ENGINE_parse_body("$html$form");		
	
	
}

function PostfixAddRelayRecipientTable(){
$page=CurrentPageName();	
$t=$_GET["t"];
if(!is_numeric($t)){$t=time();}
//relay_recipient_maps
$html="
	
	
	<div id='FFMPostfixAddRelayRecipientTable$t'>
	<input type='hidden' name='PostfixAddRelayRecipientTableSave' value='yes'>
	<table style='width:100%'>
	<tr>
	<td align='right' class=legend style='font-size:16px'>{recipient}:</strong></td>
	<td style='font-size:12px'>" . Field_text("recipient-$t",$domainName,"font-size:16px",null,null,null,false,"PostfixRelayRecipientTableSaveC$t(event)",false,null) . "</td>
	</tr>
	<tr>
	<td align='right'  colspan=2>". button("{add}","PostfixRelayRecipientTableSave$t()",18)."</td>
	</tr>			
	</table>
	<div class=text-info style='font-size:14px'>{relay_recipient_maps_text}</div>
	
	<script>


var X_PostfixDeleteRelayRecipient$t= function (obj) {
		YahooWin3Hide();
		YahooWinHide();
		$('#flexRT$t').flexReload();
	}	

function PostfixRelayRecipientTableSaveC$t(e){
	if(checkEnter(e)){PostfixRelayRecipientTableSave$t();}
}
	
function PostfixRelayRecipientTableSave$t(){
		var XHR = new XHRConnection();
		XHR.appendData('PostfixAddRelayRecipientTableSave','yes');
		XHR.appendData('recipient',document.getElementById('recipient-$t').value);
		AnimateDiv('FFMPostfixAddRelayRecipientTable$t');
		XHR.sendAndLoad('$page', 'GET',X_PostfixDeleteRelayRecipient$t);
	}
</script>	
	
	";
	
	$tpl=new templates();
	echo $tpl->_ENGINE_parse_body($html);		
}

function PostfixAddRelayTable(){
	$ldap=new clladp();
	$page=CurrentPageName();
	$org=$ldap->hash_get_ou(true);
	$org[null]='{select}';
	$listOrg=Field_array_Hash($org,'org',$org);
	$tls_table=$ldap->hash_Smtp_Tls_Policy_Maps();
	$smtp_server_line=$Table[$domainName];
	$smtp_server_line=str_replace('smtp:','',$smtp_server_line);
	$tls_value=$tls_table[$smtp_server_line];
	writelogs("server \"{$Table[$domainName]}\"=>$smtp_server_line=>".$tls_table[$smtp_server_line] ."($tls_value)",__FUNCTION__,__FILE__);
	
	$main=new main_cf();
	if($main->main_array["smtp_sasl_auth_enable"]=="yes"){
		$field=Field_array_Hash($main->array_field_relay_tls,'smtp_tls_policy_maps',$tls_value);
		$sasl="
		</tr>
			<td align='right' nowrap valign='top' class=legend>{tls_level}:</strong></td>
			<td style='font-size:12px'>$field<div class='caption'>{use_tls_relay_explain}</div></td>	
		</tr>";
		
	}
	
	
	if($smtp_port==null){$smtp_port=25;}
	
	$html="
	<h1>{add_routing_relay_domain_rule}</H1>
	<br>" . RoundedLightWhite("
	<form name='FFM3'>
	<input type='hidden' name='PostfixAddRoutingTableSave' value='yes'>
	<table style='width:100%'>
	<tr>
	<td align='right' class=legend>{organization}:</strong></td>
	<td style='font-size:12px'>$listOrg</td>
	</tr>	
	<tr>
	<td align='right' class=legend>{domainName}:</strong></td>
	<td style='font-size:12px'>" . Field_text('domain',$domainName) . "</td>
	</tr>
	<td align='right' nowrap class=legend>{relay_address}:</strong></td>
	<td style='font-size:12px'>" . Field_text('relay_address',$relay_address) . "</td>	
	</tr>
	<td align='right' nowrap class=legend>{smtp_port}:</strong></td>
	<td style='font-size:12px'>" . Field_text('relay_port',$smtp_port) . "</td>	
	</tr>	
	<tr>
	<td align='right' nowrap>" . Field_yesno_checkbox_img('MX_lookups',$MX_lookups,'{enable_disable}')."</td>
	<td style='font-size:12px'>{MX_lookups}</td>	
	</tr>
	$sasl
	<tr>
	<td align='right' colspan=2>". button("{apply}","PostfixAddNewRelayTable()")."</td>
	</tr>		
	<tr>
	<td align='left' colspan=2><hr><p class=caption>{MX_lookups}</strong><br>{MX_lookups_text}</p></td>
	</tr>			
		
	</table>
	</FORM>
	//PostfixAddRoutingRuleTableSave
<script>
var X_PostfixAddNewRelayTable= function (obj) {
		var results=obj.responseText;
		if (results.length>0){alert(results);}
		$('#container-tabs').tabs( 'load' ,3 );
		YahooWinHide();
	}		
function PostfixAddNewRelayTable(){
		var XHR = new XHRConnection();
		XHR.appendData('PostfixAddRoutingTableSave','yes');
		XHR.appendData('org',document.getElementById('org').value);
		XHR.appendData('domain',document.getElementById('domain').value);
		XHR.appendData('relay_address',document.getElementById('relay_address').value);
		XHR.appendData('MX_lookups',document.getElementById('MX_lookups').value);
		XHR.appendData('relay_port',document.getElementById('relay_port').value);
		if(document.getElementById('smtp_tls_policy_maps')){
			XHR.appendData('relay_port',document.getElementById('smtp_tls_policy_maps').value);
		}
		
		
		XHR.sendAndLoad('$page', 'GET',X_PostfixAddNewRelayTable);
		
	}		
	
</script>	
	");
	
	$tpl=new templates();
	echo $tpl->_ENGINE_parse_body($html);	
}

function PostfixAddRelayRecipientTableSave(){
	$ldap=new clladp();
	$ldap->AddRecipientRelayTable("{$_GET["recipient"]}");
	}

function PostfixAddRoutingTableSave(){
	$tpl=new templates();
	if($_GET["relay_port"]==null){$_GET["relay_port"]=25;}
	if($_GET["domain"]==null){echo $tpl->_ENGINE_parse_body("{error_no_domain_specified}");exit;}	
	if($_GET["relay_address"]==null){echo $tpl->_ENGINE_parse_body("{error_no_server_specified}");exit;}

	$ldap=new clladp();
	$ldap->AddDomainTransport($_GET["org"],$_GET["domain"],$_GET["relay_address"],$_GET["relay_port"],'relay',$_GET["MX_lookups"]);
	$ldap->smtp_tls_policy_maps_add($_GET["relay_address"],$_GET["relay_port"],$_GET["MX_lookups"],$_GET["smtp_tls_policy_maps"]);
	$ldap->AddRecipientRelayTable("@{$_GET["domain"]}");
	$ldap->AddDomainRelayTable($_GET["domain"]);
	$sock=new sockets();
	$sock->getFrameWork("services.php?postfix-single=yes");	
	}
function PostFixDeleteRoutingTable(){
	$ldap=new clladp();
	$dn=$ldap->WhereisDomainTransport($_GET["PostFixDeleteRoutingTable"]);
	$ldap->ldap_delete($dn,true);
	$tpl=new templates();
	$sock=new sockets();
	$sock->getFrameWork("cmd.php?postfix-transport-maps=yes");
	}
function relayhost(){
$main=new main_cf()	;
$tpl=new templates();
$page=CurrentPageName();
if($main->main_array["relayhost"]<>null){
	$relayhost=$main->main_array["relayhost"];
}else{
	$sock=new sockets();
	$relayhost=$sock->GET_INFO("PostfixRelayHost");
}	
if($relayhost<>null){
	$tools=new DomainsTools();
	$relayhost="smtp:".$main->main_array["relayhost"];
	$relayT=$tools->transport_maps_explode($relayhost);
}

if($relayT[1]<>null){
	$delete="<a href=\"javascript:blur();\" OnClick=\"RelayHostDelete();\" style='font-size:16px;text-decoration:underline;text-transform:capitalize'>{delete} {$relayT[1]}</a>";
}

$maps=new smtp_sasl_password_maps();
$pp=str_replace(".","\.",$relayT[1]);
$pp=str_replace("[","\[",$pp);
$pp=str_replace("]","\]",$pp);
$pp=str_replace("smtp:","",$pp);

while (list ($relaisa, $ligne) = each ($maps->smtp_sasl_password_hash) ){
	if(preg_match("#$pp#i",$relaisa)){
		if(preg_match("#^(.+?):(.+?)$#",$ligne,$re)){$username=$re[1];$password=$re[2];}
		break;
	}
}
$otherisp=Paragraphe("relais-isp.png","{USE_MY_ISP}","{USE_MY_IPS_EXAMPLES_TEXT}","javascript:Loadjs('postfix.index.php?use-my-isp=yes')");
$maptable=Paragraphe("tables-lock-64.png","(". count($maps->smtp_sasl_password_hash).") {items}:{passwords_table}","{passwords_table_text}",
"javascript:Loadjs('postfix.smptp.sasl.passwords.maps.php')");

$t=time();
$ask_compile_postfix=$tpl->javascript_parse_text("{ask_compile_postfix}");

$form="<div style='font-size:16px'>{relayhost}</div>
<div class=text-info>{relayhost_text}</div>
<div id='relayhostdiv-$t'></div>
<div style='text-align:right'><code style='font-size:14px;padding:3px'>$relayhost</code></div>
	<table style='width:100%'>
	<tr>
		<td valign='top'>$otherisp<br>$maptable
		</td>
		<td valign='top'>
			
			<div id='relayhostdiv'>
					<table style='width:100%' >
					<tr>
						<td valign='top'>
						<input type='hidden' name='relayhostSave' value='yes'>
						<div style='width:98%' class=form>
						<table style='width:99%'>
							<td align='right' nowrap class=legend>{relay_address}:</strong></td>
							<td style='font-size:12px'>" . Field_text('relay_address',$relayT[1],"font-size:13px;padding:3px") . "</td>	
						</tr>
						</tr>
							<td align='right' nowrap class=legend>{smtp_port}:</strong></td>
							<td style='font-size:12px'>" . Field_text('relay_port',$relayT[2],"font-size:13px;padding:3px") . "</td>	
						</tr>	
						<tr>
							<td align='right' nowrap>" . Field_checkbox('MX_lookups',"yes",$relayT[3],'{enable_disable}')."</td>
							<td style='font-size:12px'>{MX_lookups}</td>	
						</tr>
						</tr>
							<td align='right' nowrap class=legend>{username}:</strong></td>
							<td style='font-size:12px'>" . Field_text('relay_username',$username,"font-size:13px;padding:3px") . "</td>	
						</tr>
						</tr>
							<td align='right' nowrap class=legend>{password}:</strong></td>
							<td style='font-size:12px'>" . Field_password('relay_password',$password,"font-size:13px;padding:3px;width:120px") . "</td>	
						</tr>						
						
						<tr>
							<td align='right' colspan=2 align='right'>". button("{apply}","PostfixSaveRelayHost()",14)."</td>
						</tr>		
								
						</td>
						</tr>
						</table>
						</div>
					</td>
						
					</tr>
					</table>
					<div style='text-align:right'>$delete</div>
			</div>
		</td>
	</tr>
</table>
<div class=text-info>{MX_lookups}<br>{MX_lookups_text}</div>
</div>
<script>
var X_PostfixSaveRelayHost= function (obj) {
		var results=trim(obj.responseText);
		if(results.length>2){alert(results);}
		document.getElementById('relayhostdiv-$t').innerHTML='';
		RefreshTab('main_relayhost_config');
		if(confirm('$ask_compile_postfix')){
			Loadjs('postfix.compile.php');
		}
	}		
function PostfixSaveRelayHost(){
		var XHR = new XHRConnection();
		XHR.appendData('relayhostSave','yes');
		XHR.appendData('relay_address',document.getElementById('relay_address').value);
		XHR.appendData('relay_username',document.getElementById('relay_username').value);
		var relay_password=encodeURIComponent(document.getElementById('relay_password').value);
		XHR.appendData('relay_password',relay_password);
		if(document.getElementById('MX_lookups').checked){
			XHR.appendData('MX_lookups','yes');
		}else{
			XHR.appendData('MX_lookups','no');
		}
		
		XHR.appendData('relay_port',document.getElementById('relay_port').value);
		AnimateDiv('relayhostdiv-$t');   
		XHR.sendAndLoad('$page', 'POST',X_PostfixSaveRelayHost);
		
	}
function RelayHostDelete(){
		var XHR = new XHRConnection();
		XHR.appendData('RelayHostDelete','yes');
		XHR.sendAndLoad('$page', 'GET',X_PostfixSaveRelayHost);
		
	}
	
	
</script>";




	echo $tpl->_ENGINE_parse_body("$form");		
}
function relayhostSave(){
	
	
	$_POST["relay_password"]=url_decode_special_tool($_POST["relay_password"]);
	if($_POST["relay_port"]==null){$_POST["relay_port"]=25;}
	$tpl=new templates();
	if($_POST["relay_address"]==null){
		echo $tpl->_ENGINE_parse_body("{error_no_server_specified}");
		exit;
	}	
	$tool=new DomainsTools();
	writepostfixlogs("Port={$_POST["relay_port"]} address={$_POST["relay_address"]}",__FUNCTION__,__FILE__);
	$data=$tool->transport_maps_implode($_POST["relay_address"],$_POST["relay_port"],'smtp',$_POST["MX_lookups"]);
	writepostfixlogs("Port={$_POST["relay_port"]} address={$_POST["relay_address"]}=$data",__FUNCTION__,__FILE__);
	$data=str_replace('smtp:','',$data);
	$main=new main_cf();
	$main->main_array["relayhost"]=$data;
	$sock=new sockets();
	$sock->SET_INFO("PostfixRelayHost",$data);
	$main->save_conf();
	
	if($_POST["relay_username"]<>null){
		writelogs("ADD relay_username:`{$_POST["relay_username"]}`",__FUNCTION__,__FILE__,__LINE__);
		$sals=new smtp_sasl_password_maps();
		$sals->add($data,$_POST["relay_username"],$_POST["relay_password"]);
	}
	$sock->getFrameWork("cmd.php?postfix-relayhost=yes");
	
	}
function RelayHostDelete(){
	$main=new main_cf();
	unset($main->main_array["relayhost"]);
	$sock=new sockets();
	$sock->SET_INFO('PostfixRelayHost',null);
	$main->save_conf();
	$sock->getFrameWork("cmd.php?postfix-relayhost=yes");

}


function RelayRecipientsTable($echo=0){
ArticaSyncTable($echo);

}

function ArticaSyncTableDelete(){
	$dn=base64_decode($_GET["ArticaSyncTableDelete"]);
	$ldap=new clladp();
	if(!$ldap->ldap_delete($dn)){echo $ldap->ldap_last_error;}
	
}

function ArticaSyncTable(){
	$t=time();
	$page=CurrentPageName();
	$tpl=new templates();
	$users=new usersMenus();
	$sock=new sockets();
	$t=time();
	$domain=$tpl->_ENGINE_parse_body("{domain}");
	$are_you_sure_to_delete=$tpl->javascript_parse_text("{are_you_sure_to_delete}");
	$relay=$tpl->javascript_parse_text("{relay}");
	$MX_lookups=$tpl->javascript_parse_text("{MX_lookups}");
	$delete=$tpl->javascript_parse_text("{delete}");
	$InternetDomainsAsOnlySubdomains=$sock->GET_INFO("InternetDomainsAsOnlySubdomains");
	if(!is_numeric($InternetDomainsAsOnlySubdomains)){$InternetDomainsAsOnlySubdomains=0;}
	$add_local_domain_form_text=$tpl->javascript_parse_text("{add_local_domain_form}");
	$add_local_domain=$tpl->_ENGINE_parse_body("{add_local_domain}");
	$sender_dependent_relayhost_maps_title=$tpl->_ENGINE_parse_body("{sender_dependent_relayhost_maps_title}");
	$ouescape=urlencode($ou);
	$destination=$tpl->javascript_parse_text("{destination}");
	$add_routing_relay_recipient_rule=$tpl->javascript_parse_text("{add_routing_relay_recipient_rule}");
	$hostname=$_GET["hostname"];
	$rules=$tpl->_ENGINE_parse_body("{rules}");
	$add_remote_domain=Paragraphe("64-remotedomain-add.png",'{add_relay_domain}','{add_relay_domain_text}',
	"javascript:AddRemoteDomain_form(\"$ou\",\"new domain\")","add_relay_domain",210);
	

	$buttons="
	buttons : [
	{name: '$rules', bclass: 'add', onpress : ArticaSyncrules$t},
	{name: '$add_routing_relay_recipient_rule', bclass: 'add', onpress : PostfixAddRelayRecipientTable$t},
	
	],";		

	
$html="
<input type='hidden' id='ou' value='$ou'>
<table class='flexRT$t' style='display: none' id='flexRT$t' style='width:100%'></table>

	
<script>
var memid='';
$(document).ready(function(){
$('#flexRT$t').flexigrid({
	url: '$page?artica-sender-table-list=yes&hostname=$hostname&t=$t',
	dataType: 'json',
	colModel : [
		{display: '$domain', name : 'domain', width : 409, sortable : true, align: 'left'},
		{display: '$relay', name : 'description', width :309, sortable : true, align: 'left'},
		{display: '$delete;', name : 'delete', width : 44, sortable : false, align: 'left'},
		],
	$buttons
	searchitems : [
		{display: '$domain', name : 'domain'},
		],
	sortname: 'domain',
	sortorder: 'asc',
	usepager: true,
	title: '',
	useRp: true,
	rp: 50,
	showTableToggleBtn: false,
	width: 820,
	height: 600,
	singleSelect: true,
	rpOptions: [10, 20, 30, 50,100,200]
	
	});   
});

	function ArticaSyncrules$t(){
		Loadjs('postfix.artica.smtp-sync.php');
	}

	function sender_routing_ruleED$t(domainName){
		YahooWin3(552,'postfix.routing.table.php?SenderTable=yes&domainName='+domainName+'&t=$t','$sender_dependent_relayhost_maps_title::'+domainName);	
	}	
	
	
	function SenderTableDelete$t(domain){
		Loadjs('$page?SenderTableDelete-js=yes&domain='+domain+'&t=$t');
	
	}
	
function PostfixAddRelayRecipientTable$t(){
	YahooWin(552,'$page?PostfixAddRelayRecipientTable=yes&domainName=&t=$t','$add_routing_relay_recipient_rule')
	}		
	

var X_ArticaSyncTableDelete$t= function (obj) {
		var results=trim(obj.responseText);
		if(results.length>0){alert(results);return;}
		$('#rowdom'+memid).remove();
	}		
function ArticaSyncTableDelete$t(dn,id){
		memid=id;
		var XHR = new XHRConnection();
		XHR.appendData('ArticaSyncTableDelete',dn);
		XHR.sendAndLoad('$page', 'GET',X_ArticaSyncTableDelete$t);
		
	}
	
	function PostfixDeleteRelayRecipient$t(recipient,md){
		memid=md;
		var XHR = new XHRConnection();
		XHR.appendData('PostfixDeleteRelayRecipient',recipient);
		XHR.sendAndLoad('$page', 'GET',X_ArticaSyncTableDelete$t);		
		}		
	
</script>
";
	
	echo $html;
			
	
	
}


function ArticaSyncTable_list($echo=0){
	$page=CurrentPageName();
	$ldap=new clladp();
	
	if($_POST["query"]<>null){$searchZ=str_replace("*", ".*?", $_POST["query"]);}
	$ttime=$_GET["t"];

	$dn="cn=artica_smtp_sync,cn=artica,$ldap->suffix";
	$filter=array("cn");
	$sr = @ldap_search($ldap->ldap_connection,$dn,'(&(objectclass=ArticaSMTPSyncDB)(cn=*))',$filter);
	if ($sr) {
			$hash=ldap_get_entries($ldap->ldap_connection,$sr);
			if(!is_array($hash)){return null;}
			
			for($i=0;$i<$hash["count"];$i++){
				$cn=$hash[$i]["cn"][0];
				if(preg_match("#(.+?):(.+)#",$cn,$re)){$mailserver=$re[1];}

				$cn_dn="cn=table,cn=$cn,cn=artica_smtp_sync,cn=artica,$ldap->suffix";
				$search = @ldap_search($ldap->ldap_connection,$dn,'(&(objectclass=InternalRecipients)(cn=*))',array("cn"));
				if ($search) {
					
					$hash2=ldap_get_entries($ldap->ldap_connection,$search);
					for($t=0;$t<$hash2["count"];$t++){
					$cn_email=$hash2[$t]["cn"][0];
					$dn=base64_encode($hash2[$t]["dn"]);	
					if($searchZ<>null){if(!preg_match("#$searchZ#", $cn_email)){continue;}}
					$m5=md5($cn_email);
				$data['rows'][] = array(
					'id' => "dom$m5",
					'cell' => array("
					<a href=\"javascript:blur();\" 
						OnClick=\"\" 
						style='font-size:16px;font-weight:bold;text-decoration:'>$cn_email</span>",
					"<span style='font-size:14px'>$mailserver:25</span>",
					 imgtootltip('delete-32.png','{delete}',"ArticaSyncTableDelete$ttime('$dn','$m5');") )
					);
					if($c>$_POST["rp"]){break;}
					$c++;
		}
				}
			}
		}
		
		
	$hash=$ldap->hash_get_relay_recipients();	
if(is_array($hash)){
while (list ($domain, $ligne) = each ($hash) ){
		$m5=md5($domain);
		if($searchZ<>null){if(!preg_match("#$searchZ#", $domain)){continue;}}
		if($c>$_POST["rp"]){break;}
		$c++;		
		
				
				$data['rows'][] = array(
					'id' => "dom$m5",
					'cell' => array("
					<a href=\"javascript:blur();\" 
						OnClick=\"\" 
						style='font-size:16px;font-weight:bold;text-decoration:'>$domain</span>",
					"<span style='font-size:14px'>&nbsp;</span>",
					 imgtootltip('delete-32.png','{delete}',"PostfixDeleteRelayRecipient$ttime('$domain','$m5');") )
					);		
	}
}		
		
		
	$data['page'] = 1;
	$data['total'] = $c;
	echo json_encode($data);		

}


function RelayDomainsTable($echo=0){
	
	$ldap=new clladp();
	$hash=$ldap->hash_get_relay_domains();
	//$add_routing_relay_domain_rule=Paragraphe("routing-domain-relay.png","{add_routing_relay_domain_rule}","{add_routing_relay_domain_rule}","PostfixAddRelayTable()");
$html="
<div style='text-align:right;margin:5px;margin-top:0px'>". button("{add_routing_relay_domain_rule}","PostfixAddRelayTable()")."</div>
<table style='width:99%;padding:5px;border:2px solid #8E8785;' align='center' class=form>
	<tr style='background-color:#CCCCCC'>
		<th style='font-size:12px'>&nbsp;</th>
		<th style='font-size:12px'><strong>{domain}</strong></th>
		<th style='font-size:12px'><strong>&nbsp;</strong></th>
		<th align='center' style='font-size:12px'><strong>-</strong></th>
		<th style='font-size:12px'><strong>-</strong></td>
		<th align='center' style='font-size:12px'><strong>-</strong></th>
		<th align='center' style='font-size:12px'><strong-</strong></th>
		<th style='font-size:12px'>&nbsp;</th>
	</tr>";
if(is_array($hash)){
while (list ($domain, $ligne) = each ($hash) ){
	
		$delete=imgtootltip("ed_delete.gif",'{delete}',"PostfixDeleteRelayDomain('$domain')");
		if($domain=="localhost.localdomain"){$delete="&nbsp;";}
		$html=$html . "<tr>
		<td width=1%><img src='img/internet.png'></td>
		<td style='font-size:13px'><code>$domain</a></strong></code></td>
		<td width=1%><img src='img/fw_bold.gif'></td>
		<td align='center' style='font-size:12px'>{relay}</td>
		<td ><code></td>
		<td align='center' style='font-size:12px'><code></code></td>
		<td align='center' style='font-size:12px'><code></code></td>
		<td align='center' style='font-size:12px' width=1%>$delete</td>
		</tr>";
	}
}
$html=$html . "</table>";
$html=RoundedLightWhite("<div style='width:99%;height:350px;overflow:auto' id='routing-table'>$html</div>");

$tpl=new templates();
if($echo==1){echo $tpl->_ENGINE_parse_body($html);exit;}
return $tpl->_ENGINE_parse_body($html);
	
}



function SenderTableLoad_list(){
	$ldap=new clladp();
	$tpl=new templates();
	$tools=new DomainsTools();
	$t=$_GET["t"];
	$main=new main_cf();
	
	
	$sender=new sender_dependent_relayhost_maps();
	$h=$sender->sender_dependent_relayhost_maps_hash;	
	$Tdomain=new DomainsTools();
		
	$data = array();
	if($_POST["query"]<>null){$search=str_replace("*", ".*?", $_POST["query"]);}

	$c=0;
	
	if($_POST["sortorder"]=="desc"){krsort($h);}else{ksort($h);}
	
	if($main->main_array["relayhost"]<>null){
		$tools=new DomainsTools();
		$c++;
		$main->main_array["relayhost"]="smtp:".$main->main_array["relayhost"];
		$relayT=$tools->transport_maps_explode($main->main_array["relayhost"]);
		$all=$tpl->_ENGINE_parse_body("{all}");
		$data['rows'][] = array(
				'id' => "dom$m5",
				'cell' => array("
				<a href=\"javascript:blur();\" 
					OnClick=\"javascript:relayhost()\" 
					style='font-size:16px;font-weight:bold;text-decoration:underline'>$all</span>",
				"<span style='font-size:14px'>{$relayT[0]}:{$relayT[1]} {$relayT[2]} {$relayT[3]}</span>",
				"&nbsp;" )
				);		
	}	
	
	
	while (list ($domain, $server) = each ($h) ){
		if($search<>null){if(!preg_match("#$search#", $num)){continue;}}
		$c++;
		$array=$Tdomain->transport_maps_explode($server);
		if(substr($domain,0,1)=="@"){$domain=str_replace('@','',$domain);}
		$m5=md5($domain);
	$data['rows'][] = array(
		'id' => "dom$m5",
		'cell' => array("
		<a href=\"javascript:blur();\" 
			OnClick=\"javascript:sender_routing_ruleED$t('$domain');\" 
			style='font-size:16px;font-weight:bold;text-decoration:underline'>$domain</span>",
		"<span style='font-size:14px'>{$array[0]}:{$array[1]}:{$array[2]}:{$array[3]}</span>",
		 imgtootltip('delete-32.png','{delete}',"SenderTableDelete$t('$domain');") )
		);

		if($c>$_POST["rp"]){break;}
		
	}

	if($c==0){json_error_show("no data");}
	$data['page'] = 1;
	$data['total'] = $c;
	echo json_encode($data);	

}




function SenderTableSave(){
	$tpl=new templates();
	
	if($_GET["domain"]==null && $_GET["email"]==null){echo $tpl->_ENGINE_parse_body('{error_give_email_or_domain}');exit;}
	if($_GET["domain"]<>null && $_GET["email"]<>null){echo $tpl->_ENGINE_parse_body('{error_choose_email_or_domain}');exit;}			
	if($_GET["relay_address"]==null){echo $tpl->_ENGINE_parse_body('{error_no_server_specified}');exit;}
	
	if($_GET["MX_lookups"]=="no"){$_GET["relay_address"]="[" . $_GET["relay_address"] . "]";}
	if($_GET["domain"]==null){$_GET["domain"]=$_GET["email"];}
	
	$sender=new sender_dependent_relayhost_maps();
	if(!$sender->Add($_GET["domain"],$_GET["relay_address"])){
		echo $sender->last_error;
		exit;
	}
	
	if(isset($_GET["smtp_tls_policy_maps"])){
		$ldap=new clladp();
		$ldap->smtp_tls_policy_maps_add($_GET["domain"],null,$_GET["MX_lookups"],$_GET["smtp_tls_policy_maps"]);
	}
	
		$sock=new sockets();
	$sock->getFrameWork("services.php?postfix-single=yes");
}
function SenderTable_js(){
	$page=CurrentPageName();
	$tpl=new templates();
	$ldap=new clladp();	
	$domain=$_GET["domain"];
	$confirm=$tpl->javascript_parse_text("{delete_this_domain} `$domain` ?");
	$t=$_GET["t"];
	$m5=md5($domain);
	
	$html=
	"
	var x_DelRSDomain$t= function (obj) {
		var tempvalue=obj.responseText;
		if(tempvalue.length>3){alert(tempvalue);return;}
		if(!document.getElementById('rowdom$m5')){alert('rowdom$m5 ni such id');}
		$('#rowdom$m5').remove();
	}	
	
	if(confirm('$confirm')){
		var XHR = new XHRConnection();
		XHR.appendData('SenderTableDelete','$domain');
		XHR.sendAndLoad('$page', 'GET',x_DelRSDomain$t);
	}
	";
	echo $html;		
}


function SenderTableDelete(){
	$domain=$_GET["SenderTableDelete"];
	if(strpos($domain,'@')==0){$domain="@".$domain;}
	$ldap=new clladp();
	$dn="cn=$domain,cn=Sender_Dependent_Relay_host_Maps,cn=artica,$ldap->suffix";
	$ldap->ldap_delete($dn,false);
	$sock=new sockets();
	$sock->getFrameWork("services.php?postfix-single=yes");	
	}
	
function PostfixDeleteRelayDomain(){
	$domain=$_GET["PostfixDeleteRelayDomain"];
	$ldap=new clladp();
	$dn="cn=$domain,cn=relay_domains,cn=artica,$ldap->suffix";
	$ldap->ldap_delete($dn,false);
	$sock=new sockets();
	$sock->getFrameWork("services.php?postfix-single=yes");	
	}
function PostfixDeleteRelayRecipient(){
	$domain=$_GET["PostfixDeleteRelayRecipient"];
	$ldap=new clladp();
	$dn="cn=$domain,cn=relay_recipient_maps ,cn=artica,$ldap->suffix";
	$ldap->ldap_delete($dn,false);	
	$sock=new sockets();
	$sock->getFrameWork("services.php?postfix-single=yes");	
	}
	
	
function PostfixAddRoutingRuleTableSave(){
$MX_lookups=$_GET["MX_lookups"];
$domain=$_GET["domain"];
$org=$_GET["org"];
$relay_address=$_GET["relay_address"];
$relay_port	=$_GET["relay_port"];
$service=$_GET["service"];
$tpl=new templates();
if($relay_address==null){echo $tpl->_ENGINE_parse_body('{error_give_address}');return null;}
if($domain==null){echo $tpl->_ENGINE_parse_body('{error_give_pattern}');return null;}
if($org==null){echo $tpl->_ENGINE_parse_body('{error_no_organization}');return null;}
writelogs("organization for this transport table rule=$org",__FUNCTION__,__FILE__);
	$tool=new DomainsTools();
	$line=$tool->transport_maps_implode($relay_address,$relay_port,$service,$MX_lookups);
writelogs("$line",__FUNCTION__,__FILE__);	
	$ldap=new clladp();
	$ldap->AddTransportTable($domain,$line,$org);
	$sock=new sockets();
	$sock->getFrameWork("services.php?postfix-single=yes");

}


function TESTS(){
		$ldap=new clladp();
		$upd['cn'][0]='Sender_Dependent_Relay_host_Maps';
		$dn="cn=Sender_Dependent_Relay_host_Maps,cn=artica,$ldap->suffix";
		$upd['objectClass'][0]='senderDependentRelayhostMaps';
		$upd['objectClass'][1]='top';
		$ldap->ldap_add($dn,$upd);	
		
	
}
	
	
?>	

