#!/bin/bash

# $1 - IP

sed -i.bak "s/%%MASTER_IP%%/$1/g" addons/kubernetes-dashboard.yaml

cp -f addons/kubernetes-dashboard.yaml /etc/kubernetes/addons

/opt/bin/kubectl create -f /etc/kubernetes/addons/kubernetes-dashboard.yaml >> /tmp/murano-kube.log