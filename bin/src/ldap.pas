unit ldap;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
  Classes, SysUtils,ldapsend,RegExpr in 'RegExpr.pas',IniFiles,strutils;
  
type
  TStringDynArray = array of string;
  type
  Tldap=class
  

  private
       ldap_admin,ldap_password,ldap_suffix:string;
       function get_LDAP(key:string):string;
       DN_ROOT:string;
  public
      constructor Create();
      function Explode(const Separator, S: string; Limit: Integer = 0):TStringDynArray;
      procedure Free;
      function EmailFromAliase(email:string):string;
      function LoadBlackList(email:string):string;
      function LoadWhiteList(email:string):string;
      function LoadASRules(email:string):string;
      function LoadAVRules(email:string):string;
      function LoadOUASRules(ou:string):string;
      function LoadArticaUserRules(email:string):string;
      function COMMANDLINE_PARAMETERS(FoundWhatPattern:string):boolean;
      function Query(Query_string:string;return_attribute:string):string;
      function IsBlackListed(mail_from:string;mail_to:string):boolean;
      function IsWhiteListed(mail_from:string;mail_to:string):boolean;
      function uidFromMail(email:string):string;
      function eMailFromUid(uid:string):string;
      function OU_From_eMail(email:string):string;
      function QuarantineMaxDayByOu(Ou:string):string;
      function IsOuDomainBlackListed(Ou:string;domain:string):boolean;
      function FackedSenderParameters(Ou:string):string;
      function ArticaMaxSubQueueNumberParameter():integer;
      function LoadAllOu():string;
      SEARCH_DN:string;
      TEMP_LIST:TstringList;

end;

implementation

constructor Tldap.Create();
begin
   SEARCH_DN:='';
   ldap_admin:=get_LDAP('admin');
   ldap_password:=get_LDAP('password');
   ldap_suffix:=get_LDAP('suffix');
   TEMP_LIST:=TstringList.Create;
end;
PROCEDURE Tldap.Free();
begin
  TEMP_LIST.Free;
end;
//##############################################################################
function Tldap.LoadBlackList(email:string):string;
var

right_email,Myquery,resultats:string;
i,t,u:integer;
D:boolean;
begin
     right_email:=EmailFromaliase(email);
     D:=COMMANDLINE_PARAMETERS('black=');
     if D then writeln('Get list of black emails for "' + right_email + '"');
     Myquery:='(&(ObjectClass=ArticaSettings)(mail=' +right_email + '))';
     resultats:=trim(Query(MyQuery,'KasperkyASDatasDeny'));
     if D then writeln(resultats);
     exit(trim(resultats));
end;
//##############################################################################
function Tldap.eMailFromUid(uid:string):string;
var

right_email,Myquery,resultats:string;
i,t,u:integer;
D:boolean;
begin

     D:=COMMANDLINE_PARAMETERS('debug');
     if D then writeln('Get email of  for "' + uid + '"');
     Myquery:='(&(ObjectClass=userAccount)(uid=' +uid + '))';
     resultats:=Query(MyQuery,'mail');
     resultats:=trim(resultats);
     if D then writeln(resultats);
     exit(resultats);
end;
//##############################################################################
function Tldap.LoadArticaUserRules(email:string):string;
var
right_email,Myquery,resultats:string;
i,t,u:integer;
D:boolean;
begin
   right_email:=EmailFromaliase(email);
   Myquery:='(&(ObjectClass=ArticaSettings)(mail=' +right_email + '))';
   resultats:=Query(MyQuery,'ArticaUserFilterRule');
   exit(resultats);
end;
//##############################################################################
function Tldap.LoadAllOu():string;
var
right_email,Myquery,resultats:string;
i,t,u:integer;
D:boolean;
begin

   Myquery:='(&(ObjectClass=organizationalUnit)(ou=*))';
   resultats:=Query(MyQuery,'ou');
   exit(resultats);
end;
//##############################################################################
function Tldap.QuarantineMaxDayByOu(Ou:string):string;
var
right_email,Myquery,resultats:string;
i,t,u:integer;
D:boolean;
begin

   Myquery:='(&(ObjectClass=organizationalUnit)(ou=' + ou + '))';
   resultats:=Query(MyQuery,'ArticaMaxDayQuarantine');
   exit(trim(resultats));
