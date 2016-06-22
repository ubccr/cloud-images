#!/bin/bash

for os in centos6 centos7 ubuntu1404 ubuntu1604 debian8
do
	echo "Cleaning $os"
	cd $os
	echo "/bin/rm -rf ccr-$os*"
	echo "/bin/rm -f $os.build.out"
	echo "/bin/rm -f packer-*.json"
	cd ..
done

wait
