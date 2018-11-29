#!/bin/bash

rev=$1

if [ -z $rev ]; then
	echo "Rev required"
	exit 1;
fi

for os in centos6 centos7 ubuntu1404 ubuntu1604 ubuntu1804
#for os in ubuntu1404
do
	echo "Building $os"
	cd $os
	echo "../build_OS.sh $rev &> $os.build.out &"
	../build_OS.sh $rev &> $os.build.out &
	cd ..
done

wait

#echo "Building Foreman Image"
#cd centos7
#echo "EXTRA_NAME=FOREMAN BUILD_REGIONS='buildbot-ccr@ccr-cbls-1' PACKER_IMAGE_TYPE=local ../build.sh $rev &> centos7.FOREMAN.build.out"
#EXTRA_NAME=FOREMAN BUILD_REGIONS='buildbot-ccr@ccr-cbls-1' PACKER_IMAGE_TYPE=local ../build.sh $rev &> centos7.FOREMAN.build.out

#echo "Building Foreman Dev Image"
#echo "EXTRA_NAME=FOREMAN-dev BUILD_REGIONS='buildbot-dev@ccr-cbls-dev' PACKER_IMAGE_TYPE=local ../build.sh $rev &> centos7.FOREMAN-dev.build.out"
#EXTRA_NAME=FOREMAN-dev BUILD_REGIONS='buildbot-dev@ccr-cbls-dev' PACKER_IMAGE_TYPE=local ../build.sh $rev &> centos7.FOREMAN-dev.build.out