end;
//##############################################################################
function Tldap.IsOuDomainBlackListed(Ou:string;domain:string):boolean;
var
right_email,Myquery,resultats:string;
i,t,u:integer;
D:boolean;
begin
   result:=false;
   SEARCH_DN:='cn=blackListedDomains,ou=' + ou + ',' + ldap_suffix;
   Myquery:='(&(ObjectClass=DomainsBlackListOu)(cn='+domain+'))';
   resultats:=trim(Query(MyQuery,'cn'));
   if length(resultats)>0 then exit(true);
   
end;
//##############################################################################
function Tldap.FackedSenderParameters(Ou:string):string;
var
resultats,Myquery:string;
begin
   result:='pass';
   SEARCH_DN:='ou=' + ou + ',' + ldap_suffix;
   Myquery:='(&(ObjectClass=ArticaSettings)(ArticaFakedMailFrom=*))';
   resultats:=trim(Query(MyQuery,'ArticaFakedMailFrom'));
   if length(resultats)=0 then result:='pass' else result:=resultats;

end;
//##############################################################################
function Tldap.ArticaMaxSubQueueNumberParameter():integer;
var
resultats,Myquery:string;
begin
   result:=5;
   SEARCH_DN:='cn=artica,' + ldap_suffix;
   Myquery:='(&(ObjectClass=ArticaSettings)(ArticaMaxSubQueueNumber=*))';
   resultats:=trim(Query(MyQuery,'ArticaMaxSubQueueNumber'));
   if length(resultats)=0 then resultats:='5';
   result:=StrToInt(resultats);
end;
//##############################################################################





function Tldap.LoadASRules(email:string):string;
         const
            CR = #$0d;
            LF = #$0a;
            CRLF = CR + LF;
var
RegExpr:TRegExpr;
right_email,Myquery,resultats:string;
i,t,u:integer;
D:boolean;
begin
     right_email:=EmailFromaliase(email);
     D:=COMMANDLINE_PARAMETERS('asrules=');
     if D then writeln('Get list of Kaspersky antispam rules for "' + right_email + '"');
     Myquery:='(&(ObjectClass=ArticaSettings)(mail=' +right_email + '))';
     resultats:=Query(MyQuery,'KasperkyASDatasRules');
     if trim(resultats)='DEFAULT' then begin
          RegExpr:=TRegExpr.Create;
          RegExpr.Expression:='ou=(.+?),.+';
          if RegExpr.Exec(DN_ROOT) then resultats:=LoadOUASRules(RegExpr.Match[1]);
     end;
     if trim(resultats)='DEFAULT' then begin
            resultats:='detection_rate="45"' + CRLF;
            resultats:=resultats+ 'action_quarantine="1"' + CRLF;
            resultats:=resultats+ 'action_killmail="1"' + CRLF;
            resultats:=resultats+ 'action_prepend="0"' + CRLF;
            resultats:=resultats+ 'second_rate="90"' + CRLF;
            resultats:=resultats+ 'second_quarantine="0"' + CRLF;
            resultats:=resultats+ 'second_killmail="1"' + CRLF;
            resultats:=resultats+ 'second_prepend="0"' + CRLF;
            
     
     end;
     
     if D then writeln(resultats);
     exit(resultats);
end;
//##############################################################################
function Tldap.OU_From_eMail(email:string):string;
var
   RegExpr:TRegExpr;
   right_email,Myquery,resultats:string;
   i,t,u:integer;
   D:boolean;
   F:boolean;
begin
     D:=COMMANDLINE_PARAMETERS('whereis=');
     F:=COMMANDLINE_PARAMETERS('debug');

    if F then writeln('OU_From_eMail: ' + email );
    right_email:=EmailFromaliase(email);
    if D then writeln('Where is "' + right_email + '" ?');
    Myquery:='(&(ObjectClass=userAccount)(mail=' +right_email + '))';
    if F then writeln('OU_From_eMail: ' + Myquery );
    resultats:=Query(MyQuery,'ObjectName');
    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='ou=(.+?),.+';
    if RegExpr.Exec(resultats) then result:=RegExpr.Match[1];
end;


//##############################################################################
function Tldap.LoadAVRules(email:string):string;
         const
            CR = #$0d;
            LF = #$0a;
            CRLF = CR + LF;
