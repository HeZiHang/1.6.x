unit mailarchive;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,IniFiles, Process,md5,smtpsend,
    logs in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/logs.pas',unix,
    RegExpr in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/RegExpr.pas',
    zsystem ,MessageStorages,
    articaldap in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-ldap/articaldap.pas',
    mimemess in '/home/dtouzeau/developpement/artica-postfix/bin/src/mimemessage_src/mimemess.pas',
    artica_mysql,
    mimepart in '/home/dtouzeau/developpement/artica-postfix/bin/src/mimemessage_src/mimepart.pas';
    
type
  TStringDynArray = array of string;

type
  tmailarchive=class


private
     LOGS          :Tlogs;
     artica_path   :string;
     SYS           :Tsystem;
     mysql         :Tartica_mysql;
     ldap          :Tarticaldap;
     globalCommands:string;
     function       DecodeMessage(message_path:string;HtmlTransform:boolean):mailrecord;
     function       DecodeMailAddr(source:string):string;

     attachmentdir  :string;
     fullmessagesdir:string;
     attachmenturl  :string;
     function       TransFormToHtml(message_path:string):string;
     procedure      QuarantineFiles(ListFiles:TStringList;source_path:string);
     procedure      ArchiveFiles(source_path:string;pattern:string);
     procedure      ScanHeaders();
     TooManyConnections:boolean;
     

     function       ExtractMailFrom(Mime:TMimeMess):string;
     function       ExtractMailTo(Mime:TMimeMess):string;
     function       SendExternal(mail:mailrecord):boolean;
     function       Explode(const Separator, S: string; Limit: Integer = 0):TStringDynArray;

     D:boolean;


public
    procedure   Free;
    procedure  ParseQueue();
    procedure  ReleaseMail(source_path:string);
    procedure  ForwardMessage(TargetFile:string);
    procedure  CopyMessageTo(Path:string);
    procedure  ParseCopyToDomain();
    procedure  RecipientToAdd();
    constructor Create();
END;

implementation

constructor tmailarchive.Create();
var
   i:integer;
   s:string;
begin

       LOGS:=tlogs.Create();
       SYS:=Tsystem.Create;
       D:=SYS.COMMANDLINE_PARAMETERS('--debug');
       ldap:=Tarticaldap.Create;
       s:='';

 
 
 
 if ParamCount>0 then begin
     for i:=1 to ParamCount do begin
        s:=s  + ' ' +ParamStr(i);
     end;
 end;
 
 
 globalCommands:=s;
 
 attachmentdir:='/opt/artica/share/www/attachments';
 fullmessagesdir:='/opt/artica/share/www/original_messages';
 attachmenturl:='images.listener.php?mailattach=';
 
       forceDirectories(attachmentdir);
       forceDirectories(fullmessagesdir);

       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;

  if not ldap.Logged then begin
      LOGS.Syslogs('WARNING! LDAP connection error...');
      LOGS.Debuglogs('create():: LDAP connection error...' );
      exit;
  end;

end;
//##############################################################################
procedure tmailarchive.free();
begin
    logs.Free;
    SYS.Free;
    ldap.free;
end;
//##############################################################################
procedure tmailarchive.ParseCopyToDomain();
var
   l:TstringList;
   i:integer;
   TargetFile:string;
   msg:mailrecord;
   performed:boolean;
   ll:TstringList;
   CopyToDomainSpool:string;
begin

  CopyToDomainSpool:=SYS.GET_INFO('CopyToDomainSpool');
  if length(CopyToDomainSpool)=0 then CopyToDomainSpool:='/var/spool/artica/copy-to-domain';
    l:=TstringList.Create;
    l:=SYS.DirFilesByls(CopyToDomainSpool,'*.msg');
    logs.Debuglogs('tmailarchive.ParseCopyToDomain():: Processing ' + IntToStr(l.Count) + ' Transfered mails');
    if l.Count>0 then begin
       for i:=0 to l.Count-1 do begin
           ForwardMessage(CopyToDomainSpool+'/'+l.Strings[i]);
       end;
    end;

