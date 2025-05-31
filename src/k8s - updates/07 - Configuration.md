## 1. Configuration Management: ConfigMaps and Secrets

Decoupling application configuration and sensitive information from container images is a fundamental Kubernetes principle. Trainees should understand how to create, consume, update, and manage ConfigMaps for non‐confidential data, and Secrets for sensitive data.

### 1.1 Motivation & Benefits

* **Portability**
  Building a single container image that can run in different environments (development, staging, production) simply by referencing different ConfigMaps or Secrets—no need to bake environment-specific values into the image.

* **Separation of Concerns**
  Developers focus on building application logic. Cluster operators or site reliability engineers (SREs) manage configuration objects (ConfigMaps/Secrets). This clear ownership prevents configuration from being hard‐coded in code or manifests.

* **Declarative Updates**
  Because ConfigMaps and Secrets are API objects stored in `etcd`, updating them can propagate changes to running Pods (when mounted as volumes) without rebuilding images or redeploying workloads. For environment‐variable‐based usage, updating the ConfigMap/Secret and restarting/redeploying Pods is sufficient.

* **Security & Compliance**
  Secrets avoid embedding sensitive data directly into container images or manifests. By enabling encryption at rest (via API server encryption providers), and enforcing RBAC restrictions on Secrets, you reduce the risk of leaking credentials.

### 1.2 ConfigMap: Non‐Sensitive Configuration

#### 1.2.1 Definition & Structure

A **ConfigMap** is a namespaced API object that stores non‐confidential data as key–value pairs. It can hold:

* **`data`**: UTF‐8 string key–value pairs.
* **`binaryData`**: Base64‐encoded binary blobs (e.g., an icon, small certificate, or binary config file).

Example ConfigMap YAML:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: demo
data:
  DATABASE_HOST: "mysql.default.svc.cluster.local"
  LOG_LEVEL: "DEBUG"
  app.properties: |
    max.connections=100
    enableFeatureX=true
binaryData:
  favicon.ico: iVBORw0KGgoAAAANSUhEUgA...
```

* Keys in `data` are identifiers (e.g., `DATABASE_HOST`, `LOG_LEVEL`) or file names (e.g., `app.properties` with block‐style `|` for multi‐line).
* Keys in `binaryData` must be base64‐encoded; Kubernetes decodes them when mounting.

##### Size Limit

* ConfigMaps have a 1 MiB size limit. For larger artifacts (certificates, full‐blown JSON/YAML configs >1 MiB), use external volumes (e.g., S3 CSI driver, PersistentVolumeClaim) instead.

#### 1.2.2 Creating ConfigMaps

1. **From Literal Values**

   ```bash
   kubectl create configmap app-config \
     --from-literal=DATABASE_HOST=mysql.default.svc.cluster.local \
     --from-literal=LOG_LEVEL=INFO
   ```

    * Creates `app-config` in the current namespace with keys `DATABASE_HOST` and `LOG_LEVEL`.

2. **From Files or Directories**

    * **Single File**

      ```bash
      kubectl create configmap app-config \
        --from-file=app.properties=/path/to/app.properties
      ```

      Creates a key `app.properties`, whose value is the file’s contents.

    * **Directory**

      ```bash
      kubectl create configmap app-config --from-file=/path/to/config-dir
      ```

      Each file under `config-dir` becomes a key (filename as key, content as value).

3. **From a Declarative YAML Manifest**

   ```yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: app-config
     namespace: demo
   data:
     DATABASE_HOST: "mysql.default.svc.cluster.local"
     LOG_LEVEL: "INFO"
     FEATURE_FLAGS: |
       featureA=true
       featureB=false
   ```

   Apply with:

   ```bash
   kubectl apply -f app-config.yaml
   ```

    * Declarative approach recommended for version control (GitOps).

#### 1.2.3 Consuming a ConfigMap in Pods

ConfigMaps can be consumed in two primary ways: **environment variables** and **volume mounts**.

1. **Environment Variables**
   In the Pod spec:

   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: configmap-env-pod
   spec:
     containers:
       - name: app
         image: myapp:latest
         env:
           - name: DATABASE_HOST
             valueFrom:
               configMapKeyRef:
                 name: app-config
                 key: DATABASE_HOST
           - name: LOG_LEVEL
             valueFrom:
               configMapKeyRef:
                 name: app-config
                 key: LOG_LEVEL
   ```

   At runtime, `DATABASE_HOST` and `LOG_LEVEL` appear as environment variables in the container.

   > **Note**: If you update the ConfigMap, environment‐variable values do **not** refresh in running Pods. You must restart or redeploy (e.g., `kubectl rollout restart deployment/my-app`).

2. **Volume Mounts**
   As files under a directory:

   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: configmap-volume-pod
   spec:
     volumes:
       - name: config-volume
         configMap:
           name: app-config
           # Optionally: select specific keys
           items:
             - key: app.properties
               path: app.properties
           # Optionally: set file mode
           defaultMode: 0644
     containers:
       - name: app
         image: myapp:latest
         volumeMounts:
           - name: config-volume
             mountPath: /etc/app-config
             readOnly: true
   ```

   Inside the container:

   ```
   /etc/app-config/DATABASE_HOST       # Contains content "mysql.default.svc.cluster.local"
   /etc/app-config/LOG_LEVEL           # Contains content "INFO"
   /etc/app-config/app.properties      # Contains full properties file
   ```

   > **Dynamic Updates**: If you update the ConfigMap, kubelet automatically updates the mounted files (typically within seconds). Applications that watch file changes (e.g., via inotify) can pick up new config without restarting.

#### 1.2.4 Updating & Deleting ConfigMaps

* **Update**
  Modify the YAML (e.g., change `LOG_LEVEL: "DEBUG"` → `"INFO"`) and run:

  ```bash
  kubectl apply -f app-config.yaml
  ```

    * If volume‐mounted, files auto‐refresh for running Pods.
    * If env‐var‐based, restart Pods to pick up changes.

* **Deletion**

  ```bash
  kubectl delete configmap app-config
  ```

    * Removing a ConfigMap may break Pods referencing it (e.g., missing file or env var). Coordinate deletion with rolling updates of consuming workloads.

#### 1.2.5 Best Practices for ConfigMaps

1. **Limit Size (<1 MiB)**

    * Offload large or binary artifacts (SSL certs >1 MiB) to external volumes/CSI drivers.

2. **Don’t Store Secrets Here**

    * ConfigMaps are stored in `etcd` unencrypted (unless you opt in). Keep only non‐sensitive data.

3. **Version Control**

    * Store ConfigMap manifests in Git alongside application code or Helm charts for traceability.

4. **Use `envFrom` When Injecting Many Keys**

   ```yaml
   envFrom:
     - configMapRef:
         name: app-config
   ```

    * Injects all key–value pairs as env vars in one shot, reducing boilerplate.

5. **Namespace Awareness**

    * ConfigMaps are namespaced. Pods in `namespace-a` cannot reference a ConfigMap in `namespace-b`.

6. **Immutable ConfigMaps (v1.18+)**

    * Add `immutable: true`:

      ```yaml
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: app-config
      immutable: true
      data:
        KEY1: "value1"
      ```
    * Prevents accidental in‐place updates. To change, create a new ConfigMap (e.g., `app-config-v2`).

---

### 1.3 Secrets: Sensitive Data Management

#### 1.3.1 Definition & Structure

A **Secret** is much like a ConfigMap but specifically intended for confidential information such as:

* Database credentials (username/password)
* API tokens, OAuth tokens
* TLS certificates and keys
* SSH private keys

Key fields:

* **`data`**: Base64‐encoded strings.
* **`stringData`**: Plaintext values. Kubernetes base64‐encodes these when creating the `data` field behind the scenes.

Common Secret `type` values:

* `Opaque` (generic).
* `kubernetes.io/dockerconfigjson` (for Docker registry credentials).
* `kubernetes.io/tls` (TLS certificate & key pairs).
* `kubernetes.io/basic-auth`, `kubernetes.io/ssh-auth`, etc.

Example Secret YAML (TLS type):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: tls-secret
  namespace: demo
type: kubernetes.io/tls
data:
  tls.crt: LS0tLS1CRUdJTiBDRVJ...
  tls.key: LS0tLS1CRUdJTiBSU0E...
```

Or using `stringData` (plaintext):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
  namespace: demo
type: Opaque
stringData:
  username: admin
  password: S3cur3P@ssw0rd!
