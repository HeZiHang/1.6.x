unit setup_fedora_class;
{$MODE DELPHI}
//{$mode objfpc}{$H+}
{$LONGSTRINGS ON}

interface

uses
  Classes, SysUtils,strutils,RegExpr in 'RegExpr.pas',unix,IniFiles,setup_libs,distriDetect;
type
  TStringDynArray = array of string;
  type
  tfedora=class


private
       libs:tlibs;
       DEBUG:boolean;
       ArchStruct:integer;
       function CheckCyrus():string;
       function CheckDevcollectd():string;
       function CheckSelinux():string;
       function DisableSeLinux():string;
       function Explode(const Separator, S: string; Limit: Integer = 0):TStringDynArray;







public
      distri:tdistriDetect;
      constructor Create();
      procedure Free;
      function InstallPackageLists(list:string):boolean;
      procedure Show_Welcome;
      function CheckBaseSystem():string;
      function checkSamba():string;
      function checkApps(l:tstringlist):string;
      function CheckPostfix():string;
      function checkSQuid():string;
      function InstallPackageListsSilent(list:string):boolean;
      function CheckBasePHP():string;
      function CheckPDNS():string;
      function CheckZabbix():string;
      function ejabberd():string;
END;

implementation

constructor tfedora.Create();
begin
ArchStruct:=libs.ArchStruct();
libs:=tlibs.Create;
DEBUG:=libs.COMMANDLINE_PARAMETERS('--verbose');
end;
//#########################################################################################
procedure tfedora.Free();
begin
  libs.Free;

end;
//#########################################################################################
procedure tfedora.Show_Welcome;
var
   base,postfix,u,cyrus,samba,squid,selinux,pdns:string;
begin

   if not FileExists('/usr/bin/yum') then begin
      writeln('Your system does not store /usr/bin/yum utils, this program must be closed...');
      exit;
    end;
    if not FileExists('/tmp/zypper-update') then begin
       fpsystem('touch /tmp/zypper-update');
       fpsystem('/usr/bin/yum check-update');
    end;


    if not FileExists('/tmp/iptables_stopped') then begin
       if FileExists('/etc/init.d/iptables') then begin
          fpsystem('/etc/init.d/iptables stop');
          fpsystem('chkconfig iptables off');
          fpsystem('touch /tmp/iptables_stopped');
       end;
    end;


    writeln('Checking.............: system...');
    writeln('Checking.............: SeLinux...');
    
    selinux:=trim(CheckSelinux());
    if selinux='y' then begin
        writeln('Artica is not compliance with SeLinux installed on your system...');
        writeln('Do you want to uninstall it ? [Y]');
        readln(u);
        if length(u)=0 then u:='Y';
        if u='Y' then begin
           DisableSeLinux();
           exit;
        end;
        halt(0);
    end;
    
    
    writeln('Checking.............: Base system...');
    base:=CheckBaseSystem();
    writeln('Checking.............: Postfix system...');
    postfix:=trim(CheckPostfix());
    writeln('Checking.............: Cyrus system...');
    cyrus:=trim(CheckCyrus());
    writeln('Checking.............: Files Sharing system...');
    samba:=checkSamba();
    writeln('Checking.............: Squid proxy and securities...');
    squid:=checkSQuid();
    writeln('Checking.............: PowerDNS System...');
    pdns:=CheckPDNS();
    u:=libs.INTRODUCTION(base,postfix,cyrus,samba,squid);
    
    writeln('You have selected the option : ' + u);

    if length(u)=0 then begin
        if length(base)>0 then u:='B';
    end;
    
    if u='B' then begin
        InstallPackageLists(base);
        Show_Welcome();
        exit;
    end;
    
    if length(u)=0 then begin
       Show_Welcome();
        exit;
    end;

    if lowercase(u)='a' then begin
       InstallPackageLists(base + ' ' + postfix+' '+cyrus+' '+samba+' '+squid);
       fpsystem('/usr/share/artica-postfix/bin/artica-make APP_ROUNDCUBE3');
       fpsystem('/etc/init.d/artica-postfix restart');
       Show_Welcome();
       exit;
    end;
    

    if u='1' then begin
          InstallPackageLists(postfix);
          fpsystem('/usr/share/artica-postfix/bin/artica-make APP_ISOQLOG');
          Show_Welcome;
          exit;
    end;

   if u='2' then begin
          InstallPackageLists(cyrus);
          fpsystem('/usr/share/artica-postfix/bin/artica-make APP_ROUNDCUBE3');
          Show_Welcome;
          exit;
    end;
    
   if u='3' then begin
          InstallPackageLists(samba);
          fpsystem('/etc/init.d/artica-postfix restart samba >/dev/null 2>&1 &');
          fpsystem('/usr/share/artica-postfix/bin/artica-install --nsswitch');
          Show_Welcome;
          exit;
    end;
    
   if u='4' then begin
          InstallPackageLists(squid);
          Show_Welcome;
          exit;
    end;
    
    if length(u)=0 then begin
       if length(base)=0 then begin
          InstallPackageLists(postfix+' '+cyrus+' '+samba+' '+squid);
          libs.InstallArtica();
       end;
       Show_Welcome;
       exit;
    end;


