unit hooksyslog;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes,SysUtils,variants,strutils,IniFiles, Process,logs,unix,RegExpr in 'RegExpr.pas',zsystem,BaseUnix;

  type
  thooksyslog=class


private
     LOGS:Tlogs;
     artica_path:string;
     database:string;
     procedure StartListener();
     procedure ParseLine(line:string);
     mail:Tstringlist;
     procedure AddMailID(mailid:string;time_connect:string);
     procedure Addmsgid(mailid:string;msg_id:string;time_connect:string);
     procedure AddMailFROM(mailid:string;mailfrom:string;size:string;time_connect:string);
     procedure AddMailStatus(mailid:string;mailto:string;status:string;time_connect:string;bounce_error:string);
     procedure AddSPAM(msgid:string;spam_result:string);
     procedure AddFilterReject(mailid:string;reject:string;mailfrom:string;time_connect:string);
     procedure FixAmavis(line:string);
     procedure FixBadCyrusSeen(path:string);
     EnableMysqlFeatures:integer;
     procedure FixMilterGreyList();
     procedure FixCyrusAccount();
     procedure ApplyPostfigConfig(line:string);
     procedure CyrusSocketErrot(line:string;socket:string);
     procedure FixSieveScript(line:string;socket:string);
     procedure EventSMTPHost(line:string;host:string);
     procedure Kas3DatabasesUpdate(line:string);
     procedure CyrusDbError(line:string;filepath:string);
     procedure CyrusRestart(line:string);
     procedure UserUnknown(line:string;mail:string);
     procedure UpdateKasperskyAntivirus(line:string);
     procedure CyrusBadLogin(line:string;user:string);
     procedure KasError(line:string);
     procedure GreyListedLog(mailserver:string;mailfrom:string;mailto:string);
     procedure ReloadAmavis(line:string);
     procedure AddDiscard(postfixid:string;mailfrom:string;mailto:string);
     procedure AddBadContentScanner(postfixid:string;mailfrom:string;mailto:string);
     mypid:string;
     debug:boolean;
     SYS:Tsystem;

public
    procedure   Free;
    constructor Create;





END;

implementation

constructor thooksyslog.Create;
begin
       forcedirectories('/etc/artica-postfix/postfix-logger');
       ForceDirectories('/var/log/artica-postfix/RTM');
       forcedirectories('/opt/artica/tmp');
       LOGS:=tlogs.Create();
       SYS:=Tsystem.Create();
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




      mypid:=IntToStr(fpgetpid);
      StartListener();
      mail:=Tstringlist.Create;
      SYS.Free;
      LOGS.free;
end;
//##############################################################################
procedure thooksyslog.free();
begin

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
   memory:integer;
   label freeexit;
