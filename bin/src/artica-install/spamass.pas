unit spamass;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,Process,
    logs in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/logs.pas',unix,
    RegExpr in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/RegExpr.pas',
    zsystem;

type LDAP=record
      admin:string;
      password:string;
      suffix:string;
      servername:string;
      Port:string;
  end;

  type
  Tspamass=class


private
     LOGS:Tlogs;
     SYS:        TSystem;
     artica_path:string;
     SpamAssMilterEnabled:Integer;
     EnableSaBlackListUpdate:Integer;
     InsufficentRessources:boolean;
     enable_dkim_verification:integer;
     EnableSPF:integer;
     function    COMMANDLINE_PARAMETERS(FoundWhatPattern:string):boolean;
     function    ReadFileIntoString(path:string):string;
     function    TRUSTED_NETWORK():string;
     procedure   SPAMASSASSIN_REMOVE_INCLUDE_FILE(filepath:string);
     procedure   SPAMASSASSIN_REMOVE_PLUGIN(plugin:string);
     function    BLOCK_MAIL():string;
     procedure   SPAMASSASSIN_init_pre();
     function    GET_VALUE(key:string):string;
     procedure   CHANGE_INITD_SPAMASS();

public
    SpamdEnabled:integer;
    procedure   Free;
    constructor Create(const zSYS:Tsystem);
    FUNCTION    MILTER_INITD_PATH():string;
    FUNCTION    MILTER_DAEMON_BIN_PATH():string;
    FUNCTION    MILTER_SOCKET_PATH():string;
    FUNCTION    MILTER_PID():string;
    PROCEDURE   MILTER_ETC_DEFAULT();
    procedure   MILTER_START();
    procedure   MILTER_STOP();
    function    MILTER_VERSION():string;
    FUNCTION    MILTER_DEFAULT_PATH():string;
    procedure   CHANGE_INITD_MILTER();
    function    rewrite_header():string;
    function    SPAMASSASSIN_LOCAL_CF():string;
    function    SPAMASSASSIN_BIN_PATH():string;
    procedure   SPAMASSASSIN_START();
    function    SPAMASSASSIN_INITD():string;
    procedure   SPAMASSASSIN_ETC_DEFAULT();
    procedure   SPAMASSASSIN_STOP();
    function    SPAMASSASSIN_PID():string;
    FUNCTION    SPAMASSASSIN_STATUS():string;
    function    SPAMASSASSIN_VERSION():string;
    function    SPAMASSASSIN_PATTERN_VERSION():string;
    procedure   SPAMASSASSIN_ADD_INCLUDE_FILE(filepath:string);
    procedure   SPAMASSASSIN_ADD_PLUGIN(plugin:string);
    procedure   SPAMASSASSIN_RELOAD();
    function    SA_UPDATE_PATH():string;
    function    IF_PATTERN_FOUND(pattern:string):boolean;
    function    IS_SPAMD_ENABLED:integer;
    function    RAZOR_AGENT_CONF_PATH():string;
    function    RAZOR_ADMIN_PATH():string;
    procedure   RAZOR_INIT();
    procedure   RAZOR_SET_VALUE(key:string;value:string);
    function    RAZOR_GET_VALUE(key:string):string;
    procedure   DEFAULT_SETTINGS();

    function    PYZOR_BIN_PATH():string;
    procedure   DSPAM_PATCH();

END;

implementation

constructor Tspamass.Create(const zSYS:Tsystem);
begin
       forcedirectories('/etc/artica-postfix');
       LOGS:=tlogs.Create();
       SYS:=zSYS;
       SpamAssMilterEnabled:=0;
       SpamdEnabled:=1;
       enable_dkim_verification:=0;

       if not TryStrToInt(SYS.get_INFO('SpamAssMilterEnabled'),SpamAssMilterEnabled) then SpamAssMilterEnabled:=0;
       if not TryStrToInt(SYS.GET_INFO('EnableSaBlackListUpdate'),EnableSaBlackListUpdate) then EnableSaBlackListUpdate:=0;
       if not TryStrToInt(SYS.GET_INFO('EnableSPF'),EnableSPF) then EnableSPF:=0;
       if not TryStrToInt(SYS.GET_INFO('enable_dkim_verification'),enable_dkim_verification) then enable_dkim_verification:=0;



       InsufficentRessources:=SYS.ISMemoryHiger1G();
        if not InsufficentRessources then begin
             if SpamAssMilterEnabled=1 then begin
                SYS.set_INFO('SpamAssMilterEnabled','0');
                SpamAssMilterEnabled:=0;
          end;
       end;

       SpamdEnabled:=IS_SPAMD_ENABLED();
       
       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;
end;
//##############################################################################
procedure Tspamass.free();
begin
    logs.Free;
end;
//##############################################################################
function Tspamass.IS_SPAMD_ENABLED:integer;
var  EnableAmavisDaemon:integer;
begin
result:=0;
EnableAmavisDaemon:=0;
if not SYS.ISMemoryHiger1G() then exit(0);
if not TryStrToInt(SYS.GET_INFO('EnableAmavisDaemon'),EnableAmavisDaemon) then EnableAmavisDaemon:=0;
if EnableAmavisDaemon=1 then exit(0);
if SpamAssMilterEnabled=1 then exit(1);
end;
//##############################################################################

FUNCTION Tspamass.MILTER_INITD_PATH():string;
begin
 if FileExists('/etc/init.d/spamass-milter') then exit('/etc/init.d/spamass-milter');
end;
//##############################################################################
FUNCTION Tspamass.MILTER_DAEMON_BIN_PATH():string;
begin
result:=SYS.LOCATE_GENERIC_BIN('spamass-milter');
end;
//##############################################################################
function  Tspamass.RAZOR_AGENT_CONF_PATH():string;
begin
result:=ExtractFilePath(SPAMASSASSIN_LOCAL_CF()) + '.razor/razor-agent.conf';
end;
//##############################################################################
function tspamass.RAZOR_ADMIN_PATH():string;
begin
if FileExists('/usr/bin/razor-admin') then exit('/usr/bin/razor-admin');
if FileExists('/opt/artica/bin/razor-admin') then exit('/opt/artica/bin/razor-admin');
end;
//##############################################################################
FUNCTION Tspamass.MILTER_SOCKET_PATH():string;
begin
if FIleExists('/var/spool/postfix/spamass/spamass.sock') then exit('/var/spool/postfix/spamass/spamass.sock');
if FileExists('/var/run/spamass/spamass.sock') then exit('/var/run/spamass/spamass.sock');
if FileExists('/var/run/sendmail/spamass.sock') then exit('/var/run/sendmail/spamass.sock');
exit('/var/spool/postfix/spamass/spamass.sock');
end;
//##############################################################################
function Tspamass.SA_UPDATE_PATH():string;
begin
    if FileExists('/usr/bin/sa-update') then exit('/usr/bin/sa-update');
    if FileExists('/opt/artica/bin/sa-update') then exit('/opt/artica/bin/sa-update');
