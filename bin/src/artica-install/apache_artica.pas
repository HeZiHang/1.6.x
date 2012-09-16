unit apache_artica;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,IniFiles, Process,md5,logs,unix,RegExpr in 'RegExpr.pas',zsystem,openldap;

  type
  tapache_artica=class


private
     LOGS:Tlogs;
     D:boolean;
     GLOBAL_INI:TiniFIle;
     SYS:TSystem;
     artica_path:string;


     function   ADD_MODULE(moduleso_file:string):string;
     function   START_COMMAND():string;
     function   CERTIFICATE_SERVER_NAME():boolean;
     function   COMPILATION_VALUE(KEY_NAME_STRING:string):string;
     procedure  MIME_TYPES_DIRECTIVES();
     function   AuthorizedModule(module_so:string):boolean;
     procedure  BuildConf();
public
    procedure   Free;
    constructor Create(const zSYS:Tsystem);
    function  BIN_PATH():string;
    function  CONFIG_PATH():string;
    function  VERSION():string;
    function  PID_NUM():string;
    procedure START();
    procedure STOP();
    function  STATUS():string;
    function  APACHE_ARTICA_SSL_KEY():string;
    function  SET_MODULES():string;


END;

implementation

constructor tapache_artica.Create(const zSYS:Tsystem);
begin
       forcedirectories('/etc/artica-postfix');
       LOGS:=tlogs.Create();
       SYS:=zSYS;






       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;
end;
//##############################################################################
procedure tapache_artica.free();
begin
    FreeAndNil(logs);
end;
//##############################################################################
function tapache_artica.CONFIG_PATH():string;
begin
if FileExists('/etc/artica-postfix/settings/Daemons/httpdCONF') then exit('/etc/artica-postfix/settings/Daemons/httpdCONF');
if FileExists('/usr/share/artica-postfix/bin/install/apache/httpd.conf') then exit('/usr/share/artica-postfix/bin/install/apache/httpd.conf');
end;
//##############################################################################
function tapache_artica.BIN_PATH():string;
begin
result:=SYS.LOCATE_APACHE_BIN_PATH();
end;
//##############################################################################
function tapache_artica.START_COMMAND():string;
begin
result:=BIN_PATH()+' -f '+CONFIG_PATH();
end;
//##############################################################################

function tapache_artica.VERSION():string;
  var
   RegExpr:TRegExpr;
   tmpstr:string;
   l:TstringList;
   i:integer;
   path:string;
begin
 path:=SYS.LOCATE_APACHE_BIN_PATH();
     if not FileExists(path) then begin
        logs.Debuglogs('tapache_artica.VERSION():: Apache is not installed');
        exit;
     end;

    result:=SYS.GET_CACHE_VERSION('APP_APACHE_ARTICA');
   if length(result)>0 then exit;

   tmpstr:=logs.FILE_TEMP();
   fpsystem(path+' -v >'+tmpstr+' 2>&1');


     l:=TstringList.Create;
     RegExpr:=TRegExpr.Create;
     l.LoadFromFile(tmpstr);
     RegExpr.Expression:='Server version: Apache/([0-9\.]+)';
     for i:=0 to l.Count-1 do begin
         if RegExpr.Exec(l.Strings[i]) then begin
            result:=RegExpr.Match[1];
            result:=trim(result);
            break;
         end;
     end;
l.Free;
RegExpr.free;
SYS.SET_CACHE_VERSION('APP_APACHE_ARTICA',result);
logs.Debuglogs('APP_APACHE_ARTICA:: -> ' + result);
end;
//#############################################################################
procedure tapache_artica.START();
var
   pid:string;
   count:integer;
   LOCK_PATH:string;
   pid_path:string;
   bin_path:string;

