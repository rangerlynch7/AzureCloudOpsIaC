#!/bin/bash
# Brian Cornally at ObjectSharp.com 20190123
# head node setup

###############################################################
# parameter variables
###############################################################

function help_message {
	echo >&2 "Usage: $0 -a ARTIFACTS -t TIER -p ClusterLoginPassword -u ClusterLoginUserName -k SSLKEYPASS -s SSLSTOREPASS";
	echo >&2 "$@"; # debug
}

if [[ "$#" -eq 0 ]]; then
	echo arg count "$#"
	help_message
	exit 1
fi

# parse command-line options
while getopts a:p:u:k:s: o
do case "$o" in
	a) ARTIFACTS="$OPTARG";;
	p) ClusterLoginPassword="$OPTARG";;
	u) ClusterLoginUserName="$OPTARG";;
	k) SSLKEYPASS="$OPTARG";;
	s) SSLSTOREPASS="$OPTARG";;
	[?]) help_message
		exit 1;;
	esac
done
echo $0 -a $ARTIFACTS -p $ClusterLoginPassword -u $ClusterLoginUserName -k $SSLKEYPASS -s $SSLSTOREPASS # debug

###############################################################
# variables
###############################################################

ClusterNAME=$(xmllint --xpath  '//Management/Identity/IdentityComponent[@name="ClusterDnsName"]/text()' /etc/mdsd.d/mdsd.xml)
SSLDIR=/var/private/ssl

###############################################################
# helper functions
###############################################################

wget -O /tmp/HDInsightUtilities-v01.sh -q https://hdiconfigactions.blob.core.windows.net/linuxconfigactionmodulev01/HDInsightUtilities-v01.sh && source /tmp/HDInsightUtilities-v01.sh && rm -f /tmp/HDInsightUtilities-v01.sh
sudo python /opt/startup_scripts/wait_for_Cluster_setup.py

################################################################################
# get java keystore files
################################################################################

#hdfs dfs -ls /artifacts/

ClusterNAMESUFFIX=$(hostname | awk -F\- '{print substr($2,2)}')

echo "* STEP1 - copy jks artifacts from azure storage container"
sudo mkdir -p $SSLDIR
for i in keystore truststore; do 
	DEST=$SSLDIR/server.$i.jks
	if [ -f $DEST ]; then sudo rm $DEST; fi 
	sudo hadoop fs -copyToLocal /artifacts/$ClusterNAMESUFFIX.server.$i.jks $SSLDIR/server.$i.jks
done
for i in $SSLDIR/*.jks; do 
	keytool -list -v -storepass "$SSLSTOREPASS" -keypass "$SSLKEYPASS" -noprompt -keystore $i
done

