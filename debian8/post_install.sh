#!/bin/bash

wget -O - http://mirrors.ccr.buffalo.edu/ccr/RPM-GPG-KEY-ccrpkg | apt-key add -

echo "deb http://mirrors.ccr.buffalo.edu/ccr/debian/8 /" >> /etc/apt/sources.list
echo "deb http://mirrors.ccr.buffalo.edu/debian jessie-backports main" >> /etc/apt/sources.list

apt-get update

apt-get -y -t jessie-backports install cloud-init

apt-get -y install cloud-initramfs-growroot traceroute libnss3-tools apt-file pcp libpcp3-dev sudo haveged

apt-get -y upgrade

apt-file update

# Keep our apt sources
echo "apt_preserve_sources_list: true" >> /etc/cloud/cloud.cfg

# Debian cloud-init is brain dead
echo "datasource_list: [ Ec2 ]" > /etc/cloud/cloud.cfg.d/90_dpkg.cfg

# Debian uses /bin/sh by default
#sed -i -e 's@SHELL=/bin/sh@SHELL=/bin/bash@' /etc/default/useradd

# Debian cloudinit doesn't turn on sudo
#sed -i -e '/default_user:/a \ \ \ \ \ sudo: ["ALL=(ALL) NOPASSWD:ALL"]' /etc/cloud/cloud.cfg

# Setup secure pcp
cd /tmp/deploy
/bin/bash ./secure-pcp.sh

systemctl enable haveged

# Start pmcd only on boot, upstart is a pain
systemctl enable pmcd
systemctl disable pmie
systemctl disable pmproxy
systemctl disable pmlogger

# Turn on proc reporting
sed -i -e '/iam=proc/a args=-A' /var/lib/pcp/pmdas/proc/Install
touch /var/lib/pcp/pmdas/proc/.NeedInstall

# Configure hotproc
cp /tmp/deploy/hotproc.conf /var/lib/pcp/pmdas/proc/

sed -i -e 's/.*PasswordAuthentication.*//g' -e 's/.*PermitRootLogin.*//g' /etc/ssh/sshd_config
sed -i -e 's/.*ssh_pwauth.*//g' -e 's/.*disable_root.*//g' /etc/cloud/cloud.cfg

echo "disable_root: 1" >> /etc/cloud/cloud.cfg
echo "ssh_pwauth:   0" >> /etc/cloud/cloud.cfg

echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
echo "PermitRootLogin no" >> /etc/ssh/sshd_config

passwd --delete root
passwd --lock root

cat /etc/cloud/cloud.cfg
