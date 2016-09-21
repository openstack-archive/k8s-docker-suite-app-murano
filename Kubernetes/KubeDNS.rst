DNS in Kubernetes Cluster deployed by Murano
--------------------------------------------

Kubernetes Cluster deployed by Murano offers a Kube-DNS cluster addon, which is
configured and enabled by default. The running Kubernetes Kube-DNS pod holds 3
containers:

* The kubedns container:

  * Watches changes in services and endpoints
  * Maintains in-memory lookup structures to service DNS requests

* The dnsmasq container adds DNS caching to improve performance
* The healthz container performing healthchecks for dnsmasq and kubedns

Additionally, kubelets on each node has been configured to tell individual containers
to use the DNS Service’s IP to resolve DNS names. The DNS server watches the Kubernetes
API for new Services and creates a set of DNS records for each, so that every Service
defined in the cluster will be assigned a DNS name. As a result Pods are able to do
name resolution of Cluster Services automatically.

The Kubernetes cluster DNS server supports: Forward lookups (A records),
Service lookups (SRV records), Reverse IP address lookups (PTR records).

Kube-DNS addon in Kubernetes Cluster has following default settings:

* IP address of DNS server = 10.32.0.10
* Default Domain of DNS server = kubernetes.local

Above settings can be customized, if required.