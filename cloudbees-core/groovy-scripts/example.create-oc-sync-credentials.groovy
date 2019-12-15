import hudson.util.Secret
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.CredentialsProvider.*
import com.cloudbees.plugins.credentials.domains.*
import com.openshift.jenkins.plugins.*
import org.jenkinsci.plugins.kubernetes.credentials.*
import org.jenkinsci.plugins.plaincredentials.impl.*
import io.fabric8.jenkins.openshiftsync.*;


def token = 'REPLACE_ME_WITH_SERVICE_ACCOUNT_TOKEN'

Credentials ocSyncTokenC = (Credentials) new OpenShiftToken(CredentialsScope.GLOBAL, "oc-sync-token", "OpenShift Sync Plugin Token with Service Account Token", Secret.fromString(token))
SystemCredentialsProvider.getInstance().getStore().addCredentials(Domain.global(), ocSyncTokenC)