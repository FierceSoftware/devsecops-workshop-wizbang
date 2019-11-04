# CloudBees Core on OpenShift

Want to run CloudBees Core on OpenShift?  No problem!

Want it to integrate into OpenShift just like the built-in Jenkins?  Oh...okay...yeah, sure...kind of a pain though...

## Introduction

When running Red Hat OpenShift Container Platform you can quickly deploy OSS Jenkins as a CI/CD platform and it beautifully integrates with OCP's Build and Pipeline objects, the OpenShift DSL is available, log into Jenkins with the OCP OAuth provider, it's simply great *chefs kiss*

Except, Red Hat unfortunately does not provide the best Jenkins.  It is out-dated, vulnerable, with no central management if you have a large team, so it's just not secure or scalable.   As a central part of your CI/CD platform those are two things that are kind of required.  This is where CloudBees Core comes into play.

CloudBees Core is a managed, scalable, secure Jenkins and deploying on OCP is very easy.  Integrating it into OCP as the built-in Jenkins, that's a different story.

## {1}. Deployment - Automated-ish

The deployment script ```./deploy.sh``` can also take preset environmental variables to provision without prompting the user.  To do so, copy over the ```example.vars.sh``` file, set the variables, source and run the deployer.

```bash
$ cp example.vars.sh vars.sh
$ vim vars.sh
$ source ./vars.sh && ./deployer.sh
```

## {1}. Deployment - Interactive

There's a simple deployment script that can either prompt a user for variables or take them set in the Bash script.  As long as you have an OpenShift Cluster then you can simply run:

```bash
$ ./deployer.sh
```

And answer the prompts to deploy the full CloudBees Core integrated into OCP stack.

## 2. Manual Initial Deployment Steps

When running the ```deployer.sh``` script, you'll find it's run in two sections.
The first part will deploy the OpenShift manifests needed to run CloudBees Core.  Once it it deployed, you need to manually finish the Setup Wizard and run some other steps.  These are those steps...

1. Login to the CloudBees Jenkins Operations Center (CJOC) by hitting the route set in deployment.
2. Use the administrative password at the initial Setup Wizard prompt to continue
3. I suggest Requesting a Trial License - it's seemless and easy, lets you see what CloudBees Core really can do.
4. Install the Suggested Plugins
5. For the deployment script to continue to the next phase, don't fill out **Create First Admin User** just click **Continue as admin** - otherwise you will need to modify the environmental variable for ```JENKINS_API_TOKEN``` to also be the same password and username you set as the first admin user you create.
6. Click ***Save*** and ***Finish***
7. Next, navigate to ***Manage Jenkins > Configure Security*** then scroll down to ***CSRF Protection > Prevent Cross Site Request Forgery exploits*** and uncheck the box - this is only until the rest of the system is configured and the Team Master is deployed.  Jenkins has issues behind a LoadBalancer.
8. Click ***Apply***, reload the page, and then click ***Save***
9. Return to the terminal with your waiting deployment script, press ***Y*** to continue.

We now have the required manual steps done in order to proceed with the deployer.  Please continue with the deployment script and then configure LDAP/RBAC afterwards.  Just go back to the deployer script, press ***Y***, wait a few seconds, then go about configuring LDAP below.  You may think *Well, I'll go ahead and knock out the LDAP...* ***NO!*** STOP IT!  Doing so will break the script as the jenkins-cli needs the password and merging the LDAP user messes that up.

### 3. Setting up LDAP - Stuffing Certificates

If you deployed RH IDM/LDAP with this repo's provisioner then it's using self-signed certificates which means you need to stuff them into the JRE keystore.  I fucking hate Java...

The easiest way to do this is to call the ```ss-ca-stuffer.sh``` script with a host that you'd like to pull the cert from, such as the following:

