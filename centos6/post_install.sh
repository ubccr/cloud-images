#!/bin/bash

# Add our repos
/bin/cp -f /tmp/deploy/CentOS-Base.repo /etc/yum.repos.d/
/bin/cp -f /tmp/deploy/ccr.repo /etc/yum.repos.d/

# Disable fastest mirror plugin since we only list our repo
sed -i -e 's/enabled=1/enabled=0/' /etc/yum/pluginconf.d/fastestmirror.conf

yum clean all
yum repolist

yum install -y epel-release

/bin/cp -f /tmp/deploy/epel.repo /etc/yum.repos.d/

yum clean all
yum repolist

# Need cloud-utils-growpart otherwise ebs resize just fails silently
yum install -y cloud-init cloud-utils-growpart dracut-modules-growroot

# growpart doesn't work in centos6 so use growroot and rebuild initrd
dracut -f

yum -y update

# Setup secure pcp
cd /tmp/deploy
/bin/bash ./secure-pcp.sh 

# Start pcp on boot
chkconfig pmproxy off
chkconfig pmie off
chkconfig pmlogger off

# Turn on proc reporting
sed -i -e '/iam=proc/a args=-A' /var/lib/pcp/pmdas/proc/Install
touch /var/lib/pcp/pmdas/proc/.NeedInstall

cat /etc/cloud/cloud.cfg
