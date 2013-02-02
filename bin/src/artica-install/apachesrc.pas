unit apachesrc;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,Process,logs,unix,RegExpr in 'RegExpr.pas',zsystem,IniFiles;



  type
  tapachesrc=class


private
     LOGS:Tlogs;
     SYS:TSystem;
     artica_path:string;
     EnableFreeWeb:integer;
     LOCATE_APACHE_CONF_PATH_MEM:string;
     APACHE_SRC_ACCOUNT_MEM:string;
     binpath_memory:string;
     binpath:string;
     NOREPAIR:boolean;
     apache2ctl_bin:string;
     function getmodpathfromconf():string;
     function LOCATE_APACHE_CONF_PATH():string;
     function PID_PATH2():string;

public
    procedure    Free;
    constructor  Create(const zSYS:Tsystem);
    procedure    START();
    procedure    STOP();
    function     STATUS():string;
    function     BIN_PATH():string;
    function     PID_NUM():string;
    function     VERSION():string;
    procedure    RELOAD();
    function     PID_PATH():string;
    function     APACHE_DIR_SITES_ENABLED():string;
    function     APACHE_SRC_ACCOUNT():string;
    function     MODULE_EXISTS(modulename:string):boolean;
END;

implementation

constructor tapachesrc.Create(const zSYS:Tsystem);
begin

       LOGS:=tlogs.Create();
       SYS:=zSYS;
       binpath:=SYS.LOCATE_APACHE_BIN_PATH();
       if not TryStrToInt(SYS.GET_INFO('EnableFreeWeb'),EnableFreeWeb) then EnableFreeWeb:=0;
       apache2ctl_bin:=SYS.LOCATE_GENERIC_BIN('apache2ctl');
       if not FileExists(apache2ctl_bin) then apache2ctl_bin:=SYS.LOCATE_GENERIC_BIN('apachectl');
       NOREPAIR:=SYS.COMMANDLINE_PARAMETERS('--no-repair');


end;
//##############################################################################
procedure tapachesrc.free();
begin
    logs.Free;
end;
//##############################################################################

procedure tapachesrc.STOP();
var
   count:integer;
   RegExpr:TRegExpr;
   cmd:string;
   pids:Tstringlist;
   pidstring:string;
   fpid,i:integer;
begin
if not FileExists(binpath) then begin
   writeln('Stopping Apache.................: Not installed');
   exit;
end;

if not SYS.PROCESS_EXIST(PID_NUM()) then begin
   writeln('Stopping Apache.................: Already Stopped');
   pidstring:=SYS.PIDOF_PATTERN('/usr/sbin/apache2 -f /etc/apache2/apache2.conf');
   if length(pidstring)>0 then begin
       writeln('Stopping Apache.................: kill pid ',pidstring);
       fpsystem('/bin/kill -9 ' + pidstring);
  end;
   exit;
end;

   pidstring:=PID_NUM();
   writeln('Stopping Apache.................: '+pidstring);
   if FileExists(apache2ctl_bin) then fpsystem(apache2ctl_bin+' -k stop');

   pidstring:=PID_NUM();
   writeln('Stopping Apache.................: ' + pidstring + ' PID..');
   cmd:=SYS.LOCATE_GENERIC_BIN('kill')+' '+pidstring+' >/dev/null 2>&1';
   fpsystem(cmd);

   count:=0;
   while SYS.PROCESS_EXIST(pidstring) do begin
        sleep(200);
        count:=count+1;
        if count>50 then begin
            if length(pidstring)>0 then begin
               if SYS.PROCESS_EXIST(pidstring) then begin
                  writeln('Stopping Apache.................: kill pid '+ pidstring+' after timeout');
                  fpsystem('/bin/kill -9 ' + pidstring);
               end;
            end;
            break;
        end;
        pidstring:=PID_NUM();
  end;

  pidstring:=SYS.PIDOF_PATTERN('/usr/sbin/apache2 -f /etc/apache2/apache2.conf');
  if length(pidstring)>0 then begin
       writeln('Stopping Apache.................: kill pid ',pidstring);
       fpsystem('/bin/kill -9 ' + pidstring);
  end;


  if not SYS.PROCESS_EXIST(PID_NUM()) then  writeln('Stopping Apache.................: success');
