Murano deployed Kubernetes Cluster application
==============================================

Packages in this folder are required to deploy both Google Kubernetes and
applications on top of it.

Contents of each folder need to be zipped and uploaded to Murano Catalog.

You will also need to build a proper image for Kubernetes.
This can be done using `diskimage-builder <https://git.openstack.org/cgit/openstack/diskimage-builder>`_
and `DIB elements
<https://git.openstack.org/cgit/openstack/murano/tree/contrib/elements/kubernetes>`_.
The image has to be named *debian8-x64-kubernetes.qcow2*


Overview of Kubernetes
----------------------

Kubernetes is an open-source container manager by Google. It is responsible to
schedule, run and manage docker containers into its own clustered setup.

Kubernetes consists of one or more master nodes running Kubernetes API and
one or more worker nodes (aka minions) that are used to schedule containers.
Containers are aggregated into pods. All containers in single pod are
guaranteed to be scheduled to a single node and share common port space.
Thus it can be considered as a container co-location.

Pods can be replicated. This is achieved by creation of Replication Controller
which creates and maintain fixed number of pod clones. In Murano replica
count is a property of KubernetesPod.

For a more in-depth review of Kubernetes please refer to official
`documentation <http://kubernetes.io/v1.1/docs/user-guide/README.html>`_.

Features
========

Murano deployed Kubernetes Cluster supports following features:

* Networking_: Calico
* `Container Runtime`_: Docker
* `Rolling Updates`_ of Kubernetes application
* Publishing services:  ClusterIP Type

.. _Networking:

Networking
----------

Kubernetes Cluster deployed by Murano supports Calico networking by default.
Support for Flannel is disabled by default, but can be enabled as an option.


.. _Container runtime:

Container runtime
-----------------

A container runtime responsible for pulling container images from a registry,
unpacking the container and running the application. Kubernetes by default
supports Docker runtime. Recently in Kubernetes version 1.3 support for rkt
runtime has been added. More runtimes planned to be added in the future.

Kubernetes Cluster deployed by Murano currently supports only Docker runtime.
Though we planning to add rkt runtime in close future.


.. _Rolling Updates:

Rolling Updates of Kubernetes application
-----------------------------------------

Kubernetes Cluster deployed by Murano supports rolling updates with the use of
“Deployments” and “Replication Controllers (RC)” abstractions. Rolling updates
using  Deployments is a recommended way to perform updates.
Rolling update via Deployments provides following benefits over RC:

* Declarative way to control how service updates are performed
* Rollback to an earlier Deployment version
* Pause and resume a Deployment.

To use Rolling updates via Deployments refer to `Kubernetes documentation <http://kubernetes.io/docs/user-guide/deployments/#updating-a-deployment>`_.

**NOTE:** Currently all applications deployed from Apps Catalog has been created as
Replication Controllers (RC). It means that  Rolling updates via Deployments
are not available for those applications.

In case application running as Replication Controllers (RC) and requires update,
please refer to Kubernetes documentation `here <http://kubernetes.io/docs/user-guide/rolling-updates>`_.


Interacting with Kubernetes Cluster deployed by Murano
======================================================

There are several ways to create, manage applications on Kubernetes cluster:

Using Murano->Apps Catalog-> Environments view in Horizon:
----------------------------------------------------------
Users can perform following actions:

* Deploy/Destroy Kubernetes Cluster
* Perform Kubernetes Cluster related actions such as scale Nodes and Gateways.
* Perform Kubernetes Pod related actions such as scale, recreate pods or restart Containers.
* Deploy selected Application from Apps Catalog via Murano Dashboard.
* Deploy any docker image from Docker Hub using Docker Container apps from Apps Catalog.

Using kubectl CLI:
------------------

Deploy and manage applications using Kubernetes command-line tool - ``kubectl``
from you laptop or any local environment:

 *  * `Download and install <http://kubernetes.io/docs/getting-started-guides/minikube/#install-kubectl>`_ the ``kubectl`` executable based on OS of the choice.
 * Configure kubectl context on local env:

  * ``kubectl config set-cluster kubernetes --server=http://<kube1-floating_IP>:8080``
  * ``kubectl config set-context kubelet-context --cluster=kubernetes --user=""``
  * ``kubectl config use-context kubelet-context``

 * Verify kubectl Configuration and Connection:

  * ``kubectl config view``
  * ``kubectl get nodes``

The resulting kubeconfig file will be stored in ~/.kube/config. Can be sourced at any time after.

Additionally, it is possible to access ``kubectl cli`` from Master Node (kube-1),
where ```kubectl cli``` is installed and configured by default.

**NOTE:** In case application has been deployed via kubectl it will be exposed
automatically outside based on the port information provided in service yaml file.
However, it will be required to manually add required port to the OpenStack Security
Groups  created for this Cluster in order to be able reach application from outside.


How murano installs Kubernetes
------------------------------

Currently Murano supports setups with only single API node and at least one
worker node. API node cannot be used as a worker node.

To establish required network connectivity model for the Kubernetes Murano
sets up an overlay network between Kubernetes nodes using Flannel networking.
See `flannel <https://github.com/coreos/flannel>`_ for more information.

Because IP addresses of containers are in that internal network and not
accessible from outside in order to provide public endpoints Murano sets up
a third type of nodes: Gateway nodes.

Gateway nodes are connected to both Flannel and OpenStack Neutron networks
and serves as a gateway between them. Each gateway node runs HAProxy.
When an application deploys all its public endpoints are automatically registered
on all gateway nodes. Thus if user chose to have more than one gateway
it will usually get several endpoints for the application. Then those endpoints
can be registered in physical load balancer or DNS.


KubernetesCluster
=================

This is the main application representing Kubernetes Cluster.
It is responsible for deployment of the Kubernetes and its nodes.

The procedure is:

#. Create VMs for all node types - 1 for Kubernetes API and requested number
   for worker and gateway nodes.
#. Join them into etcd cluster. etcd is a distributed key-value storage
   used by the Kubernetes to store and synchronize cluster state.
#. Setup Flannel network over etcd cluster. Flannel uses etcd to track
   network and nodes.
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

    Call `restartContainers($podName)` on each minion node.

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
    Set up the node, by first setting up Flannel and
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
    Set up the node. This includes setting up Flannel for master and
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
    Set up the node, by first setting up Flannel and
    then joining the minion into the cluster. If `dockerRegistry` or
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
