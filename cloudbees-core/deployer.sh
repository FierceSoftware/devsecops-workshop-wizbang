#!/bin/bash

## set -x	## Uncomment for debugging

## Include vars if the file exists
FILE=./vars.sh
if [ -f "$FILE" ]; then
    source ./vars.sh
fi

## Default variables to use
export DEPLOYER_ORIGIN_DIR="$(pwd)"
export CBC_OCP_WORK_DIR=${CBC_OCP_WORK_DIR:="/tmp/cbc-ocp"}
export INTERACTIVE=${INTERACTIVE:="true"}
export OCP_HOST=${OCP_HOST:=""}
## userpass or token
export OCP_AUTH_TYPE=${OCP_AUTH_TYPE:="userpass"}
export OCP_AUTH=${OCP_AUTH:=""}
export OCP_USERNAME=${OCP_USERNAME:=""}
export OCP_PASSWORD=${OCP_PASSWORD:=""}
export OCP_TOKEN=${OCP_TOKEN:=""}
export OCP_CREATE_PROJECT=${OCP_CREATE_PROJECT:="true"}
export OCP_PROJECT_NAME=${OCP_PROJECT_NAME:="central-cicd"}
export OCP_CJOC_ROUTE=${OCP_CJOC_ROUTE:="cjoc.ocp.example.com"}
export OCP_CJOC_ROUTE_EDGE_TLS=${OCP_CJOC_ROUTE_EDGE_TLS:="true"}
export OCP_CJOC_SKIP_SETUP=${OCP_CJOC_SKIP_SETUP:="true"}
export OC_ARG_OPTIONS=${OC_ARG_OPTIONS:=""}

export CJOC_CaC_SETUP_KUBERNETES_CLOUD=${CJOC_CaC_SETUP_KUBERNETES_CLOUD:="true"}
export CJOC_CaC_SETUP_LDAP_AUTHENTICATION=${CJOC_CaC_SETUP_LDAP_AUTHENTICATION:="false"}
export CJOC_CaC_SETUP_OPENSHIFT_PLUGINS=${CJOC_CaC_SETUP_OPENSHIFT_PLUGINS:="true"}
export CJOC_CaC_SETUP_ROCKETCHAT_PLUGIN=${CJOC_CaC_SETUP_ROCKETCHAT_PLUGIN:="false"}

export LDAP_DOMAIN_REALM=${LDAP_DOMAIN_REALM:="EXAMPLE.COM"}
export LDAP_SERVER_HOSTNAME=${LDAP_SERVER_HOSTNAME:="idm.example.com"}
export LDAP_SERVER_PROTOCOL=${LDAP_SERVER_PROTOCOL:="ldaps"}
export LDAP_SERVER_PORT=${LDAP_SERVER_PORT:="636"}
export LDAP_BIND_DN=${LDAP_BIND_DN:="cn=Directory Manager"}
export LDAP_BIND_PASSWORD=${LDAP_BIND_PASSWORD:=""}

export EXTRA_OC_SYNC_NAMESPACES_HERE=${EXTRA_OC_SYNC_NAMESPACES_HERE:=""}

export ROCKET_CHAT_EXTERNAL_FQDN=${ROCKET_CHAT_EXTERNAL_FQDN:="https://rocketchat.ocp.example.com"}
export ROCKET_CHAT_USER=${ROCKET_CHAT_USER:="rcjenkins"}
export ROCKET_CHAT_USER_PASSWORD=${ROCKET_CHAT_USER_PASSWORD:=""}
export ROCKET_CHAT_CHANNEL=${ROCKET_CHAT_CHANNEL:="#devsecops-workshop"}

export CJOC_MANIFEST_ALTERED="false"


## Functions
function checkForProgram() {
    command -v $1
    if [[ $? -eq 0 ]]; then
        printf '%-72s %-7s\n' $1 "PASSED!";
    else
        printf '%-72s %-7s\n' $1 "FAILED!";
        exit 1
    fi
}

