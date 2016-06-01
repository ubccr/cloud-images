#!/bin/bash

# Add the public ip for the mirror since thats what is accessable
echo "128.205.41.74 mirrors.ccr.buffalo.edu" >> /etc/hosts

# Add our repos
/bin/cp -f /tmp/deploy/CentOS-Base.repo

# Disable fastest mirror plugin since we only list our repo
sed -i -e 's/enabled=1/enabled=0/' /etc/yum/pluginconf.d/fastestmirror.conf

yum clean all
yum repolist

yum install -y epel-release

/bin/cp -f /tmp/deploy/epel.repo /etc/yum.repos.d/

yum clean all
yum repolist

yum install -y cloud-init

yum -y update

cat /etc/cloud/cloud.cfg
