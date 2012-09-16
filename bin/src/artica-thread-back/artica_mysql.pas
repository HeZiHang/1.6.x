unit artica_mysql;

{$mode objfpc}{$H+}
{$LONGSTRINGS ON}


interface

uses
       Classes, SysUtils,variants,IniFiles,unix,
       RegExpr in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/RegExpr.pas',
       mysql4,
       logs in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/logs.pas';


type
  Tartica_mysql=class
  
private
     function Connect():boolean;
    qmysql:TMYSQL;
    qbuf : string [160];
     GLOBAL_INI:TIniFile;
     LOGS:Tlogs;
     sock:PMYSQL;
     mquery : string;
     alloc : PMYSQL;

public
    constructor Create;
     procedure Free;
    
    Connected:boolean;
    TooManyConnections:boolean;
    function GetAsSQLText(MessageToTranslate:string) : string;
    function GetServerStatus: String;
    FUNCTION QUERY_SQL(sql:Pchar;database:string):boolean;
    FHostInfo: String;
    FServerInfo: String;
    recbuf : PMYSQL_RES;
    rowbuf : MYSQL_ROW;
    FUNCTION STORE_SQL(sql:string;database:string):boolean;
    FUNCTION STORE_SQL_SINGLE(sql:string;database:string):string;
    procedure CheckAnAndRepairTable(error:string);
end;

implementation

//-------------------------------------------------------------------------------------------------------


//##############################################################################
constructor Tartica_mysql.Create;
begin
       forcedirectories('/etc/artica-postfix');
       LOGS:=Tlogs.Create;
       TooManyConnections:=false;
       Connected:=Connect();
end;
//##############################################################################
PROCEDURE Tartica_mysql.Free();
begin
try
mysql_close(alloc);
except
logs.Debuglogs('Failed mysql_close');
end;

end;
//##############################################################################
function Tartica_mysql.Connect():boolean;
var
   root     :string;
   password :string;
   port     :string;
   server   :string;
   error    :string;
   RegExpr  :TRegExpr;
begin
  port    :=logs.MYSQL_INFOS('port');
  server  :=logs.MYSQL_INFOS('mysql_server');
  root    :=logs.MYSQL_INFOS('database_admin');

   if length(port)=0 then port:='3306';
   if length(server)=0 then server:='127.0.0.1';
   if length(root)=0 then root:='root';
   if server='*' then server:='127.0.0.1';

  root    :=root+#0;
  password:=logs.MYSQL_INFOS('database_password') +#0;
  port    :=port+#0;
  server  :=server+#0;
  alloc   :=mysql_init(PMYSQL(@qmysql));
  sock    :=mysql_real_connect(alloc, PChar(@server[1]), PChar(@root[1]), PChar(@password[1]), nil, StrtoInt(port), Nil,0);

//              mysql_real_connect(mysql:PMYSQL; host:Pchar; user:Pchar; passwd:Pchar; db:Pchar;port:dword; unix_socket:Pchar; clientflag:dword):
  if sock=Nil then
    begin
      logs.Debuglogs('Connect():: Couldn''t connect to MySQL.');
      error:=StrPas(mysql_error(@qmysql));
      logs.Debuglogs('Connect():: Error was: '+ error);
      RegExpr:=TRegExpr.Create;
      RegExpr.Expression:='Too many connections';
      if RegExpr.Exec(error) then TooManyConnections:=true;
      exit(false);
   end;
   //logs.Debuglogs('GetServerStatus -> ' + GetServerStatus());
  exit(true);

end;
//##############################################################################
function Tartica_mysql.GetAsSQLText(MessageToTranslate:string) : string;
var
  escaped: pchar;
  slen: longword;
  res: longword;
  newlen: longword;
begin
  result:= '';
  slen:= length(MessageToTranslate);
  newlen:=(slen*2) + 1;
  getmem(escaped, newlen); // allocate worst case scenario
  res:= mysql_real_escape_string(sock, escaped,  pchar(MessageToTranslate), slen);
  if res > newlen then logs.Debuglogs('GetAsSQLText():: Allocated pchar in mysqlEscape too small');
  result:= string(escaped); // makes copy of pchar
  freemem(escaped);
end;

//##############################################################################
function Tartica_mysql.GetServerStatus: String;
begin

  Result := mysql_stat(alloc);
