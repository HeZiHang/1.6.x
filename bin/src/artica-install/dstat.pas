unit dstat;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,Process,logs,unix,RegExpr in 'RegExpr.pas',zsystem,postfix_class;


  type
  tdstat=class


private
     LOGS:Tlogs;
     SYS:Tsystem;
     artica_path:string;
     function GET_PID():string;
     function GET_PID1():string;
     function GET_PID2():string;

public
    procedure   Free;
    constructor Create(const zSYS:Tsystem);
    procedure   START();
    procedure   STOP();
    function    VERSION():string;
    procedure   GENERATE_MEMORY(filepath:string);
    procedure   GENERATE_CPU(filepath:string);
    procedure   GENERATE_POSTFIX(filepath:string);
    procedure   STOP_TOP_MEMORY();
    procedure   STOP_TOP_CPU();
    procedure   START_TOP_MEMORY();
    procedure   START_TOP_CPU();
    function    IS_GNUPLOT_PNG():boolean;
    procedure   FOLLOWFILES();



END;

implementation

constructor tdstat.Create(const zSYS:Tsystem);
begin
       forcedirectories('/etc/artica-postfix');
       LOGS:=tlogs.Create();
       SYS:=zSys;



       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;
end;
//##############################################################################
procedure tdstat.free();
begin
    logs.Free;
end;
//##############################################################################
procedure tdstat.START();

var
   pid:string;
   postfix:tpostfix;
begin

     if not FileExists('/usr/bin/dstat') then begin
        logs.DebugLogs('Starting......: dstat is not installed');
        exit;
     end;

     pid:=GET_PID();
     if SYS.PROCESS_EXIST(pid) then begin
        logs.DebugLogs('Starting......: dstat "memory" already running pid '+pid);
     end else begin
        logs.DebugLogs('Starting......: dstat "memory"');
        fpsystem('/usr/bin/dstat -tm --noheaders 10 > /var/log/artica-postfix/dstat_memory.csv 2>&1 &');
     end;

     pid:=GET_PID1();
     if SYS.PROCESS_EXIST(pid) then begin
        logs.DebugLogs('Starting......: dstat "cpu" already running pid '+pid);
     end else begin
        logs.DebugLogs('Starting......: dstat "cpu"');
        fpsystem('/usr/bin/dstat -tc --noheaders 5 500  > /var/log/artica-postfix/dstat_cpu.csv 2>&1 &');
     end;

     postfix:=tpostfix.Create(SYS);
     if FileExists(postfix.POSFTIX_POSTCONF_PATH()) then begin
        pid:=GET_PID2();
         if SYS.PROCESS_EXIST(pid) then begin
           logs.DebugLogs('Starting......: dstat "postfix" already running pid '+pid);
         end else begin
           logs.DebugLogs('Starting......: dstat "postfix"');
           fpsystem('/usr/bin/dstat -t -M postfix --noheaders 5 500 > /var/log/artica-postfix/dstat_postfix.csv 2>&1 &');
         end;
     end;


postfix.free;

end;

//##############################################################################
function tdstat.VERSION:string;
  var
   RegExpr:TRegExpr;
   tmpstr:string;
   l:TstringList;
   i:integer;
   path:string;
begin



     path:='/usr/bin/dstat';
     if not FileExists(path) then begin
        logs.Debuglogs('tdstat.DSTAT_VERSION():: dstat is not installed');
        exit;
     end;


   result:=SYS.GET_CACHE_VERSION('APP_DSTAT');
   if length(result)>0 then exit;
   tmpstr:=path;



     l:=TstringList.Create;
     RegExpr:=TRegExpr.Create;
     l.LoadFromFile(tmpstr);
     RegExpr.Expression:='VERSION\s+=.+?([0-9\.]+)';
     for i:=0 to l.Count-1 do begin
         if RegExpr.Exec(l.Strings[i]) then begin
            result:=RegExpr.Match[1]+'.'+RegExpr.Match[2];
            break;
         end;
     end;
l.Free;
RegExpr.free;
SYS.SET_CACHE_VERSION('APP_DSTAT',result);
logs.Debuglogs('APP_DSTAT:: -> ' + result);
end;

//##############################################################################
function tdstat.GET_PID():string;
var
   pid:string;
begin

     PID:=trim(SYS.ExecPipe('/usr/bin/pgrep -f "python /usr/bin/dstat -tm --noheaders"'));
     result:=pid;
end;
//##############################################################################
function tdstat.GET_PID1():string;
var
   pid:string;
begin

     PID:=trim(SYS.ExecPipe('/usr/bin/pgrep -f "python /usr/bin/dstat -tc --noheaders"'));
     result:=pid;
end;
//##############################################################################
function tdstat.GET_PID2():string;
var
   pid:string;
