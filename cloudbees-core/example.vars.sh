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
OCP_CJOC_SKIP_SETUP="true"

CJOC_CaC_SETUP_KUBERNETES_CLOUD="true"
CJOC_CaC_SETUP_LDAP_AUTHENTICATION="false"
CJOC_CaC_SETUP_OPENSHIFT_PLUGINS="true"
CJOC_CaC_SETUP_ROCKETCHAT_PLUGIN="false"

LDAP_DOMAIN_REALM="EXAMPLE.COM"
LDAP_SERVER_HOSTNAME="idm.example.com"
LDAP_SERVER_PROTOCOL="ldaps"
LDAP_SERVER_PORT="636"
LDAP_BIND_DN="cn=Directory Manager"
LDAP_BIND_PASSWORD=""

EXTRA_OC_SYNC_NAMESPACES_HERE=""

ROCKET_CHAT_EXTERNAL_FQDN="https://rocketchat.ocp.example.com"
ROCKET_CHAT_USER="rcjenkins"
ROCKET_CHAT_USER_PASSWORD=""
ROCKET_CHAT_CHANNEL="#devsecops-workshop"

CJOC_MANIFEST_ALTERED="false"

OC_ARG_OPTIONS=""
CBC_OCP_WORK_DIR="/tmp/cbc-ocp"

INTERACTIVE="false"

function returnDC() {
    LDAP_DC=""
    for i in $(echo $1 | tr "." "\n")
    do
        LDAP_DC="${LDAP_DC},dc=$i"
    done
    echo ${LDAP_DC#?}
}

LDAP_DC_BASE=$(returnDC $LDAP_DOMAIN_REALM)

if [ $OCP_AUTH_TYPE = "userpass" ]; then
    OCP_AUTH="-u $OCP_USERNAME -p $OCP_PASSWORD"
fi
if [ $OCP_AUTH_TYPE = "token" ]; then
    OCP_AUTH="--token=$OCP_TOKEN"
fi