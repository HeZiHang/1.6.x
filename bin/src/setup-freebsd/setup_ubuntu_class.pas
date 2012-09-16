unit setup_ubuntu_class;
{$MODE DELPHI}
//{$mode objfpc}{$H+}
{$LONGSTRINGS ON}

interface

uses
  Classes, SysUtils,strutils,RegExpr in 'RegExpr.pas',unix,IniFiles;

  type
  tubuntu=class


private
       procedure Show_Welcome;
       function uninstall_app_armor():boolean;
       function is_application_installed(appname:string):boolean;
       function CheckBaseSystem():string;
       function InstallPackageLists(list:string):boolean;
       function CheckPostfix():string;
       function CheckCyrus():string;
       function checkSamba():string;
       function checkSQuid():string;
       function GET_HTTP_PROXY:string;
       function WGET_DOWNLOAD_FILE(uri:string;file_path:string):boolean;
       function LOCATE_CURL():string;
       procedure SET_HTTP_PROXY(proxy_string:string);
       function  REMOVE_HTTP_PROXY:string;
       procedure InstallArtica();




public
      constructor Create();
      procedure Free;
      function get_LDAP(key:string):string;
      procedure set_LDAP(key:string;val:string);
      function SLAPD_CONF_PATH():string;
      function ARTICA_VERSION():string;
      function get_LDAP_suffix():string;
      function get_LDAP_PASSWORD():string;
      function get_LDAP_ADMIN():string;



END;

implementation

constructor tubuntu.Create();
begin
  Show_Welcome();
end;
//#########################################################################################
procedure tubuntu.Free();
begin

end;
//#########################################################################################
procedure tubuntu.Show_Welcome;
var
   base,postfix,u,cyrus,samba,squid:string;
begin
    if not FileExists('/usr/bin/apt-get') then begin
      writeln('Your system does not store apt-get utils, this program must be closed...');
      halt(0);
    end;
    
    writeln('Checking.............: system...');
    writeln('Checking.............: AppArmor...');
    writeln('Checking.............: Base system...');
    base:=CheckBaseSystem();
    writeln('Checking.............: Postfix system...');
    postfix:=CheckPostfix();
    writeln('Checking.............: Cyrus system...');
    cyrus:=CheckCyrus();
    writeln('Checking.............: Files Sharing system...');
    samba:=checkSamba();
    writeln('Checking.............: Squid proxy and securties...');
    squid:=checkSQuid();



    if is_application_installed('apparmor') then begin
         if not uninstall_app_armor() then begin
            Show_Welcome;
            exit;
         end;
    Show_Welcome;
    exit;
    end;
    

    if length(base)>0 then begin
          if not InstallPackageLists(base) then halt(0);
          Show_Welcome;
          exit;
    end;

    
    writeln('');
    writeln('######## Artica-postfix modules installation ########');
  if FileExists('/usr/share/artica-postfix/bin/artica-install') then begin
     writeln('You can access to artica by typing https://yourserver:9000');
     writeln( 'Use on logon section the username "' + get_LDAP('admin') + '" ');
     writeln( 'Use on logon section the password "' + get_LDAP('password') + '" ');
     writeln( 'You have to logon to artica web site, set yours domains and apply policies');
     writeln();
  end;
    writeln('');
    writeln('Select the modules you want to install:');
    writeln('');
    writeln('Install all modules.......:............................[type "enter" key]');
    writeln('');
    
    if length(postfix)>0 then begin
    writeln('SMTP MTA (include postfix and securities modules):.....[1]');
    end else begin
    writeln('SMTP MTA (include postfix and securities modules):.....Installed');
    end;
    
   if length(postfix)=0 then begin
      if length(cyrus)>0 then begin
         writeln('Mail server (include postfix and Cyrus-imap):..........[2]');
      end else begin
          writeln('Mail server (include postfix and Cyrus-imap):..........Installed');
      end;
   end;
writeln('');
writeln('----------------------------');
writeln('');

    if length(samba)>0 then begin
    writeln('Files Sharing (include Samba and Pure-ftpd):...........[3]');
    end else begin
    writeln('Files Sharing (include Samba and Pure-ftpd):...........Installed');
    end;

