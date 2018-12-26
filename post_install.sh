#!/bin/sh

# Enable the service
sysrc -f /etc/rc.conf backuppc_enable="YES"
sysrc -f /etc/rc.conf apache24_enable="YES"

# Configure the service
echo "" | sh /usr/local/etc/backuppc/update.sh
perl -I /usr/local/lib /usr/local/libexec/backuppc/configure.pl \
  --batch \
  --config-only \
  --config-dir /usr/local/etc/backuppc \
  --config-override CgiImageDirURL="''" \
  --config-override CgiAdminUsers='backuppc'

htpasswd -b -c /usr/local/etc/apache24/htpasswd "backuppc" "password"

chmod 750 /usr/local/www/cgi-bin/BackupPC_Admin

# Start the service
service backuppc start 2>/dev/null
service apache24 restart 2>/dev/null
