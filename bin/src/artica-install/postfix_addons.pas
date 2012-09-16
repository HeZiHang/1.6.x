
unit postfix_addons;
{$MODE DELPHI}
//{$mode objfpc}{$H+}
{$LONGSTRINGS ON}

interface

uses
Classes, SysUtils,Process,unix,global_conf,RegExpr in 'RegExpr.pas',install_common,logs,cyrus,openldap;

  type
  Tpostfix_addon=class


private
       GLOBAL_INI:MyConf;
       LOGS:tlogs;
       logout:boolean;
       mldap:Topenldap;
       ccyrus:Tcyrus;
       function ReadFileIntoString(path:string):string;
       function GetValue(value_name:string;text_path:string):string;
       procedure xfpsystem(cmd:string);
       procedure KAV_SaveAutoAnswerConf();
       procedure KAV_INSTALL_DEBIAN();
       procedure KAV_INSTALL_READHAT();


public
      Debug:boolean;
      force_to_lmtp:boolean;
      constructor Create();
      procedure Free;
      procedure AddPostfixSettings();
      function  GetContentFilter():string;
      procedure set_KasperskylmtpContentFilter(Sourceport:string;DestPort:string);
      function  GetMyHostName():string;
      procedure inet_interfaces;
      procedure set_openssl_generateKey();
      procedure SetPostFixContentFilter(port:string;destport:string);
      procedure install_kaspersky_mail_servers();
      procedure ConfigTLS();
      PROCEDURE SetLogout();
      procedure Cyrus_cyrdeliver_mode;
      procedure PROCMAIL_MASTER_CF;
      procedure PROCMAIL_PROCMAILRC;
      procedure REMOVE_MASTER_CF1_OPTIONS(regex1:string);


END;

implementation
//###############################################################################
constructor Tpostfix_addon.Create();
begin
       forcedirectories('/etc/artica-postfix');
       GLOBAL_INI:=MyConf.Create();
       LOGS:=tlogs.Create;
       LOGS.Enable_echo:=logout;
       mldap:=topenldap.Create;
       ccyrus:=Tcyrus.Create(GLOBAL_INI.SYS);
end;
//###############################################################################
PROCEDURE Tpostfix_addon.SetLogout();
begin
   logout:=True;
   LOGS.Enable_echo_install:=logout;
end;
//###############################################################################
PROCEDURE Tpostfix_addon.Free();
begin
   GLOBAL_INI.Free;
   LOGS.Free;
end;
//###############################################################################
function Tpostfix_addon.GetMyHostName():string;
var cm:Tcommon;
myhostname:string;
begin
  xfpsystem('/usr/sbin/postconf >/tmp/postconf');
   myhostname:=GetValue('myhostname','/tmp/postconf');
   if length(myhostname)=0 then begin
      cm:=Tcommon.Create();
      myhostname:=cm.ExecPipe('/bin/hostname -f',false);
   end;
   result:=Trim(myhostname);
end;