end;
//##############################################################################
procedure tmailarchive.RecipientToAdd();
var
   l:TstringList;
   i:integer;
   TargetFile:string;
   msg:mailrecord;
   performed:boolean;
   ll:TstringList;
   CopyCCQueue:string;
begin

  CopyCCQueue:=SYS.GET_INFO('CopyCCQueue');
  if length(CopyCCQueue)=0 then CopyCCQueue:='/var/spool/artica/CCQueue';
  If not DirectoryExists(CopyCCQueue) then begin
     ForceDirectories(CopyCCQueue);
     logs.OutputCmd('/bin/chown -R postfix:postfix '+CopyCCQueue);
  end;


    l:=TstringList.Create;
    l:=SYS.DirFilesByls(CopyCCQueue,'*.msg');
    logs.Debuglogs('tmailarchive.RecipientToAdd():: Processing ' + IntToStr(l.Count) + ' Transfered mails');
    if l.Count>0 then begin
       for i:=0 to l.Count-1 do begin
           CopyMessageTo(CopyCCQueue+'/'+l.Strings[i]);
       end;
    end;

end;
//##############################################################################
procedure tmailarchive.CopyMessageTo(Path:string);
var
   mailto:string;
   i:integer;
   RegExpr:TRegExpr;
   newmto:string;
   TargetInfo:string;
   l:TstringList;
   sTo,TargetFile,cmd:string;
   sFrom:string;
begin
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='(.+)\.msg$';
   RegExpr.Exec(Path);
   TargetInfo:=RegExpr.Match[1]+'.info';
   l:=TstringList.Create;
   try
      l.LoadFromFile(TargetInfo);
   except
       logs.syslogs('tmailarchive.RecipientToAdd():: fatal error while reading '+TargetInfo);
       exit;
   end;

   for i:=0 to l.Count-1 do begin
          RegExpr.Expression:='rcpt:(.+)';
          if RegExpr.Exec(l.Strings[i]) then begin
             sTo:=RegExpr.Match[1];
          end;

          RegExpr.Expression:='from:(.+)';
          if RegExpr.Exec(l.Strings[i]) then begin
             sFrom:=RegExpr.Match[1];
          end;
   end;

   if length(sFrom)=0 then begin
       logs.syslogs('tmailarchive.RecipientToAdd():: fatal error while parsing mailfrom '+TargetInfo);
       sFrom:='postmaster@localhost.localdomain';
   end;

   if length(sTo)=0 then begin
       logs.syslogs('tmailarchive.RecipientToAdd():: fatal error while parsing mailto '+TargetInfo);
       exit;
   end;

   if Lowercase(trim(sTo))=Lowercase(trim(sFrom)) then begin
        logs.Syslogs('from=<' +sFrom+'>, to=<'+sTo+'>,status=deleted, cannot duplicate for the same user');
        logs.DeleteFile(Path);
        logs.DeleteFile(TargetInfo);
        exit;
   end;

cmd:='/usr/sbin/sendmail -bm -t "'+trim(sTo)+'" '+ '"'+trim(sFrom)+'"<'+Path;
logs.OutputCmd(cmd);
logs.DeleteFile(Path);
logs.DeleteFile(TargetInfo);
logs.Syslogs('from=<' +sFrom+'>, to=<'+sTo+'>,status=duplicate to address success');
RegExpr.free;
l.free;
end;
//##############################################################################
procedure tmailarchive.ParseQueue();
var
   l:TstringList;
   i:integer;
   TargetFile:string;
   msg:mailrecord;
   performed:boolean;
   ll:TstringList;

begin
    ArchiveFiles('/tmp/savemail','*.msg');
    ArchiveFiles('/var/spool/jchkmail','*.unknown');


    l:=TstringList.Create;
    L.Clear;
    l:=SYS.DirFiles('/var/spool/jchkmail','*.virus');
    logs.Debuglogs('tmailarchive.ParseQueue():: Processing ' + IntToStr(l.Count) + ' viruses mail(s) in /var/spool/jchkmail');
    if l.Count>0 then begin
       QuarantineFiles(l,'/var/spool/jchkmail');
    end;
    
    
    L.Clear;
    l:=SYS.DirFilesByls('/var/db/kav/5.6/kavmilter/backup','*.bak');
    logs.Debuglogs('tmailarchive.ParseQueue():: Processing ' + IntToStr(l.Count) + ' viruses mail(s) in /var/db/kav/5.6/kavmilter/backup');
    if l.Count>0 then begin
       QuarantineFiles(l,'/var/db/kav/5.6/kavmilter/backup');
    end;
    
    
    logs.Debuglogs('tmailarchive.ParseQueue():: Processing Queue end...');
