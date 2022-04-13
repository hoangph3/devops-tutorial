### Authentication and Authorization in Kubernetes

In this tutorial, we will create two namespaces "my-app-dev" and "my-app-prod" and two users "dev" and "test" with different roles to those namespaces:

```
my-app-dev:
  dev: Edit
my-app-prod:
  dev: View
  test: Edit
```

The default Roles defined in Kubernetes are:

```
- view: read-only access, excludes secrets.
- edit: above + ability to edit most resources, excludes roles and role bindings.
- admin: above + ability to manage roles and role bindings at a namespace level.
- cluster-admin: everything.
```

To manage normal users, we will use X.509 client certificate:

```
1. Create a user's private key and a certificate signing request.
2. Get it certified by a CA (Kubernetes CA) to have the user's certificate.
```

Suppose you are the admin (like root privileges), now you will create the normal user `dev:123456`:

```sh
sudo useradd -m dev
sudo passwd dev
```

```
New password: 123456
Retype new password: 123456
passwd: password updated successfully
```

Go into dev's home directory as root privileges:

```sh
sudo su
cd /home/dev && ls -la
```

```
┌──(root💀jump-windows)-[/home/dev]
└─# cd /home/dev && ls -la
total 60
drwxr-xr-x 4 dev  dev   4096 Apr 11 13:09 .
drwxr-xr-x 4 root root  4096 Apr 11 13:09 ..
-rw-r--r-- 1 dev  dev    220 Feb 24  2021 .bash_logout
-rw-r--r-- 1 dev  dev   5551 Apr  2 00:54 .bashrc
-rw-r--r-- 1 dev  dev   3526 Feb 24  2021 .bashrc.original
drwxr-xr-x 5 dev  dev   4096 Jan 24 05:06 .config
-rw-r--r-- 1 dev  dev  11759 May 19  2021 .face
lrwxrwxrwx 1 dev  dev      5 Mar  4 11:38 .face.icon -> .face
drwxr-xr-x 3 dev  dev   4096 Jan 24 05:06 .java
-rw-r--r-- 1 dev  dev    807 Feb 24  2021 .profile
-rw-r--r-- 1 dev  dev  10875 Feb  3 22:45 .zshrc
```

Create a private key:

```sh
openssl genrsa -out dev.key 2048
```

Create a certificate signing request (CSR):

```sh
openssl req -new -key dev.key -subj "/CN=dev" -out dev.csr
```

Sign the CSR with the Kubernetes CA:

If minikube:

  ```sh
  openssl x509 -req -in dev.csr -CA /home/ph3/.minikube/ca.crt -CAkey /home/ph3/.minikube/ca.key -CAcreateserial -out dev.crt -days 500
  ```

If kubernetes cluster:

  ```sh
  openssl x509 -req -in dev.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out dev.crt -days 500
  ```

List files in dev's home directory:

```
┌──(root💀jump-windows)-[/home/dev]
└─# ls -la
total 72
drwxr-xr-x 4 dev  dev   4096 Apr 11 13:17 .
drwxr-xr-x 4 root root  4096 Apr 11 13:09 ..
-rw-r--r-- 1 dev  dev    220 Feb 24  2021 .bash_logout
-rw-r--r-- 1 dev  dev   5551 Apr  2 00:54 .bashrc
-rw-r--r-- 1 dev  dev   3526 Feb 24  2021 .bashrc.original
drwxr-xr-x 5 dev  dev   4096 Jan 24 05:06 .config
-rw-r--r-- 1 root root   985 Apr 11 13:17 dev.crt
-rw-r--r-- 1 root root   883 Apr 11 13:13 dev.csr
-rw------- 1 root root  1675 Apr 11 13:12 dev.key
-rw-r--r-- 1 dev  dev  11759 May 19  2021 .face
lrwxrwxrwx 1 dev  dev      5 Mar  4 11:38 .face.icon -> .face
drwxr-xr-x 3 dev  dev   4096 Jan 24 05:06 .java
-rw-r--r-- 1 dev  dev    807 Feb 24  2021 .profile
-rw-r--r-- 1 dev  dev  10875 Feb  3 22:45 .zshrc
```

We have new three files: dev.crt, dev.csr, dev.key but under root privileges. We need to grant all the created files and directories to the "dev" user:

```sh
chown -R dev: /home/dev/
```

