#!/bin/bash

image=$1

region="buildbot-ccr@ccr-cbls-1"


emi=`euca-describe-images --region $region|grep centos7 |grep -v ebs |head -n 1 |cut -f 2`

echo "Starting imager instance"

inst=`euca-run-instances --region $region -n 1 -g buildbot -k buildbot -t m2.2xlarge -f userdata.sh $emi | grep INSTANCE | cut -f 2`

echo "Creating volume"

vol=`euca-create-volume --region $region -z ccr-cbls-1a -s 10 |cut -f 2`

ip=`euca-describe-instances --region $region $inst |grep INSTANCE | awk '{print $13}'`

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

echo "Attaching volume"

# The -d option is ignored, but required, perfect
euca-attach-volume --region $region $vol -i $inst -d /dev/sdq

# Give everything a chance to come up
echo "Instance booted"
sleep 20

echo "Running dd"

# Note the braindead device file name, looks like exactly what we chose :(
dd if=$image | ssh -o "StrictHostKeyChecking no" -i ~/.ssh/buildbot.key centos@$ip sudo dd of=/dev/vdc

echo "Detaching volume"

euca-detach-volume --region $region $vol

echo $vol
