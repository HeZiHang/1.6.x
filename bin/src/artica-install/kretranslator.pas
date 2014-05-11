unit kretranslator;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,IniFiles, Process,logs,unix,RegExpr in 'RegExpr.pas',zsystem;

  type
  tkretranslator=class


private
     LOGS:Tlogs;
     SYS:TSystem;
     artica_path:string;
     RetranslatorHttpdPort:integer;
     RetranslatorHttpdEnabled:integer;
     RetranslatorRegionSettings:string;
     RetranslatorUseProxy:string;
     RetranslatorProxyAddress:string;
     RetranslatorUseUpdateServerUrlOnly:string;
     RetranslatorUseUpdateServerUrl:string;
     RetranslatorUpdateServerUrl:string;
     RetranslatorRetranslateComponentsList:string;
     RetranslatorReportLevel:integer;
public
    RetranslatorEnabled:integer;
    procedure   Free;
    constructor Create(const zSYS:Tsystem);
    function    bin_path():string;
    procedure   START();
    procedure   STOP();
    function    STATUS():string;
    function    VERSION():string;
    procedure   CREATE_INITIAL_CONF();
    procedure   CREATE_HTTPD_CONF();
    function    conf_path():string;
    function    PID_NUM():string;
    function    PID_HTTP():string;
    function    LIGHTTPD_VERSION():string;
    function    RetranslationPath():string;
    function    PATTERN_DATE():string;
    procedure   KILL();

END;

implementation

constructor tkretranslator.Create(const zSYS:Tsystem);
begin
       forcedirectories('/etc/artica-postfix');
       LOGS:=tlogs.Create();
       SYS:=zSYS;

      if not TryStrToInt(SYS.GET_INFO('RetranslatorEnabled'),RetranslatorEnabled) then RetranslatorEnabled:=0;
      if not TryStrToInt(SYS.GET_INFO('RetranslatorHttpdPort'),RetranslatorHttpdPort) then RetranslatorHttpdPort:=80;
      if not TryStrToInt(SYS.GET_INFO('RetranslatorHttpdEnabled'),RetranslatorHttpdEnabled) then RetranslatorHttpdEnabled:=0;
      if not TryStrToInt(SYS.GET_INFO('RetranslatorReportLevel'),RetranslatorReportLevel) then RetranslatorReportLevel:=2;
      RetranslatorRegionSettings:=SYS.GET_INFO('RetranslatorRegionSettings');
      RetranslatorUseProxy:=SYS.GET_INFO('RetranslatorUseProxy');
      RetranslatorProxyAddress:=SYS.GET_INFO('RetranslatorProxyAddress');
      RetranslatorUseUpdateServerUrl:=SYS.GET_INFO('RetranslatorUseUpdateServerUrl');
      RetranslatorUpdateServerUrl:=SYS.GET_INFO('RetranslatorUpdateServerUrl');
      RetranslatorUseUpdateServerUrlOnly:=SYS.GET_INFO('RetranslatorUseUpdateServerUrlOnly');
      
      RetranslatorRetranslateComponentsList:=SYS.GET_INFO('RetranslatorRetranslateComponentsList');
      

      
      if length(RetranslatorRegionSettings)=0 then RetranslatorRegionSettings:='ru';
      if length(RetranslatorUseProxy)=0 then RetranslatorUseProxy:='no';
      if length(RetranslatorUseUpdateServerUrl)=0 then RetranslatorUseUpdateServerUrl:='no';
      if length(RetranslatorUseUpdateServerUrlOnly)=0 then RetranslatorUseUpdateServerUrlOnly:='no';
      if length(RetranslatorRetranslateComponentsList)=0 then RetranslatorRetranslateComponentsList:='AVS,CORE,BLST,UPDATER';

       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;
end;
//##############################################################################
procedure tkretranslator.free();
begin
    FreeAndNil(logs);
end;
//##############################################################################
function tkretranslator.BIN_PATH():string;
begin
   if FileExists(artica_path+'/bin/retranslator.bin') then exit(artica_path+'/bin/retranslator.bin');
