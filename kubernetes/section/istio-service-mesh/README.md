### Configure Istio for Kubernetes cluster

Step 1: Start minikube cluster

```
$ minikube start
...
Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
```

Step 2: Download istio from https://github.com/istio/istio/releases/ and extracting:

```
$ wget https://github.com/istio/istio/releases/download/1.12.7/istio-1.12.7-linux-amd64.tar.gz

$ tar zvxf istio-1.12.7-linux-amd64.tar.gz
```

Step 3: Checking the binary istio:

```
$ cd istio-1.12.7 && ls
bin  LICENSE  manifests  manifest.yaml  README.md  samples  tools

$ cd bin && ls
istioctl

$ ./istioctl
Istio configuration command line utility for service operators to
debug and diagnose their Istio mesh.

Usage:
  istioctl [command]

Available Commands:
  ...

Flags:
      ...

Additional help topics:
  istioctl options                           Displays istioctl global options

Use "istioctl [command] --help" for more information about a command.
```

If you have not installed istio:

```
$ kubectl get ns
NAME              STATUS   AGE
default           Active   105d
kube-node-lease   Active   105d
kube-public       Active   105d
kube-system       Active   105d

$ kubectl get pods
No resources found in default namespace.
```

Let's install istio service mesh:

```
$ ./istioctl install
This will install the Istio 1.12.7 default profile with ["Istio core" "Istiod" "Ingress gateways"] components into the cluster. Proceed? (y/N) y
✔ Istio core installed                                                                                                                                                  
✔ Istiod installed                                                                                                                                                      
- Processing resources for Ingress gateways. Waiting for Deployment/istio-system/istio-ingressgateway                                                                   
✔ Ingress gateways installed                                                                                                                                            
✔ Installation complete
Making this installation the default for injection and validation.
```

Now listing pods and namespace in kubernetes cluster:

```
$ kubectl get ns
NAME              STATUS   AGE
default           Active   105d
istio-system      Active   18m
kube-node-lease   Active   105d
kube-public       Active   105d
kube-system       Active   105d

$ kubectl get pods -n istio-system 
NAME                                    READY   STATUS    RESTARTS   AGE
istio-ingressgateway-5744ff657c-cbnz9   1/1     Running   0          18m
istiod-76f7bb65df-6w8cn                 1/1     Running   0          18m
```

Run demo microservices system:

```
$ kubectl apply -f kubernetes-manifests.yaml
...
deployment.apps/redis-cart created
service/redis-cart created
deployment.apps/adservice created
service/adservice created

$ kubectl get pods
NAME                                     READY   STATUS    RESTARTS        AGE
adservice-c886fc5f7-wsx8m                1/1     Running   2 (2m27s ago)   8h
cartservice-7fb998789-cnn9d              1/1     Running   5 (41s ago)     8h
checkoutservice-54688c7ccf-hclzz         1/1     Running   1 (6m6s ago)    8h
currencyservice-5677cc98f7-pq7ts         1/1     Running   1 (6m6s ago)    8h
emailservice-6c95fc6fbc-ncm2z            1/1     Running   2 (3m16s ago)   8h
frontend-67bf478cf-7tsx2                 1/1     Running   1 (6m6s ago)    8h
loadgenerator-67b4bfb865-fgpjp           1/1     Running   1 (8h ago)      8h
paymentservice-7dd8c8d7bf-glbdp          1/1     Running   1 (6m6s ago)    8h
productcatalogservice-85f7455fd9-d6m9b   1/1     Running   1 (6m6s ago)    8h
recommendationservice-7dc69f759c-lqfqr   1/1     Running   2 (3m16s ago)   8h
redis-cart-5b569cd47-8v4gd               1/1     Running   1 (6m6s ago)    8h
shippingservice-79b568878f-bjzlj         1/1     Running   2 (41s ago)     8h
```

We can see `1/1` in READY column, means that the pods have deployed without sidecar proxy (istio). Because the istio uses the `nodeAffinity`allows you to tell Kubernetes to schedule pods only to specific subsets of nodes.