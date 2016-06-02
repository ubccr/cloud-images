#!/bin/bash

apt-get update

apt-get -y install cloud-init traceroute apt-file

apt-get -y upgrade

apt-file update

cat /etc/cloud/cloud.cfg
