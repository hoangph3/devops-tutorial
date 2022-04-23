### Node Affinity

The `nodeAffinity` allows you to tell Kubernetes to schedule pods only to specific subsets of nodes. Each pod can define its own `nodeAffinity` rules. These allow you to specify either hard requirements or preferences. By specifying a preference, you tell Kubernetes which nodes you prefer for a specific pod, and Kubernetes will try to schedule the pod to one of those nodes. If that's not possible, it will choose one of the other nodes (the `nodeSelector` is not).

List the nodes in your cluster, along with their labels:

```
vagrant@master-1:~$ kubectl get nodes --show-labels
NAME       STATUS   ROLES                  AGE   VERSION   LABELS
master-1   Ready    control-plane,master   17d   v1.23.0   ...,kubernetes.io/hostname=master-1,...
master-2   Ready    control-plane,master   17d   v1.23.0   ...,kubernetes.io/hostname=master-2,...
worker-1   Ready    <none>                 17d   v1.23.0   ...,kubernetes.io/hostname=worker-1,kubernetes.io/os=linux
worker-2   Ready    <none>                 17d   v1.23.0   ...,kubernetes.io/hostname=worker-2,kubernetes.io/os=linux
```

Chose one of your nodes, and add a label to it:

```
vagrant@master-1:~$ kubectl label nodes worker-1 device=gpu
node/worker-1 labeled

vagrant@master-1:~$ kubectl label nodes worker-2 device=cpu
node/worker-2 labeled

vagrant@master-1:~$ kubectl get nodes --show-labels
NAME       STATUS   ROLES                  AGE   VERSION   LABELS
master-1   Ready    control-plane,master   17d   v1.23.0   ...,kubernetes.io/hostname=master-1,...
master-2   Ready    control-plane,master   17d   v1.23.0   ...,kubernetes.io/hostname=master-2,...
worker-1   Ready    <none>                 17d   v1.23.0   ...,device=gpu,kubernetes.io/hostname=worker-1,kubernetes.io/os=linux
worker-2   Ready    <none>                 17d   v1.23.0   ...,device=cpu,kubernetes.io/hostname=worker-2,kubernetes.io/os=linux
```

Schedule a Pod using required node affinity with `pod-required-node-affinity.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pod-required-node-affinity
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
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: device
                operator: In
                values:
                - gpu
      containers:
      - name: nginx
        image: nginx
```

The `requiredDuringSchedulingIgnoredDuringExecution` means that the pod will get scheduled only on a node that has a `device=gpu` label.

```
vagrant@master-1:~$ kubectl apply -f pod-required-node-affinity.yaml
deployment.apps/pod-required-node-affinity created

vagrant@master-1:~$ kubectl get pods -o wide
NAME                                          READY   STATUS    RESTARTS   AGE     IP            NODE       NOMINATED NODE   READINESS GATES
pod-required-node-affinity-6fbcb8c97c-cvrwv   1/1     Running   0          2m24s   10.244.2.14   worker-1   <none>           <none>
pod-required-node-affinity-6fbcb8c97c-hwhg5   1/1     Running   0          2m24s   10.244.2.17   worker-1   <none>           <none>
pod-required-node-affinity-6fbcb8c97c-kcrc6   1/1     Running   0          2m24s   10.244.2.16   worker-1   <none>           <none>
pod-required-node-affinity-6fbcb8c97c-m82d4   1/1     Running   0          2m24s   10.244.2.18   worker-1   <none>           <none>
pod-required-node-affinity-6fbcb8c97c-qstx5   1/1     Running   0          2m24s   10.244.2.15   worker-1   <none>           <none>
```

Schedule a Pod using preferred node affinity with `pod-preferred-node-affinity.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pod-preferred-node-affinity
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
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 80
            preference:
              matchExpressions:
              - key: device 
                operator: In
                values:
                - gpu
          - weight: 20
            preference:
              matchExpressions:
              - key: device
                operator: In
                values:
                - cpu
      containers:
      - name: nginx
        image: nginx
```

The `preferredDuringSchedulingIgnoredDuringExecution` means the first preference rule (`device=gpu`) is important by setting its weight to 80, whereas the second one is much less important (weight is set to 20 with `device=cpu`).

```
vagrant@master-1:~$ kubectl apply -f pod-preferred-node-affinity.yaml 
deployment.apps/pod-preferred-node-affinity created

vagrant@master-1:~$ kubectl get pods -o wide
NAME                                           READY   STATUS    RESTARTS   AGE   IP            NODE       NOMINATED NODE   READINESS GATES
pod-preferred-node-affinity-66f89c6b4d-59src   1/1     Running   0          36s   10.244.3.27   worker-2   <none>           <none>
pod-preferred-node-affinity-66f89c6b4d-8dlwd   1/1     Running   0          36s   10.244.2.20   worker-1   <none>           <none>
pod-preferred-node-affinity-66f89c6b4d-br4s4   1/1     Running   0          36s   10.244.2.21   worker-1   <none>           <none>
pod-preferred-node-affinity-66f89c6b4d-s5sr9   1/1     Running   0          36s   10.244.2.19   worker-1   <none>           <none>
pod-preferred-node-affinity-66f89c6b4d-zn4b2   1/1     Running   0          36s   10.244.2.22   worker-1   <none>           <none>
```

