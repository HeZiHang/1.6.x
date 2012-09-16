unit bind9;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,Process,logs,unix,RegExpr in 'RegExpr.pas',zsystem,lighttpd;

type LDAP=record
      admin:string;
      password:string;
      suffix:string;
      servername:string;
      Port:string;
  end;

  type
  tbind9=class


private
     LOGS:Tlogs;
     SYS:TSystem;
     artica_path:string;
     lighttp:Tlighttpd;
     DNSServerList:TstringList;
     function PID_PATH():string;
     function FixFIles():string;
     function GET_USER():string;
     function WORKING_DIRECTORY():string;
     function  MergeDNSServersListExists(DnsServer:string):boolean;
     procedure MergeDNSServersList();
     procedure hosts_localhost_cf();
     procedure hosts_255_in_addr_arpa();
     procedure hosts_dot_cf();
     procedure hosts_0_in_addr_arpa();
     procedure CompileArpaZone(Arpa:string);
     procedure CompileDomaineZone(ZoneDomain:string);
public
    procedure   Free;
    constructor Create(const zSYS:Tsystem);
    function    bin_path():string;
    function    rndc_path():string;
    function    conf_path():string;
    function    bindrrd_path():string;
    function    init_d():string;
    procedure   START();
    procedure   STOP();
    function    STATUS():string;
    function    VERSION():string;
    procedure   FIX_PERMISSIONS();
    function    BIND_PID():string;
    procedure   bindrrd_configure();
    function    statistics_path():string;
    procedure   Generate_binrrd();
    function    forwarders():string;
    function    ApplyForwarders(path:string=''):boolean;
    procedure   ApplyLoopBack();
    function    dnssec_keygen_path():string;
    function    GenerateKey(domainname:string):string;

END;

implementation

constructor tbind9.Create(const zSYS:Tsystem);
begin
       forcedirectories('/etc/artica-postfix');
       LOGS:=tlogs.Create();
       SYS:=zSYS;
       lighttp:=Tlighttpd.Create(SYS);
       DNSServerList:=TStringList.Create;

       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;
end;
//##############################################################################
procedure tbind9.free();
begin
    FreeAndNil(logs);
end;
//##############################################################################
function tbind9.bin_path():string;
begin
   if FileExists('/usr/sbin/named') then exit('/usr/sbin/named');
end;
//##############################################################################
function tbind9.init_d():string;
begin
   if FileExists('/etc/init.d/bind9') then exit('/etc/init.d/bind9');
   if FileExists('/etc/init.d/named') then exit('/etc/init.d/named');
end;
//##############################################################################
function tbind9.rndc_path():string;
begin
   if FileExists('/usr/sbin/rndc') then exit('/usr/sbin/rndc');
end;
//##############################################################################
function tbind9.bindrrd_path():string;
begin
if FileExists('/usr/sbin/bindrrdcronjob.sh') then exit('/usr/sbin/bindrrdcronjob.sh');
end;
//#############################################################################
function tbind9.GET_USER():string;
begin
 if SYS.IsUserExists('named') then exit('named');
 if SYS.IsUserExists('bind') then exit('bind');
end;


function tbind9.dnssec_keygen_path():string;
begin
  if FileExists('/usr/sbin/dnssec-keygen') then exit('/usr/sbin/dnssec-keygen');
end;
//#############################################################################
function tbind9.conf_path():string;
begin
if FileExists('/var/named/chroot/etc/named.conf') then exit('/var/named/chroot/etc/named.conf');
if FileExists('/etc/bind/named.conf') then exit('/etc/bind/named.conf');
if FileExists('/etc/named.conf') then exit('/etc/named.conf');
if FileExists('/etc/named.caching-nameserver.conf') then exit('/etc/named.caching-nameserver.conf');
exit('/etc/named.conf');
end;
//#############################################################################

procedure tbind9.FIX_PERMISSIONS();
var
   daemon_user:string;
   global_path:string;
begin
  daemon_user:=GET_USER();
  if length(daemon_user)=0 then begin
     logs.Syslogs('Starting......: bind FAILED unable to define running user');
     exit;
  end;
  logs.Debuglogs('Starting......: bind running has user:'+daemon_user);
  
  global_path:=WORKING_DIRECTORY();
  
 if length(global_path)=0 then begin
     logs.Syslogs('Starting......: bind FAILED unable to determine working directory');
     exit;
  end;
  
  daemon_user:=daemon_user+':'+daemon_user;
  forceDirectories('/var/log/bind');
  forceDirectories('/var/run/bind');
  forceDirectories('/var/dum/bind');
  logs.OutputCmd('/bin/chown -R '+daemon_user+' /var/log/bind');
  logs.OutputCmd('/bin/chown -R '+daemon_user+' /var/run/bind');
  logs.OutputCmd('/bin/chown -R '+daemon_user+' /var/dump/bind');
  logs.OutputCmd('/bin/chown -R '+daemon_user+' '+global_path);
  logs.Debuglogs('Starting......: bind Success setting permissions');
