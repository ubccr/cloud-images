#!/bin/sh

build=$1

if [ -z $build ]; then
	echo "Build required"
	exit 1;
fi

dash=`echo $build | grep -c -- -`

if [ $dash -ne 1 ]; then
	echo "Must have a dash in the name"
	exit
fi

images=`openstack image list -f value |grep -v -i windows | grep $build | awk '{print $2}'`

for image in $images
do
	echo "Deleting $image"
	openstack image delete $image
done
