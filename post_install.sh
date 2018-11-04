#!/bin/sh

# Enable the service
sysrc -f /etc/rc.conf backuppc_enable="YES"
sysrc -f /etc/rc.conf apache24_enable="YES"

# Configure the service
echo "" | sh /usr/local/etc/backuppc/update.sh

chmod 755 /usr/local/www/cgi-bin/BackupPC_Admi

# Start the service
service backuppc start 2>/dev/null
service apache24 restart 2>/dev/null
