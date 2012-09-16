unit wthread3;
{$MODE DELPHI}
//{$mode objfpc}{$H+}
{$LONGSTRINGS ON}
interface
uses
  Libc, Classes,logs,SysUtils,global_conf,IniFiles,RegExpr,systemlog,mimedefang,unix,artica_mysql;
type
  TSampleThread3 = class(TThread)
  private
    tid          : integer;
    logs         :tlogs;
    maillog_path :string;
    fileSize_mem :integer;
    GLOBAL_INI   :myconf;
    memvals      :TiniFile;
    artica_path  :string;
    mem_year     :string;
    memread      :TiniFile;
    function     GetFileBytes(path:string):longint;
    procedure    filter_log();
    procedure    ParseLine(line:string);

  protected
    procedure Execute; override;
  public

    constructor Create(startSuspended: boolean);
  end;

implementation
//##############################################################################
procedure TSampleThread3.Execute;
begin
GLOBAL_INI:=myconf.Create;
maillog_path:=GLOBAL_INI.SYSTEM_GET_SYSLOG_PATH();
artica_path:=GLOBAL_INI.get_ARTICA_PHP_PATH();
logs:=tlogs.Create;

  logs.Debuglogs('wthread3:[' + IntToStr(tid)+']: Start');

  while not Terminated do begin

    if DirectoryExists('/usr/local/ap-mailfilter3/log') then begin
       filter_log();
    end;
    logs.Debuglogs('wthread3:[' + IntToStr(tid)+']: Sleeping 30 seconds');
    __sleep(30);
  end;

  logs.Debuglogs('wthread3:[' + IntToStr(tid)+']: end');
end;

//##############################################################################
constructor TSampleThread3.Create(startSuspended: boolean);
begin
  inherited Create(startSuspended);
  tid:=ThreadID;
  memread:=TiniFile.Create('/etc/artica-postfix/tail.kas3.conf');
  
  
end;
//##############################################################################
procedure TSampleThread3.filter_log();
var
   old_filesize:integer;
   old_lines:integer;
   fileSize:integer;
   FileLines:integer;
   i:Integer;
   maillog_path:string;
   l:TstringList;
begin


 maillog_path:='/usr/local/ap-mailfilter3/log/filter.log';
 if not FileExists('/usr/local/ap-mailfilter3/log/filter.log') then begin
  logs.Debuglogs('wthread3:[' + IntToStr(tid)+']: /usr/local/ap-mailfilter3/log/filter.log doesn''t exists');
  exit;
 end;

old_filesize:=memread.ReadInteger('TMP','maillogsize',0);
old_lines:=memread.ReadInteger('TMP','mailloglines',0);
fileSize:=GetFileBytes('/usr/local/ap-mailfilter3/log/filter.log');



logs.Debuglogs('wthread3:[' + IntToStr(tid)+']: -> ' +maillog_path + ' old_filesize=' + intToStr(old_filesize) + ',old_lines=' + intToStr(old_lines) + '('+intToStr(fileSize) + ' bytes)');

if fileSize<old_filesize then begin
    logs.Debuglogs('wthread3:[' + IntToStr(tid)+']: filter_log() :: -> ' +maillog_path + '-> purge');
     old_filesize:=0;
     old_lines:=0;
end;

if old_filesize=fileSize then exit;

   logs.Debuglogs('wthread3:[' + IntToStr(tid)+']: filter_log() :: -> ' + maillog_path + '-> analyze (fileSize='+ IntToStr(fileSize)+' bytes)');
   l:=TstringList.Create;
   l.LoadFromFile(maillog_path);
   FileLines:=l.count-1;

   if old_lines<l.Count-1 then begin
         for i:=old_lines to  FileLines do begin
             ParseLine(l.Strings[i]);
         end;

   end;


   memread.WriteInteger('TMP','mailloglines',FileLines);
   memread.WriteInteger('TMP','maillogsize',fileSize);
   l.free;

//S 25-04-08 17:55:37 [filter-module[4265]] KASSTATS  AAP00010A900004811FEF9: group="00000000" spam_status=spam size=181 method="headers plus" relay_ip=127.0.0.1 from=<toto@titi.com> to=<david.touzeau@klf.fr>

end;

//##############################################################################
procedure TSampleThread3.ParseLine(line:string);
var
   RegExpr:TRegExpr;
   month,day,year,time,service,text,newdate,msg_id,relay_ip,from,sto,spam_stat:string;
   domainf:string;
   domaint:string;
   mysql:Tartica_mysql;
   sql_command:string;
   l:TstringList;
begin
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^S\s+([0-9]+)-([0-9]+)-([0-9]+)\s+([0-9\:]).+?KASSTATS\s+(.+?):.+spam_status=(formal|probable_spam|spam).+?relay_ip=(.+?)\s+from=<(.+?)>\s+to=<(.+?)>';

  if not RegExpr.Exec(line) then exit;
        logs.Debuglogs('wthread3:[' + IntToStr(tid)+']: ParseLine() :: -> ' +line );
        month:=RegExpr.Match[2];
        day:=RegExpr.Match[1];
        time:=RegExpr.Match[4];
        msg_id:=RegExpr.Match[5];
        spam_stat:=RegExpr.Match[6];
        relay_ip:=RegExpr.Match[7];
        from:=RegExpr.Match[8];
        sto:=RegExpr.Match[9];
     RegExpr.Expression:='.+?@(.+)';
     if RegExpr.Exec(from) then domainf:=RegExpr.Match[1];
     if RegExpr.Exec(sto) then domaint:=RegExpr.Match[1];

     mysql:=Tartica_mysql.Create;
     year:=LOGS.getyear();
     sql_command:='INSERT INTO `artica_events`.`spam_events` ( `msgid`,`zDate`,`mailfrom`,`rcpt_to`,`filter`,`ipfrom`,`mailfrom_domain`,`rcpt_to_domain`,`spam_level`)';
     sql_command:=sql_command + ' VALUES("' + msg_id + '","'+year+'-'+month+'-'+day+' '+time+'",';
     sql_command:=sql_command + '"' + from + '","' + sto +'","1","' + relay_ip+'","'+ domainf+'","'+ domaint + '","'+ spam_stat+'");';
     logs.Debuglogs('wthread3:[' + IntToStr(tid)+']: ParseLine() :: '+ from + ' ' + time + '('+spam_stat +')');
     if not mysql.QUERY_SQL(pChar(sql_command),'artica_events') then begin
         l:=TstringList.Create;
         l.Add(sql_command);
         l.SaveToFile('/opt/artica/mysql/artica-queue/' + LOGS.MD5FromString(sql_command));
         l.Free;
     end;

     
end;
//##############################################################################


function TSampleThread3.GetFileBytes(path:string):longint;
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


