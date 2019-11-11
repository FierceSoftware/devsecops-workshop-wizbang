# All-Star Software, a partially owned subsidiary of Prestige World Wide Presents: DevSecOps Workshops

## Featuring:

- The Public Cloud!
- Red Hat Identity Management for LDAP
- Red Hat OpenShift Container Platform
- CloudBees Core
- GitLab
- Sonatype Nexus
- Sonatype IQ Server
- SonarQube
- SysDig
- Rocket.Chat
- Eclipse Che
- 3 Pipeline examples!

## How to Use

1. Start with an OpenShift cluster with Logging/Metrics - this is tested on a cluster deployed via the [Red Hat OpenShift on AWS Quickstart](https://aws.amazon.com/quickstart/architecture/openshift/)
2. Deploy Red Hat Identity Management for LDAP
3. Deploy GitLab
4. Run workshop-ocp-provisioner.sh in order to provision OCP Namespaces, Manifests, and Objects such as CloudBees, Jenkins Agents, and centralized Rocket.Chat, Sonatype Nexus IQ Platform, SonarQube, and Eclipse Che.
5. Do post-config for integrations such as LDAP and Team Masters
6. ???????
7. Hope it works - LUH-KEY CHANZ

## Requirements

### Red Hat OpenShift Container Platform

Quickly, let's get this outta the way:

*"Can you use OKD/Minishift instead of Red Hat OCP?"*

YES!  Though you'll need to make some changes to some image references, if your cluster is running without proper SSL certificates there are additional security bypasses you need to add, so on, and so forth.  It's possible, but would take a bit of tweaking.

Either way, if you're trying to run this as a PoC, baseline Secure Software Factory, or as a workshop then you'll need a properly subscribed Red Hat OpenShift Container Platform cluster running.  Note that the version tested with this deployment is Red Hat OpenShift Container Platform 3.11.

If you need to get a 60 or 90-day trial of Red Hat OpenShift Container Platform, contact [Fierce Software](https://fiercesw.com/request-a-demo) for a demo or trial subscription.

The method we suggest deploying is via the [Red Hat OpenShift on AWS Quickstart](https://aws.amazon.com/quickstart/architecture/openshift/) - the Azure Quickstart has been used and tested as well.  When deploying this quickstart, there are a few things to know:

1. Ensure you have [Cloud Access](https://www.redhat.com/en/technologies/cloud-computing/cloud-access) enabled for your Red Hat OpenShift/RHEL subscriptions or else you'll be double-charged for your RHEL/OpenShift subscriptions by AWS.
2. When using this CloudFormation deployer and Cloud Access, in order to not be double-charged you'll need to specifiy the RHEL AMI - we test with ```ami-0240b09539b9692a0``` which is RHEL 7.6.
3. Don't bother with the Gluster additions...it's never worked.
4. You'll probably want to deploy into a new VPC...it's CloudFormations, what do you expect, a simple clean-up without torching the rest of your environment?
5. You need at least 3 AZs so regions with only 2 are not acceptable.
6. Try to set your App Node count to what you expect to run...you can turn off the nodes once they're launched but the scaling events are failure prone which leaves you playing Wack-a-mole with EC2 nodes, deleting subs from your RH Account, while timing everything properly...
7. To add users, and cluster-admin roles to users, you'll need to SSH into the ```ansible-config``` Bastion host the Cloudformation deployment sets up, and modify the ```/etc/origin/master/htpasswd``` configuration on all 3 Master nodes.

### AWS/Boto/Ansible/OC CLIs

Before starting with most of these workshop provisioners, odds are you'll need some packages installed locally.

#### Boto, Passlib, Ansible Installation

##### OS X
```
$ sudo easy_install pip
$ sudo pip install boto
$ sudo pip install boto3
$ sudo pip install ansible
$ sudo pip install passlib
$ sudo pip install netaddr
```

##### Debian/Ubuntu
```
$ sudo apt-get install -y git python3-boto python3-boto3 python3-passlib python3-netaddr python-netaddr ansible
```

##### CentOS/RHEL 7
```
$ sudo subscription-manager repos \
--enable rhel-7-server-ansible-2.8-rpms \
--enable rhel-7-server-optional-rpms \
--enable rhel-7-server-extras-rpms
$ sudo yum install -y git python-virtualenv ansible
$ virtualenv --system-site-packages ansible
$ source ansible/bin/activate
(ansible) $ pip install boto boto3 netaddr
```

#### OC - OpenShift CLI

Many components in the overall provisioner rely on the OpenShift CLI tool (oc) in order to interact with the OpenShift cluster.
To download the latest OC CLI binaries for your operating system, follow the instructions here:
https://docs.okd.io/latest/cli_reference/get_started_cli.html#installing-the-cli

#### AWS Credential Config

Now that you've got the packages we need to deploy Ansible Playbooks on AWS, we need to set the credentials that will be used in provisioning.  To do so, copy the ```aws_env.sh_example``` file to ```aws_env.sh``` and modify the two variables to set your AWS Access and Secret Keys.  After doing so, load the variables into your session:

```
$ cp aws_env.sh_example aws_env.sh
$ vim aws_env.sh
$ source aws_env.sh
```

## Deploying Red Hat Identity Management (Ansible-based)

Arguably, this is the first thing you should do, after deploying OCP as this deployer needs an existing VPC.

There is a provisioner to deploy Red Hat Identity Management (FreeIPA) in AWS from scratch.

This will take care of provisioning the EC2 instance, setting public AND private Route 53 zones, and even using Let's Encrypt to update the SSL used to serve the web interface.

1. Make sure you have completed the requirements of installing Ansible, Boto, and configured AWS credentials as stated above.
2. Navigate to the ```ansible-playbooks``` directory, copy the ```example_aws-deploy-rh-idm-vars.yaml``` to ```aws-deploy-rh-idm-vars.yaml``` and modify to suit your needs.
3. Run the Playbook

```
$ cd ansible-playbooks/
$ cp example_aws-deploy-rh-idm-vars.yaml aws-deploy-rh-idm-vars.yaml
$ vim aws-deploy-rh-idm-vars.yaml
$ ansible-playbook aws-deploy-rh-idm.yaml
```

NOTE: Currently, there is an issue with how the services listen and AWS's DNS...Private Zone queries respond with the Public IP address of the IDM Server so it is ***VITAL*** to use LDAPS (port 636) and not LDAP (port 389) to keep from screaming your passwords in plain-text across Amazon's network...for a workshop that is alive for only a day it's not a big deal though.

Once complete, you should be able to log into the RH IDM web panel and start integrating it as an LDAP source into the rest of the Secure Software Factory.

For an example of useful LDAP configuration specs, here is what it would look like when provisioned for {idm.}FIERCESW.NETWORK:

- **Realm:** FIERCESW.NETWORK
- **Hostname:** idm.fiercesw.network
- **Port:** 636
- **Protocol::** LDAPS
- **Base DN:** DC=fiercesw,DC=network
- **Binding User DN:** CN=Directory Manager
- **Binding User Pass:** Set in Ansible vars
- **User Base DN:** CN=accounts,DC=fiercesw,DC=network
- **Group Base DN:** CN=groups,CN=accounts,DC=fiercesw,DC=network
- **Username Field/Unique ID Attribute:** uid
- **Email Attribute:** mail
- **Display Name Attribute:** displayname (or cn)

## Deploying GitLab EE (Ansible-based)

Once you have LDAP set up, you can deploy GitLab EE in (ideally) the same VPC as your RH IDM server on AWS.
This provisioner will deploy GitLab, add Let's Encrypt, and configure LDAP all in one go - LDAP can also be disabled and internal default auth provider will be used instead.

If using GitLab EE you may have the deployer also copy over your License file.  You can simple set ```add_gitlab_ee_license``` to ```True``` and then copy your license to ```files/company.gitlab-license``` and it will automatically be copied to the GitLab host and enabled.

Additionally, if you'd like you can also pre-provision each user a series of repositories if you'd like.
In order to pre-provision repositories for users, you'll need to first create a [Personal Access Token in GitHub](https://github.com/settings/tokens).  Then add that token and the list of repositories from GitHub you'd like to clone into each student user, as defined in the vars file ```{example_}aws-deploy-gitlab-vars.yaml```
Currently, the pre-provisioner is disabled because GitLab does not auto-sync users from LDAP until they log in at least once via the WebUI...yes, that means

```
$ cd ansible-playbooks/
$ cp example_aws-deploy-gitlab-vars.yaml aws-deploy-gitlab-vars.yaml
$ vim aws-deploy-gitlab-vars.yaml
$ ansible-playbook aws-deploy-gitlab.yaml
```

Once the provisioner is complete, you can access the Web UI at ```https://gitlab.example.com```.  If you did not set an Admin/Root password in the Ansible Playbook's vars then you must ***IMMEDIATELY*** access the panel and set the Root password.  Otherwise, you can log in with the one set in the vars config YAML.

Now if you set LDAP, you'll notice that you can log in but users aren't listed even if you have GitLab EE and LDAP Sync active.  It's just how GitLab is.
You now need to log into all the student-userNN accounts you have in RH IDM/LDAP via the Web UI in order to manage them.

Once you have logged in as each and every, individual user, all the users listed in the Web UI, you can run the 2nd step of the deployment to pre-provision the workshop repo.

```
$ ansible-playbook aws-deploy-gitlab.yaml --tags "setupRepos"
```

That will run the gitlab-rake command need to copy over the repos into the users' namespace.  Once this is complete you should have a GitLab server with each student user having their own repo imported from GitHub.

## Deploying CloudBees Core on OpenShift with External Jenkins Integration

See the ```cloudbees-core/``` subdirectory for updated deployment methods

## Deploying Shared Workshop Resources

There are a number of resources that are shared across the workshop and they are provisioned in a central OpenShift Project.
In this centrally shared project, you can find Templates deployed to allow workshop users to quickly "order" things such as Eclipse Che, some sample applications and pipelines, and other usefuly resources that can quickly be ordered and provisioned.

The resources available are:

- [Template] Eclipse Che - Single User
- [Template] Demo App & Pipeline #1 - [Embedded OSS Jenkins Demo](https://github.com/kenmoini/demo-app-slide-deck)

To deploy these resources, simply run the following provisioner:

```
$ ./shared-resource-project.provisioner.sh
```

Answer the prompts, and it'll deploy the resources.  Then log into OCP, and you should be able to "Select from Project", navigate to the shared project, and order from its catalog of Templates.

# Tested deployment

- AWS, us-east-1 due to needing 3 AZs
- OpenShift 3.11, AWS Quickstart CloudFormation template

***

### *LEGACY SHIT DON'T LOOK BUT I DON'T WANNA FORGET IN CASE I NEED IT*

### Getting CloudBees Core to play nice with OCP

So the built in OSS Jenkins is magic, but not managable.  The CJOC integration with OpenShift as a Kubernetes platform is
decent at best, let's recreate some of that integrated magic. http://v1.uncontained.io/playbooks/continuous_delivery/external-jenkins-integration.html

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
