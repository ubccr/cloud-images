#!/bin/bash

wget -O - http://mirrors.ccr.buffalo.edu/full-mirror/ccr/RPM-GPG-KEY-ccrpkg | apt-key add -

echo "deb http://mirrors.ccr.buffalo.edu/full-mirror/ccr/debian/8 /" >> /etc/apt/sources.list

apt-get update

apt-get -y install cloud-init cloud-initramfs-growroot traceroute libnss3-tools apt-file pcp libpcp3-dev sudo

apt-get -y upgrade

apt-file update

# Keep our apt sources
echo "apt_preserve_sources_list: true" >> /etc/cloud/cloud.cfg

# Debian uses /bin/sh by default
sed -i -e 's@SHELL=/bin/sh@SHELL=/bin/bash@' /etc/default/useradd

# Debian cloudinit doesn't turn on sudo
sed -i -e '/default_user:/a \ \ \ \ \ sudo: ["ALL=(ALL) NOPASSWD:ALL"]' /etc/cloud/cloud.cfg

# Setup secure pcp
cd /tmp/deploy
/bin/bash ./secure-pcp.sh

# Start pmcd only on boot, upstart is a pain
systemctl enable pmcd
systemctl disable pmie
systemctl disable pmproxy
systemctl disable pmlogger

# Turn on proc reporting
sed -i -e '/iam=proc/a args=-A' /var/lib/pcp/pmdas/proc/Install
touch /var/lib/pcp/pmdas/proc/.NeedInstall

cat /etc/cloud/cloud.cfg
