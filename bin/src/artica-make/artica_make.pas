program artica_make;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, setup_collectd, setup_clamav, unix, setup_kas3,
  setup_simple_groupware, setup_atmailopen, setup_milterspy,
  setup_miltergreylist, setup_amavisdmilter, setup_imapsync, setup_obm,
  setup_isoqlog, setup_dotclear, setup_jcheckmail, setup_kavmilter, setup_squid,
  setup_kavsamba, logs, setup_pommo, setup_dar, setup_fetchmail, setup_cicap,
  setup_gnarwl, setup_mhonarc, setup_postfix, setup_msmtp, setup_pflogsumm,
  setup_spamassassin, setup_cups, setup_cyrus, install_generic, setup_pureftpd,
  setup_obm2, setup_smartmontools, setup_nmap, setup_samba, setup_xapian,
  setup_opengoo, setup_joomla, setup_stunnel, setup_gnuplot, setup_dstat,
  setup_eaccelerator, setup_bacula, setup_roundcube, setup_acxdrv,
  setup_hostapd, zsystem, setup_mysql, setup_winexe, setup_assp, setup_ocs,
  setup_lmb, setup_glusterfs, setup_postfilter, setup_vmtools,
  setup_phpldapadmin, setup_zarafa, setup_cpulimit, setup_drupal,
  setup_emailrelay, setup_mldonkey, setup_backuppc, setup_kav4fs,
  setup_opendkim, setup_ufdbguard, setup_dkimproxy, setup_dkimmilter,
  setup_dropbox, setup_crossroads, setup_squidclamav, setup_cluebringer,
  setup_awstats, setup_sabnzbdplus, setup_openldap, setup_lxc, setup_snort,
  setup_greensql, setup_amanda, setup_mysqlserver, setup_dhcpd, setup_drupal7,
  setup_openemm, setup_mysqlnd, setup_phprrd, setup_haproxy;

var
   collectd:tsetup_collectd;
   clamav:tsetup_clamav;
   kas3:tsetup_kas3;
   SimpleGroupWare:tsetup_simple_groupware;
   atmail:tatmail;
   greylist:miltergreylist;
   mailspy:milterspy;
   amavis:amavisd;
   imaps:imapsync;
   zobm:tobm_install;
   zisoqlog:isoqlog;
   zdotclear:dotclear;
   zjcheckmail:jcheckmail;
   kavmilter:tsetup_kavmilter;
   squid:tsetup_squid;
   kavsamba:tsetup_kavsamba;
   pommo:tpommo;
   ddar:dar;
   fetchmail:install_fetchmail;
   ccicap:cicap;
   sgnarwl:gnarwl;
   mhonarc:mhonarcisnt;
   postfix:tpostfix_install;
   msmtp:tmsmtp;
   pflogsumm:tpflogsumm;
   spamassassin:tspam;
   cups:tcups_install;
   zinstall:tinstall;
   zcyrus:tcyrus_install;
   pureftpd:installpure;
   obm2:setupobm2;
   smartmon:smartmontools_install;
   nmap:install_nmap;
   samba:install_samba;
   xapian:install_xapian;
   opengoo:setupopengoo;
   joomla:tsetup_joomla;
   stunnel:tsetup_stunnel;
   gnuplot:install_gnuplot;
   dstat:install_dstat;
   eacc:tsetup_eacc;
   bacula:install_bacula;
   roundcube:install_roundcube;
   acx:tacx;
   hostpad:tsetup_hostapd;
   SYS:Tsystem;
   mysql:mysql_server;
   winexe:tsetup_winexe;
   ocsi:tsetup_ocs;
   assp:tsetup_assp;
   lmb:tsetup_lmb;
   glusterfs:install_glusterfs;
   postfilter:tsetup_postfilter;
   vmtools:tsetup_vmtools;
   phpldapadmin:tsetup_phpldapadmin;
   zarafa:tzarafa;
   cpulimit:tsetup_cpulimit;
   drupal:tsetup_drupal;
   emailrelay:tsetup_emailrelay;
   mldonkey:tsetup_mldonkey;
   backuppc:tsetup_backuppc;
   kav4fs:Tsetup_kav4fs;
   opendkim:install_opendkim;
   ufdbguardd:install_ufdbguard;
   dkimproxy:install_dkimproxy;
   dkimmilter:install_dkimmilter;
   dropbox:tsetup_dropbox;
   crossroads:install_crossroads;
   squidclamav:install_squidclamav;
   cluebringer:install_cluebringer;
   awstats:install_awstats;
   sabnzbdplus:install_sabnzbdplus;
   openldap:tsetup_openldap;
   lxc:install_lxc;
   snort:install_snort;
   greensql:install_greensql;
   app_amanda:amanda;
   dhcpd:tdhcpd;
   drupal7:tsetup_drupal7;
   openemm:tsetup_openemm;
   mysqlnd:tsetup_mysqlnd;
   sexport:Tstringlist;
   php_rrd:tsetup_phprrd;
   zhaproxy:haproxy;
   zlogs:tlogs;

