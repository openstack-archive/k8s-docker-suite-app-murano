#!/bin/bash

cp -f addons/kube-dns-addon.yaml /etc/kubernetes/addons

/opt/bin/kubectl create -f /etc/kubernetes/addons/kube-dns-addon.yaml >> /tmp/murano-kube.log