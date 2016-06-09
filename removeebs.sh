#!/bin/bash

image=$1

if [ -z $image ]; then
	echo "Need an image name"
	exit 1;
fi

emi=`euca-describe-images |grep $image |cut -f 2`
snap=`euca-describe-images  $emi| grep BLOCKDEVICEMAPPING |cut -f 4`
vol=`euca-describe-snapshots $snap |cut -f 3`


echo "Removing $emi"
euca-deregister $emi

echo "Removing $snap"
euca-delete-snapshot $snap

echo "Removing $vol"
euca-delete-volume $vol

echo "Deleting Bucket: $image"
./deletes3s.sh $image