writeln('');
writeln('----------------------------');
writeln('');
    if length(squid)>0 then begin
    writeln('Squid Proxy (include Squid and dansguardian):..........[4]');
    end else begin
    writeln('Squid Proxy (include Squid and dansguardian):..........Installed');

    end;
    
    
writeln('');
writeln('----------------------------');
writeln('Install/upgrade Artica-postfix:........................[5] ('+ARTICA_VERSION()+')');
writeln('');
      

    writeln('');
    readln(u);
    
    if length(u)=0 then begin
       InstallPackageLists(postfix+' '+cyrus+' '+samba+' '+squid);
       InstallArtica();
       Show_Welcome;
       exit;
    end;
    
    if u='1' then begin
          InstallPackageLists(postfix);
          Show_Welcome;
          exit;
    end;
    
    if u='2' then begin
          InstallPackageLists(cyrus);
          Show_Welcome;
          exit;
    end;
    
    if u='3' then begin
          InstallPackageLists(samba);
          Show_Welcome;
          exit;
    end;
    
    if u='4' then begin
          InstallPackageLists(squid);
          Show_Welcome;
          exit;
    end;
    
    if u='5' then begin
          InstallArtica();
          Show_Welcome;
          exit;
    end;


end;
//#########################################################################################
function tubuntu.uninstall_app_armor():boolean;
var
   u:string;
begin
result:=false;
writeln('');
writeln('You have apparmor installed.');
writeln('To enable full compaibility with artica, apparmor');
writeln('Must be uninstalled');
writeln('');
writeln('');
writeln('Do you allow uninstall apparmor ? [Y]');
readln(u);
if length(u)=0 then u:='y';
if LowerCase(u)='y' then begin
   fpsystem('/usr/bin/apt-get remove apparmor --purge --yes --force-yes');
   fpsystem('/bin/rm -rf /tmp/packages.list');
end;
end;
//#########################################################################################
function tubuntu.InstallPackageLists(list:string):boolean;
var
   cmd:string;
      u:string;
begin
if length(trim(list))=0 then exit;
result:=false;

writeln('');
writeln('The following package(s) must be installed in order to perform continue setup');
writeln('');
writeln('-----------------------------------------------------------------------------');
writeln('"',list,'"');
writeln('-----------------------------------------------------------------------------');
writeln('');
writeln('Do you allow install these packages? [Y]');
readln(u);
if length(u)=0 then u:='y';

if LowerCase(u)='y' then begin
   cmd:='DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy install ' + list;
   fpsystem(cmd);
   result:=true;
end;








end;
//#########################################################################################
function tubuntu.is_application_installed(appname:string):boolean;
var
   l:TstringList;
   RegExpr:TRegExpr;
   i:integer;
begin
    result:=false;
    if not FileExists('/tmp/packages.list') then begin
       fpsystem('/usr/bin/dpkg -l >/tmp/packages.list');
    end;

    l:=TstringList.Create;
    l.LoadFromFile('/tmp/packages.list');
    if l.Count<10 then begin
       fpsystem('/bin/rm -rf /tmp/packages.list');
       result:=is_application_installed(appname);
       exit;
    end;
    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='^ii\s+'+appname;
    for i:=0 to l.Count-1 do begin
        if RegExpr.Exec(l.Strings[i]) then begin
           result:=true;
           break;
        end;
    end;

    l.free;
    RegExpr.free;

end;

//#########################################################################################
function tubuntu.CheckBaseSystem():string;
var
   l:TstringList;
   f:string;
   i:integer;
   
