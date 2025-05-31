## Exercise 1: Creating and Consuming ConfigMaps

**Objective**
Learn how to create a ConfigMap from literal values and files, then mount it into a Pod as environment variables and as a volume.

### 1.1. Create a Namespace

```bash
kubectl create namespace config-exercise
```

### 1.2. Create a ConfigMap from Literals

```bash
kubectl create configmap app-settings \
  --namespace=config-exercise \
  --from-literal=DATABASE_HOST=mysql.default.svc.cluster.local \
  --from-literal=LOG_LEVEL=INFO
```

Verify it exists:

```bash
kubectl get configmap app-settings -n config-exercise
```

### 1.3. Create a ConfigMap from a File

1. Create a file on your workstation called `feature-flags.properties`:

   ```
   featureA=true
   featureB=false
   featureC=true
   ```

2. Create a ConfigMap from that file:

   ```bash
   kubectl create configmap feature-flags \
     --namespace=config-exercise \
     --from-file=feature-flags.properties=./feature-flags.properties
   ```

3. Verify:

   ```bash
   kubectl get configmap feature-flags -n config-exercise -o yaml
   ```

### 1.4. Pod That Uses ConfigMap as Environment Variables

Create a file `configmap-env-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: configmap-env-demo
  namespace: config-exercise
spec:
  containers:
    - name: app
      image: busybox:1.35
      command:
        - sh
        - -c
        - |
          echo "DATABASE_HOST=$DATABASE_HOST"
          echo "LOG_LEVEL=$LOG_LEVEL"
          sleep 3600
      env:
        - name: DATABASE_HOST
          valueFrom:
            configMapKeyRef:
              name: app-settings
              key: DATABASE_HOST
        - name: LOG_LEVEL
          valueFrom:
            configMapKeyRef:
              name: app-settings
              key: LOG_LEVEL
```

Apply it:

```bash
kubectl apply -f configmap-env-pod.yaml
```

Verify:

```bash
kubectl logs configmap-env-demo -n config-exercise
```

You should see something like:

```
DATABASE_HOST=mysql.default.svc.cluster.local
LOG_LEVEL=INFO
```

### 1.5. Pod That Mounts ConfigMap as Files

Create a file `configmap-volume-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: configmap-volume-demo
  namespace: config-exercise
spec:
  volumes:
    - name: config-vol
      configMap:
        name: feature-flags
        items:
          - key: feature-flags.properties
            path: feature-flags.properties
        defaultMode: 0644
  containers:
    - name: app
      image: busybox:1.35
      command:
        - sh
        - -c
        - |
          echo "Contents of /etc/flags/feature-flags.properties:"
          cat /etc/flags/feature-flags.properties
          sleep 3600
      volumeMounts:
        - name: config-vol
          mountPath: /etc/flags
          readOnly: true
```

Apply it:

```bash
kubectl apply -f configmap-volume-pod.yaml
```

Verify:

```bash
kubectl logs configmap-volume-demo -n config-exercise
```

You will see:

```
Contents of /etc/flags/feature-flags.properties:
featureA=true
featureB=false
featureC=true
```

### 1.6. Update the ConfigMap and Observe Live Reload

1. Edit the ConfigMap (change `LOG_LEVEL` and add a new key):

   ```bash
   kubectl edit configmap app-settings -n config-exercise
   ```

   Change `LOG_LEVEL: "INFO"` to `"DEBUG"` and add:

   ```
   MAX_CONNECTIONS: "20"
   ```

2. For the **environment-variable** Pod (`configmap-env-demo`), the changes will **not** reflect until you restart the Pod:

   ```bash
   kubectl delete pod configmap-env-demo -n config-exercise
   kubectl apply -f configmap-env-pod.yaml
   kubectl logs configmap-env-demo -n config-exercise
   ```

   Now you should see:

   ```
   DATABASE_HOST=mysql.default.svc.cluster.local
   LOG_LEVEL=DEBUG
   ```

3. For the **volume-mounted** Pod (`configmap-volume-demo`), the file itself updates automatically. Exec into the container and `tail` the file:

   ```bash
   kubectl exec -it configmap-volume-demo -n config-exercise -- sh
   # Inside:
   cat /etc/flags/feature-flags.properties
   exit
   ```

   (Since we didn’t actually update `feature-flags.properties` in this example, you won’t see new content; but if you had updated that ConfigMap, the file content in `/etc/flags/feature-flags.properties` would refresh within seconds.)

---

## Exercise 2: Creating and Consuming Secrets

**Objective**
Learn how to create a Secret from literal values and files, then mount it into a Pod as environment variables and as a volume with restricted permissions.

### 2.1. Create a Secret from Literals

```bash
kubectl create secret generic db-credentials \
  --namespace=config-exercise \
  --from-literal=username=admin \
  --from-literal=password=S3cr3tP@ss
```

Verify:

```bash
kubectl get secret db-credentials -n config-exercise -o yaml
```

You’ll see `data:` containing base64-encoded values.

### 2.2. Create a Secret from Files

1. Create two local files:

    * `tls.crt` (your TLS certificate)
    * `tls.key` (your TLS private key)

2. Create a TLS Secret:

   ```bash
   kubectl create secret tls tls-secret \
     --namespace=config-exercise \
     --cert=./tls.crt \
     --key=./tls.key
   ```