end;
//##############################################################################
procedure  tmailarchive.ReleaseMail(source_path:string);
var
   sender:string;
   Mime:TMimeMess;
   mailto:string;
   cmd:string;
begin
 Mime:=TMimeMess.Create;
 Mime.Lines.LoadFromFile(source_path);
 Mime.DecodeMessage;
 sender:=ExtractMailFrom(Mime);
 if length(sender)=0 then begin
     logs.Debuglogs('ResendMail: no sender found');
     exit;
 end;

 mailto:=ExtractMailTo(Mime);
if not FileExists('/usr/sbin/sendmail') then begin
   logs.Syslogs('Fatal error unable to locate /usr/sbin/sendmail');
end;
logs.Syslogs('from=<'+trim(sender)+'> to=<'+trim(mailto)+'> resend...');
if length(sender)=0 then begin
   logs.Syslogs('FATAL ERROR '+source_path+' Sender is NULL !!');
   exit;
end;
cmd:='/usr/sbin/sendmail -bm -t "'+trim(mailto)+'" '+ '"'+trim(sender)+'"<'+source_path;
logs.OutputCmd(cmd);
end;
//##############################################################################
function tmailarchive.ExtractMailFrom(Mime:TMimeMess):string;
var
   sender:string;
   RegExpr:TRegExpr;
begin
   sender:=Mime.Header.From;
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='<(.+?)>';
   if RegExpr.Exec(sender) then sender:=RegExpr.Match[1];
   RegExpr.free;
   result:=sender;
end;
//##############################################################################
function tmailarchive.ExtractMailTo(Mime:TMimeMess):string;
var
   mailto:string;
   i:integer;
   RegExpr:TRegExpr;
   newmto:string;
begin
     RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='<(.+?)>';
     for i:=0 to Mime.Header.ToList.Count-1 do begin
        if RegExpr.Exec(Mime.Header.ToList.Strings[i]) then newmto:=RegExpr.Match[1] else newmto:=Mime.Header.ToList.Strings[i];
        mailto:=mailto+' ' + newmto;
     end;
    result:=mailto;
end;
//##############################################################################
procedure  tmailarchive.ForwardMessage(TargetFile:string);
var
   msg:mailrecord;
   Ini:TiniFile;
   RegExpr:TRegExpr;
   domain:string;
   i:integer;
   TargetInfo:string;
begin
   RegExpr:=TRegExpr.Create;
   if not FileExists('/etc/artica-postfix/settings/Daemons/AmavisCopyToDomain') then begin
      logs.Syslogs('Unable to stat /etc/artica-postfix/settings/Daemons/AmavisCopyToDomain');
      exit;
   end;
   
   logs.Debuglogs('');
   logs.debuglogs('ForwardMessage:: processing "'+TargetFile+'"');
   RegExpr.Expression:='(.+)\.msg$';
   RegExpr.Exec(TargetFile);
   TargetInfo:=RegExpr.Match[1]+'.info';
   
   
   
   if not FileExists(TargetInfo) then begin
      logs.Syslogs('Unable to stat '+TargetInfo);
      //logs.DeleteFile(TargetFile);
      exit;
   end;

   try
    msg:=DecodeMessage(TargetFile,false);
    except
    logs.syslogs('tmailarchive.ForwardMessage()::FATAL ERROR ON decoding file '+TargetFile);
    exit;
    end;

msg.mailto.Clear;
msg.mailto.LoadFromFile(TargetInfo);

for i:=0 to msg.mailto.Count-1 do begin
       msg.MailToListString:=msg.mailto.Strings[i]+' '+ msg.MailToListString;

