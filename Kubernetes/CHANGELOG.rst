Release Notes
=============

V1.0.0 - 9/23/2016
------------------
* Added support for Calico Networking by default
* Added Rolling updates support for Kubernetes applications
* Added Kubernetes binaries for Debian image
* Changed Kubernetes configuration to support Kubernetes v1.3
* Changed support for Flannel Networking to be disabled by default
* Changed Readme with Calico networking information
* Changed Readme with rolling update support and usage information
* Changed Readme with how to interact with kubernetes cluster deployed by
murano
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
