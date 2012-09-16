unit TmimeDecode;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
Classes, SysUtils,variants,IniFiles,RegExpr in 'RegExpr.pas',mimemess,mimepart,ldap,smtpsend,oldlinux,Process,logs,strutils,md5;

  type
  ArticamimeDecode=class


private
     GLOBAL_INI:TIniFile;
     QUEUE_DIRECTORY:string;

     function COMMANDLINE_PARAMETERS(FoundWhatPattern:string):boolean;
     function FULL_COMMANDLINE_PARAMETERS():string ;
     function ExecStream(commandline:string):TMemoryStream;
     function DecodeSubPart(SubPart:TMimePart):string;
     function FileSizeKo(path:string):string;
     function FileSizeNum(path:string):integer;
     function MessageDateForMysql(MDate:string;stime:string;twice:boolean):string;
     function MYSQL_ACTION_QUERY(sql:string;database:string):boolean;
     function MD5FromString(values:string):string;
     function ParsePart2(SubPart:TMimePart):boolean;
     function ArticaFilterQueuePath():string;
     D:boolean;
     Mime: TMimemess;
public
    constructor Create;
    procedure Free;
    function ParseFile(path:string):string;
    function ReleaseMail(path:string;uid:string;action_keep:string):boolean;
    function QUARANTINE_LAST_TEN_QUEUE(uid:string;mode:string):string;
    function FILTER_QUARANTINE(uid:string;regex:string):string;
    function QUARANTINE_DECODE_LIST(filepath:string):string;
    function DeleteMails(TargetListFile:string):boolean;
    lasterror:string;
    ARRAY_RESULT:TstringList;

end;

implementation

//-------------------------------------------------------------------------------------------------------


//##############################################################################
constructor ArticamimeDecode.Create;

begin
       forcedirectories('/etc/artica-postfix');
       Mime:=TMimemess.Create;
       ARRAY_RESULT:=TstringList.Create;
        D:=COMMANDLINE_PARAMETERS('debug');
end;
//##############################################################################
PROCEDURE ArticamimeDecode.Free();
begin
    Mime.Free;
end;
//##############################################################################
function ArticamimeDecode.ArticaFilterQueuePath():string;
var ini:TIniFile;
begin
 ini:=TIniFile.Create('/etc/artica-postfix/artica-filter.conf');
 result:=ini.ReadString('INFOS','QueuePath','');
 if length(trim(result))=0 then result:='/usr/share/artica-filter';
end;
//##############################################################################

function ArticamimeDecode.ParseFile(path:string):string;
      var
        RegExpr:TRegExpr;

        n:integer;
        o:integer;
        s:string;
        MESSSAGE_TEXT:Tstringlist;
        HTML_FOUND:Boolean;
        ASRESULTS:TstringList;
BEGIN


     if D then writeln('DEBUG MODE is on');
     if not FileExists(path) then begin
         writeln('Unable to locate ' + path);
         exit;
     end;
     RegExpr:=TRegExpr.Create;
     Mime.Clear;
     Mime.Lines.LoadFromFile(path);
     Mime.DecodeMessage;
     MESSSAGE_TEXT:=Tstringlist.Create;
     HTML_FOUND:=false;
     if D then writeln('Subject..............:' , mime.Header.Subject);
     if D then writeln('Sub Part Count.........:' , mime.MessagePart.GetSubPartCount);

     s:=format('%-30s',[mime.MessagePart.primary+'/'+mime.MessagePart.secondary]);
     s:=lowercase(s);
     if D then writeln('First part.............:' , s);
     if not ParsePart2(mime.MessagePart) then begin
          DecodeSubPart(mime.MessagePart);
     
     end;
END;
//##############################################################################
function ArticamimeDecode.ParsePart2(SubPart:TMimePart):boolean;
var
   o:integer;
   s:string;
   HTML_FOUND:boolean;