begin
    SYS:=Tsystem.Create;
    memory:=SYS.PROCESS_MEMORY(mypid);
    year:=FormatDateTime('yyyy', Now);
    RegExpr:=TRegExpr.Create;
    RegExpr2:=TRegExpr.Create;
    LOGS:=tlogs.Create();


    RegExpr.Expression:='NOQUEUE.+?milter-reject.?RCPT\s+from\s+(.+).+?451 4.7.1 Greylisting in action, please come back in .+?; from=<(.+?)> to=<(.+?)>\s+proto=SMTP helo';
    if RegExpr.Exec(line) then begin
       GreyListedLog(RegExpr.Match[1],RegExpr.Match[2],RegExpr.Match[3]);
       goto freeexit;
    end;


    RegExpr.Expression:='postfix.+?cleanup.+?:\s+(.+?):\s+milter-reject: END-OF-MESSAGE.+4.6.0 Content scanner malfunction; from=<(.+?)> to=<(.+?)> proto=SMTP';
        if RegExpr.Exec(line) then begin
           AddBadContentScanner(RegExpr.Match[1],RegExpr.Match[2],RegExpr.Match[3]);
           goto freeexit;
        end;

    RegExpr.Expression:='postfix.+?cleanup.+?:\s+(.+?):\s+milter-discard.+?END-OF-MESSAGE.+?DISCARD.+?from=<(.+?)> to=<(.+?)> proto=SMTP';
        if RegExpr.Exec(line) then begin
           AddDiscard(RegExpr.Match[1],RegExpr.Match[2],RegExpr.Match[3]);
           goto freeexit;
        end;


    RegExpr.Expression:='^([A-ZA-z]+)\s+([0-9]+)\s+([0-9\:]+).+?:\s+([A-Z0-9]+):\s+client=(.+)';
    if RegExpr.Exec(line) then begin
       month:=logs.TRANSFORM_DATE_MONTH(RegExpr.Match[1]);
       day:=RegExpr.Match[2];
       time:=RegExpr.Match[3];
       sqltime:=year+'-'+month+'-'+day+' ' + time;
       if debug then writeln('Begin a new mail '+ sqltime+ ' '+ RegExpr.Match[4]);
         AddMailID(RegExpr.Match[4],sqltime);
         goto freeexit;
    end;

    RegExpr.Expression:='^([A-ZA-z]+)\s+([0-9]+)\s+([0-9\:]+).+?:\s+([A-Z0-9]+):\s+message-id=<(.+?)>';
    if RegExpr.Exec(line) then begin
       month:=logs.TRANSFORM_DATE_MONTH(RegExpr.Match[1]);
       day:=RegExpr.Match[2];
       time:=RegExpr.Match[3];
       sqltime:=year+'-'+month+'-'+day+' ' + time;
       Addmsgid(RegExpr.Match[4],RegExpr.Match[5],sqltime);
       goto freeexit;
    end;

    RegExpr.Expression:='^([A-ZA-z]+)\s+([0-9]+)\s+([0-9\:]+).+?:\s+([A-Z0-9]+):\s+from=<(.*?)>, size=([0-9]+)';
    if RegExpr.Exec(line) then begin
       month:=logs.TRANSFORM_DATE_MONTH(RegExpr.Match[1]);
       day:=RegExpr.Match[2];
       time:=RegExpr.Match[3];
       sqltime:=year+'-'+month+'-'+day+' ' + time;
       AddMailFROM(RegExpr.Match[4],RegExpr.Match[5],RegExpr.Match[6],sqltime);
       goto freeexit;
    end;

    RegExpr.Expression:='^([A-ZA-z]+)\s+([0-9]+)\s+([0-9\:]+).+?:\s+([A-Z0-9]+):\s+milter-reject:.+?:(.+?)\s+from=<(.+?)>';
    if RegExpr.Exec(line) then begin
       month:=logs.TRANSFORM_DATE_MONTH(RegExpr.Match[1]);
       day:=RegExpr.Match[2];
       time:=RegExpr.Match[3];
       sqltime:=year+'-'+month+'-'+day+' ' + time;
       AddFilterReject(RegExpr.Match[4],RegExpr.Match[5],RegExpr.Match[6],sqltime);
       goto freeexit;
    end;


    RegExpr.Expression:='^([A-ZA-z]+)\s+([0-9]+)\s+([0-9\:]+).+?:\s+([A-Z0-9]+):\s+to=<(.+?)>,\s+orig_to=<.+?>,\s+relay=(.+?),\s+delay=.+?,\s+delays=.+?,\s+dsn=.+?,\s+status=([a-zA-Z]+)';
    if RegExpr.Exec(line) then begin

       month:=logs.TRANSFORM_DATE_MONTH(RegExpr.Match[1]);
       day:=RegExpr.Match[2];
       time:=RegExpr.Match[3];
       sqltime:=year+'-'+month+'-'+day+' ' + time;
       RegExpr2.Expression:='\s+status=.+?\s+\((.+?)\)';
       if RegExpr2.Exec(line) then  bounce_error:=RegExpr2.Match[1];
       AddMailStatus(RegExpr.Match[4],RegExpr.Match[5],RegExpr.Match[7],sqltime,bounce_error);
       goto freeexit;
    end;

    RegExpr.Expression:='^([A-ZA-z]+)\s+([0-9]+)\s+([0-9\:]+).+?:\s+([A-Z0-9]+):\s+to=<(.+?)>,\s+relay=(.+?),\s+delay=.+?,\s+delays=.+?,\s+dsn=.+?,\s+status=([a-zA-Z]+)';
    if RegExpr.Exec(line) then begin

       month:=logs.TRANSFORM_DATE_MONTH(RegExpr.Match[1]);
       day:=RegExpr.Match[2];
       time:=RegExpr.Match[3];
       sqltime:=year+'-'+month+'-'+day+' ' + time;
       RegExpr2.Expression:='\s+status=.+?\s+\((.+?)\)';
       if RegExpr2.Exec(line) then  bounce_error:=RegExpr2.Match[1];
       AddMailStatus(RegExpr.Match[4],RegExpr.Match[5],RegExpr.Match[7],sqltime,bounce_error);
       goto freeexit;
    end;


    RegExpr.Expression:='.+?spamd:\s+result:\s+([A-Z\.]).+?,mid=<(.+?)>';
    if RegExpr.Exec(line) then begin
       AddSPAM(RegExpr.Match[2],RegExpr.Match[1]);
       goto freeexit;
    end;

    RegExpr.Expression:='amavisd-milter.+?could not connect to amavisd socket.+?\.sock: No such file';
    if RegExpr.Exec(line) then begin
       FixAmavis(line);
         RegExpr.Free;
       exit;
    end;







    RegExpr.Expression:='warning:\s+connect to Milter service.+?milter-greylist.+?No\s+such\s+file\s+or\s+directory';
    if RegExpr.Exec(line) then begin
         FixMilterGreyList();
         goto freeexit;
    end;


    RegExpr.Expression:='warning:\s+connect to Milter service.+?milter-greylist.+?No\s+such\s+file\s+or\s+directory';
    if RegExpr.Exec(line) then begin
         FixMilterGreyList();
        goto freeexit;
    end;

    RegExpr.Expression:='badlogin: localhost \[127\.0\.0\.1\] plaintext cyrus SASL\(-13\): authentication failure: checkpass failed';
    if RegExpr.Exec(line) then begin
         FixCyrusAccount();
         goto freeexit;
    end;

     RegExpr.Expression:='warning.+dict_ldap_lookup.+?RelaisDomainsTable.+Search base.+?not found: 32: No such object';
     if RegExpr.Exec(line) then begin
         ApplyPostfigConfig(line);
        goto freeexit;
    end;

     RegExpr.Expression:='fatal.+?ldap:.+?:\s+table lookup problem';
     if RegExpr.Exec(line) then begin
         ApplyPostfigConfig(line);
        goto freeexit;
    end;






    RegExpr.Expression:='host\s+(.+?)\[.+\] refused to talk to me';
    if RegExpr.Exec(line) then begin
         EventSMTPHost(line,RegExpr.Match[1]);
        goto freeexit;
    end;

