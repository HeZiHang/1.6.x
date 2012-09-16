unit MessageStorages;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,Process,logs,articaldap,artica_mysql,RegExpr,zsystem;
type

  mailrecord=record
        mailfrom:string;
        mailto:TstringList;
        MailToListString:string;
        subject:string;
        messageID:string;
        MessageDate:string;
        OriginalMessage:TstringList;
        HtmlMessage:string;
        message_path:string;
        TargetServer:string;
        TargetPort:string;
        header:string;
        NoHtmlTransform:integer;

  end;


  type
  tMessageStorages=class


private
     LOGS          :Tlogs;
     ldap          :Tarticaldap;
     SYS           :Tsystem;
     mysql         :Tartica_mysql;
     attachmentdir :string;
     fullmessagesdir:string;
     attachmenturl:string;
     TooManyConnections:boolean;



public
    procedure   Free;
    constructor Create();
    function SaveQuarantineToMysql(msg:mailrecord):boolean;
    function SaveArchiveToMysql(msg:mailrecord):boolean;
END;

implementation
//##############################################################################
constructor tMessageStorages.Create();
var
   i:integer;
   s:string;
begin

       LOGS:=tlogs.Create();
       SYS:=Tsystem.Create;
       ldap:=Tarticaldap.Create;
       attachmentdir:='/opt/artica/share/www/attachments';
       fullmessagesdir:='/opt/artica/share/www/original_messages';
       attachmenturl:='images.listener.php?mailattach=';

end;
//##############################################################################
procedure tMessageStorages.free();
begin
    logs.Free;
    SYS.Free;
    ldap.free;
end;
//##############################################################################
function tMessageStorages.SaveQuarantineToMysql(msg:mailrecord):boolean;
var
   mssql:Tartica_mysql;
   subject:string;
   html:string;
   mailfrom:string;
   sql:string;
   f:users_datas;
   Organization:string;
   recipient_domain:string;
   MessageID,FullMessage_path:string;
   mailfrom_domain:string;
   i:integer;
   RegExpr:TRegExpr;
   GetFileBytes:string;
   MessageID_logs:string;
   header:string;
   MailtoString:string;
   MessageIDRandom:string;
   MessageUniquePath:string;
begin

    mssql:=Tartica_mysql.Create;
    if not mssql.Connected then begin
        logs.Syslogs('Fatal error while connecting to mysql server');
        if mssql.TooManyConnections then begin
            logs.Syslogs('Too Many connections on mysql halt process');
            halt(0);
        end;

        exit(false);
    end;
    f:=ldap.UserDataFromMail(msg.mailfrom);
    result:=false;
    subject:=mssql.GetAsSQLText(msg.subject);
    html:=mssql.GetAsSQLText(msg.HtmlMessage);
    mailfrom:=mssql.GetAsSQLText(msg.mailfrom);
    MessageID:=mssql.GetAsSQLText(msg.messageID);
    Organization:=f.Organization;
    FullMessage_path:=fullmessagesdir+'/quarantines/sources/'+logs.MD5FromString(msg.messageID+msg.message_path)+'.eml';
    header:=mssql.GetAsSQLText(msg.header);
    MessageID_logs:=msg.messageID;
    MessageID_logs:=AnsiReplaceText(MessageID_logs,'%','-');
    MessageIDRandom:=logs.MD5FromString(msg.messageID+logs.DateTimeNowSQL());
    forcedirectories(fullmessagesdir+'/quarantines/sources');

    try

       msg.OriginalMessage.SaveToFile(FullMessage_path);
    except
          logs.Syslogs('Fatal error while writing file ' + FullMessage_path);
          exit;
    end;


    for i:=0 to msg.mailto.Count-1 do begin
        MessageUniquePath:=fullmessagesdir+'/quarantines/' + msg.mailto.Strings[i]+'/' + MessageIDRandom;

        try
        forceDirectories(MessageUniquePath);
        except
         logs.Syslogs('Unable to create directory '+MessageUniquePath);
         exit;
        end;
        logs.WriteToFile(msg.HtmlMessage,MessageUniquePath+'/message.html');
        logs.WriteToFile(FullMessage_path,MessageUniquePath+'/original');
    end;




