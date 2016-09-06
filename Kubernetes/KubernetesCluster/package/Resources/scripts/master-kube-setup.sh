#!/bin/bash

# $1 - NAME
# $2 - IP

# Generate certs
sed -i.bak "s/%%MASTER_IP%%/$2/g" certs/openssl_master.cnf
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

# Install Calico on master 
cp /opt/copy/cni/bin/* /usr/bin
docker load /opt/copy/calico-node.tar

sed -i.bak "s/%%MASTER_IP%%/$2/g" /opt/copy/network-environment
sed -i.bak "s/%%IP%%/$2/g" /opt/copy/network-environment
cp -f /opt/copy/network-environment /etc

sed -i.bak "s/%%MASTER_IP%%/$2/g" systemd/calico-node.service
cp -f systemd/calico-node.service /etc/systemd/system/
systemctl enable calico-node.service

#Create log folder for Kubernetes services
mkdir -p /var/run/murano-kubernetes

if [[ $(which systemctl) ]]; then
  systemctl stop kube*
  sed -i.bak "s/%%MASTER_IP%%/$2/g" environ/kube-config

  mkdir -p /etc/kubernetes/

  cp -f environ/apiserver /etc/kubernetes/apiserver
  cp -f environ/kube-config /etc/kubernetes/config

  cp -f systemd/kube-apiserver.service /etc/systemd/system/
  cp -f systemd/kube-scheduler.service /etc/systemd/system/
  cp -f systemd/kube-controller-manager.service /etc/systemd/system/

  systemctl daemon-reload

  systemctl enable kube-apiserver
  systemctl enable kube-scheduler
  systemctl enable kube-controller-manager

  systemctl start kube-apiserver
  systemctl start kube-scheduler
  systemctl start kube-controller-manager

else
  service kube-proxy stop
  service kube-scheduler stop
  service kube-controller-manager stop
  service kubelet stop
  service kube-apiserver stop

  #Disable controller-manager for now
  #chmod -x /etc/init.d/kube-controller-manager

  sed -i.bak "s/%%MASTER_IP%%/$2/g" default_scripts/kube-scheduler

  cp -f default_scripts/kube-apiserver /etc/default/
  cp -f default_scripts/kube-scheduler /etc/default/
  cp -f default_scripts/kube-controller-manager /etc/default/

  cp init_conf/kube-apiserver.conf /etc/init/
  cp init_conf/kube-controller-manager.conf /etc/init/
  cp init_conf/kube-scheduler.conf /etc/init/

  chmod +x initd_scripts/*
  cp initd_scripts/kube-apiserver /etc/init.d/
  cp initd_scripts/kube-controller-manager /etc/init.d/
  cp initd_scripts/kube-scheduler /etc/init.d/

  service kube-apiserver start
  service kube-scheduler start
  service kube-controller-manager start
fi

mkdir /var/log/kubernetes
/opt/bin/kubectl delete node 127.0.0.1
sleep 1