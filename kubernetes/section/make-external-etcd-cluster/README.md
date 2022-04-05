### Create kubernetes cluster using kubeadm and ansible from scratch

### Starting Virtual Machine

Step 1: Create master and worker server (--provision flag to run script when startup)

```sh
vagrant up --provision
```

Step 2: Checking connection

```sh
sshpass -p vagrant ssh vagrant@192.168.56.11
sshpass -p vagrant ssh vagrant@192.168.56.12
sshpass -p vagrant ssh vagrant@192.168.56.21
sshpass -p vagrant ssh vagrant@192.168.56.22
sshpass -p vagrant ssh vagrant@192.168.56.15
```

### Generate the certificate

Firstly, install `cfssl`:

```sh
wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64

cd Downloads
chmod +x cfssl*

sudo mv cfssl_linux-amd64 /usr/local/bin/cfssl
sudo mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
sudo mv cfssl-certinfo_linux-amd64 /usr/local/bin/cfssl-certinfo
```

```sh
cd certs
chmod +x gen.sh
./gen.sh
```

```
2022/04/04 13:33:36 [INFO] generating a new CA key and certificate from CSR
2022/04/04 13:33:36 [INFO] generate received request
2022/04/04 13:33:36 [INFO] received CSR
2022/04/04 13:33:36 [INFO] generating key: rsa-2048
2022/04/04 13:33:37 [INFO] encoded CSR
2022/04/04 13:33:37 [INFO] signed certificate with serial number 168845797640225205009115083971177470265899005809
2022/04/04 13:33:37 [INFO] generate received request
2022/04/04 13:33:37 [INFO] received CSR
2022/04/04 13:33:37 [INFO] generating key: rsa-2048
2022/04/04 13:33:37 [INFO] encoded CSR
2022/04/04 13:33:37 [INFO] signed certificate with serial number 445423558377599319684907386638393716430750399638
2022/04/04 13:33:37 [WARNING] This certificate lacks a "hosts" field. This makes it unsuitable for
websites. For more information see the Baseline Requirements for the Issuance and Management
of Publicly-Trusted Certificates, v.1.1.6, from the CA/Browser Forum (https://cabforum.org);
specifically, section 10.2.3 ("Information Requirements").
```

Now we will verify the ca certificate and private key were generated:

```sh
ls -la
```

