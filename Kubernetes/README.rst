Murano-deployed Kubernetes Cluster application
==============================================

The Packages in this folder are required to deploy both Google Kubernetes and
the applications that run on top of it.

The contents of each folder need to be zipped and uploaded to the Murano Catalog.

You will also need to build a proper image for Kubernetes.
This can be done using `diskimage-builder <https://git.openstack.org/cgit/openstack/diskimage-builder>`_
and `DIB elements
<https://git.openstack.org/cgit/openstack/murano/tree/contrib/elements/kubernetes>`_.
The image has to be named *debian8-x64-kubernetes.qcow2*


Overview of Kubernetes
----------------------

Kubernetes is an open-source platform for automating deployment, scaling, and
operations of application containers across clusters of hosts. 

For a more in-depth review of Kubernetes please refer to the official
`documentation <http://kubernetes.io/v1.1/docs/user-guide/README.html>`_.


How Murano installs/upgrades a Kubernetes Cluster
=================================================

Installation
------------

Minimum requirements for Openstack in order to deploy Kubernetes cluster with Murano:
* Deployed Murano and Heat Openstack Services
* 3 instances of m1.medium flavor (Master Node, Kubernetes Node, Gateway Node)
* 1 Floating IP for Gateway, in case required to expose applications outside
* 2 Floating IPs for Master and Kubernetes Nodes to access kubectl CLI or
troubleshooting

A Kubernetes cluster deployed by Murano provisions 3 types of VMs that can be observed in
the Openstack Horizon Dashboard with this naming convention:

Single **Master Node** (murano-kube-1) - which represents the Kubernetes Control
Plane and runs the API server, Scheduler and Controller Manager. In the current
implementation of Kubernetes Cluster deployed by Murano, the Master Node is not
running in HA mode. Additionally it is not possible to schedule containers
on the Master node.

One or several **Kubernetes Nodes** (murano-kube-2..n) - Kubernetes worker nodes
that are responsible for running actual containers. Each Kubernetes Node runs
the Docker, kubelet and kube-proxy services.

One or several **Gateway nodes** (murano-gateway-1..n) - used as an interconnection
between Kubernetes internal Networking_ and the OpenStack external network
(Neutron-managed). The Gateway node provides the Kubernetes cluster with
external endpoints and allows users and services to reach Kubernetes pods from
the outside. Each gateway node runs confd and HAProxy services. When the end
user deploys an application and exposes it via a service, confd automatically
detects it and adds it to the haproxy configuration. HAProxy will expose
the application via the floating IP of the Gateway node and required port.
If the user choses multiple Gateways, the result will be several endpoints for
the application, which  can be registered in the physical load balancer or DNS.

**ETCD** - Kubernetes uses etcd for key value store as well as for cluster
consensus between different software components. Additionally, if the Kubernetes
cluster is configured to run Calico networking, etcd will be configured to
support Calico configurations. In the current implementation of Kubernetes
Cluster deployed by Murano, the etcd cluster is not running on dedicated nodes.
Instead etcd is running on each node deployed by Murano. For example, if
Kubernetes Cluster deployed by Murano is running in the minimum available
configuration with 3 nodes: Master Node, Kubernetes Node and Gateway, then
etcd will run as a 3 node cluster.


Upgrade
-------

In current implementation of Kubernetes Cluster deployed by Murano it is not
possible to upgrade Kubernetes Cluster from previous version to newer.


Features
========

Murano deployed Kubernetes Cluster supports following features:

* Networking_: Calico by default, Flannel optional
* `Container runtime`_: Docker
* `Rolling updates`_ of the Kubernetes application
* Publishing services:  ClusterIP Type

.. _Networking:

Networking
----------

Kubernetes Cluster deployed by Murano supports Calico networking by default.
Calico provides a highly scalable networking and network policy solution for
connecting Kubernetes pods based on the same IP networking principles as a
layer 3 approach.

Calico Networking deployed by Murano as CNI plugin contains following components:

* **etcd** - distributed key-value store, which ensures Calico can always build
an accurate network, used primerly for data storage and communication
* **Felix**, the Calico worker process, which primarily routes and provides
desired connectivity to and from the workloads on host. As well as provides
the interface to kernels for outgoing endpoint traffic
* **BIRD**, BGP client that exchanges routing information between hosts
* **Confd**, a templating process to auto-generate configuration for BIRD
* **calicoctl**, the command line used to configure and start the Calico service

See `Calico <https://github.com/coreos/flannel>`_ for more information.


Support for Flannel is disabled by default, but can be enabled as an option.
Flannel is simple overlay network that satisfies the Kubernetes requirements.
See `flannel <https://www.projectcalico.org/>`_ for more information.

.. _Container runtime:

Container runtime
-----------------

A container runtime is responsible for pulling container images from a registry,
unpacking the container and running the application. Kubernetes by default
supports the Docker runtime. Recently in Kubernetes version 1.3 support for the
rkt runtime has been added. More runtimes are planned to be added in the future.
The Kubernetes Cluster deployed by Murano currently supports only the Docker
runtime, but we planning to add rkt runtime in close future.


.. _Rolling updates:

Rolling updates of the Kubernetes application
---------------------------------------------

The Kubernetes Cluster deployed by Murano supports rolling updates with the use
of “Deployments” and “Replication Controllers (RC)” abstractions. Rolling updates
using Deployments is the recommended way to perform updates. Rolling update via
Deployments provides following benefits over RC:

* Declarative way to control how service updates are performed
* Rollback to an earlier Deployment version
* Pause and resume a Deployment.

To use Rolling updates via Deployments refer to the `Kubernetes documentation <http://kubernetes.io/docs/user-guide/deployments/#updating-a-deployment>`_.

**NOTE:** Currently all applications deployed from the Apps Catalog have been
created as Replication Controllers (RC), so Rolling updates via Deployments
are not available for those applications.

If an application running as a Replication Controllers (RC) requires an update,
please refer to the Kubernetes documentation `here <http://kubernetes.io/docs/user-guide/rolling-updates>`_.


Interacting with the Kubernetes Cluster deployed by Murano
==========================================================

There are several ways to create and manage applications on Kubernetes cluster:

Using the Murano Environments view in Horizon:
----------------------------------------------------------
Users can perform the following actions:

* Deploy/Destroy the Kubernetes Cluster
* Perform Kubernetes Cluster related actions such as scale Nodes and Gateways.
* Perform Kubernetes Pod related actions such as scale, recreate pods or restart Containers.
* Deploy selected Application from the Apps Catalog via the Murano Dashboard.
* Deploy any docker image from the Docker Hub using Docker Container apps from the Apps Catalog.

Using kubectl CLI:
------------------

You can also deploy and manage applications using the Kubernetes command-line
tool - ``kubectl`` from your laptop or any local environment:

 *  `Download and install <http://kubernetes.io/docs/getting-started-guides/minikube/#install-kubectl>`_ the ``kubectl`` executable based on OS of the choice.
 * Configure kubectl context on the local environments:

  * ``kubectl config set-cluster kubernetes --server=http://<kube1-floating_IP>:8080``
  * ``kubectl config set-context kubelet-context --cluster=kubernetes --user=""``
  * ``kubectl config use-context kubelet-context``

 * Verify kubectl Configuration and Connection:

  * ``kubectl config view``
  * ``kubectl get nodes``

The resulting kubeconfig file will be stored in ~/.kube/config and
can be sourced at any time afterwards.

Additionally, it is possible to access ``kubectl cli`` from Master Node (kube-1),
where ```kubectl cli``` is installed and configured by default.

**NOTE:**  If the application has been deployed using kubectl CLI, it will be
automatically exposed outside based on the port information provided in
service yaml file. However, you will need to manually update the OpenStack
Security Groups configuration with the required port information in order to be
able reach the application from the outside.


KubernetesCluster
=================

This is the main application representing Kubernetes Cluster.
It is responsible for deployment of the Kubernetes and its nodes.

The procedure is:

#. Create VMs for all node types - 1 for Kubernetes API and requested number
   for worker and gateway nodes.
#. Join them into etcd cluster. etcd is a distributed key-value storage
   used by the Kubernetes to store and synchronize cluster state.
