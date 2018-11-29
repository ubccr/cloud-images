#!/bin/bash

# Usage: sudo ./secure-pcp.sh
#
# NOTE: CCR-PCP-CA.crt must be in the local directory
#

function badexit
{
    echo "$1" 1>&2
    exit 1
}

# Set if we want to add signed cert/key for client access
mycert=$1
mykey=$2

HOSTNAME=`/bin/hostname`

IP=`/bin/hostname -i`

LOCAL_CA_CN="PCP $HOSTNAME LOCAL CA"
LOCAL_CA_NICK="PCP $HOSTNAME CA CERT"

LOCAL_CERT_CN="PCP $HOSTNAME Collector"

LOCAL_CERT_NICK="PCP_${HOSTNAME}_Collector_certificate"

PCP_CERT_DIR="/etc/pcp/nssdb"

#echo $LOCAL_CA_CN
#echo $LOCAL_CA_NICK
#echo $LOCAL_CERT_NICK
#echo $PCP_CERT_DIR

if [ ! -d $PCP_CERT_DIR ]; then
    badexit "$PCP_CERT_DIR doesn't exist."
fi

if [ "$(ls -A $PCP_CERT_DIR)"  ]; then
    badexit "$PCP_CERT_DIR already contains files. Delete them if you'd like to recreate the certs."
fi

# Create an empty cert database
test -f /tmp/empty || echo > /tmp/empty
certutil -d sql:$PCP_CERT_DIR -N -f /tmp/empty || badexit "Can't initialize cert db at: $PCP_CERT_DIR"

# Add the CCR cert
certutil -d sql:$PCP_CERT_DIR -A -t "CT,," -n "CCR PCP CA" -i ./CCR-PCP-CA.crt || badexit "Can't add CCR-PCP-CA.crt, is it in this directory?"

# Create a local CA for the PMCD cert
# Use a file expected to exist for the noise
certutil -d sql:$PCP_CERT_DIR -S -x -n "$LOCAL_CA_NICK" -s "cn=$LOCAL_CA_CN" -t "CT,," -v 120 -z /etc/passwd || badexit "Can't create local CA: $LOCAL_CA_NICK" 

# Ugly. Something in certutil is tied to the timestamp.  SEC_ERROR_REUSED_ISSUER_AND_SERIAL errors without sleep. Need to wait between certutil calls
sleep 2

# Cert for pmcd
#
# Don't add the IP/hostname attributes for cloud since they will change
#
# certutil -d sql:$PCP_CERT_DIR -S -c "$LOCAL_CA_NICK" -n "$LOCAL_CERT_NICK" -s "cn=$LOCAL_CERT_CN" -t "P,," -v 120 -z /etc/passwd -8 "$HOSTNAME" --extSAN ip:$IP || badexit "Can't create $LOCAL_CERT_NICK"
#
certutil -d sql:$PCP_CERT_DIR -S -c "$LOCAL_CA_NICK" -n "$LOCAL_CERT_NICK" -s "cn=$LOCAL_CERT_CN" -t "P,," -v 120 -z /etc/passwd || badexit "Can't create $LOCAL_CERT_NICK"

# Signed cert for client
if [ ! -z $mycert ]; then
	echo "Adding cert: '$mycert'"
	certutil -d sql:$PCP_CERT_DIR -A -t "P,," -n "$mycert" -i $mycert || badexit "Can't add signed cert $mycert"
fi

# Signed key for client
if [ ! -z $mykey ]; then
	echo "Adding key: '$mykey'"
	pk12util -i $mykey -d sql:$PCP_CERT_DIR || badexit "Can't add signed key $mykey"
fi

# Fixup permissions
chown -R pcp.pcp $PCP_CERT_DIR || badexit "Can't chown pcp cert dir"


# PCP environment setup

# PMCD
grep -q "^-C sql:$PCP_CERT_DIR" /etc/pcp/pmcd/pmcd.options || echo "-C sql:$PCP_CERT_DIR" >> /etc/pcp/pmcd/pmcd.options || badexit "Can't add -C option for pmcd"
grep -q "^-M" /etc/pcp/pmcd/pmcd.options || echo "-M $LOCAL_CERT_NICK" >> /etc/pcp/pmcd/pmcd.options || badexit "Can't add -M option for pmcd"
grep -q "^-Q" /etc/pcp/pmcd/pmcd.options || echo "-Q" >> /etc/pcp/pmcd/pmcd.options || badexit "Can't add -Q option for pmcd"

# PMPROXY
grep -q "^-C sql:$PCP_CERT_DIR" /etc/pcp/pmproxy/pmproxy.options || echo "-C sql:$PCP_CERT_DIR" >> /etc/pcp/pmproxy/pmproxy.options || badexit "Can't add -C option for pmproxy"

# CLIENT TOOLS (including pmproxy)
grep -q "^PCP_ALLOW_SERVER_SELF_CERT" /etc/pcp.conf || echo "PCP_ALLOW_SERVER_SELF_CERT=1" >> /etc/pcp.conf || badexit "Can't add PCP_ALLOW_SERVER_SELF_CERT"
grep -q "^PCP_ALLOW_BAD_CERT_DOMAIN" /etc/pcp.conf || echo "PCP_ALLOW_BAD_CERT_DOMAIN=1" >> /etc/pcp.conf || badexit "Can't add PCP_ALLOW_BAD_CERT_DOMAIN"
