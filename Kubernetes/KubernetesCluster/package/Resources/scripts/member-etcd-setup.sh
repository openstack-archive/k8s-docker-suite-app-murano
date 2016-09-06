#!/bin/bash -x

# $1 - NAME
# $2 - IP
# $3 - ETCD_INITIAL_CLUSTER

# Install Calico on worker
mkdir -p /opt/cni/bin
cp /opt/copy/cni/bin/* /opt/cni/bin
ln -s /opt/bin/calicoctl /usr/bin/calicoctl
docker load < /opt/copy/calico-node.tar

sed -i.bak "s/%%MASTER_IP%%/$2/g" /opt/copy/network-environment
sed -i.bak "s/%%IP%%/$2/g" /opt/copy/network-environment
cp -f /opt/copy/network-environment /etc

sed -i.bak "s/%%IP%%/$2/g" systemd/calico-node.service
cp -f systemd/calico-node.service /etc/systemd/system/
systemctl enable calico-node.service

mkdir -p /etc/cni/net.d
sed -i.bak "s/%%MASTER_IP%%/$2/g" /opt/copy/10-calico.conf
cp -f /opt/copy/10-calico.conf /etc/cni/net.d

systemctl start calico-node

mkdir /var/lib/etcd

if [[ $(which systemctl) ]]; then
  systemctl stop etcd

  sed -i.bak "s/%%NAME%%/$1/g" environ/etcd
  sed -i.bak "s/%%IP%%/$2/g" environ/etcd
  sed -i.bak "s/%%STATE%%/existing/g" environ/etcd
  sed -i.bak "s#%%CLUSTER_CONFIG%%#$3#g" environ/etcd

  cp -f environ/etcd /etc/default/
  cp -f systemd/etcd.service /etc/systemd/system/

  systemctl daemon-reload
  systemctl enable etcd
  systemctl start etcd

else
  service etcd stop

  sed -i.bak "s/%%NAME%%/$1/g" default_scripts/etcd-member
  sed -i.bak "s/%%IP%%/$2/g" default_scripts/etcd-member
  sed -i.bak "s#%%CLUSTER_CONFIG%%#$3#g" default_scripts/etcd-member

  cp -f default_scripts/etcd-member /etc/default/etcd
  cp init_conf/etcd.conf /etc/init/
  chmod +x initd_scripts/etcd
  cp initd_scripts/etcd /etc/init.d/

  service etcd start
fi

#check if cluster works well after member adding
count=30

echo "Registration member $1 in etcd cluster" >> /tmp/etcd.log
while [ $count -gt 0 ]; do
 /opt/bin/etcdctl cluster-health >> /tmp/etcd.log
 if [ $? -eq 0 ]; then
   echo "Member $1 started" >> /tmp/etcd.log
   sleep 10
   exit 0
 fi
 ((count-- ))
 sleep 5
done
echo "Member $1 is not started" >> /tmp/etcd.log
exit 1