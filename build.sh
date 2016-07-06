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

function myebs
{

	# Global $region and $imagename are used

	emi=`euca-describe-images --region $region|grep centos7-ccr |grep -v ebs |head -n 1 |cut -f 2`

	[[ ! -z "$emi" ]] || badexit "No usable image"
	
	echo "Starting imager instance"
	
	# Need to check for error here
	inst=`euca-run-instances --region $region -n 1 -g buildbot -k buildbot -t m2.2xlarge -f ../userdata.sh $emi | grep INSTANCE | cut -f 2`
	
	echo "Creating volume"
	
	# Need to check for error here
	vol=`euca-create-volume --region $region -z ccr-cbls-1a -s 10 | cut -f 2`
	
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
	
	sleep 10

	# The -d option is ignored, but required, perfect
	euca-attach-volume --region $region $vol -i $inst -d /dev/sdq
	
	[[ "$?" -eq "0" ]] || badexit "Failed to attach volume"

	# Give everything a chance to come up
	echo "Instance booted"
	sleep 20
	
	echo "Running dd"
	
	# Note the braindead device file name, looks like exactly what we chose :(
	dd if=$imagename/$imagename | ssh -o "StrictHostKeyChecking no" -i ~/.ssh/buildbot.key centos@$ip sudo dd of=/dev/vdc
	
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

builddate=`date +%Y%m%d`
imagename=$os-ccr-$builddate-$rev
ebsimagename=$os-ebs-ccr-$builddate-$rev
fulllog=$imagename.log

zone=ccr-cbls-2a

touch $fulllog

# Build the qemu image
# May take a long time, 5-10 minutes
# Can connect to the build with: vncviewer -Shared localhost:<port>

echo "Building packer image: $imagename" | tee -a $fulllog

sed -e "s/CHANGE_NAME/$imagename/g" packer.json > packer-$builddate.json
packer build packer-$builddate.json >> $fulllog || badexit "Can't build: $imagename"

# Convert for Euca
echo "Running virt-sysprep" | tee -a $fulllog
virt-sysprep -a $imagename/$imagename >> $fulllog || badexit "Can't virt-sysprep $imagename"

# Do the rest for both regions

#regions='buildbot@ccr-cbls-2 buildbot-ccr@ccr-cbls-1'
regions='buildbot-ccr@ccr-cbls-1'

for region in $regions; do

	echo "Adding to region: $region"

	fulllog="$imagename.$region.log"
	touch $fulllog

	# Install Instance store Image
	echo "euca-install-image for: $imagename" | tee -a $fulllog
	euca-install-image --region $region -i $imagename/$imagename --description $os --virtualization-type hvm -b $imagename -r x86_64 --name $imagename >> $fulllog || badexit "euca-install-image failed"
	
	emi=`grep ^IMAGE $fulllog |cut -f 2`
	
	# Make public
	echo "Making $emi public" | tee -a $fulllog
	euca-modify-image-attribute --region $region -l -a all $emi >> $fulllog || badexit "Can't make $emi public"

	if [[ $region =~ "ccr-cbls-1" ]]; then

		echo "Running our own EBS import for $ebsimagename"

		myebs
		
	else
	
		# Submit a task to create an EBS volume
		echo "Making EBS task for $ebsimagename" | tee -a $fulllog
		euca-import-volume $imagename/$imagename --region $region --format raw  --bucket $ebsimagename --prefix $ebsimagename -z $zone >> $fulllog || badexit "Can't start EBS task"
		
		importvol=`grep IMPORTVOLUME $fulllog | cut -f 4`
		
		while true ; do
			echo "Waiting for EBS task to finish..." | tee -a $fulllog
			euca-describe-conversion-tasks --region $region $importvol |grep completed && break
			sleep 10
		done
		
		volid=`euca-describe-conversion-tasks --region $region $importvol |grep VolumeId |cut -f 7`
	fi
	
	# Create the snapshot from the volume
	echo "Make snapshot for $volid" | tee -a $fulllog
	euca-create-snapshot --region $region $volid >> $fulllog || badexit "Can't make snapshot for $volid"
	
	importsnap=`grep SNAPSHOT $fulllog |cut -f 2`
	
	while true ; do
		echo "Waiting for Snapshot $importsnap task to finish..." | tee -a $fulllog
		euca-describe-snapshots --region $region $importsnap | grep completed && break
		sleep 10
	done
	
	
	# Register the EBS image
	euca-register --region $region --name $ebsimagename --description "$os-ebs" --snapshot $importsnap -a x86_64 >> $fulllog || badexit "Can't register EBS: $ebsimagename from $importsnap"
	
	ebsemi=`grep ^IMAGE $fulllog | tail -1 | cut -f 2`
	
	# Make public
	echo "Making EBS $ebsemi public" | tee -a $fulllog
	euca-modify-image-attribute --region $region -l -a all $ebsemi >> $fulllog || badexit "Can't make EBS image public"

done

# Make a backup
echo "Copying to /srv/cosmos/euca/images"
cp -r $imagename /srv/cosmos/euca/images/$os
touch /srv/cosmos/euca/images/$os/$imagename/info.txt
# Need to fix this for regions.  Create one file per region above and then copy here
echo "emi=$emi" >> /srv/cosmos/euca/images/$os/$imagename/info.txt
echo "ebsemi=$ebsemi" >> /srv/cosmos/euca/images/$os/$imagename/info.txt
echo "vol=$volid" >> /srv/cosmos/euca/images/$os/$imagename/info.txt
echo "snap=$importsnap" >> /srv/cosmos/euca/images/$os/$imagename/info.txt
