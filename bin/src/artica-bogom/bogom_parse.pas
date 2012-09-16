unit bogom_parse;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,IniFiles, Process,
    logs in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/logs.pas',unix,
    RegExpr in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/RegExpr.pas',
    zsystem in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/zsystem.pas',
    articaldap in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-ldap/articaldap.pas',
    mimemess in '/home/dtouzeau/developpement/artica-postfix/bin/src/mimemessage_src/mimemess.pas',
    artica_mysql,
    mimepart in '/home/dtouzeau/developpement/artica-postfix/bin/src/mimemessage_src/mimepart.pas',
    spamass,bogom;
type

  mailrecord=record
        mailfrom:string;
        mailto:TstringList;
        subject:string;
        messageID:string;
        MessageDate:string;
        OriginalMessage:TstringList;
        HtmlMessage:string;
        message_path:string;
        X_SpamTest_Rate:integer;
        X_Spam_Score:integer;
        X_Spam_Status:boolean;
        subject_match:boolean;
        
        
        
  end;

  type
  tbogom_parse=class


private
     LOGS          :Tlogs;
     artica_path   :string;
     SYS           :Tsystem;
     mysql         :Tartica_mysql;
     ldap          :Tarticaldap;
     globalCommands:string;
     function       DecodeMessage(message_path:string):mailrecord;
     function       DecodeMailAddr(source:string):string;
     function       Justice(msg:mailrecord):boolean;
     procedure      LearnBogoSpam(msg:mailrecord);
     procedure      LearnBogoHam(msg:mailrecord);
     maildirs       :string;
     attachmenturl  :string;
     rewrite_header :string;

public
    procedure   Free;
    procedure  ParseQueue();
    constructor Create();
END;

implementation

constructor tbogom_parse.Create();
var
   i:integer;
   s:string;
   spam:Tspamass;
begin

       LOGS:=tlogs.Create();
       SYS:=Tsystem.Create;
       spam:=Tspamass.Create(SYS);
       rewrite_header:=spam.rewrite_header();


 if ParamCount>0 then begin
     for i:=1 to ParamCount do begin
        s:=s  + ' ' +ParamStr(i);
     end;
 end;
 
 
 globalCommands:=s;
 
 maildirs:='/opt/artica/bogo-dump';
 
 

       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;

end;
//##############################################################################
procedure tbogom_parse.free();
begin
    logs.Free;
    SYS.Free;
end;
//##############################################################################
procedure tbogom_parse.ParseQueue();
var
   l:TstringList;
   i:integer;
   TargetFile:string;
   msg:mailrecord;

begin

    l:=TstringList.Create;
    l:=SYS.DirFiles(maildirs,'*.msg');

    logs.Debuglogs('processing ' + IntToStr(l.Count) + ' dump mail(s)');
    
    for i:=0 to l.Count-1 do begin
        TargetFile:=maildirs+'/'+ l.Strings[i];
        logs.Debuglogs('processing '+ TargetFile);
        try
         msg:=DecodeMessage(TargetFile);
         if Justice(msg) then begin
            logs.Debuglogs('processing '+ TargetFile + ' for spam');
            LearnBogoSpam(msg)
         end else begin
            logs.Debuglogs('processing '+ TargetFile + ' for ham');
             LearnBogoHam(msg);
         end;
        except
         logs.syslogs('FATAL ERROR ON regestire message '+TargetFile);
         continue;
        end;


    end;

end;
//##############################################################################
function tbogom_parse.Justice(msg:mailrecord):boolean;
begin
result:=false;
    if msg.X_SpamTest_Rate>70 then exit(true);
    if msg.X_Spam_Status then exit(true);
    if msg.subject_match then exit(true);
end;
//##############################################################################
procedure tbogom_parse.LearnBogoHam(msg:mailrecord);
var bogom:tbogom;
begin

