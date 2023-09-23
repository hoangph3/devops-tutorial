### Note: Support 1 local machine with nvidia-gpu, and minikube on it

Step 1: setup gpu (secureBoot must be off)

- install nvidia-driver (nvidia-driver-515), cuda (11.7), cudnn following the instructions: https://developer.nvidia.com/cuda-downloads

Step 2: install minikube (v1.25.2)

```sh
$ curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
$ sudo dpkg -i minikube_latest_amd64.deb
$ minikube version
minikube version: v1.25.2
commit: 362d5fdc0a3dbee389b3d3f1034e8023e72bd3a7
```

Step 3: install nvidia-docker

```sh
$ wget http://mirror.cs.uchicago.edu/nvidia-docker/libnvidia-container/stable/ubuntu18.04/amd64/libnvidia-container1_1.9.0-1_amd64.deb (libnvidia-container1)
$ wget http://mirror.cs.uchicago.edu/nvidia-docker/libnvidia-container/stable/ubuntu18.04/amd64/libnvidia-container-tools_1.9.0-1_amd64.deb (libnvidia-container-tools)

$ sudo dpkg -i libnvidia-container1_1.9.0-1_amd64.deb libnvidia-container-tools_1.9.0-1_amd64.deb
```

```sh
$ wget http://mirror.cs.uchicago.edu/nvidia-docker/libnvidia-container/stable/ubuntu18.04/amd64/nvidia-container-runtime_3.9.0-1_all.deb (nvidia-container-runtime)
$ wget http://mirror.cs.uchicago.edu/nvidia-docker/libnvidia-container/stable/ubuntu18.04/amd64/nvidia-container-toolkit_1.9.0-1_amd64.deb (nvidia-container-toolkit)
$ wget http://mirror.cs.uchicago.edu/nvidia-docker/libnvidia-container/stable/ubuntu18.04/amd64/nvidia-docker2_2.10.0-1_all.deb (nvidia-docker2)

$ sudo dpkg -i nvidia-container-runtime_3.9.0-1_all.deb nvidia-container-toolkit_1.9.0-1_amd64.deb nvidia-docker2_2.10.0-1_all.deb
```

Step 4: config daemon docker in `/etc/docker/daemon.json`

```json
{
    "runtimes": {
        "nvidia": {
            "path": "nvidia-container-runtime",
            "runtimeArgs": []
        }
    },
    "default-runtime": "nvidia"
}
```

Step 5: download kube-system images from https://hub.docker.com/ (because the proxy server has no connection to https://k8s.gcr.io/)

List the images of kubernetes cluster:

```sh
$ kubeadm config images list
W0618 11:26:15.229688   15772 version.go:103] could not fetch a Kubernetes version from the internet: unable to get URL "https://dl.k8s.io/release/stable-1.txt": Get "https://dl.k8s.io/release/stable-1.txt": x509: certificate signed by unknown authority
W0618 11:26:15.229716   15772 version.go:104] falling back to the local client version: v1.24.2

k8s.gcr.io/kube-apiserver:v1.24.2
k8s.gcr.io/kube-controller-manager:v1.24.2
k8s.gcr.io/kube-scheduler:v1.24.2
k8s.gcr.io/kube-proxy:v1.24.2
k8s.gcr.io/pause:3.7
k8s.gcr.io/etcd:3.5.3-0
k8s.gcr.io/coredns/coredns:v1.8.6
```

Now we will pull images (stable version v1.23.3), also we need to pull the `storage-provider` image:

```sh
# api-server
$ docker pull k8simage/kube-apiserver:v1.23.3

# controller-manager
$ docker pull k8simage/kube-controller-manager:v1.23.3

# scheduler
$ docker pull k8simage/kube-scheduler:v1.23.3

# proxy
$ docker pull k8simage/kube-proxy:v1.23.3

# pause
$ docker pull k8simage/pause:3.6

# etcd
$ docker pull k8simage/etcd:3.5.1-0

# coredns
$ docker pull k8simage/coredns:v1.8.6

# storage-provisioner
$ docker pull yedward/gcr.io.k8s-minikube.storage-provisioner:v1.8.1
```

Then re-tag image to ensure that the image's name same as the image name will pulled when run `minikube start`:

```sh
# api-server
$ docker tag k8simage/kube-apiserver:v1.23.3 k8s.gcr.io/kube-apiserver:v1.23.3

# controller-manager
$ docker tag k8simage/kube-controller-manager:v1.23.3 k8s.gcr.io/kube-controller-manager:v1.23.3

# scheduler
$ docker tag k8simage/kube-scheduler:v1.23.3 k8s.gcr.io/kube-scheduler:v1.23.3

# proxy
$ docker tag k8simage/kube-proxy:v1.23.3 k8s.gcr.io/kube-proxy:v1.23.3

# pause
$ docker tag k8simage/pause:3.6 k8s.gcr.io/pause:3.6

# etcd
$ docker tag k8simage/etcd:3.5.1-0 k8s.gcr.io/etcd:3.5.1-0

# coredns
$ docker tag k8simage/coredns:v1.8.6 k8s.gcr.io/coredns/coredns:v1.8.6

# storage-provisioner
$ docker tag yedward/gcr.io.k8s-minikube.storage-provisioner:v1.8.1 gcr.io/k8s-minikube/storage-provisioner:v5
```

