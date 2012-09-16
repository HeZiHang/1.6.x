unit danslogs;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes,SysUtils,variants,strutils,IniFiles, Process,logs,unix,RegExpr in 'RegExpr.pas',zsystem,mysql4;

  type
  thooksyslog=class


private
     LOGS:Tlogs;
     SYS:TSystem;
     artica_path:string;
     qmysql : TMYSQL;
     rowbuf : MYSQL_ROW;
     recbuf : PMYSQL_RES;
     alloc : PMYSQL;
     database:string;
     procedure StartListener();
     procedure ParseLine(line:string);
     mail:Tstringlist;
     procedure AddMailFROM(mailid:string;mailfrom:string;size:string;time_connect:string);
     EnableMysqlFeatures:integer;
     procedure ADDFile(uri:string;client:string;status:string;log:string;rule:string);
     debug:boolean;
public
    procedure   Free;
    constructor Create;





END;

implementation

constructor thooksyslog.Create;
begin
       forcedirectories('/etc/artica-postfix');
       forcedirectories('/opt/artica/tmp');
       LOGS:=tlogs.Create();
       SYS:=Tsystem.Create;
       debug:=false;
       if paramstr(1)='--verbose' then debug:=true;
       if not TryStrToInt(SYS.GET_INFO('EnableMysqlFeatures'),EnableMysqlFeatures) then EnableMysqlFeatures:=1;

       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;
      database:='artica_events';




      StartListener();
      mail:=Tstringlist.Create;
end;
//##############################################################################
procedure thooksyslog.free();
begin
    logs.Free;
    SYS.Free;


end;
//##############################################################################
procedure thooksyslog.StartListener();
var
 st: text;
 s: string;
begin

 assign(st,'');
 reset(st);
 while not eof(st) do begin // <<<<<<<<--- iterate while not en of file
   readln(st,s); //<<< read only a line
   ParseLine(s);
 end;
 close(st); // <<<<<---
end;
//##############################################################################
procedure thooksyslog.ParseLine(line:string);
var
   RegExpr:TRegExpr;
   RegExpr2:TRegExpr;
   month:string;
   year:string;
   day:string;
   time:string;
   sqltime:string;
   bounce_error:string;
begin


    year:=FormatDateTime('yyyy', Now);
    RegExpr:=TRegExpr.Create;
    RegExpr2:=TRegExpr.Create;
    RegExpr.Expression:='.+?\s+-\s+(.+?)\s+(.+?)\s+CONNECT';

    if RegExpr.Exec(line) then begin

        ADDFile(RegExpr.Match[2],RegExpr.Match[1],'OK','','');
        RegExpr.Free;
        exit;
    end;


    RegExpr.Expression:='.+?\s+-\s+(.+?)\s+(.+?)\s+\*SCANNED\*';
    if RegExpr.Exec(line) then begin

        ADDFile(RegExpr.Match[2],RegExpr.Match[1],'SCANNED','','');
        RegExpr.Free;
        exit;
    end;


    RegExpr.Expression:='.+?\s+-\s+(.+?)\s+(.+?)\s+\*INFECTED\*(.+?)\s+GET.+?html\s+(.+?)-';
    if RegExpr.Exec(line) then begin

        ADDFile(RegExpr.Match[2],RegExpr.Match[1],'SCANNED',RegExpr.Match[3],trim(RegExpr.Match[4]));
        RegExpr.Free;
        exit;
    end;

  RegExpr.Expression:='.+?\s+-\s+(.+?)\s+(.+?)\s+\*EXCEPTION\*(.+?)\s+GET.+?-(.+?)-';
  if RegExpr.Exec(line) then begin

        ADDFile(RegExpr.Match[2],RegExpr.Match[1],'EXCEPTION',RegExpr.Match[3],trim(RegExpr.Match[4]));
        RegExpr.Free;
        exit;
    end;

  RegExpr.Expression:='.+?\s+-\s+(.+?)\s+(.+?)\s+\*DENIED\*(.+?)\s+GET\s+[0-9]+\s+[0-9]+\s+.+?\s+.+?\s+.+?\s+.+?\s+(.+?)-';
  if RegExpr.Exec(line) then begin

        ADDFile(RegExpr.Match[2],RegExpr.Match[1],'DENIED',RegExpr.Match[3],trim(RegExpr.Match[4]));
        RegExpr.Free;
        exit;
    end;


    RegExpr.Expression:='.+?\s+-\s+(.+?)\s+(.+?)\s+GET';
    if RegExpr.Exec(line) then begin
        ADDFile(RegExpr.Match[2],RegExpr.Match[1],'OK','','');
        RegExpr.Free;
        exit;
    end;

    RegExpr.Expression:='.+?\s+-\s+(.+?)\s+(.+?)\s+POST\s+[0-9]+\s+[0-9]+\s+[0-9]+\s+[0-9]+\s+.+?\s+(.+?)-';
    if RegExpr.Exec(line) then begin
       ADDFile(RegExpr.Match[2],RegExpr.Match[1],'OK','','');
       RegExpr.Free;
       exit;
    end;



    RegExpr.free;
    logs.Debuglogs('failed !=>"'+line+'"');