3. Verify:

   ```bash
   kubectl get secret tls-secret -n config-exercise -o yaml
   ```

### 2.3. Pod That Uses Secret as Environment Variables

Create `secret-env-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-env-demo
  namespace: config-exercise
spec:
  containers:
    - name: app
      image: busybox:1.35
      command:
        - sh
        - -c
        - |
          echo "DB_USER: $DB_USER"
          echo "DB_PASS: $DB_PASS"
          sleep 3600
      env:
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: username
        - name: DB_PASS
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
```

Apply:

```bash
kubectl apply -f secret-env-pod.yaml
```

Verify:

```bash
kubectl logs secret-env-demo -n config-exercise
```

You’ll see:

```
DB_USER: admin
DB_PASS: S3cr3tP@ss
```

### 2.4. Pod That Mounts Secret as Files with Restrictive Permissions

Create `secret-volume-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-volume-demo
  namespace: config-exercise
spec:
  volumes:
    - name: secret-vol
      secret:
        secretName: db-credentials
        items:
          - key: username
            path: db_username
          - key: password
            path: db_password
        defaultMode: 0400
  containers:
    - name: app
      image: busybox:1.35
      command:
        - sh
        - -c
        - |
          echo "Contents of /etc/secret/db_username:"
          cat /etc/secret/db_username
          echo ""
          echo "Contents of /etc/secret/db_password:"
          cat /etc/secret/db_password
          echo "Permissions:"
          ls -l /etc/secret
          sleep 3600
      volumeMounts:
        - name: secret-vol
          mountPath: /etc/secret
          readOnly: true
```

Apply:

```bash
kubectl apply -f secret-volume-pod.yaml
```

Verify:

```bash
kubectl logs secret-volume-demo -n config-exercise
```

You should see:

```
Contents of /etc/secret/db_username:
admin

Contents of /etc/secret/db_password:
S3cr3tP@ss

Permissions:
-r--------    1 root     root            5 Jun  1 12:00 db_username
-r--------    1 root     root           10 Jun  1 12:00 db_password
```

> **Note:** Because `defaultMode: 0400`, only the container’s process (running as root inside BusyBox) can read these files. In a real app, you’d run as a non-root user and add `fsGroup` to ensure group-ownership.

### 2.5. Update the Secret and Observe Live Reload

1. Edit the Secret:

   ```bash
   kubectl edit secret db-credentials -n config-exercise
   ```

   Change the `password` to `N3wP@ssw0rd` (base64-encoded).

2. For the **environment-variable** Pod (`secret-env-demo`), you must restart the Pod to pick up the new values:

   ```bash
   kubectl delete pod secret-env-demo -n config-exercise
   kubectl apply -f secret-env-pod.yaml
   kubectl logs secret-env-demo -n config-exercise
   ```

   You should now see:

   ```
   DB_USER: admin
   DB_PASS: N3wP@ssw0rd
   ```

3. For the **volume-mounted** Pod (`secret-volume-demo`), the file content updates automatically. Exec in and read the file:

   ```bash
   kubectl exec -it secret-volume-demo -n config-exercise -- sh
   # Inside:
   cat /etc/secret/db_password
   exit
   ```

You should see `N3wP@ssw0rd` without needing to restart the Pod.

---

## Exercise 3: Configuring Probes (Liveness, Readiness, Startup)

**Objective**
Practice adding Liveness, Readiness, and Startup probes to a simple HTTP application and observe how Kubernetes responds to simulated failures.

### 3.1. Prepare a Simple HTTP Server Image

For this exercise, we’ll use a small Go‐based HTTP server that:

* Listens on port 8080.
* Returns 200 OK for `/healthz` (always healthy).
* Returns 200 OK for `/readyz` only if a file `/tmp/ready` exists.
* Sleeps for 30 seconds at startup to simulate a slow initialization.

You can build and push this to your own registry, or use a prebuilt image if available. For simplicity, here is the code; save as `main.go`:

```go
package main

import (
    "fmt"
    "net/http"
    "os"
    "time"
)

func main() {
    // Simulate slow startup
    time.Sleep(30 * time.Second)

    http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(200)
        fmt.Fprintf(w, "ok")
    })
    http.HandleFunc("/readyz", func(w http.ResponseWriter, r *http.Request) {
        if _, err := os.Stat("/tmp/ready"); err == nil {
            w.WriteHeader(200)
            fmt.Fprintf(w, "ready")
        } else {
            w.WriteHeader(503)
            fmt.Fprintf(w, "not ready")
        }
    })
    // A handler to create /tmp/ready
    http.HandleFunc("/make-ready", func(w http.ResponseWriter, r *http.Request) {
        f, err := os.Create("/tmp/ready")
        if err != nil {
            w.WriteHeader(500)
            return
        }
        f.Close()
        w.WriteHeader(200)
        fmt.Fprintf(w, "now ready")
    })

    http.ListenAndServe(":8080", nil)
}
```

