#!/bin/bash

# $1 - IP

# Generate certs
sed -i.bak "s/%%IP%%/$1/g" certs/openssl_worker.cnf
cp -f certs/openssl_worker.cnf /tmp/openssl_worker.cnf
# Generate keys.
openssl genrsa -out worker-key.pem 2048
openssl req -new -key worker-key.pem -out worker.csr -subj "/CN=worker-key" -config /tmp/openssl_worker.cnf
openssl x509 -req -in worker.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out worker.pem -days 365 -extensions v3_req -extfile /tmp/openssl_worker.cnf
# Move certs to proper location
sudo mkdir -p /etc/kubernetes/ssl/
sudo mv -t /etc/kubernetes/ssl/ ca.pem worker.pem worker-key.pem
# Set permissions
sudo chmod 600 /etc/kubernetes/ssl/worker-key.pem
sudo chown root:root /etc/kubernetes/ssl/worker-key.pem