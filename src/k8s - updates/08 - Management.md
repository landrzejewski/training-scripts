## Module 1: Node Maintenance in a Kubernetes Cluster

When operating a production Kubernetes cluster, it is essential to know how to take individual machines (nodes) offline for maintenance—whether for OS upgrades, security patches, or hardware fixes—without disrupting applications. This module covers how to cordon, drain, taint, and restore nodes safely, and it outlines strategies for automating or coordinating rolling maintenance windows across a cluster.

### 1.1 Cordoning a Node: Marking the Node Unschedulable

* **Definition**: *Cordoning* means marking a node as unschedulable so that no new Pods are assigned to it. Existing Pods continue to run until explicitly evicted.
* **Command**:

  ```bash
  kubectl cordon <node-name>
  # Example:
  kubectl cordon worker-node-01
  ```
* **When to use**: When you want to prevent new work from landing on a node but still allow currently running Pods to continue until you are ready to evict them.

### 1.2 Draining a Node: Evicting Workloads Before Maintenance

* **Definition**: *Draining* a node evicts all eligible Pods (except those managed by DaemonSets or those explicitly protected) so that the node can be taken offline.
* **Basic Command**:

  ```bash
  kubectl drain <node-name> \
    --ignore-daemonsets \
    --delete-emptydir-data
  # Example:
  kubectl drain worker-node-01 \
    --ignore-daemonsets \
    --delete-emptydir-data
  ```

    * `--ignore-daemonsets`: Skips Pods created by DaemonSets (these will automatically restart once the node is back online).
    * `--delete-emptydir-data`: Allows eviction of Pods that use `emptyDir` volumes; data stored in those volumes will be lost once the Pod is deleted.
* **PodDisruptionBudgets (PDBs)**: By default, draining honors any PDBs in the namespace. If a Pod’s PDB prevents eviction (e.g., minimum-available count is not met), `kubectl drain` will hang or error. To work around:

    1. Check current PDBs:

       ```bash
       kubectl get pdb -n <namespace>
       ```
    2. Temporarily relax or delete the PDB if you are certain eviction is safe, or adjust your workloads to tolerate a reduced replica count during maintenance.

#### 1.2.1 Handling StatefulSets and PDB-Protected Pods

* Pods managed by StatefulSets or with strict PDBs may refuse eviction. In those cases:

    1. **Scale down** (with caution) StatefulSet replicas, ensuring that the application can tolerate fewer replicas temporarily.
    2. **Relax PDB constraints** (for example, increase `maxUnavailable`) so that drain can proceed without violating the desired availability.

### 1.3 Tainting for Maintenance: Using Taints and Tolerations

* **Alternative to drain/cordon**: You can apply a taint that immediately evicts Pods lacking a matching toleration.
* **Taint Command**:

  ```bash
  kubectl taint nodes worker-node-01 maintenance=true:NoExecute
  ```

    * The effect `NoExecute` evicts any Pod that does not explicitly tolerate the taint.
* **Pod Toleration Example** (allowing a Pod to remain for short-term maintenance):

  ```yaml
  tolerations:
    - key: "maintenance"
      operator: "Equal"
      value: "true"
      effect: "NoExecute"
      tolerationSeconds: 600
  ```

    * `tolerationSeconds: 600` means the Pod may continue to run for up to 600 seconds (10 minutes) after the taint is applied; after that, it is evicted if still not relocated.

### 1.4 Performing the Maintenance and Restoring the Node

1. **Perform Maintenance**: Once the node is drained (or tainted), it is safe to patch the OS, reboot, swap hardware, or apply kernel upgrades.
2. **Uncordon/Remove Taint**:

    * To mark the node schedulable again:

      ```bash
      kubectl uncordon worker-node-01
      ```
    * Or, if you used a taint:

      ```bash
      kubectl taint nodes worker-node-01 maintenance:NoExecute-
      ```
3. **Scheduler Behavior**: After uncordoning (or removing the taint), the scheduler may place new Pods or evicted Pods onto the node as the cluster’s desired state reconciles.

### 1.5 Automating Rolling Maintenance

In medium‐to‐large clusters, manually cordoning and draining nodes one by one can be error‐prone. Consider these enhancements:

* **PodDisruptionBudget Configuration**: For each critical Deployment or StatefulSet, define a PDB that allows a safe number of replicas to be unavailable during rolling maintenance (e.g., allow one Pod to be disrupted at a time).
* **Node Pools & Managed Upgrades**: If you run on a managed Kubernetes service (GKE, EKS, AKS), leverage built-in node pool rolling upgrades. The control plane will automatically cordon/drain each node in the pool, update it with the new OS/image, then uncordon it in a controlled fashion.
* **Custom Operators or Scripts**:

    * Write a simple script (or use a Kubernetes Operator) that:

        1. Lists all nodes in a particular group or with a specific label.
        2. For each node, cordons, drains (with PDB awareness), waits for all Pods to evacuate, and then triggers your maintenance action (e.g., via SSH or cloud API).
        3. Uncordons once the node is healthy.
    * Enforce “one node at a time” to ensure cluster capacity remains above a safe threshold.

---

## Module 2: Application Update Strategies

Kubernetes offers built-in mechanics for zero- or low-downtime application updates. In more advanced scenarios, organizations employ Blue/Green, Canary, A/B testing, or Traffic Shadowing. This module covers:

1. **Native Deployment Strategies**: Recreate vs. RollingUpdate.
2. **Blue/Green Deployments**.
3. **Canary Releases**.
4. **A/B Testing**.
5. **Shadow (Mirroring) Traffic**.

### 2.1 Native Deployment Update Strategies

A Kubernetes **Deployment** manages ReplicaSets (sets of Pods). Two main `strategy` types exist:

#### 2.1.1 Recreate Strategy

* **Behavior**: Terminates all existing Pods first, then spins up new Pods.
* **Use Case**:

    * Acceptable downtime is okay.
    * Major data/schema changes where old and new versions cannot coexist.
* **Configuration**:

  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: myapp
  spec:
    replicas: 3
    strategy:
      type: Recreate
    template:
      metadata:
        labels:
          app: myapp
      spec:
        containers:
          - name: myapp
            image: myapp:v2
  ```
* **Result**: All three old-version Pods terminate; once they are gone, three new Pods launch. Users experience a brief outage.

#### 2.1.2 RollingUpdate Strategy (Default)

* **Behavior**: Gradually replaces old Pods with new Pods, respecting two parameters:

    * `maxSurge` (how many extra Pods above `replicas` are allowed during the update).
    * `maxUnavailable` (how many old Pods are allowed to be down simultaneously).
* **Configuration Example**:

  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: myapp
  spec:
    replicas: 3
    strategy:
      type: RollingUpdate
      rollingUpdate:
        maxSurge: 1
        maxUnavailable: 0
    template:
      metadata:
        labels:
          app: myapp
      spec:
        containers:
          - name: myapp
            image: myapp:v2
  ```

    * With `replicas: 3`, `maxSurge: 1`, and `maxUnavailable: 0`, Kubernetes will:

        1. Create one new Pod (v2), bringing total to 4.
        2. Once that Pod passes readiness checks, delete one old Pod (v1), returning to 3.
        3. Repeat until all old Pods are replaced.
