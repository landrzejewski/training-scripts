## 1. Local Kubernetes Clusters with Kind

### 1.1 Overview of Kind

* **Kind** (Kubernetes in Docker) runs lightweight Kubernetes clusters inside Docker containers.
* Each node in a Kind cluster is a Docker container running the Kubernetes components (`kubelet`, `kube-proxy`, and a container runtime such as `containerd`).
* **Use Cases**: Local development, CI/CD pipelines, learning Kubernetes without provisioning VMs.

### 1.2 Prerequisites

1. **Docker Engine**

   * Version ≥ 19.03 recommended.
   * Ensure your user can run Docker (e.g., is in the `docker` group or uses `sudo`).
2. **Kind Binary**

   * Download from GitHub releases and install to `/usr/local/bin/kind`.
   * Verify via `kind version`.
3. **kubectl CLI**

   * Download the latest stable release; install to `/usr/local/bin/kubectl`.
   * Verify with `kubectl version --client`.
4. **Operating System**

   * Linux kernel ≥ 4.19 (for `cgroup` support), or Docker Desktop on Mac/Windows (including WSL2).

### 1.3 Creating a Basic Kind Cluster

1. **Create Cluster**

   ```bash
   kind create cluster --name kind-dev
   ```

   * Downloads (or reuses) a node image (e.g., `kindest/node:v1.27.3`).
   * Spins up one control-plane and one worker container.
   * Writes a new kubeconfig context `kind-kind-dev`.

2. **Verify Cluster**

   ```bash
   kubectl cluster-info --context kind-kind-dev
   kubectl get nodes --context kind-kind-dev
   ```

   Expect two nodes (`Ready`):

   ```
   NAME                         STATUS   ROLES           AGE   VERSION
   kind-dev-control-plane       Ready    control-plane   1m    v1.27.3
   kind-dev-worker              Ready    <none>          1m    v1.27.3
   ```

3. **Deploy a Sample Application**

   ```bash
   kubectl create namespace demo --context kind-kind-dev
   kubectl apply -n demo -f https://k8s.io/examples/application/deployment.yaml --context kind-kind-dev
   kubectl get pods -n demo --context kind-kind-dev
   ```

   You'll see NGINX pods running inside the `demo` namespace.

### 1.4 Customizing a Kind Cluster

1. **Example Config (`kind-cluster.yaml`)**

   ```yaml
   kind: Cluster
   apiVersion: kind.x-k8s.io/v1alpha4
   nodes:
     - role: control-plane
       extraPortMappings:
         - containerPort: 30080   # Map host port 80 → container port 30080
           hostPort: 80
           protocol: TCP
     - role: worker
     - role: worker
   networking:
     apiServerAddress: "127.0.0.1"
     apiServerPort: 6443
   ```

2. **Create with Config**

   ```bash
   kind create cluster --name dev-cluster --config kind-cluster.yaml
   ```

   * Creates one control-plane and two worker nodes.
   * Maps host’s port 80 to control-plane container port 30080; services of type NodePort/LoadBalancer on port 80 become directly accessible.

3. **Exposing Services Externally**

   * Define a Service of type `NodePort` or `LoadBalancer`.
   * Traffic to host port 80 → container port 30080 → `kube-proxy` routes to pod port.

### 1.5 Benefits and Limitations of Kind

* **Advantages**:

   * Fast startup/teardown.
   * Low resource overhead (runs entirely in Docker).
   * Ideal for CI/CD (spin up clusters in pipelines, run tests, destroy).
* **Limitations**:

   * **Not production-grade**: containerized nodes lack many real-world networking features.
   * Docker networking (bridge) cannot simulate complex topologies.
   * Cannot attach multiple physical NICs or advanced firewall rules to nodes.

### 1.6 Tips for Kind Usage

* **Updating Kubernetes Version**:

  ```bash
  kind create cluster --image kindest/node:v1.28.0
  ```
* **Multiple Clusters & Contexts**:
  Create clusters with different names (e.g., `kind-dev`, `kind-staging`). Use:

  ```bash
  kubectl config use-context kind-dev
  ```
* **Mounting Host Volumes**:
  In `kind-cluster.yaml`:

  ```yaml
  nodes:
    - role: worker
      extraMounts:
        - hostPath: /home/user/localdata
          containerPath: /data
  ```

  Pod can mount `/data`.

---

## 2. On-Premise Kubernetes with kubeadm

### 2.1 Overview and Use Cases

* **kubeadm** streamlines provisioning an on-premise or bare-metal Kubernetes cluster.
* Creates a control-plane (or multiple control-plane nodes for HA) and worker nodes.
* **Use Cases**: Production-like environments, private datacenters, equipment you manage yourself.

### 2.2 Hardware & OS Requirements

* **Control-Plane Nodes**: ≥ 4 GiB RAM, ≥ 2 CPU cores, ≥ 20 GiB storage.
* **Worker Nodes**: ≥ 2 GiB RAM, ≥ 2 CPU cores, ≥ 20 GiB storage.
* **OS**: Ubuntu 20.04/22.04, Debian 11/12, CentOS 7/8, Rocky Linux 8/9, or similar with Linux kernel ≥ 4.19.
* **Networking**: Nodes must reach each other via IP; ideally set static IPs or use reliable DNS or `/etc/hosts`.

### 2.3 Linux Kernel & System Configuration

1. **Disable Swap**

   ```bash
   sudo swapoff -a
   ```

   Comment out any swap lines in `/etc/fstab`.
2. **Load Kernel Modules & sysctl**
   Create `/etc/modules-load.d/k8s.conf`:

   ```
   br_netfilter
   overlay
   ```

   Create `/etc/sysctl.d/k8s.conf`:

   ```
   net.bridge.bridge-nf-call-iptables  = 1
   net.bridge.bridge-nf-call-ip6tables = 1
   net.ipv4.ip_forward                 = 1
   net.ipv6.conf.all.forwarding        = 1
   vm.swappiness                        = 0
   ```

   Apply:

   ```bash
   sudo sysctl --system
   ```
3. **Firewall & SELinux**

   * **Ubuntu/Debian**: If using `ufw`, either open ports manually or disable it temporarily:

     ```bash
     sudo ufw disable
     ```
   * **CentOS/RHEL**: Disable `firewalld`:

     ```bash
     sudo systemctl disable firewalld --now
     ```
   * **SELinux (CentOS/Fedora/RHEL)**:

     ```bash
     sudo setenforce 0
     # Edit /etc/selinux/config → SELINUX=permissive
     ```

### 2.4 Installing a Container Runtime Interface (CRI)

Since Kubernetes v1.24, Docker’s built-in shim is removed. Use **containerd** or **CRI-O**.

#### 2.4.1 Install containerd (Ubuntu/Debian Example)

1. **Prerequisites**

   ```bash
   sudo apt-get update
   sudo apt-get install -y ca-certificates curl gnupg lsb-release
   ```
2. **Add Docker’s Repository**

   ```bash
   sudo mkdir -p /etc/apt/keyrings
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
   echo \
     "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
     https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
     | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   sudo apt-get update
   ```
3. **Install containerd**

   ```bash
   sudo apt-get install -y containerd.io
   ```
4. **Configure containerd**

   ```bash
   sudo mkdir -p /etc/containerd
   sudo containerd config default | sudo tee /etc/containerd/config.toml
   ```

   In `/etc/containerd/config.toml`, find:

   ```toml
   [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
     SystemdCgroup = false
   ```

   Change to:

   ```toml
   [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
     SystemdCgroup = true
   ```

   Restart and enable:

   ```bash
   sudo systemctl restart containerd
   sudo systemctl enable containerd
   ```

#### 2.4.2 (Optional) Install Docker Instead

1. Install Docker:

   ```bash
   sudo apt-get install -y docker.io
   sudo systemctl enable docker --now
   sudo usermod -aG docker $USER   # Re-login to apply
   ```
2. Configure `daemon.json`:

   ```json
   {
     "exec-opts": ["native.cgroupdriver=systemd"],
     "log-driver": "json-file",
     "log-opts": { "max-size": "100m" },
     "storage-driver": "overlay2"
   }
   ```

   Restart Docker:

   ```bash
   sudo systemctl restart docker
   ```

### 2.5 Installing kubeadm, kubelet, and kubectl

1. **Add Kubernetes APT Repository**

   ```bash
   sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg \
       https://packages.cloud.google.com/apt/doc/apt-key.gpg
   echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] \
     https://apt.kubernetes.io/ kubernetes-xenial main" \
     | sudo tee /etc/apt/sources.list.d/kubernetes.list
   sudo apt-get update
   ```
