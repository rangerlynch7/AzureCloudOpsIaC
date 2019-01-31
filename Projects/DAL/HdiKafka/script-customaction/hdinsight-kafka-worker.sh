#!/bin/bash
# Brian Cornally at ObjectSharp.com 20190123
# kafka cluster worker script
# function:
#  - copy jks artifacts from azure storage container 
#  - ambari update kafka-broker parameters & restart kafka broker service
#
# side-note: copyToLocal this script from storage 
# hadoop fs -copyToLocal /artifacts/hdinsight-kafka-worker.sh .

###############################################################
# parameter variables
###############################################################

function help_message {
	echo >&2 "Usage: $0 -a ARTIFACTS -p ClusterLoginPassword -u ClusterLoginUserName -k SSLKEYPASS -s SSLSTOREPASS";
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

CLUSTERNAME=$(xmllint --xpath  '//Management/Identity/IdentityComponent[@name="ClusterDnsName"]/text()' /etc/mdsd.d/mdsd.xml)
SSLDIR=/var/private/ssl
STARTWAIT=120

###############################################################
# helper functions
###############################################################

sudo python /opt/startup_scripts/wait_for_cluster_setup.py

################################################################################
# get java keystore files
################################################################################

#hdfs dfs -ls /artifacts/

CLUSTERNAMESUFFIX=$(hostname | awk -F\- '{print substr($2,2)}')

echo "* STEP1 - copy jks artifacts from azure storage container"
sudo mkdir -p $SSLDIR
for i in keystore truststore; do 
	DEST=$SSLDIR/server.$i.jks
	if [ -f $DEST ]; then sudo rm $DEST; fi 
	sudo hadoop fs -copyToLocal /artifacts/$CLUSTERNAMESUFFIX.server.$i.jks $SSLDIR/server.$i.jks
done
for i in $SSLDIR/*.jks; do 
	keytool -list -v -storepass "$SSLSTOREPASS" -keypass "$SSLKEYPASS" -noprompt -keystore $i
done

################################################################################
echo "* ambari kafka-broker config updates"
################################################################################

wget -O /tmp/HDInsightUtilities-v01.sh -q https://hdiconfigactions.blob.core.windows.net/linuxconfigactionmodulev01/HDInsightUtilities-v01.sh && source /tmp/HDInsightUtilities-v01.sh && rm -f /tmp/HDInsightUtilities-v01.sh

# choose head node where ambari is active
if curl -k --output /dev/null --silent --head --connect-timeout 1 -u $ClusterLoginUserName:$ClusterLoginPassword -G http://$(get_primary_headnode):8080/api/v1/clusters/$CLUSTERNAME; then 
	CLUSTERHEADNODE=$(get_primary_headnode)
elif curl -k --output /dev/null --silent --head --connect-timeout 1 -u $ClusterLoginUserName:$ClusterLoginPassword -G http://$(get_secondary_headnode):8080/api/v1/clusters/$CLUSTERNAME; then
	CLUSTERHEADNODE=$(get_secondary_headnode)
else
	echo "fail: ambari not active on CLUSTERHEADNODE $CLUSTERHEADNODE"
fi
echo "* CLUSTERHEADNODE=$CLUSTERHEADNODE"

################################################################################
echo "* append to /etc/hosts"
################################################################################
sudo apt -y install jq
export KAFKABROKERS=$(curl --silent --user $ClusterLoginUserName:$ClusterLoginPassword -G http://$CLUSTERHEADNODE:8080/api/v1/clusters/$CLUSTERNAME/services/HDFS/components/DATANODE | jq -r '.host_components[].HostRoles.host_name')
sed -i -e '/domain.com/{/@/!d;}' /etc/hosts
for i in $KAFKABROKERS; do ip=$(nslookup $i | awk '/Address/ {print $2}' | egrep -v "#53"); fqdn=$(echo $i | awk -F. '{print $1"."substr($1,6,11)".domain.com"}'); sudo echo $ip $fqdn >> /etc/hosts; done

# all # curl -u $ClusterLoginUserName:$ClusterLoginPassword -G http://$CLUSTERHEADNODE:8080/api/v1/clusters/$CLUSTERNAME | less
# curl -u $ClusterLoginUserName:$ClusterLoginPassword -G http://$CLUSTERHEADNODE:8080/api/v1/clusters/$CLUSTERNAME/services/KAFKA/components/KAFKA_BROKER

################################################################################
echo "* update ambari if wn0"
################################################################################
if [ $(echo $HOSTNAME | grep -c wn0) -eq 1 ]; then
echo 	
echo "* STEP2 run ambari kafka-broker updates on wn0 node"

function kafkaBrokerSet() {
CONFIG_KEY=$1
CONFIG_VALUE=$2
/var/lib/ambari-server/resources/scripts/configs.sh -u $ClusterLoginUserName -p $ClusterLoginPassword set $CLUSTERHEADNODE $CLUSTERNAME kafka-broker $CONFIG_KEY $CONFIG_VALUE | egrep -v "USERID|PASSWORD"
}

# for ambari restart
function kafkaRestart1() { 
SERVICE=KAFKA
echo "* stop SERVICE $SERVICE"
newURL=$(curl --silent --user $ClusterLoginUserName:$ClusterLoginPassword -i -H "X-Requested-By: ambari" -X PUT -d '{"RequestInfo": {"context": "Stop KAFKA"}, "ServiceInfo": {"state": "INSTALLED"}}' http://$CLUSTERHEADNODE:8080/api/v1/clusters/$CLUSTERNAME/services/$SERVICE | grep -o '"href" : [^, }]*' | sed 's/^.*: //' | tr -d '"')
echo $newURL
sleep 90
echo "* start SERVICE $SERVICE"
curl --silent --user $ClusterLoginUserName:$ClusterLoginPassword -i -H "X-Requested-By: ambari" -X PUT -d '{"RequestInfo": {"context": "Start KAFKA"}, "ServiceInfo": {"state": "STARTED"}}' http://$CLUSTERHEADNODE:8080/api/v1/clusters/$CLUSTERNAME/services/$SERVICE
}

function kafkaRestart2() { # for cli restart; does NOT work when invoked from ambari
SERVICE=KAFKA
POLLSLEEP=3
echo "* stop SERVICE $SERVICE"
newURL=$(curl --silent --user $ClusterLoginUserName:$ClusterLoginPassword -i -H "X-Requested-By: ambari" -X PUT -d '{"RequestInfo": {"context": "Stop KAFKA"}, "ServiceInfo": {"state": "INSTALLED"}}' http://$CLUSTERHEADNODE:8080/api/v1/clusters/$CLUSTERNAME/services/$SERVICE | grep -o '"href" : [^, }]*' | sed 's/^.*: //' | tr -d '"')
echo newURL=$newURL
curl --silent --user $ClusterLoginUserName:$ClusterLoginPassword -i -X GET "$newURL"; sleep 20
curl --silent --user $ClusterLoginUserName:$ClusterLoginPassword -i -X GET "$newURL"; sleep 20
curl --silent --user $ClusterLoginUserName:$ClusterLoginPassword -i -X GET "$newURL"; sleep 20
curl --silent --user $ClusterLoginUserName:$ClusterLoginPassword -i -X GET "$newURL"; sleep 20
curl --silent --user $ClusterLoginUserName:$ClusterLoginPassword -i -X GET "$newURL"; sleep 20
curl --silent --user $ClusterLoginUserName:$ClusterLoginPassword -i -X GET "$newURL"; sleep 20
curl --silent --user $ClusterLoginUserName:$ClusterLoginPassword -i -X GET "$newURL"; sleep 20
curl --silent --user $ClusterLoginUserName:$ClusterLoginPassword -i -X GET "$newURL"; sleep 20
curl --silent --user $ClusterLoginUserName:$ClusterLoginPassword -i -X GET "$newURL"; sleep 20
echo "* start SERVICE $SERVICE"
curl --silent --user $ClusterLoginUserName:$ClusterLoginPassword -i -H "X-Requested-By: ambari" -X PUT -d '{"RequestInfo": {"context": "Start KAFKA"}, "ServiceInfo": {"state": "STARTED"}}' http://$CLUSTERHEADNODE:8080/api/v1/clusters/$CLUSTERNAME/services/$SERVICE
}


echo "* set kafkaBroker config"
kafkaBrokerSet listeners "PLAINTEXT://localhost:9092,SSL://localhost:9093"
kafkaBrokerSet ssl.keystore.location $SSLDIR/server.keystore.jks
kafkaBrokerSet ssl.truststore.location $SSLDIR/server.truststore.jks
kafkaBrokerSet ssl.key.password $SSLKEYPASS
kafkaBrokerSet ssl.keystore.password $SSLSTOREPASS
kafkaBrokerSet ssl.truststore.password $SSLSTOREPASS

kafkaBrokerSet ssl.enabled.protocols TLSv1.2,TLSv1.1,TLSv1
kafkaBrokerSet ssl.keystore.type JKS
kafkaBrokerSet ssl.truststore.type JKS
kafkaBrokerSet ssl.secure.bns_random.implementation SHA1PRNG

cat << 'EOF' > PROPERTIESFILE
"properties" : {
"content" : "#!/bin/bash\n\n# Set KAFKA specific environment variables here.\n\n# The java implementation to use.\nexport JAVA_HOME={{java64_home}}\nexport PATH=$PATH:$JAVA_HOME/bin\nexport PID_DIR={{kafka_pid_dir}}\nexport LOG_DIR={{kafka_log_dir}}\nexport KAFKA_KERBEROS_PARAMS={{kafka_kerberos_params}}\nexport JMX_PORT=${JMX_PORT:-9999}\n\n# Add kafka sink to classpath and related depenencies\nif [ -e \"/usr/lib/ambari-metrics-kafka-sink/ambari-metrics-kafka-sink.jar\" ]; then\n export CLASSPATH=$CLASSPATH:/usr/lib/ambari-metrics-kafka-sink/ambari-metrics-kafka-sink.jar\n export CLASSPATH=$CLASSPATH:/usr/lib/ambari-metrics-kafka-sink/lib/*\nfi\nif [ -f /etc/kafka/conf/kafka-ranger-env.sh ]; then\n. /etc/kafka/conf/kafka-ranger-env.sh\nfi\n\nexport KAFKA_HEAP_OPTS=\"-Xmx2560m -Xms2560m\"\nexport KAFKA_JVM_PERFORMANCE_OPTS=\"-XX:MetaspaceSize=256m -XX:+UseG1GC -XX:MaxGCPauseMillis=20 -XX:InitiatingHeapOccupancyPercent=35 -XX:G1HeapRegionSize=16M -XX:MinMetaspaceFreeRatio=50 -XX:MaxMetaspaceFreeRatio=80\"\n\nFRIENDLYDOMAIN=\"domain.com\"\nLISTENER=$HOSTNAME.$(echo $HOSTNAME | awk -F- '{print substr($2,2)}').$FRIENDLYDOMAIN\nsed -i.bak -e '/advertised/{/advertised@/!d;}' /usr/hdp/current/kafka-broker/conf/server.properties\necho \"advertised.listeners=PLAINTEXT://$LISTENER:9092,SSL://$LISTENER:9093\" >> /usr/hdp/current/kafka-broker/conf/server.properties",
"is_supported_kafka_ranger" : "true",
"kafka_log_dir" : "/var/log/kafka",
"kafka_pid_dir" : "/var/run/kafka",
"kafka_user" : "kafka",
"kafka_user_nofile_limit" : "128000",
"kafka_user_nproc_limit" : "65536"
}

EOF
/var/lib/ambari-server/resources/scripts/configs.sh -u $ClusterLoginUserName -p $ClusterLoginPassword set $CLUSTERHEADNODE $CLUSTERNAME kafka-env PROPERTIESFILE

kafkaBrokerSet ssl.server.auth required
kafkaBrokerSet security.inter.broker.protocol SSL
kafkaBrokerSet ssl.endpoint.identification.algorithm HTTPS

kafkaRestart2

#echo -e "current kafka-env settings"
# /var/lib/ambari-server/resources/scripts/configs.sh -u $ClusterLoginUserName -p $ClusterLoginPassword get $CLUSTERHEADNODE $CLUSTERNAME kafka-env
# /var/lib/ambari-server/resources/scripts/configs.sh -u $ClusterLoginUserName -p $ClusterLoginPassword get $CLUSTERHEADNODE $CLUSTERNAME kafka-env $PROPERTIES # generate PROPERTIES current file from ambari

fi