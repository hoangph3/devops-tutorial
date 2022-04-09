### Configure Liveness, Readiness and Startup Probes

### Configure `livenessProbe` by execute command

```yaml
# exec-liveness.yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-exec
spec:
  containers:
  - name: liveness
    image: busybox
    args:
    - /bin/sh
    - -c
    - touch /tmp/healthy; sleep 30; rm -rf /tmp/healthy; sleep 600
    livenessProbe:
      exec: # the kubelet executes the command to perform a probe
        command:
        - cat
        - /tmp/healthy
      initialDelaySeconds: 5 # perform a liveness probe every 5 seconds
      periodSeconds: 5 # wait 5 seconds before performing the first probe
```

In `livenessProbe` section, the kubelet executes the command `cat /tmp/healthy` to perform a probe.

`initialDelaySeconds`: perform a liveness probe every 5 seconds.

`periodSeconds`: wait 5 seconds before performing the first probe.

If the command succeeds (returns 0), the kubelet considers the container to be alive and healthy. Otherwise, the kubelet kills the container and restarts it (returns a non-zero value).

Let's create the pod:

```sh
kubectl apply -f exec-liveness.yaml
```

Now we can describe the pod:

```sh
kubectl describe pod liveness-exec
```

```
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  21s   default-scheduler  Successfully assigned default/liveness-exec to minikube
  Normal  Pulling    20s   kubelet            Pulling image "busybox"
  Normal  Pulled     17s   kubelet            Successfully pulled image "busybox" in 3.800450597s
  Normal  Created    16s   kubelet            Created container liveness
  Normal  Started    16s   kubelet            Started container livenesss
```

Wait for half a minute, then describe the pod:

```
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  66s                default-scheduler  Successfully assigned default/liveness-exec to minikube
  Normal   Pulling    65s                kubelet            Pulling image "busybox"
  Normal   Pulled     62s                kubelet            Successfully pulled image "busybox" in 3.800450597s
  Normal   Created    61s                kubelet            Created container liveness
  Normal   Started    61s                kubelet            Started container liveness
  Warning  Unhealthy  21s (x3 over 31s)  kubelet            Liveness probe failed: cat: can't open '/tmp/healthy': No such file or directory
  Normal   Killing    21s                kubelet            Container liveness failed liveness probe, will be restarted
```

As above, the pod is unhealthy and the kubelet will kill the container and restart it:

```
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  83s                default-scheduler  Successfully assigned default/liveness-exec to minikube
  Normal   Pulled     79s                kubelet            Successfully pulled image "busybox" in 3.800450597s
  Warning  Unhealthy  38s (x3 over 48s)  kubelet            Liveness probe failed: cat: can't open '/tmp/healthy': No such file or directory
  Normal   Killing    38s                kubelet            Container liveness failed liveness probe, will be restarted
  Normal   Pulling    8s (x2 over 82s)   kubelet            Pulling image "busybox"
  Normal   Created    4s (x2 over 78s)   kubelet            Created container liveness
  Normal   Started    4s (x2 over 78s)   kubelet            Started container liveness
  Normal   Pulled     4s                 kubelet            Successfully pulled image "busybox" in 3.417375064s
```

### Configure `livenessProbe` by HTTP GET request

```yaml
# http-liveness.yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-http
spec:
  containers:
  - name: liveness
    image: k8s.gcr.io/liveness
    args:
    - /server
    livenessProbe:
      httpGet: # the kubelet sends HTTP GET request
        path: /healthz
        port: 8080 # listening on port 8080
        httpHeaders:
        - name: Custom-Header
          value: Awesome
      initialDelaySeconds: 3
      periodSeconds: 3
```

To perform a probe, the kubelet sends an HTTP GET request to the server that is running in the container and listening on port 8080. If the handler for the server's `/healthz` path returns a success code (`[200;400)`), the kubelet considers the container to be alive and healthy. If the handler returns a failure code, the kubelet kills the container and restarts it.

```sh
kubectl apply -f http-liveness.yaml
kubectl get pods
```

```
NAME            READY   STATUS    RESTARTS     AGE
liveness-http   1/1     Running   2 (2s ago)   41s
```

After a minute, let's describe the pod:

```sh
kubectl describe pods liveness-http
```

```
Events:
  Type     Reason     Age               From               Message
  ----     ------     ----              ----               -------
  Normal   Scheduled  45s               default-scheduler  Successfully assigned default/liveness-http to minikube
  Normal   Pulled     43s               kubelet            Successfully pulled image "k8s.gcr.io/liveness" in 1.461349146s
  Normal   Pulled     23s               kubelet            Successfully pulled image "k8s.gcr.io/liveness" in 1.51144169s
  Warning  Unhealthy  6s (x6 over 30s)  kubelet            Liveness probe failed: HTTP probe failed with statuscode: 500
  Normal   Killing    6s (x2 over 24s)  kubelet            Container liveness failed liveness probe, will be restarted
  Normal   Pulling    6s (x3 over 44s)  kubelet            Pulling image "k8s.gcr.io/liveness"
  Normal   Created    5s (x3 over 43s)  kubelet            Created container liveness
  Normal   Started    5s (x3 over 43s)  kubelet            Started container liveness
  Normal   Pulled     5s                kubelet            Successfully pulled image "k8s.gcr.io/liveness" in 1.421177595s
```

### Configure `livenessProbe`, `readinessProbe` by TCP socket

In Kubernetes, you can use `readinessProbe` to ensure that traffic does not reach a container that is not ready for it. For example, an application might need to load large data or configuration files during startup, or depend on external services after startup. In such cases, you don't want to kill the application, but you don't want to send it requests either. Note that `readinessProbe` runs on the container during its whole lifecycle.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-health-probes
spec:
  containers:
  - image: nginx
    name: myapp-container
    ports:
    - containerPort: 80
    readinessProbe:
      tcpSocket:
        port: 80
      initialDelaySeconds: 10
      periodSeconds: 5
    livenessProbe:
      tcpSocket:
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 15
```

Let's create pod:

```sh
kubectl apply -f tcp-liveness-readiness.yaml
kubectl describe pod myapp-health-probes
```

```
Events:
  Type    Reason     Age    From               Message
  ----    ------     ----   ----               -------
  Normal  Scheduled  8m30s  default-scheduler  Successfully assigned default/myapp-health-probes to minikube
  Normal  Pulling    8m29s  kubelet            Pulling image "nginx"
  Normal  Pulled     8m13s  kubelet            Successfully pulled image "nginx" in 16.010486815s
  Normal  Created    8m13s  kubelet            Created container myapp-container
  Normal  Started    8m13s  kubelet            Started container myapp-container
```

### Configure `startupProbe`

Additionally, you can protect slow starting containers with `startupProbe`. Because sometimes, you have to deal with legacy applications that might require an additional startup time on their first initialization.

The trick is to set up a `startupProbe` with the same command, HTTP or TCP check, with a `failureThreshold * periodSeconds` long enough to cover the worse case startup time.

```yaml
ports:
- name: liveness-port
  containerPort: 8080
  hostPort: 8080

livenessProbe:
  httpGet:
    path: /healthz
    port: liveness-port
  failureThreshold: 1
  periodSeconds: 10

startupProbe:
  httpGet:
    path: /healthz
    port: liveness-port
  failureThreshold: 30
  periodSeconds: 10
```

As the `startupProbe` section, the application will have a maximum of 30 * 10 = 300s to finish its startup.

Once the `startupProbe` has succeeded once, the `livenessProbe` takes over to provide a fast response to container deadlocks. If the `startupProbe` never succeeds, the container is killed after 300s and subject to the pod's `restartPolicy`.