1. Build and push it:

   ```bash
   go mod init example.com/probes
   go mod tidy
   go build -o http-app .
   # Build Docker image (assumes you have a Dockerfile)
   # Dockerfile:
   #   FROM golang:1.20-alpine as builder
   #   WORKDIR /app
   #   COPY . .
   #   RUN go build -o /http-app .
   #
   #   FROM alpine
   #   COPY --from=builder /http-app /usr/local/bin/http-app
   #   ENTRYPOINT ["/usr/local/bin/http-app"]
   docker build -t <your-registry>/http-app:latest .
   docker push <your-registry>/http-app:latest
   ```

   (If you prefer, use any image that can simulate these endpoints.)

### 3.2. Create a Deployment with Probes

Create `probes-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: probe-demo
  namespace: config-exercise
spec:
  replicas: 1
  selector:
    matchLabels:
      app: probe-demo
  template:
    metadata:
      labels:
        app: probe-demo
    spec:
      containers:
        - name: http-app
          image: <your-registry>/http-app:latest
          ports:
            - containerPort: 8080
          startupProbe:
            httpGet:
              path: /healthz
              port: 8080
            failureThreshold: 10
            periodSeconds: 5
          livenessProbe:
            httpGet:
              path: /healthz
              port: 8080
            initialDelaySeconds: 60
            periodSeconds: 10
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /readyz
              port: 8080
            initialDelaySeconds: 35
            periodSeconds: 5
            failureThreshold: 3
```

**Explanation**:

* **Startup Probe** (`/healthz`): Because the server sleeps for 30 seconds at startup, we give it up to `10*5 = 50 seconds` before declaring failure. Until this probe succeeds, Kubernetes disables liveness/readiness probes.
* **Liveness Probe** (`/healthz`): Waits `initialDelaySeconds: 60` (enough time for startup) and then checks every 10 seconds. If `/healthz` ever returns non-200 three times in a row, the container is restarted.
* **Readiness Probe** (`/readyz`): Starts 35 seconds after the container starts (so that startup is likely done). Until a file `/tmp/ready` exists, `/readyz` returns 503 (not ready). Once we call `/make-ready`, it will return 200, and the Pod will transition to Ready.

Apply:

```bash
kubectl apply -f probes-deployment.yaml
```

### 3.3. Observe Probe Behavior

1. **Watch Pod Status**:

   ```bash
   kubectl get pods -n config-exercise -l app=probe-demo -w
   ```

    * You should see the Pod in `ContainerCreating` or `Init` for the first 30 seconds, then transition to `Running, NotReady` (because `/readyz` is failing).
    * After you trigger `/make-ready`, it should become `Running, Ready`.

2. **Trigger Readiness**:

   ```bash
   POD=$(kubectl get pods -n config-exercise -l app=probe-demo -o jsonpath="{.items[0].metadata.name}")
   kubectl exec -it $POD -n config-exercise -- wget -qO- http://localhost:8080/make-ready
   ```

   Now `/tmp/ready` exists inside the container. The readiness probe (`/readyz`) will succeed within 5 seconds, and the Pod becomes Ready.

3. **Simulate Liveness Failure**:

   Exec into the container and remove `/healthz` functionality by killing the HTTP process:

   ```bash
   kubectl exec -it $POD -n config-exercise -- sh
   # Inside:
   pkill http-app
   exit
   ```

   The container will exit; Kubernetes sees the process died and restarts it. Because the liveness probe is disabled during startup (startup probe must succeed first), the container will restart and go through the same 30 seconds of “not ready” until `/make-ready` is called.

---

## Exercise 4: Resource Requests, Limits, LimitRange, and ResourceQuota

**Objective**
Practice setting container resource requests and limits; create a LimitRange to enforce defaults and minimums; create a ResourceQuota to restrict overall namespace usage.

### 4.1. Create a Namespace and LimitRange

1. Create a new namespace:

   ```bash
   kubectl create namespace resources-exercise
   ```

2. Create a `LimitRange` that enforces:

    * Each container must request **at least** 100 m CPU and 128 Mi memory.
    * Each container’s limits cannot exceed 1 CPU and 512 Mi memory.
    * If a Pod omits requests/limits, assign defaults: request = 200 m CPU, 256 Mi memory; limit = 500 m CPU, 512 Mi memory.

   Save as `limitrange.yaml`:

   ```yaml
   apiVersion: v1
   kind: LimitRange
   metadata:
     name: default-limits
     namespace: resources-exercise
   spec:
     limits:
       - type: Container
         min:
           cpu: "100m"
           memory: "128Mi"
         max:
           cpu: "1"
           memory: "512Mi"
         defaultRequest:
           cpu: "200m"
           memory: "256Mi"
         default:
           cpu: "500m"
           memory: "512Mi"
         maxLimitRequestRatio:
           cpu: "5"
           memory: "4"
   ```

   Apply:

   ```bash
   kubectl apply -f limitrange.yaml
   ```

3. Verify:

   ```bash
   kubectl get limitrange default-limits -n resources-exercise -o yaml
   ```

### 4.2. Deploy a Pod Without Resource Specs

Create `pod-no-resources.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: no-resources
  namespace: resources-exercise
spec:
  containers:
    - name: busybox
      image: busybox:1.35
      command:
        - sh
        - -c
        - |
          echo "Requests:"
          cat /sys/fs/cgroup/cpu/cpu.cfs_quota_us  # shows CPU quota
          echo "Memory limit:"
          cat /sys/fs/cgroup/memory/memory.limit_in_bytes
          sleep 3600
```