end;
//##############################################################################
function Tspamass.SPAMASSASSIN_BIN_PATH():string;
begin
   if FileExists('/usr/sbin/spamd') then exit('/usr/sbin/spamd');
   if FileExists('/usr/bin/spamd') then exit('/usr/bin/spamd');
   if FIleExists('/usr/bin/perlbin/vendor/spamd') then exit('/usr/bin/perlbin/vendor/spamd');
   if FileExists('/opt/artica/bin/spamd') then exit('/opt/artica/bin/spamd');
end;
//##############################################################################

function Tspamass.PYZOR_BIN_PATH():string;
begin
     if FileExists('/usr/bin/pyzor') then exit('/usr/bin/pyzor');
end;
//##############################################################################
FUNCTION Tspamass.MILTER_PID():string;
begin
if FileExists('/var/run/spamass/spamass.pid') then exit(SYS.GET_PID_FROM_PATH('/var/run/spamass/spamass.pid'));
end;
//##############################################################################
FUNCTION Tspamass.MILTER_DEFAULT_PATH():string;
begin
if FileExists('/etc/default/spamass-milter') then exit('/etc/default/spamass-milter');
if FileExists('/etc/sysconfig/spamass-milter') then exit('/etc/sysconfig/spamass-milter');
end;
//##############################################################################


PROCEDURE Tspamass.MILTER_ETC_DEFAULT();
var
l:TstringList;
begin
l:=TstringList.Create;
if not FileExists(MILTER_DEFAULT_PATH()) then exit();
l.Add('# spamass-milt startup defaults');
l.Add('');
l.Add('# OPTIONS are passed directly to spamass-milter.');
l.Add('# man spamass-milter for details');
l.Add('');
l.Add('# Default, use the nobody user as the default user, ignore messages');
l.Add('# from localhost');
l.Add('OPTIONS="-P /var/run/spamass/spamass.pid -u postfix -i 127.0.0.1 -- --port 9031"');
l.Add('');
l.Add('# Reject emails with spamassassin scores > 15.');
l.Add('#OPTIONS="-r 15"');
l.Add('');
l.Add('# Do not modify Subject:, Content-Type: or body.');
l.Add('#OPTIONS="-m"');
l.Add('');
l.Add('######################################');
l.Add('# If /usr/sbin/postfix is executable, the following are set by');
l.Add('# default. You can override them by uncommenting and changing them');
l.Add('# here.');
l.Add('######################################');
l.Add('SOCKET="/var/spool/postfix/spamass/spamass.sock"');
l.Add('SOCKETOWNER="postfix:postfix"');
l.Add('SOCKETMODE="0660"');
l.Add('######################################');
logs.Debuglogs('spamass-milter:: MILTER_ETC_DEFAULT:: save '+MILTER_DEFAULT_PATH());
l.SaveToFile(MILTER_DEFAULT_PATH());
l.free;
end;
//##############################################################################
procedure Tspamass.MILTER_START();
var
   cmd:string;
   tn:string;
   b:string;
   count:integer;
   updatercd:string;
begin


   logs.Debuglogs('############## spamass-milter ##############');
   count:=0;

   if not FileExists(MILTER_INITD_PATH()) then begin
      logs.Debuglogs('Starting......: spamass-milter daemon is not installed');
      exit;
   end;
   
   updatercd:=SYS.LOCATE_GENERIC_BIN('update-rc.d');

   if SpamAssMilterEnabled=0 then begin
        logs.DebugLogs('Starting......: spamass-milter daemon is disabled by Artica');
         if FileExists(updatercd) then fpsystem(updatercd+' spamass-milter remove');
         MILTER_STOP();
        exit;
   end;
   

  if not FileExists(SYS.LOCATE_SU()) then begin
      logs.Syslogs('Starting......: spamass-milter daemon failed, unable to stat "su" tool');
      exit;
  end;

if SYS.isoverloadedTooMuch() then begin
   logs.DebugLogs('Starting......: spamass-milter System is overloaded');
   exit;
end;


   if SYS.PROCESS_EXIST(MILTER_PID()) then begin
        logs.DebugLogs('spamass-milter:: MILTER_START:: spamass-milter daemon is already running using PID ' + MILTER_PID() + '...');
        if not InsufficentRessources then begin
            logs.Syslogs('Starting......: spamass-milter Insuficient Ressources');
             MILTER_STOP();
        end;
        exit;
   end;
   
   if FileExists('/var/spool/postfix/spamass/spamass.sock') then logs.DeleteFile('/var/spool/postfix/spamass/spamass.sock');
   
   logs.DebugLogs('spamass-milter:: MILTER_START:: spamass-milter daemon is enabled');
   logs.DebugLogs('Starting......: spamass-milter change /etc/default/...');
   MILTER_ETC_DEFAULT();
   logs.DebugLogs('Starting......: spamass-milter change /etc/init.d/...');
   CHANGE_INITD_MILTER();
   
   logs.DebugLogs('Starting......: spamass-milter apply securities...');
   forcedirectories('/var/spool/postfix/spamass');
   forcedirectories('/var/run/spamass');
   logs.OutputCmd('/bin/chown -R postfix:postfix /var/run/spamass');
   logs.OutputCmd('/bin/chown -R postfix:postfix /var/spool/postfix/spamass');
   
   if SYS.IsUserExists('spamass-milter') then begin
      SYS.AddUserToGroup('postfix','nogroup','','');
      SYS.AddUserToGroup('spamass-milter','postfix','','');
      SYS.AddUserToGroup('spamass-milter','mail','','');
   end;

   tn:=TRUSTED_NETWORK();
   b:=BLOCK_MAIL();
   logs.DebugLogs('Starting......: spamass-milter daemon changing configuration done...');
   if not SYS.PROCESS_EXIST(MILTER_PID()) then begin
     logs.DebugLogs('Starting......: spamass-milter daemon');
     cmd:=SYS.LOCATE_SU() +' postfix -c "'+MILTER_DAEMON_BIN_PATH()+b+' -f -p /var/spool/postfix/spamass/spamass.sock -P /var/run/spamass/spamass.pid '+tn+' -- --port 9031" &';
     logs.Debuglogs(cmd);
     fpsystem(cmd);
     
    while not SYS.PROCESS_EXIST(MILTER_PID()) do begin
        sleep(100);
        inc(count);
        if count>60 then begin
           logs.Syslogs('Starting......: spamass-milter daemon timeout daemon is too heavy to start...');
           break;
        end;
    end;
     
     
   end;
   
   if not SYS.PROCESS_EXIST(MILTER_PID()) then begin
      logs.DebugLogs('Starting......: spamass-milter daemon failed to start');
      exit;
   end else begin
       logs.DebugLogs('Starting......: spamass-milter success to pid '+MILTER_PID() );
       logs.Syslogs('Success starting spamass-milter');
   end;
           
   
