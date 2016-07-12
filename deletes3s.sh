#!/bin/bash

bucket=$1

if [ -z $bucket ]; then
	echo "Need to specify bucket"
	exit
fi

if [ -z "$S3CURLCREDS" ]; then
	echo "Need S3CURLCREDS"
	exit
fi

if [ -z "$url" ]; then
	echo "Need url"
	exit
fi

echo "Deleting files in bucket: $bucket"

./s3curl.pl --id $S3CURLCREDS -- -s "http://$url:8773/services/objectstorage/$bucket?max-keys=10000" | ../student-projects/dtelford/xmlScripts/runBucket.py -p ListBucketResult/Contents/Key -c "./s3curl.pl --delete --id $S3CURLCREDS -- -s \"http://$url:8773/services/objectstorage/$bucket/{}\""

echo "Deleting bucket: $bucket"

# Need to add max-keys, default truncates to 1000
./s3curl.pl --delete --id $S3CURLCREDS -- "http://$url:8773/services/objectstorage/$bucket"
