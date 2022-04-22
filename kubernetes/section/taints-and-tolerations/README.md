### Configure Taints and Tolerations

We use a taint to prevent pods from being scheduled to the master node or worker node, unless those pods tolerate this taint. The pods that tolerate it are usually system pods.

Suppose you have a cluster with 2 master nodes and 2 worker nodes:

```
vagrant@master-1:~$ kubectl get nodes
NAME       STATUS   ROLES                  AGE   VERSION
master-1   Ready    control-plane,master   16d   v1.23.0
master-2   Ready    control-plane,master   16d   v1.23.0
worker-1   Ready    <none>                 16d   v1.23.0
worker-2   Ready    <none>                 16d   v1.23.0
```

In kubernetes cluster, default you can only deploy your pods to the worker nodes (not master nodes), unless the kube-system pods. Because the master nodes have taints, and the kube-system pods tolerates the master nodes's taints.

Let's get taints from master nodes:

```
vagrant@master-1:~$ kubectl describe node master-1
Name:               master-1
Roles:              control-plane,master
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/os=linux
                    kubernetes.io/arch=amd64
                    kubernetes.io/hostname=master-1
                    kubernetes.io/os=linux
                    node-role.kubernetes.io/control-plane=
                    node-role.kubernetes.io/master=
                    node.kubernetes.io/exclude-from-external-load-balancers=
Annotations:        flannel.alpha.coreos.com/backend-data: {"VNI":1,"VtepMAC":"42:7b:34:b8:33:95"}
                    flannel.alpha.coreos.com/backend-type: vxlan
                    flannel.alpha.coreos.com/kube-subnet-manager: true
                    flannel.alpha.coreos.com/public-ip: 10.0.2.15
                    kubeadm.alpha.kubernetes.io/cri-socket: /var/run/dockershim.sock
                    node.alpha.kubernetes.io/ttl: 0
                    volumes.kubernetes.io/controller-managed-attach-detach: true
CreationTimestamp:  Tue, 05 Apr 2022 07:00:15 +0000
Taints:             node-role.kubernetes.io/master:NoSchedule
...
```

The format of Taints is `<key>=<value>:<effect>`. Only the kube-system pods with `Tolerations: node-role.kubernetes.io/master=:NoSchedule` can be scheduled on the master nodes.

Let's describe the kube-system pods:

```
vagrant@master-1:~$ kubectl get po -n kube-system
NAME                               READY   STATUS    RESTARTS         AGE
coredns-64897985d-fppdp            1/1     Running   5 (9m13s ago)    16d
coredns-64897985d-t4mxq            1/1     Running   5 (9m13s ago)    16d
kube-apiserver-master-1            1/1     Running   6 (9m13s ago)    16d
kube-apiserver-master-2            1/1     Running   2 (8m23s ago)    16d
kube-controller-manager-master-1   1/1     Running   8 (5m7s ago)     16d
kube-controller-manager-master-2   1/1     Running   4 (8m23s ago)    16d
kube-flannel-ds-4qtvn              1/1     Running   4 (8m23s ago)    16d
kube-flannel-ds-fxptk              1/1     Running   14 (9m13s ago)   16d
kube-flannel-ds-g68rx              1/1     Running   5 (6m36s ago)    16d
kube-flannel-ds-hkwqd              1/1     Running   4 (4m59s ago)    16d
kube-proxy-7tcjf                   1/1     Running   3 (7m22s ago)    16d
kube-proxy-j22bn                   1/1     Running   3 (8m23s ago)    16d
kube-proxy-wq9hg                   1/1     Running   3 (6m36s ago)    16d
kube-proxy-xsrqt                   1/1     Running   5 (9m13s ago)    16d
kube-scheduler-master-1            1/1     Running   8 (5m10s ago)    16d
kube-scheduler-master-2            1/1     Running   3 (8m23s ago)    16d

vagrant@master-1:~$ kubectl describe pod -n kube-system | grep Tolerations
Tolerations:                 CriticalAddonsOnly op=Exists
Tolerations:                 CriticalAddonsOnly op=Exists
Tolerations:       :NoExecute op=Exists
Tolerations:       :NoExecute op=Exists
Tolerations:       :NoExecute op=Exists
Tolerations:       :NoExecute op=Exists
Tolerations:                 :NoSchedule op=Exists
Tolerations:                 :NoSchedule op=Exists
Tolerations:                 :NoSchedule op=Exists
Tolerations:                 :NoSchedule op=Exists
Tolerations:                 op=Exists
Tolerations:                 op=Exists
Tolerations:                 op=Exists
Tolerations:                 op=Exists
Tolerations:       :NoExecute op=Exists
Tolerations:       :NoExecute op=Exists
```

Each taint has an effect associated with it. Three possible effects exist:

- `NoSchedule`: pods won't be scheduled to the node if they don't tolerate the taint.

