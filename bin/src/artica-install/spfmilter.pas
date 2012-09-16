unit spfmilter;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,IniFiles, Process,logs,unix,RegExpr in 'RegExpr.pas',zsystem;

type LDAP=record
      admin:string;
      password:string;
      suffix:string;
      servername:string;
      Port:string;
  end;

  type
  tspf=class


private
     LOGS:Tlogs;
     GLOBAL_INI:TiniFIle;
     SYS:TSystem;
     artica_path:string;
     function get_INFOS(key:string):string;


public
    procedure   Free;
    constructor Create;
    procedure   SPFMILTER_START();
    procedure   ETC_DEFAULT();
    function    SPFMILTER_INITD():string;
    function    SPFMILTER_PID():string;
    procedure   SPF_MILTER_STOP();
    function    SPFMILTER_SOCK():string;
    function    SPFMILTER_STATUS():string;
    procedure   CHANGE_INIT_TO_POSTFIX();
    function    BIN_PATH():string;
END;

implementation

constructor tspf.Create;
begin
       forcedirectories('/etc/artica-postfix');
       LOGS:=tlogs.Create();
       SYS:=Tsystem.Create;


       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;
end;
//##############################################################################
procedure tspf.free();
begin
    logs.Free;
    SYS.Free;
end;
//##############################################################################
function tspf.SPFMILTER_INITD():string;
begin
   if FileExists('/etc/init.d/spfmilter') then exit('/etc/init.d/spfmilter');
end;
//##############################################################################
function tspf.SPFMILTER_SOCK():string;
begin
    if FileExists('/var/run/spfmilter/spfmilter.sock') then exit('/var/run/spfmilter/spfmilter.sock');
end;


function tspf.SPFMILTER_PID():string;
var
   pid:string;
begin
if FileExists('/var/run/spfmilter/spfmilter.pid') then pid:=SYS.GET_PID_FROM_PATH('/var/run/spfmilter/spfmilter.pid');
if not SYS.PROCESS_EXIST(pid) then begin
   pid:=SYS.PIDOF(BIN_PATH());
end;

result:=pid;


end;
//##############################################################################
function tspf.BIN_PATH():string;
begin
 if FileExists('/usr/sbin/spfmilter') then exit('/usr/sbin/spfmilter');
end;
//##############################################################################

procedure tspf.ETC_DEFAULT();
var
l:TstringList;
begin

if not FileExists('/etc/default/spfmilter') then exit;
l:=TstringList.Create;

l.Add('# Defaults for spfmilter');
l.Add('');
l.Add('# Some possibly useful options:');
l.Add('# --trustedforwarders (use the trusted-forwarder.org whitelist)');
l.Add('# --localpolicy "local SPF policy" (add a local SPF policy to all checks)');
l.Add('# remove --markonly to reject SPF-fail emails in the SMTP conversation');
l.Add('#   (instead of merely tagging their headers)');
l.Add('DAEMON_OPTS="--markonly"');
l.Add('# Uncomment this to disable the warning about {auth_type} missing from');
l.Add('# Milter.macros.envfrom (see README.Debian.gz for more information)');
l.Add('NO_MACROS_CHECK=1');
l.Add('# Use this to listen on an alternate socket');
l.Add('#SOCKET="inet:54321" # listen to the whole world on port 54321');
l.Add('#SOCKET="inet:12345@localhost" # listen just on loopback on port 12345');
l.Add('#SOCKET="inet:12345@192.0.2.1" # listen on 192.0.2.1 on port 12345');
l.SaveToFile('/etc/default/spfmilter');
l.free;
end;
//##############################################################################
procedure tspf.CHANGE_INIT_TO_POSTFIX();
var
    RegExpr:TRegExpr;
    FileDatas:TStringList;
    i:integer;
begin
 if not FileExists(SPFMILTER_INITD()) then exit;
 FileDatas:=TstringList.Create;
 FileDatas.LoadFromFile(SPFMILTER_INITD());
 RegExpr:=TRegExpr.Create;
 RegExpr.Expression:='^USER=.+';
 for i:=0 to FileDatas.Count-1 do begin
     if RegExpr.Exec(FileDatas.Strings[i]) then begin
         FileDatas.Strings[i]:='USER=postfix';
         FileDatas.SaveToFile(SPFMILTER_INITD());
         break;
     end;
 
 end;
         FileDatas.Free;
         RegExpr.Free;

end;
//##############################################################################


function tspf.SPFMILTER_STATUS:string;
var
ini:TstringList;
begin
   ini:=TstringList.Create;
   ini.Add('[SPFMILTER]');
   if FileExists(SPFMILTER_INITD()) then  begin
      if SYS.PROCESS_EXIST(SPFMILTER_PID()) then ini.Add('running=1') else  ini.Add('running=0');
      ini.Add('application_installed=1');
      ini.Add('master_pid='+ SPFMILTER_PID());
      ini.Add('master_memory=' + IntToStr(SYS.PROCESS_MEMORY(SPFMILTER_PID())));
      ini.Add('master_version=unknown');
      ini.Add('status='+SYS.PROCESS_STATUS(SPFMILTER_PID()));
      ini.Add('service_name=APP_SPFMILTER');
      ini.Add('service_cmd=spfmilter');
   end;

   result:=ini.Text;
   ini.free;

end;
//##############################################################################
procedure tspf.SPFMILTER_START();
begin
    if not FileExists(SPFMILTER_INITD()) then exit;
    if SYS.PROCESS_EXIST(SPFMILTER_PID()) then exit;
    if get_INFOS('spfmilterEnabled')<>'1' then begin
        logs.Debuglogs('SPF_MILTER_START:: spfmilter is disabled');
        exit;
    end;
    

    logs.DebugLogs('Starting......: spfmilter daemon');
    ETC_DEFAULT();
    CHANGE_INIT_TO_POSTFIX();
    SYS.FILE_CHOWN('postfix','postfix','/var/run/spfmilter');
    
    
    logs.OutputCmd(SPFMILTER_INITD() + ' start');
    
    
    if not SYS.PROCESS_EXIST(SPFMILTER_PID()) then begin
        logs.Debuglogs('Starting......: spfmilter Failed to start spfmilter');
        exit;
    end;
end;
//##############################################################################
procedure tspf.SPF_MILTER_STOP();
begin
    if not FileExists(SPFMILTER_INITD()) then exit;
    if not SYS.PROCESS_EXIST(SPFMILTER_PID()) then begin
       writeln('Stopping spfmilter daemon.....: Already stopped');
       exit;
    end;
    writeln('Stopping spfmilter...........: ' + SPFMILTER_PID() + ' PID');
    fpsystem(SPFMILTER_INITD() + ' stop >/dev/null 2>&1');


    if SYS.PROCESS_EXIST(SPFMILTER_PID()) then begin
        writeln('Stopping spfmilter daemon ' + SPFMILTER_PID() + ' PID (failed to stop)');
        exit;
    end;
end;
//##############################################################################
function tspf.get_INFOS(key:string):string;
var value:string;
begin
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
value:=GLOBAL_INI.ReadString('INFOS',key,'');
result:=value;
GLOBAL_INI.Free;
end;
//#############################################################################

end.
