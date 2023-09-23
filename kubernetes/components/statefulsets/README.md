### StatefulSet Application

The StatefulSet look like the ReplicaSet, but it's creates both Pods and PersistentVolumeClaims. And a StatefulSet maintains a sticky identity for each of their Pods. StatefulSet Pods have a unique identity that is comprised of an ordinal, a stable network identity, and stable storage.

For a StatefulSet with N replicas, each Pod in the StatefulSet will be assigned an integer ordinal, from 0 up through N-1, that is unique over the Set, each Pod is attached to a PersistentVolumeClaim.

#### Create the PersistentVolume

Because the PersistentVolumeClaim will request resource from PersistentVolume, so we need create PersistentVolume first. Note that we must create more if we plan on scaling the StatefulSet up more than that.

In this tutorial, we will need 3 PersistentVolumes, because we will be scaling the StatefulSet up to 3 replicas.

```sh
kubectl apply -f persistent-volumes-hostpath.yaml
kubectl get pv
```

```
NAME   CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
pv-a   1Mi        RWO            Retain           Available                                   7s
pv-b   1Mi        RWO            Retain           Available                                   7s
pv-c   1Mi        RWO            Retain           Available                                   7s
```

Create StatefulSet with Headless Service:

```sh
kubectl apply -f kubia-statefulset.yaml
kubectl get pods
```

```
NAME      READY   STATUS    RESTARTS   AGE
kubia-0   1/1     Running   0          104s
kubia-1   1/1     Running   0          56s
```

Forward port to test connection from localhost:

```sh
kubectl port-forward kubia-0 8080:8080
curl localhost:8080
```

```
Forwarding from 127.0.0.1:8080 -> 8080
Forwarding from [::1]:8080 -> 8080

You've hit kubia-0
Data stored on this pod: No data posted yet
```

Send HTTP POST request to the application:

```sh
curl -X POST -d "Hello kubia-0" localhost:8080
```

```
Data stored on pod kubia-0
```

Send HTTP GET request to the application:

```sh
curl localhost:8080
```

```
You've hit kubia-0
Data stored on this pod: Hello kubia-0
```

Now let's interact with another pod:

```sh
kubectl port-forward kubia-0 8081:8080
curl localhost:8081
```

```
You've hit kubia-1
Data stored on this pod: No data posted yet
```

As expected, each node has its own state. But is that state persisted?

We are going to delete the kubia-0 pod and wait for it to be rescheduled. Then we will see if it's still serving the same data as before.

```sh
kubectl delete pods kubia-0
kubectl get pods
```

```
NAME      READY   STATUS        RESTARTS   AGE
kubia-0   1/1     Terminating   0          20m
kubia-1   1/1     Running       0          20m
```

The pod is rescheduled:

```sh
kubectl get pods
```

```
NAME      READY   STATUS              RESTARTS   AGE
kubia-0   0/1     ContainerCreating   0          5s
kubia-1   1/1     Running             0          21m

NAME      READY   STATUS    RESTARTS   AGE
kubia-0   1/1     Running   0          8s
kubia-1   1/1     Running   0          21m
```

Now we will use API server to communicate the kubia-0, it's another option like forward port:

First, run proxy:

```sh
kubectl proxy
```

Send HTTP GET request to the URL with template: `<apiServerHost>:<port>/api/v1/namespaces/default/pods/kubia-0/proxy/<path>`

```curl
curl 127.0.0.1:8001/api/v1/namespaces/default/pods/kubia-0/proxy/
```

```
You've hit kubia-0
Data stored on this pod: Hello kubia-0
```

It's data persistence!

