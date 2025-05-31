## 1. Introduction to Kubernetes

* **What Is Kubernetes?**
  Kubernetes is an open-source container orchestration platform. It automates deployment, scaling, and management of containerized applications. Rather than manually starting and stopping containers, Kubernetes lets you declare the desired state of your application (e.g., “run three replicas of nginx”), and it continuously works to ensure that state is met.

* **Why Use Kubernetes?**

    * **Portability & Flexibility:** Works on-premises or in the cloud.
    * **Declarative API-Driven Management:** You describe *what* you want (in YAML or via CLI), and Kubernetes figures out *how* to get there.
    * **Self-Healing:** Detects failures (e.g., crashed Pods or nodes) and automatically replaces or reschedules workloads.
    * **Horizontal Scaling:** Can automatically scale Pods based on CPU/memory usage or custom metrics.
    * **Ecosystem & Extensibility:** Pluggable networking, storage (CSI), logging, monitoring, and more.

* **Key Terminology**

    * **Cluster:** A set of machines (virtual or physical) running Kubernetes.
    * **Control Plane:** The “brain” of the cluster, comprising components that store cluster state and make scheduling decisions.
    * **Worker Nodes:** Machines that run application containers in Pods.
    * **Pod:** The smallest deployable unit—one or more co-located containers with shared networking and storage.
    * **Container Runtime:** Software (e.g., containerd) responsible for starting/stopping containers on a node.
    * **kubectl:** CLI tool to interact with the Kubernetes API server.

---

## 2. Cluster Architecture Overview

Kubernetes employs a **hub-and-spoke** model:

```
         ┌──────────────────────┐
         │    Control Plane     │   ← “Hub” (management & scheduling)
         │  (master components) │
         └──────────────────────┘
                   ▲
                   │
           gRPC/HTTPS calls
                   │
                   ▼
┌───────────┐   ┌───────────┐   ┌───────────┐
│  Node #1  │   │  Node #2  │   │  Node #3  │   ← “Spokes” (run user workloads)
│(worker)   │   │(worker)   │   │(worker)   │
└───────────┘   └───────────┘   └───────────┘
```

* **Control Plane** (hub):

    * Maintains the *desired state* (e.g., “3 replicas of this Deployment”).
    * Exposes the Kubernetes API.
    * Runs controllers and the scheduler to reconcile current vs. desired state.
    * Typically highly available (multiple instances) in production.

* **Worker Nodes** (spokes):

    * Run Pods (application containers).
    * Report status to the control plane.
    * Execute instructions from control-plane components.

> **Example:**
> A cluster with 1 control-plane VM and 3 worker-node VMs. The control plane stores cluster configuration in etcd, responds to `kubectl` commands, and the three worker nodes host Pods that serve application traffic.

---

## 3. Control-Plane Components

Control-plane components work together to manage cluster state, schedule workloads, and respond to changes.

1. **etcd (Distributed Key-Value Store)**

    * **Role:** Single source of truth for all cluster state (Deployments, Services, ConfigMaps, node info, etc.).
    * **Characteristics:** Strong consistency (reads reflect the latest writes), fault-tolerant (runs on multiple machines), recommended to use an odd number of etcd instances for quorum.
    * **Why It Matters:** Every time you `kubectl apply -f`, the API server writes to etcd. Controllers and scheduler read from etcd (via the API server) to decide what actions to take.

2. **kube-apiserver (API Server)**

    * **Role:** Central entrypoint for all REST/dynamic updates to the cluster. Validates requests (schema/auth), writes to etcd, and serves read requests to other components.
    * **Key Points:**

        * Exposes Kubernetes API under `/api/...` and `/apis/...`.
        * All changes (from users or controllers) pass through the API server.
        * Implements admission control, RBAC, and API version validation.

3. **kube-controller-manager (Controller Manager)**

    * **Role:** Runs a suite of controllers in a single binary (process). Each controller implements a *control loop* that watches resources and reconciles state.
    * **Common Controllers:**

        * **Node Controller:** Monitors node health and evicts Pods when nodes become unhealthy.
        * **ReplicaSet Controller:** Ensures the number of Pod replicas matches the desired state.
        * **Deployment Controller:** Manages rolling updates and rollbacks for Deployments.
        * **DaemonSet Controller:** Ensures that a copy of a specific Pod runs on designated nodes (e.g., log collector DaemonSet).
        * **Job Controller:** Runs batch Jobs to completion.
        * **Lease Controller:** Manages Lease objects (used for leader election and health checking).
    * **Example:** If you define a Deployment of 5 replicas and one Pod crashes, the Deployment Controller detects only 4 exist and creates a new Pod to restore the replica count.

4. **kube-scheduler (Scheduler)**

    * **Role:** Assigns newly created Pods (without a node) to a worker node.
    * **Scheduling Process:**

        1. **Filtering (Predicates):** Identify nodes that have sufficient CPU, memory, conform to taints/tolerations, satisfy affinity/anti-affinity rules.
        2. **Scoring (Priorities):** Rank filtered nodes based on metrics (e.g., least loaded, matching labels, topology alignment).
        3. **Binding:** Once a node is selected, the scheduler updates the Pod’s `.spec.nodeName`.
    * **Example:** A Pod requests “2 CPU and 4 Gi memory.” The scheduler finds all nodes with ≥2 CPU and ≥4 Gi available and picks the one with the most balanced resource usage.

