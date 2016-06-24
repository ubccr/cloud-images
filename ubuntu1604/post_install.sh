#!/bin/bash

apt-get update

apt-get -y install cloud-init traceroute apt-file libnss3-tools

apt-get -y upgrade

apt-file update

# Add our local repo
echo "deb http://mirrors.ccr.buffalo.edu/ccr/ubuntu/1604 ./" >> /etc/apt/sources.list

apt-get update

apt-get -y install pcp libpcp3-dev

echo "apt_preserve_sources_list: true" >> /etc/cloud/cloud.cfg

# Setup secure pcp
cd /tmp/deploy
/bin/bash ./secure-pcp.sh

# Start pmcd only on boot
systemctl enable pmcd
systemctl disable pmie
systemctl disable pmlogger
systemctl disable pmproxy

# Turn on proc reporting
sed -i -e '/iam=proc/a args=-A' /var/lib/pcp/pmdas/proc/Install
touch /var/lib/pcp/pmdas/proc/.NeedInstall

cat /etc/cloud/cloud.cfg