end;
//##############################################################################
function tbind9.WORKING_DIRECTORY():string;
begin
  if DirectoryExists('/var/named') then exit('/var/named');
  if DirectoryExists('/var/cache/bind') then exit('/var/cache/bind');
end;
//##############################################################################
function tbind9.BIND_PID():string;
begin
        result:=trim(SYS.PIDOF(bin_path()));
end;
//##############################################################################
function tbind9.PID_PATH():string;
begin
if FileExists('/var/cache/bind/bind.pid') then exit('/var/cache/bind/bind.pid');
if FileExists('/var/run/bind/bind.pid') then exit('/var/run/bind/bind.pid');
end;
//##############################################################################
procedure tbind9.START();
var
   count:integer;
   pid:string;
   cmd:string;
begin
count:=0;
if not FileExists(bin_path()) then exit;
pid:=BIND_PID();
if SYS.PROCESS_EXIST(pid) then begin
   logs.Debuglogs('Starting......: bind9 Already running PID '+pid);
   if FIleExists(SYS.LOCATE_PDNS_BIN()) then begin
       logs.Debuglogs('Starting......: bind9 -> PowerDNS');
       STOP();
   end;
   exit;
end;

if FIleExists(SYS.LOCATE_PDNS_BIN()) then begin
    logs.Debuglogs('Starting......: bind9 -> PowerDNS');
    STOP();
    exit;
end;

if SYS.MEM_TOTAL_INSTALLEE()<400000 then begin
    logs.Debuglogs('Starting......: bind9 -> No more memory');
    STOP();
    exit;
end;

   FIX_PERMISSIONS();
   bindrrd_configure();

   logs.DebugLogs('Starting......: bind9 '+init_d());
   logs.DebugLogs('Starting......: bind9 '+bin_path());
   ApplyForwarders('');
   FixFIles();
   cmd:=bin_path() +' -c "'+ conf_path()+ '" -4 -u ' + GET_USER();
   logs.OutputCmd('/bin/chown '+ GET_USER + ' ' +conf_path());
   logs.Debuglogs(cmd);
   fpsystem(cmd);


    while not SYS.PROCESS_EXIST(BIND_PID()) do begin
        sleep(100);
        inc(count);
        if count>30 then begin
           logs.DebugLogs('Starting......: bind9 (failed)');
           exit;
        end;
    end;

if SYS.PROCESS_EXIST(BIND_PID()) then logs.OutputCmd(artica_path + '/bin/artica-ldap --bind9-compile');

logs.DebugLogs('Starting......: bind9 with new PID ' + BIND_PID());

end;
//##############################################################################
procedure tbind9.STOP();
 var
    pid:string;
    count:integer;
begin
count:=0;
  if not FileExists(bin_path()) then exit;

  pid:=BIND_PID();
  
  if not SYS.PROCESS_EXIST(pid) then begin
       writeln('Stopping bind9...............: Already stopped pid='+pid);
       exit;
  end;
  
  
   writeln('Stopping bind9...............: ' + pid + ' PID');

   fpsystem('/bin/kill '+pid);

       while SYS.PROCESS_EXIST(pid) do begin
        sleep(100);
        inc(count);
        if count>30 then begin
           writeln('Stopping bind9...............: time-out');
           break;
        end;
       end;
  pid:=BIND_PID();
  if SYS.PROCESS_EXIST(pid) then STOP();

end;
//##############################################################################
function tbind9.STATUS():string;
var
   ini:TstringList;
   pid:string;
begin
 if not FileExists(bin_path()) then exit;
 pid:=BIND_PID();
ini:=TstringList.Create;
   ini.Add('[BIND9]');
   if SYS.PROCESS_EXIST(pid) then ini.Add('running=1') else  ini.Add('running=0');
   ini.Add('master_pid='+pid);
   ini.Add('master_version='+VERSION());
   ini.Add('application_installed=1');
   ini.Add('master_memory='+ IntToStr(SYS.PROCESS_MEMORY(pid)));
   ini.Add('status='+SYS.PROCESS_STATUS(pid));
   ini.Add('service_name=APP_BIND9');
   ini.Add('service_cmd=bind9');
   if FIleExists(SYS.LOCATE_PDNS_BIN()) then begin
      ini.Add('service_disabled=0');
   end;
   result:=ini.Text;
   ini.free;

end;
//##############################################################################
function tbind9.VERSION():string;
var
   RegExpr        :TRegExpr;
   D              :boolean;
   F              :TstringList;
   T              :string;
   i              :integer;
begin
   result:='';
   
  D:=SYS.COMMANDLINE_PARAMETERS('--verbose');
  result:=SYS.GET_CACHE_VERSION('APP_BIND9');
  if length(result)>0 then exit;
   
   if not FileExists(BIN_PATH()) then begin
      if D then writeln('tbind9.VERSION() -> unable to stat binary');
      exit;
   end;
   t:=logs.FILE_TEMP();
   fpsystem(BIN_PATH()+' -v >'+t+' 2>&1');
   if not FileExists(t) then exit;
   f:=TstringList.Create;
   f.LoadFromFile(t);
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='BIND\s+([0-9\.\-A-Za-z]+)';
   For i:=0 to f.Count-1 do begin

   if RegExpr.Exec(f.Strings[i]) then begin
      result:=RegExpr.Match[1];
      break;
   end;
   end;

   RegExpr.Free;
   f.free;
     SYS.SET_CACHE_VERSION('APP_BIND9',result);