* **Result**: At least two Pods remain available at all times; minimal or zero downtime.

### 2.2 Blue/Green Deployment

**Concept**: Two independent environments—Blue (current live) and Green (staging for new version). Only one environment is live at a time.

#### 2.2.1 Steps

1. **Deploy Blue Version (Initial State)**:

    * For example, a Deployment named `web-blue`, with Pods labeled `version=blue`.
    * Service (e.g., `web-svc`) selects pods with `version=blue`.
2. **Deploy Green Version**:

    * Create a separate Deployment named `web-green` with Pods labeled `version=green`.
    * Do not yet switch traffic; run tests against `web-green` (e.g., run smoke tests, health checks).
3. **Switch Service Traffic**:

    * Once `web-green` is healthy, update the Service selector:

      ```bash
      kubectl patch svc web-svc -p '{"spec":{"selector":{"app":"web","version":"green"}}}'
      ```
    * All incoming requests now go to `version=green` Pods.
4. **Optional Rollback**:

    * If issues arise, patch Service back to `version=blue`.
5. **Clean Up**:

    * Once confident `green` is stable, delete `web-blue` or keep it idle as a rollback pool.

#### 2.2.2 Kubernetes YAML Example

* **Blue Deployment**:

  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: web-blue
  spec:
    replicas: 3
    selector:
      matchLabels:
        app: web
        version: blue
    template:
      metadata:
        labels:
          app: web
          version: blue
      spec:
        containers:
          - name: web
            image: web-app:v1
  ```
* **Green Deployment**:

  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: web-green
  spec:
    replicas: 3
    selector:
      matchLabels:
        app: web
        version: green
    template:
      metadata:
        labels:
          app: web
          version: green
      spec:
        containers:
          - name: web
            image: web-app:v2
  ```
* **Single Service** (initially pointing to Blue):

  ```yaml
  apiVersion: v1
  kind: Service
  metadata:
    name: web-svc
  spec:
    type: ClusterIP
    selector:
      app: web
      version: blue
    ports:
      - name: http
        port: 80
        targetPort: 8080
  ```

### 2.3 Canary Deployment

**Concept**: Release a new version (the canary) to a small subset of users or a small percentage of traffic, then gradually shift more traffic as confidence builds.

#### 2.3.1 Manual Pod Count Approach

1. **Existing Stable Deployment**: e.g., `web-stable` with label `version=stable` and 10 replicas.
2. **Create Canary Deployment**: e.g., `web-canary` with label `version=canary` and 1 replica.
3. **Service Configuration**: A Service that selects both `version=stable` and `version=canary`. Without additional weighting, Kubernetes will load-balance evenly among all Pods; to achieve “5% traffic,” you rely on external traffic weighting (Ingress) or manually control Pod counts (e.g., 1 canary vs. 19 stable).
4. **Traffic Splitting**: Use an Ingress controller annotation or service mesh for precise percentages:

    * **NGINX Ingress Controller**:

      ```yaml
      metadata:
        annotations:
          nginx.ingress.kubernetes.io/canary: "true"
          nginx.ingress.kubernetes.io/canary-weight: "5"
      ```

      This sends \~5% of requests to the canary Ingress/Service, the rest to stable.
    * **Services Only**: If `web-stable` has 19 Pods and `web-canary` has 1 Pod (20 total), the default ClusterIP load-balancer will send 5% of traffic (1/20) to the canary Pods.

#### 2.3.2 Service Mesh Traffic Splitting (Istio Example)

1. **DestinationRule** configuring subsets:

   ```yaml
   apiVersion: networking.istio.io/v1alpha3
   kind: DestinationRule
   metadata:
     name: web-destinationrule
   spec:
     host: web-svc
     subsets:
       - name: stable
         labels:
           version: stable
       - name: canary
         labels:
           version: canary
   ```
2. **VirtualService** specifying weights:

   ```yaml
   apiVersion: networking.istio.io/v1alpha3
   kind: VirtualService
   metadata:
     name: web-virtualservice
   spec:
     hosts:
       - web.example.com
     http:
       - route:
           - destination:
               host: web-svc
               subset: stable
             weight: 95
           - destination:
               host: web-svc
               subset: canary
             weight: 5
   ```
3. **Deployment Labels**:

    * `web-stable` Pods: label `version: stable`.
    * `web-canary` Pods: label `version: canary`.
4. **Result**: Istio’s sidecar proxies route 95% of traffic to stable, 5% to canary.

### 2.4 A/B Testing: Segmenting by User Criteria

**Concept**: Similar to Canary, but instead of purely numeric percentage splits, route based on user segment (e.g., header, cookie).

#### 2.4.1 NGINX Ingress Example with Cookie-Based Splitting

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  annotations:
    nginx.ingress.kubernetes.io/traffic-split: |
      stable=90,canary=10
    nginx.ingress.kubernetes.io/traffic-shaping-method: "cookie"
spec:
  rules:
    - host: web.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web-svc
                port:
                  number: 80
```

* **Behavior**: On first visit, the Ingress controller sets a cookie determining whether the user lands on the stable or canary version (90% vs. 10%). Subsequent requests from that user go consistently to the same version until cookie expires or is changed.

#### 2.4.2 Header-Based Routing (Ingress or Service Mesh)

```yaml
# Example: route requests with header X-Group: beta to canary
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: web-virtualservice
spec:
  hosts:
    - web.example.com
  http:
    - match:
        - headers:
            X-Group:
              exact: "beta"
      route:
        - destination:
            host: web-svc
            subset: canary
    - route:
        - destination:
            host: web-svc
            subset: stable
```

* **Behavior**: All requests with header `X-Group: beta` go to canary, others to stable. This allows testing on a defined subset of users (e.g., internal QA team, or a segment of real traffic).

### 2.5 Traffic Shadowing (Mirroring) for Safe Validation

**Concept**: Route a copy of real user traffic (“mirror” or “shadow”) to a new version while still serving production traffic from the stable version. The mirrored traffic is used for analysis or load testing; responses from the shadow service are discarded.

#### 2.5.1 Istio Mirroring Example

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: web-virtualservice
spec:
  hosts:
    - web-svc
  http:
    - match:
        - uri:
            prefix: /
      route:
        - destination:
            host: web-svc
            subset: stable
      mirror:
        host: web-svc
        subset: canary
      mirrorPercent: 100
```

* **Behavior**:

    1. 100% of live traffic is routed to `subset: stable`.
    2. Each request is duplicated (“mirrored”) to `subset: canary`.
    3. Canary processes the request but its response is ignored. You can inspect canary logs, metrics, or tracing to see how it handles real traffic under load.

#### 2.5.2 When to Use

* Validate performance/principled correctness of a new version under real-world traffic patterns, without risking user impact.
* Identify unexpected errors or latency in the new version before fully shifting traffic.

---

## Module 3: Custom Resource Definitions (CRDs) and Extending Kubernetes

