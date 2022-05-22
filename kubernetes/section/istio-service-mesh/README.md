### Configure Istio for Kubernetes cluster

Firstly, starting your minikube cluster:

```
$ minikube start --memory=8192 --cpus=4
...
Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
```

To build service mesh for kubernetes cluster, we can use istio, let's download istio from https://github.com/istio/istio/releases/ and extracting:

```
$ wget https://github.com/istio/istio/releases/download/1.12.7/istio-1.12.7-linux-amd64.tar.gz

$ tar zvxf istio-1.12.7-linux-amd64.tar.gz
```

Checking the binary istio:

```
$ cd istio-1.12.7 && ls
bin  LICENSE  manifests  manifest.yaml  README.md  samples  tools

$ export PATH=$PWD/bin:$PATH

$ istioctl
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
default           Active   8m47s
kube-node-lease   Active   8m50s
kube-public       Active   8m50s
kube-system       Active   8m50s

$ kubectl get pods
No resources found in default namespace.
```

Let's install istio service mesh:

```
$ istioctl install
This will install the Istio 1.12.7 default profile with ["Istio core" "Istiod" "Ingress gateways"] components into the cluster. Proceed? (y/N) y
✔ Istio core installed
✔ Istiod installed- Processing resources for Ingress gateways. Waiting for Deployment/istio-system/istio-ingressgateway
✔ Ingress gateways installed
✔ Installation complete
Making this installation the default for injection and validation.
```

Now listing pods and namespace in kubernetes cluster:

```
$ kubectl get ns
NAME              STATUS   AGE
default           Active   10m
istio-system      Active   62s
kube-node-lease   Active   10m
kube-public       Active   10m
kube-system       Active   10m

$ kubectl get pods -n istio-system
NAME                                    READY   STATUS    RESTARTS   AGE
istio-ingressgateway-5744ff657c-cb6z2   1/1     Running   0          42s
istiod-76f7bb65df-tcfvj                 1/1     Running   0          66s

$ kubectl get svc -A              
NAMESPACE      NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                                      AGE
default        kubernetes             ClusterIP      10.96.0.1        <none>        443/TCP                                      10m
istio-system   istio-ingressgateway   LoadBalancer   10.111.182.40    <pending>     15021:31549/TCP,80:30496/TCP,443:32456/TCP   61s
istio-system   istiod                 ClusterIP      10.103.110.234   <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP        86s
kube-system    kube-dns               ClusterIP      10.96.0.10       <none>        53/UDP,53/TCP,9153/TCP                       10m
```

We can get a list of the ports available with the istio-ingressgateway service using:

```
$ kubectl get svc istio-ingressgateway -n istio-system
NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                                      AGE
istio-ingressgateway   LoadBalancer   10.111.182.40   <pending>     15021:31549/TCP,80:30496/TCP,443:32456/TCP   10m

$ kubectl describe svc istio-ingressgateway -n istio-system
Name:                     istio-ingressgateway
Namespace:                istio-system
Labels:                   app=istio-ingressgateway
                          install.operator.istio.io/owning-resource=unknown
                          install.operator.istio.io/owning-resource-namespace=istio-system
                          istio=ingressgateway
                          istio.io/rev=default
                          operator.istio.io/component=IngressGateways
                          operator.istio.io/managed=Reconcile
                          operator.istio.io/version=1.12.7
                          release=istio
Annotations:              <none>
Selector:                 app=istio-ingressgateway,istio=ingressgateway
Type:                     LoadBalancer
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.111.182.40
IPs:                      10.111.182.40
Port:                     status-port  15021/TCP
TargetPort:               15021/TCP
NodePort:                 status-port  31549/TCP
Endpoints:                172.17.0.4:15021
Port:                     http2  80/TCP
TargetPort:               8080/TCP
NodePort:                 http2  30496/TCP
Endpoints:                172.17.0.4:8080
Port:                     https  443/TCP
TargetPort:               8443/TCP
NodePort:                 https  32456/TCP
Endpoints:                172.17.0.4:8443
Session Affinity:         None
External Traffic Policy:  Cluster
Events:                   <none>
```

The output here shows that the istio-ingressgateway service is forwarding requests from port `80` to port `30496` (http2).

The load balancer listener is set to listen on HTTP port 80, which is the port for the NGINX web server application used in the virtual service in this example.

Step 1: Create the namespace `my-namespace` and enable automatic proxy sidecar injection.

```
$ kubectl create ns my-namespace
namespace/my-namespace created

$ kubectl label ns my-namespace istio-injection=enabled
namespace/my-namespace labeled

$ kubectl get ns --show-labels
NAME              STATUS   AGE   LABELS
default           Active   60m   kubernetes.io/metadata.name=default
istio-system      Active   51m   kubernetes.io/metadata.name=istio-system
kube-node-lease   Active   60m   kubernetes.io/metadata.name=kube-node-lease
kube-public       Active   60m   kubernetes.io/metadata.name=kube-public
kube-system       Active   60m   kubernetes.io/metadata.name=kube-system
my-namespace      Active   30m   istio-injection=enabled,kubernetes.io/metadata.name=my-namespace
```