### Pod Affinity

Inter-pod affinity and anti-affinity allow you to configure that a set of workloads should be co-located in the same defined topology, eg., the same node.

Imagine having a web application and an in-memory cache like redis pod. Having those pods deployed near to each other reduces latency and improves the performance of the app. In Kubernetes, you could use inter-pod affinity and anti-affinity to co-locate the web servers with the cache as much as possible by `podAffinity`.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-cache
spec:
  selector:
    matchLabels:
      app: store
  replicas: 2
  template:
    metadata:
      labels:
        app: store
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - store
            topologyKey: "kubernetes.io/hostname"
      containers:
      - name: redis-server
        image: redis:3.2-alpine
```

In the above example Deployment for the redis cache, the replicas get the label `app=store`. The `podAntiAffinity` rule tells the scheduler to avoid placing multiple replicas with the `app=store` label on a single node. This creates each cache in a separate node. In this case, we have 2 replicas corresponding to 2 worker nodes.

```
vagrant@master-1:~$ kubectl apply -f redis-pod-anti-affinity.yaml 
deployment.apps/redis-cache created

vagrant@master-1:~$ kubectl get pods -o wide
NAME                           READY   STATUS    RESTARTS   AGE   IP            NODE       NOMINATED NODE   READINESS GATES
redis-cache-6b7b79d589-mfkdh   1/1     Running   0          75s   10.244.2.23   worker-1   <none>           <none>
redis-cache-6b7b79d589-vzmlf   1/1     Running   0          74s   10.244.3.28   worker-2   <none>           <none>
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-server
spec:
  selector:
    matchLabels:
      app: web-store
  replicas: 2
  template:
    metadata:
      labels:
        app: web-store
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - web-store
            topologyKey: "kubernetes.io/hostname"
        podAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - store
            topologyKey: "kubernetes.io/hostname"
      containers:
      - name: web-app
        image: nginx:1.16-alpine
```

The above Deployment for the web servers creates replicas with the label `app=web-store`. The `podAffinity` rule tells the scheduler to place each replica on a node that has a Pod with the label `app=store`. The `podAntiAffinity` rule tells the scheduler to avoid placing multiple `app=web-store` servers on a single node.

```
vagrant@master-1:~$ kubectl apply -f webapp-pod-affinity.yaml 
deployment.apps/web-server created

vagrant@master-1:~$ kubectl get pods -o wide
NAME                           READY   STATUS    RESTARTS   AGE     IP            NODE       NOMINATED NODE   READINESS GATES
redis-cache-6b7b79d589-mfkdh   1/1     Running   0          6m21s   10.244.2.23   worker-1   <none>           <none>
redis-cache-6b7b79d589-vzmlf   1/1     Running   0          6m20s   10.244.3.28   worker-2   <none>           <none>
web-server-f6798875f-b5nn2     1/1     Running   0          17s     10.244.2.24   worker-1   <none>           <none>
web-server-f6798875f-s625n     1/1     Running   0          16s     10.244.3.29   worker-2   <none>           <none>
```

Suppose we need scaling the replicas up to `3`, we will get the `Pending` status:

```
vagrant@master-1:~$ kubectl get pods -o wide
NAME                           READY   STATUS    RESTARTS   AGE     IP            NODE       NOMINATED NODE   READINESS GATES
redis-cache-6b7b79d589-gvcdh   1/1     Running   0          2m54s   10.244.3.32   worker-2   <none>           <none>
redis-cache-6b7b79d589-hl44v   0/1     Pending   0          2m24s   <none>        <none>     <none>           <none>
redis-cache-6b7b79d589-pfxlc   1/1     Running   0          2m54s   10.244.2.27   worker-1   <none>           <none>
web-server-f6798875f-2j65x     1/1     Running   0          2m45s   10.244.3.33   worker-2   <none>           <none>
web-server-f6798875f-dp6pj     0/1     Pending   0          2m14s   <none>        <none>     <none>           <none>
web-server-f6798875f-k5595     1/1     Running   0          2m45s   10.244.2.28   worker-1   <none>           <none>
```

Let's describe the `Pending` pod:

```
vagrant@master-1:~$ kubectl describe pod web-server-f6798875f-dp6pj
...
Events:
  Type     Reason            Age                    From               Message
  ----     ------            ----                   ----               -------
  Warning  FailedScheduling  8m51s                  default-scheduler  0/4 nodes are available: 2 node(s) didn't match pod anti-affinity rules, 2 node(s) had taint {node-role.kubernetes.io/master: }, that the pod didn't tolerate.
...
```

My cluster have 4 nodes with 2 master nodes and 2 worker nodes. With `podAntiAffinity`, the scheduler will create each pod in a separate node, we have `3` pods with `replicas: 3` (2 pods on 2 worker nodes, 1 pod on 1 master node). Because the master node have taint, the pod can't be scheduled on it.

### Node Name

