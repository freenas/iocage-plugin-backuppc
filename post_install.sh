#!/bin/sh

# Enable the service
sysrc -f /etc/rc.conf backuppc_enable="YES"

# Start the service
service backuppc start 2>/dev/null
