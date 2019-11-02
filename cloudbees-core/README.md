# CloudBees Core on OpenShift

Want to run CloudBees Core on OpenShift?  No problem!

Want it to integrate into OpenShift just like the built-in Jenkins?  Oh...okay...yeah, sure...kind of a pain though...

## Introduction
When running Red Hat OpenShift Container Platform you can quickly deploy OSS Jenkins as a CI/CD platform and it beautifully integrates with OCP's Build and Pipeline objects, the OpenShift DSL is available, log into Jenkins with the OCP OAuth provider, it's simply great *chefs kiss*

Except, Red Hat unfortunately does not provide the best Jenkins.  It is out-dated, vulnerable, with no central management if you have a large team, so it's just not secure or scalable.   As a central part of your CI/CD platform those are two things that are kind of required.  This is where CloudBees Core comes into play.

CloudBees Core is a managed, scalable, secure Jenkins and deploying on OCP is very easy.  Integrating it into OCP as the built-in Jenkins, that's a different story.

##  Deployment - Automated

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
6. Click Save and Finish
7. Next, navigate to ***Manage Jenkins > Configure Security*** then scroll down to ***CSRF Protection > Crumb Algorithm*** and check the ***Enable proxy compatibility*** box - this is so CJOC operates properly behind the OCP LoadBalancer/Router
8. At this same screen you may also specify the LDAP server to connect to.  ***NOTE:***  If you deployed RH IDM/LDAP with this repo's provisioner then it's using self-signed certificates which means you need to stuff them into the JRE keystore.  I fucking hate Java...

### Setting up LDAP - Stuffing Certificates
The easiest way to do this is to call the ```ss-ca-stuffer.sh``` script with a host that you'd like to pull the cert from, such as the following:

```
$ oc exec cjoc-0 -- curl -L -sS -o /var/jenkins_home/ss-ca-stuffer.sh 
$ oc exec cjoc-0 -- /var/jenkins_home/ss-ca-stuffer.sh idm.example.com:636
```

That will copy over the script and run a few commands that'll pull it into your CJOC JRE keystore.