Step 2: Create the NGINX deployment and NGINX service by create the manifest file `nginx.yaml`.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: webserver
  name: my-nginx
  namespace: my-namespace
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webserver
  template:
    metadata:
      labels:
        app: webserver
    spec:
      containers:
      - image: nginx
        name: my-nginx
        ports:
        - containerPort: 80 # matched targetPort
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: my-nginx
  name: webserver
  namespace: my-namespace
spec:
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 80 # matched containerPort
  selector:
    app: webserver
  type: ClusterIP
```

```
$ kubectl apply -f nginx.yaml
deployment.apps/my-nginx created
service/webserver created

$ kubectl get deploy,svc,po -n my-namespace
NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/my-nginx   3/3     3            3           19s

NAME                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/webserver   ClusterIP   10.96.221.204   <none>        80/TCP    19s

NAME                            READY   STATUS    RESTARTS   AGE
pod/my-nginx-856fb4777f-7s67q   2/2     Running   0          19s
pod/my-nginx-856fb4777f-8bhj2   2/2     Running   0          19s
pod/my-nginx-856fb4777f-d77fs   2/2     Running   0          19s
```

We can see `2/2` in READY column, means that the pods have deployed with sidecar proxy. To validate this, we describe one of the pods:

```
$ kubectl describe pods my-nginx-856fb4777f-7s67q -n my-namespace
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  46s                default-scheduler  Successfully assigned my-namespace/my-nginx-856fb4777f-7s67q to minikube
  Normal   Pulled     45s                kubelet            Container image "docker.io/istio/proxyv2:1.12.7" already present on machine
  Normal   Created    45s                kubelet            Created container istio-init
  Normal   Started    45s                kubelet            Started container istio-init
  Normal   Pulling    45s                kubelet            Pulling image "nginx"
  Normal   Pulled     41s                kubelet            Successfully pulled image "nginx" in 3.441922626s
  Normal   Created    41s                kubelet            Created container my-nginx
  Normal   Started    41s                kubelet            Started container my-nginx
  Normal   Pulled     41s                kubelet            Container image "docker.io/istio/proxyv2:1.12.7" already present on machine
  Normal   Created    41s                kubelet            Created container istio-proxy
  Normal   Started    41s                kubelet            Started container istio-proxy
  Warning  Unhealthy  38s (x3 over 40s)  kubelet            Readiness probe failed: Get "http://172.17.0.5:15021/healthz/ready": dial tcp 172.17.0.5:15021: connect: connection refused
```

Because my environment does not provide an external load balancer for the ingress gateway, the connection refused to `172.17.0.5:15021`. But don't worry about it, we can access the gateway using the service's node port (`30496`).

Step 3: Create an ingress gateway for the NGINX service by create the manifest file `nginx-gateway.yaml`.

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: my-nginx-gateway
  namespace: my-namespace
spec:
  selector:
    istio: ingressgateway # get from labels when describe istio-ingressgateway service
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
      - "mynginx.example.com"
```

```
$ kubectl apply -f nginx-gateway.yaml
gateway.networking.istio.io/my-nginx-gateway created

$ kubectl get gateways.networking.istio.io -n my-namespace 
NAME               AGE
my-nginx-gateway   14m
```

Step 4: Create a virtual service for the ingress gateway by create the manifest file `nginx-virtualservice.yaml`.

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: my-nginx-virtualservice
  namespace: my-namespace
spec:
  hosts:
  - "mynginx.example.com"
  gateways:
  - my-nginx-gateway
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        port:
          number: 80
        host: webserver # matched .metadata.name in Service
```

```
$ kubectl apply -f nginx-virtualservice.yaml
virtualservice.networking.istio.io/my-nginx-virtualservice created

$ kubectl get virtualservices.networking.istio.io -n my-namespace 
NAME                      GATEWAYS               HOSTS                     AGE
my-nginx-virtualservice   ["my-nginx-gateway"]   ["mynginx.example.com"]   17s
```

To confirm the ingress gateway is serving the application to the load balancer, use:

```
$ minikube ip
192.168.49.2

$ kubectl describe svc istio-ingressgateway -n istio-system | grep http2
Port:                     http2  80/TCP
NodePort:                 http2  30496/TCP

$ curl -I -HHost:mynginx.example.com 192.168.49.2:30496
HTTP/1.1 200 OK
server: istio-envoy
date: Sun, 22 May 2022 13:07:54 GMT
content-type: text/html
content-length: 615
last-modified: Tue, 25 Jan 2022 15:03:52 GMT
etag: "61f01158-267"
accept-ranges: bytes
x-envoy-upstream-service-time: 17
```