function returnDC() {
    LDAP_DC=""
    for i in $(echo $1 | tr "." "\n")
    do
        LDAP_DC="${LDAP_DC},dc=$i"
    done
    echo ${LDAP_DC#?}
}

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

    export JENKINS_USER_ID=${JENKINS_USER_ID:="admin"}
    export JENKINS_API_TOKEN=$JENKINS_ADMIN_PASS
    export JENKINS_URL=$OCP_CJOC_ROUTE
    if [ "$OCP_CJOC_ROUTE_EDGE_TLS" = "true" ]; then
        export JENKINS_PROTOCOL_PREFIX="https"
    else
        export JENKINS_PROTOCOL_PREFIX="http"
    fi

    echo -e "\n================================================================================"
    echo -e "Sending plugin stuffer to CJOC pod..."
    oc $OC_ARG_OPTIONS exec cjoc-0 -- curl -L -sS -o /var/jenkins_home/cjoc-plugin-stuffer.sh https://raw.githubusercontent.com/FierceSoftware/devsecops-workshop-wizbang/master/cloudbees-core/cjoc-plugin-stuffer.sh
    oc $OC_ARG_OPTIONS exec cjoc-0 -- chmod +x /var/jenkins_home/cjoc-plugin-stuffer.sh
    oc $OC_ARG_OPTIONS exec cjoc-0 -- /var/jenkins_home/cjoc-plugin-stuffer.sh openshift-client workflow-scm-step workflow-step-api workflow-api jsch durable-task workflow-job workflow-multibranch branch-api workflow-support pipeline-stage-step pipeline-input-step pipeline-graph-analysis pipeline-milestone-step pipeline-rest-api pipeline-build-step momentjs handlebars pipeline-stage-view workflow-durable-task-step pipeline-model-api pipeline-model-extensions pipeline-model-definition pipeline-model-declarative-agent pipeline-stage-tags-metadata git-server git git-client workflow-cps-global-lib docker-workflow rocketchatnotifier lockable-resources workflow-basic-steps workflow-cps openshift-sync openshift-pipeline pipeline-utility-steps configuration-as-code

    echo -e "\n================================================================================"
    echo -e "Downloading Jenkins CLI now from CJOC..."
    curl -L -sS -o "$CBC_OCP_WORK_DIR/jenkins-cli.jar" "${JENKINS_PROTOCOL_PREFIX}://${OCP_CJOC_ROUTE}/cjoc/jnlpJars/jenkins-cli.jar"

    echo -e "\n================================================================================"
    echo -e "Testing jenkins-cli...\n"

    java -jar $CBC_OCP_WORK_DIR/jenkins-cli.jar -s "${JENKINS_PROTOCOL_PREFIX}://${OCP_CJOC_ROUTE}/cjoc/" who-am-i

    echo -e "\n================================================================================"
    echo -e "Safely restarting CJOC...for safe measure...\n"

    java -jar $CBC_OCP_WORK_DIR/jenkins-cli.jar -s "${JENKINS_PROTOCOL_PREFIX}://${OCP_CJOC_ROUTE}/cjoc/" safe-restart

    echo -e "\n================================================================================"
    echo "Sleeping for 120s while CJOC restarts...don't touch it yet..."
    sleep 120

    echo -e "\n================================================================================"
    echo -e "Pushing Plugin Catalog to CJOC...\n"

    curl -L -sS -o $CBC_OCP_WORK_DIR/dso-ocp-workshop-plugin-catalog.json https://raw.githubusercontent.com/FierceSoftware/devsecops-workshop-wizbang/master/cloudbees-core/dso-ocp-workshop-plugin-catalog.json

    java -jar $CBC_OCP_WORK_DIR/jenkins-cli.jar -s "${JENKINS_PROTOCOL_PREFIX}://${OCP_CJOC_ROUTE}/cjoc/" plugin-catalog --put < $CBC_OCP_WORK_DIR/dso-ocp-workshop-plugin-catalog.json

    echo -e "\n\n================================================================================"
    echo -e "Pushing Team Master Recipe to CJOC...\n"

    curl -L -sS -o $CBC_OCP_WORK_DIR/team-master-recipes.json https://raw.githubusercontent.com/FierceSoftware/devsecops-workshop-wizbang/master/cloudbees-core/team-master-recipes.json

    java -jar $CBC_OCP_WORK_DIR/jenkins-cli.jar -s "${JENKINS_PROTOCOL_PREFIX}://${OCP_CJOC_ROUTE}/cjoc/" team-creation-recipes --put < $CBC_OCP_WORK_DIR/team-master-recipes.json

    echo -e "\n\n================================================================================"
    echo -e "Safely restarting CJOC...\n"

    java -jar $CBC_OCP_WORK_DIR/jenkins-cli.jar -s "${JENKINS_PROTOCOL_PREFIX}://${OCP_CJOC_ROUTE}/cjoc/" safe-restart

    echo -e "\n================================================================================"
    echo "Sleeping for 120s while CJOC restarts...still don't touch it..."
    sleep 120

    if [ $CJOC_CaC_SETUP_KUBERNETES_CLOUD = "true" ]; then

        echo -e "\n================================================================================"
        echo -e "Setting configuration for Kubernetes plugin..."

        cp $DEPLOYER_ORIGIN_DIR/configuration-as-code/example.kubernetes.yaml $DEPLOYER_ORIGIN_DIR/configuration-as-code/working-kubernetes.yaml
        sed -i -e s,CJOC_NAMESPACE_HERE,$OCP_PROJECT_NAME,g $DEPLOYER_ORIGIN_DIR/configuration-as-code/working-kubernetes.yaml

        oc $OC_ARG_OPTIONS exec cjoc-0 -- mkdir -p /var/jenkins_home/jcasc_config/

        echo -e "\n================================================================================"
        echo -e "Creating ConfigMap for Kubernetes plugin...\n"

        oc $OC_ARG_OPTIONS create configmap jcasc-kubernetes-plugin --from-file=$DEPLOYER_ORIGIN_DIR/configuration-as-code/working-kubernetes.yaml -o yaml --dry-run > $DEPLOYER_ORIGIN_DIR/working-configmap-jcasc-kubernetes-plugin.yaml
        oc $OC_ARG_OPTIONS apply -f $DEPLOYER_ORIGIN_DIR/working-configmap-jcasc-kubernetes-plugin.yaml

        echo -e "\n================================================================================"
        echo -e "Setting Volume and VolumeMount for ConfigMap for Kubernetes plugin...\n"

        SUB_DATA="volumeMounts:\n        - name: jcasc-kubernetes-plugin\n          mountPath: /var/jenkins_home/jcasc_config/kubernetes-plugin.yaml\n          readOnly: true"

        sed -e "s,volumeMounts:,$SUB_DATA," < cloudbees-core-working.yml > tmp && mv tmp cloudbees-core-working.yml

        SUB_DATA="volumes:\n      - name: jcasc-kubernetes-plugin\n        configMap:\n          name: jcasc-kubernetes-plugin"

        sed -e "s,volumes:,$SUB_DATA," < cloudbees-core-working.yml > tmp && mv tmp cloudbees-core-working.yml
        
        CJOC_MANIFEST_ALTERED="true"
    fi


    if [ $CJOC_CaC_SETUP_OPENSHIFT_PLUGINS = "true" ]; then

        echo -e "\n================================================================================"
        echo -e "Setting configuration for Openshift Client and Sync plugins...\n"

        cp $DEPLOYER_ORIGIN_DIR/configuration-as-code/example.openshift.yaml $DEPLOYER_ORIGIN_DIR/configuration-as-code/working-openshift.yaml

        sed -i -e s,CJOC_NAMESPACE_HERE,$OCP_PROJECT_NAME,g $DEPLOYER_ORIGIN_DIR/configuration-as-code/working-openshift.yaml
        sed -i -e s,EXTRA_OC_SYNC_NAMESPACES_HERE,$EXTRA_OC_SYNC_NAMESPACES_HERE,g $DEPLOYER_ORIGIN_DIR/configuration-as-code/working-openshift.yaml

        oc $OC_ARG_OPTIONS exec cjoc-0 -- mkdir -p /var/jenkins_home/jcasc_config/

        echo -e "\n================================================================================"
        echo -e "Creating ConfigMap for Openshift Client and Sync plugins...\n"

        oc $OC_ARG_OPTIONS create configmap jcasc-openshift-plugin --from-file=$DEPLOYER_ORIGIN_DIR/configuration-as-code/working-openshift.yaml -o yaml --dry-run > $DEPLOYER_ORIGIN_DIR/working-configmap-jcasc-openshift-plugin.yaml
        oc $OC_ARG_OPTIONS apply -f $DEPLOYER_ORIGIN_DIR/working-configmap-jcasc-openshift-plugin.yaml

        echo -e "\n================================================================================"
        echo -e "Setting Volume and VolumeMount for ConfigMap for Openshift Client and Sync plugins...\n"

        SUB_DATA="volumeMounts:\n        - name: jcasc-openshift-plugin\n          mountPath: /var/jenkins_home/jcasc_config/openshift-plugin.yaml\n          readOnly: true"

        sed -e "s,volumeMounts:,$SUB_DATA," < cloudbees-core-working.yml > tmp && mv tmp cloudbees-core-working.yml

        SUB_DATA="volumes:\n      - name: jcasc-openshift-plugin\n        configMap:\n          name: jcasc-openshift-plugin"

        sed -e "s,volumes:,$SUB_DATA," < cloudbees-core-working.yml > tmp && mv tmp cloudbees-core-working.yml
        
        CJOC_MANIFEST_ALTERED="true"
    fi


    if [ $CJOC_CaC_SETUP_ROCKETCHAT_PLUGIN = "true" ]; then

        echo -e "\n================================================================================"
        echo -e "Setting configuration for Rocket.Chat plugin...\n"

        cp $DEPLOYER_ORIGIN_DIR/configuration-as-code/example.rocketchat.yaml $DEPLOYER_ORIGIN_DIR/configuration-as-code/working-rocketchat.yaml

        sed -i -e s,EXTERNAL_ROCKET_CHAT_FQDN,$ROCKET_CHAT_EXTERNAL_FQDN,g $DEPLOYER_ORIGIN_DIR/configuration-as-code/working-rocketchat.yaml
        sed -i -e s,RC_USERNAME,$ROCKET_CHAT_USER,g $DEPLOYER_ORIGIN_DIR/configuration-as-code/working-rocketchat.yaml
        sed -i -e s,RC_PASSWORD,$ROCKET_CHAT_USER_PASSWORD,g $DEPLOYER_ORIGIN_DIR/configuration-as-code/working-rocketchat.yaml
        sed -i -e s,RC_CHANNEL,$ROCKET_CHAT_CHANNEL,g $DEPLOYER_ORIGIN_DIR/configuration-as-code/working-rocketchat.yaml

        oc $OC_ARG_OPTIONS exec cjoc-0 -- mkdir -p /var/jenkins_home/jcasc_config/

        echo -e "\n================================================================================"
        echo -e "Creating ConfigMap for Rocket.Chat plugin...\n"

        oc $OC_ARG_OPTIONS create configmap jcasc-rocketchat-plugin --from-file=$DEPLOYER_ORIGIN_DIR/configuration-as-code/working-rocketchat.yaml -o yaml --dry-run > $DEPLOYER_ORIGIN_DIR/working-configmap-jcasc-rocketchat-plugin.yaml
        oc $OC_ARG_OPTIONS apply -f $DEPLOYER_ORIGIN_DIR/working-configmap-jcasc-rocketchat-plugin.yaml

        echo -e "\n================================================================================"
        echo -e "Setting Volume and VolumeMount for ConfigMap for Rocket.Chat plugin...\n"

        SUB_DATA="volumeMounts:\n        - name: jcasc-rocketchat-plugin\n          mountPath: /var/jenkins_home/jcasc_config/rocketchat-plugin.yaml\n          readOnly: true"

        sed -e "s,volumeMounts:,$SUB_DATA," < cloudbees-core-working.yml > tmp && mv tmp cloudbees-core-working.yml

        SUB_DATA="volumes:\n      - name: jcasc-rocketchat-plugin\n        configMap:\n          name: jcasc-rocketchat-plugin"

        sed -e "s,volumes:,$SUB_DATA," < cloudbees-core-working.yml > tmp && mv tmp cloudbees-core-working.yml
        
        CJOC_MANIFEST_ALTERED="true"
    fi


    if [ $CJOC_CaC_SETUP_LDAP_AUTHENTICATION = "true" ]; then

        export LDAP_DC_BASE=${LDAP_DC_BASE:=$(returnDC $LDAP_DOMAIN_REALM)}
        export LDAP_STUFFER_URL="${LDAP_SERVER_HOSTNAME}:${LDAP_SERVER_PORT}"
        export LDAP_FULL_PATH="${LDAP_SERVER_PROTOCOL}://${LDAP_SERVER_HOSTNAME}:${LDAP_SERVER_PORT}"
        
        echo -e "\n================================================================================"
        echo -e "Sending SSL CA Stuffer to CJOC pod...\n"

        oc $OC_ARG_OPTIONS exec cjoc-0 -- curl -L -sS -o /var/jenkins_home/ss-ca-stuffer.sh https://raw.githubusercontent.com/FierceSoftware/devsecops-workshop-wizbang/master/cloudbees-core/ss-ca-stuffer.sh
        oc $OC_ARG_OPTIONS exec cjoc-0 -- chmod +x /var/jenkins_home/ss-ca-stuffer.sh
        oc $OC_ARG_OPTIONS exec cjoc-0 -- /var/jenkins_home/ss-ca-stuffer.sh $LDAP_STUFFER_URL
        
        echo -e "\n================================================================================"
        echo -e "Setting new JAVA_OPTS for custom keystore on manifest for CJOC pod...\n"

        SUB_DATA="-XshowSettings:vm\n            -Djavax.net.ssl.trustStore="'$JENKINS_HOME'"/.cacerts/cacerts\n            -Djavax.net.ssl.trustStorePassword=changeit"

        sed -e "s,-XshowSettings:vm,$SUB_DATA," < cloudbees-core-working.yml > tmp && mv tmp cloudbees-core-working.yml
        
        CJOC_MANIFEST_ALTERED="true"

    fi

    if [ $CJOC_MANIFEST_ALTERED = "true" ]; then

        echo -e "\n================================================================================"
        echo -e "Setting environmental variable for Jenkins Configuration as Code plugin...\n"

        SUB_DATA="env:\n        - name: CASC_JENKINS_CONFIG\n          value: \"/var/jenkins_home/jcasc_config/\""

        sed -e "s,env:,$SUB_DATA," < cloudbees-core-working.yml > tmp && mv tmp cloudbees-core-working.yml

        echo -e "\n================================================================================"
        echo -e "Creating Credentials...\n"

        JENKINS_SA_TOKEN=$(oc $OC_ARG_OPTIONS serviceaccounts get-token jenkins -n $OCP_PROJECT_NAME)

        cp $DEPLOYER_ORIGIN_DIR/groovy-scripts/example.create-generic-credentials.groovy $DEPLOYER_ORIGIN_DIR/groovy-scripts/working-create-generic-credentials.groovy
        sed -i -e s,REPLACE_ME_WITH_SERVICE_ACCOUNT_TOKEN,$JENKINS_SA_TOKEN,g $DEPLOYER_ORIGIN_DIR/groovy-scripts/working-create-generic-credentials.groovy

        cp $DEPLOYER_ORIGIN_DIR/groovy-scripts/example.create-oc-client-credentials.groovy $DEPLOYER_ORIGIN_DIR/groovy-scripts/working-create-oc-client-credentials.groovy
        sed -i -e s,REPLACE_ME_WITH_SERVICE_ACCOUNT_TOKEN,$JENKINS_SA_TOKEN,g $DEPLOYER_ORIGIN_DIR/groovy-scripts/working-create-oc-client-credentials.groovy

        cp $DEPLOYER_ORIGIN_DIR/groovy-scripts/example.create-oc-sync-credentials.groovy $DEPLOYER_ORIGIN_DIR/groovy-scripts/working-create-oc-sync-credentials.groovy
        sed -i -e s,REPLACE_ME_WITH_SERVICE_ACCOUNT_TOKEN,$JENKINS_SA_TOKEN,g $DEPLOYER_ORIGIN_DIR/groovy-scripts/working-create-oc-sync-credentials.groovy

        java -jar $CBC_OCP_WORK_DIR/jenkins-cli.jar -s "${JENKINS_PROTOCOL_PREFIX}://${OCP_CJOC_ROUTE}/cjoc/" groovy = < $DEPLOYER_ORIGIN_DIR/groovy-scripts/working-create-generic-credentials.groovy
        java -jar $CBC_OCP_WORK_DIR/jenkins-cli.jar -s "${JENKINS_PROTOCOL_PREFIX}://${OCP_CJOC_ROUTE}/cjoc/" groovy = < $DEPLOYER_ORIGIN_DIR/groovy-scripts/working-create-oc-client-credentials.groovy
        java -jar $CBC_OCP_WORK_DIR/jenkins-cli.jar -s "${JENKINS_PROTOCOL_PREFIX}://${OCP_CJOC_ROUTE}/cjoc/" groovy = < $DEPLOYER_ORIGIN_DIR/groovy-scripts/working-create-oc-sync-credentials.groovy
        

        if [ $CJOC_CaC_SETUP_LDAP_AUTHENTICATION = "true" ]; then
            ## This has to be the last Groovy script applied as itll mess up other following commands with the new admin password...
            ## Sure we could check to see at a certain point and swap passwords but...thats meh
            
            echo -e "\n================================================================================"
            echo -e "Creating & executing LDAP Configuration groovy script...\n"

            cp $DEPLOYER_ORIGIN_DIR/groovy-scripts/example.configure-ldap.groovy $DEPLOYER_ORIGIN_DIR/groovy-scripts/working-configure-ldap.groovy

            sed -i -e s,SERVER_HERE,${LDAP_FULL_PATH},g $DEPLOYER_ORIGIN_DIR/groovy-scripts/working-configure-ldap.groovy
            sed -i -e s/ROOT_DN_HERE/${LDAP_DC_BASE}/g $DEPLOYER_ORIGIN_DIR/groovy-scripts/working-configure-ldap.groovy
            sed -i -e "s/MANAGER_DN_HERE/${LDAP_BIND_DN}/g" $DEPLOYER_ORIGIN_DIR/groovy-scripts/working-configure-ldap.groovy
            sed -i -e s,TOTALLY_SECURE_PASSWORD_HERE,${LDAP_BIND_PASSWORD},g $DEPLOYER_ORIGIN_DIR/groovy-scripts/working-configure-ldap.groovy

            java -jar $CBC_OCP_WORK_DIR/jenkins-cli.jar -s "$JENKINS_PROTOCOL_PREFIX://$OCP_CJOC_ROUTE/cjoc/" groovy = < $DEPLOYER_ORIGIN_DIR/groovy-scripts/working-configure-ldap.groovy

            export JENKINS_API_TOKEN=$LDAP_BIND_PASSWORD
        fi

        echo -e "\n================================================================================"
        echo -e "Reapplying manifest for CJOC pod...\n"

        oc $OC_ARG_OPTIONS apply -f cloudbees-core-working.yml

        echo -e "\n================================================================================"
        echo -e "Sleeping for 120s while Cloudbees Core redeploys with the new manifest...\n"
        sleep 120
    fi

    echo -e "\n================================================================================"
    echo "Creating Workshop Team Master..."
    curl -L -sS -o $CBC_OCP_WORK_DIR/workshop-team.json https://raw.githubusercontent.com/FierceSoftware/devsecops-workshop-wizbang/master/cloudbees-core/workshop-team.json

    java -jar $CBC_OCP_WORK_DIR/jenkins-cli.jar -s "${JENKINS_PROTOCOL_PREFIX}://${OCP_CJOC_ROUTE}/cjoc/" teams "workshop-team" --put < $CBC_OCP_WORK_DIR/workshop-team.json

    echo -e "\n\n================================================================================"
    echo -e "Finished with deploying Cloudbees Core!\n"

    if [ $CJOC_CaC_SETUP_LDAP_AUTHENTICATION = "true" ]; then
        echo -e "Admin password: ${LDAP_BIND_PASSWORD} \n"
    else
        echo -e "Admin password: ${JENKINS_ADMIN_PASS} \n"
    fi

    if [ "$INTERACTIVE" = "true" ]; then
        echo -e "\n\n================================================================================"
        read -p "Clean up and delete tmp directory? [N/y] " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            rm -rf $CBC_OCP_WORK_DIR
        fi
    fi
}

