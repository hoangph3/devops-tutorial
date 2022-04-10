### External access by configure Ingress

Firstly, install nginx ingress:

```sh
minikube addons enable ingress
kubectl get all -n ingress-nginx
```

```
NAME                                            READY   STATUS      RESTARTS   AGE
pod/ingress-nginx-admission-create--1-6rs7v     0/1     Completed   0          14m
pod/ingress-nginx-admission-patch--1-qf2zd      0/1     Completed   1          14m
pod/ingress-nginx-controller-5f66978484-wtpph   1/1     Running     0          14m

NAME                                         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
service/ingress-nginx-controller             NodePort    10.104.234.97    <none>        80:31300/TCP,443:30830/TCP   14m
service/ingress-nginx-controller-admission   ClusterIP   10.109.145.221   <none>        443/TCP                      14m

NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/ingress-nginx-controller   1/1     1            1           14m

NAME                                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/ingress-nginx-controller-5f66978484   1         1         1       14m

NAME                                       COMPLETIONS   DURATION   AGE
job.batch/ingress-nginx-admission-create   1/1           4s         14m
job.batch/ingress-nginx-admission-patch    1/1           5s         14m
```

Create kubia application:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kubia-deployment
  labels:
    app: kubia
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kubia
  template:
    metadata:
      labels:
        app: kubia
    spec:
      containers:
      - name: kubia
        image: luksa/kubia:latest
        ports:
        - containerPort: 8080
          protocol: TCP
---
apiVersion: v1
kind: Service
metadata:
  name: kubia-internal-service
spec:
  # type default is ClusterIP
  selector:
    app: kubia
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
```

```sh
kubectl apply -f kubia.yaml
```

Create ingress for kubia-internal-service:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: kubia-ingress
spec:
  rules:
  - host: kubia.example.com
    http:
      paths:
      - pathType: Prefix
        path: /
        backend:
          service:
            name: kubia-internal-service
            port:
              number: 8080
```

```sh
kubectl apply -f ingress.yaml
```

Now we can list of ingress:

```sh
kubectl get ingress
```

```
NAME            CLASS   HOSTS               ADDRESS     PORTS   AGE
kubia-ingress   nginx   kubia.example.com   localhost   80      94s
```

The ADDRESS is localhost, this is the url that kubernetes control plane is running. In this case is `minikube ip: 192.168.49.2`.

Edit `/etc/hosts` file:

```
127.0.0.1       localhost
127.0.1.1       jump-windows

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters

# k8s
192.168.49.2 kubia.example.com
```

Go to your browser or use `curl`, we can access service through ingress:

```sh
curl kubia.example.com
```

```
You've hit kubia-deployment-7b895464d7-h8448
```