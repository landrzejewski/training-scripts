### Exercise 1: Control Plane vs. Worker Node Responsibilities

**Instruction:**
Explain, in your own words, at least **three** major responsibilities of the **control plane** (as a whole) and contrast them with at least **three** responsibilities of a **worker node**. Your answer should clearly identify which tasks belong to the control plane and which belong to worker nodes, and why those distinctions matter.

**Answer:**

1. **Control Plane Responsibilities**

    * **Maintaining Desired State (etcd + Controllers):**

        * The control plane (via `etcd` and controllers in the `kube-controller-manager`) continuously tracks the desired state (Deployment, ReplicaSet, Service specs, etc.) stored in the distributed key-value store (`etcd`). Whenever a user submits or updates an object (e.g., a Deployment manifest), the controllers compare that desired state to what’s actually running and take corrective actions (e.g., create new Pods or reschedule Pods).
        * *Why it matters:* This reconciliation loop is what ensures “self-healing” and consistency across the cluster—if something drifts (e.g., a Pod crashes), the control plane notices and recreates it to match the spec.

    * **Scheduling Pods onto Nodes (`kube-scheduler`):**

        * The scheduler watches for newly created Pods that do not yet have a node assignment. It evaluates each unscheduled Pod against factors such as resource requests (CPU/memory), node taints/tolerations, affinity/anti-affinity rules, and custom policies. Once it picks a suitable node, it writes that chosen node into the Pod’s spec by talking to the API server.
        * *Why it matters:* Without the scheduler, Pods would never be placed onto worker nodes. By centralizing scheduling logic, the control plane ensures optimal resource utilization and respects constraints like “this Pod must run in zone us-east-1a” or “do not schedule on nodes with the label `disk=ssd`.”

    * **Exposing and Validating the Kubernetes API (`kube-apiserver`):**

        * The API server is the front end for the control plane. Every single operation—whether it’s a user issuing `kubectl create -f` or an internal component (controller, scheduler, kubelet) reading/updating objects—flows through the API server. It validates API schemas, authenticates requests (TLS/client certs or tokens), authorizes actions (RBAC), and then persists changes to `etcd`.
        * *Why it matters:* Because everything is centralized through the API server, there’s a consistent, authenticated, and authorized way to read or modify cluster state. This also means that both human users and automated controllers have a single, coherent interface to interact with the entire cluster.

2. **Worker Node Responsibilities**

    * **Pod Lifecycle Management (`kubelet` + Container Runtime):**

        * Each worker node runs a `kubelet` agent that “watches” the API server for PodSpecs assigned to that particular node. When it sees a new Pod, the kubelet calls the container runtime (e.g., `containerd`) via the CRI to pull the specified image, create containers, and start them. It also restarts containers if a liveness probe fails or the container crashes.
        * *Why it matters:* The kubelet is what actually turns a declarative Pod object into a running process on the node. Without the kubelet, the control plane’s desired-state instructions would never materialize into real containers.

    * **Node Health & Metrics Reporting (cAdvisor + Lease Updates):**

        * On each node, `cAdvisor` (built into the kubelet) monitors CPU, memory, disk, and network usage of every container. The kubelet packages these metrics into Node status (including conditions like `MemoryPressure` or `DiskPressure`) and updates a `Lease` object in the `coordination.k8s.io` API group every few seconds.
        * *Why it matters:* Those heartbeats and resource reports feed right back to the control plane: the Node Controller examines the Lease to detect dead nodes, and metrics may inform the Horizontal Pod Autoscaler (HPA). If a node stops renewing its Lease, the control plane marks it `NotReady` and eventually evicts its Pods.

    * **Service Networking Rules (`kube-proxy`):**

        * Each worker node runs a `kube-proxy` process that watches Service and Endpoints objects in the API server. If a Service named `my-svc` exists, `kube-proxy` will add iptables (or IPVS) rules so that traffic to the Service’s ClusterIP (and NodePort/LoadBalancer ports) gets load-balanced to one of the healthy Pod IPs.
        * *Why it matters:* From the outside, clients hit a stable virtual IP (`ClusterIP`) or NodePort, and `kube-proxy` ensures their traffic actually reaches one of the alive Pods, even if the Pod’s IP changes over time. This abstracts away Pod churn so applications can rely on a consistent Service endpoint.