end;
//##############################################################################
function tkretranslator.conf_path():string;
begin
ForceDirectories('/etc/kretranslator');
if not FileExists('/etc/kretranslator/retranslator.conf') then begin
   CREATE_INITIAL_CONF();
   exit('/etc/kretranslator/retranslator.conf');
end;
end;
//#############################################################################
function tkretranslator.PID_NUM():string;
begin
     if not FileExists('/var/run/kav-retranslator.pid') then begin
         result:=SYS.PidByProcessPath(bin_path());
         if length(trim(result))>0 then exit;
     end;

result:=SYS.PIDOF(bin_path());
end;
//##############################################################################
function tkretranslator.PID_HTTP():string;
begin
     if FileExists('/var/run/lighttpd/lighttpd-retranslator.pid') then begin
         result:=SYS.GET_PID_FROM_PATH('/var/run/lighttpd/lighttpd-retranslator.pid');
         exit;
     end;
end;
//##############################################################################
function tkretranslator.LIGHTTPD_VERSION():string;
var
     l:TstringList;
     RegExpr:TRegExpr;
     i:integer;
begin
    if not FileExists(SYS.LOCATE_LIGHTTPD_BIN_PATH()) then exit;

    fpsystem(SYS.LOCATE_LIGHTTPD_BIN_PATH()+' -v >/opt/artica/tmp/lighttpd.ver 2>&1');
    if not FileExists('/opt/artica/tmp/lighttpd.ver') then exit;
    l:=TStringList.Create;
    l.LoadFromFile('/opt/artica/tmp/lighttpd.ver');
    logs.DeleteFile('/opt/artica/tmp/lighttpd.ver');
    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='lighttpd-([0-9\.]+)';
    For i:=0 to l.Count-1 do begin
        if RegExpr.Exec(l.Strings[i]) then begin
            result:=RegExpr.Match[1];
        end;
    end;

    l.free;
    RegExpr.Free;
end;
//##############################################################################
procedure tkretranslator.KILL();
var
   pid:string;
   pidnum:integer;
   count:integer;
begin
  pid:=PID_NUM();
  if not SYS.PROCESS_EXIST(pid) then begin
      writeln('Stopping retranslator task...: Already stopped');
      exit;
  end;

   count:=0;
   while SYS.PROCESS_EXIST(pid) do begin
      TryStrToint(pid,pidnum);
      if pidnum>1 then begin
         writeln('Stopping retranslator task...: ' + pid + ' PID..');
         fpsystem('/bin/kill '+pid);
         sleep(200);
      end;
      if count>50 then begin
         writeln('Stopping retranslator task...: Force :' + pid + ' PID..');
         fpsystem('/bin/kill -9 '+ pid);
         break;
      end;
      inc(count);
      pid:=PID_NUM();

   end;

pid:=PID_NUM();
  if not SYS.PROCESS_EXIST(pid) then begin
      writeln('Stopping retranslator task...: Stopped');
      exit;
  end;
  writeln('Stopping retranslator task...: Failed');

end;


procedure tkretranslator.STOP();
 var
    count      :integer;
begin

     count:=0;

     logs.DeleteFile('/etc/artica-postfix/cache.global.status');
     if SYS.PROCESS_EXIST(PID_HTTP()) then begin
        writeln('Stopping retranslator httpd..: ' + PID_HTTP() + ' PID..');
        logs.OutputCmd('/bin/kill ' + PID_HTTP());
        while SYS.PROCESS_EXIST(PID_HTTP()) do begin
              sleep(100);
              inc(count);
              if count>100 then begin
                 writeln('Stopping retranslator httpd..: Failed force kill');
                 logs.OutputCmd('/bin/kill -9 '+PID_HTTP());
                 exit;
              end;
        end;

      end else begin
        writeln('Stopping retranslator httpd..: Already stopped');
     end;

end;
//##############################################################################
procedure tkretranslator.START();
var
   count:integer;
begin
forceDirectories('/var/db/kav/databases');
ForceDirectories('/var/db/kav/databases_backup');
ForceDirectories('/var/log/kretranslator');



logs.OutputCmd('/bin/chown -R '+SYS.GET_INFO('LighttpdUserAndGroup')+' /var/log/kretranslator');

