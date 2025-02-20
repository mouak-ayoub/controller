# Amazon Linux 2023 is used, there is resemblance with CentOS stream

# Install openldap server
sudo yum install openldap-servers openldap-clients
sudo systemctl enable  slapd
sudo systemctl start  slapd

# Configure manager user and create base entry
# generate password for manager to use it after in ldapadd
slappasswd -s your_password

ldapmodify -Y EXTERNAL -H ldapi:/// <<EOF
dn: olcDatabase={2}mdb,cn=config
changetype: modify
add: olcRootPW
olcRootPW: {SSHA}GMyR1y1jv1oEP2UzQufIHnkDsP6XcLZY
EOF

# Create base entry
ldapadd -x -D "cn=Manager,dc=my-domain,dc=com" -W <<EOF
dn: dc=my-domain,dc=com
objectClass: dcObject
objectClass: organization
dc: my-domain
o: My Organization
EOF

# To use posixaccount,inetorgperson,.. schemas we need:
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/misc.ldif

sudo systemctl restart  slapd

##################################################################################################################
# Install phpldapadmin in apache server
sudo yum update -y
sudo yum install -y httpd php php-xml php-mbstring php-ldap
sudo systemctl start httpd
sudo systemctl enable httpd
sudo yum install -y wget
wget https://github.com/leenooks/phpLDAPadmin/archive/refs/heads/master.zip
sudo yum install -y unzip
unzip master.zip
sudo mv phpLDAPadmin-master /var/www/html/phpldapadmin
sudo cp /var/www/html/phpldapadmin/.env.testing /var/www/html/phpldapadmin/.env
# populate env variables in .env
sudo chown -R apache:apache /var/www/html/phpldapadmin
sudo chmod -R 755 /var/www/html/phpldapadmin
sudo chmod -R 775 /var/www/html/phpldapadmin/storage

######  INSTALL COMPOSER
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
sudo composer install --ignore-platform-reqs
# To ignore php version requirements
sudo yes | composer install --ignore-platform-reqs
# Install node Compile assets in webpack.mix.js
sudo yum install -y nodejs npm
sudo npm install
sudo npm run dev

# Rerun this
sudo chown -R apache:apache /var/www/html/phpldapadmin
sudo chmod -R 755 /var/www/html/phpldapadmin
sudo chmod -R 775 /var/www/html/phpldapadmin/storage


cat > /etc/httpd/conf.d/phpldapadmin.conf <<EOF
Alias /phpldapadmin /var/www/html/phpldapadmin/public
<VirtualHost *:80>
  DocumentRoot /var/www/html/phpldapadmin/public
  <Directory /var/www/html/phpldapadmin/public>
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
  </Directory>
</VirtualHost>
EOF
# then you can access the phpldapadmin app with http://ec2-ip:80

# Change the memory limit in /etc/php.ini from 128M to 512M (or more if needed, 128 is not enough)
# Try this command to test
# sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php.ini


# and in .env file
LDAP_port=363
LDAP_SSL=true
LDAP_TLS=false
# To allow selfsigned certificate in phpldapadmin (laravel)
# In /var/www/html/phpldapadmin/config/ldap.php
# add this line in the options array
# LDAP_OPT_X_TLS_REQUIRE_CERT is a predefined constant in PHP see https://www.php.net/manual/en/ldap.constants.php#constant.ldap-opt-x-tls-require-cert
'options' => [
    LDAP_OPT_X_TLS_REQUIRE_CERT => LDAP_OPT_X_TLS_ALLOW, // Allow self-signed certificates
],

reboot
##################################################################################################################

# Configure LDAPS with SSL
# We suppose that the server.crt and server.key are already generated
# The certificate must be also in the /etc/pki/tls/certs directory

sudo cp server.crt /etc/openldap/certs
sudo cp server.key /etc/openldap/certs

sudo ldapmodify -Y EXTERNAL -H ldapi:///  <<EOF
dn: cn=config
changetype: modify
replace: olcTLSCertificateFile
olcTLSCertificateFile: /etc/openldap/certs/server.crt
-
replace: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/openldap/certs/server.key
-
replace: olcTLSVerifyClient
olcTLSVerifyClient: never
EOF
