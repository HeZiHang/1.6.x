unit filter;

{$MODE DELPHI}
//{$mode objfpc}{$H+}
{$LONGSTRINGS ON}

interface

uses
Classes, SysUtils,variants, Process,IniFiles,oldlinux,md5,RegExpr in 'RegExpr.pas',logs,ldap,strutils,synautil,dnssend,synamisc;
type
  TStringDynArray = array of string;
  
type

    TTMailInfo = record
               client_address:string;
               client_name:string;
               reverse_client_name:string;
               sender:string;
               sender_name:string;
               recipient:string;
               size:string;
               ldap_uid:string;
               ldap_ou:string;
               senderdomain:string;
               Filter_result:string;
               mx_record:string;
               md:string;
               end;
  
  type
  Tfilter=class




private
     function Explode(const Separator, S: string; Limit: Integer = 0):TStringDynArray;
     function COMMANDLINE_PARAMETERS(FoundWhatPattern:string):boolean;
     GLOBAL_INI:TIniFile;
     function get_ARTICA_PHP_PATH():string;
     function BlackList(Email:TTMailInfo):TTMailInfo;
     function ArticaFilterQueuePath():string;
     function MYSQL_ACTION_QUERY(sql:string):boolean;
     procedure SendSqlQuery(email:TTmailInfo);
     function DNSMX(Email:TTMailInfo):TTMailInfo;
     function DSNMASQ_RUN():boolean;
     infos:TTMailInfo;
     DNSMASQ:boolean;


public
    constructor Create;
    destructor Destroy; override;
    MESSAGE_IDA:string;
    function ParseLines(receive:string):string;
    function MD5FromString(values:string):string;
end;



implementation

//-------------------------------------------------------------------------------------------------------


//##############################################################################
constructor Tfilter.Create;

begin
  forcedirectories('/etc/artica-postfix');
  DNSMASQ:=DSNMASQ_RUN();
end;
//##############################################################################
destructor Tfilter.Destroy;
begin

  inherited Destroy;
end;
//##############################################################################
function Tfilter.ParseLines(receive:string):string;
         const
            CR = #$0d;
            LF = #$0a;
            //CRLF = CR + LF;
            CRLF = #$0D + #$0A;
      var
        RegExpr:TRegExpr;
        response:string;
        LOGS:Tlogs;
        Table:TStringDynArray;
        S:TStringList;
        i:integer;
        verbose:boolean;

