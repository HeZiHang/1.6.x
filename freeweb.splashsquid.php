<?php
	session_start();
	if($_SESSION["uid"]==null){echo "window.location.href ='logoff.php';";die();}
	include_once('ressources/class.templates.inc');
	include_once('ressources/class.ldap.inc');
	include_once('ressources/class.users.menus.inc');
	include_once('ressources/class.pure-ftpd.inc');
	include_once('ressources/class.apache.inc');
	include_once('ressources/class.freeweb.inc');
	include_once('ressources/class.user.inc');
	include_once('ressources/class.system.network.inc');

//freeweb_slashsquid
	if(isset($_GET["upload-pic-js"])){upload_pic_js();exit;}
	if(isset($_GET["upload-pic-popup"])){upload_pic_popup();exit;}
	if( isset($_GET['TargetpathUploaded']) ){upload_form_perform();exit();}
	if(isset($_GET["getimage"])){getimage();exit;}
	if(isset($_POST["servername"])){save();exit;}
page();


function page(){
	$tpl=new templates();
	$page=CurrentPageName();
	$q=new mysql();
	$servername=$_GET["servername"];
	$q=new mysql();
	$t=time();
	$sql="SELECT * FROM freeweb_slashsquid WHERE servername='$servername'";
	$ligne=mysql_fetch_array($q->QUERY_SQL($sql,"artica_backup"));
	$params=unserialize(base64_decode($ligne["params"]));
	if($params["title"]==null){$params["title"]="HotSpot Authentication page";}
	
	$subtitle=$ligne["subtitle"];
	if($subtitle==null){$subtitle="To access to internet, set your username and password here";}
	$html="
	<div id='anim-$t'></div>
	<table style='width:100%' class=form>
	<tr>
		<td valign='top' class=legend style='font-size:16px'>{background_color}</td>
		<td>". Field_text("backgroundcolor",$ligne["backgroundcolor"],"font-size:16px;width:90px")."</td>
	</tR>
	<tr>
		<td valign='top' class=legend style='font-size:16px'>{title2}:</td>
		<td>". Field_text("title",$params["title"],"font-size:16px;width:290px")."</td>
	</tR>	
	<tr>
		<td valign='top' class=legend style='font-size:16px'>{debug}:</td>
		<td>". Field_checkbox("debug_auth",1,$ligne["debug_auth"])."</td>
	</tR>	
	<tr>
		<td valign='top' class=legend style='font-size:16px'>{subtitle}</td>
		<td><textarea style='width:100%;height:75px;font-size:16px;border:4px solid #CCCCCC;font-family:\"Courier New\",
	Courier,monospace;background-color:white;color:black' id='subtitle'>$subtitle</textarea></td>
	</tr>	
	<tr>
		<td colspan=2 align='right'><hr>".button("{apply}","Save$t()",18)."</td>
	</tr>
	</table>
	<center style='margin:10px;border:4px solid #CCCCCC;padding:10px'>
	<a href=\"javascript:blur()\" OnClick=\"javascript:Loadjs('$page?upload-pic-js=yes&servername=$servername');\" class=\"coverWrap\">
	<img src='$page?getimage=$servername&t=$t'>
	</a>
	</center>

<script>
	var xSave$t=function(obj){
      var tempvalue=obj.responseText;
      if(tempvalue.length>3){alert(tempvalue);}
      RefreshTab('main_config_freewebedit');
     }
	
	function Save$t(){
			var XHR = new XHRConnection();
			var debug_auth=0;
			XHR.appendData('backgroundcolor',document.getElementById('backgroundcolor').value);
			XHR.appendData('title',encodeURIComponent(document.getElementById('title').value));
			if(document.getElementById('debug_auth').checked){debug_auth=1;}
			XHR.appendData('subtitle',encodeURIComponent(document.getElementById('subtitle').value));
			XHR.appendData('debug_auth','debug_auth');
			XHR.appendData('servername','$servername');
			AnimateDiv('anim-$t');
			XHR.sendAndLoad('$page', 'POST',xSave$t);
			
			}	
	</script>
			
			
			
	";
	
	echo $tpl->_ENGINE_parse_body($html);
	
	
	
}