end;
//#########################################################################################
function tfedora.InstallPackageLists(list:string):boolean;
var
   cmd:string;
   u  :string;
   i  :integer;
   ll :TStringDynArray;
   fulllist:string;
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

if not libs.COMMANDLINE_PARAMETERS('--silent') then begin
   readln(u);
end else begin
    u:='y';
end;


if length(u)=0 then u:='y';

if LowerCase(u)<>'y' then exit;


   ll:=Explode(',',list);
   for i:=0 to length(ll)-1 do begin
       if length(trim(ll[i]))>0 then begin
          fulllist:=fulllist + ' ' +  trim(ll[i]);
       end;
   end;

   fpsystem('/usr/bin/yum -y install ' + fulllist);

   if FileExists('/tmp/packages.list') then fpsystem('/bin/rm -f /tmp/packages.list');
   result:=true;


end;
//#########################################################################################
function tfedora.InstallPackageListsSilent(list:string):boolean;
var
   cmd:string;
   u  :string;
   i  :integer;
   ll :TStringDynArray;
   fulllist:string;
begin
if length(trim(list))=0 then exit;
result:=false;

   ll:=Explode(',',list);
   for i:=0 to length(ll)-1 do begin
       if length(trim(ll[i]))>0 then begin
          fulllist:=fulllist + ' ' +  trim(ll[i]);
       end;
   end;

   fpsystem('/usr/bin/yum -y install ' + fulllist);

   if FileExists('/tmp/packages.list') then fpsystem('/bin/rm -f /tmp/packages.list');
   result:=true;


end;
//#########################################################################################
function tfedora.CheckSelinux():string;
var
   l:TstringList;
   f:string;
   i:integer;
   RegExpr:TRegExpr;
begin
result:='';
if not FileExists('/etc/selinux/config') then exit();
l:=TstringList.Create;
l.LoadFromFile('/etc/selinux/config');
RegExpr:=TRegExpr.Create;
RegExpr.Expression:='SELINUX=(.+)';
for i:=0 to l.Count-1 do begin
     if RegExpr.Exec(l.Strings[i]) then begin
         if trim(RegExpr.Match[1])<>'disabled' then begin
            result:='y';
            break;
         end;
     end;
end;
RegExpr.Free;
l.Free;
end;
//#########################################################################################
function tfedora.DisableSeLinux():string;
var
   l:TstringList;
begin
if not FileExists('/etc/selinux/config') then exit();
l:=TstringList.Create;
l.Add('SELINUX=disabled');
l.Add('SELINUXTYPE=targeted');
l.SaveToFile('/etc/selinux/config');
l.free;
Writeln('You need to reboot your computer.....');
Writeln('after rebooting , launch the command');
writeln('"'+paramStr(0)+'"');
halt(0);
end;
//#########################################################################################
function tfedora.CheckPDNS():string;
var
   l:TstringList;
   f:string;
   i:integer;
begin
l:=Tstringlist.Create;
l.add('boost-devel');
l.add('lua');
L.add('lua-devel');

for i:=0 to l.Count-1 do begin
     if not libs.RPM_is_application_installed(l.Strings[i]) then begin
          f:=f + ',' + l.Strings[i];
     end;
end;
 result:=f;
 l.free;

end;
//#########################################################################################