if FileExists(SYS.LOCATE_LIGHTTPD_BIN_PATH()) then begin
   if RetranslatorHttpdEnabled=0 then begin
      logs.DebugLogs('Starting......: kav-retranslation http engine daemon is disabled');
      STOP();
      exit;
   end;
   
   if SYS.PROCESS_EXIST(PID_HTTP()) then begin
       logs.DebugLogs('Starting......: kav-retranslation http engine daemon is running');
       exit;
   end;
   
   logs.DebugLogs('Starting......: kav-retranslation http engine..');
   CREATE_HTTPD_CONF();
   CREATE_INITIAL_CONF();
   logs.OutputCmd(SYS.LOCATE_LIGHTTPD_BIN_PATH() + ' -f /etc/artica-postfix/lighttpd-retranslator.conf');
        count:=0;
        while not SYS.PROCESS_EXIST(PID_HTTP()) do begin
              sleep(100);
              inc(count);
              if count>100 then begin
                  logs.DebugLogs('Starting......: kav-retranslation http engine timeout..');
                  break;
              end;
        end;
   
if not SYS.PROCESS_EXIST(PID_HTTP()) then begin
     logs.DebugLogs('Starting......: kav-retranslation http engine failed');
end else begin
     logs.DebugLogs('Starting......: kav-retranslation http engine succes PID '+PID_HTTP());
end;

   
end;


end;
//##############################################################################
function tkretranslator.STATUS():string;
var
   ini:TstringList;
   pid,pidpath:string;
begin

 pid:=PID_NUM();
 ini:=TstringList.Create;
 if not FileExists(bin_path()) then exit;

 ini.Add('[KRETRANSLATOR]');
 if SYS.PROCESS_EXIST(pid) then ini.Add('running=1') else  ini.Add('running=0');
 ini.Add('master_pid='+pid);
 ini.Add('master_version='+VERSION());
 ini.Add('application_installed=1');
 ini.Add('master_memory='+ IntToStr(SYS.PROCESS_MEMORY(pid)));
 ini.Add('status='+SYS.PROCESS_STATUS(pid));
 ini.Add('service_name=APP_KRETRANSLATOR');
 ini.Add('service_disabled='+IntToStr(RetranslatorEnabled));
 ini.Add('service_croned=1');
 ini.Add('pattern_version='+PATTERN_DATE());
 ini.Add('service_cmd=retranslator-tsk');
 ini.Add('');
pidpath:=logs.FILE_TEMP();
fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.status.php --retranslator >'+pidpath +' 2>&1');
ini.Add(logs.ReadFromFile(pidpath));
logs.DeleteFile(pidpath);

result:=ini.Text;
ini.Free;



end;
//##############################################################################
procedure tkretranslator.CREATE_INITIAL_CONF();
var
   l:TstringList;
begin
forcedirectories('/etc/kretranslator');
l:=TstringList.Create;
l.Add('[path]');
l.Add('RetranslationPath=/var/db/kav/databases');
l.Add('TempPath=/tmp');
l.Add('[locale]');
l.Add('DateFormat=%d-%m-%Y');
l.Add('TimeFormat=%H:%M:%S');
l.Add('[updater.path]');
l.Add('BackUpPath=/var/db/kav/databases_backup');
l.Add('PidFile=/var/run/kav-retranslator.pid');
l.Add('[updater.options]');
l.Add('RetranslateComponentsList='+RetranslatorRetranslateComponentsList);
l.Add('Index=u0607g.xml');
l.Add('IndexRelativeServerPath=index');
l.Add('UseUpdateServerUrl='+RetranslatorUseUpdateServerUrl);
l.Add('UseUpdateServerUrlOnly='+RetranslatorUseUpdateServerUrlOnly);
l.Add('UpdateServerUrl='+RetranslatorUpdateServerUrl);
l.Add('RegionSettings='+RetranslatorRegionSettings);
l.Add('ConnectTimeout=20');
l.Add('KeepSilent=no');
l.Add('UseProxy='+RetranslatorUseProxy);
l.Add('ProxyAddress='+RetranslatorProxyAddress);
l.Add('PassiveFtp=no');
l.Add('PostRetranslateCmd=');
l.Add('[updater.report]');
l.Add('Append=no');
l.Add('ReportFileName=/var/log/kretranslator/retranslator.log');
l.Add('ReportLevel='+IntToStr(RetranslatorReportLevel));
l.SaveToFile('/etc/kretranslator/retranslator.conf');
end;
//##############################################################################
function tkretranslator.RetranslationPath():string;
var ini:TiniFile;

