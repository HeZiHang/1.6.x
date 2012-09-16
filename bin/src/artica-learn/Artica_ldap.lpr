program Artica_ldap;

{$mode objfpc}{$H+}

uses
  Classes,logs,unix,BaseUnix,SysUtils,RegExpr,articaldap,global_conf,ldapconf,samba,zsystem,strutils,kav4proxy,
  fetchmail;

var
GLOBAL_INI:myconf;
tempfile:TstringList;
y,tmppath:string;
xldap:Tarticaldap;
i:Integer;
sfetchmail               :fetchmail_settings;
inadyn                  :inadyn_settings;
proxy                   :http_proxy_settings;
XSETS                   :tldapconf;
xsamba                  :tsamba;
zlogs                   :Tlogs;
SYS                     :Tsystem;
zkav4proxy              :Tkav4proxy;
Dfetchmail              :tfetchmail;
//##############################################################################

begin
if ParamStr(1)='-iptables' then begin
     GLOBAL_INI:=myconf.Create;
     tmppath:=GLOBAL_INI.IPTABLES_PATH();
     if GLOBAL_INI.Get_INFOS('IptablesEnabled')='1' then begin
        if FileExists(tmppath) then begin
         fpsystem(tmppath + ' -F');
         fpsystem(tmppath + ' -X');
         fpsystem(tmppath + ' -P INPUT ACCEPT');
       end;
     end;
end;


  xldap:=Tarticaldap.Create;
  XSETS:=tldapconf.Create();
  SYS:=Tsystem.Create;
  zlogs:=Tlogs.Create;
  

if ParamStr(1)='-backups' then begin
   XSETS.Enable_postfixmodules();
   XSETS.free;
   Halt(0);
end;

if ParamStr(1)='--fetchmail-understand' then begin
   XSETS.UNDERSTAND_fetchmailrc();
   XSETS.free;
   Halt(0);
end;

if ParamStr(1)='--wbld' then begin
   XSETS.SpamAssassin_whitelistBlacklist();
   XSETS.free;
   Halt(0);
end;


if ParamStr(1)='-modules' then begin
   XSETS.Enable_postfixmodules();
   XSETS.free;
   Halt(0);
end;


if ParamStr(1)='-mailboxes' then begin
   XSETS.mailboxes_sync();
   XSETS.free;
   Halt(0);
end;

if ParamStr(1)='-mailbox' then begin
   XSETS.mailbox_sync(ParamStr(2));
   XSETS.free;
   Halt(0);
end;


if ParamStr(1)='-kavmilter' then begin
   XSETS.kavmilter_settings();
   XSETS.free;
   Halt(0);
end;

  
// ===================== garde fous ===========================================
  
  if not SYS.BuildPids() then begin
     zlogs.Debuglogs('Stop process other process using this command...');
     halt(0);
  end;
  
if ParamStr(1)='-fdm' then begin
   if ParamStr(2)<>'--verbose' then begin
      if not SYS.croned_minutes2(10) then begin
         zlogs.logs('Not time to execute...');
         halt(0);
      end;

      zlogs.logs('Executing FDM procedure...');
      XSETS.fdm_exec();
      FreeAndNil(XSETS);
    end;
     halt(0);
end;
  
  
 if ParamStr(1)='--cyrreconstruct' then begin
    XSETS.cyrreconstruct();
    XSETS.free;
    Halt(0);
 end;
 
 if ParamStr(1)='--cyrrepair' then begin
    XSETS.cyrrepair();
    XSETS.free;
    Halt(0);
 end;
 
 
 if ParamStr(1)='--repair-mailbox' then begin
     XSETS.repair_mailbox(ParamStr(2),ParamStr(3));
     XSETS.free;
    Halt(0);
 end;

 if ParamStr(1)='-sa-learn' then begin
     XSETS.sa_learn();
     XSETS.free;
    Halt(0);
 end;
  
 if ParamStr(1)='-mimedefang' then begin
    XSETS.mimedefang();
    halt(0);
 end;
 
 
if ParamStr(1)='--bind9-compile' then begin
   XSETS.Bind_Compile();
   XSETS.free;
   halt(0);