echo -e "\n\n================================================================================"
echo -e "Checking prerequisites...\n"

checkForProgram oc
checkForProgram curl
checkForProgram git
checkForProgram java

## Make the script interactive to set the variables
if [ "$INTERACTIVE" = "true" ]; then
    
    echo -e "\n================================================================================"
    echo -e "Starting interactive setup...\n"

	read -rp "OpenShift Cluster Host http(s)://ocp.example.com: ($OCP_HOST): " choice;
	if [ "$choice" != "" ] ; then
		export OCP_HOST="$choice";
	fi

	read -rp "OpenShift Auth Type [userpass or token]: ($OCP_AUTH_TYPE): " choice;
	if [ "$choice" != "" ] ; then
		export OCP_AUTH_TYPE="$choice";
	fi

    if [ $OCP_AUTH_TYPE = "userpass" ]; then

        read -rp "OpenShift Username: ($OCP_USERNAME): " choice;
        if [ "$choice" != "" ] ; then
            export OCP_USERNAME="$choice";
        fi

        read -rsp "OpenShift Password: " choice;
        if [ "$choice" != "" ] ; then
            export OCP_PASSWORD="$choice";
        fi
        echo -e ""

        OCP_AUTH="-u $OCP_USERNAME -p $OCP_PASSWORD"

    fi

    if [ $OCP_AUTH_TYPE = "token" ]; then

        read -rp "OpenShift Token: ($OCP_TOKEN): " choice;
        if [ "$choice" != "" ] ; then
            export OCP_TOKEN="$choice";
        fi

        OCP_AUTH="--token=$OCP_TOKEN"

    fi

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

	read -rp "Configure Kubernetes Cloud plugin? ($CJOC_CaC_SETUP_KUBERNETES_CLOUD): " choice;
	if [ "$choice" != "" ] ; then
		export CJOC_CaC_SETUP_KUBERNETES_CLOUD="$choice";
	fi

	read -rp "Configure OpenShift Client and Sync plugins? ($CJOC_CaC_SETUP_OPENSHIFT_PLUGINS): " choice;
	if [ "$choice" != "" ] ; then
		export CJOC_CaC_SETUP_OPENSHIFT_PLUGINS="$choice";
	fi

    if [ $CJOC_CaC_SETUP_OPENSHIFT_PLUGINS = "true" ]; then

        read -rp "Additional K8s Namespaces/OCP Projects to watch? ($EXTRA_OC_SYNC_NAMESPACES_HERE): " choice;
        if [ "$choice" != "" ] ; then
            export EXTRA_OC_SYNC_NAMESPACES_HERE="$choice";
        fi

    fi

	read -rp "Configure Rocket.Chat plugin? ($CJOC_CaC_SETUP_ROCKETCHAT_PLUGIN): " choice;
	if [ "$choice" != "" ] ; then
		export CJOC_CaC_SETUP_ROCKETCHAT_PLUGIN="$choice";
	fi

    if [ $CJOC_CaC_SETUP_ROCKETCHAT_PLUGIN = "true" ]; then

        read -rp "External Rocket.Chat Route? ($ROCKET_CHAT_EXTERNAL_FQDN): " choice;
        if [ "$choice" != "" ] ; then
            export ROCKET_CHAT_EXTERNAL_FQDN="$choice";
        fi

        read -rp "Rocket.Chat User for Jenkins? ($ROCKET_CHAT_USER): " choice;
        if [ "$choice" != "" ] ; then
            export ROCKET_CHAT_USER="$choice";
        fi

        read -rp "Rocket.Chat User Password for Jenkins? ($ROCKET_CHAT_USER_PASSWORD): " choice;
        if [ "$choice" != "" ] ; then
            export ROCKET_CHAT_USER_PASSWORD="$choice";
        fi

        read -rp "Rocket.Chat Channel? ($ROCKET_CHAT_CHANNEL): " choice;
        if [ "$choice" != "" ] ; then
            export ROCKET_CHAT_CHANNEL="$choice";
        fi

    fi

	read -rp "Configure LDAP Authentication? ($CJOC_CaC_SETUP_LDAP_AUTHENTICATION): " choice;
	if [ "$choice" != "" ] ; then
		export CJOC_CaC_SETUP_LDAP_AUTHENTICATION="$choice";
	fi

    if [ $CJOC_CaC_SETUP_LDAP_AUTHENTICATION = "true" ]; then

        read -rp "Skip Initial Setup? ($OCP_CJOC_SKIP_SETUP): " choice;
        if [ "$choice" != "" ] ; then
            export OCP_CJOC_SKIP_SETUP="$choice";
        fi

        read -rp "LDAP Domain Realm ($LDAP_DOMAIN_REALM): " choice;
        if [ "$choice" != "" ] ; then
            export LDAP_DOMAIN_REALM="$choice";
        fi

        read -rp "LDAP Server Protocol ($LDAP_SERVER_PROTOCOL): " choice;
        if [ "$choice" != "" ] ; then
            export LDAP_SERVER_PROTOCOL="$choice";
        fi

        read -rp "LDAP Server Port ($LDAP_SERVER_PORT): " choice;
        if [ "$choice" != "" ] ; then
            export LDAP_SERVER_PORT="$choice";
        fi

        read -rp "LDAP Server Hostname ($LDAP_SERVER_HOSTNAME): " choice;
        if [ "$choice" != "" ] ; then
            export LDAP_SERVER_HOSTNAME="$choice";
        fi

        read -rp "LDAP Bind DN ($LDAP_BIND_DN): " choice;
        if [ "$choice" != "" ] ; then
            export LDAP_BIND_DN="$choice";
        fi

        read -rsp "LDAP Bind DN Password ($LDAP_BIND_PASSWORD): " choice;
        if [ "$choice" != "" ] ; then
            export LDAP_BIND_PASSWORD="$choice";
        fi
        echo -e ""

    fi