> **Why Distinguish Them?**
>
> * **Control Plane** components never directly run workload containers but instead decide *what* should run and *where.* They must remain highly available (multiple API servers, etcd replicas, controllers).
> * **Worker Nodes** actually *run* the Pods and enforce the control plane’s decisions. They must be robust and report status accurately. Separating these roles ensures that if, say, a node fails, the control plane can react (reschedule), and if the control plane is temporarily degraded, worker nodes can still run their existing Pods until reconnection.

---

### Exercise 2: Describe Key Control-Plane Components

**Instruction:**
Without quoting the article verbatim, summarize the roles of the following control-plane components:

1. **etcd**
2. **kube-apiserver**
3. **kube-controller-manager** (give two examples of controllers it runs)
4. **kube-scheduler**
5. **cloud-controller-manager**

For each, write **one or two sentences** indicating its primary function and why it matters for the cluster.

**Answer:**

1. **etcd**

    * A strongly consistent, distributed key-value store that holds every Kubernetes object’s state and metadata. It is the single source of truth: if `etcd` fails or becomes inconsistent, the entire cluster’s state is effectively lost.

2. **kube-apiserver**

    * The API server exposes the Kubernetes API via REST, handling every client request (from `kubectl`, controllers, and nodes), enforcing authentication, authorization, and validation before writing changes to `etcd`. It is the gatekeeper and ensures that only well-formed, permitted requests modify the cluster.

3. **kube-controller-manager**

    * Runs a suite of controllers—each a reconciliation loop that watches for specific object types and ensures the actual state matches the declared (`spec`) state.

        * **Example 1:** *Node Controller* monitors heartbeats (Leases) from each node; if a node’s Lease expires, it marks the node `NotReady` and evicts Pods.
        * **Example 2:** *ReplicaSet Controller* checks if the number of running Pod replicas matches the desired `.spec.replicas`; if too few, it creates new Pods; if too many, it deletes extras.

4. **kube-scheduler**

    * Observes unscheduled Pods and selects the “best” node for each, considering resource capacity (CPU, memory), Pod affinities/anti-affinities, taints and tolerations, and any custom scheduling policies. Once it picks a node, it writes that assignment to the Pod’s spec in the API server.

5. **cloud-controller-manager**

    * Runs only in cloud environments and implements cloud-provider-specific control loops (e.g., provisioning a load balancer for a Service of type `LoadBalancer`, populating Route tables, or creating PersistentVolumes in the cloud). By separating this logic from the in-tree controllers, the core Kubernetes codebase stays agnostic, and cloud vendors can release updates independently.

---

### Exercise 3: Imperative vs. Declarative Object Management

**Instruction:**

1. Using **imperative** commands, create a Deployment named `redis-deploy` with image `redis:6.2`, set its replica count to **2**, and then scale it to **4** replicas. Finally, delete the Deployment.
2. Provide an equivalent **declarative** manifest (`YAML`) for the same Deployment (with 2 replicas initially). Then show the `kubectl` command to apply it and another command to change replicas to **4** by editing the YAML (remember, you can update fields in place).

**Answer:**

1. **Imperative Commands**

   ```bash
   # a) Create Deployment imperatively with 2 replicas
   kubectl create deployment redis-deploy --image=redis:6.2 --replicas=2

   # b) Scale to 4 replicas
   kubectl scale deployment redis-deploy --replicas=4

   # c) Delete the Deployment
   kubectl delete deployment redis-deploy
   ```

2. **Declarative Manifest and Commands**

   ```yaml
   # File: redis-deployment.yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: redis-deploy
   spec:
     replicas: 2
     selector:
       matchLabels:
         app: redis
     template:
       metadata:
         labels:
           app: redis
       spec:
         containers:
         - name: redis
           image: redis:6.2
           ports:
           - containerPort: 6379
   ```

    * **Apply the Manifest**

      ```bash
      kubectl apply -f redis-deployment.yaml
      ```

      This creates (or updates) the Deployment with 2 replicas.

    * **Scale to 4 Replicas by Editing the YAML**

        1. Open the file in your editor:

           ```bash
           vi redis-deployment.yaml
           ```

           Change `replicas: 2` → `replicas: 4` under `spec:`.
        2. Reapply the updated manifest:

           ```bash
           kubectl apply -f redis-deployment.yaml
           ```

      Kubernetes notices the difference and spins up 2 additional Pods to satisfy 4 total replicas.