end;




ini:=Tinifile.Create('/etc/artica-postfix/settings/Daemons/AmavisCopyToDomain');
RegExpr.Expression:='(.+?)@(.+)';
for i:=0 to msg.mailto.Count-1 do begin
      if not RegExpr.Exec(msg.mailto.Strings[i]) then begin
         logs.Debuglogs('ForwardMessage():: failed regex on '+msg.mailto.Strings[i]);
         continue;
      end;
      
      
      domain:=RegExpr.Match[2];
      if ini.ReadInteger(domain,'enable',0)=1 then begin
         msg.TargetServer:=ini.ReadString(domain,'duplicate_host','');
         msg.TargetPort:=ini.ReadString(domain,'duplicate_port','');
         if SendExternal(msg) then begin
             logs.DeleteFile(TargetInfo);
             logs.DeleteFile(TargetFile);
         end;
         
         break;
      end else begin
        logs.Debuglogs('ForwardMessage():: '+domain + ' has no config ');
      
      end;
      


end;




end;
 //##############################################################################





procedure  tmailarchive.ArchiveFiles(source_path:string;pattern:string);
var
   l:TstringList;
   i:integer;
   TargetFile:string;
   msg:mailrecord;
   performed:boolean;
   ll:TstringList;
   MessageStorages:tMessageStorages;

begin

 if not FileExists('/usr/bin/mhonarc') then begin
     fpsystem('/usr/share/artica-postfix/bin/artica-make APP_MHONARC');
     halt(0);
 end;


 if not FileExists('/usr/bin/mhonarc') then begin
     LOGS.Syslogs('FATAL ERROR: Unable to stat /usr/bin/mhonarc');
     halt(0);
 end;


l:=TstringList.Create;
l:=SYS.DirFiles(source_path,pattern);
logs.Debuglogs('tmailarchive.ParseQueue():: Processing ' + IntToStr(l.Count) + ' dump mail(s) in '+source_path);
TooManyConnections:=false;

    for i:=0 to l.Count-1 do begin
        TargetFile:=source_path+'/'+ l.Strings[i];

        if TooManyConnections then begin
           logs.Syslogs('Stop program it seems that mysql is not available!!');
           halt(0);
           exit;
        end;
        logs.Debuglogs('tmailarchive.ArchiveFiles()::Processing '+ TargetFile);


        try
         msg:=DecodeMessage(TargetFile,true);
        except
         logs.syslogs('tmailarchive.ArchiveFiles()::FATAL ERROR ON decoding file '+TargetFile);
         continue;
        end;

        try
         MessageStorages:=tMessageStorages.Create();
         performed:=MessageStorages.SaveArchiveToMysql(msg);
         MessageStorages.Free;
        except
         logs.syslogs('tmailarchive.ArchiveFiles()::FATAL ERROR ON processing mysql database on file '+TargetFile);
         continue;
        end;


        if performed then begin
           logs.Debuglogs('tmailarchive.ArchiveFiles()::"'+TargetFile+'" success backuped');
           logs.DeleteFile(TargetFile);
        end;

    end;
l.free;
    
end;


procedure  tmailarchive.QuarantineFiles(ListFiles:TStringList;source_path:string);
var
    i:integer;
   TargetFile:string;
   msg:mailrecord;
   performed:boolean;
   MessageStorages:TMessageStorages;
begin


 if not FileExists('/usr/bin/mhonarc') then begin
     LOGS.Syslogs('FATAL ERROR: Unable to stat /usr/bin/mhonarc');
     halt(0);
 end;


 for i:=0 to ListFiles.Count-1 do begin
        TargetFile:=source_path+'/'+ ListFiles.Strings[i];
        logs.Debuglogs('tmailarchive.QuarantineFiles():: Processing: Quarantine: '+ TargetFile);


        try
         msg:=DecodeMessage(TargetFile,true);
        except
         logs.syslogs('tmailarchive.QuarantineFiles():: FATAL ERROR ON decoding file '+TargetFile);
         continue;
        end;

        try
         MessageStorages:=tMessageStorages.Create();
         performed:=MessageStorages.SaveQuarantineToMysql(msg);
         MessageStorages.free;
        except
         logs.syslogs('tmailarchive.QuarantineFiles():: FATAL ERROR ON processing mysql database on file '+TargetFile);
         continue;
        end;


        if performed then begin
           logs.Debuglogs('tmailarchive.QuarantineFiles():: "'+TargetFile+'" success quarantine');
           logs.DeleteFile(TargetFile);
        end;

    end;