2. **Install Specific Versions**

   ```bash
   sudo apt-get install -y kubelet=1.27.3-00 kubeadm=1.27.3-00 kubectl=1.27.3-00
   ```

   Replace `1.27.3-00` with your desired version.
3. **Prevent Unintended Upgrades (Optional)**

   ```bash
   sudo apt-mark hold kubelet kubeadm kubectl
   ```
4. **Verify**

   ```bash
   kubeadm version
   kubelet --version
   kubectl version --client
   ```

### 2.6 Initializing the Control Plane (`kubeadm init`)

1. **Create a Configuration File** (recommended)
   Save as `kubeadm-config.yaml`:

   ```yaml
   apiVersion: kubeadm.k8s.io/v1beta3
   kind: ClusterConfiguration
   kubernetesVersion: v1.27.3
   controlPlaneEndpoint: "master.example.local:6443"   # or a load balancer/VIP
   networking:
     podSubnet: "10.244.0.0/16"       # if you plan to use Flannel
     serviceSubnet: "10.96.0.0/12"
   ---
   apiVersion: kubeproxy.config.k8s.io/v1alpha1
   kind: KubeProxyConfiguration
   mode: "iptables"
   ```
2. **Run `kubeadm init`**

   ```bash
   sudo kubeadm init --config=kubeadm-config.yaml --upload-certs
   ```

   * `--upload-certs`: Stores control-plane certificates in a `Secret` for HA join tokens.
3. **Post-Init Steps**

   ```bash
   mkdir -p $HOME/.kube
   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   sudo chown $(id -u):$(id -g) $HOME/.kube/config
   ```

   Verify pods in `kube-system` are running:

   ```bash
   kubectl get pods -n kube-system
   ```
4. **Note the `kubeadm join` Command**
   Kubernetes prints a line similar to:

   ```
   kubeadm join master.example.local:6443 --token <token> \
     --discovery-token-ca-cert-hash sha256:<hash>
   ```

   Use this on each worker node to join the cluster.

### 2.7 Joining Worker Nodes

1. **Prerequisites on Worker**:

   * Same Linux config changes (swap off, `sysctl`, CRI installed, kubeadm/kubelet installed).
2. **Execute Join**

   ```bash
   sudo kubeadm join master.example.local:6443 \
     --token <token> \
     --discovery-token-ca-cert-hash sha256:<hash>
   ```
3. **Verify from Control Plane**

   ```bash
   kubectl get nodes
   ```

   You should see the worker node in `Ready` state.

### 2.8 Installing a CNI Plugin

Kubernetes requires a CNI for inter-pod networking. Popular options:

1. **Flannel**

   ```bash
   kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/v0.23.0/Documentation/kube-flannel.yml
   ```

   * Ensure `podSubnet` in your `kubeadm` config matches `10.244.0.0/16`.
2. **Calico**

   ```bash
   kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
   ```
3. **Weave Net**

   ```bash
   kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
   ```
4. **Cilium (eBPF)**

   ```bash
   kubectl create -f https://raw.githubusercontent.com/cilium/cilium/v1.14.0/install/kubernetes/quick-install.yaml
   ```

   * Requires Linux kernel ≥ 4.19.

After installation, wait for all CNI pods in `kube-system` to be `Running`:

```bash
kubectl get pods -n kube-system
```

### 2.9 (Optional) MetalLB for LoadBalancer Services

On-prem clusters lack cloud-provider load balancers. **MetalLB** provides a bare-metal load balancer implementation.

1. **Deploy MetalLB**

   ```bash
   kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.11/config/manifests/metallb-native.yaml
   ```
2. **Configure an Address Pool**
   Create `metallb-config.yaml`:

   ```yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     namespace: metallb-system
     name: config
   data:
     config: |
       address-pools:
       - name: default
         protocol: layer2
         addresses:
         - 192.168.1.240-192.168.1.250
   ```

   Apply:

   ```bash
   kubectl apply -f metallb-config.yaml
   ```
3. **Using Services of Type LoadBalancer**

   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: nginx-lb
   spec:
     type: LoadBalancer
     ports:
       - port: 80
         targetPort: 80
     selector:
       app: nginx
   ```

   MetalLB advertises an IP from the pool (e.g., `192.168.1.241`) so external traffic can reach your service.

### 2.10 Basic Security & Best Practices

1. **RBAC (Role-Based Access Control)**

   * By default, `admin.conf` has `cluster-admin` privileges. In multi-user clusters, create `Roles`/`ClusterRoles` and `RoleBindings` to limit access (e.g., “pod-reader” for read-only pod access).
2. **Pod Security Admission**

   * Avoid deprecated Pod Security Policies (PSPs). Instead, use **Pod Security Admission** labels on namespaces to enforce baseline/restricted settings.

     ```bash
     kubectl label namespace dev pod-security.kubernetes.io/enforce=baseline
     kubectl label namespace dev pod-security.kubernetes.io/enforce-version=v1.27.0
     ```
3. **PersistentVolumes & StorageClasses**

   * For on-prem storage, use NFS, iSCSI, Ceph, LVM, etc.
   * Define `StorageClass` resources and create `PersistentVolumeClaims` in workloads. Consider dynamic provisioning or pre-provisioning PVs.
4. **Upgrades**

   * **Check available versions**:

     ```bash
     sudo kubeadm upgrade plan
     ```
   * **Upgrade control plane**:

     ```bash
     sudo kubeadm upgrade apply v1.28.0
     ```
   * **Upgrade kubelet/kubectl** on each node:

     ```bash
     sudo apt-get install kubelet=1.28.0-00 kubectl=1.28.0-00
     sudo systemctl restart kubelet
     ```
   * **Version Skew Policy**: Kubelets can be one minor version older or newer than control plane; do not skip more than one minor version.
5. **Monitoring & Metrics**

   * **Metrics Server** for HPA:

     ```bash
     kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
     ```
   * For production-grade monitoring, deploy Prometheus + Grafana, using exporters like `node-exporter` and `kubestate-metrics`.
6. **etcd Backup & Restore**

   * **Snapshot** on single control-plane node:

     ```bash
     sudo ETCDCTL_API=3 etcdctl snapshot save ~/etcd-snapshot-$(date +%F).db \
       --endpoints=https://127.0.0.1:2379 \
       --cacert=/etc/kubernetes/pki/etcd/ca.crt \
       --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
       --key=/etc/kubernetes/pki/etcd/healthcheck-client.key
     ```
   * **Restore**:

      1. Stop control-plane components.
      2. Run `etcdctl snapshot restore <snapshot> --data-dir=<new-dir>`.
      3. Update etcd’s data directory in the static pod spec (`/etc/kubernetes/manifests/etcd.yaml`).
      4. Restart control-plane pods.

---

## 3. Kubernetes Object Management

Kubernetes is **declarative**: you express the desired state using YAML/JSON manifests, and Kubernetes continuously works to make reality match that. **Objects** represent cluster entities (Pods, Services, Deployments, ConfigMaps, etc.). Each object has:

* **`apiVersion`**: Which API group/version (e.g., `v1`, `apps/v1`, `batch/v1`).
* **`kind`**: Type of object (e.g., `Pod`, `Deployment`, `Service`).
* **`metadata`**: Fields like `name`, `namespace`, `labels`, `annotations`.
* **`spec`**: Desired state (user-defined).
* **`status`**: Current observed state (managed by Kubernetes).

### 3.1 Creating and Updating Objects

#### 3.1.1 Creating

```bash
kubectl apply -f <manifest>.yaml
```

* If object doesn’t exist, it’s created.
* If it exists, Kubernetes attempts to merge changes (patch).

Alternatively:

```bash
kubectl create -f <manifest>.yaml
```

* Errors if object already exists (no merge).

#### 3.1.2 Viewing

* **List all objects of a kind**:

  ```bash
  kubectl get pods
  kubectl get deployments
  ```
* **Describe detail**:

  ```bash
  kubectl describe deployment nginx-deployment
  ```

  Shows events, status, replica counts, etc.
* **Output as YAML/JSON**:

  ```bash
  kubectl get svc myservice -o yaml
  kubectl get pod mypod -o json
  ```

#### 3.1.3 Updating

* Modify your local YAML (e.g., change `replicas: 3` → `replicas: 5`).
* Run:

  ```bash
  kubectl apply -f deployment.yaml
  ```

  Kubernetes performs a **rolling update** if supported by the object type.
* Or use `kubectl edit` to open the live spec in an editor:

  ```bash
  kubectl edit deployment nginx-deployment
  ```

  Save to trigger the update.

#### 3.1.4 Deleting

```bash
kubectl delete -f deployment.yaml
# or
kubectl delete deployment nginx-deployment
```

* By default, pods terminate gracefully (`SIGTERM` → wait → `SIGKILL` if unresponsive).
* To force immediate deletion (usually discouraged):

  ```bash
  kubectl delete pod mypod --grace-period=0 --force
  ```

### 3.2 Object YAML Structure

```yaml
apiVersion: <group>/<version>     # e.g., apps/v1
kind: <Kind>                      # e.g., Deployment, Service
metadata:
  name: <object-name>
  namespace: <namespace>          # optional; defaults to “default”
  labels:
    <key>: <value>
  annotations:
    <key>: <value>