RegExpr.Expression:='KASERROR file data\.set\.tgz is corrupted';
if RegExpr.Exec(line) then begin
         Kas3DatabasesUpdate(line);
         goto freeexit;
    end;


RegExpr.Expression:='550\s+User\s+unknown\s+<(.+?)>.+?in reply to RCPT TO command';
    if RegExpr.Exec(line) then begin
         UserUnknown(line,RegExpr.Match[1]);
         goto freeexit;
    end;


RegExpr.Expression:='<(.+?)>.+?Recipient address rejected.+?User unknown';
    if RegExpr.Exec(line) then begin
         UserUnknown(line,RegExpr.Match[1]);
         goto freeexit;
    end;


RegExpr.Expression:='kavmilter.+?WARNING.+?Your AV signatures\s+are\s+older\s+than\s+[0-9]+days';
     if RegExpr.Exec(line) then begin
         UpdateKasperskyAntivirus(line);
         goto freeexit;
    end;


RegExpr.Expression:='badlogin.+?plaintext\s+(.+?)\s+SASL.+?authentication failure.+?checkpass failed';
     if RegExpr.Exec(line) then begin
         CyrusBadLogin(line,trim(RegExpr.Match[1]));
         goto freeexit;
    end;





    logs.Debuglogs('mem:'+IntToStr(memory)+'; Not Filtered :'+line);

    if memory>10000 then begin
        logs.Debuglogs('mem:'+IntToStr(memory)+' exceed max memory size, restart mysqlpost');
        fpsystem('/etc/init.d/artica-postfix restart postfix-logger &');
        halt(0);
    end;


    goto freeexit;