begin

     pid:=PID_NUM();

 if SYS.PROCESS_EXIST(pid) then begin
      logs.DebugLogs('Starting......: Apache daemon already running PID '+pid);
      exit;
 end;

     bin_path:=SYS.LOCATE_APACHE_BIN_PATH();



     if not FileExists('/etc/ssl/certs/apache/server.key') then APACHE_ARTICA_SSL_KEY();
     if not FileExists('/etc/ssl/certs/apache/server.crt') then APACHE_ARTICA_SSL_KEY();
     logs.DebugLogs('Starting......: Apache daemon libphp....:'+SYS.LOCATE_APACHE_LIBPHP5());
     logs.DebugLogs('Starting......: Apache daemon mod_ssl...:'+SYS.LOCATE_APACHE_MODSSLSO());


     BuildConf();
     CERTIFICATE_SERVER_NAME();
     MIME_TYPES_DIRECTIVES();
     logs.Debuglogs(START_COMMAND());
     fpsystem(START_COMMAND());

 count:=0;
 while not SYS.PROCESS_EXIST(PID_NUM()) do begin
              sleep(150);
              inc(count);
              if count>50 then begin
                 logs.DebugLogs('Starting......: Apache daemon. (timeout!!!)');
                 logs.DebugLogs('Starting......: Apache daemon. "'+START_COMMAND()+'" failed');
                 break;
              end;
        end;

 pid:=PID_NUM();
 if SYS.PROCESS_EXIST(pid) then begin
      logs.DebugLogs('Starting......: Apache daemon with new PID '+pid);
 end;



end;
//##############################################################################
function tapache_artica.SET_MODULES():string;
var
i:integer;
APACHE_MODULES_PATH:string;
l:Tstringlist;
xmod:string;
lnpath:string;
begin
l:=Tstringlist.Create;
APACHE_MODULES_PATH:=SYS.LOCATE_APACHE_MODULES_PATH();

if length(APACHE_MODULES_PATH)=0 then begin
    logs.DebugLogs('Starting......: Apache daemon unable to locate modules path');
    result:='';
    exit;
end;
lnpath:=SYS.LOCATE_GENERIC_BIN('ln');
if DirectoryExists('/usr/lib/apache2') then begin
   if Not FileExists('/usr/lib/apache2/mod_ssl.so') then begin
      if FIleExists('/usr/lib/apache2-prefork/mod_ssl.so') then fpsystem(lnpath+' -s /usr/lib/apache2-prefork/mod_ssl.so /usr/lib/apache2/mod_ssl.so');
   end;
end;


logs.DebugLogs('Starting......: Apache daemon modules are stored in '+APACHE_MODULES_PATH);
SYS.DirFiles(SYS.LOCATE_APACHE_MODULES_PATH(),'*.so');
 for i:=0 to SYS.DirListFiles.Count-1 do begin
       xmod:=trim(ADD_MODULE(SYS.DirListFiles.Strings[i]));
       if length(xmod)=0 then begin
          logs.DebugLogs('Apache daemon refused mod:"'+SYS.DirListFiles.Strings[i]+'"');
          continue;
       end;
       logs.DebugLogs('Starting......: Apache daemon add mod:"'+SYS.DirListFiles.Strings[i]+'"');
       l.Add(ADD_MODULE(SYS.DirListFiles.Strings[i]));
end;

if FileExists('/usr/lib/apache-extramodules/mod_php5.so') then begin
   logs.DebugLogs('Starting......: Apache daemon add mod:"mod_php5.so"');
   l.add('LoadModule php5_module'+chr(9)+'/usr/lib/apache-extramodules/mod_php5.so');
end;


logs.DebugLogs('Starting......: Apache daemon '+IntTOstr(l.Count) +' modules');
result:=l.Text;

end;

//##############################################################################
function tapache_artica.ADD_MODULE(moduleso_file:string):string;

 const
            CR = #$0d;
            LF = #$0a;
            CRLF = CR + LF;
  var
   RegExpr:TRegExpr;
   ADD:boolean;
   l:TstringList;
   i:integer;
   moduleso_file_pattern:string;
   APACHE_MODULES_PATH:string;
   module_name:string;
begin
moduleso_file:=trim(moduleso_file);
APACHE_MODULES_PATH:=SYS.LOCATE_APACHE_MODULES_PATH();


if moduleso_file='mod_perl.so' then begin
    result:='LoadModule perl_module'+chr(9)+APACHE_MODULES_PATH+'/'+moduleso_file;
    exit;
end;

