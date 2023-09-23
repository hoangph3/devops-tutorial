### Configure the node's network for a pod

A pod with `hostNetwork: true` uses the node's network interfaces instead of its own.

```yaml
# pod-host-network.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-host-network
spec:
  hostNetwork: true
  containers:
  - name: main
    image: busybox
    command: ['sh', '-c']
    args:
    - echo "$(date) Hello Kubernetes !";
      sleep 999999;
```

```sh
kubectl apply -f pod-host-network.yaml
```

```
$ kubectl exec -it pod-host-network -- sh
/ # ifconfig 
docker0   Link encap:Ethernet  HWaddr 02:42:80:85:1A:48  
          inet addr:172.17.0.1  Bcast:172.17.255.255  Mask:255.255.0.0
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:14359 errors:0 dropped:0 overruns:0 frame:0
          TX packets:15146 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0 
          RX bytes:1433351 (1.3 MiB)  TX bytes:5055820 (4.8 MiB)

eth0      Link encap:Ethernet  HWaddr 02:42:C0:A8:31:02  
          inet addr:192.168.49.2  Bcast:192.168.49.255  Mask:255.255.255.0
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:3718 errors:0 dropped:0 overruns:0 frame:0
          TX packets:3598 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0 
          RX bytes:1441107 (1.3 MiB)  TX bytes:1062006 (1.0 MiB)

lo        Link encap:Local Loopback  
          inet addr:127.0.0.1  Mask:255.0.0.0
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:486808 errors:0 dropped:0 overruns:0 frame:0
          TX packets:486808 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000 
          RX bytes:96821077 (92.3 MiB)  TX bytes:96821077 (92.3 MiB)

veth0953ee8 Link encap:Ethernet  HWaddr F2:DD:B9:2F:C6:7B  
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:2 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0 
          RX bytes:0 (0.0 B)  TX bytes:84 (84.0 B)

veth8447375 Link encap:Ethernet  HWaddr 42:4F:33:37:87:C4  
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:2 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0 
          RX bytes:0 (0.0 B)  TX bytes:84 (84.0 B)

...
```

We can see the eth0 ip is the control plane ip (`use: $ kubectl cluster-info`).

Without `hostNetwork: true`:

```
$ kubectl exec -it pod-host-network -- sh
/ # ifconfig
eth0      Link encap:Ethernet  HWaddr 02:42:AC:11:00:07  
          inet addr:172.17.0.7  Bcast:172.17.255.255  Mask:255.255.0.0
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0 
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

lo        Link encap:Local Loopback  
          inet addr:127.0.0.1  Mask:255.0.0.0
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000 
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)
```

### Configure hostPort for a pod

If a host port is used, only a single pod instance can be scheduled to a node, because the port is already bound.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-host-port
spec:
  containers:
  - name: main
    image: busybox
    command: ['sh', '-c']
    args:
    - echo "$(date) Hello Kubernetes !";
      sleep 999999;
    ports:
      - containerPort: 8080
        hostPort: 9000
        protocol: TCP
```

```sh
kubectl apply -f pod-host-port.yaml
```

### Configure hostPID, hostIPC for a pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-host-pid-ipc
spec:
  hostPID: true
  hostIPC: true
  containers:
  - name: main
    image: busybox
    command: ['sh', '-c']
    args:
    - echo "$(date) Hello Kubernetes !";
      sleep 999999;
```

```sh
kubectl apply -f pod-host-pid-ipc.yaml
```

By setting the `hostIPC: true`, processes in the pod's containers can also communicate with all the other processes running on the node, through Inter-Process Communication.

```
$ kubectl exec -it pod-host-pid-ipc -- sh
/ # ps aux
PID   USER     TIME  COMMAND
    1 root      0:01 {systemd} /sbin/init
   96 root      0:00 /lib/systemd/systemd-journald
  108 108       0:00 /usr/bin/dbus-daemon --system --address=systemd: --nofork -
  114 root      0:05 /usr/bin/containerd
  121 root      0:00 sshd: /usr/sbin/sshd -D [listener] 0 of 10-100 startups
  213 root      2:45 /usr/bin/dockerd -H tcp://0.0.0.0:2376 -H unix:///var/run/d
  805 root      5:53 /var/lib/minikube/binaries/v1.22.3/kubelet --bootstrap-kube
 1439 root      0:00 /usr/bin/containerd-shim-runc-v2 -namespace moby -id 90ed40
 1440 root      0:00 /usr/bin/containerd-shim-runc-v2 -namespace moby -id ea5af7
 1444 root      0:00 /usr/bin/containerd-shim-runc-v2 -namespace moby -id 1604e3
 1446 root      0:00 /usr/bin/containerd-shim-runc-v2 -namespace moby -id 6d4476
 1518 65535     0:00 /pause
 1520 65535     0:00 /pause
 1528 65535     0:00 /pause
 1529 65535     0:00 /pause
 ...
```

### Running a container as a specific user