```

* Kubernetes will base64‐encode the contents of `stringData` when storing in `data`.

> **Security Note**: By default, Secrets are base64‐encoded (not encrypted) in `etcd`. Always enable **encryption at rest** (via API server encryption providers) if you store Secrets in etcd. Enforce strict RBAC so only authorized workloads or users can read specific Secrets.

#### 1.3.2 Creating Secrets

1. **From Literal Values**

   ```bash
   kubectl create secret generic db-credentials \
     --from-literal=username=admin \
     --from-literal=password='S3cur3P@ssw0rd!'
   ```

    * Creates a Secret named `db-credentials` with base64‐encoded `username` and `password`.

2. **From Files**

    * **Single File (e.g., TLS)**

      ```bash
      kubectl create secret generic tls-secret \
        --from-file=tls.crt=/path/to/tls.crt \
        --from-file=tls.key=/path/to/tls.key
      ```

      Creates keys `tls.crt` and `tls.key` in `data` with base64‐encoded file contents.

    * **Directory**

      ```bash
      kubectl create secret generic ssh-keys \
        --from-file=/path/to/ssh-keys-dir
      ```

      Each file under `ssh-keys-dir` becomes a key.

3. **From a Declarative YAML Manifest**

   ```yaml
   apiVersion: v1
   kind: Secret
   metadata:
     name: db-credentials
     namespace: demo
   type: Opaque
   stringData:
     username: admin
     password: S3cur3P@ss
   ```

   Apply with:

   ```bash
   kubectl apply -f db-credentials.yaml
   ```

#### 1.3.3 Consuming Secrets in Pods

Secrets can be consumed via **environment variables**, **volume mounts**, or as **image pull credentials**.

1. **Environment Variables**

   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: secret-env-pod
   spec:
     containers:
       - name: app
         image: myapp:latest
         env:
           - name: DB_USERNAME
             valueFrom:
               secretKeyRef:
                 name: db-credentials
                 key: username
           - name: DB_PASSWORD
             valueFrom:
               secretKeyRef:
                 name: db-credentials
                 key: password
   ```

    * At runtime, `DB_USERNAME` and `DB_PASSWORD` appear as environment variables, decoded from the Secret.

   > **Note**: Updating the Secret does **not** refresh environment variables in running Pods. You must restart or redeploy.

2. **Volume Mounts**

   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: secret-volume-pod
   spec:
     volumes:
       - name: secret-volume
         secret:
           secretName: db-credentials
           items:
             - key: username
               path: credentials/username
             - key: password
               path: credentials/password
           defaultMode: 0400
     containers:
       - name: app
         image: myapp:latest
         volumeMounts:
           - name: secret-volume
             mountPath: /etc/creds
             readOnly: true
   ```

   Inside the container:

   ```
   /etc/creds/credentials/username   # Contains plaintext “admin”
   /etc/creds/credentials/password   # Contains plaintext “S3cur3P@ssw0rd!”
   ```

    * Use `defaultMode: 0400` (owner‐read only) to restrict access. Usually, application processes run as non‐root or have a dedicated user.

   > **Dynamic Updates**: Kubernetes automatically updates mounted Secret volumes when the Secret changes (within seconds). Applications that watch these file paths can reload credentials dynamically. If not, restart to pick up new values.

3. **Image Pull Secrets (Private Registries)**

    * Create a Docker registry Secret:

      ```bash
      kubectl create secret docker-registry regcred \
        --docker-server=https://index.docker.io/v1/ \
        --docker-username=myuser \
        --docker-password=mypassword \
        --docker-email=myuser@example.com \
        --namespace=demo
      ```
    * Pod spec:

      ```yaml
      apiVersion: v1
      kind: Pod
      metadata:
        name: private-image-pod
        namespace: demo
      spec:
        imagePullSecrets:
          - name: regcred
        containers:
          - name: private-app
            image: myprivateregistry/myapp:latest
      ```
    * Kubernetes uses `.dockerconfigjson` to authenticate to the private registry.

#### 1.3.4 Updating & Deleting Secrets

* **Update**
  Modify the YAML (or use `kubectl edit secret/db-credentials`) and reapply:

  ```bash
  kubectl apply -f db-credentials.yaml
  ```

    * Mounted volumes auto‐refresh; environment variables require restart.

* **Deletion**

  ```bash
  kubectl delete secret db-credentials
  ```

    * Consuming Pods relying on that Secret may fail or crash. Coordinate deletion/rotation carefully, especially for database credentials.

#### 1.3.5 Best Practices for Secrets

1. **Enable Encryption at Rest**

    * By default, Secrets in `etcd` are only base64‐encoded. Configure API server encryption providers (e.g., KMS, AES‐CBC) to encrypt all `secrets` resources at rest.

2. **RBAC Restrictions**

    * Define Roles/RoleBindings that limit which ServiceAccounts or users can read specific Secrets:

      ```yaml
      apiVersion: rbac.authorization.k8s.io/v1
      kind: Role
      metadata:
        namespace: production
        name: secret-reader
      rules:
        - apiGroups: [""]
          resources: ["secrets"]
          resourceNames: ["db-credentials"]
          verbs: ["get", "list"]
      ---
      apiVersion: rbac.authorization.k8s.io/v1
      kind: RoleBinding
      metadata:
        namespace: production
        name: bind-secret-reader
      subjects:
        - kind: ServiceAccount
          name: frontend-sa
          namespace: production
      roleRef:
        kind: Role
        name: secret-reader
        apiGroup: rbac.authorization.k8s.io
      ```
    * Only `frontend-sa` can fetch `db-credentials`.

3. **Immutable Secrets (v1.19+)**

    * Add `immutable: true` to prevent in‐place modifications:

      ```yaml
      apiVersion: v1
      kind: Secret
      metadata:
        name: db-credentials
      immutable: true
      stringData:
        username: admin
        password: S3cur3P@ss
      ```
    * To rotate, create a new Secret (e.g., `db-credentials-v2`) and update Pod specs.

4. **Avoid Checking Base64 Data into Git**

    * Instead of committing raw Secret YAMLs, use tools such as [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) or [HashiCorp Vault](https://www.vaultproject.io/) to encrypt/engineer Secret management.

5. **Rotate Secrets Regularly**

    * Build automation (e.g., closed‐loop scripts or CI/CD pipelines) to rotate database passwords or API tokens on a schedule, updating the Secret and rolling out consuming workloads.

---

### 1.4 Coordinating ConfigMaps and Secrets in Workloads

Applications often need both non‐sensitive configuration (ConfigMap) and sensitive credentials (Secret). Kubernetes supports projecting multiple sources into a single Pod.

#### 1.4.1 Combined Volume Projection

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: combined-pod
  namespace: demo
spec:
  containers:
    - name: app
      image: myapp:latest
      volumeMounts:
        - name: config-volume
          mountPath: /etc/config      # ConfigMap
        - name: secret-volume
          mountPath: /etc/secret      # Secret
        - name: combined
          mountPath: /etc/app         # Combined
  volumes:
    - name: config-volume
      configMap:
        name: app-config
        items:
          - key: app.properties
            path: app.properties
        defaultMode: 0644
    - name: secret-volume
      secret:
        secretName: db-credentials
        items:
          - key: password
            path: db/password
        defaultMode: 0400
    - name: combined
      projected:
        sources:
          - configMap:
              name: app-config
          - secret:
              name: db-credentials
          - downwardAPI:
              items:
                - path: "metadata/labels"
                  fieldRef:
                    fieldPath: metadata.labels
```

* **`config-volume`**: Contains non‐sensitive application properties (`app.properties`).
* **`secret-volume`**: Contains sensitive database password under `/etc/secret/db/password`.
* **`combined`** (projected volume): Merges ConfigMap, Secret, and Pod metadata (Downward API) into a single mount point `/etc/app`.

Inside the container, you might see:

```
/etc/app/DATABASE_HOST         # From ConfigMap
/etc/app/LOG_LEVEL             # From ConfigMap
/etc/app/db/password           # From Secret (file mode 0400)
/etc/app/metadata/labels       # Downward API content (labels)
```

This projection simplifies application code that expects a single directory of config and credentials.

#### 1.4.2 Updating and Rolling Updates

* **ConfigMap Volume**: Updates to ConfigMap propagate to mounted files. Applications configured to watch file changes can reload automatically.
* **Secret Volume**: Updates to Secret propagate similarly. Applications must watch file paths or be restarted.
* **EnvVar References**: Always require Pod restart to pick up new values if consumed via `envFrom`/`valueFrom`.
* **Rolling Updates**: If using Deployments/ReplicaSets, update the ConfigMap or Secret, then trigger a `kubectl rollout restart deployment/<name>` (if environment variables are used). For volume‐mounted cases, consider using `immutable` for ConfigMaps/Secrets and switch to a new resource name/version to force a rolling update of Pods.

---

## 2. Container Health Probes: Liveness, Readiness, and Startup

Kubernetes uses **probes** to verify container health and readiness, minimizing downtime by restarting unhealthy containers and preventing traffic to Pods that aren’t ready. Understanding and configuring these probes correctly is critical for reliable production workloads.

### 2.1 Liveness Probes

* **Purpose**: Determine whether a container is alive (i.e., not stuck). If a liveness probe fails repeatedly, kubelet **restarts** the container.
* **Use Cases**:

    * Detect deadlocks (application is running but cannot make progress).
    * Recover from application crashes where process remains alive but unresponsive.
* **Configuration Parameters**:

    * **`httpGet`**, **`tcpSocket`**, or **`exec`**: Defines how Kubernetes checks.
    * **`initialDelaySeconds`**: Wait this long after container start before probing.
    * **`periodSeconds`**: How often to perform the probe.
    * **`timeoutSeconds`**: How long to wait for a response.
    * **`failureThreshold`**: Number of consecutive failures to consider the container unhealthy.

#### Example: HTTP Liveness Probe

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 15
  periodSeconds: 10
  timeoutSeconds: 1
  failureThreshold: 3
```

* Kubernetes will wait 15 s after start, then send an HTTP GET to `/healthz:8080` every 10 s. If it fails (timeout >1 s or non-2xx) 3 times, the container is restarted.

#### Example: Exec Liveness Probe

```yaml
livenessProbe:
  exec:
    command:
      - cat
      - /tmp/healthy-file
  initialDelaySeconds: 10
  periodSeconds: 5
  failureThreshold: 2
