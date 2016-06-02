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

os=ubuntu1404

rev=1

builddate=`date +%Y%m%d`
imagename=ccr-$os-$builddate-$rev
ebsimagename=ccr-$os-ebs-$builddate-$rev
fulllog=$imagename.log

touch $fulllog

# Build the qemu image
# May take a long time, 5-10 minutes
# Can connect to the build with: vncviewer -Shared localhost:<port>

echo "Building packer image: $imagename" | tee -a $fulllog

sed -e "s/CHANGE_NAME/$imagename/" packer.json > packer-$builddate.json
packer build packer-$builddate.json >> $fulllog || badexit "Can't build: $imagename"

# Convert for Euca
echo "Running virt-sysprep" | tee -a $fulllog
virt-sysprep -a output-qemu/$imagename >> $fulllog || badexit "Can't virt-sysprep $imagename"

# Install Instance store Image
echo "euca-install-image for: $imagename" | tee -a $fulllog
euca-install-image -i output-qemu/$imagename --virtualization-type hvm -b $imagename -r x86_64 --name $imagename >> $fulllog || badexit "euca-install-image failed"

emi=`grep ^IMAGE $fulllog |cut -f 2`

# Make public
echo "Making $emi public" | tee -a $fulllog
euca-modify-image-attribute -l -a all $emi >> $fulllog || badexit "Can't make $emi public"

# Submit a task to create an EBS volume
echo "Making EBS task for $ebsimagename" | tee -a $fulllog
euca-import-volume output-qemu/$imagename --format raw  --bucket $ebsimagename --prefix $ebsimagename -z ccr-cbls-2a >> $fulllog || badexit "Can't start EBS task"

importvol=`grep IMPORTVOLUME $fulllog | cut -f 4`

while true ; do
	echo "Waiting for EBS task to finish..." | tee -a $fulllog
	euca-describe-conversion-tasks $importvol |grep completed && break
	sleep 10
done

volid=`euca-describe-conversion-tasks $importvol |grep VolumeId |cut -f 7`

# Create the snapshot from the volume
echo "Make snapshot for $volid" | tee -a $fulllog
euca-create-snapshot $volid >> $fulllog || badexit "Can't make snapshot for $volid"

importsnap=`grep SNAPSHOT $fulllog |cut -f 2`

while true ; do
	echo "Waiting for Snapshot $importsnap task to finish..." | tee -a $fulllog
	euca-describe-snapshots $importsnap | grep completed && break
	sleep 10
done


# Register the EBS image
euca-register --name $ebsimagename --snapshot $importsnap -a x86_64 >> $fulllog || badexit "Can't register EBS: $ebsimagename from $importsnap"

ebsemi=`grep ^IMAGE $fulllog | tail -1 | cut -f 2`

# Make public
echo "Making EBS $ebsemi public" | tee -a $fulllog
euca-modify-image-attribute -l -a all $ebsemi >> $fulllog || badexit "Can't make EBS image public"