BEGIN

    LOGS:=Tlogs.create;
    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='(.+?)=(.+)';
    Table:=Explode(#10,receive);
    for i:=0 to length(Table)-1 do begin
        if RegExpr.Exec(Table[i]) then begin
        if LowerCase(RegExpr.Match[1])='client_address'  then infos.client_address:=RegExpr.Match[2];
        if LowerCase(RegExpr.Match[1])='client_name'  then infos.client_name:=RegExpr.Match[2];
        if LowerCase(RegExpr.Match[1])='recipient'  then infos.recipient:=RegExpr.Match[2];
        if LowerCase(RegExpr.Match[1])='sender'  then infos.sender:=RegExpr.Match[2];
        if LowerCase(RegExpr.Match[1])='size'  then infos.size:=RegExpr.Match[2];
        end;

    end;
    verbose:=COMMANDLINE_PARAMETERS('verbose');
    
    
     logs.logs('artica-policy:: initialize');
     if verbose then logs.logs('artica-policy:: verbose mode=true');
     
     
     
     RegExpr.free;
     infos.md:=MD5FromString(receive);
     infos.Filter_result:='send';
     if verbose then logs.logs('artica-policy:: --> BlackList()');
     
     infos:=BlackList(infos);
     if infos.Filter_result='send' then begin
        if verbose then logs.logs('artica-policy:: --> DNSMX()');
        infos:=DNSMX(infos);
     end;
        
    
    logs.logs('artica-policy:: ' + infos.md+' :: From  <' + infos.sender + '> To <'+infos.recipient + '> (' + infos.client_address + ' [' + infos.client_name + '])=' + infos.Filter_result);

    s:=TStringList.Create;
    
    if infos.Filter_result='blacklist' then begin
    SendSqlQuery(infos);
    s.Add('action=REJECT 571 Delivery not authorized, message refused');
    s.Add('');
    s.Add('');
    result:=s.Text;
    s.free;
    LOGS.Free;
    exit;
    end;
    
    if infos.Filter_result='DNS' then begin
    SendSqlQuery(infos);
    s.Add('action=REJECT 571 Delivery not authorized, message refused');
    s.Add('');
    s.Add('');
    result:=s.Text;
    s.free;
    LOGS.Free;
    exit;
    end;
    
    
    
    s.Add('action=DUNNO');
    s.Add('');
    s.Add('');
    result:=s.Text;
    s.free;
    LOGS.Free;
    exit;


end;
//##############################################################################
function Tfilter.DNSMX(Email:TTMailInfo):TTMailInfo;
var
   l:TstringList;
   LOGS:Tlogs;
   s:string;
   RegExpr:TRegExpr;
   I:Integer;
   ldap:Tldap;
   parameters:string;
   verbose:boolean;

begin
verbose:=COMMANDLINE_PARAMETERS('verbose');
ldap:=Tldap.Create;
LOGS:=TLOGS.Create;
result:=Email;

     if length(Email.senderdomain)=0 then begin
        RegExpr:=TRegExpr.Create;
        RegExpr.Expression:='(.+?)@(.+)';
        if RegExpr.Exec(Email.sender) then  begin
           Email.senderdomain:=RegExpr.Match[2];
           email.sender_name:=RegExpr.Match[1];
           if verbose then logs.logs('domain --> '+Email.senderdomain);
        end;
        RegExpr.Free;
     end;
     
     
    if email.sender_name='mailman-bounces' then exit;
  
  if length(trim(email.ldap_ou))=0 then email.ldap_ou:=ldap.OU_From_eMail(Email.recipient);
  if length(trim(email.ldap_ou))=0 then begin
     ldap.Free;
     logs.Free;
     exit(Email);
  end;
  if verbose then logs.logs('artica-policy:: --> ldap.ArticaDenyNoMXRecordsOu() --> '+email.ldap_ou);
  parameters:=Ldap.ArticaDenyNoMXRecordsOu(email.ldap_ou);

  
  
  
  LOGS.LOGS('artica-policy:: parameters="' +parameters + '"');
  if parameters='pass' then begin
       ldap.free;
       Logs.free;
      exit(email);
  end;
     
  
  
  if ldap.ISRegisteredDomain(Email.senderdomain) then begin
       if verbose then logs.logs('artica-policy:: --> ldap.ISRegisteredDomain() --> TRUE');
       ldap.free;
       Logs.free;
       exit(email);
  end;
  

  ldap.free;
  l := TStringList.create;
  
 if not DNSMASQ then begin
  
  try
    s := GetDNS;
    LOGS.LOGS('artica-policy:: DNSMX:: servers="' +s + '"');
    l.commatext := s;
    if l.count > 0 then
    begin
      s := l[0];
      LOGS.LOGS('artica-policy:: DNSMX:: request for="' +s + '" =>' + Email.senderdomain);
      GetMailServers(s, Email.senderdomain, l);
    end;
  finally

  end;
  
  end else begin
    LOGS.LOGS('artica-policy:: DNSMX:: request for="127.0.0.1" =>' + Email.senderdomain);
      GetMailServers('127.0.0.1', Email.senderdomain, l);
  
  end;
  
  
  
   if l.count>0 then begin
      for i:=0 to l.Count -1 do begin
        LOGS.LOGS('artica-policy:: DNSMX::(' + InttoStr(i) + ') "' +l.Strings[i] + '"');
      end;
   end else begin
       LOGS.LOGS('artica-policy:: No mx for ' + Email.senderdomain);
       Email.Filter_result:='DNS';
   end;
  
   l.free;
   result:=Email;
end;
//##############################################################################
function Tfilter.DSNMASQ_RUN():boolean;
  var pid:string;
begin
  result:=false;
   if FileExists('/usr/sbin/dnsmasq') then result:=true;
   if FileExists('/usr/local/sbin/dnsmasq') then result:=true;
end;
//##############################################################################


 //##############################################################################
function Tfilter.BlackList(Email:TTMailInfo):TTMailInfo;
var
   LDAP:Tldap;
   trouve:boolean;
   i:integer;
   ou,uid:string;
   RegExpr:TRegExpr;
   Sender_domain:string;
   LOGS:TLogs;
   D:boolean;
begin
     D:=false;
     LDAP:=TLdap.Create();
     LOGS:=TLOGS.Create;
     D:=COMMANDLINE_PARAMETERS('debug');
     Email.ldap_uid:=ldap.EmailFromAliase(Email.recipient);
     if D then writeln('BlackList:: uid=' + Email.ldap_uid);
     
     if length(trim(email.ldap_ou))=0 then begin
        ou:=ldap.OU_From_eMail(Email.recipient);
        email.ldap_ou:=ou;
     end else begin
        ou:=Email.ldap_ou;
     end;
     
        RegExpr:=TRegExpr.Create;
        RegExpr.Expression:='(.+?)@(.+)';
        if RegExpr.Exec(Email.sender) then  begin
           Sender_domain:=RegExpr.Match[2];
           email.sender_name:=RegExpr.Match[1];
           Email.senderdomain:=Sender_domain;
        end;
        RegExpr.Free;

     if length(ou)>0 then begin
          if D then writeln('BlackList:: OU=' + ou);


           if ldap.IsOuDomainBlackListed(ou,Email.senderdomain) then begin
                LOGS.Logs('artica-send::Global BlackList::' +ou + ' as black listed '+Sender_domain);
                LDAP.Free;
                LOGS.FREE;
                email.Filter_result:='blacklist';
                exit(email);
           end;
          RegExpr.Free;

     end;

       if D then writeln('BlackList:: IsOuDomainBlackListed:: false');


          if LDAP.IsBlackListed(Email.sender,Email.recipient) then begin
              LOGS.Logs('artica-send:: BlackList::' +email.recipient + ' as black listed '+Email.sender);
              LDAP.Free;
              LOGS.FREE;
              email.Filter_result:='blacklist';
              exit(email);
          end;

          if LDAP.IsBlackListed(Email.sender,Email.recipient) then begin
             LOGS.Logs('artica-send:: BlackList::' + email.recipient+ ' as black listed '+Email.sender);
             LDAP.Free;
             LOGS.FREE;
             email.Filter_result:='blacklist';
             exit(email);
          end;


    LDAP.Free;
    LOGS.FREE;
    exit(email);
end;
//#########################################################################################
procedure Tfilter.SendSqlQuery(email:TTmailInfo);
var sql,Subject:string;
begin
    Subject:='No Subject';
          sql:='INSERT INTO messages (MessageID,mail_from,mailfrom_domain,mail_to,subject,zDate,received_date,SpamRate,message_path,filter_action,ou,MailSize,SpamInfos,quarantine) ';
    sql:=sql + 'VALUES("'+ email.md+'","' + email.sender+'","' + email.senderdomain+'","' + email.recipient +'","'+Subject+'",';
    sql:=sql + 'DATE_FORMAT(NOW(),''%Y-%m-%d %H:%I:%S''),DATE_FORMAT(NOW(),''%Y-%m-%d %H:%I:%S''),"0","'+email.md+'","' +email.Filter_result+'","' +email.ldap_ou+'","' + email.size + '","NONE","0")';
       MYSQL_ACTION_QUERY(sql);

end;
//#########################################################################################
function Tfilter.Explode(const Separator, S: string; Limit: Integer = 0):TStringDynArray;
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
//####################################################################################
function Tfilter.MD5FromString(values:string):string;
var StACrypt,StCrypt:String;
Digest:TMD5Digest;
begin
Digest:=MD5String(values);
exit(MD5Print(Digest));
end;
//####################################################################################
function Tfilter.COMMANDLINE_PARAMETERS(FoundWhatPattern:string):boolean;
var
   i:integer;
   s:string;
   RegExpr:TRegExpr;

begin
 result:=false;
 if ParamCount>0 then begin
     for i:=0 to ParamCount do begin
        s:=s  + ' ' +ParamStr(i);
     end;
 end;
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:=FoundWhatPattern;
   if RegExpr.Exec(s) then begin
      RegExpr.Free;
      result:=True;
   end;


end;
//####################################################################################
function Tfilter.get_ARTICA_PHP_PATH():string;
var path:string;
begin
  if not DirectoryExists('/usr/share/artica-postfix') then begin
  path:=ParamStr(0);
  path:=ExtractFilePath(path);
  path:=AnsiReplaceText(path,'/bin/','');
  exit(path);
  end else begin
  exit('/usr/share/artica-postfix');
  end;

end;
//##############################################################################
function Tfilter.MYSQL_ACTION_QUERY(sql:string):boolean;
    var root,commandline,password,cmd_result,pass:string;
    i:integer;
    D:boolean;
    RegExpr:TRegExpr;
    found:boolean;
    logs:Tlogs;
    MyRes:TstringList;
    QueuePath:string;
    FileTemp:string;
    database:string;
begin
  database:='artica_filter';
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
//##############################################################################
function Tfilter.ArticaFilterQueuePath():string;
var ini:TIniFile;
begin
 ini:=TIniFile.Create('/etc/artica-postfix/artica-filter.conf');
 result:=ini.ReadString('INFOS','QueuePath','');
 if length(trim(result))=0 then result:='/usr/share/artica-filter';
end;
//##############################################################################
end.