5. **cloud-controller-manager (Cloud Controller Manager)**

    * **Role:** Integrates cloud-provider-specific logic separately from core Kubernetes code.
    * **Typical Sub-Controllers:**

        * **Node Controller (Cloud Sub-Controller):** Detects if cloud VM was deleted externally and updates the Kubernetes node object.
        * **Route Controller:** Manages routing tables (e.g., on AWS/GCP) for Pod-to-Pod networking.
        * **Service Controller:** Provisions cloud load balancers for `Service` resources of type `LoadBalancer`.
        * **PersistentVolume Controller:** Automatically provisions PersistentVolumes when a PVC is created.
    * **When to Use:** Required in managed/cloud-hosted environments (e.g., AWS EKS, GCP GKE) so that Kubernetes can create cloud load balancers, update auto-scaling groups, and manage storage.

---

## 4. Worker-Node Components

Each worker node must run a set of processes/agents that ensure Pods start, health is reported, and networking functions:

1. **Container Runtime (containerd, CRI-O, etc.)**

    * **Role:** Fetch container images from registries, manage container lifecycles (create, start, stop, delete).
    * **Container Runtime Interface (CRI):** Standard gRPC-based protocol that kubernetes kubelet uses to talk to container runtimes.
    * **Common Runtimes:**

        * **containerd:** Lightweight, Kubernetes-friendly runtime (default for many distributions).
        * **CRI-O:** Kubernetes-specific runtime maintained by Red Hat.
        * **Docker (Dockershim):** Deprecated as of v1.24; removed in v1.24. If you see “Docker Engine,” behind the scenes it now uses containerd.

2. **kubelet (Node Agent)**

    * **Role:**

        * Watches the API server for Pods assigned to *its* node.
        * Creates, updates, and deletes containers via the CRI.
        * Monitors container health (liveness/readiness probes) and restarts containers when probes fail.
        * Reports node and Pod status (resource usage, readiness) back to the API server by updating `Node.status` and sending Lease heartbeats.
        * Manages mounting Volumes (PVCs, ConfigMaps, Secrets).
        * Optionally runs static Pods defined on the node’s filesystem.
    * **Pod Lifecycle Example:**

        1. Control plane assigns a new Pod to this node.
        2. kubelet sees the Pod definition, calls containerd to pull the image.
        3. Container starts, kubelet attaches requested volumes.
        4. kubelet begins probing (e.g., HTTP GET on `/healthz` every 10 seconds). If probe fails, it restarts the container per Pod’s `restartPolicy`.

3. **kube-proxy (Network Proxy)**

    * **Role:** Provides Service abstraction by implementing virtual IPs (ClusterIP) on each node. Routes traffic destined for a Service to one of the backend Pod IPs.
    * **Modes:**

        * **iptables Mode (default):** Installs iptables rules that match packets destined for a Service’s ClusterIP/port and rewrites destination to one of the Pod endpoints.
        * **IPVS Mode:** Uses the Linux IP Virtual Server (IPVS) subsystem for high-performance load balancing (preferred in large clusters).
    * **Service Example:**

        1. You define a `Service` called `frontend-service` exposing port 8080.
        2. kube-proxy sees the Service + corresponding Endpoints (Pod IPs).
        3. On Node A, an iptables rule sends traffic for `10.96.0.25:8080` to one of the Pod IPs from the Endpoint list.
        4. If a backend Pod is rescheduled or scaled down, kube-proxy updates iptables/IPVS rules automatically.

4. **cAdvisor (Container Advisor)**

    * **Role:** Embedded in kubelet; collects resource usage (CPU, memory, filesystem, network) for each container.
    * **Usage:**

        * kubelet uses cAdvisor data to enforce resource limits/requests.
        * Monitoring systems (e.g., Prometheus) scrape metrics from endpoints that aggregate cAdvisor data.

---

## 5. Control-Plane ↔ Node Communication

Communication flows between control-plane components (mainly the API server) and node agents (kubelet, kube-proxy), using secure channels by default.

### 5.1 Node ➔ Control Plane (kubelet → API Server)

* **Protocol:** HTTPS (default port 443 for the API server).
* **Authentication:**

    * **Client Certificates:** kubelet can have a serving certificate/Client Certificate signed by the cluster’s CA.
    * **Service Account Tokens:** For Pods or internal components communicating to the API server. Mounted into Pods by kubelet.
* **Heartbeat (Lease Objects):**

    * kubelet periodically updates a **Lease** object in the `coordination.k8s.io/v1` API.
    * Enables the Node Controller to detect unhealthy or unreachable nodes when Leases expire.
* **Status Updates:**

    * Periodically, kubelet writes resource usage, conditions (e.g., `Ready`, `MemoryPressure`), and other status fields to the Node’s `status` subresource.

### 5.2 Control Plane ➔ Node (API Server → kubelet)

* **Protocol:** HTTPS (default port 10250 on each kubelet).
* **Use Cases:**

    * **Log Retrieval:** `kubectl logs` requires the API server to get logs from the kubelet.
    * **Exec / Attach / Port-Forward:** `kubectl exec -it pod /bin/bash` triggers API server to call kubelet, which then attaches stdin/stdout to the container.
    * **Metrics & Metrics Server:** `kubectl top nodes`/`kubectl top pods` ultimately fetch data from kubelet (via metrics API).
