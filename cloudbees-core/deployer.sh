#!/bin/bash

## Default variables to use
export CBC_OCP_WORK_DIR="/tmp/cbc-ocp"
export INTERACTIVE=${INTERACTIVE:="true"}
export OCP_HOST=${OCP_HOST:=""}
export OCP_USERNAME=${OCP_USERNAME:=""}
export OCP_PASSWORD=${OCP_PASSWORD:=""}
export OCP_CREATE_PROJECT=${OCP_CREATE_PROJECT:="true"}
export OCP_PROJECT_NAME=${OCP_PROJECT_NAME:="cicd-pipeline"}
export OCP_CJOC_ROUTE=${OCP_CJOC_ROUTE:="cjoc.ocp.example.com"}
export OC_ARG_OPTIONS=${OC_ARG_OPTIONS=:=""}

## Functions
function promptToContinueAfterCJOCDeploy {
    echo -e "\n================================================================================"
    read -p "Have you completed the CloudBees Core Initial Setup Wizard? [N/y] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        continueWithCJOCConfig
    else
        promptToContinueAfterCJOCDeploy
    fi
}

function continueWithCJOCConfig {
    echo -e "\n================================================================================"
    echo "Downloading Jenkins CLI now from CJOC..."
    curl -L -sS -o "$CBC_OCP_WORK_DIR/jenkins-cli.jar" "$OCP_CJOC_ROUTE/cjoc/jnlpJars/jenkins-cli.jar"

    export JENKINS_USER_ID="admin"
    export JENKINS_API_TOKEN=$JENKINS_ADMIN_PASS
    export JENKINS_URL=$OCP_CJOC_ROUTE

    echo -e "\n================================================================================"
    echo "Testing jenkins-cli..."

    java -jar $CBC_OCP_WORK_DIR/jenkins-cli.jar -s "http://$OCP_CJOC_ROUTE/cjoc/" who-am-i

    echo -e "\n================================================================================"
    echo "Pushing Plugin Catalog to CJOC..."

    curl -L -sS -o $CBC_OCP_WORK_DIR/team-master-recipes.json https://raw.githubusercontent.com/FierceSoftware/devsecops-workshop-wizbang/master/cloudbees/dso-ocp-workshop-plugin-catalog.json

    java -jar $CBC_OCP_WORK_DIR/jenkins-cli.jar -s "http://$OCP_CJOC_ROUTE/cjoc/" plugin-catalog --put < $CBC_OCP_WORK_DIR/dso-ocp-workshop-plugin-catalog.json

    echo -e "\n================================================================================"
    echo "Pushing Team Master Recipe to CJOC..."

    curl -L -sS -o $CBC_OCP_WORK_DIR/team-master-recipes.json https://raw.githubusercontent.com/FierceSoftware/devsecops-workshop-wizbang/master/cloudbees/team-master-recipes.json

    java -jar $CBC_OCP_WORK_DIR/jenkins-cli.jar -s "http://$OCP_CJOC_ROUTE/cjoc/" team-creation-recipes --put < $CBC_OCP_WORK_DIR/team-master-recipes.json

    echo -e "\n================================================================================"
    echo "Creating Team..."

    curl -L -sS -o $CBC_OCP_WORK_DIR/workshop-team.fiercesw.network.json https://raw.githubusercontent.com/FierceSoftware/devsecops-workshop-wizbang/master/cloudbees/workshop-team.fiercesw.network.json

    java -jar $CBC_OCP_WORK_DIR/jenkins-cli.jar -s "http://$OCP_CJOC_ROUTE/cjoc/" teams workshop-team --put < $CBC_OCP_WORK_DIR/workshop-team.fiercesw.network.json

    echo -e "\n================================================================================"
    read -p "Clean up and delete tmp directory? [N/y] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        rm -rf $CBC_OCP_WORK_DIR
    fi
}

## Things to do...
##CHECK Download latest Cloudbees Core
##CHECK Unzip, copy example config, modify vars
##CHECK Deploy Agent ConfigMaps
##CHECK Deploy CloudBees Core to OCP
##CHECK Pull in Jenkins CLI
##CHECK? Download all needed plugins
## Import Plugin Catalog to CJOC
## Install plugins to CJOC
## Integrate LDAP to CJOC
## Setup Team Master



