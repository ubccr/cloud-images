#!/bin/bash

# Not a real script yet, just keep track of the commands

# Build the qemu image
# May take a long time, 5-10 minutes
# Can connect to the build with: vncviewer -Shared localhost:<port>
packer build centos-packer.json

# Convert for Euca
virt-sysprep -a output-qemu/centos-7-base 

# Install Instance store Image
euca-install-image --region minnus2@ccr-cbls-2 -i output-qemu/centos-7-base --virtualization-type hvm -b centos -r x86_64 --name PackerTest_3_Centos7

# Make public
euca-modify-image-attribute --region minnus2@ccr-cbls-2 -l -a all emi-4f006ddf

# Submit a task to create an EBS volume
euca-import-volume output-qemu/centos-7-base  --region minnus2@ccr-cbls-2 --format raw  --bucket ebscentos7bucket --prefix centos7_packer_ebs -z ccr-cbls-2a

# Create the snapshot from the volume
euca-create-snapshot --region minnus2@ccr-cbls-2 vol-38a3162e

# Register the EBS image
euca-register --region minnus2@ccr-cbls-2  --name packer-centos7-ebs --snapshot snap-c584bda2 -a x86_64

# Make public
euca-modify-image-attribute --region minnus2@ccr-cbls-2 -l -a all emi-6018d46b
