### Configure the CustomResourceDefinitions

To define a new resource type, all you need to do is post a `CustomResourceDefinition` object (CRD) to the Kubernetes API server. The `CustomResourceDefinition` object is the description of the custom resource type. Once the CRD is posted, users can then create instances of the custom resource by posting JSON or YAML manifests to the API server, the same as with any other Kubernetes resource.

Let's imagine you want to allow users of your Kubernetes cluster to run static websites as easily as possible, without having to deal with `Pods`, `Services`, and other Kubernetes resources. What you want to achieve is for users to create objects of type `Website` that contain nothing more than the website's name and the source from which the website's files (HTML, CSS, PNG, and others) should be obtained, eg., docker image, github, ... When a user creates an instance of the `Website` resource, you want Kubernetes to spin up a new web server pod and expose it through a Service.

To create the `Website` resource, you want users to post manifests along the lines of the one shown in the following listing.

```yaml
apiVersion: extensions.example.com/v1
kind: Website
metadata:
  name: kubia
spec:
  gitRepo: https://github.com/hoangph3/kubia-website-example.git
```

If you try posting this resource to Kubernetes, you'll receive an error because Kubernetes doesn’t know what a `Website` object is yet:

```
$ kubectl apply -f imaginary-website.yaml
error: unable to recognize "imaginary-website.yaml": no matches for kind "Website" in version "extensions.example.com/v1"
```

Now you will create the CRD from the `website-crd.yaml` file:

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  # name must match the spec fields below, and be in the form: <plural>.<group>
  name: websites.extensions.example.com
spec:
  scope: Namespaced # either Namespaced or Cluster
  group: extensions.example.com # group name to use for REST API: /apis/<group>/<version>
  versions:
    - name: v1
      served: true # Each version can be enabled/disabled by Served flag.
      storage: true # One and only one version must be marked as the storage version.
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                gitRepo:
                  type: string
  names:
    kind: Website # kind is normally the CamelCased singular type. Your resource manifests use this.
    singular: website # singular name to be used as an alias on the CLI and for display
    plural: websites # plural name to be used in the URL: /apis/<group>/<version>/<plural>
    shortNames: # shortNames allow shorter string to match your resource on the CLI
    - gitrp
```

```
$ kubectl apply -f website-crd.yaml
customresourcedefinition.apiextensions.k8s.io/websites.extensions.example.com created
```

Create your `Website` object now:

```
$ kubectl apply -f imaginary-website.yaml
website.extensions.example.com/kubia created

$ kubectl get websites
NAME    AGE
kubia   35s

$ kubectl describe websites.extensions.example.com kubia 
Name:         kubia
Namespace:    default
Labels:       <none>
Annotations:  <none>
API Version:  extensions.example.com/v1
Kind:         Website
Metadata:
  Creation Timestamp:  2022-04-24T08:06:14Z
  Generation:          1
  Managed Fields:
    API Version:  extensions.example.com/v1
    Fields Type:  FieldsV1
    fieldsV1:
      f:metadata:
        f:annotations:
          .:
          f:kubectl.kubernetes.io/last-applied-configuration:
      f:spec:
        .:
        f:gitRepo:
    Manager:         kubectl-client-side-apply
    Operation:       Update
    Time:            2022-04-24T08:06:14Z
  Resource Version:  505709
  UID:               e1721dc4-e80e-4628-be20-11366aa6bffa
Spec:
  Git Repo:  https://github.com/hoangph3/kubia-website-example.git
Events:      <none>
```

To make your Website objects run a web server pod exposed through a Service, you'll need to build and deploy a Website controller, which will watch the API server for the creation of Website objects and then create the Service and the web server Pod for each of them.

Firstly, build website-controller image:

```
$ cd website-controller && ls
deployment-template.json  Dockerfile  pkg  service-template.json

$ go mod init website-controller
go: creating new go.mod: module website-controller
go: to add module requirements and sums:
        go mod tidy

