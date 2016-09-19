#!/bin/bash

# $1 - NAME
# $2 - IP
# $3 - MASTER_IP

# Install Calico on worker
mkdir -p /opt/cni/bin
cp /opt/copy/cni/bin/* /opt/cni/bin/
ln -s /opt/bin/calicoctl /usr/bin/calicoctl
docker load < /opt/copy/calico-node.tar

sed -i.bak "s/%%MASTER_IP%%/$3/g" /opt/copy/network-environment
sed -i.bak "s/%%IP%%/$2/g" /opt/copy/network-environment
cp -f /opt/copy/network-environment /etc

sed -i.bak "s/%%IP%%/$2/g" systemd/calico-node.service
cp -f systemd/calico-node.service /etc/systemd/system/
systemctl enable calico-node.service
systemctl start calico-node

mkdir -p /etc/cni/net.d
sed -i.bak "s/%%MASTER_IP%%/$3/g" /opt/copy/10-calico.conf
cp -f /opt/copy/10-calico.conf /etc/cni/net.d

mkdir -p /var/run/murano-kubernetes

if [[ $(which systemctl) ]]; then

  sed -i.bak "s/%%MASTER_IP%%/$3/g" environ/kube-config
  sed -i.bak "s/%%MASTER_IP%%/$3/g" environ/kubelet
  sed -i.bak "s/%%IP%%/$2/g" environ/kubelet

  mkdir -p /etc/kubernetes/

  cp -f environ/kubelet /etc/kubernetes/
  cp -f environ/kube-config /etc/kubernetes/config

  cp -f systemd/kube-proxy.service /etc/systemd/system/
  cp -f systemd/kubelet.service /etc/systemd/system/

  systemctl daemon-reload

  systemctl enable kubelet
  systemctl enable kube-proxy

  systemctl start kubelet
  systemctl start kube-proxy

else
  mkdir /var/log/kubernetes

  sed -i.bak "s/%%MASTER_IP%%/$3/g" default_scripts/kube-proxy
  sed -i.bak "s/%%MASTER_IP%%/$3/g" default_scripts/kubelet
  sed -i.bak "s/%%IP%%/$2/g" default_scripts/kubelet

  cp init_conf/kubelet.conf /etc/init/
  cp init_conf/kube-proxy.conf /etc/init/

  chmod +x initd_scripts/*
  cp initd_scripts/kubelet /etc/init.d/
  cp initd_scripts/kube-proxy /etc/init.d/

  cp -f default_scripts/kube-proxy /etc/default
  cp -f default_scripts/kubelet /etc/default/

  service kubelet start
  service kube-proxy start
fi

sleep 1