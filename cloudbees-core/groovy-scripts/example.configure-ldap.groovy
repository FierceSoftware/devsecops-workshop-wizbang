import jenkins.*
import hudson.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.domains.*
import hudson.model.*
import jenkins.model.*
import hudson.security.*

def instance = Jenkins.getInstance()

def hudsonRealm = new HudsonPrivateSecurityRealm(false)

String server = 'ldaps://idm.example.com'
String rootDN = 'dc=example,dc=com'
String userSearchBase = 'cn=accounts'
String userSearchFilter = 'uid={0}'
String groupSearchBase = 'cn=groups,cn=accounts'
String groupSearchFilter = ''
String groupMembershipFilter = '(| (member={0}) (uniqueMember={0}) (memberUid={1}))'
String managerDN = 'cn=Directory Manager'
String passcode = 'totallySecurePasscode'
boolean inhibitInferRootDN = false
boolean disableMailAddressResolver = false;

SecurityRealm ldap_realm = new LDAPSecurityRealm(server, rootDN, userSearchBase, userSearchFilter, groupSearchBase, groupSearchFilter, groupMembershipFilter, managerDN, passcode, inhibitInferRootDN, disableMailAddressResolver)

instance.setSecurityRealm(ldap_realm)

instance.save()