begin
     HTML_FOUND:=false;
     result:=false;
     SubPart.DecodePart;
     if D then writeln('ParsePart2: Subpart:' +intToStr(SubPart.GetSubPartCount));

     for o:=0 to SubPart.GetSubPartCount-1 do begin
                s:=format('%-30s',[SubPart.GetSubPart(o).primary+'/'+SubPart.GetSubPart(o).secondary]);
                s:=lowercase(s);
                if D then writeln('ParsePart2: Content-type(' + intToStr(o)+'):' +s);

                if  trim(s)='text/html' then begin
                      DecodeSubPart(SubPart.GetSubPart(o));
                      HTML_FOUND:=true;
                      result:=true;
                      break;
                end;
;
                if trim(s)='text/plain' then begin
                   if HTML_FOUND=false then begin
                       DecodeSubPart(SubPart.GetSubPart(o));
                       result:=true;
                       break
                   end;
                end;

              if trim(s)='text/rfc822-headers' then begin
                if HTML_FOUND=false then begin
                   DecodeSubPart(SubPart.GetSubPart(o));
                   result:=true;
                   break
                end;
              end;
              
              if trim(s)='multipart/alternative' then begin
                if HTML_FOUND=false then begin
                   result:=ParsePart2(SubPart.GetSubPart(o));
                   break
                end;
              end;

              if trim(s)='text/rfc822-headers' then begin
                 if HTML_FOUND=false then begin
                   DecodeSubPart(mime.MessagePart.GetSubPart(o));
                   result:=true;
                   break
                end;
              end;

              if trim(s)='multipart/alternative' then begin
                 result:=ParsePart2(mime.MessagePart.GetSubPart(o));
                 break;
              end;

              if trim(s)='multipart/related' then begin
                 result:=ParsePart2(mime.MessagePart.GetSubPart(o));
                 break;
              end;

              if trim(s)='multipart/mixed' then begin
                 result:=ParsePart2(mime.MessagePart.GetSubPart(o));
                 break;
              end;


    end;

end;
//##############################################################################

function ArticamimeDecode.DecodeSubPart(SubPart:TMimePart):string;
var
   i,temp_count:integer;
   
   s,j:string;
   RegExpr:TRegExpr;
   MESSSAGE_TEXT,HEADERLIST:TstringList;
   BODY:TStream;
   COMMANDS,MailFrom_text,MailFrom_name,OU_NAME:string;
   MailfromParsed:boolean;
   content_type:string;
   MAILTO,MESSAGE_DATE:string;
   ldap:TLdap;
   sql,Subject,message_spam_rate,message_id,backupType,mailfrom_domain,MailSize,SPAM_INFO,HeadFilePath,quarantineStore:string;
   D,ST,A,SQ:boolean;
   LOGS:TLogs;
   DELETE_THE_FILE:boolean;
   