fi

## Ensure Setup skipping is disabled unless LDAP is enabled
if [ $CJOC_CaC_SETUP_LDAP_AUTHENTICATION = "false" ]; then
    export OCP_CJOC_SKIP_SETUP="false";
fi

echo -e "\n "

echo -e "\n================================================================================"
echo "Log in to OpenShift..."
oc $OC_ARG_OPTIONS login $OCP_HOST $OCP_AUTH

echo -e "\n================================================================================"
echo "Create and Set Project..."
if [ "$OCP_CREATE_PROJECT" = "true" ]; then
    oc $OC_ARG_OPTIONS new-project $OCP_PROJECT_NAME --description="Central & Managed CI/CD Pipeline" --display-name="[Shared] Central CI/CD"
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

if [ "$OCP_CJOC_ROUTE_EDGE_TLS" = "true" ]; then
    sed -e s,http://cloudbees-core,https://cloudbees-core,g < cloudbees-core.yml > tmp && mv tmp cloudbees-core-working.yml && \
    sed -e s,cloudbees-core.example.com,$OCP_CJOC_ROUTE,g < cloudbees-core-working.yml > tmp && mv tmp cloudbees-core-working.yml && \
    sed -e s,myproject,$OCP_PROJECT_NAME,g < cloudbees-core-working.yml > tmp && mv tmp cloudbees-core-working.yml && \
    sed -e 's/host: /tls:'"\n"'    termination: edge'"\n"'    insecureEdgeTerminationPolicy: Redirect'"\n"'  host: /g' < cloudbees-core-working.yml > tmp && mv tmp cloudbees-core-working.yml