RegExpr:=TRegExpr.Create;
RegExpr.Expression:='(.+?)@(.+)';
if RegExpr.Exec(msg.mailfrom) then mailfrom_domain:=RegExpr.Match[2];

for i:=0 to msg.mailto.Count-1 do begin
    MailtoString:=MailtoString+' ' +msg.mailto.Strings[i];
end;

GetFileBytes:=IntToStr(logs.GetFileBytes(FullMessage_path));
sql:='INSERT INTO quarantine (MessageID,zDate,mailfrom,mailfrom_domain,subject,MessageBody,organization,header,mailto) ';
sql:=sql+'VALUES ("'+ MessageID+'","'+msg.MessageDate+'","'+mailfrom+'","'+mailfrom_domain+'","'+subject+'","'+ html+'","'+Organization+'","'+header+'","'+MailtoString+'")';

    logs.Debuglogs('SaveQuarantineToMysql: Launch query 1');
    if not mssql.QUERY_SQL(pChar(sql),'artica_backup') then begin
         logs.Syslogs('warning Unable to backup ' + MessageID_logs + ' message in quarantine table, mysql error, try later time');
         exit(false);
    end;

    logs.Debuglogs('SaveQuarantineToMysql: Launch query 2');
    sql:='INSERT INTO orgmails (MessageID,message_path,MessageSize) VALUES("'+ MessageID+'","'+FullMessage_path+'","'+GetFileBytes+'")';
    if not mssql.QUERY_SQL(pChar(sql),'artica_backup') then begin
         logs.Syslogs('warning Unable to quarantine ' + MessageID_logs + ' message in orgmails table, mysql error, try later time');
         exit(false);
    end;



    for i:=0 to msg.mailto.Count-1 do begin
         RegExpr.Expression:='(.+?)@(.+)';
         if RegExpr.Exec(msg.mailto.Strings[i]) then recipient_domain:=RegExpr.Match[2];

         sql:='INSERT INTO storage_recipients (MessageID,recipient,recipient_domain) VALUES("'+ MessageID+'","'+msg.mailto.Strings[i]+'","'+recipient_domain+'")';
             logs.Debuglogs('SaveQuarantineToMysql: Launch query 3-' + IntToStr(i) + ' For: "' + msg.mailto.Strings[i]+'"');
         if not mssql.QUERY_SQL(pChar(sql),'artica_backup') then begin
            logs.Syslogs('warning Unable to quarantine ' + MessageID_logs + ' to=<' + msg.mailto.Strings[i] + '> message in storage_recipients table, mysql error, try later time');
            exit(false);
         end;


         logs.Syslogs(MessageID_logs + ': from=<' +msg.mailfrom+'>, to=<'+msg.mailto.Strings[i]+'>, original-size='+GetFileBytes+ ', html-size='+IntToStr(length(msg.HtmlMessage))+' bytes, status=quarantine_success');

    end;

  logs.Debuglogs('SaveQuarantineToMysql: Success...');

 mssql.free;
 RegExpr.free;
 msg.OriginalMessage.Free;
 msg.mailto.Free;
 exit(true);

end;
//##############################################################################
function tMessageStorages.SaveArchiveToMysql(msg:mailrecord):boolean;
var
   mssql:Tartica_mysql;
   subject:string;
   html:string;
   mailfrom:string;
   sql:string;
   f:users_datas;
   Organization:string;
   recipient_domain:string;
   MessageID,FullMessage_path:string;
   i:integer;
   RegExpr:TRegExpr;
   GetFileBytes:string;
   MessageID_logs:string;
   MessageIDRandom:string;
   MessageUniquePath:string;