//###############################################################################
procedure Tpostfix_addon.AddPostfixSettings();
     var
        database_files:string;
        queue_directory:string;
        myFile:TextFile;
        myhostname,yesno:string;
        RegExpr:TRegExpr;
     begin

  writeln('Strip nested "#" in main.cf (prevent bugs postfix parser)');
  GLOBAL_INI.set_FileStripDiezes('/etc/postfix/main.cf');

  xfpsystem('/usr/sbin/postconf >/tmp/postconf');
  queue_directory:=GetValue('queue_directory','/tmp/postconf');
  myhostname:=GetMyHostName();

 writeln('Queue Directory..............: ' + queue_directory);
 writeln('myhostname...................: ' + myhostname);
 writeln('Domain name..................: ' + GLOBAL_INI.get_LINUX_DOMAIN_NAME());
 

 RegExpr:=TRegExpr.create;
 RegExpr.expression:='([a-zA-Z0-9]+)\.([a-zA-Z0-9]+)\.([a-zA-Z0-9]+)';
 if not RegExpr.Exec(myhostname)  then begin
     writeln('');
     writeln('it seems that your hostname (' + myhostname +') is not fully qualified domain name (fqdn)');
     writeln('Like "server.domain.tn"');
     writeln('Do you want to change this to a fqdn server ? (yes/no)');
     readln(yesno);
     if yesno='yes' then begin
              writeln('Set your server name fqdn:');
              readln(myhostname);
              if length(myhostname)>0 then begin
                xfpsystem('/usr/sbin/postconf -e myhostname=' + myhostname);
                AddPostfixSettings();
                exit;
              end;
     end;
 
 end;

     inet_interfaces;


     database_files:=GLOBAL_INI.get_POSTFIX_HASH_FOLDER();
     forceDirectories(database_files);

     writeln('Creating - updating: ' + database_files + '/header_checks.cf ...');
    if not fileExists(database_files + '/header_checks.cf') then begin
       AssignFile(myFile, database_files + '/header_checks.cf');
       ReWrite(myFile);
       CloseFile(myFile)
    end;
    xfpsystem('/usr/sbin/postconf -e header_checks=regexp:' + database_files + '/header_checks.cf');



    writeln('Creating - updating: ' + database_files + '/body_checks.cf ...');
    if not fileExists(database_files + '/body_checks.cf') then begin
       AssignFile(myFile, database_files + '/body_checks.cf');
       ReWrite(myFile);
       CloseFile(myFile)
    end;
    xfpsystem('/usr/sbin/postconf -e body_checks=regexp:' + database_files + '/body_checks.cf');

    writeln('Creating - updating: ' + database_files + '/mime_header_checks.cf ...');
    if not fileExists(database_files + '/mime_header_checks.cf') then begin
       AssignFile(myFile, database_files + '/mime_header_checks.cf');
       ReWrite(myFile);
       CloseFile(myFile)
    end;
    xfpsystem('/usr/sbin/postconf -e mime_header_checks=regexp:' + database_files + '/mime_header_checks.cf');

end;

//###############################################################################
procedure Tpostfix_addon.ConfigTLS();
    var smtpd_recipient_restrictions:string;
    list:TstringList;