end;
//#############################################################################
function tbind9.GenerateKey(domainname:string):string;
var
   RegExpr        :TRegExpr;
   host           :string;
   i              :integer;
   kyfile         :string;
   l              :TstringList;
   pattern        :string;

begin

    if not FileExists(dnssec_keygen_path()) then begin
       logs.Syslogs('Starting......: bind9 Unable to stat dnssec-keygen');
       exit;
    end;
    
    
    host:=SYS.HOSTNAME_g();
    RegExpr:=TRegExpr.Create;
    if length(domainname)=0 then begin
        RegExpr.Expression:='(.+?)\.(.+)';
        if not RegExpr.Exec(host) then domainname:='localhost.localdomain' else domainname:=RegExpr.Match[1];
    end;
    
    forceDirectories('/tmp/dnsskey');
    SetCurrentDir('/tmp/dnsskey');
    logs.OutputCmd(dnssec_keygen_path()+' -a hmac-md5 -b 128 -n host '+ domainname);
    SYS.DirFiles('/tmp/dnsskey','*.private');
    if SYS.DirListFiles.Count=0 then exit;
    kyfile:='/tmp/dnsskey/'+SYS.DirListFiles.Strings[0];
    logs.Debuglogs('tbind9.GenerateKey():: Generated file ' + kyfile);
    l:=TstringList.Create;
    l.LoadFromFile(kyfile);
    RegExpr.Expression:='Key:\s+(.+)';
    for i:=0 to l.Count-1 do begin
        if RegExpr.Exec(l.Strings[i]) then begin
             pattern:=RegExpr.Match[1];
             break;
        end;
    end;


    if length(pattern)>0 then begin
        logs.Debuglogs('tbind9.GenerateKey():: Generated string ' + pattern);
        result:=pattern;
    end;
    SetCurrentDir('/tmp');
    fpsystem('/bin/rm -rf /tmp/dnsskey');

end;
//#############################################################################
procedure tbind9.MergeDNSServersList();
var
 i:integer;
 PostfixEnabledInBind9:integer;
 l:TstringList;
begin

PostfixEnabledInBind9:=0;
l:=TstringList.Create;
DNSServerList.Clear;
if not TryStrToInt(SYS.GET_INFO('PostfixEnabledInBind9'),PostfixEnabledInBind9) then  PostfixEnabledInBind9:=0;

if PostfixEnabledInBind9=1 then begin
   if FileExists('/etc/artica-postfix/settings/Daemons/PostfixBind9DNSList') then begin
      l.LoadFromFile('/etc/artica-postfix/settings/Daemons/PostfixBind9DNSList');
      for i:=0 to l.Count-1 do begin
              if not MergeDNSServersListExists(l.Strings[i]) then DNSServerList.Add(l.Strings[i]);
      end;
  end;
end;
l.Clear;

if FileExists('/etc/artica-postfix/settings/Daemons/Bind9ForwardersList') then begin
      l.LoadFromFile('/etc/artica-postfix/settings/Daemons/Bind9ForwardersList');
      for i:=0 to l.Count-1 do begin
              if not MergeDNSServersListExists(l.Strings[i]) then DNSServerList.Add(l.Strings[i]);
      end;
  end;

  l.free;

end;

//#############################################################################
function tbind9.MergeDNSServersListExists(DnsServer:string):boolean;
var
   i:integer;
begin
     result:=false;
     for i:=0 to DNSServerList.Count-1 do begin
         if DNSServerList.Strings[i]=DnsServer then begin
            result:=true;
            break;
         end;
     end;

end;
//#############################################################################




function tbind9.ApplyForwarders(path:string):boolean;
var
l:TstringList;
RegExpr        :TRegExpr;
i:Integer;
working_path:string;
firstkey:string;
ZoneDomain:string;
ConfigFolder:string;
FilSystem:Tsystem;
begin
result:=false;
working_path:=WORKING_DIRECTORY();
configFolder:='/etc/artica-postfix/settings/Daemons';
logs.DebugLogs('Starting......: bind9 Apply forwarders and change configuration');
logs.DebugLogs('Starting......: bind9 working directory on '+working_path);

if length(working_path)=0 then begin
    logs.DebugLogs('Starting......: bind9 (failed) unable to determine working directory');
    exit;
end;

firstkey:=SYS.GET_INFO('Bind9GlobalKey');
if length(firstkey)=0 then firstkey:=GenerateKey('');
SYS.set_INFO('Bind9GlobalKey',firstkey);

l:=TstringList.Create;
l.add('key "globalkey" {');
l.Add(chr(9)+'algorithm hmac-md5;');
l.Add(chr(9)+'secret "'+firstkey+'";');
l.Add('};');

