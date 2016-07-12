#!/bin/sh

build=$1

# Use: AWS_DEFAULT_REGION='buildbot-ccr@ccr-cbls-1'
#  for different region

if [ -z $build ]; then
	echo "Build required"
	exit 1;
fi

dash=`echo $build | grep -c -- -`

if [ $dash -ne 1 ]; then
	echo "Must have a dash in the name"
	exit
fi

images=`euca-describe-images |grep -v -i windows | grep $build |cut -f 3 | cut -d/ -f2 |cut -d. -f1`


for image in $images
do
	ebs=`echo $image | grep -c ebs`

	if [ $ebs -eq 1 ]; then
		echo "Removing ebs $image"
		./removeebs.sh $image
	else
		echo "Removing $image"
		./removeimage.sh $image
	fi
done
