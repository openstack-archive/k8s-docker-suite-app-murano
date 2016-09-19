#!/bin/bash

# $1 - IP

# TODO(asilenlov): we need to refactor this script

# Install Calico on worker
mkdir -p /opt/cni/bin
cp /opt/copy/cni/bin/* /opt/cni/bin
ln -s /opt/bin/calicoctl /usr/bin/calicoctl
docker load < /opt/copy/calico-node.tar

sed -i.bak "s/%%MASTER_IP%%/$1/g" environ/network-environment
sed -i.bak "s/%%IP%%/$1/g" environ/network-environment
cp -f environ/network-environment /etc

sed -i.bak "s/%%IP%%/$1/g" systemd/calico-node.service
cp -f systemd/calico-node.service /etc/systemd/system/
systemctl enable calico-node.service

mkdir -p /etc/cni/net.d
sed -i.bak "s/%%MASTER_IP%%/$1/g" 10-calico.conf
cp -f 10-calico.conf /etc/cni/net.d

systemctl start calico-node