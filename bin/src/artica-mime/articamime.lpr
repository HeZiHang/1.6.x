program articamime;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes,logs,TmimeDecode,RegExpr in 'RegExpr.pas',unix,ldap;
  
  
var
   MIME:ArticamimeDecode;
   mLDAP:Tldap;


procedure help();
begin
writeln('Methods -----------------------------------');
writeln('parse [file]...............................: Decode a file');
writeln('parse [file] output........................: Output SMTP Infos from [File]');
writeln('send [uid] [file] (keep|delete)............: Send a mail [file] to LDAP [uid] and delete or keep it');
writeln('lasttenQuarFiles [uid].....................: Get a list of last 10 quaratine mails for UID');
writeln('queryfiles [uid] [PATTERN].................: Get a list of mails files that match [PATTERN] for [uid] quanrantine area');
writeln('DeleteMails [uid] [PATTERN]................: DeleteMails  mails files that match [PATTERN] for [uid] quanrantine area');
writeln('emptyarea [uid]............................: Delete all quarantines mails files  for [uid]');
writeln('ou-black [ou] [DOMAIN].....................: Detect if domain is black listed for the entire organization');
writeln('ou-config [ou].............................: Get ou security rules');
writeln('notif [file path]..........................: Send HTML notification from defined xml file');
writeln('releasemailmd5 [md5].......................: release a mail stored in quarantine by md5 value');
writeln('releaseallmailfrommd5 [md5]................: release all mails stored in quarantine by Sender define in an md5 mail ');




end;



begin


if ParamCount>0 then begin
      if ParamStr(1)='parse' then begin
          MIME:=ArticamimeDecode.Create;
          MIME.ParseFile(ParamStr(2));
          halt(0);
      end;



 if ParamStr(1)='--sendmail' then begin
       MIME:=ArticamimeDecode.Create;
       MIME.SendHTMLMail();
       halt(0);
 end;
      
      

      
      if ParamStr(1)='send' then begin
            MIME:=ArticamimeDecode.Create;
           if not MIME.ReleaseMail(ParamStr(3),ParamStr(2),ParamStr(4)) then begin
              writeln('{failed}');
              writeln(MIME.lasterror);
           end else begin
              writeln('{success}');
              writeln(MIME.lasterror);
           end;
         halt(0);
      end;
      
      if ParamStr(1)='lasttenQuarFiles' then begin
         MIME:=ArticamimeDecode.Create;
         MIME.QUARANTINE_LAST_TEN_QUEUE(ParamStr(2),'');
         halt(0);
      end;
      
      
      if ParamStr(1)='queryfiles' then begin
         MIME:=ArticamimeDecode.Create;
         Writeln('Query files that match ' + ParamStr(3) + ' for ' +ParamStr(2));
         MIME.FILTER_QUARANTINE(ParamStr(2),ParamStr(3));
         halt(0);
      end;

      if ParamStr(1)='listMails' then begin
         MIME:=ArticamimeDecode.Create;
         MIME.QUARANTINE_DECODE_LIST(ParamStr(2));
         halt(0);
      end;
      
      if ParamStr(1)='ou-black' then begin
         mLDAP:=Tldap.Create();
         if mldap.IsOuDomainBlackListed(ParamStr(2),ParamStr(3)) then writeln(ParamStr(3) + ' is blacklisted');
         halt(0);
      end;
      

      if ParamStr(1)='email' then begin
         mLDAP:=Tldap.Create();
        writeln(mldap.eMailFromUid(ParamStr(2)));
         halt(0);
      end;
      
      if ParamStr(1)='ou-config' then begin
         mLDAP:=Tldap.Create();
         writeln('faked sender address...............:',mLDAP.FackedSenderParameters(ParamStr(2)));
         writeln('Anti-spam rules....................:',mldap.LoadOUASRules(ParamStr(2)));
         halt(0);
      end;
      
      
      

      
      if ParamStr(1)='test' then Shell('/bin/egrep -r -l -f /tmp/regex.pattern --line-buffered /var/quarantines/procmail/david.touzeau/new>/tmp/a');
      
      help();
      halt(0);

end;




end.

