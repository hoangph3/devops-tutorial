# Auto rotation of Kubernetes certificates by DaemonSet

1. Run minikube, other-wise you can run a kubernetes cluster:
```sh
minikube start
```

2. Validate the cluster:
```sh
kubectl get pods -A
```
```
NAMESPACE     NAME                               READY   STATUS    RESTARTS      AGE
kube-system   coredns-6d4b75cb6d-n96gg           1/1     Running   0             18m
kube-system   etcd-minikube                      1/1     Running   0             18m
kube-system   kube-apiserver-minikube            1/1     Running   0             18m
kube-system   kube-controller-manager-minikube   1/1     Running   0             18m
kube-system   kube-proxy-r7tkh                   1/1     Running   0             18m
kube-system   kube-scheduler-minikube            1/1     Running   0             18m
kube-system   storage-provisioner                1/1     Running   1 (17m ago)   18m
```

3. Create a symlink in the minikube container:

Firstly, ssh to the minikube container:

```sh
minikube ssh
```
```
docker@minikube:~$
```

In the minikube container, we create a symlink. If you run a kubernetes cluster, you can skip this.
```sh
sudo ln -s /var/lib/minikube/binaries/v1.24.3/kube* /usr/bin/
sudo mkdir -p /etc/kubernetes/pki
sudo ln -s /var/lib/minikube/certs/* /etc/kubernetes/pki/
```


Exit the container:
```sh
<Ctrl> + D
```

4. Check certificate expiration:
```sh
docker exec -it minikube kubeadm certs check-expiration
```
```
[check-expiration] Reading configuration from the cluster...
[check-expiration] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'

CERTIFICATE                EXPIRES                  RESIDUAL TIME   CERTIFICATE AUTHORITY   EXTERNALLY MANAGED
admin.conf                 Jan 13, 2024 17:04 UTC   364d            ca                      no      
apiserver                  Jan 12, 2026 17:04 UTC   2y              ca                      no      
apiserver-etcd-client      Jan 13, 2024 17:04 UTC   364d            etcd-ca                 no      
apiserver-kubelet-client   Jan 13, 2024 17:04 UTC   364d            ca                      no      
controller-manager.conf    Jan 13, 2024 17:04 UTC   364d            ca                      no      
etcd-healthcheck-client    Jan 13, 2024 17:04 UTC   364d            etcd-ca                 no      
etcd-peer                  Jan 13, 2024 17:04 UTC   364d            etcd-ca                 no      
etcd-server                Jan 13, 2024 17:04 UTC   364d            etcd-ca                 no      
front-proxy-client         Jan 13, 2024 17:04 UTC   364d            front-proxy-ca          no      
scheduler.conf             Jan 13, 2024 17:04 UTC   364d            ca                      no      

CERTIFICATE AUTHORITY   EXPIRES                  RESIDUAL TIME   EXTERNALLY MANAGED
ca                      Jan 10, 2033 17:04 UTC   9y              no      
etcd-ca                 Jan 10, 2033 17:04 UTC   9y              no      
front-proxy-ca          Jan 10, 2033 17:04 UTC   9y              no      
```

We can see the expire date is `Jan 13, 2024 17:04 UTC`.

5. Create the DaemonSet:

Now we will setup a DaemonSet to rotate the kubernetes certificates by applying the manifests:
```sh
kubectl apply -f manifests/
```
```
daemonset.apps/kucero created
clusterrole.rbac.authorization.k8s.io/kucero created
clusterrolebinding.rbac.authorization.k8s.io/kucero created
role.rbac.authorization.k8s.io/kucero created
rolebinding.rbac.authorization.k8s.io/kucero created
serviceaccount/kucero created
```

Validate the DaemonSet:
```sh
kubectl get ds -n kube-system kucero
```
```
NAME     DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
kucero   1         1         1       1            1           <none>          3m56s
```

6. Tracking:

Every 5 minutes:
```sh
docker exec -it minikube kubeadm certs check-expiration
```
```
[check-expiration] Reading configuration from the cluster...
[check-expiration] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'

CERTIFICATE                EXPIRES                  RESIDUAL TIME   CERTIFICATE AUTHORITY   EXTERNALLY MANAGED
admin.conf                 Jan 13, 2024 17:45 UTC   364d            ca                      no      
apiserver                  Jan 12, 2026 17:04 UTC   2y              ca                      no      
apiserver-etcd-client      Jan 13, 2024 17:45 UTC   364d            etcd-ca                 no      
apiserver-kubelet-client   Jan 13, 2024 17:45 UTC   364d            ca                      no      
controller-manager.conf    Jan 13, 2024 17:46 UTC   364d            ca                      no      
etcd-healthcheck-client    Jan 13, 2024 17:45 UTC   364d            etcd-ca                 no      
etcd-peer                  Jan 13, 2024 17:46 UTC   364d            etcd-ca                 no      
etcd-server                Jan 13, 2024 17:45 UTC   364d            etcd-ca                 no      
front-proxy-client         Jan 13, 2024 17:46 UTC   364d            front-proxy-ca          no      
scheduler.conf             Jan 13, 2024 17:45 UTC   364d            ca                      no      

CERTIFICATE AUTHORITY   EXPIRES                  RESIDUAL TIME   EXTERNALLY MANAGED
ca                      Jan 10, 2033 17:04 UTC   9y              no      
etcd-ca                 Jan 10, 2033 17:04 UTC   9y              no      
front-proxy-ca          Jan 10, 2033 17:04 UTC   9y              no      
```

The expire date now is `Jan 13, 2024 17:45 UTC`.

Every 5 minutes:
```sh
docker exec -it minikube kubeadm certs check-expiration
```
```
[check-expiration] Reading configuration from the cluster...
[check-expiration] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'

CERTIFICATE                EXPIRES                  RESIDUAL TIME   CERTIFICATE AUTHORITY   EXTERNALLY MANAGED
admin.conf                 Jan 13, 2024 17:52 UTC   364d            ca                      no      
apiserver                  Jan 12, 2026 17:04 UTC   2y              ca                      no      
apiserver-etcd-client      Jan 13, 2024 17:52 UTC   364d            etcd-ca                 no      
apiserver-kubelet-client   Jan 13, 2024 17:52 UTC   364d            ca                      no      
controller-manager.conf    Jan 13, 2024 17:52 UTC   364d            ca                      no      
etcd-healthcheck-client    Jan 13, 2024 17:52 UTC   364d            etcd-ca                 no      
etcd-peer                  Jan 13, 2024 17:52 UTC   364d            etcd-ca                 no      
etcd-server                Jan 13, 2024 17:52 UTC   364d            etcd-ca                 no      
front-proxy-client         Jan 13, 2024 17:52 UTC   364d            front-proxy-ca          no      
scheduler.conf             Jan 13, 2024 17:52 UTC   364d            ca                      no      

CERTIFICATE AUTHORITY   EXPIRES                  RESIDUAL TIME   EXTERNALLY MANAGED
ca                      Jan 10, 2033 17:04 UTC   9y              no      
etcd-ca                 Jan 10, 2033 17:04 UTC   9y              no      
front-proxy-ca          Jan 10, 2033 17:04 UTC   9y              no      
```

The expire date now is `Jan 13, 2024 17:52 UTC`.

That's working!
