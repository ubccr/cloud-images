#!/bin/bash

rev=$1

if [ -z $rev ]; then
	echo "Rev required"
	exit 1;
fi

for os in centos7 ubuntu1404
do
	echo "Building $os"
	cd $os
	../build.sh $rev | tee $os.build.out
	cd ..
done
