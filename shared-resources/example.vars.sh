#!/usr/bin/env bash

OCP_HOST=""

OCP_AUTH_TYPE="userpass"

OCP_USERNAME=""
OCP_PASSWORD=""
OCP_TOKEN=""

OCP_CREATE_PROJECT="true"
OCP_PROJECT_NAME="workshop-resources"

OCP_DEPLOY_CHE="true"
OCP_DEPLOY_WORKSHOP_TERMINAL="true"
OCP_DEPLOY_SAMPLE_PIPELINE_DEMO_APP1="true"

OC_ARG_OPTIONS=""

INTERACTIVE="false"

if [ $OCP_AUTH_TYPE == "userpass" ]; then
    OCP_AUTH="-u $OCP_USERNAME -p $OCP_PASSWORD"
fi
if [ $OCP_AUTH_TYPE == "token" ]; then
    OCP_AUTH="--token=$OCP_TOKEN"
fi