end;
//#############################################################################
FUNCTION Tartica_mysql.STORE_SQL(sql:string;database:string):boolean;
begin
  result:=false;
  if not QUERY_SQL(PChar(sql),database) then exit(false);
  recbuf := mysql_store_result(sock);
  
  if RecBuf=Nil then begin
     LOGS.Debuglogs('STORE_SQL:: recbuf returned nil result.');
     exit;
  end;
  
  rowbuf := mysql_fetch_row(recbuf);
  exit(true);
end;
//#############################################################################
FUNCTION Tartica_mysql.STORE_SQL_SINGLE(sql:string;database:string):string;
begin
if STORE_SQL(sql,database) then begin
            TRY
              result:=rowbuf[0];
           EXCEPT
           LOGS.Debuglogs('STORE_SQL_SINGLE:: error while query "' + sql + '"')
           end;
end;
end;
//#############################################################################
FUNCTION Tartica_mysql.QUERY_SQL(sql:Pchar;database:string):boolean;
var
   sql_results:longint;
   db:Pchar;
   RegExpr     :TRegExpr;
   error:string;
begin

    RegExpr:=TRegExpr.Create;
if not Connected then begin
   if not Connect() then begin
        LOGS.Debuglogs('QUERY_SQL:: error while connecting');
        exit;
   end;
end;

 if length(trim(database))>0 then begin

    db:=PChar(database+#0);
    sql_results:=mysql_select_db(sock,db);


    if sql_results=1 then begin
       error:=mysql_error(sock);

       RegExpr.Expression:='Unknown database';
        if RegExpr.Exec(error) then begin

           LOGS.Debuglogs('QUERY_SQL:: mysql_select_db:: '+ mysql_error(sock) + ' EXEC -> ' + ExtractFilePath(ParamStr(0)) + 'artica-install --mysql-reconfigure-db');
           if ParamStr(1)='--mysql-reconfigure-db' then  exit(false);
           fpsystem(ExtractFilePath(ParamStr(0)) + 'artica-install --mysql-reconfigure-db');
           exit(false);
        end;

        RegExpr.Expression:='already exists';
        if RegExpr.Exec(error) then exit(true);


        LOGS.Debuglogs('QUERY_SQL:: mysql_select_db::  mysql_select_db->error number : ' + IntToStr(sql_results));
        LOGS.Debuglogs('QUERY_SQL:: mysql_select_db:: '+ mysql_error(sock));
        exit(false);
    end;

end;





     sql_results:=mysql_query(alloc, sql);
     if sql_results=1 then begin



      error:=mysql_error(sock);
        RegExpr.Expression:='Duplicate entry';
        if RegExpr.Exec(error) then begin
           LOGS.Debuglogs('QUERY_SQL:: ASSUME TRUE FOR ::' + error);
           exit(true);
        end;

        RegExpr.Expression:='already exists';
        if RegExpr.Exec(error) then begin
           LOGS.Debuglogs('QUERY_SQL:: ASSUME TRUE FOR ::' + error);
           exit(true);
        end;

        RegExpr.Expression:='Duplicate key name';
        if RegExpr.Exec(error) then begin
           LOGS.Debuglogs('QUERY_SQL:: ASSUME TRUE FOR ::' + error);
           exit(true);
        end;

        LOGS.Debuglogs('QUERY_SQL:: mysql_query:: mysql_query error number: ' + IntToStr(sql_results));
        LOGS.Debuglogs('QUERY_SQL:: mysql_query:: mysql_query query.......: '+sql);
        error:=mysql_error(sock);
        LOGS.Debuglogs('QUERY_SQL:: mysql_query:: Error returned..........: '+ mysql_error(sock));
        CheckAnAndRepairTable(error);
        exit(false);
     end;

 RegExpr.free;
 exit(true);
end;
//#############################################################################
procedure Tartica_mysql.CheckAnAndRepairTable(error:string);
var
   RegExpr     :TRegExpr;
   table_Path:string;
   dir:string;
begin
  RegExpr:=TRegExpr.Create;
  RegExpr.Expression:='Table\s+(.+?)\s+is marked as crashed and should be repaired';
  if not RegExpr.Exec(error) then begin
     RegExpr.free;
     exit;
  end;

  fpsystem('/usr/share/artica-postfix/bin/artica-backup --repair-database');
end;
//#############################################################################






end.