```

* Kubernetes runs `cat /tmp/healthy-file` every 5 s. If it exits non-zero twice consecutively, container is killed and restarted.

### 2.2 Readiness Probes

* **Purpose**: Determine if a container is ready to serve requests. Readiness probe failure will remove the Pod from Service endpoints, preventing traffic routing until it passes again.
* **Use Cases**:

    * Delay routing traffic until the application has fully initialized (e.g., loaded configuration, warmed caches).
    * Signal temporary unavailability during graceful shutdown or configuration reload.
    * Integration with load balancers or Service objects to ensure only healthy Pods receive traffic.
* **Behavior**:

    * If a readiness probe fails, Pod transitions to `NotReady`—kubelet stops sending traffic.
    * Container is not killed; only routing is affected.

#### Example: Exec Readiness Probe

```yaml
readinessProbe:
  exec:
    command:
      - cat
      - /tmp/healthy-file
  initialDelaySeconds: 5
  periodSeconds: 5
  timeoutSeconds: 1
  failureThreshold: 1
```

* If `cat /tmp/healthy-file` fails, Pod is removed from Service endpoints.

### 2.3 Startup Probes

* **Purpose**: Used for containers that have a long initialization sequence—delay liveness and readiness probes until the application is fully started.
* **Use Cases**:

    * JVM applications with long warm-up times or large EXE files that take time to extract.
    * Databases performing initial recovery tasks.
* **Behavior**:

    * Startup probe runs until it succeeds. Until successful, Kubernetes disables liveness and readiness probes for that container.
    * Once the startup probe passes, normal liveness and readiness probing resumes.
* **Configuration Parameters**:

    * Same as liveness (httpGet/tcpSocket/exec, initialDelaySeconds, periodSeconds, timeoutSeconds, failureThreshold).

#### Example: HTTP Startup Probe

```yaml
startupProbe:
  httpGet:
    path: /startup-complete
    port: 8080
  failureThreshold: 30
  periodSeconds: 10
```

* Allows up to 30 attempts (10 s apart) → up to 5 minutes for application to mark `/startup-complete` as healthy. During this period, liveness and readiness probes are disabled.

### 2.4 Choosing Probe Types

* **`httpGet`**: Ideal for HTTP-based services exposing a health endpoint.
* **`exec`**: Suitable when health is determined by checking a file, running a script, or inspecting application-specific signals.
* **`tcpSocket`**: Checks if a TCP port is open—useful for simple port-listening health checks.

### 2.5 Probe Parameters Tuning

* **`initialDelaySeconds`**:

    * Set longer delays for applications that take time to start (e.g., large frameworks, DBs).
    * Prevent premature failures.

* **`periodSeconds`**:

    * Determines how frequently Kubernetes checks. Too aggressive probing can overload the application. Too infrequent can delay detection of failure/unavailability.

* **`timeoutSeconds`**:

    * How long to wait for a response. Set based on expected application response times.

* **`failureThreshold`**:

    * Higher values allow transient failures (e.g., short network hitches) without triggering restarts or marking Pod as unready.

* **`successThreshold`** (for readiness/startup probes only):

    * Number of consecutive successes required before marking as healthy or ready. Not used in basic liveness probes.

---

## 3. Resource Management: Requests, Limits, QoS, LimitRange, ResourceQuota

Kubernetes uses **resource requests** and **limits** to schedule Pods effectively, enforce container resource usage at runtime, and assign a Pod’s Quality of Service (QoS) class. Additional namespace‐scoped policies like **LimitRange** and **ResourceQuota** guide and constrain resource consumption across teams or projects.

### 3.1 Requests vs. Limits

* **Resource Requests** (`resources.requests`):

    * The minimum amount of CPU and memory guaranteed to a container.
    * Used by the scheduler: a node must have at least this much unallocated CPU/Memory to place the Pod.
    * At runtime, kubelet reserves this amount of resources for the container.

* **Resource Limits** (`resources.limits`):

    * The maximum amount of a resource a container can use.
    * **CPU**: Enforced via cgroup CPU quota—if a container tries to exceed its CPU limit, it gets throttled.
    * **Memory**: If usage exceeds the memory limit and the node is under pressure, the kernel may OOM‐kill the container.

* **When Only Limit Is Specified**:

    * Kubernetes infers the request to be the same as the limit for scheduling purposes.

#### Example Pod Resource Specification

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-demo
spec:
  containers:
    - name: compute-intensive
      image: busybox
      command: ["sh", "-c", "while true; do echo running; sleep 5; done"]
      resources:
        requests:
          cpu: "500m"      # Reserve 0.5 CPU
          memory: "256Mi"  # Reserve 256 MiB
        limits:
          cpu: "1"         # Allow up to 1 CPU
          memory: "512Mi"  # Allow up to 512 MiB
```

* **Scheduling**: Node must have ≥0.5 CPU and ≥256 MiB free.
* **Runtime**: Container can use up to 1 CPU core; if it tries to exceed 512 MiB under memory pressure, it may be killed.

#### Pod‐Level Summation

* For multi-container Pods, the Pod’s effective request is the **sum** of each container’s request. Likewise, Pod’s limit is the sum of individual container limits. This aggregate is used in scheduling and QoS classification.

### 3.2 Quality of Service (QoS) Classes

Based on requests and limits, Kubernetes assigns Pods one of three QoS classes. This influences eviction decisions under node pressure:

1. **Guaranteed**

    * Every container in the Pod has **requests == limits** for **all** CPU and memory.
    * The Pod is least likely to be evicted under resource contention.

   ```yaml
   resources:
     requests:
       cpu: "500m"
       memory: "256Mi"
     limits:
       cpu: "500m"
       memory: "256Mi"
   ```

2. **Burstable**

    * All containers have requests specified, but at least one container has **limit > request**.
    * These Pods can use resources beyond their request (up to the limit) if available but may be evicted before Guaranteed Pods if the node is under memory pressure.

   ```yaml
   resources:
     requests:
       cpu: "250m"
       memory: "256Mi"
     limits:
       cpu: "500m"
       memory: "512Mi"
   ```

3. **BestEffort**

    * No requests or limits specified for any container.
    * Pod is scheduled only if the node has absolutely free resources. Under memory or disk pressure, these Pods are evicted first.

### 3.3 LimitRange: Namespace‐Scoped Defaults and Constraints

A **LimitRange** is an admission‐control policy for a namespace that enforces:

* **Default requests/limits** for containers if omitted.
* **Minimum and maximum** CPU/memory per container or Pod.
* **Maximum ratio** between limit and request (e.g., `limit/request ≤ 2`).
* **Constraints on PVC storage requests** (min/max).

#### Example LimitRange

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: compute-limits
  namespace: dev
spec:
  limits:
    - type: Container
      # Minimum per container
      min:
        cpu: "100m"
        memory: "64Mi"
      # Maximum per container
      max:
        cpu: "2"
        memory: "1Gi"
      # Default requests for containers that omit them
      defaultRequest:
        cpu: "200m"
        memory: "128Mi"
      # Default limits for containers that omit them
      default:
        cpu: "500m"
        memory: "256Mi"
      # Ensure limit/request ≤ 4
      maxLimitRequestRatio:
        cpu: "4"
        memory: "4"
    - type: PersistentVolumeClaim
      min:
        storage: "1Gi"
      max:
        storage: "20Gi"
```

* **Default Injection**: A container in namespace `dev` that does not specify resources gets `requests.cpu=200m`, `limits.cpu=500m`, `requests.memory=128Mi`, `limits.memory=256Mi` automatically injected.
* **Min/Max Enforcement**: If a Pod requests `cpu: "50m" (<100m)`, API server rejects with 403 Forbidden. Likewise, `cpu: "3"` (>2) is rejected.
* **Ratio Check**: If a Pod sets `request.cpu=500m` and `limit.cpu=3` (>4 × request), it is rejected.

#### Use Cases

* **Prevent “Noisy Neighbor” Pods**: Bound individual container resource consumption, so that no single container can monopolize node resources.
* **Ensure Requests for Scheduling**: Guarantee pods specify at least some minimal requests, making scheduling predictions more reliable.
* **Auto‐Inject Defaults for Developers**: Developers do not have to specify requests/limits explicitly; LimitRange ensures safe defaults.

### 3.4 ResourceQuota: Namespace‐Scoped Usage Caps

A **ResourceQuota** enforces aggregate resource usage constraints within a namespace. It can limit:

* **Count of specific objects**: e.g., max number of Pods, Services, ConfigMaps, Secrets.
* **Sum of resource requests/limits**: total CPU, memory requests and limits across all Pods.
* **Storage usage**: total PVC storage requests.
* **Ephemeral storage**: total `/tmp` or container filesystem usage.

#### Example ResourceQuota

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: dev-quota
  namespace: dev
spec:
  hard:
    pods: "10"
    requests.cpu: "4"         # Total CPU requests ≤ 4
    requests.memory: "8Gi"    # Total memory requests ≤ 8Gi
    limits.cpu: "8"           # Total CPU limits ≤ 8
    limits.memory: "16Gi"     # Total memory limits ≤ 16Gi
    requests.storage: "50Gi"  # Total PVC storage ≤ 50Gi
```

* **Pods Count**: At most 10 Pods can be created in `dev`.
* **Compute Requests Sum**: Sum of all Pod requests.cpu must not exceed 4 CPUs.
* **Compute Limits Sum**: Sum of all Pod limits.cpu must not exceed 8 CPUs.
* **PVC Storage Sum**: Sum of all PVC storage requests ≤ 50 GiB.

#### How Quota Is Enforced

