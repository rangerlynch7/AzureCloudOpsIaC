cd $SSLDIR
FILE=$CLIENT.client.keystore.jks; if [ -e $FILE ]; then rm $FILE; echo removed $FILE; fi
keytool -keystore $CLIENT.client.truststore.jks -alias CARoot -import -file $CACERTFILE -storepass $CLIPASS -keypass $CLIPASS -noprompt
keytool -list -v -keystore $CLIENT.client.truststore.jks -storepass $CLIPASS # validate