begin
   if not FileExists('/etc/kretranslator/retranslator.conf') then exit;
   ini:=TiniFile.Create('/etc/kretranslator/retranslator.conf');
   result:=ini.ReadString('path','RetranslationPath','/var/db/kav/databases');
   ini.free;
end;
//##############################################################################





procedure tkretranslator.CREATE_HTTPD_CONF();
var
   l:TstringList;
begin

l:=TstringList.Create;

l.Add('#artica-postfix saved by artica ' + logs.DateTimeNowSQL());
l.Add('');
l.Add('server.modules = (');
l.Add('	"mod_alias",');
l.Add('	"mod_access",');
l.Add('	"mod_accesslog",');
l.Add('	"mod_compress",');
l.Add('	"mod_fastcgi",');
l.Add('	"mod_status",');
l.Add('	"mod_setenv" )');
l.Add('');
l.Add('server.document-root        = "/var/db/kav/databases"');
l.Add('server.username = "www-data"');
l.Add('server.groupname = "www-data"');
l.Add('server.errorlog             = "/var/log/kretranslator/retranslator-error.log"');
l.Add('index-file.names            = ( "index.xml")');
l.Add('');
l.Add('mimetype.assign             = (');
l.Add('	".pdf"          =>      "application/pdf",');
l.Add('	".sig"          =>      "application/pgp-signature",');
l.Add('	".spl"          =>      "application/futuresplash",');
l.Add('	".class"        =>      "application/octet-stream",');
l.Add('	".ps"           =>      "application/postscript",');
l.Add('	".torrent"      =>      "application/x-bittorrent",');
l.Add('	".dvi"          =>      "application/x-dvi",');
l.Add('	".gz"           =>      "application/x-gzip",');
l.Add('	".pac"          =>      "application/x-ns-proxy-autoconfig",');
l.Add('	".swf"          =>      "application/x-shockwave-flash",');
l.Add('	".tar.gz"       =>      "application/x-tgz",');
l.Add('	".tgz"          =>      "application/x-tgz",');
l.Add('	".tar"          =>      "application/x-tar",');
l.Add('	".zip"          =>      "application/zip",');
l.Add('	".mp3"          =>      "audio/mpeg",');
l.Add('	".m3u"          =>      "audio/x-mpegurl",');
l.Add('	".wma"          =>      "audio/x-ms-wma",');
l.Add('	".wax"          =>      "audio/x-ms-wax",');
l.Add('	".ogg"          =>      "application/ogg",');
l.Add('	".wav"          =>      "audio/x-wav",');
l.Add('	".gif"          =>      "image/gif",');
l.Add('	".jar"          =>      "application/x-java-archive",');
l.Add('	".jpg"          =>      "image/jpeg",');
l.Add('	".jpeg"         =>      "image/jpeg",');
l.Add('	".png"          =>      "image/png",');
l.Add('	".xbm"          =>      "image/x-xbitmap",');
l.Add('	".xpm"          =>      "image/x-xpixmap",');
l.Add('	".xwd"          =>      "image/x-xwindowdump",');
l.Add('	".css"          =>      "text/css",');
l.Add('	".html"         =>      "text/html",');
l.Add('	".htm"          =>      "text/html",');
l.Add('	".js"           =>      "text/javascript",');
l.Add('	".asc"          =>      "text/plain",');
l.Add('	".c"            =>      "text/plain",');
l.Add('	".cpp"          =>      "text/plain",');
l.Add('	".log"          =>      "text/plain",');
l.Add('	".conf"         =>      "text/plain",');
l.Add('	".text"         =>      "text/plain",');
l.Add('	".txt"          =>      "text/plain",');
l.Add('	".dtd"          =>      "text/xml",');
l.Add('	".xml"          =>      "text/xml",');
l.Add('	".mpeg"         =>      "video/mpeg",');
l.Add('	".mpg"          =>      "video/mpeg",');
l.Add('	".mov"          =>      "video/quicktime",');
l.Add('	".qt"           =>      "video/quicktime",');
l.Add('	".avi"          =>      "video/x-msvideo",');
l.Add('	".asf"          =>      "video/x-ms-asf",');
l.Add('	".asx"          =>      "video/x-ms-asf",');
l.Add('	".wmv"          =>      "video/x-ms-wmv",');
l.Add('	".bz2"          =>      "application/x-bzip",');
l.Add('	".tbz"          =>      "application/x-bzip-compressed-tar",');
l.Add('	".tar.bz2"      =>      "application/x-bzip-compressed-tar",');
l.Add('	""              =>      "application/octet-stream",');
l.Add(' )');
l.Add('');
l.Add('');
l.Add('accesslog.filename          = "/var/log/kretranslator/retranslator-access.log"');
l.Add('url.access-deny             = ( "~", ".inc" )');
l.Add('');
l.Add('');
l.Add('server.port                 = '+IntToStr(RetranslatorHttpdPort));
l.Add('#server.bind                = "127.0.0.1"');
l.Add('server.pid-file             = "/var/run/lighttpd/lighttpd-retranslator.pid"');
l.Add('server.max-fds 		    = 2048');
l.Add('status.status-url          = "/server-status"');
l.Add('status.config-url          = "/server-config"');
l.Add('');
l.Add('');
l.SaveToFile('/etc/artica-postfix/lighttpd-retranslator.conf');
l.Free;
logs.DebugLogs('Starting......: kav-retranslation set configuration listen='+IntToStr(RetranslatorHttpdPort) + ' port done');
end;


