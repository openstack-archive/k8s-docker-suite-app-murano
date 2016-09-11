#!/bin/bash

# $1 - REPLICAS
# $2 - DNS_SERVER_IP

export DNS_REPLICAS=$1 DNS_SERVER_IP=$2 DNS_DOMAIN=kubernetes.local

cp -f addons/kubedns-deployment.yaml /etc/kubernetes/addons
cp -f addons/kubedns-svc.yaml /etc/kubernetes/addons

/opt/bin/kubectl create -f /etc/kubernetes/addons/kubedns-deployment.yaml >> /tmp/murano-kube.log
/opt/bin/kubectl create -f /etc/kubernetes/addons/kubedns-deployment.yaml >> /tmp/murano-kube.log