end;
 
 if ParamStr(1)='chmodsmb' then begin
    xsamba:=Tsamba.Create;
    xsamba.FixDirectoriesChmod();
    halt(0);
 end;
 
  if ParamStr(1)='-fetchmail' then begin
     GLOBAL_INI:=myconf.Create;
      XSETS.Enable_postfixmodules();
      Dfetchmail:=tfetchmail.Create(GLOBAL_INI.SYS);
      sfetchmail:=xldap.Load_Fetchmail_settings();
      Dfetchmail.FETCHMAIL_APPLY_CONF(sfetchmail.fetchmailrc);
      halt(0);
  end;
  
   if ParamStr(1)='-dansguardian' then begin
      XSETS.Dansguardian();
      halt(0);
  end;

  
  if ParamStr(1)='-kav4proxy' then begin
         y:=xldap.Load_Kav4proxy_settings();
         GLOBAL_INI:=myconf.Create;
         zkav4proxy:=Tkav4proxy.Create(GLOBAL_INI.SYS);
         if length(y)>0 then begin
            tempfile:=TStringList.Create;
            tempfile.Add(xldap.Load_Kav4proxy_settings());
            tempfile.SaveToFile(zkav4proxy.CONF_PATH());
            zkav4proxy.KAV4PROXY_STOP();
            zkav4proxy.KAV4PROXY_START();
            halt(0);
         end;
  end;
  
if ParamStr(1)='-squid' then begin
  XSETS.squid(ParamStr(2));
  halt(0);
end;


if ParamStr(1)='-kav4samba' then begin
  XSETS.kav4samba_save();
  XSETS.free;
  halt(0);
end;


if ParamStr(1)='-ftp-users' then begin
    XSETS.FtpUsers();
    XSETS.free;
    halt(0);
end;

if ParamStr(1)='-sqlgrey' then begin
  if length(ParamStr(2))=0 then begin
     writeln('no servername specified');
     halt(0);
  end;


   XSETS.sqlgrey(ParamStr(2));
   XSETS.free;
  halt(0);
end;

if ParamStr(1)='-maincf' then begin
   zlogs.Debuglogs('Execute function maincf()...');
   XSETS.maincf();
   XSETS.free;
   halt(0);
end;

if ParamStr(1)='-spamass' then begin
   XSETS.SpamAssassin();
   XSETS.free;
   halt(0);
   end;
   


if ParamStr(1)='-milter-greylist' then begin
   XSETS.milter_greylist();
   XSETS.free;
   Halt(0);
end;

if ParamStr(1)='-obm-sys' then begin
   XSETS.OBM_OPERATIONS();
   XSETS.free;
   Halt(0);
end;

if ParamStr(1)='-ntpd' then begin
   XSETS.NTPD();
   XSETS.free;
   Halt(0);
end;

if ParamStr(1)='-iptables' then begin
   writeln('Starting......: verify iptables tables...');
   XSETS.iptables();
   XSETS.free;
   Halt(0);
end;

if ParamStr(1)='-modules' then begin
   XSETS.Enable_postfixmodules();
   XSETS.free;
   Halt(0);
end;


if ParamStr(1)='-nmaps' then begin
   XSETS.NMAP_SINGLE(ParamStr(2));
   XSETS.free;
   Halt(0);
end;


if ParamStr(1)='-samba' then begin
     XSETS.samba();
     XSETS.free;
     Halt(0);
end;

if ParamStr(1)='-userinfo' then begin
     xldap.UserDataFromMail(ParamStr(2));
     XSETS.free;
     Halt(0);
end;

if ParamStr(1)='-cyrus' then begin
     XSETS.cyrusconfig();
     XSETS.free;
     Halt(0);
end;


if ParamStr(1)='-localdomains' then begin
     XSETS.localdomains();
     XSETS.free;
     Halt(0);
end;

if ParamStr(1)='-pnetworks' then begin
     XSETS.pnetworks();
     XSETS.free;
     Halt(0);
end;

if ParamStr(1)='-dkimfilter' then begin
     XSETS.dkimfilter();
     Halt(0);
end;

if ParamStr(1)='-nmap' then begin
     if FileExists(ParamStr(2)) then begin
           XSETS.NMAP_scan_results(ParamStr(2));
           XSETS.free;
           halt(0);
     end;
     XSETS.NMAP();
     XSETS.free;
     Halt(0);
end;


   

if ParamStr(1)='--testldap' then begin
     XSETS.Testldap_cmdline();
     XSETS.free;
     halt(0);
end;

if ParamStr(1)='--getlive' then begin
     Dfetchmail:=tfetchmail.Create(SYS);
     Dfetchmail.FETCHMAIL_APPLY_GETLIVE();
     halt(0);