freeexit:
         RegExpr.Free;
         RegExpr2.free;
         SYS.Free;
         LOGS.Free;
         exit;


    //RegExpr.Expression:='.+?spamd:\s+result:\s+([A-Z\.]).+?,mid=<(.+?)>#



end;
//##############################################################################
procedure thooksyslog.KasError(line:string);
var
   stime:string;
   path:string;
   checktime:string;
begin


   checktime:='/etc/artica-postfix/postfix-logger/kaserror.time';

   if FileExists(checktime) then begin
      if SYS.FILE_TIME_BETWEEN_MIN(checktime)<15 then begin
         logs.Syslogs('Kaspersky Antispam report ' + line+', but time stamp ('+checktime+') block perform operations');
         exit;
      end;
   end;
   logs.Debuglogs('KasError():: TAKE ACTION FOR "Kaspersky Antispam :'+line+'"');
   logs.NOTIFICATION('Kaspersky Anti-spam report failure when updating it`s database','Kaspersky report ' +line+' for your information', 'update');
   logs.DeleteFile(checktime);
   logs.WriteToFile('#',checktime);

end;



//##############################################################################
procedure thooksyslog.CyrusBadLogin(line:string;user:string);
var
   stime:string;
   path:string;
   checktime:string;
   RegExpr:TRegExpr;
   count:integer;
begin

   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='cyrus@.+';
   if RegExpr.Exec(user) then begin
      RegExpr.free;
      exit;
   end;
   checktime:='/etc/artica-postfix/postfix-logger/cyrus-badlogin.'+logs.MD5FromString(user)+'.time';


   if FileExists(checktime) then begin
      if not TryStrToInt(logs.ReadFromFile(checktime),count) then count:=0;
      count:=count+1;
      if count<10 then begin
         logs.WriteToFile(IntTostr(count),checktime);
         exit;
      end;

   end;

   logs.Debuglogs('CyrusBadLogin():: TAKE ACTION FOR "'+user+'"');
   logs.NOTIFICATION('User: '+user+' failed to connect 10 times on the mailbox server','This user "'+user+'" have tried to connect 10 times to mailbox server but it failed...(just for information)','mailbox');
   logs.DeleteFile(checktime);
   logs.WriteToFile('0',checktime);

end;

//##############################################################################
procedure thooksyslog.ReloadAmavis(line:string);
var
   stime:string;
   path:string;
   checktime:string;
begin

   checktime:='/etc/artica-postfix/postfix-logger/reload.amavis.time';



   if FileExists(checktime) then begin
      if SYS.FILE_TIME_BETWEEN_MIN(checktime)<15 then begin
         logs.Syslogs('Postfix ' + line+', but time stamp ('+checktime+') block perform operations');
         exit;
      end;
   end;

   logs.Debuglogs('ReloadAmavis():: TAKE ACTION FOR "'+line+'"');
   fpsystem('/usr/share/artica-postfix/bin/artica-install --amavis-reload &');
   logs.NOTIFICATION('WARNING AMAVIS ERROR the daemon will be reloaded','Postfix report "'+line+'" Artica has reloaded the Amavis daemon','system');
   logs.DeleteFile(checktime);
   logs.WriteToFile('0',checktime);

end;

//##############################################################################
procedure thooksyslog.UpdateKasperskyAntivirus(line:string);
var
   stime:string;
   path:string;
   checktime:string;
begin


   checktime:='/etc/artica-postfix/postfix-logger/kaspersky-av-keepup2date.time';

   if FileExists(checktime) then begin
      if SYS.FILE_TIME_BETWEEN_MIN(checktime)<15 then begin
         logs.Syslogs('Kaspersky report ' + line+', but time stamp ('+checktime+') block perform operations');
         exit;
      end;
   end;
   logs.Debuglogs('UserUnknown():: TAKE ACTION FOR "KeepUp2date"');
   logs.NOTIFICATION('Warning older databases pattern file For Kaspersky Antivirus','Artica will launch the update manually','system');
   fpsystem('/opt/kav/5.6/kavmilter/bin/keepup2date &');
   logs.DeleteFile(checktime);
   logs.WriteToFile('#',checktime);

