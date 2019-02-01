#!/bin/sh

LOGFILE="/var/log/post_install.log"
date >> $LOGFILE

# Enable the service
sysrc -f /etc/rc.conf backuppc_enable="YES"
sysrc -f /etc/rc.conf apache24_enable="YES"

# Configure the service
echo "" | sh /usr/local/etc/backuppc/update.sh >> $LOGFILE
perl -I /usr/local/lib /usr/local/libexec/backuppc/configure.pl \
  --batch \
  --config-only \
  --config-dir /usr/local/etc/backuppc \
  --config-override CgiImageDirURL=\"\" \
  --config-override CgiAdminUsers=\"backuppc\" \
  --config-override RsyncClientPath=\"/usr/bin/rsync\" \
  >> $LOGFILE

htpasswd -b -c /usr/local/etc/backuppc/htpasswd "backuppc" "password" >> $LOGFILE

chmod 750 /usr/local/www/cgi-bin/BackupPC_Admin
chown backuppc:backuppc -R /usr/local/etc/backuppc

# Set home directory (for ssh keys)
pw usermod -n backuppc -m -d /home/backuppc
# Generate ssh keys
su -m backuppc -c "ssh-keygen -t rsa -N '' -f /home/backuppc/.ssh/id_rsa" >> $LOGFILE

# Start the service
service backuppc restart 2>/dev/null >> $LOGFILE
service apache24 restart 2>/dev/null >> $LOGFILE

echo
echo "SSH public key:"
cat /home/backuppc/.ssh/id_rsa.pub
echo "Add this to the authorized_keys of the client machines you want to backup using ssh public key authentication"

echo
echo "Standard username and password is"
echo "backuppc password"
echo "You can change the password with"
echo "iocage set -P adminpass=\"newpassword\" backuppc"

echo
echo "Full installation log at $LOGIFLE"