spec:
  # Desired state fields vary by kind
status:       # Managed by Kubernetes; not set in YAML
  ...
```

* **`labels`**: Key/value pairs for grouping, selection, and filtering.
* **`annotations`**: Arbitrary metadata (not used for selection; for tools, documentation).

> **Tip**: Use `kubectl explain <kind>.<field>` to learn about each field.
> Example:
>
> ```
> kubectl explain deployment.spec.template.spec.containers
> ```

### 3.3 Labels and Selectors

Labels are essential for identifying and grouping objects.

#### 3.3.1 Label Syntax

* **Key**: `(<prefix>/)?<name>`, where `<prefix>` is a DNS subdomain (optional); total length ≤ 253 characters. Name ≤ 63 characters, alphanumeric, `-`, `_`, `.`.
* **Value**: ≤ 63 characters, alphanumeric, `-`, `_`, `.` (can be empty).

**Examples**:

```yaml
labels:
  app: nginx
  tier: frontend
  environment: production
  example.com/version: "v1.2.3"
```

#### 3.3.2 Label Selectors

* **Equality-based**:

   * `key=value`, `key==value`
   * `key!=value`
* **Set-based**:

   * `key in (value1,value2)`
   * `key notin (value1,value2)`
   * `key` (exists)
   * `!key` (does not exist)

**kubectl examples**:

```bash
kubectl get pods -l app=nginx
kubectl get services -l environment=production,tier=frontend
kubectl get pods -l "release in (stable,canary)"
```

Controllers like Deployments, ReplicaSets, and Services use label selectors to know which Pods to manage or route to.

### 3.4 Namespaces

Namespaces provide **logical partitions** within a cluster, isolating names and resources. By default, kubeadm sets up:

* `default` (for user workloads)
* `kube-system` (system components)
* `kube-public` (read-only, cluster info)

#### 3.4.1 Creating a Namespace

```yaml
# namespace-dev.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: dev
```

Apply:

```bash
kubectl apply -f namespace-dev.yaml
```

List:

```bash
kubectl get namespaces
# NAME          STATUS   AGE
# default       Active   10d
# dev           Active   5m
# kube-system   Active   10d
# kube-public   Active   10d
```

#### 3.4.2 Deleting a Namespace

```bash
kubectl delete namespace dev
```

* Asynchronous: Kubernetes deletes all resources in that namespace before removing it.

#### 3.4.3 Using Namespaces

* **Creating an object in a namespace**:
  Add `metadata.namespace: dev` in manifest or use `-n dev` with `kubectl`.
* **Switch default namespace for context**:

  ```bash
  kubectl config set-context --current --namespace=dev
  ```
* **Listing across namespaces**:

  ```bash
  kubectl get pods --all-namespaces
  ```

#### 3.4.4 Resource Quotas & LimitRanges

* **ResourceQuota** (limits total resource usage per namespace):

  ```yaml
  apiVersion: v1
  kind: ResourceQuota
  metadata:
    name: dev-quota
    namespace: dev
  spec:
    hard:
      requests.cpu: "4"
      requests.memory: 8Gi
      limits.cpu: "8"
      limits.memory: 16Gi
      pods: "10"
  ```
* **LimitRange** (sets default requests/limits for containers):

  ```yaml
  apiVersion: v1
  kind: LimitRange
  metadata:
    name: dev-limits
    namespace: dev
  spec:
    limits:
    - default:
        cpu: "500m"
        memory: "256Mi"
      defaultRequest:
        cpu: "200m"
        memory: "128Mi"
      type: Container
  ```

#### 3.4.5 Network Policies & RBAC

* **NetworkPolicy** can isolate traffic by namespace:

  ```yaml
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    name: allow-frontend-to-backend
    namespace: backend
  spec:
    podSelector: {}  # selects all pods in backend
    ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            name: frontend
  ```
* **RBAC**: Use `Role`/`RoleBinding` scoped to a namespace to grant specific permissions (e.g., Pod read-only to user `alice` in `dev`).

### 3.5 Annotations

Annotations store **non-identifying metadata** (e.g., build info, URLs, descriptive text).

* Located under `metadata.annotations`.
* Not used for selectors (unlike labels).
* Can be larger/verbose.

**Example**:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  annotations:
    build-version: "42"
    git-commit: "a1b2c3d4"
    changelog-url: "https://git.example.com/myrepo/commit/a1b2c3d4"
    maintainer: "ops-team@example.com"
spec:
  replicas: 3
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: webapp
        image: example/webapp:latest
```

* **Add/Update** post-creation:

  ```bash
  kubectl annotate deployment webapp build-version="2025-05-30-002" --overwrite
  ```
* **Remove**:

  ```bash
  kubectl annotate pod mypod backup/schedule-
  ```
* **Retrieve**:

  ```bash
  kubectl describe pod mypod
  ```

  or

  ```bash
  kubectl get deployment webapp -o yaml | grep annotations -A 5
  ```

---

## 4. Common Labeling Conventions

Standardizing labels simplifies automation, dashboards, and policies. Kubernetes recommends a set of “common labels” under the `app.kubernetes.io/` prefix:

| Key                             | Example Value        | Purpose                                                                    |
| ------------------------------- | -------------------- | -------------------------------------------------------------------------- |
| `app.kubernetes.io/name`        | `nginx`              | The application’s name.                                                    |
| `app.kubernetes.io/instance`    | `nginx-1`            | A unique instance ID (e.g., one deployment).                               |
| `app.kubernetes.io/version`     | `v1.2.3`             | Application version (image tag or release).                                |
| `app.kubernetes.io/component`   | `frontend`, `cache`  | The component role (e.g., front-end, database).                            |
| `app.kubernetes.io/part-of`     | `ecommerce-app`      | The higher-level app this belongs to (e.g., microservices suite).          |
| `app.kubernetes.io/managed-by`  | `Helm`, `kustomize`  | Tool managing this object (e.g., Helm).                                    |
| `app.kubernetes.io/operated-by` | `db-team`            | Team or entity responsible for this workload.                              |
| `app.kubernetes.io/created-by`  | `GitOps`, `CircleCI` | Indicates what created it.                                                 |
| `helm.sh/chart`                 | `nginx-1.0.0`        | The Helm chart name and version (if deployed via Helm).                    |
| `heritage`                      | `Helm`               | The tool that originally created this resource (often auto-added by Helm). |

**Benefits**:

* Dashboards (Prometheus, Grafana) can group metrics by `app.kubernetes.io/part-of`.
* Policies (OPA, Kyverno) can enforce required labels on resources.
* Services can select pods consistently across microservices.

**Example Deployment with Common Labels**:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-master
  labels:
    app.kubernetes.io/name: redis
    app.kubernetes.io/instance: redis-master-1
    app.kubernetes.io/version: "6.2.5"
    app.kubernetes.io/component: database
    app.kubernetes.io/part-of: "ecommerce-app"
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/operated-by: "db-team"
    helm.sh/chart: "redis-4.5.0"
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: redis
      app.kubernetes.io/instance: redis-master-1
  template:
    metadata:
      labels:
        app.kubernetes.io/name: redis
        app.kubernetes.io/instance: redis-master-1
        app.kubernetes.io/version: "6.2.5"
        app.kubernetes.io/component: database
        app.kubernetes.io/part-of: "ecommerce-app"
        app.kubernetes.io/managed-by: Helm
        app.kubernetes.io/operated-by: "db-team"
        helm.sh/chart: "redis-4.5.0"
    spec:
      containers:
      - name: redis
        image: redis:6.2.5
        ports:
        - containerPort: 6379
```

**Service Selecting on Common Labels**:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: redis-service
spec:
  selector:
    app.kubernetes.io/name: redis
    app.kubernetes.io/instance: redis-master-1
  ports:
  - protocol: TCP
    port: 6379
    targetPort: 6379
```

**Additional Useful Labels** (beyond the official set):

* `team`: e.g., `team: payment-service`
* `environment`: `dev`, `staging`, `prod`
* `git-repo`: URL of the Git repo
* `release`: e.g., `v2.3.1` (especially for GitOps)

---

