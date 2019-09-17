#!/bin/bash


# Variables
# Break these out into a separate shell script to configure/ignore, then source the script
ADMIN_OC_USER="admin"
ADMIN_OC_PASSWORD="changeme"

STUDENT_OC_USER_PREFIX="student-user"
STUDENT_OC_USER_SUFFIX=""
STUDENT_OC_USER_PASSWORD="changemetoo"

STUDENT_OC_USER_BEGIN=0
STUDENT_OC_USER_COUNT=50

OC_ENDPOINT="https://ocp.example.com:443"
OC_PROJECT_SUFFIX="-dso"
OC_ARG_OPTIONS=

GITHUB_ACCOUNT=${GITHUB_ACCOUNT:-kenmoini}
GITHUB_REF=${GITHUB_REF:-master}

# Tasks

PRJ_SUFFIX=${OC_PROJECT_SUFFIX:-`echo $OPENSHIFT_USER | sed -e 's/[-@].*//g'`}

# Admin - Create Shared CI/CD Space
function deploy() {

    # Create shared CI CD Space
    oc $OC_ARG_OPTIONS new-project cicd-pipeline-$PRJ_SUFFIX --display-name="[Shared] CI/CD Pipeline"

    #  Download Cloudbees Core
    wget https://downloads.cloudbees.com/cloudbees-core/cloud/2.176.2.3/cloudbees-core_2.176.2.3_openshift.tgz
    tar zxvf cloudbees-core_*_openshift.tgz

}

function destroy() {

    # Destroy shared CI CD Space
    oc $OC_ARG_OPTIONS delete project cicd-pipeline-$PRJ_SUFFIX

}
