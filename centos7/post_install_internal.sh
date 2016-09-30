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
yum install -y cloud-init cloud-utils-growpart haveged

yum -y update

cat /etc/cloud/cloud.cfg