end;
//#############################################################################
function Tspamass.TRUSTED_NETWORK():string;
var
    RegExpr:TRegExpr;
    l:TStringList;
    i:integer;
    tn:string;
begin

if not FileExists(SPAMASSASSIN_LOCAL_CF()) then begin
   logs.Syslogs('Unable to stat spamassassin local.cf');
   exit;
end;

   tn:='';
   l:=TstringList.Create;
   l.LoadFromFile(SPAMASSASSIN_LOCAL_CF());
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^trusted_networks\s+(.+)';
   for i:=0 to l.Count-1 do begin
       if RegExpr.Exec(l.Strings[i]) then begin
           logs.Syslogs('Starting......: spamass-milter Adding trusted network ' + RegExpr.Match[1]);
           tn:=tn+'-i '+ RegExpr.Match[1]+' ';
       end;
   end;
   
   result:=tn;
   l.free;
   RegExpr.free;
end;
//#############################################################################
function Tspamass.BLOCK_MAIL():string;
var
    RegExpr:TRegExpr;
    l:TStringList;
    i:integer;

begin

if not FileExists(SPAMASSASSIN_LOCAL_CF()) then begin
   logs.Syslogs('Unable to stat spamassassin local.cf');
   exit;
end;

   l:=TstringList.Create;
   l.LoadFromFile(SPAMASSASSIN_LOCAL_CF());
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='milter_block_with_required_score:([0-9\.]+)';
   for i:=0 to l.Count-1 do begin
       if RegExpr.Exec(l.Strings[i]) then begin
           if RegExpr.Match[1]='0' then break;
           logs.Syslogs('Starting......: spamass-milter Block mails up to ' + RegExpr.Match[1]);
           result:=' -r '+ RegExpr.Match[1]+' ';
       end;
   end;


   l.free;
   RegExpr.free;
end;
//#############################################################################
function Tspamass.rewrite_header():string;
var
    RegExpr:TRegExpr;
    l:TStringList;
    i:integer;

begin

if not FileExists(SPAMASSASSIN_LOCAL_CF()) then begin
   logs.Debuglogs('Unable to stat spamassassin local.cf');
   exit;
end;

   l:=TstringList.Create;
   l.LoadFromFile(SPAMASSASSIN_LOCAL_CF());
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='rewrite_header Subject\s+(.+)';
   for i:=0 to l.Count-1 do begin
       if RegExpr.Exec(l.Strings[i]) then begin
          result:=RegExpr.Match[1];
       end;
   end;


   l.free;
   RegExpr.free;
end;
//#############################################################################

function Tspamass.IF_PATTERN_FOUND(pattern:string):boolean;
var
    RegExpr:TRegExpr;
    l:TStringList;
    i:integer;

begin
result:=false;
if not FileExists(SPAMASSASSIN_LOCAL_CF()) then begin
   logs.Debuglogs('Unable to stat spamassassin local.cf');
   exit;
end;

   l:=TstringList.Create;
   l.LoadFromFile(SPAMASSASSIN_LOCAL_CF());
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:=pattern;
   for i:=0 to l.Count-1 do begin
   
       if RegExpr.Exec(l.Strings[i]) then begin
          logs.Syslogs('Starting......: pattern "'+pattern+'" is detected in '+SPAMASSASSIN_LOCAL_CF());
          result:=true;
          break;
       end;
   end;
   l.free;
   RegExpr.free;
end;
//#############################################################################
procedure Tspamass.DSPAM_PATCH();
var l:TStringList;
    localcf:string;
begin
localcf:=SPAMASSASSIN_LOCAL_CF();
if not FileExists(localcf) then begin
      logs.DebugLogs('Starting......: patching DSPAM_PATCH() fatal error unbale to stat local.cf for dpsam+amavis');
      exit;
end;


if not IF_PATTERN_FOUND('header DSPAM_SPAM') then begin
   logs.DebugLogs('Starting......: patching '+SPAMASSASSIN_LOCAL_CF()+' for dpsam+amavis');
   l:=TstringList.Create;
   l.LoadFromFile(SPAMASSASSIN_LOCAL_CF());
   l.Add('header DSPAM_SPAM X-DSPAM-Result =~ /^Spam$/');
   l.Add('describe DSPAM_SPAM DSPAM claims it is spam');
   l.Add('score DSPAM_SPAM 0.5');

   l.Add('header DSPAM_HAM X-DSPAM-Result =~ /^Innocent$/');
   l.Add('describe DSPAM_HAM DSPAM claims it is ham');
   l.Add('score DSPAM_HAM -0.1');
   try
   l.SaveToFile(SPAMASSASSIN_LOCAL_CF());
   except
     logs.Syslogs('Starting......: Unable to patch !!! '+SPAMASSASSIN_LOCAL_CF()+' for dpsam+amavis');
     l.free;
   end;
end else begin
     logs.DebugLogs('Starting......: patching '+SPAMASSASSIN_LOCAL_CF()+' already done..');
end;
end;
//#############################################################################
procedure Tspamass.MILTER_STOP();
var
count:integer;
PID:string;
begin
  if not FileExists(MILTER_INITD_PATH()) then begin
     logs.DebugLogs('Stopping spamass-milter daemon: not installed');
     exit;
  end;
  

  count:=0;
  CHANGE_INITD_MILTER();

  if SYS.PROCESS_EXIST(MILTER_PID()) then begin
     logs.Output('Stopping spamass-milter daemon: ' + MILTER_PID() + ' PID');

     fpsystem('/bin/kill ' + MILTER_PID());
     while SYS.PROCESS_EXIST(MILTER_PID()) do begin
           Inc(count);
           sleep(300);
           if count>20 then begin
                  logs.Output('killing spamass-milter........: ' + MILTER_PID() + ' PID (timeout)');
                  fpsystem('/bin/kill -9 ' + MILTER_PID());
                  break;
           end;
     end;
     
     
     PID:=SYS.PidAllByProcessPath(MILTER_DAEMON_BIN_PATH());
     if length(PID)>0 then begin
        logs.Output('killing spamass-milter........: ' + PID + ' PID(s)');
        fpsystem('/bin/kill -9 ' + PID);
     end;
     
     
  end else begin
      logs.Output('Stopping spamass-milter daemon: Already stopped');
  end;