---

### Exercise 4: Write a Deployment + Service Multi-Document YAML

**Instruction:**
Create a **single YAML file** that contains two documents separated by `---`:

1. A **Service** of type `ClusterIP` named `nginx-svc` that selects Pods with label `app: nginx` and routes port 80 → port 80.
2. A **Deployment** named `nginx-deploy` with **3** replicas of the `nginx:1.21` image, each Pod labeled `app: nginx`. The Pod template should expose container port 80.

Fill in all required fields (`apiVersion`, `kind`, `metadata`, etc.). This multi-document file should be valid when applied with `kubectl apply -f`.

**Answer:**

```yaml
# Document 1: Service
apiVersion: v1
kind: Service
metadata:
  name: nginx-svc
spec:
  type: ClusterIP
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
---
# Document 2: Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deploy
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80
```

* **Explanation of Key Sections:**

    * The **Service** (`apiVersion: v1`, `kind: Service`) listens on port 80 and forwards to Pods matching `app: nginx`.
    * The **Deployment** (`apiVersion: apps/v1`, `kind: Deployment`) ensures 3 Pods run with the label `app: nginx`, each using `nginx:1.21`. Because they share the same label, the Service above automatically routes traffic to these 3 Pods.

---

### Exercise 5: How the Scheduler Picks a Node

**Instruction:**
Briefly describe the two main phases of scheduling that the `kube-scheduler` performs for each unscheduled Pod. Then, imagine you have two nodes in a cluster:

* **node-A**: 8 GiB RAM free, 4 CPU cores free, no taints.
* **node-B**: 2 GiB RAM free, 2 CPU cores free, and is tainted with `key=dedicated:NoSchedule`.

A Pod has `requests: cpu=1`, `memory=500Mi`, and no tolerations.
Explain which node the scheduler will choose and why.

**Answer:**

1. **Two Main Scheduling Phases**

    * **Filtering/Predicates (Feasibility):** The scheduler first filters out nodes that cannot run the Pod, based on resource requests (CPU/memory), node taints/tolerations, `nodeSelector` or `nodeAffinity`, and other “hard” constraints. Only nodes that pass all these checks remain in the candidate set.
    * **Scoring/Ranking:** Among the feasible nodes, the scheduler scores each node according to policies like resource utilization (Prefer nodes with most free resources), Pod affinity/anti-affinity weighting, and custom presets. The node with the highest aggregate score is chosen for binding.

2. **Which Node is Selected?**

    * **Resource Feasibility Check:**

        * `node-A` has enough free memory (8 GiB > 500 Mi) and CPU (4 > 1) → passes.
        * `node-B` has 2 GiB RAM and 2 CPU cores, so resource-wise it could run the Pod (2 GiB > 500 Mi, 2 cores > 1).
    * **Taints/Tolerations Check:**

        * `node-B` is tainted `dedicated=NoSchedule`. Our Pod has **no** toleration for `dedicated`. Therefore, it is *automatically filtered out* and cannot be scheduled onto `node-B`.
    * **Result:** Only `node-A` remains feasible. The scheduler binds the Pod to `node-A`. If `node-A` were full or unschedulable, the Pod would stay pending because `node-B` is off-limits without a toleration.

---

### Exercise 6: Container Runtime Interface (CRI) & Runtimes

**Instruction:**

1. Describe in **two sentences** the purpose of the **Container Runtime Interface (CRI)**.
2. Explain why Kubernetes deprecated “dockershim” and now relies on CRI-compliant runtimes like `containerd` or `CRI-O`.
3. List **two** things that a CRI-compliant runtime (e.g., `containerd`) is responsible for when the kubelet tells it to run a new Pod.

**Answer:**

1. **CRI Purpose (2 sentences):**
   The CRI is a gRPC-based interface that standardizes how Kubernetes’ kubelet interacts with container runtimes (e.g., pulling images, creating containers, starting/stopping containers). By abstracting runtime functionality behind CRI, Kubernetes can support multiple runtimes interchangeably without in-tree dependencies on Docker’s specific API.