begin

     PID:=trim(SYS.ExecPipe('/usr/bin/pgrep -f "python /usr/bin/dstat -t -M postfix"'));
     result:=pid;
end;
//##############################################################################
procedure tdstat.STOP();
var
   pid:string;
begin


pid:=get_pid();
 if SYS.PROCESS_EXIST(pid) then begin
     writeln('Stopping dstat "memory"......: pid '+pid);
     logs.OutputCmd('/bin/kill ' +pid);
 end else begin
     writeln('Stopping dstat "memory"......: Already stopped');
 end;


pid:=get_pid1();
 if SYS.PROCESS_EXIST(pid) then begin
     writeln('Stopping dstat "cpu".........: pid '+pid);
     logs.OutputCmd('/bin/kill ' +pid);
 end else begin
     writeln('Stopping dstat "cpu".........: Already stopped');
 end;


pid:=get_pid2();
 if SYS.PROCESS_EXIST(pid) then begin
     writeln('Stopping dstat "postfix".....: pid '+pid);
     logs.OutputCmd('/bin/kill ' +pid);
 end else begin
     writeln('Stopping dstat "postfix".....: Already stopped');
 end;

end;
//##############################################################################
procedure tdstat.STOP_TOP_MEMORY();
var
   pid:string;
begin


pid:=SYS.PIDOF_PATTERN('/usr/bin/dstat -t -M topmem --noheader 5 500');
 if SYS.PROCESS_EXIST(pid) then begin
     writeln('Stopping dstat "TOP MEMORY"..: pid '+pid);
     logs.OutputCmd('/bin/kill ' +pid);
 end else begin
     writeln('Stopping dstat "TOP MEMORY"..: Already stopped');
 end;

end;
//##############################################################################
procedure tdstat.STOP_TOP_CPU();
var
   pid:string;
begin


pid:=SYS.PIDOF_PATTERN('/usr/bin/dstat -t -M topcpu --noheader 5 500');
 if SYS.PROCESS_EXIST(pid) then begin
     writeln('Stopping dstat "TOP CPU".....: pid '+pid);
     logs.OutputCmd('/bin/kill ' +pid);
 end else begin
     writeln('Stopping dstat "TOP CPU".....: Already stopped');
 end;

end;
//##############################################################################
procedure tdstat.START_TOP_MEMORY();
var
   pid:string;
begin

     if not FileExists('/usr/bin/dstat') then begin
        logs.DebugLogs('Starting......: dstat "TOP MEMORY" is not installed');
        exit;
     end;

     pid:=SYS.PIDOF_PATTERN('/usr/bin/dstat -t -M topmem --noheader 5 500');
     if SYS.PROCESS_EXIST(pid) then begin
        logs.DebugLogs('Starting......: dstat "TOP MEMORY" already running pid '+pid);
     end else begin
        logs.DebugLogs('Starting......: dstat "TOP MEMORY"');
        fpsystem('/usr/bin/dstat -t -M topmem --noheader 5 500 >> /var/log/artica-postfix/dstat_topmem.csv 2>&1 &');
     end;

     pid:=SYS.PIDOF_PATTERN('/usr/bin/dstat -t -M topmem --noheader 5 500');
     if SYS.PROCESS_EXIST(pid) then begin
        logs.DebugLogs('Starting......: dstat "TOP MEMORY" success with PID '+pid);
     end;

end;
//##############################################################################
procedure tdstat.START_TOP_CPU();
var
   pid:string;
begin

     if not FileExists('/usr/bin/dstat') then begin
        logs.DebugLogs('Starting......: dstat "TOP CPU" is not installed');
        exit;
     end;

     pid:=SYS.PIDOF_PATTERN('/usr/bin/dstat -t -M topcpu --noheader 5 500');
     if SYS.PROCESS_EXIST(pid) then begin
        logs.DebugLogs('Starting......: dstat "TOP CPU" already running pid '+pid);
     end else begin
        logs.DebugLogs('Starting......: dstat "TOP CPU"');
        fpsystem('/usr/bin/dstat -t -M topcpu --noheader 5 500 >> /var/log/artica-postfix/dstat_topcpu.csv 2>&1 &');
     end;

     pid:=SYS.PIDOF_PATTERN('/usr/bin/dstat -t -M topcpu --noheader 5 500');
     if SYS.PROCESS_EXIST(pid) then begin
        logs.DebugLogs('Starting......: dstat "TOP CPU" success with PID '+pid);
     end;

end;
//##############################################################################
function tdstat.IS_GNUPLOT_PNG():boolean;
var
   l:Tstringlist;
   RegExpr:TRegExpr;
   tmpstr:string;
   i:Integer;
