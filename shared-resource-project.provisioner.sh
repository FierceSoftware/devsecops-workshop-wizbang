#!/bin/bash

## Default variables to use
export INTERACTIVE=${INTERACTIVE:="true"}

export OCP_HOST=${OCP_HOST:=""}
export OCP_USERNAME=${OCP_USERNAME:=""}
export OCP_PASSWORD=${OCP_PASSWORD:=""}

export OCP_CREATE_PROJECT=${OCP_CREATE_PROJECT:="true"}
export OCP_PROJECT_NAME=${OCP_PROJECT_NAME:="workshop-resources"}

export OCP_DEPLOY_CHE=${OCP_DEPLOY_CHE:="true"}
export OCP_DEPLOY_SAMPLE_PIPELINE_DEMO_APP1=${OCP_DEPLOY_SAMPLE_PIPELINE_DEMO_APP1:="true"}

export OC_ARG_OPTIONS=${OC_ARG_OPTIONS:=""}

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

	read -rp "Deploy Che Template? ($OCP_DEPLOY_CHE): " choice;
	if [ "$choice" != "" ] ; then
		export OCP_DEPLOY_CHE="$choice";
	fi

	read -rp "Deploy Demo App Sample Pipeline Template? ($OCP_DEPLOY_SAMPLE_PIPELINE_DEMO_APP1): " choice;
	if [ "$choice" != "" ] ; then
		export OCP_DEPLOY_SAMPLE_PIPELINE_DEMO_APP1="$choice";
	fi

fi

echo -e "\n "

echo -e "\n================================================================================"
echo "Log in to OpenShift..."
oc $OC_ARG_OPTIONS login $OCP_HOST -u $OCP_USERNAME -p $OCP_PASSWORD

echo -e "\n================================================================================"
echo "Create and Set Project..."
if [ "$OCP_CREATE_PROJECT" = "true" ]; then
    oc $OC_ARG_OPTIONS new-project $OCP_PROJECT_NAME --description="Central & Managed Workshop Team Resources" --display-name="[Shared] Team Resources"
    oc $OC_ARG_OPTIONS project $OCP_PROJECT_NAME
fi
if [ "$OCP_CREATE_PROJECT" = "false" ]; then
    oc $OC_ARG_OPTIONS project $OCP_PROJECT_NAME
fi

if [ "$OCP_DEPLOY_CHE" = "true" ]; then
    echo -e "Deploying Eclipse Che template to shared namespace...\n"
    oc $OC_ARG_OPTIONS create -f https://raw.githubusercontent.com/kenmoini/openshift-eclipse-che/master/template-deployer.yml
fi

if [ "$OCP_DEPLOY_SAMPLE_PIPELINE_DEMO_APP1" = "true" ]; then
    echo -e "Deploying Demo App #1 template to shared namespace...\n"
    oc $OC_ARG_OPTIONS create -f https://raw.githubusercontent.com/kenmoini/demo-app-slide-deck/master/openshift/openshift-template.yaml
fi