function tfedora.CheckBaseSystem():string;
var
   l:TstringList;
   f:string;
   i:integer;
   D:boolean;
   Major:integer;
begin
D:=libs.COMMANDLINE_PARAMETERS('--verbose');
f:='';
l:=TstringList.Create;
distri:=tdistriDetect.Create();
Major:=distri.DISTRI_MAJOR;

l.Add('cron');
l.Add('file');
l.Add('hdparm');
l.Add('less');
l.Add('rdate');
l.Add('rsync');
l.Add('rsh');
l.Add('openssh');
l.Add('strace');
l.Add('sysfsutils');
l.Add('tcsh');
l.Add('time');
l.Add('eject');
l.add('zlib');

if ArchStruct=64 then begin
   if Major<16 then    l.add('glibc.i686');
   if Major>15 then l.add('glibc');
end;

Writeln('Unsing Fedora major version ',Major);

l.Add('pciutils ');
l.Add('usbutils');

//LDAP
l.Add('openldap-servers');
l.Add('openldap-clients');

l.Add('openssl');

//PHP+LIGHTTPD
l.Add('libmcrypt');
l.Add('lighttpd');
l.Add('lighttpd-fastcgi');
l.Add('php-ldap ');
l.Add('php-mysql');
l.Add('php-imap ');
l.Add('php-pear');
l.Add('php-pear-Log');
l.Add('php-pecl-mailparse');
l.add('php-pear-Mail-Mime');
l.add('php-pear-Net-Sieve');
L.add('php-pecl-apc');
l.Add('php-mbstring');
l.Add('php-mcrypt');
l.Add('php-process');
l.Add('php-gd');

//perl
l.Add('rrdtool');
l.Add('rrdtool-devel');
l.Add('rrdtool-perl');
l.Add('perl-File-Tail');
l.Add('mhonarc');

l.Add('mysql-libs');
l.Add('mysql-server');
l.Add('perl-libwww-perl');

l.Add('cyrus-sasl-ldap');
l.Add('cyrus-sasl');
l.add('perl-Authen-SASL');
l.add('perl-BerkeleyDB');
L.add('awstats');
l.Add('sudo');
l.add('httpd');
l.add('autofs');

//ocs
l.add('perl-Apache2-SOAP');

l.add('nfs-utils');
if Major<16 then l.add('nfs-utils-lib');
if major >15 then l.add('libnfsidmap');
l.add('nfswatch');
l.add('udisks');
l.add('libcgroup');



//DEVEL
l.Add('gcc');
L.add('patch');
l.Add('make');
l.add('bison');
l.add('byacc');
l.add('cmake');
l.add('glib-devel');
l.add('expat-devel'); //for squid
l.add('libxml2-devel'); //for squid
l.add('pcre-devel'); //for squid
l.add('openldap-devel'); //for squid
l.Add('libusb-devel');
l.add('openssl-devel');
l.add('mysql++-devel');
l.add('gdbm-devel');
l.add('flex');
l.add('gcc-c++');
l.add('imake');
l.add('unixODBC-devel');
l.add('unixODBC');
l.add('php-devel');
l.add('freetype-devel');
l.add('t1lib-devel');
l.add('libpaper-devel');
l.add('bzip2-devel');
l.add('aspell-devel');
l.add('libcurl-devel');
l.add('e2fsprogs-devel');
l.add('freetype-devel');
l.add('glibc-devel');
l.add('keyutils-libs-devel');
l.add('krb5-devel');
l.add('libgcc');
l.add('libidn-devel');
l.add('libjpeg-turbo-devel');
l.add('libpng-devel');
l.add('libselinux-devel');
l.add('libsepol-devel');
l.add('libstdc++-devel');
l.add('libX11-devel');
l.add('libXau-devel');
l.add('libXdmcp-devel');
l.add('libXpm-devel');
l.add('net-snmp-devel');
l.add('openldap-devel');
l.add('openssl-devel');
l.add('tcp_wrappers');
l.add('zlib-devel');
l.add('gd-devel');
l.add('libtool-ltdl-devel');
l.add('GeoIP');
l.add('GeoIP-devel');
l.add('readline-devel');
l.add('tcp_wrappers');
l.add('rsync');
l.add('perl-Net-DNS');
l.add('stunnel');
l.add('clamav-devel');
l.add('httpd-devel');
l.add('libpcap-devel');
l.add('libcap-devel');
L.add('bridge-utils');

