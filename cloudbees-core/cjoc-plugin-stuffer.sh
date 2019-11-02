#!/usr/bin/env bash

## This script pulls in plugins for Jenkins manually and drops them into the plugins directory

set -e
## set -x	## Uncomment for debugging

echo ""
echo -e "Starting plugin downloads...\n"

for PLUGIN in "$@"
do
  echo "Pulling plugin file for ${PLUGIN}..."
  wget -O "$JENKINS_HOME/plugins/${PLUGIN}.jpi" "https://updates.jenkins.io/latest/${PLUGIN}.hpi"
done