end;
//##############################################################################
function tmailarchive.DecodeMessage(message_path:string;HtmlTransform:boolean):mailrecord;
var
   msg:mailrecord;
   Mime:TMimeMess;
   mailto:string;
   i:Integer;
   RegExpr     :TRegExpr;

begin
   if D then writeln('DecodeMessage:: Create instance..');
   Mime:=TMimeMess.Create;
   msg.mailto:=TstringList.Create;
   msg.OriginalMessage:=TstringList.Create;
   logs.Debuglogs('tmailarchive.DecodeMessage:: loading '+message_path);
   Mime.Lines.LoadFromFile(message_path);
   if D then writeln('DecodeMessage:: decoding '+message_path);
   Mime.DecodeMessage;
   msg.messageID:=Mime.Header.MessageID;
   if D then writeln('DecodeMessage:: Messagid: '+msg.messageID);
   msg.MessageDate:=FormatDateTime('yyyy-mm-dd hh:mm:ss', Mime.Header.Date);
   RegExpr:=TRegExpr.Create;
   msg.mailfrom:=DecodeMailAddr(Mime.Header.From);
   msg.subject:=Mime.Header.Subject;
   msg.OriginalMessage.LoadFromFile(message_path);
   if HtmlTransform then msg.HtmlMessage:=TransFormToHtml(message_path);
   msg.message_path:=message_path;
   
   for i:=0 to mime.Header.ToList.Count-1 do begin;
        mailto:=DecodeMailAddr(mime.Header.ToList.Strings[i]);
        msg.mailto.Add(mailto);
   end;
   
   for i:=0 to mime.Header.CCList.Count-1 do begin;
        mailto:=DecodeMailAddr(mime.Header.CCList.Strings[i]);
        msg.mailto.Add(mailto);
   end;
   
   
  result:=msg;

end;
//##############################################################################
function tmailarchive.DecodeMailAddr(source:string):string;
var
RegExpr     :TRegExpr;
begin
RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='<(.+?)>';
   if RegExpr.Exec(source) then begin
      result:=RegExpr.Match[1];
   end else begin
        RegExpr.Expression:='(.+?)@(.+?)\s+';
        if RegExpr.Exec(source) then begin
            result:=RegExpr.Match[1]+'@'+RegExpr.Match[2];
        end else begin
            result:=source;
         end;
   end;

   result:=AnsiReplaceText(result,'"<','');
   result:=AnsiReplaceText(result,'"','');
   result:=LowerCase(result);
 RegExpr.Free;

end;
//##############################################################################
function tmailarchive.TransFormToHtml(message_path:string):string;
var
   cmd:string;
begin


   cmd:='/usr/bin/mhonarc ';
   cmd:=cmd+'-attachmentdir ' + attachmentdir + ' ';
   cmd:=cmd+'-attachmenturl ' + attachmenturl + ' ';
   cmd:=cmd+'-nodoc ';
   cmd:=cmd+'-nofolrefs ';
   cmd:=cmd+'-nomsgpgs ';
   cmd:=cmd+'-nospammode ';
   cmd:=cmd+'-nosubjectthreads ';
   cmd:=cmd+'-idxfname storage ';
   cmd:=cmd+'-nosubjecttxt "no subject" ';
   cmd:=cmd+'-single ';
   cmd:=cmd + message_path + ' ';
   cmd:=cmd + '>/opt/artica/tmp/' + ExtractFileName(message_path) + '.html 2>&1';

  logs.Debuglogs('TransFormToHtml():: Export to html ' + message_path);
  logs.Debuglogs('TransFormToHtml():: '+cmd);
  fpsystem(cmd);

  result:=logs.ReadFromFile('/opt/artica/tmp/' + ExtractFileName(message_path) + '.html');
  logs.DeleteFile('/opt/artica/tmp/' + ExtractFileName(message_path) + '.html');