begin
f:='';
l:=TstringList.Create;
l.Add('hal');
l.Add('dhcp3-client');
l.Add('cfengine2');
l.Add('cron');
l.Add('debconf-utils');
l.Add('discover');
l.Add('file');
l.Add('hdparm');
l.Add('jove');
l.Add('less');
l.Add('nfs-common');
l.Add('nscd');
l.Add('rdate');
l.Add('rsync');
l.Add('rsh-client');
l.Add('openssh-client ');
l.Add('openssh-server');
l.Add('strace');
//l.Add('sysutils');
l.Add('tcsh');
l.Add('time');
l.Add('eject');
l.Add('locales');
l.Add('console-common');
l.Add('pciutils ');
l.Add('usbutils');
l.Add('slapd ');
l.Add('openssl ');
l.Add('php5-cgi ');
l.Add('php5-ldap ');
l.Add('php5-mysql');
l.Add('php5-imap ');
l.Add('php-log');
l.Add('php-pear');
l.Add('lighttpd ');
l.Add('mysql-server');
l.Add('rrdtool ');
l.Add('librrdp-perl ');
l.Add('librrds-perl ');
l.Add('libfile-tail-perl ');
l.Add('libmysqlclient15-dev ');
l.Add('libgeo-ipfree-perl ');
l.Add('libnet-xwhois-perl ');
l.Add('libwww-perl');
l.Add('php5-imap ');
l.Add('php-log');
l.Add('sasl2-bin');
l.Add('sudo');
l.Add('gcc ');
l.Add('make');
l.Add('build-essential');
l.Add('ntp');
l.Add('iproute');
l.Add('libusb-dev ');
l.Add('libusb-0.1-4 ');
l.Add('libinline-perl ');
l.Add('libcdio-dev ');
l.Add('libconfuse-dev');
l.Add('curl');
l.Add('lm-sensors');
l.Add('hddtemp');
l.Add('libsasl2-modules ');
l.Add('libsasl2-modules-ldap');
l.Add('libauthen-sasl-perl ');
l.Add('bzip2');
l.Add('unrar');
l.Add('arj');
l.Add('lha');
//l.Add('unzoo');
l.Add('htop');
l.Add('telnet');
l.Add('lsof');
//l.Add('locales-all');
l.Add('syslog-ng');
l.Add('dar');
l.Add('preload');
fpsystem('/bin/rm -rf /tmp/packages.list');

for i:=0 to l.Count-1 do begin
     if not is_application_installed(l.Strings[i]) then begin
          f:=f + ' ' + l.Strings[i];
     end;
end;
 result:=f;
end;
//#########################################################################################
function tubuntu.CheckPostfix():string;
var
   l:TstringList;
   f:string;
   i:integer;

begin
f:='';
l:=TstringList.Create;
L.Add('milter-greylist');
l.Add('razor');
l.Add('pyzor');
l.Add('queuegraph');
l.Add('mailgraph');
l.Add('libio-socket-ssl-perl');
l.Add('libcrypt-ssleay-perl');
l.Add('libnet-ssleay-perl');
l.Add('libgeo-ipfree-perl');
l.Add('libconvert-tnef-perl');
l.Add('libhtml-parser-perl ');
l.Add('libfile-scan-perl ');
l.Add('libarchive-zip-perl ');
l.Add('fetchmail');
l.Add('mimedefang ');
l.Add('sanitizer ');
l.Add('wv ');
l.Add('graphdefang');
l.Add('ttf-dustin ');
l.Add('libgd-tools ');
l.Add('awstats');
l.Add('postfix');
l.Add('postfix-ldap');
l.Add('clamav-milter');
l.Add('spamass-milter');
l.Add('spamassassin');
l.Add('spamc');
l.Add('dkim-filter');
fpsystem('/bin/rm -rf /tmp/packages.list');

for i:=0 to l.Count-1 do begin
     if not is_application_installed(l.Strings[i]) then begin
          f:=f + ' ' + l.Strings[i];
     end;
end;
 result:=f;
end;
//#########################################################################################
function tubuntu.CheckCyrus():string;
var
   l:TstringList;
   f:string;
   i:integer;

begin
f:='';
l:=TstringList.Create;
l.Add('cyrus-imapd-2.2');
l.Add('cyrus-admin-2.2');
l.Add('sasl2-bin');
l.Add('cyrus-pop3d-2.2');
l.Add('cyrus-murder-2.2');
l.Add('fetchmail');
l.Add('fdm');
for i:=0 to l.Count-1 do begin
     if not is_application_installed(l.Strings[i]) then begin
          f:=f + ' ' + l.Strings[i];
     end;