if moduleso_file='mod_log_config.so' then begin
    result:='LoadModule log_config_module'+chr(9)+APACHE_MODULES_PATH+'/'+moduleso_file;
    exit;
end;

if moduleso_file='mod_vhost_ldap.so' then begin
    result:='LoadModule vhost_ldap_module'+chr(9)+APACHE_MODULES_PATH+'/'+moduleso_file;
    exit;
end;


if moduleso_file='mod_ldap.so' then begin
    result:='LoadModule ldap_module'+chr(9)+APACHE_MODULES_PATH+'/'+moduleso_file;
    if FileExists(APACHE_MODULES_PATH+'/mod_authnz_ldap.so') then result:=result+CRLF+'LoadModule authnz_ldap_module'+chr(9)+APACHE_MODULES_PATH+'/mod_authnz_ldap.so';
    exit;
end;

if moduleso_file='mod_rewrite.so' then begin
    result:='LoadModule rewrite_module'+chr(9)+APACHE_MODULES_PATH+'/'+moduleso_file;
    exit;
end;

if moduleso_file='mod_dav.so' then begin
    result:='LoadModule dav_module'+chr(9)+APACHE_MODULES_PATH+'/'+moduleso_file;
    if FileExists(APACHE_MODULES_PATH+'/mod_dav_fs.so') then result:=result+CRLF+'LoadModule dav_fs_module'+chr(9)+APACHE_MODULES_PATH+'/mod_dav_fs.so';
    exit;
end;


if moduleso_file='mod_suexec.so' then begin
    result:='LoadModule suexec_module'+chr(9)+APACHE_MODULES_PATH+'/'+moduleso_file;
    exit;
end;
if moduleso_file='mod_php5.so' then begin
    result:='LoadModule php5_module'+chr(9)+APACHE_MODULES_PATH+'/'+moduleso_file;
    exit;
end;



if not AuthorizedModule(moduleso_file) then exit;
if moduleso_file='mod_proxy_connect.so' then exit;
if moduleso_file='mod_dav_lock.so' then exit;
if moduleso_file='mod_mem_cache.so' then exit;
if moduleso_file='mod_cgid.so' then exit;
if moduleso_file='mod_proxy.so' then exit;
if moduleso_file='mod_proxy_http.so' then exit;
if moduleso_file='mod_proxy_ajp.so' then exit;




ADD:=false;
moduleso_file_pattern:=AnsiReplaceText(moduleso_file,'.','\.');
RegExpr:=TRegExpr.CReate;
RegExpr.Expression:='^mod_(.+?)\.so';
if RegExpr.Exec(moduleso_file) then begin
     module_name:=RegExpr.Match[1]+'_module';
end else begin
    RegExpr.Expression:='^(.+?)\.so';
    module_name:=RegExpr.Match[1]+'_module';
end;


if moduleso_file='libphp5.so' then module_name:='php5_module';
result:='LoadModule '+ module_name+chr(9)+APACHE_MODULES_PATH+'/'+moduleso_file;
end;
//##############################################################################
function tapache_artica.AuthorizedModule(module_so:string):boolean;
var
   l:Tstringlist;
   i:integer;
begin

l:=Tstringlist.Create;
result:=false;
l.add('mod_alias.so');
l.add('mod_auth_basic.so');
l.add('mod_authn_file.so');
l.add('mod_authz_default.so');
l.add('mod_authz_groupfile.so');
l.add('mod_authz_host.so');
l.add('mod_authz_user.so');
l.add('mod_autoindex.so');
l.add('mod_cgi.so');
l.add('mod_deflate.so');
l.add('mod_dir.so');
l.add('mod_env.so');
l.add('mod_mime.so');
l.add('mod_negotiation.so');
l.add('libphp5.so');
l.add('mod_php5.so');
l.add('mod_setenvif.so');
l.add('mod_status.so');
l.add('mod_ssl.so');
L.add('mod_dav.so');
l.add('mod_ldap.so');
l.add('mod_suexec.so');
for i:=0 to l.Count-1 do begin
    if l.Strings[i]=module_so then begin
       result:=true;
       break;
    end;

end;
l.free;

end;




