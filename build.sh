#!/bin/bash

# Inputs:
#  user
#  region
#  zone

function badexit
{
    echo "$1" 1>&2
    exit 1
}

function retry {
  local n=1
  local max=9
  local delay=30
  while true; do
    "$@" && break || {
      if [[ $n -lt $max ]]; then
        ((n++))
        echo "Command failed. Attempt $n/$max:"
        sleep $delay;
      else
        badexit "The command has failed after $n attempts."
      fi
    }
  done
}

function myebs
{
	
	# Need to update the zone mapping below if you add a region
	zone="NEED_TO_SET_ZONE"

	#buildbot@ccr-cbls-2 buildbot-ccr@ccr-cbls-1 buildbot-dev@ccr-cbls-dev
	if [ "$region" == "buildbot@ccr-cbls-2" ]; then
		zone="ccr-cbls-2a"
	elif [ "$region" == "buildbot-ccr@ccr-cbls-1" ]; then
		zone="ccr-cbls-1a"
	elif [ "$region" == "buildbot-dev@ccr-cbls-dev" ]; then
		zone="ccr-cbls-dev"
	fi

	# Global $region and $imagename are used

	emi=`euca-describe-images --region $region|grep centos7-ccr |grep -v ebs |grep -v FOREMAN | head -n 1 |cut -f 2`

	[[ ! -z "$emi" ]] || badexit "No usable image"
	
	echo "Starting imager instance"
	
	# Need to check for error here
	inst=`euca-run-instances --region $region -z $zone -n 1 -g buildbot -k buildbot -t m2.2xlarge -f ../userdata.sh $emi | grep INSTANCE | cut -f 2`
	
	echo "Creating volume"
	
	# Need to check for error here
	vol=`euca-create-volume --region $region -z $zone -s 10 | cut -f 2`
	
	# Name the volume so we can find orphaned ones later
	retry euca-create-tags --region $region $vol --tag Name="$imagename"

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
	
	# So even after the instance is booted, you can get:
	# euca-attach-volume: error (IncorrectState): Instance 'i-c9b9581d' is not 'running'
	# Need to wait for quite a while
	#sleep 30

	# The -d option is ignored, but required, perfect
	retry euca-attach-volume --region $region $vol -i $inst -d /dev/sdq
	
	[[ "$?" -eq "0" ]] || badexit "Failed to attach volume $vol"

	# Give everything a chance to come up
	# sleep 30
	retry ssh -o "StrictHostKeyChecking no" -o "CheckHostIP no" -i ~/.ssh/buildbot.key centos@$ip hostname
	echo "Instance booted"

	echo "Looking for volumes"
	ssh -o "StrictHostKeyChecking no" -o "CheckHostIP no" -i ~/.ssh/buildbot.key centos@$ip lsblk

	sleep 60
	
	echo "Running dd"
	# Note the braindead device file name, looks like exactly what we chose :(
	dd if=$imagename/$imagename | ssh -o "StrictHostKeyChecking no" -o "CheckHostIP no" -i ~/.ssh/buildbot.key centos@$ip sudo dd of=/dev/vdc
	
	[[ "$?" -eq "0" ]] || badexit "Failed to DD"

	echo "Detaching volume"
	
	euca-detach-volume --region $region $vol

	[[ "$?" -eq "0" ]] || badexit "Failed to detach volume"

	echo "Terminating instance"

	euca-terminate-instances --region $region $inst

	[[ "$?" -eq "0" ]] || badexit "Failed to termiante instance $inst"
	
	# global return
	volid=$vol	
}

rev=$1

if [ -z $rev ]; then
	echo "Rev required"
	exit 1
fi


