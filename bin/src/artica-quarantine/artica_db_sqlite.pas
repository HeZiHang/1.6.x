unit artica_db_sqlite;

{$LONGSTRINGS ON}
{$mode objfpc}{$H+}
interface

uses
Classes, SysUtils,variants, IniFiles,oldlinux,strutils,md5,logs,RegExpr in 'RegExpr.pas',global_conf in 'global_conf.pas',db,sqlite3ds;

type

  ServFailedInfo= record //shared data between component, listen thread and handler
    zMD5:String;
    DOMAIN:string;
    MX:string;
    MX_IP:string;
    COUNT_TIME:integer;
    MESSAGE_ID:string;
  end;

 type
  artica_sqlite=class


private
     GLOBAL_INI:MyConf;
     LOGS:Tlogs;
     procedure Create_database_server_timeout();
     DatabasePath:string;
     dsTest:TSqlite3Dataset;
     D:boolean;
    function MD5FromString(values:string):string;
    procedure add_new_server(info:ServFailedInfo);
    Function TableExists(tablename:string):boolean;
    procedure UpgradeDatabaseRBL();
public
    procedure Free;
    constructor Create;
    function GetServerInfos(servername:string):string;
    Function TableExistsG(tablename:string;FileName:string):boolean;
    procedure MAILLOG_SCAN_FAILED_SERRVERS();
    procedure Dump_ServersFailed();
    procedure LIB_VERSION();
    procedure CREATE_table_messages();
    function IfChampsMessagesExists(champ:string):boolean;
    procedure UpgradeTableMessages();
    procedure CreateDatabaseRBL();
END;

implementation

constructor artica_sqlite.Create;

begin
       forcedirectories('/etc/artica-postfix');
       GLOBAL_INI:=MyConf.Create();
       LOGS:=tlogs.Create();
       DatabasePath:='/usr/share/artica-postfix/LocalDatabases/artica_database.db';
       if ParamStr(2)='in' then DatabasePath:=ParamStr(3);
       ForceDirectories(ExtractFilePath(DatabasePath));


       dsTest:=TSqlite3Dataset.Create(nil);
       dsTest.FileName:=DatabasePath;
       TRY
       if ParamStr(1)='-install' then begin
          Create_database_server_timeout();
          Create_table_messages();
          Shell('/bin/chmod 755 ' + ExtractFilePath(DatabasePath));
          shell('/bin/chown artica:root ' + DatabasePath);
       end;
       EXCEPT;
       end;
       
       if FileExists(DatabasePath) then begin
          shell('/bin/chmod 666 /usr/share/artica-postfix/LocalDatabases/*');
          shell('/bin/chown -R artica:root /usr/share/artica-postfix/LocalDatabases');
       end;
       
end;

PROCEDURE artica_sqlite.Free();
begin
GLOBAL_INI.Free;
LOGS.Free;
dsTest.Destroy;
//get_LINUX_MAILLOG_PATH
end;

//##############################################################################
procedure artica_sqlite.Create_database_server_timeout();
var sql:string;
begin

sql:='CREATE TABLE server_timeout (id AUTOINC_INT , domain VARCHAR , md5 VARCHAR , mx VARCHAR , mx_ip VARCHAR , delay INTEGER , messageid VARCHAR)';
dsTest.QuickQuery(sql);
dsTest.QuickQuery('CREATE INDEX domain ON messages(domain)');
dsTest.QuickQuery('CREATE INDEX mx ON messages(mx)');
dsTest.QuickQuery('CREATE INDEX mx_ip ON messages(mx_ip)');
LOGS.logs('artica-db::Create_database_server_timeout:: ' + dsTest.SqliteReturnString);


end;
//##############################################################################
procedure artica_sqlite.CreateDatabaseRBL();
var
   sql:string;
   db:TSqlite3Dataset;
begin
       if FileExists('/usr/share/artica-postfix/LocalDatabases/rbl_database.db') then begin
          UpgradeDatabaseRBL();
          exit;
       end;
       writeln('Create rbl_database.db in background mode...');
       db:=TSqlite3Dataset.Create(nil);
       db.FileName:='/usr/share/artica-postfix/LocalDatabases/rbl_database.db';
       sql:='CREATE TABLE rbl (id AUTOINC_INT , service VARCHAR , mx VARCHAR , result INTEGER,zDate datetime)';
       db.QuickQuery(sql);
       db.QuickQuery('CREATE INDEX service ON rbl(service)');
       db.QuickQuery('CREATE INDEX mx ON rbl(mx)');
       db.QuickQuery('CREATE INDEX zDate ON rbl(zDate)');
       db.Close;
       UpgradeDatabaseRBL();
