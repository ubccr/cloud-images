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

if [ "$IMAGE_TYPE" != "local" ]; then

	yum install -y pcp pcp-conf pcp-libs pcp-libs-devel pcp-system-tools perl-PCP-PMDA python-pcp
	
	yum -y update
	
	#Allow sudo over ssh
	#sed -i -e 's/Defaults    requiretty//' -e 's/Defaults   !visiblepw//' /etc/sudoers
	
	# Setup secure pcp
	cd /tmp/deploy
	/bin/bash ./secure-pcp.sh 
	
	systemctl enable haveged
	
	# Start pcp on boot
	systemctl enable pmcd
	
	# Turn on proc reporting
	sed -i -e '/iam=proc/a args=-A' /var/lib/pcp/pmdas/proc/Install
	touch /var/lib/pcp/pmdas/proc/.NeedInstall
	
	# Configure hotproc
	cp /tmp/deploy/hotproc.conf /var/lib/pcp/pmdas/proc/
fi

sed -i -e 's/.*PasswordAuthentication.*//g' -e 's/.*PermitRootLogin.*//g' /etc/ssh/sshd_config
sed -i -e 's/.*ssh_pwauth.*//g' -e 's/.*disable_root.*//g' /etc/cloud/cloud.cfg

echo "disable_root: 1" >> /etc/cloud/cloud.cfg
echo "ssh_pwauth:   0" >> /etc/cloud/cloud.cfg

echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
echo "PermitRootLogin no" >> /etc/ssh/sshd_config

passwd --delete root
passwd --lock root

cat /etc/cloud/cloud.cfg