procedure tapache_artica.BuildConf();
var
   l:Tstringlist;
   username:string;
   group:string;
   RegExpr:TRegExpr;
   i:integer;
   LighttpdUserAndGroup:string;
   debug_apache:string;
   ldap:Topenldap;
begin

   LighttpdUserAndGroup:=SYS.LIGHTTPD_GET_USER();
   logs.Debuglogs('Starting......: username:group "'+LighttpdUserAndGroup+'"');
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^(.+?):(.+)';
   if length(LighttpdUserAndGroup)=0 then LighttpdUserAndGroup:='www-data:www-data';
   if not RegExpr.Exec(LighttpdUserAndGroup) then begin
      logs.Debuglogs('Starting......: Apache daemon unable to stat username and group !');
      exit;
   end;


debug_apache:=SYS.GET_INFO('ApacheArticaDebugLevel');
if length(debug_apache)=0 then begin
   debug_apache:='warn';
   SYS.set_INFO('ApacheArticaDebugLevel','warn');
end;
username:=RegExpr.Match[1];
group:=RegExpr.Match[2];

     ForceDirectories('/var/run/artica-apache');
     ForceDirectories('/var/log/artica-postfix/apache');

     logs.OutputCmd('/bin/chown '+LighttpdUserAndGroup+' /var/run/artica-apache');
     logs.OutputCmd('/bin/chown '+LighttpdUserAndGroup+' /var/log/artica-postfix/apache');
     logs.OutputCmd('/bin/chown '+LighttpdUserAndGroup+' /var/lib/php5');

logs.Debuglogs('Starting......: Apache daemon Building configuration');
logs.Debuglogs('Starting......: Apache logs is set to "'+ debug_apache+'"');

ldap:=topenldap.Create;


