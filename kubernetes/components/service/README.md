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

### Configure TLS for Ingress

Firstly, we create the RSA private key:

```sh
openssl genrsa -out tls.key 2048
```

Next we will use the RSA private key to generate the certificate:

```sh
openssl req -new -x509 -key tls.key -days 360 -subj "/CN=kubia" -out tls.crt
```

Perform base64 encode for `tls.key` and `tls.crt`, then fill to yaml file:

```sh
cat tls.crt | base64 | tr -d "\n"
cat tls.key | base64 | tr -d "\n"
```

Create `tls-secret.yaml` save secret TLS:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: secret-tls
type: kubernetes.io/tls
data:
  # the data is abbreviated in this example
  tls.crt: |
    LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURBVENDQWVtZ0F3SUJBZ0lVUWw2eitJOUY4MmgwQThjbzUxVmJ5K2Vjay9nd0RRWUpLb1pJaHZjTkFRRUwKQlFBd0VERU9NQXdHQTFVRUF3d0ZhM1ZpYVdFd0hoY05Nakl3TkRFd01UWXlOek0wV2hjTk1qTXdOREExTVRZeQpOek0wV2pBUU1RNHdEQVlEVlFRRERBVnJkV0pwWVRDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDCkFRb0NnZ0VCQU1DNURMa3JXMHhJWkVEUFE4N1RYdlMxU3M3UkJKWk9wZGlTcnlaSTFHb0s4cndZRTZQZ2pwM1MKaUNlQ3FHbWRWNGV1aGhmbjk5WGlEQVFYSjRlS1R5TDlndTdvV2M5ZFg4d25KR0tXSjVnRE8zTzFnUWNjcGRhSwppSWRyUTlyMXBPTkIrSjZnR0t6NUtucXpZK2wvL0NSSDU2M0FuZ1h2TWlvODVWTWNOd3ZOV09nVjBpNlRjSk1kCmE4aWk2YXhLQWcwMjlaWjFRRFFPTVhYR3ZNeFFzRkhUM045ZUthbDFKYlZRL2ZFUy9hOHNNbXFYN01ncE0wdkUKV2xLSzF1TjlzeWYyamtKQzlhd0Fac3hveDQxbjd0WENPdTJ5alVqTlQvWGNyU0hPbUtScXRqL215T096N1Myawp0VE5QckVBVWk1U3FNbjBTbG43UXVjVEdtUVIrdDNrQ0F3RUFBYU5UTUZFd0hRWURWUjBPQkJZRUZMZTYvbERqCmZSNk8yOXptTHlLc3hZQmxmb0FMTUI4R0ExVWRJd1FZTUJhQUZMZTYvbERqZlI2TzI5em1MeUtzeFlCbGZvQUwKTUE4R0ExVWRFd0VCL3dRRk1BTUJBZjh3RFFZSktvWklodmNOQVFFTEJRQURnZ0VCQUgyTDh6S0dLUmZrdkMxNgplbW9ESE1jT0MxOEpiWmIzNG5yRDB0MWlleHp4MHJLNTFVRU5TZlJYK2E4Y3Vma2xFREROc0hUNnRHV2xEYmFECkhPeXRUZDNKcXg5bFJNMG1LK1pXZk1ITGNXQVF2bXZWcUNGa3NDcUhHc3ZTb1Q3WVY0OHBqcytpL1VsZnJPcE8KcmlNYk5tbTdHNkdqLzA4VkluTDdIVUZaQnNLdEovNkJ5WXJrR01LUHoyNjB5aHQ2TDJxaUx1NlRIbUN3eGV1YwpNd1J3bWN1ajlzQmFtL3JQOWJoTHJYcThuSUxCSUlEZmlIWE5zYXBnL1I0WGVlcDZaaG8yUDJlSmlHRE1udHRDCkVyVUtnT29IOWdHZmlrR2FiWHNQK0c2dkFFZk1FQXR3L09wVmZHTHNSZnZ1U1RQT0JTVXdkaThvcldUTDFvOVAKMVFjSVRVTT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
  tls.key: |
    LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFcFFJQkFBS0NBUUVBd0xrTXVTdGJURWhrUU05RHp0TmU5TFZLenRFRWxrNmwySkt2SmtqVWFncnl2QmdUCm8rQ09uZEtJSjRLb2FaMVhoNjZHRitmMzFlSU1CQmNuaDRwUEl2MkM3dWhaejExZnpDY2tZcFlubUFNN2M3V0IKQnh5bDFvcUloMnREMnZXazQwSDRucUFZclBrcWVyTmo2WC84SkVmbnJjQ2VCZTh5S2p6bFV4dzNDODFZNkJYUwpMcE53a3gxcnlLTHByRW9DRFRiMWxuVkFOQTR4ZGNhOHpGQ3dVZFBjMzE0cHFYVWx0VkQ5OFJMOXJ5d3lhcGZzCnlDa3pTOFJhVW9yVzQzMnpKL2FPUWtMMXJBQm16R2pIaldmdTFjSTY3YktOU00xUDlkeXRJYzZZcEdxMlArYkkKNDdQdExhUzFNMCtzUUJTTGxLb3lmUktXZnRDNXhNYVpCSDYzZVFJREFRQUJBb0lCQURzdkdPY3NsMmIvdkRuaQo3TEh4VzNITzB1QmNkQW9zc09XbmRqNU5rMTNWYXVHMGl5T0NiSW12QTcwT2RPV3FPaDBpelc4OS8zQWhjUXM0CmlSMG9ybERTaFlrVXRhL212dXFWQXFsNzcwRFJqVXBsYlBCZ0xkV0t5WTY4dENQajEvVXFaMDFmWVBTTnVDdmkKTjBhWDFUalhGQ0RaekMyS1hWOTNQLzJiNXBPcXZMRHRiWDhDRkYrcmloYnhGOEk5ZkhmdXBTYzFwQXNYWkNBQQoxRnNXZG83Nmk2YVBuL3ZuRU9kRG1KK09ZN3p5K01hM3E3alF3ajhFMmRkUFdDQkp1UE9yNzEzRGt1TXJUc3RTCjFMRVptWlIzckFJcytxbDI4U0ZVbkdiWHZHZjhSNDBkWnhsNkpzR09hS3d1VjNwck9zN2hUbW9leUhSYlk1V0cKNkV5TXp6a0NnWUVBKzFlSjdoTVR6eFhDVTAxTU5sMjFmYjU1cEpaNm55ZmFPMWI1bUhUR295dndrWEN0NFRUcwovb1plN0tzVUtJZFVmWDZ1OCs0Nms0VzNkZjBwVDZWR2ZHODdwWlBNVVJaMk53SmUzc3FMMnBBNHRzZXQ2N3Q0ClVlaGswdlJYRXRQQXV3SVBlbXhHMXI0Q0FMNFZsMFJOK29UQ1B4YmJrRlRVZ1FsdzUrS29TWU1DZ1lFQXhFdG0KVml4eVluUUZROW0wZk4vWndUZTZVMzZ2S0s3WXF3NHRVelAyejRwQ1RkWEhsREgrWEhtMDR1aFd3dVg0V1hHMwpvNHV5NTFBZmpjS1VJcFVyckgxa3RMWkM4T3RZYzlVY0dUTUZEYzhmNzI0R2dNRXU1c3dYWTJHS1RvbkJOcm8wCktLYmhlTEFpeW9HMGM0OEppS3BtYTYrRVdvSDFNM1EvOS9hWjlsTUNnWUVBMURCeklhcTVibnJRTThOdU0vZW8KNFIrTlVvWTN2MlhGdDVNVjVMK3hjdEFGcU1PWUNDakdhNXJGU01pbG5CR2tJczV3cFQ3WjlQRk9rUzNKVXBRVgpqYmZhZzA3amp4R0hlNmxrcm5JUTM5UWlEUzFHaDEwZGx3aTdGZDF5SlZMZnd3RmFUK0JaYmJHN3Z5UzYxWm0wCnUycVpFdW9aTXlCcXh3VlJiSExONEVFQ2dZRUFuVmhuTnNvNEFrMUg3eVJ5ZGVxbHpTalRsWndsNGJHT0FrZkIKODBEakpXZUpVSVQ5andBb0NZNlJmWldKL242Qy9ZZVhFV1NveXB4Q1BzcnJIWEYvYWF1MTd0bHVmVm5aTkRodQpacENzQzI2dEJhcW5VY3dJd1g1MWZQY3grMVNXNlR5SEZOTDRSMXJBK0p6UnZoTzVLN0NUbXR3OWRxTlhucUFmCnFxOGtxUHNDZ1lFQWcxQng5TksyVVVkZTgyaDZmZmFlWXROVDdXa1RXM2dvandFV2p3WXhzZVBVQ0Q1MWloVUEKYVQ0QVhvaWxsRys1Wnd3Q3Z4V0NYNE1kWTl5SDlVMng5SGhjS1QreCszZnp3NjNPN0g1ampjcHRXYVJhdlZadApsdUlEM1crVnpaL3ZvYnV2WUdScVc5NUhLbThRN2FuU283SzB2TkswUXZzYXJySjZ4c01rcW1FPQotLS0tLUVORCBSU0EgUFJJVkFURSBLRVktLS0tLQo=