end;


  
  if ParamStr(1)='-getlive' then begin
      writeln('no longer supported, use "--getlive" instead');
      halt(0);
      halt(0);
  end;
  
  if ParamStr(1)='-cyrus-restore' then begin
         xldap.DeleteCyrusUser();
         xldap.CreateCyrusUser();
         halt(0);
  end;
  if ParamStr(1)='-inadyn' then begin
         GLOBAL_INI:=myconf.Create;
         GLOBAL_INI.INADYN_PERFORM_STOP();
         inadyn:=xldap.Load_inadyn_settings();
         if inadyn.ArticaInadynRule.Count >0 then begin
            if StrToInt(inadyn.ArticaInadynPoolRule)>0 then begin
               for i:=0 to inadyn.ArticaInadynRule.Count -1 do begin
                   GLOBAL_INI.INADYN_PERFORM(inadyn.ArticaInadynRule.Strings[i]+inadyn.proxy_settings.IniSettings,StrToInt(inadyn.ArticaInadynPoolRule));
               end;
            end;
         end;
         halt(0);
  end;
  

  
  
  
//------------------------------------------------------------------------------
  if ParamStr(1)='-proxy' then begin
      proxy:=xldap.Load_proxy_settings();
      writeln('Enabled.............:' + proxy.ArticaProxyServerEnabled);
      writeln('Server..............:' + proxy.ArticaProxyServerName + ':' +proxy.ArticaProxyServerPort);
      writeln('Username............:' + proxy.ArticaProxyServerUsername + ':' + proxy.ArticaProxyServerUserPassword);
      halt(0);
  
  end;
//------------------------------------------------------------------------------

  

   if ParamStr(1)='-secu-level' then begin
       XSETS.ApplySecuLevel();
       halt(0);
   end;
 





   if ParamStr(1)='--maintenance' then begin
    if SYS.croned_minutes2(10) then begin
       zlogs.Debuglogs('Execute maintenance operation...');
       XSETS.Enable_postfixmodules();
       XSETS.FoldersSizeConfig();
       XSETS.maintenance();
       XSETS.fdm_exec();
    end else begin
        zlogs.Debuglogs('Too early needs 10minutes');
    end;
    
       XSETS.free;
       halt(0);
   end;
   
   if ParamStr(1)='-amavis' then begin
       XSETS.Amavis();
       XSETS.free;
       halt(0);
   end;

   if ParamStr(1)='-crossroads' then begin
       if ParamStr(2)='sync' then begin
          zlogs.logs('Synchronize slaves servers for crossroads');
          XSETS.crossroads_sync();
          XSETS.free;
          halt(0);
       end;
       
       if ParamStr(2)='apply' then begin
          XSETS.crossroads_apply(ParamStr(3));
          XSETS.free;
          halt(0);
       end;
       
   end;


if ParamStr(1)='-syncmodules' then begin
     if ParamStr(2)='--force' then begin
          XSETS.Enable_postfixmodules();
          XSETS.free;
          halt(0);
     end;
     if SYS.croned_minutes() then begin
        XSETS.Enable_postfixmodules();
        XSETS.free;
     end;
     Halt(0);
end;


if ParamStr(1)='-sharedfolders' then begin
     XSETS.SharedFolders();
     XSETS.free;
     Halt(0);
end;

if ParamStr(1)='--reconfigure-lighttpd' then begin
     XSETS.Reconfigure_lighttpd();
     XSETS.free;
     Halt(0);
end;
 
 if ParamStr(1)='-kasgroups' then begin
     XSETS.KasperskyASGroups();
     XSETS.free;
     Halt(0);
end;


 if ParamStr(1)='-apply-httpd' then begin
     XSETS.Enable_postfixmodules();
     zlogs.Debuglogs('Restarting http engine...');
     fpsystem('/etc/init.d/artica-postfix restart apache');
     XSETS.free;
     Halt(0);
end;

 if ParamStr(1)='-stunnel' then begin
      XSETS.Enable_postfixmodules();
      XSETS.stunnel4();
      XSETS.Free;
      halt(0);
 end;




if ParamStr(1)='-newuid' then begin
     writeln(xldap.samba_get_new_uidNumber());
     Halt(0);
end;

if ParamStr(1)='-gsid' then begin
writeln(xldap.samba_group_sid_from_gid(ParamStr(2)));
halt(0);
end;

if ParamStr(1)='-luid' then begin
xldap.Load_userasdatas(ParamStr(2));
halt(0);
end;

if ParamStr(1)='-mac' then begin
writeln(xldap.ComputerDN_From_MAC(ParamStr(2)));
halt(0);
end;

if ParamStr(1)='--bind9-import' then begin
   XSETS.bind_import();
   XSETS.free;
   halt(0);
end;

if ParamStr(1)='-squidnewbee' then begin
   XSETS.squidnewbee();
   XSETS.free;
   halt(0);
end;