end;
//##############################################################################
procedure thooksyslog.UserUnknown(line:string;mail:string);
var
   stime:string;
   path:string;
   checktime:string;
begin


   checktime:='/etc/artica-postfix/postfix-logger/postfix.user-unkown.'+logs.MD5FromString(mail)+'.time';

   if FileExists(checktime) then begin
      if SYS.FILE_TIME_BETWEEN_MIN(checktime)<15 then begin
         logs.Syslogs('Postfix report ' + line+', but time stamp ('+checktime+') block perform operations');
         exit;
      end;
   end;
   logs.Debuglogs('UserUnknown():: TAKE ACTION FOR "'+mail+'"');
   logs.NOTIFICATION('Warning user unknown "'+mail+'"','postfix claim '+line+' you need to create this user or an user alias for '+ mail,'system');
   logs.DeleteFile(checktime);
   logs.WriteToFile('#',checktime);

end;

//##############################################################################




procedure thooksyslog.Kas3DatabasesUpdate(line:string);
var
   checktime:string;
   addstr:string;
begin

   checktime:='/etc/artica-postfix/postfix-logger/kas3.time';

   if FileExists(checktime) then begin
      if SYS.FILE_TIME_BETWEEN_MIN(checktime)<15 then begin
         logs.Syslogs('Kaspersky Anti-spam has reported failed, but time stamp block perform operations');
         exit;
      end;
   end;

   logs.Debuglogs('TAKE ACTION !!!');


   logs.NOTIFICATION('Warning databases corrupted for Kaspersky Anti-spam','Kas3 claim '+line+' database update will be performed now','system');
   fpsystem('/usr/local/ap-mailfilter3/bin/sfupdates &');
   logs.DeleteFile(checktime);
   logs.WriteToFile('#',checktime);

end;
//##############################################################################
procedure thooksyslog.EventSMTPHost(line:string;host:string);
var
   checktime:string;
   addstr:string;
begin
   if length(SYS.PIDOF('artica-install'))>0 then exit;
   checktime:='/etc/artica-postfix/postfix-logger/postfix.host.'+logs.MD5FromString(host)+'.time';

   if FileExists(checktime) then begin
      if SYS.FILE_TIME_BETWEEN_MIN(checktime)<15 then begin
         logs.Syslogs('postfix has reported failed, but time stamp block perform operations');
         exit;
      end;
   end;

   logs.Debuglogs('TAKE ACTION !!!');


   logs.NOTIFICATION('Warning Postfix could not send messages to '+host,'Postfix claim '+line,'system');
   logs.DeleteFile(checktime);
   logs.WriteToFile('#',checktime);

end;

//##############################################################################

procedure thooksyslog.CyrusRestart(line:string);
var
   checktime:string;
   addstr:string;
begin
   if length(SYS.PIDOF('artica-install'))>0 then exit;
   checktime:='/etc/artica-postfix/postfix-logger/postfix.cyrus.restart.error.time';

   if FileExists(checktime) then begin
      if SYS.FILE_TIME_BETWEEN_MIN(checktime)<15 then begin
         logs.Syslogs('cyrus has reported failed, but time stamp block perform operations');
         exit;
      end;
   end;

logs.NOTIFICATION('Warning cyrus-imapd error ','cyrus claim '+line+' cyrus-imapd will be restarted','system');
fpsystem('/etc/init.d/artica-postfix restart imap &');

   logs.DeleteFile(checktime);
   logs.WriteToFile('#',checktime);

end;

//##############################################################################

//##############################################################################

procedure thooksyslog.ApplyPostfigConfig(line:string);
var
   checktime:string;
