### Exercise 1: Create and Verify a Kind Cluster

**Task:**

1. Install Kind (if not already installed).
2. Create a new Kind cluster named `exercise-cluster`.
3. Confirm that both control-plane and worker nodes are in the `Ready` state.

**Steps You’ll Perform:**

* `kind create cluster --name exercise-cluster`
* `kubectl get nodes --context kind-exercise-cluster`

**Expected Outcome:**
You should see two nodes (e.g., `exercise-cluster-control-plane` and `exercise-cluster-worker`) listed as `Ready`.

---

### Exercise 2: Deploy a Basic NGINX Pod Using kubeadm-Created Cluster

**Prerequisite:** You must have a kubeadm-initialized cluster with at least one control-plane and one worker node.

**Task:**

1. Create a namespace called `demo-ns`.
2. Deploy a single-pod NGINX application in that namespace.
3. Expose it via a `ClusterIP` Service on port 80.
4. Verify that the Pod is running and the Service has an assigned ClusterIP.

**Steps You’ll Perform:**

* `kubectl create namespace demo-ns`
* Create a file `nginx-pod.yaml` with:

  ```yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: nginx-pod
    namespace: demo-ns
    labels:
      app: nginx
  spec:
    containers:
    - name: nginx
      image: nginx:1.21
      ports:
      - containerPort: 80
  ```
* `kubectl apply -f nginx-pod.yaml`
* Create a Service manifest `nginx-svc.yaml`:

  ```yaml
  apiVersion: v1
  kind: Service
  metadata:
    name: nginx-svc
    namespace: demo-ns
  spec:
    selector:
      app: nginx
    ports:
    - port: 80
      targetPort: 80
    type: ClusterIP
  ```
* `kubectl apply -f nginx-svc.yaml`
* `kubectl get pods -n demo-ns`
* `kubectl get svc -n demo-ns`

**Expected Outcome:**

* The pod `nginx-pod` should be in `Running` status.
* The service `nginx-svc` should show a `CLUSTER-IP` (e.g., `10.x.x.x`).

---

### Exercise 3: Label and Select Pods

**Task:**

1. In namespace `demo-ns`, label the `nginx-pod` with `environment=staging`.
2. Verify you can list the Pod using a label selector.
3. Add another label `tier=frontend` and then remove `environment` (without deleting the Pod).

**Steps You’ll Perform:**

* `kubectl label pod nginx-pod -n demo-ns environment=staging`
* `kubectl get pods -n demo-ns -l environment=staging`
* `kubectl label pod nginx-pod -n demo-ns tier=frontend`
* `kubectl label pod nginx-pod -n demo-ns environment-`

**Expected Outcome:**

* After the first command, `kubectl get pods -l environment=staging` should list `nginx-pod`.
* After removing `environment`, `nginx-pod` should no longer match `-l environment=staging`, but should match `-l tier=frontend`.

---

### Exercise 4: Work with ConfigMaps and Annotations

**Task:**

1. Create a ConfigMap named `app-config` in `demo-ns` that contains a key `welcome-message: "Hello, Kubernetes!"`.
2. Launch a Pod (`busybox-pod`) in `demo-ns` that mounts this ConfigMap as a file under `/config/message.txt`.
3. Annotate that Pod with `backup/daily=true`.
4. Verify both the ConfigMap mount and the annotation.

**Steps You’ll Perform:**

* Create `configmap.yaml`:

  ```yaml
  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: app-config
    namespace: demo-ns
  data:
    welcome-message: "Hello, Kubernetes!"
  ```
* `kubectl apply -f configmap.yaml`
* Create `busybox-pod.yaml`:

  ```yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: busybox-pod
    namespace: demo-ns
  spec:
    containers:
    - name: busybox
      image: busybox:1.35
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
      - name: config-volume
        mountPath: /config
    volumes:
    - name: config-volume
      configMap:
        name: app-config
  ```
* `kubectl apply -f busybox-pod.yaml`
* `kubectl annotate pod busybox-pod -n demo-ns backup/daily=true`
* `kubectl describe pod busybox-pod -n demo-ns` (look under Annotations)
* `kubectl exec -n demo-ns busybox-pod -- cat /config/welcome-message`

**Expected Outcome:**

* The annotation `backup/daily=true` appears in `kubectl describe`.
* Running the `cat` command inside the Pod prints: `Hello, Kubernetes!`

---

### Exercise 5: Create and Test a Deployment with Rolling Updates

**Task:**

1. Create a Deployment named `demo-deploy` in `demo-ns` running 2 replicas of `nginx:1.21.0`.
2. Confirm the two Pods are in `Running` status.
3. Simulate a rolling update by changing the image to `nginx:1.22.0`.
4. Verify that Pods are updated one at a time (observe `kubectl rollout status`).

**Steps You’ll Perform:**