end;
//##############################################################################
function Tspamass.MILTER_VERSION():string;
var
    RegExpr:TRegExpr;
    FileDatas:TStringList;
    i:integer;
begin
if not FileExists(MILTER_DAEMON_BIN_PATH()) then exit;

result:=SYS.GET_CACHE_VERSION('APP_SPAMASSASSIN_MILTER');
if length(result)>0 then exit;

fpsystem(MILTER_DAEMON_BIN_PATH() +' -h >/opt/artica/logs/spamass-v 2>&1');
    RegExpr:=TRegExpr.Create;
    FileDatas:=TStringList.Create;
    FileDatas.LoadFromFile('/opt/artica/logs/spamass-v');
    RegExpr.Expression:='Version\s+([0-9\.]+)';
    for i:=0 to FileDatas.Count-1 do begin
        if RegExpr.Exec(FileDatas.Strings[i]) then begin
             result:=RegExpr.Match[1];
             break;
        end;
    end;

    RegExpr.free;
    FileDatas.Free;
    SYS.SET_CACHE_VERSION('APP_SPAMASSASSIN_MILTER',result);
end;
//#############################################################################
function Tspamass.ReadFileIntoString(path:string):string;
var
   List:TstringList;
begin

      if not FileExists(path) then begin
        exit;
      end;

      List:=Tstringlist.Create;
      List.LoadFromFile(path);
      result:=List.Text;
      List.Free;
end;
//##############################################################################
function Tspamass.COMMANDLINE_PARAMETERS(FoundWhatPattern:string):boolean;
var
   i:integer;
   s:string;
   RegExpr:TRegExpr;

begin
 result:=false;
 s:='';
 if ParamCount>1 then begin
     for i:=2 to ParamCount do begin
        s:=s  + ' ' +ParamStr(i);
     end;
 end;
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:=FoundWhatPattern;
   if RegExpr.Exec(s) then begin
      RegExpr.Free;
      result:=True;
   end;


end;
//##############################################################################
function Tspamass.SPAMASSASSIN_LOCAL_CF():string;
begin
if FileExists('/etc/spamassassin/local.cf') then exit('/etc/spamassassin/local.cf');
if FileExists('/etc/mail/spamassassin/local.cf') then exit('/etc/mail/spamassassin/local.cf');
if FileExists('/opt/artica/etc/spamassassin/local.cf') then exit('/opt/artica/etc/spamassassin/local.cf');

ForceDirectories('/etc/spamassassin');
fpsystem('/bin/touch /etc/spamassassin/local.cf');
exit('/etc/spamassassin/local.cf');

end;
//##############################################################################
procedure Tspamass.RAZOR_INIT();
var razor_path:string;
begin
    if not FileExists(RAZOR_ADMIN_PATH()) then begin
           logs.DebugLogs('Starting......: unable to stat razor');
           exit;
    end;
    
    logs.Debuglogs('RAZOR_INIT:: test -> ' + RAZOR_AGENT_CONF_PATH());
    razor_path:=ExtractFilePath(RAZOR_AGENT_CONF_PATH());
    if FIleExists(RAZOR_AGENT_CONF_PATH()) then begin
       RAZOR_SET_VALUE('razorhome',razor_path);
       exit;
    end;

    logs.OutputCmd(RAZOR_ADMIN_PATH() + ' -home=' + razor_path + ' -register >/dev/null 2>&1');
    logs.OutputCmd(RAZOR_ADMIN_PATH() + ' -home=' + razor_path + ' -create >/dev/null 2>&1');
    logs.OutputCmd(RAZOR_ADMIN_PATH() + ' -home=' + razor_path + ' -discover >/dev/null 2>&1');
end;
//##############################################################################
function Tspamass.RAZOR_GET_VALUE(key:string):string;
var
   l:Tstringlist;
   RegExpr:TRegExpr;

   i:integer;
begin
     if not FileExists(RAZOR_AGENT_CONF_PATH()) then exit;
     RegExpr:=TRegExpr.Create;
     l:=Tstringlist.Create;
     l.LoadFromFile(RAZOR_AGENT_CONF_PATH());
     RegExpr.Expression:='^'+key+'[\s=]+(.+)';
     for i:=0 to l.Count-1 do begin
          if RegExpr.Exec(l.Strings[i]) then begin
            result:=trim(RegExpr.Match[1]);
            break;
          end;
     end;


     l.free;
     RegExpr.free;
end;
//##############################################################################


procedure Tspamass.RAZOR_SET_VALUE(key:string;value:string);
var
   l:Tstringlist;
   RegExpr:TRegExpr;
   f:boolean;
   i:integer;
begin
     f:=false;
     if not FileExists(RAZOR_AGENT_CONF_PATH()) then exit;
     RegExpr:=TRegExpr.Create;
     l:=Tstringlist.Create;
     l.LoadFromFile(RAZOR_AGENT_CONF_PATH());
     RegExpr.Expression:='^'+key;
     for i:=0 to l.Count-1 do begin
          if RegExpr.Exec(l.Strings[i]) then begin
            f:=True;
            l.Strings[i]:=key + chr(9) + '= ' + value;
            break;
          end;
     end;
     
     if not f then l.Add(key + chr(9) + '= ' + value);
     l.SaveToFile(RAZOR_AGENT_CONF_PATH());
     l.free;
     RegExpr.free;
end;
//##############################################################################
procedure Tspamass.SPAMASSASSIN_RELOAD();
 var
pid:string;
begin
pid:=SPAMASSASSIN_PID();
if NOT SYS.PROCESS_EXIST(pid) then begin
        logs.DebugLogs('Starting......: spamassassin daemon is Stopped, start it..');
        SPAMASSASSIN_START();
        exit;
     end;

fpsystem(SYS.LOCATE_PHP5_BIN()+' ' + artica_path+'/exec.spamassassin.php');
DEFAULT_SETTINGS();
RAZOR_INIT();
     
