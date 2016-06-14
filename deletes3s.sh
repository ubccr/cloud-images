#!/bin/bash

bucket=$1

if [ -z $bucket ]; then
	echo "Need to specify bucket"
	exit
fi

echo "Deleting files in bucket: $bucket"

./s3curl.pl --id euca -- -s "http://199.109.195.247:8773/services/objectstorage/$bucket?max-keys=10000" | ../student-projects/dtelford/xmlScripts/runBucket.py -p ListBucketResult/Contents/Key -c "./s3curl.pl --delete --id euca -- -s \"http://199.109.195.247:8773/services/objectstorage/$bucket/{}\""

echo "Deleting bucket: $bucket"

# Need to add max-keys, default truncates to 1000
./s3curl.pl --delete --id euca -- "http://199.109.195.247:8773/services/objectstorage/$bucket"
