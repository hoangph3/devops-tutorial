### Running a single completable task by Job

```yaml
# job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: my-job
spec:
  template:
    metadata:
      labels:
        app: my-job
    spec:
      containers:
      - name: my-job
        image: busybox
        command: ['sh', '-c']
        args: 
        - echo "$(date) Job starting";
          sleep 30;
          echo "$(date) Finished succesfully";
      restartPolicy: OnFailure
```

The YAML defines a Job that will run the busybox image, which invokes a process that runs for exactly 30 seconds and then exits. In spec section, the `restartPolicy` is set `OnFailure`, because Job can't use the default restart policy (which is `Always`). This setting is what prevents the container from being restarted when it finishes.

After we run command `kubectl apply -f job.yaml` to create job, we can list pods by `kubectl get pods`:

```
NAME              READY   STATUS    RESTARTS   AGE
my-job--1-4n4rk   1/1     Running   0          8s
```

After 30 seconds have passed, the job has completed and no restart:

```
NAME              READY   STATUS      RESTARTS   AGE
my-job--1-4n4rk   0/1     Completed   0          39s
```

We can get log of job:

```sh
kubectl logs -f my-job--1-4n4rk
```

```
Sat Apr  9 15:34:32 UTC 2022 Job starting
Sat Apr  9 15:35:02 UTC 2022 Finished succesfully
```

To running job pods sequentially or parallel, we can configure the `.spec.completions` and the `.spec.parallelism`:

```yaml
# batch-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: my-job
spec:
  completions: 5  # this job must ensure 5 pods complete successfully
  parallelism: 2  # up to 2 pods can run in parallel
  template:
    metadata:
      labels:
        app: my-job
    spec:
      containers:
      - name: my-job
        image: busybox
        command: ['sh', '-c']
        args: 
        - echo "$(date) Job starting";
          sleep 30;
          echo "$(date) Finished succesfully";
      restartPolicy: OnFailure
```

With `completions: 5` indicate that this job must ensure 5 pods complete successfully, and up to 2 pods can run in parallel with `parallelism: 2`.

```sh
kubectl get pods
kubectl get jobs
```

```
NAME              READY   STATUS    RESTARTS   AGE
my-job--1-grq6l   1/1     Running   0          9s
my-job--1-w85p2   1/1     Running   0          9s

NAME     COMPLETIONS   DURATION   AGE
my-job   0/5           17s        17s
```

When the job completed:

```sh
kubectl get pods
kubectl get jobs
```

```
NAME              READY   STATUS      RESTARTS   AGE
my-job--1-cv5js   0/1     Completed   0          77s
my-job--1-grq6l   0/1     Completed   0          112s
my-job--1-khnbl   0/1     Completed   0          73s
my-job--1-w85p2   0/1     Completed   0          112s
my-job--1-x95mk   0/1     Completed   0          41s

NAME     COMPLETIONS   DURATION   AGE
my-job   5/5           107s       115s
```

### Scheduling Jobs to run periodically

Let's create a CronJob:

```yaml
# cron-job.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: cronjob-every-minute
spec:
  schedule: "* * * * *"
  jobTemplate:
    spec:
      template:
        metadata:
          labels:
            app: cronjob-every-minute
        spec:
          containers:
          - name: cronjob-every-minute
            image: busybox
            command: ['sh', '-c']
            args: 
            - echo "$(date) Job starting";
              sleep 30;
              echo "$(date) Finished succesfully";
          restartPolicy: OnFailure
```

```sh
kubectl apply -f cron-job.yaml
kubectl get cronjobs.batch
```

```
NAME                   SCHEDULE    SUSPEND   ACTIVE   LAST SCHEDULE   AGE
cronjob-every-minute   * * * * *   False     1        8s              44s
```

After 3 minutes, let's list of pods:

```sh
kubectl get pods
```

```
NAME                                     READY   STATUS      RESTARTS   AGE
cronjob-every-minute-27492030--1-qdtgl   0/1     Completed   0          2m38s
cronjob-every-minute-27492031--1-wl9jr   0/1     Completed   0          98s
cronjob-every-minute-27492032--1-rb6p6   0/1     Completed   0          38s
```

Print log of pods, we can see the job is scheduled every minute:

```sh
kubectl logs -f cronjob-every-minute-27492030--1-qdtgl
kubectl logs -f cronjob-every-minute-27492031--1-wl9jr
kubectl logs -f cronjob-every-minute-27492032--1-rb6p6
```

```
Sat Apr  9 16:30:04 UTC 2022 Job starting
Sat Apr  9 16:30:34 UTC 2022 Finished succesfully

Sat Apr  9 16:31:04 UTC 2022 Job starting
Sat Apr  9 16:31:34 UTC 2022 Finished succesfully

Sat Apr  9 16:32:04 UTC 2022 Job starting
Sat Apr  9 16:32:34 UTC 2022 Finished succesfully
```

The `.spec.successfulJobsHistoryLimit` and `.spec.failedJobsHistoryLimit` fields are optional. These fields specify how many completed and failed jobs should be kept. By default, they are set to 3 and 1 respectively.

Access to https://crontab.guru/ to get more info about cronjob schedule expressions.
