#!/bin/bash

# $1 - NAME
# $2 - IP
# $3 - MASTER_IP
# $4 - USE_CALICO
# $5 - ENABLE_DNS

mkdir -p /var/run/murano-kubernetes
mkdir -p /etc/kubernetes/

if [[ $(which systemctl) ]]; then

  sed -i.bak "s/%%MASTER_IP%%/$3/g" environ/kube-config
  sed -i.bak "s/%%MASTER_IP%%/$3/g" environ/kubelet
  sed -i.bak "s/%%IP%%/$2/g" environ/kubelet

  if [ "$4" == "False" ]; then
    echo KUBELET_ARGS=\"--network-plugin=cni --network-plugin-dir=/etc/cni/net.d\" >> environ/kubelet
  fi

  if [ "$5" == "True" ]; then
    echo KUBELET_CLUSTER_DNS=\"--cluster-dns=10.32.0.10\" >> environ/kubelet
    echo KUBELET_DNS_DOMAIN=\"--cluster-domain=kubernetes.local\" >> environ/kubelet

    if [ "$4" == "False" ]; then
      echo KUBE_PROXY_ARGS=\"--proxy-mode=iptables --masquerade-all=true\" > /etc/kubernetes/proxy
    fi
  fi

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

sed -i.bak "s/%%MASTER_IP%%/$3/g" kubeconfig.yaml
cp -f kubeconfig.yaml /etc/kubernetes/

sleep 1