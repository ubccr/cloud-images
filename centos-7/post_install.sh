#!/bin/bash
yum install -y epel-release
yum install -y cloud-init

yum -y update

### Configure cloud-init for root
#sed -i 's/disable_root:.*/disable_root: 0/g' /etc/cloud/cloud.cfg
#sed -i 's/cloud-user/root/g' /etc/cloud/cloud.cfg

cat /etc/cloud/cloud.cfg