## 5. Kubernetes Pods and Container Types

### 5.1 What Is a Pod?

* A **Pod** is the smallest deployable unit in Kubernetes, representing one or more containers that:

   * Share a network namespace (one IP, one port space).
   * Share storage volumes.
* Pods model an application-specific “logical host.” When a Pod runs multiple containers, those containers can communicate over `localhost` and share mounted volumes.

**Simple Pod Example**:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.21
    ports:
    - containerPort: 80
```

Apply:

```bash
kubectl apply -f pod-demo.yaml
kubectl get pods
kubectl describe pod nginx-pod
```

### 5.2 Pod Lifecycle Phases

1. **Pending**: Pod object exists, but containers not scheduled or images not pulled yet.
2. **Running**: At least one container is running; others may be initializing.
3. **Succeeded**: All containers have terminated successfully (exit code 0), and the Pod is not configured to restart.
4. **Failed**: At least one container terminated with a non-zero exit code and is not restarting.
5. **Unknown**: The control plane lost communication with the node.

#### Pod Conditions

* **PodScheduled**: Pod is scheduled to a node.
* **Ready**: All containers (including init & sidecars) are ready.
* **ContainersReady**: Application containers are ready (probes passing).
* **Initialized**: All init containers have completed successfully.

View a Pod’s phase and conditions with:

```bash
kubectl describe pod nginx-pod
```

### 5.3 Init Containers

* Run **before** any application containers.
* Defined under `spec.initContainers`. Execute sequentially; each must exit 0 before the next starts.
* Common Uses:

   1. Populate volumes (e.g., fetch config/secrets).
   2. Verify preconditions (e.g., wait for a database).
   3. Generate artifacts (e.g., certificates).
* **Characteristics**:

   * Run sequentially (`initContainers[0]` → `initContainers[1]` → …).
   * If an init container fails (non-zero exit), Kubernetes restarts it until success (unless `restartPolicy: Never`).
   * Cannot have probes (liveness/readiness).
   * Use volumes (e.g., `emptyDir`) to share data with main containers.

**Init Container Example**:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example-init-pod
spec:
  volumes:
    - name: shared-data
      emptyDir: {}
  initContainers:
    - name: init-fetch-config
      image: bitnami/kubectl:1.27.6
      command:
        - sh
        - -c
        - |
          echo "config_value=42" > /mnt/shared/config.env
      volumeMounts:
        - name: shared-data
          mountPath: /mnt/shared
    - name: init-wait-for-db
      image: busybox:1.35
      command:
        - sh
        - -c
        - |
          until nc -z db-service 5432; do
            echo "Waiting for database..."
            sleep 3
          done
      resources:
        requests:
          cpu: "50m"
          memory: "20Mi"
  containers:
    - name: app
      image: myapp:latest
      env:
        - name: CONFIG_VALUE
          valueFrom:
            configMapKeyRef:
              name: dynamic-config
              key: config_value
      volumeMounts:
        - name: shared-data
          mountPath: /etc/app/config
      ports:
        - containerPort: 8080
  restartPolicy: OnFailure
```

* `init-fetch-config`: writes `/mnt/shared/config.env`.
* `init-wait-for-db`: polls `db-service:5432`.
* Once both finish, the main container runs with data in `/etc/app/config`.

### 5.4 Sidecar Containers

* Run **concurrently** with the main application containers.
* Provide supporting functionality:

   * Logging/metrics exporters.
   * Proxies (e.g., Envoy/Istio).
   * Certificate or credential refreshers.
   * Data synchronization (e.g., S3 sync).
* **Implementation** (since v1.29, feature stabilized):

   * Defined under `spec.initContainers` with a `restartPolicy` other than `Never`, causing them to run alongside application containers.
   * Support probes (`liveness`, `readiness`).
   * Terminated **after** application containers on Pod shutdown (reverse order).

**Sidecar Example: Log Forwarding**:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  labels:
    app: webapp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      volumes:
        - name: log-volume
          emptyDir: {}
      initContainers:
        - name: log-collector
          image: fluent/fluentd:latest
          command:
            - sh
            - -c
            - |
              fluentd -c /fluentd/etc/fluent.conf
          volumeMounts:
            - name: log-volume
              mountPath: /var/log/app
          restartPolicy: Always
      containers:
        - name: app
          image: my-web-app:1.2.3
          command:
            - sh
            - -c
            - |
              while true; do echo "Request at $(date)" >> /var/log/app/access.log; sleep 2; done
          volumeMounts:
            - name: log-volume
              mountPath: /var/log/app
          ports:
            - containerPort: 8080
```

* Sidecar `log-collector` tails logs from `/var/log/app` and forwards to a remote backend.
* If `log-collector` or `app` crashes, Kubernetes restarts them.

### 5.5 Ephemeral Containers

* **Injected on-demand** into a running Pod for debugging or diagnostics.
* Do **not** restart automatically; run only once (until Pod is deleted/replaced).
* Cannot have probes, ports, resource requests/limits, or lifecycle hooks (existing Pod’s resources are immutable).
* Use `kubectl debug`:

  ```bash
  kubectl debug <pod-name> --image=busybox:1.35 --target=<container-name> -it -- /bin/sh
  ```

   * `--target=<container-name>`: shares network/PID/IPC namespaces of target container.
* **Use Cases**:

   * Attach a shell to a Pod with no shell.
   * Inspect crashed container’s filesystem or logs.
   * Run profiling tools (e.g., `strace`, `top`).

**Ephemeral Container Example**:

```bash
kubectl run pause-pod \
  --image=registry.k8s.io/pause:3.6 \
  --restart=Never \
  -- sleep 3600

# Add ephemeral container
kubectl debug pause-pod \
  --image=busybox:1.35 \
  --name=debugger \
  --target=pause \
  -it -- /bin/sh
```

* `kubectl describe pod pause-pod` shows:

  ```
  Ephemeral Containers:
    debugger:
      Image: busybox:1.35
      Command: sh -c -- /bin/sh
      TargetContainerName: pause
      State: Running
  ```
* Once you exit the shell, the ephemeral container terminates. Its status remains until Pod deletion.

### 5.6 Pod Startup & Shutdown Sequence

1. **Init Containers** (sequential):

   * Run each init container; if one fails, it restarts until exit 0 (unless `restartPolicy: Never`).
2. **Sidecar Containers** (if any):

   * Start alongside application containers (begin after init containers start).
   * Contribute to overall Pod readiness if they have readiness probes.
3. **Application Containers**:

   * Start once init containers finish; run concurrently with sidecars.
4. **Pod Phase: Running**

   * Pod is “Ready” when all containers (app + sidecars with readiness probes) are ready.
5. **Termination (Ordered)**:

   1. **Application Containers**: receive `SIGTERM` first.
   2. **Sidecar Containers**: receive `SIGTERM` next, ensuring they remain to service any cleanup tasks (e.g., log forwarding).
   3. Kubernetes waits up to `terminationGracePeriodSeconds` (default 30s) before sending `SIGKILL`.

---

## 6. ReplicationController

### 6.1 Purpose

* A **ReplicationController (RC)** ensures a specified number of pod replicas run at all times.
* Watches pods matching its selector; if actual count < desired, it creates new pods; if > desired, it deletes extras.
* **Legacy**: Largely superseded by ReplicaSets and Deployments but important to understand self-healing and scaling concepts.

### 6.2 Anatomy of an RC Manifest

```yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: nginx-rc
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx-container
        image: nginx:1.14.2
        ports:
        - containerPort: 80
```

* **`spec.replicas: 3`**: Desired replica count.
* **`spec.selector: app: nginx`**: Matches any pod with `metadata.labels.app=nginx`.
* **`spec.template`**: Defines how to create new pods (including the same label so they immediately match the selector).

### 6.3 RC Control Loop

1. Count pods matching selector (and not marked for deletion).
2. If `currentCount < desiredCount`, create new pods (using template).
3. If `currentCount > desiredCount`, delete surplus pods (graceful `SIGTERM` → `SIGKILL` if necessary).

If a pod or node fails, RC sees a deficit and spins up replacements.

### 6.4 Management with `kubectl`

* **Create**

  ```bash
  kubectl apply -f rc.yaml
  ```
* **View**

  ```bash
  kubectl get rc
  kubectl get pods -l app=nginx
  kubectl describe rc nginx-rc
  ```
* **Scale**

  ```bash
  kubectl scale rc nginx-rc --replicas=5
  # or edit rc.yaml and kubectl apply -f rc.yaml
  ```
* **Delete**

  ```bash
  kubectl delete rc nginx-rc
  ```

   * By default, pods are also deleted (cascade).
   * Use `--cascade=false` to keep pods and orphan them.

### 6.5 Comparison: RC vs. ReplicaSet vs. Deployment

* **ReplicationController**:

   * Only equality-based selectors (`key=value`).
   * No rolling updates, no revision history.
* **ReplicaSet**:

   * Supports set-based selectors (`in`, `notin`).
   * Largely replaces RC.
* **Deployment**:

   * Manages ReplicaSets underneath.
   * Rolling updates, automatic rollbacks, revision history.

---

## 7. ReplicaSet

### 7.1 Purpose

* A **ReplicaSet** (RS) ensures **N** replicas of pods run at any time.
* Similar to RC but with more flexible selectors.
* Typically created and managed by Deployments.

### 7.2 Anatomy of a RS Manifest

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-rs
  labels:
    app: nginx
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
        image: nginx:1.21.0
        ports:
        - containerPort: 80
```