2. **Why Deprecate “dockershim” and Use CRI-Compliant Runtimes:**

    * The `dockershim` was a legacy adapter that translated CRI calls into Docker engine calls. Maintaining this shim added complexity and slowed Kubernetes releases whenever Docker internals changed.
    * By switching to pure CRI-compliant runtimes (like `containerd` or CRI-O), Kubernetes avoids extra layers of indirection, reduces maintenance overhead, and improves startup/performance because containerd can talk to kubelet directly.

3. **Responsibilities of a CRI-Compliant Runtime**

    * **Image Management:** Pull container images (e.g., `docker.io/library/nginx:1.21`), unpack them into appropriate layers, and manage local image caches.
    * **Container Lifecycle Management:** Create container sandboxes (namespace, cgroups), start/stop/restart containers, and report container status (exit code, running vs. terminated).

   *(Additional answers that also count: managing snapshots/overlayFS mounts; providing namespaces/isolation; reporting logs and stats back to kubelet.)*

---

### Exercise 7: kubelet, cAdvisor, and Health Probes

**Instruction:**

1. List **three** tasks the `kubelet` on a worker node performs for each Pod it is responsible for.
2. Explain how a **liveness probe** defined in a Pod spec helps kubelet maintain application availability.
3. Describe briefly how `cAdvisor` fits into the kubelet’s node-level monitoring.

**Answer:**

1. **Three kubelet Tasks for Each Pod**

    * **Pod Creation & Container Management:** Calls the container runtime (via CRI) to pull images, create containers, and start them with the exact command and environment variables defined in the Pod spec.
    * **Health Checking & Restarts:** Periodically runs liveness and readiness probes (e.g., HTTP `GET /healthz` or TCP socket check). If a container fails a liveness probe, the kubelet kills and restarts it according to the Pod’s restart policy.
    * **Volume Management:** Mounts volumes (PVCs, ConfigMaps, Secrets) into Pod containers at their specified mount paths, ensuring data is available inside the container’s filesystem.

2. **How a Liveness Probe Maintains Availability**

    * A **liveness probe** is a command or HTTP/TCP check that the kubelet runs at defined intervals inside the container. If the probe fails repeatedly (per the `failureThreshold` and `timeoutSeconds`), the kubelet recognizes that the container is “unhealthy” and restarts it. This automatic restart helps recover from application hangs or deadlocks without manual intervention, minimizing downtime.

3. **Role of cAdvisor in kubelet Monitoring**

    * `cAdvisor` (Container Advisor) runs embedded within the kubelet to gather real-time resource metrics (CPU, memory, filesystem, network) for every container on the node. The kubelet then uses those metrics to report Node status (e.g., memory pressure, CPU usage) back to the API server, and these metrics can also feed cluster-level monitoring systems (Prometheus) to inform auto-scaling decisions.

---

### Exercise 8: kube-proxy Service Implementation

**Instruction:**

1. In **one paragraph**, explain how `kube-proxy` implements a Kubernetes Service of type **ClusterIP** using either `iptables` mode or `IPVS` mode. Include how traffic is forwarded from the Service’s ClusterIP to backend Pod IPs.
2. What happens to `kube-proxy`’s rules when a new Pod enters or leaves a Service’s Endpoint list?

**Answer:**

1. **ClusterIP via iptables or IPVS (Paragraph):**

    * When you create a Service of type ClusterIP (e.g., `apiVersion: v1, kind: Service` with `spec.clusterIP: 10.96.0.1`), `kube-proxy` on each node watches the API server for Service and Endpoints updates. In **iptables mode**, `kube-proxy` inserts rules into the node’s netfilter (iptables) chains such that any packet destined for `10.96.0.1:80` is DNAT’ed (destination NAT) to one of the backend Pod IPs (e.g., `10.244.1.5:80`) chosen at random (round-robin). Each time the Endpoints object changes, `kube-proxy` rewrites those iptables rules. In **IPVS mode**, `kube-proxy` programs a virtual server in the Linux IPVS table for `10.96.0.1:80`, again load-balancing to the set of backend Pod IPs with a chosen scheduling algorithm (e.g., round-robin or least-connections). Either way, Service clients use the stable ClusterIP, and `kube-proxy` transparently forwards their traffic to one of the live Pod endpoints.

2. **What Happens When Endpoints Change:**

    * Whenever a new Pod with label `app: nginx` (for instance) is created or terminated, the Endpoints object for that Service is updated. `kube-proxy` sees this change and immediately updates its iptables (or IPVS) rules to add or remove that Pod’s IP\:port from the pool. This ensures traffic no longer goes to terminated Pods and that new Pods start receiving traffic as soon as they become “Ready.”

