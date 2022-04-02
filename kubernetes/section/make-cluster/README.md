### Create kubernetes cluster using kubeadm and ansible from scratch

### Starting Virtual Machine

Step 1: Create master and worker server (--provision flag to run script when startup)

```sh
vagrant up --provision
```

Step 2: Checking connection

```sh
sshpass -p vagrant ssh vagrant@192.168.56.10
sshpass -p vagrant ssh vagrant@192.168.56.11
sshpass -p vagrant ssh vagrant@192.168.56.12
```

### Create cluster kubernetes

Step 1: Build environment by apt dependencies and config for all server

```sh
ansible-playbook -i hosts build-env.yml
```

Step 2: Build master node

```sh
ansible-playbook -i hosts build-master.yml
```

Step 3: Build worker node

```sh
ansible-playbook -i hosts build-worker.yml
```

Step 4: Explore cluster

```sh
sshpass -p vagrant ssh vagrant@192.168.56.10
kubectl get nodes
kubectl get po -n kube-system

NAME       STATUS   ROLES                  AGE     VERSION
master     Ready    control-plane,master   34m     v1.23.0
worker-1   Ready    <none>                 5m36s   v1.23.0
worker-2   Ready    <none>                 5m48s   v1.23.0

NAME                             READY   STATUS    RESTARTS   AGE
coredns-64897985d-92fhv          1/1     Running   0          34m
coredns-64897985d-kf6bt          1/1     Running   0          34m
etcd-master                      1/1     Running   2          35m
kube-apiserver-master            1/1     Running   2          35m
kube-controller-manager-master   1/1     Running   2          35m
kube-flannel-ds-6pcq5            1/1     Running   0          6m22s
kube-flannel-ds-wfq5l            1/1     Running   0          34m
kube-flannel-ds-xzh2s            1/1     Running   0          6m10s
kube-proxy-9vr5m                 1/1     Running   0          34m
kube-proxy-cbm87                 1/1     Running   0          6m10s
kube-proxy-nj2l5                 1/1     Running   0          6m22s
kube-scheduler-master            1/1     Running   2          35m
```

Step 5: Deploy application

- Access to master node:

```sh
sshpass -p vagrant ssh vagrant@192.168.56.10
```

- Create file `demo-nginx.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 2 
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector: 
    app: nginx
  type: NodePort  
  ports:
    - port: 80
      targetPort: 80
      nodePort: 32000
```

- Create pods:

```sh
kubectl apply -f demo-nginx.yaml
```

- Get pods status:

```sh
kubectl get pods

NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-74d589986c-75xqx   1/1     Running   0          47s
nginx-deployment-74d589986c-lrgq5   1/1     Running   0          47s
```

- Access application from external service: `curl <workerIP>:<nodePort>`

```sh
curl http://192.168.56.11:32000
curl http://192.168.56.12:32000
```

```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
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