logs.Syslogs('Reloading spamassassin PID ' + pid);
logs.OutputCmd('/bin/kill -HUP ' +pid);
end;
//##############################################################################
procedure Tspamass.SPAMASSASSIN_START();
 var
    count      :integer;
    cmdline    :string;
    helper_home:string;

begin
     if not FileExists(SPAMASSASSIN_BIN_PATH()) then begin
        logs.DebugLogs('Starting......: spamassassin is not installed');
        exit;
     end;




     if SYS.PROCESS_EXIST(SPAMASSASSIN_PID()) then begin
        if not InsufficentRessources then begin
           logs.DebugLogs('Starting......: spamassassin insufficient resources');
           SPAMASSASSIN_STOP();
           exit;
        end;

        if SpamdEnabled=0 then begin
            logs.DebugLogs('Starting......: spamassassin is not used by any program...');
            SPAMASSASSIN_STOP();
           exit;
        end;

        logs.DebugLogs('Starting......: spamassassin daemon is already running using PID ' + SPAMASSASSIN_PID() + '...');
        exit;
     end;

     SPAMASSASSIN_ETC_DEFAULT();
     DEFAULT_SETTINGS();
     RAZOR_INIT();


 if SpamdEnabled=0 then begin
      logs.DebugLogs('Starting......: spamassassin is not used by any program...');
      exit;
 end;

     if not InsufficentRessources then begin
         logs.DebugLogs('Starting......: spamassassin insufficient resources ! this computer have not memory higher than 1G, disable Spamassassin');
         SPAMASSASSIN_STOP();
         exit;
     end;

if SYS.isoverloadedTooMuch() then begin
   logs.DebugLogs('Starting......: spamassassin System is overloaded');
   exit;
end;



     helper_home:=ExtractFilePath(SPAMASSASSIN_LOCAL_CF())+'helper-home-dir';

        count:=0;
        logs.DebugLogs('Starting......: spamassassin computer memory higher than 1G OK');
        logs.DebugLogs('Starting......: spamassassin daemon....');


        
        
     ForceDirectories('/var/spool/postfix/.spamassassin/user_prefs');
     ForceDirectories('/var/lib/spamassassin/tmp');
     ForceDirectories(helper_home);
     logs.OutputCmd('/bin/chmod -R 755 /var/spool/postfix/.spamassassin');
     logs.OutputCmd('/bin/chown -R postfix:postfix /var/spool/postfix/.spamassassin');
     logs.OutputCmd('/bin/chown -R postfix:postfix /var/lib/spamassassin');
     logs.OutputCmd('/bin/chown -R postfix:postfix /var/lib/spamassassin');
     fpsystem(SYS.LOCATE_PHP5_BIN()+' ' + artica_path+'/exec.spamassassin.php >/dev/null 2>&1');


     cmdline:=SPAMASSASSIN_BIN_PATH()+' --username=postfix --groupname=postfix --max-children 10 -l ';
     cmdline:=cmdline +'--create-prefs --nouser-config ';
     cmdline:=cmdline +'--siteconfigpath='+ExtractFilePath(SPAMASSASSIN_LOCAL_CF()) + ' ';
     cmdline:=cmdline +'--pidfile /var/run/spamd.pid ';
     cmdline:=cmdline +'-H /var/lib/spamassassin/tmp ';
     cmdline:=cmdline +'--listen-ip=127.0.0.1 --port=9031 --daemonize';
     logs.OutputCmd(cmdline);

        while not SYS.PROCESS_EXIST(SPAMASSASSIN_PID()) do begin
              sleep(50);
              inc(count);
              write('.');
              if count>100 then begin
                 writeln('');
                 logs.DebugLogs('Starting......: spamassassin daemon. (timeout!!!)');
                 logs.DebugLogs('Starting......: '+cmdline);
                 break;
              end;
        end;

     writeln('');
     if not SYS.PROCESS_EXIST(SPAMASSASSIN_PID()) then begin

        logs.DebugLogs('Starting......: spamassassin daemon. (failed!!!)');
        logs.DebugLogs(cmdline);
        exit;
     end;
        
        
        logs.DebugLogs('Starting......: spamassassin daemon with new PID ' + SPAMASSASSIN_PID() + ' and listen 9031 port...');

end;
//##############################################################################
function Tspamass.SPAMASSASSIN_INITD():string;
begin
if FileExists('/etc/init.d/spamassassin') then exit('/etc/init.d/spamassassin');
end;
//##############################################################################
procedure Tspamass.SPAMASSASSIN_ETC_DEFAULT();
var
l:tstringlist;
begin
l:=TstringList.Create;
logs.Debuglogs('Writing /etc/default/spamassassin');

if FileExists('/etc/default/spamassassin') then begin
   forcedirectories('/etc/default');
   l.Add('# /etc/default/spamassassin');
   l.Add('# Duncan Findlay');
   l.Add('');
   l.Add('# WARNING: please read README.spamd before using.');
   l.Add('# There may be security risks.');
   l.Add('');
   l.Add('# Change to one to enable spamd');
   l.Add('ENABLED=1');
   l.Add('');
   l.Add('# Options');
   l.Add('# See man spamd for possible options. The -d option is automatically added.');
   l.Add('');
   l.Add('# SpamAssassin uses a preforking model, so be careful! You need to');
   l.Add('# make sure --max-children is not set to anything higher than 5,');
   l.Add('# unless you know what you''re doing.');
   l.Add('');
   l.Add('OPTIONS="--create-prefs --max-children 5 --helper-home-dir --listen-ip=127.0.0.1 --port=9031 --username=postfix --groupname=postfix"');
   l.Add('');
   l.Add('# Pid file');
   l.Add('# Where should spamd write its PID to file? If you use the -u or');
   l.Add('# --username option above, this needs to be writable by that user.');
   l.Add('# Otherwise, the init script will not be able to shut spamd down.');
   l.Add('PIDFILE="/var/run/spamd.pid"');
   l.Add('');
   l.Add('# Set nice level of spamd');
   l.Add('#NICE="--nicelevel 15"');
   l.Add('');
   l.Add('# Cronjob');
   l.Add('# Set to anything but 0 to enable the cron job to automatically update');
   l.Add('# spamassassin''s rules on a nightly basis');
   l.Add('CRON=1');
   l.SaveToFile('/etc/default/spamassassin');