end;
//##############################################################################
procedure artica_sqlite.UpgradeDatabaseRBL();
var
   sql:string;
   db:TSqlite3Dataset;
begin
 db:=TSqlite3Dataset.Create(nil);
  if not TableExistsG('uribl','/usr/share/artica-postfix/LocalDatabases/rbl_database.db') then begin
        writeln('Create uribl in background mode...');
        db.FileName:='/usr/share/artica-postfix/LocalDatabases/rbl_database.db';
        sql:='CREATE TABLE uribl (id AUTOINC_INT , uribl_service VARCHAR , uribl_mx VARCHAR , uribl_result INTEGER,uribl_zDate datetime)';
        db.QuickQuery(sql);
        db.QuickQuery('CREATE INDEX uribl_service ON uribl(uribl_service)');
        db.QuickQuery('CREATE INDEX uribl_mx ON uribl(uribl_mx)');
        db.QuickQuery('CREATE INDEX uribl_zDate ON uribl(uribl_zDate)');
        db.Close;
  end;

db.Free;
end;
//##############################################################################


procedure artica_sqlite.Create_table_messages();
var
   sql:string;
   txtcmd:string;

begin

  
  if TableExists('messages') then exit;
  

  
  sql:='CREATE TABLE messages (ID INTEGER PRIMARY KEY,MessageID VARCHAR ,mail_from VARCHAR ,mailfrom_domain VARCHAR ,';
  sql:=sql + 'mail_to VARCHAR ,ou VARCHAR ,subject VARCHAR ,filter_action VARCHAR ,zDate datetime ,received_date datetime ,MailSize INTEGER ,';
  sql:=sql+'SpamRate INTEGER ,message_path VARCHAR ,backupType INTEGER ,Deleted INTEGER ,SpamInfos VARCHAR ,quarantine INTEGER)';
  dsTest.QuickQuery(sql);
  LOGS.logs('artica-db::Create_table_messages:: ' + dsTest.SqliteReturnString);

   dsTest.QuickQuery('CREATE INDEX mail_from ON messages(mail_from)');
   dsTest.QuickQuery('CREATE INDEX mailfrom_domain ON messages(mailfrom_domain)');
   dsTest.QuickQuery('CREATE INDEX mail_to ON messages(mail_to)');
   dsTest.QuickQuery('CREATE INDEX ou ON messages(ou)');
   dsTest.QuickQuery('CREATE INDEX filter_action ON messages(filter_action)');
   dsTest.QuickQuery('CREATE INDEX zDate ON messages(zDate)');
   dsTest.QuickQuery('CREATE INDEX received_date ON messages(received_date)');
   dstest.Close;
end;
//##############################################################################

function artica_sqlite.IfChampsMessagesExists(champ:string):boolean;
var
   i:integer;
   sField:string;
begin
  result:=false;
  champ:=Uppercase(champ);
 dsTest.SQL:='PRAGMA table_info(messages)';
 dsTest.Open;
 dsTest.First;
    while not dsTest.EOF do begin
        sField:=dsTest.Fields[1].AsString;
        sField:=Uppercase(sField);
        if sField=champ then result:=true;
     dsTest.Next;
     end;
end;
//##############################################################################
procedure artica_sqlite.UpgradeTableMessages();
var
   sql:string;
   txtcmd:string;
   DB:TSqlite3Dataset;