```
total 40
drwxr-xr-x 3 ph3 ph3 4096 Apr  4 13:33 .
drwxr-xr-x 4 ph3 ph3 4096 Apr  4 13:29 ..
-rw-r--r-- 1 ph3 ph3  997 Apr  4 13:33 ca.csr
-rw------- 1 ph3 ph3 1679 Apr  4 13:33 ca-key.pem
-rw-r--r-- 1 ph3 ph3 1350 Apr  4 13:33 ca.pem
drwxr-xr-x 2 ph3 ph3 4096 Apr  4 12:38 config
-rwxr-xr-x 1 ph3 ph3  235 Apr  4 13:06 gen.sh
-rw-r--r-- 1 ph3 ph3 1249 Apr  4 13:33 server.csr
-rw------- 1 ph3 ph3 1679 Apr  4 13:33 server-key.pem
-rw-r--r-- 1 ph3 ph3 1610 Apr  4 13:33 server.pem
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

Step 3: Build external etcd cluster on master nodes

```sh
ansible-playbook -i hosts build-etcd.yml
```

After finish, you can see the etcd cluster status:

```
TASK [print etcd status cluster] ***************************************************************************************************************************************
ok: [master-1] => {
    "msg": [
        "+------------------+---------+----------+----------------------------+----------------------------+------------+",
        "|        ID        | STATUS  |   NAME   |         PEER ADDRS         |        CLIENT ADDRS        | IS LEARNER |",
        "+------------------+---------+----------+----------------------------+----------------------------+------------+",
        "| 7de60f185c634ebb | started | master-2 | https://192.168.56.12:2380 | https://192.168.56.12:2379 |      false |",
        "| e81c9fc39b7ba9f8 | started | master-1 | https://192.168.56.11:2380 | https://192.168.56.11:2379 |      false |",
        "+------------------+---------+----------+----------------------------+----------------------------+------------+"
    ]
}
ok: [master-2] => {
    "msg": [
        "+------------------+---------+----------+----------------------------+----------------------------+------------+",
        "|        ID        | STATUS  |   NAME   |         PEER ADDRS         |        CLIENT ADDRS        | IS LEARNER |",
        "+------------------+---------+----------+----------------------------+----------------------------+------------+",
        "| 7de60f185c634ebb | started | master-2 | https://192.168.56.12:2380 | https://192.168.56.12:2379 |      false |",
        "| e81c9fc39b7ba9f8 | started | master-1 | https://192.168.56.11:2380 | https://192.168.56.11:2379 |      false |",
        "+------------------+---------+----------+----------------------------+----------------------------+------------+"
    ]
}
```

Step 4: Build master and worker node

```sh
ansible-playbook -i hosts build-master-and-worker.yml
```

Step 5: Verify the cluster

```sh
sshpass -p vagrant ssh vagrant@192.168.56.11
kubectl get nodes
kubectl get po -n kube-system -o wide
```

```
NAME                               READY   STATUS    RESTARTS         AGE     IP              NODE       NOMINATED NODE   READINESS GATES
coredns-64897985d-fppdp            0/1     Running   3                30m     10.244.0.3      master-1   <none>           <none>
coredns-64897985d-t4mxq            0/1     Running   3                30m     10.244.0.2      master-1   <none>           <none>
kube-apiserver-master-1            1/1     Running   4                30m     192.168.56.11   master-1   <none>           <none>
kube-apiserver-master-2            1/1     Running   0                3m11s   192.168.56.12   master-2   <none>           <none>
kube-controller-manager-master-1   1/1     Running   4                30m     192.168.56.11   master-1   <none>           <none>
kube-controller-manager-master-2   1/1     Running   1                25m     192.168.56.12   master-2   <none>           <none>
kube-flannel-ds-4qtvn              1/1     Running   1                25m     192.168.56.12   master-2   <none>           <none>
kube-flannel-ds-fxptk              1/1     Running   12 (3m37s ago)   28m     192.168.56.11   master-1   <none>           <none>
kube-flannel-ds-g68rx              1/1     Running   3                23m     192.168.56.22   worker-2   <none>           <none>
kube-flannel-ds-hkwqd              1/1     Running   1                23m     192.168.56.21   worker-1   <none>           <none>
kube-proxy-7tcjf                   1/1     Running   1                23m     192.168.56.21   worker-1   <none>           <none>
kube-proxy-j22bn                   1/1     Running   1                25m     192.168.56.12   master-2   <none>           <none>
kube-proxy-wq9hg                   1/1     Running   1                23m     192.168.56.22   worker-2   <none>           <none>
kube-proxy-xsrqt                   1/1     Running   3                30m     192.168.56.11   master-1   <none>           <none>
kube-scheduler-master-1            1/1     Running   4                30m     192.168.56.11   master-1   <none>           <none>
kube-scheduler-master-2            1/1     Running   1                25m     192.168.56.12   master-2   <none>           <none>
```

Now we can see the etcd isn't present in the cluster, because it's external.

Step 5: Deploy application

- Access to master node:

```sh
sshpass -p vagrant ssh vagrant@192.168.56.11
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
NAME                                READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES
nginx-deployment-74d589986c-96lkf   1/1     Running   0          40s   10.244.3.3   worker-2   <none>           <none>
nginx-deployment-74d589986c-f8cgh   1/1     Running   0          40s   10.244.2.2   worker-1   <none>           <none>
nginx-deployment-74d589986c-pph6t   1/1     Running   0          40s   10.244.3.2   worker-2   <none>           <none>
nginx-deployment-74d589986c-vzn68   1/1     Running   0          40s   10.244.2.3   worker-1   <none>           <none>
```

- Access application from external service: `curl <workerIP>:<nodePort>`

```sh
curl http://192.168.56.21:32000
curl http://192.168.56.22:32000
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
