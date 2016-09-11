#!/bin/bash

cp -f addons/kubedns-deployment.yaml /etc/kubernetes/addons
cp -f addons/kubedns-svc.yaml /etc/kubernetes/addons

/opt/bin/kubectl create -f /etc/kubernetes/addons/kubedns-deployment.yaml >> /tmp/murano-kube.log
/opt/bin/kubectl create -f /etc/kubernetes/addons/kubedns-svc.yaml >> /tmp/murano-kube.log