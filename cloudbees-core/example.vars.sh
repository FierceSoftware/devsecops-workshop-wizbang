#!/usr/bin/env bash

OCP_HOST=""

OCP_AUTH_TYPE="userpass"

OCP_USERNAME=""
OCP_PASSWORD=""
OCP_TOKEN=""

OCP_CREATE_PROJECT="true"
OCP_PROJECT_NAME="cicd-pipeline"

OCP_CJOC_ROUTE="cjoc.ocp.example.com"
OCP_CJOC_ROUTE_EDGE_TLS="true"

OC_ARG_OPTIONS=""
CBC_OCP_WORK_DIR="/tmp/cbc-ocp"

INTERACTIVE="false"

if [ $OCP_AUTH_TYPE == "userpass" ]; then
    OCP_AUTH="-u $OCP_USERNAME -p $OCP_PASSWORD"
fi
if [ $OCP_AUTH_TYPE == "token" ]; then
    OCP_AUTH="--token=$OCP_TOKEN"
fi