* **`spec.selector.matchLabels`**: Label selector (supports equality and set-based selectors).
* **Pod Template** must have matching labels.

### 7.3 RS Control Loop

1. Count pods matching selector (without an `ownerReference` or orphan).
2. If `currentCount < desiredCount`, create missing pods.
3. If `currentCount > desiredCount`, delete extra pods.

Pods created by RS have an `ownerReference` pointing to the RS, so RS knows exactly which pods it owns.

### 7.4 Management with `kubectl`

* **Create**

  ```bash
  kubectl apply -f rs.yaml
  ```
* **View**

  ```bash
  kubectl get rs
  kubectl get pods -l app=nginx
  kubectl describe rs nginx-rs
  ```
* **Scale**

  ```bash
  kubectl scale rs nginx-rs --replicas=5
  ```
* **Delete**

  ```bash
  kubectl delete rs nginx-rs
  ```

   * By default, deletes pods (cascade).
   * Use `--cascade=false` to orphan pods.

### 7.5 When to Use RS Directly

* Rare in modern clusters—Deployments are preferred.
* Use RS directly when:

   * You need a low-level controller without rolling-update history.
   * Workloads are immutable and don’t require rolling updates.

### 7.6 Comparison: RS vs. RC vs. Deployment

* **ReplicaSet** supports set‐based selectors.
* **ReplicationController** only supports equality‐based selectors.
* **Deployment** manages RS(es) for rolling updates, rollback, version history.

---

## 8. DaemonSet

### 8.1 Purpose

* Ensures exactly one copy of a Pod runs on **all** (or a subset of) nodes.
* Ideal for node‐level services: logging agents, monitoring daemons, network plugins.

### 8.2 Anatomy of a DaemonSet Manifest

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd-elasticsearch
  namespace: kube-system
  labels:
    k8s-app: fluentd-logging
spec:
  selector:
    matchLabels:
      name: fluentd-elasticsearch
  template:
    metadata:
      labels:
        name: fluentd-elasticsearch
    spec:
      tolerations:
        - key: node-role.kubernetes.io/control-plane
          operator: Exists
          effect: NoSchedule
        - key: node-role.kubernetes.io/master
          operator: Exists
          effect: NoSchedule
      containers:
        - name: fluentd-elasticsearch
          image: quay.io/fluentd_elasticsearch/fluentd:v2.5.2
          resources:
            requests:
              cpu: 100m
              memory: 200Mi
            limits:
              memory: 200Mi
          volumeMounts:
            - name: varlog
              mountPath: /var/log
      terminationGracePeriodSeconds: 30
      volumes:
        - name: varlog
          hostPath:
            path: /var/log
```

* **`spec.selector.matchLabels`** and **`template.metadata.labels`** must match exactly.
* **`clusterIP: None`** headless Service is not required here (daemon pods don’t need stable DNS names).
* **Tolerations** allow scheduling to tainted nodes (e.g., control-plane).

### 8.3 DaemonSet Scheduling

1. **Existing Nodes**: On apply, controller creates a Pod on each eligible node (matching `nodeSelector`/`affinity` and tolerations).
2. **New Nodes**: When nodes join, controller automatically schedules a Pod on each.
3. **Node Removal**: When a node leaves or is drained, its DaemonSet Pod is garbage-collected.

### 8.4 Advanced Scheduling Controls

* **`nodeSelector` / `affinity`**: Limit which nodes run pods.

  ```yaml
  spec:
    template:
      spec:
        nodeSelector:
          hardware-type: high-memory
  ```
* **`tolerations`**: Allow pods on nodes with taints.
* **`priorityClassName`**: Guarantee critical daemons preempt less important pods.

### 8.5 Managing DaemonSets

* **Create/Apply**

  ```bash
  kubectl apply -f daemonset.yaml
  ```
* **List**

  ```bash
  kubectl get daemonsets --all-namespaces
  kubectl get pods -l name=fluentd-elasticsearch -n kube-system
  ```
* **Describe**

  ```bash
  kubectl describe daemonset fluentd-elasticsearch -n kube-system
  ```
* **Update** (RollingUpdate is default)

  ```yaml
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  ```

  Edit `image:` or other container fields and re-apply; DaemonSet replaces pods one at a time per `maxUnavailable`.
* **Delete**

  ```bash
  kubectl delete daemonset fluentd-elasticsearch -n kube-system
  ```

   * By default, pods are deleted (cascade).
   * `--cascade=false` keeps pods orphaned (rarely recommended).

### 8.6 Comparison to Other Controllers

| Feature                 | Deployment                     | ReplicaSet/RC              | DaemonSet                          |
| ----------------------- | ------------------------------ | -------------------------- | ---------------------------------- |
| **Scale Model**         | N replicas (any nodes)         | N replicas (any nodes)     | One-per eligible node              |
| **Rolling Updates**     | Built‐in                       | N/A                        | Built‐in via `updateStrategy`      |
| **Use Case**            | Stateless apps (web/API)       | Basic replication (legacy) | Node-level services (logging)      |
| **Selector Mutability** | Immutable in ReplicaSet        | Immutable                  | Immutable                          |
| **Pod Scheduling**      | Default scheduler chooses node | Same                       | Controller binds pods to each node |

---

## 9. Jobs

### 9.1 Purpose

* **Jobs** run one‐time or finite tasks until successful completion rather than long‐running services.
* Ensure a specified number of pods terminate successfully.
* **Use Cases**: Batch processing, data migrations, backups, one‐off scripts.

### 9.2 Anatomy of a Job Manifest

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: hello-job
spec:
  completions: 1        # Number of successful pod completions before Job succeeds
  parallelism: 1        # Number of pods to run in parallel
  template:
    metadata:
      name: hello-pod
    spec:
      restartPolicy: OnFailure   # OnFailure or Never
      containers:
      - name: hello
        image: busybox:1.35
        command:
        - /bin/sh
        - -c
        - |
          echo "Hello, World!"
```

* **`completions`**: Total successes required (default 1).
* **`parallelism`**: Max concurrent pods (default 1).
* **`completionMode`** (v1.21+):

   * `NonIndexed` (default): No unique index; pods are fungible.
   * `Indexed`: Pods receive `JOB_COMPLETION_INDEX` in `metadata.annotations` (0 → `completions−1`) for deterministic sharding.
* **`backoffLimit`**: Number of retries after failure before marking Job `Failed` (default 6).
* **`activeDeadlineSeconds`**: Overall Job timeout in seconds.
* **`ttlSecondsAfterFinished`** (v1.21+): TTL for cleaning up Job and pods after completion.

### 9.3 Job Lifecycle & Status

* **Active**: Number of currently running pods (`status.active`).
* **Succeeded**: Count of pods that finished with exit 0 (`status.succeeded`).
* **Failed**: Count of pods that exited non-zero (`status.failed`).
* **Completion**: Once `status.succeeded == spec.completions`, Job is marked **Complete**.
* **Failure**: If `status.failed > spec.backoffLimit`, Job is marked **Failed**.

View status:

```bash
kubectl describe job hello-job
```

### 9.4 Parallelism Patterns

1. **Sequential Job (non-parallel)**

   ```yaml
   kind: Job
   spec:
     template:
       spec:
         restartPolicy: OnFailure
         containers:
         - name: task
           image: alpine
           command: ["sh", "-c", "echo 'Task complete'; exit 0"]
   ```
2. **Parallel Non-Indexed (work queue)**

   ```yaml
   spec:
     completions: 10
     parallelism: 4
     backoffLimit: 3
     template:
       spec:
         restartPolicy: OnFailure
         containers:
         - name: worker
           image: myregistry/worker:latest
           env:
           - name: QUEUE_NAME
             value: "tasks-queue"
   ```

   * Maintains up to 4 pods concurrently; total of 10 successful completions.