Apply:

```bash
kubectl apply -f pod-no-resources.yaml
```

1. Inspect the Pod’s resource requests/limits because of LimitRange default injection:

   ```bash
   kubectl get pod no-resources -n resources-exercise -o yaml | grep -A3 "resources"
   ```

   You should see something like:

   ```yaml
   resources:
     limits:
       cpu: "500m"
       memory: "512Mi"
     requests:
       cpu: "200m"
       memory: "256Mi"
   ```

2. Exec into the container and inspect cgroup files:

   ```bash
   POD=$(kubectl get pods -n resources-exercise -l name=no-resources -o jsonpath="{.items[0].metadata.name}")
   kubectl exec -it $POD -n resources-exercise -- sh
   # Inside:
   echo "CPU CFS quota (microseconds): $(cat /sys/fs/cgroup/cpu/cpu.cfs_quota_us)"
   echo "Memory limit (bytes): $(cat /sys/fs/cgroup/memory/memory.limit_in_bytes)"
   exit
   ```

    * CPU quota of \~500m means the container can use up to 0.5 CPU core.
    * Memory limit of 512 MiB is enforced.

### 4.3. Create a ResourceQuota in the Same Namespace

Create `resourcequota.yaml`:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-quota
  namespace: resources-exercise
spec:
  hard:
    pods: "5"
    requests.cpu: "2"
    requests.memory: "4Gi"
    limits.cpu: "4"
    limits.memory: "8Gi"
    persistentvolumeclaims: "3"
    requests.storage: "10Gi"
```

Apply:

```bash
kubectl apply -f resourcequota.yaml
```

Verify:

```bash
kubectl get resourcequota team-quota -n resources-exercise -o yaml
```

You’ll see current usage versus the `hard` limits.

### 4.4. Attempt to Exceed ResourceQuota

1. Create a Deployment with 4 replicas, each requesting 1 CPU and 2 Gi memory:

   ```bash
   cat <<EOF | kubectl apply -f -
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: high-memory
     namespace: resources-exercise
   spec:
     replicas: 4
     selector:
       matchLabels:
         app: high-memory
     template:
       metadata:
         labels:
           app: high-memory
       spec:
         containers:
           - name: app
             image: busybox:1.35
             resources:
               requests:
                 cpu: "1"
                 memory: "2Gi"
               limits:
                 cpu: "1"
                 memory: "2Gi"
             command:
               - sh
               - -c
               - |
                 echo "Running"
                 sleep 3600
   EOF
   ```

2. Observe that only **2 replicas** are scheduled:

   ```bash
   kubectl get pods -n resources-exercise -l app=high-memory
   ```

   The third/ fourth Pod remains `Pending` because:

    * Total `requests.cpu` for 2 Pods = 2 CPU (meets `requests.cpu: 2`)
    * Total `requests.memory` for 2 Pods = 4 Gi (meets `requests.memory: 4Gi`)

   The 3rd Pod would exceed the quota.

3. Inspect the Pending Pod’s event:

   ```bash
   kubectl describe pod <pending-pod-name> -n resources-exercise
   ```

   You’ll see an error: “exceeds quota: requests.cpu: must specify requests.cpu ≤ 2” or similar.

### 4.5. Clean Up

```bash
kubectl delete deployment high-memory -n resources-exercise
kubectl delete pod no-resources -n resources-exercise
kubectl delete resourcequota team-quota -n resources-exercise
kubectl delete limitrange default-limits -n resources-exercise
```

---

## Exercise 5: Node Affinity and Taints/Tolerations

**Objective**
Label your nodes, then create workloads that use nodeSelector and nodeAffinity. Add taints to a node and configure Pods with tolerations.

> **Prerequisite:** You need at least two nodes in your cluster, so you can label one node differently from the other. Use `kubectl get nodes` to see your nodes’ names.

### 5.1. Label One Node

1. List your nodes:

   ```bash
   kubectl get nodes
   ```

   Suppose you have `node-a` and `node-b`.

2. Label `node-a` with `disktype=ssd` and `zone=zone-1`:

   ```bash
   kubectl label node node-a disktype=ssd zone=zone-1
   ```

3. Label `node-b` with `disktype=hdd` and `zone=zone-2`:

   ```bash
   kubectl label node node-b disktype=hdd zone=zone-2
   ```

Verify:

```bash
kubectl get nodes --show-labels
```

### 5.2. Pod Using nodeSelector

Create `nodeSelector-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: selector-demo
  namespace: config-exercise
spec:
  nodeSelector:
    disktype: ssd
  containers:
    - name: app
      image: busybox:1.35
      command:
        - sh
        - -c
        - |
          echo "Running on $(hostname)"
          sleep 3600
```

Apply:

```bash
kubectl apply -f nodeSelector-pod.yaml
```

Verify:

```bash
kubectl get pod selector-demo -o wide -n config-exercise
```

You should see that `selector-demo` is scheduled on `node-a` (the one labeled `disktype=ssd`).

### 5.3. Pod Using Node Affinity (Required + Preferred)

Create `nodeAffinity-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: affinity-demo
  namespace: config-exercise
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: disktype
                operator: In
                values:
                  - ssd
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 1
          preference:
            matchExpressions:
              - key: zone
                operator: In
                values:
                  - zone-2
  containers:
    - name: app
      image: busybox:1.35
      command:
        - sh
        - -c
        - |
          echo "Affinity Pod Running on $(hostname)"
          sleep 3600
