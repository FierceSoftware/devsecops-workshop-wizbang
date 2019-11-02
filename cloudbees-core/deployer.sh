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
export OCP_CJOC_ROUTE_EDGE_TLS=${OCP_CJOC_ROUTE_EDGE_TLS:="true"}
export OC_ARG_OPTIONS=${OC_ARG_OPTIONS:=""}

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
    curl -L -sS -o "$CBC_OCP_WORK_DIR/jenkins-cli.jar" "$JENKINS_PROTOCOL_PREFIX://$OCP_CJOC_ROUTE/cjoc/jnlpJars/jenkins-cli.jar"

    export JENKINS_USER_ID="admin"
    export JENKINS_API_TOKEN=$JENKINS_ADMIN_PASS
    export JENKINS_URL=$OCP_CJOC_ROUTE
    if [ "$OCP_CJOC_ROUTE_EDGE_TLS" = "true" ]; then
        export JENKINS_PROTOCOL_PREFIX="https"
    else
        export JENKINS_PROTOCOL_PREFIX="http"
    fi

    echo -e "\n================================================================================"
    echo "Testing jenkins-cli..."

    java -jar $CBC_OCP_WORK_DIR/jenkins-cli.jar -s "$JENKINS_PROTOCOL_PREFIX://$OCP_CJOC_ROUTE/cjoc/" who-am-i

    echo -e "\n================================================================================"
    echo "Pushing Plugin Catalog to CJOC..."

    curl -L -sS -o $CBC_OCP_WORK_DIR/dso-ocp-workshop-plugin-catalog.json https://raw.githubusercontent.com/FierceSoftware/devsecops-workshop-wizbang/master/cloudbees-core/dso-ocp-workshop-plugin-catalog.json

    java -jar $CBC_OCP_WORK_DIR/jenkins-cli.jar -s "$JENKINS_PROTOCOL_PREFIX://$OCP_CJOC_ROUTE/cjoc/" plugin-catalog --put < $CBC_OCP_WORK_DIR/dso-ocp-workshop-plugin-catalog.json

    echo -e "\n================================================================================"
    echo "Pushing Team Master Recipe to CJOC..."

    curl -L -sS -o $CBC_OCP_WORK_DIR/team-master-recipes.json https://raw.githubusercontent.com/FierceSoftware/devsecops-workshop-wizbang/master/cloudbees-core/team-master-recipes.json

    java -jar $CBC_OCP_WORK_DIR/jenkins-cli.jar -s "$JENKINS_PROTOCOL_PREFIX://$OCP_CJOC_ROUTE/cjoc/" team-creation-recipes --put < $CBC_OCP_WORK_DIR/team-master-recipes.json

    echo -e "\n================================================================================"
    echo "Creating Team..."

    curl -L -sS -o $CBC_OCP_WORK_DIR/workshop-team.fiercesw.network.json https://raw.githubusercontent.com/FierceSoftware/devsecops-workshop-wizbang/master/cloudbees-core/workshop-team.fiercesw.network.json

    java -jar $CBC_OCP_WORK_DIR/jenkins-cli.jar -s "$JENKINS_PROTOCOL_PREFIX://$OCP_CJOC_ROUTE/cjoc/" teams workshop-team --put < $CBC_OCP_WORK_DIR/workshop-team.fiercesw.network.json

    echo -e "\n================================================================================"
    echo "Safely restarting CJOC..."
    
    java -jar $CBC_OCP_WORK_DIR/jenkins-cli.jar -s "$JENKINS_PROTOCOL_PREFIX://$OCP_CJOC_ROUTE/cjoc/" safe-restart


    echo -e "\n\n================================================================================"
    echo -e "Finished with deploying Cloudbees Core!\n Now feel free to finish configuring LDAP/RBAC"

    echo -e "\n\n================================================================================"
    read -p "Clean up and delete tmp directory? [N/y] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        rm -rf $CBC_OCP_WORK_DIR
    fi
}

## Integrate LDAP to CJOC

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

	read -rp "Secure TLS Edge for CJOC Route? ($OCP_CJOC_ROUTE_EDGE_TLS): " choice;
	if [ "$choice" != "" ] ; then
		export OCP_CJOC_ROUTE_EDGE_TLS="$choice";
	fi

fi

echo -e "\n "

echo -e "\n================================================================================"
echo "Log in to OpenShift..."
oc $OC_ARG_OPTIONS login $OCP_HOST -u $OCP_USERNAME -p $OCP_PASSWORD

echo -e "\n================================================================================"
echo "Create and Set Project..."
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

if [ "$OCP_CJOC_ROUTE_EDGE_TLS" = "true" ]; then
    cd $CBC_OCP_WORK_DIR && tar zxvf cjoc.tgz && cd cloudbees-core_* && \
    sed -e s,http://cloudbees-core,https://cloudbees-core,g < cloudbees-core.yml > tmp && mv tmp cloudbees-core-working.yml && \
    sed -e s,cloudbees-core.example.com,$OCP_CJOC_ROUTE,g < cloudbees-core-working.yml > tmp && mv tmp cloudbees-core-working.yml && \
    sed -e s,myproject,$OCP_PROJECT_NAME,g < cloudbees-core-working.yml > tmp && mv tmp cloudbees-core-working.yml && \
    sed -e 's/host:  \"$OCP_CJOC_ROUTE\"/host:  \"$OCP_CJOC_ROUTE\"'"\n"'  tls:'"\n"'    termination: edge'"\n"'    insecureEdgeTerminationPolicy: Redirect/g' < cloudbees-core-working.yml > tmp && mv tmp cloudbees-core-working.yml