end;
//##############################################################################
procedure thooksyslog.ADDFile(uri:string;client:string;status:string;log:string;rule:string);
var
 RegExpr:TRegExpr;
 server:string;
 sql:string;
 zdate:string;
 zmd5:string;

begin
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:=':\/\/(.+?)\/';
   if RegExpr.exec(uri) then begin
       server:=RegExpr.Match[1];
       server:=trim(server);
   end;

   if length(server)=0 then begin
        RegExpr.Expression:=':\/\/(.+?):';
        if RegExpr.exec(uri) then server:=RegExpr.Match[1];
        server:=trim(server);
   end;

   if length(server)=0 then begin
        RegExpr.Expression:=':\/\/(.+)';
        if RegExpr.exec(uri) then server:=RegExpr.Match[1];
        server:=trim(server);
   end;

   if length(server)<2 then begin
      logs.Debuglogs('failed !! the web server name is less than 2 caracters !!! "' +uri+'"');
      exit;
   end;


   sql:='INSERT INTO dansguardian_sites (website_md5,website) VALUES ("'+logs.MD5FromString(server)+'","'+ server+'")';
   logs.QUERY_SQL(pchar(sql),'artica_events');


   sql:='INSERT INTO dansguardian_uris (uri_MD5,uri,site_md5) VALUES("'+ logs.MD5FromString(uri) +'","'+uri+'","'+ logs.MD5FromString(server)+'")';
   logs.QUERY_SQL(pchar(sql),'artica_events');

   zdate:=logs.DateTimeNowSQL();
   zmd5:=logs.MD5FromString(uri+client+status+log+rule+zdate);
   sql:='INSERT INTO dansguardian_events (sitename,uri,TYPE,REASON,CLIENT,zDate,zMD5) VALUES("'+ logs.MD5FromString(server) +'","'+uri+'","'+status+'","'+log+'","'+client+'","'+zdate+'","'+zmd5+'")';
   logs.QUERY_SQL(pchar(sql),'artica_events');
   logs.Disconnect();
   logs.Debuglogs('['+client+'] '+status+' '+server);



end;
//##############################################################################


procedure thooksyslog.AddMailFROM(mailid:string;mailfrom:string;size:string;time_connect:string);
var
sql:string;
id:integer;
RegExpr:TRegExpr;
begin

     if EnableMysqlFeatures=0 then begin
       logs.Debuglogs('thooksyslog.AddMailFROM:: EnableMysqlFeatures=0' );
       exit;
    end;

//    id:=ID_FROM_MAILID(mailid);
    if id=0 then begin
      // AddMailID(mailid,time_connect);
//       id:=ID_FROM_MAILID(mailid);
       if id=0 then exit;
    end;
    mailfrom:=logs.GetAsSQLText(mailfrom);
    if debug then writeln('new mailfrom:' + mailfrom + ' id='+intToStr(id));

    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='(.+?)\@(.+)';
    RegExpr.Exec(mailfrom);
    sql:='UPDATE smtp_logs SET sender_user="'+RegExpr.Match[1]+'", sender_domain="'+RegExpr.Match[2]+'", bytes="'+size+'"  WHERE id='+intToStr(id);
             if debug then writeln(sql);
    logs.QUERY_SQL(pchar(sql),'artica_events');





end;



end.