```

```sh
kubectl apply -f tls-secret.yaml
```

Now create Ingress with TLS:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-kubia-ingress
spec:
  tls:
  - hosts: 
    - kubia.example.com
    secretName: secret-tls
  rules:
  - host: kubia.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: kubia-internal-service
            port:
              number: 8080
```

```sh
kubectl apply -f tls-ingress.yaml
kubectl get ingress
```

```
NAME                CLASS   HOSTS               ADDRESS     PORTS     AGE
tls-kubia-ingress   nginx   kubia.example.com   localhost   80, 443   17s
```

We can see the PORTS is 80, 443. Let's use HTTPS to access your service through the Ingress: 

```sh
curl -k -v https://kubia.example.com/kubia
```

```
*   Trying 192.168.49.2:443...
* Connected to kubia.example.com (192.168.49.2) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
* ALPN, server accepted to use h2
* Server certificate:
*  subject: O=Acme Co; CN=Kubernetes Ingress Controller Fake Certificate
*  start date: Apr 10 14:38:48 2022 GMT
*  expire date: Apr 10 14:38:48 2023 GMT
*  issuer: O=Acme Co; CN=Kubernetes Ingress Controller Fake Certificate
*  SSL certificate verify result: self signed certificate (18), continuing anyway.
* Using HTTP2, server supports multiplexing
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x560b8745fb10)
> GET /kubia HTTP/2
> Host: kubia.example.com
> user-agent: curl/7.81.0
> accept: */*
> 
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* old SSL session ID is stale, removing
* Connection state changed (MAX_CONCURRENT_STREAMS == 128)!
< HTTP/2 200 
< date: Sun, 10 Apr 2022 16:51:41 GMT
< 
You've hit kubia-deployment-7b895464d7-h8448
* Connection #0 to host kubia.example.com left intact
```

### Configure headless service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kubia-headless
spec:
  selector:
    app: kubia
  clusterIP: None
  ports:
  - port: 80
    targetPort: 8080
```

A headless service is a service with a service IP but instead of load-balancing it will return the IPs of our associated Pods. This allows us to interact directly with the Pods instead of a proxy.

Let's list of service:

```sh
kubectl get service
```

```
NAME                     TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
kubernetes               ClusterIP   10.96.0.1      <none>        443/TCP    73d
kubia-headless           ClusterIP   None           <none>        80/TCP     33m
kubia-internal-service   ClusterIP   10.96.220.32   <none>        8080/TCP   3h1m
```

Because headless service is connected to Pod's IPs without proxy. If we exec to the pod, we can interact with headless service:

```sh
kubectl get pods
```

```
NAME                                READY   STATUS    RESTARTS   AGE
kubia-deployment-7b895464d7-h8448   1/1     Running   0          3h5m
```

```sh
kubectl exec -it kubia-deployment-7b895464d7-h8448 -- bash
```

```
root@kubia-deployment-7b895464d7-h8448:/# curl kubia-headless:8080
You've hit kubia-deployment-7b895464d7-h8448

root@kubia-deployment-7b895464d7-h8448:/# curl kubia-internal-service:8080

```