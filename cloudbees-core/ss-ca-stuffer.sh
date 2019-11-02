#!/usr/bin/env bash

## This script pulls in SSL Certificates and spits em into the certificate store for Java

set -e
## set -x	## Uncomment for debugging

for CERT in "$@"
do
  echo "Pulling SSL certificate for ${CERT}..."
  FILENAME=${CERT//":"/".p"}
  CERTNAME=${FILENAME//"."/"-"}
  echo "Q" | openssl s_client -connect ${CERT} 2>/dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > /tmp/$FILENAME.pem
  keytool -import -noprompt -storepass changeit -file /tmp/$FILENAME.pem -alias $CERTNAME -keystore $JAVA_HOME/jre/lib/security/cacerts
done