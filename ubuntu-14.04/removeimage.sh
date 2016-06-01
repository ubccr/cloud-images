#!/bin/bash

image=$1

if [ -z $image ]; then
	echo "Need an image name"
	exit 1;
fi

emi=`euca-describe-images |grep $image |cut -f 2`

echo "Removing $emi"

euca-deregister $emi

euca-delete-bundle -b $image -p $image

# This second one may fail, but is sometimes necessary
euca-deregister $emi
