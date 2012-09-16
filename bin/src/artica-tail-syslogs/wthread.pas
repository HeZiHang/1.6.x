unit wthread;
{$MODE DELPHI}
//{$mode objfpc}{$H+}
{$LONGSTRINGS ON}
interface
uses
  Libc, Classes,logs,SysUtils,global_conf,IniFiles,RegExpr,systemlog;
type
  TSampleThread = class
  private
    tid          : integer;
    logs         :tlogs;
    maillog_path :string;
    fileSize_mem :integer;
    GLOBAL_INI   :myconf;
    regexfile    :TstringList;
    infected_file:TstringList;
    memvals      :TiniFile;
    artica_path  :string;
    mem_year     :string;
    FUNCTION      TRANSFORM_DATE_MONTH(zText:string):string;
    function      GetFileBytes(path:string):longint;
    function      maillog():string;
    procedure     ParseLine(line:string);
    procedure     ParseRegexErrors(text:string;service:string);
    procedure     ParseFileRegex(regex:string;error:string;number:string;text:string;service:string);
    procedure     ParseInfected(text:string;service:string;zdate:string);
    procedure     CheckMaxLogs();
public

    constructor Create();
  end;

implementation

constructor TSampleThread.Create;
begin
GLOBAL_INI:=myconf.Create;
maillog_path:=GLOBAL_INI.SYSTEM_GET_SYSLOG_PATH();
artica_path:=GLOBAL_INI.get_ARTICA_PHP_PATH();
logs:=tlogs.Create;
mem_year:=logs.getyear();
memvals:=TiniFile.Create('/etc/artica-postfix/tail.maillog.conf');
regexfile:=TstringList.Create;
infected_file:=TstringList.Create;
if FileExists(artica_path +'/ressources/databases/tail.infected.regex') then begin
   logs.Debuglogs('loading ' + artica_path +'/ressources/databases/tail.infected.regex');
   infected_file.LoadFromFile(artica_path +'/ressources/databases/tail.infected.regex');
end;

if FileExists(artica_path +'/ressources/databases/postfix.syslog.regex') then begin
   logs.Debuglogs('loading ' + artica_path +'/ressources/databases/postfix.syslog.regex');
   regexfile.LoadFromFile(artica_path +'/ressources/databases/postfix.syslog.regex');
end;
    maillog();
    CheckMaxLogs();
    logs.Debuglogs('Execute :: -> end');
end;

function TSampleThread.maillog():string;
var
   filesize:integer;
   old_filesize:integer;
   old_lines:integer;
   l:TstringList;
   i:integer;
   FileLines:integer;
begin
result:='';
old_filesize:=memvals.ReadInteger('TMP','maillogsize',0);
old_lines:=memvals.ReadInteger('TMP','mailloglines',0);
fileSize:=GetFileBytes(maillog_path);

logs.Debuglogs('maillog() :: ' +maillog_path + ' old_filesize=' + intToStr(old_filesize) + ',old_lines=' + intToStr(old_lines) + '('+intToStr(fileSize) + ' bytes) ' + IntToStr(regexfile.Count) + ' regex patterns');

if fileSize<old_filesize then begin
    logs.Debuglogs('maillog() :: ' +maillog_path + '-> purge');
     old_filesize:=0;
     old_lines:=0;
end;


if old_filesize=fileSize then exit;

   logs.Debuglogs('maillog() :: ' + maillog_path + '-> analyze (fileSize='+ IntToStr(fileSize)+' bytes)');
   l:=TstringList.Create;
   l.LoadFromFile(maillog_path);
   FileLines:=l.count-1;
   if FileLines-old_lines>10000 then begin
        old_lines:=FileLines-10000;
        memvals.WriteInteger('TMP','mailloglines',old_lines);
   end;

   
   logs.Debuglogs('maillog() :: Starting from '+ IntTOStr(old_lines) + ' to ' +IntTOStr(l.Count));
   if old_lines<l.Count-1 then begin
         for i:=old_lines to  FileLines do begin
             ParseLine(l.Strings[i]);
             //logs.Debuglogs('maillog() :: Parse line ' + IntTOStr(i) + '/' + IntTOStr(FileLines));
             memvals.WriteInteger('TMP','mailloglines',i);
         end;

   end;



   memvals.WriteInteger('TMP','maillogsize',fileSize);


   l.free;

end;
//##############################################################################
procedure TSampleThread.CheckMaxLogs();
var
   tmpstr:string;
   MysqlMaxEventsLogs:integer;
   currentnum:integer;
   limit:integer;
   sql:string;
begin
  tmpstr:=GLOBAL_INI.get_INFOS('MysqlMaxEventsLogs');
  if length(tmpstr)=0 then tmpstr:='200000';
  MysqlMaxEventsLogs:=StrToInt(tmpstr);
  currentnum:=logs.SYS_EVENTS_ROWNUM();
  if currentnum>MysqlMaxEventsLogs then begin
     limit:=currentnum-MysqlMaxEventsLogs;
     limit:=limit+100;
     logs.logs('TSampleThread.CheckMaxLogs():: DELETE '+ IntToStr(limit) +' first rows in sys_events table');
     sql:='DELETE FROM `sys_events` ORDER BY zDate LIMIT '+IntToStr(limit);
     tRY
        logs.QUERY_SQL(Pchar(sql),'artica_events');
     EXCEPT
        logs.logs('CheckMaxLogs():: FATAL ERROR');
     END;
  end;

end;
//##############################################################################



procedure TSampleThread.ParseLine(line:string);
var
   RegExpr:TRegExpr;
   month,day,time,service,text,newdate,msg_id:string;
