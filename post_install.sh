#!/bin/sh

LOGFILE="/var/log/post_install.log"
date >> $LOGFILE

BPC_USER=backuppc

# Enable the service
sysrc -f /etc/rc.conf backuppc_enable="YES" >> $LOGFILE
sysrc -f /etc/rc.conf apache24_enable="YES" >> $LOGFILE

# Configure the service
echo "" | sh /usr/local/etc/backuppc/update.sh >> $LOGFILE
perl -I /usr/local/lib /usr/local/libexec/backuppc/configure.pl \
  --batch \
  --config-only \
  --config-dir /usr/local/etc/backuppc \
  --config-override CgiImageDirURL=\"\" \
  --config-override CgiAdminUsers=\"admin\" \
  --config-override RsyncClientPath=\"/usr/bin/rsync\" \
  >> $LOGFILE
chmod 750 /usr/local/www/cgi-bin/BackupPC_Admin
chown ${BPC_USER}:${BPC_USER} -R /usr/local/etc/backuppc
# Create web admin user
/usr/local/bin/backuppcset "adminpass" "password" >> $LOGFILE

# Create self signed web certificate
TLS_DIR=/usr/local/etc/apache24/tls
mkdir -p ${TLS_DIR}/self-signed
echo "self-signed" > ${TLS_DIR}/self-signed/MODE # marks the current mode for settings script
# TODO not supported by old openssl version:	-addext "subjectAltName = DNS:`hostname`" \
openssl req -newkey rsa:4096 -nodes -sha256 \
  -subj "/O=BackupPC/CN=`hostname`" \
  -keyout ${TLS_DIR}/self-signed/key.pem \
  -out ${TLS_DIR}/self-signed/csr.pem \
  >> $LOGFILE
openssl x509 \
  -signkey ${TLS_DIR}/self-signed/key.pem \
  -in ${TLS_DIR}/self-signed/csr.pem \
  -req -days 2555 -out ${TLS_DIR}/self-signed/cert.pem \
  >> $LOGFILE
TLS_SS_FP=`openssl x509 -in ${TLS_DIR}/self-signed/cert.pem -noout -sha256 -fingerprint`
# TODO acme/user supplied certs go in other directories under ${TLS_DIR}
# create symlinks
ln -sf ./self-signed ${TLS_DIR}/live
chmod -R 600 ${TLS_DIR}
chown -R ${BPC_USER}:${BPC_USER} ${TLS_DIR}

# Set home directory (for ssh keys)
BPC_HOME=/home/${BPC_USER}
pw usermod -n ${BPC_USER} -m -d ${BPC_HOME}
# Generate ssh keys
su -m ${BPC_USER} -c "ssh-keygen -t rsa -N '' -f ${BPC_HOME}/.ssh/id_rsa" >> $LOGFILE
# Disable strict host key checking
cat > ${BPC_HOME}/.ssh/config <<- EOM
Host *
  StrictHostKeyChecking no
EOM
chmod 600 ${BPC_HOME}/.ssh/config
chown ${BPC_USER}:${BPC_USER} ${BPC_HOME}/.ssh/config

# Start the service
service backuppc restart 2>/dev/null >> $LOGFILE
service apache24 restart 2>/dev/null >> $LOGFILE

echo
echo "SSH public key:"
cat ${BPC_HOME}/.ssh/id_rsa.pub
echo "Add this to the authorized_keys of the client machines you want to backup using ssh public key authentication"

echo
echo "Fingerprint of the web certificate"
echo ${TLS_SS_FP}

echo
echo "Standard username and password is"
echo "admin password"
echo "You can change the password with"
echo "iocage set -P adminpass=\"newpassword\" backuppc"

echo
echo "Full installation log at $LOGFILE"