if ParamStr(1)='--imapsync' then begin
   Xsets.imapsync_export(ParamStr(2),ParamStr(3),ParamStr(4));
   XSETS.free;
   halt(0);
end;

if ParamStr(1)='--imapsync_import' then begin
   Xsets.imapsync_import(ParamStr(2));
   XSETS.free;
   halt(0);
end;


if ParamStr(1)='--dotclear' then begin
   Xsets.dtoclear_users();
   XSETS.free;
   halt(0);
end;


if ParamStr(1)='--jckmail' then begin
   Xsets.jckmail();
   XSETS.free;
   halt(0);
end;



 
 if length(ParamStr(1))>0 then begin
     zlogs.logs('Unable to understand ' + ParamStr(1));
     writeln('usage....................................');
     
     writeln('--reconfigure-lighttpd....: Rebuild the lighttpd configuration');
     writeln('--reconfigure-lighttpd path: Rebuild the lighttpd configuration using config file in path');
     


     writeln('-squidnewbee..............: Save simple squid configuration');
     writeln('-cyrus-restore............: re-create ldap cyrus user admin');
     writeln('-fetchmail................: Save fetchmail config from LDAP to disk');
     writeln('-getlive..................: perform GetLive fetching');
     writeln('-inadyn...................: perform inadyn synchronisation..');
     writeln('-proxy....................: Get proxy informations');
     writeln('-kav4proxy................: perform Kaspersky for squid config from ldap');
     writeln('-squid servername.........: perform squid config from ldap + give the name of this server stored in ldap');
     writeln('-dansguardian servername..: Apply DansGuardian settings from ldap to disk...');
     writeln('-secu-level...............: Apply modules enabled setting from ldap to disk...');
     writeln('-ftp-users servername.....: Apply FTP users settings from ldap to disk...');
     writeln('-sqlgrey servername.......: Apply sqlgrey settings from ldap to disk...');
     writeln('-maincf...................: Apply Posfix Main.cf to disk...');
     writeln('-amavis...................: Apply amavis settings to disk...');
     writeln('-ntpd.....................: Apply NTPD settings to disk...');
     writeln('-milter-greylist..........: Apply Milter greylist settings ');
     writeln('-crossroads sync..........: Send syncronize orders to crossroads slaves ');
     writeln('-mailboxes................: Create mailboxes ');
     writeln('-mailbox user.............: Create mailbox user ');
     writeln('-obm-sys..................: Set OBM (system mode) ');
     writeln('-iptables.................: Set iptables firewall rules (system mode) ');
     writeln('-backups..................: Set backups rules (system mode) ');
     writeln('-sharedfolders............: Set Shared folder rules (system mode) ');
     writeln('-kasgroups................: Set Kaspersky Anti-spam Groups rules (system mode) ');
     writeln('-apply-httpd..............: Apply settings for http engines and restart http engine');
     writeln('-mailfromd................: Apply mailfromd settings');
     writeln('-samba....................: Apply samba settings');
     writeln('-spamass..................: Apply spamassassin settings');
     writeln('-userinfo.................: Get user informations form mail...');
     writeln('-cyrus....................: Apply cyrus configuration');
     writeln('-stunnel..................: Apply stunnel4 configuration');
     writeln('-localdomains [path]......: List local domains or save list to file path');
     writeln('-pnetworks [path].........: List local Postfix networks or save list to file path');
     writeln('-nmap.....................: perform nmap scanning process with subnets set in ldap database (use --force)');
     writeln('--bind9-import............: import bind settings into ldap database');
     writeln('--bind9-compile...........: Apply bind9 settings from LDAP database');
     writeln('--repair-mailbox user path: Repair mailbox');
     writeln('--imapsync mbx1 mbx2 1|0..: Export using imapsync mailbox mbx1 -> mbx2 and delete/not delete sources messages');
     writeln('--imapsync_import mbx1....: import  using imapsync mailbox mbx1 <- mbx2 set by artica interface');
     writeln('--jckmail.................: Save jchkmail settings');
     writeln('--wbld....................: Replicate White lists & black lists');
     writeln('-sa-learn.................: Remote junk mailbox sa_learn analysis');
     


     
     writeln('');
     writeln('Testing LDAP connection:');
     writeln('--testldap [server] [port] [admin dn] [password] ');
     
     writeln('');
     writeln('use --verbose/debug after commands lines to see more process infos');
     halt(0);
 end;

 // xldap.CreateSuffix();
  xldap.CreateArticaUser();
  xldap.CreateCyrusUser();
  xldap.CreateMailManBranch();
  halt(0);
end.