Kubernetes is extensible not just via flags or plugin binaries, but at the API level through **Custom Resource Definitions (CRDs)**. With CRDs you can teach Kubernetes about new “kinds” of objects and build your own controllers (often called Operators) to manage them.

### 3.1 What Is a CRD?

* **Definition**: A CRD is a Kubernetes API extension mechanism. Once you register a CRD, the API server begins accepting objects of that custom Kind as first-class resources (e.g., `kubectl get myresources`).
* **Use-cases**:

    * Package an application-specific concept into Kubernetes (e.g., `BackupJob`, `CertificateRequest`, `DatabaseCluster`).
    * Create operators/controllers that reconcile the desired state described by your CRs (Custom Resources) with actual cluster resources.

### 3.2 Anatomy of a CRD Manifest

Below is a minimal example of a CRD for a custom resource called `Widget`:

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: widgets.example.com
spec:
  group: example.com
  versions:
    - name: v1alpha1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                size:
                  type: integer
                color:
                  type: string
      subresources:
        status: {}          # Allows writing to .status subresource
      additionalPrinterColumns:
        - name: Size
          type: integer
          jsonPath: .spec.size
  scope: Namespaced
  names:
    plural: widgets
    singular: widget
    kind: Widget
    shortNames:
      - wd
```

* **`group: example.com`**: The API group under which this CRD lives.
* **`versions`**: You can define multiple versions (`v1alpha1`, `v1beta1`, `v1`). One version must have `storage: true`; the API server stores CRs in that version. Other versions can be served (readable/writable) if you implement conversion logic.
* **`schema.openAPIV3Schema`**: Defines a JSON schema for validation of your CR. This ensures that objects created under `kind: Widget` will be checked against that schema (e.g., `spec.size` must be an integer).
* **`subresources.status`**: Enables a `/status` subresource. Controllers can update `.status` without changing `.spec`.
* **`additionalPrinterColumns`**: Adds custom columns to `kubectl get widgets`, e.g., a column named “Size” showing `spec.size`.
* **`scope: Namespaced`**: Indicates that `Widget` resources live inside a namespace (as opposed to `Cluster` scope—cluster-wide).

### 3.3 Creating and Using a Custom Resource

1. **Apply the CRD**:

   ```bash
   kubectl apply -f widget-crd.yaml
   ```

   After this, you can `kubectl get crd widgets.example.com` and see that Kubernetes recognizes the new resource.

2. **Create a Custom Resource (CR)**:

   ```yaml
   apiVersion: example.com/v1alpha1
   kind: Widget
   metadata:
     name: my-widget
   spec:
     size: 3
     color: "blue"
   ```

   Save as `my-widget.yaml` and apply:

   ```bash
   kubectl apply -f my-widget.yaml
   ```

   Now you can inspect it:

   ```bash
   kubectl get widgets
   # NAME         AGE
   # my-widget    1m
   kubectl describe widget my-widget
   ```

3. **Write a Controller/Operator**:

    * Use a framework like [Kubebuilder](https://book.kubebuilder.io/) or the Operator SDK to scaffold a Go (or other language) project that:

        1. **Watches** for changes to `Widget` resources.
        2. **Reconciles**: Reads the desired state (`spec.size`, `spec.color`) and creates/updates underlying Kubernetes objects (e.g., Deployment, Service) to match.
        3. **Updates status**: Writes progress or conditions to `status` subresource (e.g., `status.phase: Ready`).
    * Over time, the CRD can evolve, adding new fields or behaviors. Use known patterns to manage versioning, conversions, and backward compatibility.

### 3.4 Versioning and Conversions

* **Multiple Versions**: When your CRD reaches a mature state, you might introduce a newer API version (`v1beta1`, `v1`), deprecating older ones.
* **Conversion Strategies**:

    * **Webhook Conversion**: Implement a conversion webhook service. When the API server needs to serve or store a CR in a different version, it calls your webhook to translate between versions.
    * **None (Default)**: Kubernetes can do a basic “no-op” conversion if the versions share the same structural schema. Once your schemas diverge, you must implement a conversion webhook.
* **Graduating to Stable**: Once `v1` is stable and `v1beta1` is deprecated, mark `v1` as `storage: true` and remove older versions (after a deprecation period).

---

## Module 4: Downward API—Accessing Pod and Container Metadata

Containers often need to know information about their own Pod (name, namespace, labels, resource requests) at runtime, without passing it explicitly via environment variables or ConfigMaps. The **Downward API** is a built-in mechanism that lets you expose Pod metadata and resource fields into the container’s environment or filesystem.

### 4.1 Use Cases for the Downward API

* **Log Tagging**: Automatically include the Pod name or namespace in application logs, so that when logs land in a centralized system you know exactly which Pod produced them.
* **Config by Labels/Annotations**: If a Pod has a label like `featureX=enabled`, the application can read that label from its environment and toggle behavior accordingly.
* **Resource-Aware Behavior**: A Java application might read its CPU or memory request at startup to size thread pools or caches accordingly.
* **Self-Registration/Discovery**: A Pod registers itself in a service registry with its IP and namespace when it starts.

### 4.2 Exposing Metadata via Environment Variables

#### 4.2.1 Sample Pod Spec

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: downward-demo
  namespace: production
  labels:
    app: metrics-proxy
    tier: backend
  annotations:
    log-level: debug
spec:
  containers:
    - name: app
      image: myapp:latest
      env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: LABEL_APP
          valueFrom:
            fieldRef:
              fieldPath: metadata.labels['app']
        - name: ANNOT_LOG_LEVEL
          valueFrom:
            fieldRef:
              fieldPath: metadata.annotations['log-level']
        - name: CPU_REQUEST
          valueFrom:
            resourceFieldRef:
              containerName: app
              resource: requests.cpu
              divisor: "1"        # Keep as millicores
        - name: MEMORY_REQUEST
          valueFrom:
            resourceFieldRef:
              containerName: app
              resource: requests.memory
              divisor: "1Mi"     # Convert to MiB
      resources:
        requests:
          cpu: "250m"
          memory: "512Mi"
```

#### 4.2.2 Resulting Environment Variables Inside the Container

```
POD_NAME=downward-demo
POD_NAMESPACE=production
LABEL_APP=metrics-proxy
ANNOT_LOG_LEVEL=debug
CPU_REQUEST=250m
MEMORY_REQUEST=512Mi
```

* **`metadata.name` / `metadata.namespace`**: Provides Pod identity.
* **`metadata.labels['app']`**: Reads the value of the label named `app`.
* **`metadata.annotations['log-level']`**: Reads the annotation value.
* **`resourceFieldRef`**: Reads resource requests (`cpu`, `memory`). Divisors let you choose units: `"1"` means millicores for CPU; `"1Mi"` means Mebibytes for memory.

### 4.3 Exposing Metadata via Files (Volume Projection)

Instead of (or in addition to) environment variables, you can project metadata into files. Kubernetes creates a tiny in-memory volume that presents JSON-encoded values for each item you specify. The container can read those files at runtime.

#### 4.3.1 Sample Pod Spec with Downward API Volume

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: downward-volume-demo
  labels:
    app: logger
    version: v1
