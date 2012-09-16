unit amavisquar;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,Process,
    logs in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/logs.pas',unix,
    RegExpr in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/RegExpr.pas',
    zsystem in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/zsystem.pas',
    articaldap in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-ldap/articaldap.pas',
    mimemess in '/home/dtouzeau/developpement/artica-postfix/bin/src/mimemessage_src/mimemess.pas',
    artica_mysql,
    mimepart in '/home/dtouzeau/developpement/artica-postfix/bin/src/mimemessage_src/mimepart.pas',
    amavisd_milter,MessageStorages;


  type
  tamavisquar=class


private
     LOGS          :Tlogs;
     artica_path   :string;
     SYS           :Tsystem;
     mysql         :Tartica_mysql;
     ldap          :Tarticaldap;
     globalCommands:string;
     function       DecodeMessage(message_path:string):mailrecord;
     function       DecodeMailAddr(source:string):string;
     attachmentdir  :string;
     fullmessagesdir:string;
     attachmenturl  :string;
     function       TransFormToHtml(message_path:string):string;
     amavis         :tamavis;
     function       GunzipError(TargetFile:string):boolean;




public
    procedure   Free;
    procedure  ParseQueue();
    constructor Create();
    procedure   SCAN_AMAVIS_STANDARD_QUEUE();
END;

implementation

constructor tamavisquar.Create();
var
   i:integer;
   s:string;
begin
       SetCurrentDir('/root');
       LOGS:=tlogs.Create();
       SYS:=Tsystem.Create;
       ldap:=Tarticaldap.Create;
       amavis:=tamavis.Create(SYS);
       s:='';

 if not FileExists('/usr/bin/mhonarc') then begin
     LOGS.Syslogs('FATAL ERROR: Unable to stat /usr/bin/mhonarc');
     halt(0);
 end;

 if not FileExists(amavis.AMAVISD_BIN_PATH()) then begin
    logs.Debuglogs('FATAL ERROR: unable to stat amavis !! I think it is not installed');
    halt(0);
 end;
 
 if not FileExists('/bin/gunzip') then begin
    LOGS.Syslogs('FATAL ERROR: Unable to stat /bin/gunzip');
    halt(0);
 end;
 
 

 if ParamCount>0 then begin
     for i:=1 to ParamCount do begin
        s:=s  + ' ' +ParamStr(i);
     end;
 end;


 globalCommands:=s;

 attachmentdir:='/opt/artica/share/www/attachments';
 fullmessagesdir:='/opt/artica/share/www/original_messages';
 attachmenturl:='images.listener.php?mailattach=';



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
procedure tamavisquar.free();
begin
    logs.Free;
    SYS.Free;
    ldap.free;
    amavis.free;
end;
//##############################################################################
procedure tamavisquar.ParseQueue();
         const
            CR = #$0d;
            LF = #$0a;
            CRLF = CR + LF;
var
   l:TstringList;
   i:integer;
   TargetFile:string;
   msg:mailrecord;
   performed:boolean;
   quarantine_dir:string;
   gzfile:string;
   cmd:string;
   notification_text:string;
   MessageStorages:tMessageStorages;