begin


     if length(SYS.GET_CACHE_VERSION('IS_GNUPLOT_PNG'))>0 then exit(true);

     result:=false;
     if not FileExists('/usr/bin/gnuplot') then exit;
     tmpstr:=LOGS.FILE_TEMP();

     fpsystem('/bin/echo "\n\n\n"|/usr/bin/gnuplot -e "set terminal" >'+tmpstr+' 2>&1');
     if not FileExists(tmpstr) then exit;
     l:=TstringList.Create;
     RegExpr:=TRegExpr.Create;
     RegExpr.Expression:='PNG images using';

     l.LoadFromFile(tmpstr);
     logs.DeleteFile(tmpstr);
     for i:=0 to l.Count-1 do begin
         if RegExpr.Exec(l.Strings[i]) then begin
            result:=true;
            SYS.SET_CACHE_VERSION('IS_GNUPLOT_PNG','good');
            break;
         end;
     end;

    l.free;
    RegExpr.free;

end;
//##############################################################################
procedure tdstat.GENERATE_MEMORY(filepath:string);
var
   l:TstringList;
   tmpstr:string;
begin

logs.OutputCmd('/bin/rm -rf /usr/share/artica-postfix/ressources/logs/web/dstat-mem-*.png');


if FileExists('/var/log/artica-postfix/dstat_memory.csv') then begin
   l:=Tstringlist.Create;
   l.LoadFromFile('/var/log/artica-postfix/dstat_memory.csv');
   l.Strings[0]:='';
   l.Strings[1]:='';
   l.Strings[2]:='';

   tmpstr:=logs.FILE_TEMP();
   l.SaveToFile(tmpstr);
   l.Clear;
   l.add('#!/usr/bin/gnuplot -persist');
   l.add('reset');
   l.add('set xlabel "time"');
   l.add('set autoscale');
   l.add('set grid');
   l.add('set xdata time');
   l.add('set format x "%H:%M"');
   l.add('set timefmt "%d-%m %H:%M:%S"');
   l.add('set ylabel "MB"');
   l.add('set term png transparent size 500,250');
   l.add('set datafile commentschars "-"');
   l.add('set title "physical memory"');
   l.add('set output "'+filepath+'"');
   l.add('plot "'+tmpstr+'" using 1:3 title "used" with lines,"'+tmpstr+'" using 1:4 title "buffered" with lines,"'+tmpstr+'" using 1:5 title "cached" with lines');
   l.SaveToFile(tmpstr+'.plot');
   logs.OutputCmd('/bin/chmod 777 '+tmpstr+'.plot');
   fpsystem(tmpstr+'.plot');
   logs.DeleteFile(tmpstr+'.plot');
   logs.DeleteFile(tmpstr);
   if FileExists(filepath) then logs.OutputCmd('/bin/chmod 755 ' + filepath);
   sleep(1000);
   l.free;
end;


end;
//##############################################################################
procedure tdstat.GENERATE_CPU(filepath:string);
var
   l:TstringList;
   tmpstr:string;
begin

logs.OutputCmd('/bin/rm -rf /usr/share/artica-postfix/ressources/logs/web/dstat-cpu-*.png');


if FileExists('/var/log/artica-postfix/dstat_cpu.csv') then begin
   l:=Tstringlist.Create;
   l.LoadFromFile('/var/log/artica-postfix/dstat_cpu.csv');
   l.Strings[0]:='';
   l.Strings[1]:='';
   l.Strings[2]:='';

   tmpstr:=logs.FILE_TEMP();
   l.SaveToFile(tmpstr);
   l.Clear;
   l.add('#!/usr/bin/gnuplot -persist');
   l.add('reset');
   l.add('set xlabel "time"');
   l.add('set ylabel "%"');
   l.add('set autoscale');
   l.add('set grid');
   l.add('set xdata time');
   l.add('set format x "%H:%M"');
   l.add('set timefmt "%d-%m %H:%M:%S"');
   l.add('set term png transparent size 500,250');
   l.add('set datafile commentschars "-"');
   l.add('set title "CPU"');
   l.add('set output "'+filepath+'"');
   l.add('plot "'+tmpstr+'" using 1:3 title "Usr" with lines,"'+tmpstr+'" using 1:4 title "Syst" with lines');
   l.SaveToFile(tmpstr+'.plot');
   logs.OutputCmd('/bin/chmod 777 '+tmpstr+'.plot');
   fpsystem(tmpstr+'.plot');
   logs.DeleteFile(tmpstr+'.plot');
   logs.DeleteFile(tmpstr);
   if FileExists(filepath) then logs.OutputCmd('/bin/chmod 755 ' + filepath);
   sleep(1000);
   l.free;
end;


end;
//##############################################################################
procedure tdstat.FOLLOWFILES();
var
   filesize:integer;
   pid:string;
   tostart:boolean;