else
    sed -e s,http://cloudbees-core,https://cloudbees-core,g < cloudbees-core.yml > tmp && mv tmp cloudbees-core-working.yml && \
    sed -e s,cloudbees-core.example.com,$OCP_CJOC_ROUTE,g < cloudbees-core-working.yml > tmp && mv tmp cloudbees-core-working.yml && \
    sed -e s,myproject,$OCP_PROJECT_NAME,g < cloudbees-core-working.yml > tmp && mv tmp cloudbees-core-working.yml
fi

if [ "$OCP_CJOC_SKIP_SETUP" = "trueAF" ]; then
    ## On second thought dont skip since it leaves it super wide open
    ## But i left the setting in here just in case...
    SUB_DATA="-XshowSettings:vm\n            -Djenkins.install.runSetupWizard=false"

    sed -e "s,-XshowSettings:vm,$SUB_DATA," < cloudbees-core-working.yml > tmp && mv tmp cloudbees-core-working.yml
fi

## echo "Applying Jenkins Agent - Maven..."
## oc $OC_ARG_OPTIONS create -f https://raw.githubusercontent.com/kenmoini/jenkins-agent-maven-rhel7/master/jenkins-agent-maven-rhel7.yaml

## echo "Applying Jenkins Agent - Ansible..."
## oc $OC_ARG_OPTIONS create -f https://raw.githubusercontent.com/kenmoini/jenkins-agent-ansible/master/openshift-build-configmap.yaml