l:=Tstringlist.Create;
l.add('ServerRoot "/usr/share/artica-postfix"');
l.add('Listen '+SYS.LIGHTTPD_LISTEN_PORT());
//l.add('#SSLPassPhraseDialog  builtin');
//l.add('#SSLSessionCache        "shmcb:/var/log/artica-postfix/apache/ssl_scache(512000)"');
//l.add('#SSLSessionCacheTimeout  300');
l.add('SSLMutex  "file:/var/log/artica-postfix/apache/ssl_mutex"');
l.add('SSLEngine on');
//l.add('#SSLCipherSuite ALL:!ADH:!DSS:!EXPORT56:!AES256-SHA:!DHE-RSA-AES256-SHA:@STRENGTH:+3DES:+DES');
//l.add('#SSLCipherSuite ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP:+eNULL');
//l.add('#SSLCACertificateFile "/usr/share/artica-postfix/bin/install/apache/ComodoSecurityServicesCA2018.crt"');
l.add('SSLCertificateFile "/etc/ssl/certs/apache/server.crt"');
l.add('SSLCertificateKeyFile "/etc/ssl/certs/apache/server.key"');
l.add('SSLVerifyClient none');
l.add('ServerSignature Off');
//l.add('#SSLProtocol ALL -SSLv2');
l.add('');
l.add('<IfModule !mpm_netware_module>');
l.add('User '+username);
l.add('Group '+group);
l.add('ServerName '+GetHostname());
l.add('</IfModule>');
l.add('');
l.add('<IfModule mod_vhost_ldap.c>');
l.add('    VhostLDAPEnabled on');
l.add('    VhostLDAPUrl "ldap://'+ldap.ldap_settings.servername+':'+ldap.ldap_settings.Port+'/dc=organizations,'+ldap.ldap_settings.suffix+'"');
l.add('    VhostLdapBindDN "cn='+ldap.ldap_settings.admin+','+ldap.ldap_settings.suffix+'"');
l.add('    VhostLDAPBindPassword "'+ldap.ldap_settings.password+'"');
l.add('</IfModule>');
l.add('ServerAdmin you@example.com');
l.add('DocumentRoot "/usr/share/artica-postfix"');
l.add('DirectoryIndex logon.php admin.index.php index.php');
l.add('');
l.add('<Directory />');
l.add('    SSLOptions +StdEnvVars');
l.add('    Options FollowSymLinks');
l.add('    AllowOverride None');
l.add('    Order deny,allow');
l.add('    Deny from all');
l.add('</Directory>');
l.add('');
l.add('');
l.add('<Directory "/usr/share/artica-postfix">');
l.add('    Options Indexes FollowSymLinks');
l.add('    AllowOverride None');
l.add('    Order allow,deny');
l.add('    Allow from all');
l.add('');
l.add('</Directory>');
l.add('');
l.add('<IfModule dir_module>');
l.add('    DirectoryIndex index.php');
l.add('</IfModule>');
l.add('');
l.add('<FilesMatch "^\.ht">');
l.add('    Order allow,deny');
l.add('    Deny from all');
l.add('    Satisfy All');
l.add('</FilesMatch>');
l.add('');
l.add('ErrorLog	/var/log/artica-postfix/apache/error_log');
l.add('');
l.add('LogLevel '+debug_apache);
l.add('');
l.add('<IfModule log_config_module>');
l.add('    LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined');
l.add('    LogFormat "%h %l %u %t \"%r\" %>s %b" common');
l.add('');
l.add('    <IfModule logio_module>');
l.add('      LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %I %O" combinedio');
l.add('    </IfModule>');
l.add('');
l.add('CustomLog	/var/log/artica-postfix/apache/access_log common');
l.add('</IfModule>');
l.add('');
l.add('<IfModule alias_module>');
l.add('    ScriptAlias /cgi-bin/ "/opt/artica/cgi-bin/"');
l.add('');
l.add('</IfModule>');
l.add('');
l.add('<IfModule cgid_module>');
l.add('</IfModule>');
l.add('');
l.add('<Directory "/opt/artica/cgi-bin">');
l.add('    AllowOverride None');
l.add('    Options None');
l.add('    Order allow,deny');
l.add('    Allow from all');
l.add('</Directory>');
l.add('');
l.add('DefaultType text/plain');
l.add('');
l.add('<IfModule mime_module>');
l.add('TypesConfig	/etc/mime.types');
l.add('');
l.add('    #AddType application/x-gzip .tgz');
l.add('    #AddEncoding x-compress .Z');
l.add('    #AddEncoding x-gzip .gz .tgz');
l.add('    AddType application/x-compress .Z');
l.add('    AddType application/x-gzip .gz .tgz');
l.add('    AddType application/x-httpd-php .php .phtml');
l.add('    AddType application/x-httpd-php-source .phps');
l.add('    #AddHandler cgi-script .cgi');
l.add('    #AddType text/html .shtml');
l.add('    #AddOutputFilter INCLUDES .shtml');
l.add('</IfModule>');
l.add('');
l.add('#MIMEMagicFile conf/magic');
l.add('#ErrorDocument 500 "The server made a boo boo."');
l.add('#ErrorDocument 404 /missing.html');
l.add('#ErrorDocument 404 "/cgi-bin/missing_handler.pl"');
l.add('#ErrorDocument 402 http://www.example.com/subscription_info.html');
l.add('#EnableMMAP off');
l.add('#EnableSendfile off');
l.add('');
//l.add('<IfModule ssl_module>');
//l.add('SSLRandomSeed startup builtin');
//l.add('SSLRandomSeed connect builtin');
//l.add('</IfModule>');
l.add('');
l.add('PidFile	/var/run/artica-apache/apache.pid');
l.Add(SET_MODULES());
logs.WriteToFile(l.Text,CONFIG_PATH());

l.free;
RegExpr.free;
end;
//##############################################################################

function tapache_artica.PID_NUM():string;
var
   pid_path:string;

begin
     pid_path:='/var/run/artica-apache/apache.pid';
     if FileExists(pid_path) then begin
        result:=SYS.GET_PID_FROM_PATH(pid_path);
        if not SYS.PROCESS_EXIST(result) then result:='';
     end;



     if length(trim(result))=0 then result:=SYS.PIDOF(START_COMMAND());
end;
//##############################################################################
procedure tapache_artica.STOP();
var
   count:integer;
   pid:string;
begin

    if not FileExists(BIN_PATH()) then begin
    writeln('Stopping Apache Daemon.......: Not installed');
    exit;
    end;
    pid:=PID_NUM();