function save(){
	$servername=$_POST["servername"];
	$q=new mysql();
	if(!$q->TABLE_EXISTS("freeweb_slashsquid", "artica_backup")){
		$q->BuildTables();
	}
	
	
	$_POST["subtitle"]=url_decode_special_tool($_POST["subtitle"]);
	
	$sql="SELECT servername,params FROM freeweb_slashsquid WHERE servername='$servername'";
	$ligne=mysql_fetch_array($q->QUERY_SQL($sql,"artica_backup"));
	if($ligne["servername"]<>null){
		$params=unserialize(base64_decode($ligne["$params"]));
		$params["title"]=url_decode_special_tool($_POST["title"]);
		$params1=base64_encode(serialize($params));
		$sql="UPDATE freeweb_slashsquid 
		SET backgroundcolor='".$_POST["backgroundcolor"]."',
		subtitle='".mysql_escape_string2($_POST["subtitle"])."',
		debug_auth='".mysql_escape_string2($_POST["debug_auth"])."',
		params='".mysql_escape_string2($params1)."' 
		WHERE servername='$servername'";
	
	}else{
		$params["title"]=url_decode_special_tool($_POST["title"]);
		$params1=base64_encode(serialize($params));
		$sql="INSERT INTO freeweb_slashsquid (backgroundcolor,subtitle,debug_auth,params,servername)
		VALUES ('{$_POST["backgroundcolor"]}',
		'".mysql_escape_string2($_POST["subtitle"])."',
		'".mysql_escape_string2($_POST["debug_auth"])."',
		'".mysql_escape_string2($params1)."', '$servername');";
		
		
	}
	$q->QUERY_SQL($sql,"artica_backup");	
	if(!$q->ok){echo $q->mysql_error;}
}

function getimage(){
	$servername=$_GET["getimage"];
	$q=new mysql();
	$sql="SELECT * FROM freeweb_slashsquid WHERE servername='$servername'";
	$ligne=mysql_fetch_array($q->QUERY_SQL($sql,"artica_backup"));
	if(strlen($ligne["logoimg"])==0){
		$fsize = filesize("ressources/templates/Squid/i/logo-captive.png");
		header("Content-type: image/png");
		header("Content-Disposition: attachment; filename=\"logo-captive.png\";" );
		header("Content-Transfer-Encoding: binary");
		header("Content-Length: ".$fsize);		
		readfile("ressources/templates/Squid/i/logo-captive.png");
		ob_clean();
		flush();		
		return;
	}
	$path_info = pathinfo($ligne["logoname"]);
	$ext=$path_info['extension'];	
	header("Content-Type: image/$ext");
	$fsize = strlen($ligne["logoimg"]);
	header("Content-Disposition: attachment; filename=\"{$ligne["logoname"]}\";" );
	header("Content-Transfer-Encoding: binary");
	header("Content-Length: ".$fsize);
	ob_clean();
	flush();
	echo $ligne["logoimg"];
	
	
	
}


function upload_pic_js(){
	$page=CurrentPageName();
	$tpl=new templates();
	$title=$tpl->javascript_parse_text("{change_logo}");
	$servername=$_GET["servername"];
	$html="YahooWin4('550','$page?upload-pic-popup=yes&servername=$servername','$title')";
	echo $html;
}

function upload_pic_popup(){
	$servername=$_GET["servername"];
	$page=CurrentPageName();
	$tpl=new templates();
	$UploadAFile=$tpl->javascript_parse_text("{upload_your_picture} 393x125");
	$allowedExtensions="'jpg','jpeg','png'";
	if($allowedExtensions<>null){
		$allowedExtensions="allowedExtensions: [$allowedExtensions],";
	}
	$UploadAFile=str_replace(" ", "&nbsp;", $UploadAFile);
	$html="
	<div id='file-uploader-demo1' style='width:100%;text-align:center'>
	<noscript>
	<!-- or put a simple form for upload here -->
	</noscript>
	</div>
	<script>
	function createUploader(){
	var uploader = new qq.FileUploader({
	element: document.getElementById('file-uploader-demo1'),
	action: '$page',$allowedExtensions
	template: '<div class=\"qq-uploader\">' +
	'<div class=\"qq-upload-drop-area\"><span>Drop files here to upload</span></div>' +
	'<div class=\"qq-upload-button\" style=\"width:100%\">&nbsp;&laquo;&nbsp;$UploadAFile&nbsp;&raquo;&nbsp;</div>' +
	'<ul class=\"qq-upload-list\"></ul>' +
	'</div>',
	debug: false,
	params: {
	TargetpathUploaded: '{$_GET["upload-file"]}',
	servername: '$servername',
	//select-file: '{$_GET["select-file"]}'
				    },
			onComplete: function(id, fileName){
			RefreshTab('main_config_freewebedit');
}
});
}

createUploader();
</script>
";

//$html="<iframe style='width:100%;height:250px;border:1px' src='$page?form-upload={$_GET["upload-file"]}&select-file={$_GET["select-file"]}'></iframe>";
	echo $html;
//url("/ressources/templates/Squid/i/logo-captive.png") no-repeat scroll 0 0 transparent
}