```

Apply:

```bash
kubectl apply -f nodeAffinity-pod.yaml
```

Verify:

```bash
kubectl get pod affinity-demo -o wide -n config-exercise
```

Although *required* is `disktype=ssd` (so it can only run on `node-a`), the *preferred* zone is `zone-2`. Since no SSD node is in `zone-2`, it winds up on `node-a` anyway. If you had labeled `node-b` as `disktype=ssd` in `zone-2`, this Pod would prefer `node-b`.

### 5.4. Taint a Node and Use Tolerations

1. Taint `node-b` with `maintenance=true:NoSchedule`:

   ```bash
   kubectl taint nodes node-b maintenance=true:NoSchedule
   ```

   Any Pod without a matching toleration for `maintenance=true:NoSchedule` will not be scheduled on `node-b`.

2. Create a Pod that tolerates this taint:

   `toleration-pod.yaml`:

   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: toleration-demo
     namespace: config-exercise
   spec:
     tolerations:
       - key: maintenance
         operator: Equal
         value: "true"
         effect: NoSchedule
     containers:
       - name: app
         image: busybox:1.35
         command:
           - sh
           - -c
           - |
             echo "Toleration Pod running on $(hostname)"
             sleep 3600
   ```

3. Apply:

   ```bash
   kubectl apply -f toleration-pod.yaml
   ```

4. Since `toleration-demo` has a toleration for the taint on `node-b`, it is eligible to run there. Verify:

   ```bash
   kubectl get pod toleration-demo -o wide -n config-exercise
   ```

   It should be scheduled on `node-b`. If other nodes also satisfy scheduling constraints, it might pick a different node if it doesn’t specifically have a nodeSelector.

5. Verify that, if you remove the toleration, the Pod cannot be scheduled there anymore:

   ```bash
   kubectl delete pod toleration-demo -n config-exercise
   kubectl apply -f toleration-pod.yaml    # edit out the tolerations block first
   # It will remain Pending if no other nodes are available.
   ```

---

## Exercise 6: Pod Priority and Preemption

**Objective**
Define two PriorityClasses and create Pods with different priorities. Then simulate resource pressure to observe preemption.

### 6.1. Create PriorityClasses

1. Create `priorityclasses.yaml`:

   ```yaml
   apiVersion: scheduling.k8s.io/v1
   kind: PriorityClass
   metadata:
     name: high-priority
   value: 1000000
   globalDefault: false
   description: "High priority for critical Pods"

   ---
   apiVersion: scheduling.k8s.io/v1
   kind: PriorityClass
   metadata:
     name: low-priority
   value: 1000
   globalDefault: true
   description: "Default low priority"
   ```

2. Apply:

   ```bash
   kubectl apply -f priorityclasses.yaml
   ```

3. Verify:

   ```bash
   kubectl get priorityclass
   ```

   You should see both `high-priority` (value 1,000,000) and `low-priority` (value 1,000, default).

### 6.2. Create a DaemonSet That Reserves Node Resources

We’ll create a DaemonSet with a container that requests most of each node’s CPU, leaving little headroom.

1. Determine the allocatable CPU on your nodes:

   ```bash
   kubectl describe node node-a | grep Allocatable -A2
   ```

   Suppose each node has 2 CPU allocatable.

2. Create `high-cpu-daemonset.yaml`:

   ```yaml
   apiVersion: apps/v1
   kind: DaemonSet
   metadata:
     name: cpu-hog
     namespace: config-exercise
   spec:
     selector:
       matchLabels:
         app: cpu-hog
     template:
       metadata:
         labels:
           app: cpu-hog
       spec:
         containers:
           - name: hog
             image: busybox:1.35
             command:
               - sh
               - -c
               - |
                 while true; do
                   echo "Consuming CPU..."
                   md5sum /dev/zero
                   sleep 1
                 done
             resources:
               requests:
                 cpu: "1800m"    # request 1.8 CPU
                 memory: "100Mi"
               limits:
                 cpu: "1800m"
                 memory: "100Mi"
   ```

3. Apply:

   ```bash
   kubectl apply -f high-cpu-daemonset.yaml
   ```

Now each node will be mostly occupied (1.8 CPU requested out of \~2 CPU).

### 6.3. Create a Low-Priority Pod That Cannot Be Scheduled

Create `low-priority-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: low-priority-pod
  namespace: config-exercise
spec:
  # No priorityClassName -> inherits low-priority (value 1000)
  containers:
    - name: app
      image: busybox:1.35
      resources:
        requests:
          cpu: "500m"
          memory: "100Mi"
      command:
        - sh
        - -c
        - |
          echo "Hello from low-priority"
          sleep 3600
```

Apply:

```bash
kubectl apply -f low-priority-pod.yaml
```

Check its status:

```bash
kubectl get pod low-priority-pod -n config-exercise
```

It will remain `Pending` because all nodes are already nearly full. Check events:

```bash
kubectl describe pod low-priority-pod -n config-exercise
```