var
RegExpr:TRegExpr;
right_email,Myquery,resultats,ou:string;
i,t,u:integer;
D:boolean;
begin
     right_email:=EmailFromaliase(email);
     ou:=OU_From_eMail(right_email);
     D:=COMMANDLINE_PARAMETERS('avrules=');
     if D then writeln('Get list of Kaspersky antivirus rules for "' + ou + '"');
     Myquery:='(&(ObjectClass=ArticaSettings)(ou=' +ou + '))';
     resultats:=Query(MyQuery,'KasperkyAVScanningDatas');
     if trim(resultats)='DEFAULT' then begin
     resultats:='NotifyFromAddress="postmaster"' + CRLF;
     resultats:=resultats+ 'DeleteDetectedVirus="1"' + CRLF;
     resultats:=resultats+ 'NotifyFrom="1"' + CRLF;
     resultats:=resultats+ 'NotifyTo="1"' + CRLF;
     resultats:=resultats+ 'ArchiveMail="1"' + CRLF;
     resultats:=resultats+ 'NotifyMessageSubject="%SUBJECT%"' + CRLF;
     resultats:=resultats+ '<NotifyMessageTemplate><p><font face="arial,helvetica,sans-serif" size="4" color="#ff0000">Warning !!</font></p>';
     resultats:=resultats+ '<p>The message %SUBJECT% sended by %SENDER% For %MAILTO% was infected please, try to send your messages without any viruses.</p><p><strong>Virus detected</strong> :</p><blockquote><p>%VIRUS% !!!<br /> </p></blockquote></NotifyMessageTemplate>' + CRLF;
     end;

     if D then writeln(resultats);
     exit(resultats);
end;
//##############################################################################
function Tldap.LoadOUASRules(ou:string):string;
var

right_email,Myquery,resultats:string;
i,t,u:integer;
D:boolean;
begin

     D:=COMMANDLINE_PARAMETERS('asrules=');
     if D then writeln('Get list of Kaspersky antispam rules for "' + ou + '"');
     Myquery:='(&(ObjectClass=ArticaSettings)(ou=' +ou + '))';
     resultats:=Query(MyQuery,'KasperkyASDatasRules');
     exit(resultats);
end;
//##############################################################################
function Tldap.uidFromMail(email:string):string;
var

right_email,Myquery,resultats:string;
i,t,u:integer;
D:boolean;
begin

     D:=COMMANDLINE_PARAMETERS('uid=');
     right_email:=EmailFromaliase(email);
     Myquery:='(&(ObjectClass=userAccount)(mail=' +right_email + '))';
     resultats:=trim(Query(MyQuery,'uid'));
     exit(resultats);
end;
//##############################################################################
function Tldap.LoadWhiteList(email:string):string;
var

right_email,Myquery,resultats:string;
i,t,u:integer;
D:boolean;
begin
     right_email:=EmailFromaliase(email);
     D:=COMMANDLINE_PARAMETERS('black=');
     if D then writeln('Get list of black emails for "' + right_email + '"');
     Myquery:='(&(ObjectClass=ArticaSettings)(mail=' +right_email + '))';
     resultats:=Query(MyQuery,'KasperkyASDatasAllow');
     if D then writeln(resultats);
     exit(resultats);
end;
//##############################################################################
function Tldap.IsBlackListed(mail_from:string;mail_to:string):boolean;
         const
            CR = #$0d;
            LF = #$0a;
            CRLF = CR + LF;
var
   QueryDatabase:TStringDynArray;
   i:integer;
   blocked:string;
   D:boolean;
   RegExpr:TRegExpr;
begin
result:=false;
mail_to:=EmailFromaliase(LowerCase(mail_to));
mail_from:=LowerCase(mail_from);
D:=COMMANDLINE_PARAMETERS('debug');

  QueryDatabase:=Explode(CRLF,LoadBlackList(mail_to));
  if Length(QueryDatabase)=0 then begin
     if D then writeln('"' + mail_to + '" has no black list entries');
     exit(false);
  end;
  
  for i:=0 to Length(QueryDatabase)-1 do begin
        blocked:=LowerCase(QueryDatabase[i]);
        if D then writeln('IsBlackListed:: blocked="' + blocked + '"');
        if blocked=mail_from then exit(true);
        if Pos('*',blocked)>0 then begin
           RegExpr:=TRegExpr.Create;
           blocked:=AnsiReplaceText(blocked,'*','.+');
           if D then writeln('IsBlackListed:: RegExpr="' + Blocked + '"');
           RegExpr.Expression:=blocked;
           if RegExpr.Exec(mail_from) then begin
              RegExpr.Free;
              exit(true);
           end;
        end;
           
        
        
  end;
  
  if D then writeln('IsBlackListed:: Done');