if FileExists('/etc/bind/rndc.key') then begin
   logs.DebugLogs('Starting......: bind9 save /etc/bind/rndc.key');
   l.SaveToFile('/etc/bind/rndc.key');
end;

l.Add('');
l.Add('options {');
l.Add(chr(9)+'default-key "globalkey";');
l.Add(chr(9)+'default-server 127.0.0.1;');
l.Add(chr(9)+'default-port 953;');
l.Add('};');
l.Add('');

logs.DebugLogs('Starting......: bind9 save /etc/rndc.conf');
try
l.SaveToFile('/etc/rndc.conf');
except
logs.DebugLogs('Starting......: bind9 FATAL ERROR ON /etc/rndc.conf');
end;
l.Clear;
l.Add('controls {');
l.Add(chr(9)+'inet 127.0.0.1 port 953');
l.add(chr(9)+chr(9)+'allow { localhost; } keys { "globalkey"; };');
l.Add('};');
l.add('');
l.add('key "globalkey" {');
l.Add(chr(9)+'algorithm hmac-md5;');
l.Add(chr(9)+'secret "'+firstkey+'";');
l.Add('};');
l.add('');
l.add('');
l.add('');
l.Add('options {');
l.Add(chr(9)+'directory "'+working_path+'";');
l.Add(chr(9)+'pid-file    "bind.pid";');
l.Add(chr(9)+'dump-file    "named_dump.db";');
l.Add(chr(9)+'statistics-file    "named.stats";');
l.Add(chr(9)+'auth-nxdomain no;    # conform to RFC1035');
l.Add(chr(9)+'listen-on-v6 { any; };');
l.Add(chr(9)+'forwarders {');

MergeDNSServersList();

logs.Debuglogs('ApplyForwarders():: DNSServerList.count='+IntTOstr(DNSServerList.Count)+' nameservers');
      for i:=0 to DNSServerList.Count-1 do begin
          if length(trim(DNSServerList.Strings[i]))>0 then begin
           logs.Syslogs('Apply '+DNSServerList.Strings[i] + ' has a forwarder namserver');
           l.Add(chr(9)+chr(9)+ DNSServerList.Strings[i]+';');
          end;
      end;

logs.Debuglogs('ApplyForwarders():: finish forwarders');

l.Add('	};');
l.Add('};');
l.Add('');
l.Add('logging {');
l.Add('	channel update_debug {');
l.Add('		file "log-update-debug.log" versions 3 size 100k;');
l.Add('		severity  debug 5;');
l.Add('		print-category yes;');
l.Add('		print-severity yes;');
l.Add('		print-time     yes;');
l.Add('	};');
l.Add('	channel security_info    {');
l.Add('		file "log-named-auth.info";');
l.Add('		severity  info;');
l.Add('		print-category yes;');
l.Add('		print-severity yes;');
l.Add('		print-time     yes;');
l.Add('	};');
l.Add('');
l.Add('	channel queries_info        {');
l.Add('		file "log-queries.info";');
l.Add('		severity  info;');
l.Add('		print-category yes;');
l.Add('		print-severity yes;');
l.Add('		print-time     yes;');
l.Add('	};');
l.Add('');
l.Add('	 channel lame_info        {');
l.Add('		file "log-lame.info";');
l.Add('		severity  info;');
l.Add('		print-category yes;');
l.Add('		print-severity yes;');
l.Add('		print-time     yes;');
l.Add('	};');
l.Add('');
l.Add('	category update { update_debug; };');
l.Add('	category security { security_info; };');
l.Add('	category queries { queries_info; };');
l.Add('	category lame-servers { lame_info; };');
l.Add('};');
l.Add('');
l.Add('zone "." {');
l.Add('	type hint;');
l.Add('	file "/etc/bind/hosts.dot.cf";');
l.Add('};');
l.Add('');
l.Add('zone "localhost" {');
l.Add('	type master;');
l.Add('	file "/etc/bind/hosts.localhost.cf";');
l.Add('};');
l.Add('');
l.Add('zone "127.in-addr.arpa" {');
l.Add('	type master;');
l.Add('	file "/etc/bind/hosts.127.in-addr.arpa.cf";');
l.Add('};');
l.Add('');
l.Add('zone "0.in-addr.arpa" {');
l.Add('	type master;');
l.Add('	file "/etc/bind/hosts.0.in-addr.arpa.cf";');
l.Add('};');
l.Add('');
l.Add('zone "255.in-addr.arpa" {');
l.Add('	type master;');
l.Add('	file "/etc/bind/hosts.255.in-addr.arpa.cf";');
l.Add('};');
l.Add('');
RegExpr:=TRegExpr.Create;

logs.Debuglogs('ApplyForwarders():: Settings zones...');

ForceDirectories('/etc/bind');
FilSystem:=Tsystem.Create();


try
   FilSystem.DirFiles('/etc/artica-postfix/settings/Daemons','Bind9Zone.*.zone.*');