spec:
  volumes:
    - name: podinfo
      downwardAPI:
        items:
          - path: "labels"
            fieldRef:
              fieldPath: metadata.labels
          - path: "annotations"
            fieldRef:
              fieldPath: metadata.annotations
          - path: "podname"
            fieldRef:
              fieldPath: metadata.name
          - path: "cpu"
            resourceFieldRef:
              containerName: app
              resource: requests.cpu
              divisor: "1"
          - path: "memory"
            resourceFieldRef:
              containerName: app
              resource: requests.memory
              divisor: "1Mi"
  containers:
    - name: app
      image: busybox
      command:
        - "sh"
        - "-c"
        - |
          echo "Pod name: $(cat /etc/podinfo/podname)"
          echo "Labels: $(cat /etc/podinfo/labels)"
          echo "Annotations: $(cat /etc/podinfo/annotations)"
          echo "CPU Request: $(cat /etc/podinfo/cpu)m"
          echo "Memory Request: $(cat /etc/podinfo/memory)Mi"
          sleep 3600
      volumeMounts:
        - name: podinfo
          mountPath: /etc/podinfo
```

* **Volume Type**: `downwardAPI`.
* **Items**:

    * `"labels"`: A file named `labels` will contain a JSON object of all labels (e.g., `{"app":"logger","version":"v1"}`).
    * `"annotations"`: A file named `annotations` will contain a JSON object of all annotations.
    * `"podname"`: Contains just the Pod’s name as a UTF-8 string.
    * `"cpu"` / `"memory"`: Contain numeric values (as strings) representing the CPU and memory requests.

#### 4.3.2 Inside the Container

If you `cat /etc/podinfo/labels`, you might see:

```json
{"app":"logger","version":"v1"}
```

And `cat /etc/podinfo/podname` yields:

```
downward-volume-demo
```

The application or sidecar can then parse or log these values.

### 4.4 Common Downward API Patterns

1. **Loggers & Sidecars**:

    * A sidecar container (e.g., a logging agent) can read the Pod’s labels from `/etc/podinfo/labels` and add those as metadata tags when shipping logs to a centralized system (ELK, Graylog, etc.).
2. **Feature Flags via Labels**:

    * Instead of building a separate ConfigMap or flag system, an application checks for `metadata.labels['featureX']`. If `featureX=enabled`, the application toggles a new behavior.
3. **Self-Registration**:

    * A service registry component in the same Pod reads `metadata.annotations['service-endpoint']` or `status.hostIP` to auto-register itself where needed.
4. **Resource-Aware Configuration**:

    * A Java or Go server starts up and reads `requests.cpu` to decide how many worker threads to spawn; reads `requests.memory` to allocate an internal cache.

---

## Module 5: Log Collection in Kubernetes

In containerized environments, logs are ephemeral and scattered across nodes. Centralizing logs ensures you can search, analyze, and visualize them even after Pods restart or move. This module explains the challenges of Kubernetes logging, architectural patterns (DaemonSet vs. sidecar), and two popular aggregation stacks: the ELK Stack and Graylog.

### 5.1 Challenges of Containerized Logging

* **Ephemeral Pods**:
  Pods launch and terminate frequently; once a Pod dies, its logs vanish unless collected beforehand.
* **Distributed Nodes**:
  Containers run on many nodes; logs need to be shipped off each node to a central location.
* **Standard Interfaces**:
  By default, containers emit logs to `stdout`/`stderr`; Kubernetes writes those streams to files under `/var/log/containers`. Manually running `kubectl logs` becomes impractical at scale.
* **Log Formats**:
  Some applications produce structured JSON logs; others emit unstructured text. A log pipeline must be able to parse, filter, and normalize different formats.

### 5.2 Architectural Patterns for Log Shippers

#### 5.2.1 DaemonSet-Based Log Forwarder (Recommended)

A DaemonSet ensures exactly one Pod runs on each node and can mount host directories to tail container log files.

* **Typical Flow**:

    1. Kubernetes writes each container’s `stdout`/`stderr` to a host path such as:

       ```
       /var/log/pods/<pod-uid>/<container-name>/0.log
       /var/log/containers/<pod_name>_<namespace>_<container_name>-<container_id>.log
       ```
    2. A DaemonSet Pod (Fluentd or Fluent Bit) mounts `/var/log` and `/var/lib/docker/containers` on the host:

       ```yaml
       apiVersion: apps/v1
       kind: DaemonSet
       metadata:
         name: fluentd
         namespace: logging
       spec:
         selector:
           matchLabels:
             k8s-app: fluentd-logging
         template:
           metadata:
             labels:
               k8s-app: fluentd-logging
           spec:
             tolerations:
               - operator: "Exists"      # Ensures it can run on all nodes
             containers:
               - name: fluentd
                 image: fluent/fluentd-kubernetes-daemonset:v1.14.0
                 env:
                   - name: FLUENT_ELASTICSEARCH_HOST
                     value: "elasticsearch.logging.svc.cluster.local"
                 volumeMounts:
                   - name: varlog
                     mountPath: /var/log
                   - name: varlibdockercontainers
                     mountPath: /var/lib/docker/containers
                     readOnly: true
             volumes:
               - name: varlog
                 hostPath:
                   path: /var/log
               - name: varlibdockercontainers
                 hostPath:
                   path: /var/lib/docker/containers
       ```
    3. Fluentd (or Fluent Bit) tails each log file, applies parsing (e.g., JSON vs. text), and forwards events to a backend (Elasticsearch, Graylog, etc.).
* **Advantages**:

    * **Cluster-Wide Coverage**: One Pod per node automatically picks up every container’s logs.
    * **Simplicity**: No need to modify individual application manifests.
    * **Resource Efficiency**: Running one logging agent per node (rather than per Pod) reduces overhead.
* **Caveats**:

    * You need to ensure the DaemonSet tolerates all node taints (e.g., `node.kubernetes.io/unschedulable`) so it continues running even when nodes are cordoned.

#### 5.2.2 Sidecar-Based Log Forwarder (Less Common)

A sidecar log shipper runs alongside each application container in the same Pod. Application writes logs to a shared volume; the sidecar tails the logs and sends them off.

* **Pod Spec Example**:

  ```yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: app-with-logging-sidecar
  spec:
    containers:
      - name: app
        image: myapp:latest
        volumeMounts:
          - name: log-volume
            mountPath: /var/log/app
      - name: fluent-bit
        image: fluent/fluent-bit:latest
        args:
          - -i
          - tail
          - -p
          - path=/var/log/app/*.log
          - -o
          - es
        volumeMounts:
          - name: log-volume
            mountPath: /var/log/app
    volumes:
      - name: log-volume
        emptyDir: {}
  ```
* **Pros**:

    * **Encapsulation**: Logs are written by the application to a known location; the sidecar handles parsing and shipping.
    * **Per-Pod Context**: The sidecar can enrich logs with Pod-specific metadata easily if you mount the Downward API.
* **Cons**:

    * **Overhead**: Each Pod has two containers (application + log shipper), doubling resource footprints.
    * **Maintenance**: Every Pod spec must be modified to include the sidecar; for large clusters or many workloads, this can be cumbersome.

### 5.3 The ELK Stack (Elasticsearch, Logstash/Beats, Kibana)

The classic “ELK Stack” consists of:

1. **Elasticsearch**: Distributed search and analytics engine for storing, indexing, and querying logs.
2. **Logstash** (or **Beats**):

    * **Logstash**: General-purpose data processing pipeline (ingest, filter, transform, output).
    * **Beats** (e.g., Filebeat): Lightweight agents installed on each node to ship logs to Elasticsearch or Logstash.
    * In Kubernetes, many teams prefer **Fluentd/Fluent Bit** instead of Logstash because they are lighter and integrate well as a DaemonSet.
3. **Kibana**: User interface for exploring indices stored in Elasticsearch—build dashboards, run full-text searches, create visualizations.

#### 5.3.1 Deploying Elasticsearch in Kubernetes

* Run Elasticsearch as a **StatefulSet** (to ensure stable network IDs and persistent storage):

  ```yaml
  apiVersion: apps/v1
  kind: StatefulSet
  metadata:
    name: elasticsearch
    namespace: logging
  spec:
    serviceName: "elasticsearch"
    replicas: 3
    selector:
      matchLabels:
        app: elasticsearch
    template:
      metadata:
        labels:
          app: elasticsearch
      spec:
        containers:
          - name: elasticsearch
            image: docker.elastic.co/elasticsearch/elasticsearch:7.17.0
            resources:
              limits:
                memory: "2Gi"
                cpu: "1000m"
              requests:
                memory: "1Gi"
                cpu: "500m"
            env:
              - name: cluster.name
                value: "k8s-logs"
              - name: node.name
                valueFrom:
                  fieldRef:
                    fieldPath: metadata.name
              - name: discovery.seed_hosts
                value: "elasticsearch-0.elasticsearch,elasticsearch-1.elasticsearch,elasticsearch-2.elasticsearch"
              - name: cluster.initial_master_nodes
                value: "elasticsearch-0,elasticsearch-1,elasticsearch-2"
            ports:
              - containerPort: 9200
                name: rest
              - containerPort: 9300
                name: inter-node
            volumeMounts:
              - name: storage
                mountPath: /usr/share/elasticsearch/data
    volumeClaimTemplates:
      - metadata:
          name: storage
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi
  ```
* **Key points**:

    * **StatefulSet**: Ensures each Elasticsearch Pod keeps the same name and persistent volume across restarts.
    * **PersistentVolumeClaims**: Stores indices on durable disks (ensuring data persists across Pod restarts).
    * **Cluster Formation**: Environment variables instruct each node how to discover peers.

#### 5.3.2 Deploying Kibana

* Run Kibana as a simple Deployment that points to the Elasticsearch service:

  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: kibana
    namespace: logging
  spec:
    replicas: 1
    selector:
      matchLabels:
        app: kibana
    template:
      metadata:
        labels:
          app: kibana
      spec:
        containers:
          - name: kibana
            image: docker.elastic.co/kibana/kibana:7.17.0
            env:
              - name: ELASTICSEARCH_URL
                value: http://elasticsearch.logging.svc.cluster.local:9200
            ports:
              - containerPort: 5601
  ```

#### 5.3.3 Fluentd Configuration to Send Logs to Elasticsearch

* A typical Fluentd `output` section to write logs into Elasticsearch:

  ```xml
  <match **>
    @type elasticsearch
    @id out_elasticsearch
    host elasticsearch.logging.svc.cluster.local
    port 9200
    logstash_format true
    logstash_prefix kubernetes-logs
    include_tag_key true
    type_name _doc
    flush_interval 5s
  </match>
  ```
* **Behavior**:

    * Fluentd reads every log entry from `/var/log/containers`.
    * It tags each event and writes it into an index named:

      ```
      kubernetes-logs-YYYY.MM.DD
      ```
    * Kibana is configured to look at the index pattern `kubernetes-logs-*` so you can view logs by date, namespace, Pod, etc.

#### 5.3.4 Pros and Cons of ELK

* **Pros**:

    * Mature, widely adopted, large community.
    * Kibana offers powerful dashboards and search features.
    * Beats (Filebeat, Metricbeat) can reduce resource usage on nodes.
* **Cons**:

    * Elasticsearch is memory- and CPU-intensive; requires careful capacity planning and management of shards/replicas.
    * Logstash (if used) can also be resource-heavy; many Kubernetes deployments prefer Fluentd/Fluent Bit instead.
    * Some features (security, advanced alerting) may require a commercial license.

---

## Module 6: Graylog for Centralized Logging

Graylog is a centralized log management platform that emphasizes simplicity of search, pipelines for processing, and built-in alerting. It uses Elasticsearch (or OpenSearch) for storage but adds its own processing layer and UI.

### 6.1 Core Components of Graylog

1. **Graylog Server**:

    * Receives log messages (via GELF, Beats, or Syslog).
    * Parses and enriches messages via pipeline rules.
    * Stores events in Elasticsearch (or OpenSearch).
    * Provides the web UI for searching, dashboards, and alert definitions.
2. **MongoDB**:

    * Stores Graylog’s internal configuration and metadata (e.g., user accounts, stream definitions).
3. **Elasticsearch (or OpenSearch)**:

    * Persists all log events that Graylog ingests—used for indexing and search.
4. **Graylog Sidecar (Optional)**:

    * A lightweight agent deployed on each node (DaemonSet) that can manage and configure local log shippers such as Filebeat or Fluent Bit.
    * Sidecar fetches configuration from Graylog’s API, so you can centrally manage which logs are collected and how they are parsed.

### 6.2 Deploying Graylog in Kubernetes

#### 6.2.1 Elasticsearch & MongoDB (StatefulSets)

* Deploy both as StatefulSets with persistent storage, similar to how you would for an ELK setup.

#### 6.2.2 Graylog Server Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: graylog
  namespace: logging
spec:
  replicas: 1
  selector:
    matchLabels:
      app: graylog
  template:
    metadata:
      labels:
        app: graylog
    spec:
      containers:
        - name: graylog
          image: graylog/graylog:4.3
          env:
            - name: GRAYLOG_PASSWORD_SECRET
              valueFrom:
                secretKeyRef:
                  name: graylog-secret
                  key: password_secret
            - name: GRAYLOG_ROOT_PASSWORD_SHA2
              valueFrom:
                secretKeyRef:
                  name: graylog-secret
                  key: root_password_sha2
            - name: GRAYLOG_HTTP_EXTERNAL_URI
              value: "http://graylog.logging.svc.cluster.local:9000/"
          ports:
            - containerPort: 9000    # Web UI
            - containerPort: 12201   # GELF TCP input
          volumeMounts:
            - name: graylog-data
              mountPath: /usr/share/graylog/data
      volumes:
        - name: graylog-data
          emptyDir: {}
```

* **Secrets**:

    * `GRAYLOG_PASSWORD_SECRET`: A random string used to encrypt sessions and tokens.
    * `GRAYLOG_ROOT_PASSWORD_SHA2`: SHA-256 hash of the admin password.
* **Ports**:

    * `9000`: Web UI (search, dashboards, streams).
    * `12201`: GELF input port—agents can send JSON-formatted logs over TCP/UDP.

#### 6.2.3 Optional Graylog Sidecar DaemonSet

* Deploy the Sidecar so that each node can run Filebeat or Fluent Bit with configuration pushed from Graylog:

  ```yaml
  apiVersion: apps/v1
  kind: DaemonSet
  metadata:
    name: graylog-sidecar
    namespace: logging
  spec:
    selector:
      matchLabels:
        app: graylog-sidecar
    template:
      metadata:
        labels:
          app: graylog-sidecar
      spec:
        tolerations:
          - operator: "Exists"
        containers:
          - name: sidecar
            image: graylog/sidecar:1.3
            env:
              - name: GRAYLOG_URL
                value: "http://graylog.logging.svc.cluster.local:9000/api/"
              - name: GRAYLOG_API_TOKEN
                valueFrom:
                  secretKeyRef:
                    name: graylog-secret
                    key: api_token
            volumeMounts:
              - name: varlog
                mountPath: /var/log
              - name: varlibdockercontainers
                mountPath: /var/lib/docker/containers
                readOnly: true
        volumes:
          - name: varlog
            hostPath:
              path: /var/log
          - name: varlibdockercontainers
            hostPath:
              path: /var/lib/docker/containers
  ```

* The Sidecar pulls configuration (e.g., Filebeat prospector definitions) from Graylog, tails local logs, and ships them to Graylog’s GELF input.

### 6.3 Ingesting and Processing Logs

1. **Inputs**:

    * Graylog can open TCP/UDP listening ports for various formats:

        * **GELF** (Graylog Extended Log Format) is the preferred structured logging format.
        * **Beats** (if Filebeat is used, it can send to a Beats input).
        * **Syslog** (for syslog-style forwarding).
2. **Streams**:

    * Logical flows of messages based on rules (e.g., “nginx access logs,” “application errors”).
    * A stream can route events to different indices, and you can attach alerts to streams.
3. **Pipelines**:

    * Write small DSL rules to parse, enrich, mutate, or drop messages before they are indexed.
    * For example, extract certain JSON fields, mask sensitive data, or tag severity levels.
4. **Dashboards & Searches**:

    * In the Graylog UI, you can run ad-hoc searches, save queries, build dashboards, and visualize event frequency, histogram charts, and message tables.
5. **Alerts**:

    * Define conditions on streams (e.g., “if > 100 ERROR events in 5 minutes, trigger alert”).
    * Notifications can be sent via email, Slack, or custom webhooks.

### 6.4 Pros and Cons of Graylog

* **Pros**:

    * Intuitive UI with built-in search, dashboarding, and alerting.
    * Flexible pipelines for processing messages.
    * Sidecar approach centralizes configuration of log shippers.
* **Cons**:

    * Requires managing additional components (MongoDB) beyond Elasticsearch and Fluentd.
    * Slightly steeper learning curve around pipeline rules compared to Kibana’s JSON approach.
    * Still depends on Elasticsearch (or OpenSearch) for storage, so underlying storage scaling and maintenance remain.

---

## Module 7: Centralized Monitoring of Cluster Resources

While logs tell you *what* happened and *where*, metrics tell you *how much* and *how well*—CPU, memory, disk, network, application-specific counters. A fully observant production Kubernetes cluster combines log aggregation with metrics collection and alerting. In this module, we cover:

1. **Prometheus Architecture and Exporters**.
2. **AlertManager Configuration**.
3. **Grafana Dashboards**.
4. **Reference Implementation: kube-prometheus Stack**.

### 7.1 Prometheus: Pull-Based Metrics Collection

Prometheus is the de facto standard for Kubernetes monitoring. It uses a pull model (scrapes targets over HTTP) and stores time-series data locally.

#### 7.1.1 Core Components

* **Prometheus Server**:

    * **Scraping**: Periodically polls endpoints (e.g., `/metrics`) exposed by applications or exporters.
    * **Storage**: On-disk time-series database; retention is configurable.
    * **PromQL**: Powerful query language for aggregations, functions, and alert rules.
* **Exporters**:

    * **node\_exporter**: Runs as a DaemonSet; exposes host metrics (CPU, memory, disk, network) at `:9100/metrics`.
    * **kube-state-metrics**: Runs as a Deployment; queries the Kubernetes API and exports metrics about Deployments, DaemonSets, ReplicaSets, Pod statuses, etc., at `:8080/metrics`.
    * **cAdvisor**: Built into each Kubelet; exposes per-container CPU/memory/disk usage.
    * **Application-Specific Exporters**: Many apps (Redis, MySQL, NGINX, etc.) have their own Prometheus exporters that expose internal metrics.
* **Service Discovery**:

    * Prometheus can discover targets from the Kubernetes API (e.g., roles: node, pod, service).
    * Scrape configurations can include relabeling to keep or drop certain endpoints.

#### 7.1.2 Sample `prometheus.yml` Snippet (Kubernetes SD)

```yaml
scrape_configs:
  - job_name: 'kubernetes-node'
    kubernetes_sd_configs:
      - role: node
    relabel_configs:
      - source_labels: [__meta_kubernetes_node_label_role]
        regex: "worker"
        action: keep
      - source_labels: [__meta_kubernetes_node_name]
        target_label: instance

  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        regex: "true"
        action: keep
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        regex: "(.+)"
        target_label: __metrics_path__
      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        regex: "([^:]+)(?::\\d+)?;([0-9]+)"
        replacement: "$1:$2"
        target_label: __address__
```

* **Explanation**:

    * **`role: node`**: Discovers all nodes. The relabel rule keeps only nodes labeled `role=worker`.
    * **`role: pod`**: Discovers all Pods. Only Pods annotated with `prometheus.io/scrape=true` are scraped. The annotation `prometheus.io/port` and `prometheus.io/path` tell Prometheus how to build the URL.

#### 7.1.3 Pod Annotations for Application Scraping

To have Prometheus scrape a Pod’s `/metrics` endpoint, annotate its Pod template:

```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/metrics"
```

At scale, you typically:

* Label or annotate application Deployments to expose metrics.
* Use a `ServiceMonitor` CRD (with Prometheus Operator) to automatically generate scraping rules.

### 7.2 AlertManager: Defining and Routing Alerts

Once Prometheus detects a condition (e.g., node CPU > 90% for 5 minutes), it emits an alert. **AlertManager** receives alerts, deduplicates, groups, and delivers notifications via email, Slack, PagerDuty, etc.

#### 7.2.1 Defining Alert Rules

In a separate file (e.g., `rules.yml`), specify alerting rules:

```yaml
groups:
  - name: node-alerts
    rules:
      - alert: NodeMemoryHigh
        expr: node_memory_Active_bytes / node_memory_MemTotal_bytes * 100 > 90
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Node memory usage > 90%"
          description: "Node {{ $labels.instance }} memory usage is above 90% for more than 5 minutes."

  - name: pod-alerts
    rules:
      - alert: PodCrashLooping
        expr: increase(kube_pod_container_status_restarts_total[10m]) > 5
        for: 0m
        labels:
          severity: critical
        annotations:
          summary: "Pod {{ $labels.pod }} is crash looping"
```

* **Fields**:

    * **`alert`**: Name of the alert rule.
    * **`expr`**: PromQL expression that evaluates to true or false.
    * **`for`**: Duration for which the expression must remain true before firing.
    * **`labels`**: Key/value pairs used for routing or grouping in AlertManager.
    * **`annotations`**: Human-readable summary and description, often templated with variables like `{{ $labels.instance }}`.

#### 7.2.2 Configuring AlertManager

Sample `alertmanager.yml`:

```yaml
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname', 'priority']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  receiver: 'team-email'
  routes:
    - match:
        severity: critical
      receiver: 'pagerduty'

receivers:
  - name: 'team-email'
    email_configs:
      - to: 'devops@example.com'
        from: 'alertmanager@example.com'
        smarthost: 'smtp.example.com:587'

  - name: 'pagerduty'
    pagerduty_configs:
      - service_key: '<YOUR_SERVICE_KEY>'
        severity: 'critical'

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'instance']
```

* **How it works**:

    * **Root route**: By default, send all alerts to `team-email`.
    * **Sub-route**: If an alert’s `severity` label equals `critical`, send it instead to `pagerduty`.
    * **Inhibition**: If a critical alert is firing for a given `alertname` and `instance`, do not send a redundant warning alert.

#### 7.2.3 Hooking Prometheus to AlertManager

In `prometheus.yml`:

```yaml
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - 'alertmanager.logging.svc.cluster.local:9093'
```

* Prometheus pushes fired alerts to the AlertManager endpoint at port 9093.

### 7.3 Grafana: Visualization and Dashboards

Grafana provides a UI for building dashboards on top of Prometheus data. In addition, newer Grafana versions allow defining alert rules directly in dashboards.

#### 7.3.1 Deploying Grafana

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
        - name: grafana
          image: grafana/grafana:8.5
          env:
            - name: GF_SECURITY_ADMIN_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: grafana-admin-secret
                  key: admin-password
          ports:
            - containerPort: 3000
```

* **Access**: Expose via Service (`NodePort`/`LoadBalancer`/Ingress) so you can reach Grafana at `http://grafana.monitoring.svc.cluster.local:3000`.

#### 7.3.2 Configuring Prometheus as a Data Source

* In Grafana UI (or via a ConfigMap/CRD if using Grafana Operator), add a new data source:

    * **Type**: Prometheus
    * **URL**: `http://prometheus.monitoring.svc.cluster.local:9090`
    * **Access**: “Server” (Grafana queries Prometheus from within the cluster)

#### 7.3.3 Key Dashboards

1. **Cluster Overview**:

    * Node CPU usage (%), memory usage (%), and total cluster resources.
    * Pod counts: Running vs. pending vs. failed.
2. **Node Exporter Dashboards**:

    * Disk I/O, network traffic, CPU per core, file system utilization.
3. **kube-state-metrics Dashboards**:

    * Deployment availability, ReplicaSet counts, StatefulSet status, DaemonSet health.
4. **Application-Specific Dashboards**:

    * Custom metrics exposed by your applications (e.g., request latency, error rates).

#### 7.3.4 Grafana Alerting

* In Grafana v8+, you can define alert rules directly in dashboard panels (e.g., “If average CPU > 85% for 5m, fire alert”) and send notifications via Slack, PagerDuty, or email.
* However, many teams still prefer to treat Prometheus → AlertManager as the “source of truth” for alerting, using Grafana’s Notification Channels to mirror or augment alerts.

### 7.4 kube-prometheus Stack: A Ready-Made, Production-Grade Setup

Instead of wiring Prometheus, AlertManager, Grafana, and exporters by hand, you can use the **kube-prometheus-stack** from the Prometheus Community. It includes:

1. **Prometheus Operator**: A Kubernetes Operator that manages Prometheus instances, AlertManager, and related RBAC/ConfigMaps.
2. **AlertManager Operator**: Manages AlertManager configurations and lifecycle.
3. **Grafana Operator**: Manages Grafana instances, data sources, dashboards, and users.
4. **Preconfigured Exporters**:

    * **node\_exporter** as a DaemonSet.
    * **kube-state-metrics** Deployment.
    * **Prometheus** StatefulSet(s) with sensible defaults.
    * **AlertManager** StatefulSet(s).
5. **ServiceMonitor** CRDs: Let you declaratively configure which Kubernetes Services (or Pods) Prometheus should scrape, rather than editing `prometheus.yml` manually.

#### 7.4.1 Installation via Helm

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace
```

* **What You Get**:

    * `Prometheus` custom resource (`Prometheus` CRD) that triggers a `StatefulSet` with high availability.
    * `AlertManager` custom resource for managing alert rules.
    * `Grafana` custom resource for provisioning Grafana, its data sources, and default dashboards.
    * Pre-installed dashboards, alerts, and recording rules for common Kubernetes and cluster components.

#### 7.4.2 Key Benefits

* **CRD-Driven Configuration**: Define `ServiceMonitor` objects to select which Pods or Services Prometheus scrapes (e.g., “scrape all Pods in namespace `myns` with label `prometheus.io/scrape=true`”).
* **Secure by Default**: Operators generate necessary RBAC (ClusterRoles, RoleBindings) to allow Prometheus to discover and scrape resources.
* **Out-of-the-Box Dashboards & Alerts**: Includes recommended dashboards for cluster health, plus alert rules for DiskPressure, NodeNotReady, PodCrashLooping, etc.
* **TLS Integration**: Optionally integrate with cert-manager to auto-provision certificates for Prometheus → AlertManager → Grafana internal communication.

---

## Module 8: Putting It All Together—Reference Architecture

Below is a textual description of a combined logging + monitoring architecture in Kubernetes. Imagine how the pieces fit:

```
      +-----------------------------------------+
      |       Kubernetes Control Plane          |
      |  (API Server, Scheduler, ControllerMgr) |
      +-----------------------------------------+
                ▲                       ▲
         Pod/Node Status            Node States
                |                       |
  +---------------------------+  +---------------------------+
  |     Worker Node 1         |  |     Worker Node 2         |
  |---------------------------|  |---------------------------|
  |  +---------------------+  |  |  +---------------------+  |
  |  |  App Pod (app-A)    |  |  |  |  App Pod (app-B)    |  |
  |  |  (/var/log/containers) |  |  |  (/var/log/containers) |  |
  |  +---------------------+  |  |  +---------------------+  |
  |  |  node-exporter      |<----+  |  node-exporter      |  |
  |  |  (DaemonSet, /metrics) |  |  |  (/metrics)          |  |
  |  +---------------------+  |  |  +---------------------+  |
  |  |  Fluentd (DaemonSet) |  |  |  Fluentd (DaemonSet) |  |
  |  |  (tails /var/log      |  |  |  (tails /var/log      |  |
  |  |   /containers/*.log)  |  |  |   /containers/*.log)  |  |
  |  +---------------------+  |  |  +---------------------+  |
  +---------------------------+  +---------------------------+
                ▲                      ▲
                |                      |
          Sends metrics           Sends logs
         (Prometheus scrape)   (to Elasticsearch or Graylog)
                |                      |
      +-----------------------------------------+
      |           Monitoring Stack              |
      |                                         |
      |  +------------+   +------------------+  |
      |  | Prometheus |   |   AlertManager   |  |
      |  +------------+   +------------------+  |
      |         ▲                 ▲              |
      |         |  Fires alerts   | Notifies     |
      |         |                 | team/email  |
      |  +-----------------------------------+   |
      |  |            Grafana                |   |
      |  +-----------------------------------+   |
      |         ▲                                   |
      |         | Visualizes Metrics Dashboards      |
      +---------------------------------------------+
                ▲
                |
        +-----------------------------------------+
        |           Log Aggregation Stack        |
        |                                         |
        |  +---------------+   +---------------+  |
        |  | Elasticsearch |   |   Graylog     |  |
        |  +---------------+   +---------------+  |
        |        ▲                   ▲            |
        |        |                   |            |
        |  +-------------------------+            |
        |  |     Fluentd / Fluent Bit             |
        |  |      (DaemonSet on each node)        |
        |  +--------------------------------------+ 
```

* **Worker Nodes**:

    * **Application Pods** write `stdout`/`stderr` to files in `/var/log/containers`.
    * A **DaemonSet** (Fluentd or Fluent Bit) tails those files and forwards logs to a centralized log store (Elasticsearch or Graylog).
    * A **node\_exporter** DaemonSet exports host-level metrics to Prometheus.
    * **cAdvisor** (built into kubelet) provides per-container CPU/memory metrics, scraped by Prometheus automatically (via kubelet metrics endpoint).
* **Monitoring Stack**:

    * **Prometheus** scrapes:

        * `node_exporter` on each node.
        * `kube-state-metrics`.
        * Any Pods annotated for scraping (application metrics).
    * **AlertManager** receives alerts from Prometheus and notifies on-call teams or chat channels.
    * **Grafana** connects to Prometheus to display dashboards (cluster overview, node metrics, Pod resource usage).
* **Logging Stack**:

    * **Fluentd / Fluent Bit** (DaemonSet) ships logs to:

        * **Elasticsearch** (indices per day, searchable via Kibana).
        * Or to **Graylog**, which itself writes to Elasticsearch (and MongoDB for metadata) and provides its own UI for search, pipelines, and alerts.
* **CRDs & Operators**:

    * In a production environment, one may deploy the **kube-prometheus-stack**:

        * A Prometheus Operator to manage the entire Prometheus + AlertManager + Grafana lifecycle via Kubernetes CRDs.
        * A Fluentd or Filebeat operator for log collection CRDs.
        * An Elasticsearch operator (e.g., Elastic Cloud on Kubernetes) for managing Elasticsearch clusters, shards, and backups.
    * For advanced workloads (e.g., databases, custom applications), you might write a **CRD** and corresponding **Operator** (controller) to manage the full lifecycle of those resources in Kubernetes (e.g., backup/restore, schema migrations, scaling).

---

## Module 9: Summary of Key Concepts

1. **Node Maintenance**

    * **Cordoning** prevents new Pods from scheduling onto a node.
    * **Draining** evicts existing Pods (respecting DaemonSets and PDBs).
    * **Taint/Toleration** provides a flexible way to evict or keep certain Pods during maintenance.
    * **Automation** (node pools, rolling upgrades, or custom operators) helps ensure you never take too many nodes down at once.

2. **Application Update Strategies**

    * **Recreate**: Tear down all old Pods before launching new ones—acceptable downtime, simple.
    * **RollingUpdate**: Gradual replacement of Pods, controlled by `maxSurge` and `maxUnavailable`—near zero-downtime.
    * **Blue/Green**: Two parallel environments; switch traffic via Service selector.
    * **Canary**: Send a small percentage of traffic to new version (via Pod counts or service mesh/Ingress annotations).
    * **A/B Testing**: Route based on user segment (cookie or header).
    * **Shadowing**: Mirror production traffic to a new version for real-world load testing without impacting users.

3. **Custom Resource Definitions (CRDs)**

    * **Extensibility**: Define new API objects (Kinds) that Kubernetes treats like built-in resources.
    * **Controller/Operator**: Your code watches CRs and reconciles real-world resources to the desired state expressed in `.spec`.
    * **Versioning**: Support multiple API versions, conversions, and deprecations as your CRD evolves.

4. **Downward API**

    * **FieldRef**: Expose Pod metadata (name, namespace, labels, annotations) into environment variables or files.
    * **ResourceFieldRef**: Expose container resource requests (CPU, memory) into the container’s environment or files.
    * **Use Cases**: Logging, metrics tagging, self-registration, resource-aware initialization, feature toggles via labels.

5. **Log Collection**

    * **DaemonSet Pattern**: Run a single log shipper (Fluentd, Fluent Bit, or Filebeat) on each node to collect and forward container logs.
    * **Sidecar Pattern**: Embed a log shipper in each Pod—less common, more overhead.
    * **ELK Stack**: Elasticsearch (StatefulSet), Logstash/Beats or Fluentd (DaemonSet), and Kibana for search and visualization.
    * **Graylog**: Graylog server + MongoDB + Elasticsearch + Sidecar for log aggregation, processing pipelines, and built-in alerting.

6. **Centralized Monitoring**

    * **Prometheus**: Pull-based metrics collection (scrape exporters and annotated Pods). Stores time-series data; use PromQL.
    * **Exporters**: node\_exporter (host metrics), kube-state-metrics (cluster state), cAdvisor (container stats), application exporters.
    * **AlertManager**: Ingests alerts from Prometheus, groups and routes them to various receivers (email, Slack, PagerDuty).
    * **Grafana**: Visualization layer—dashboards, charts, and optional Grafana alerting.
    * **kube-prometheus Stack**: Prometheus Operator, AlertManager Operator, Grafana Operator, and predefined ServiceMonitors/Alerts/Dashboards for faster setup.

---

## Additional Resources for Independent Learning

To deepen your knowledge, consider exploring the following:

1. **Kubernetes Official Documentation**

    * [Node Maintenance](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/)
    * [Deployments and Rollouts](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
    * [Custom Resource Definitions](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)
    * [Downward API](https://kubernetes.io/docs/tasks/inject-data-application/downward-api-volume-expose-pod-information/)

2. **Prometheus & Monitoring**

    * [Prometheus Documentation](https://prometheus.io/docs/introduction/overview/)
    * [kube-prometheus-stack Helm Chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
    * [Grafana Documentation](https://grafana.com/docs/)
    * [AlertManager Documentation](https://prometheus.io/docs/alerting/latest/alertmanager/)

3. **Logging Solutions**

    * [Fluentd Kubernetes DaemonSet](https://github.com/fluent/fluentd-kubernetes-daemonset)
    * [Elastic Cloud on Kubernetes (ECK)](https://github.com/elastic/cloud-on-k8s)
    * [Graylog Documentation](https://docs.graylog.org/)

4. **Operators and CRD Frameworks**

    * [Kubebuilder Book](https://book.kubebuilder.io/)
    * [Operator SDK](https://sdk.operatorframework.io/)