* **Security Note:**

    * By default, the API server does not verify kubelet serving certificates unless `--kubelet-certificate-authority` is set. That can introduce a security risk if this traffic traverses untrusted networks.
    * For untrusted environments, many setups use SSH tunnels, VPNs, or the Kubernetes **Konnectivity** proxy to secure API → kubelet traffic.

---

## 6. Kubernetes Object Management: Imperative vs. Declarative

Kubernetes objects (Deployments, Services, ConfigMaps, etc.) represent the *desired state* of your cluster. You can interact with them imperatively (ad-hoc commands) or declaratively (YAML manifests).

### 6.1 Imperative Management

* **Definition:** Directly issue commands to create/update/delete resources.

* **Common Commands:**

  ```bash
  # Create a Deployment with 3 nginx replicas
  kubectl create deployment nginx --image=nginx:1.21

  # Scale the Deployment to 5 replicas
  kubectl scale deployment nginx --replicas=5

  # Expose the Deployment via a Service
  kubectl expose deployment nginx --port=80 --target-port=80 --type=ClusterIP

  # Delete a Service
  kubectl delete svc my-service
  ```

* **When to Use:**

    * Quick experiments or demos.
    * Simple scripts where writing a full YAML manifest feels verbose.
    * Debugging or troubleshooting on-the-fly.

* **Limitations:**

    * Imperative commands do not get persisted in a Git repository (unless you record them).
    * Harder to track exact configuration over time (no manifest diff).
    * Cannot easily roll back to a prior state unless you manually track commands.

### 6.2 Declarative Management

* **Definition:** Define the desired state of resources in files (YAML or JSON) and apply them.

* **Example: Deployment (nginx-deployment.yaml)**

  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: nginx-deployment
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

* **Apply It:**

  ```bash
  kubectl apply -f nginx-deployment.yaml
  ```

* **Update It:**

    * Edit `nginx-deployment.yaml` (e.g., change `replicas: 5`), then run `kubectl apply -f nginx-deployment.yaml` again.
    * Kubernetes computes the diff and reconciles (increasing or decreasing replicas to match 5).

* **Benefits:**

    * **Version Control:** Store YAML in Git, review changes, track history.
    * **Reusability:** Reuse the same manifest in different environments (e.g., Dev, QA, Prod) with minimal adjustments.
    * **Rollback Support:** `kubectl rollout undo deployment/nginx-deployment` can revert to a previous configuration.

* **Declarative Workflow (GitOps Example):**

    1. Developer creates/updates a YAML manifest in Git.
    2. A Continuous Delivery (CD) system (e.g., ArgoCD, Flux) detects the Git change.
    3. CD system applies the manifest to the cluster.
    4. Kubernetes controllers converge to the new desired state.

---

## 7. Kubernetes Object Manifests: Structure & Format

A Kubernetes manifest is usually written in YAML, which describes:

1. **`apiVersion`**: Specifies the API group and version (e.g., `apps/v1`, `v1`, `batch/v1`).

2. **`kind`**: The type of object (e.g., `Deployment`, `Service`, `Pod`, `ConfigMap`).

3. **`metadata`**: Contains information identifying the object:

    * **`name`** (required): Unique name within the namespace.
    * **`namespace`** (optional): Defaults to `default` if omitted.
    * **`labels`** and **`annotations`**: Key-value pairs for grouping, filtering, or attaching arbitrary metadata.

4. **`spec`**: Declares the desired state. Fields here vary by object kind.

5. **`status`**: Populated by Kubernetes, reflects the observed state. Users rarely specify it directly.

---

### 7.1 Common Fields for Deployments

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-deployment
  labels:
    app: myapp
spec:
  replicas: 3                # Number of pod replicas
  selector:
    matchLabels:
      app: myapp             # How Deployment finds Pods it manages
  template:                  # Pod template used by ReplicaSet
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp-container
        image: myapp:1.0
        ports:
        - containerPort: 8080
        env:
        - name: ENV_VAR       # Example of passing environment variables
          value: "production"
        volumeMounts:
        - name: config-volume  # Mounting a Volume in the container
          mountPath: /etc/myapp/config
      volumes:
      - name: config-volume
        configMap:
          name: myapp-config  # A ConfigMap resource must already exist