```bash
$ oc exec cjoc-0 -- curl -L -sS -o /var/jenkins_home/ss-ca-stuffer.sh https://raw.githubusercontent.com/FierceSoftware/devsecops-workshop-wizbang/master/cloudbees-core/ss-ca-stuffer.sh
$ oc exec cjoc-0 -- chmod +x /var/jenkins_home/ss-ca-stuffer.sh
$ oc exec cjoc-0 -- /var/jenkins_home/ss-ca-stuffer.sh idm.example.com:636
```

That will copy over the script and run a few commands that'll pull it into your CJOC JRE keystore.  However, you're not done yet because on OpenShift containers don't run as root and you can't write to the system keystore :)
Instead, that script will create a copy of the system keystore in a writable path at ```$JENKINS_HOME/.cacerts/cacerts```.  In order for CJOC to load the custom keystore it must be added to the JAVA_OPTS on the CJOC StatefulSet...
You can do this a few different ways - by modifying the ```cloudbees-core-working.yml``` file that was used to deploy this and then reapply it to the cluster to update the manifest, or by just modifying it in the Web UI.  That's way easier and faster.
In the OCP Web UI, navigate to the project, click on the StatefulSet, then in the ***Actions*** drop down to the right click ***Edit YAML***
Then find the CJOC container's ```env``` definitions in the manifest and modify the ```JAVA_OPTS``` value, add the following lines to the end:

```bash
-Djavax.net.ssl.trustStore=$JENKINS_HOME/.cacerts/cacerts
-Djavax.net.ssl.trustStorePassword=changeit
```

Then click ***Save***.  Wait a few moments and with any luck, CJOC will restart and JavaX will consume the new CA Certificate keystore that now includes your self-signed IDM certificate, allowing the connection of LDAPS.

### 4. Setting up LDAP - Configuring LDAP

Once you have the custom keystore set up you can continue with configuring LDAP over LDAPS.  *Reminder: Don't use LDAP since you'll be screaming your passwords in plain-text over the Internet :)*

1. With CJOC reloaded, log in as admin and navigate to ***Manage Jenkins > Configure Global Security***.
2. Select the ***LDAP*** radio
3. Go ahead and click on that ***Advanced Server Configuration...*** button
4. Configure with the following settings:

  - ***Server:***  ldaps://idm.example.com:636
  - ***root DN:*** dc=example,dc=com
  - ***User search base:*** cn=accounts
  - ***User search filter:*** uid={0}
  - ***Group search base:*** cn=groups,cn=accounts
  - ***Group membership:*** Select *Search for LDAP groups container user*
  - ***Group membership attribute:*** (| (member={0}) (uniqueMember={0}) (memberUid={1}))
  - ***Manager DN:*** cn=Directory Manager
  - ***Manager Password:*** lol_idk_my_bff_jill?
  - ***Display Name LDAP Attribute:*** displayname
  - ***Email Address LDAP Attribute:*** mail

5. Under the ***Authorization*** Field, select the *Role-based matrix authorization strategy* radio option
6. For the ***Import strategy*** select *Typical initial setup*
7. Click ***Apply*** then ***Save***

### 5. Setting up LDAP - RBAC

So the LDAP groups don't automatically map to Jenkins groups and...yeah, whatever, no one does LDAP right and I'm tired of it.  Let's just get the show on with it now...

1. In the left hand pane click on the new ***Groups*** link
2. Because LDAP and Jenkins have an overlapping admin user, we need to manually add the ***admin*** user to the ***Administrators*** group.  Do that.
3. Next, add the ***ipausers*** group to the ***Developers*** group.
4. That should be about it, but what do I know.

### Configuring OCP + CJOC Integrations

So now it's time to add some of those delightful integrations the native OSS Jenkins + OCP have.  Most of these steps are distilled from here: http://v1.uncontained.io/playbooks/continuous_delivery/external-jenkins-integration.html

#### 6. Configuring OCP + CJOC Integrations - Service Accounts

If you're not familiar with Service Accounts (SAs) in Kubernetes/OpenShift, they're non-expiring credentials that can have roles, secrets, and scopes applied to them in order to provide applications a way to interact with the Kubernetes API.  Basically it's how CJOC can push new Pods/Routes/etc to K8s/OCP.

