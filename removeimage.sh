#!/bin/bash

image=$1

if [ -z $image ]; then
	echo "Need an image name"
	exit 1;
fi

export S3CURLCREDS="ccrcbls2"
export url="199.109.195.247"

if [[ "$AWS_DEFAULT_REGION" =~ "ccr-cbls-1" ]]; then
	export S3CURLCREDS="ccrcbls1"
	export url="128.205.11.242"
fi

if [[ "$AWS_DEFAULT_REGION" =~ "ccr-cbls-dev" ]]; then
        export S3CURLCREDS="ccrcblsdev"
        export url="128.205.41.252"
fi

emi=`euca-describe-images |grep $image |cut -f 2`

echo "Removing $emi"

euca-deregister $emi

euca-delete-bundle -b $image -p $image

# This second one may fail, but is sometimes necessary
euca-deregister $emi

# Remove the empty bucket
./s3curl.pl --delete --id $S3CURLCREDS -- "http://$url:8773/services/objectstorage/$image"
