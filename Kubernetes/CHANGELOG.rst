Release Notes
=============

V1.0.0 - 9/22/2016
------------------

* Added KubeDNS Addon v1.7
* Added support for Calico Networking by default
* Added  Rolling updates support for Kubernetes applications
* Changed Kubernetes configuration to support Kubernetes v1.3
* Changed Kubernetes binaries for Debian image
* Changed support for Flannel Networking to be disabled by default
* Changed Readme with Calico networking information
* Changed Readme with KubeDNS addons information
* Changed Readme with rolling update support and usage information
* Changed Readme with how to interact with kubernetes cluster deployed by
murano
* Deprecated portal_net from api server configurations
* Fixed  service naming for applications deployed with Murano apps
* Known issues:

  * DNS limitations: https://github.com/kubernetes/kubernetes/issues/19634

V0.1.0
------

* Initial changes