//l.add('ruby');
//l.add('ruby-cairo');
//l.add('ruby-bdb');
l.add('kernel-devel');
l.add('monit');
l.add('libuuid-devel'); //for zarafa
l.add('scons');
l.add('dmidecode');
l.add('virt-what');

l.Add('ntp');
l.Add('iproute');
l.Add('nmap');
L.add('quota');
l.add('dnsmasq');
L.add('davfs2');
l.add('vconfig');


l.Add('perl-Inline');
l.add('db4-devel');
l.Add('libcdio');
l.Add('libconfuse-devel');
l.add('krb5-devel');
l.add('libgssglue');
l.Add('curl');

//sensors
l.Add('lm_sensors');
l.Add('lm_sensors-devel');
L.add('sysstat');

l.Add('bzip2');
l.Add('arj');
l.add('zip');
l.add('unzip');

//OCS
l.Add('perl-Module-Build');
l.Add('perl-Net-Server');
L.Add('perl-SOAP-Lite');
l.add('perl-Net-IP');
l.add('perl-XML-Simple');
l.add('perl-IO-Compress');
//l.add('perl-Compress-Zlib');
//l.add('perl-LWP');
//l.add('perl-Digest-MD5');
l.add('perl-Net-SSLeay');
l.add('mod_security');
l.add('mod_evasive');


l.Add('htop');
l.Add('telnet');
l.Add('lsof');
l.Add('dar');

fpsystem('/bin/rm -rf /tmp/packages.list');
if D then writeln(IntToStr(l.Count)+ ' packages to check...');

for i:=0 to l.Count-1 do begin
     if D then writeln('CheckBaseSystem:: ' + l.Strings[i]);
     if not libs.RPM_is_application_installed(l.Strings[i]) then begin
          f:=f + ',' + l.Strings[i];
     end;
end;



 result:=f;
end;
//#########################################################################################
function tfedora.CheckPostfix():string;
var
   l:TstringList;
   f:string;
   i:integer;

begin
f:='';
l:=TstringList.Create;
l.Add('perl-Razor-Agent');
l.Add('pyzor');
l.add('sendmail-devel');
l.add('zlib-devel');
l.Add('perl-Crypt-SSLeay');
l.add('perl-Net-SSLeay');
l.Add('perl-Convert-TNEF');
l.Add('perl-HTML-Parser');
l.Add('perl-Archive-Zip');
l.Add('perl-Font-TTF');
l.add('gd');
l.Add('wv');
l.Add('postfix');
l.Add('clamav');
l.add('clamav-milter');
//l.add('dkim-milter');
l.add('sendmail-devel');
l.add('milter-greylist');
//l.add('mimedefang');
if not FileExists('/usr/bin/spamd') then l.Add('spamassassin');
l.Add('mailman');
l.add('postfix-perl-scripts');

l.add('perl-IO-Compress');//Bzip2.pm
l.add('perl-Email-Valid');// */Email/Valid.pm
l.add('perl-File-ReadBackwards'); // **/File/ReadBackwards.pm
l.add('perl-Mail-SPF');// Mail/SPF.pm
l.add('perl-Email-MIME');// Email/MIME.pm
//l.add('perl-Mail-SRS'); // Mail/SRS.pm
l.add('perl-Net-DNS'); // Net/DNS.pm
// Sys/Syslog.pm
l.add('perl-LDAP');// Net/LDAP.pm
l.add('perl-Email-Send');// Email/Send.pm
l.add('perl-IO-Socket-SSL'); // IO/Socket/SSL.pm

//FuzzyOCR
l.add('netpbm');
l.add('gifsicle');
l.add('giflib');
l.add('giflib-utils');
l.add('gocr');
l.add('ocrad');
l.add('ImageMagick');
l.add('tesseract');
l.add('perl-String-Approx');
l.add('perl-MLDBM');

fpsystem('/bin/rm -rf /tmp/packages.list');

for i:=0 to l.Count-1 do begin
     if not libs.RPM_is_application_installed(l.Strings[i]) then begin
          f:=f + ',' + l.Strings[i];
     end;
end;

if not FIleExists('/usr/bin/python') then f:=f + ',python';

 result:=f;