except
   logs.Syslogs('Starting......: bind9 FATAL ERROR while try to list Bind9Zone files settings');
   exit;
end;


logs.Debuglogs('ApplyForwarders():: Settings zones...' +IntTOStr(FilSystem.DirListFiles.Count) + ' zones');

if FilSystem.DirListFiles.Count>0 then begin
      for i:=0 to FilSystem.DirListFiles.Count-1 do begin
          RegExpr.Expression:='Bind9Zone\.(.+?)\.zone\.hosts$';
          if RegExpr.Exec(FilSystem.DirListFiles.Strings[i]) then begin
             ZoneDomain:=RegExpr.Match[1];
             CompileDomaineZone(ZoneDomain);


             logs.DebugLogs('Starting......: bind9 include zone ' + ZoneDomain);
             logs.DebugLogs('ApplyForwarders()::  Loading '+configFolder+'/'+FilSystem.DirListFiles.Strings[i]);
             l.Add(logs.ReadFromFile(configFolder+'/'+FilSystem.DirListFiles.Strings[i]));
          end;
          
          RegExpr.Expression:='Bind9Zone\.(.+?)\.zone\.arpa$';
          if RegExpr.Exec(FilSystem.DirListFiles.Strings[i]) then begin
             logs.DebugLogs('Starting......: bind9 include reverse zone ' + RegExpr.Match[1]);
             CompileArpaZone( RegExpr.Match[1]);
             logs.DebugLogs('ApplyForwarders():: Loading '+configFolder+'/'+FilSystem.DirListFiles.Strings[i]);
             l.Add(logs.ReadFromFile(configFolder+'/'+FilSystem.DirListFiles.Strings[i]));
          end;
             
      end;
end;
      
if not FileExists('/etc/bind/hosts.0.in-addr.arpa.cf') then logs.OutputCmd('/bin/touch /etc/bind/hosts.0.in-addr.arpa.cf');
if not FileExists('/etc/bind/hosts.127.in-addr.arpa.cf') then logs.OutputCmd('/bin/touch /etc/bind/hosts.127.in-addr.arpa.cf');
if not FileExists('/etc/bind/hosts.0.in-addr.arpa.cf') then logs.OutputCmd('/bin/touch /etc/bind/hosts.0.in-addr.arpa.cf');
if not FileExists('/etc/bind/hosts.255.in-addr.arpa.cf') then logs.OutputCmd('/bin/touch /etc/bind/hosts.255.in-addr.arpa.cf');

hosts_localhost_cf();
 //hosts.255.in-addr.arpa.cf
hosts_255_in_addr_arpa();
//hosts.0.in-addr.arpa.cf
hosts_0_in_addr_arpa();
//hosts.dot.cf
hosts_dot_cf();
try
logs.Debuglogs('ApplyForwarders():: saving '+conf_path);
logs.WriteToFile(l.Text,conf_path());
except
      logs.Syslogs('tbind9.ApplyForwarders() fatal error while saving named.conf: '+conf_path());
      exit;
end;

l.free;

end;
//#############################################################################
procedure tbind9.CompileArpaZone(Arpa:string);
var
   configFolder:string;
   CompileFile:string;
begin

configFolder:='/etc/artica-postfix/settings/Daemons';

if fileExists(configFolder+'/Bind9Zone.'+ Arpa+'.zone.arpa.header') then begin
   logs.DebugLogs('Starting......: bind9 include reverse file ' + Arpa);
   CompileFile:=logs.ReadFromFile(configFolder+'/Bind9Zone.'+Arpa+'.zone.arpa.header');
    if FileExists(configFolder+'/Bind9Zone.'+Arpa+'.zone.arpa.footer') then begin
       CompileFile:=CompileFile+logs.ReadFromFile(configFolder+'/Bind9Zone.'+Arpa+'.zone.arpa.footer');
    end else begin
        logs.Debuglogs('CompileArpaZone():: unable to stat '+configFolder+'/Bind9Zone.'+ Arpa+'.zone.arpa.footer');
    end;

    logs.WriteToFile(compilefile,'/etc/bind/'+Arpa+'.arpa');
end else begin
    logs.Debuglogs('CompileArpaZone():: unable to stat '+configFolder+'/Bind9Zone.'+ Arpa+'.zone.arpa.header');
end;

end;
//#############################################################################
procedure tbind9.CompileDomaineZone(ZoneDomain:string);
var
   configFolder:string;
   CompileFile:string;
begin

configFolder:='/etc/artica-postfix/settings/Daemons';

if fileExists(configFolder+'/Bind9Zone.'+ ZoneDomain+'.hosts') then begin
   logs.DebugLogs('Starting......: bind9 include hosts ' + ZoneDomain);
   CompileFile:=logs.ReadFromFile(configFolder+'/Bind9Zone.'+ZoneDomain+'.hosts');
    if FileExists(configFolder+'/Bind9Zone.'+ZoneDomain+'.footer') then CompileFile:=CompileFile+logs.ReadFromFile(configFolder+'/Bind9Zone.'+ZoneDomain+'.footer');
    logs.WriteToFile(CompileFile,'/etc/bind/Bind9Zone.'+ZoneDomain+'.hosts');
