#!/bin/bash

sudo passwd --delete root
sudo passwd --lock root

sudo sed -i -e 's/.*PasswordAuthentication.*//g' -e 's/.*PermitRootLogin.*//g' -e 's/.*ChallengeResponseAuthentication.*//g' -e 's/.*UsePAM.*//g'  /etc/ssh/sshd_config

sudo sh -c '(echo "PasswordAuthentication no" >> /etc/ssh/sshd_config)'
sudo sh -c '(echo "PermitRootLogin no" >> /etc/ssh/sshd_config)'
sudo sh -c '(echo "ChallengeResponseAuthentication no" >> /etc/ssh/sshd_config)'
sudo sh -c '(echo "UsePAM no" >> /etc/ssh/sshd_config)'

sudo /bin/cp /tmp/deploy/cloud-config.yml /usr/share/oem