* On any create/update of a Pod, Deployment, or PVC, the API server computes the prospective new total usage (existing usage + requested resource). If it exceeds a `hard` limit, the request is rejected with HTTP 403 Forbidden.
* You can view current usage vs. quota:

  ```bash
  kubectl get resourcequota dev-quota -n dev
  ```

  Output shows `used` vs. `hard`, e.g., `pods 3/10`, `requests.cpu 1/4`.

#### Combining with LimitRange

* A common best practice is to pair a ResourceQuota with a LimitRange in the same namespace.
* Example: If ResourceQuota for CPU requests is 4 CPUs, and LimitRange enforces a default request of `200m`, then at most 20 containers (200m each) can be created (`20 × 200m = 4 CPUs`). If a user tries to create a container with no requests, LimitRange injects a default, ensuring accurate quota accounting.

### 3.5 Quality of Service & Eviction Order

Under node pressure (memory or disk), kubelet uses QoS classes to determine eviction order:

1. **BestEffort** (no requests/limits) – evicted first.
2. **Burstable** (requests < limits) – evicted next, prioritizing those with the largest resource usage relative to request.
3. **Guaranteed** (requests == limits) – evicted last.

Understanding this eviction sequence is vital for designing workloads that must remain up during resource contention.

---

## 4. Scheduling Mechanisms: kube-scheduler, Node Selection, Taints/Tolerations, Priority/Preemption

Kubernetes scheduling ensures Pods are placed on suitable Nodes while meeting resource, topology, and policy constraints. This section covers:

1. **kube-scheduler Architecture & Workflow**
2. **Node Selection Mechanisms** (nodeSelector, nodeAffinity)
3. **Taints & Tolerations**
4. **Pod Priority & Preemption**

### 4.1 Kube-Scheduler Architecture & Workflow

* **kube-scheduler** is the core control-plane component responsible for assigning (binding) Pods to Nodes.
* It watches the API server for newly created Pods in `Pending` state without a `spec.nodeName`.
* For each unscheduled Pod, scheduler performs:

    1. **Filtering Phase (“Predicates”)**

        * Iterates over all eligible Nodes and **filters out** Nodes that do not meet Pod requirements:

            * **PodFitsResources**: Node allocatable CPU/Memory ≥ Pod’s requests.
            * **PodFitsHostPorts**: Node has no port conflicts.
            * **PodFitsNodeSelector** / **NodeAffinity**: Node labels match Pod’s selector/affinity.
            * **TaintToleration**: Pod must tolerate Node’s taints.
            * And many other predicate checks (e.g., SELinux, volume binding, etc.).
    2. **Scoring Phase (“Priorities”)**

        * Remaining Nodes after filtering are **scored** via priority (weight) functions:

            * **LeastRequestedPriority**: Prefers Nodes with most free CPU/Memory (to spread load).
            * **BalancedResourceAllocation**: Prefers Nodes with balanced CPU/Memory usage.
            * **NodeAffinityPriority**: Ranks Nodes matching preferred affinity terms higher.
            * **TaintTolerationPriority**: Ranks Nodes whose taints are least penalizing.
            * Custom or plugin-based scoring can be configured via scheduler profiles.
    3. **Binding Phase**

        * Selects the highest-scored Node and issues a **Bind** operation: sets `spec.nodeName` on the Pod.
        * kubelet on that Node then admits the Pod, pulling images and starting containers.
* **Scheduling Cycle**:

    * Default scheduler reschedules every \~10 seconds or when Pod/Node changes occur.
    * Only one scheduler binds a given Pod to avoid conflicts. You can deploy multiple scheduler replicas for high throughput; they coordinate via leadership election.

### 4.2 Node Selection: nodeSelector, Node Affinity

#### 4.2.1 nodeSelector (Simple, Exact‐Match)

* **Syntax**:

  ```yaml
  spec:
    nodeSelector:
      disktype: ssd
      environment: production
  ```
* Only Nodes labeled with `disktype=ssd AND environment=production` qualify.
* To label a Node:

  ```bash
  kubectl label node node-123 disktype=ssd environment=production
  ```
* **Limitation**: Only exact-match key/value pairs. No expressions (e.g., “notin”, “exists”).

#### 4.2.2 Node Affinity (v1.6+; Preferred & Required)

* **More expressive** than `nodeSelector`. Supports:

    * **`requiredDuringSchedulingIgnoredDuringExecution`**: Hard requirement, equivalent to nodeSelector but using affinity syntax.
    * **`preferredDuringSchedulingIgnoredDuringExecution`**: Soft preference with weights—Node that matches preference gets higher score but Pod can still schedule on other Nodes if no match.

##### Example: Node Affinity

```yaml
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
                  - us-west1-b
                  - us-west1-c
```

* **Required**: Node must have label `disktype=ssd`.
* **Preferred**: Among those Nodes, ones labeled `zone=us-west1-b` or `us-west1-c` get weight 1. If no Node matches preferred, scheduler falls back to any Node meeting the required term.

##### Comparison: nodeSelector vs. nodeAffinity

* `nodeSelector`: Simple key/value matches, no weighting.
* `nodeAffinity`:

    * Allows operators: `In`, `NotIn`, `Exists`, `DoesNotExist`, `Gt`, `Lt`.
    * Supports multiple `nodeSelectorTerms` (OR semantics).
    * Supports soft preferences (`preferredDuringSchedulingIgnoredDuringExecution`) with weights.

#### 4.2.3 Manual Scheduling (spec.nodeName)

* You can bypass the scheduler by specifying:

  ```yaml
  spec:
    nodeName: node-123
  ```
* The Pod will only schedule on that Node, provided it meets all constraints (has enough resources, tolerates taints, etc.).
* Primarily used for debugging or cluster bootstrap. If the Node does not exist or is unschedulable, the Pod remains `Pending`.

---

### 4.3 Taints and Tolerations

While affinity/selector rules describe where a Pod *should* go, **taints** on Nodes describe where Pods *should not* go unless they explicitly **tolerate** those taints. This is essential for isolating workloads (e.g., dedicated GPU Nodes, maintenance Nodes).

#### 4.3.1 Taint Structure

A Node taint consists of:

* **key**: Identifier (e.g., `"maintenance"`, `"gpu"`).
* **value**: Optional string.
* **effect**: One of:

    * `NoSchedule`: Pods not tolerating the taint are not scheduled on the Node (existing Pods unaffected).
    * `PreferNoSchedule`: Kubernetes tries to avoid placing untolerating Pods but may still place them if necessary.
    * `NoExecute`: Pods not tolerating the taint are evicted if already running, and new Pods not tolerating cannot be scheduled.

##### Taint Example

```bash
kubectl taint nodes node-123 key=value:NoSchedule
```

* Adds a taint `key=value:NoSchedule`.
* Only Pods with a matching toleration can schedule onto `node-123`.

View current Node taints:

```bash
kubectl describe node node-123 | grep -i Taint
```

#### 4.3.2 Toleration Structure

A Pod’s `spec.tolerations` lists tolerations that match Node taints. Example:

```yaml
spec:
  tolerations:
    - key: "key"
      operator: "Equal"
      value: "value"
      effect: "NoSchedule"
      # OPTIONAL: tolerationSeconds (only for effect=NoExecute)
```

* **`operator`**:

    * `Equal` (must match key+value).
    * `Exists` (matches any taint with that key, regardless of value).
* **`tolerationSeconds`**: Only valid when `effect: NoExecute`. Allows Pods to remain for a grace period before eviction (e.g., during maintenance).

##### Tolerate All `NoSchedule` Taints

```yaml
tolerations:
  - operator: "Exists"
    effect: "NoSchedule"
```

* Pod will schedule on any Node with any `NoSchedule` taint, effectively “opting in” to all such Nodes.

#### 4.3.3 Common Use Cases

1. **Dedicated GPU Nodes**

    * Taint all GPU Nodes:

      ```bash
      kubectl taint nodes gpu-node gpu=true:NoSchedule
      ```
    * Pods needing GPUs (e.g., machine learning workloads) declare:

      ```yaml
      resources:
        limits:
          nvidia.com/gpu: 1
      tolerations:
        - key: "gpu"
          operator: "Equal"
          value: "true"
          effect: "NoSchedule"
      ```
    * Only pods explicitly requesting a GPU and tolerating `gpu=true:NoSchedule` can schedule on GPU nodes.

2. **Spot/Preemptible Instance Workloads**

    * Cloud providers often taint spot/preemptible VMs:

      ```bash
      kubectl taint nodes spot-node spot=true:NoSchedule
      ```
    * Non‐critical jobs tolerate `spot=true:NoSchedule` to run on spot instances. Critical services avoid those Nodes by not having that toleration.

3. **Node Maintenance**

    * Taint a Node to prevent new Pods and optionally evict existing ones:

      ```bash
      kubectl taint nodes node-123 node.kubernetes.io/maintenance=:NoExecute
      ```
    * Pods without a matching toleration are evicted immediately; Pods that tolerate can remain running (useful for live migrations).

4. **Dedicated Workload Segmentation**

    * Taint a Node so that only certain tiers of applications run there (e.g., `frontend=true:NoSchedule`).
    * Tolerations allow specific workloads to run on those Nodes, isolating tiers.

---

### 4.4 Pod Priority & Preemption

When cluster resources are limited, **Pod Priority** ensures that high‐priority Pods can preempt lower‐priority ones to claim resources. Understanding this mechanism is crucial in multi‐tenant clusters and production environments where critical services must always run.

#### 4.4.1 PriorityClass Definition

* A **PriorityClass** is a cluster‐wide resource specifying:

    * `value`: Integer priority value (higher = more important).
    * `globalDefault`: Boolean; if `true`, Pods without an explicit priorityClassName get this priority.
    * `description`: Human‐readable explanation.