3. **Parallel Indexed (deterministic sharding)**

   ```yaml
   spec:
     completions: 5
     parallelism: 5
     completionMode: Indexed
     template:
       spec:
         restartPolicy: Never
         containers:
         - name: shard-worker
           image: myregistry/shard-worker:latest
           env:
           - name: JOB_COMPLETION_INDEX
             valueFrom:
               fieldRef:
                 fieldPath: metadata.annotations['batch.kubernetes.io/job-completion-index']
   ```

   * Creates 5 pods up front, each with index 0 → 4 in `annotations`. Each processes a unique shard.

### 9.5 Managing Jobs with `kubectl`

* **Create**

  ```bash
  kubectl apply -f job.yaml
  ```
* **List Jobs**

  ```bash
  kubectl get jobs
  # NAME            COMPLETIONS   DURATION   AGE
  # hello-job       1/1           5s         1m
  ```
* **Describe**

  ```bash
  kubectl describe job parallel-job
  ```
* **Get Pod Logs**

  ```bash
  kubectl logs job/hello-job
  # or for parallel jobs:
  kubectl get pods -l job-name=parallel-job
  kubectl logs <pod-name>
  ```
* **Scale/Update**

   * Jobs are immutable for `completions`/`parallelism`; to change, delete and recreate.
   * Can patch `backoffLimit` or `activeDeadlineSeconds`:

     ```bash
     kubectl patch job parallel-job -p '{"spec":{"backoffLimit":10}}'
     ```
* **Delete**

  ```bash
  kubectl delete job parallel-job
  ```

   * Cascades by default (deletes pods). Use `--cascade=false` to orphan pods.

### 9.6 Best Practices