```
┌──(root💀jump-windows)-[/home/dev]
└─# ls -la
total 72
drwxr-xr-x 4 dev  dev   4096 Apr 11 13:17 .
drwxr-xr-x 4 root root  4096 Apr 11 13:09 ..
-rw-r--r-- 1 dev  dev    220 Feb 24  2021 .bash_logout
-rw-r--r-- 1 dev  dev   5551 Apr  2 00:54 .bashrc
-rw-r--r-- 1 dev  dev   3526 Feb 24  2021 .bashrc.original
drwxr-xr-x 5 dev  dev   4096 Jan 24 05:06 .config
-rw-r--r-- 1 dev  dev    985 Apr 11 13:17 dev.crt
-rw-r--r-- 1 dev  dev    883 Apr 11 13:13 dev.csr
-rw------- 1 dev  dev   1675 Apr 11 13:12 dev.key
-rw-r--r-- 1 dev  dev  11759 May 19  2021 .face
lrwxrwxrwx 1 dev  dev      5 Mar  4 11:38 .face.icon -> .face
drwxr-xr-x 3 dev  dev   4096 Jan 24 05:06 .java
-rw-r--r-- 1 dev  dev    807 Feb 24  2021 .profile
-rw-r--r-- 1 dev  dev  10875 Feb  3 22:45 .zshrc
```

Now we will login to "dev" user to create user and context in kubernetes:

```sh
sudo -u dev bash
```

Create the user inside kubernetes as "dev" privileges:

```sh
kubectl config set-credentials dev --client-certificate=/home/dev/dev.crt --client-key=/home/dev/dev.key
```

```
┌──(dev㉿jump-windows)-[~]
└─$ kubectl config set-credentials dev --client-certificate=/home/dev/dev.crt --client-key=/home/dev/dev.key
User "dev" set.
```

Create a context for the user:

If minikube:

  ```sh
  kubectl config set-context dev-context --cluster=minikube --user=dev
  ```

If kubernetes cluster:

  ```sh
  kubectl config set-context dev-context --cluster=kubernetes --user=dev
  ```

After above steps, the `/home/dev/.kube/config` file is created:

```yaml
apiVersion: v1
clusters: null
contexts:
- context:
    cluster: minikube
    user: dev
  name: dev-context
current-context: ""
kind: Config
preferences: {}
users:
- name: dev
  user:
    client-certificate: /home/dev/dev.crt
    client-key: /home/dev/dev.key
```

Edit user config file:

```yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /home/ph3/.minikube/ca.crt
    server: https://192.168.49.2:8443 
  name: minikube
contexts:
- context:
    cluster: minikube
    user: dev
  name: dev-context
current-context: dev-context
kind: Config
preferences: {}
users:
- name: dev
  user:
    client-certificate: /home/dev/dev.crt
    client-key: /home/dev/dev.key
```

Note that the `certificate-authority` and `server` variables have to be as in the cluster admin config.

Now we have a user "dev" created. We will do the same for user "test".

As administrator, we can create the two namespaces:

```sh
kubectl create namespace my-app-dev
kubectl create namespace my-app-prod
```

As we have not defined any authorization to the users, they should get forbidden access to all cluster resources.

```
┌──(dev㉿jump-windows)-[~]
└─$ kubectl get nodes
Error from server (Forbidden): nodes is forbidden: User "dev" cannot list resource "nodes" in API group "" at the cluster scope

┌──(dev㉿jump-windows)-[~]
└─$ kubectl get pods
Error from server (Forbidden): pods is forbidden: User "dev" cannot list resource "pods" in API group "" in the namespace "default"

┌──(dev㉿jump-windows)-[~]
└─$ kubectl get pods -n my-app-dev
Error from server (Forbidden): pods is forbidden: User "dev" cannot list resource "pods" in API group "" in the namespace "my-app-dev"

┌──(dev㉿jump-windows)-[~]
└─$ kubectl get pods -n my-app-prod
Error from server (Forbidden): pods is forbidden: User "dev" cannot list resource "pods" in API group "" in the namespace "my-app-prod"
```

```
┌──(test㉿jump-windows)-[~]
└─$ kubectl get nodes
Error from server (Forbidden): nodes is forbidden: User "test" cannot list resource "nodes" in API group "" at the cluster scope

┌──(test㉿jump-windows)-[~]
└─$ kubectl get pods
Error from server (Forbidden): pods is forbidden: User "test" cannot list resource "pods" in API group "" in the namespace "default"

┌──(test㉿jump-windows)-[~]
└─$ kubectl get pods -n my-app-dev
Error from server (Forbidden): pods is forbidden: User "test" cannot list resource "pods" in API group "" in the namespace "my-app-dev"

┌──(test㉿jump-windows)-[~]
└─$ kubectl get pods -n my-app-prod
Error from server (Forbidden): pods is forbidden: User "test" cannot list resource "pods" in API group "" in the namespace "my-app-prod"
```

