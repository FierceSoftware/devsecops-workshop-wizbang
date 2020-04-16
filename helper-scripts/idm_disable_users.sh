#/bin/bash

## set -x	## Uncomment for debugging

## Include vars if the file exists
FILE=./vars.sh
if [ -f "$FILE" ]; then
    source ./vars.sh
fi

## Default variables to use
export INTERACTIVE=${INTERACTIVE:="true"}

export IDM_HOST=${IDM_HOST:="idm.example.com"}

export IDM_ADMIN_USERNAME=${IDM_ADMIN_USERNAME:="admin"}
export IDM_ADMIN_PASSWORD=${IDM_ADMIN_PASSWORD:=""}

export BATCH_USER_PREFIX=${BATCH_USER_PREFIX:="student"}
export BATCH_USER_SUFFIX=${BATCH_USER_SUFFIX:=""}
export BATCH_USER_START=${BATCH_USER_START:="0"}
export BATCH_USER_COUNT=${BATCH_USER_COUNT:="20"}

## Make the script interactive to set the variables
if [ "$INTERACTIVE" = "true" ]; then

    echo -e "\n================================================================================"
    echo -e "Starting interactive setup...\n"

    read -rp "Red Hat Identity Management Host idm.example.com: ($IDM_HOST): " choice;
    if [ "$choice" != "" ] ; then
      export IDM_HOST="$choice";
    fi

    read -rp "IDM Admin Username: ($IDM_ADMIN_USERNAME): " choice;
    if [ "$choice" != "" ] ; then
      export IDM_ADMIN_USERNAME="$choice";
    fi

    read -rp "IDM Admin Password: ($IDM_ADMIN_PASSWORD): " choice;
    if [ "$choice" != "" ] ; then
      export IDM_ADMIN_PASSWORD="$choice";
    fi

    read -rp "IDM Batch User Prefix: ($BATCH_USER_PREFIX): " choice;
    if [ "$choice" != "" ] ; then
      export BATCH_USER_PREFIX="$choice";
    fi

    read -rp "IDM Batch User Suffix: ($BATCH_USER_SUFFIX): " choice;
    if [ "$choice" != "" ] ; then
      export BATCH_USER_SUFFIX="$choice";
    fi

    read -rp "IDM Batch User Starting Interval: ($BATCH_USER_START): " choice;
    if [ "$choice" != "" ] ; then
      export BATCH_USER_START="$choice";
    fi

    read -rp "IDM Batch User Count: ($BATCH_USER_COUNT): " choice;
    if [ "$choice" != "" ] ; then
      export BATCH_USER_COUNT="$choice";
    fi

fi

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

checkForProgram kinit
checkForProgram ipa

echo -e "\n "

echo -e "\n================================================================================"
echo -e "Log in to IDM...\n"
echo "$IDM_ADMIN_PASSWORD" | kinit "${IDM_ADMIN_USERNAME}@${IDM_HOST}"

BATCH_USER_COUNTER=0
while [[ $BATCH_USER_COUNTER -le $BATCH_USER_COUNT ]]; do

  echo -e "\nDisabling ${BATCH_USER_PREFIX}${BATCH_USER_COUNTER}${BATCH_USER_SUFFIX}...\n"
  
  ipa user-disable "${BATCH_USER_PREFIX}${BATCH_USER_COUNTER}${BATCH_USER_SUFFIX}"

done