#. Setup Networking (Calico or Flannel) over etcd cluster. Networking uses
   etcd to track network and nodes.
#. Configure required services on master node.
#. Configure worker nodes. They will register themselves in master nodes using
   etcd.
#. Setup HAProxy on each gateway node. Configure confd to watch etcd to
   register public ports in HAProxy config file. Each time new Kubernetes
   service is created it regenerates HAProxy config.


Internally KubernetesCluster contains separate classes for all node types.
They all inherit from `KubernetesNode` that defines the common interface
for all nodes. The deployment of each node is split into several methods:
`deployInstance` -> `setupEtcd` -> `setupNode` -> `removeFromCluster` as
described above.


KubernetesPod
=============

KubernetesPod represents a single Kubernetes pod with its containers and
associated volumes. KubernetesPod provides an implementation of
`DockerContainerHost` interface defined in `DockerInterfacesLibrary`.
Thus each pod can be used as a drop-in replacement for regular Docker
host implementation (DockerStandaloneHost).

All pods must have a unique name within single `KubernetesCluster`
(which is selected for each pod).

Thus KubernetesCluster is an aggregation of Docker hosts (pods) which also
handles all inter-pod entities (services, endpoints).

KubernetesPod creates Replication Controllers rather than pods. Replication
Controller with replica count equal to 1 will result in single pod being
created while it is always possible to increase/decrease replica count after
deployment. Replica count is specified using `replicas` input property.

Pods also may have labels to group them (for example into layers etc.)


Kubernetes actions
==================

Both KubernetesCluster and KubernetesPod expose number of actions that can
be used by both user (through the dashboard) and automation systems (through
API) to perform actions on the deployed applications.

See http://docs.openstack.org/developer/murano/draft/appdev-guide/murano_pl.html#murano-actions
and http://docs.openstack.org/developer/murano/specification/index.html#actions-api
for more details on actions API.

KubernetesCluster provides the following actions:

* `scaleNodesUp`: increase the number of worker nodes by 1.
* `scaleNodesDown`: decrease the number of worker nodes by 1.
* `scaleGatewaysUp`: increase the number of gateway nodes by 1.
* `scaleGatewaysDown`: decrease the number of gateway nodes by 1.

KubernetesPod has the following actions:

* `scalePodUp`: increase the number of pod replicas by 1.
* `scalePodDown`: decrease the number of pod replicas by 1.
* `recreatePod`: delete the pod and create the new one from scratch.
* `restartContainers`: restart Docker containers belonging to the pod.


Applications documentation
==========================

Documentation for KubernetesCluster application classes
-------------------------------------------------------

KubernetesCluster
~~~~~~~~~~~~~~~~~
Represents Kubernetes Cluster and is the main class responsible for
deploying both Kubernetes and it's nodes.

`isAvailable()`
    Return whether masterNode.isAvailable() or not.

`deploy()`
    Deploy Kubernetes Cluster.

`getIp()`
    Return IP of the masterNode.

`createPod(definition, isNew)`
    Create new Kubernetes Pod. `definition` is a dict of parameters, defining
    the pod. `isNew` is a boolean parameter, telling if the pod should be
    created or updated.

`createReplicationController(definition, isNew)`
    Create new Replication Controller. `definition` is a dict of parameters,
    definition of the pod. `isNew` is a boolean parameter,
    telling if the pod should be created or updated.

`deleteReplicationController(id)`
    Calls `kubectl delete replicationcontrollers` with given id on master node.

`deletePods(labels)`
    Accepts a dict of `labels` with string-keys and string-values, that would
    be passed to `kubectl delete pod` on master node.

`createService(applicationName, applicationPorts, podId)`
    * `applicationName` a string holding application's name.
    * `applicationPorts` list of instances of
      `com.mirantis.docker.ApplicationPort` class.
    * `podId` a string holding a name of the pod.

    Check each port in applicationPorts and creates or updates it if the port
    differs from what it was before (or did not exist). Calls
    `kubectl replace` or `kubectl create` on master node.

`deleteServices(applicationName, podId)`
    * `applicationName` a string holding application's name,
    * `podId` a string holding a name of the pod.

    Delete all of the services of a given pod, calling
    `kubectl delete service` for each one of them.