As administrator, we will create a Role/ClusterRole. A Role/ClusterRole are just a list of verbs (actions) permitted on specific resources and namespaces. Here is `role.yaml` file:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: list-deployments
  namespace: my-app-dev
rules:
  - apiGroups: [ apps ]
    resources: [ deployments ]
    verbs: [ get, list ]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: list-deployments
rules:
  - apiGroups: [ apps ]
    resources: [ deployments ]
    verbs: [ get, list ]
```

```sh
kubectl apply -f role.yaml
```

We can list ClusterRole:

```sh
kubectl get clusterrole
```

```
NAME                                                                   CREATED AT
admin                                                                  2022-01-27T01:18:51Z
cluster-admin                                                          2022-01-27T01:18:51Z
edit                                                                   2022-01-27T01:18:51Z
ingress-nginx                                                          2022-04-10T14:38:31Z
ingress-nginx-admission                                                2022-04-10T14:38:31Z
kubeadm:get-nodes                                                      2022-01-27T01:18:53Z
list-deployments                                                       2022-04-11T18:18:04Z
system:aggregate-to-admin                                              2022-01-27T01:18:51Z
system:aggregate-to-edit                                               2022-01-27T01:18:51Z
system:aggregate-to-view                                               2022-01-27T01:18:51Z
system:auth-delegator                                                  2022-01-27T01:18:51Z
system:basic-user                                                      2022-01-27T01:18:51Z
...
...
system:volume-scheduler                                                2022-01-27T01:18:51Z
view                                                                   2022-01-27T01:18:51Z
```

We are now going to bind Role/ClusterRole to users by `role-binding.yaml` as below:

```
dev:
  edit on namespace "my-app-dev"
  view on namespace "my-app-prod"
test:
  edit on namespace "my-app-prod"
```

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: dev
  namespace: my-app-dev
subjects:
- kind: User
  name: dev
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: edit
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: dev
  namespace: my-app-prod
subjects:
- kind: User
  name: dev
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: view
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: test
  namespace: my-app-prod
subjects:
- kind: User
  name: test
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: edit
  apiGroup: rbac.authorization.k8s.io
```

```sh
kubectl apply -f role-binding.yaml
```

Let’s check if our users have the right permissions.

```
User: test (edit on "my-app-prod" namespace)
  - can create deployments, list pods on "my-app-prod"
  - can't create or list pods, deployments on "my-app-dev"
```

```
┌──(test㉿jump-windows)-[~]
└─$ kubectl run nginx --image=nginx -n my-app-prod
pod/nginx created

┌──(test㉿jump-windows)-[~]
└─$ kubectl get pods -n my-app-prod
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          15s

┌──(test㉿jump-windows)-[~]
└─$ kubectl run nginx --image=nginx -n my-app-dev
Error from server (Forbidden): pods is forbidden: User "test" cannot create resource "pods" in API group "" in the namespace "my-app-dev"

┌──(test㉿jump-windows)-[~]
└─$ kubectl get pods -n my-app-dev
Error from server (Forbidden): pods is forbidden: User "test" cannot list resource "pods" in API group "" in the namespace "my-app-dev"
```

```
User: dev (view on "my-app-prod" namespace
           edit on "my-app-dev" namespace)
  - can list pods, deployments on "my-app-prod" but can't create
  - can list, create, delete pods, deployments on "my-app-dev"
```

```
┌──(dev㉿jump-windows)-[~]
└─$ kubectl get pods -n my-app-prod
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          7m14s

┌──(dev㉿jump-windows)-[~]
└─$ kubectl run nginx --image=nginx -n my-app-prod
Error from server (Forbidden): pods is forbidden: User "dev" cannot create resource "pods" in API group "" in the namespace "my-app-prod"

┌──(dev㉿jump-windows)-[~]
└─$ kubectl run nginx --image=nginx -n my-app-dev
pod/nginx created

┌──(dev㉿jump-windows)-[~]
└─$ kubectl get pods -n my-app-dev
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          11s

┌──(dev㉿jump-windows)-[~]
└─$ kubectl delete pods nginx -n my-app-dev
pod "nginx" deleted

┌──(dev㉿jump-windows)-[~]
└─$ kubectl get pods -n my-app-dev
No resources found in my-app-dev namespace.
```

