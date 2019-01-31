#!/bin/bash
# Brian Cornally at ObjectSharp.com 20190123
# kafka zookeeper node

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

