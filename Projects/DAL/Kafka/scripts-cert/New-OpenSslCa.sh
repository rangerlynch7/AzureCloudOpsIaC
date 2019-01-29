# Setup CA
# create CA => result: file ca-cert and the priv.key ca-key  

cd $SSLDIR
if [ ! -e $CACERTFILE ]; then 
	openssl req -new -newkey rsa:4096 -days 365 -x509 -subj $OPENSSLCASUBJECT -keyout $CACERTFILE.key -out $CACERTFILE -nodes
	echo $CACERTFILE created
else 
	echo $CACERTFILE already created
fi

# cat ca-cert
# cat ca-key
# keytool -printcert -v -file ca-cert