function tkretranslator.VERSION():string;
var
   RegExpr        :TRegExpr;
   F              :TstringList;
   T              :string;
   i              :integer;
begin
   result:='';
   if not FileExists(BIN_PATH()) then exit;

   t:=logs.FILE_TEMP();
   fpsystem(BIN_PATH()+' -v >'+t+' 2>&1');
   if not FileExists(t) then exit;
   f:=TstringList.Create;
   f.LoadFromFile(t);
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='Kaspersky Retranslator\s+(.+?),';
   For i:=0 to f.Count-1 do begin
   if RegExpr.Exec(f.Strings[i]) then begin
      result:=trim(RegExpr.Match[1]);
      break;
   end;
   end;

   RegExpr.Free;
   f.free;
end;
//#############################################################################
function tkretranslator.PATTERN_DATE():string;
var
   tmp            :string;
   RegExpr        :TRegExpr;
   F              :TstringList;
   i              :integer;
   patterndate    :string;
   fdate          :string;
begin
   result:='';
   tmp:=RetranslationPath()+'/bases/av/avc/i386/av-i386-0607g.xml';
   if not FileExists(tmp) then begin
      logs.Debuglogs('Unable to stat ' + tmp);
      exit;
   end;




   f:=TstringList.Create;
   f.LoadFromFile(tmp);
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='UpdateDate=.+?([0-9\s]+)';
   For i:=0 to f.Count-1 do begin
   if RegExpr.Exec(f.Strings[i]) then begin
      patterndate:=trim(RegExpr.Match[1]);
      break;
   end;
   end;
      f.free;
   
   if length(patterndate)=0 then begin
       logs.Debuglogs('Unable to understand ' + tmp);
       exit;
   end;
   
   RegExpr.Expression:='(\d{1,2})(\d{1,2})(\d{1,4})\s+(\d{1,2})(\d{1,2})';
   if RegExpr.Exec(patterndate) then begin
     fdate:=RegExpr.Match[3]+'-'+RegExpr.Match[1]+'-'+RegExpr.Match[2]+ ' '+RegExpr.Match[4]+':'+RegExpr.Match[5]+':00';

   end else begin
        logs.Debuglogs('tkretranslator.PATTERN_DATE() failed to get informations from '+patterndate);
   end;
   

   result:=fdate;
   RegExpr.Free;

end;
//#############################################################################




end.
