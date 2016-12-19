#!/bin/bash

image=$1

function badexit
{
    echo "$1" 1>&2
    exit 1
}

if [ -z $image ]; then
        echo "Need an image name"
        exit 1;
fi

user='none'

if [[ $image =~ "debian" ]]; then
	user='debian'
elif [[ $image =~ "ubuntu" ]]; then
	user='ubuntu'
elif [[ $image =~ "centos" ]]; then
	user='centos'
fi

emi=`euca-describe-images |grep $image |cut -f 2`

echo "Booting $emi"

inst=`euca-run-instances -n 1 -g buildbot -k buildbot -t m1.small $emi |grep INSTANCE |cut -f 2`

if [ -z "$inst" ]; then
	badexit "Failed to start $emi"
fi

echo "Pending: $inst"

ip=`euca-describe-instances $inst |grep INSTANCE |cut -f 17`

if [ -z "$ip" ]; then
        badexit "Couldn't find IP for $emi"
fi

echo "Found IP: $ip"

timer=0

while true ; do
	if [ "$timer" -eq "24" ]; then
		echo "$inst failed to boot"
		exit 1
	fi
        echo "Waiting for $inst to boot"
	ping -c 1 $ip && break
        sleep 10
	((timer++))
done

# Give everything a chance to come up
echo "Instance booted"
sleep 10

echo "Checking PCP install"

timer=0
pcpfail=0

# The centos6-ebs image takes forever for pcp to come up, give it a few tries

while true ; do
        if [ "$timer" -eq "24" ]; then
                echo "$inst failed to connect"
                pcpfail=1
        fi
	ssh -i ~/.ssh/buildbot.key -o "StrictHostKeyChecking no" $user@$ip pminfo -f kernel.uname.nodename && break
	sleep 10
	((timer++))
done

if [ "$pcpfail" -eq "0" ]; then
	echo "Image $image is GOOD"
	ssh -i ~/.ssh/buildbot.key -o "StrictHostKeyChecking no" $user@$ip uname -a
	euca-terminate-instances $inst
	exit 0
else
	echo "Image $image is BAD"
	exit 1
fi
