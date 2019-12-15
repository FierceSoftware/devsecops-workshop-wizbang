import hudson.util.Secret
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.openshift.jenkins.plugins.OpenShiftTokenCredentials

def token = 'REPLACE_ME_WITH_SERVICE_ACCOUNT_TOKEN'

Credentials ocClientTokenC = (Credentials) new OpenShiftTokenCredentials(CredentialsScope.GLOBAL, "oc-client-token", "OC Client Plugin Secret Text with Service Account Token", Secret.fromString(token))
SystemCredentialsProvider.getInstance().getStore().addCredentials(Domain.global(), ocClientTokenC)