begin
     LOGS.logsInstall('Tpostfix_addon.ConfigTLS -> Tpostfix_addon.set_openssl_generateKey()');
     set_openssl_generateKey();
     if not FileExists('/etc/certificates/smtpd.key') then begin
             LOGS.logsInstall('Tpostfix_addon.ConfigTLS -> /etc/certificates/smtpd.key doesn''t exist aborting...');
             exit;
     end;
     smtpd_recipient_restrictions:='permit_mynetworks,permit_sasl_authenticated,reject_non_fqdn_hostname,';
     smtpd_recipient_restrictions:=smtpd_recipient_restrictions + 'reject_non_fqdn_sender,reject_non_fqdn_recipient,reject_unauth_destination,';
     smtpd_recipient_restrictions:=smtpd_recipient_restrictions + 'reject_unauth_pipelining,reject_invalid_hostname,reject_rbl_client opm.blitzed.org,reject_rbl_client list.dsbl.org,reject_rbl_client bl.spamcop.net,reject_rbl_client sbl-xbl.spamhaus.org';
     
     LOGS.logsInstall('Tpostfix_addon.ConfigTLS -> execute postconf');
     xfpsystem('/usr/sbin/postconf -e smtpd_tls_cert_file=/etc/certificates/smtpd.key');
     xfpsystem('/usr/sbin/postconf -e smtpd_tls_key_file=/etc/certificates/smtpd.key');
     xfpsystem('/usr/sbin/postconf -e smtpd_sasl_auth_enable=yes');
     xfpsystem('/usr/sbin/postconf -e smtpd_sasl_local_domain=$myhostname');
     xfpsystem('/usr/sbin/postconf -e smtpd_sasl_security_options=noanonymous');
     xfpsystem('/usr/sbin/postconf -e broken_sasl_auth_clients=yes');
     xfpsystem('/usr/sbin/postconf -e ''smtpd_recipient_restrictions=' + smtpd_recipient_restrictions+ '''');
     xfpsystem('/usr/sbin/postconf -e smtpd_tls_loglevel=1');
     xfpsystem('/usr/sbin/postconf -e smtpd_tls_received_header=yes');
     xfpsystem('/usr/sbin/postconf -e smtpd_tls_session_cache_timeout=3600s');
     xfpsystem('/usr/sbin/postconf -e smtp_use_tls=yes');
     xfpsystem('/usr/sbin/postconf -e smtpd_use_tls=yes');
     xfpsystem('/usr/sbin/postconf -e smtp_tls_note_starttls_offer=yes');
     
     list:=TstringList.Create;
     list.Add('START=yes');
     list.Add('MECHANISMS="pam"');
     list.Add('PARAMS="-r"');
     LOGS.logsInstall('Tpostfix_addon.ConfigTLS ->modify /etc/default/saslauthd file');
     list.SaveToFile('/etc/default/saslauthd');
     list.Free;
     fpsystem('/etc/init.d/saslauthd restart');
end;
//###############################################################################


function Tpostfix_addon.ReadFileIntoString(path:string):string;
         const
            CR = #$0d;
            LF = #$0a;
            CRLF = CR + LF;
var
   i:integer;
   datas_file:string;
   list:TstringList;
   
begin

      if not FileExists(path) then begin
        writeln('Error:thProcThread.ReadFileIntoString -> file not found (' + path + ')');
        exit;

      end;
      datas_file:='';
      list:= TstringList.Create;
      list.LoadFromFile(path);
      for i:=0 to list.Count -1 do begin
        datas_file:=datas_file + list.Strings[i]+CRLF;
      end;
      result:=datas_file;

      exit;



end;
//###############################################################################
function Tpostfix_addon.GetValue(value_name:string;text_path:string):string;
var
RegExpr:TRegExpr;
   Index:integer;
   FileDatas:TStringList;
begin
    FileDatas:=TStringList.Create;
   if FileExists(text_path) then FileDatas.LoadFromFile(text_path);
   if not FileExists(text_path) then begin
        writeln('unable to locate ' + text_path);
        exit();
   end;
   RegExpr:=TRegExpr.create;
   RegExpr.expression:=value_name + '(|\s+)=(|\s+)(.+)?';
   for Index := 0 to FileDatas.Count - 1 do  begin
       if  RegExpr.Exec(FileDatas.Strings[Index]) then begin
              result:=RegExpr.Match[3];
              RegExpr.Free;
              FileDatas.Free;
              exit;
       end;
   end;
   FileDatas.Free;
   RegExpr.Free;

end;

//###############################################################################
function Tpostfix_addon.GetContentFilter():string;
var
RegExpr:TRegExpr;
   datas:string;
begin
     if not FileExists('/etc/postfix/master.cf') then exit;
     datas:=ReadFileIntoString('/etc/postfix/master.cf');
     RegExpr:=TRegExpr.create;
     RegExpr.expression:='^smtp\s+inet\s+.*smtpd\s*-o content_filter=([a-z\:_0-9\.-]+)';
     if  RegExpr.Exec(datas) then result:=RegExpr.Match[1];
    RegExpr.Free;
end;
//###############################################################################
procedure Tpostfix_addon.inet_interfaces;
var
   RegExpr:TRegExpr;
   datas:string;
   Minet_interfaces:string;
begin
RegExpr:=TRegExpr.create;
Minet_interfaces:='';
RegExpr.Expression:='eth[0-9]\:\[([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\]';
datas:=GLOBAL_INI.get_LINUX_INET_INTERFACES();
if RegExpr.Exec(datas) then  repeat;
    Minet_interfaces:=Minet_interfaces+RegExpr.Match[1] + ',';
until not RegExpr.ExecNext;
    Minet_interfaces:=Minet_interfaces+'127.0.0.1';
    writeln('Set inet_interfaces to all' + Minet_interfaces);
    xfpsystem('/usr/sbin/postconf -e inet_interfaces=all');
end;
//###############################################################################
procedure Tpostfix_addon.Cyrus_cyrdeliver_mode;
var
   cyr_deliver_path:string;
   list:TstringList;i:integer;
   found:boolean;
   RegExpr:TRegExpr;
begin
      cyr_deliver_path:=GLOBAL_INI.CYRUS_DELIVER_BIN_PATH();
      if length(cyr_deliver_path)=0 then begin
               writeln('Unable to get cyrdeliver binary path');
               exit;
      end;
      
      
      if not FileExists(cyr_deliver_path) then begin
          writeln('Unable to stat cyrdeliver binary path : ' + cyr_deliver_path);
          exit;
      end;
      
      found:=false;
      list:= TstringList.Create;
      list.LoadFromFile('/etc/postfix/master.cf');
      RegExpr:=TRegExpr.create;
      RegExpr.expression:='^cyrus\s+unix\s+.*pipe';
      for i:=0 to list.Count -1 do begin
          if RegExpr.Exec(list[i]) then begin
             if found=false then begin
                writeln('Cyrus pipe found change settings ....');
                list.Strings[i]:='cyrus'+ chr(9) + 'unix' + chr(9) + '-' + chr(9) + 'n' + chr(9) + 'n' + chr(9) + '-' + chr(9) + '-' + chr(9) + 'pipe';
                RegExpr.expression:='flags=.*user=cyrus\s+argv=.*cyr.*';
                found:=True;
             end;
             
             if found=true then begin
                 writeln('Cyrus argv found change settings ....');
                 list.Strings[i]:=chr(9) +'flags= user=cyrus argv=' + cyr_deliver_path + ' -e -r ${sender} -m ${extension} ${user}';
             end;
             
             
          end;

      end;

      writeln('Cyrdeliver not found adding new settings...');

       if found=false then begin
         list.Add('cyrus'+ chr(9) + 'unix' + chr(9) + '-' + chr(9) + 'n' + chr(9) + 'n' + chr(9) + '-' + chr(9) + '-' + chr(9) + 'pipe');
         list.Add(chr(9) +'flags= user=cyrus argv=' + cyr_deliver_path + ' -e -r ${sender} -m ${extension} ${user}');
         list.SaveToFile('/etc/postfix/master.cf');
      end;
      
  writeln('Adding Cyrus in master.cf done');
  writeln('Change mailbox_transport in main.cf');
  xfpsystem('/usr/sbin/postconf -e mailbox_transport=cyrus');
  writeln('Change virtual_transport in main.cf');
  xfpsystem('/usr/sbin/postconf -e virtual_transport=cyrus');
  xfpsystem('/usr/sbin/postconf -e mailbox_command=');
  list.Free;
  RegExpr.free;
end;
//###############################################################################
procedure Tpostfix_addon.REMOVE_MASTER_CF1_OPTIONS(regex1:string);
var
   master_cf:Tstringlist;
   RegExpr:TRegExpr;
   i:integer;
   found:boolean;
begin
  found:=false;
  master_cf:=Tstringlist.Create;
  RegExpr:=TRegExpr.Create;
  RegExpr.Expression:=regex1;
  writeln('search: ' + regex1);
     master_cf.LoadFromFile('/etc/postfix/master.cf');
     for i:=0 to master_cf.Count-1 do begin
         if RegExpr.exec(master_cf.Strings[i]) then begin
             found:=True;
             writeln('remove line ' + master_cf.Strings[i] + ' ' + IntTostr(i) + '/' + IntTostr(master_cf.Count));
             master_cf.Delete(i);
             break;
         end;
     end;
  if found=false then writeln('REMOVE_MASTER_CF1_OPTIONS -> not found pattern');
  master_cf.SaveToFile('/etc/postfix/master.cf');
  master_cf.free;
  RegExpr.free;
end;
//###############################################################################


procedure Tpostfix_addon.PROCMAIL_MASTER_CF;
var
   list:TstringList;
begin

      REMOVE_MASTER_CF1_OPTIONS('^procmail\s+unix\s+.*pipe');
      REMOVE_MASTER_CF1_OPTIONS('flags=.*user=([a-z]+)\s+argv=\/usr\/bin\/proc.*');

      list:= TstringList.Create;
      list.LoadFromFile('/etc/postfix/master.cf');
         list.Add('procmail'+ chr(9) + 'unix' + chr(9) + '-' + chr(9) + 'n' + chr(9) + 'n' + chr(9) + '-' + chr(9) + '-' + chr(9) + 'pipe');
         list.Add(chr(9) +'flags=R user=cyrus argv=/usr/bin/procmail -t -m USER=${user} EXTENSION=${extension} /etc/procmailrc');
         list.SaveToFile('/etc/postfix/master.cf');


  writeln('Adding procmail in master.cf done');
  writeln('Change mailbox_transport in main.cf');
  xfpsystem('/usr/sbin/postconf -e mailbox_transport=procmail');
  writeln('Change virtual_transport in main.cf');
  xfpsystem('/usr/sbin/postconf -e virtual_transport=procmail');
  xfpsystem('/usr/sbin/postconf -e ''mailbox_command = /usr/bin/procmail -t -a "$EXTENSION"''');
  list.Free;