end;
if FileExists('/etc/sysconfig/spamassassin') then begin
    l.Add('# Options to spamd');
    l.Add('# SPAMDOPTIONS="-d -c -m5 -H --listen-ip=127.0.0.1 --port=9031"');
    l.SaveToFile('/etc/sysconfig/spamassassin');
end;
l.free;
end;
//##############################################################################
procedure Tspamass.SPAMASSASSIN_STOP();
 var
    pid:string;
    count:integer;
begin
count:=0;
  if not FileExists(SPAMASSASSIN_BIN_PATH()) then exit;

  pid:=SPAMASSASSIN_PID();
  if SYS.PROCESS_EXIST(pid) then begin
   logs.Output('Stopping spamassassin........: ' + pid + ' PID');
   fpsystem('/bin/kill ' + pid + ' >/dev/null 2>&1');
   sleep(100);
  while SYS.PROCESS_EXIST(SPAMASSASSIN_PID()) do begin
        sleep(1000);
        inc(count);

        if count>50 then begin
           logs.Output('Stopping spamassassin........: ' + SPAMASSASSIN_PID() + ' PID (timeout) kill it');
           fpsystem('/bin/kill -9 ' + SPAMASSASSIN_PID() + ' >/dev/null 2>&1');
           break;
        end;
  end;
   exit;
  end;

  if not SYS.PROCESS_EXIST(SPAMASSASSIN_PID()) then begin
     logs.Output('Stopping spamassassin........: Already stopped');
  end;

  //
end;
//#############################################################################
function Tspamass.SPAMASSASSIN_PID():string;
begin
 if FIleExists('/var/run/spamd.pid') then exit(SYS.GET_PID_FROM_PATH('/var/run/spamd.pid'));
 if FIleExists('/var/run/spamassassin/artica-spamd.pid') then exit(SYS.GET_PID_FROM_PATH('/var/run/spamassassin/artica-spamd.pid'));
end;
//##############################################################################
FUNCTION Tspamass.SPAMASSASSIN_STATUS():string;
var
   pidpath:string;
begin
if not FileExists(SPAMASSASSIN_BIN_PATH()) then exit;
SYS.MONIT_DELETE('APP_SPAMASSASSIN');
SYS.MONIT_DELETE('SPAMASS_MILTER');
pidpath:=logs.FILE_TEMP();
fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.status.php --spamassassin >'+pidpath +' 2>&1');
result:=logs.ReadFromFile(pidpath);
logs.DeleteFile(pidpath);
end;
//#########################################################################################
procedure Tspamass.DEFAULT_SETTINGS();
var
   l:TstringList;
   sapmcfDir:string;
   auto_whitelist_path:string;
   auto_whitelist_file_mode:string;
begin

if not FileExists(SPAMASSASSIN_LOCAL_CF()) then begin
   logs.Debuglogs('Starting......: Unable to stat spamassassin local.cf');
   exit;
end;
sapmcfDir:=ExtractFilePath(SPAMASSASSIN_LOCAL_CF());

SPAMASSASSIN_ADD_PLUGIN('Rule2XSBody');

if enable_dkim_verification=1 then begin
    SPAMASSASSIN_ADD_PLUGIN('DKIM');
    logs.Debuglogs('Starting......: spamassassin DKIM Engine is enabled');
    fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.spamassassin.php --dkim');
end else begin
     logs.Debuglogs('Starting......: spamassassin DKIM Engine is disbaled');
     SPAMASSASSIN_REMOVE_PLUGIN('DKIM');
end;

SPAMASSASSIN_ADD_PLUGIN('AWL');
SPAMASSASSIN_init_pre();
if EnableSaBlackListUpdate=1 then SPAMASSASSIN_ADD_INCLUDE_FILE(sapmcfDir+'sa-blacklist.work') else SPAMASSASSIN_REMOVE_INCLUDE_FILE(sapmcfDir+'sa-blacklist.work');


auto_whitelist_path:=GET_VALUE('auto_whitelist_path');
auto_whitelist_file_mode:=GET_VALUE('auto_whitelist_file_mode');

if length(auto_whitelist_path)>0 then begin
        logs.Debuglogs('Starting......: spamassassin auto-whitelist path '+auto_whitelist_path+' chmod '+ auto_whitelist_file_mode);
        ForceDirectories(ExtractFilePath(auto_whitelist_path));
        if not FileExists(auto_whitelist_path) then fpsystem('/bin/touch  '+auto_whitelist_path +' >/dev/null 2>&1');
        fpsystem('/bin/chmod '+auto_whitelist_file_mode+' '+auto_whitelist_path);
end;





l:=TstringList.Create;
l.LoadFromFile(SPAMASSASSIN_LOCAL_CF());
if not IF_PATTERN_FOUND('^rewrite_header Subject') then begin
      logs.Debuglogs('Starting......: spamassassin Set default rewrite_header parameter');
      l.Add('rewrite_header Subject ***** SPAM *****');
end;

if not IF_PATTERN_FOUND('^required_score') then begin
   l.Add('required_score 5.0');
   logs.Debuglogs('Starting......: spamassassin Set default required_score parameter');
end;

if not IF_PATTERN_FOUND('^report_safe') then begin
   l.Add('report_safe 0');
   logs.Debuglogs('Starting......: spamassassin Set default report_safe parameter');
end;

if not IF_PATTERN_FOUND('^bayes_ignore_header') then begin
   l.Add('bayes_ignore_header X-Bogosity');
   l.Add('bayes_ignore_header X-Spam-Flag');
   l.Add('bayes_ignore_header X-Spam-Status');
   logs.Debuglogs('Starting......: Set default bayes_ignore_header');
end;

if not IF_PATTERN_FOUND('^use_bayes') then l.Add('use_bayes 1');
if not IF_PATTERN_FOUND('^bayes_auto_learn') then l.Add('bayes_auto_learn 1');



try
logs.WriteToFile(l.Text,SPAMASSASSIN_LOCAL_CF());
except
logs.Debuglogs('Starting......: spamassassin Unable to save configuration file '+SPAMASSASSIN_LOCAL_CF());
end;
l.free;
end;
//#########################################################################################
procedure Tspamass.SPAMASSASSIN_ADD_INCLUDE_FILE(filepath:string);
var l:TstringList;
    RegExpr:TRegExpr;
    i:integer;
    F:boolean;
begin
if not FileExists(SPAMASSASSIN_LOCAL_CF()) then begin
   logs.Debuglogs('SPAMASSASSIN_ADD_INCLUDE_FILE():: Unable to stat spamassassin local.cf');
   exit;
end;