---

### Exercise 9: Controller Reconciliation and Node Failure

**Instruction:**

1. Describe the sequence of events that occurs from the moment a **worker node** unexpectedly goes offline (e.g., hardware failure) until its Pods are rescheduled onto healthy nodes. Mention at least the **Lease object**, which controller notices, and how the Pods get evicted/rescheduled.
2. What part of the Control Plane acts to actually create replacement Pods, and how does it know how many replicas to make?

**Answer:**

1. **Sequence on Node Failure:**

    * **Lease Expiry:** Each kubelet periodically renews a Lease object in the `coordination.k8s.io` API group (e.g., `leases/worker-node-1`). When the node crashes, it stops updating its Lease.
    * **Node Controller Detection:** The **Node Controller** (in `kube-controller-manager`) notices that the Lease has not been refreshed within the configured threshold (default is typically 40 seconds), so it marks the associated Node object’s `status.conditions` to `NotReady`.
    * **Pod Eviction:** Once a Node is marked `NotReady` for a set time (e.g., `podEvictionTimeoutSeconds`, default 5 minutes), the Node Controller begins evicting Pods from that node (gracefully deleting their Pod objects). At any point after `NotReady`, the scheduler knows not to place new Pods on that node.
    * **Replacement Scheduling:** As soon as the Pod objects are deleted (or the scheduler sees the Pod still exists but no longer bound to a node), those are considered “unscheduled,” so the **kube-scheduler** picks new nodes (among the healthy ones) to run identical PodSpecs. That triggers the kubelet on the healthy nodes to create new containers via the CRI.

2. **Which Controller Creates Replacement Pods & How It Knows Replicas:**

    * The **ReplicaSet Controller** (or Deployment Controller managing the ReplicaSet) is responsible for ensuring the desired Pod replica count. It continuously watches the ReplicaSet’s `.spec.replicas` field and the listing of actual Pod objects with matching labels. If it sees fewer Pods than `.spec.replicas` because some were evicted from the dead node, it immediately creates new Pod objects. That is how it “knows” how many replacements to spin up: it compares `status.readyReplicas` (or actual Pods) versus `.spec.replicas`.

---

### Exercise 10: Kubernetes Release Cycle and Support

**Instruction:**

1. Summarize the **three‐to‐four-month** release cadence for Kubernetes minor versions, including how many minor versions are actively supported at any one time.
2. If **v1.31** was released in August 2024, state its likely End-of-Life (EOL) timeframe.
3. Explain the **version skew policy** between control-plane (e.g., API server) and `kubelet` versions on worker nodes, and why that policy exists.

**Answer:**

1. **Release Cadence & Support Window:**

    * Kubernetes issues a **minor release** roughly every three to four months (e.g., v1.31 in August 2024, v1.32 in November 2024, v1.33 in February 2025, etc.). Each minor release adds new features, maintains backward compatibility for existing APIs, and may deprecate old ones. At any given time, the project actively supports the **three most recent minor versions**: the current one plus the prior two (for example, if v1.33 is current, then v1.32 and v1.31 are still in support; v1.30 is EOL).

2. **EOL for v1.31:**

    * Since each minor version receives about **14 months** total (12 months of patch support + 2 months grace), v1.31 (released August 2024) would reach EOL around **late October 2025** (14 months after August 2024). After that point, no further security or bug-fix patches are provided for v1.31.

3. **Version Skew Policy & Its Rationale:**

    * The policy states that a `kubelet` may be at most **one minor version older or newer** than the control plane. In other words, if the API server is running v1.33.x, each kubelet should be either v1.32.x, v1.33.x, or v1.34.x (one version ahead for minor). Anything outside that window (e.g., a v1.31 kubelet talking to a v1.33 control plane) is unsupported.
    * *Why it exists:* This ensures that new API objects or fields introduced in the control plane are still understood by the kubelet (backward compatibility), and vice versa for older kubelets that might not know about brand-new fields. By limiting skew to one minor version, administrators can upgrade the control plane first (say from v1.32 → v1.33) and then roll out kubelet upgrades gradually to v1.33, without fear of version incompatibilities breaking the cluster.