end;

//##############################################################################
function tapachesrc.BIN_PATH():string;
begin
if length(binpath_memory)>3 then exit(binpath_memory);
binpath_memory:=SYS.LOCATE_APACHE_BIN_PATH();
exit(binpath_memory);
end;
//##############################################################################
procedure tapachesrc.RELOAD();
var
   pid,cmd:string;
begin
pid:=PID_NUM();

if SYS.PROCESS_EXIST(pid) then begin
   logs.DebugLogs('Starting......:  Apache reload PID ' +pid+ '...');
   if FileExists(apache2ctl_bin) then begin
      cmd:=SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.freeweb.php --build';
      fpsystem(cmd);
      cmd:=apache2ctl_bin +' -k restart';
      fpsystem(cmd);
      exit;
   end;
   STOP();
   START();
end;



   START();

end;
//##############################################################################
function tapachesrc.APACHE_DIR_SITES_ENABLED();
var binpath:string;
begin
   binpath:=SYS.LOCATE_APACHE_BIN_PATH();
   if not FileExists(binpath) then begin
      if sys.verbosed then writeln('APACHE_DIR_SITES_ENABLED():: Unable to stat apache bin path');
       exit;
   end;
   if sys.verbosed then writeln('APACHE_DIR_SITES_ENABLED():: binary ',binpath);
  result:=getmodpathfromconf()+'/sites-enabled';
   result:=AnsiReplaceText(result,'//','/');
  if sys.verbosed then writeln('APACHE_DIR_SITES_ENABLED():: ',result);



end;
//##############################################################################
function tapachesrc.MODULE_EXISTS(modulename:string):boolean;
var
   RegExpr:TRegExpr;
   l:Tstringlist;
   i:integer;
   D:boolean;
begin
D:=SYS.COMMANDLINE_PARAMETERS('--verbose');
if not FileExists(apache2ctl_bin) then begin
   if D then writeln('apache2ctl_bin -> false');
   exit(false);
end;

if FileExists('/tmp/artica-DUMP_MODULES.txt') then begin
   if SYS.FILE_TIME_BETWEEN_MIN('/tmp/artica-DUMP_MODULES.txt')>60 then logs.DeleteFile('/tmp/artica-DUMP_MODULES.txt');
end;
if not FileExists('/tmp/artica-DUMP_MODULES.txt') then begin
   if D then writeln(apache2ctl_bin+' -t -D DUMP_MODULES >/tmp/artica-DUMP_MODULES.txt 2>&1');
   fpsystem(apache2ctl_bin+' -t -D DUMP_MODULES >/tmp/artica-DUMP_MODULES.txt 2>&1');
end;

l:=tstringlist.Create;
RegExpr:=TRegExpr.Create;
l.LoadFromFile('/tmp/artica-DUMP_MODULES.txt');
RegExpr.Expression:=modulename+'\s+\(';
for i:=0 to l.Count-1 do begin
    if RegExpr.Exec(l.Strings[i]) then begin
       l.free;
       RegExpr.free;
       exit(true);
    end;
    if D then writeln('LINE: ',l.Strings[i]);

end;
      l.free;
       RegExpr.free;
       exit(false);
end;
//##############################################################################

function tapachesrc.APACHE_SRC_ACCOUNT():string;
 var binpath,httpd_conf,envars:string;
   RegExpr:TRegExpr;
   l:Tstringlist;
   i:integer;
