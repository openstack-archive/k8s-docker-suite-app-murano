#!/bin/bash

# $1 - IP

sed -i.bak "s/%%MASTER_IP%%/$1/g" addons/kube-dashboard-addon.yaml

cp -f addons/kube-dashboard-addon.yaml /etc/kubernetes/addons

/opt/bin/kubectl create -f /etc/kubernetes/addons/kube-dashboard-addon.yaml >> /tmp/murano-kube.log