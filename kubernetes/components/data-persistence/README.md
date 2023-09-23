### Volume

### Share data between containers with `emptyDir`

Step 1: Create deployment with emptyDir volume:

```sh
kubectl apply -f emptydir-volume.yaml
```

Step 2: Tracking logs in pods:

```sh
kubectl get pods
kubectl logs -f my-app-68f4bfd84c-79wvl log-sidecar
```

```
NAME                      READY   STATUS    RESTARTS   AGE
my-app-68f4bfd84c-79wvl   2/2     Running   0          9s

Thu Apr  7 14:44:10 UTC 2022 INFO some app data
Thu Apr  7 14:44:15 UTC 2022 INFO some app data
Thu Apr  7 14:44:20 UTC 2022 INFO some app data
Thu Apr  7 14:44:25 UTC 2022 INFO some app data
Thu Apr  7 14:44:30 UTC 2022 INFO some app data
Thu Apr  7 14:44:35 UTC 2022 INFO some app data
Thu Apr  7 14:44:40 UTC 2022 INFO some app data
```

### `PersistentVolumeClaims` and `PersistentVolumes`

The `PersistentVolumes` is resource that communicate with Storage, and the `PersistentVolumeClaims` request resource from `PersistentVolumes`. In production environment, the administrator will create the cluster, install plugin, ... while the developers will write yaml file to deploy application. So, the `PersistentVolumes` will created by the administrator, the developers only need to create `PersistentVolumeClaims` to use.


Suppose you are administrator, you will create the `PersistentVolumes`:

```sh
kubectl apply -f pv.yaml
kubectl get pv
```

```
NAME      CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
data-pv   10Gi       RWO            Retain           Available                                   59s
```

Note that the `PersistentVolumes` is not belong to any namespace, this is cluster resource, same as node. But the Pod, Deployment, ... is the namespace resource.

Now, suppose you are developers, you need to create `PersistentVolumeClaims` to store persistent data. If exist any `PersistentVolumes`, the `PersistentVolumeClaims` you created will request storage from it.

```sh
kubectl apply -f pvc.yaml
kubectl get pvc
```

```
NAME             STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
mysql-data-pvc   Bound    pvc-e5d8e277-3831-4a1b-b9c4-351df960f58a   5Gi        RWO            standard       7s
```

The STATUS=Bound indicate that the `mysql-data-pvc` bounded `pvc-e5d8e277-3831-4a1b-b9c4-351df960f58a` volume, now let's show the pv:

```sh
kubectl get pv
```

```
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM                    STORAGECLASS   REASON   AGE
data-pv                                    10Gi       RWO            Retain           Available                                                    119s
pvc-e5d8e277-3831-4a1b-b9c4-351df960f58a   5Gi        RWO            Delete           Bound       default/mysql-data-pvc   standard                31s
```

The `default/mysql-data-pvc` pvc was claimed resource from `pvc-e5d8e277-3831-4a1b-b9c4-351df960f58a` pv.
