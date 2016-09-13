#!/bin/bash

cp -f addons/kubernetes-dashboard.yaml /etc/kubernetes/addons

/opt/bin/kubectl create -f /etc/kubernetes/addons/kubernetes-dashboard.yaml >> /tmp/murano-kube.log