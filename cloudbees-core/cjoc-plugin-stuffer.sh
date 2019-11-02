#!/usr/bin/env bash

## This script pulls in plugins for Jenkins manually and drops them into the plugins directory

set -e
## set -x	## Uncomment for debugging

echo ""
echo -e "Starting plugin downloads...\n"

for PLUGIN in "$@"
do
  echo "Pulling plugin file for ${PLUGIN}..."
  ## Rename to .jpi because that is what they do for system included plugins...yeah...whatever
  wget -O "$JENKINS_HOME/plugins/${PLUGIN}.jpi" "https://updates.jenkins.io/latest/${PLUGIN}.hpi"
done