end;

end;
//#############################################################################


procedure tbind9.hosts_dot_cf();

var
   l:Tstringlist;
   FileSize:longint;
   filepath:string;
begin
filepath:='/etc/bind/hosts.dot.cf';
FileSize:= SYS.FileSize_bytes(filepath);
logs.Debuglogs(filepath+':'+IntToStr(FileSize)+ ' bytes');

if FileSize>5 then begin
      logs.DebugLogs('Starting......: bind9 ' + ExtractFileName(filepath) + ' OK');
      exit;
end;

l:=TstringList.Create;

l.Add('.                        3600000  IN  NS    A.ROOT-SERVERS.NET.');
l.Add('A.ROOT-SERVERS.NET.      3600000      A     198.41.0.4');
l.Add('A.ROOT-SERVERS.NET.      3600000      AAAA  2001:503:BA3E::2:30');
l.Add('.                        3600000      NS    B.ROOT-SERVERS.NET.');
l.Add('B.ROOT-SERVERS.NET.      3600000      A     192.228.79.201');
l.Add('.                        3600000      NS    C.ROOT-SERVERS.NET.');
l.Add('C.ROOT-SERVERS.NET.      3600000      A     192.33.4.12');
l.Add('.                        3600000      NS    D.ROOT-SERVERS.NET.');
l.Add('D.ROOT-SERVERS.NET.      3600000      A     128.8.10.90');
l.Add('.                        3600000      NS    E.ROOT-SERVERS.NET.');
l.Add('E.ROOT-SERVERS.NET.      3600000      A     192.203.230.10');
l.Add('.                        3600000      NS    F.ROOT-SERVERS.NET.');
l.Add('F.ROOT-SERVERS.NET.      3600000      A     192.5.5.241');
l.Add('F.ROOT-SERVERS.NET.      3600000      AAAA  2001:500:2f::f');
l.Add('.                        3600000      NS    G.ROOT-SERVERS.NET.');
l.Add('G.ROOT-SERVERS.NET.      3600000      A     192.112.36.4');
l.Add('.                        3600000      NS    H.ROOT-SERVERS.NET.');
l.Add('H.ROOT-SERVERS.NET.      3600000      A     128.63.2.53');
l.Add('H.ROOT-SERVERS.NET.      3600000      AAAA  2001:500:1::803f:235');
l.Add('.                        3600000      NS    I.ROOT-SERVERS.NET.');
l.Add('I.ROOT-SERVERS.NET.      3600000      A     192.36.148.17');
l.Add('.                        3600000      NS    J.ROOT-SERVERS.NET.');
l.Add('J.ROOT-SERVERS.NET.      3600000      A     192.58.128.30');
l.Add('J.ROOT-SERVERS.NET.      3600000      AAAA  2001:503:C27::2:30');
l.Add('.                        3600000      NS    K.ROOT-SERVERS.NET.');
l.Add('K.ROOT-SERVERS.NET.      3600000      A     193.0.14.129 ');
l.Add('K.ROOT-SERVERS.NET.      3600000      AAAA  2001:7fd::1');
l.Add('.                        3600000      NS    L.ROOT-SERVERS.NET.');
l.Add('L.ROOT-SERVERS.NET.      3600000      A     199.7.83.42');
l.Add('.                        3600000      NS    M.ROOT-SERVERS.NET.');
l.Add('M.ROOT-SERVERS.NET.      3600000      A     202.12.27.33');
l.Add('M.ROOT-SERVERS.NET.      3600000      AAAA  2001:dc3::35');



try
   l.SaveToFile(filepath);
except
   logs.Syslogs('Starting......: bind9 FATAL ERROR WHILE SAVING '+filepath);
   exit;
end;

l.free;

end;

//#############################################################################
procedure tbind9.hosts_0_in_addr_arpa();

var
   l:Tstringlist;
   FileSize:longint;
   filepath:string;
begin
filepath:='/etc/bind/hosts.0.in-addr.arpa.cf';
FileSize:= SYS.FileSize_bytes(filepath);
logs.Debuglogs(filepath+':'+IntToStr(FileSize)+ ' bytes');

if FileSize>5 then begin
      logs.DebugLogs('Starting......: bind9 ' + ExtractFileName(filepath) + ' OK');
      exit;
end;

l:=TstringList.Create;

l.Add('$TTL	604800');
l.Add('@	IN	SOA	localhost. root.localhost. (');
l.Add('			      1		; Serial');
l.Add('			 604800		; Refresh');
l.Add('			  86400		; Retry');
l.Add('			2419200		; Expire');
l.Add('			 604800 )	; Negative Cache TTL');
l.Add(';');
l.Add('@	IN	NS	localhost.');

try
   l.SaveToFile(filepath);
except
   logs.Syslogs('Starting......: bind9 FATAL ERROR WHILE SAVING '+filepath);
   exit;
end;

l.free;

