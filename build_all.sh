#!/bin/bash

rev=$1

if [ -z $rev ]; then
	echo "Rev required"
	exit 1;
fi

for os in centos6 centos7 ubuntu1404 ubuntu1604 debian8
do
	echo "Building $os"
	cd $os
	echo "../build.sh $rev &> $os.build.out &"
	../build.sh $rev &> $os.build.out &
	cd ..
done

wait