end;
//###############################################################################
procedure Tpostfix_addon.PROCMAIL_PROCMAILRC;
var FileDatas:TstringList;
cyr_deliver_path:string;

begin

     cyr_deliver_path:=GLOBAL_INI.CYRUS_DELIVER_BIN_PATH();
      if length(cyr_deliver_path)=0 then begin
               writeln('Unable to get cyrdeliver binary path');
               exit;
      end;


      if not FileExists(cyr_deliver_path) then begin
          writeln('Unable to stat cyrdeliver binary path : ' + cyr_deliver_path);
          exit;
      end;
      

      

   FileDatas:=TstringList.Create;
   FileDatas.Add('DELIVERTO="' + cyr_deliver_path + '"');
   FileDatas.Add('USERINBOX="$DELIVERTO -e -a $USER -m user/$USER"');
   FileDatas.Add('LOGFILE="/var/log/procmail/procmail.log"');
   FileDatas.Add('VERBOSE=yes');
   FileDatas.Add('LOGABSTRACT=all');
   FileDatas.Add(':0 w');
   FileDatas.Add('| $USERINBOX');
   FileDatas.SaveToFile('/etc/procmailrc');
   FileDatas.Free;
   writeln('Save /etc/procmailrc done.');
   ForceDirectories('/var/log/procmail');
   fpsystem('/bin/chown cyrus /var/log/procmail');

