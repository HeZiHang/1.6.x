<?php
	include_once('ressources/class.templates.inc');
	include_once('ressources/class.ldap.inc');
	include_once('ressources/class.users.menus.inc');
	include_once('ressources/class.groups.inc');
	include_once('ressources/class.user.inc');
	include_once('ressources/class.cyrus.inc');
	
	//if(count($_POST)>0)
	$usersmenus=new usersMenus();
	if(!$usersmenus->AllowAddUsers){
			$tpl=new templates();
			$error="{ERROR_NO_PRIVS}";
			echo $tpl->_ENGINE_parse_body("alert('$error')");
			die();
	}
	
	
	if(isset($_GET["popup"])){popup();exit;}
	if(isset($_GET["Confirm"])){Confirm();exit;}
	
//YahooUser_c	
js();
function js(){
	$page=CurrentPageName();
	$tpl=new templates();
	$title=$tpl->_ENGINE_parse_body('{delete_this_user}',"domains.edit.user.php");
	$networks=$tpl->_ENGINE_parse_body('{edit_networks}');
	$delete_all_computers_warn=$tpl->_ENGINE_parse_body('{delete_all_computers_warn}');
	$prefix=str_replace('.','_',$page);
	$prefix=str_replace('-','',$prefix);
	$uidenc=urlencode($_GET["uid"]);
	$html="
	var rule_mem='';
	var {$prefix}timeout=0;
	var {$prefix}timerID  = null;
	var {$prefix}tant=0;
	var {$prefix}reste=0;	
	
	function {$prefix}start(){
		YahooLogWatcher(665,'$page?popup=yes&uid=$uidenc&flexRT={$_GET["flexRT"]}','$title::{$_GET["uid"]}');
	}
	
	var x_ConfirmDeletionOfUser= function (obj) {
		var results=obj.responseText;
		if(results.length>0){alert(results);return;}
		CacheOff();
		YahooLogWatcherHide();
		YahooUserHide();
		if(YahooSearchUserOpen()){FindUser();}
		if(document.getElementById('DomainsUsersFindPopupDiv')){DomainsUsersFindPopupDivRefresh();}
		if(document.getElementById('flexRT{$_GET["flexRT"]}')){ $('#flexRT{$_GET["flexRT"]}').flexReload(); }
		
	}
	
	function ZarafaDCopyToPublicCallBack(uid){
		document.getElementById('ZarafaCopyToPublic').value=uid;
		document.getElementById('unhookZarafaStore').checked=true;
		WinORGHide();
	
	}
	
	function ConfirmDeletionOfUser(){
		var XHR = new XHRConnection();
		XHR.appendData('uid','{$_GET["uid"]}');
		XHR.appendData('Confirm','yes');
		if(document.getElementById('DeleteMailBox')){
			XHR.appendData('delete-mailbox',document.getElementById('DeleteMailBox').value);
		}
		
		if(document.getElementById('unhookZarafaStore')){
			if(document.getElementById('unhookZarafaStore').checked){XHR.appendData('unhookZarafaStore','yes');}
		}
		if(document.getElementById('ZarafaCopyToPublic')){
			XHR.appendData('ZarafaCopyToPublic',document.getElementById('ZarafaCopyToPublic').value);
		}		
		
		AnimateDiv('deletion');
		XHR.sendAndLoad('$page', 'GET',x_ConfirmDeletionOfUser);
	}
	
	{$prefix}start();
	";
	
	
	echo $html;
}


function popup(){
	
	$uid=$_GET["uid"];
	$user=new user($uid);
	$usersmenus=new usersMenus();
	
	$delete_mailbox="
			<tr>
				<td>
					<table style='width:100%'>
						<tr>
						<td class=legend nowrap>{delete_mailbox}:</td>
						<td>". Field_numeric_checkbox_img('DeleteMailBox',0,"{delete_mailbox}")."</td>
						</tr>
					</table>
				</td>
			</tr>";
	
	
	$delete_mailbox_zarafa="
			<tr>
				<td>
					<table style='width:100%'>
						<tr>
							<td class=legend nowrap style='font-size:14px'>{unhook_mailbox}:</td>
							<td>". Field_checkbox('unhookZarafaStore',1,0,"unhookZarafaStoreCheck()")."</td>
							<td>&nbsp;</td>
						</tr>
						
							<td class=legend nowrap style='font-size:14px'>{hook_mailboxto}:</td>
							<td>". Field_text('ZarafaCopyToPublic',null,"width:140px;font-size:14px")."</td>
							<td width=1%>". button("{browse}","Loadjs('MembersBrowse.php?OnlyUsers=1&NOComputers=0&Zarafa=1&callback=ZarafaDCopyToPublicCallBack')")."</td>
						</tr>	
						<tr>
							<td colspan=3><div class=explain>{ZarafaCopyToPublic}</div></td>
						<tr>											
					</table>
				</td>
			</tr>";
	
	
	if(!$usersmenus->cyrus_imapd_installed){$delete_mailbox=null;}
	if(!$usersmenus->ZARAFA_INSTALLED){$delete_mailbox_zarafa=null;}
$picture="<img src='img/user-server-64-delete.png'>";
$user_infos="<table style='width:99%' class=form>
<tr>
	<td valign='top' width=1%>$picture</td>
	<td valign='top' width=99%>
		<table style='width:100%'>
		<tbody>
			<tr>
				<td style='border-bottom:1px solid #CCCCCC'><strong style='font-size:16px;'>$user->uid</strong></td>
			</tr>
			<tr>
				<td align='right'><strong style='font-size:11px' >$user->DisplayName</strong></td>
			</tr>
			<tr>
				<td><strong style='font-size:12px'>$user->mail</strong></td>
			</tr>
			$delete_mailbox
			$delete_mailbox_zarafa
			</tbody>
		</table>
	</td>
</tr>
<tr>
	<td colspan=2 align='right'><div style='margin-top:15px;text-align:right'><hr>".button("{confirm_deletion_of}:$user->uid", "ConfirmDeletionOfUser();",16)."</div>
</table>";



$html="
<div id='deletion'>
	$user_infos
</div>
<script>
function unhookZarafaStoreCheck(){
	if(!document.getElementById('unhookZarafaStore')){return;}
	if(!document.getElementById('unhookZarafaStore').checked){
		document.getElementById('ZarafaCopyToPublic').disabled=true;
	}else{
		document.getElementById('ZarafaCopyToPublic').disabled=false;
	}
}
unhookZarafaStoreCheck();
</script>

";

$tpl=new templates();
echo $tpl->_ENGINE_parse_body($html,"domains.edit.user.php");
}

function Confirm(){
	
	if($_GET["delete-mailbox"]==1){
		$mbx=$_GET["uid"];
		$sock=new sockets();
		$sock->getFrameWork("cmd.php?DelMbx=$mbx");	
		$cmd="/usr/share/artica-postfix/bin/artica-install --delete-mailbox $mbx";
	}
	
	if(isset($_GET["unhookZarafaStore"])){
		$mbx=$_GET["uid"];
		$sock=new sockets();
		$sock->getFrameWork("zarafa.php?unhook-store=$mbx&ZarafaCopyToPublicAfter={$_GET["ZarafaCopyToPublic"]}");			
	}
	
	
	$user=new user($_GET["uid"]);
	$user->DeleteUser();
}

	
	
?>