begin

   tostart:=false;
   filesize:=SYS.FileSize_ko('/var/log/artica-postfix/dstat_postfix.csv');

   if Filesize>1000 then begin
      logs.Syslogs('Killing /var/log/artica-postfix/dstat_postfix.csv');
      logs.DeleteFile('/var/log/artica-postfix/dstat_postfix.csv');
      pid:=get_pid2();
      if length(pid)>0 then begin
         fpsystem('/bin/kill ' + pid);
         tostart:=true;
      end;
   end;


   filesize:=SYS.FileSize_ko('/var/log/artica-postfix/dstat_cpu.csv');

   logs.Debuglogs('tdstat.FOLLOWFILES() dstat_cpu.csv='+ IntToStr(filesize)+'Ko');

   if Filesize>1000 then begin
      logs.Syslogs('Killing /var/log/artica-postfix/dstat_cpu.csv');
      logs.DeleteFile('/var/log/artica-postfix/dstat_cpu.csv');
      pid:=get_pid1();
      if length(pid)>0 then begin
         fpsystem('/bin/kill ' + pid);
         tostart:=true;
      end;
   end;



   filesize:=SYS.FileSize_ko('/var/log/artica-postfix/dstat_memory.csv');
   logs.Debuglogs('tdstat.FOLLOWFILES() dstat_memory.csv='+ IntToStr(filesize)+'Ko');

   if Filesize>1000 then begin
      logs.Syslogs('Killing /var/log/artica-postfix/dstat_memory.csv');
      logs.DeleteFile('/var/log/artica-postfix/dstat_memory.csv');
      pid:=get_pid();
      if length(pid)>0 then begin
         fpsystem('/bin/kill ' + pid);
         tostart:=true;
      end;
   end;

   filesize:=SYS.FileSize_ko('/var/log/artica-postfix/dstat_topcpu.csv');
   logs.Debuglogs('tdstat.FOLLOWFILES() dstat_topcpu.csv='+ IntToStr(filesize)+'Ko');
   if Filesize>1000 then begin
      logs.Syslogs('Killing /var/log/artica-postfix/dstat_topcpu.csv');
      logs.DeleteFile('/var/log/artica-postfix/dstat_topcpu.csv');
      STOP_TOP_CPU();
      START_TOP_CPU();
   end;

  filesize:=SYS.FileSize_ko('/var/log/artica-postfix/dstat_topmem.csv');
   logs.Debuglogs('tdstat.FOLLOWFILES() dstat_topmem.csv='+ IntToStr(filesize)+'Ko');

   if Filesize>1000 then begin
      logs.Syslogs('Killing /var/log/artica-postfix/dstat_topmem.csv');
      logs.DeleteFile('/var/log/artica-postfix/dstat_topmem.csv');
      STOP_TOP_MEMORY();
      START_TOP_MEMORY();
   end;


if tostart then logs.OutputCmd('/etc/init.d/artica-postfix start dstat &');

end;
//##############################################################################



procedure tdstat.GENERATE_POSTFIX(filepath:string);
var
   l:TstringList;
   tmpstr:string;
begin

logs.OutputCmd('/bin/rm -rf /usr/share/artica-postfix/ressources/logs/web/dstat-postfix-*.png');


if FileExists('/var/log/artica-postfix/dstat_postfix.csv') then begin
   l:=Tstringlist.Create;
   l.LoadFromFile('/var/log/artica-postfix/dstat_postfix.csv');
   l.Strings[0]:='';
   l.Strings[1]:='';
   l.Strings[2]:='';

   tmpstr:=logs.FILE_TEMP();
   l.SaveToFile(tmpstr);
   l.Clear;
   l.add('#!/usr/bin/gnuplot -persist');
   l.add('reset');
   l.add('set xlabel "time"');
   l.add('set autoscale');
   l.add('set grid');
   l.add('set xdata time');
   l.add('set format x "%H:%M"');
   l.add('set timefmt "%d-%m %H:%M:%S"');
   l.add('set ylabel "eMails"');
   l.add('set term png transparent size 500,250');
   l.add('set datafile commentschars "-"');
   l.add('set title "Postfix queues"');
   l.add('set output "'+filepath+'"');
   l.add('plot "'+tmpstr+'" using 1:3 title "incoming" with lines,"'+tmpstr+'" using 1:4 title "active" with lines,"'+tmpstr+'" using 1:5 title "deferred" with lines,"'+tmpstr+'" using 1:6 title "bounce" with lines,"'+tmpstr+'" using 1:7 title "defer" with lines');
   l.SaveToFile(tmpstr+'.plot');
   logs.OutputCmd('/bin/chmod 777 '+tmpstr+'.plot');
   logs.OutputCmd(tmpstr+'.plot');
   logs.DeleteFile(tmpstr+'.plot');
   logs.DeleteFile(tmpstr);
   if FileExists(filepath) then logs.OutputCmd('/bin/chmod 755 ' + filepath);
   sleep(1000);
   l.free;
end;


end;
//##############################################################################


end.