##### Example PriorityClass Manifests

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000000
globalDefault: false
description: "High priority class for critical workloads."
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: low-priority
value: 1000
globalDefault: true
description: "Default low priority for non-critical workloads."
```

* Pods referencing `high-priority` get priority 1 000 000.
* Pods with no `priorityClassName` get `low-priority` (priority 1000).

#### 4.4.2 Assigning Priority to Pods

Pod spec:

```yaml
spec:
  priorityClassName: high-priority
  containers:
    - name: critical-app
      image: myapp:latest
      resources:
        requests:
          cpu: "500m"
          memory: "512Mi"
        limits:
          cpu: "1"
          memory: "1Gi"
```

* Scheduler sees `priorityClassName: high-priority` → priority 1 000 000.

#### 4.4.3 Preemption Mechanism

When a **high‐priority Pod** cannot be scheduled due to insufficient resources on all Nodes, the scheduler attempts to **preempt** (evict) lower‐priority Pods:

1. **Identify Unschedulable Pod**

    * Pod Z with `priority=100000` requests `cpu=3`.
2. **Find Victim Pods**

    * On Node A:

        * Pod X (`priority=1000`, `cpu=2`)
        * Pod Y (`priority=1000`, `cpu=2`)
    * Neither Node A nor Node B have free CPU to schedule Pod Z.
3. **Evaluate Victims**

    * The scheduler finds that evicting both X and Y (sum=4 CPU) frees enough CPU to schedule Z.
    * Among victims, it picks those with lowest priority (1000). Ties broken by earliest creation timestamp.
4. **Evict**

    * Scheduler issues eviction API calls for X and Y. After they terminate, Pod Z can schedule.
    * Preempted Pods are deleted (subject to grace periods). If part of a Deployment/ReplicaSet, they will be replaced unless policy prevents it.

##### Preemption Example

* Node A allocatable CPU: 4
* Running Pods:

    * X: `priority 1000`, `request.cpu=2`
    * Y: `priority 1000`, `request.cpu=2`
* Pod Z: `priority 100000`, `request.cpu=3`

    * No free CPU on Node A or any Node.
    * Scheduler finds victims X and Y; evicts both → frees 4 CPU → Pod Z schedules.

#### 4.4.4 Pod Disruption Budgets (PDBs) & Preemption

* **PDBs** ensure a minimum number of replicas remain available during voluntary disruptions (e.g., maintenance, manual eviction).
* **Preemption** is an involuntary disruption triggered by the scheduler → **PDBs do not prevent preemption**.
* If you want a Pod never to be preempted, set `preemptionPolicy: Never` in the Pod spec:

  ```yaml
  spec:
    priorityClassName: high-priority
    preemptionPolicy: Never
  ```

    * Pod can be scheduled only if there are enough free resources; it will not preempt lower-priority Pods.
    * A Pod with `preemptionPolicy: Never` also cannot preempt others even if it cannot be scheduled otherwise.

#### 4.4.5 Best Practices for Priority & Preemption

1. **Define a Clear Priority Hierarchy**

    * Create meaningful classes: e.g.,

        * `system-critical` (e.g., control-plane, cluster core services)
        * `high` (e.g., production business services)
        * `medium` (e.g., staging or lower-tier services)
        * `low` (e.g., demos, experiments)

2. **Reserve Top Priority for System Components**

    * Use `system-node-critical` or `system-cluster-critical` for essential components (kube-proxy, kube-dns).

3. **Use `preemptionPolicy: Never` for Stateful or Critical Applications**

    * Databases or transactional services with strict stability requirements should not get preempted mid-operation.

4. **Avoid Starvation of Lower‐Priority Pods**

    * If cluster is flooded with high‐priority Pods, lower‐priority Pods may never schedule. Consider reserving capacity via **ResourceQuota** or dedicated node pools.

5. **Monitor Preemption Events**

    * Check events (`kubectl get events`) for `Preempted` messages.
    * Use metrics such as `kube_preemption_victims` for observability and alerting.

6. **Combine with Taints/Tolerations**

    * Taint nodes for critical workloads; only high‐priority Pods with tolerations can land there, further isolating priority classes.

7. **Coordinate with ResourceQuota and LimitRange**

    * Prevent resource overcommitment so that high‐priority Pods do not starve the cluster.
    * Example: If a namespace has `requests.cpu: "4"` quota and LimitRange default `request: 200m`, at most 20 containers can be created. This ensures low‐priority tenants cannot exhaust cluster CPU.

---

## 5. Autoscaling: HPA, VPA, and Cluster Autoscaler

Autoscaling in Kubernetes operates at three levels:

1. **Horizontal Pod Autoscaler (HPA)**: Adjusts the number of pod replicas in a workload (Deployment, ReplicaSet, StatefulSet) based on observed metrics (CPU, memory, custom).
2. **Vertical Pod Autoscaler (VPA)**: Recommends and/or updates a Pod’s resource requests (CPU, memory) to match real usage.
3. **Cluster Autoscaler (CA)**: Scales the number of worker Nodes (VMs) up or down when Pods are unschedulable or Nodes are underutilized.

Understanding how these components work together helps maintain cost-effective, responsive clusters.

### 5.1 Horizontal Pod Autoscaler (HPA)

#### 5.1.1 Overview

* HPA is implemented as a Kubernetes API resource (`autoscaling/v2` or older versions) and a controller running in the control plane.

* Periodically (default \~15 s), HPA queries metrics (via the Metrics API or custom metrics adapter) to observe Pod resource usage.

* HPA computes the desired replica count as:

  ```
  desiredReplicas = ceil[currentReplicas * (currentMetricValue / targetMetricValue)]
  ```

* HPA updates the workload’s `spec.replicas` (bounded by `minReplicas` and `maxReplicas`).

* **Scale‐Down Stabilization**: By default, HPA waits (e.g., 3 minutes) between scale‐down events to avoid flapping.

#### 5.1.2 HPA Manifest Example (CPU Utilization)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-deployment
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
```

* **`scaleTargetRef`**: HPA “watches” `web-deployment`.
* **`minReplicas`/`maxReplicas`**: Bound auto‐scaling between 2 and 10 replicas.
* **`metrics`**:

    * Type: `Resource` → CPU utilization.
    * Targets 50% average CPU across all Pods.

#### 5.1.3 Scaling on Custom or External Metrics

* **Custom Metrics**: E.g., request‐per‐second, queue length (via Prometheus Adapter).

  ```yaml
  metrics:
    - type: Pods
      pods:
        metric:
          name: http_requests_per_second
        target:
          type: AverageValue
          averageValue: "100"
  ```

    * If average RPS >100 per Pod, HPA scales out.

* **External Metrics**: E.g., cloud LB metrics, business KPIs.

  ```yaml
  metrics:
    - type: External
      external:
        metric:
          name: request_count_per_minute
          selector:
            matchLabels:
              service: payment
        target:
          type: Value
          value: "1000"
  ```

    * If external metric value >1000, HPA adjusts replicas.

#### 5.1.4 HPA Requirements & Considerations

* **Metrics Server (or Custom Adapter)**

    * HPA relies on the Metrics API (`metrics.k8s.io/v1beta1`). Ensure Metrics Server is installed and healthy.

* **Resource Requests**

    * HPA uses resource requests as the denominator when calculating utilization.
    * Pods without explicit requests are not ideal; combine with LimitRange in namespaces to enforce minimum requests.

* **Cooldown & Stabilization**

    * Tune `behavior` (scaleUp/scaleDown policies) to avoid rapid oscillations:

      ```yaml
      behavior:
        scaleUp:
          policies:
            - type: Percent
              value: 50  # Can increase replicas by 50% at a time
              periodSeconds: 60
        scaleDown:
          stabilizationWindowSeconds: 300
          policies:
            - type: Percent
              value: 20
              periodSeconds: 60
      ```

* **Min/Max**

    * Setting a nonzero `minReplicas` helps absorb short spikes without needing immediate scaling events.

### 5.2 Vertical Pod Autoscaler (VPA)

#### 5.2.1 Overview

* VPA helps **right‐size** Pods by adjusting resource requests (CPU, memory) to match observed usage.

* Components:

    1. **VPA Recommender**: Watches metrics (via Metrics Server or Prometheus), computes recommendations (e.g., `container A should request 700m CPU, 1Gi memory` based on 95th percentile usage).
    2. **VPA Updater**: If `updateMode` allows, evicts Pods whose resource requests deviate significantly from recommendations. New Pods are created with updated resource requests.
    3. **VPA Admission Controller (Mutating Webhook)**: In some configurations, injects recommended resource requests on Pod creation.

* **Modes**:

    * **`Off`**: Only records recommendations; no evictions or updates.
    * **`Auto`**: Automatically evicts Pods to apply new requests.
    * **`Recreate`**: Deletes all Pods in the targeted workload when applying new requests—useful when you need to ensure rolling‐update semantics.
    * **`Initial`**: Only acts at Pod creation time, injecting recommended requests; does not update running Pods.

#### 5.2.2 Example VPA Manifest

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: backend-vpa
  namespace: production
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
      - containerName: api-container
        minAllowed:
          cpu: "100m"
          memory: "128Mi"
        maxAllowed:
          cpu: "2000m"
          memory: "4Gi"
