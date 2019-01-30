## create kafka server certificate
cd $SSLDIR

# remove jks exist files
FILE=$SUBDOMAIN.keystore.jks; if [ -e $FILE ]; then rm $FILE; echo removed $FILE; fi
FILE=$SUBDOMAIN.truststore.jks; if [ -e $FILE ]; then rm $FILE; echo removed $FILE; fi

keytool -genkey -keystore $SUBDOMAIN.keystore.jks -validity $VALIDITY -storepass $SRVPASS -keyalg RSA -keysize 2048 -storetype pkcs12 -dname $KEYTOOLDNAME
keytool -list -v -keystore $SUBDOMAIN.keystore.jks -storepass $SRVPASS # validate

## create a certification request file, to be signed by the CA
keytool -keystore $SUBDOMAIN.keystore.jks -certreq -file $SUBDOMAIN.csr -storepass $SRVPASS -keypass $SRVPASS

## sign the server certificate => output: file "cert-signed
# openssl x509 -req -CA $CACERTFILE -CAkey ca-key -in cert-file -out cert-signed -days 365 -CAcreateserial -passin pass:$SRVPASS # Simple Sign
openssl x509 -req -in $SUBDOMAIN.csr -out $SUBDOMAIN.crt -CA $CACERTFILE -CAkey $CACERTFILE.key -CAcreateserial -days $VALIDITY -passin "pass:$SRVPASS" -extfile $OPENSSLEXTFILE
openssl x509 -noout -text -in $SUBDOMAIN.crt | grep -B1 DNS # validation

## check certificates
### our local certificates
keytool -printcert -v -file $SUBDOMAIN.crt
keytool -list -v -keystore $SUBDOMAIN.keystore.jks -storepass $SRVPASS 

# Trust the CA by creating a truststore and importing the $CACERTFILE
keytool -keystore $SUBDOMAIN.truststore.jks -alias CARoot -import -file $CACERTFILE -storepass $SRVPASS -keypass $SRVPASS -noprompt

# Import CA and the signed server certificate into the keystore
keytool -keystore $SUBDOMAIN.keystore.jks -alias CARoot -import -file $CACERTFILE -storepass $SRVPASS -keypass $SRVPASS -noprompt
keytool -keystore $SUBDOMAIN.keystore.jks -import -file $SUBDOMAIN.crt -storepass $SRVPASS -keypass $SRVPASS -noprompt
 