os=${PWD##*/}

extraname=""

if [ ! -z "$EXTRA_NAME" ]; then
	extraname="$EXTRA_NAME"-
fi	

builddate=`date +%Y%m%d`
imagename=$os-ccr-$extraname$builddate-$rev
ebsimagename=$os-ebs-ccr-$extraname$builddate-$rev
fulllog=$imagename.log

zone=ccr-cbls-2a

touch $fulllog

# Build the qemu image
# May take a long time, 5-10 minutes
# Can connect to the build with: vncviewer -Shared localhost:<port>

echo "Building packer image: $imagename" | tee -a $fulllog

sed -e "s/CHANGE_NAME/$imagename/g" packer.json > packer-$builddate.json
packer build -var-file=../vars.json packer-$builddate.json >> $fulllog || badexit "Can't build: $imagename"

# Convert for Euca
if [[ "$imagename" =~ "coreos" ]]; then
	echo "Skipping virt-sysprep for coreos" | tee -a $fulllog
else
	echo "Running virt-sysprep" | tee -a $fulllog
	virt-sysprep -a $imagename/$imagename >> $fulllog || badexit "Can't virt-sysprep $imagename"
fi

#regions='buildbot@ccr-cbls-2 buildbot-ccr@ccr-cbls-1 buildbot-dev@ccr-cbls-dev'
#regions='buildbot@ccr-cbls-2'
#regions='buildbot-dev@ccr-cbls-dev'

if [ ! -z "$BUILD_REGIONS" ]; then
	regions="$BUILD_REGIONS"
fi

if [ -z "$regions" ]; then
	echo "Regions required"
	exit 1
fi

for region in $regions; do

	echo "Adding to region: $region"

	fulllog="$imagename.$region.log"
	touch $fulllog

	# Install Instance store Image
	echo "euca-install-image for: $imagename" | tee -a $fulllog
	euca-install-image --region $region -i $imagename/$imagename --description $os --virtualization-type hvm -b $imagename -r x86_64 --name $imagename >> $fulllog || badexit "euca-install-image failed"
	
	emi=`grep ^IMAGE $fulllog |cut -f 2`
	
	if [ -z "$PRIVATE" ]; then
		# Make public
		echo "Making $emi public" | tee -a $fulllog
		euca-modify-image-attribute --region $region -l -a all $emi >> $fulllog || badexit "Can't make $emi public"
	fi


	echo "Running our own EBS import for $ebsimagename"

	myebs
		
	# Create the snapshot from the volume
	echo "Make snapshot for $volid" | tee -a $fulllog
	euca-create-snapshot --region $region $volid >> $fulllog || badexit "Can't make snapshot for $volid"
	
	importsnap=`grep SNAPSHOT $fulllog |cut -f 2`
	
	while true ; do
		echo "Waiting for Snapshot $importsnap task to finish..." | tee -a $fulllog
		euca-describe-snapshots --region $region $importsnap | grep completed && break
		sleep 10
	done
	
	# Name the snapshot so we can find orphaned ones later
	euca-create-tags --region $region $importsnap --tag Name="$imagename"
	
	# Register the EBS image
	euca-register --region $region --name $ebsimagename --description "$os-ebs" --snapshot $importsnap -a x86_64 >> $fulllog || badexit "Can't register EBS: $ebsimagename from $importsnap"
	
	ebsemi=`grep ^IMAGE $fulllog | tail -1 | cut -f 2`
	
	if [ -z "$PRIVATE" ]; then
		# Make public
		echo "Making EBS $ebsemi public" | tee -a $fulllog
		euca-modify-image-attribute --region $region -l -a all $ebsemi >> $fulllog || badexit "Can't make EBS image public"
	fi

	
	touch $region.info
	echo "emi=$emi" >> $region.info
	echo "ebsemi=$ebsemi" >> $region.info
	echo "vol=$volid" >> $region.info
	echo "snap=$importsnap" >> $region.info

done

# Make a backup
echo "Copying to /srv/cosmos/euca/images"
cp -r $imagename /srv/cosmos/euca/images/$os
cp *.info /srv/cosmos/euca/images/$os/$imagename/
