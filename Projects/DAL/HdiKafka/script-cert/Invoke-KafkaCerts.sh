#!/usr/bin/env bash
# Custom

# source Set-Vars.sh
COMPANYNAME=sal.az.tygoelelat.com
BASEDIR=$HOME/OneDrive/os-rg-kafka/AzureCloudOpsIaC/Projects/DAL/HdiKafka/script-cert # BASEDIR=`pwd`

# General
BASEDOMAIN=$COMPANYNAME.com
CACERTFILE=$BASEDIR/ca/opensslca.cer
CADIR=$BASEDIR/ca
CLIENT=kafka
CLIPASS=clientpass
KEYTOOLDNAME="CN=$SUBDOMAIN,O=$COMPANYNAME,OU=Cloud,L=Toronto,ST=Ontario,C=CA" # kafka does not support wildcard in CN
printf "subjectAltName = @alt_names\n[alt_names]\nDNS.1=*.$SUBDOMAIN" > $OPENSSLEXTFILE # kafka supports wildcard in SAN only
cat $OPENSSLEXTFILE; echo
LC_ALL=C
OPENSSLCASUBJECT="/C=CA/ST=Ontario/L=Toronto/OU=Cloud/O=$COMPANYNAME/CN=$COMPANYNAME"
OPENSSLEXTFILE=$BASEDIR/ca/opensslext.txt
CertSrvPass=serversecret
SSLDIR=$BASEDIR/ssl
STORAGECONTAINER=artifacts
VALIDITY=365 # Cert validity, in days

if [ ! -d $BASEDIR/ssl ]; then mkdir $SSLDIR; echo created $SSLDIR; fi
if [ ! -d $BASEDIR/ca ]; then mkdir $CADIR; echo created $CADIR; fi

cd $SSLDIR
rm $CACERTFILE
source $BASEDIR/New-OpenSslCa.sh

TIERS=(l n p)
LOCATIONS=(cc ce)
TIER=l
LOCATION=cc

# create certs

# for TIER in ${TIERS[@]}; do
# 	for LOCATION in ${LOCATIONS[@]}; do
		SUBDOMAIN=$LOCATION$TIER.$COMPANYNAME
 		source $BASEDIR/New-KafkaServerJks.sh
# 	done
# done
source $BASEDIR/New-KafkaClientJks.sh
cd $BASEDIR