end;
//#########################################################################################
function tfedora.ejabberd():string;
var
   l:TstringList;
   f:string;
   i:integer;

begin
f:='';
l:=TstringList.Create;
l.add('ejabberd');
fpsystem('/bin/rm -rf /tmp/packages.list');

for i:=0 to l.Count-1 do begin
     if not libs.RPM_is_application_installed(l.Strings[i]) then begin
          f:=f + ',' + l.Strings[i];
     end;
end;

if not FIleExists('/usr/bin/python') then f:=f + ',python';

 result:=f;

end;
//#########################################################################################

function tfedora.CheckZabbix():string;
var
   l:TstringList;
   f:string;
   i:integer;

begin
f:='';
l:=TstringList.Create;
l.add('zabbix');
l.add('zabbix-web');
l.add('zabbix-agent');
fpsystem('/bin/rm -rf /tmp/packages.list');

for i:=0 to l.Count-1 do begin
     if not libs.RPM_is_application_installed(l.Strings[i]) then begin
          f:=f + ',' + l.Strings[i];
     end;
end;

if not FIleExists('/usr/bin/python') then f:=f + ',python';

 result:=f;

end;
//#########################################################################################
function tfedora.CheckCyrus():string;
var
   l:TstringList;
   f:string;
   i:integer;
   Major:integer;
begin
distri:=tdistriDetect.Create();
Major:=distri.DISTRI_MAJOR;
f:='';
l:=TstringList.Create;
l.Add('cyrus-imapd');
if Major < 16 then l.Add('cyrus-imapd-perl');
if Major >15 then  l.Add('cyrus-imapd-utils');

for i:=0 to l.Count-1 do begin
     if not libs.RPM_is_application_installed(l.Strings[i]) then begin
          f:=f + ',' + l.Strings[i];
     end;
end;
 result:=f;
 l.free;
end;
//#########################################################################################
function tfedora.checkSamba():string;
var
   l:TstringList;
   f:string;
   i:integer;
   Major:integer;
begin
distri:=tdistriDetect.Create();
Major:=distri.DISTRI_MAJOR;
f:='';
l:=TstringList.Create;
l.Add('nss_ldap');
if Major<16 then l.Add('samba-[0-9\.]+');
if Major>15 then  l.Add('samba');
l.add('samba-winbind');
l.Add('samba-client');
if Major<16 then l.Add('pam_smb');
l.Add('nmap');
l.add('cups-devel');
l.add('gutenprint-cups');
l.add('gtk2-devel');
l.add('libtiff-devel');
l.add('libjpeg-turbo-devel');
l.add('e2fsprogs-devel');
l.add('pam-devel');
l.add('audit');

for i:=0 to l.Count-1 do begin
     if not libs.RPM_is_application_installed(l.Strings[i]) then begin
          l.Strings[i]:=AnsiReplaceText(l.Strings[i],'-[0-9\.]+','');
          if DEBUG then writeln('Cannot found package named ',l.Strings[i]);
          f:=f + ',' + l.Strings[i];
     end;
end;
 result:=f;
 l.free;
end;
//#########################################################################################
function tfedora.CheckDevcollectd():string;
var
   l:TstringList;
   f:string;
   i:integer;

begin
f:='';
l:=TstringList.Create;
l.Add('iproute-dev');
l.Add('xfslibs-dev');
l.Add('librrd2-dev');
l.Add('libsensors-dev');
l.Add('libmysqlclient15-dev');
l.Add('libperl5.8');
L.add('xmms-dev');
L.add('xmms2-dev');
l.add('libesmtp-dev');
l.add('libnotify-dev');
l.add('libxml2-dev');
l.add('libpcap-dev');
l.add('hddtemp');
l.add('mbmon');
l.add('libconfig-general-perl');
l.Add('memcached');
for i:=0 to l.Count-1 do begin
     if not libs.RPM_is_application_installed(l.Strings[i]) then begin
          f:=f + ',' + l.Strings[i];
     end;
end;
 result:=f;
 l.free;
end;



function tfedora.checkSQuid():string;
var
   l:TstringList;
   f:string;
   i:integer;

begin
f:='';
l:=TstringList.Create;
l.Add('squid');
l.Add('awstats');
for i:=0 to l.Count-1 do begin
     if not libs.RPM_is_application_installed(l.Strings[i]) then begin
          f:=f + ',' + l.Strings[i];
     end;
