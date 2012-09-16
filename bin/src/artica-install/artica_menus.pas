unit artica_menus;
{$MODE DELPHI}
//{$mode objfpc}{$H+}
{$LONGSTRINGS ON}

interface

uses
Classes, SysUtils,Process,unix,RegExpr in 'RegExpr.pas', zsystem,
class_install,global_conf,debian,logs,openldap,cyrus,squid,postfix_class,lighttpd,awstats;

  type
  Tmenus=class


private
       GLOBAL_INI:MyConf;
       install:Tclass_install;
       LOG:Tlogs;
       mldap:Topenldap;
       x:char;
       ccyrus:Tcyrus;
       squid:Tsquid;
       zpostfix:tpostfix;
       zlighttpd:tlighttpd;
       awstats:Tawstats;
       procedure ShowScreen(line:string);
       PROCEDURE Repository(package_name:string);
       function setup_require():boolean;

public
      constructor Create();
      PROCEDURE mysql_setup();
      PROCEDURE ldap_setup(restart_config:boolean);
      procedure Free();
      PROCEDURE install_Packages(notauto:boolean);
      PROCEDURE HELP_POSTFIX();
      PROCEDURE HELP_AVESERVER();
      PROCEDURE HELP_DNSMASQ();
      PROCEDURE HELP_DSPAM();
      PROCEDURE HELP_EMAILRELAY();
      PROCEDURE Introduction();
      PROCEDURE remove_Packages_addon(Packagename:string);

//      PROCEDURE setup();

      PROCEDURE hostname_valid();
      PROCEDURE reconfigure_ldap();
END;

implementation

constructor Tmenus.Create();
begin
       forcedirectories('/etc/artica-postfix');
       GLOBAL_INI:=MyConf.Create;
       install:=Tclass_install.Create();
       LOG:=TLogs.Create;
       mldap:=Topenldap.Create;
       ccyrus:=Tcyrus.create(GLOBAL_INI.SYS);
       squid:=Tsquid.Create;
       zpostfix:=Tpostfix.Create(GLOBAL_INI.SYS);
       zlighttpd:=Tlighttpd.Create(GLOBAL_INI.SYS);
       awstats:=Tawstats.Create(GLOBAL_INI.SYS);
       //CheckPackages();
       
end;
PROCEDURE Tmenus.Free();
begin
   GLOBAL_INI.Free;
   install.Free;
end;
//##############################################################################

PROCEDURE Tmenus.Introduction();
var
   global_ini:myconf;
   whatis:string;