```

* **`targetRef`**: Points to Deployment `backend`.
* **`updateMode: Auto`**: VPA Updater will evict Pods when recommendations change sufficiently (e.g., >20% difference).
* **`resourcePolicy`**: Constrain how far recommendations can go; ensure that recommendations do not dip below certain thresholds or exceed safe maxima.

#### 5.2.3 VPA Workflow

1. **Data Collection**:

    * VPA Recommender collects historical CPU/memory usage for all Pods matching the target Deployment.

2. **Recommendation Calculation**:

    * At periodic intervals, Recommender computes new recommended values (e.g., 95th percentile usage for CPU and memory).

3. **Pod Eviction & Update (Auto Mode)**:

    * If existing Pods’ requests deviate more than a set threshold from recommendations, VPA Updater evicts them one by one (respecting PodDisruptionBudgets).
    * Evicted Pods are replaced by new Pods with updated resource requests.

4. **Mutating During Creation (Initial Mode)**:

    * If `updateMode: Initial`, VPA Admission Controller intercepts Pod creation and mutates the Pod spec to include the current recommendations. Suitable for initial right-sizing in development or staging.

#### 5.2.4 Caveats & Best Practices

* **HPA & VPA Interactions**

    * Simultaneously using HPA and VPA on the same Deployment can cause oscillations (“Pod churn”).
    * Mitigations:

        * Run VPA in **Initial** mode only (so HPA handles scaling; VPA only sets initial requests).
        * Alternatively, separate workloads: some auto‐scale horizontally (HPA only), others scale vertically (VPA only).

* **Stability & Disruption**

    * VPA eviction may momentarily reduce availability. Always pair with PodDisruptionBudget to avoid mass evictions.
    * Consider using `updateMode: Recreate` in staging/testing to validate behavior before using `Auto` in production.

* **PodDisruptionBudgets**

    * For critical workloads, define PDBs (e.g., `minAvailable: 50%`) to limit how many Pods can be evicted at once.

* **ResourcePolicy**

    * Fine‐tune `minAllowed`/`maxAllowed` to guard against runaway recommendations (e.g., if traffic spike triggers large CPU recommendation that breaks other dependencies).

* **Monitoring**

    * Expose VPA recommendations via:

      ```bash
      kubectl describe vpa backend-vpa -n production
      ```
    * Use metrics such as `vpa_recommendation_cpu_cores` to visualize in dashboards.

### 5.3 Cluster Autoscaler (CA)

#### 5.3.1 Overview

* CA automatically adjusts the number of worker Nodes (VMs) in the cluster based on scheduling demands and node utilization.
* Works in cloud‐provider environments (GKE, EKS, AKS, etc.) by interacting with cloud APIs (e.g., Auto Scaling Groups in AWS) to add or remove Nodes.

#### 5.3.2 How CA Scales Up

1. **Detect Unschedulable Pods**

    * kube-scheduler marks Pods in `Pending` phase with a condition `Unschedulable=true` if they cannot fit on any Node.

2. **Simulate Pod Placement**

    * CA simulates scheduling of unschedulable Pods onto existing Nodes (accounting for affinity, taints, resource requests).
    * If no Node can accommodate, identifies **scale-up candidates**.

3. **Select Node Group to Expand**

    * CA evaluates each Node Group (e.g., AWS ASG or GKE Node Pool) and finds the smallest group that can fit all `Pending` Pods.
    * If multiple Node Groups could work, CA picks one with the best fit (e.g., smallest flavor that satisfies requests).

4. **Provision New Node(s)**

    * CA communicates with cloud provider to increase Node Group size (e.g., set desired capacity = current + 1).
    * New Node registers with the cluster; once ready, scheduler schedules the previously unschedulable Pods.

##### Example: Enable CA on GKE

```bash
gcloud container clusters create my-cluster \
  --enable-autoscaling \
  --min-nodes=1 \
  --max-nodes=5 \
  --num-nodes=1 \
  --zone=us-west1-b
```

* Creates a cluster with initial Node count = 1, and autoscaling enabled between 1 and 5.

#### 5.3.3 How CA Scales Down

1. **Identify Underutilized Nodes**

    * CA periodically checks each Node’s allocatable vs. requested resources.
    * A Node is a **scale-down candidate** if:

        * All non-daemonset Pods on it can be **moved** to other Nodes (respecting resource, affinity, PDB).
        * Node has been underutilized (e.g., < 50% CPU/Memory) for a minimum timeout (e.g., 10 minutes).

2. **Cordon & Drain Node**

    * CA cordons (marks as unschedulable) the candidate Node.
    * Evicts all movable Pods (respecting PDBs).
    * Daemonset Pods and mirror/critical Pods remain because they cannot be evicted.

3. **Terminate Node**

    * Once Node is empty of managed Pods, CA instructs the cloud provider to terminate the VM and decrements desired capacity.

#### 5.3.4 CA Configuration and Tuning

* **Scale‐Down Delay**:

    * Configure `--scale-down-delay-after-add` to wait some time after a scale‐up event before considering scale‐down (to avoid flip‐flopping).
    * Example: `--scale-down-delay-after-add=10m` (wait 10 minutes after adding a Node).

* **Maximum Unneeded Node Count**:

    * `--max-empty-bulk-delete` limits how many empty Nodes can be deleted at once.

* **Ejection Thresholds**:

    * Only delete Nodes once they have been underutilized for a specific grace period (default 10 minutes).
    * Can tune via `--scale-down-unneeded-time` (e.g., 20 minutes).

* **PodDisruptionBudgets (PDBs)**:

    * CA respects PDBs when evicting Pods during scale‐down. If evicting a Pod would violate its PDB, CA skips that Node and will try again later.

* **Expander Strategies (GKE/EKS)**:

    * Determine how CA chooses which Node Group to grow first when multiple Node Groups are eligible. Strategies include:

        * **`most-pods`** (default): Expand group which will not schedule the most pending Pods (maximize Pods scheduled per Node).
        * **`least-waste`**: Expand group that results in least unused CPU/Memory.
        * **`random`**: Pick a random eligible Node Group.

#### 5.3.5 Example CA Behavior

* **Scale-Up Scenario**:

    1. HPA scales a Deployment from 3 to 6 replicas.
    2. kube-scheduler tries to place 6th Pod; no existing Node has enough CPU.
    3. Pod enters `Pending` with `Unschedulable=true`.
    4. CA sees unschedulable Pod, simulates placement → determines Node Group “ng-1” can fit.
    5. CA increases `ng-1` desired size by 1. Cloud provisioning takes \~2 minutes.
    6. New Node joins cluster; scheduler rechecks and places the Pod.

* **Scale-Down Scenario**:

    1. After load decreases, HPA scales Deployment from 6 back to 3 replicas.
    2. Current Node utilization:

        * Node A: 3 Pods (heavy)
        * Node B: 0 Pods
        * Node C: 0 Pods
    3. CA identifies Node B and Node C as underutilized (no non-daemon Pods). Dom lively respected PDBs, safe to evict no-Pod node.
    4. CA cordons Node B, drains (no Pods to drain), and instructs cloud to terminate Node B.
    5. Same for Node C (subject to scale-down thresholds).

#### 5.3.6 Best Practices with Autoscalers

1. **Explicit Resource Requests**

    * HPA and CA rely on accurate resource requests.
    * Enforce defaults via LimitRange so that new Pods always have meaningful resource requests.

2. **Tune HPA Boundaries & Behavior**

    * Increase `minReplicas` to absorb short traffic spikes and avoid triggering scale‐up immediately.
    * Adjust `stabilizationWindowSeconds` to control scale‐down aggressiveness.

3. **Combine VPA Initial Mode with HPA**

    * Let VPA set optimal requests at Pod creation. HPA then scales horizontally. Avoid VPA-driven evictions in production.

4. **Pre‐Provision Buffer Nodes**

    * If cloud provisioning is slow (1–2 minutes), keep a small pool of idle Nodes (e.g., 20% headroom) to handle sudden bursts.

5. **Respect PDBs**

    * CA will skip Nodes if PDB blocking eviction. Ensure PDBs are visible and reflect real availability requirements.

6. **Isolate Workloads with Taints/Affinities**

    * Schedule critical workloads on dedicated Node Pools (tainted) so that CA doesn’t scale generic Node Pools for them.
    * Example:

        * Production workload on Node Pool “prod” (taint `prod=true:NoSchedule`, Pods tolerate).
        * Dev workloads on Node Pool “dev” (taint `dev=true:NoSchedule`).
        * Enables different autoscaling policies per pool.

7. **Avoid HPA & VPA Conflicts**

    * Choose a single autoscaler for a given workload. Often, use VPA in **read‐only** or **initial** mode, and rely on HPA for real‐time scaling.

8. **Monitor Metrics & Events**

    * Check HPA status:

      ```bash
      kubectl get hpa web-hpa -n production
      ```

      Shows current replicas, target vs. actual utilization.
    * Check CA logs (via metrics or direct logs) for scale‐up/scale‐down decisions.
    * Observe Node events:

      ```bash
      kubectl get events -n kube-system --field-selector reason=ScaleUp
      ```

---

## 6. Putting Theory into Practice: Sample Configurations

Below are curated examples illustrating how to combine the above concepts into cohesive, real‐world Kubernetes manifests. Trainees can reference these as blueprints for production‐ready deployments.

---

### 6.1 Three‐Tier Application with ConfigMaps and Secrets

**Scenario**: A microservice “frontend” needs:

1. Non‐sensitive backend API URL.
2. A TLS certificate to authenticate to the backend.
3. Pod should run on SSD Nodes in preferred zones.

#### 6.1.1 ConfigMap: `frontend-config`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-config
  namespace: production
data:
  BACKEND_URL: "https://backend.production.svc.cluster.local:8443"
  REQUEST_TIMEOUT: "30s"
```

