unit mimedefang_hook;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,IniFiles, Process,md5,logs,unix,RegExpr in 'RegExpr.pas',zsystem,mimemess, mimepart,articaldap,global_conf,bogofilter,artica_mysql;

type LDAP=record
      admin:string;
      password:string;
      suffix:string;
      servername:string;
      Port:string;
  end;

  type
  thook=class


private
     LOGS          :Tlogs;
     artica_path   :string;
     hookpath      :string;
     MessageID     :string;
     SYS           :Tsystem;
     HEADERS       :TstringList;
     Mime          :TMimeMess;
     RegExpr       :TRegExpr;
     mailfrom      :string;
     GLOBAL_SUBJECT:string;
     Recipients    :TstringList;
     LocalDomains  :TstringList;
     ldap          :Tarticaldap;
     mysql         :Tartica_mysql;
     function      GetDomain(email:string):string;
     function      SendedToLocal(domain:string):boolean;
     GLOBAL_INI    :myconf;
     UserInfos     :users_datas;
     Resultat       :boolean;
     globalCommands :string;
     function   LoadLocalsDomains():boolean;
     function   LoadUserSettings(mailfrom:string):boolean;

public
    procedure   Free;
    constructor Create();
    procedure   ScanHeaders();

END;

implementation

constructor thook.Create();
var
   i:integer;
   s:string;
begin

       LOGS:=tlogs.Create();
       SYS:=Tsystem.Create;
       Mime:=TMimeMess.Create;
       RegExpr:=TRegExpr.Create;
       Recipients:=TstringList.Create;
       LocalDomains:=TstringList.Create;
       ldap:=Tarticaldap.Create;
       GLOBAL_INI:=myconf.Create;
       
       s:='';
       
       
 if ParamCount>0 then begin
     for i:=1 to ParamCount do begin
        s:=s  + ' ' +ParamStr(i);
     end;
 end;
 globalCommands:=s;
 LOGS.Debuglogs('thook.create():: receive "'+globalCommands+'"' );
 hookpath:= RegExpr.Match[1];
       
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
procedure thook.free();
begin
    logs.Free;
    SYS.Free;
    ldap.Free;
end;
//##############################################################################
procedure thook.ScanHeaders();
var
   i:integer;
   l:TstringList;
   recptDomain:string;
   from:string;
   mailto:string;
   mailer:string;
   ip:string;
begin


     RegExpr.Expression:='--from=<(.+?)>';
     RegExpr.Exec(globalCommands);
     from:=RegExpr.Match[1];

     RegExpr.Expression:='--to=(.+?) --';
     RegExpr.Exec(globalCommands);
     mailto:=RegExpr.Match[1];
     recptDomain:=GetDomain(mailto);

     RegExpr.Expression:='--ip=(.+?) --';
     RegExpr.Exec(globalCommands);
     ip:=RegExpr.Match[1];

     LOGS.Debuglogs('thook.ScanHeaders():: Parsing FROM "'+from+'" TO "'+ mailto+'"');
     
     if length(from)=0 then begin
         LOGS.Syslogs('from <> to <'+mailto+'> skip');
         exit;
     end;

    if not LoadUserSettings(from) then begin
          LOGS.Syslogs(ip + ': from=<'+from+'> to=<'+mailto+'> ('+recptDomain+') SKIP (Internet user or access granted)');
          exit;
    end;
    
    if not LoadLocalsDomains() then begin
        LOGS.Syslogs(ip + ': from=<'+from+'> to=<'+mailto+'> ('+recptDomain+') SKIP (no local domains !)');
    end;
     


         resultat:=SendedToLocal(recptDomain);
         if not resultat then begin
           logs.Syslogs(ip + ': from=<'+from+'> to=<'+mailto+'> ('+recptDomain+') REJECT');
           writeln('FALSE');
           exit;
         end;


    logs.Syslogs(ip + ': from=<'+from+'> to=<'+mailto+'> ('+recptDomain+') PASS');
    writeln('TRUE');


end;
//##############################################################################
function thook.SendedToLocal(domain:string):boolean;
var
   i:integer;

begin
  result:=false;
  try
   for i:=0 to LocalDomains.Count-1 do begin
   
       if LowerCase(domain)=LowerCase(LocalDomains.Strings[i]) then begin
          exit(true);
       end;
   end;

   except
   logs.Syslogs('thook.SendedToLocal('+domain+'):: Fatal error while parsing domains');
   end;
   exit(false);


end;
//##############################################################################
function thook.GetDomain(email:string):string;
var
  sRegExpr:TRegExpr;
  i:Integer;
begin
  sRegExpr:=TRegExpr.Create;
  sRegExpr.Expression:='.+?@(.+)';
  
  if not sRegExpr.Exec(email) then exit;
  result:=LowerCase(sRegExpr.Match[1]);
  sRegExpr.free;
end;
//##############################################################################
function thook.LoadUserSettings(mailfrom:string):boolean;
var AllowedSMTPTroughtInternet:integer;
begin

if not ldap.Logged then begin
   logs.Syslogs('LDAP connection failed');
   exit(false);
end;

UserInfos:=ldap.UserDataFromMail(mailfrom);
if length(UserInfos.uid)=0 then exit(false);


if not TryStrToInt(UserInfos.AllowedSMTPTroughtInternet,AllowedSMTPTroughtInternet) then AllowedSMTPTroughtInternet:=1;

if AllowedSMTPTroughtInternet=0 then begin
   LOGS.Debuglogs('thook.LoadUserSettings():: check user "'+mailfrom+'"='+UserInfos.uid + ' not allowed usually');
   exit(true);
end;

exit(false);
end;
//##############################################################################
function thook.LoadLocalsDomains():boolean;
begin
 if not ldap.Logged then begin
   logs.Syslogs('LDAP connection failed');
   exit(false);
end;
  LocalDomains:=TstringList.Create;
  result:=false;
  try
  LocalDomains.AddStrings(ldap.Allowed_domains());
  except
    logs.Syslogs('thook.LoadLocalsDomains() fatal error while get domains in memory..');
  end;
  if LocalDomains.Count=0 then begin
    logs.Syslogs('No internal domains');
    exit(false);
  end else begin
     logs.Debuglogs('thook.LoadLocalsDomains()::' + IntTOStr(LocalDomains.Count) + ' local domain(s)');
     exit(true);
  end;
end;
//##############################################################################
end.