begin
    if not sys.verbosed then begin
       if length(trim(APACHE_SRC_ACCOUNT_MEM))>3 then exit(APACHE_SRC_ACCOUNT_MEM);

       result:=SYS.GET_CACHE_VERSION('APACHE_SRC_ACCOUNT');
       if length(trim(result))>3 then begin

          APACHE_SRC_ACCOUNT_MEM:=trim(result);
          RegExpr:=TRegExpr.Create;
          RegExpr.Expression:='"';
          if not RegExpr.exec(APACHE_SRC_ACCOUNT_MEM) then exit(result);
       end;
   end;


   binpath:=SYS.LOCATE_APACHE_BIN_PATH();
    if not FileExists(binpath) then begin
      if sys.verbosed then writeln('APACHE_SRC_ACCOUNT():: Unable to stat apache bin path');
       exit;
   end;



   if sys.verbosed then writeln('APACHE_DIR_SITES_ENABLED():: binary ',binpath);
   httpd_conf:=LOCATE_APACHE_CONF_PATH();
   envars:=ExtractFilePath(httpd_conf)+'/envvars';
   envars:=AnsiReplaceText(envars,'//','/');
   if FileExists(envars) then begin
       if sys.verbosed then writeln('Open:',envars);
       l:=Tstringlist.Create;
       l.LoadFromFile(envars);
       RegExpr:=TRegExpr.Create;
       RegExpr.Expression:='export APACHE_RUN_USER=(.+)';
       for i:=0 to l.Count-1 do begin
           if RegExpr.Exec(l.Strings[i]) then begin
              if sys.verbosed then writeln('Found :',l.Strings[i]);
              result:=trim(RegExpr.Match[1]);
              SYS.SET_CACHE_VERSION('APACHE_SRC_ACCOUNT',result);
              APACHE_SRC_ACCOUNT_MEM:=result;
              l.free;
              RegExpr.free;
              exit(result);
           end;
       end;
   end;

       l:=Tstringlist.Create;
       if sys.verbosed then writeln('Open:',httpd_conf);
       l.LoadFromFile(httpd_conf);

       RegExpr:=TRegExpr.Create;
       RegExpr.Expression:='^User\s+(.+)';
 for i:=0 to l.Count-1 do begin
           if RegExpr.Exec(l.Strings[i]) then begin
               result:=trim(RegExpr.Match[1]);
               if length(result)>0 then begin
                 APACHE_SRC_ACCOUNT_MEM:=result;
                 RegExpr.Expression:='"';
                 if not RegExpr.exec(APACHE_SRC_ACCOUNT_MEM) then begin
                      SYS.SET_CACHE_VERSION('APACHE_SRC_ACCOUNT',result);
                      l.free;
                      RegExpr.free;
                      exit(result);
                 end;
              end;
           end;
       end;


l:=Tstringlist.Create;
if sys.verbosed then writeln('Open:','/etc/passwd');
l.LoadFromFile('/etc/passwd');
RegExpr.Expression:='^(.+?):x:[0-9]+:[0-9]+:(.+?):\/var\/www:';
 for i:=0 to l.Count-1 do begin
   if RegExpr.Exec(l.Strings[i]) then begin
    result:=trim(RegExpr.Match[1]);
    APACHE_SRC_ACCOUNT_MEM:=result;
    SYS.SET_CACHE_VERSION('APACHE_SRC_ACCOUNT',result);
    l.free;
    RegExpr.free;
    exit(result);
  end;
 end;



 l.free;
 RegExpr.free;

end;



function tapachesrc.LOCATE_APACHE_CONF_PATH():string;
var
   tmpstr,binpath:string;
   RegExpr:TRegExpr;
   l:Tstringlist;
   i:integer;
   HTTPD_ROOT:string;
   SERVER_CONFIG_FILE:string;