echo -e "\n================================================================================"
echo -e "Deploying ImageStreams...\n"

echo "Applying JBoss EAP 7.0 ImageStream..."
oc $OC_ARG_OPTIONS create -f https://raw.githubusercontent.com/kenmoini/application-templates/master/eap/eap70-image-stream.json

echo -e "\n================================================================================"
echo -e "Deploying Cloudbees Core...\n"
oc $OC_ARG_OPTIONS apply -f cloudbees-core-working.yml

echo -e "\n================================================================================"
echo -e "Adding admin role to cjoc, default, and jenkins service accounts...\n"
oc $OC_ARG_OPTIONS policy add-role-to-user admin system:serviceaccount:$OCP_PROJECT_NAME:cjoc
oc $OC_ARG_OPTIONS policy add-role-to-user admin system:serviceaccount:$OCP_PROJECT_NAME:default
oc $OC_ARG_OPTIONS policy add-role-to-user admin system:serviceaccount:$OCP_PROJECT_NAME:jenkins

echo -e "\n================================================================================"
echo -e "Sleeping for 120s while Cloudbees Core deploys...\n"
sleep 120

echo -e "\n================================================================================"
echo "Read the default Admin password with:"
echo " oc $OC_ARG_OPTIONS exec cjoc-0 -- cat /var/jenkins_home/secrets/initialAdminPassword"
echo ""
JENKINS_ADMIN_PASS="$(oc $OC_ARG_OPTIONS exec cjoc-0 -- cat /var/jenkins_home/secrets/initialAdminPassword)"
echo "Attempting admin password read-out: $JENKINS_ADMIN_PASS"

if [ "$OCP_CJOC_ROUTE_EDGE_TLS" = "true" ]; then
    echo -e "\n If you get a password above, please log into your Admin user at https://$OCP_CJOC_ROUTE/cjoc/ and\n 1. Complete the Setup Wizard\n 2. Disable CSRF and CAP\n 3. Come back and finish this script...I know, it is lame.\n\n Oh and when you get to the Create First Admin User screen just click Continue as admin - please.  Or otherwise modify this script with your intended password..."
else
    echo -e "\n If you get a password above, please log into your Admin user at http://$OCP_CJOC_ROUTE/cjoc/ and\n 1. Complete the Setup Wizard\n 2. Disable CSRF and CAP\n 3. Come back and finish this script...I know, it is lame.\n\n Oh and when you get to the Create First Admin User screen just click Continue as admin - please.  Or otherwise modify this script with your intended password..."
fi

promptToContinueAfterCJOCDeploy
