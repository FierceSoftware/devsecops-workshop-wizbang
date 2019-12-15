import hudson.util.Secret
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*;
import com.cloudbees.plugins.credentials.impl.*
import org.jenkinsci.plugins.plaincredentials.impl.*


def token = 'REPLACE_ME_WITH_SERVICE_ACCOUNT_TOKEN'

Credentials ocGenericTokenC = (Credentials) new StringCredentialsImpl(CredentialsScope.GLOBAL, "oc-generic-token", "Generic OC Secret Text with Service Account Token", Secret.fromString(token))
SystemCredentialsProvider.getInstance().getStore().addCredentials(Domain.global(), ocGenericTokenC)