begin
     DB:=TSqlite3Dataset.Create(nil);
     DB.FileName:=DatabasePath;

    if not IfChampsMessagesExists('GeoISP') then begin
       writeln('Upgrading SQLite Database in background for GeoISP');
       DB.QuickQuery('ALTER TABLE messages ADD GeoISP VARCHAR');
       DB.QuickQuery('CREATE INDEX GeoISP ON messages(GeoISP)');
    end;
    
    if not IfChampsMessagesExists('GeoCountry') then begin
       writeln('Upgrading SQLite Database in background for GeoCountry');
       DB.QuickQuery('ALTER TABLE messages ADD GeoCountry VARCHAR');
       DB.QuickQuery('CREATE INDEX GeoCountry ON messages(GeoCountry)');
    end;
    
    if not IfChampsMessagesExists('GeoCity') then begin
       writeln('Upgrading SQLite Database in background for GeoCity');
       DB.QuickQuery('ALTER TABLE messages ADD GeoCity VARCHAR');
       DB.QuickQuery('CREATE INDEX GeoCity ON messages(GeoCity)');
    end;
    
    if not IfChampsMessagesExists('GeoTCPIP') then begin
       writeln('Upgrading SQLite Database in background for GeoTCPIP');
       DB.QuickQuery('ALTER TABLE messages ADD GeoTCPIP VARCHAR');
       DB.QuickQuery('CREATE INDEX GeoTCPIP ON messages(GeoTCPIP)');
    end;
    
    if not IfChampsMessagesExists('uid') then begin
       writeln('Upgrading SQLite Database in background for uid');
       DB.QuickQuery('ALTER TABLE messages ADD uid VARCHAR');
       DB.QuickQuery('CREATE INDEX uid ON messages(uid)');
    end;
    
    if not IfChampsMessagesExists('zMD5') then begin
       writeln('Upgrading SQLite Database in background for zMD5');
       DB.QuickQuery('ALTER TABLE messages ADD zMD5 VARCHAR');
       DB.QuickQuery('CREATE INDEX zMD5 ON messages(zMD5)');
    end;
    
    if not IfChampsMessagesExists('dspam_result') then begin
       writeln('Upgrading SQLite Database in background for dspam_result');
       DB.QuickQuery('ALTER TABLE messages ADD dspam_result VARCHAR');
       DB.QuickQuery('CREATE INDEX dspam_result ON messages(dspam_result)');
    end;

    if not IfChampsMessagesExists('dspam_class') then begin
       writeln('Upgrading SQLite Database in background for dspam_class');
       DB.QuickQuery('ALTER TABLE messages ADD dspam_class VARCHAR');
       DB.QuickQuery('CREATE INDEX dspam_class ON messages(dspam_class)');
    end;
    
    if not IfChampsMessagesExists('dspam_probability') then begin
       writeln('Upgrading SQLite Database in background for dspam_probability');
       DB.QuickQuery('ALTER TABLE messages ADD dspam_probability VARCHAR');
       DB.QuickQuery('CREATE INDEX dspam_probability ON messages(dspam_probability)');
    end;

    if not IfChampsMessagesExists('dspam_confidence') then begin
       writeln('Upgrading SQLite Database in background for dspam_confidence');
       DB.QuickQuery('ALTER TABLE messages ADD dspam_confidence VARCHAR');
       DB.QuickQuery('CREATE INDEX dspam_confidence ON messages(dspam_confidence)');
    end;

    if not IfChampsMessagesExists('dspam_signature') then begin
       writeln('Upgrading SQLite Database in background for dspam_signature');
       DB.QuickQuery('ALTER TABLE messages ADD dspam_signature VARCHAR');
       DB.QuickQuery('CREATE INDEX dspam_signature ON messages(dspam_signature)');
    end;

DB.Close;
DB.free;
end;

//##############################################################################

procedure artica_sqlite.Dump_ServersFailed();
var i:integer;
begin
dsTest.SQL:='SELECT _ROWID_,* FROM server_timeout ORDER BY delay DESC';
 dsTest.Open;

     dsTest.First;
     while not dsTest.EOF do begin
          writeln(dsTest.FieldByName('_ROWID_').AsString + ' ' +dsTest.FieldByName('md5').AsString + ' ' +  dsTest.FieldByName('domain').AsString + ' ' + dsTest.FieldByName('mx').AsString + ' ' + dsTest.FieldByName('mx_ip').AsString + ' ' + dsTest.FieldByName('delay').AsString);
          dsTest.Next;
     end;
end;
//##############################################################################
procedure artica_sqlite.LIB_VERSION();
var i:integer;
begin
writeln(dsTest.SqliteVersion);
end;
//##############################################################################
Function artica_sqlite.TableExists(tablename:string):boolean;
begin
  result:=false;
  dsTest.Sql:='Select name,sql From sqlite_master where type="table"';
  TRY
  dsTest.Open;
  if dsTest.RecordCount>0 then begin
  dsTest.First;
   while not dsTest.EOF do begin
       if dsTest.FieldByName('name').AsString=tablename then begin
           result:=true;
           break
       end;
     dsTest.Next;
   end;
   end;
  FINALLY
    dsTest.Close;
  end;
  
end;
//##############################################################################
Function artica_sqlite.TableExistsG(tablename:string;FileName:string):boolean;
   var
   sql:string;
   db:TSqlite3Dataset;

begin
  if ParamStr(1)='-iftable' then D:=true;
  result:=false;
  db:=TSqlite3Dataset.Create(nil);
  if D then writeln('OPEN: ',FileName);
  db.FileName:=FileName;
  db.Sql:='Select name,sql From sqlite_master where type="table"';
  TRY
  if D then writeln('OPEN: DATABASE');
  db.Open;
  if D then writeln('OPENED: entries number:',db.RecordCount);
  if db.RecordCount>0 then begin
  db.First;
   while not db.EOF do begin
       if db.FieldByName('name').AsString=tablename then begin
           result:=true;
           break;
       end;
     db.Next;
   end;
   end;
  FINALLY
    db.Close;
    db.free;
  end;