* Stores non‐sensitive data such as service endpoint and timeout settings.

#### 6.1.2 Secret: `frontend-cert`

First, base64‐encode cert and key:

```bash
cat tls.crt | base64 -w0 > cert.b64
cat tls.key | base64 -w0 > key.b64
```

Create Secret YAML:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: frontend-cert
  namespace: production
type: kubernetes.io/tls
data:
  tls.crt: <contents-of-cert.b64>
  tls.key: <contents-of-key.b64>
```

* Stores TLS certificate and private key.

#### 6.1.3 Deployment: `frontend`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      # Node Affinity: require SSD; prefer zones us-west1-a, us-west1-b
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
                      - us-west1-a
                      - us-west1-b

      containers:
        - name: frontend
          image: myregistry/frontend:v1.2.3
          # Environment variables from ConfigMap
          env:
            - name: BACKEND_URL
              valueFrom:
                configMapKeyRef:
                  name: frontend-config
                  key: BACKEND_URL
            - name: REQUEST_TIMEOUT
              valueFrom:
                configMapKeyRef:
                  name: frontend-config
                  key: REQUEST_TIMEOUT
          # Mount TLS cert from Secret
          volumeMounts:
            - name: tls-volume
              mountPath: /etc/ssl/certs
              readOnly: true
          # Liveness & readiness probes
          livenessProbe:
            httpGet:
              path: /healthz
              port: 8080
            initialDelaySeconds: 15
            periodSeconds: 10
            timeoutSeconds: 1
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /readyz
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
        - name: sidecar
          image: prom/blackbox-exporter:latest
          # Resource requests/limits
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "200m"
              memory: "256Mi"
          # Startup probe to delay readiness
          startupProbe:
            exec:
              command:
                - /bin/sh
                - -c
                - "sleep 30"
            failureThreshold: 5
            periodSeconds: 10
      volumes:
        - name: tls-volume
          secret:
            secretName: frontend-cert
            items:
              - key: tls.crt
                path: tls.crt
              - key: tls.key
                path: tls.key
            defaultMode: 0400
```

**Key Points**:

* **Node Affinity**:

    * Required: `disktype=ssd`.
    * Preferred: `zone=us-west1-a` or `us-west1-b`.

* **ConfigMap as Environment Variables**:

    * Inject `BACKEND_URL` and `REQUEST_TIMEOUT` via `valueFrom: configMapKeyRef`.
    * Updates to `frontend-config` (volume‐mounted) propagate automatically if mounted as a volume; since they are env vars, Pod restart needed.

* **Secret as Volume**:

    * Mount TLS keys under `/etc/ssl/certs`.
    * File mode `0400` restricts access to root. Application should run as root or adjust security context accordingly.

* **Probes**:

    * Liveness: HTTP probe on `/healthz:8080`, restarts if service deadlocks.
    * Readiness: HTTP probe on `/readyz:8080`, removes Pod from Service if not ready.
    * Startup (in sidecar): Waits 50 s before readiness/liveness probes, ensuring Prometheus exporter is fully initialized.

#### 6.1.4 Rolling Update (Changing `REQUEST_TIMEOUT`)

If `REQUEST_TIMEOUT` should be increased from `30s` to `60s`:

1. Update ConfigMap YAML:

   ```yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: frontend-config
     namespace: production
   data:
     BACKEND_URL: "https://backend.production.svc.cluster.local:8443"
     REQUEST_TIMEOUT: "60s"
   ```
2. Apply:

   ```bash
   kubectl apply -f frontend-config.yaml
   ```

    * Since the ConfigMap was consumed as environment variables (not volume), Pods must be restarted:

      ```bash
      kubectl rollout restart deployment/frontend -n production
      ```
    * New Pods will pick up `REQUEST_TIMEOUT=60s`.

#### 6.1.5 Secret Rotation (TLS Renewal)

1. Generate new certificate files: `new-tls.crt`, `new-tls.key`.
2. Create new Secret YAML (`frontend-cert`):

   ```yaml
   apiVersion: v1
   kind: Secret
   metadata:
     name: frontend-cert
     namespace: production
   type: kubernetes.io/tls
   data:
     tls.crt: <base64 of new-tls.crt>
     tls.key: <base64 of new-tls.key>
   ```
3. Apply:

   ```bash
   kubectl apply -f new-frontend-cert.yaml
   ```

    * Because Secret is volume‐mounted, kubelet updates files under `/etc/ssl/certs` on each Pod.
    * If the frontend application watches certificate file paths and reloads on change, no restart needed. Otherwise:

      ```bash
      kubectl rollout restart deployment/frontend -n production
      ```

---

### 6.2 Namespace Policies: LimitRange + ResourceQuota + Default Taints

**Scenario**: A development (`dev`) namespace needs to enforce resource discipline:

1. **LimitRange**: Minimum/maximum per-container requests/limits.
2. **ResourceQuota**: Overall caps on Pods, CPU/memory sums, and PVC storage.
3. **Default Node Taint**: All dev namespaces run on a `dev`-tainted Node pool, isolating from production.

#### 6.2.1 LimitRange for `dev`

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: dev-limit-range
  namespace: dev
spec:
  limits:
    - type: Container
      # Minimum per container
      min:
        cpu: "100m"
        memory: "128Mi"
      # Maximum per container
      max:
        cpu: "2"
        memory: "2Gi"
      # Default if omitted
      defaultRequest:
        cpu: "200m"
        memory: "256Mi"
      default:
        cpu: "500m"
        memory: "512Mi"
      # Ensure limit/request ≤ 4
      maxLimitRequestRatio:
        cpu: "4"
        memory: "4"
    - type: PersistentVolumeClaim
      min:
        storage: "1Gi"
      max:
        storage: "20Gi"
```

* Any container created in `dev` without resource specs gets requests=`200m`/`256Mi`, limits=`500m`/`512Mi`.
* Containers cannot request <100 m CPU or >2 CPU; memory between `128Mi` and `2Gi`.
* PVCs must request between 1 Gi and 20 Gi.

#### 6.2.2 ResourceQuota for `dev`

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: dev-quota
  namespace: dev
spec:
  hard:
    pods: "10"
    services: "5"
    persistentvolumeclaims: "5"
    requests.cpu: "4"
    requests.memory: "8Gi"
    limits.cpu: "8"
    limits.memory: "16Gi"
    requests.storage: "50Gi"
```

* **Object Counts**: ≤10 Pods, ≤5 Services, ≤5 PVCs.
* **Compute Sums**: Total CPU requests ≤4 CPU, total memory requests ≤8 Gi; total CPU limits ≤8 CPU, total memory limits ≤16 Gi.
* **Storage**: Sum of PVC storage ≤50 Gi.

> **Combined Effect**:
>
> * If a developer tries to create 1 Pod without resource specs:
    >
    >   * LimitRange injects default requests: `200m` CPU, `256Mi` memory.
>   * ResourceQuota tracks usage: after 20 such Pods, `requests.cpu=20×200m=4`, hitting quota.
>   * Any attempt beyond 20 Pods is rejected.

#### 6.2.3 Assigning Dev Pods to Tainted Nodes

Assuming there is a Node Pool labeled and tainted:

1. Label and taint all `dev` Nodes:

   ```bash
   kubectl label node node-dev-1 pool=dev
   kubectl taint node node-dev-1 pool=dev:NoSchedule

   kubectl label node node-dev-2 pool=dev
   kubectl taint node node-dev-2 pool=dev:NoSchedule
   ```

2. In dev Namespace, require `pool=dev` and add toleration:

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: web-app
     namespace: dev
   spec:
     replicas: 3
     selector:
       matchLabels:
         app: web
     template:
       metadata:
         labels:
           app: web
       spec:
         tolerations:
           - key: "pool"
             operator: "Equal"
             value: "dev"
             effect: "NoSchedule"
         containers:
           - name: frontend
             image: nginx:1.21
             resources:
               # Developer can omit resources; LimitRange injects defaults
             readinessProbe:
               httpGet:
                 path: /healthz
                 port: 80
               initialDelaySeconds: 5
               periodSeconds: 10
             livenessProbe:
               httpGet:
                 path: /healthz
                 port: 80
               initialDelaySeconds: 15
               periodSeconds: 20
   ```

* **Toleration**: Allows Pods to schedule onto Nodes tainted `pool=dev:NoSchedule`.
* Without matching toleration, Pods in `dev` namespace cannot land on these Nodes.

---

### 6.3 Robust Scheduling with Taints, Affinity, and Priority

**Scenario**: A “critical-web” Deployment in `production` requiring:

1. SSD Nodes only (`disktype=ssd`).
2. Preferred zones to minimize latency.
3. Tolerate `maintenance` taints (so Pods survive planned Node maintenance).
4. High priority so they can preempt lower‐priority workloads under resource contention.

#### 6.3.1 PriorityClasses

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000000
globalDefault: false
description: "High priority for critical web workloads."
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: low-priority
value: 1000
globalDefault: true
description: "Default priority for non-critical workloads."
```

* Pods specifying `priorityClassName: high-priority` get priority `1000000`.
* All other Pods (no priorityClassName) default to `low-priority` (1000).