You can create a new service account for CJOC/Jenkins, but the ones provisioned with CloudBees Core on OCP are good enough if they just have another role.
Primarily, the included SAs from CJOC's deployment require an additional ```edit``` role to interact and watch the namespace.  If you've provisioned it with this script, you may notice that the ```cjoc``` and ```jenkins``` SAs were given ```admin``` roles.  That's more or less fine, but probably not for production since that allows Jenkins to do pretty much anything in this namespace - not too worried about it for workshops.

Either way, you'll need to get the SA Token to include it into CJOC.

```bash
## Option 1) Create new SA
$ oc create serviceaccount ocp-jenkins-sa
$ oc adm policy add-role-to-user edit system:serviceaccount:your_project_namespace_here:ocp-jenkins-sa -n your_project_namespace_here
$ oc serviceaccounts get-token ocp-jenkins-sa -n your_project_namespace_here

## Option 2) Use included SA
$ oc serviceaccounts get-token jenkins -n your_project_namespace_here
```

You should end up with a long string - that's your token.  Maybe dump it to a file if you need to, but you'll need it in the following steps...

#### 7. Configuring OCP + CJOC Integrations - CJOC Credentials

Next, we'll drop back into CJOC to store some Credentials that will be used to communicate with K8s/OCP.

1. From the main CJOC side panel, select ***Credentials***
2. Find ***Stores scoped to Jenkins*** and hover over ***(global)*** where a dropdown caret will appear.
3. Click the dropdown caret that appears next to ***(global)*** and select ***Add credentials***
4. There are two credentials to make, as configured below:

##### OpenShift Sync Plugin Credential

- ***Kind:*** OpenShit Token for OpenShift Sync Plugin
- ***Scope:*** Global
- ***Token:*** that_long_ass_token_string_from_earlier_that_i_told_ya_to_keep_handy
- ***ID:*** Can enter any value or leave blank for Jenkins to autogenerate a UUID - I suggest setting to ```oc-sync-token```
- ***Description:*** Whatever you'd like

##### Generic Token Credential

- ***Kind:*** Secret Text
- ***Scope:*** Global
- ***Token:*** that_long_ass_token_string_from_earlier_that_i_told_ya_to_keep_handy
- ***ID:*** Can enter any value or leave blank for Jenkins to autogenerate a UUID - I suggest setting to ```oc-generic-token```
- ***Description:*** Whatever you'd like

#### 8. Configuring OCP + CJOC Integrations - OpenShift Sync Plugin

The Jenkins OpenShift Sync Plugin is responsible for synchronizing the state of BuildConfig API objects in OpenShift and jobs within Jenkins. Whenever a new BuildConfig with a JenkinsPipeline type is created in OpenShift, the contents result in a new job in Jenkins.  This is some of the major magic.

1. From the overview page, select ***Manage Jenkins > Configure System***
2. Locate the ***OpenShift Jenkins Sync*** section and configure as follows:

  - ***Enabled:*** Checked...
  - ***Server:*** *(Blank!)*
  - ***Credentials:*** oc-sync-token
  - ***Namespace:*** The namespace CJOC resides in should be already filled, otherwise add a list of namespaces for the plugin to monitor, maybe for a workshop it'd be something like:

  ```
  dev-student-user0 dev-student-user1 dev-student-user2 dev-student-user3 dev-student-user4 dev-student-user5 dev-student-user6 dev-student-user7 dev-student-user8 dev-student-user9 dev-student-user10 dev-student-user11 dev-student-user12 dev-student-user13 dev-student-user14 dev-student-user15 dev-student-user16 dev-student-user17 dev-student-user18 dev-student-user19 dev-student-user20 dev-student-user21 dev-student-user22 dev-student-user23 dev-student-user24 dev-student-user25 dev-student-user26 dev-student-user27 dev-student-user28 dev-student-user29 dev-student-user30 dev-student-user31 dev-student-user32 dev-student-user33 dev-student-user34 dev-student-user35 dev-student-user36 dev-student-user37 dev-student-user38 dev-student-user39 dev-student-user40 dev-student-user41 dev-student-user42 dev-student-user43 dev-student-user44 dev-student-user45 dev-student-user46 dev-student-user47 dev-student-user48 dev-student-user49 dev-student-user50
  ```
  
  I would actually suggest setting all those dev- namespaces on the OpenShift Sync Plugin config on the Team Master - that way the Team Master will look for BuildConfigs in the student-user dev namespaces and CJOC will look after itself.

  ***NOTE*** In order for the Team Master to watch the different student-user dev namespaces, you also need to provide the Service Account used for credentials in CJOC to access those namespaces as well...

  ```bash
  $ oc adm policy add-role-to-user edit system:serviceaccount:your_cjoc_namespace:jenkins_service_account_here -n dev-student-user0
  $ oc adm policy add-role-to-user edit system:serviceaccount:your_cjoc_namespace:jenkins_service_account_here -n dev-student-user1
  ...
  $ oc adm policy add-role-to-user edit system:serviceaccount:your_cjoc_namespace:jenkins_service_account_here -n dev-student-user50
  ```

