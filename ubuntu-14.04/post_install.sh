#!/bin/bash
echo password | sudo -S curl -o /etc/rc.local https://raw.githubusercontent.com/viglesiasce/cloud-images/master/utils/rc.local
echo password | sudo -S chmod +x /etc/rc.local


echo password | sudo -S add-apt-repository -y ppa:adiscon/v8-stable


echo password | sudo -S  apt-get update
sudo apt-get install -y rsyslog

sudo apt-get install -y ganglia-monitor



# the host value is the private IP of the central ganlia server IP
sudo sed -i '/mcast_join = 239.2.11.71/i \ host = 192.168.19.87' /etc/ganglia/gmond.conf
sudo sed -i 's/name = "unspecified"/#name = "euca cluster"/g' /etc/ganglia/gmond.conf
sudo sed -i 's/mcast_join = 239.2.11.71/ #mcast_join = 239.2.11.71/g' /etc/ganglia/gmond.conf
sudo sed -i 's/bind = 239.2.11.71/#bind = 239.2.11.71/g' /etc/ganglia/gmond.conf

sudo sed -i 's/port = 8649/#port = 8649/g' /etc/ganglia/gmond.conf

sudo sed -i 's/bind = 239.2.11.71/#bind = 239.2.11.71/g' /etc/ganglia/gmond.conf

sudo service ganglia-monitor restart



# Install rsyslog
# Again assuming that the IP here is the private cloud IP of the Central Rsyslog server
sudo sed -i "$ a *.* @192.168.19.87:514" /etc/rsyslog.conf



echo "passwd -l vagrant" > /tmp/shutdown
echo "rm /tmp/shutdown" >> /tmp/shutdown
echo "shutdown -P now" >> /tmp/shutdown