begin
     if length(LOCATE_APACHE_CONF_PATH_MEM)>3 then exit(LOCATE_APACHE_CONF_PATH_MEM);
     binpath:=SYS.LOCATE_APACHE_BIN_PATH();
     tmpstr:=logs.FILE_TEMP();
     fpsystem(binpath+' -V 2>&1 >'+tmpstr);
     RegExpr:=TRegExpr.Create;
     l:=Tstringlist.Create;
     l.LoadFromFile(tmpstr);
     logs.DeleteFile(tmpstr);
     for i:=0 to l.Count-1 do begin
      RegExpr.Expression:='HTTPD_ROOT="(.+?)"';
      if RegExpr.Exec(l.Strings[i]) then HTTPD_ROOT:=RegExpr.Match[1];
      RegExpr.Expression:='SERVER_CONFIG_FILE="(.+?)"';
      if RegExpr.Exec(l.Strings[i]) then SERVER_CONFIG_FILE:=RegExpr.Match[1];
     end;
     RegExpr.free;
     l.free;
     if FileExists(SERVER_CONFIG_FILE) then begin
        LOCATE_APACHE_CONF_PATH_MEM:=SERVER_CONFIG_FILE;
         if sys.verbosed then writeln('LOCATE_APACHE_CONF_PATH():: '+SERVER_CONFIG_FILE);
        exit(SERVER_CONFIG_FILE);
     end;

     result:=HTTPD_ROOT+'/'+SERVER_CONFIG_FILE;
     result:=AnsiReplaceText(result,'//','/');
     if sys.verbosed then writeln('LOCATE_APACHE_CONF_PATH():: '+result);
     LOCATE_APACHE_CONF_PATH_MEM:=result;


end;
//##############################################################################
function tapachesrc.getmodpathfromconf():string;
var httpdconf:string;
begin
   httpdconf:=LOCATE_APACHE_CONF_PATH();
   if httpdconf='/etc/httpd/conf/httpd.conf' then exit('/etc/httpd');
   if httpdconf='/usr/local/etc/httpd/conf/httpd.conf' then exit('/usr/local/etc/httpd');
   result:=ExtractFilePath(httpdconf);
end;
//##############################################################################




procedure tapachesrc.START();
var
   count:integer;
   cmd:string;
   su,nohup:string;
   conf:TiniFile;
   enabled:integer;
   RegExpr:TRegExpr;
   servername:string;
   tmpfile:string;
   cmdline:string;
   pidpath:string;
begin

   if not FileExists(binpath) then begin
      logs.DebugLogs('Starting......: Apache is not installed');
      exit;
   end;

if EnableFreeWeb=0 then begin
   logs.DebugLogs('Starting......: Apache is disabled');
   STOP();
   exit;
end;
pidpath:=PID_PATH();
logs.DebugLogs('Starting......: Apache detected pid: '+pidpath);

if SYS.PROCESS_EXIST(PID_NUM()) then begin
   logs.DebugLogs('Starting......: Apache Already running using PID ' +PID_NUM()+ '...');
   exit;
end;


   if FileExists(pidpath) then begin
      logs.DebugLogs('Starting......: Apache removing "'+pidpath+'"');
      logs.DeleteFile(pidpath);
   end;

   cmd:=SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.freeweb.php --build';
   fpsystem(cmd);


   count:=0;
   while not SYS.PROCESS_EXIST(PID_NUM()) do begin
     sleep(300);
     inc(count);
     if count>50 then begin
       logs.DebugLogs('Starting......: Apache (timeout!!!)');
       logs.DebugLogs('Starting......: Apache "'+cmd+'"');
       break;
     end;
   end;

   if not SYS.PROCESS_EXIST(PID_NUM()) then begin
      logs.DebugLogs('Starting......: Apache (failed!!!)');
      logs.DebugLogs('Starting......: Apache "'+cmd+'"');

       if not NOREPAIR then begin
          logs.DebugLogs('Starting......: Apache try to repair...');
          cmd:=SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.freeweb.php --failed-start';
          fpsystem(cmd);
       end;
   end else begin
       logs.DebugLogs('Starting......: Apache started with new PID '+PID_NUM());
       fpsystem('/etc/init.d/artica-postfix restart artica-status');
   end;

