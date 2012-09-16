unit hookPostfix;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes,SysUtils,variants,strutils,IniFiles, Process,logs,unix,RegExpr in 'RegExpr.pas',zsystem,
    mimemess in '/home/dtouzeau/developpement/artica-postfix/bin/src/mimemessage_src/mimemess.pas',
    mimepart in '/home/dtouzeau/developpement/artica-postfix/bin/src/mimemessage_src/mimepart.pas',
    BaseUnix;

  type
  thookPostfix=class


private
     LOGS:Tlogs;
     artica_path:string;
     mail:Tstringlist;
     mypid:string;
     SYS:Tsystem;
     commandlines:string;
     procedure StartListener();
     function DecodeMessage():boolean;


public
    procedure   Free;
    constructor Create;





END;

implementation

constructor thookPostfix.Create;
var
i:integer;
begin

 commandlines:='';
 if ParamCount>0 then begin
     for i:=1 to ParamCount do begin
        commandlines:=commandlines  + ' ' +ParamStr(i);
     end;
 end;

       forcedirectories('/var/mail/artica-wbl');
       LOGS:=tlogs.Create();
       SYS:=Tsystem.Create();


        mail:=Tstringlist.Create;

       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;


      mypid:=IntToStr(fpgetpid);
      StartListener();

end;
//##############################################################################
procedure thookPostfix.free();
begin

end;
//##############################################################################
procedure thookPostfix.StartListener();
var
 st: text;
 s: string;
 l:TstringList;
begin

 assign(st,'');
 reset(st);
 mail.Clear;
 while not eof(st) do begin // <<<<<<<<--- iterate while not en of file
   readln(st,s); //<<< read only a line
   mail.Add(s);
 end;
 close(st); // <<<<<---
 DecodeMessage();
 mail.Clear;
end;
//##############################################################################
function thookPostfix.DecodeMessage():boolean;
var
   Mime:TMimeMess;
   i:Integer;
   RegExpr     :TRegExpr;
   xfrom:string;
   xto:string;
   messageID:string;
   MessageDate:string;
   content_type:string;
   l:TstringList;
   orignal_from:string;
   action:string;
   robotname:string;

begin
   Mime:=TMimeMess.Create;
   Mime.Lines.AddStrings(mail);
   Mime.DecodeMessage;

   messageID:=Mime.Header.MessageID;
   messageID:=logs.MD5FromString(MessageID);
   MessageDate:=FormatDateTime('yyyy-mm-dd hh:mm:ss', Mime.Header.Date);
   RegExpr:=TRegExpr.Create;

   xfrom:=trim(Mime.Header.From);
   if length(xfrom)=0 then begin
      xfrom:=trim(Mime.Header.FindHeader('X-Envelope-From'));
   end;

   RegExpr.Expression:='--white';
   if RegExpr.Exec(commandlines) then action:='white';

   RegExpr.Expression:='--black';
   if RegExpr.Exec(commandlines) then action:='black';

   RegExpr.Expression:='--report';
   if RegExpr.Exec(commandlines) then action:='report';

   RegExpr.Expression:='--quarantine';
   if RegExpr.Exec(commandlines) then action:='quarantine';

   RegExpr.Expression:='--spam';
   if RegExpr.Exec(commandlines) then begin
      if length(messageID)=0 then messageID:=logs.MD5FromString(mail.Text);
      action:='spam';
      try
         logs.WriteToFile(mail.Text,'/var/spam-mails/'+messageID+'.eml');
      except
        halt(1);
      end;
      halt(0);
   end;

   RegExpr.Expression:='-s\s+(.+?)\s+';
   if RegExpr.Exec(commandlines) then orignal_from:=RegExpr.Match[1];


   RegExpr.Expression:='-a\s+(.+?)\s+';
   if RegExpr.Exec(commandlines) then robotname:=RegExpr.Match[1];

   RegExpr.Expression:='<(.+?)>';
   if RegExpr.Exec(xfrom) then xfrom:=RegExpr.Match[1];

   l:=TstringList.Create;


   logs.Debuglogs(commandlines);
   logs.Debuglogs('X-Envelope-From: '+ xfrom);
   logs.Debuglogs('Subject: '+ Mime.Header.Subject);
   if length(xfrom)=0 then xfrom:=trim(Mime.Header.From);
   logs.Debuglogs('From: '+ xfrom);
   logs.Debuglogs('Parts numbers:'+IntToStr(Mime.MessagePart.GetSubPartCount));
   l.Add('[MAIL]');
   l.Add('From='+xfrom);
   l.Add('orignal_from='+orignal_from);
   l.Add('Content=/var/mail/artica-wbl/'+messageID+'.eml');
   l.Add('action='+action);
   l.Add('robotname='+robotname);
   l.Add('subject='+Mime.Header.Subject);

   if Mime.MessagePart.GetSubPartCount=0 then begin
        content_type:=format('%-30s',[Mime.MessagePart.primary+'/'+Mime.MessagePart.secondary]);
        content_type:=trim(lowercase(content_type));
        logs.Debuglogs('Parts 0 '+content_type);
        if content_type='text/plain' then begin
           Mime.MessagePart.DecodePart;
           Mime.MessagePart.DecodedLines.SaveToFile('/var/mail/artica-wbl/'+messageID+'.eml');
           logs.Debuglogs('Parts 0 '+content_type +' /var/mail/artica-wbl/'+messageID+'.eml');
           logs.WriteToFile(l.Text,'/var/mail/artica-wbl/'+messageID+'.ini');
           logs.Syslogs('From: <'+orignal_from+'> "'+action+'" success');
        end;
        exit;
   end;



   for i:=0 to Mime.MessagePart.GetSubPartCount -1 do begin
       Mime.MessagePart.GetSubPart(i).TargetCharset:=Mime.MessagePart.GetSubPart(i).CharsetCode;
       content_type:=format('%-30s',[Mime.MessagePart.GetSubPart(i).primary+'/'+Mime.MessagePart.GetSubPart(i).secondary]);
       content_type:=trim(lowercase(content_type));
       logs.Debuglogs('Parts ' + intToStr(i)+' '+content_type);
       if content_type='text/plain' then begin
          Mime.MessagePart.GetSubPart(i).DecodePart;
          Mime.MessagePart.GetSubPart(i).DecodedLines.SaveToFile('/var/mail/artica-wbl/'+messageID+'.eml');
          logs.Debuglogs('Parts ' + intToStr(i)+' '+content_type +' /var/mail/artica-wbl/'+messageID+'.eml');
          logs.WriteToFile(l.Text,'/var/mail/artica-wbl/'+messageID+'.ini');
          logs.Syslogs('From: <'+orignal_from+'> "'+action+'" success');
          break;
       end;


   end;


  result:=true;

end;
//##############################################################################









end.