end;

//#############################################################################
procedure tbind9.hosts_255_in_addr_arpa();

var
   l:Tstringlist;
   FileSize:longint;
   filepath:string;
begin
filepath:='/etc/bind/hosts.255.in-addr.arpa.cf';
FileSize:= SYS.FileSize_bytes(filepath);
logs.Debuglogs(filepath+':'+IntToStr(FileSize)+ ' bytes');

if FileSize>5 then begin
      logs.DebugLogs('Starting......: bind9 ' + ExtractFileName(filepath) + ' OK');
      exit;
end;

l:=TstringList.Create;

l.Add('$TTL	604800');
l.Add('@	IN	SOA	localhost. root.localhost. (');
l.Add('			      1		; Serial');
l.Add('			 604800		; Refresh');
l.Add('			  86400		; Retry');
l.Add('			2419200		; Expire');
l.Add('			 604800 )	; Negative Cache TTL');
l.Add(';');
l.Add('@	IN	NS	localhost.');

try
   l.SaveToFile(filepath);
except
   logs.Syslogs('Starting......: bind9 FATAL ERROR WHILE SAVING '+filepath);
   exit;
end;

l.free;

end;
//#############################################################################
procedure tbind9.hosts_localhost_cf();

var
   l:Tstringlist;
   FileSize:longint;
   filepath:string;
begin
filepath:='/etc/bind/hosts.localhost.cf';
FileSize:= SYS.FileSize_bytes(filepath);
logs.Debuglogs(filepath+':'+IntToStr(FileSize)+ ' bytes');

if FileSize>5 then begin
      logs.DebugLogs('Starting......: bind9 ' + ExtractFileName(filepath) + ' OK');
      exit;
end;

l:=TstringList.Create;

l.add('$TTL	604800');
l.add('@	IN	SOA	localhost. root.localhost. (');
l.add('			      2		; Serial');
l.add('			 604800		; Refresh');
l.add('			  86400		; Retry');
l.add('			2419200		; Expire');
l.add('			 604800 )	; Negative Cache TTL');
l.add(';');
l.add('@	IN	NS	localhost.');
l.add('@	IN	A	127.0.0.1');
l.add('@	IN	AAAA	::1');

try
   l.SaveToFile(filepath);
except
   logs.Syslogs('Starting......: bind9 FATAL ERROR WHILE SAVING '+filepath);
   exit;
end;

l.free;

end;
//#############################################################################

function tbind9.FixFIles():string;

var
   conffile:TstringList;
   RegExpr        :TRegExpr;
   i:Integer;
   tf:string;

begin
   result:='';
   if not FileExists(conf_path()) then exit;
   conffile:=TstringList.Create;
   conffile.LoadFromFile(conf_path());
   RegExpr:=TRegExpr.Create;
      RegExpr.Expression :='file\s+(.+?);';
for i:=0 to conffile.Count-1 do begin
      if RegExpr.Exec(conffile.Strings[i]) then begin
           tf:=AnsiReplaceText(RegExpr.Match[1],'"','');
           logs.Debuglogs('FixFIles():'+tf);
           if not FileExists(tf) then logs.OutputCmd('/bin/touch ' + tf);
      end;
end;

RegExpr.Free;
conffile.Free;
end;
//#############################################################################
function tbind9.forwarders():string;

var
   conffile:TstringList;
   RegExpr        :TRegExpr;
   start:boolean;
   start1:boolean;
   i:Integer;

begin

   if not FileExists(conf_path()) then exit;
   conffile:=TstringList.Create;
   conffile.LoadFromFile(conf_path());
   RegExpr:=TRegExpr.Create;
   start:=false;
   start1:=false;
for i:=0 to conffile.Count-1 do begin
   if not start then begin
      RegExpr.Expression :='forwarders';
      if RegExpr.Exec(conffile.Strings[i]) then start:=true;
   end;
   
   if not start1 then begin
    RegExpr.Expression :='\{';
    if RegExpr.Exec(conffile.Strings[i]) then start1:=true;
   end;
   
   if start1 then begin
      RegExpr.Expression :='([0-9\.]+);';
      if RegExpr.Exec(conffile.Strings[i]) then result:=result+RegExpr.Match[1]+';';
      RegExpr.Expression :='\}';
      if RegExpr.Exec(conffile.Strings[i]) then break;
   end;
end;

RegExpr.Free;
conffile.Free;
end;
//#############################################################################
procedure tbind9.ApplyLoopBack();
var
   RegExpr        :TRegExpr;
   D              :boolean;
   L              :TstringList;
   i              :integer;