if not FileExists(filepath) then begin
      logs.Debuglogs('Starting......: spamassassin Unable to stat file '+filepath);
      exit;
end;

   f:=false;
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^include\s+(.+)';
   l:=TstringList.Create;
   l.LoadFromFile(SPAMASSASSIN_LOCAL_CF());
   for i:=0 to l.Count-1 do begin
       if RegExpr.Exec(l.Strings[i]) then begin
          if trim(RegExpr.Match[1])=filepath then begin
             F:=true;
             break;
          end;
       end;
   end;
   
   if not F then begin
      try
         l.Add('include '+filepath);
         l.SaveToFile(SPAMASSASSIN_LOCAL_CF());
      except
         logs.Syslogs('SPAMASSASSIN_ADD_INCLUDE_FILE():: Unable to save configuration file '+SPAMASSASSIN_LOCAL_CF());
         exit;
      end;
   end else begin
       logs.Debuglogs('SPAMASSASSIN_ADD_INCLUDE_FILE():: '+ filepath +' is already included');
   end;
l.free;
   
end;
//#########################################################################################
function Tspamass.GET_VALUE(key:string):string;
var
   l:TstringList;
   i:integer;
   RegExpr:TRegExpr;
begin

   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^'+key+'\s+(.+)';
   l:=TstringList.Create;
   l.LoadFromFile(SPAMASSASSIN_LOCAL_CF());
   for i:=0 to l.Count-1 do begin
       if RegExpr.Exec(l.Strings[i]) then begin
          result:=trim(RegExpr.Match[1]);
          break;
       end;
   end;

   l.free;
   RegExpr.free;

end;

procedure Tspamass.SPAMASSASSIN_REMOVE_INCLUDE_FILE(filepath:string);
var l:TstringList;
    RegExpr:TRegExpr;
    i:integer;
    F:boolean;
    orgfilepath:string;
begin
if not FileExists(SPAMASSASSIN_LOCAL_CF()) then begin
   logs.Debuglogs('SPAMASSASSIN_REMOVE_INCLUDE_FILE():: Unable to stat spamassassin local.cf');
   exit;
end;
orgfilepath:=filepath;
RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^include\s+(.+)';
   l:=TstringList.Create;
   l.LoadFromFile(SPAMASSASSIN_LOCAL_CF());
   for i:=0 to l.Count-1 do begin
       if RegExpr.Exec(l.Strings[i]) then begin
          if trim(RegExpr.Match[1])=filepath then begin
             l.Delete(i);
             F:=true;
             break;
          end;
       end;
   end;

   if F then begin
        logs.Debuglogs('Starting......: Success remove '+orgfilepath);
        logs.WriteToFile(l.Text,SPAMASSASSIN_LOCAL_CF());
   end else begin
        logs.Debuglogs('Starting......: Remove '+orgfilepath +' Already removed');
   end;


   l.free;
   RegExpr.free;

end;
//#########################################################################################
procedure Tspamass.SPAMASSASSIN_init_pre();
var filename:string;
    l:Tstringlist;
begin
 filename:='/etc/spamassassin/init.pre';
 l:=Tstringlist.Create;
 logs.Debuglogs('Starting......: spamassassin URIDNSBL enabled');
 l.Add('loadplugin Mail::SpamAssassin::Plugin::Hashcash');
 if EnableSPF=1 then begin
    logs.Debuglogs('Starting......: spamassassin SPF enabled');
    fpsystem(SYS.LOCATE_PHP5_BIN()+' ' + artica_path+'/exec.spamassassin.php --spf');
 end;
  logs.WriteToFile(l.Text,filename);
  logs.Debuglogs('Starting......: spamassassin init.pre success');
  fpsystem(SYS.LOCATE_PHP5_BIN()+' ' + artica_path+'/exec.spamassassin.php --dnsbl');
 l.free;
end;
//#########################################################################################
procedure Tspamass.SPAMASSASSIN_ADD_PLUGIN(plugin:string);
var
   l:Tstringlist;
   RegExpr:TRegExpr;
   found:boolean;
   filename:string;
   i:integer;
begin
    filename:='/etc/spamassassin/v310.pre';
    if not FileExists(filename) then begin
       ForceDirectories(ExtractFilePath(filename));
       fpsystem('/bin/touch '+filename);
    end;


    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='^loadplugin Mail.+?'+plugin;
    l:=TstringList.Create;
    l.LoadFromFile(filename);
    found:=false;
    for i:=0 to l.Count-1 do begin
         if RegExpr.Exec(l.Strings[i]) then begin
            found:=true;
            break;
         end;
    end;

    if not found then begin
        logs.DebugLogs('Starting......: spamassassin adding new plugin ' + plugin);
        l.Add('loadplugin Mail::SpamAssassin::Plugin::'+plugin);
        logs.WriteToFile(l.Text,filename);
    end;

    l.free;
    RegExpr.free;

end;
//#########################################################################################
procedure   Tspamass.SPAMASSASSIN_REMOVE_PLUGIN(plugin:string);
var
   l:Tstringlist;
   RegExpr:TRegExpr;
   found:boolean;
   filename:string;
   i:integer;
begin
 filename:='/etc/spamassassin/v310.pre';
    if not FileExists(filename) then begin
       ForceDirectories(ExtractFilePath(filename));
       fpsystem('/bin/touch '+filename);
    end;


    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='^loadplugin Mail.+?'+plugin;
    l:=TstringList.Create;
    l.LoadFromFile(filename);
    found:=false;
    for i:=0 to l.Count-1 do begin
         if RegExpr.Exec(l.Strings[i]) then begin
            l.Delete(i);
            found:=true;
            break;
         end;
    end;

    if found then logs.WriteToFile(l.Text,filename);
    l.free;
    RegExpr.free;
end;

//#########################################################################################
function Tspamass.SPAMASSASSIN_VERSION():string;
var
    RegExpr:TRegExpr;
    FileDatas:TStringList;
    i:integer;
begin
if not FileExists(SPAMASSASSIN_BIN_PATH()) then exit;

result:=SYS.GET_CACHE_VERSION('APP_SPAMASSASSIN');
if length(result)>0 then exit;

fpsystem(SPAMASSASSIN_BIN_PATH()+' -V >/opt/artica/logs/spamd.tmp');
    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='Server version\s+([0-9\.]+)';
    FileDatas:=TStringList.Create;
    FileDatas.LoadFromFile('/opt/artica/logs/spamd.tmp');
    for i:=0 to FileDatas.Count-1 do begin
        if RegExpr.Exec(FileDatas.Strings[i]) then begin
             result:=RegExpr.Match[1];
             break;
        end;
    end;
             RegExpr.free;
             FileDatas.Free;
             SYS.SET_CACHE_VERSION('APP_SPAMASSASSIN',result);