end;
 result:=f;
 l.free;
end;
//#########################################################################################
function tubuntu.checkSamba():string;
var
   l:TstringList;
   f:string;
   i:integer;

begin
f:='';
l:=TstringList.Create;
l.Add('libnss-ldap');
l.Add('samba ');
l.Add('smbldap-tools ');
l.Add('smbclient ');
l.Add('smbfs ');
l.Add('libpam-ldap ');
l.Add('libpam-smbpass');
l.Add('ldap-utils ');
l.Add('nscd');
l.Add('pure-ftpd');
l.Add('nmap');
for i:=0 to l.Count-1 do begin
     if not is_application_installed(l.Strings[i]) then begin
          f:=f + ' ' + l.Strings[i];
     end;
end;
 result:=f;
 l.free;
end;
//#########################################################################################
function tubuntu.checkSQuid():string;
var
   l:TstringList;
   f:string;
   i:integer;

begin
f:='';
l:=TstringList.Create;
l.Add('squid3');
l.Add('squidclient');
l.Add('dansguardian');
l.Add('awstats');
for i:=0 to l.Count-1 do begin
     if not is_application_installed(l.Strings[i]) then begin
          f:=f + ' ' + l.Strings[i];
     end;
end;
 result:=f;
 l.free;
end;
//########################################################################################
procedure tubuntu.InstallArtica();
var
   my:TiniFile;
   articaversion:string;

begin

writeln('Getting index file');
if fileexists('/tmp/artica.ini') then fpsystem('/bin/rm -f /tmp/artica.ini');
if not WGET_DOWNLOAD_FILE('http://www.artica.fr/auto.update.php','/tmp/artica.ini') then begin
   writeln('Failed to get artica version...');
   exit;
end;


my:=TiniFile.Create('/tmp/artica.ini');
articaversion:=my.ReadString('NEXT','artica','');
if length(articaversion)=0 then begin
   writeln('Failed to get artica version after downloading the index file...');
   exit;
end;

if ARTICA_VERSION()=articaversion then begin
   writeln('Your artica-version is already updated....');
   exit;
end;


writeln('Downloading '+articaversion + ' artica version');

if FileExists('/tmp/'+articaversion+'.tgz') then fpsystem('/bin/rm -f /tmp/'+articaversion+'.tgz');
if not WGET_DOWNLOAD_FILE('http://www.artica.fr/download/artica-'+articaversion+'.tgz','/tmp/'+articaversion+'.tgz') then begin
   writeln('Failed to get artica package...');
   exit;
end;

writeln('extracting  '+articaversion + ' artica version');
fpsystem('tar -xf /tmp/'+articaversion+'.tgz -C /usr/share');

if not FileExists('/usr/share/artica-postfix/bin/artica-install') then begin
    writeln('Failed to extract the content');
    exit;
end;

writeln('Installing  '+articaversion + ' artica version');
fpsystem('/usr/share/artica-postfix/bin/artica-install --init-from-repos');
fpsystem('/usr/share/artica-postfix/bin/artica-install --perl-addons-repos');
fpsystem('/usr/share/artica-postfix/bin/artica-install -awstats-reconfigure');
fpsystem('/usr/share/artica-postfix/bin/artica-install -awstats generate');
fpsystem('/etc/init.d/artica-postfix restart');
fpsystem('/etc/init.d/artica-postfix restart');

end;