begin
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^([a-zA-Z]+)\s+([0-9]+)\s+([0-9\:]+)\s+.+?\s+([a-zA-Z0-9\-\_\/]+).+?\s+(.+)';
   if not RegExpr.Exec(line) then begin
      logs.logs('unable to match ' + line);
      exit;
   end;

   month:=RegExpr.Match[1];
   month:=TRANSFORM_DATE_MONTH(month);
   day:=RegExpr.Match[2];
   time:=RegExpr.Match[3];
   service:=RegExpr.Match[4];
   text:=RegExpr.Match[5];
   newdate:=mem_year + '-'+month+'-'+ day + ' ' + time;


   RegExpr.Expression:='postfix\/[a-z]+';
   if RegExpr.Exec(service) then service:='postfix';

   if service='cyrus/lmtpunix' then service:='cyrus';
   if service='cyrus/master' then service:='cyrus';
   if service='cyrus/imap' then service:='cyrus';
   if service='cyrus/notify' then service:='cyrus';
   if service='cyrus/pop3' then service:='cyrus';
   if service='cyrus/ctl_cyrusdb' then service:='cyrus';
   if service='cyrus/cyr_expire' then service:='cyrus';
   if service='/USR/SBIN/CRON' then service:='cron';
   if service='kas-restart' then  service  :='kas';
   if service='kas-thttpd' then   service  :='kas';
   if service='sfmonitoring' then service  :='kas';

   RegExpr.Expression:='([A-Z0-9]+):\s+';
   if RegExpr.Exec(text) then msg_id:=RegExpr.Match[1];
   ParseRegexErrors(text,service);
   ParseInfected(text,service,newdate);
   if GLOBAL_INI.get_INFOS('EnableSyslogMysql')='1' then logs.mysql_sysev('0',service,text,newdate,msg_id);
   RegExpr.free;

end;
//##############################################################################
procedure TSampleThread.ParseRegexErrors(text:string;service:string);
var
   i:integer;
   RegExpr:TRegExpr;

begin
   i:=0;
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='(.+?);(.+);([0-9]+)';
   for i:=0 to regexfile.Count-1 do begin
        if RegExpr.Exec(regexfile.Strings[i]) then begin
             ParseFileRegex(RegExpr.Match[1],RegExpr.Match[2],RegExpr.Match[3],text,service);
        end;
   end;
   RegExpr.free;
end;
//##############################################################################
procedure TSampleThread.ParseInfected(text:string;service:string;zdate:string);
var
   i:integer;
   RegExpr:TRegExpr;

begin
   RegExpr:=TRegExpr.Create;


   for i:=0 to infected_file.Count-1 do begin
        RegExpr.Expression:=infected_file.Strings[i];
      try
        if RegExpr.Exec(text) then begin
             logs.Debuglogs('ParseInfected :: virus '+RegExpr.Match[1]);
             logs.mysql_virus(service,text,zdate,RegExpr.Match[1]);
             RegExpr.free;
             exit;
        end;
      except
            logs.Debuglogs('ParseInfected :: fatal error on ' + infected_file.Strings[i]);
            RegExpr.free;
            exit;
      end;
   end;
   RegExpr.free;
end;
//##############################################################################


procedure TSampleThread.ParseFileRegex(regex:string;error:string;number:string;text:string;service:string);
var
   RegExpr:TRegExpr;

begin

   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:=regex;
   
   try
   if RegExpr.Exec(text) then begin
     logs.Debuglogs('ParseFileRegex ::  match ' +regex + ' notify '+error);
     logs.mysql_notify(number,service,text+chr(9)+chr(10)+error);
   end;
   except
      logs.Debuglogs('ParseFileRegex ::  fatal error on ' + regex);
      exit;

   end;

    RegExpr.free;

end;




//##############################################################################
FUNCTION TSampleThread.TRANSFORM_DATE_MONTH(zText:string):string;
begin
  zText:=UpperCase(zText);
  zText:=StringReplace(zText, 'JAN', '01',[rfReplaceAll, rfIgnoreCase]);
  zText:=StringReplace(zText, 'FEB', '02',[rfReplaceAll, rfIgnoreCase]);
  zText:=StringReplace(zText, 'MAR', '03',[rfReplaceAll, rfIgnoreCase]);
  zText:=StringReplace(zText, 'APR', '04',[rfReplaceAll, rfIgnoreCase]);
  zText:=StringReplace(zText, 'MAY', '05',[rfReplaceAll, rfIgnoreCase]);
  zText:=StringReplace(zText, 'JUN', '06',[rfReplaceAll, rfIgnoreCase]);
  zText:=StringReplace(zText, 'JUL', '07',[rfReplaceAll, rfIgnoreCase]);
  zText:=StringReplace(zText, 'AUG', '08',[rfReplaceAll, rfIgnoreCase]);
  zText:=StringReplace(zText, 'SEP', '09',[rfReplaceAll, rfIgnoreCase]);
  zText:=StringReplace(zText, 'OCT', '10',[rfReplaceAll, rfIgnoreCase]);
  zText:=StringReplace(zText, 'NOV', '11',[rfReplaceAll, rfIgnoreCase]);
  zText:=StringReplace(zText, 'DEC', '12',[rfReplaceAll, rfIgnoreCase]);
  result:=zText;
end;
function TSampleThread.GetFileBytes(path:string):longint;
Var
L : File Of byte;
size:longint;
ko:longint;

begin
if not FileExists(path) then begin
   result:=0;
   exit;
end;
   TRY
  Assign (L,path);
  Reset (L);
  size:=FileSize(L);
   Close (L);
  ko:=size;
  result:=ko;
  EXCEPT

  end;
end;
//##############################################################################

end.


