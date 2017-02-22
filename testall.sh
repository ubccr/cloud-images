#!/bin/bash

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

images=`euca-describe-images |grep -v -i windows | grep -v -i coreos | grep $build |cut -f 3 | cut -d/ -f2 |cut -d. -f1`

touch $build-test.out

for image in $images
do
	./testimage.sh $image >> $build-test.out 2>&1
	if [ "$?" -eq "0" ]; then
		echo "GOOD $image"
	else
		echo "BAD $image"
	fi
done
