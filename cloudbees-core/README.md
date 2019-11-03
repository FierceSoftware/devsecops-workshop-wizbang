# CloudBees Core on OpenShift

Want to run CloudBees Core on OpenShift?  No problem!

Want it to integrate into OpenShift just like the built-in Jenkins?  Oh...okay...yeah, sure...kind of a pain though...

## Introduction
When running Red Hat OpenShift Container Platform you can quickly deploy OSS Jenkins as a CI/CD platform and it beautifully integrates with OCP's Build and Pipeline objects, the OpenShift DSL is available, log into Jenkins with the OCP OAuth provider, it's simply great *chefs kiss*

Except, Red Hat unfortunately does not provide the best Jenkins.  It is out-dated, vulnerable, with no central management if you have a large team, so it's just not secure or scalable.   As a central part of your CI/CD platform those are two things that are kind of required.  This is where CloudBees Core comes into play.

CloudBees Core is a managed, scalable, secure Jenkins and deploying on OCP is very easy.  Integrating it into OCP as the built-in Jenkins, that's a different story.

##  Deployment - Automated-ish

The deployment script ```./deploy.sh``` can also take preset environmental variables to provision without prompting the user.  To do so, copy over the ```example.vars.sh``` file, set the variables, source and run the deployer.

```
$ cp example.vars.sh vars.sh
$ vim vars.sh
$ source ./vars.sh && ./deployer.sh
```

##  Deployment - Interactive

There's a simple deployment script that can either prompt a user for variables or take them set in the Bash script.  As long as you have an OpenShift Cluster then you can simply run:

```
$ ./deployer.sh
```

And answer the prompts to deploy the full CloudBees Core integrated into OCP stack.

## Manual Steps

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

We now have the required manual steps done in order to proceed with the deployer.  Please continue with the deployment script and then configure LDAP/RBAC afterwards.  Just go back to the deployer script, press ***Y***, wait a few seconds, then go about configuring LDAP below.  You may think *Well, I'll go ahead and knock out the LDAP...* ***NO!*** STOP IT!  Doing so will break the script as the jenkins-cli needs the password and merging the LDAP user messes that up.

### Setting up LDAP - Stuffing Certificates
If you deployed RH IDM/LDAP with this repo's provisioner then it's using self-signed certificates which means you need to stuff them into the JRE keystore.  I fucking hate Java...

The easiest way to do this is to call the ```ss-ca-stuffer.sh``` script with a host that you'd like to pull the cert from, such as the following:

```
$ oc exec cjoc-0 -- curl -L -sS -o /var/jenkins_home/ss-ca-stuffer.sh https://raw.githubusercontent.com/FierceSoftware/devsecops-workshop-wizbang/master/cloudbees-core/ss-ca-stuffer.sh
$ oc exec cjoc-0 -- chmod +x /var/jenkins_home/ss-ca-stuffer.sh
$ oc exec cjoc-0 -- /var/jenkins_home/ss-ca-stuffer.sh idm.example.com:636
```

That will copy over the script and run a few commands that'll pull it into your CJOC JRE keystore.  However, you're not done yet because on OpenShift containers don't run as root and you can't write to the system keystore :)
Instead, that script will create a copy of the system keystore in a writable path at ```$JENKINS_HOME/.cacerts/cacerts```.  In order for CJOC to load the custom keystore it must be added to the JAVA_OPTS on the CJOC StatefulSet...
You can do this a few different ways - by modifying the ```cloudbees-core-working.yml``` file that was used to deploy this and then reapply it to the cluster to update the manifest, or by just modifying it in the Web UI.  That's way easier and faster.
In the OCP Web UI, navigate to the project, click on the StatefulSet, then in the ***Actions*** drop down to the right click ***Edit YAML***
Then find the CJOC container's ```env``` definitions in the manifest and modify the ```JAVA_OPTS``` value, add the following lines to the end:
```
-Djavax.net.ssl.trustStore=$JENKINS_HOME/.cacerts/cacerts
-Djavax.net.ssl.trustStorePassword=changeit
```
Then click ***Save***.  Wait a few moments and with any luck, CJOC will restart and JavaX will consume the new CA Certificate keystore that now includes your self-signed IDM certificate, allowing the connection of LDAPS.

### Setting up LDAP - Configuring LDAP
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

### Setting up LDAP - RBAC
So the LDAP groups don't automatically map to Jenkins groups and...yeah, whatever, no one does LDAP right and I'm tired of it.  Let's just get the show on with it now...

1. In the left hand pane click on the new ***Groups*** link
2. Because LDAP and Jenkins have an overlapping admin user, we need to manually add the ***admin*** user to the ***Administrators*** group.  Do that.
3. Next, add the ***ipausers*** group to the ***Developers*** group.
4. That should be about it, but what do I know...