end;


//##############################################################################
function tmailarchive.SendExternal(mail:mailrecord):boolean;

var
   i:integer;
   CommandLine:string;
   RegExpr:TRegExpr;
   temp:string;
   tmpfile:string;
   myhostname:string;
   l:Tstringlist;
begin
   Result:=false;
   RegExpr:=TRegExpr.Create;


 if not FileExists(artica_path+'/bin/artica-msmtp') then begin
    logs.Syslogs('WARNING: Unable to stat '+artica_path+'/bin/artica-msmtp');
    exit;
 end;
 myhostname:=SYS.HOSTNAME_g();
 tmpfile:=LOGS.FILE_TEMP();
 CommandLine:='';
 mail.message_path:=AnsiReplaceText(mail.message_path,'$','\$');
 CommandLine:=CommandLine+ artica_path+'/bin/artica-msmtp';
 CommandLine:=CommandLine+' --syslog=on';
 CommandLine:=CommandLine+' --host='+mail.TargetServer +' --port='+mail.TargetPort;
 CommandLine:=CommandLine+' --domain='+myhostname;
 CommandLine:=CommandLine+' --from='+mail.mailfrom;
 CommandLine:=CommandLine+' '+mail.MailToListString;
 CommandLine:=CommandLine+' <"'+mail.message_path+'"';
 CommandLine:=CommandLine+' >'+tmpfile+' 2>&1';
 logs.Debuglogs(CommandLine);
 fpsystem(CommandLine);
 if not FileExists(tmpfile) then exit(false);

 l:=Tstringlist.Create;
 l.LoadFromFile(tmpfile);
 for i:=0 to l.Count-1 do begin
     if length(trim(l.Strings[i]))=0 then continue;
     temp:=temp+l.Strings[i];
 end;
 
 if length(temp)>0 then begin
    logs.Syslogs('SendExternal:: Failed '+l.text);

 end else begin
     logs.Syslogs('SendExternal:: Success ');
     result:=true;
 
 end;
 
 RegExpr.free;
 l.free;
 
 
 





end;
//##############################################################################



procedure tmailarchive.ScanHeaders();
var
   i:integer;
   l:TstringList;
   HEADERS:TstringList;
