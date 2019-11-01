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

1. 