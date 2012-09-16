unit kavmilterd;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
  Classes, SysUtils,ldap,RegExpr in 'RegExpr.pas',logs,global_conf,unix,BaseUnix,
  kavmilter    in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/kavmilter.pas';

type

  mailman_settings=record
        local_lists:TstringList;
        ldap_lists:TstringList;
        prepend:string;
        action:string;
  end;

         const
            CR = #$0d;
            LF = #$0a;
            CRLF = CR + LF;

  type
  Tkavmilterd=class


  private
   logs:Tlogs;
   param:kavmilterd_parameters;
   function CheckSenderRecipients(rulename:string;ruledatas:string):boolean;
   GLOBAL_INI:MyConf;
   D:boolean;
   ldap:Tldap;
   procedure Load_lists();

  public
      constructor Create();
      destructor  Destroy; override;
      procedure   infos();
      procedure   SaveToDisk();
end;

implementation

constructor Tkavmilterd.Create();
begin


   GLOBAL_INI:=Myconf.Create;
   D:=GLOBAL_INI.COMMANDLINE_PARAMETERS('debug');
   if D then writeln('Tkavmilterd -> init...');
   logs:=Tlogs.Create;
   ldap:=Tldap.Create();

   Load_lists();
end;
//##############################################################################
destructor Tkavmilterd.Destroy;
begin
  logs.Free;
  GLOBAL_INI.free;
  inherited Destroy;
end;
//##############################################################################
procedure Tkavmilterd.infos();
begin
   writeln(param.kavmilter_conf);

end;
//##############################################################################

procedure Tkavmilterd.Load_lists();
VAR
   DATAS:String;
   LISTS:TStringDynArray;
   LDAP_LISTS:TstringList;

   I:Integer;
begin
      if D then writeln('Load_lists() -> Load global configs');
      param:=ldap.Load_kavmilterd_parameters();
end;
//##############################################################################
procedure Tkavmilterd.SaveToDisk();
   var
      TFile:TstringList;
      RegExpr:TRegExpr;
      Error_detected:boolean;
      i:integer;
      kavmilter:tkavmilter;

begin

   Error_detected:=false;
   if not FileExists('/opt/kav/5.6/kavmilter/bin/kavmilter') then begin
       if D then writeln('artica-kavmilterd:: It seems that kavmilter is not installed');
       logs.logs('artica-kavmilterd:: It seems that kavmilter is not installed');
       exit;
   end;
   TFile:=TstringList.Create;
   RegExpr:=TRegExpr.Create;
   
   
   tfile.Add(param.kavmilter_conf);
   if D then writeln('artica-kavmilterd:: Saving temporary configuration file....');
   logs.logs('artica-kavmilterd:: Saving temporary configuration file....');
   tfile.SaveToFile('/tmp/kavmilter.conf');
   if D then writeln('artica-kavmilterd:: /opt/kav/5.6/kavmilter/bin/kavmilter -c /tmp/kavmilter.conf  -t >/tmp/kavmilter.results 2>&1');

   
   RegExpr.Expression:='GroupName=(.+?)\s+';
   if DirectoryExists('/tmp/groups.d') then fpsystem('/bin/rm -rf /tmp/groups.d');
   
   forcedirectories('/tmp/groups.d');

   
   if D then writeln('artica-kavmilterd:: ' + IntToStr(param.kavmilter_rules.Count) + ' rules to save');
   logs.logs('artica-kavmilterd:: ' + IntToStr(param.kavmilter_rules.Count) + ' rules to save');
   for i:=0 to param.kavmilter_rules.Count-1 do begin
     if RegExpr.Exec(param.kavmilter_rules.Strings[i]) then begin
         if D then writeln('artica-kavmilterd:: Rule name="' + RegExpr.Match[1] + '"');

         if CheckSenderRecipients(RegExpr.Match[1],param.kavmilter_rules.Strings[i]) then begin
            tfile.Clear;
            tfile.Add(param.kavmilter_rules.Strings[i]);
            logs.logs('artica-kavmilterd::Saving rule name : "' + RegExpr.Match[1] + '" in /tmp/groups.d/' + LowerCase(RegExpr.Match[1]) + '.conf');
            tfile.SaveToFile('/tmp/groups.d/' + LowerCase(RegExpr.Match[1]) + '.conf');
         end;
     end;
   
   end;
   fpsystem('/bin/chmod -R 755 /tmp/groups.d');
   fpsystem('/opt/kav/5.6/kavmilter/bin/kavmilter -c /tmp/kavmilter.conf  -t >/tmp/kavmilter.results 2>&1');
   tfile.LoadFromFile('/tmp/kavmilter.results');

   RegExpr.Expression:='^Config\s+Error';
   for i:=0 to tfile.Count-1 do begin
       if D then writeln('artica-kavmilterd:: "'+tfile.Strings[i]+'"');
       if RegExpr.Exec(tfile.Strings[i]) then begin
           if D then writeln('artica-kavmilterd:: "Detected as error..."');
           logs.logs('artica-kavmilterd:: Error detected : "' + tfile.Strings[i] + '"');
           Error_detected:=true;
           break;
       end;
   end;
   
   if not Error_detected then begin
      logs.logs('artica-kavmilterd:: apply configuration to product....');
      if D then writeln('artica-kavmilterd::  apply configuration to product....');
      if DirectoryExists('/etc/kav/5.6/kavmilter/groups.d') then fpsystem('/bin/rm -rf /etc/kav/5.6/kavmilter/groups.d');
      fpsystem('/bin/mv /tmp/groups.d /etc/kav/5.6/kavmilter/groups.d');
      fpsystem('/bin/chmod 755 /etc/kav/5.6/kavmilter/groups.d');
      fpsystem('/bin/mv /tmp/kavmilter.conf /etc/kav/5.6/kavmilter/kavmilter.conf');
      logs.logs('artica-kavmilterd:: restart product....');
      if D then writeln('artica-kavmilterd:: restart product....');
      kavmilter:=tkavmilter.Create(GLOBAL_INI.SYS);
      kavmilter.STOP();
      kavmilter.START();
      kavmilter.free;
   end;
   
   
   

end;
//##############################################################################
function Tkavmilterd.CheckSenderRecipients(rulename:string;ruledatas:string):boolean;
   var
      RegExpr:TRegExpr;
      Error_detected:boolean;
      i:integer;

begin
    if lowerCase(rulename)='default' then exit(true);
    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='^Recipients=(.+)\s+';
     if RegExpr.Exec(ruledatas) then begin
        if D then writeln('artica-kavmilterd:: Found recipients... OK');
        logs.logs('artica-kavmilterd:: Found recipients... OK for ' + rulename);
        result:=true;
        RegExpr.Free;
        exit;
     end;
     if D then writeln('artica-kavmilterd:: Found recipients... failed in ' + rulename );
     logs.logs('artica-kavmilterd:: Found recipients... failed in ' + rulename);
     RegExpr.Free;
     exit(false);

end;



end.
