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
/mysql/db-config/mysql.conf
[mysqld]
port=3306
socket=/tmp/mysql.sock
key_buffer_size=16M
max_allowed_packet=128M

/mysql/db-config/secure-flag
ThiS_Is_FLagggggggggg_4U@@

/mysql/db-config/test.conf
ThiS_iS_0nLy_f0R_T3st!^^

/mysql/db-secret/secret.file
Sup3r_s3cure_F1agggggggggg!^^
```

Because we omit the items array entirely, every key in the ConfigMap and Secret becomes a file with the same name as the key. So we get 4 files, contain 3 files from ConfigMap and 1 file from Secret.

### Configure as a Volume with items

```sh
kubectl apply -f config-volumes-with-items.yaml
kubectl get pods
kubectl logs -f my-db-5f9585df5f-8fzlc
```

```
configmap/mysql-config created
secret/mysql-secret created
deployment.apps/my-db created

NAME                     READY   STATUS      RESTARTS   AGE
my-db-5f9585df5f-8fzlc   0/1     Completed   0          8s

/mysql/db-config/flag.txt
ThiS_Is_FLagggggggggg_4U@@

/mysql/db-config/test.conf
ThiS_iS_0nLy_f0R_T3st!^^

/mysql/db-secret/flag.txt
Sup3r_s3cure_F1agggggggggg!^^
```

We defined 2 arrays of keys from the ConfigMap (not contain mysql.conf) and 1 array from Secret to create as files, the filename was changed from `key` to `path` (default is `key`).

### Configure Redis

```sh
kubectl apply -f config-redis.yaml
```

```
configmap/example-redis-config created
deployment.apps/my-redis created
service/my-redis-service created
```

```sh
kubectl get svc -o wide
kubectl get pods
```

```
NAME               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE   SELECTOR
kubernetes         ClusterIP   10.96.0.1       <none>        443/TCP          65d   <none>
my-redis-service   NodePort    10.105.172.53   <none>        6379:30100/TCP   35s   app=my-redis

NAME                        READY   STATUS    RESTARTS   AGE
my-redis-6496f6bbf8-nsgjk   1/1     Running   0          40s
```

Access redis server to get config and data:

```sh
kubectl exec -it my-redis-6496f6bbf8-nsgjk -- redis-cli
```

```
127.0.0.1:6379> CONFIG GET maxmemory
1) "maxmemory"
2) "2097152"

127.0.0.1:6379> CONFIG GET maxmemory-policy
1) "maxmemory-policy"
2) "allkeys-lru"

127.0.0.1:6379> keys *
(empty array)
```

Now we will create python script `test_redis.py` to communicate with redis server:

```python
# test_redis.py
import redis

r = redis.Redis(host="192.168.49.2", # host is url that kubernetes control plane is running.
                port="30100",
                db=0)
r.rpush('foo', 'bar')
r.rpush('foo', 'bar2')
```

Note that host argument is the url that kubernetes control plane is running. In this case, we use minikube and the url can find by the command `minikube ip` or `kubectl cluster-info`:

```
Kubernetes control plane is running at https://192.168.49.2:8443
CoreDNS is running at https://192.168.49.2:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

Access redis server to get data after run python script:

```sh
python3 test_redis.py
kubectl exec -it my-redis-6496f6bbf8-nsgjk -- redis-cli
```

```
127.0.0.1:6379> keys *
1) "foo"

127.0.0.1:6379> lrange foo 0 -1
1) "bar"
2) "bar2"
```
