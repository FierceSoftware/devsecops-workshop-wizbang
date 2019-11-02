#!/usr/bin/env bash

## This script pulls in SSL Certificates and spits em into the certificate store for Java

set -e
## set -x	## Uncomment for debugging

## check for custom keystore
CUSTOM_TRUSTSTORE=$JENKINS_HOME/.cacerts
if [ ! -f "$CUSTOM_TRUSTSTORE/cacerts" ]; then
    mkdir -p $CUSTOM_TRUSTSTORE
    cp $JAVA_HOME/jre/lib/security/cacerts $CUSTOM_TRUSTSTORE
fi
chmod +w $CUSTOM_TRUSTSTORE/cacerts

for CERT in "$@"
do
  echo "Pulling SSL certificate for ${CERT}..."
  FILENAME=${CERT//":"/".p"}
  CERTNAME=${FILENAME//"."/"-"}
  #echo "Q" | openssl s_client -connect ${CERT} 2>/dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > /tmp/$FILENAME.pem
  keytool -printcert -rfc -sslServer ${CERT} > /tmp/$FILENAME.pem
  echp "Importing certificate to keystore..."
  keytool -list -storepass changeit -keystore $CUSTOM_TRUSTSTORE/cacerts -alias $CERTNAME
  if [ $? -eq 0 ]; then
    echo "Certificate already exists, skipping..."
  else
    echo "Certificate not in keystore, importing..."
    keytool -import -noprompt -storepass changeit -file /tmp/$FILENAME.pem -alias $CERTNAME -keystore $CUSTOM_TRUSTSTORE/cacerts 2>/dev/null
  fi
done

chmod -w $CUSTOM_TRUSTSTORE/cacerts