begin


  SetCurrentDir('/root');
  zinstall:=tinstall.Create;


   if ParamStr(1)='--empty-cache' then begin
      zinstall.EMPTY_CACHE();
      halt(0);
   end;


  zlogs:=Tlogs.Create;
  zlogs.NOTIFICATION('artica-make as been ordered with option '+ParamStr(1),'','softwares');


  zinstall.INSTALL_PROGRESS(ParamStr(1),'{checking}');
  zinstall.INSTALL_STATUS(ParamStr(1),5);

  sexport:=tstringlist.Create;
  sexport.Add('#!/bin/sh');
  sexport.Add('export LD_LIBRARY_PATH="/lib:/lib64:/usr/lib:/usr/lib64"');
  sexport.Add('export LDFLAGS="-L/lib -L/usr/local/lib -L/usr/lib/libmilter -L/usr/lib"');
  sexport.Add('export CPPFLAGS="-I/usr/include/ -I/usr/local/include -I/usr/include/libpng12 -I/usr/include/sasl"');
  sexport.Add('export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/bin/X11');
  try
   sexport.SaveToFile('/tmp/export.sh');
   fpsystem('/bin/chmod 777 /tmp/export.sh');
   fpsystem('/tmp/export.sh');
  finally
  end;




  sys:=Tsystem.Create;

   if ParamStr(1)='--db-ver' then begin
      zcyrus:=tcyrus_install.Create;
      writeln(zcyrus.GET_DB_VERSION());
      halt(0);
   end;

   if ParamStr(1)='--cyrus-patch-db' then begin
      zcyrus:=tcyrus_install.Create;
      zcyrus.PatchdebVer(ParamStr(2));
      zinstall.EMPTY_CACHE();
      halt(0);
   end;

   if ParamStr(1)='APP_OPENVPN' then begin
      fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-openvpn');
      zinstall.EMPTY_CACHE();
      halt(0);
   end;

   if ParamStr(1)='APP_PHP5_MYSQLND' then begin
      mysqlnd:=tsetup_mysqlnd.Create();
      mysqlnd.xinstall();
      halt(0);
   end;

   if ParamStr(1)='APP_SNORT' then begin
      if not SYS.BuildPids() then begin
         writeln('APP_SNORT:: Already executed, aborting');
         exit;
        end;
         snort:=install_snort.Create;
         snort.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end ;
    if ParamStr(1)='APP_IPTACCOUNT' then begin
        fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         snort:=install_snort.Create;
         zinstall.EMPTY_CACHE();
         snort.iptaccount();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;
     if ParamStr(1)='APP_PHP5_RRD' then begin
         php_rrd:=tsetup_phprrd.Create;
         php_rrd.xinstall();
         zinstall.EMPTY_CACHE();
         fpsystem('/etc/init.d/artica-postfix restart apache');
         halt(0);
   end;

     if ParamStr(1)='APP_PHP5_MEMCACHED' then begin
         php_rrd:=tsetup_phprrd.Create;
         php_rrd.xmemcached_install();
         zinstall.EMPTY_CACHE();
         fpsystem('/etc/init.d/artica-postfix restart apache');
         halt(0);
   end;






   if ParamStr(1)='APP_SNORT_RULES' then begin
         snort:=install_snort.Create;
         snort.rules();
         halt(0);
   end ;
   if ParamStr(1)='APP_SNORT_CAP' then begin
         snort:=install_snort.Create;
         snort.libpcap();
         halt(0);
   end ;


 if ParamStr(1)='APP_OPENEMM' then begin
       openemm:=tsetup_openemm.Create();
       openemm.openemm_install();
       zinstall.EMPTY_CACHE();
       halt(0);
 end;


  if ParamStr(1)='APP_OPENEMM_SENDMAIL' then begin
       openemm:=tsetup_openemm.Create();
       openemm.sendmail_install();
       zinstall.EMPTY_CACHE();
       halt(0);
 end;



 if ParamStr(1)='APP_TOMCAT6' then begin
       openemm:=tsetup_openemm.Create();
       openemm.tomcat6();
       zinstall.EMPTY_CACHE();
       halt(0);
 end;

 if ParamStr(1)='APP_TOMCAT' then begin
       fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
       openemm:=tsetup_openemm.Create();
       openemm.tomcat();
       zinstall.EMPTY_CACHE();
       halt(0);
 end;


   if ParamStr(1)='APP_GREENSQL' then begin
          fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         greensql:=install_greensql.Create;
         greensql.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end ;

   if ParamStr(1)='APP_AMANDA' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-amanda');
         app_amanda:=amanda.Create;
         app_amanda.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end ;


   if ParamStr(1)='APP_SNORT_DAQ' then begin
         snort:=install_snort.Create;
         snort.daq();
         halt(0);
   end ;

   if ParamStr(1)='APP_SNORT_DNET' then begin
         snort:=install_snort.Create;
         snort.install_dnet();
         halt(0);
   end ;

    if ParamStr(1)='APP_DHCP' then begin
         dhcpd:=tdhcpd.Create;
         dhcpd.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end ;


   if ParamStr(1)='APP_CPULIMIT' then begin
         cpulimit:=tsetup_cpulimit.Create;
         cpulimit.xinstall();
         halt(0);
   end;


   if ParamStr(1)='APP_LXC' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         lxc:=install_lxc.Create;
         lxc.xinstall();
         halt(0);
   end;

   if ParamStr(1)='APP_HAPROXY' then begin
         zhaproxy:=haproxy.Create();
         zhaproxy.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;
   ;


   if ParamStr(1)='APP_LXC_DEBIAN_TEMPLATE' then begin
         lxc:=install_lxc.Create;
         lxc.debian_template();
         halt(0);
   end;

   if ParamStr(1)='APP_LXC_FEDORA_TEMPLATE' then begin
         lxc:=install_lxc.Create;
         lxc.fedora_template();
         halt(0);
   end;

   if ParamStr(1)='APP_OPENLDAP' then begin
          fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         openldap:=tsetup_openldap.Create;
         openldap.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_SABNZBDPLUS' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         sabnzbdplus:=install_sabnzbdplus.Create;
         sabnzbdplus.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_FUPPES' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-fuppes');
         sabnzbdplus:=install_sabnzbdplus.Create;
         sabnzbdplus.xinstall_fuppes();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_BACKUPPC' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-samba');
         backuppc:=tsetup_backuppc.Create;
         backuppc.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_DROPBOX' then begin
         dropbox:=tsetup_dropbox.Create;
         dropbox.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_KUPDATE_UTILITY' then begin
         dropbox:=tsetup_dropbox.Create;
         dropbox.KasperskyUpdateUtility();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_KASPERSKY_UPDATE_UTILITY' then begin
         dropbox:=tsetup_dropbox.Create;
         dropbox.KasperskyUpdateUtility();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;



   if ParamStr(1)='APP_AWSTATS' then begin
         awstats:=install_awstats.Create;
         awstats.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_SQUIDCLAMAV' then begin
         clamav:=tsetup_clamav.Create;
         clamav.install_clamav();
         squidclamav:=install_squidclamav.Create;
         squidclamav.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_CLUEBRINGER' then begin
         cluebringer:=install_cluebringer.Create;
         cluebringer.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_THINCLIENT' then begin
         dropbox:=tsetup_dropbox.Create;
         dropbox.thinclient();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;
    if ParamStr(1)='APP_THINSTATION' then begin
         dropbox:=tsetup_dropbox.Create;
         dropbox.thinclient();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;
    if ParamStr(1)='APP_CROSSROADS' then begin
         crossroads:=install_crossroads.Create;
         crossroads.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;





   if ParamStr(1)='APP_DKIMPROXY' then begin
       dkimproxy:=install_dkimproxy.Create();
       dkimproxy.xinstall();
       halt(0);
   end;

   if ParamStr(1)='APP_OPENDKIM' then begin
         //fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         opendkim:=install_opendkim.Create;
         if ParamStr(2)='dk' then begin
               opendkim.dkmilter_install();
               exit;
         end;
         opendkim.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_UFDBGUARD' then begin
         ufdbguardd:=install_ufdbguard.Create();
         ufdbguardd.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

  if ParamStr(1)='APP_KAV4FS' then begin
       //  fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
        // fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-samba');
         kav4fs:=tsetup_kav4fs.Create;
         kav4fs.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;




   if ParamStr(1)='APP_EMAIL_RELAY' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         emailrelay:=tsetup_emailrelay.Create;
         emailrelay.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_EMAILRELAY_REMOVE' then begin
         emailrelay:=tsetup_emailrelay.Create;
         emailrelay.xremove();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_EMAILRELAY' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         emailrelay:=tsetup_emailrelay.Create;
         emailrelay.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_MLDONKEY' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         mldonkey:=tsetup_mldonkey.Create;
         mldonkey.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_DRUPAL' then begin
         drupal:=tsetup_drupal.Create;
         drupal.xinstall();
         halt(0);
   end;

   if ParamStr(1)='APP_DRUPAL7' then begin
         drupal7:=tsetup_drupal7.Create;
         drupal7.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_DRUPAL7_LANGS' then begin
         drupal7:=tsetup_drupal7.Create;
         drupal7.langupack();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;



   if ParamStr(1)='APP_DRUSH7' then begin
         drupal7:=tsetup_drupal7.Create;
         drupal7.APP_DRUSH();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_UPLOADPROGRESS' then begin
         drupal7:=tsetup_drupal7.Create;
         drupal7.APP_UPLOAD_PROGRESS();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_MILTER_DKIM' then begin
         dkimmilter:=install_dkimmilter.Create;
         dkimmilter.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;




   if ParamStr(1)='APP_MONIT' then begin
         cpulimit:=tsetup_cpulimit.Create;
         cpulimit.monit_xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_ZARAFA_LIBVMIME' then begin
         zarafa:=tzarafa.Create;
         zarafa.libvmime();
         halt(0);
   end;
   if ParamStr(1)='APP_ARKEIA' then begin
         zarafa:=tzarafa.Create;
         zarafa.arkeia();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_ZARAFADB' then begin
         zarafa:=tzarafa.Create;
         zarafa.zarafadb();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_ZARAFA_WEBAPP' then begin
         zarafa:=tzarafa.Create;
         zarafa.webapp();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_WEBAPP' then begin
         zarafa:=tzarafa.Create;
         zarafa.webapp_svn();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_ZARAFA_CLUCENE' then begin
         zarafa:=tzarafa.Create;
         zarafa.clucene();
         halt(0);
   end;

   if ParamStr(1)='APP_ZARAFA_ARCHIVER' then begin
         zarafa:=tzarafa.Create;
         zarafa.archiver();
         halt(0);
   end;



   if ParamStr(1)='APP_Z_PUSH' then begin
         zarafa:=tzarafa.Create;
         zarafa.zpush();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_Z_PUSH_WEB' then begin
         zarafa:=tzarafa.Create;
         zarafa.zpush();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_HAMACHI' then begin
         zarafa:=tzarafa.Create;
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         zarafa.hamachi();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;
   if ParamStr(1)='APP_NETATALK' then begin
         zarafa:=tzarafa.Create;
         zarafa.netatalk();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;



   if ParamStr(1)='APP_Z_ADMIN' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-postfix');
         zarafa:=tzarafa.Create;
         zarafa.zadmin();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_YAFFAS' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-postfix');
         zarafa:=tzarafa.Create;
         zarafa.zadmin();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_SPREED' then begin
         zarafa:=tzarafa.Create;
         zarafa.spreedsrc();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_ZARAFA_GOOGLE' then begin
         zarafa:=tzarafa.Create;
         zarafa.google_perftools();
         halt(0);
   end;

  if ParamStr(1)='APP_ZARAFA_LIBICAL' then begin
         zarafa:=tzarafa.Create;
         zarafa.libical();
         halt(0);
   end;

  if ParamStr(1)='APP_ZARAFA_SERVER' then begin
         zarafa:=tzarafa.Create;
         zarafa.xcompile();
         halt(0);
   end;

   if ParamStr(1)='APP_ZARAFA6' then begin

       if ParamStr(2)='--remove' then begin
            fpsystem('/etc/init.d/artica-postfix stop zarafa');
            zarafa.REMOVE();
            zinstall.INSTALL_PROGRESS(ParamStr(1),'{removed}');
            zinstall.INSTALL_STATUS(ParamStr(1),100);
            halt(0);
         end;

    zarafa:=tzarafa.Create;
    zarafa.xinstall6();
    zinstall.EMPTY_CACHE();
    fpsystem('/etc/init.d/artica-postfix restart zarafa');
    halt(0);
   end;


   if ParamStr(1)='APP_ZARAFA_WEB' then begin
         zarafa:=tzarafa.Create;
         zarafa.xinstall('APP_ZARAFA_WEB');
         zarafa.zpush();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_ZARAFA' then begin
         zarafa:=tzarafa.Create;

         if ParamStr(2)='--compile' then begin
              zarafa.COMPILE_TAR();
              halt(0);
         end;
         if ParamStr(2)='--remove' then begin
            fpsystem('/etc/init.d/artica-postfix stop zarafa');
            zarafa.REMOVE();
            zinstall.INSTALL_PROGRESS(ParamStr(1),'{removed}');
            zinstall.INSTALL_STATUS(ParamStr(1),100);
            halt(0);
         end;
         zarafa.xinstall('');
         zinstall.EMPTY_CACHE();
         fpsystem('/etc/init.d/artica-postfix restart zarafa');
         halt(0);
   end;





   if ParamStr(1)='APP_PHPLDAPADMIN' then begin
         phpldapadmin:=tsetup_phpldapadmin.Create;
         phpldapadmin.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_PIWIK' then begin
         phpldapadmin:=tsetup_phpldapadmin.Create;
         phpldapadmin.xinstall_piwik();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_PHPMYADMIN' then begin
         phpldapadmin:=tsetup_phpldapadmin.Create;
         phpldapadmin.xinstall_phpmyadmin();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_SQUID0' then begin
            squid:=tsetup_squid.Create;
            squid.squid32('squid2');
            zinstall.EMPTY_CACHE();
            halt(0);
         end;



   if ParamStr(1)='APP_SQUID' then begin
         if FileExists('/etc/artica-postfix/SQUID_APPLIANCE') then begin
            writeln('Only squid 3.2x is supported...');
            squid:=tsetup_squid.Create;
            squid.squid32();
            zinstall.EMPTY_CACHE();
            halt(0);
         end;

         if FileExists('/etc/artica-postfix/KASPERSKY_WEB_APPLIANCE') then begin
            writeln('Only squid 3.2x is supported...');
            squid:=tsetup_squid.Create;
            squid.squid32();
            zinstall.EMPTY_CACHE();
            halt(0);
         end;


         squid:=tsetup_squid.Create;
         if length(ParamStr(2))>0 then begin
            if SYS.COMMANDLINE_PARAMETERS('--configure') then begin
                 writeln('Artica will compile squid with these directives:');
                 writeln('');
                 squid.command_line_squid();
                 writeln('');
                 halt(0);
            end;
         end;

         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-squid');
         squid.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_SQUID2' then begin
         squid:=tsetup_squid.Create;
         squid.squid32();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_SQUID31' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-squid');
         squid:=tsetup_squid.Create;
         squid.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_ECAPAV' then begin
         squid:=tsetup_squid.Create;
         squid.ecapav();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_DANSGUARDIAN2' then begin
         squid:=tsetup_squid.Create;
         squid.dansguardian2();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


    if ParamStr(1)='APP_MSKTUTIL' then begin
       squid:=tsetup_squid.Create;
       squid.msktutil();
       zinstall.EMPTY_CACHE();

       halt(0);
    end;






   if ParamStr(1)='APP_SQUIDGUARD' then begin
         squid:=tsetup_squid.Create;
         if length(ParamStr(2))>0 then begin
            if SYS.COMMANDLINE_PARAMETERS('--configure') then begin
                 writeln('Artica will compile squidGuard with these directives:');
                 writeln('');
                 writeln(squid.command_line_squidguard());
                 writeln('');
                 halt(0);
            end;
         end;

         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-squid');
         squid.squidguard_install();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_VMTOOLS' then begin
         vmtools:=tsetup_vmtools.Create;
         vmtools.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;
    if ParamStr(1)='APP_VBOXADDITIONS' then begin
         vmtools:=tsetup_vmtools.Create;
         vmtools.VirtualBoxAdditions();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_WINEXE' then begin
         winexe:=tsetup_winexe.Create;
         winexe.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_OCS_SERVER' then begin
         ocsi:=tsetup_ocs.Create;
         ocsi.xinstall_v2();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_OCSI2' then begin
         ocsi:=tsetup_ocs.Create;
         ocsi.xinstall_v2();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;



   if ParamStr(1)='APP_OCSI' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         ocsi:=tsetup_ocs.Create;
         ocsi.xinstall_v2();
         ocsi.xwpkg_server_install();
         fpsystem('/usr/share/artica-postfix/bin/artica-make APP_OCSI_CLIENT &');
         ocsi.xclient_install();
         winexe:=tsetup_winexe.Create;
         winexe.xinstall();

         ocsi.xfusionclient_install();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_OCSI_CLIENT' then begin
         ocsi:=tsetup_ocs.Create;
         ocsi.xclient_install();
         ocsi.xfusionclient_install();
         halt(0);
   end;


   if ParamStr(1)='APP_OCSI_FUSIONCLIENT' then begin
         ocsi:=tsetup_ocs.Create;
         ocsi.xfusionclient_install();
         halt(0);
   end;

   if ParamStr(1)='APP_OCSC' then begin
         ocsi:=tsetup_ocs.Create;
         ocsi.xclient_install();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_WPKG' then begin
         ocsi:=tsetup_ocs.Create;
         ocsi.xwpkg_server_install();
         fpsystem('/etc/init.d/artica-postfix restart ocsweb');
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_OCSI_LINUX_CLIENT' then begin
         if ParamStr(2)<>'--nocheck' then fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         ocsi:=tsetup_ocs.Create;
         ocsi.xclient_linux_install();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_POSTFILTER' then begin
         postfilter:=tsetup_postfilter.Create;
         postfilter.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_BACULA' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         bacula:=install_bacula.Create;
         bacula.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_MYSQL' then begin
         mysql:=mysql_server.Create;
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         mysql.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_ACX_DRIVERS' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         writeln('Start installing drivers WIFI ACX Code name=APP_ACX_DRIVERS');
         acx:=tacx.Create;
         acx.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_HOSTAPD' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         writeln('Start installing hostapd Code name=APP_HOSTAPD');
         hostpad:=tsetup_hostapd.Create;
         hostpad.xinstall();

         zinstall.EMPTY_CACHE();
         halt(0);
   end;

  if ParamStr(1)='APP_EACCELERATOR' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         eacc:=tsetup_eacc.Create();
         eacc.xinstall();
         eacc.groupwareinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


  if ParamStr(1)='APP_GLUSTERFS' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         glusterfs:=install_glusterfs.Create();
         glusterfs.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

  if ParamStr(1)='APP_HAMSTERDB' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         glusterfs:=install_glusterfs.Create();
         glusterfs.hamsterdb();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;



  if ParamStr(1)='APP_FUSE' then begin
         glusterfs:=install_glusterfs.Create();
         glusterfs.fuse();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

  if ParamStr(1)='APP_ZFS_FUSE' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         glusterfs:=install_glusterfs.Create();
         glusterfs.zfsfuseinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

  if ParamStr(1)='APP_TOKYOCABINET' then begin
         glusterfs:=install_glusterfs.Create();
         glusterfs.tokyocabinet();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

  if ParamStr(1)='APP_LESSFS' then begin
         glusterfs:=install_glusterfs.Create();
         glusterfs.lessfs();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

  if ParamStr(1)='APP_MHASH' then begin
         glusterfs:=install_glusterfs.Create();
         glusterfs.mhash();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


  if ParamStr(1)='APP_GLUSTER' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         glusterfs:=install_glusterfs.Create();
         glusterfs.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


  if ParamStr(1)='APP_AMACHI' then begin
         opengoo:=setupopengoo.Create;
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         opengoo.APP_AMACHI_INSTALL();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


  if ParamStr(1)='APP_GROUPWARE_APACHE' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         opengoo:=setupopengoo.Create;
         opengoo.apacheinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

  if ParamStr(1)='APP_PYAUTHENNTLM' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         opengoo:=setupopengoo.Create;
         opengoo.PYAUTHENNTLM();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

  if ParamStr(1)='APP_MOD_QOS' then begin
         opengoo:=setupopengoo.Create;
         opengoo.MOD_QOS();
         halt(0);
  end;

  if ParamStr(1)='APP_MOD_PAGESPEED' then begin
         opengoo:=setupopengoo.Create;
         opengoo.MOD_PAGESPEED();
         zinstall.EMPTY_CACHE();
         halt(0);
  end;


  if ParamStr(1)='APP_GROUPOFFICE' then begin
         opengoo:=setupopengoo.Create;
         opengoo.GROUPOFFICE_INSTALL();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


  if ParamStr(1)='APP_STUNNEL' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         stunnel:=tsetup_stunnel.Create;
         stunnel.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


  if ParamStr(1)='APP_GNUPLOT' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         gnuplot:=install_gnuplot.Create;
         gnuplot.xinstall();

         dstat:=install_dstat.Create();
         dstat.xinstall();

         zinstall.EMPTY_CACHE();
         halt(0);
   end;


  if ParamStr(1)='APP_DSTAT' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         gnuplot:=install_gnuplot.Create;
         gnuplot.xinstall();
         dstat:=install_dstat.Create();
         dstat.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

  if ParamStr(1)='APP_ASSP' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-postfix');
         assp:=tsetup_assp.Create;
         assp.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;




  if ParamStr(1)='APP_PHP' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-php');
         opengoo:=setupopengoo.Create;
         opengoo.PHP_STANDARD_INSTALL();

         zinstall.EMPTY_CACHE();
         halt(0);
   end;


  if ParamStr(1)='APP_CC_CLIENT' then begin
          opengoo:=setupopengoo.Create;
         opengoo.CC_CLIENT_INSTALL();
         halt(0);
   end;


  if ParamStr(1)='APP_GROUPWARE_PHP' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         opengoo:=setupopengoo.Create;
         opengoo.CC_CLIENT_INSTALL();
         opengoo.phpinstall();
         eacc:=tsetup_eacc.Create();
         eacc.groupwareinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

  if ParamStr(1)='APP_ROUNDCUBE3' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         roundcube:=install_roundcube.Create();
         roundcube.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

  if ParamStr(1)='APP_ROUNDCUBE' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         roundcube:=install_roundcube.Create();
         roundcube.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

  if ParamStr(1)='APP_ROUNDCUBE3_SIEVE_RULE' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');

         roundcube:=install_roundcube.Create();
         roundcube.SieveRules();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

  if ParamStr(1)='APP_CC_CLIENT' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         opengoo:=setupopengoo.Create;
         opengoo.CC_CLIENT_INSTALL();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

  if ParamStr(1)='APP_WORDPRESS' then begin
         joomla:=tsetup_joomla.Create;
         joomla.xinstall_wordpress();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

  if ParamStr(1)='APP_ARTICA_AGENT' then begin
         joomla:=tsetup_joomla.Create;
         joomla.artica_agent();
         halt(0);
   end;

  if ParamStr(1)='APP_SQUID32_REPOS' then begin
         joomla:=tsetup_joomla.Create;
         joomla.APP_SQUID32_REPOS();
         halt(0);
   end;
  if ParamStr(1)='APP_SQUID32_PURGE' then begin
         joomla:=tsetup_joomla.Create;
         joomla.APP_SQUID32_PURGE();
         halt(0);
   end;


  if ParamStr(1)='APP_CONCRETE5' then begin
         joomla:=tsetup_joomla.Create;
         joomla.concrete5();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


  if ParamStr(1)='APP_JOOMLA' then begin
         joomla:=tsetup_joomla.Create;
         joomla.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

  if ParamStr(1)='APP_JOOMLA17' then begin
         joomla:=tsetup_joomla.Create;
         joomla.xinstall17();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;



  if ParamStr(1)='APP_EYEOS' then begin
         joomla:=tsetup_joomla.Create;
         joomla.eyeOS_install();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

  if ParamStr(1)='APP_OWNCLOUD' then begin
         joomla:=tsetup_joomla.Create;
         joomla.Ownloud_install();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

  if ParamStr(1)='APP_PIWIGO' then begin
         joomla:=tsetup_joomla.Create;
         joomla.piwigo_install();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

  if ParamStr(1)='APP_LMB' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         lmb:=tsetup_lmb.Create;
         lmb.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

  if ParamStr(1)='APP_SOGO' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         lmb:=tsetup_lmb.Create;
         lmb.sogo_xinstall();

         zinstall.EMPTY_CACHE();
         halt(0);
   end;

 if ParamStr(1)='APP_SUGARCRM' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         joomla:=tsetup_joomla.Create;
         joomla.SugarCRM_INSTALL();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


  if ParamStr(1)='APP_CCLIENT' then begin
         //fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         opengoo:=setupopengoo.Create;
         opengoo.CC_CLIENT_INSTALL();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


  if ParamStr(1)='APP_OPENGOO' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         opengoo:=setupopengoo.Create;
         opengoo.xinstall();

         zinstall.EMPTY_CACHE();
         halt(0);
   end;



   if ParamStr(1)='APP_SARG' then begin
         squid:=tsetup_squid.Create;
         squid.sarg_install();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_XAPIAN' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         xapian:=install_xapian.Create;
         xapian.libinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_XAPIAN_PHP' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         xapian:=install_xapian.Create;
         xapian.phpinstall();

         fpsystem('/usr/share/artica-postfix/bin/process1 --force &');
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_XAPIAN_OMEGA' then begin
        fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         xapian:=install_xapian.Create;
         xapian.omegainstall();

         fpsystem('/usr/share/artica-postfix/bin/process1 --force &');
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_XPDF' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         xapian:=install_xapian.Create;
         xapian.xpdf();

         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_UNZIP' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         xapian:=install_xapian.Create;
         xapian.unzip();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_CATDOC' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         xapian:=install_xapian.Create;
         xapian.catdoc();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_UNRTF' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         xapian:=install_xapian.Create;
         xapian.unrtf();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_ANTIWORD' then begin
         xapian:=install_xapian.Create;
         xapian.antiword();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_NMAP' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         nmap:=install_nmap.Create;
         nmap.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

 if ParamStr(1)='APP_SMARTMONTOOLS' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         smartmon:=smartmontools_install.Create;
         smartmon.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;



   if ParamStr(1)='APP_OBM2' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         obm2:=setupobm2.Create;
         obm2.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;



   if ParamStr(1)='APP_CYRUS_IMAP' then begin
         writeln('Operation not supported... use the system installer instead...');
         halt(0);
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         zcyrus:=tcyrus_install.Create;
         zcyrus.install_cyrus();

         fpsystem('/usr/share/artica-postfix/bin/process1 --force &');
         halt(0);
   end;


   if ParamStr(1)='APP_PUREFTPD' then begin
         if not SYS.BuildPids() then begin halt(0) end;
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         pureftpd:=installpure.Create;
         pureftpd.xinstall();
         fpsystem('/usr/share/artica-postfix/bin/process1 --force &');
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_PFLOGSUMM' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-postfix');
         pflogsumm:=tpflogsumm.Create;
         pflogsumm.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;



   if ParamStr(1)='APP_CUPS_DRV' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-samba');
         cups:=tcups_install.Create;
         cups.cupsdrivers();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_GUTENPRINT' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-samba');
         cups:=tcups_install.Create;
         cups.gutenprint();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_CUPS_BROTHER' then begin
         cups:=tcups_install.Create;
         cups.cupsBrother();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_HPINLINUX' then begin
         cups:=tcups_install.Create;
         cups.hpinlinux();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_SAMBA' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-samba');
         samba:=install_samba.Create;
         samba.xinstall();
         fpsystem('/etc/init.d/artica-postfix restart samba');
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

    if ParamStr(1)='APP_CTDB' then begin
       samba:=install_samba.Create;
       samba.ctdb();
       halt(0);
    end;

   if ParamStr(1)='APP_SAMBA35' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-samba');
         samba:=install_samba.Create;
         samba.xinstall('samba35');
         fpsystem('/etc/init.d/artica-postfix restart samba');
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='--remove-samba' then begin
       samba:=install_samba.Create;
       fpsystem('/etc/init.d/artica-postfix stop samba');
       samba.xinstall_REMOVE_SAMBA();
       zinstall.EMPTY_CACHE();
       halt(0);
   end;


       if ParamStr(1)='APP_SAMBA36' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-samba');
         samba:=install_samba.Create;
         samba.xinstall('samba36');
         fpsystem('/etc/init.d/artica-postfix restart samba');
         zinstall.EMPTY_CACHE();
         halt(0);
   end;




   if ParamStr(1)='APP_TALLOC' then begin
         samba:=install_samba.Create;
         samba.talloc();
         halt(0);
   end;
    if ParamStr(1)='APP_TDB' then begin
         samba:=install_samba.Create;
         samba.libtdb();
         halt(0);
   end;


   if ParamStr(1)='APP_SCANNED_ONLY' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-samba');
         samba:=install_samba.Create;
         samba.scannedonly();
         fpsystem('/etc/init.d/artica-postfix restart samba');
         fpsystem(sys.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.admin.status.postfix.flow.php --force &');
         zinstall.EMPTY_CACHE();
         halt(0);;
  end;

   if ParamStr(1)='APP_GREYHOLE' then begin
         //fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         //fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-samba');
         samba:=install_samba.Create;
         samba.greyhole();
         //fpsystem('/etc/init.d/artica-postfix restart samba');
         //fpsystem(sys.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.admin.status.postfix.flow.php --force &');
         zinstall.EMPTY_CACHE();
         halt(0);;
  end;


   if ParamStr(1)='APP_PDNS' then begin
         writeln('STARTING UPGRADE SYSTEM, PLEASE WAIT.....');
         zinstall.INSTALL_STATUS('APP_PDNS',12);
         zinstall.INSTALL_PROGRESS('APP_PDNS','{checking}');
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-pdns');
         samba:=install_samba.Create;
         writeln('STARTING INSTALL/COMPILE POWERDNS, PLEASE WAIT.....');
         zinstall.INSTALL_STATUS('APP_PDNS',15);
         samba.pdnsinstall();
         zinstall.INSTALL_STATUS('APP_POWERADMIN',12);
         samba.poweradmin();
         zinstall.INSTALL_STATUS('APP_POWERADMIN',100);
         fpsystem('/etc/init.d/artica-postfix restart pdns');
         zinstall.EMPTY_CACHE();
         halt(0);;
   end;


   if ParamStr(1)='APP_CAS' then begin
         samba:=install_samba.Create;
         samba.CAS_SERVER();
         zinstall.EMPTY_CACHE();
         halt(0);;
   end;
   if ParamStr(1)='APP_PDNS_STATIC' then begin
         writeln('STARTING UPGRADE SYSTEM, PLEASE WAIT.....');
         zinstall.INSTALL_STATUS('APP_PDNS_STATIC',12);
         zinstall.INSTALL_PROGRESS('APP_PDNS_STATIC','{checking}');
         samba:=install_samba.Create;
         writeln('STARTING INSTALL/COMPILE POWERDNS, PLEASE WAIT.....');
         zinstall.INSTALL_STATUS('APP_PDNS_STATIC',15);
         samba.pdnsinstall_static();
         zinstall.INSTALL_STATUS('APP_POWERADMIN',100);
         zinstall.EMPTY_CACHE();
         halt(0);;
   end;



   if ParamStr(1)='APP_POWERADMIN' then begin
         writeln('STARTING UPGRADE SYSTEM, PLEASE WAIT.....');
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-pdns');
         samba:=install_samba.Create;
         writeln('STARTING INSTALL/COMPILE APP_POWERADMIN, PLEASE WAIT.....');
         samba.poweradmin();
         zinstall.EMPTY_CACHE();
         halt(0);;
   end;



   if ParamStr(1)='APP_FOO2ZJS' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-samba');
         cups:=tcups_install.Create;
         cups.foo2zjs();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

 if ParamStr(1)='APP_SPAMASSASSIN_RQ' then begin
    spamassassin:=tspam.Create;
    spamassassin.minium_require();
    halt(0);
 end;



 if ParamStr(1)='APP_SPAMASSASSIN' then begin

         spamassassin:=tspam.Create;
         if ParamStr(2)='--remove' then begin
              spamassassin.spamassassin_remove();
              zinstall.EMPTY_CACHE();
              halt(0);
         end;
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-postfix');
         spamassassin.xinstall();
         zinstall.EMPTY_CACHE();
         fpsystem('/usr/share/artica-postfix/bin/process1 --force &');
         halt(0);
   end;

 if ParamStr(1)='APP_FUZZYOCR' then begin
//         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-postfix');
         spamassassin:=tspam.Create;
         spamassassin.fuzzy();
         zinstall.EMPTY_CACHE();
        // fpsystem('/usr/share/artica-postfix/bin/process1 --force &');
         halt(0);
   end;


   if ParamStr(1)='APP_MSMTP' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         msmtp:=tmsmtp.Create;
         msmtp.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_MHONARC' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         mhonarc:=mhonarcisnt.Create;
         mhonarc.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_POSTFIX' then begin
        if not SYS.BuildPids() then begin
         writeln('APP_POSTFIX:: Already executed, aborting');
         exit;
        end;

         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-postfix');
         postfix:=tpostfix_install.Create;
         postfix.xinstall();

         zinstall.EMPTY_CACHE();
         halt(0);
   end;

 if ParamStr(1)='APP_FETCHMAIL' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         fetchmail:=install_fetchmail.Create();
         fetchmail.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

 if ParamStr(1)='APP_VNSTAT' then begin
         fetchmail:=install_fetchmail.Create();
         fetchmail.VNSTAT();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_KAV4PROXY' then begin
         squid:=tsetup_squid.Create;
         squid.kav4proxy_install();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_SOCAT' then begin
         squid:=tsetup_squid.Create;
         squid.socat();
         halt(0);
   end;



   if ParamStr(1)='APP_KAVUTILITY2' then begin
         squid:=tsetup_squid.Create;
         squid.kavupdateutility_install();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_DAR' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         ddar:=dar.Create;
         ddar.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_DANSGUARDIAN' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         squid:=tsetup_squid.Create;
         squid.dansgardian_install();

         zinstall.EMPTY_CACHE();
         halt(0);
   end;


  if ParamStr(1)='APP_KAV4SAMBA' then begin
         kavsamba:=tsetup_kavsamba.Create;
         kavsamba.xinstall();

         halt(0);
   end;

  if ParamStr(1)='APP_C_ICAP' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         ccicap:=cicap.Create;
         if ParamStr(2)='-configure' then begin
            ccicap.configure();
            writeln('done');
            halt(0);
         end;
         ccicap.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_GNARWL' then begin
      fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
      sgnarwl:=gnarwl.Create;
      sgnarwl.xinstall();
      halt(0);
   end;


  if ParamStr(1)='APP_COLLECTD' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         collectd:=tsetup_collectd.Create;
         collectd.collectd_install();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_KAVMILTER' then begin
         kavmilter:=tsetup_kavmilter.Create;
         if ParamStr(2)='remove' then begin
            kavmilter.xremove();
            halt(0);
         end;

         kavmilter.xinstall();

         halt(0);
   end;

   if ParamStr(1)='APP_KAV4LMS' then begin
         kavmilter:=tsetup_kavmilter.Create;
         kavmilter.xremove();
         kavmilter.kav4lms_xinstall();

         halt(0);
   end;

    if ParamStr(1)='APP_KLMS' then begin
         kavmilter:=tsetup_kavmilter.Create;
         kavmilter.xinstall_klms();
         halt(0);
   end;





   if ParamStr(1)='APP_CLAMAV_MILTER' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-postfix');
         clamav:=tsetup_clamav.Create;
         clamav.install_clamav();

         halt(0);
   end;

   if ParamStr(1)='APP_CLAMAV' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         clamav:=tsetup_clamav.Create;
         clamav.install_clamav();

         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_MILTERGREYLIST' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-postfix');

         greylist:=miltergreylist.Create;
         greylist.xinstall();

         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_MAILSPY' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-postfix');
         mailspy:=milterspy.Create;
         mailspy.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_KAS3' then begin
         kas3:=tsetup_kas3.Create();
         kas3.install_kas3();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_SIMPLE_GROUPEWARE' then begin
         SimpleGroupWare:=tsetup_simple_groupware.Create();
         SimpleGroupWare.install_groupware();

         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_OBM' then begin
         zobm:=tobm_install.Create;
         zobm.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_ATOPENMAIL' then begin
         atmail:=tatmail.Create();
        if ParamStr(2)='--config' then begin
          atmail.SetConfig();
          halt(0);
        end;


         if ParamStr(2)='patch' then begin
              atmail.PatchingLogonForm();
              halt(0);
         end;

         if ParamStr(2)='reconfigure' then begin
              writeln('Reconfigure Atmail... All datas will be erased...');
              atmail.SetConfig();
              atmail.CreateDatabase();
              zinstall.EMPTY_CACHE();
              halt(0);
         end;


         atmail.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   //APP_AMAVISD_MILTER --local
   if ParamStr(1)='APP_MAIL_DKIM' then begin
      amavis:=amavisd.Create();
      amavis.install_MAIL_DKIM();
      zinstall.EMPTY_CACHE();
      halt(0);
   end;






   //APP_COMPRESS_ROW_ZLIB
   if ParamStr(1)='APP_COMPRESS_ROW_ZLIB' then begin
      amavis:=amavisd.Create();
      if not amavis.CheckCompressRowZlib() then begin
         amavis.COMPRESS_ROW_ZLIB();
         halt(0);
      end;
      halt(0);
   end;


   if ParamStr(1)='APP_AMAVISD_MILTER' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-postfix');

       amavis:=amavisd.Create();
       spamassassin:=tspam.Create;
       spamassassin.xinstall();
       if ParamStr(2)='--local' then begin
          amavis.xinstall();
          zinstall.EMPTY_CACHE();
          halt(0);
       end;


       if ParamStr(2)='dnew' then begin
          amavis.xinstallamavis();
          zinstall.EMPTY_CACHE();
          halt(0);
       end;
       amavis.xinstall();
       zinstall.EMPTY_CACHE();
       halt(0);


   end;


   if ParamStr(1)='APP_AMAVISD_NEW' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-postfix');
          spamassassin:=tspam.Create;
          spamassassin.xinstall();
          amavis:=amavisd.Create();
          amavis.xinstallamavis();
          zinstall.EMPTY_CACHE();
          halt(0);
   end;

   if ParamStr(1)='APP_MIMEDEFANG' then begin
          amavis:=amavisd.Create();
          amavis.mimedefang_install();
          zinstall.EMPTY_CACHE();
          halt(0);
   end;

   if ParamStr(1)='APP_ALTERMIME' then begin
         amavis:=amavisd.Create();
         amavis.altermime_install();
         amavis.ripmime_install();
         zinstall.EMPTY_CACHE();
       halt(0);
   end;
    if ParamStr(1)='APP_RIPMIME' then begin
         amavis:=amavisd.Create();
         amavis.altermime_install();
         amavis.ripmime_install();
         zinstall.EMPTY_CACHE();
       halt(0);
   end;


   if ParamStr(1)='APP_DSPAM' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-postfix');
         amavis:=amavisd.Create();
         amavis.dspam_install();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_IMAPSYNC' then begin
          fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
          imaps:=imapsync.Create();
          imaps.xinstall();
          zinstall.EMPTY_CACHE();
          halt(0);
   end;

    if ParamStr(1)='APP_OFFLINEIMAP' then begin
          imaps:=imapsync.Create();
          imaps.offlineimap();
          zinstall.EMPTY_CACHE();
          halt(0);
   end;



   if ParamStr(1)='APP_ISOQLOG' then begin
          fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
          zisoqlog:=isoqlog.Create();
          zisoqlog.xinstall();
          zinstall.EMPTY_CACHE();
          halt(0);
   end;

   if ParamStr(1)='APP_DOTCLEAR' then begin
          zdotclear:=dotclear.Create;
          zdotclear.xinstall();
          zinstall.EMPTY_CACHE();
          halt(0);
   end;


   if ParamStr(1)='APP_JCHKMAIL' then begin
      fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
      zjcheckmail:=jcheckmail.Create();
      zjcheckmail.xinstall();
      zinstall.EMPTY_CACHE();
      halt(0);
   end;

   if ParamStr(1)='APP_POMMO' then begin
      pommo:=tpommo.Create();
      pommo.xinstall();
      zinstall.EMPTY_CACHE();
      halt(0);
   end;
   writeln('');
   writeln('UNABLE TO UNDERSTAND "'+ParamStr(1)+'"');
   writeln('');
   writeln('Systems applications');
   writeln('___________________________________________________________');
   writeln('APP_COLLECTD.............: install collectd from sources');
   writeln('APP_VMTOOLS..............: install VMWare Tools');
   writeln('APP_VBOXADDITIONS........: install VirtualBox Additions');
   writeln('APP_POMMO................: install poMMo from sources');
   writeln('APP_EMAIL_RELAY..........: install/reconfigure Email-relay');
   writeln('APP_EMAILRELAY_REMOVE....: Uninstall Email-relay');
   writeln('APP_STUNNEL..............: install Install universal SSL Tunnel');
   writeln('APP_GNUPLOT..............: install gnuplot,dtsat');
   writeln('APP_DSTAT................: install gnuplot,dtsat');
   writeln('APP_VNSTAT...............: install vnStat');
   writeln('APP_HOSTAPD..............: install hostapd (wifi)');
   writeln('APP_FUSE.................: install fuse');
   writeln('APP_ZFS_FUSE.............: install zfs-fuse');
   writeln('APP_TOKYOCABINET.........: install TokyoCabinet libraries');
   writeln('APP_MHASH................: install mhash libraries');
   writeln('APP_HAMSTERDB............: install hamsterdb libraries');
   writeln('APP_LESSFS...............: install lessFS File System');
   writeln('APP_LXC..................: install LXC Containers');
   writeln('APP_PDNS.................: install PowerDNS');
   writeln('APP_POWERADMIN...........: install PowerAdmin Web console for PowerDNS');
   writeln('APP_IPTACCOUNT...........: install xt_ACCOUNT iptables module');
   writeln('APP_AMANDA...............: install Amanda backup system');
   writeln('APP_DHCP.................: install isc dhcp  system');
   writeln('APP_HAMACHI..............: install LogmeIn hamachi client');
   writeln('APP_HAPROXY..............: install HaProxy load balancer');
   writeln('APP_ARKEIA...............: install Arkeia Backup system');





   writeln('APP_GLUSTERFS............: install GlusterFS (Clustering)');
   writeln('APP_MONIT................: install Monit (system monitor)');
   writeln('APP_THINCLIENT...........: install ThinClient OS');
   writeln('APP_THINSTATION..........: install ThinClient OS');
   writeln('APP_KUPDATE_UTILITY......: install Kaspersky Update Utility 2.0');
   writeln('APP_KASPERSKY_UPDATE_UTILITY: install Kaspersky Update Utility 2.0');

   writeln('');
   writeln('');
   writeln('Apache/php modules');
   writeln('___________________________________________________________');
   writeln('APP_MOD_PAGESPEED........: install mod_pagespeed');
   writeln('APP_MOD_QOS..............: install mod_qos');
   writeln('APP_UPLOADPROGRESS.......: install UploadProgress php extension');
   writeln('APP_PHP5_RRD.............: install php5-rrd library');
   writeln('APP_PHP5_MEMCACHED.......: install Memcached daemon and php5 extension');


   writeln('');
   writeln('');
   writeln('Groupwares applications');
   writeln('___________________________________________________________');
   writeln('APP_JOOMLA...............: install Joomla sources 1.5.x');
   writeln('APP_JOOMLA17.............: install Joomla sources 1.7.x');
   writeln('APP_WORDPRESS............: install WordPress');
   writeln('APP_SUGARCRM.............: install SugarCRM sources');
   writeln('APP_SIMPLE_GROUPEWARE....: install SimpleGroupware from sources');
   writeln('APP_DOTCLEAR.............: install DotClear (blog interface)');
   writeln('APP_ATOPENMAIL...........: install @Mail open (webmail)');
   writeln('APP_ROUNDCUBE3...........: install RoundCube WebMail generation 3');
   writeln('APP_ROUNDCUBE3_SIEVE_RULE: install RoundCube Sieve plugin for RoundCube generation 3');
   writeln('APP_GROUPWARE_APACHE.....: Install dedicated Apache engine for groupwares applications');
   writeln('APP_GROUPWARE_PHP........: Install dedicated PHP engine for groupwares applications');
   writeln('APP_PHPLDAPADMIN.........: Install PhpLDAPadmin');
   writeln('APP_GREENSQL.............: Install Greensql firewall');
   writeln('APP_PHPMYADMIN...........: Install phpMyadmin');
   writeln('APP_OBM..................: install OBM v2.1 groupware calendar');
   writeln('APP_OBM2.................: install OBM v2.2 groupware calendar');
   writeln('APP_PIWIGO...............: install PIWIGO sources');
   writeln('APP_EYEOS................: install EyeOS sources');
   writeln('APP_DRUPAL...............: install drupal 6.x version');
   writeln('APP_DRUPAL7..............: install drupal 7.x version');
   writeln('APP_DRUSH7...............: install drush 7.x version');
   writeln('APP_DRUPAL7_LANGS........: install drupal 7.x language pack');
   writeln('APP_OPENEMM..............: install OpenEMM application');
   writeln('APP_TOMCAT...............: install Tomcat web server');
   writeln('APP_CONCRETE5............: install Concrete5 CMS');




   writeln('');
   writeln('');
   writeln('SQUID');
   writeln('___________________________________________________________');
   writeln('APP_SQUID0...............: install SQUID 2.7.x with ICAP enabled');
   writeln('APP_SQUID2...............: install SQUID 3.2.x with ICAP enabled');
   writeln('APP_SQUID................: install SQUID 3.x, SQUID 3.1.x with ICAP enabled');
   writeln('APP_SQUID................:  --reconfigure to recompile');
   writeln('APP_SQUID................:  --configure to display only configure directives');
   writeln('APP_MSKTUTIL.............:  install keytab client for Microsoft Active Directory');
   writeln('APP_SQUID32_PURGE........:  install purge tool');
   writeln('');
   writeln('APP_SQUIDGUARD...........: install SquidGuard');
   writeln('APP_SQUIDGUARD...........:  --reconfigure to recompile (not implemented)');
   writeln('APP_SQUIDGUARD...........:  --configure to display only configure directives');
   writeln('');
   writeln('APP_KAV4PROXY............: install Kaspersky For Squid');
   writeln('APP_C_ICAP...............: install c-icap');
   writeln('APP_DANSGUARDIAN.........: install/reconfigure Dansguardian');
   writeln('APP_UFDBGUARD............: install/reconfigure UFDBGUARD');
   writeln('APP_SQUIDCLAMAV..........: install/reconfigure SquidClamAV');
   writeln('APP_ECAPAV...............: install/reconfigure install Securepoint eCAP antivirus adapter');





   writeln('');
   writeln('');
   writeln('File Sharing & computer management');
   writeln('___________________________________________________________');
   writeln('APP_SAMBA................: install/reconfigure Samba current branch');
   writeln('APP_SAMBA35..............: install/reconfigure Samba 3.5x branch');
   writeln('APP_SAMBA36..............: install/reconfigure Samba 3.6x branch');
   writeln('APP_CTDB.................: install/reconfigure CTDB libraries for Samba clustering support');

   writeln('APP_KAV4SAMBA............: install Kaspersky For Samba server');
   writeln('APP_KAV4FS...............: install Kaspersky For Linux File server 8.x');
   writeln('APP_DROPBOX..............: install DropBox client');
   writeln('APP_NETATALK.............: install Networking Apple Macintosh');

   writeln('APP_BACKUPPC.............: install BackupPC');
   writeln('APP_MLDONKEY.............: install MlDonkey');
   writeln('APP_CUPS_DRV.............: install/reconfigure Cups printers drivers');
   writeln('APP_CUPS_BROTHER.........: install/reconfigure Cups Brother printers drivers');
   writeln('APP_GUTENPRINT...........: install/reconfigure Cups gimp additionals drivers');
   writeln('APP_FOO2ZJS..............: install/reconfigure foo2hp --force to install/upgrade');
   writeln('APP_HPINLINUX............: install/reconfigure HP Printers');
   writeln('APP_PUREFTPD.............: install/reconfigure pure-ftpd');
   writeln('APP_SABNZBDPLUS..........: install/reconfigure SABnzbd');
   writeln('APP_FUPPES...............: install/reconfigure Fuppes has the main UPNP server');
   writeln('APP_OCS_SERVER...........: install/reconfigure OCS Inventory 2.x');
   writeln('APP_OCSI2................: install/reconfigure OCS Inventory 2.x (alias)');
   writeln('APP_OCSI.................: install/reconfigure OCS Inventory 1.x');
   writeln('APP_OCSI_CLIENT..........: install/reconfigure OCS Inventory 1.x (clients)');
   writeln('APP_OCSI_FUSIONCLIENT....: install/reconfigure OCS Fusion Inventory 1.x (clients)');





   writeln('');
   writeln('');
   writeln('Messaging');
   writeln('___________________________________________________________');
   writeln('APP_CYRUS_IMAP...........: install/reconfigure Cyrus-imapd');
   writeln('APP_FETCHMAIL............: install/reconfigure Fetchmail');
   writeln('APP_COMPRESS_ROW_ZLIB....: Check Compress:Row:Zlib library');
   writeln('APP_AMAVISD_MILTER.......: install amavisd-new and amavisd-milter');
   writeln('APP_AMAVISD_NEW..........: install amavisd-new');
   writeln('APP_KAVMILTER............: install Kaspersky Anti-virus SendMail edition');
   writeln('APP_MAILSPY..............: install mail-spy');
   writeln('APP_MILTERGREYLIST.......: install milter-greylist');
   writeln('APP_KAS3.................: install Kaspersky Anti-spam 3.x');
   writeln('APP_IMAPSYNC.............: install imapsync');
   writeln('APP_MAILSYNC.............: install mailsync');
   writeln('APP_OFFLINEIMAP..........: install offlineimap');
   writeln('APP_DSPAM................: install dspam');
   writeln('APP_ALTERMIME............: install AlterMIME for amavis');
   writeln('APP_CLAMAV...............: install/update clamav engines');
   writeln('APP_GNARWL...............: install gnarwl vacation addon');
   writeln('APP_MHONARC..............: install MHonArc has a Perl mail-to-HTML converter');
   writeln('APP_MSMTP................: install/reconfigure artica-msmtp ');
   writeln('APP_PFLOGSUMM............: install/reconfigure PFLOGSUMM ');
   writeln('APP_SPAMASSASSIN.........: install/reconfigure SpamAssassin add --remove to uninstall');
   writeln('APP_OPENDKIM.............: install/reconfigure OpenDKIM');
   writeln('APP_MILTER_DKIM..........: install/reconfigure Milter-DKIM');
   writeln('APP_CLAMAV_MILTER........: install clamav and clamav milter');
   writeln('APP_JCHKMAIL.............: install jcheckmail');
   writeln('APP_ISOQLOG..............: install isoqlog');
   writeln('APP_CROSSROADS...........: install Crossroads Load Balancer');
   writeln('APP_CLUEBRINGER..........: install cluebringer (has policyd v2.0)');






   writeln('');
   writeln('');
   writeln('ZARAFA');
   writeln('___________________________________________________________');
   writeln('APP_ZARAFA_WEBAPP........: Install the successor to the existing Zarafa WebApp');
   writeln('APP_ZARAFA_LIBVMIME......: install libvmime for Zarafa');
   writeln('APP_ZARAFA...............: install Zarafa');
   writeln('APP_ZARAFA...............: --remove to remove and re-install');
   writeln('APP_Z_ADMIN..............: install z-admin administration interface');
   writeln('APP_YAFFAS...............: install z-admin administration interface');
   writeln('');







   writeln('');
   writeln('');
   writeln('XAPIAN');
   writeln('___________________________________________________________');
   writeln('APP_XAPIAN...............: install/reconfigure xapian library search');
   writeln('APP_XAPIAN_OMEGA.........: install/reconfigure xapian spider search');
   writeln('APP_XAPIAN_PHP...........: install/reconfigure xapian php library');
   writeln('APP_XPDF APP_UNRTF APP_CATDOC APP_ANTIWORD install/reconfigure xapian convert tools');
   writeln('');

   if FileExists('/usr/share/artica-postfix/ressources/install/'+ParamStr(1)+'.dbg') then fpsystem('/bin/rm -f /usr/share/artica-postfix/ressources/install/'+ParamStr(1)+'.dbg');
   if FileExists('/usr/share/artica-postfix/ressources/install/'+ParamStr(1)+'.ini') then fpsystem('/bin/rm -f /usr/share/artica-postfix/ressources/install/'+ParamStr(1)+'.ini');











end.