end;
//##############################################################################
function Tldap.IsWhiteListed(mail_from:string;mail_to:string):boolean;
         const
            CR = #$0d;
            LF = #$0a;
            CRLF = CR + LF;
var
   QueryDatabase:TStringDynArray;
   i:integer;
   blocked:string;
   D:boolean;
   RegExpr:TRegExpr;
begin
result:=false;
mail_to:=EmailFromaliase(LowerCase(mail_to));
mail_from:=LowerCase(mail_from);
D:=COMMANDLINE_PARAMETERS('debug');

  QueryDatabase:=Explode(CRLF,LoadWhiteList(mail_to));
  if Length(QueryDatabase)=0 then begin
     if D then writeln('"' + mail_to + '" has no white list entries');
     exit(false);
  end;

  for i:=0 to Length(QueryDatabase)-1 do begin
        blocked:=LowerCase(QueryDatabase[i]);
        if blocked=mail_from then exit(true);
        if Pos('*',blocked)>0 then begin
           RegExpr:=TRegExpr.Create;
           blocked:=AnsiReplaceText(blocked,'*','.+');
           if D then writeln('IsWhiteListed:: RegExpr="' + Blocked + '"');
           RegExpr.Expression:=blocked;
           if RegExpr.Exec(mail_from) then begin
              RegExpr.Free;
              exit(true);
           end;
        end;
  end;
end;


 //##############################################################################
function Tldap.Query(Query_string:string;return_attribute:string):string;
         const
            CR = #$0d;
            LF = #$0a;
            CRLF = CR + LF;
var  ldap:TLDAPSend;
l:TStringList;
i,t,u:integer;
D,Z:boolean;
value_result:string;
AttributeNameQ:string;
begin
D:=false;
D:=COMMANDLINE_PARAMETERS('debug');
Z:=COMMANDLINE_PARAMETERS('q=');
ldap :=  TLDAPSend.Create;
     ldap.TargetHost := '127.0.0.1';
     ldap.TargetPort := '389';
     ldap.UserName := ldap_admin;
     ldap.Password := ldap_password;
     ldap.Version := 3;
     ldap.FullSSL := false;
     
     if not ldap.Login then begin
        ldap.Free;
        exit();
     end;

    return_attribute:=LowerCase(return_attribute);
    ldap.Bind;
    l:=TstringList.Create;
    l.Add('*');
    if length(SEARCH_DN)=0 then SEARCH_DN:=ldap_suffix;

    if D then writeln('QUERY:: "' + Query_string  + '" find attr:' + return_attribute);
    if D then writeln('QUERY:: IN DN "' + SEARCH_DN  + '"');

    if not ldap.Search(SEARCH_DN, False, Query_string, l) then begin
       if D then writeln('QUERY::  failed "' + ldap.FullResult + '"');
       ldap.Logout;
       ldap.Free;
    end;
    
 if D then writeln('QUERY:: Results Count :' + IntToStr(ldap.SearchResult.Count));


 if ldap.SearchResult.Count=0 then begin
     if D then writeln('QUERY::  no results...');
       ldap.Logout;
       ldap.Free;
       exit();
 end;
 
 if Z then writeln(CRLF +CRLF +'************************************************');
 
 
 for i:=0 to ldap.SearchResult.Count -1 do begin
      if D then writeln('QUERY:: ObjectName.......: "' +ldap.SearchResult.Items[i].ObjectName + '"');
      DN_ROOT:=ldap.SearchResult.Items[i].ObjectName;
      if return_attribute='objectname' then begin
         ldap.Logout;
         ldap.Free;
         if D then writeln('QUERY:: RETURN ObjectName.......: "' +DN_ROOT + '"');
         exit(DN_ROOT);
      end;
      
      if D then writeln('QUERY:: Count attributes.: ' +IntToStr(ldap.SearchResult.Items[i].Attributes.Count));
      
      for t:=0 to ldap.SearchResult.Items[i].Attributes.Count -1 do begin

      AttributeNameQ:=LowerCase(ldap.SearchResult.Items[i].Attributes[t].AttributeName);
      if D then writeln('QUERY:: Attribute name[' + IntToStr(t) + '].......: "' + AttributeNameQ + '"');
      
     TEMP_LIST.Clear;
     if AttributeNameQ=return_attribute then begin
              if D then writeln('QUERY:: Count items......: ' +IntToStr(ldap.SearchResult.Items[i].Attributes.Items[t].Count));
              for u:=0 to ldap.SearchResult.Items[i].Attributes.Items[t].Count-1 do begin
                  value_result:=ldap.SearchResult.Items[i].Attributes.Items[t].Strings[u];
                  if D then writeln('QUERY:: item[' + IntToStr(t) + ']"............:'+value_result+ '"');
                  TEMP_LIST.Add(trim(value_result));
                  Result:=Result + value_result+CRLF;
              end;
        end;
     end;
 
 end;
 
     if Z then writeln(Result);
      if Z then writeln('************************************************');
     if D then writeln('QUERY:: logout');

     ldap.Logout;
     ldap.Free;
 