- `PreferNoSchedule` is a soft version of `NoSchedule`, meaning the scheduler will try to avoid scheduling the pod to the node, but will schedule it to the node if it can't schedule it somewhere else.

- `NoExecute`, unlike `NoSchedule` and `PreferNoSchedule` that only affect scheduling, also affects pods already running on the node. If you add a `NoExecute` taint to a node, pods that are already running on that node and don't tolerate the `NoExecute` taint will be evicted from the node.

#### Add Taints to Nodes

Imagine having a single Kubernetes cluster where you run both production and development workloads. It's of the utmost importance that development pods never run on the production nodes. This can be achieved by adding a taint to your production nodes.

```
vagrant@master-1:~$ kubectl get nodes
NAME       STATUS   ROLES                  AGE   VERSION
master-1   Ready    control-plane,master   16d   v1.23.0
master-2   Ready    control-plane,master   16d   v1.23.0
worker-1   Ready    <none>                 16d   v1.23.0
worker-2   Ready    <none>                 16d   v1.23.0

vagrant@master-1:~$ kubectl taint node worker-1 node-type=production:NoSchedule
node/worker-1 tainted
```

This adds a taint with key node-type, value production and the `NoSchedule` effect. If you now deploy multiple replicas of a regular pod, you'll see none of them are scheduled to the node you tainted, as shown in the following listing.

```
vagrant@master-1:~$ kubectl create deploy test --image busybox --replicas 5 -- sleep 99999
deployment.apps/test created

vagrant@master-1:~$ kubectl get pods -o wide
NAME                    READY   STATUS    RESTARTS   AGE    IP            NODE       NOMINATED NODE   READINESS GATES
test-5c4f786f47-59hf5   1/1     Running   0          102s   10.244.3.8    worker-2   <none>           <none>
test-5c4f786f47-h6ttk   1/1     Running   0          102s   10.244.3.9    worker-2   <none>           <none>
test-5c4f786f47-jr92r   1/1     Running   0          102s   10.244.3.12   worker-2   <none>           <none>
test-5c4f786f47-qvt4r   1/1     Running   0          102s   10.244.3.10   worker-2   <none>           <none>
test-5c4f786f47-r2r7z   1/1     Running   0          102s   10.244.3.11   worker-2   <none>           <none>
```

To deploy production pods to the production nodes, they need to tolerate the taint you added to the nodes, look like `pod-with-toleration.yaml` file: 

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pod-with-toleration
  labels:
    app: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 5
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
      tolerations:
      - key: node-type
        operator: Equal
        value: production
        effect: NoSchedule
```

```
vagrant@master-1:~$ kubectl apply -f pod-with-tolerations.yaml 
deployment.apps/pod-with-toleration created

vagrant@master-1:~$ kubectl get pods -o wide
NAME                                   READY   STATUS    RESTARTS   AGE    IP            NODE       NOMINATED NODE   READINESS GATES
pod-with-toleration-6c884d5b5b-6bjs4   1/1     Running   0          37s    10.244.3.13   worker-2   <none>           <none>
pod-with-toleration-6c884d5b5b-8zx8q   1/1     Running   0          37s    10.244.2.9    worker-1   <none>           <none>
pod-with-toleration-6c884d5b5b-c6jkl   1/1     Running   0          37s    10.244.2.10   worker-1   <none>           <none>
pod-with-toleration-6c884d5b5b-gb6rn   1/1     Running   0          37s    10.244.2.8    worker-1   <none>           <none>
pod-with-toleration-6c884d5b5b-hhcvf   1/1     Running   0          37s    10.244.3.14   worker-2   <none>           <none>
```

You can also use a toleration to specify how long Kubernetes should wait before rescheduling a pod to another node if the node that the pod is running on becomes unready or unreachable. Let's see the tolerations of one of your pods:

```
vagrant@master-1:~$ kubectl get pod pod-with-toleration-6c884d5b5b-hhcvf -o yaml
apiVersion: v1
kind: Pod
...
spec:
  ...
  tolerations:
  - effect: NoSchedule
    key: node-type
    operator: Equal
    value: production
  - effect: NoExecute
    key: node.kubernetes.io/not-ready
    operator: Exists
    tolerationSeconds: 300
  - effect: NoExecute
    key: node.kubernetes.io/unreachable
    operator: Exists
    tolerationSeconds: 300
...
```

These tolerations say that this pod tolerates a node being `notReady` or `unreachable` for `300` seconds. The Kubernetes Control Plane, when it detects that a node is no longer ready or no longer reachable, will wait for `300` seconds before it deletes the pod and reschedules it to another node.

Finally, remove taints from node:

```
vagrant@master-1:~$ kubectl taint node worker-1 node-type=production:NoSchedule-
node/worker-1 untainted
```