begin
   if length(SYS.PIDOF('artica-install'))>0 then exit;
   checktime:='/etc/artica-postfix/postfix-logger/postfix.dict_ldap_lookup.error.time';

   if FileExists(checktime) then begin
      if SYS.FILE_TIME_BETWEEN_MIN(checktime)<15 then begin
         logs.Syslogs('Postfix has reported failed, but time stamp block perform operations');
         exit;
      end;
   end;

      logs.Debuglogs('TAKE ACTION !!!');

   logs.NOTIFICATION('Warning Corrupted Postfix configuration file','Postfix claim '+line+' main.cf is probably corrupted, Artica will try to repair it','system');
   if FileExists('/etc/artica-postfix/postfix-logger/settings/Daemons/PostfixMainCfFile') then begin
      fpsystem('/bin/cp /etc/artica-postfix/postfix-logger/settings/Daemons/PostfixMainCfFile /etc/postfix/main.cf');
      fpsystem('/etc/init.d/artica-postfix restart postfix');
   end;

   logs.DeleteFile(checktime);
   logs.WriteToFile('#',checktime);

end;
//##############################################################################

procedure thooksyslog.FixCyrusAccount();

var checktime:string;
begin
   if length(SYS.PIDOF('artica-install'))>0 then exit;
   checktime:='/etc/artica-postfix/postfix-logger/cyrus-account.error.time';
   if FileExists(checktime) then begin
      if SYS.FILE_TIME_BETWEEN_MIN(checktime)<15 then begin
         logs.Syslogs('cyrus has reported failed, but time stamp block perform operations');
         exit;
      end;
   end;
      logs.Debuglogs('TAKE ACTION !!!');

   fpsystem('/etc/init.d/artica-postfix start daemon &');
   logs.NOTIFICATION('Warning Cyrus claim that saslauthd cannot retreive credentials informations','Artica will try to create a default cyrus account','system');
   SYS.THREAD_COMMAND_SET(SYS.LOCATE_PHP5_BIN()+ ' /usr/share/artica-postfix/exec.check-cyrus-account.php cyrus');

   logs.DeleteFile(checktime);
   logs.WriteToFile('#',checktime);

end;
//##############################################################################

procedure thooksyslog.FixAmavis(line:string);
begin
   if length(SYS.PIDOF('artica-install'))>0 then exit;

   if FileExists('/etc/artica-postfix/postfix-logger/amavisd.error.time') then begin
      if SYS.FILE_TIME_BETWEEN_MIN('/etc/artica-postfix/postfix-logger/amavisd.error.time')<15 then begin
         logs.Syslogs('Amvisd has reported failed, but time stamp block perform operations');
         exit;
      end;
   end;
      logs.Debuglogs('TAKE ACTION !!!');

   fpsystem('/etc/init.d/artica-postfix start daemon &');
   logs.NOTIFICATION('Warning Amavis socket is not available',line+'(Postfix claim that amavis socket is not available, Artica will restart amavis service)','system');
   SYS.THREAD_COMMAND_SET('/etc/init.d/artica-postfix restart amavis');

   logs.DeleteFile('/etc/artica-postfix/postfix-logger/amavisd.error.time');
   logs.WriteToFile('#','/etc/artica-postfix/postfix-logger/amavisd.error.time');

end;
//##############################################################################
procedure thooksyslog.FixMilterGreyList();
var checktime:string;
begin
   checktime:='/etc/artica-postfix/postfix-logger/milter-greylist.error.time';

   if length(SYS.PIDOF('artica-install'))>0 then exit;
   if FileExists(checktime) then begin
      if SYS.FILE_TIME_BETWEEN_MIN(checktime)<15 then begin
         logs.Syslogs('Milter-grey list has reported failed, but time stamp block perform operations');
         exit;
      end;
   end;

      logs.Debuglogs('TAKE ACTION !!!');

   fpsystem('/etc/init.d/artica-postfix start daemon &');
   logs.NOTIFICATION('Warning milter-greylist socket is not available','Postfix claim that milter-greylist socket is not available, Artica will restart milter-greylist service','system');
   SYS.THREAD_COMMAND_SET('/etc/init.d/artica-postfix restart mgreylist');
   fpsystem('/etc/init.d/artica-postfix start daemon');


   logs.DeleteFile(checktime);
   logs.WriteToFile('#',checktime);