end;



//##############################################################################
function Tldap.EmailFromaliase(email:string):string;
var  ldap:TLDAPSend;
l:TStringList;
i,t,u:integer;
D:boolean;
F:boolean;
begin
      F:=COMMANDLINE_PARAMETERS('debug');
      if F then writeln('EmailFromaliase:' + email);
     ldap :=  TLDAPSend.Create;
     if F then writeln('EmailFromaliase:init engine success');
     ldap.TargetHost := '127.0.0.1';
     ldap.TargetPort := '389';
     ldap.UserName := ldap_admin;
     ldap.Password := ldap_password;
     ldap.Version := 3;
     ldap.FullSSL := false;
     if F then writeln('EmailFromaliase:Login "' + ldap_admin + '"');
     if not ldap.Login then begin
        if F then writeln('EmailFromaliase:Error connection');
        ldap.Free;
        exit(email);
     end;

     if F then writeln('EmailFromaliase: Bind');
     ldap.Bind;
     if F then writeln('EmailFromaliase: Binded');
     D:=COMMANDLINE_PARAMETERS('aliases');


    l:=TstringList.Create;
    l.Add('mail');
    if F then writeln('EmailFromaliase:(&(objectclass=userAccount)(mailAlias=' + email+'))');
    ldap.Search(ldap_suffix, False, '(&(objectclass=userAccount)(mailAlias=' + email+'))', l);
    //writeln(LDAPResultdump(ldap.SearchResult));
    
    if D then writeln('Count:' + IntToStr(ldap.SearchResult.Count));
    
    if ldap.SearchResult.Count>0 then begin
         result:=ldap.SearchResult.Items[0].Attributes.Items[0].Strings[0];
         if D then writeln(email+'="' + result + '"');
         ldap.Logout;
         ldap.Free;
         exit;
    end else begin
        result:=email;
         if D then writeln(email+'="' + result + '"');
         ldap.Logout;
         ldap.Free;
        exit;
    end;
    
    
     writeln('count=' + IntToStr(ldap.SearchResult.Count));
     for i:=0 to ldap.SearchResult.Count -1 do begin
       writeln( ldap.SearchResult.Items[i].ObjectName);
       writeln( 'attributes:=' +IntToStr(ldap.SearchResult.Items[i].Attributes.Count));
       writeln('ObjectName:'+ldap.SearchResult.Items[i].ObjectName);
       
       
        for t:=0 to ldap.SearchResult.Items[i].Attributes.Count -1 do begin
              for u:=0 to ldap.SearchResult.Items[i].Attributes.Items[t].Count-1 do begin
                  writeln(ldap.SearchResult.Items[i].Attributes.Items[t].Strings[u]);
              end;
        end;
        
     end;
     writeln('logout');

     ldap.Logout;
     ldap.Free;

end;
//##############################################################################
function Tldap.COMMANDLINE_PARAMETERS(FoundWhatPattern:string):boolean;
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
//##############################################################################
function Tldap.get_LDAP(key:string):string;
var value:string;
GLOBAL_INI:TiniFile;
begin
if not fileExists('/etc/artica-postfix/artica-postfix-ldap.conf') then begin
   writeln('unable to stat /etc/artica-postfix/artica-postfix-ldap.conf !!!');
   exit;
end;
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix-ldap.conf');
value:=GLOBAL_INI.ReadString('LDAP',key,'');
result:=value;
GLOBAL_INI.Free;
end;

//##############################################################################

function Tldap.Explode(const Separator, S: string; Limit: Integer = 0):TStringDynArray;
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

