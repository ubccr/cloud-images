#!/bin/bash

#Not a proper script just a list of commands to run

euca-run-instances -n 1 -g buildbot -k buildbot -t m2.2xlarge emi-6f50f14d

euca-create-volume -z ccr-cbls-2a -s 10

# The -d option is ignored, but required, perfect
euca-attach-volume vol-6ad25906 -i i-867c4531 -d /dev/sdq

# Fix remote sudo if neccesarry


# Note the braindead device file name, looks like exactly what we chose :(
dd if=output-qemu/ccr-centos7-20160603-1 | ssh -i ~/.ssh/buildbot.key centos@172.17.41.70 sudo dd of=/dev/vdc

euca-detach-volume vol-6ad25906

euca-create-snapshot vol-6ad25906

euca-register --name ebstest2 --snapshot snap-76e6b7c4 -a x86_64
