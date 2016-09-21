
Dashboard UI
------------

Dashboard (the web-based user interface for Kubernetes) allows to deploy
containerized applications to a Kubernetes cluster, troubleshoot them, and
manage the cluster and its resources itself. It can be used to overview
of applications running on the cluster, as well as for creating or modifying
individual Kubernetes resources and workloads, such as Deployments, Daemonsets,
Replica sets, Jobs, Replication controllers, corresponding Services and Pods.

Using Kubernetes Dashboard:
---------------------------

URL to access Dashboard provided after Kubernetes Cluster Deployment in the format:

 * `http://<gateway-1-IP>:5050`

**NOTE**: In case application has been deployed via Dashboard it will be exposed
automatically outside based on the port information provided in service yaml file.
However, it will be required to manually add required port to the OpenStack Security
Groups  created for this Cluster in order to be able reach application from outside.