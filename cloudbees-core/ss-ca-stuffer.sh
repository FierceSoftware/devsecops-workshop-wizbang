#!/usr/bin/env bash

## This script pulls in SSL Certificates and spits em into the certificate store for Java

set -e
## set -x	## Uncomment for debugging

## check for custom keystore
CUSTOM_TRUSTSTORE=$JENKINS_HOME/.cacerts
if [ ! -f "$CUSTOM_TRUSTSTORE/cacerts" ]; then
    mkdir -p $CUSTOM_TRUSTSTORE
    cp $JAVA_HOME/jre/lib/security/cacerts $CUSTOM_TRUSTSTORE
    chmod +w $CUSTOM_TRUSTSTORE/cacerts
fi

for CERT in "$@"
do
  echo "Pulling SSL certificate for ${CERT}..."
  FILENAME=${CERT//":"/".p"}
  CERTNAME=${FILENAME//"."/"-"}
  #echo "Q" | openssl s_client -connect ${CERT} 2>/dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > /tmp/$FILENAME.pem
  keytool -printcert -rfc -sslServer ${CERT} > /tmp/$FILENAME.pem
  keytool -import -noprompt -storepass changeit -file /tmp/$FILENAME.pem -alias $CERTNAME -keystore $JAVA_HOME/jre/lib/security/cacerts
done

chmod -w $CUSTOM_TRUSTSTORE/cacerts