Make the container run as user guest with chown: 405.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-as-guest
spec:
  containers:
  - name: main
    image: busybox
    command: ["/bin/sleep", "999999"]
    securityContext:
      runAsUser: 405
```

```sh
kubectl apply -f pod-as-guest.yaml
```

Now we will run the id command in this new pod:

```
$ kubectl exec -it pod-as-guest -- sh
/ $ id
uid=405 gid=0(root)
/ $ 
```

### Preventing a container from running as root

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-as-non-root
spec:
  containers:
  - name: main
    image: busybox
    command: ["/bin/sleep", "999999"]
    securityContext:
      runAsNonRoot: true
```

```sh
kubectl apply -f pod-as-non-root.yaml
```

If you deploy this pod, it gets scheduled, but is not allowed to run:

```sh
kubectl get pods
kubectl describe pods pod-as-non-root
```

```
kubectl get pods                     
NAME              READY   STATUS                       RESTARTS   AGE
pod-as-non-root   0/1     CreateContainerConfigError   0          4m24s

Events:
  Type     Reason     Age                    From               Message
  ----     ------     ----                   ----               -------
  Normal   Scheduled  4m47s                  default-scheduler  Successfully assigned default/pod-as-non-root to minikube
  Normal   Pulled     3m18s                  kubelet            Successfully pulled image "busybox" in 3.064278141s
  Warning  Failed     3m1s (x8 over 4m43s)   kubelet            Error: container has runAsNonRoot and image will run as root (pod: "pod-as-non-root_default(fd120b40-998e-4421-b054-ed7284df9b00)", container: main)
  Normal   Pulled     3m1s                   kubelet            Successfully pulled image "busybox" in 3.002184008s
  Normal   Pulling    2m47s (x9 over 4m46s)  kubelet            Pulling image "busybox"
```

### Running pods in privileged mode

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-privileged
spec:
  containers:
  - name: main
    image: busybox
    command: ["/bin/sleep", "999999"]
    securityContext:
      privileged: true
```

```sh
kubectl apply -f pod-privileged.yaml
```

We can list the device files your privileged pod. In fact, the privileged container sees
all the host node’s devices. This means it can use any device freely.

```
$ kubectl exec -it pod-privileged -- sh
/ # ls /dev
autofs           kmsg             rtc0             tty13            tty30            tty48            tty8             vcs6             vcsu7
bsg              kvm              sda              tty14            tty31            tty49            tty9             vcs7             vcsu8
btrfs-control    loop-control     sda1             tty15            tty32            tty5             ttyS0            vcs8             vfio
bus              mapper           sda2             tty16            tty33            tty50            ttyS1            vcsa             vga_arbiter
core             media0           sg0              tty17            tty34            tty51            ttyS2            vcsa1            vhci
cpu              mei0             shm              tty18            tty35            tty52            ttyS3            vcsa2            vhost-net
cpu_dma_latency  mem              snapshot         tty19            tty36            tty53            uhid             vcsa3            vhost-vsock
cuse             mqueue           snd              tty2             tty37            tty54            uinput           vcsa4            video0
dri              net              stderr           tty20            tty38            tty55            urandom          vcsa5            video1
drm_dp_aux0      null             stdin            tty21            tty39            tty56            vboxdrv          vcsa6            watchdog
drm_dp_aux1      nvram            stdout           tty22            tty4             tty57            vboxdrvu         vcsa7            watchdog0
drm_dp_aux2      port             termination-log  tty23            tty40            tty58            vboxnetctl       vcsa8            watchdog1
fb0              ppp              tpm0             tty24            tty41            tty59            vboxusb          vcsu             zero
fd               psaux            tty              tty25            tty42            tty6             vcs              vcsu1
full             ptmx             tty0             tty26            tty43            tty60            vcs1             vcsu2
fuse             ptp0             tty1             tty27            tty44            tty61            vcs2             vcsu3
hidraw0          pts              tty10            tty28            tty45            tty62            vcs3             vcsu4
hpet             random           tty11            tty29            tty46            tty63            vcs4             vcsu5
input            rfkill           tty12            tty3             tty47            tty7             vcs5             vcsu6
```

### Dropping capabilities from a container

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-drop-chown-capability
spec:
  containers:
  - name: main
    image: busybox
    command: ["/bin/sleep", "999999"]
    securityContext:
      capabilities:
        drop:
        - CHOWN
```

```sh
kubectl apply -f pod-drop-chown-capability.yaml
```

By dropping the CHOWN capability, you're not allowed to change the owner of the /tmp directory in this pod:

```
$ kubectl exec -it pod-drop-chown-capability -- sh
/ # chown 1000:1000 /tmp/
chown: /tmp/: Operation not permitted
```

### Preventing processes from writing to the container's filesystem

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-readonly-filesystem
spec:
  containers:
  - name: main
    image: busybox
    command: ["/bin/sleep", "999999"]
    securityContext:
      readOnlyRootFilesystem: true
    volumeMounts:
    - name: my-volume
      mountPath: /volume
      readOnly: false
  volumes:
  - name: my-volume
    emptyDir:
```

```sh
kubectl apply -f pod-with-readonly-filesystem.yaml
```

When you deploy this pod, the container is running as root, which has write permissions to the / directory, but trying to write a file there fails:

```
$ kubectl exec -it pod-with-readonly-filesystem -- sh 
/ # touch a.txt
touch: a.txt: Read-only file system
```

### Sharing volumes when containers run as different users

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-shared-volume
spec:
  containers:
  - name: first
    image: busybox
    command: ["/bin/sleep", "999999"]
    securityContext:
      runAsUser: 1111
    volumeMounts:
    - name: shared-volume
      mountPath: /volume
      readOnly: false
  - name: second
    image: busybox
    command: ["/bin/sleep", "999999"]
    securityContext:
      runAsUser: 2222
    volumeMounts:
    - name: shared-volume
      mountPath: /volume
      readOnly: false
  volumes:
  - name: shared-volume
    emptyDir:
```

The first container runs as user ID 1111, the second container runs as user ID 2222, and both containers use the same volume.

```sh
kubectl apply -f pod-with-shared-volume.yaml
```

```
$ kubectl exec -it pod-with-shared-volume -c first -- sh
/ $ ls -la | grep volume
drwxrwxrwx    2 root     root          4096 Apr 20 16:37 volume
/ $ echo foo > volume/foo 
/ $ ls -la volume/
total 12
drwxrwxrwx    2 root     root          4096 Apr 20 16:37 .
drwxr-xr-x    1 root     root          4096 Apr 20 16:32 ..
-rw-r--r--    1 1111     root             4 Apr 20 16:39 foo
```

As you can see, the group ID is always root, the container runs as user ID that we set in `.spec.securityContext.runAsUser`.

What happen when we define the `fsGroup` and `supplementalGroups` in the security context at the pod level?

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-shared-volume-fsgroup
spec:
  securityContext:
    fsGroup: 555
    supplementalGroups: [666, 777]
  containers:
  - name: first
    image: busybox
    command: ["/bin/sleep", "999999"]
    securityContext:
      runAsUser: 1111
    volumeMounts:
    - name: shared-volume
      mountPath: /volume
      readOnly: false
  - name: second
    image: busybox
    command: ["/bin/sleep", "999999"]
    securityContext:
      runAsUser: 2222
    volumeMounts:
    - name: shared-volume
      mountPath: /volume
      readOnly: false
  volumes:
  - name: shared-volume
    emptyDir:
```

```sh
kubectl apply -f pod-with-shared-volume-fsgroup.yaml
```

```
$ kubectl exec -it pod-with-shared-volume-fsgroup -c first -- sh
/ $ id
uid=1111 gid=0(root) groups=555,666,777
/ $ ls -la | grep volume
drwxrwsrwx    2 root     555           4096 Apr 20 16:42 volume
/ $ echo bar > volume/bar
/ $ ls -la volume/
total 12
drwxrwsrwx    2 root     555           4096 Apr 20 16:43 .
drwxr-xr-x    1 root     root          4096 Apr 20 16:42 ..
-rw-r--r--    1 1111     555              4 Apr 20 16:43 bar
/ $ echo foo > tmp/foo
/ $ ls -la tmp/
total 12
drwxrwxrwt    1 root     root          4096 Apr 20 16:43 .
drwxr-xr-x    1 root     root          4096 Apr 20 16:42 ..
-rw-r--r--    1 1111     root             4 Apr 20 16:43 foo
```

In the pod definition, we set `fsGroup` to `555`, so the mounted volume will be owned by group ID `555`. And because we create a file in the mounted volume's directory, the file is owned by user ID `1111` and by group ID `555`.

### Enabling network isolation in a namespace

By default, pods in a given namespace can be accessed by anyone. Now we can use `NetworkPolicy` to prevent all clients from connecting to any pod in your namespace.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
spec:
  podSelector:
```

Note that: Empty pod selector matches all pods in the same namespace.

To let clients connect to the pods in the namespace, you must now explicitly say who can connect to the pods.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: postgres-netpolicy
spec:
  podSelector:
    matchLabels:
      app: database
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: webserver
    ports:
    - port: 5432
```

The example `NetworkPolicy` allows pods with the `app=webserver` label to connect to pods with the `app=database` label, only on port `5432`. Other pods can't connect to the database pods, and no one (not even the webserver pods) can connect to anything other than port `5432` of the database pods.

A `NetworkPolicy` only allowing pods in namespaces matching a `namespaceSelector` to access a specific pod.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: shoppingcart-netpolicy
spec:
  podSelector:
    matchLabels:
      app: shopping-cart 
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          tenant: manning
    ports:
    - port: 80
```

You can also specify an IP block in CIDR notation.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ipblock-netpolicy
spec:
  podSelector:
    matchLabels:
      app: shopping-cart
  ingress:
  - from:
    - ipBlock:
        cidr: 192.168.1.0/24
```

You can also limit their outbound traffic through egress rules.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: egress-net-policy
spec:
  podSelector:
    matchLabels:
      app: webserver
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - port: 5432
```