end;
//##############################################################################
procedure thooksyslog.AddFilterReject(mailid:string;reject:string;mailfrom:string;time_connect:string);
var
sql:string;
id:integer;
RegExpr:TRegExpr;
ini:TiniFile;
begin
     ini:=TiniFile.Create('/var/log/artica-postfix/RTM/'+mailid+'.msg');
     ini.WriteString('TIME','sender_user',mailfrom);
     ini.WriteString('TIME','delivery_success','no');
     ini.WriteString('TIME','bounce_error',reject);
     ini.free;
     exit;

end;
//##############################################################################
procedure thooksyslog.AddSPAM(msgid:string;spam_result:string);
var
sql:string;
id:integer;
ini:TiniFile;
mailid:string;
begin

if FileExists('/var/log/artica-postfix/RTM/'+msgid+'.id') then begin
   ini:=TiniFile.Create('/var/log/artica-postfix/RTM/'+msgid+'.id');
   mailid:=ini.ReadString('TIME','postfix_id','');
   if length(mailid)=0 then begin
      ini.WriteString('TIME','spam','1');
     ini.WriteString('TIME','bounce_error',spam_result);
      ini.free;
      exit;
   end;
end;


     ini:=TiniFile.Create('/var/log/artica-postfix/RTM/'+mailid+'.msg');
     ini.WriteString('TIME','delivery_success','no');
     ini.WriteString('TIME','bounce_error',spam_result);
     ini.free;
     exit;



end;

//##############################################################################
procedure thooksyslog.AddMailID(mailid:string;time_connect:string);
var
Ini:TiniFile;

begin
     if FileExists('/var/log/artica-postfix/RTM/'+mailid+'.msg') then exit;
     ini:=TiniFile.Create('/var/log/artica-postfix/RTM/'+mailid+'.msg');
     ini.WriteString('TIME','time_start',time_connect);
     ini.UpdateFile;


end;

//##############################################################################
procedure thooksyslog.AddMailStatus(mailid:string;mailto:string;status:string;time_connect:string;bounce_error:string);
var
sql:string;
id:integer;
RegExpr:TRegExpr;
delivery_success:string;
ini:TiniFile;
begin



    RegExpr:=TRegExpr.Create;
    delivery_success:='yes';
    if status='bounced' then delivery_success:='no';
    if status='deferred' then delivery_success:='no';

    if  delivery_success='no' then begin
        logs.Debuglogs('AddMailStatus():: bounce_error="' + bounce_error+'"');
        RegExpr.Expression:='connect to.+?\[(.+?)lmtp\].+?No such file or directory';
        if RegExpr.Exec(bounce_error) then CyrusSocketErrot(bounce_error,RegExpr.Match[1]+'/lmtp');
        RegExpr.Expression:='550\s+User\s+unknown\s+<(.+?)>.+?in reply to RCPT TO command';
        if RegExpr.Exec(bounce_error) then UserUnknown(bounce_error,RegExpr.Match[1]);
    end;

     ini:=TiniFile.Create('/var/log/artica-postfix/RTM/'+mailid+'.msg');
     ini.WriteString('TIME','time_sended',time_connect);
     ini.WriteString('TIME','mailto',mailto);
     ini.WriteString('TIME','delivery_success',delivery_success);
     ini.WriteString('TIME','bounce_error',bounce_error);
     ini.UpdateFile;
     ini.free;
     exit;



end;

//##############################################################################

procedure thooksyslog.AddMailFROM(mailid:string;mailfrom:string;size:string;time_connect:string);
var
sql:string;
id:integer;
RegExpr:TRegExpr;
ini:TiniFile;
begin

     ini:=TiniFile.Create('/var/log/artica-postfix/RTM/'+mailid+'.msg');
     ini.WriteString('TIME','time_mailfrom',time_connect);
     ini.WriteString('TIME','sender_user',mailfrom);
     ini.UpdateFile;
     ini.free;
     exit;
end;

//##############################################################################