function upload_form_perform(){
	usleep(300);
	writelogs("upload_form_perform() -> OK {$_GET['qqfile']}",__FUNCTION__,__FILE__,__LINE__);
	$sock=new sockets();
	$sock->getFrameWork("services.php?lighttpd-own=yes");

	if (isset($_GET['qqfile'])){
		$fileName = $_GET['qqfile'];
		if(function_exists("apache_request_headers")){
			$headers = apache_request_headers();
			if ((int)$headers['Content-Length'] == 0){
				writelogs("content length is zero",__FUNCTION__,__FILE__,__LINE__);
				die ('{error: "content length is zero"}');
			}
		}else{
			writelogs("apache_request_headers() no such function",__FUNCTION__,__FILE__,__LINE__);
		}
	} elseif (isset($_FILES['qqfile'])){
		$fileName = basename($_FILES['qqfile']['name']);
		writelogs("_FILES['qqfile']['name'] = $fileName",__FUNCTION__,__FILE__,__LINE__);
		if ($_FILES['qqfile']['size'] == 0){
			writelogs("file size is zero",__FUNCTION__,__FILE__,__LINE__);
			die ('{error: "file size is zero"}');
		}
	} else {
		writelogs("file not passed",__FUNCTION__,__FILE__,__LINE__);
		die ('{error: "file not passed"}');
	}

	writelogs("upload_form_perform() -> OK {$_GET['qqfile']}",__FUNCTION__,__FILE__,__LINE__);

	if (count($_GET)){
		$datas=json_encode(array_merge($_GET, array('fileName'=>$fileName)));
		writelogs($datas,__FUNCTION__,__FILE__,__LINE__);

	} else {
		writelogs("query params not passed",__FUNCTION__,__FILE__,__LINE__);
		die ('{error: "query params not passed"}');
	}
	writelogs("upload_form_perform() -> OK {$_GET['qqfile']} upload_max_filesize=".ini_get('upload_max_filesize')." post_max_size:".ini_get('post_max_size'),__FUNCTION__,__FILE__,__LINE__);
	include_once(dirname(__FILE__)."/ressources/class.file.upload.inc");
	$allowedExtensions = array();
	$sizeLimit = qqFileUploader::toBytes(ini_get('upload_max_filesize'));
	$sizeLimit2 = qqFileUploader::toBytes(ini_get('post_max_size'));

	if($sizeLimit2<$sizeLimit){$sizeLimit=$sizeLimit2;}

	$content_dir=dirname(__FILE__)."/ressources/conf/upload/";
	$uploader = new qqFileUploader($allowedExtensions, $sizeLimit);
	$result = $uploader->handleUpload($content_dir);

	writelogs("upload_form_perform() -> OK $resultTXT",__FUNCTION__,__FILE__,__LINE__);
	$servername=$_GET["servername"];
	$TargetpathUploaded=base64_decode($_GET["TargetpathUploaded"]);

	if(!is_file("$content_dir$fileName")){
		die ("{error: \"$content_dir$fileName no such file \"}");
	}
	include_once(dirname(__FILE__).'/ressources/class.images.inc');
	$base="ressources/profiles/icons";
	$uid=time();
	$jpeg_filename="$content_dir$fileName";
	$jpegPhoto_datas=file_get_contents("$content_dir$fileName");
	$image=new images($jpeg_filename);
	$jpeg_dimensions=@getimagesize($jpeg_filename);
	$img_type=array(1=>"gif",2=>'jpg',3=>'png',4=>'swf',5=>'psd',6=>'bmp',7=>'tiff',8=>'tiff',9=>'jpc',10=>'jp2',11=>'jpx');
	$extension="{$img_type[$jpeg_dimensions[2]]}";
	$thumbnail_path="$base/background-$servername.$extension";
	if(!$image->thumbnail(393,125,$thumbnail_path)){
		die ("{error: \"Create image error\"}");
	}
	$tpl=new templates();
	$thumbnail_data=@file_get_contents($thumbnail_path);
	$q=new mysql();
	if(!$q->TABLE_EXISTS("freeweb_slashsquid", "artica_backup")){
		$q->BuildTables();
	}
	$sql="SELECT servername FROM freeweb_slashsquid WHERE servername='$servername'";
	$ligne=mysql_fetch_array($q->QUERY_SQL($sql,"artica_backup"));
	if($ligne["servername"]<>null){
		$sql="UPDATE freeweb_slashsquid SET logoname='".basename($thumbnail_path)."',
		logoimg='".mysql_escape_string2($thumbnail_data)."' WHERE servername='$servername'";	
				
	}else{
		$sql="INSERT INTO freeweb_slashsquid (logoname,logoimg,servername) 
		VALUES ('".basename($thumbnail_path)."','".mysql_escape_string2($thumbnail_data)."','$servername')";
	}
	$q->QUERY_SQL($sql,"artica_backup");
	if(!$q->ok){die ("{error: \"". $tpl->javascript_parse_text("$q->mysql_error")."\"}");}
	echo htmlspecialchars(json_encode($result), ENT_NOQUOTES);
	return;

}