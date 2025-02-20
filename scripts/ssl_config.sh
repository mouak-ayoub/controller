# Generate a private key
openssl genrsa -aes128 2048 > server.key
# Remove the passphrase from the private key
openssl rsa -in server.key -out server.key
# Generate a certificate signing request
openssl req -utf8 -new -key server.key -out server.csr
# Generate a self-signed certificate
openssl x509 -req -in server.csr -signkey server.key -out server.crt -days 365
# Copy the private key and certificate to the appropriate locations
# To trust the certificate, copy it to the /etc/pki/tls/certs directory
sudo cp server.crt /etc/pki/tls/certs
sudo cp server.key /etc/pki/tls/private