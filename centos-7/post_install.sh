#!/bin/bash
yum install -y epel-release
yum install -y cloud-init

yum -y update

cat /etc/cloud/cloud.cfg