3. Click ***Apply*** and ***Save*** below to continue.

#### 9. Configuring OCP + CJOC Integrations - Kubernetes Plugin

The Jenkins Kubernetes Plugin allows you to spin up Dynamic Agents on a K8s/OCP cluster.  Very handy.

1. From the overview page, select ***Manage Jenkins > Configure System***
2. Locate the ***Cloud*** section, probably close to the bottom.
3. Click ***Add a new cloud*** and select ***Kubernetes***
4. Configure with the following bits:

  - ***Name:*** kubernetes
  - ***Kubernetes Namespace:*** The namespace you want Agents to spawn in.  Can be the same one you're currently in, like ```cicd-pipeline-cjoc```
  - ***Credentials:*** oc-generic-token

### 10. Provisioning the Workshops Team Master

If deploying with LDAP and the OCP integrations you'll want to provision the Team Master last.  Reason being it'll inherit the configurations without needing to be specifically set.

There are a few sample Team Master templates that you can use the ```jenkins-cli``` to deploy.

- ```test-basic-team.json``` - This file should work no matter what - the recipe and user are native to Jenkins
- ```test-ocp-team.json``` - This file is the OCP Java + Node Team with just a single native admin user - also should work.
- ```workshop-team.json``` - This file is the same as the ```test-ocp-team``` but also includes the ```ipausers``` group for LDAP integrations.  Evidently there's a rule of thumb to not have more than 20 Member entries for a team, so 50 individual users would cause it to fail...

If you kept your temporary working directory after deployment, you'll find the ```jenkins-cli.jar``` file there.  If not just simply navigate to ***cloudbees-core.ocp.example.com/cjoc/jnlpJars/jenkins-cli.jar*** to download it.

The commands to deploy the Team Masters are similar to the following examples *(oh, you need Java installed btw, tested with OpenJDK 11)*:

```bash
$ java -jar jenkins-cli.jar -auth admin:your_admin_password -s https://cloudbees-core.ocp.example.com/cjoc/ teams "test-from-cli" --put < test-basic-team.json
$ java -jar jenkins-cli.jar -auth admin:your_admin_password -s https://cloudbees-core.ocp.example.com/cjoc/ teams "ocp-test-from-cli" --put < test-ocp-team.json
$ java -jar jenkins-cli.jar -auth admin:your_admin_password -s https://cloudbees-core.ocp.example.com/cjoc/ teams "workshop-team" --put < workshop-team.json
```

With a few minutes time, you should see your Teams deployed in Teams/BlueOcean.

### 11. Setting Team Master General Configuration

All that you really need to do on this is enter the Team Master from CJOC, not BlueOcean, and navigate to ***Manage Jenkins > Configure System*** and set the OpenShift Sync Plugin namespace to monitor the student namespaces this Team Master should sync with.  Then give the service account in the CJOC/TM namespace access to those other student namespaces.