end;
//##############################################################################
function tapachesrc.STATUS():string;
var
pidpath:string;
begin

   if not FileExists(binpath) then exit;
   if EnableFreeWeb=0 then exit;
    pidpath:=logs.FILE_TEMP();
    fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.status.php --apachesrc >'+pidpath +' 2>&1');
   result:=logs.ReadFromFile(pidpath);
   logs.DeleteFile(pidpath);
end;
//#########################################################################################
 function tapachesrc.PID_NUM():string;
var  pidpath:string;
begin
     pidpath:=PID_PATH();
     if not FileExists(pidpath) then pidpath:=PID_PATH2();
     result:=SYS.GET_PID_FROM_PATH(PID_PATH());
     if sys.verbosed then logs.Debuglogs(' ->'+result);
end;
 //##############################################################################
function tapachesrc.PID_PATH2():string;
begin
 if FileExists('/var/run/httpd/httpd.pid') then exit('/var/run/httpd/httpd.pid');
end;



function tapachesrc.PID_PATH():string;
var
   l:TstringList;
   i:integer;
   RegExpr:TRegExpr;
   tmpstr:string;
   DEFAULT_PIDLOG:string;
   HTTPD_ROOT:string;
begin

    if length(binpath)=0 then exit;
    if Not Fileexists(binpath) then exit;
    result:=SYS.GET_CACHE_VERSION('APP_APACHE_SRC_PID');
    if FileExists(result) then exit;

    tmpstr:=logs.FILE_TEMP();
    fpsystem(binpath +' -V >'+tmpstr +' 2>&1');
    if not FileExists(tmpstr) then exit;
    l:=TstringList.Create;
    l.LoadFromFile(tmpstr);
    logs.DeleteFile(tmpstr);

    RegExpr:=TRegExpr.Create;

    for i:=0 to l.Count-1 do begin
         RegExpr.Expression:='DEFAULT_PIDLOG="(.+?)"';
         if RegExpr.Exec(l.Strings[i]) then DEFAULT_PIDLOG:=RegExpr.Match[1];
         RegExpr.Expression:='HTTPD_ROOT="(.+?)"';
         if RegExpr.Exec(l.Strings[i]) then HTTPD_ROOT:=RegExpr.Match[1];
    end;

    if FIleExists(DEFAULT_PIDLOG) then result:=DEFAULT_PIDLOG;
    if length(result)=0 then if FIleExists(HTTPD_ROOT+'/'+DEFAULT_PIDLOG) then result:=HTTPD_ROOT+'/'+DEFAULT_PIDLOG;
    SYS.SET_CACHE_VERSION('APP_APACHE_SRC_PID',result);
l.free;
RegExpr.free;
end;
//##############################################################################





function tapachesrc.VERSION():string;
var
   l:TstringList;
   i:integer;
   RegExpr:TRegExpr;
   tmpstr:string;
begin

    if length(binpath)=0 then exit;
    if Not Fileexists(binpath) then exit;
    result:=SYS.GET_CACHE_VERSION('APP_CLUEBRINGER');
     if length(result)>2 then exit;
     if not FileExists(binpath) then exit;

    tmpstr:=logs.FILE_TEMP();
    fpsystem(binpath +' --help >'+tmpstr +' 2>&1');
    if not FileExists(tmpstr) then exit;
    l:=TstringList.Create;
    l.LoadFromFile(tmpstr);
    logs.DeleteFile(tmpstr);

    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='ClueBringer.+?v([0-9\.A-Za-z]+)';
    for i:=0 to l.Count-1 do begin
         if RegExpr.Exec(l.Strings[i]) then begin
            result:=RegExpr.Match[1];
            break;
         end;
    end;
 SYS.SET_CACHE_VERSION('APP_CLUEBRINGER',result);
l.free;
RegExpr.free;
end;
//##############################################################################
end.