## Make the script interactive to set the variables
if [ "$INTERACTIVE" = "true" ]; then
    
    echo -e "\n================================================================================"
    echo -e "Starting interactive setup...\n"

	read -rp "OpenShift Cluster Host http(s)://ocp.example.com: ($OCP_HOST): " choice;
	if [ "$choice" != "" ] ; then
		export OCP_HOST="$choice";
	fi

	read -rp "OpenShift Username: ($OCP_USERNAME): " choice;
	if [ "$choice" != "" ] ; then
		export OCP_USERNAME="$choice";
	fi

	read -rsp "OpenShift Password: " choice;
	if [ "$choice" != "" ] ; then
		export OCP_PASSWORD="$choice";
	fi
	echo -e ""

	read -rp "Create OpenShift Project? (true/false) ($OCP_CREATE_PROJECT): " choice;
	if [ "$choice" != "" ] ; then
		export OCP_CREATE_PROJECT="$choice";
	fi

	read -rp "OpenShift Project Name ($OCP_PROJECT_NAME): " choice;
	if [ "$choice" != "" ] ; then
		export OCP_PROJECT_NAME="$choice";
	fi

	read -rp "Cloudbees Core CJOC Route ($OCP_CJOC_ROUTE): " choice;
	if [ "$choice" != "" ] ; then
		export OCP_CJOC_ROUTE="$choice";
	fi

fi

echo -e "\n "

## Log in
echo -e "\n================================================================================"
echo "Log in to OpenShift..."
oc $OC_ARG_OPTIONS login $OCP_HOST -u $OCP_USERNAME -p $OCP_PASSWORD

## Create and Use Project
echo -e "\n================================================================================"
echo "Create/Set Project..."
if [ "$OCP_CREATE_PROJECT" = "true" ]; then
    oc $OC_ARG_OPTIONS new-project $OCP_PROJECT_NAME --description="Central & Managed CI/CD Pipeline" --display-name="Central CI/CD"
    oc $OC_ARG_OPTIONS project $OCP_PROJECT_NAME
fi
if [ "$OCP_CREATE_PROJECT" = "false" ]; then
    oc $OC_ARG_OPTIONS project $OCP_PROJECT_NAME
fi

echo -e "\n================================================================================"
echo "Making temporary directory..."
mkdir -p $CBC_OCP_WORK_DIR

echo -e "\n================================================================================"
echo -e "Downloading Cloudbees Core directory listing...\n"
curl -L -sS -o $CBC_OCP_WORK_DIR/cjoc.txt https://downloads.cloudbees.com/cloudbees-core/cloud/latest/
MATCH_LINK=$(cat $CBC_OCP_WORK_DIR/cjoc.txt | grep -Eoi '<a [^>]+>' | grep 'openshift.tgz">' | sed -e 's/^<a href=["'"'"']//i' -e 's/["'"'"']$//i' | sed -e 's/\">//')

echo "Downloading the latest from https://downloads.cloudbees.com/cloudbees-core/cloud/latest/$MATCH_LINK..."
curl -L -sS -o "$CBC_OCP_WORK_DIR/cjoc.tgz" https://downloads.cloudbees.com/cloudbees-core/cloud/latest/$MATCH_LINK

echo -e "\n================================================================================"
echo -e "Setting Cloudbees Core YAML configuration...\n"
cd $CBC_OCP_WORK_DIR && tar zxvf cjoc.tgz && cd cloudbees-core_* && \
    sed -e s,http://cloudbees-core,https://cloudbees-core,g < cloudbees-core.yml > tmp && mv tmp cloudbees-core-working.yml && \
    sed -e s,cloudbees-core.example.com,$OCP_CJOC_ROUTE,g < cloudbees-core-working.yml > tmp && mv tmp cloudbees-core-working.yml && \
    sed -e s,myproject,$OCP_PROJECT_NAME,g < cloudbees-core-working.yml > tmp && mv tmp cloudbees-core-working.yml

echo -e "\n================================================================================"
echo -e "Deploying Jenkins Agent ConfigMaps and ImageStreams...\n"
echo "Applying Jenkins Agent - Maven..."
oc $OC_ARG_OPTIONS create -f https://raw.githubusercontent.com/kenmoini/jenkins-agent-maven-rhel7/master/jenkins-agent-maven-rhel7.yaml

echo "Applying Jenkins Agent - Ansible..."
oc $OC_ARG_OPTIONS create -f https://raw.githubusercontent.com/kenmoini/jenkins-agent-ansible/master/openshift-build-configmap.yaml

echo "Applying JBoss EAP 7.0 ImageStream..."
oc $OC_ARG_OPTIONS create -f https://raw.githubusercontent.com/kenmoini/application-templates/master/eap/eap70-image-stream.json