1. **Choose Completion Mode**

   * **NonIndexed** if pods can share a work queue.
   * **Indexed** if tasks must be deterministic (e.g., data shard #0 → shard #4).
2. **Idempotency**

   * In non-indexed mode, ensure tasks can run multiple times if retried.
3. **`backoffLimit` & `activeDeadlineSeconds`**

   * Adjust for failure tolerance and timeouts.
   * For long tasks, set `activeDeadlineSeconds` so they don’t run indefinitely.
4. **Cleanup Completed Jobs**

   * Use `ttlSecondsAfterFinished` (v1.21+) to auto-delete old jobs.
   * Or build a script to remove jobs older than a threshold:

     ```bash
     kubectl delete jobs --field-selector=metadata.creationTimestamp<=$(date -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ)
     ```
5. **Resources**

   * Always specify `resources.requests` (and optionally `limits`) so pods schedule correctly and don’t hog resources unexpectedly.
6. **Node Selection**

   * Use `nodeSelector` or `affinity` if jobs require special nodes (e.g., GPUS).

---

## 10. CronJob

### 10.1 Purpose

* A **CronJob** schedules **Jobs** to run at specified times/intervals, similar to Unix `cron`.
* Common for periodic tasks: nightly backups, report generation, cleanup scripts.

### 10.2 Anatomy of a CronJob Manifest

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: hello-cron
spec:
  schedule: "*/5 * * * *"   # Every 5 minutes
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
          - name: hello
            image: busybox:1.35
            command:
            - /bin/sh
            - -c
            - date; echo "Hello from Kubernetes CronJob"
```

* **`spec.schedule`**: Standard cron expression (minute, hour, day-of-month, month, day-of-week).
* **`spec.jobTemplate`**: A **JobTemplateSpec**—essentially identical to a Job’s `spec.template` (minus fields like `ownerReferences`).
* **`spec.concurrencyPolicy`** (optional):

   * `Allow` (default): multiple Jobs may run concurrently.
   * `Forbid`: skip next run if previous Job still active.
   * `Replace`: cancel currently running Job and start a new one.
* **`spec.suspend`** (optional):

   * `true`: pause scheduling; no new Jobs created.
   * `false` (default).
* **`spec.startingDeadlineSeconds`** (optional):

   * If controller misses a scheduled time (e.g., due to downtime), and current time > `scheduledTime + startingDeadlineSeconds`, skip that run.
* **`spec.failedJobsHistoryLimit`** (optional): Number of failed Job objects to retain (default 1).
* **`spec.successfulJobsHistoryLimit`** (optional): Number of successful Job objects to retain (default 3).

### 10.3 Cron Syntax & Timezones

* Cron format:

  ```
  <minute> <hour> <day-of-month> <month> <day-of-week>
  ```

   * Examples:

      * `"0 2 * * *"` → daily at 02:00.
      * `"0 0 * * 0"` → weekly on Sunday at midnight.
      * `"*/15 * * * *"` → every 15 minutes.
* To specify a timezone (cluster must support `CRON_TZ`):

  ```yaml
  spec:
    schedule: "CRON_TZ=UTC 0 23 * * *"   # Daily at 23:00 UTC
  ```

### 10.4 How the CronJob Controller Works

1. Maintains an internal schedule for next run times.
2. When `now ≥ nextScheduleTime` and not suspended:

   * Checks `concurrencyPolicy`:

      * `Allow`: always create a new Job.
      * `Forbid`: skip if any existing Job is active.
      * `Replace`: delete active Jobs and create a new one.
   * Honors `startingDeadlineSeconds`: skip if too late.
3. Created Job names:

   ```
   <cronjob-name>-<timestamp>
   ```

   e.g., `hello-cron-1696128000` (11-character suffix).
4. **OwnerReferences**: Jobs have `ownerReference` pointing to CronJob. Deleting CronJob with `ownerReference` set to foreground causes all Jobs to be garbage-collected.
5. **History Cleanup**: After Job completion (success or failure), controller deletes old Jobs beyond `successfulJobsHistoryLimit` and `failedJobsHistoryLimit`.

### 10.5 Managing CronJobs with `kubectl`

* **Create**

  ```bash
  kubectl apply -f cronjob.yaml
  ```
* **List**

  ```bash
  kubectl get cronjobs
  # NAME             SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
  # hello-cron       */5 * * * *   False     0        <none>          10m
  ```
* **Describe**

  ```bash
  kubectl describe cronjob hello-cron
  ```
* **Delete**

  ```bash
  kubectl delete cronjob hello-cron
  ```

   * Deletes CronJob; Jobs and pods may remain until cleaned by ownerReferences or TTL.

### 10.6 Common Pitfalls & Tips

1. **Missed Schedules**:

   * If controller is offline at scheduled time and `startingDeadlineSeconds` is small, missed run is skipped.
   * Increase `startingDeadlineSeconds` to allow catch-up.
2. **CronJob Not Firing**:

   * Check that `spec.suspend` is `false`.
   * Ensure schedule syntax is valid (`kubectl describe cronjob` shows parse errors).
   * Confirm controller is running on control-plane.
3. **Too Many Concurrent Jobs**:

   * If `concurrencyPolicy=Allow` and jobs take longer than cron interval, jobs accumulate.
   * Switch to `Forbid` or `Replace`.
4. **Jobs Building Up**:

   * Use `successfulJobsHistoryLimit` and `failedJobsHistoryLimit` to auto-clean old jobs.
   * Or use TTL for Jobs:

     ```yaml
     spec:
       ttlSecondsAfterFinished: 3600  # delete 1h after completion
     ```
5. **Name Length**:

   * Keep CronJob name ≤ 52 characters so generated Job names (CronJob + suffix) stay ≤ 63 characters.

### 10.7 Advanced Patterns

* **ConfigMap/Secret Injection**:
  Mount as volume in `jobTemplate` so updates to ConfigMap/Secret automatically reflect in next run.

  ```yaml
  volumes:
    - name: report-config
      configMap:
        name: report-configmap
  containers:
    - name: report-generator
      image: myregistry/reportgen:latest
      volumeMounts:
        - name: report-config
          mountPath: /etc/report
      command: ["/app/run.sh", "--config", "/etc/report/config.yaml"]
  ```
* **Dynamic Schedules**:
  For “last day of month” or complex logic, schedule a daily CronJob and include a script to check if it’s the last day:

  ```yaml
  command:
  - /bin/sh
  - -c
  - |
    TODAY=$(date +%d)
    DAYS=$(date -d "$(date +%Y-%m-01) +1 month -1 day" +%d)
    if [ "$TODAY" -eq "$DAYS" ]; then
      /app/run-month-end.sh
    else
      echo "Not last day: $TODAY/$DAYS; exiting."
      exit 0
    fi
  ```

---

## 11. StatefulSets

### 11.1 Purpose

* Designed for **stateful applications** requiring:

   1. **Stable, unique network identities** (DNS names).
   2. **Stable, persistent storage** (one PVC per pod).
   3. **Ordered, graceful scaling and updates** (ensure proper sequencing).
* Ideal for databases (MySQL, PostgreSQL, Cassandra), message brokers (Kafka, Zookeeper), and other clustered systems.

### 11.2 Core Guarantees

1. **Ordinal Index**: Pods named `<sts-name>-0`, `<sts-name>-1`, … `<sts-name>-N`.
2. **Stable Network Identity**:

   * Requires a **Headless Service** (`clusterIP: None`).
   * DNS A records:

     ```
     <sts-name>-0.<service-name>.<namespace>.svc.cluster.local
     <sts-name>-1.<service-name>.<namespace>.svc.cluster.local
     ```
3. **Persistent Storage**:

   * Using `volumeClaimTemplates`, Kubernetes creates one PVC per pod (e.g., `data-<sts-name>-0`, `data-<sts-name>-1`, …).
   * PVCs outlive pods; data persists across restarts.
4. **Ordered Creation & Deletion**:

   * **Creation**: Pods created sequentially by ordinal (0 → 1 → …).
   * **Deletion/Scale-Down**: Pods terminated in reverse ordinal order (highest → … → 0).
5. **Controlled Updates**:

   * Default `RollingUpdate` updates pods one at a time, in ordinal order, waiting for readiness before moving on.
   * Use `OnDelete` to manually control pod replacements.

### 11.3 Anatomy of a StatefulSet Manifest

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
  labels:
    app: mysql
spec:
  serviceName: "mysql-headless"   # Headless Service name (must exist)
  replicas: 3
  selector:
    matchLabels:
      app: mysql                 # Must match template labels
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - containerPort: 3306
          name: mysql
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: root-password
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
  volumeClaimTemplates:
  - metadata:
      name: data                # PVC name prefix → data-mysql-0, data-mysql-1, …
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
```

#### Key Fields

* **`serviceName`**

   * Name of a **Headless Service**.
   * Headless Service (`clusterIP: None`) enables DNS for each pod.
* **`volumeClaimTemplates`**

   * Creates one `PersistentVolumeClaim` per pod.
   * PVC names: `<template-name>-<statefulset-name>-<ordinal>`, e.g., `data-mysql-0`.
* **Pod Template**

   * `metadata.labels` must match `spec.selector.matchLabels`.
   * Pods mount PVC named `data` at `/var/lib/mysql`.
* **`spec.updateStrategy`** (optional)

   * Default: `type: RollingUpdate` (one pod at a time).
   * `rollingUpdate.partition`: Defines ordinal index from which to update (useful for canary rollouts).
* **`podManagementPolicy`** (optional)

   * `OrderedReady` (default): Pods created/updated/deleted strictly in ordinal order.
   * `Parallel`: Allows simultaneous create/delete across ordinals.

### 11.4 Headless Service for StatefulSet

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql-headless
  labels:
    app: mysql
spec:
  clusterIP: None           # Headless → no cluster IP assigned
  selector:
    app: mysql
  ports:
  - port: 3306
    name: mysql
```

* Creates DNS records for each pod:

  ```
  mysql-0.mysql-headless.default.svc.cluster.local
  mysql-1.mysql-headless.default.svc.cluster.local
  mysql-2.mysql-headless.default.svc.cluster.local
  ```

### 11.5 Persistent Storage with `volumeClaimTemplates`

* **Dynamic provisioning**: Specify `storageClassName` (e.g., `fast-ssd`) so PVC is bound to an appropriate PV.

  ```yaml
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      storageClassName: fast-ssd
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
  ```
* **PVC Lifecycle**:

   * PVC is created when pod ordinal 0 starts, then ordinal 1, then ordinal 2.
   * PVC remains even if the pod is deleted.
   * To reuse data on re-creation, keep PVCs intact.
   * To delete PVCs, remove them manually (StatefulSet deletion does NOT automatically delete PVCs).

### 11.6 Pod Lifecycle & Update Strategy

1. **Creation (`OrderedReady`)**:

   * Create `mysql-0` → wait until ready (readiness probe) → create `mysql-1` → wait until ready → create `mysql-2`.
2. **Rolling Update (`RollingUpdate`)**:

   * Default: Update pods in ascending ordinal order.

      1. Delete `mysql-2` → wait for new `mysql-2` to be **Ready**.
      2. Delete `mysql-1` → wait for new `mysql-1`.
      3. Delete `mysql-0` → wait for new `mysql-0`.
   * **Partitioned Update**:

     ```yaml
     updateStrategy:
       type: RollingUpdate
       rollingUpdate:
         partition: 1
     ```

      * Pods with ordinal ≥ 1 updated (e.g., update `mysql-1`, then `mysql-2`); `mysql-0` remains on the old version.
3. **OnDelete Update Strategy**:

   ```yaml
   updateStrategy:
     type: OnDelete
   ```

   * New pod created only when you manually delete an old pod (e.g., `kubectl delete pod mysql-0`).
   * Gives manual control over when each pod is replaced.

### 11.7 Scaling

* **Scale Up** (e.g., 3 → 5 replicas):

   * Create `mysql-3` → wait until ready → create `mysql-4`.
* **Scale Down** (e.g., 5 → 2 replicas):

   * Delete `mysql-4` → delete `mysql-3`.
   * PVCs (`data-mysql-3`, `data-mysql-4`) persist (status becomes `Released`).
   * If re-scaled to 5 later, pods rebind to existing PVCs.

### 11.8 Common StatefulSet Use Cases

1. **Databases**: MySQL, MariaDB, PostgreSQL (primary/replica); require stable hostnames & persistent volumes.
2. **Distributed Data Stores**: Cassandra, MongoDB, Elasticsearch (each node needs a stable identity and storage).
3. **Message Brokers/Coordination**: Kafka, Zookeeper, etcd clusters.
4. **Leader/Election Workloads**: Consul, Vault (leader needs a stable address).

### 11.9 Best Practices & Considerations

1. **`podManagementPolicy`**:

   * Use `OrderedReady` for workloads where strict ordering matters.
   * Use `Parallel` for faster scale-up/down if ordering is not critical.
2. **StorageClass & PVC Availability**:

   * Ensure enough PVs or dynamic provisioning to satisfy PVCs (e.g., 3 PVCs for a 3-replica StatefulSet).
   * If a PVC is pending, corresponding pod remains in `Pending` state, blocking sequential creation.
3. **PersistentVolume Reclaim Policy**:

   * Default for dynamically provisioned PVs is `Delete` (PV deleted when PVC is deleted).
   * If you want to preserve data after StatefulSet deletion, set reclaim policy to `Retain` or remove PVCs manually.
4. **Readiness Probes**:

   * Include readiness checks (e.g., MySQL: `SELECT 1`) so pods only signal readiness when fully healthy.
   * Example:

     ```yaml
     readinessProbe:
       exec:
         command:
         - /usr/bin/mysql
         - -uroot
         - -p$(MYSQL_ROOT_PASSWORD)
         - -e
         - "SELECT 1"
       initialDelaySeconds: 30
       periodSeconds: 10
     ```
5. **DNS & Client Access**:

   * For clients connecting to the primary/leader, use the DNS `mysql-0.mysql-headless.default.svc.cluster.local`.
   * For peer discovery, use headless SRV records (e.g., `_mysql._tcp.mysql-headless.default.svc.cluster.local`).
6. **Resource Requests/Limits**:

   * Always define `resources.requests` to ensure pods schedule correctly (e.g., CPU, memory).
7. **Cleanup PVCs Carefully**:

   * Deleting PVCs without care can cause data loss.
   * If you want fresh volumes, delete PVCs before re-creating StatefulSet.
8. **Rolling Updates & Recovery**:

   * If readiness fails for a new pod, StatefulSet halts updates.
   * To manually recover, you can switch to `OnDelete` and recreate pods one by one.

---

## 12. Deployments

### 12.1 Purpose

* A **Deployment** manages **stateless** workloads by creating and maintaining a **ReplicaSet**.
* Provides:

   * **Rolling updates**: Gradual replacement of pods to new versions with zero-downtime (when configured properly).
   * **Rollbacks**: Revert to a previous ReplicaSet if a rollout fails.
   * **Revision history**: Track previous versions; configurable limit (`revisionHistoryLimit`).

### 12.2 Anatomy of a Deployment Manifest

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
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
        image: nginx:1.21.0
        ports:
        - containerPort: 80
```

* **`spec.replicas`**: Desired number of pods (default 1 if omitted).
* **`spec.selector.matchLabels`**: Label selector that matches pods created by this Deployment; must match `template.metadata.labels`.
* **`spec.template`**: Pod template (metadata + spec) including containers, volumes, probes, etc.

### 12.3 Update Strategy

By default:

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 25%
    maxSurge: 25%
```

* **`maxUnavailable`**: Maximum pods that can be unavailable during update.
* **`maxSurge`**: Maximum extra pods (beyond desired replicas) that can be created during update.

Adjust for zero-downtime:

```yaml
rollingUpdate:
  maxUnavailable: 0
  maxSurge: 1
```

* Ensures new pods come up before old pods terminate.

### 12.4 Deployment Lifecycle

1. **Creation**

   * `kubectl apply -f deployment.yaml`.
   * Kubernetes creates a new ReplicaSet (e.g., `nginx-deployment-5f4c8f7b9f`).
   * ReplicaSet creates pods to match `spec.replicas`.
2. **Rolling Update**

   * Modify `spec.template.spec.containers[0].image` (e.g., `nginx:1.21.0` → `nginx:1.22.0`).
   * Re-apply or patch triggers a new ReplicaSet (e.g., `nginx-deployment-6a8df3e7a2`).
   * New ReplicaSet scales up (`maxSurge`) while old ReplicaSet scales down (`maxUnavailable`).
   * Waits for new pods to be ready before continuing.
3. **Monitoring Rollout**

   ```bash
   kubectl rollout status deployment/nginx-deployment --timeout=10m
   ```

   * Shows progress; if stalled `progressDeadlineSeconds` (default 600s) passes, deployment is marked failed.
4. **Rollback**

   ```bash
   kubectl rollout undo deployment/nginx-deployment
   ```

   * Reverts to previous ReplicaSet in a rolling fashion.
   * Use `kubectl rollout history deployment/nginx-deployment` to view revisions.

### 12.5 Scaling

* **Imperative**:

  ```bash
  kubectl scale deployment/nginx-deployment --replicas=5
  ```
* **Declarative**:

   * Edit `spec.replicas: 5` in the YAML file and re-apply:

     ```bash
     kubectl apply -f nginx-deployment.yaml
     ```

### 12.6 Health Probes

* **Liveness Probe**: Restarts container if it becomes unresponsive or unhealthy.
* **Readiness Probe**: Signals when a container is ready to serve traffic.
* **Startup Probe** (v1.18+): Ensures container starts within expected time before liveness/readiness kick in.

Example readiness probe:

```yaml
readinessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 10
```

### 12.7 Advanced Deployment Features

1. **Pause & Resume Rollouts**

   ```bash
   kubectl rollout pause deployment/nginx-deployment
   # Make multiple edits
   kubectl rollout resume deployment/nginx-deployment
   ```
2. **Set Image via CLI**

   ```bash
   kubectl set image deployment/nginx-deployment nginx=nginx:1.23.0
   ```
3. **Pod Anti-Affinity**
   Spread pods across nodes:

   ```yaml
   spec:
     template:
       spec:
         affinity:
           podAntiAffinity:
             requiredDuringSchedulingIgnoredDuringExecution:
               - labelSelector:
                   matchLabels:
                     app: nginx
                 topologyKey: "kubernetes.io/hostname"
   ```
4. **Horizontal Pod Autoscaler (HPA)**
   Automatically adjust replicas based on metrics:

   ```yaml
   apiVersion: autoscaling/v2
   kind: HorizontalPodAutoscaler
   metadata:
     name: nginx-hpa
   spec:
     scaleTargetRef:
       apiVersion: apps/v1
       kind: Deployment
       name: nginx-deployment
     minReplicas: 3
     maxReplicas: 10
     metrics:
     - type: Resource
       resource:
         name: cpu
         target:
           type: Utilization
           averageUtilization: 50
   ```
5. **Pod Disruption Budget (PDB)**
   Ensure minimum availability during voluntary disruptions (e.g., node upgrades):

   ```yaml
   apiVersion: policy/v1
   kind: PodDisruptionBudget
   metadata:
     name: nginx-pdb
   spec:
     maxUnavailable: 1
     selector:
       matchLabels:
         app: nginx
   ```

---

## 13. Managing Workloads End-to-End

Putting together all elements—from local development with Kind, on-prem clusters with kubeadm, object management, to controllers—enables robust, production-grade deployments.

### 13.1 Organizing Resource Configurations

* **Multi‐Document YAML**: Combine multiple related objects (Deployment, Service, ConfigMap) in one file separated by `---`.

  ```yaml
  apiVersion: v1
  kind: Service
  metadata:
    name: my-nginx-svc
    labels:
      app: nginx
  spec:
    selector:
      app: nginx
    ports:
      - port: 80
  ---
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: my-nginx
    labels:
      app: nginx
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
            image: nginx:1.14.2
            ports:
              - containerPort: 80
  ```
* **Directory Hierarchy & Recursion**:

  ```bash
  project/k8s/
    ├── configmap/
    │   └── my-configmap.yaml
    ├── deployment/
    │   └── my-deployment.yaml
    └── pvc/
        └── my-pvc.yaml
  kubectl apply -f project/k8s/ --recursive
  ```

### 13.2 Scaling Applications

* Use `kubectl scale` or update `spec.replicas`.
* Combine with HPA for automated scaling based on CPU/memory.

### 13.3 Zero-Downtime Updates

* **Deployments** with RollingUpdate strategy.
* Adjust `maxUnavailable` and `maxSurge`:

   * To ensure no downtime:

     ```yaml
     rollingUpdate:
       maxUnavailable: 0
       maxSurge: 1
     ```
* **Monitor**:

  ```bash
  kubectl rollout status deployment/my-app
  ```
* **Health Probes** ensure new pods are only considered Ready when truly healthy.

### 13.4 Rollouts & Rollbacks

* **Pause/Resume** for batching multi-step changes.
* **Rollback** to last revision on failures:

  ```bash
  kubectl rollout undo deployment/my-app
  ```

### 13.5 Canary Deployments

1. **Stable Deployment** (e.g., 3 replicas, `track=stable`).
2. **Canary Deployment** (e.g., 1 replica, `track=canary`).
3. **Service** selects on shared labels (excluding `track`), e.g.:

   ```yaml
   spec:
     selector:
       app: guestbook
       tier: frontend
   ```
4. Traffic split ≈ `canaryReplicas / (stableReplicas + canaryReplicas)`.
5. Increase canary replicas to shift more traffic; eventually promote or roll back.

### 13.6 Using Helm for Packaging & Upgrades

* **Install Chart**:

  ```bash
  helm repo add bitnami https://charts.bitnami.com/bitnami
  helm install my-nginx bitnami/nginx
  ```
* **Upgrade Chart**:

  ```bash
  helm upgrade my-nginx bitnami/nginx --set image.tag=1.21.0
  ```
* **Rollback**:

  ```bash
  helm rollback my-nginx 1
  ```
* Helm charts group multiple resources, support templating with `values.yaml`, and maintain release history.

---

## 14. Summary of Key Concepts

* **Local Clusters (Kind)**: Run Kubernetes inside Docker for fast local development and CI.
* **On-Prem Clusters (kubeadm)**: Set up a production-like cluster on Linux machines, including CRI installation, kubeadm init/join, and CNI plugins.
* **Object Management**: Declarative approach using YAML/JSON; create/update/delete with `kubectl apply`, `kubectl get`, `kubectl describe`, `kubectl delete`.
* **Labels & Selectors**: Key/value metadata for grouping and selecting objects.
* **Namespaces**: Logical partitions; use for environment, team isolation, and resource quotas.
* **Annotations**: Non-identifying metadata for tooling and documentation.
* **Common Labels**: Standard label keys under `app.kubernetes.io/` to promote consistency.
* **Pods & Container Types**:

   * **Init Containers**: Pre‐startup tasks (sequential).
   * **Sidecar Containers**: Run alongside main containers to provide auxiliary functions.
   * **Ephemeral Containers**: Injected for debugging; non‐restartable.
* **Controllers**:

   1. **ReplicationController**: Legacy controller for N replicas (use for foundational concepts).
   2. **ReplicaSet**: Ensures N replicas; supports set-based selectors; usually managed by Deployments.
   3. **DaemonSet**: Ensures one pod per node for node-level services.
   4. **Job**: Runs pods to completion (finite tasks).
   5. **CronJob**: Schedules Jobs on cron-like schedules.
   6. **StatefulSet**: Manages stateful applications requiring stable identities and storage.
   7. **Deployment**: Preferred for stateless apps; provides rolling updates, rollback, self-healing.
* **Workload Management**:

   * Use multi‐document YAML or recursive apply for managing grouped resources.
   * Scale and update apps via Deployments (scale, rolling update, rollback).
   * Use canary patterns (duplicate Deployments with label variants) for gradual rollouts.
   * Leverage Helm for packaging, templating, and streamlined upgrades.