begin
    quarantine_dir:=amavis.QUARANTINEDIR();
    if not DirectoryExists(quarantine_dir) then begin
       logs.Syslogs('tamavisquar.ParseQueue():: unable to stat amavis quarantine "' +quarantine_dir+'"' );
       halt(0);
    end;

       
    l:=TstringList.Create;
    l:=SYS.DirFiles(quarantine_dir,'*.gz');
    performed:=false;
    logs.Debuglogs('tamavisquar.ParseQueue():: Processing ' + IntToStr(l.Count) + ' dump mail(s) in '+quarantine_dir);


    ForceDirectories('/tmp/amavis-quar');


    for i:=0 to l.Count-1 do begin
        gzfile:=quarantine_dir+'/'+ l.Strings[i];
        logs.Debuglogs('decompresssing '+ gzfile);
        TargetFile:='/tmp/amavis-quar/'+l.Strings[i]+'.tmp';
        if FileExists(TargetFile) then logs.DeleteFile(TargetFile);
        cmd:='/bin/gunzip -d -c '+gzfile + ' >' + TargetFile+ ' 2>&1';
        logs.Debuglogs(cmd);
        fpsystem(cmd);
        
        
        if not FileExists(TargetFile) then begin
           logs.Debuglogs('Unable to decompress ' +gzfile);
           continue;
        end;
        
        if GunzipError(TargetFile) then begin
            logs.Syslogs('Corrupted file ' + gzfile + ' it will be deleted from queue');
            notification_text:='Corrupted file ' + gzfile + ' it will be deleted from queue'+CRLF;
            notification_text:=notification_text+'Reported gzip:'+CRLF;
            notification_text:=notification_text+ logs.ReadFromFile(TargetFile);
            logs.NOTIFICATION('[ARTICA]: ('+ SYS.HOSTNAME_g()+'): Corrupted file '+l.Strings[i]+' in amavis quarantine queue',notification_text,'system');
            logs.DeleteFile(gzfile);
            logs.DeleteFile(TargetFile);
            continue;
        end;
        
        

        try
         msg:=DecodeMessage(TargetFile);
        except
         logs.syslogs('tamavisquar.ParseQueue():: FATAL ERROR ON decoding file '+TargetFile);
         continue;
        end;

        logs.Debuglogs('tamavisquar.ParseQueue():: Success decoding From=<' + msg.mailfrom+'> to ' + intToStr(msg.mailto.Count) + ' Recipient(s)');
        
        if msg.mailto.Count=0 then begin
            logs.Debuglogs('tamavisquar.ParseQueue():: failed decoding, there is no recipients ! ('+ IntToStr(msg.OriginalMessage.Count)+') lines');
            if msg.OriginalMessage.Count=0 then begin
               logs.DeleteFile(TargetFile);
               logs.DeleteFile(gzfile);
            end;
            continue;
        end;
        


        try
         MessageStorages:=tMessageStorages.Create();
         performed:=MessageStorages.SaveQuarantineToMysql(msg);
        except
         logs.syslogs('tamavisquar.ParseQueue()::FATAL ERROR ON processing mysql database on file '+TargetFile);
         continue;
        end;


        if performed then begin
           logs.Debuglogs('tamavisquar.ParseQueue():: "'+TargetFile+'" success quarantine');
           logs.DeleteFile(TargetFile);
           logs.DeleteFile(gzfile);
        end;
        


    end;

end;
//##############################################################################
procedure tamavisquar.SCAN_AMAVIS_STANDARD_QUEUE();
var
i:integer;
folder:string;
 msg:mailrecord;
TargetFile:STRING;
performed:boolean;
MessageStorages:tMessageStorages;
begin
    SYS.DirDir('/var/amavis');
    logs.Debuglogs('SCAN_AMAVIS_STANDARD_QUEUE:: ' + IntToStr(SYS.DirListFiles.Count) + ' folders');
    for i:=0 to SYS.DirListFiles.Count-1 do begin
        performed:=false;
        folder:=sys.DirListFiles.Strings[i];
        if FileExists('/var/amavis/'+folder+'/email.txt') then begin
           TargetFile:='/var/amavis/'+folder+'/email.txt';
           logs.Debuglogs('tamavisquar.SCAN_AMAVIS_STANDARD_QUEUE():: build operation for '+TargetFile);
        end else begin
         continue;
        end;


    try
       msg:=DecodeMessage(TargetFile);
    except
         logs.syslogs('tamavisquar.SCAN_AMAVIS_STANDARD_QUEUE():: FATAL ERROR ON decoding file '+TargetFile);
         continue;
    end;


        logs.Debuglogs('tamavisquar.SCAN_AMAVIS_STANDARD_QUEUE():: Success decoding From=<' + msg.mailfrom+'> to ' + intToStr(msg.mailto.Count) + ' Recipient(s)');

        if msg.mailto.Count=0 then begin
            logs.Debuglogs('tamavisquar.SCAN_AMAVIS_STANDARD_QUEUE():: failed decoding, there is no recipients ! ('+ IntToStr(msg.OriginalMessage.Count)+') lines');
            if msg.OriginalMessage.Count=0 then begin
               continue;
            end;
            continue;
        end;



        try
         MessageStorages:=tMessageStorages.Create();
         performed:=MessageStorages.SaveQuarantineToMysql(msg);
         MessageStorages.free;
        except
         logs.syslogs('tamavisquar.SCAN_AMAVIS_STANDARD_QUEUE()::FATAL ERROR ON processing mysql database on file '+TargetFile);
         continue;
        end;


        if performed then begin
           logs.Debuglogs('tamavisquar.SCAN_AMAVIS_STANDARD_QUEUE():: "'+TargetFile+'" success quarantine');
           fpsystem('/bin/rm -rf /var/amavis/'+folder);
        end;

    end;