### Configure ServiceAccount to pull private image

Create service account with imagePullSecrets by `sa-image-pull-secrets.yaml`:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: sa-docker-registry
imagePullSecrets:
- name: mydockerhubsecret
```

Now, you can inspect the ServiceAccount with the describe command:

```sh
kubectl describe sa sa-docker-registry
```

```
Name:                sa-docker-registry
Namespace:           default
Labels:              <none>
Annotations:         <none>
Image pull secrets:  mydockerhubsecret
Mountable secrets:   sa-docker-registry-token-bcbmg
Tokens:              sa-docker-registry-token-bcbmg
Events:              <none>
```

You can see that a custom token Secret has been created and associated with the ServiceAccount.

Let's inspect the secret `sa-docker-registry-token-bcbmg`:

```sh
kubectl describe secret sa-docker-registry-token-bcbmg
```

```
Name:         sa-docker-registry-token-bcbmg
Namespace:    default
Labels:       <none>
Annotations:  kubernetes.io/service-account.name: sa-docker-registry
              kubernetes.io/service-account.uid: 643bb848-6f9f-4f4e-a087-0ce61fec527f

Type:  kubernetes.io/service-account-token

Data
====
ca.crt:     1111 bytes
namespace:  7 bytes
token:      eyJhbGciOiJSUzI1NiIs...
```

To assign a ServiceAccount to a pod, we will set the name of the ServiceAccount in the `spec.serviceAccountName` field in the pod definition:

This is `busybox-sa.yaml` without service account:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: busybox
spec:
  containers:
  - name: busybox
    image: hoangph3/busybox
    command: ['sh', '-c']
    args: 
    - echo "$(date) Hello Kubernetes !";
      sleep 9999999;
```

```sh
kubectl apply -f busybox-sa.yaml
kubectl get pods
kubectl describe pod busybox
```

```
NAME      READY   STATUS         RESTARTS   AGE
busybox   0/1     ErrImagePull   0          7s

Events:
  Type     Reason     Age   From               Message
  ----     ------     ----  ----               -------
  Normal   Scheduled  16s   default-scheduler  Successfully assigned default/busybox to minikube
  Normal   Pulling    15s   kubelet            Pulling image "hoangph3/busybox"
  Warning  Failed     11s   kubelet            Failed to pull image "hoangph3/busybox": rpc error: code = Unknown desc = Error response from daemon: pull access denied for hoangph3/busybox, repository does not exist or may require 'docker login': denied: requested access to the resource is denied
  Warning  Failed     11s   kubelet            Error: ErrImagePull
  Normal   BackOff    11s   kubelet            Back-off pulling image "hoangph3/busybox"
  Warning  Failed     11s   kubelet            Error: ImagePullBackOff
```

This is `busybox-sa.yaml` with service account:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: busybox
spec:
  serviceAccountName: sa-docker-registry
  containers:
  - name: busybox
    image: hoangph3/busybox
    command: ['sh', '-c']
    args: 
    - echo "$(date) Hello Kubernetes !";
      sleep 9999999;
```

```sh
kubectl apply -f busybox-sa.yaml
kubectl get pods
kubectl describe pod busybox
kubectl logs -f busybox
```

```
NAME      READY   STATUS    RESTARTS   AGE
busybox   1/1     Running   0          20s

Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  15s   default-scheduler  Successfully assigned default/busybox to minikube
  Normal  Pulling    14s   kubelet            Pulling image "hoangph3/busybox"
  Normal  Pulled     10s   kubelet            Successfully pulled image "hoangph3/busybox" in 3.227788488s
  Normal  Created    10s   kubelet            Created container busybox
  Normal  Started    10s   kubelet            Started container busybox

Wed Apr 13 16:31:10 UTC 2022 Hello Kubernetes !
```

The custom ServiceAccount's token is mounted into the container, you can confirm by exec command:

```
$ kubectl exec -it busybox -- sh                                              
/ # cd /var/run/secrets/kubernetes.io/serviceaccount/
/var/run/secrets/kubernetes.io/serviceaccount # ls
ca.crt     namespace  token
/var/run/secrets/kubernetes.io/serviceaccount # cat token 
eyJhbGciOiJSUzI1NiIs...
```