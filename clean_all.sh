#!/bin/bash

/bin/rm -f *-test.out

for os in centos6 centos7 ubuntu1404 ubuntu1604 debian8 coreos
do
	echo "Cleaning $os"
	cd $os
	/bin/rm -rf $os-ccr*
	/bin/rm -rf ccr-$os-*
	/bin/rm -f $os.build.out
	/bin/rm -f $os.FOREMAN.build.out
	/bin/rm -f $os.FOREMAN-dev.build.out
	/bin/rm -f packer-*.json
	/bin/rm -rf output-qemu
	/bin/rm -rf CHANGE_NAME
	/bin/rm -f *.info
	cd ..
done

/bin/rm -rf coreos/packer_cache/