Step 6: start minikube cluster

Initialize the cluster as `root` privileges:

```sh
$ sudo -i
$ minikube start --driver=none --apiserver-ips 127.0.0.1 --apiserver-name localhost
```

Change the permission to `$USER`:

```sh
$ sudo mv /root/.kube /root/.minikube $HOME
$ sudo chown -R $USER $HOME/.kube $HOME/.minikube
```

Edit kubernetes config file, change `certificate-authority`, `client-certificate`, and `client-key` from root path to $USER path:

```yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /home/hoang/.minikube/ca.crt
    extensions:
    - extension:
        last-update: Fri, 17 Jun 2022 17:10:56 +07
        provider: minikube.sigs.k8s.io
        version: v1.25.2
      name: cluster_info
    server: https://localhost:8443
  name: minikube
contexts:
- context:
    cluster: minikube
    extensions:
    - extension:
        last-update: Fri, 17 Jun 2022 17:10:56 +07
        provider: minikube.sigs.k8s.io
        version: v1.25.2
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
    client-certificate: /home/hoang/.minikube/profiles/minikube/client.crt
    client-key: /home/hoang/.minikube/profiles/minikube/client.key
```

Step 7: install NVIDIA's device plugin

Create the manifest yaml file `nvidia-device-plugin.yml`:

```yaml
# Copyright (c) 2019, NVIDIA CORPORATION.  All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: nvidia-device-plugin-daemonset
  namespace: kube-system
spec:
  selector:
    matchLabels:
      name: nvidia-device-plugin-ds
  updateStrategy:
    type: RollingUpdate
  template:
    metadata:
      labels:
        name: nvidia-device-plugin-ds
    spec:
      tolerations:
      - key: nvidia.com/gpu
        operator: Exists
        effect: NoSchedule
      # Mark this pod as a critical add-on; when enabled, the critical add-on
      # scheduler reserves resources for critical add-on pods so that they can
      # be rescheduled after a failure.
      # See https://kubernetes.io/docs/tasks/administer-cluster/guaranteed-scheduling-critical-addon-pods/
      priorityClassName: "system-node-critical"
      containers:
      - image: nvidia/k8s-device-plugin
        name: nvidia-device-plugin-ctr
        env:
          - name: FAIL_ON_INIT_ERROR
            value: "false"
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop: ["ALL"]
        volumeMounts:
          - name: device-plugin
            mountPath: /var/lib/kubelet/device-plugins
      volumes:
        - name: device-plugin
          hostPath:
            path: /var/lib/kubelet/device-plugins
```

Create the daemonset:

```sh
$ kubectl create -f nvidia-device-plugin.yml
```

Step 8: testing

Create the manifest yaml file `gpu-demo.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gpu-demo
spec:
  selector:
    matchLabels:
      app: gpu
  replicas: 2
  template:
    metadata:
      labels:
        app: gpu
    spec:
      containers:
      - name: gpu-demo
        image: nvidia/cuda:10.1-cudnn7-runtime-ubuntu18.04
        command: ["/bin/sh", "-c"]
        args: ["nvidia-smi && tail -f /dev/null"]
        ports:
        - containerPort: 80
```

Create the deployment:

```sh
$ kubectl apply -f gpu-demo.yaml
deployment.apps/gpu-demo created
```

Tracking pods:

```sh
$ kubectl get pods
NAME                        READY   STATUS    RESTARTS   AGE
gpu-demo-78b68dbfb6-wdxns   1/1     Running   0          58s
gpu-demo-78b68dbfb6-wkk25   1/1     Running   0          58s

$ kubectl logs -f gpu-demo-78b68dbfb6-wdxns
Fri Jun 17 11:45:07 2022
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 515.43.04    Driver Version: 515.43.04    CUDA Version: 11.7     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|                               |                      |               MIG M. |
|===============================+======================+======================|
|   0  NVIDIA GeForce ...  On   | 00000000:01:00.0  On |                  N/A |
| 30%   38C    P8    35W / 350W |    544MiB / 24576MiB |     12%      Default |
|                               |                      |                  N/A |
+-------------------------------+----------------------+----------------------+
                                                                               
+-----------------------------------------------------------------------------+
| Processes:                                                                  |
|  GPU   GI   CI        PID   Type   Process name                  GPU Memory |
|        ID   ID                                                   Usage      |
|=============================================================================|
+-----------------------------------------------------------------------------+
```
