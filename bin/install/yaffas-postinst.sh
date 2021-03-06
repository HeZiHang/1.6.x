#!/bin/bash
# postinst script for bbwebmin-bbproxy
#
# see: dh_installdeb(1)

set -e

# summary of how this script can be called:
#        * <postinst> `configure' <most-recently-configured-version>
#        * <old-postinst> `abort-upgrade' <new version>
#        * <conflictor's-postinst> `abort-remove' `in-favour' <package>
#          <new-version>
#        * <deconfigured's-postinst> `abort-deconfigure' `in-favour'
#          <failed-install-package> <version> `removing'
#          <conflicting-package> <version>
# for details, see http://www.debian.org/doc/debian-policy/ or
# the debian-policy package
#

source /opt/yaffas/lib/bbinstall-lib.sh

case "$1" in
    configure)

	# generate passwort file for admin logging if no one exists
	if [ ! -f /opt/yaffas/etc/webmin/miniserv.users ]; then
		echo "admin:129TZgbE1H546:0" > /opt/yaffas/etc/webmin/miniserv.users
	fi

	# generate acl file for webmin if no one exists
	if [ ! -f /opt/yaffas/etc/webmin/webmin.acl-global ]; then
        echo "admin: " > /opt/yaffas/etc/webmin/webmin.acl-global
        echo "admin: setup" > /opt/yaffas/etc/webmin/webmin.acl-setup
        ln -sf /opt/yaffas/etc/webmin/webmin.acl-setup /opt/yaffas/etc/webmin/webmin.acl
	fi

	touch /opt/yaffas/etc/webmin/hidden_modules

	# correct permissions
	chmod 600 /opt/yaffas/etc/webmin/miniserv.*

	# restart webmin (stop script can crash, so lets kill it!)
	PID=`ps ax | grep -v grep | grep "/opt/yaffas/webmin/miniserv.pl" | awk {' print $1 '}`	
	if [ "$PID" ]; then
	        kill -9 $PID
	        rm -f /opt/yaffas/var/miniserv.pid
	fi


    MODULE="certificate"
    add_webmin_acl $MODULE
    del_license $MODULE "all"
	add_license $MODULE ""

    ;;

    abort-upgrade|abort-remove|abort-deconfigure)

    ;;

    *)
        echo "postinst called with unknown argument \`$1'" >&2
        exit 1
    ;;
esac

# dh_installdeb will replace this with shell code automatically
# generated by other debhelper scripts.



exit 0


