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
fulllog=$imagename.log

touch $fulllog

# Build the qemu image
# May take a long time, 5-10 minutes
# Can connect to the build with: vncviewer -Shared localhost:<port>

echo "Building packer image: $imagename" | tee -a $fulllog

sed -e "s/CHANGE_NAME/$imagename/g" packer.json > packer-$builddate.json
packer build -var-file=../vars.json packer-$builddate.json >> $fulllog || badexit "Can't build: $imagename"

# Clean up for the cloud
if [[ "$imagename" =~ "coreos" ]]; then
	echo "Skipping virt-sysprep for coreos" | tee -a $fulllog
else
	echo "Running virt-sysprep" | tee -a $fulllog
	virt-sysprep -a $imagename/$imagename >> $fulllog || badexit "Can't virt-sysprep $imagename"
fi

source ../openrc

#openstack image create $imagename --file $imagename/$imagename --disk-format raw --container-format bare --public >> $fulllog || badexit "Can't upload $imagename"
openstack image create $imagename --file $imagename/$imagename --disk-format raw --container-format bare >> $fulllog || badexit "Can't upload $imagename"

image_uuid=`openstack image list -f value |grep -v -i windows | grep $imagename | awk '{print $1}'`
	
touch $imagename.info
echo "uuid=$image_uuid" >> $imagename.info

# Make a backup
echo "Copying to /srv/cosmos/openstack/images"
cp -r $imagename /srv/cosmos/openstack/images/$os
cp *.info /srv/cosmos/openstack/images/$os/$imagename/