begin

    mssql:=Tartica_mysql.Create;

        if not mssql.Connected then begin
            TooManyConnections:=true;
            logs.Syslogs('warning Unable to backup Unable to connect to Mysql server');
        end;


        if not fileExists(msg.message_path) then begin
           logs.Syslogs('Unable to stat '+msg.message_path);
           exit;
        end;

    f:=ldap.UserDataFromMail(msg.mailfrom);
    result:=false;
    subject:=mssql.GetAsSQLText(msg.subject);
    html:=mssql.GetAsSQLText(msg.HtmlMessage);
    mailfrom:=mssql.GetAsSQLText(msg.mailfrom);
    MessageID:=mssql.GetAsSQLText(msg.messageID);
    Organization:=f.Organization;
    FullMessage_path:=fullmessagesdir+'/backup/sources/'+logs.MD5FromString(msg.messageID+msg.message_path)+'.eml';
    forceDirectories(fullmessagesdir+'/backup/sources');
    MessageID_logs:=msg.messageID;
    MessageID_logs:=AnsiReplaceText(MessageID_logs,'%','-');
    MessageIDRandom:=logs.MD5FromString(msg.messageID+logs.DateTimeNowSQL());


    for i:=0 to msg.mailto.Count-1 do begin
        MessageUniquePath:=fullmessagesdir+'/backup/' + msg.mailto.Strings[i]+'/' + MessageIDRandom;
        try
        forceDirectories(MessageUniquePath);
        except
         logs.Syslogs('Unable to create directory '+MessageUniquePath);
         exit;
         break;
        end;

        logs.WriteToFile(msg.HtmlMessage,MessageUniquePath+'/message.html');
        logs.WriteToFile(FullMessage_path,MessageUniquePath+'/original');

    end;


    try

       msg.OriginalMessage.SaveToFile(FullMessage_path);
   except
          logs.Syslogs('Fatal error while writing file ' + FullMessage_path);
          exit;
   end;


GetFileBytes:=IntToStr(logs.GetFileBytes(FullMessage_path));
sql:='INSERT INTO storage (MessageID,zDate,mailfrom,subject,MessageBody,organization) ';
sql:=sql+'VALUES ("'+ MessageID+'","'+msg.MessageDate+'","'+mailfrom+'","'+subject+'","'+ html+'","'+Organization+'")';


    if not mssql.QUERY_SQL(pChar(sql),'artica_backup') then begin
         logs.Syslogs('warning Unable to backup ' + MessageID_logs + ' message in storage table, mysql error, try later time');
         exit(false);
    end;


    sql:='INSERT INTO orgmails (MessageID,message_path,MessageSize) VALUES("'+ MessageID+'","'+FullMessage_path+'","'+GetFileBytes+'")';
    if not mssql.QUERY_SQL(pChar(sql),'artica_backup') then begin
         logs.Syslogs('warning Unable to backup ' + MessageID_logs + ' message in orgmails table, mysql error, try later time');
         exit(false);
    end;


    RegExpr:=TRegExpr.Create;
    for i:=0 to msg.mailto.Count-1 do begin
         RegExpr.Expression:='(.+?)@(.+)';
         if RegExpr.Exec(msg.mailto.Strings[i]) then recipient_domain:=RegExpr.Match[2];

         sql:='INSERT INTO storage_recipients (MessageID,recipient,recipient_domain) VALUES("'+ MessageID+'","'+msg.mailto.Strings[i]+'","'+recipient_domain+'")';
         if not mssql.QUERY_SQL(pChar(sql),'artica_backup') then begin
            logs.Syslogs('warning Unable to backup ' + MessageID_logs + ' to=<' + msg.mailto.Strings[i] + '> message in storage_recipients table, mysql error, try later time');
            exit(false);
         end;


         logs.Syslogs(MessageID_logs + ': from=<' +msg.mailfrom+'>, to=<'+msg.mailto.Strings[i]+'>, original-size='+GetFileBytes+ ', html-size='+IntToStr(length(msg.HtmlMessage))+' bytes, status=backup_success');

    end;
 mssql.free;
 RegExpr.free;
 msg.OriginalMessage.Free;
 msg.mailto.Free;
 exit(true);

end;
//##############################################################################


end.