end;


procedure Tpostfix_addon.set_KasperskylmtpContentFilter(Sourceport:string;DestPort:string);
var
RegExpr:TRegExpr;
    list:TstringList;i:integer;
    myhostname:string;
begin
     if not FileExists('/etc/postfix/master.cf') then exit;
      list:= TstringList.Create;
      list.LoadFromFile('/etc/postfix/master.cf');
     RegExpr:=TRegExpr.create;
     RegExpr.expression:='^smtp\s+inet\s+.*smtpd';
     
      for i:=0 to list.Count -1 do begin
         if RegExpr.Exec(list.Strings[i]) then begin
              writeln('found in '  + list[i]);
              list.Insert(i+1,chr(9)+'-o content_filter=lmtp:127.0.0.1:' + Sourceport);
         end;
      end;
      
    RegExpr.expression:='^pickup\s+fifo\s+.*pickup';
      for i:=0 to list.Count -1 do begin
         if RegExpr.Exec(list.Strings[i]) then begin
              writeln('found in '  + list[i]);
              list.Insert(i+1,chr(9)+'-o content_filter=lmtp:127.0.0.1:' + Sourceport);
         end;
      end;
      myhostname:=GetMyHostName();
      list.Add('127.0.0.1:' + Sourceport + chr(9) + 'inet' + chr(9) + 'n' + chr(9) + 'n' + chr(9) + 'n' + chr(9) + '-' + chr(9) + '20' + chr(9) + 'spawn' );
      list.Add(chr(9) + 'user=kluser   argv=/opt/kav/5.5/kav4mailservers/bin/smtpscanner');
      list.Add('127.0.0.1:' + DestPort + chr(9) + 'inet' + chr(9) + 'n' + chr(9) + '-' + chr(9) + 'n' + chr(9) + '-' + chr(9) + '21' + chr(9) + 'smtpd' );
      list.Add(chr(9)+'-o content_filter=');
      list.Add(chr(9)+'-o local_recipient_maps=');
      list.Add(chr(9)+'-o relay_recipient_maps=');
      list.Add(chr(9)+'-o smtpd_restriction_classes=');
      list.Add(chr(9)+'-o smtpd_client_restrictions=');
      list.Add(chr(9)+'-o smtpd_helo_restrictions=');
      list.Add(chr(9)+'-o smtpd_sender_restrictions=');
      list.Add(chr(9)+'-o mynetworks=127.0.0.0/8');
      list.Add(chr(9)+'-o strict_rfc821_envelopes=yes');
      list.Add(chr(9)+'-o smtpd_error_sleep_time=0');
      list.Add(chr(9)+'-o smtpd_soft_error_limit=1001');
      list.Add(chr(9)+'-o smtpd_hard_error_limit=1000');
      list.Add(chr(9)+'-o myhostname=' + myhostname);
      list.SaveToFile('/etc/postfix/master.cf');
      list.free;