procedure thooksyslog.Addmsgid(mailid:string;msg_id:string;time_connect:string);
var
sql:string;
id:integer;
ini:TiniFile;
begin


     ini:=TiniFile.Create('/var/log/artica-postfix/RTM/'+mailid+'.msg');
     ini.WriteString('TIME','time_connect',time_connect);
     ini.WriteString('TIME','message-id',msg_id);
     ini.UpdateFile;
     ini.free;

     ini:=TiniFile.Create('/var/log/artica-postfix/RTM/'+msg_id+'.id');
     ini.WriteString('TIME','postfix_id',mailid);
     ini.free;
     exit;
end;

//##############################################################################
procedure thooksyslog.GreyListedLog(mailserver:string;mailfrom:string;mailto:string);
var
filestring:string;
id:integer;
ini:TiniFile;
date:string;
begin
     date:=logs.DateTimeNowSQL();

     filestring:=logs.MD5FromString(date+mailserver+mailfrom);
     ini:=TiniFile.Create('/var/log/artica-postfix/RTM/'+filestring+'.greylisted');
     logs.Debuglogs('/var/log/artica-postfix/RTM/'+trim(filestring)+'.greylisted  <'+mailfrom+'> to <'+mailto+'>');
     ini.WriteString('TIME','time_connect',date);
     ini.WriteString('TIME','mailfrom',mailfrom);
     ini.WriteString('TIME','mailto',mailto);
     ini.WriteString('TIME','greylisted','1');
     ini.UpdateFile;
     ini.free;
     logs.Debuglogs('Greylisted server '+mailserver);
end;

//##############################################################################
procedure thooksyslog.AddDiscard(postfixid:string;mailfrom:string;mailto:string);
var
filestring:string;
id:integer;
ini:TiniFile;
date:string;
begin
  date:=logs.DateTimeNowSQL();
  logs.Debuglogs('/var/log/artica-postfix/RTM/'+trim(postfixid)+'.msg DISCARD action <'+mailfrom+'> to <'+mailto+'>');
   ini:=TiniFile.Create('/var/log/artica-postfix/RTM/'+trim(postfixid)+'.msg');
     ini.WriteString('TIME','time_end',date);
     ini.WriteString('TIME','mailfrom',mailfrom);
     ini.WriteString('TIME','mailto',mailto);
     ini.WriteString('TIME','delivery_success','no');
     ini.WriteString('TIME','bounce_error','DISCARD action');
     ini.UpdateFile;
     ini.free;
end;
//##############################################################################
procedure thooksyslog.AddBadContentScanner(postfixid:string;mailfrom:string;mailto:string);
var
filestring:string;
id:integer;
ini:TiniFile;
date:string;
begin
  date:=logs.DateTimeNowSQL();
  logs.Debuglogs('/var/log/artica-postfix/RTM/'+trim(postfixid)+'.msg Content scanner malfunction <'+mailfrom+'>to <'+mailto+'>' );
   ini:=TiniFile.Create('/var/log/artica-postfix/RTM/'+trim(postfixid)+'.msg');
     ini.WriteString('TIME','time_end',date);
     ini.WriteString('TIME','mailfrom',mailfrom);
     ini.WriteString('TIME','mailto',mailto);
     ini.WriteString('TIME','delivery_success','no');
     ini.WriteString('TIME','bounce_error','Content scanner malfunction');
     ini.UpdateFile;
     ini.free;
end;
//##############################################################################





{function thooksyslog.ID_FROM_msg_id(msgid:string):integer;
var sql:string;
    l:Tstringlist;
    id:integer;
begin



     if EnableMysqlFeatures=0 then begin
       logs.Debuglogs('thooksyslog.ID_FROM_msg_id:: EnableMysqlFeatures=0' );
       exit;
    end;

    msgid:=logs.GetAsSQLText(msgid);
    sql:='SELECT id FROM smtp_logs WHERE msg_id_text="'+msgid+'";';
    l:=TstringList.Create;
    if debug then writeln('ID_FROM_msg_id(): '+sql);
    l:=logs.QUERY_SQL_PARSE_COLUMN(sql,database,0);
    if l.Count=0 then exit;
    TryStrToInt(l.Strings[0],result);

end;
//##############################################################################}








end.