else
    cd $CBC_OCP_WORK_DIR && tar zxvf cjoc.tgz && cd cloudbees-core_* && \
    sed -e s,http://cloudbees-core,https://cloudbees-core,g < cloudbees-core.yml > tmp && mv tmp cloudbees-core-working.yml && \
    sed -e s,cloudbees-core.example.com,$OCP_CJOC_ROUTE,g < cloudbees-core-working.yml > tmp && mv tmp cloudbees-core-working.yml && \
    sed -e s,myproject,$OCP_PROJECT_NAME,g < cloudbees-core-working.yml > tmp && mv tmp cloudbees-core-working.yml
fi

echo -e "\n================================================================================"
echo -e "Deploying Jenkins Agent ConfigMaps and ImageStreams...\n"

echo "Applying Jenkins Agent - Maven..."
oc $OC_ARG_OPTIONS create -f https://raw.githubusercontent.com/kenmoini/jenkins-agent-maven-rhel7/master/jenkins-agent-maven-rhel7.yaml

echo "Applying Jenkins Agent - Ansible..."
oc $OC_ARG_OPTIONS create -f https://raw.githubusercontent.com/kenmoini/jenkins-agent-ansible/master/openshift-build-configmap.yaml

echo "Applying JBoss EAP 7.0 ImageStream..."
oc $OC_ARG_OPTIONS create -f https://raw.githubusercontent.com/kenmoini/application-templates/master/eap/eap70-image-stream.json

echo -e "\n================================================================================"
echo -e "Deploying Cloudbees Core...\n"
oc $OC_ARG_OPTIONS apply -f cloudbees-core-working.yml

echo -e "\n================================================================================"
echo "Adding admin role to jenkins & cjoc service accounts..."
oc $OC_ARG_OPTIONS policy add-role-to-user admin system:serviceaccount:$OCP_PROJECT_NAME:jenkins
oc $OC_ARG_OPTIONS policy add-role-to-user admin system:serviceaccount:$OCP_PROJECT_NAME:cjoc

echo -e "\n================================================================================"
echo "Sleeping for 120s while Cloudbees Core deploys..."
sleep 120

echo -e "\n================================================================================"
echo "Sending plugin stuffer to CJOC pod..."
oc $OC_ARG_OPTIONS exec cjoc-0 -- curl -L -sS -o /var/jenkins_home/cjoc-plugin-stuffer.sh https://raw.githubusercontent.com/FierceSoftware/devsecops-workshop-wizbang/master/cloudbees-core/cjoc-plugin-stuffer.sh
oc $OC_ARG_OPTIONS exec cjoc-0 -- chmod +x /var/jenkins_home/cjoc-plugin-stuffer.sh
oc $OC_ARG_OPTIONS exec cjoc-0 -- /var/jenkins_home/cjoc-plugin-stuffer.sh openshift-client workflow-scm-step workflow-api jsch durable-task workflow-job workflow-multibranch branch-api workflow-support pipeline-stage-step pipeline-input-step pipeline-graph-analysis pipeline-milestone-step pipeline-rest-api pipeline-build-step momentjs handlebars pipeline-stage-view workflow-durable-task-step pipeline-model-api pipeline-model-extensions pipeline-model-declarative-agent pipeline-stage-tags-metadata git-server git git-client workflow-cps-global-lib docker-workflow rocketchatnotifier lockable-resources workflow-basic-steps workflow-cps openshift-sync openshift-pipeline

echo -e "\n================================================================================"
echo "Read the default Admin password with:"
echo " oc $OC_ARG_OPTIONS exec cjoc-0 -- cat /var/jenkins_home/secrets/initialAdminPassword"
echo ""
JENKINS_ADMIN_PASS="$(oc $OC_ARG_OPTIONS exec cjoc-0 -- cat /var/jenkins_home/secrets/initialAdminPassword)"
echo "Attempting admin password read-out: $JENKINS_ADMIN_PASS"

if [ "$OCP_CJOC_ROUTE_EDGE_TLS" = "true" ]; then
    echo -e "\n If you get a password above, please log into your Admin user at https://$OCP_CJOC_ROUTE/cjoc/ and complete the Setup Wizard, then come back and finish the setup...I know, it is lame.\n\n Oh and when you get to the Create First Admin User screen just click Continue as admin - please.  Or otherwise modify this script with your intended password..."
else
    echo -e "\n If you get a password above, please log into your Admin user at http://$OCP_CJOC_ROUTE/cjoc/ and complete the Setup Wizard, then come back and finish the setup...I know, it is lame.\n\n Oh and when you get to the Create First Admin User screen just click Continue as admin - please.  Or otherwise modify this script with your intended password..."
fi

echo -e "\n After completing the Setup Wizard, you also need to set some additional manual configuration such as LDAP.  Read the Manual Steps section for those functions, then return here."

promptToContinueAfterCJOCDeploy