end;
//#############################################################################
function Tspamass.SPAMASSASSIN_PATTERN_VERSION():string;
var
    RegExpr:TRegExpr;
    FileDatas:TStringList;
    i:integer;
    Z:Tsystem;
    path:string;
begin
if not FileExists(SPAMASSASSIN_BIN_PATH()) then exit;
  Z:=TSystem.Create;
  FileDatas:=TStringList.Create;
  FileDatas.AddStrings(z.RecusiveListFiles('/opt/artica/spamassassin'));
    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='updates_spamassassin_org\.cf';


    for i:=0 to FileDatas.Count-1 do begin
        if RegExpr.Exec(FileDatas.Strings[i]) then begin
             path:=FileDatas.Strings[i];
             break;
        end;
    end;

    RegExpr.Expression:='# UPDATE version ([0-9]+)';
   if FileExists(path) then begin
        FileDatas.LoadFromFile(path);
        for i:=0 to FileDatas.Count-1 do begin
        if RegExpr.Exec(FileDatas.Strings[i]) then begin
             result:=RegExpr.Match[1];
             break;
        end;
        end;

   end;


RegExpr.free;
FileDatas.Free;

end;
//#############################################################################
procedure Tspamass.CHANGE_INITD_MILTER();
var
l:TstringList;
updatercd:string;
begin
if not FileExists(MILTER_INITD_PATH()) then exit;
 updatercd:=SYS.LOCATE_GENERIC_BIN('update-rc.d');
   if SpamAssMilterEnabled=0 then begin
         if FileExists('/etc/init.d/spamass-milter') then begin
            if FileExists(updatercd) then fpsystem(updatercd+' spamass-milter remove >/dev/null 2>&1');
         end;
         exit;
   end;


if FileExists(updatercd) then fpsystem(updatercd+' spamass-milter remove');

l:=TstringList.Create;
l.Add('#!/bin/sh');

    l.Add('### BEGIN INIT INFO');
    l.Add('# Provides:          spamd-milter');
    l.Add('# Required-Start:    $local_fs $remote_fs $syslog $named $network $time');
    l.Add('# Required-Stop:     $local_fs $remote_fs $syslog $named $network');
    l.Add('# Should-Start:');
    l.Add('# Should-Stop:');
    l.Add('# Default-Start:     2 3 4 5');
    l.Add('# Default-Stop:      0 1 6');
    l.Add('# Short-Description: Start spamassassin milter');
    l.Add('# chkconfig: 2345 11 89');
    l.Add('# description: Spamassassin milter');
    l.Add('### END INIT INFO');

l.Add('#Begin /etc/init.d/artica-postfix');
l.Add('case "$1" in');
l.Add(' start)');
l.Add('    /usr/share/artica-postfix/bin/artica-install start spamd $3');
l.Add('    ;;');
l.Add('');
l.Add('  stop)');
l.Add('    /usr/share/artica-postfix/bin/artica-install stop spamd $3');
l.Add('    ;;');
l.Add('');
l.Add(' restart)');
l.Add('     /usr/share/artica-postfix/bin/artica-install stop spamd $3');
l.Add('     sleep 3');
l.Add('     /usr/share/artica-postfix/bin/artica-install start spamd $3');
l.Add('    ;;');
l.Add('');
l.Add('  *)');
l.Add('    echo "Usage: $0 {start|stop|restart} (debug or --verbose for more infos)"');
l.Add('    exit 1');
l.Add('    ;;');
l.Add('esac');
l.Add('exit 0');
l.SaveToFile(MILTER_INITD_PATH());
CHANGE_INITD_SPAMASS();
 if FileExists(updatercd) then fpsystem(updatercd+' spamass-milter defaults >/dev/null 2>&1');
end;
//#############################################################################
procedure Tspamass.CHANGE_INITD_SPAMASS();
var
l:TstringList;
updatercd:string;
begin
if not FileExists(MILTER_INITD_PATH()) then exit;
 updatercd:=SYS.LOCATE_GENERIC_BIN('update-rc.d');
   if SpamdEnabled=0 then begin
         if FileExists('/etc/init.d/spamassassin') then begin
            if FileExists(updatercd) then fpsystem(updatercd+' spamassassin remove >/dev/null 2>&1');
         end;
         exit;
   end;


if FileExists(updatercd) then fpsystem(updatercd+' spamass-milter remove');

l:=TstringList.Create;
l.Add('#!/bin/sh');
l.Add('### BEGIN INIT INFO');
l.Add('# Provides:          spamd');
l.Add('# Required-Start:    $local_fs $remote_fs $syslog $named $network $time');
l.Add('# Required-Stop:     $local_fs $remote_fs $syslog $named $network');
l.Add('# Should-Start:');
l.Add('# Should-Stop:');
l.Add('# Default-Start:     2 3 4 5');
    l.Add('# Default-Stop:      0 1 6');
    l.Add('# Short-Description: Start spamassassin');
    l.Add('# chkconfig: 2345 11 89');
    l.Add('# description: Spamassassin');
    l.Add('### END INIT INFO');

l.Add('#Begin /etc/init.d/artica-postfix');
l.Add('case "$1" in');
l.Add(' start)');
l.Add('    /usr/share/artica-postfix/bin/artica-install start spamd $3');
l.Add('    ;;');
l.Add('');
l.Add('  stop)');
l.Add('    /usr/share/artica-postfix/bin/artica-install stop spamd $3');
l.Add('    ;;');
l.Add('');
l.Add(' restart)');
l.Add('     /usr/share/artica-postfix/bin/artica-install stop spamd $3');
l.Add('     sleep 3');
l.Add('     /usr/share/artica-postfix/bin/artica-install start spamd $3');
l.Add('    ;;');
l.Add('');
l.Add('  *)');
l.Add('    echo "Usage: $0 {start|stop|restart} (debug or --verbose for more infos)"');
l.Add('    exit 1');
l.Add('    ;;');
l.Add('esac');
l.Add('exit 0');
if FileExists(SPAMASSASSIN_INITD()) then l.SaveToFile(SPAMASSASSIN_INITD());
if FileExists(updatercd) then fpsystem(updatercd+' spamassassin defaults >/dev/null 2>&1');
end;
//#############################################################################

end.