$ go get github.com/hoangph3/website-controller/pkg/v1
go: downloading github.com/hoangph3/website-controller v0.0.0-20170607104431-912c847af8cc
go: added github.com/hoangph3/website-controller v0.0.0-20170607104431-912c847af8cc

$ CGO_ENABLED=0 GOOS=linux go build -o website-controller -a pkg/website-controller.go

$ ls -la
total 6564
drwxr-xr-x 3 ph3 ph3    4096 Apr 24 07:09 .
drwxr-xr-x 4 ph3 ph3    4096 Apr 24 06:51 ..
-rw-r--r-- 1 ph3 ph3    1786 Apr 24 05:51 deployment-template.json
-rw-r--r-- 1 ph3 ph3     125 Apr 24 05:49 Dockerfile
-rw-r--r-- 1 ph3 ph3     266 Jun  7  2017 .gitignore
-rw-r--r-- 1 ph3 ph3     130 Apr 24 06:45 go.mod
-rw-r--r-- 1 ph3 ph3     251 Apr 24 06:45 go.sum
drwx------ 3 ph3 ph3    4096 Jun  7  2017 pkg
-rw-r--r-- 1 ph3 ph3     342 Jun  7  2017 service-template.json
-rwxr-xr-x 1 ph3 ph3 6680760 Apr 24 07:09 website-controller

$ docker build -t website-controller . 
Sending build context to Docker daemon  6.696MB
Step 1/5 : FROM scratch
 ---> 
Step 2/5 : ADD website-controller /
 ---> 6f3fd9ca8612
Step 3/5 : ADD deployment-template.json /
 ---> 77a642a5c4af
Step 4/5 : ADD service-template.json /
 ---> 7886a1be5b6c
Step 5/5 : CMD ["/website-controller"]
 ---> Running in e0677b637e27
Removing intermediate container e0677b637e27
 ---> 757ada991a0c
Successfully built 757ada991a0c
Successfully tagged kube-website-controller:latest
```

Then build ambassador `kubectl-proxy` image used for communication with the API server:

```
$ cd kubectl-proxy && ls
Dockerfile  kubectl-proxy.sh

$ docker build -t kubectl-proxy .      
Sending build context to Docker daemon  3.072kB
Step 1/5 : FROM python:3.8-slim-buster
 ---> 9f9436d44487
Step 2/5 : RUN apt -y update && apt -y install curl telnet nano && curl -L -O https://dl.k8s.io/v1.23.5/kubernetes-client-linux-amd64.tar.gz && tar zvxf kubernetes-client-linux-amd64.tar.gz kubernetes/client/bin/kubectl && mv kubernetes/client/bin/kubectl / && rm -rf kubernetes && rm -f kubernetes-client-linux-amd64.tar.gz
 ---> Using cache
 ---> 6e63691a26b0
Step 3/5 : ADD kubectl-proxy.sh /kubectl-proxy.sh
 ---> 8188274c8f2c
Step 4/5 : RUN chmod +x kubectl-proxy.sh
 ---> Running in f18dacc8be53
Removing intermediate container f18dacc8be53
 ---> 2619234d7639
Step 5/5 : ENTRYPOINT /kubectl-proxy.sh
 ---> Running in 5ab5b47a9706
Removing intermediate container 5ab5b47a9706
 ---> fd2d8e870acf
Successfully built fd2d8e870acf
Successfully tagged kubectl-proxy:latest
```

Create kubernetes website controller:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: website-controller
  labels:
    app: website-controller
spec:
  replicas: 1
  selector:
    matchLabels:
      app: website-controller
  template:
    metadata:
      name: website-controller
      labels:
        app: website-controller
    spec:
      serviceAccountName: website-controller
      containers:
      - name: main
        image: website-controller
        imagePullPolicy: Never
      - name: proxy
        image: kubectl-proxy
        imagePullPolicy: Never
```

Note that you need create ServiceAccount website-controller first:

```
$ kubectl create serviceaccount website-controller
serviceaccount/website-controller created
```

Then create the controller:

```
$ kubectl apply -f website-controller.yaml
deployment.apps/website-controller created
```

Bind ClusterRole `cluster-admin` to ServiceAccount:

```
$ kubectl create clusterrolebinding website-controller --clusterrole=cluster-admin --serviceaccount=default:website-controller
clusterrolebinding.rbac.authorization.k8s.io/website-controller created
```

With the controller now running, create the Website resource again:

```
$ kubectl apply -f imaginary-website.yaml
website.extensions.example.com/kubia created
```

Now, let's check the controller's logs and lists all Deployments, Services and Pods:

```
$ kubectl get pods
NAME                                  READY   STATUS    RESTARTS       AGE
kubia-website-7d94854d9f-clqg5        2/2     Running   0              5s
website-controller-5dd4555d87-rwsz7   2/2     Running   1 (2m4s ago)   2m5s

$ kubectl logs -f website-controller-5dd4555d87-4rl2x -c main
2022/04/25 01:45:17 website-controller started.
2022/04/25 01:45:30 Received watch event: ADDED: kubia: https://github.com/hoangph3/kubia-website-example.git
2022/04/25 01:45:30 Creating services with name kubia-website in namespace default
2022/04/25 01:45:30 response Status: 201 Created
2022/04/25 01:45:30 Creating deployments with name kubia-website in namespace default
2022/04/25 01:45:30 response Status: 201 Created

$ kubectl get deploy,svc,po
NAME                                 READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/kubia-website        0/1     1            0           4s
deployment.apps/website-controller   1/1     1            1           19s

NAME                    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
service/kubernetes      ClusterIP   10.96.0.1       <none>        443/TCP        88d
service/kubia-website   NodePort    10.104.14.151   <none>        80:32522/TCP   4s

NAME                                      READY   STATUS              RESTARTS      AGE
pod/kubia-website-7d94854d9f-jxzbh        0/2     ContainerCreating   0             4s
pod/website-controller-5dd4555d87-rwsz7   2/2     Running             1 (18s ago)   19s

$ minikube service list
|---------------|------------------------------------|--------------|---------------------------|
|   NAMESPACE   |                NAME                | TARGET PORT  |            URL            |
|---------------|------------------------------------|--------------|---------------------------|
| default       | kubernetes                         | No node port |
| default       | kubia-service                      |           80 | http://192.168.49.2:32522 |
| ingress-nginx | ingress-nginx-controller           | http/80      | http://192.168.49.2:31300 |
|               |                                    | https/443    | http://192.168.49.2:30830 |
| ingress-nginx | ingress-nginx-controller-admission | No node port |
| kube-system   | kube-dns                           | No node port |
|---------------|------------------------------------|--------------|---------------------------|

$ curl http://192.168.49.2:32522
<html>
<body>
Hello there.
</body>
</html>
```

If you want to delete this website:

```
$ kubectl delete -f imaginary-website.yaml
website.extensions.example.com "kubia" deleted

$ kubectl get deploy,svc,po               
NAME                                 READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/website-controller   1/1     1            1           4m6s

NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   88d

NAME                                      READY   STATUS    RESTARTS       AGE
pod/website-controller-5dd4555d87-rwsz7   2/2     Running   1 (4m5s ago)   4m6s

$ kubectl logs -f website-controller-5dd4555d87-rwsz7 -c main
2022/04/25 01:45:17 website-controller started.
2022/04/25 01:45:30 Received watch event: ADDED: kubia: https://github.com/hoangph3/kubia-website-example.git
2022/04/25 01:45:30 Creating services with name kubia-website in namespace default
2022/04/25 01:45:30 response Status: 201 Created
2022/04/25 01:45:30 Creating deployments with name kubia-website in namespace default
2022/04/25 01:45:30 response Status: 201 Created
2022/04/25 01:46:01 Received watch event: DELETED: kubia: https://github.com/hoangph3/kubia-website-example.git
2022/04/25 01:46:01 Deleting services with name kubia-website in namespace default
2022/04/25 01:46:01 response Status: 200 OK
2022/04/25 01:46:01 Deleting deployments with name kubia-website in namespace default
2022/04/25 01:46:01 response Status: 200 OK
```
