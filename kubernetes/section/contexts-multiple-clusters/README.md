### Configure Access to multiple clusters

Suppose we have a minikube cluster on local machine, we can get the content of config file from: `$HOME/.kube/config`

```yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /home/ph3/.minikube/ca.crt
    extensions:
    - extension:
        last-update: Sat, 23 Apr 2022 22:15:17 EDT
        provider: minikube.sigs.k8s.io
        version: v1.24.0
      name: cluster_info
    server: https://192.168.49.2:8443
  name: minikube
contexts:
- context:
    cluster: minikube
    extensions:
    - extension:
        last-update: Sat, 23 Apr 2022 22:15:17 EDT
        provider: minikube.sigs.k8s.io
        version: v1.24.0
      name: context_info
    namespace: default
    user: minikube
  name: minikube
current-context: minikube
kind: Config
preferences: {}
users:
- name: minikube
  user:
    client-certificate: /home/ph3/.minikube/profiles/minikube/client.crt
    client-key: /home/ph3/.minikube/profiles/minikube/client.key
```

Show all contexts and current context:

```
$ kubectl config get-contexts                                                                
CURRENT   NAME       CLUSTER    AUTHINFO   NAMESPACE
*         minikube   minikube   minikube   default

$ kubectl config current-context 
minikube
```

Suppose we have another kubernetes cluster with information about `certificate-authority-data` and `server` also `client-certificate-data` and `client-key-data`. If we want to access to this cluster from local machine, we need to change config file, look like following that:

```yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /home/ph3/.minikube/ca.crt
    extensions:
    - extension:
        last-update: Sat, 23 Apr 2022 22:15:17 EDT
        provider: minikube.sigs.k8s.io
        version: v1.24.0
      name: cluster_info
    server: https://192.168.49.2:8443
  name: minikube
- cluster:
    certificate-authority-data: xxxxxx
    server: xxxxxx
  name: kubernetes
contexts:
- context:
    cluster: minikube
    extensions:
    - extension:
        last-update: Sat, 23 Apr 2022 22:15:17 EDT
        provider: minikube.sigs.k8s.io
        version: v1.24.0
      name: context_info
    namespace: default
    user: minikube
  name: minikube
- context:
    cluster: kubernetes
    namespace: default
    user: dev-admin
  name: dev-admin@kubernetes
current-context: minikube
kind: Config
preferences: {}
users:
- name: minikube
  user:
    client-certificate: /home/ph3/.minikube/profiles/minikube/client.crt
    client-key: /home/ph3/.minikube/profiles/minikube/client.key
- name: dev-admin
  user:
    client-certificate-data: xxxxxx
    client-key-data: xxxxxx
```

Filling data from `certificate-authority-data`, `server`, `client-certificate-data` and `client-key-data` into xxxxxx.

Now we listing contexts, then switching between contexts:

```
$ kubectl config get-contexts        
CURRENT   NAME                   CLUSTER      AUTHINFO    NAMESPACE
          dev-admin@kubernetes   kubernetes   dev-admin   default
*         minikube               minikube     minikube    default

$ kubectl cluster-info       
Kubernetes control plane is running at https://192.168.49.2:8443
CoreDNS is running at https://192.168.49.2:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

$ kubectl config use-context dev-admin@kubernetes 
Switched to context "dev-admin@kubernetes".

$ kubectl cluster-info                           
Kubernetes control plane is running at https://192.168.56.15:6443
CoreDNS is running at https://192.168.56.15:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```
