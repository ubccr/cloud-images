#!/bin/bash
yum install -y epel-release

/bin/cp -f /tmp/deploy/CentOS-Base.repo /tmp/deploy/epel.repo /etc/yum.repos.d/

echo "128.205.41.74 mirrors.ccr.buffalo.edu" >> /etc/hosts

yum clean all
yum repolist

yum install -y cloud-init

yum -y update

cat /etc/cloud/cloud.cfg