if  not SYS.PROCESS_EXIST(pid) then begin
    writeln('Stopping Apache Daemon.......: Already stopped');
    exit;
end;

    writeln('Stopping Apache Daemon.......: ' + pid + ' PID..');
    fpsystem('/bin/kill '+ pid);
    pid:=PID_NUM();
    if FileExists(SYS.LOCATE_APACHECTL()) then begin
       logs.OutputCmd(SYS.LOCATE_APACHECTL() +' -f '+ CONFIG_PATH() + ' -k stop');
    end else begin
       writeln('Stopping Apache Daemon.......: failed to stat apachectl');
    end;

  while SYS.PROCESS_EXIST(pid) do begin
        sleep(200);
        count:=count+1;
        if count>20 then begin
            if length(pid)>0 then begin
               if SYS.PROCESS_EXIST(pid) then begin
                  writeln('Stopping Apache Daemon.......: kill pid '+ pid+' after timeout');
                  fpsystem('/bin/kill -9 ' + pid);
               end;
            end;
            break;
        end;
        pid:=PID_NUM();
  end;

if  not SYS.PROCESS_EXIST(PID_NUM()) then begin
    writeln('Stopping Apache Daemon.......: success');
    exit;
end;
    writeln('Stopping Apache Daemon.......: failed');
end;


//#############################################################################

function tapache_artica.STATUS();
var
   ini:TstringList;
   pid:string;
begin
if not FileExists(BIN_PATH()) then exit;
pid:=PID_NUM();


      ini:=TstringList.Create;
      ini.Add('[POLICYD_WEIGHT]');
      if SYS.PROCESS_EXIST(pid) then ini.Add('running=1') else  ini.Add('running=0');
      ini.Add('application_installed=1');
      ini.Add('master_pid='+ pid);
      ini.Add('master_memory=' + IntToStr(SYS.PROCESS_MEMORY(pid)));
      ini.Add('master_version=' + VERSION());
      ini.Add('status='+SYS.PROCESS_STATUS(pid));
      ini.Add('service_name=APP_POLICYD_WEIGHT');
      ini.Add('service_cmd=apache');
      ini.Add('service_disabled=0');
      result:=ini.Text;
      ini.free;
end;
//##############################################################################
function tapache_artica.APACHE_ARTICA_SSL_KEY():string;
var
   openssl:string;
   tmp,cf_path,cmd,CertificateMaxDays:string;
   ldap:topenldap;
   servername,extensions:string;
begin
SYS:=Tsystem.Create();
ForceDirectories('/etc/ssl/certs/apache');
tmp:=logs.FILE_TEMP();
ldap:=Topenldap.Create;
logs.WriteToFile(ldap.ldap_settings.password,tmp);
SYS.OPENSSL_CERTIFCATE_CONFIG();
cf_path:=SYS.OPENSSL_CONFIGURATION_PATH();
openssl:=SYS.LOCATE_OPENSSL_TOOL_PATH();
CertificateMaxDays:=SYS.GET_INFO('CertificateMaxDays');
if length(SYS.OPENSSL_CERTIFCATE_HOSTS())>0 then extensions:=' -extensions HOSTS_ADDONS ';
if length(CertificateMaxDays)=0 then CertificateMaxDays:='730';
 servername:=GetHostname();



   cmd:=openssl+' genrsa -out /etc/ssl/certs/apache/server.key 1024';
   logs.Debuglogs(cmd);
   fpsystem(cmd);


  // cmd:=openssl+' rsa -in /etc/ssl/certs/apache/server.key -passin pass:'+ldap.ldap_settings.password+' -out /etc/ssl/certs/apache/server.key';
//   logs.Debuglogs(cmd);
//   fpsystem(cmd);

logs.DebugLogs('Starting......: Apache daemon using configuration file '+cf_path);
cmd:=openssl +' req -outform PEM -new -key /etc/ssl/certs/apache/server.key -x509 -config '+cf_path+extensions+' -days '+CertificateMaxDays+' -out /etc/ssl/certs/apache/server.crt';