begin
HEADERS:=TstringList.Create;
{
RegExpr.Expression:='--perform=stat';
 if RegExpr.Exec(globalCommands) then begin
     performStats();
     halt(0);
 end;


  if not FileExists(hookpath + '/INPUTMSG') then begin
     LOGS.Syslogs('WARNING! Unable to stat ' + hookpath + '/INPUTMSG');
     exit;
  end;


  HEADERS:=TstringList.Create;
  HEADERS.LoadFromFile(hookpath + '/INPUTMSG');


  Mime.Lines.AddStrings(HEADERS);
  Mime.DecodeMessage;

  LOAD_SENDER();
  RegExpr.Expression:='<(.*?)>';
  if length(mailfrom)=0 then begin
     if RegExpr.Exec(Mime.Header.From) then mailfrom:=RegExpr.Match[1];
  end;

     LOGS.Debuglogs('ScanHeaders():: From: ' + mailfrom );

     GLOBAL_SUBJECT:=Mime.Header.Subject;
     LOGS.Debuglogs('ScanHeaders():: Subject: ' + GLOBAL_SUBJECT );


     MessageID:=Mime.Header.MessageID;
     MessageID:=AnsiReplaceText(MessageID,';','-');
     MessageID:=AnsiReplaceText(MessageID,' ','-');
     MessageID:=AnsiReplaceText(MessageID,'$','-');
     MessageID:=AnsiReplaceText(MessageID,'%','-');
     MessageID:=AnsiReplaceText(MessageID,'!','-');
     MessageID:=AnsiReplaceText(MessageID,'&','-');




     LOGS.Debuglogs('ScanHeaders():: MessageID: ' + Mime.Header.MessageID );

     ScanRecipts_inCOMMANDS();


     for i:=0 to mime.Header.ToList.Count-1 do begin
        AddRecipient(mime.Header.ToList.Strings[i]);
     end;


     for i:=0 to mime.Header.CCList.Count-1 do begin
        AddRecipient(mime.Header.CCList.Strings[i]);
     end;

     LOGS.Debuglogs('ScanHeaders():: To,bcc List:=' + IntToStr(Recipients.Count));

  RegExpr.Expression:='--perform=htmlsize';

   if RegExpr.Exec(globalCommands) then begin
     LOGS.Debuglogs('ScanHeaders():: perform HTML Size..');
     htmlsize();
  end;

RegExpr.Expression:='--perform=backup';

   if RegExpr.Exec(globalCommands) then begin
     logs.Syslogs('<' + MessageID + '> mail is put into backup queue in /opt/artica/mimedefang-hooks/backup-queue/ waiting backup process');
     LOGS.Debuglogs('ScanHeaders():: perform Backup rules...');
     forceDirectories('/opt/artica/mimedefang-hooks/backup-queue');
     forceDirectories('/opt/artica/mimedefang-hooks/rcpt-queue');
     HEADERS.SaveToFile('/opt/artica/mimedefang-hooks/backup-queue/' + MessageID);
     Recipients.SaveToFile('/opt/artica/mimedefang-hooks/rcpt-queue/' + MessageID);


  end;


RegExpr.Expression:='--perform=bogo';
   if RegExpr.Exec(globalCommands) then begin
      LOGS.Debuglogs('ScanHeaders():: perform bogofilter rules...');
      bogofilter(hookpath + '/INPUTMSG');
      LOGS.Debuglogs('ScanHeaders():: finish die...');
      halt(0);
   end;

RegExpr.Expression:='--perform=learn_bogo';
   if RegExpr.Exec(globalCommands) then begin
      LOGS.Debuglogs('ScanHeaders():: perform bogofilter learning...');
      bogofilter_learn(hookpath + '/INPUTMSG');
      LOGS.Debuglogs('ScanHeaders():: finish die...');
      halt(0);
   end;

RegExpr.Expression:='--perform=whitelist';
 if RegExpr.Exec(globalCommands) then begin
      LOGS.Debuglogs('ScanHeaders():: perform whitelist learning...');
      autowhite(hookpath + '/INPUTMSG');
      LOGS.Debuglogs('ScanHeaders():: finish die...');
      halt(0);
 end;

RegExpr.Expression:='--perform=translations';
 if RegExpr.Exec(globalCommands) then begin
      LOGS.Debuglogs('ScanHeaders():: perform duplicates emails for recipients...');
      Duplicates(hookpath);
      LOGS.Debuglogs('ScanHeaders():: finish die...');
      halt(0);
 end;



   }

end;

//##############################################################################
function tmailarchive.Explode(const Separator, S: string; Limit: Integer = 0):TStringDynArray;
var
  SepLen       : Integer;
  F, P         : PChar;
  ALen, Index  : Integer;
begin
  SetLength(Result, 0);
  if (S = '') or (Limit < 0) then
    Exit;
  if Separator = '' then
  begin
    SetLength(Result, 1);
    Result[0] := S;
    Exit;
  end;
  SepLen := Length(Separator);
  ALen := Limit;
  SetLength(Result, ALen);

  Index := 0;
  P := PChar(S);
  while P^ <> #0 do
  begin
    F := P;
    P := StrPos(P, PChar(Separator));
    if (P = nil) or ((Limit > 0) and (Index = Limit - 1)) then
      P := StrEnd(F);
    if Index >= ALen then
    begin
      Inc(ALen, 5); // mehrere auf einmal um schneller arbeiten zu können
      SetLength(Result, ALen);
    end;
    SetString(Result[Index], F, P - F);
    Inc(Index);
    if P^ <> #0 then
      Inc(P, SepLen);
  end;
  if Index < ALen then
    SetLength(Result, Index); // wirkliche Länge festlegen
end;
//##############################################################################
end.