//########################################################################################
function tubuntu.WGET_DOWNLOAD_FILE(uri:string;file_path:string):boolean;
var
   RegExpr:TRegExpr;
   ProxyString:string;
   ProxyCommand:string;
   ProxyUser:string;
   ProxyPassword:string;
   ProxyName:string;
   commandline_artica:string;
   command_line_curl:string;
   command_line_wget:string;
   localhost:boolean;
   ssl:boolean;
 begin
   localhost:=false;
   command_line_curl:='';
   RegExpr:=TRegExpr.Create;
   ProxyString:=GET_HTTP_PROXY();
   ProxyString:=AnsiReplaceStr(ProxyString,'"','');
   ProxyString:=AnsiReplaceStr(ProxyString,'http://','');
   ProxyString:=AnsiReplaceStr(ProxyString,'https://','');

   ssl:=false;
   command_line_curl:= command_line_curl + ' --progress-bar --output ' + file_path + ' "' + uri+'"';

   RegExpr.Expression:='^https:.+';
   if RegExpr.Exec(uri) then ssl:=True;


   RegExpr.Expression:='http://127\.0\.0\.1';
   if RegExpr.Exec(uri) then localhost:=True;

 if not localhost then begin
   if length(ProxyString)>0 then begin
       RegExpr.Expression:='(.+?):(.+?)@(.+)';
       if RegExpr.Exec(ProxyString) then begin
            ProxyUser:=RegExpr.Match[1];
            ProxyPassword:=RegExpr.Match[2];
            ProxyName:=RegExpr.Match[3];
       end;
       RegExpr.Expression:='(.+?)@(.+)';
       if RegExpr.Exec(ProxyString) then begin
           ProxyUser:=RegExpr.Match[1];
           ProxyName:=RegExpr.Match[3];
       end;
   end;

   if length(ProxyName)=0 then ProxyName:=ProxyString;
 end;

   if length(ProxyName)>0 then begin
      ProxyCommand:='--proxy ' +  ProxyName;
      if length(ProxyUser)>0 then begin
         if length(ProxyPassword)>0 then begin
            ProxyCommand:=' --proxy ' +  ProxyName + ' --proxy-user ' + ProxyUser + ':' + ProxyPassword;
         end else begin
            ProxyCommand:=' --proxy ' +  ProxyName + ' --proxy-user ' + ProxyUser;
         end;
      end;
     command_line_curl:=ProxyCommand + ' --progress-bar --output ' + file_path + ' "' + uri+'"';

   end;


   command_line_wget:=uri + '  -q --output-document=' + file_path;


   if FileExists(LOCATE_CURL()) then begin
         if ssl then command_line_curl:=command_line_curl+ ' --insecure';
         command_line_curl:=LOCATE_CURL() + command_line_curl;
         fpsystem(command_line_curl);
         result:=true;
         exit;
   end;



  if FileExists('/usr/bin/wget') then begin
     if length(ProxyName)>0 then begin
         SET_HTTP_PROXY(GET_HTTP_PROXY());
     end;
     command_line_wget:='/usr/bin/wget ' + command_line_wget;
     if ssl then command_line_wget:=command_line_wget + ' --no-check-certificate';
     fpsystem(command_line_wget);
     result:=true;
     exit;
  end;



     if length(ProxyName)>0 then ProxyCommand:=' --proxy=on --proxy-name=' + ProxyName;
     if length(ProxyUser)>0 then ProxyCommand:=' --proxy=on --proxy-name=' + ProxyName  + ' --proxy-user=' + ProxyUser;
     if length(ProxyPassword)>0 then ProxyCommand:=' --proxy=on --proxy-name=' + ProxyName  + ' --proxy-user=' + ProxyUser + ' --proxy-passwd=' + ProxyPassword;
     commandline_artica:=ExtractFilePath(ParamStr(0)) + 'artica-get  '+ uri + ' ' + ProxyCommand + ' -q --output-document=' + file_path;
     fpsystem(commandline_artica);
     result:=true;





end;
//##############################################################################
function  tubuntu.GET_HTTP_PROXY:string;
var
   l:TStringList;
   i:integer;
   RegExpr:TRegExpr;

 begin
  if not FileExists('/etc/environment') then begin
     l:=TStringList.Create;
     l.Add('LANG="en_US.UTF-8"');
     l.SaveToFile('/etc/environment');
     exit;
  end;


  l:=TStringList.Create;
  RegExpr:=TRegExpr.Create;
  RegExpr.Expression:='(http_proxy|HTTP_PROXY)=(.+)';

  l.LoadFromFile('/etc/environment');
  for i:=0 to l.Count -1 do begin
      if RegExpr.Exec(l.Strings[i]) then result:=RegExpr.Match[2];

  end;
 l.FRee;
 RegExpr.free;