You’ll see something like “0/2 nodes are available: 2 Insufficient cpu.”

### 6.4. Create a High-Priority Pod and Observe Preemption

Create `high-priority-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: high-priority-pod
  namespace: config-exercise
spec:
  priorityClassName: high-priority
  containers:
    - name: app
      image: busybox:1.35
      resources:
        requests:
          cpu: "500m"
          memory: "100Mi"
      command:
        - sh
        - -c
        - |
          echo "Hello from high-priority"
          sleep 3600
```

Apply:

```bash
kubectl apply -f high-priority-pod.yaml
```

1. Observe that the high-priority Pod is scheduled by preempting (evicting) one of the DaemonSet’s `cpu-hog` Pods (or the low-priority Pod, if it had been scheduled). Check:

   ```bash
   kubectl get pods -n config-exercise -o wide
   ```

   You’ll see that one node’s `cpu-hog` Pod was evicted (or `low-priority-pod` if it ever got scheduled), and `high-priority-pod` is now `Running`.

2. Inspect events for preemption:

   ```bash
   kubectl get events -n config-exercise | grep -i preempt
   ```

   You should see something like “Pod high-priority-pod preempted Pod cpu-hog-xxxxx.”

### 6.5. Clean Up

```bash
kubectl delete pod high-priority-pod low-priority-pod -n config-ercise
kubectl delete daemonset cpu-hog -n config-exercise
kubectl delete priorityclass high-priority low-priority
```

---

## Exercise 7: Combining Affinity, Taints, and Priority in a Deployment

**Objective**
Deploy a critical application that uses nodeAffinity (required + preferred), tolerations for maintenance taints, priorityClass, and resource requests/limits.

### 7.1. Label Nodes and Taint One Node

1. Label `node-a` as before: `disktype=ssd`, `zone=zone-1`.
2. Taint `node-a` with `maintenance=true:NoSchedule`:

   ```bash
   kubectl taint nodes node-a maintenance=true:NoSchedule
   ```

   Nodes with this taint will not accept new Pods unless they tolerate it.

### 7.2. Create a PriorityClass

(Re-use or recreate the `high-priority` class from Exercise 6 if needed.)

```bash
kubectl apply -f priorityclasses.yaml
```

### 7.3. Deployment Manifest

Create `combined-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: critical-app
  namespace: config-exercise
spec:
  replicas: 2
  selector:
    matchLabels:
      app: critical-app
  template:
    metadata:
      labels:
        app: critical-app
    spec:
      priorityClassName: high-priority
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: disktype
                    operator: In
                    values:
                      - ssd
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 1
              preference:
                matchExpressions:
                  - key: zone
                    operator: In
                    values:
                      - zone-2
      tolerations:
        - key: maintenance
          operator: Equal
          value: "true"
          effect: NoSchedule
      containers:
        - name: web
          image: nginx:1.21
          resources:
            requests:
              cpu: "300m"
              memory: "256Mi"
            limits:
              cpu: "600m"
              memory: "512Mi"
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 5
          livenessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 15
            periodSeconds: 10
```

Apply:

```bash
kubectl apply -f combined-deployment.yaml
```

### 7.4. Verify Scheduling

1. The Deployment must schedule 2 replicas.

2. Because `node-a` is tainted with `maintenance=true:NoSchedule`, only Pods that tolerate that taint can land on it. Our Pods have that toleration, so they can be scheduled on `node-a`. However, we also require `disktype=ssd`. If `node-b` is `disktype=hdd`, they cannot land there. So both replicas run on `node-a`.

3. If you remove the taint from `node-a`:

   ```bash
   kubectl taint nodes node-a maintenance:NoSchedule-
   ```

   Then the scheduler may spread the two Pods:

    * One on `node-a` (because it’s SSD).
    * If you change `node-b` to `disktype=ssd zone=zone-2`:

      ```bash
      kubectl label node node-b disktype=ssd zone=zone-2
      ```

      Then one Pod may land on each node, with a preference for `zone-2` node due to `preferredDuringScheduling`.

4. Check:

   ```bash
   kubectl get pods -o wide -n config-exercise
   ```

### 7.5. Simulate Resource Pressure to Trigger Preemption

1. On each node, schedule a `cpu-hog` Pod that requests 500 m CPU (only 2 were free, now saturate them):

   ```bash
   cat <<EOF | kubectl apply -f -
   apiVersion: v1
   kind: Pod
   metadata:
     name: pressure1
     namespace: config-exercise
   spec:
     containers:
       - name: hog
         image: busybox:1.35
         command:
           - sh
           - -c
           - |
             while true; do md5sum /dev/zero; done
         resources:
           requests:
             cpu: "500m"
             memory: "100Mi"
           limits:
             cpu: "500m"
             memory: "100Mi"
   EOF
   ```

   Do this twice (once for each node). Now each node is heavily used (requests). The critical-app Pods (requests 300 m CPU each) may be evicted or prevented from scheduling.

2. Because `critical-app` has `high-priority`, the scheduler will try to preempt (evict) one of these `pressure1` Pods on each node to make room. Check:

   ```bash
   kubectl get pods -n config-exercise -o wide
   kubectl get events -n config-exercise | grep -i preempt
   ```

   You should see that `pressure1` gets evicted to free up 300 m CPU for each `critical-app` Pod.

