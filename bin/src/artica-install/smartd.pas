unit smartd;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,IniFiles, Process,md5,logs,unix,RegExpr in 'RegExpr.pas',zsystem;

  type
  tsmartd=class


private
     LOGS:Tlogs;
     D:boolean;
     GLOBAL_INI:TiniFIle;
     SYS:TSystem;
     artica_path:string;
     binpath:string;
     EnableSMARTDisk:integer;
     procedure etc_default_debian();
     procedure ERROR_FAILED();

public
    procedure   Free;
    constructor Create(const zSYS:Tsystem);
    function  VERSION():string;
    function  PID_NUM():string;
    procedure START();
    procedure STOP();
    function  STATUS():string;



END;

implementation

constructor tsmartd.Create(const zSYS:Tsystem);
begin
       forcedirectories('/etc/artica-postfix');
       LOGS:=tlogs.Create();
       SYS:=zSYS;
       if not TryStrToInt(SYS.GET_INFO('EnableSMARTDisk'),EnableSMARTDisk) then begin
          EnableSMARTDisk:=1;
          SYS.set_INFO('EnableSMARTDisk','1');
       end;
       binpath:=SYS.LOCATE_GENERIC_BIN('smartd');





       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;
end;
//##############################################################################
procedure tsmartd.free();
begin
    FreeAndNil(logs);
end;
//##############################################################################
function tsmartd.VERSION():string;
  var
   RegExpr:TRegExpr;
   x:string;
   tmpstr:string;
   l:TstringList;
   i:integer;
   path:string;
begin



     path:=binpath;
     if not FileExists(path) then begin
        logs.Debuglogs('tsmartd.VERSION():: smartd is not installed');
        exit;
     end;


   result:=SYS.GET_CACHE_VERSION('APP_SMARTMONTOOLS');
   if length(result)>0 then exit;
   tmpstr:=logs.FILE_TEMP();
   fpsystem(path+' -V >'+tmpstr+' 2>&1');


     l:=TstringList.Create;
     RegExpr:=TRegExpr.Create;
     l.LoadFromFile(tmpstr);
     RegExpr.Expression:='release\s+([0-9\.]+)';
     for i:=0 to l.Count-1 do begin
         if RegExpr.Exec(l.Strings[i]) then begin
            result:=RegExpr.Match[1];
            break;
         end;
     end;
l.Free;
RegExpr.free;
SYS.SET_CACHE_VERSION('APP_SMARTMONTOOLS',result);
logs.Debuglogs('APP_SMARTMONTOOLS:: -> ' + result);
end;
//#############################################################################
procedure tsmartd.START();
var
   pid:string;
   count:integer;
begin

    if not FileExists(binpath) then begin
    logs.DebugLogs('Starting......: smartd is not installed');
    exit;
    end;

    if EnableSMARTDisk=0 then begin
        logs.DebugLogs('Starting......: smartd is disabled');
        exit;
    end;

  pid:=PID_NUM();

if SYS.PROCESS_EXIST(pid) then begin
     logs.DebugLogs('Starting......: smartd already running using PID ' +pid+ '...');
     exit;
end;

    etc_default_debian();
    fpsystem(binpath);

 count:=0;
 while not SYS.PROCESS_EXIST(PID_NUM()) do begin
              sleep(150);
              inc(count);
              if count>20 then begin
                 logs.DebugLogs('Starting......: smartd daemon. (timeout!!!)');
                 break;
              end;
        end;



if  not SYS.PROCESS_EXIST(PID_NUM()) then begin
    logs.DebugLogs('Starting......: smartd daemon failed try to understand why');
    ERROR_FAILED();
    exit;
end;

logs.DebugLogs('Starting......: smartd daemon success with new PID ' + PID_NUM());



end;
//##############################################################################
function tsmartd.PID_NUM():string;
begin
     result:=SYS.PIDOF(binpath);
end;
//##############################################################################
procedure tsmartd.ERROR_FAILED();

 var
 tmpstr:string;
 l:Tstringlist;
 RegExpr:TRegExpr;
 i:integer;
begin
 tmpstr:=logs.FILE_TEMP();
 fpsystem('/usr/sbin/smartd -d -q onecheck >'+ tmpstr+ ' 2>&1');
 if not FIleExists(tmpstr) then exit;
 l:=Tstringlist.Create;
 l.LoadFromFile(tmpstr);
 logs.DeleteFile(tmpstr);
 RegExpr:=TRegExpr.Create;
 for i:=0 to l.Count-1 do begin
    RegExpr.Expression:='Unable to monitor any SMART enabled devices';
    if RegExpr.Exec(l.Strings[i]) then begin
         logs.DebugLogs('Starting......: smartd daemon is incompatible with your disk(s), disable it');
         SYS.SET_INFO('EnableSMARTDisk','0');
         break;
    end;
 end;

 l.free;
 RegExpr.free;

end;
//##############################################################################

procedure tsmartd.STOP();
var
   count:integer;
begin

    if not FileExists('/usr/sbin/smartd') then begin
    writeln('Stopping smartd..............: Not installed');
    exit;
    end;

    if SYS.PROCESS_EXIST(PID_NUM()) then begin
       writeln('Stopping smartd..............: ' + PID_NUM() + ' PID..');
       fpsystem('/etc/init.d/smartd stop');
    end;

if  not SYS.PROCESS_EXIST(PID_NUM()) then begin
     writeln('Stopping smartd..............: success');
    exit;
end;
     writeln('Stopping smartd..............: failed');

end;
//#############################################################################
procedure tsmartd.etc_default_debian();
var
   l:Tstringlist;
begin
if not fileExists('/etc/default/smartmontools') then exit;
l:=Tstringlist.Create;
l.Add('start_smartd=yes');
l.add('smartd_opts="--interval=1800"');
logs.WriteToFile(l.Text,'/etc/default/smartmontools');
l.free;
end;
//#############################################################################
function tsmartd.STATUS();
var
   ini:TstringList;
   pid:string;
begin
if not FileExists(binpath) then exit;
pid:=PID_NUM();


      ini:=TstringList.Create;
      ini.Add('[SMARTD]');
      ini.Add('master_version=' + VERSION());
      ini.Add('service_name=APP_SMARTMONTOOLS');
      ini.Add('service_cmd=smartd');
      ini.Add('service_disabled='+IntToStr(EnableSMARTDisk));

      if EnableSMARTDisk=0 then begin
            result:=ini.Text;
            ini.free;

            exit;
      end;



      if SYS.PROCESS_EXIST(pid) then ini.Add('running=1') else  ini.Add('running=0');
      ini.Add('application_installed=1');
      ini.Add('master_pid='+ pid);
      ini.Add('master_memory=' + IntToStr(SYS.PROCESS_MEMORY(pid)));
      ini.Add('status='+SYS.PROCESS_STATUS(pid));
      result:=ini.Text;
      ini.free;
end;
//##############################################################################
end.
