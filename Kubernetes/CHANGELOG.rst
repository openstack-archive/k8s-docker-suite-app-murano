Release Notes
=============

V1.0.0 - 9/23/2016
------------------
* Updated Kubernetes components to:

 * etcd v3.0.9
 * kubernetes v1.4.0-beta
 * flannel v0.5.5
 * Go v1.7.1
 * confd v0.7.1
 * docker v1.12.1
 * calico v0.22.0
 * calico-cni v1.4.2

* Added support for Calico networking by default
* Added rolling updates support for Kubernetes applications
* Added Kubernetes binaries for Debian image
* Changed Kubernetes configuration to support Kubernetes v1.4-beta
* Changed support for Flannel networking to be optional, disabled by default
* Changed Readme with Calico networking information
* Changed Readme with rolling update support and usage information
* Changed Readme with how to interact with kubernetes cluster
* Deprecated Kubernetes binaries for Ubuntu image
* Deprecated portal_net from api server configurations
* Fixed  service naming for applications deployed with Murano apps
* Known issues:

  * Currently Upgrade of Murano deployed Kubernetes Cluster is not supported.
  * Using Calico requires one fix in Heat project.
    This patch can be applied manually for MOS 9.0:
    https://review.openstack.org/#/c/370603/3
    Note: Current fix will be included in MOS 9.1 by default.

V0.1.0
------

* Initial changes