end;
 result:=f;
 l.free;
end;
//########################################################################################
function tfedora.CheckBasePHP():string;
var
   l:TstringList;
   f:string;
   i:integer;
   distri:tdistriDetect;
   UbuntuIntVer:integer;
   libs:tlibs;

begin
f:='';
l:=TstringList.Create;
distri:=tdistriDetect.Create();
libs:=tlibs.Create;

// --enablerepo=centosplus
l.add('httpd-devel');
L.add('openldap-devel');
l.add('expat-devel'); //expat.h
l.add('freetype-devel'); // ftconfig.h
l.add('libgcrypt-devel'); //gcrypt.h
l.add('gd-devel'); //gdcache.h
l.add('gmp-devel'); //gmp.h
//jpegint.h match pas
l.add('krb5-devel'); //gssapi_krb5.h
l.add('libmcrypt-devel'); //mcrypt.h
l.add('libmhash-devel'); //mhash.h
l.add('mysql-devel'); //mysql.h
l.add('ncurses-devel'); //curses.h
l.add('pam-devel'); //pam_ext.h
l.add('pcre-devel'); //pcre.h
l.add('libpng-devel'); //png.h
l.add('postgresql-devel'); //postgresql/c.h match pas
l.add('aspell-devel'); //pspell.h
l.add('recode-devel'); //recode.h
l.add('cyrus-sasl-devel'); //sasl.h
l.add('sqlite-devel'); //sqlite.h
l.add('openssl-devel'); //libcrypto.a
l.add('t1lib-devel'); //t1lib.h
l.add('libtidy-devel');//libtidy.a ,tify.h match pas
l.add('libtool'); //libtool
l.add('tcp_wrappers'); //libwrap.a ,tcpd.h
//libxmlparse.a,libxmlparse.so ,xmlparse.h
l.add('libxml2-devel'); //libxml2.a,libxml2.a
l.add('libxslt-devel'); //libexslt.a
//bin/quilt match pas
l.add('re2c');//bin/re2c
l.add('unixODBC-devel');//sql.h
l.add('zlib-devel');//zlib.h
L.add('chrpath'); //bin/chrpath
l.add('freetds-devel'); //sybdb.h



l.add('libc-client-devel');//c-client/smtp.h
l.add('curl-devel'); //curl.h
l.add('net-snmp-devel'); //agent_callbacks.h


for i:=0 to l.Count-1 do begin
     if not libs.RPM_is_application_installed(l.Strings[i]) then begin
          f:=f + ',' + l.Strings[i];
     end;
end;
 result:=f;


end;
//#########################################################################################
function tfedora.checkApps(l:tstringlist):string;
var
   f:string;
   i:integer;

begin
f:='';
for i:=0 to l.Count-1 do begin
     if not libs.RPM_is_application_installed(l.Strings[i]) then begin
          f:=f + ',' + l.Strings[i];
     end;
end;
 result:=f;
 l.free;
end;

//##############################################################################
function tfedora.Explode(const Separator, S: string; Limit: Integer = 0):TStringDynArray;
var
  SepLen       : Integer;
  F, P         : PChar;
  ALen, Index  : Integer;
begin
  SetLength(Result, 0);
  if (S = '') or (Limit < 0) then
    Exit;
  if Separator = '' then
  begin
    SetLength(Result, 1);
    Result[0] := S;
    Exit;
  end;
  SepLen := Length(Separator);
  ALen := Limit;
  SetLength(Result, ALen);

  Index := 0;
  P := PChar(S);
  while P^ <> #0 do
  begin
    F := P;
    P := StrPos(P, PChar(Separator));
    if (P = nil) or ((Limit > 0) and (Index = Limit - 1)) then
      P := StrEnd(F);
    if Index >= ALen then
    begin
      Inc(ALen, 5); // mehrere auf einmal um schneller arbeiten zu können
      SetLength(Result, ALen);
    end;
    SetString(Result[Index], F, P - F);
    Inc(Index);
    if P^ <> #0 then
      Inc(P, SepLen);
  end;
  if Index < ALen then
    SetLength(Result, Index); // wirkliche Länge festlegen
end;
//#########################################################################################
end.
