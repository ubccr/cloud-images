#!/bin/bash

wget -O - http://mirrors.ccr.buffalo.edu/full-mirror/ccr/RPM-GPG-KEY-ccrpkg | apt-key add -

echo "deb http://mirrors.ccr.buffalo.edu/full-mirror/ccr/ubuntu/1404 /" >> /etc/apt/sources.list

apt-get update

apt-get -y install cloud-init traceroute libnss3-tools apt-file pcp libpcp3-dev

apt-get -y upgrade

apt-file update

# Keep our apt sources
echo "apt_preserve_sources_list: true" >> /etc/cloud/cloud.cfg

# Setup secure pcp
cd /tmp/deploy
/bin/bash ./secure-pcp.sh

# Start pmcd only on boot, upstart is a pain
update-rc.d pmie
update-rc.d pmlogger
update-rc.d pmproxy

# Turn on proc reporting
sed -i -e '/iam=proc/a args=-A' /var/lib/pcp/pmdas/proc/Install
touch /var/lib/pcp/pmdas/proc/.NeedInstall

cat /etc/cloud/cloud.cfg
