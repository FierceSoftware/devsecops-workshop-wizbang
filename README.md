# All-Star Software World Wide Presents: DevSecOps Workshops
## Featuring:
- The Public Cloud!
- Red Hat OpenShift Container Platform
- CloudBees Core
- GitLab
- Sonatype
- SonarQube
- SysDig
- RocketChat

## How to Use

Fuck if I remember...

1. Start with an OpenShift cluster with Logging/Metrics
2. Deploy GitLab and IDM Servers by running ansible-playbooks
3. Run provisioner.sh in order to provision OCP Namespaces and Objects such as CloudBees and SysDig
4. ???????
5. Hope it works


## Deploying CloudBees Core

The provisioner.sh file handles creating all of the OpenShift jazz and deploying the CloudBees Core objects by calling an
Ansible Playbook that will template a file and deploy to the cluster.

Upon provisioning, you'll need to cat /var/jenkins_home/secrets/initialAdminPassword from the CJOC pod to get the 
initial Admin Password and provision the rest of CloudBees Core for the initial set up.
- Set CORS legacy proxy shit in Global Security settings or else nothing will work behind OCP LB
- If you get gitlab issues, it's probably because AWS' shit internal DNS isn't resolving and you have to set a private zone A record to the public IP address...
- Connect LDAP/IDM to CJOC with:

  - Server: ldap://idm.fiercesw.network:389
  - User search base: CN=accounts
  - User search filter: uid={0}
  - Manager DN: CN=Directory Manager
  - Manager Password: duh
  - Display Name LDAP attribute: displayname
  - Email Address LDAP attribute: mail

### Getting CloudBees Core to play nice with OCP

So the built in OSS Jenkins is magic, but not managable.  The CJOC integration with OpenShift as a Kubernetes platform is
decent at best, let's recreate some of that integrated magic. http://v1.uncontained.io/playbooks/continuous_delivery/external-jenkins-integration.html

- Getting CJOC to play nice with other plug-in repos, even after disabling CAP is a pain in the ass. Sometimes you can just add the public jenkins repo and it'll work (https://updates.jenkins.io/update-center.json) but most times it doesn't.  Funny thing is that
the easiest thing to do is just download the OpenShift plugins manually and install them by hand...you'll need a lot of dependancies, but here's a good starting list:

  - openshift-client
  - pipeline-build-step
  - pipeline-input-step
  - pipeline-milestone-step
  - pipeline-stage-step
  - pipeline graph-analysis
  - pipeline-rest-api
  - pipeline-stage-view
  - pipeline-model-definition
  - git-server
  - lockable-resources
  - Pipeline: Shared Groovy Libraries/workflow-cps-global-lib
  - pipeline/workflow-aggrigator
  - openshift-sync
  - openshift-pipeline
  - rocketchat

- Next, set up some secrets and service accounts as described by the external Jenkins integration bit (should probably
  be run before deploying CJOC...)

  - oc login
  - oc new-project dso-workshop-dev
  - oc new-project dso-workshop-stage
  - oc new-project dso-workshop-prod
  - oc new-project cloudbees-core
  - oc create serviceaccount cloudbees-jenkins
  - oc policy add-role-to-user edit system:serviceaccount:cloudbees-core:cloudbees-jenkins -n dso-workshop-dev
  - oc policy add-role-to-user edit system:serviceaccount:cloudbees-core:cloudbees-jenkins -n dso-workshop-stage
  - oc policy add-role-to-user edit system:serviceaccount:cloudbees-core:cloudbees-jenkins -n dso-workshop-prod
  - oc serviceaccounts get-token cloudbees-jenkins -n cloudbees-core
  - Download CloudBees Core, make modifications to the yaml, oc create -f cloudbees-core.yml
  - Create a new global/root Jenkins Credential with the SA token for the OpenShift Token for OpenShift Sync Plugin
  - Create a new global/root Jenkins Credential with the SA token for the Secret Text type
  - Set configuration on Jenkins K8s/OCP Plugins



## Deploying Rocket Chat for ChatOps

Create a RocketChat server on OCP from here: https://github.com/kenmoini/openshift-rocketchat

Run the initial admin account creation, then create a room for your #workshops-team.  Configure LDAP with the following:

- LDAP General - Enable: True
- LDAP General - Login Fallback: True
- LDAP General - Find user after login: True
- LDAP General - Host: idm.fiercesw.network
- LDAP General - Port: 636
- LDAP General - Reconnect: True
- LDAP General - Encryption: SSL/LDAPS
- LDAP General - Regect Unauthorized: False
- LDAP General - Base DN: cn=accounts,dc=fiercesw,dc=network
- LDAP Authentication - Enable: True
- LDAP Authentication - User DN: cn=Directory Manager
- LDAP Authentication - Password: duh
- LDAP Sync/Import - Username Field: uid
- LDAP Sync/Import - Unique Identifier Field: uid
- LDAP User Search - Filter: (objectclass=*)
- LDAP User Search - Scope: sub
- LDAP User Search - Search Field: uid

You'll also probably want to create a user for Jenkins to interact with Rocketchat.

