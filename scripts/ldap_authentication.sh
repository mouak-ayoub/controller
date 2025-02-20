
sudo yum install -y sssd sssd-tools sssd-ldap openldap-clients authconfig
sudo authselect select sssd with-mkhomedir --force
# put this content  in /etc/sssd/sssd.conf
cat > /etc/sssd/sssd.conf <<EOF
[domain/default]
id_provider = ldap
autofs_provider = ldap
auth_provider = ldap
chpass_provider = ldap
ldap_uri = ldaps://98.81.180.5:636/
ldap_search_base = dc=my-domain,dc=com
ldap_default_bind_dn = cn=Manager,dc=my-domain,dc=com
ldap_default_authtok_type = obfuscated_password
ldap_default_authtok = Some_Place_Holder_For_Now
ldap_id_use_start_tls = False
ldap_tls_reqcert = never
cache_credentials = True

[sssd]
services = nss, pam, autofs
domains = default

[nss]
homedir_substring = /home
EOF
sudo chmod 600 /etc/sssd/sssd.conf
# generate obfuscated password put your cn=Manager,dc=my-domain,dc=com password in the standard input
sss_obfuscate --domain default

sudo systemctl enable sssd oddjobd
sudo systemctl restart sssd oddjobd


# in /etc/ssh/sshd_config add this line or change the no to yes
passwordAuthentication yes

sudo systemctl restart sshd