end;
//###############################################################################
procedure Tpostfix_addon.set_openssl_generateKey();
var
   cmd,domain:string;
begin
if not FileExists('/usr/bin/openssl') then begin
    LOGS.logsInstall('Tpostfix_addon.set_openssl_generateKey ->/usr/bin/openssl doesn''t exits');
    exit;
end;
ForceDirectories('/etc/postfix/certificates');

domain:=GLOBAL_INI.get_LINUX_DOMAIN_NAME();
LOGS.logsInstall('Tpostfix_addon.set_openssl_generateKey -> domain "' + domain + '"');
cmd:='/usr/bin/openssl ';
cmd:=cmd + ' ' + 'req -new -outform PEM -out';
cmd:=cmd + ' ' + '/etc/postfix/certificates/smtpd.cert';
cmd:=cmd + ' ' + '-newkey rsa:2048 -nodes';
cmd:=cmd + ' ' + '-subj ''/CN=' + domain + '/O=' + domain + ', Inc./C=FR/ST=IDF/L=PARIS''';
cmd:=cmd + ' ' + '-keyout /etc/postfix/certificates/smtpd.key -keyform PEM -days 365 -x509 -batch';
xfpsystem(cmd);
end;
procedure Tpostfix_addon.xfpsystem(cmd:string);
begin
  LOGS.logsInstall('Tpostfix_addon.xShell -> "' + cmd + '"');
  fpsystem(cmd);
end;
//##############################################################################
procedure Tpostfix_addon.SetPostFixContentFilter(port:string;destport:string);
var  postfix:Tpostfix_addon;
content_filter:string;
begin
  writeln('Set smtp content filter from socket ' + port + ' socket ' + destport);
  postfix:=Tpostfix_addon.Create();
  content_filter:=postfix.GetContentFilter();
  if length(content_filter)>0 then begin
     writeln('content_filter already set: ' + content_filter);
  end;
   writeln('Setting redirection to Kaspersky Content filter in master.cf');
   postfix.set_KasperskylmtpContentFilter(port,destport);



  postfix.Free;
end;
//###############################################################################

procedure Tpostfix_addon.KAV_SaveAutoAnswerConf();
var
   autoanswers_conf:TStringList;
   GLOBAL_INI:myConf;


begin
    GLOBAL_INI:=myConf.Create;

         autoanswers_conf:=TStringList.Create;
         autoanswers_conf.Add('CONFIGURE_ENTER_KEY_PATH=' + GLOBAL_INI.get_INSTALL_PATH() + '/bin/install');
         autoanswers_conf.Add('KAVMS_SETUP_LICENSE_DOMAINS=*');
         autoanswers_conf.Add('CONFIGURE_KEEPUP2DATE_ASKPROXY=no');
         autoanswers_conf.Add('CONFIGURE_RUN_KEEPUP2DATE=no');
         autoanswers_conf.Add('CONFIGURE_WEBMIN_ASKCFGPATH=');
         autoanswers_conf.SaveToFile('/opt/kav/5.5/kav4mailservers/setup/autoanswers.conf');
         autoanswers_conf.Free;
         GLOBAL_INI.Free;

end;
//###############################################################################
procedure Tpostfix_addon.install_kaspersky_mail_servers();
begin
writeln('INSTALLING KASPERSKY FOR UNIX MAIL SERVERS....');

if FileExists('/usr/bin/dpkg') then KAV_INSTALL_DEBIAN();
if FileExists('/bin/rpm') then KAV_INSTALL_READHAT();
   if FileExists('/opt/kav/5.5/kav4mailservers/bin/keepup2date') then begin
      writeln('updating av databases please wait for few minutes');
      fpsystem('/opt/kav/5.5/kav4mailservers/bin/keepup2date >/tmp/keepUp2Date.log &');
   end;


end;
//############################################################################### 

procedure Tpostfix_addon.KAV_INSTALL_READHAT();
begin
writeln('INSTALLING KASPERSKY FOR UNIX MAIL SERVERS (readhat mode)');



if FileExists('/etc/init.d/aveserver') then begin
         writeln('/etc/init.d/aveserver exists');
         writeln('product is already installed.. Reconfigure it...');
         KAV_SaveAutoAnswerConf();
         fpsystem('cd /opt/kav/5.5/kav4mailservers/setup &&  ./postinstall.pl');
         writeln('Exit...');
         exit();