### 7.6. Clean Up

```bash
kubectl delete deployment critical-app -n config-exercise
kubectl delete pod pressure1 -n config-exercise
kubectl delete priorityclass high-priority low-priority
kubectl label node node-b disktype-   # remove labels
kubectl taint node node-a maintenance:NoSchedule-   # remove taint
```

---

## Exercise 8: Horizontal Pod Autoscaler (HPA)

**Objective**
Deploy a simple CPU‐bound application and configure an HPA to scale the Deployment between 1 and 5 replicas based on CPU utilization. Then generate artificial load to observe scaling.

> **Prerequisite:** You must have the Metrics Server installed in your cluster. Verify with:
>
> ```bash
> kubectl get deployment metrics-server -n kube-system
> ```

### 8.1. Deploy a CPU-Bound Application

Create `cpu-stress-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: stress-cpu
  namespace: config-exercise
spec:
  replicas: 1
  selector:
    matchLabels:
      app: stress-cpu
  template:
    metadata:
      labels:
        app: stress-cpu
    spec:
      containers:
        - name: stress-container
          image: polinux/stress
          args:
            - "-c"
            - "1"    # spin 1 CPU worker
          resources:
            requests:
              cpu: "200m"
            limits:
              cpu: "500m"
```

Apply:

```bash
kubectl apply -f cpu-stress-deployment.yaml
```

Verify the Pod is `Running`:

```bash
kubectl get pods -l app=stress-cpu -n config-exercise
```

### 8.2. Create an HPA (Scale on CPU Utilization)

Create `cpu-hpa.yaml`:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: stress-hpa
  namespace: config-exercise
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: stress-cpu
  minReplicas: 1
  maxReplicas: 5
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
```

Apply:

```bash
kubectl apply -f cpu-hpa.yaml
```

Verify HPA status:

```bash
kubectl get hpa stress-hpa -n config-exercise
```

You’ll see something like:

```
NAME         REFERENCE         TARGETS     MINPODS   MAXPODS   REPLICAS   AGE
stress-hpa   Deployment/stress-cpu   80%/50%   1         5         1          1m
```

(If CPU is above 50% on average, HPA will scale out.)

### 8.3. Generate Load and Observe Scaling

1. In a separate shell, watch the number of replicas:

   ```bash
   watch -n 5 "kubectl get pods -l app=stress-cpu -n config-exercise"
   ```

2. The single Pod is already consuming 100% of its requested 200m CPU (since `stress -c 1` spins a full core). Metrics API reports usage > 200m, so HPA sees that average utilization (actual / requested × 100) is \~100%. Consequently, HPA will scale out.

3. After \~30 seconds, you should see a second replica spawn. Continue to watch until you reach 5 replicas (maximum).

4. Remove or reduce CPU load:

   ```bash
   kubectl scale deployment stress-cpu -n config-exercise --replicas=1
   # Or delete some Pods to reduce load
   ```

   HPA will scale back down to 1 over time (respecting stabilization windows).

### 8.4. Clean Up

```bash
kubectl delete hpa stress-hpa -n config-exercise
kubectl delete deployment stress-cpu -n config-exercise
```

---

## Exercise 9: Vertical Pod Autoscaler (VPA) in “Initial” Mode

**Objective**
Install VPA (if not already present), create a VPA that suggests resource requests for a workload, and deploy a new Pod to see the initial resource recommendation applied. We’ll run in **Initial** mode so VPA only sets requests at Pod creation time.

> **Prerequisite:** VPA components must be installed in your cluster. You can install them via:
>
> ```bash
> kubectl apply -f https://github.com/kubernetes/autoscaler/releases/download/<vpa-version>/vpa-crd.yaml
> kubectl apply -f https://github.com/kubernetes/autoscaler/releases/download/<vpa-version>/vpa-recommender.yaml
> kubectl apply -f https://github.com/kubernetes/autoscaler/releases/download/<vpa-version>/vpa-updater.yaml
> kubectl apply -f https://github.com/kubernetes/autoscaler/releases/download/<vpa-version>/vpa-admission-controller.yaml
> ```
>
> Replace `<vpa-version>` with a compatible version for your cluster (e.g., `v0.11.0`).

### 9.1. Deploy a Sample Workload Without Resource Requests

Create `vpa-target-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vpa-demo
  namespace: config-exercise
spec:
  replicas: 1
  selector:
    matchLabels:
      app: vpa-demo
  template:
    metadata:
      labels:
        app: vpa-demo
    spec:
      containers:
        - name: app
          image: polinux/stress
          args:
            - "-c"
            - "1"
          # No resources.requests or limits specified
```

Apply:

```bash
kubectl apply -f vpa-target-deployment.yaml
```

### 9.2. Create a VPA in “Initial” Mode

Create `vpa-initial.yaml`:

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: vpa-demo
  namespace: config-exercise
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: vpa-demo
  updatePolicy:
    updateMode: Initial
  resourcePolicy:
    containerPolicies:
      - containerName: app
        minAllowed:
          cpu: "100m"
          memory: "128Mi"
        maxAllowed:
          cpu: "1000m"
          memory: "1Gi"
```

Apply:

```bash
kubectl apply -f vpa-initial.yaml
```