echo -e "\n================================================================================"
echo -e "Downloading plugins...\n"
echo "Downloading openshift-client..."
curl -L -sS -o "$CBC_OCP_WORK_DIR/plugin.openshift-client.hpi" https://updates.jenkins.io/latest/openshift-client.hpi
echo "Downloading pipeline-build-step..."
curl -L -sS -o "$CBC_OCP_WORK_DIR/plugin.pipeline-build-step.hpi" https://updates.jenkins.io/latest/pipeline-build-step.hpi
echo "Downloading pipeline-input-step..."
curl -L -sS -o "$CBC_OCP_WORK_DIR/plugin.pipeline-input-step.hpi" https://updates.jenkins.io/latest/pipeline-input-step.hpi
echo "Downloading pipeline-milestone-step..."
curl -L -sS -o "$CBC_OCP_WORK_DIR/plugin.pipeline-milestone-step.hpi" https://updates.jenkins.io/latest/pipeline-milestone-step.hpi
echo "Downloading pipeline-stage-step..."
curl -L -sS -o "$CBC_OCP_WORK_DIR/plugin.pipeline-stage-step.hpi" https://updates.jenkins.io/latest/pipeline-stage-step.hpi
echo "Downloading pipeline-graph-analysis..."
curl -L -sS -o "$CBC_OCP_WORK_DIR/plugin.pipeline-graph-analysis.hpi" https://updates.jenkins.io/latest/pipeline-graph-analysis.hpi
echo "Downloading pipeline-rest-api..."
curl -L -sS -o "$CBC_OCP_WORK_DIR/plugin.pipeline-rest-api.hpi" https://updates.jenkins.io/latest/pipeline-rest-api.hpi
echo "Downloading pipeline-stage-view..."
curl -L -sS -o "$CBC_OCP_WORK_DIR/plugin.pipeline-stage-view.hpi" https://updates.jenkins.io/latest/pipeline-stage-view.hpi
echo "Downloading pipeline-graph-analysis..."
curl -L -sS -o "$CBC_OCP_WORK_DIR/plugin.pipeline-graph-analysis.hpi" https://updates.jenkins.io/latest/pipeline-graph-analysis.hpi
echo "Downloading pipeline-model-definition..."
curl -L -sS -o "$CBC_OCP_WORK_DIR/plugin.pipeline-model-definition.hpi" https://updates.jenkins.io/latest/pipeline-model-definition.hpi
echo "Downloading git-server..."
curl -L -sS -o "$CBC_OCP_WORK_DIR/plugin.git-server.hpi" https://updates.jenkins.io/latest/git-server.hpi
echo "Downloading lockable-resources..."
curl -L -sS -o "$CBC_OCP_WORK_DIR/plugin.lockable-resources.hpi" https://updates.jenkins.io/latest/lockable-resources.hpi
echo "Downloading workflow-cps-global-lib..."
curl -L -sS -o "$CBC_OCP_WORK_DIR/plugin.workflow-cps-global-lib.hpi" https://updates.jenkins.io/latest/workflow-cps-global-lib.hpi
echo "Downloading workflow-aggrigator..."
curl -L -sS -o "$CBC_OCP_WORK_DIR/plugin.workflow-aggrigator.hpi" https://updates.jenkins.io/latest/workflow-aggrigator.hpi
echo "Downloading openshift-sync..."
curl -L -sS -o "$CBC_OCP_WORK_DIR/plugin.openshift-sync.hpi" https://updates.jenkins.io/latest/openshift-sync.hpi
echo "Downloading openshift-pipeline..."
curl -L -sS -o "$CBC_OCP_WORK_DIR/plugin.openshift-pipeline.hpi" https://updates.jenkins.io/latest/openshift-pipeline.hpi

echo -e "\n================================================================================"
echo -e "Deploying Cloudbees Core...\n"
oc $OC_ARG_OPTIONS apply -f cloudbees-core-working.yml

echo -e "\n================================================================================"
echo "Sleeping for 120s while Cloudbees Core deploys..."
sleep 120

echo -e "\n================================================================================"
echo "Adding admin role to jenkins service account..."
oc $OC_ARG_OPTIONS policy add-role-to-user admin system:serviceaccount:$OCP_PROJECT_NAME:jenkins

echo -e "\n================================================================================"
echo "Read the default Admin password with:"
echo " oc $OC_ARG_OPTIONS exec cjoc-0 -- cat /var/jenkins_home/secrets/initialAdminPassword"
echo ""
JENKINS_ADMIN_PASS="$(oc $OC_ARG_OPTIONS exec cjoc-0 -- cat /var/jenkins_home/secrets/initialAdminPassword)"
echo "Attempting admin password read-out: $JENKINS_ADMIN_PASS"
echo -e "\n If you get a password above, please log into your Admin user at $OCP_CJOC_ROUTE/cjoc/ and complete the Setup Wizard, then come back and finish the setup...I know, it is lame.\n\n Oh and when you get to the Create First Admin User screen just click Continue as admin - please.  Or otherwise modify this script with your intended password..."
echo -e "\n After completing the Setup Wizard, you also need to set some additional manual configuration such as LDAP.  Read the Manual Steps section for those functions, then return here."

promptToContinueAfterCJOCDeploy