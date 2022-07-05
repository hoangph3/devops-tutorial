### Manage pod resource by `LimitRange`

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: example
spec:
  limits:
  - type: Pod
    min:
      cpu: 50m
      memory: 5Mi
    max:
      cpu: 1
      memory: 1Gi
  - type: Container
    defaultRequest:
      cpu: 100m
      memory: 10Mi
    default:
      cpu: 200m
      memory: 100Mi
    min:
      cpu: 50m
      memory: 5Mi
    max:
      cpu: 1
      memory: 1Gi
    maxLimitRequestRatio:
      cpu: 4
      memory: 10
  - type: PersistentVolumeClaim
    min:
      storage: 1Gi
    max:
      storage: 10Gi
```

```sh
kubectl apply -f limit-range.yaml
```

Now we try creating a pod that requests more CPU than allowed by the `LimitRange`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: big-pod
spec:
  containers:
  - image: busybox
    args: ["sleep", "9999999"]
    name: main
    resources:
      requests:
        cpu: 2
```

We will get error:

```
$ kubectl apply -f pod-with-big-resource.yaml 
The Pod "big-pod" is invalid: spec.containers[0].resources.requests: Invalid value: "2": must be less than or equal to cpu limit
```

### Manage namespace resource by `ResourceQuota`

Step 1: Create demo namespace

```sh
kubectl create namespace deployment-demo
```

Step 2: Use Resource Quotas

Create `resource-quota.yaml` file:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: mem-cpu-quota
  namespace: deployment-demo
spec:
  hard:
    requests.cpu: "1"
    requests.memory: 2Gi
    limits.cpu: "2"
    limits.memory: 4Gi
```

Apply to create the resource quota for deployment-demo namespace.

```sh
kubectl apply -f resource-quota.yaml
```

Now, let’s describe the deployment-demo namespace

```sh
kubectl describe namespace deployment-demo
```

```
Name:         deployment-demo
Labels:       kubernetes.io/metadata.name=deployment-demo
Annotations:  <none>
Status:       Active

Resource Quotas
  Name:            mem-cpu-quota
  Resource         Used  Hard
  --------         ---   ---
  limits.cpu       0     2
  limits.memory    0     4Gi
  requests.cpu     0     1
  requests.memory  0     2Gi

No LimitRange resource.
```

Step 3: Create the nginx deployment

Following is `my-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: deployment-demo
  labels:
    app: my-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: nginx:1.20
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
        ports:
        - containerPort: 80
      - name: logging-sidecar
        image: busybox:1.28
        command: ['sh', '-c', "while true; do echo sync logs; sleep 20; done"]
        resources:
          requests:
            memory: "32Mi"
            cpu: "125m"
          limits:
            memory: "64Mi"
            cpu: "250m"
```

Apply to create the deployment:

```sh
kubectl apply -f my-deployment.yaml
```

Now, let's describe my deployment in deployment-demo namespace:

```sh
kubectl describe -n deployment-demo deployments.apps my-app
```

```
Name:                   my-app
Namespace:              deployment-demo
CreationTimestamp:      Tue, 05 Apr 2022 23:17:28 -0400
Labels:                 app=my-app
Annotations:            deployment.kubernetes.io/revision: 1
Selector:               app=my-app
Replicas:               1 desired | 1 updated | 1 total | 1 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=my-app
  Containers:
   my-app:
    Image:      nginx:1.20
    Port:       80/TCP
    Host Port:  0/TCP
    Limits:
      cpu:     500m
      memory:  128Mi
    Requests:
      cpu:        250m
      memory:     64Mi
    Environment:  <none>
    Mounts:       <none>
   logging-sidecar:
    Image:      busybox:1.28
    Port:       <none>
    Host Port:  <none>
    Command:
      sh
      -c
      while true; do echo sync logs; sleep 20; done
    Limits:
      cpu:     250m
      memory:  64Mi
    Requests:
      cpu:        125m
      memory:     32Mi
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   my-app-57d67fffc4 (1/1 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  36s   deployment-controller  Scaled up replica set my-app-57d67fffc4 to 1
```

Step 4: Create the service and expose the deployment

```sh
kubectl expose deployment my-app -n deployment-demo --type=NodePort --name=my-service
kubectl get svc -n deployment-demo
```

```
kubectl get svc -n deployment-demo
NAME         TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
my-service   NodePort   10.97.225.53   <none>        80:30991/TCP   20s
```

Now, use the external IP address (`http://<minikube-ip>:<port>`) to access the nginx application:

```sh
curl http://192.168.49.2:30991
```

```
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

The ResourceQuota have many `.spec.hard` properties other:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: object-storage-quota
spec:
  hard:
    pods: 10
    replicationcontrollers: 5
    secrets: 10
    configmaps: 10
    persistentvolumeclaims: 5
    services: 5
    services.loadbalancers: 1
    services.nodeports: 2
    ssd.storageclass.storage.k8s.io/persistentvolumeclaims: 2
    requests.storage: 500Gi
    ssd.storageclass.storage.k8s.io/requests.storage: 300Gi
    standard.storageclass.storage.k8s.io/requests.storage: 1Ti
```