```

* **`selector.matchLabels`:** Must match the labels on the Pod template, so the Deployment knows which Pods to manage.
* **`template`:** Describes how to run each Pod—container image, ports, environment variables, volume mounts, etc.
* **`volumes`:** References ConfigMaps, Secrets, PersistentVolumeClaims, host paths, etc.
* **Multi-Document Files:** You can combine multiple Kubernetes objects in one YAML file, separated by `---`.

  ```yaml
  # service.yaml + deployment.yaml in one file
  ---
  apiVersion: v1
  kind: Service
  metadata:
    name: myapp-service
  spec:
    selector:
      app: myapp
    ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
  ---
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: myapp-deployment
  spec:
    replicas: 3
    selector:
      matchLabels:
        app: myapp
    template:
      metadata:
        labels:
          app: myapp
      spec:
        containers:
        - name: myapp-container
          image: myapp:1.0
          ports:
          - containerPort: 8080
  ```

---

## 8. Controllers, Leases, and Self-Healing

One of Kubernetes’ core strengths is **self-healing** via continuous reconciliation loops implemented by controllers.

### 8.1 The Controller Pattern

* **Desired State vs. Actual State:**

    * **Desired State:** What you declare in your manifest/spec (e.g., “3 replicas of myapp”).
    * **Actual State:** What is actually running (e.g., “2 replicas due to a Pod crash”).
* **Reconciliation Loop:** Every controller:

    1. **Watches** relevant resources via the API server.
    2. **Compares** actual state vs. desired state.
    3. **Acts** to correct differences (e.g., start new Pods, delete extra Pods, recreate missing resources).

> **Example: ReplicaSet Controller**
>
> * Watches `ReplicaSet` objects. If `spec.replicas = 3` but only 2 Pods exist (due to a Pod crash), the controller creates a new Pod to match 3 replicas.

### 8.2 Leases & Node Health

* **What Is a Lease?**

    * A Kubernetes object in the `coordination.k8s.io/v1` API group.
    * Primarily used for leader election (among controllers) and for node heartbeat.
* **Node Heartbeat:**

    * Each node’s kubelet periodically (e.g., every 10 seconds) updates a Lease object named after the node.
    * The Node Controller in the control plane checks if it has seen a Lease update within a certain timeframe (default \~40 seconds).
    * If the Lease has not been renewed within the threshold, the Node Controller marks that node as `NotReady` and begins eviction of Pods.

> **Failure Scenario:**
>
> 1. Node A loses connectivity (network outage) and cannot update its Lease.
> 2. After Lease timeout, Node Controller marks Node A `NotReady`.
> 3. Pods on Node A are gradually evicted and rescheduled to other healthy nodes (depending on Pod priority and eviction policy).
> 4. kube-scheduler places new Pods elsewhere, restoring the Deployment/ReplicaSet to the desired replica count.

### 8.3 Other Self-Healing Controllers

* **Deployment Controller:**

    * Manages rolling updates. If a new Pod version fails readiness probes, Deployment Controller can pause/rollback.
* **StatefulSet Controller:**

    * Ensures ordered, unique identity Pods for stateful applications (e.g., databases).
* **DaemonSet Controller:**

    * Guarantees that a copy of a Pod runs on every node (or subset). If new nodes join, they automatically get the DaemonSet Pods.
* **Job Controller:**

    * Ensures that batch tasks (e.g., once-off data migrations) run to completion and succeed.
* **Horizontal Pod Autoscaler (HPA):**

    * Periodically queries resource metrics (CPU/memory) and scales Deployments up/down by adjusting `spec.replicas` based on configured thresholds.

---

## 9. Container Runtime Interface (CRI) and containerd

The **Container Runtime Interface (CRI)** abstracts the communication between kubelet and the container runtime.

### 9.1 Why CRI Exists

* Originally, Kubernetes used a “dockershim” to translate CRI calls into Docker Engine API calls. Maintaining dockershim became burdensome, so it was deprecated in v1.23 and fully removed in v1.24.
* **CRI-Compliant Runtimes:** Allow Kubernetes to work directly with container runtimes without an extra shim layer.

### 9.2 Common CRI Runtimes

1. **containerd**

    * **Overview:** High-performance, lightweight runtime originally spun out of Docker.
    * **Features:**

        * Pulls images (OCI-compliant).
        * Manages container lifecycle (create, start, kill).
        * Provides namespaces, snapshotter plugins (e.g., overlayfs).
    * **Usage:**

        * Most major cloud Kubernetes services (GKE, EKS, AKS) now use containerd under the hood.
        * Local Kubernetes distributions like `minikube`, `kind`, and `k3s` often default to containerd.

2. **CRI-O**

    * **Overview:** Built by Red Hat specifically to implement CRI.
    * **Features:**

        * Minimal, strictly adheres to CRI specification.
        * Maintains no extra features outside of containerd-equivalent functionality.
    * **Usage:** Often used in Red Hat-based distributions (e.g., OpenShift) or when operators want a very slim runtime.

3. **Docker (via dockershim, Deprecated)**

    * **Status:** Removed in Kubernetes v1.24. Modern clusters must use containerd or CRI-O.
    * **Legacy Note:** If you have older clusters (v1.23 or prior), Docker Engine can still be used, but an upgrade requires switching to a CRI-compliant runtime.

---

## 10. kubelet: Detailed Responsibilities

The **kubelet** is the node’s agent, responsible for making sure containers match the desired Pod specs. Its main responsibilities:

1. **Pod Lifecycle Management**

    * **Watch for Assigned Pods:** Continuously queries the API server for Pods with `.spec.nodeName = <this node>`.
    * **Create Containers:** For each new Pod, calls the container runtime (via CRI) to pull images and run containers.
    * **Health Probes:** Executes liveness and readiness probes (HTTP, TCP, or command-based).

        * **Liveness Probe Failure:** kubelet kills the container and restarts it.
        * **Readiness Probe Failure:** kubelet marks the Pod as not ready; Service endpoints are updated to exclude it.
    * **Pod Termination:** If a Pod is deleted or evicted, kubelet stops containers, unmounts volumes, and reports status.

2. **Node Status Reporting**

    * **Resource Metrics:** Using cAdvisor, gathers CPU, memory, disk, and network usage per container and aggregates per-node usage.
    * **Status Updates:** Every few seconds, kubelet updates Node’s `status` subresource (conditions, capacity, allocatable).
    * **Lease Renewal:** Updates a Lease object to inform the Node Controller that the node is healthy.

3. **Volume & Storage Management**

    * **Mounting Volumes:**

        * **HostPath Volumes:** For local directories on the node’s filesystem.
        * **ConfigMaps & Secrets:** kubelet creates temporary in-memory files or mounts tmpfs to provide these to containers.
        * **PersistentVolumeClaims (PVCs):** Works with Container Storage Interface (CSI) drivers to provision, attach, and mount external storage (cloud block storage, NFS, etc.).
    * **Volume Lifecycle:** Ensures volumes are unmounted when Pods are deleted.

4. **Node-Level Admission Checks**

    * **Resource Enforcement:** If a node is running out of memory or disk, kubelet can evict Pods to relieve pressure.
    * **Node Conditions:** Tracks conditions like `DiskPressure`, `PIDPressure`, and sets Node status accordingly.

5. **Static Pods (Bootstrapping Use Case)**

    * **Definition:** Pods defined in static YAML files on the node’s filesystem (in `/etc/kubernetes/manifests` by default).
    * **Behaviour:** kubelet watches that directory and creates Pods automatically. These Pods are not managed by the API server initially but become visible in the API once kubelet registers them.
    * **Use Case:** Often used to run control-plane components on the first master node, before the API server is available.

---

## 11. kube-proxy: Networking & Service Abstraction

`kube-proxy` provides a stable virtual IP for Services and ensures routing to healthy endpoint Pods.

### 11.1 Service Concept

* **Service (ClusterIP):**

    * Abstracts a set of Pods behind a single, stable IP address (ClusterIP).
    * Even if the underlying Pods get recreated or moved, the ClusterIP remains the same.
* **Service Types:**

    * **ClusterIP (default):** Internal-to-cluster virtual IP.
    * **NodePort:** Opens a port on every node; forwards to Service endpoints.
    * **LoadBalancer:** Provisions a cloud load balancer (via cloud-controller-manager) that forwards to NodePorts.
    * **ExternalName:** Points to an external DNS name (CNAME-like behavior).

### 11.2 How kube-proxy Works

1. **Watches the API Server:** Listens for changes to Service and Endpoint objects.
2. **Installs Networking Rules:** Depending on the mode:

    * **iptables Mode:**

        * Creates iptables chains (e.g., `KUBE-SERVICES`, `KUBE-ENDPOINTS`).
        * For each Service, installs rules that match `dst IP:port` to a set of Pod IPs (endpoints), typically using a random or round-robin choice.
        * Pros: Wide OS support; good performance for small-to-medium clusters.
    * **IPVS Mode (IP Virtual Server):**

        * Creates IPVS virtual servers and real servers corresponding to Services and endpoints.
        * Offers more sophisticated load-balancing algorithms (round-robin, least connections).
        * Pros: Better scalability and performance in large clusters.
3. **Routing External Traffic:**

    * **NodePort:** Opens a high-numbered port (e.g., 30000–32767) on every node. Traffic to `<NodeIP>:<NodePort>` is forwarded to the Service endpoints.
    * **LoadBalancer:** cloud-controller-manager configures a cloud provider’s external LB (e.g., AWS ELB, GCP LB), which forwards to NodePorts.

> **Traffic Flow Example:**
>
> 1. Client sends request to `10.96.0.15:80` (ClusterIP).
> 2. On Node A, iptables rule matches `dst=10.96.0.15:80`, picks Pod IP (e.g., `10.244.1.5:80`), DNATs packet.
> 3. Packet arrives at Pod, Pod responds. Response goes back through iptables and out to client.

---

## 12. Object Model & Self-Healing

All Kubernetes resources are represented as **objects** in the API server. Understanding how objects, controllers, and reconciliation work is critical to leveraging Kubernetes effectively.

### 12.1 Kubernetes Objects

* **Persistent Records:** Each object persists in etcd, represented by:

    1. **`metadata`:**

        * **`name`**, **`namespace`** (except for cluster-scoped objects).
        * **`labels`**—key/value tags for selection (e.g., “app=nginx”).
        * **`annotations`**—arbitrary key/value pairs for external tooling.
    2. **`spec`:** Desired state.
    3. **`status`:** Current observed state (populated by controllers).

* **Common Object Types:**

    * **Pod:** Single instance of a running container (or co-located containers).
    * **ReplicaSet:** Ensures a specified number of Pod replicas are running.
    * **Deployment:** Manages ReplicaSets for rolling updates/rollbacks.
    * **StatefulSet:** Manages stateful applications (e.g., databases) with stable network IDs and persistent storage.
    * **DaemonSet:** Ensures a Pod runs on all (or selected) nodes (e.g., log collector, monitoring agent).
    * **Job / CronJob:** Manages one-off or scheduled batch tasks.
    * **Service:** Abstracts Pods behind a stable IP/port with load balancing.
    * **ConfigMap / Secret:** Key/value pairs of configuration data or sensitive data, consumable in Pods as files or environment variables.

### 12.2 Self-Healing via Reconciliation

* **Controller Workflow:**

    1. **Watch:** Controller watches for events (add, update, delete) on relevant objects.
    2. **Fetch Actual State:** Reads current state from API server (e.g., “how many Pods are running?”).
    3. **Compare:** Checks difference between actual and desired (spec).
    4. **Act:** Calls API server to create, update, or delete resources so that the actual state matches desired state.

* **Examples of Self-Healing:**

    1. **Pod Crash:** If a container process crashes inside a Pod, kubelet’s liveness probe detects it and restarts the container. The Pod remains in a ready state when the container becomes healthy.
    2. **Node Failure:** Node A’s kubelet stops renewing its Lease. Node Controller marks Node A `NotReady`. Pods on Node A are evicted; Deployment controller ensures new Pods are scheduled on Nodes B or C to maintain replica count.
    3. **Rolling Update Failure:** A new version of an application fails readiness probes. Deployment controller pauses rollout and can revert to the previous ReplicaSet automatically (or manually with `kubectl rollout undo`).

---

## 13. Kubernetes Releases & Support Windows

Kubernetes follows a time-based release cycle, making it important for cluster operators to track supported versions, plan upgrades, and ensure component compatibility.

### 13.1 Release Cadence

* **Minor Releases (e.g., v1.32, v1.33):**

    * Occur approximately every three to four months (roughly three per year).
    * Introduce new features, API enhancements, deprecations (while maintaining backward compatibility).
* **Patch Releases (e.g., v1.32.1, v1.32.2):**

    * Address bug fixes, security patches, minor improvements.
    * Typically issued every one to two weeks, depending on severity of issues.

> **Example Timeline (Spring 2025):**
>
> * **February 2025:** v1.32 (minor) released.
> * **March–April 2025:** v1.32.x patch releases (e.g., v1.32.1, v1.32.2).
> * **May 2025:** v1.33 (minor) released.

### 13.2 Supported Versions & EOL Policy

* **Active Support:** Kubernetes maintains patch support for the *three most recent minor versions* at any time. If v1.33 is current, then v1.31, v1.32, and v1.33 receive patches. When v1.34 arrives, v1.31 moves to End of Life.
* **Patch Support Window:**

    * For versions **v1.19 and newer**, each minor release gets about **1 year** of patch support.
    * Older (pre-v1.19) versions had around **9 months** of patch support historically.
* **Total Support Window:** Roughly **14 months** from initial minor release (12 months of active patching + \~2-month grace period to upgrade).
* **Managed Kubernetes (EKS, GKE, AKS):** Often extend support windows beyond upstream policy (e.g., Amazon EKS might offer extended support totaling up to 26 months, combining standard and extended patch windows).

### 13.3 Version Skew Policy

* **Control Plane vs. kubelet:** kubelet (on worker nodes) may run **one minor version older or newer** than the control plane.

    * Allowed skew scenarios:

        * **Control Plane (v1.33.x) & Node kubelet (v1.32.x)** —supported.
        * **Control Plane (v1.33.x) & Node kubelet (v1.34.x)** —supported (node newer by one minor).
        * **Control Plane (v1.33.x) & Node kubelet (v1.31.x)** —*unsupported* (skew of two minors).
* **Upgrade Path:**

    1. **Control Plane First:** Upgrade API server, controller-manager, scheduler to new minor (e.g., v1.33).
    2. **kubelets Next:** Upgrade kubelet and kube-proxy on nodes, one node at a time (to v1.33).
* **Why It Matters:**

    * Ensures compatibility (e.g., API features, CRI interactions).
    * Allows rolling upgrades without downtime (nodes can still serve traffic even if kubelet is a version behind).

---

## 14. Summary of Key Concepts

Below is a concise summary of the most important Kubernetes components and ideas:

1. **Cluster Topology**

    * **Control Plane (hub):** etcd, API server, controller-manager, scheduler, cloud-controller-manager.
    * **Worker Nodes (spokes):** kubelet, container runtime (containerd/CRI-O), kube-proxy, cAdvisor.

2. **Control-Plane Responsibilities**

    * **etcd:** Stores all cluster state.
    * **API Server:** Exposes REST API and validates/authenticates requests.
    * **Controller Manager:** Runs controllers that reconcile state.
    * **Scheduler:** Assigns Pods to nodes.
    * **Cloud Controller Manager:** Interacts with cloud APIs for load balancers, volumes, routes.

3. **Node Responsibilities**

    * **containerd/CRI:** Pulls images, runs containers.
    * **kubelet:** Watches assigned Pods, manages lifecycle, health checking, volume mounts, status reporting.
    * **kube-proxy:** Implements Service networking (ClusterIP, NodePort, LoadBalancer).
    * **cAdvisor:** Collects container metrics.

4. **Communication**

    * **kubelet → API Server:** HTTPS calls for status updates, Lease renewal, resource metrics, and volume health.
    * **API Server → kubelet:** HTTPS calls for logs, exec/attach, port-forwarding. May require additional security (Konnectivity) in untrusted networks.

5. **Object Management**

    * **Imperative:** `kubectl create/scale/delete …` commands for on-the-fly operations.
    * **Declarative:** Define objects in YAML and apply via `kubectl apply -f`. Enables GitOps, version control, reproducibility.

6. **Self-Healing & Reconciliation**

    * Controllers constantly watch objects and reconcile actual vs. desired state.
    * If Pods crash or nodes fail, controllers replace or reschedule resources automatically.
    * Leases ensure timely detection of node failures.

7. **Container Runtime Interface (CRI)**

    * Standard interface for kubelet to communicate with container runtimes.
    * Containerd and CRI-O are common CRI-compliant runtimes.
    * Docker (dockershim) is deprecated/removed.

8. **kubelet Deep Dive**

    * Creates stops containers via CRI.
    * Manages volumes (ConfigMaps, Secrets, PVCs).
    * Reports node/POD health.
    * Enforces resource requests/limits and node-level pressure eviction.

9. **kube-proxy & Networking**

    * Ensures Service abstraction (ClusterIP, NodePort, LoadBalancer).
    * Uses iptables or IPVS to route traffic to Pod endpoints.
    * Automatically updates routing rules when endpoints change.

10. **Release Cycle & Support**

    * Minor releases every 3–4 months; patch releases every 1–2 weeks.
    * Support for three most recent minor versions; older versions become EOL after \~14 months.
    * kubelet may be one minor version behind/ahead of control plane.
    * Managed services often extend support windows.

---

## 15. Next Steps for Independent Study

To deepen your understanding, trainees can:

1. **Read the Official Documentation**

    * [Kubernetes Concepts & Architecture](https://kubernetes.io/docs/concepts/architecture/)
    * [API Overview & kubectl Tutorials](https://kubernetes.io/docs/reference/using-api/)
    * [Controller Patterns & Pod Lifecycle](https://kubernetes.io/docs/concepts/workloads/controllers/)

2. **Explore Example YAML Manifests**

    * Practice writing Deployments, Services, ConfigMaps, StatefulSets, and DaemonSets.
    * Use `kubectl apply -f` and `kubectl describe` to inspect objects in a test cluster (e.g., Kind, Minikube).

3. **Inspect Logs & Resources in a Local Cluster**

    * Install a local cluster with Minikube or Kind.
    * Deploy a simple Nginx Deployment; observe how ReplicaSets, Pods, and Services are created.
    * Simulate node failure by draining a node or deleting a Pod, and watch self-healing in action.

4. **Monitor Resource Usage**

    * Enable metrics-server in your cluster.
    * Run `kubectl top nodes` and `kubectl top pods` to see CPU/memory usage.
    * Create a simple Pod with resource requests and limits; observe enforcement.

5. **Experiment with Container Runtimes**

    * Create a cluster or node with containerd and/or CRI-O.
    * Observe how `crictl` (CRI command-line tool) interacts with container runtime independent of Docker.

6. **Follow Release Notes & Upgrades**

    * Track the Kubernetes [Releases Page](https://kubernetes.io/releases/) to stay updated on new minor versions.
    * Practice upgrading a test cluster (control plane then kubelets), observing version-skew policy in action.

---

## 16. Glossary of Common Kubernetes Terms

| Term                     | Definition                                                                                          |
| ------------------------ | --------------------------------------------------------------------------------------------------- |
| **Cluster**              | A set of control-plane and worker nodes running Kubernetes.                                         |
| **Control Plane**        | Components (etcd, API server, controllers, scheduler) that manage cluster state.                    |
| **Worker Node**          | A (physical/virtual) machine where Pods run; contains kubelet, container runtime, kube-proxy.       |
| **Pod**                  | Smallest deployable unit; one or more containers sharing networking and storage.                    |
| **Deployment**           | Controller that manages a ReplicaSet; supports rolling updates and rollbacks.                       |
| **ReplicaSet**           | Controller that ensures a specified number of Pod replicas run at any given time.                   |
| **StatefulSet**          | Controller for stateful applications requiring stable network IDs and persistent volumes.           |
| **DaemonSet**            | Controller that ensures a copy of a Pod runs on all (or certain) nodes.                             |
| **Job / CronJob**        | Controllers for batch or scheduled tasks.                                                           |
| **Service**              | Abstraction for a logical set of Pods, providing a stable IP and load-balancing.                    |
| **ConfigMap**            | Key-value store for non-sensitive configuration data, injected into Pods as files/env vars.         |
| **Secret**               | Key-value store for sensitive data (e.g., passwords, tokens), injected as files/env vars.           |
| **kubelet**              | Node agent that ensures containers defined in Pod specs are running and healthy.                    |
| **kube-proxy**           | Implements Services by managing iptables or IPVS rules for packet routing on each node.             |
| **etcd**                 | Distributed, consistent key-value store for all Kubernetes resource definitions.                    |
| **kube-apiserver**       | Frontend for the Kubernetes control plane; validates, authenticates, and serves API requests.       |
| **kube-scheduler**       | Assigns Pods to nodes based on resource requirements and constraints.                               |
| **Controller Manager**   | Runs various controllers (ReplicaSet, Deployment, Node, Job, Lease, etc.) to reconcile state.       |
| **Lease**                | Lightweight object indicating node or controller “heartbeat” for health and leader election.        |
| **Containerd**           | A CRI-compliant container runtime used by kubelet to manage container lifecycle.                    |
| **CRI-O**                | Alternative CRI-compliant container runtime focused on minimal Kubernetes integrations.             |
| **Admission Controller** | Plugins within the API server that intercept requests to enforce policies (e.g., validate, mutate). |

---

## 17. Useful Commands for Getting Started

Below are some basic `kubectl` commands to help trainees explore a Kubernetes cluster interactively.

* **Cluster Info & Status**

  ```bash
  kubectl version               # Show client & server versions
  kubectl cluster-info          # Display cluster and endpoint information
  kubectl get componentstatuses # View health of control-plane components
  kubectl get nodes             # List all nodes and their status
  ```

* **Working with Namespaces**

  ```bash
  kubectl get namespaces        # List all namespaces
  kubectl create namespace dev  # Create a new namespace “dev”
  kubectl config set-context --current --namespace=dev # Switch context to “dev” namespace
  ```

* **Inspecting Workloads**

  ```bash
  kubectl get pods             # List all Pods in the current namespace
  kubectl get deployments      # List all Deployments in the current namespace
  kubectl describe pod <pod>   # Show detailed information about a specific Pod
  kubectl logs <pod> [-c <container>] # View logs for a Pod (or a specific container)
  ```

* **Applying & Modifying Objects**

  ```bash
  kubectl apply -f my-deployment.yaml   # Create or update resources defined in YAML
  kubectl edit deployment nginx         # Launch editor to modify Deployment “nginx”
  kubectl scale deployment nginx --replicas=5  # Scale “nginx” Deployment to 5 replicas
  kubectl delete -f my-deployment.yaml  # Delete resources defined in YAML
  ```

* **Services & Networking**

  ```bash
  kubectl get svc                 # List Services
  kubectl describe svc my-service # Show Service details (ClusterIP, endpoints)
  kubectl port-forward svc/my-service 8080:80 # Forward local port 8080 to service port 80
  ```

* **Viewing Resource Usage**

  ```bash
  kubectl top nodes               # Show resource usage for each node (requires metrics-server)
  kubectl top pods                # Show resource usage for each Pod
  ```

* **Inspecting Events**

  ```bash
  kubectl get events              # List recent events (Pod failures, scheduling decisions, etc.)
  kubectl describe node <node>    # Look for events related to node health/evictions
  ```

---

## 18. Further Reading & References

* **Official Kubernetes Documentation**

    * [Core Concepts](https://kubernetes.io/docs/concepts/)
    * [Cluster Architecture](https://kubernetes.io/docs/concepts/architecture/)
    * [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

* **Control Plane Deep Dive**

    * [Controller Manager Concepts](https://kubernetes.io/docs/concepts/architecture/controller/)
    * [Scheduler Extender and Policy](https://kubernetes.io/docs/concepts/architecture/scheduler/)

* **Networking & Services**

    * [Services, Load Balancing, & Networking](https://kubernetes.io/docs/concepts/services-networking/service/)
    * [kube-proxy Modes (iptables vs. IPVS)](https://kubernetes.io/docs/concepts/services-networking/service/#proxy-mode-iptables-or-ipvs)

* **Container Runtime & CRI**

    * [CRI Overview](https://kubernetes.io/docs/setup/cri/)
    * [containerd Docs](https://containerd.io/docs/)
    * [CRI-O Docs](https://cri-o.io/)

* **Storage & Volumes**

    * [Volumes, PVCs, & StorageClasses](https://kubernetes.io/docs/concepts/storage/volumes/)
    * [CSI (Container Storage Interface)](https://kubernetes.io/docs/concepts/storage/).

* **Release & Versioning**

    * [Kubernetes Release Cycle](https://kubernetes.io/releases/roadmap/)
    * [Version Skew Policy](https://kubernetes.io/docs/setup/release/version-skew-policy/)
    * [End of Life (EOL) Policy](https://github.com/kubernetes/sig-release/blob/master/releases.md#support-policy).

---

## 19. Tips for Independent Learning

1. **Set Up a Local Cluster**

    * Use **Kind (Kubernetes in Docker)** or **Minikube** to experiment without needing cloud resources.
    * Practice deploying simple apps (nginx, busybox) and inspect how Kubernetes creates ReplicaSets, Pods, and Services.

2. **Use Visual Dashboards**

    * Enable the **Kubernetes Dashboard** or use third-party UIs (Lens, Octant) to visualize objects, logs, and metrics.
    * Seeing the cluster graphically can help connect the YAML definitions to running Pods and Services.

3. **Version Control Everything**

    * Store your manifests in Git, even when experimenting. If something breaks, you can quickly `git revert`.
    * Explore GitOps tools (ArgoCD, Flux) where applying YAML from Git automatically syncs with the cluster.

4. **Inspect Logs & Events**

    * Regularly run `kubectl get events` to see scheduling failures, Pod crashes, or resource pressure events.
    * Use `kubectl describe <resource>` to find detailed status and problems (e.g., image pull errors, crash loops).

5. **Simulate Failures**

    * Manually kill Pods to see how controllers spin up replacements.
    * Drain a node (`kubectl drain`) to observe Pod eviction and rescheduling.
    * Introduce resource pressure (e.g., run a CPU-intensive process) to see how HPA scales and how kubelet evicts Pods under pressure.

6. **Follow the Release Cycle**

    * Subscribe to the Kubernetes release announcements or RSS feed.
    * When a new minor version drops, read the release notes to understand new features and deprecations.
    * Practice upgrading a test cluster before tackling production upgrades.