end;
//##############################################################################
function tubuntu.LOCATE_CURL():string;
begin
   if FileExists('/usr/local/bin/curl') then exit('/usr/local/bin/curl');
   if FileExists('/usr/bin/curl') then exit('/usr/bin/curl');
   if FileExists('/opt/artica/bin/curl') then exit('/opt/artica/bin/curl');
end;
 //#############################################################################
 procedure  tubuntu.SET_HTTP_PROXY(proxy_string:string);
var
   l:TStringList;
   i:integer;
   RegExpr:TRegExpr;
   found_proxy:boolean;

 begin
  if not FileExists('/etc/environment') then begin
     writeln('Unable to find /etc/environment');
     exit;
  end;
 REMOVE_HTTP_PROXY();

  l:=TStringList.Create;
  l.LoadFromFile('/etc/environment');
  l.Add('http_proxy="'+ proxy_string + '"');
  l.SaveToFile('/etc/environment');
  writeln('export http_proxy="'+ proxy_string + '" --> done');
  fpsystem('export http_proxy="'+ proxy_string + '"');
  writeln('env http_proxy='+ proxy_string + '" --> done');
  fpsystem('env http_proxy='+ proxy_string);


  if FileExists('/etc/wgetrc') then begin
      RegExpr:=TRegExpr.Create;
      RegExpr.Expression:='^http_proxy(.+)';
      l.LoadFromFile('/etc/wgetrc');
      For i:=0 to l.Count-1 do begin
          if RegExpr.Exec(l.Strings[i]) then begin
             found_proxy:=true;
             l.Strings[i]:='http_proxy = ' + proxy_string;
             l.SaveToFile('/etc/wgetrc');
             break;
          end;
      end;

     if found_proxy=false then begin
          l.Add('http_proxy = ' + proxy_string);
          l.SaveToFile('/etc/wgetrc');
     end;

  end;

   l.free;

end;
//##############################################################################
//##############################################################################
function  tubuntu.REMOVE_HTTP_PROXY:string;
var
   l:TStringList;
   i:integer;
   RegExpr:TRegExpr;

 begin
  if not FileExists('/etc/environment') then begin
     writeln('Unable to find /etc/environment');
     exit;
  end;


  l:=TStringList.Create;
  RegExpr:=TRegExpr.Create;
  RegExpr.Expression:='(http_proxy|HTTP_PROXY)=(.+)';

  l.LoadFromFile('/etc/environment');
  for i:=0 to l.Count -1 do begin
      if RegExpr.Exec(l.Strings[i]) then begin
          l.Delete(i);
          break;
      end;
  end;
  l.SaveToFile('/etc/environment');


  if FileExists('/etc/wgetrc') then begin
      RegExpr:=TRegExpr.Create;
      RegExpr.Expression:='^http_proxy(.+)';
      l.LoadFromFile('/etc/wgetrc');
      For i:=0 to l.Count-1 do begin
          if RegExpr.Exec(l.Strings[i]) then begin
             l.Strings[i]:='#' + l.Strings[i];
             l.SaveToFile('/etc/wgetrc');
             break;
          end;
      end;
  end;


  l.free;
  RegExpr.free;
  result:='';
end;
//##############################################################################
function tubuntu.get_LDAP(key:string):string;
var
   value:string;
   Ini:TMemIniFile;

begin
Ini:=TMemIniFile.Create('/etc/artica-postfix/artica-postfix-ldap.conf');
value:=trim(Ini.ReadString('LDAP',key,''));
Ini.Free;

if length(value)=0 then begin
 if FileExists('/etc/artica-postfix/artica-postfix-ldap.bak.conf') then begin
    Ini:=TMemIniFile.Create('/etc/artica-postfix/artica-postfix-ldap.bak.conf');
    value:=Ini.ReadString('LDAP',key,'');
    Ini.Free;
    if length(value)>0 then begin
       set_LDAP(key,value);
       result:=value;
       exit;
    end;
  end;

    if key='admin' then begin
      value:=get_LDAP_ADMIN();
      if length(value)>0 then begin
         set_LDAP(key,value);
         result:=value;
         exit;
       end;
     end;

    if key='password' then begin
      value:=get_LDAP_PASSWORD();
      if length(value)>0 then begin
         set_LDAP(key,value);
         result:=value;
         exit;
       end;
     end;

    if key='suffix' then begin
      value:=get_LDAP_suffix();
      if length(value)>0 then begin
         set_LDAP(key,value);
         result:=value;
         exit;
       end;
     end;