#### 6.3.2 Deployment: `critical-web`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: critical-web
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: critical-web
  template:
    metadata:
      labels:
        app: critical-web
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
            - weight: 2
              preference:
                matchExpressions:
                  - key: zone
                    operator: In
                    values:
                      - us-west1-a
                      - us-west1-b
      tolerations:
        - key: "maintenance"
          operator: "Exists"
          effect: "NoSchedule"
      containers:
        - name: web
          image: nginx:1.21
          resources:
            requests:
              cpu: "500m"
              memory: "512Mi"
            limits:
              cpu: "1"
              memory: "1Gi"
          livenessProbe:
            httpGet:
              path: /healthz
              port: 80
            initialDelaySeconds: 10
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /readyz
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 5
```

**Breakdown**:

1. **`priorityClassName: high-priority`**

    * Ensures this Pod’s priority = 1 000 000.
    * Will preempt lower‐priority (1000) Pods if resources are scarce.

2. **Node Affinity**

    * **Required**: Node must have `disktype=ssd`.
    * **Preferred** (weight=2): Nodes labeled `zone=us-west1-a` or `us-west1-b` get extra priority.

3. **Tolerations**

    * Tolerate any `maintenance:NoSchedule` taint, allowing Pods to remain on Nodes marked for maintenance.

4. **Resource Requests & Limits**

    * Requests: `cpu=500m`, `memory=512Mi`.
    * Limits: `cpu=1`, `memory=1Gi`.
    * Ensures Pod is **Burstable** QoS (requests < limits), so less likely than BestEffort to be evicted, but more likely than Guaranteed.

5. **Probes**

    * Liveness and readiness configured for robust health checking.

#### 6.3.3 Scheduling & Preemption Flow

1. **Submit Deployment**

    * 3 replicas → scheduler attempts to place 3 Pods.

2. **Filtering Phase**

    * Check Node labels: only SSD Nodes pass.
    * Check if Node is tainted (e.g., `maintenance`). Since Pod tolerates any `maintenance:NoSchedule` taint, it can schedule on maintenance Nodes if needed.

3. **Scoring Phase**

    * Among SSD Nodes, those in `us-west1-a`/`us-west1-b` get weight 2.
    * Less‐utilized Nodes receive higher `LeastRequestedPriority` scores.

4. **Binding**

    * Scheduler picks the highest‐scored Nodes, binds Pods.
    * kubelet on each Node starts containers.

5. **Preemption (if needed)**

    * If no Node has free resources (`≥500m CPU` and `≥512Mi memory`), scheduler looks for lower‐priority Pods (`priority=1000`) to preempt.
    * Evicts victims until enough resources become free.
    * New Pod binds immediately after victims evicted (even if their termination is in progress, as soon as resources are reclaimed).

6. **Runtime**

    * **Probes** ensure containers are restarted if unhealthy and removed from Services if not ready.
    * If a Node is tainted `maintenance=true:NoExecute`, Pods without toleration get evicted; since these tolerate `maintenance`, they stay running.

---

### 6.4 Autoscaling Integration

**Scenario**: A “web-deployment” in `production` that must dynamically scale based on CPU utilization, have optimal resource requests, and run on a cluster that scales Nodes automatically.

#### 6.4.1 Deployment: `web-deployment`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
  namespace: production
spec:
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
        - name: web
          image: nginx:1.21
          resources:
            requests:
              cpu: "200m"
              memory: "256Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
          readinessProbe:
            httpGet:
              path: /healthz
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /healthz
              port: 80
            initialDelaySeconds: 15
            periodSeconds: 20
```

* Initial replicas: 2.
* Resource requests/limits: ensure cluster scheduling accuracy.

#### 6.4.2 Horizontal Pod Autoscaler (HPA)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-deployment
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
```

* HPA ensures average CPU utilization across Pods stays at \~50%.
* Will scale between 2 and 10 replicas based on real CPU usage.

#### 6.4.3 Vertical Pod Autoscaler (VPA)

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: web-vpa
  namespace: production
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-deployment
  updatePolicy:
    updateMode: "Initial"
  resourcePolicy:
    containerPolicies:
      - containerName: web
        minAllowed:
          cpu: "100m"
          memory: "128Mi"
        maxAllowed:
          cpu: "1000m"
          memory: "1Gi"
```

* **`updateMode: Initial`**: VPA only sets resource requests at Pod creation; does not evict existing Pods.
* Recommendations will be computed (e.g., maybe bump CPU from `200m` to `300m` after observing usage).

> **Workflow**:
>
> 1. VPA Recommender gathers CPU/memory usage metrics for `web-deployment` Pods.
> 2. On new Pod creation (triggered by HPA scaling out or rollout), VPA Admission Controller injects updated recommended requests (within minAllowed/maxAllowed).
> 3. HPA then uses these updated requests for subsequent scaling decisions.

#### 6.4.4 Cluster Autoscaler (CA)

* Cluster is provisioned on a cloud provider (e.g., GKE, EKS) with an autoscaling Node Pool.

* Example GKE command:

  ```bash
  gcloud container clusters create production-cluster \
    --enable-autoscaling \
    --min-nodes=3 \
    --max-nodes=10 \
    --num-nodes=3 \
    --zone=us-west1-b
  ```

* **Scale‐Up**: When HPA increases replicas but no existing Node can accommodate new Pods, CA will provision new Nodes (up to 10).

* **Scale‐Down**: When HPA scales in (e.g., from 10 → 3 replicas) and some Nodes become underutilized, CA will cordon and drain underutilized Nodes and delete them (down to min-nodes=3).

#### 6.4.5 Interplay & Considerations

1. **HPA relies on VPA in Initial Mode**

    * Ensures VPA sets accurate requests on new Pods, so HPA’s CPU utilization calculations are meaningful.

2. **CA responds to HPA-induced scheduling failures**

    * If HPA scales to 6 replicas but existing 3 Nodes cannot host, CA adds Nodes.
    * If HPA scales down to 2 replicas, CA removes underutilized Nodes.

3. **PodDisruptionBudgets (PDBs)**

    * Example PDB for web-deployment:

      ```yaml
      apiVersion: policy/v1
      kind: PodDisruptionBudget
      metadata:
        name: web-pdb
        namespace: production
      spec:
        minAvailable: 50%   # At least half of Pods must be ready during voluntary disruptions
        selector:
          matchLabels:
            app: web
      ```
    * CA respects PDBs when evicting Pods during scale-down. If eviction would violate PDB, CA delays deleting that Node.

4. **Buffer for Rapid Spikes**

    * If cloud provisioning takes \~2 minutes, consider setting `minReplicas` slightly higher (e.g., 3) to handle sudden spikes without triggering CA.
    * Alternatively, provision additional “buffer” Nodes manually or via a separate Node Pool for burst workloads.

5. **Monitoring & Metrics**

    * Check HPA status:

      ```bash
      kubectl get hpa web-hpa -n production
      ```
    * Inspect CA events/logs to see scale-up/down decisions, using cluster logging or `kubectl get events -n kube-system`.
    * VPA recommendations via:

      ```bash
      kubectl describe vpa web-vpa -n production
      ```

---

## 7. Summary & Learning Path

This guide covered the essential Kubernetes concepts trainees need to master for independently managing production‐grade clusters:

1. **Configuration Management**

    * **ConfigMaps**: Non‐sensitive key–value data, consumable via environment variables or volumes. Best practices for size, immutability, and version control.
    * **Secrets**: Sensitive data, base64‐encoded (or `stringData` plaintext), consumable via env vars, volumes, or image pull. Emphasis on encryption, RBAC, immutability, and rotation.

2. **Probes**

    * **Liveness Probes**: Detect unresponsive containers → restart.
    * **Readiness Probes**: Mark Pods as ready/not ready → control Service routing.
    * **Startup Probes**: Delay liveness/readiness for long initialization.

3. **Resource Management**

    * **Requests & Limits**: Control scheduling and runtime enforcement.
    * **QoS Classes**: Guaranteed, Burstable, BestEffort → eviction order.
    * **LimitRange**: Namespace‐scoped defaults and constraints for resource requests/limits and PVC storage.
    * **ResourceQuota**: Namespace‐scoped aggregate caps on objects and resource consumption.

4. **Scheduling Mechanics**

    * **kube-scheduler**: Filtering (predicates) + Scoring (priorities) + Binding.
    * **Node Selection**: `nodeSelector`, **Node Affinity** (required & preferred).
    * **Taints & Tolerations**: Repel Pods from Nodes unless tolerated.
    * **Pod Priority & Preemption**: Ensure critical workloads can run by evicting lower‐priority Pods when necessary.

5. **Autoscaling**

    * **Horizontal Pod Autoscaler (HPA)**: Scale replicas based on CPU/memory/custom metrics.
    * **Vertical Pod Autoscaler (VPA)**: Recommend or auto‐update Pod resource requests.
    * **Cluster Autoscaler (CA)**: Adjust Node pool size based on scheduling demands and utilization, respecting PDBs.

By reviewing and practicing with the provided examples—creating ConfigMaps/Secrets, configuring probes, setting resource policies, experimenting with affinity/taints, and deploying autoscalers—trainees can build a strong foundation. For further self‐study, consider exploring:

* Official Kubernetes documentation:

    * [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
    * [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
    * [Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
    * [Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
    * [LimitRange](https://kubernetes.io/docs/concepts/policy/limit-range/)
    * [ResourceQuota](https://kubernetes.io/docs/concepts/policy/resource-quotas/)
    * [Scheduling](https://kubernetes.io/docs/concepts/scheduling-eviction/scheduling-framework/)
    * [Taints & Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)
    * [Priority & Preemption](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)
    * [HPA](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
    * [VPA](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler)
    * [Cluster Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)