end;





function tamavisquar.GunzipError(TargetFile:string):boolean;
var
RegExpr:TRegExpr;
l:TstringList;
i:integer;

begin
   result:=false;

   if not FileExists(TargetFile) then exit(true);
   l:=TstringList.Create;
   l.LoadFromFile(TargetFile);
   RegExpr:=TRegExpr.Create;
   for i:=0 to l.Count-1 do begin
       RegExpr.Expression:='^gzip.+?unexpected end of file';
       if RegExpr.Exec(l.Strings[i]) then begin
          result:=true;
          break;
       end;
       RegExpr.Expression:='^gzip.+?not in gzip format';
       if RegExpr.Exec(l.Strings[i]) then begin
          result:=true;
          break;
       end;

   
   end;
   
   l.free;
   RegExpr.free;

end;
//##############################################################################
function tamavisquar.DecodeMessage(message_path:string):mailrecord;
var
   msg:mailrecord;
   Mime:TMimeMess;
   mailto:string;
   i:Integer;
   RegExpr     :TRegExpr;
   xfrom:string;
   xto:string;
begin
   Mime:=TMimeMess.Create;
   msg.mailto:=TstringList.Create;
   msg.OriginalMessage:=TstringList.Create;
   Mime.Lines.LoadFromFile(message_path);
   Mime.DecodeMessage;

   msg.messageID:=Mime.Header.MessageID;
   msg.MessageDate:=FormatDateTime('yyyy-mm-dd hh:mm:ss', Mime.Header.Date);
   RegExpr:=TRegExpr.Create;
   
   xfrom:=trim(Mime.Header.FindHeader('X-Envelope-From'));
   xto:=trim(Mime.Header.FindHeader('X-Envelope-To'));

   logs.Debuglogs('X-Envelope-From: '+ xfrom);
   logs.Debuglogs('Subject: '+ Mime.Header.Subject);
   if length(xfrom)=0 then xfrom:=trim(Mime.Header.From);
   
   
   
   msg.mailfrom:=DecodeMailAddr(xfrom);
   msg.subject:=Mime.Header.Subject;
   msg.OriginalMessage.LoadFromFile(message_path);
   msg.HtmlMessage:=TransFormToHtml(message_path);
   msg.message_path:=message_path;
   msg.header:=Mime.Header.CustomHeaders.Text;


   for i:=0 to mime.Header.ToList.Count-1 do begin;
        mailto:=DecodeMailAddr(mime.Header.ToList.Strings[i]);
        msg.mailto.Add(mailto);
   end;

   for i:=0 to mime.Header.CCList.Count-1 do begin;
        mailto:=DecodeMailAddr(mime.Header.CCList.Strings[i]);
        msg.mailto.Add(mailto);
   end;

   if msg.mailto.Count=0 then begin
        if length(xto)>0 then  msg.mailto.Add(xto);
   end;

  result:=msg;

end;
//##############################################################################
function tamavisquar.DecodeMailAddr(source:string):string;
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
   result:=AnsiReplaceText(result,'%20','');
   result:=LowerCase(result);
 RegExpr.Free;

end;
//##############################################################################
function tamavisquar.TransFormToHtml(message_path:string):string;
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
end.
