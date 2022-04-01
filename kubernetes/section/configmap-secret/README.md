### Configure all key-value pairs as environment variables

```sh
kubectl apply -f config-env-vars-envFrom.yaml
```

```
configmap/myapp-config created
secret/myapp-secret created
deployment.apps/my-app created
```

```sh
kubectl get pods
```

```
NAME                      READY   STATUS      RESTARTS      AGE
my-app-6594549577-7s7ks   0/1     Completed   3 (32s ago)   60s
```

```sh
kubectl logs -f my-app-6594549577-7s7ks
```

```
KUBERNETES_PORT=tcp://10.96.0.1:443
KUBERNETES_SERVICE_PORT=443
HOSTNAME=my-app-6594549577-7s7ks
SHLVL=1
username=admin
HOME=/root
KUBERNETES_PORT_443_TCP_ADDR=10.96.0.1
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
KUBERNETES_PORT_443_TCP_PORT=443
password=admin
KUBERNETES_PORT_443_TCP_PROTO=tcp
KUBERNETES_PORT_443_TCP=tcp://10.96.0.1:443
KUBERNETES_SERVICE_PORT_HTTPS=443
KUBERNETES_SERVICE_HOST=10.96.0.1
PWD=/
db_host=mysql-service
```

### Configure defined environment variables in the `command` and `args` of a container using the $(VAR_NAME)

```sh
kubectl apply -f config-env-vars-valueFrom.yaml 
```
```
configmap/myapp-config created
secret/myapp-secret created
deployment.apps/my-app created
```

```sh
kubectl get pods
```

```
NAME                      READY   STATUS      RESTARTS   AGE
my-app-6df7cd5d47-dhd2c   0/1     Completed   0          6s
```

```sh
kubectl logs -f my-app-6df7cd5d47-dhd2c
```
```
admin admin mysql-service
```

### Configure as a Volume


```sh
kubectl apply -f config-volumes.yaml
```

```
configmap/mysql-config created
secret/mysql-secret created
deployment.apps/my-db created
```

```sh
kubectl get pods
```

```
NAME                     READY   STATUS              RESTARTS   AGE
my-db-569cdd7c6c-mrshr   0/1     ContainerCreating   0          3s
```      

```sh
kubectl logs -f my-db-569cdd7c6c-mrshr
```

```
[mysqld]
port=3306
socket=/tmp/mysql.sock
key_buffer_size=16M
max_allowed_packet=128M
Sup3r_s3cure_F1agggggggggg!^^ 
```

### Configure Redis