* Create `deployment.yaml`:

  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: demo-deploy
    namespace: demo-ns
  spec:
    replicas: 2
    selector:
      matchLabels:
        app: demo-nginx
    template:
      metadata:
        labels:
          app: demo-nginx
      spec:
        containers:
        - name: nginx
          image: nginx:1.21.0
          ports:
          - containerPort: 80
  ```
* `kubectl apply -f deployment.yaml`
* `kubectl get pods -n demo-ns -l app=demo-nginx`
* Patch to `nginx:1.22.0`:

  ```bash
  kubectl patch deployment demo-deploy -n demo-ns \
    --type=merge \
    -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","image":"nginx:1.22.0"}]}}}}'
  ```
* `kubectl rollout status deployment/demo-deploy -n demo-ns`

**Expected Outcome:**

* Initially two pods run `nginx:1.21.0`.
* After patching, one Pod terminates and is replaced by one running `nginx:1.22.0`, then the second Pod follows—ensuring at least one Pod is always available.

---

### Exercise 6: Scale and Inspect ReplicaSets

**Task:**

1. Scale your `demo-deploy` from 2 to 4 replicas.
2. Observe how many ReplicaSets exist and which pods belong to which ReplicaSet.
3. Scale back down to 1 replica and verify that extra pods are deleted.

**Steps You’ll Perform:**

* `kubectl scale deployment/demo-deploy -n demo-ns --replicas=4`
* `kubectl get rs -n demo-ns -l app=demo-nginx`  (you’ll see new RS for `nginx:1.22.0`, and an old RS for `nginx:1.21.0`)
* `kubectl get pods -n demo-ns --show-labels`  (check the ReplicaSet ownerRef or use `kubectl describe pod <pod>`)
* `kubectl scale deployment/demo-deploy -n demo-ns --replicas=1`
* `kubectl get pods -n demo-ns`

**Expected Outcome:**

* After scaling to 4, you should see 4 pods belonging to the current ReplicaSet.
* After scaling to 1, three pods are terminated, leaving only one.

---

### Exercise 7: Deploy a StatefulSet with Persistent Storage

**Task:**

1. Create a Headless Service `web-headless` in `demo-ns` with `clusterIP: None` selecting `app=web`.
2. Define a StatefulSet named `web-sts` (2 replicas) with a `volumeClaimTemplates` block that requests 1Gi each. Use `busybox` containers writing to `/data` to simulate persistence.
3. Confirm that two PVCs (`data-web-sts-0` and `data-web-sts-1`) are created and bound.
4. Pod 0 should print its hostname and mount path at startup.

**Steps You’ll Perform:**

* Create `headless-svc.yaml`:

  ```yaml
  apiVersion: v1
  kind: Service
  metadata:
    name: web-headless
    namespace: demo-ns
  spec:
    clusterIP: None
    selector:
      app: web
    ports:
      - port: 80
        name: http
  ```
* `kubectl apply -f headless-svc.yaml`
* Create `statefulset.yaml`:

  ```yaml
  apiVersion: apps/v1
  kind: StatefulSet
  metadata:
    name: web-sts
    namespace: demo-ns
  spec:
    serviceName: "web-headless"
    replicas: 2
    selector:
      matchLabels:
        app: web
    template:
      metadata:
        labels:
          app: web
      spec:
        containers:
        - name: busybox
          image: busybox:1.35
          command:
          - sh
          - -c
          - |
            echo "Hostname: $(hostname)" > /data/identity.txt
            sleep 3600
          volumeMounts:
          - name: data
            mountPath: /data
    volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 1Gi
  ```
* `kubectl apply -f statefulset.yaml`
* `kubectl get pvc -n demo-ns`
* `kubectl exec -n demo-ns web-sts-0 -- cat /data/identity.txt`
* `kubectl exec -n demo-ns web-sts-1 -- cat /data/identity.txt`

**Expected Outcome:**

* Two PVCs named `data-web-sts-0` and `data-web-sts-1`, each in `Bound` status.
* Inside each Pod, `/data/identity.txt` shows its ordinal hostname (e.g., `web-sts-0` or `web-sts-1`).

---

### Exercise 8: Create a CronJob That Cleans Up a ConfigMap

**Task:**

1. Write a CronJob in `demo-ns` that runs every minute and deletes a ConfigMap named `temp-config` if it exists.
2. Create `temp-config` manually, then wait for the CronJob to remove it.
3. Verify that `temp-config` is no longer present.

**Steps You’ll Perform:**

* Create `cleanup-cronjob.yaml`:

  ```yaml
  apiVersion: batch/v1
  kind: CronJob
  metadata:
    name: cleanup-config-cron
    namespace: demo-ns
  spec:
    schedule: "*/1 * * * *"   # every minute
    jobTemplate:
      spec:
        template:
          spec:
            restartPolicy: OnFailure
            containers:
            - name: cleanup
              image: bitnami/kubectl:1.27
              command:
              - /bin/sh
              - -c
              - |
                if kubectl get configmap temp-config -n demo-ns; then
                  kubectl delete configmap temp-config -n demo-ns
                fi
  ```
* `kubectl apply -f cleanup-cronjob.yaml`
* Manually create `temp-config`:

  ```yaml
  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: temp-config
    namespace: demo-ns
  data:
    key: value
  ```
* `kubectl apply -f temp-config.yaml`
* Wait 1–2 minutes, then run:

  ```bash
  kubectl get configmap temp-config -n demo-ns
  ```

  Expect “NotFound.”

**Expected Outcome:**
After one minute, the CronJob’s Job completes and removes `temp-config`, so querying that ConfigMap returns “NotFound.”

---

### Exercise 9: Deploy a DaemonSet for Node-Local Logging

**Task:**

1. Create a DaemonSet named `logger-ds` in `demo-ns` that runs `busybox` on every node. It should mount the host’s `/var/log` directory into the container at `/host-logs`.
2. Within each DaemonSet Pod, run a simple command like `sleep 3600`.
3. List all Pods created by the DaemonSet and ensure one exists on each node.

**Steps You’ll Perform:**

* Create `daemonset.yaml`:

  ```yaml
  apiVersion: apps/v1
  kind: DaemonSet
  metadata:
    name: logger-ds
    namespace: demo-ns
  spec:
    selector:
      matchLabels:
        app: logger
    template:
      metadata:
        labels:
          app: logger
      spec:
        containers:
        - name: busybox-logger
          image: busybox:1.35
          command:
          - sh
          - -c
          - sleep 3600
          volumeMounts:
          - name: varlog
            mountPath: /host-logs
        volumes:
        - name: varlog
          hostPath:
            path: /var/log
    updateStrategy:
      type: RollingUpdate
      rollingUpdate:
        maxUnavailable: 1
  ```
* `kubectl apply -f daemonset.yaml`
* `kubectl get pods -n demo-ns -l app=logger -o wide`

**Expected Outcome:**

* You should see one Pod for `logger-ds` on each node (same number of Pods as nodes).
* Each Pod’s YAML shows a volume mount of `/var/log` from the host into `/host-logs` inside.

---

### Exercise 10: Run a Parallel Job to Process a Work Queue

**Task:**

1. Assume you have a (simulated) work queue in a ConfigMap or environment variable. Create a parallel Job named `worker-job` in `demo-ns` with `completions: 5` and `parallelism: 2`. Each Pod should echo its own Pod name and exit.
2. Verify that Kubernetes creates exactly 5 Pods (named `worker-job-xxxxx-<index>`), two at a time, until all 5 run and complete.
3. Observe the Job’s status and list the Pods when finished.

**Steps You’ll Perform:**

* Create `parallel-job.yaml`:

  ```yaml
  apiVersion: batch/v1
  kind: Job
  metadata:
    name: worker-job
    namespace: demo-ns
  spec:
    completions: 5
    parallelism: 2
    backoffLimit: 3
    template:
      metadata:
        labels:
          job: worker
      spec:
        restartPolicy: OnFailure
        containers:
        - name: worker
          image: busybox:1.35
          command:
          - sh
          - -c
          - |
            echo "Pod Name: $(hostname)"
            sleep 5
            exit 0
  ```
* `kubectl apply -f parallel-job.yaml`
* `kubectl get pods -n demo-ns -l job-name=worker-job --watch`
* After all Pods complete, run:

  ```bash
  kubectl get pods -n demo-ns -l job-name=worker-job
  kubectl describe job worker-job -n demo-ns
  ```

**Expected Outcome:**

* Kubernetes will launch 2 Pods initially (e.g., `worker-job-xxxxx-0` and `worker-job-xxxxx-1`).
* As those finish, it will create `worker-job-xxxxx-2`, etc., until a total of 5 successful completions.
* The final `kubectl describe job` shows `Succeeded: 5/5`.

---

## Tips for All Exercises

1. **Namespace Context:**
   Whenever you run `kubectl` commands, if you omit `-n demo-ns`, ensure your current context’s default namespace is `demo-ns` (use `kubectl config set-context --current --namespace=demo-ns`) or explicitly include `-n demo-ns`.

2. **Cleaning Up:**
   When you’re finished, you can remove all resources in `demo-ns` using:

   ```bash
   kubectl delete ns demo-ns
   ```

   Or delete individual kinds (Deployment, StatefulSet, etc.) as needed.

3. **Watching Resources:**
   To watch creation and termination in real time, use:

   ```bash
   kubectl get pods -n demo-ns --watch
   ```

4. **Describing Resources for Troubleshooting:**
   If something isn’t working (e.g., a Pod stays in `Pending`), run:

   ```bash
   kubectl describe pod <pod-name> -n demo-ns
   ```

   This shows events, scheduling errors, or volume-binding issues.