begin
   if not FileExists('/etc/resolv.conf') then exit;
   logs.Debuglogs('ApplyLoopBack():: Start');
   l:=TstringList.Create;
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^nameserver\s+([0-9\.]+)';
   l.LoadFromFile('/etc/resolv.conf');
   d:=false;
   logs.Debuglogs('ApplyLoopBack():: on ' + IntToStr(l.Count) + ' lines');
   for i:=0 to l.Count-1 do begin
   
       if RegExpr.Exec(l.Strings[i]) then begin
          if RegExpr.Match[1]='127.0.0.1' then begin
             logs.Syslogs('127.0.0.1 already exists in /etc/resolv.conf');
             d:=true;
             break;
          end;
       end else begin

       end;
   end;
   
   if not D then begin
     try
      l.Insert(0,'nameserver 127.0.0.1');
     except
       logs.Syslogs('tbind9.ApplyLoopBack(): fatal error while saving 127.0.0.1 in array object');
       exit;
     end;


      try
         l.SaveToFile('/etc/resolv.conf');
         logs.Syslogs('Success saving 127.0.0.1 in /etc/resolv.conf');
      except
         logs.Syslogs('tbind9.ApplyLoopBack(): fatal error while saving 127.0.0.1 in /etc/resolv.conf');
         exit;
      end;
      
  end;
  
  

  l.free;
end;
//#############################################################################
function tbind9.statistics_path():string;
var
   RegExpr        :TRegExpr;
   F              :TstringList;
   i              :integer;
begin
   result:='';
   if not FileExists(BIN_PATH()) then begin
      logs.Debuglogs('tbind9.statistics_path() -> unable to stat binary');
      exit;
   end;
   
   if not FileExists(conf_path()) then begin
       logs.Debuglogs('tbind9.statistics_path() -> unable to stat named.conf');
      exit;
   end;
   

   
   f:=TstringList.Create;
   f.LoadFromFile(conf_path());
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='statistics-file[\s+"]+(.+?)"';
   
   For i:=0 to f.Count-1 do begin
       if RegExpr.Exec(f.Strings[i]) then begin
          result:=RegExpr.Match[1];
          break;
       end;
   end;

   RegExpr.Free;
   f.free;
end;
//#############################################################################
procedure tbind9.Generate_binrrd();
var
stat:string;
begin
if not FileExists(rndc_path()) then exit;
if not FileExists('/usr/sbin/bind-rrd-collect.pl') then exit;
logs.OutputCmd(rndc_path()+' stats');
stat:=statistics_path();
logs.OutputCmd('/usr/sbin/bind-rrd-collect.pl '+stat+' /opt/artica/var/rrd/bindrrd');
logs.DeleteFile(stat);
end;
//#############################################################################

procedure tbind9.bindrrd_configure();
var
   RegExpr        :TRegExpr;
   F              :TstringList;
   i              :integer;
   stat           :string;
begin

   if not FileExists(bindrrd_path()) then begin
      logs.Debuglogs('tbind9.bindrrd_configure() -> unable to stat bindrrd cron job');
      exit;
   end;
      stat:=statistics_path();
   if length(stat)=0 then begin
        logs.Debuglogs('tbind9.bindrrd_configure() -> unable to determine statistics path');
        exit;
   end;
   

   f:=TstringList.Create;
   f.LoadFromFile(bindrrd_path());
   RegExpr:=TRegExpr.Create;
   forcedirectories('/opt/artica/var/rrd/bindrrd');

   For i:=0 to f.Count-1 do begin

       RegExpr.Expression:='STATS="';
       if RegExpr.Exec(f.Strings[i]) then begin
          f.Strings[i]:='STATS="'+stat+'"';
          logs.Debuglogs('Starting......: bindrrd statistics-file has ' + stat);
       end;
   
       RegExpr.Expression:='WORKDIR="';
       if RegExpr.Exec(f.Strings[i]) then begin
          f.Strings[i]:='WORKDIR="/opt/artica/var/rrd/bindrrd"';
       end;
   end;
   f.SaveToFile(bindrrd_path());

   
   if FileExists('/usr/lib/cgi-bin/bindrrd-grapher.pl') then begin
        RegExpr.Expression:='my \$workdir';
        f.LoadFromFile('/usr/lib/cgi-bin/bindrrd-grapher.pl');
        for i:=0 to f.Count-1 do begin
              if RegExpr.Exec(f.Strings[i]) then begin
                 f.Strings[i]:='my $workdir = "/opt/artica/var/rrd/bindrrd";';
                 f.SaveToFile('/usr/lib/cgi-bin/bindrrd-grapher.pl');
                 break;
              end;
        end;

   end;
   
   if FileExists('/usr/lib/cgi-bin/bindrrd-overview.pl') then begin
        RegExpr.Expression:='my \$workdir';
        f.LoadFromFile('/usr/lib/cgi-bin/bindrrd-overview.pl');
        for i:=0 to f.Count-1 do begin
              if RegExpr.Exec(f.Strings[i]) then begin
                 f.Strings[i]:='my $workdir = "/opt/artica/var/rrd/bindrrd";';
                 f.SaveToFile('/usr/lib/cgi-bin/bindrrd-overview.pl');
                 break;
              end;
        end;

   end;
        
   
   RegExpr.Free;
   f.free;
   SYS.CRON_CREATE_SCHEDULE('* * * * *',artica_path + '/bin/artica-install --bindrrd','artica-binrrd');

   
end;
//#############################################################################


end.