try
  bogom:=tbogom.Create(SYS);
  except
  logs.Syslogs('LearnBogoHam() Fatal error while create tbogom instance');
  exit;
  end;
  logs.Debuglogs('LearnBogoHam() :: ['+msg.messageID+'] ' + msg.message_path + ' From=<' +msg.mailfrom+'>');
  logs.Syslogs(msg.messageID+': From=<' +msg.mailfrom+'>, learn_bogofilter=ham');
  logs.Syslogs('LearnBogoHam() :: ' + msg.message_path);
  try
     bogom.Learn_spam(msg.message_path,false);
     logs.Debuglogs('LearnBogoHam() :: bogom.Learn_spam() Success')
  except
     logs.Debuglogs('LearnBogoHam() :: FATAL ERROR while invoke bogom.Learn_spam() function');
  end;
  logs.DeleteFile(msg.message_path);
  bogom.free;
end;
//##############################################################################
procedure tbogom_parse.LearnBogoSpam(msg:mailrecord);
var bogom:tbogom;
begin
  try
  bogom:=tbogom.Create(SYS);
  except
  logs.Syslogs('LearnBogoSpam() Fatal error while create tbogom instance');
  exit;
  end;
  try
     logs.Syslogs(msg.messageID+': From=<' +msg.mailfrom+'> subject='+msg.subject + ', learn_bogofilter=spam');
  except
    logs.Syslogs('LearnBogoSpam() Fatal error while following msg instance');
  end;
  logs.Syslogs('LearnBogoSpam() :: ' + msg.message_path);
  bogom.Learn_spam(msg.message_path,true);
  logs.DeleteFile(msg.message_path);
  bogom.free;
end;
//##############################################################################
function tbogom_parse.DecodeMessage(message_path:string):mailrecord;
var
   msg:mailrecord;
   Mime:TMimeMess;
   mailto:string;
   i:Integer;
   RegExpr     :TRegExpr;
   kasrate:string;
begin
   Mime:=TMimeMess.Create;
   msg.mailto:=TstringList.Create;
   msg.OriginalMessage:=TstringList.Create;
   Mime.Lines.LoadFromFile(message_path);
   Mime.DecodeMessage;
   msg.messageID:=Mime.Header.MessageID;
   
   msg.messageID:=AnsiReplaceText(msg.messageID,'%','-');
   
   msg.MessageDate:=FormatDateTime('yyyy-mm-dd hh:mm:ss', Mime.Header.Date);
   msg.mailfrom:=DecodeMailAddr(Mime.Header.From);
   msg.subject:=Mime.Header.Subject;
   msg.OriginalMessage.LoadFromFile(message_path);
   msg.message_path:=message_path;
   msg.subject_match:=false;
   msg.X_Spam_Status:=false;
   
   logs.Debuglogs('tbogom_parse.DecodeMessage('+message_path+'): success');
   
   for i:=0 to mime.Header.ToList.Count-1 do begin;
        mailto:=DecodeMailAddr(mime.Header.ToList.Strings[i]);
        logs.Debuglogs('tbogom_parse.DecodeMessage:: mailto='+mailto);
        msg.mailto.Add(mailto);
   end;
   
   for i:=0 to mime.Header.CCList.Count-1 do begin;
        mailto:=DecodeMailAddr(mime.Header.CCList.Strings[i]);
        logs.Debuglogs('tbogom_parse.DecodeMessage:: CCList='+mailto);
        msg.mailto.Add(mailto);
   end;

RegExpr:=TRegExpr.Create;

//Kaspersky AS.
kasrate:=mime.Header.FindHeader('X-SpamTest-Rate');
if not TryStrToInt(kasrate,msg.X_SpamTest_Rate) then msg.X_SpamTest_Rate:=0;



//X-Spam-Status
kasrate:=mime.Header.FindHeader('X-Spam-Status');
RegExpr.Expression:='Yes, score=';
if RegExpr.Exec(kasrate) then msg.X_Spam_Status:=true;
if pos(rewrite_header,Mime.Header.Subject)>0 then msg.subject_match:=True;

logs.Debuglogs('tbogom_parse.DecodeMessage:: End');


result:=msg;

end;
//##############################################################################
function tbogom_parse.DecodeMailAddr(source:string):string;
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
//##############################################################################
end.
