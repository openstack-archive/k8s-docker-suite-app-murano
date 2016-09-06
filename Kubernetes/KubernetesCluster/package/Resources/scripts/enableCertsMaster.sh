#!/bin/bash

# $1 - IP

# Generate certs
sed -i.bak "s/%%MASTER_IP%%/$1/g" certs/openssl_master.cnf
cp -f certs/openssl_master.cnf /tmp/openssl_master.cnf
# Generate the root CA.
openssl genrsa -out ca-key.pem 2048
openssl req -x509 -new -nodes -key ca-key.pem -days 10000 -out ca.pem -subj "/CN=kube-ca"
# Generate the API server keypair.
openssl genrsa -out apiserver-key.pem 2048
openssl req -new -key apiserver-key.pem -out apiserver.csr -subj "/CN=kube-apiserver" -config /tmp/openssl_master.cnf
openssl x509 -req -in apiserver.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out apiserver.pem -days 365 -extensions v3_req -extfile /tmp/openssl_master.cnf
# Move certs to proper location
mkdir -p /etc/kubernetes/ssl
mv -t /etc/kubernetes/ssl/ ca.pem apiserver.pem apiserver-key.pem
chmod 600 /etc/kubernetes/ssl/apiserver-key.pem
chown root:root /etc/kubernetes/ssl/apiserver-key.pem