end;

result:=value;

end;
//#############################################################################
procedure tubuntu.set_LDAP(key:string;val:string);
var ini:TIniFile;
begin
ini:=TIniFile.Create('/etc/artica-postfix/artica-postfix-ldap.conf');
ini.WriteString('LDAP',key,val);
ini.Free;

ini:=TIniFile.Create('/etc/artica-postfix/artica-postfix-ldap.bak.conf');
ini.WriteString('LDAP',key,val);
ini.Free;

end;
//#############################################################################
function tubuntu.ARTICA_VERSION():string;
var
   l:string;
   F:TstringList;

begin
   l:='/usr/share/artica-postfix/VERSION';
   if not FileExists(l) then exit('0.00');
   F:=TstringList.Create;
   F.LoadFromFile(l);
   result:=trim(F.Text);
   F.Free;
end;
//#############################################################################
//#############################################################################
function tubuntu.get_LDAP_ADMIN():string;
var
   RegExpr:TRegExpr;
   l:TstringList;
   i:integer;

begin
  if not FileExists(SLAPD_CONF_PATH()) then exit;
  RegExpr:=TRegExpr.Create;
  l:=TstringList.Create;
  TRY
  l.LoadFromFile(SLAPD_CONF_PATH());
  RegExpr.Expression:='rootdn\s+"cn=(.+?),';
  for i:=0 to l.Count-1 do begin
      if  RegExpr.Exec(l.Strings[i]) then begin
             result:=trim(RegExpr.Match[1]);
             break;
      end;
  end;
  FINALLY
   l.free;
   RegExpr.free;
  END;
end;
//#############################################################################
function tubuntu.get_LDAP_PASSWORD():string;
var
   RegExpr:TRegExpr;
   l:TstringList;
   i:integer;

begin
  if not FileExists(SLAPD_CONF_PATH()) then exit;
  RegExpr:=TRegExpr.Create;
  l:=TstringList.Create;
  TRY
  l.LoadFromFile(SLAPD_CONF_PATH());
  RegExpr.Expression:='rootpw\s+(.+)';
  for i:=0 to l.Count-1 do begin
      if  RegExpr.Exec(l.Strings[i]) then begin
             result:=trim(RegExpr.Match[1]);
             result:=AnsiReplaceText(result,'"','');
             result:=AnsiReplaceText(result,'"','');
             break;
      end;
  end;
  FINALLY
   l.free;
   RegExpr.free;
  END;
end;
//#############################################################################
function tubuntu.get_LDAP_suffix():string;
var
   RegExpr:TRegExpr;
   l:TstringList;
   i:integer;

begin
  if not FileExists(SLAPD_CONF_PATH()) then exit;
  RegExpr:=TRegExpr.Create;
  l:=TstringList.Create;
  TRY
  l.LoadFromFile(SLAPD_CONF_PATH());
  RegExpr.Expression:='^suffix\s+(.+)';
  for i:=0 to l.Count-1 do begin
      if  RegExpr.Exec(l.Strings[i]) then begin
             result:=trim(RegExpr.Match[1]);
             result:=AnsiReplaceText(result,'"','');
             result:=AnsiReplaceText(result,'"','');
             break;
      end;
  end;
  FINALLY
   l.free;
   RegExpr.free;
  END;
end;
//#############################################################################
function tubuntu.SLAPD_CONF_PATH():string;
begin
   if FileExists('/etc/ldap/slapd.conf') then exit('/etc/ldap/slapd.conf');
   if FileExists('/etc/openldap/slapd.conf') then exit('/etc/openldap/slapd.conf');
   if FileExists('/opt/artica/etc/openldap/slapd.conf') then exit('/opt/artica/etc/openldap/slapd.conf');
   exit('/etc/ldap/slapd.conf');

end;
//##############################################################################
end.
