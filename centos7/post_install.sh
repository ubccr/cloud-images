#!/bin/bash

# Add the public ip for the mirror since thats what is accessable
echo "128.205.41.74 mirrors.ccr.buffalo.edu" >> /etc/hosts

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
yum install -y cloud-init cloud-utils-growpart

yum -y update

#Allow sudo over ssh
sed -i -e 's/Defaults    requiretty//' -e 's/Defaults   !visiblepw//' /etc/sudoers

# Setup secure pcp
cd /tmp/deploy
/bin/bash ./secure-pcp.sh 

# Start pcp on boot
systemctl enable pmcd

# Turn on proc reporting
sed -i -e '/iam=proc/a args=-A' /var/lib/pcp/pmdas/proc/Install
touch /var/lib/pcp/pmdas/proc/.NeedInstall

cat /etc/cloud/cloud.cfg
