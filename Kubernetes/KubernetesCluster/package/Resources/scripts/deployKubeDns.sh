#!/bin/bash

cp -f addons/kubedns-addon.yaml /etc/kubernetes/addons

/opt/bin/kubectl create -f /etc/kubernetes/addons/kubedns-addon.yaml >> /tmp/murano-kube.log