begin
 global_ini:=myconf.Create();

  writeln();
  writeln();
  writeln(chr(9) + 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
  writeln(chr(9) + 'xxx                                                                xxx');
  writeln(chr(9) + 'xxx                    ARTICA  1.x INSTALLATION                    xxx');
  writeln(chr(9) + 'xxx                      For Postfix & Squid 3                     xxx');
  writeln(chr(9) + 'xxx                                                                xxx');
  writeln(chr(9) + 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
  writeln();
  writeln();
  writeln(chr(9) + ' ARTICA INSTALLER will install artica and all necessary libraries');
  writeln(chr(9) + ' on your system.(' + trim(global_ini.SYSTEM_FQDN()) + ')');
  writeln(chr(9) + ' it will check if your system store mandatories libraries');
  writeln();

  writeln(chr(9) + ' If these libraries are not installed, artica will be install');
  writeln(chr(9) + ' them itself in "/opt/artica"');
  writeln();
  writeln();
  writeln(chr(9) + ' libraries installation could take time....');
  writeln(chr(9) + ' So DONT''T WORRY, just wait compilations and installation');
  writeln(chr(9) + ' of these libraries...');
  writeln(chr(9) + ' Sometimes the compilation could failed, it his problem occur');
  writeln(chr(9) + ' just rune antother time "artica-install setup".');
  
  writeln();
  writeln(chr(9) + ' BUT BE PATIENT.... ');
  writeln(chr(9) + ' Type "ENTER" key to start the full installation');
  writeln();
  writeln();
  readln(whatis);

  global_ini.free;
  
  
end;
//##############################################################################
PROCEDURE Tmenus.hostname_valid();
var
   global_ini:myconf;
   answer:string;
begin
    global_ini:=myconf.Create();
    if global_ini.SYSTEM_IS_HOSTNAME_VALID()=false then begin
       writeln();
       writeln();
       writeln('HOSTNAME -- ' + global_ini.SYSTEM_FQDN() + ' -- WARNING !! ');
       writeln('**********************************************************************');
       writeln('It seems that your system hostname "' + global_ini.SYSTEM_FQDN() + '"');
       writeln('is invalid, for this server, it is mandatory to have a "fqdn" hostname');
       writeln('(server.domain.tlb, server.mydomain.com...)');
       writeln();
       writeln('before installing, specify a fully qualified domain name server:');
       readln(answer);
       fpsystem('/bin/hostname ' + LowerCase(answer));
       global_ini.SYSTEM_SET_HOSTENAME(LowerCase(answer));
       hostname_valid();
       exit;
    
    end;
    
end;
//##############################################################################
PROCEDURE Tmenus.ldap_setup(restart_config:boolean);
var
   suffix,admin,password,ldap_server,ldap_suffix,ldap_admin,ldap_password,passed_value:string;
begin
     suffix:=GLOBAL_INI.Get_LDAP('suffix');
     admin:=GLOBAL_INI.Get_LDAP('suffix');
     password:=GLOBAL_INI.Get_LDAP('password');

     ldap_server:=trim(GLOBAL_INI.get_LDAP('server'));
     ldap_admin:=trim(GLOBAL_INI.get_LDAP('admin'));
     ldap_suffix:=trim(GLOBAL_INI.get_LDAP('suffix'));
     ldap_password:=trim(GLOBAL_INI.get_LDAP('password'));

     
     if ldap_server='' then ldap_server:='127.0.0.1';
     
     
     if ldap_admin='' then begin
        if length(admin)>0 then ldap_admin:=admin;
     end;
     
     if ldap_password='' then begin
         if length(password)>0 then ldap_password:=password;
     end;
     
     if ldap_suffix='' then begin
        if length(suffix)>0 then ldap_suffix:=suffix;
     end;
     
     
     
     
  if restart_config then begin
  writeln(chr(9) + 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
  writeln(chr(9) + 'xxx                                                                xxx');
  writeln(chr(9) + 'xxx                           LDAP SETTINGS                        xxx');
  writeln(chr(9) + 'xxx                                                                xxx');
  writeln(chr(9) + 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
  
  writeln(chr(9));
  writeln(chr(9));

  writeln(chr(9)+'Infos:the web console of artica can be found here');
  writeln(chr(9)+'https://'+ global_ini.LINUX_GET_HOSTNAME + ':9000');
  writeln(chr(9)+'Username: ' + global_ini.Get_LDAP('admin') + '; Password: ' + global_ini.Get_LDAP('password'));
  writeln(chr(9));
  writeln(chr(9));
  writeln(chr(9) + 'You need now to set the account of LDAP master administrator,');
  writeln(chr(9) + 'This account allows you to be connected as global administrator');
  writeln(chr(9) + 'on the web console.');
  writeln(chr(9) + 'Artica-install will ask you few settings...');


     writeln('Give the ldap server name: (default is [' + ldap_server + '])');
     readln(passed_value);
     if length(passed_value)>0 then ldap_server:=passed_value;
     
     writeln('Give the ldap administrator name: (default is [' + ldap_admin + '])');
     readln(passed_value);
     if length(passed_value)>0 then ldap_admin:=passed_value;
     
     writeln('Give the ldap database path: (default is [' + ldap_suffix + '])');
     readln(passed_value);
     if length(passed_value)>0 then ldap_suffix:=passed_value;

     writeln('Give the ldap administrator password: (default is [' + ldap_password + '])');
     readln(passed_value);
     if length(passed_value)>0 then ldap_password:=passed_value;

     writeln('writing settings to artica...');
  end;
     
     
     if length(ldap_server)=0 then ldap_server:='127.0.0.1';
     if length(ldap_suffix)=0 then ldap_suffix:='dc=nodomain';
     if length(ldap_admin)=0 then ldap_admin:='Manager';
     if length(ldap_password)=0 then ldap_password:='secret';
     
     forcedirectories('/etc/artica-postfix');
     
     GLOBAL_INI.set_LDAP('server',ldap_server);
     GLOBAL_INI.set_LDAP('suffix',ldap_suffix);
     GLOBAL_INI.set_LDAP('admin',ldap_admin);
     GLOBAL_INI.set_LDAP('password',ldap_password);
     GLOBAL_INI.set_LDAP('cyrus_admin','cyrus');
     GLOBAL_INI.set_LDAP('cyrus_password',ldap_password);

end;
//##############################################################################
PROCEDURE Tmenus.mysql_setup();

          var mysql_server,mysql_admin,mysql_password,passed_value,mysql_repos:string;
          db:TDebian;
begin
     mysql_server:=GLOBAL_INI.SYS.MYSQL_INFOS('server');
     mysql_admin:=GLOBAL_INI.SYS.MYSQL_INFOS('root');
     mysql_password:=GLOBAL_INI.SYS.MYSQL_INFOS('password');
     
     if not FileExists(GLOBAL_INI.MYSQL_INIT_PATH) then begin
          db:=TDebian.Create();
          mysql_repos:=db.AnalyseRequiredPackages('mysql');
          writeln('');
          writeln('');
          writeln('Mysql setup....');
          writeln('Currently, there are no mysql server installed on your system.');
          writeln('You can use a remote server.');
          writeln('If you don''t have a remote mysql server and you want to install one');
          writeln('in your system, just install theses packages and restart the installation');
          writeln(mysql_repos);
          writeln('');
          writeln('');
     
     end;

     writeln('');


     writeln('Give the mysql server name: (default is [' + mysql_server + '])');
     readln(passed_value);
     if length(passed_value)>0 then mysql_server:=passed_value;

     writeln('Give the mysql administrator name: (default is [' + mysql_admin + '])');
     readln(passed_value);
     if length(passed_value)>0 then mysql_admin:=passed_value;

     writeln('Give the ldap administrator password: (default is [' + mysql_password + '])');
     readln(passed_value);
     if length(passed_value)>0 then mysql_password:=passed_value;

     writeln('writing settings to artica...');
     forcedirectories('/etc/artica-postfix');
     
     GLOBAL_INI.ARTICA_MYSQL_SET_INFOS('database_admin',mysql_admin);
     GLOBAL_INI.ARTICA_MYSQL_SET_INFOS('database_password',mysql_password);
     GLOBAL_INI.ARTICA_MYSQL_SET_INFOS('mysql_server',mysql_server);
     

     writeln('writing settings to artica done...');
     fpsystem(GLOBAL_INI.get_ARTICA_PHP_PATH() + '/bin/artica-sql setup');


end;


//##############################################################################

function Tmenus.setup_require():boolean;
var
   ans,suffix_command_line,updater,prefix_command_line,com:string;
   db:TDebian;
   repos:string;
begin
    result:=false;
    db:=TDebian.Create();
    writeln();
    writeln();
    writeln('minimum requirements on this system:');
    writeln('1) Apache + PHP5');
    writeln('**************************************************************************');
    writeln();
    suffix_command_line:=GLOBAL_INI.LINUX_REPOSITORIES_INFOS('suffix_command_line');
    updater:=GLOBAL_INI.LINUX_REPOSITORIES_INFOS('updater');
    prefix_command_line:=GLOBAL_INI.LINUX_REPOSITORIES_INFOS('prefix_command_line');

       repos:=db.AnalyseRequiredPackages('apache') + ' ' + db.AnalyseRequiredPackages('php5');
       writeln('I will install these packages for you ' + repos);
       com:=updater +' ' + prefix_command_line+ ' ' + repos + ' '+ suffix_command_line;
       writeln('Waiting... I execute ' + com);
       fpsystem(com);
       writeln();
       writeln();
       result:=true;
       exit;

    
    
    writeln('Do you want to show minimal packages required ? [y/n]');
    readln(ans);
    if ans='y' then begin
    writeln('Use your favourite repositories manager in order to install these packages');
    writeln('**************************************************************************');
    writeln('');
    writeln('');
    writeln('For apache:');
    writeln(db.AnalyseRequiredPackages('apache'));
    writeln('');
    writeln('For PHP5:');
    writeln(db.AnalyseRequiredPackages('php5') + ' php-sqlite3');
    writeln('');
    writeln('Restart the installation when all these packages are installed...');
    end;
    

end;
 //##############################################################################

PROCEDURE Tmenus.install_Packages(notauto:boolean);
var repos,distribution,reposfile:string;
com:string;
logs:Tlogs;
phppath,suffix_command_line,updater,prefix_command_line:string;
begin

     logs:=Tlogs.Create;
     repos:='';
     phppath:=ExtractFilePath(ParamStr(0));
     GLOBAL_INI.SYSTEM_ENV_PATH_SET('/usr/local/sbin');
     GLOBAL_INI.SYSTEM_ENV_PATH_SET('/usr/sbin');
     GLOBAL_INI.SYSTEM_ENV_PATH_SET('/usr/local/bin');
     GLOBAL_INI.SYSTEM_ENV_PATH_SET('/sbin');

     
     distribution:=install.LinuxInfosDistri();
     if length(distribution)=0 then begin
         ShowScreen('Your distribution is not supported...');
         ShowScreen('install_Packages:: Unable to determine distribution...');
         exit;
         halt(0);
     end;
     writeln(distribution);

     reposfile:=phppath + 'install/distributions/' + distribution + '/repositories.txt';
     if not fileexists(reposfile) then begin
          ShowScreen('install_Packages:unable to locate '+reposfile);
          logs.logsInstall('install_Packages:: unable to locate ' + reposfile);
         exit;
     end;


    suffix_command_line:=GLOBAL_INI.LINUX_REPOSITORIES_INFOS('suffix_command_line');
    updater:=GLOBAL_INI.LINUX_REPOSITORIES_INFOS('updater');
    prefix_command_line:=GLOBAL_INI.LINUX_REPOSITORIES_INFOS('prefix_command_line');

    install.Disable_se_linux();
    
    if length(repos)>0 then begin
    writeln('Installing repositories... Waiting for few minutes...');
    writeln('----------------------------------------------------------');
    writeln(repos);
    writeln('----------------------------------------------------------');

    if not FileExists(updater) then begin
       writeln('Unable to stat updater define in REPOSITORIES section :' + updater);
       exit;
    end;
    
    
    com:=updater +' ' + prefix_command_line+ ' ' + repos + ' '+ suffix_command_line;
    writeln(com);
    writeln('----------------------------------------------------------');
   

   if notauto=False then begin
      writeln('Just execute this operation:');
      writeln(com);
      writeln('Enter key to exit:');
      Readln(x);
      exit;
   end;


   fpsystem(com);
   end;
   
end;
//##############################################################################
PROCEDURE Tmenus.remove_Packages_addon(Packagename:string);
var
   debian:Tdebian;
   suffix_command_line:string;
   updater,prefix_command_uninstall,remover,FileLogs, exp:string;
   LOGS:Tlogs;
   D:boolean;
   CMD:string;
begin


       suffix_command_line:=GLOBAL_INI.LINUX_REPOSITORIES_INFOS('suffix_command_line');
       updater:=GLOBAL_INI.LINUX_REPOSITORIES_INFOS('updater');
       prefix_command_uninstall:=GLOBAL_INI.LINUX_REPOSITORIES_INFOS('prefix_command_uninstall');
       remover:=GLOBAL_INI.LINUX_REPOSITORIES_INFOS('remover');
       LOGS:=Tlogs.Create;
       D:=LOGS.COMMANDLINE_PARAMETERS('-V');
       LOGS.INSTALL_MODULES(Packagename,'Starting remove program "' + Packagename + '"');
       FileLogs:='/var/log/artica-postfix/artica-install-' + Packagename + '.log';
       if ParamStr(3)='auto' then exp:=' >>' + FileLogs;
       
   if FileExists(FileLogs) then fpsystem('/bin/rm ' + FileLogs);
   debian:=tdebian.Create();
       if D then writeln('Starting remove program "' + Packagename + '"');
       
   if Packagename='APP_AWSTATS' then begin
         LOGS.INSTALL_MODULES(Packagename,'Checking if product "awstats" exists in database...');
        if debian.ISReposListed('dnsmasq') then begin
           if D then writeln('Product exists in package database...');
           LOGS.INSTALL_MODULES(Packagename,'Product exists in package database...');
           if length(remover)=0 then begin
              CMD:=updater + ' ' + prefix_command_uninstall + ' awstats ' + suffix_command_line + exp;
           end else begin
              CMD:=remover + ' ' + prefix_command_uninstall + ' awstats ' + suffix_command_line + exp;
           end;
           LOGS.INSTALL_MODULES(Packagename,CMD);
           if D then writeln(CMD);
           fpsystem(CMD);
        end;
        exit;
   end;

   if Packagename='APP_DNSMASQ' then begin
         LOGS.INSTALL_MODULES(Packagename,'Checking if product "dnsmasq" exists in database...');
        if debian.ISReposListed('dnsmasq') then begin
           if D then writeln('Product exists in package database...');
           LOGS.INSTALL_MODULES(Packagename,'Product exists in package database...');
           if length(remover)=0 then begin
              CMD:=updater + ' ' + prefix_command_uninstall + ' dnsmasq ' + suffix_command_line + exp;
           end else begin
              CMD:=remover + ' ' + prefix_command_uninstall + ' dnsmasq ' + suffix_command_line + exp;
           end;
           LOGS.INSTALL_MODULES(Packagename,CMD);
           if D then writeln(CMD);
           fpsystem(CMD);
        end;

        exit;
   end;
   
   if Packagename='APP_FETCHMAIL' then begin
         LOGS.INSTALL_MODULES(Packagename,'Checking if product "fetchmail" exists in database...');
        if debian.ISReposListed('fetchmail') then begin
           if D then writeln('Product exists in package database...');
           LOGS.INSTALL_MODULES(Packagename,'Product exists in package database...');
           if length(remover)=0 then begin
              CMD:=updater + ' ' + prefix_command_uninstall + ' fetchmail ' + suffix_command_line+ exp;
           end else begin
              CMD:=remover + ' ' + prefix_command_uninstall + ' fetchmail ' + suffix_command_line+ exp;
           end;
           LOGS.INSTALL_MODULES(Packagename,CMD);
           if D then writeln(CMD);
           fpsystem(CMD);
        end else begin

        
        
        end;
        exit;
   end;


   if Packagename='APP_AVESERVER' then begin
         LOGS.INSTALL_MODULES(Packagename,'Checking if product "kav4mailservers-linux55" exists in database...');
        if debian.ISReposListed('kav4mailservers-linux55') then begin
           if D then writeln('Product exists in package database...');
           LOGS.INSTALL_MODULES(Packagename,'Product exists in package database...');
           if length(remover)=0 then begin
              CMD:=updater + ' ' + prefix_command_uninstall + ' kav4mailservers-linux55 ' + suffix_command_line+ exp;
           end else begin
              CMD:=remover + ' ' + prefix_command_uninstall + ' kav4mailservers-linux55 ' + suffix_command_line + exp;
           end;

           LOGS.INSTALL_MODULES(Packagename,CMD);
           if D then writeln(CMD);
           fpsystem(CMD);
        end;
      exit;
   end;
   
   if Packagename='APP_KAS3' then begin
         LOGS.INSTALL_MODULES(Packagename,'Checking if product "kas-3" exists in database...');
        if debian.ISReposListed('kas-3') then begin
           if D then writeln('Product exists in package database...');
           LOGS.INSTALL_MODULES(Packagename,'Product exists in package database...');
           if length(remover)=0 then begin
              CMD:=updater + ' ' + prefix_command_uninstall + ' kas-3 ' + suffix_command_line+ exp;
           end else begin
              CMD:=remover + ' ' + prefix_command_uninstall + ' kas-3 ' + suffix_command_line + exp;
           end;
           LOGS.INSTALL_MODULES(Packagename,CMD);
           if D then writeln(CMD);
           fpsystem(CMD);
        end;
        exit;
   end;

   LOGS.INSTALL_MODULES(Packagename,'uninstall feature of "' + PackageName + '" is not currently supported');
   
//fetchmail
//kav4mailservers-linux55
//kas-3

end;
PROCEDURE Tmenus.reconfigure_ldap();

var
   ldp:topenldap;
   admin,password,suffix:string;
   db_path:string;
   gf:myconf;
   sys:tsystem;

begin
   ldp:=topenldap.Create;
   gf:=myconf.Create;
   sys:=tsystem.Create;
   
writeln('This wizard will help you to reconfigure your ldap server');
writeln('Be carrefull, all old datas will be erase...');
writeln('');
writeln('Give the Administrator account used by artica-interface');
writeln('has the LDAP administrator: [Manager]');
readln(admin);
if length(admin)=0 then admin:='Manager';
writeln('');
writeln('Give the Administrator password: [secret]');
readln(password);
if length(password)=0 then password:='secret';
writeln('');
writeln('Give the suffix of your ldap database: [dc=nodomain]');
readln(suffix);
if length(suffix)=0 then suffix:='dc=nodomain';
gf.ARTICA_STOP();
ldp.LDAP_STOP();
db_path:=ldp.LDAP_DATABASES_PATH();
writeln('remove old datas in '+ db_path);

writeln('settings artica-postfix');
ldp.set_LDAP('admin',admin);
ldp.set_LDAP('password',password);
ldp.set_LDAP('suffix',suffix);

writeln('settings openldap...');
ldp.SAVE_SLAPD_CONF();
ldp.LDAP_STOP();
if length(db_path)>0 then fpsystem('/bin/rm -rf '+db_path);
forcedirectories(db_path);
fpsystem('/etc/init.d/artica-postfix stop ldap');
fpsystem(sys.LOCATE_SLAPINDEX());
fpsystem('/etc/init.d/artica-postfix start ldap');
fpsystem('/etc/init.d/artica-postfix start daemon');
fpsystem('/usr/share/artica-postfix/bin/process1 --force --verbose');
fpsystem('/usr/share/artica-postfix/bin/artica-install --cyrus-checkconfig --force --verbose');
fpsystem('/usr/share/artica-postfix/bin/artica-install --samba-reconfigure --force --verbose');
writeln('done...');



halt(0);







end;




//##############################################################################
PROCEDURE tmenus.Repository(package_name:string);
var
   suffix_command_line         :string;
   updater                     :string;
   prefix_command_line         :string;
   repos,com                   :string;
   debian                      :TDebian;
begin

       suffix_command_line:=GLOBAL_INI.LINUX_REPOSITORIES_INFOS('suffix_command_line');
       updater:=GLOBAL_INI.LINUX_REPOSITORIES_INFOS('updater');
       prefix_command_line:=GLOBAL_INI.LINUX_REPOSITORIES_INFOS('prefix_command_line');
       debian:=tdebian.Create();
       repos:=trim(debian.AnalyseRequiredPackages(package_name));
       ShowScreen('Repostory:: repostories length ="' + IntToStr(length(repos)) + '"');

       if length(repos)>0 then begin
           if not FileExists('/tmp/beffore_check') then begin
               writeln('');
               writeln('');
               writeln('');
               writeln('Please wait few moments while checking some components....');
               writeln('');
               writeln('');
               writeln('');
               fpsystem(GLOBAL_INI.LINUX_REPOSITORIES_INFOS('beffore_check'));
               fpsystem('touch /tmp/beffore_check');
           end;

           com:=updater +' ' + prefix_command_line+ ' ' + repos + ' '+ suffix_command_line;



           ShowScreen('Repostory:: repostories command ="' + com + '"');
           if length(com)>0 then begin
              fpsystem(com);
           end;
       end;
    end;



PROCEDURE Tmenus.HELP_DSPAM();
begin
     writeln('');
     writeln(chr(9) + 'dspam usages:');
     writeln(chr(9)+chr(9)+'-dspam install........: compile and install dspam');
     writeln(chr(9)+chr(9)+'-dspam configure......: configure,re-configure dspam');

end;

PROCEDURE Tmenus.HELP_POSTFIX();

begin
     writeln('');
     writeln(chr(9)+chr(9) + '-postfix-reconfigure-master : Reconfigure master.cf and main.cf');
     writeln('');
     writeln(chr(9) + '--enable-postfix-ssl (yes|no)..........: Enable/disable SSL in master.cf');
     writeln(chr(9) + '--read-queue (queuename)...............: Get content of 100 first mails in specified queue');
     writeln(chr(9) + '--postfix-status.......................: Get Postfix version');

     writeln(chr(9) + 'Postfix usages: -postfix (conf|cert|rrd|inet|queue [option])');
     writeln(chr(9)+chr(9)+'-postfix         : Configure postfix width ldap settings');
     writeln(chr(9)+chr(9)+'-postfix fix-sasl: Configure fix postfix width sasl settings');
     writeln(chr(9)+chr(9)+'-postfix conf    : View mandatories settings');
     writeln(chr(9)+chr(9)+'-postfix alllogs : Export logs to Artica logs path');
     writeln(chr(9)+chr(9)+'-postfix cert    : creating TLS certificates using default configuration SSL file ');
     writeln(chr(9)+chr(9)+'-postfix rrd     : generate rrd functions for mails statistics in debug mode (experimental)');
     writeln(chr(9)+chr(9)+'-postfix inet    : Automatically change inet_interface in postfix settings');
     writeln(chr(9)+chr(9)+'-postfix check-config [path]    : Apply main.cf with predefined path.');
     writeln(chr(9)+chr(9)+'-postfix errors  : View last errors');
     writeln(chr(9)+chr(9)+'Artica Queues caching features:');
     writeln(chr(9)+chr(9)+'In order to prevent CPU load to read the queues, Artica create caches for each queue...');
     writeln(chr(9)+chr(9)+chr(9)+'Generate cache files from queues listed below (available command are flush,debug,queue=,cache_delete)');
     writeln(chr(9)+chr(9)+chr(9)+'Generate cache for all queues        : -postfix queue cache');
     writeln(chr(9)+chr(9)+chr(9)+'Re-generate cache for all queues     : -postfix queue cache flush');
     writeln(chr(9)+chr(9)+chr(9)+'Re-generate cache for queue maildrop : -postfix queue cache  queue=maildrop flush');
     writeln(chr(9)+chr(9)+chr(9)+'Delete message id from cache index   : -postfix queue cache_delete [messageid]');
     
     
     writeln('');
     writeln(chr(9)+chr(9)+'-postfix queuelist: List mails stored in following queue:');
     writeln(chr(9)+chr(9)+'                                      incoming: incoming queue');
     writeln(chr(9)+chr(9)+'                                      active  : active queue');
     writeln(chr(9)+chr(9)+'                                      deferred: deferred queue');
     writeln(chr(9)+chr(9)+'                                      bounce  : non-delivery status');
     writeln(chr(9)+chr(9)+'                                      defer   : non-delivery status');
     writeln(chr(9)+chr(9)+'                                      trace   : delivery status');
     writeln(chr(9)+chr(9)+'                                      maildrop: dropped status');
     writeln(chr(9)+chr(9)+'                (from file number)');
     writeln(chr(9)+chr(9)+'                (to file number)');
     writeln(chr(9)+chr(9)+'                (queue)');
     writeln(chr(9)+chr(9)+'                (destination file)');
     writeln(chr(9)+chr(9)+'-postfix queuelist 0 100 incoming /tmp/file.txt');

end;
//##############################################################################

PROCEDURE Tmenus.HELP_AVESERVER();
begin
     writeln('');
     writeln(chr(9) + 'Kaspersky usages:................................................');
     writeln(chr(9)+chr(9)+'-mailav.................................: Install and configure Kaspersky Antivirus for Mail servers');
     writeln(chr(9)+chr(9)+'-mailav help............................: Show this help');
     writeln(chr(9)+chr(9)+'-mailav reconfigure.....................: reconfigure Kaspersky Antivirus for Mail servers');
     writeln(chr(9)+chr(9)+'-mailav delete..........................: remove Kaspersky Antivirus from master.cf');
     writeln(chr(9)+chr(9)+'-mailav remove..........................: unistall Kaspersky Antivirus');
     writeln(chr(9)+chr(9)+'-mailav template [notification] [user]..: read a template datas');
     writeln(chr(9)+chr(9)+chr(9)+'ex: artica-install -mailav template infected recipient');
     writeln(chr(9)+chr(9)+'-mailav save_templates..................: Replicate templates from artica to Kav templates folder');
     writeln(chr(9)+chr(9)+'-mailav pattern.........................: Show antivirus database date');
     writeln(chr(9)+chr(9)+'-mailav replicate [configuration file]..: replicate configuration file (used by artica web admin)');
     
end;
PROCEDURE Tmenus.HELP_DNSMASQ();
begin
     writeln('');
     writeln(chr(9) + 'dnsmasq usages:................................................');
     writeln(chr(9)+chr(9)+'-dnsmasq help...........: Show this help');
     writeln(chr(9)+chr(9)+'-dnsmasq version........: show dnsmasq version');
end;
PROCEDURE Tmenus.HELP_EMAILRELAY();
begin
     writeln('');
     writeln(chr(9) + 'emailrelay usages:................................................');
     writeln(chr(9)+chr(9)+'-emailrelay help........: Show this help');
     writeln(chr(9)+chr(9)+'-emailrelay reconfigure.: reconfigure or install emailrelay');
     writeln(chr(9)+chr(9)+'-emailrelay clean.......: Clean/resend emailrelay queue');
     writeln('');
     writeln('additional option --verbose for debuging');
     writeln('');
     

end;

procedure Tmenus.ShowScreen(line:string);
 var  logs:Tlogs;
 begin
     logs:=Tlogs.Create();
     logs.Enable_echo_install:=True;
     Logs.logs('MENUS::' + line);
     logs.free;

 END;


end.