### 9.3. Observe VPA Recommendation

1. Wait a minute for VPA Recommender to collect metrics from the running Pod. Then query:

   ```bash
   kubectl get vpa vpa-demo -n config-exercise -o yaml
   ```

   Under `status.recommendation`, you’ll see something like:

   ```yaml
   recommendation:
     containerRecommendations:
       - containerName: app
         lowerBound:
           cpu: "100m"
           memory: "128Mi"
         target:
           cpu: "500m"
           memory: "256Mi"
         uncappedTarget:
           cpu: "680m"
           memory: "300Mi"
         upperBound:
           cpu: "1000m"
           memory: "1Gi"
   ```

2. Because VPA is in **Initial** mode, it will not evict existing Pods. But if you delete the Pod, the next Pod creation will pick up the recommended requests. Delete the Pod:

   ```bash
   kubectl delete pod -l app=vpa-demo -n config-exercise
   ```

3. Watch for the new Pod:

   ```bash
   kubectl get pods -l app=vpa-demo -n config-exercise -w
   ```

4. Inspect the new Pod’s spec:

   ```bash
   kubectl get pod -l app=vpa-demo -n config-exercise -o yaml | grep -A3 "resources"
   ```

   You should see that the container now has:

   ```yaml
   resources:
     requests:
       cpu: "500m"
       memory: "256Mi"
   ```

   (Which matches the `target` from VPA’s recommendation.)

### 9.4. Clean Up

```bash
kubectl delete vpa vpa-demo -n config-exercise
kubectl delete deployment vpa-demo -n config-exercise
```

---

## Exercise 10: Cluster Autoscaler (CA) on a Managed Cloud (GKE/EKS/AKS)

**Objective**
Enable Cluster Autoscaler on a managed Kubernetes cluster, create a workload that triggers scale-up by requesting more CPU than the current nodes can provide, and then remove the workload to see nodes scale down.

> **Prerequisite:** You must have a managed Kubernetes cluster (GKE, EKS, or AKS) with autoscaling enabled on at least one node pool. Below are GKE examples; adapt for EKS/AKS accordingly.

### 10.1. (GKE) Create a Node Pool with Autoscaling Enabled

```bash
gcloud container node-pools create autoscale-pool \
  --cluster=my-cluster \
  --zone=us-west1-b \
  --machine-type=n1-standard-2 \
  --num-nodes=1 \
  --min-nodes=1 \
  --max-nodes=3 \
  --enable-autoscaling
```

Verify the node pool:

```bash
gcloud container node-pools list --cluster=my-cluster --zone=us-west1-b
```

### 10.2. Deploy a CPU-Intensive Workload to Trigger Scale-Up

1. In the `config-exercise` namespace, create `ca-stress.yaml`:

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: ca-stress
     namespace: config-exercise
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: ca-stress
     template:
       metadata:
         labels:
           app: ca-stress
       spec:
         containers:
           - name: stress
             image: polinux/stress
             args:
               - "-c"
               - "4"    # spin 4 CPU workers
             resources:
               requests:
                 cpu: "2000m"
                 memory: "512Mi"
               limits:
                 cpu: "2000m"
                 memory: "512Mi"
   ```

2. Apply:

   ```bash
   kubectl apply -f ca-stress.yaml
   ```

3. The single node pool has `n1-standard-2` (2 CPUs) allocatable. Because this Pod requests 2 CPUs, the scheduler may immediately place it on the existing node. To force scale-up, increase the requested CPU to more than 2, e.g., `"-c 3"` and `requests.cpu: "3000m"`:

   Edit `ca-stress.yaml` accordingly, then reapply:

   ```bash
   kubectl delete deployment ca-stress -n config-exercise
   # Edit requests.cpu: "3000m" and args: "-c 3"
   kubectl apply -f ca-stress.yaml
   ```

4. Watch for a new node:

   ```bash
   kubectl get nodes -w
   ```

   Or in a separate shell:

   ```bash
   gcloud container clusters describe my-cluster --zone=us-west1-b | grep currentNodeCount
   ```

   A new node will be created (up to a max of 3) by CA to accommodate the Pod.

### 10.3. Observe Scale-Down

1. Delete the deployment:

   ```bash
   kubectl delete deployment ca-stress -n config-exercise
   ```

2. CA will detect that the extra node is now underutilized (no Pods) and, after a few minutes (default 10 minutes of underutilization), will cordon and drain it, then delete it. You can watch with:

   ```bash
   kubectl get nodes -w
   ```

   The extra node should eventually be removed, returning you to 1 node in the pool.

### 10.4. Clean Up

```bash
kubectl delete deployment ca-stress -n config-exercise
gcloud container node-pools delete autoscale-pool --cluster=my-cluster --zone=us-west1-b
```

---

## Final Cleanup

Once you’ve finished all exercises, you can delete both namespaces to remove most resources created:

```bash
kubectl delete namespace config-exercise resources-exercise
```

Double-check for any lingering pods/PVs/other objects and delete them as needed:

```bash
kubectl get all --all-namespaces | grep config-exercise
kubectl get all --all-namespaces | grep resources-exercise
```

If any PVs remain bound, delete them manually:

```bash
kubectl get pv
kubectl delete pv <pv-name>
```