end;
//##############################################################################
procedure artica_sqlite.add_new_server(info:ServFailedInfo);
var
   SQL:string;
   id:integer;
   i:integer;
   
begin


     SQL:='SELECT _ROWID_,id,Delay FROM server_timeout WHERE md5="' + info.zMD5 + '"';
     dsTest.Sql:=SQL;
     dsTest.Open;


     if dsTest.RecordCount>0 then begin
         dsTest.First;
         id:=dsTest.FieldByName('_ROWID_').AsInteger;
         if dsTest.FieldByName('Delay').AsInteger>info.COUNT_TIME then begin
             dsTest.Close;
             exit;
         end;

         dsTest.Close;
         SQL:='UPDATE server_timeout SET Delay=' + IntToStr(info.COUNT_TIME) + ' WHERE _ROWID_=+ ' +IntToStr(id);

         dsTest.QuickQuery(SQL);
         dsTest.Close;
         exit;
     end;
     
     dsTest.Close;
     dsTest.QuickQuery('INSERT INTO server_timeout (domain,md5,mx,mx_ip,delay,messageid) VALUES  ("' + info.DOMAIN+'","' + info.zMD5+'","' + info.MX + '","' + info.MX_IP + '","' + IntToStr(info.COUNT_TIME) + '","' + info.MESSAGE_ID + '")');
     writeln('Last sqlite return: ',dsTest.SqliteReturnString);
     exit;


   writeln('Database:',DatabasePath);

  // dsTest.Sql:= 'SELECT _ROWID_,* FROM server_timeout';
//   dsTest.QuickQuery('INSERT INTO server_timeout VALUES("1","1","' + servername + '")');
   writeln('Last sqlite return: ',dsTest.SqliteReturnString);
   exit;
   writeln('Last sqlite opened');
   WriteLn('RecordCount: ',dsTest.RecordCount);
   dsTest.Append;
   dsTest.FieldByName('index').AsInteger:=100;
   dsTest.FieldByName('Count').AsInteger:=1;
//   dsTest.FieldByName('servername').AsString:=servername;
   dsTest.Post;
   dsTest.ApplyUpdates;
   writeln('Last sqlite return: ',dsTest.SqliteReturnString);
   dsTest.Close;
end;
//##############################################################################
function artica_sqlite.GetServerInfos(servername:string):string;
begin
    dsTest.Sql:= 'SELECT _ROWID_,* FROM server_timeout WHERE servername="' + servername + '"';
    dsTest.open;
    WriteLn('RecordCount: ',dsTest.RecordCount);
end;
//##############################################################################




//##############################################################################
function artica_sqlite.MD5FromString(values:string):string;
var StACrypt,StCrypt:String;
Digest:TMD5Digest;
begin
Digest:=MD5String(values);
exit(MD5Print(Digest));
end;
//####################################################################################
procedure artica_sqlite.MAILLOG_SCAN_FAILED_SERRVERS();
var
  maillog_path:string;
  FILE_DATA:TStringList;
  RegExpr:TRegExpr;
  i:integer;
  zMD5:string;
  info:ServFailedInfo;
  info_tp:string;
begin
   maillog_path:=GLOBAL_INI.get_LINUX_MAILLOG_PATH();
   if not FileExists(maillog_path) then begin
       LOGS.logs('artica-db::Unable to stat ' + maillog_path);
       exit;
   end;
  RegExpr:=TRegExpr.Create;
  RegExpr.Expression:='postfix/smtp\[[0-9]+\]:\s+([A-Z0-9]+): to=<.+@(.+?)>, relay=none, delay=([0-9]+), delays=.+status=deferred \(connect to (.+?)\[([0-9\.]+)\]: Connection timed out\)';
  FILE_DATA:=TstringList.Create;
  FILE_DATA.LoadFromFile(maillog_path);
  For i:=0 to FILE_DATA.Count-1 do begin

      if RegExpr.Exec(FILE_DATA.Strings[i]) then begin


         info.MESSAGE_ID:=RegExpr.Match[1];
         info.DOMAIN:=RegExpr.Match[2];
         info.COUNT_TIME:=strToInt(RegExpr.Match[3]);
         info.MX:=RegExpr.Match[4];
         info.MX_IP:=RegExpr.Match[5];
         info_tp:=info.DOMAIN + info.MX+info.MX_IP;
         info.zMD5:=MD5FromString(info_tp);
         
         add_new_server(info);
      end;
  
  end;

end;



end.