`scaleRc(rcName, newSize)`
    * `rnName` string holding the name of the RC
    * `newSize` integer holding the number of replicas.

    Call `kubectl scale rc` on master node, setting number of replicas for a
    given RC.

`scaleNodesUp()`
    Increase the number of nodes by one (`$.nodeCount` up to the
    `len($.minionNodes)`) and call `.deploy()`.
    Can be used as an Action.

`scaleGatewaysUp()`
    Increase the number of gateways by one (`$.gatewayCount` up to the
    `len($.gatewayNodes)`) and call `.deploy()`.
    Can be used as an Action.

`scaleNodesDown()`
    Decrease the number of nodes by one (`$.nodeCount` up to 1)
    and call `.deploy()`.
    Can be used as an Action.

`scaleGatewaysUp()`
    Decrease the number of gateways by one (`$.gatewayCount` up to 1)
    and call `.deploy()`.
    Can be used as an Action.

`restartContainers(podName)`
    * `podName` string holding the name of the pod.

    Call `restartContainers($podName)` on each Kubernetes node.

KubernetesNode
~~~~~~~~~~~~~~
Base class for all Kubernetes nodes.

`getIp(preferFloatingIp)`
    Return IP address of the instance. If preferFloatingIp is False (default)
    return first IP address found. Otherwise give preference to floating IP.

`deployInstance()`
    Call `.deploy()` method of underlying instance.

KubernetesGatewayNode
~~~~~~~~~~~~~~~~~~~~~
Kubernetes Gateway Node. Extends `KubernetesNode` class.
All methods in this class are idempotent. This is achieved by memoizing the
fact that the function has been called.

`deployInstance()`
    Deploy underlying instance.

`setupEtcd()`
    Add current node to etcd config (by calling `etcdctl member add`) on
    master node and start etcd member service on underlying instance.

`setupNode()`
    Set up the node, by first setting up Calico or Flannel and
    then setting up HAProxy load balancer on underlying instance.

`removeFromCluster()`
    Remove current node from etcd cluster and call
    `$.instance.releaseResources()`. Also clear up memoized values for
    `deployInstance`, `setupEtcd`, `setupNode`, allowing you to call these
    functions again.

KubernetesMasterNode
~~~~~~~~~~~~~~~~~~~~
Kubernetes Master Node. Extends `KubernetesNode` class.
Most methods in this class are idempotent. This is achieved by memoizing the
fact that the function has been called.

`deployInstance()`
    Deploy underlying instance.

`setupEtcd()`
    Set up etcd master node config and launch etcd service on master node.

`setupNode()`
    Set up the node. This includes setting up Calico or Flannel for master and
    configuring and launching `kube-apiserver`, `kube-scheduler` and
    `kube-controller-manager` services
    on the underlying instance.

`isAvailable()`
    Return whether underlying instance has been deployed.

KubernetesMinionNode
~~~~~~~~~~~~~~~~~~~~
Kubernetes Minion Node. Extends `KubernetesNode` class.
All methods in this class are idempotent. This is achieved by memoizing the
fact that the function has been called.

`deployInstance()`
    Deploy underlying instance.

`setupEtcd()`
    Add current node to etcd config (by calling `etcdctl member add`) on
    master node and start etcd member service on underlying instance.

`setupNode()`
    Set up the node, by first setting up Calico or Flannel and
    then joining the Kubernetes Nodes into the cluster. If `dockerRegistry` or
    `dockerMirror` are supplied for underlying cluster, those are appended to
    the list of docker parameters. If gcloudKey is supplied for underlying
    cluster, then current node attempts to login to google cloud registry.
    Afterwards restart docker and configure and launch `kubelet` and
    `kube-proxy` services

`removeFromCluster()`
    Remove current node from etcd cluster and call
    `$.instance.releaseResources()`. Also clear up memoized values for
    `deployInstance`, `setupEtcd`, `setupNode`, allowing you to call these
    functions again.

`restartContainers(podName)`
    * `podName` string holding the name of the pod.

    Filter docker containers on the node containing the specified `podName` in
    their names and call `docker restart` command on them.