//cmd:=openssl+' req -new -config '+cf_path+' -x509 -days '+CertificateMaxDays+' -subj ''/CN='+servername+''' -key /etc/ssl/certs/apache/server.key -out /etc/ssl/certs/apache/server.crt';
   logs.Debuglogs(cmd);
   fpsystem(cmd);

end;
//##############################################################################
function tapache_artica.CERTIFICATE_SERVER_NAME():boolean;
var
   servername:string;
   cert:string;
   tmp:string;
   l:Tstringlist;
   RegExpr:TRegExpr;
   i:integer;
   cmd:string;
begin
  if not FileExists('/etc/ssl/certs/apache/server.crt') then exit(false);
  servername:=GetHostname();
  RegExpr:=TRegExpr.Create;
  RegExpr.Expression:='(.+?)\.(.+)';
  if not RegExpr.Exec(servername) then  servername:=servername+'.local';



  tmp:=logs.FILE_TEMP();
  cmd:=SYS.OPENSSL_TOOL_PATH()+' x509 -in /etc/ssl/certs/apache/server.crt -text -noout -out '+tmp;
  logs.Debuglogs(cmd);
  fpsystem(cmd);
  if not FileExists(tmp) then exit(false);

  l:=Tstringlist.Create;
  l.LoadFromFile(tmp);
  logs.DeleteFile(tmp);



  RegExpr.Expression:='CN=(.+?)/';

  logs.DebugLogs('Starting......: Apache daemon certificate store "'+IntTOStr(l.count)+'" lines');

  for i:=0 to l.Count-1 do begin
    if RegExpr.Exec(l.Strings[i]) then begin
         logs.DebugLogs('Starting......: Apache daemon certificate store CN "'+RegExpr.Match[1]+'"');
         cert:=lowercase(trim(RegExpr.Match[1]));
         if cert<>lowercase(servername) then begin
                logs.DebugLogs('Starting......: Apache daemon certificate store wrong CN "'+cert+'" requires '+servername+' rebuild certificate');
                APACHE_ARTICA_SSL_KEY();
                break;
         end else begin
             break;
         end;
    end;

  end;

RegExpr.free;
l.free;
end;
//##############################################################################
function tapache_artica.COMPILATION_VALUE(KEY_NAME_STRING:string):string;
var
   servername:string;
   cert:string;
   tmp:string;
   l:Tstringlist;
   RegExpr:TRegExpr;
   i:integer;
   cmd:string;
begin

tmp:=logs.FILE_TEMP();
cmd:=BIN_PATH() +' -V >'+tmp;
logs.Debuglogs(cmd);
fpsystem(cmd);
l:=Tstringlist.Create;
try
   l.LoadFromFile(tmp);
except
  logs.Debuglogs('Starting......: Apache daemon Fatal error on COMPILATION_VALUE('+KEY_NAME_STRING+') function');
  exit;
end;

logs.DeleteFile(tmp);
RegExpr:=TRegExpr.Create;
RegExpr.Expression:='-D '+KEY_NAME_STRING+'="(.+?)"';
for i:=0 to l.Count-1 do begin
    if RegExpr.Exec(l.Strings[i]) then begin
       result:=RegExpr.Match[1];
       break;
    end;
end;

l.free;
RegExpr.free;
end;
//##############################################################################
procedure tapache_artica.MIME_TYPES_DIRECTIVES();
var
   path:string;

begin

path:=COMPILATION_VALUE('AP_TYPES_CONFIG_FILE');


if length(SYS.LOCATE_MIME_TYPES())=0 then begin
   logs.Debuglogs('Starting......: Apache daemon unable to stat mime.types file ?? (see MIME_TYPES_DIRECTIVES() function)');
   exit;
end;


if length(path)=0 then begin
   logs.Debuglogs('Starting......: Apache daemon unable to determine AP_TYPES_CONFIG_FILE compilation directive');
   exit;
end;
logs.DebugLogs('Starting......: Apache daemon mimes type:'+path);
if not FileExists(path) then begin
   logs.DebugLogs('Starting......: Apache daemon installing mimes type in '+path);
   forceDirectories(extractFilePath(path));
   logs.OutputCmd('/bin/ln -s '+SYS.LOCATE_MIME_TYPES()+' '+path);
end;
end;

end.