begin
  A:=false;
  SQ:=false;
  if ParamStr(3)='output' then A:=true;
  if ParamStr(3)='sql' then begin
     SQ:=True;
  end;
     
 
    MESSSAGE_TEXT:=Tstringlist.Create;
    BODY:=TStream.Create;
    MailfromParsed:=false;
    RegExpr:=TRegExpr.Create;
    LOGS:=TLogs.Create;
    ldap:=Tldap.Create;
    COMMANDS:=FULL_COMMANDLINE_PARAMETERS();
    DELETE_THE_FILE:=false;
    
    ST:=false;
    D:=COMMANDLINE_PARAMETERS('debug');


           SubPart.TargetCharset:=SubPart.CharsetCode;
           content_type:=format('%-30s',[SubPart.primary+'/'+SubPart.secondary]);
           content_type:=trim(lowercase(content_type));
           if D then writeln('CONTENT-TYPE: ' + content_type);
           SubPart.DecodePart;
           SubPart.DecodedLines.SaveToFile('/tmp/messages.tmp');
           if D then writeln('DecodeSubPart load /tmp/messages.tmp (1)');
           MESSSAGE_TEXT.LoadFromFile('/tmp/messages.tmp');


   for i:=0 to mime.Lines.Count-1 do begin
        if not ST then if length(trim(mime.Lines.Strings[i]))=0 then ST:=true;
        if ST then MESSSAGE_TEXT.Add(mime.Lines.Strings[i]);
   end;

        
   if D then writeln('208) content_type='+ content_type);
    
   if content_type='text/plain' then begin
       RegExpr.Expression:='<(body|BODY)>(.+?)</(body|BODY)>';
       if not RegExpr.exec(MESSSAGE_TEXT.Text) then begin
          for i:= 0 to MESSSAGE_TEXT.Count-1 do begin
               MESSSAGE_TEXT.Strings[i]:=AnsiReplaceText(MESSSAGE_TEXT.Strings[i],'>','&gt;');
               MESSSAGE_TEXT.Strings[i]:=AnsiReplaceText(MESSSAGE_TEXT.Strings[i],'<','&lt;');
               MESSSAGE_TEXT.Strings[i]:=AnsiReplaceText(MESSSAGE_TEXT.Strings[i],'"','&quot;');
               MESSSAGE_TEXT.Strings[i]:=MESSSAGE_TEXT.Strings[i] + '<br>';
          end;
       end else begin
               MESSSAGE_TEXT.Clear;
               MESSSAGE_TEXT.Add(RegExpr.Match[2]);
       end;
   end;
    

    if content_type='text/html' then begin
    RegExpr.Expression:='<(body|BODY)>(.+?)</(body|BODY)>';
        if RegExpr.exec(MESSSAGE_TEXT.Text) then begin
            MESSSAGE_TEXT.Clear;
            MESSSAGE_TEXT.Add(RegExpr.Match[2]);
        end;
    end;
    
    
    RegExpr.Expression:='"(.+?)"\s+<(.+?)>';
    if RegExpr.Exec(mime.Header.From) then begin
        MailFrom_text:=RegExpr.Match[2];
        MailFrom_name:=RegExpr.Match[1];
        MailfromParsed:=True;
    end;

       if D then writeln('MailFrom_text='+ MailFrom_text);

    if not MailfromParsed then begin
         RegExpr.Expression:='<(.+?)>';
         if RegExpr.Exec(mime.Header.From) then begin
            MailFrom_text:=RegExpr.Match[1];
            MailFrom_name:='&nbsp;';
            MailfromParsed:=True;
         end;
    end;
    if not MailfromParsed then begin
       MailFrom_text:=mime.Header.From;
       MailFrom_name:='&nbsp;';
    end;
    
    HEADERLIST:=TStringList.Create;
    HEADERLIST.Clear;
    Mime.Header.FindHeaderList('Received',HEADERLIST);
    RegExpr.Expression:='for <(.+)?>';
    if HEADERLIST.Count>0 then if RegExpr.Exec(HEADERLIST.Strings[0]) then MAILTO:=RegExpr.Match[1];
    
    message_date:=MessageDateForMysql(DateToStr(mime.Header.Date),TimeToStr(mime.Header.Date)+':00',false);
    
     if D then writeln('message_date='+ message_date + '(' + DateToStr(mime.Header.Date) +' ' + TimeToStr(mime.Header.Date)+':00)');
    
    message_spam_rate:=Mime.Header.FindHeader('X-SpamTest-Rate');
    if length(message_spam_rate)=0 then message_spam_rate:='0';
    Subject:=Mime.Header.Subject;
    Subject:=AnsiReplaceText(Subject,'''','`');
    Subject:=AnsiReplaceText(Subject,'\','\\');
    Subject:=AnsiReplaceText(Subject,'"','\"');

    
    if D then writeln('Subject='+ Subject);

    message_id:=Mime.Header.MessageID;
    if D then writeln('message_id='+ message_id);
    
    RegExpr.Expression:='(.+?)@(.+)';
    if RegExpr.Exec(MailFrom_text) then begin
          mailfrom_domain:=RegExpr.Match[2];
    end else begin
       mailfrom_domain:='unknown';
    end;
    if D then writeln('mailfrom_domain='+ mailfrom_domain);

    for i:=0 to Mime.Header.ToList.Count-1 do begin
        RegExpr.Expression:='<(.+?)>';
        if RegExpr.Exec(Mime.Header.ToList.Strings[i]) then begin
           if A=true then writeln('To:' + RegExpr.Match[1]);
        end else begin
             if A=true then writeln('To:' + Mime.Header.ToList.Strings[i]);
        
        end;
    end;

    
    if A=true then begin
       writeln('MAIL FROM....: ',MailFrom_text);
       writeln('MAIL TO......: ',MAILTO);
       writeln('Date.........: ',message_date);
       writeln('SPAM RATE....: ',message_spam_rate);
       writeln('MESSAGE ID...: ',message_id);
       writeln('Subject......: ',Subject);
       exit;
    end;

    if SQ then begin
       MailSize:=IntToStr(FileSizeNum(ParamStr(2)));
       if ParamStr(6)='debug' then backupType:='';
       MailFrom_text:=AnsiReplaceText(MailFrom_text,'"','\"');
       mailfrom_domain:=AnsiReplaceText(mailfrom_domain,'"','\"');
       message_id:=AnsiReplaceText(mailfrom_domain,'"','\"');


       HEADERLIST.Clear;
       RegExpr.Expression:='\{(.+?)\}';
       Mime.Header.FindHeaderList('X-SpamTest-Info',HEADERLIST);
       for i:=0 to HEADERLIST.Count-1 do begin
            if RegExpr.exec(HEADERLIST.Strings[i]) then begin
                 SPAM_INFO:=RegExpr.Match[1];
                 break;
            end;
       end;
       
       if length(SPAM_INFO)=0 then SPAM_INFO:='none';
       OU_NAME:=ParamStr(6);
       MAILTO:=ldap.eMailFromUid(ParamStr(5));
       quarantineStore:=ParamStr(7);
       LOGS.LOgs('artica-mime:: quarantineStore:: {' + quarantineStore + '}');
       sql:='INSERT INTO messages (MessageID,mail_from,mailfrom_domain,mail_to,subject,zDate,received_date,SpamRate,message_path,filter_action,ou,MailSize,SpamInfos,quarantine) ';
       sql:=sql + 'VALUES("'+ message_id+'","' + MailFrom_text+'","' + mailfrom_domain+'","' + MAILTO +'","'+Subject+'",';
       sql:=sql + '"'+message_date+'",DATE_FORMAT(NOW(),''%Y-%m-%d %H:%I:%S''),"'+message_spam_rate+'","'+ParamStr(2)+'","' +ParamStr(4)+'","' +OU_NAME+'","' + MailSize + '","' + SPAM_INFO+'","' + quarantineStore + '")';
       LOGS.LOgs('artica-mime:: DecodeSubPart:: {' + sql + '}');
       if D then writeln(sql);
       MYSQL_ACTION_QUERY(sql,'artica_filter');
       exit;
   end;

    
    s:='<input type="hidden" id="spammed_mail_from" value="'+MailFrom_text+'">';
    s:=s+'<center><table style="width:100%;border:1px dotted #CCCCCC;background-color:#DFF9E7">';
    s:=s+'<tr>';
    s:=s+'<td align=right><strong>{date}:</strong></td>';
    s:=s+'<td align=left>'+ message_date + '</td>';
    s:=s+'</tr>';
    s:=s+'<tr>';
    s:=s+'<td align=right><strong>{name}:</strong></td>';
    s:=s+'<td align=left>'+ MailFrom_name + '</td>';
    s:=s+'</tr>';
    s:=s+'<tr>';
    s:=s+'<td align=right><strong>{mail_from}:</strong></td>';
    s:=s+'<td align=left>'+ MailFrom_text + '</td>';
    s:=s+'</tr>';
    s:=s+'<tr>';
    s:=s+'<td align=right><strong>{subject}:</strong></td>';
    s:=s+'<td align=left>'+ Subject + '</td>';
    s:=s+'</tr>';
    s:=s+'</table></center><hr>';
    
    
    j:=j + '<ADDON>';
    j:=j +'<H4>{extra_infos}</H4>';
    j:=j +'<center><table style="width:100%;border:1px dotted #CCCCCC;font-size:12px">';
    j:=j+'<tr>';
    j:=j+'<td align=right><strong>Content-type:</strong></td>';
    j:=j+'<td align=left>' + content_type + '</td>';
    j:=j+'</tr>';
    j:=j+'<tr>';
    j:=j+'<td align=right><strong>{anti_spam_rate}:</strong></td>';
    j:=j+'<td align=left>' + message_spam_rate + '</td>';
    j:=j+'</tr>';
    HEADERLIST.Clear;
    Mime.Header.FindHeaderList('X-SpamTest-Info',HEADERLIST);
    for i:=0 to HEADERLIST.Count -1 do begin
        RegExpr.Expression:='^Profile.+';
        if not RegExpr.Exec(HEADERLIST.Strings[i]) then begin
        HEADERLIST.Strings[i]:=AnsiReplaceText(HEADERLIST.Strings[i],'{','');
        HEADERLIST.Strings[i]:=AnsiReplaceText(HEADERLIST.Strings[i],'}','');
           j:=j+'<tr>';
           j:=j+'<td align=right valign=top><strong>{anti_spam_results}:</strong></td>';
           j:=j+'<td align=left valign=top>' + HEADERLIST.Strings[i] + '</td>';
           j:=j+'</tr>';
        end;
    end;
    

    HEADERLIST.Clear;
    Mime.Header.FindHeaderList('Received',HEADERLIST);
   for i:=0 to HEADERLIST.Count -1 do begin
       RegExpr.Expression:='(from|FROM)\s+([a-zA-Z0-9\.\-\_]+)\s+.+?\[([0-9\.]+)\]';
       if RegExpr.Exec(HEADERLIST.Strings[i]) then begin
        temp_count:=(HEADERLIST.Count-1)-i;
        HEADERLIST.Strings[i]:=AnsiReplaceText(HEADERLIST.Strings[i],'<','');
        HEADERLIST.Strings[i]:=AnsiReplaceText(HEADERLIST.Strings[i],'>','');
        j:=j+'<tr>';
        j:=j+'<td align=right valign=top><strong>{mail_servers_ip} (' + IntToStr(temp_count) + '):</strong></td>';
        j:=j+'<td align=left valign=top>' + RegExpr.Match[2] + ' ' + RegExpr.Match[3] +'</td>';
        j:=j+'</tr>';
        end;
    end;
    

    j:=j+'</table></center></ADDON>';
    
    

    MESSSAGE_TEXT.Insert(0,s);
    MESSSAGE_TEXT.Add(j);
    writeln( MESSSAGE_TEXT.Text);
    
end;
//##############################################################################
function ArticamimeDecode.MessageDateForMysql(MDate:string;stime:string;twice:boolean):string;
var
   i:integer;
   LOGS:TLogs;
   RegExpr:TRegExpr;
   YEAR,MONTH,DAY:string;
   D:boolean;
begin
   RegExpr:=TRegExpr.create;
   RegExpr.Expression:='([0-9]+)-([0-9]+)-([0-9]+)';
   if RegExpr.Exec(MDate) then begin
   if length(RegExpr.Match[3])=2 then YEAR:='20' + RegExpr.Match[3] else YEAR:=RegExpr.Match[3];
   if length(RegExpr.Match[2])=1 then MONTH:='0' + RegExpr.Match[2] else MONTH:=RegExpr.Match[2];
   if length(RegExpr.Match[1])=1 then DAY:='0' + RegExpr.Match[1] else DAY:=RegExpr.Match[1];
    D:=COMMANDLINE_PARAMETERS('debug');
    if D then writeln(YEAR+'-' + MONTH + '-' + DAY + ' ' + stime);
   result:=YEAR+'-' + MONTH + '-' + DAY + ' ' + stime;
   end else begin
         if D then writeln('Failed to parse ([0-9]+)-([0-9+])-([0-9]+) ->"' + MDate + '"');
         MDate:=DateToStr(Date);
         stime:=TimeToStr(Time);
         if twice=false then result:=MessageDateForMysql(MDate,stime,true);
   end;
   
end;



//##############################################################################
function ArticamimeDecode.DeleteMails(TargetListFile:string):boolean;
var
   i:integer;
   LOGS:TLogs;
begin
   logs:=Tlogs.create;

   logs.logs('DeleteMails:: From file pattern ' + TargetListFile);
   ARRAY_RESULT.LoadFromFile(TargetListFile);
   
   for i:=0 to ARRAY_RESULT.Count -1 do begin
       shell('/bin/rm ' +ARRAY_RESULT.Strings[i]);
   end;

   writeln(intToStr(ARRAY_RESULT.Count) + ' {emails_deleted}');


end;
//##############################################################################


//##############################################################################
function ArticamimeDecode.ReleaseMail(path:string;uid:string;action_keep:string):boolean;
var
   ldap:Tldap;
   mail_to:string;
   mail_from:string;
   SMTP:TSMTPSend;
   LIST:TstringList;
   D:boolean;
begin

 if not FileExists(path) then begin
    lasterror:='Unable to stat ' + path;
    exit(false);
 end;
 
 
 result:=false;
 ldap:=Tldap.Create;
 LIST:=TstringList.Create;
 LIST.LoadFromFile(path);
 mail_to:=ldap.eMailFromUid(uid);
 D:=COMMANDLINE_PARAMETERS('debug');

 
 
 if length(mail_to)=0 then exit(false);
     Mime.Clear;
     Mime.Lines.LoadFromFile(path);
     Mime.DecodeMessage;
     mail_from:=mime.Header.From;
     
     
     if D then writeln('ReleaseMail:: to "' + mail_to + '" from "' + mail_from + '"');
 
     SMTP := TSMTPSend.Create;
     SMTP.TargetHost:='127.0.0.1';
     SMTP.TargetPort:='29300';
     if not SMTP.Login then begin
        lasterror:=SMTP.FullResult.Text;
        exit(false);
     end;
     
     if not SMTP.MailFrom(mail_from,Length(LIST.Text)) then begin
       lasterror:=SMTP.FullResult.Text;
       exit(false);
     end;
     
     if not SMTP.MailTo(mail_to) then begin
        lasterror:=SMTP.FullResult.Text;
        exit(false);
     end;
     
     if not SMTP.MailData(LIST) then begin
        lasterror:=SMTP.FullResult.Text;
        exit(false);
     end;
     lasterror:=SMTP.FullResult.Text;
     SMTP.Logout;
     if action_keep='delete' then Shell('/bin/rm ' +path);
     exit(true);
     

end;
//##############################################################################
function ArticamimeDecode.FILTER_QUARANTINE(uid:string;regex:string):string;
var
   FILES:TstringList;
   RegExpr:TRegExpr;
   command_line:string;
   i:integer;
   A:boolean;
   D:Boolean;
   logs:Tlogs;
begin
  D:=COMMANDLINE_PARAMETERS('debug');
  A:=COMMANDLINE_PARAMETERS('queryfiles');
  logs:=Tlogs.create;
  command_line:='/bin/grep -r -l -E "' + regex + '" /var/quarantines/procmail/' + uid + '/new >/tmp/'+uid + '.quarantine.search.list.tmp';
  Shell(command_line);
  if D then begin
     if A then writeln('Output enabled');
     writeln('command line[' + command_line + ']');
  end;
  ARRAY_RESULT.Clear;
  ARRAY_RESULT.LoadFromFile('/tmp/'+uid + '.quarantine.search.list.tmp');
  if ARRAY_RESULT.Count=0 then begin
     logs.logs('FILTER_QUARANTINE:: ' + command_line + ' NO RESULTS');
     if A then writeln('No results');
     exit;
  end;
  if A then writeln(ARRAY_RESULT.Text);
end;
//##############################################################################
function ArticamimeDecode.QUARANTINE_DECODE_LIST(filepath:string):string;
var
   FILES:TstringList;
   RegExpr:TRegExpr;
   Max,i,RealCountFiles:integer;
   Logs:Tlogs;
begin
  FILES:=TstringList.Create;
  RegExpr:=TRegExpr.Create;
  Mime:=TMimeMess.Create;
  Logs:=Tlogs.Create;

  if not FileExists(filepath) then begin
     logs.logs('ArticamimeDecode.QUARANTINE_DECODE_LIST:: unable to stat ' + filepath);
  end;

  
  FILES.LoadFromFile(filepath);
  RealCountFiles:=FILES.Count;
  if (FILES.Count-1)<50 then Max:=FILES.Count-1 else Max:=50;
  logs.logs('ArticamimeDecode.QUARANTINE_DECODE_LIST:: ' + IntTostr(FILES.Count) + ' rows get MAX ' +IntToStr(Max));
   writeln('<COUNT>' + intToStr(RealCountFiles) + '</COUNT>');
TRY
  for i:=0 to Max do begin
      Mime.Lines.LoadFromFile(FILES.Strings[i]);
      Mime.DecodeMessage;
      writeln(FileSizeKo(FILES.Strings[i])+';' + DateToStr(mime.Header.Date)+ ';' +  TimeToStr(mime.Header.Date)+ ';' + ExtractFileName(FILES.Strings[i])+';' + Mime.Header.FindHeader('X-SpamTest-Rate') + ';' + Mime.Header.From + ';"' + Mime.Header.Subject + '"');
  end;
EXCEPT
    logs.logs('ArticamimeDecode.QUARANTINE_DECODE_LIST:: FATAL ERROR !!!');
END;
  logs.free;
  RegExpr.free;


end;

//##############################################################################

//##############################################################################
function ArticamimeDecode.QUARANTINE_LAST_TEN_QUEUE(uid:string;mode:string):string;
var
   FILES:TstringList;
   RegExpr:TRegExpr;
   Max,i,RealCountFiles:integer;
   Logs:Tlogs;
begin
  FILES:=TstringList.Create;
  RegExpr:=TRegExpr.Create;
  Mime:=TMimeMess.Create;
  Logs:=Tlogs.Create;


  FILES.LoadFromStream(ExecStream('/bin/ls -lthA --time-style=full-iso /var/quarantines/procmail/' + uid + '/new'));
  RegExpr.expression  :='[\-rwx]+\s+[0-9]+\s+[a-zA-Z]+\s+[a-zA-Z]+\s+([0-9\.A-Za-z]+)\s+([0-9\-]+)\s+([0-9:]+)\.[0-9]+\s+[0-9\+]+\s+(.+)';

//   -rw-r--r-- 1 root root  50K 2007-09-16 19:52:19.000000000 +0200 SPAM.ffa01f6e6d9fdd4a7aa187fe19067f7d
  RealCountFiles:=FILES.Count;
  if FILES.Count-1<50 then Max:=FILES.Count-1 else Max:=50;
  logs.logs('ArticamimeDecode.QUARANTINE_LAST_TEN_QUEUE:: ' + IntTostr(FILES.Count) + ' rows get MAX ' +IntToStr(Max));
   writeln('<COUNT>' + intToStr(RealCountFiles) + '</COUNT>');
TRY
  for i:=0 to Max do begin
     if RegExpr.Exec(FILES.Strings[i]) then begin
            //logs.logs('ArticamimeDecode.QUARANTINE_LAST_TEN_QUEUE:: Loading ' + RegExpr.Match[4]);
            Mime.Lines.LoadFromFile('/var/quarantines/procmail/' + uid + '/new/' + trim(RegExpr.Match[4]));
            Mime.DecodeMessage;
         //logs.logs('ArticamimeDecode.QUARANTINE_LAST_TEN_QUEUE:: Send line ' + IntToStr(i));
            writeln(RegExpr.Match[1]+ ';' + RegExpr.Match[2] + ';' + RegExpr.Match[3]+ ';' + trim(RegExpr.Match[4]+';' + Mime.Header.FindHeader('X-SpamTest-Rate') + ';' + Mime.Header.From + ';"' + Mime.Header.Subject + '"'));
     end else begin
         logs.logs('ArticamimeDecode.QUARANTINE_LAST_TEN_QUEUE:: unable to regexp line ' + IntToStr(i));
         logs.logs(RegExpr.expression);
         logs.logs(FILES.Strings[i]);
     end;

  end;
EXCEPT
    logs.logs('ArticamimeDecode.QUARANTINE_LAST_TEN_QUEUE:: FATAL ERROR !!!');
END;
  logs.free;
  RegExpr.free;


end;

//##############################################################################
function ArticamimeDecode.ExecStream(commandline:string):TMemoryStream;
const
  READ_BYTES = 2048;
  CR = #$0d;
  LF = #$0a;
  CRLF = CR + LF;

var
  S: TStringList;
  M: TMemoryStream;
  P: TProcess;
  n: LongInt;
  BytesRead: LongInt;
  xRes:string;
  D:boolean;

begin
  D:=COMMANDLINE_PARAMETERS('debug');
  M := TMemoryStream.Create;
  BytesRead := 0;
  P := TProcess.Create(nil);
  P.CommandLine := commandline;
  P.Options := [poUsePipes];
  if D then writeln('ExecStream:: "' + commandline + '"');

  TRY
     P.Execute;
     while P.Running do begin
           M.SetSize(BytesRead + READ_BYTES);
           n := P.Output.Read((M.Memory + BytesRead)^, READ_BYTES);
           if D then writeln('n:: ',n);
           if n > 0 then begin
              Inc(BytesRead, n);
              end else begin
              Sleep(100);
           end;
     end;
  EXCEPT
        P.Free;
        exit;
  end;


  repeat
    M.SetSize(BytesRead + READ_BYTES);
    n := P.Output.Read((M.Memory + BytesRead)^, READ_BYTES);
    if n > 0 then begin
      Inc(BytesRead, n);
    end;
  until n <= 0;
  M.SetSize(BytesRead);
  exit(M);
end;

//##############################################################################
function ArticamimeDecode.COMMANDLINE_PARAMETERS(FoundWhatPattern:string):boolean;
var
   i:integer;
   s:string;
   RegExpr:TRegExpr;

begin
 result:=false;
 s:=FULL_COMMANDLINE_PARAMETERS();
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:=FoundWhatPattern;
   if RegExpr.Exec(s) then begin
      RegExpr.Free;
      result:=True;
   end;


end;
//##############################################################################
function ArticamimeDecode.FULL_COMMANDLINE_PARAMETERS():string ;
var
   i:integer;
   s:string;
   RegExpr:TRegExpr;

begin
 if ParamCount>0 then begin
     for i:=0 to ParamCount do begin
        s:=s  + ' ' +ParamStr(i);
     end;
 end;
  exit(s);


end;
//##############################################################################
function ArticamimeDecode.FileSizeKo(path:string):string;
 Var F : File Of byte;
 Size:longint;
begin
  if not FileExists(path) then exit('OK');
  Try
  Assign (F,path);
  Reset (F);
  Size:=FileSize(F) div 1024;
  Close (F);
  except
  exit();
  end;
  exit(IntToStr(Size) + 'K');
end;
//##############################################################################
function ArticamimeDecode.FileSizeNum(path:string):integer;
 Var F : File Of byte;
 Size:longint;
begin
  if not FileExists(path) then exit(0);
  Try
  Assign (F,path);
  Reset (F);
  result:=FileSize(F);
  Close (F);
  except
  exit();
  end;
end;
//##############################################################################
function ArticamimeDecode.MYSQL_ACTION_QUERY(sql:string;database:string):boolean;
    var root,commandline,password,cmd_result,pass:string;
    i:integer;
    D:boolean;
    RegExpr:TRegExpr;
    found:boolean;
    logs:Tlogs;
    MyRes:TstringList;
    QueuePath:string;
    FileTemp:string;
begin
  D:=COMMANDLINE_PARAMETERS('debug');
  FileTemp:=MD5FromString(sql+database)+'.sql';
  QueuePath:=ArticaFilterQueuePath() +'/sql_queue';
  ForceDirectories(QueuePath);
  MyRes:=TstringList.Create;
  MyRes.Add('<database>'+database + '</database>');
  MyRes.Add('<sqlquery>'+ sql + '</sqlquery>');
  MyRes.SaveToFile(QueuePath + '/'+FileTemp );
  myRes.Free;
end;

//#############################################################################
function ArticamimeDecode.MD5FromString(values:string):string;
var StACrypt,StCrypt:String;
Digest:TMD5Digest;
begin
Digest:=MD5String(values);
exit(MD5Print(Digest));
end;
//##############################################################################



end.
