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
  --config-override CgiImageDirURL=\"\" \
  --config-override CgiAdminUsers=\"backuppc\" \
  --config-override RsyncClientPath=\"/usr/bin/rsync\"

htpasswd -b -c /usr/local/etc/backuppc/htpasswd "backuppc" "password"

chmod 750 /usr/local/www/cgi-bin/BackupPC_Admin
chown backuppc:backuppc -R /usr/local/etc/backuppc

# Set home directory (for ssh keys)
pw usermod -n backuppc -m -d /home/backuppc
# Generate ssh keys
su -m backuppc -c "ssh-keygen -t rsa -N '' -f /home/backuppc/.ssh/id_rsa"
echo
echo "SSH public key:"
cat /home/backuppc/.ssh/id_rsa.pub
echo "Add this to the authorized_keys of the client machines you want to backup using ssh public key authentication"

# Start the service
service backuppc restart 2>/dev/null
service apache24 restart 2>/dev/null