end;



       if Not FileExists('/var/artica-postfix/addons/kav4mailservers-linux-5.5-33.i386.rpm') then begin
         if not FileExists('/usr/bin/wget') then begin
             writeln('Unable to locate wget program !!, aborting...');
             exit;
         end;
         
         forcedirectories('/var/artica-postfix/addons');
         writeln('Downloading Kaspersky for Mail server product from uri http://www.artica.fr/download/kav4mailservers-linux-5.5-33.i386.rpm...');
         fpsystem('/usr/bin/wget http://www.artica.fr/download/kav4mailservers-linux-5.5-33.i386.rpm  --output-document=/var/artica-postfix/addons/kav4mailservers-linux-5.5-33.i386.rpm');
         if Not FileExists('/var/artica-postfix/addons/kav4mailservers-linux-5.5-33.i386.rpm') then begin
                writeln('Unable to download Kaspersky Product');
                exit();
         end;
       end;

         writeln('Installing package...');
         fpsystem('/bin/rpm -i  /var/artica-postfix/addons/kav4mailservers-linux-5.5-33.i386.rpm');
         if not FileExists('/opt/kav/5.5/kav4mailservers/setup/setup.pl') then begin
            writeln('Error while installing Kaspersky For Mail server');
            if FileExists('/var/artica-postfix/addons/kav4mailservers-linux-5.5-33.i386.rpm') then fpsystem('/bin/rm /var/artica-postfix/addons/kav4mailservers-linux-5.5-33.i386.rpm');
            exit;
         end;

         KAV_SaveAutoAnswerConf();
         fpsystem('cd /opt/kav/5.5/kav4mailservers/setup && ./postinstall.pl');



   if fileExists('/opt/kav/5.5/kav4mailservers/setup/autoanswers.conf') then fpsystem('/bin/rm /opt/kav/5.5/kav4mailservers/setup/autoanswers.conf');

end;


procedure Tpostfix_addon.KAV_INSTALL_DEBIAN();
begin
writeln('INSTALLING KASPERSKY FOR UNIX MAIL SERVERS (debian mode)');



if FileExists('/etc/init.d/aveserver') then begin
         writeln('/etc/init.d/aveserver exists');
         writeln('product is already installed.. Reconfigure it...');
         KAV_SaveAutoAnswerConf();
         fpsystem('cd /opt/kav/5.5/kav4mailservers/setup && /usr/sbin/dpkg-reconfigure kav4mailservers-linux55');
         writeln('Exit...');
         exit();
end;



       if Not FileExists('/var/artica-postfix/addons/kav4mailservers-linux-5.5.33.deb') then begin
         if not FileExists('/usr/bin/wget') then fpsystem('apt-get install wget');
         forcedirectories('/var/artica-postfix/addons');
         writeln('Downloading Kaspersky for Mail server product from uri http://www.artica.fr/download/kav4mailservers-linux-5.5.33.deb...');
         fpsystem('/usr/bin/wget http://www.artica.fr/download/kav4mailservers-linux-5.5.33.deb  --output-document=/var/artica-postfix/addons/kav4mailservers-linux-5.5.33.deb');
         if Not FileExists('/var/artica-postfix/addons/kav4mailservers-linux-5.5.33.deb') then begin
                writeln('Unable to download Kaspersky Product');
                exit();
         end;
       end;

         writeln('Installing package...');
         fpsystem('/usr/bin/dpkg --unpack /var/artica-postfix/addons/kav4mailservers-linux-5.5.33.deb');
         if not FileExists('/opt/kav/5.5/kav4mailservers/setup/setup.pl') then begin
            writeln('Error while installing Kaspersky For Mail server');
            if FileExists('/var/artica-postfix/addons/kav4mailservers-linux-5.5.33.deb') then fpsystem('/bin/rm /var/artica-postfix/addons/kav4mailservers-linux-5.5.33.deb');
            exit;
         end;

         KAV_SaveAutoAnswerConf();
         fpsystem('cd /opt/kav/5.5/kav4mailservers/setup && /usr/bin/dpkg --configure kav4mailservers-linux55');



   if fileExists('/opt/kav/5.5/kav4mailservers/setup/autoanswers.conf') then fpsystem('/bin/rm /opt/kav/5.5/kav4mailservers/setup/autoanswers.conf');



end;

end.

