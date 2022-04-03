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
sshpass -p vagrant ssh vagrant@192.168.56.13
sshpass -p vagrant ssh vagrant@192.168.56.14
```

### Create cluster kubernetes

Step 1: Build environment by apt dependencies and config for master and worker node

```sh
ansible-playbook -i hosts build-env-cluster.yml
```

Step 2: Build load balancer

```sh
ansible-playbook -i hosts build-load-balancer.yml
```

Step 3: Build master and worker node

```sh
ansible-playbook -i hosts build-master-and-worker.yml
```

Step 4: Explore cluster

```sh
sshpass -p vagrant ssh vagrant@192.168.56.10
kubectl get nodes
kubectl get po -n kube-system -o wide
```

```
NAME       STATUS   ROLES                  AGE   VERSION
master-1   Ready    control-plane,master   32m   v1.23.0
master-2   Ready    control-plane,master   31m   v1.23.0
worker-1   Ready    <none>                 30m   v1.23.0
worker-2   Ready    <none>                 30m   v1.23.0

NAME                               READY   STATUS    RESTARTS      AGE   IP              NODE       NOMINATED NODE   READINESS GATES
coredns-64897985d-2nwxr            1/1     Running   0             32m   10.244.0.3      master-1   <none>           <none>
coredns-64897985d-gnh4h            1/1     Running   0             32m   10.244.0.2      master-1   <none>           <none>
etcd-master-1                      1/1     Running   3             33m   192.168.56.10   master-1   <none>           <none>
etcd-master-2                      1/1     Running   0             31m   192.168.56.11   master-2   <none>           <none>
kube-apiserver-master-1            1/1     Running   3             33m   192.168.56.10   master-1   <none>           <none>
kube-apiserver-master-2            1/1     Running   0             31m   192.168.56.11   master-2   <none>           <none>
kube-controller-manager-master-1   1/1     Running   4 (31m ago)   33m   192.168.56.10   master-1   <none>           <none>
kube-controller-manager-master-2   1/1     Running   0             31m   192.168.56.11   master-2   <none>           <none>
kube-flannel-ds-2mjsv              1/1     Running   0             30m   192.168.56.12   worker-1   <none>           <none>
kube-flannel-ds-cmmf8              1/1     Running   0             32m   192.168.56.10   master-1   <none>           <none>
kube-flannel-ds-kqrd6              1/1     Running   0             30m   192.168.56.13   worker-2   <none>           <none>
kube-flannel-ds-r4kcz              1/1     Running   0             31m   192.168.56.11   master-2   <none>           <none>
kube-proxy-h4fh5                   1/1     Running   0             32m   192.168.56.10   master-1   <none>           <none>
kube-proxy-mdfm7                   1/1     Running   0             30m   192.168.56.12   worker-1   <none>           <none>
kube-proxy-wsr69                   1/1     Running   0             31m   192.168.56.11   master-2   <none>           <none>
kube-proxy-zkhpf                   1/1     Running   0             30m   192.168.56.13   worker-2   <none>           <none>
kube-scheduler-master-1            1/1     Running   4 (31m ago)   33m   192.168.56.10   master-1   <none>           <none>
kube-scheduler-master-2            1/1     Running   0             31m   192.168.56.11   master-2   <none>           <none>
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
  replicas: 4
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
kubectl get pods -o wide
```

```
NAME                               READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES
nginx-deployment-8d545c96d-6r4vr   1/1     Running   0          41s   10.244.3.2   worker-1   <none>           <none>
nginx-deployment-8d545c96d-jftnn   1/1     Running   0          41s   10.244.2.3   worker-2   <none>           <none>
nginx-deployment-8d545c96d-vll4h   1/1     Running   0          41s   10.244.2.2   worker-2   <none>           <none>
nginx-deployment-8d545c96d-x5m5g   1/1     Running   0          41s   10.244.3.3   worker-1   <none>           <none>
```

- Access application from external service: `curl <workerIP>:<nodePort>`

```sh
curl http://192.168.56.12:32000
curl http://192.168.56.13:32000
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
