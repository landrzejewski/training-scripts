## 1. Local Cluster with Docker and Kind

### 1.1 What Is Kind?

* **Kind** (short for “Kubernetes IN Docker”) is a tool for running one or more Kubernetes clusters inside Docker containers.
* Each Kind “node” is in fact a Docker container running `kubelet`, `kube-proxy`, and a CRI (e.g., containerd).
* Kind is extremely fast to spin up and tear down since you don’t need to provision VMs or physical machines—everything lives 
* inside Docker containers on your local host. This makes it great for CI/CD pipelines, local testing, and learning purposes.

### 1.2 Prerequisites

1. **Docker**

    * A working Docker engine (version ≥ 19.03 recommended).
    * Your user must be able to run Docker commands (e.g., membership in the `docker` group or root privileges).

2. **Kind**

    * Download the Kind binary from its GitHub releases and make it executable. For example:

      ```bash
      curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
      chmod +x ./kind
      sudo mv ./kind /usr/local/bin/kind
      ```
    * (Check [https://github.com/kubernetes-sigs/kind/releases](https://github.com/kubernetes-sigs/kind/releases) for the latest version number.)

3. **kubectl**

    * The Kubernetes CLI—needed to inspect and interact with your Kind cluster. For example:

      ```bash
      curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
      chmod +x kubectl
      sudo mv kubectl /usr/local/bin/
      ```
    * Verify with `kubectl version --client` to ensure it’s installed correctly.

4. **Operating System**

    * Any modern Linux distribution (Ubuntu, Debian, CentOS, Fedora, etc.) with kernel ≥ 4.19 (to support the necessary cgroup features).
    * In practice, Kind also works inside WSL2 (Windows) or Docker Desktop on macOS because Docker is available there.

### 1.3 Creating a Simple Kind Cluster

Once Docker, Kind, and kubectl are installed:

1. **Create a default cluster named `kind-dev`**

   ```bash
   kind create cluster --name kind-dev
   ```

    * By default, Kind will download (or reuse if already present) the node image (e.g., `kindest/node:v1.27.3`).
    * It then creates one “control-plane” container (running the API server, etcd, controller-manager, scheduler, kubelet, kube-proxy) and one “worker” container.
    * Kind automatically sets up a Docker network so these containers can communicate.
    * It writes a new kubeconfig context (`kind-kind-dev`) into your `~/.kube/config`.

2. **Verify the cluster is up**

   ```bash
   kubectl cluster-info --context kind-kind-dev
   kubectl get nodes
   ```

   You should see output like:

   ```
   NAME                         STATUS   ROLES           AGE     VERSION
   kind-dev-control-plane       Ready    control-plane   1m      v1.27.3
   kind-dev-worker              Ready    <none>          1m      v1.27.3
   ```

   That confirms both the control-plane node and the worker node are running (inside Docker).

3. **Run a sample Deployment**
   For example, create a namespace and deploy an NGINX pod:

   ```bash
   kubectl create namespace demo --context kind-kind-dev
   kubectl apply -n demo -f https://k8s.io/examples/application/deployment.yaml --context kind-kind-dev
   kubectl get pods -n demo --context kind-kind-dev
   ```

   You should see the NGINX pods coming up. Because this is all inside Docker, networking is internal to the Docker bridge.

4. **Customize the Kind cluster**
   You can supply a YAML configuration file to control how many nodes you want, port mappings, taints, etc. For example, save this as `kind-cluster.yaml`:

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
     disableDefaultCNI: false
   ```

   Then create the cluster with:

   ```bash
   kind create cluster --name dev-cluster --config kind-cluster.yaml
   ```

   This example makes a control-plane and two workers, and also maps your host’s port 80 to port 30080 on the control-plane container so you can directly hit Services exposed on port 80.

5. **Expose a Service externally**
   If you want your demo to be reachable from your host at port 80, you can, for instance, create a Service of type `NodePort` or `LoadBalancer` (though “LoadBalancer” in Kind doesn’t provision a real LB—it ends up being a NodePort). Because of the `extraPortMappings` above, traffic to your host’s port 80 gets directed into the control-plane container’s port 30080, and then `kube-proxy`/iptables will route it to a pod port.

6. **Advantages and Limitations of Kind**

    * **Advantages**:

        * Extremely fast to start and tear down clusters.
        * Very low resource overhead (only Docker containers).
        * Perfect for CI/CD pipelines: spin up a cluster, run tests, destroy it.
    * **Limitations**:

        * Not intended for production (because it’s not running full VMs).
        * Networking is limited to Docker’s virtual bridge, so you can’t easily simulate complicated network topologies.
        * You cannot easily attach multiple physical NICs or advanced firewall rules to these containerized “nodes.”

### 1.4 Additional Tips for Kind

* **Updating the Node Image**
  Kind uses images like `kindest/node:vX.Y.Z`. To use a newer Kubernetes version, specify `--image kindest/node:vX.Y.Z` or update the `kind-cluster.yaml` accordingly.

* **Multiple Clusters & Contexts**
  If you create several clusters (`kind-dev`, `kind-staging`, etc.), they all live in your `~/.kube/config` with different contexts. You can switch contexts by running:

  ```bash
  kubectl config use-context kind-dev
  ```

* **Mounting Host Volumes**
  You can mount a host directory into a Kind node container if you need local storage. In the config:

  ```yaml
  nodes:
    - role: worker
      extraMounts:
        - hostPath: /home/user/localdata
          containerPath: /data
  ```

  Now `/home/user/localdata` on your laptop appears as `/data` inside that worker container, which pods can mount as a volume.

---

## 2. On-Premise Cluster with kubeadm on Linux

If you want to set up a more production-like on-premise cluster—one control-plane node (or multiple for high availability) plus dedicated worker nodes—then **kubeadm** is the recommended tool. Below is a step-by-step guide:

1. **System Requirements & Networking**
2. **Kernel & Linux Configuration (swap, sysctl, firewall)**
3. **Install a CRI (containerd or Docker)**
4. **Install kubeadm, kubelet, kubectl**
5. **Initialize the Control Plane with `kubeadm init`**
6. **Join Worker Nodes**
7. **Install a CNI Plugin**
8. **(Optional) Set Up a LoadBalancer Replacement (e.g., MetalLB) for Services of Type LoadBalancer**
9. **Basic Security & Best Practices**

### 2.1 Hardware & OS Requirements

* **Machines**:

    * At least one machine designated as the control-plane (often called the “master”). In production you usually run 3 or 5 control-plane nodes to form an etcd quorum.
    * At least one (but usually several) worker nodes.
* **Operating System**:

    * Ubuntu 20.04/22.04, Debian 11/12, CentOS 7/8, Rocky Linux 8/9, AlmaLinux 8/9, or similar.
    * Each node should have ≥2 CPU cores, ≥2 GiB RAM (control-plane preferably ≥4 GiB), and ≥20 GiB disk.
* **Network**:

    * All nodes must be able to reach each other via their IP addresses (ideally static IPs; avoid DHCP if possible).
    * DNS or `/etc/hosts` entries so that each node can resolve the control-plane’s hostname (if you plan to reference by name).

### 2.2 Linux Kernel & System Configuration

1. **Disable Swap**
   Kubernetes requires that swap be turned off or kubelet will refuse to start. On each node:

   ```bash
   sudo swapoff -a
   ```

   To make it permanent, open `/etc/fstab` and comment out (or remove) any line that refers to a swap partition or swap file (anything starting with `/swap` or `UUID=… swap`).

2. **Load Necessary Kernel Modules & sysctl Settings**
   Create a file `/etc/modules-load.d/k8s.conf` containing:

   ```
   br_netfilter
   overlay
   ```

   Then create `/etc/sysctl.d/k8s.conf` containing:

   ```
   net.bridge.bridge-nf-call-iptables  = 1
   net.bridge.bridge-nf-call-ip6tables = 1
   net.ipv4.ip_forward                 = 1
   net.ipv6.conf.all.forwarding        = 1
   vm.swappiness                        = 0
   ```

   Apply them immediately:

   ```bash
   sudo sysctl --system
   ```

3. **Firewall & SELinux (if using RHEL/CentOS/Fedora)**

    * On Ubuntu/Debian, if you are running `ufw`, either open the required ports (2379/2380 for etcd, 6443 for the API server, 10250 for kubelet, CNI ports, etc.) or disable it temporarily:

      ```bash
      sudo ufw disable
      ```
    * On CentOS/RHEL, you can disable firewalld while setting up:

      ```bash
      sudo systemctl disable firewalld --now
      ```
    * For SELinux on CentOS/Fedora/RHEL, set to permissive or disabled (at least during initial setup):

      ```bash
      sudo setenforce 0
      # Then edit /etc/selinux/config and set SELINUX=permissive
      ```

### 2.3 Install a Container Runtime (CRI)

Since Kubernetes v1.24 removed Docker’s built-in shim, you must install a CRI—either **containerd** or **CRI-O**. Below is an example using **containerd** on Ubuntu or Debian:

1. **Install prerequisites**

   ```bash
   sudo apt-get update
   sudo apt-get install -y ca-certificates curl gnupg lsb-release
   ```

2. **Add Docker’s official GPG key and repository** (because containerd is distributed alongside Docker packages):

   ```bash
   sudo mkdir -p /etc/apt/keyrings
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

   echo \
     "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
     https://download.docker.com/linux/ubuntu \
     $(lsb_release -cs) stable" | \
     sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

   sudo apt-get update
   ```

3. **Install containerd**

   ```bash
   sudo apt-get install -y containerd.io
   ```

4. **Configure containerd**
   Create the directory (if it doesn’t exist) and generate a default config:

   ```bash
   sudo mkdir -p /etc/containerd
   sudo containerd config default | sudo tee /etc/containerd/config.toml
   ```

   In `/etc/containerd/config.toml`, find the section:

   ```toml
   [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
     SystemdCgroup = false
   ```

   Change it to:

   ```toml
   [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
     SystemdCgroup = true
   ```

   This ensures containerd uses systemd cgroups, which is recommended. Then restart containerd:

   ```bash
   sudo systemctl restart containerd
   sudo systemctl enable containerd
   ```

5. **(Optional) If you prefer Docker instead**
   You could install Docker Engine:

   ```bash
   sudo apt-get install -y docker.io
   sudo systemctl enable docker --now
   sudo usermod -aG docker $USER   # Then log out/in or restart your shell
   ```

   And configure `/etc/docker/daemon.json` to use the systemd cgroup driver:

   ```json
   {
     "exec-opts": ["native.cgroupdriver=systemd"],
     "log-driver": "json-file",
     "log-opts": { "max-size": "100m" },
     "storage-driver": "overlay2"
   }
   ```

   Then restart Docker:

   ```bash
   sudo systemctl restart docker
   ```

### 2.4 Install kubeadm, kubelet, and kubectl

1. **Add the Kubernetes apt repository** (Ubuntu/Debian example):

   ```bash
   sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg \
       https://packages.cloud.google.com/apt/doc/apt-key.gpg

   echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] \
     https://apt.kubernetes.io/ kubernetes-xenial main" | \
     sudo tee /etc/apt/sources.list.d/kubernetes.list

   sudo apt-get update
   ```
2. **Install specific versions** (you generally want kubelet, kubeadm, and kubectl to match, and kubelet should be no more than one minor version older/newer than your control plane). For example:

   ```bash
   sudo apt-get install -y kubelet=1.27.3-00 kubeadm=1.27.3-00 kubectl=1.27.3-00
   ```

   Replace `1.27.3-00` with the version you intend to run.
3. **Pin the versions to prevent accidental upgrades** (optional):

   ```bash
   sudo apt-mark hold kubelet kubeadm kubectl
   ```
4. **Verify installation**:

   ```bash
   kubeadm version
   kubelet --version
   kubectl version --client
   ```

### 2.5 Initialize the Control Plane (`kubeadm init`)

Ensure on your control-plane node that:

* Swap is turned off (`swapoff -a`).
* sysctl settings are applied (`sysctl net.bridge.bridge-nf-call-iptables` should be `1`, `net.ipv4.ip_forward` should be `1`).
* containerd (or Docker) is running with the correct cgroup driver.

#### 2.5.1 Prepare a `kubeadm` Configuration File (Optional but Recommended)

You can supply a YAML file to configure certain settings, such as the Pod network CIDR, service network, and control-plane endpoint (helpful for HA). For instance, save this as `kubeadm-config.yaml`:

```yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: v1.27.3
controlPlaneEndpoint: "master.example.local:6443"
networking:
  podSubnet: "10.244.0.0/16"       # matches Flannel’s default
  serviceSubnet: "10.96.0.0/12"
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: "iptables"
```

* **`kubernetesVersion`**: Matches the version you installed for kubeadm/kubelet/kubectl.
* **`controlPlaneEndpoint`**: If you plan multiple control-plane nodes behind a load balancer or VIP, set that address here. Otherwise, use the hostname or IP of this single control-plane node.
* **`podSubnet`**: This must match whatever your CNI expects—e.g., Flannel uses `10.244.0.0/16` by default.
* **`serviceSubnet`**: Defaults to `10.96.0.0/12` unless you have a reason to change it.
* **`KubeProxyConfiguration`**: If you want iptables mode (default), leave it as-is. IPVS is possible but requires extra kernel modules.

Initialize with:

```bash
sudo kubeadm init --config=kubeadm-config.yaml --upload-certs
```

* **`--upload-certs`**: If you intend to add additional control-plane nodes (HA), this uploads the certificates to a secret in `kube-system` so other control-plane nodes can retrieve them.

#### 2.5.2 Follow the Post-Init Instructions

Once initialization succeeds, you’ll see something like:

```
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, run:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join master.example.local:6443 --token abcdef.0123456789abcdef \
    --discovery-token-ca-cert-hash sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
```

1. **Copy the kubeconfig** so you can run `kubectl` as a regular user:

   ```bash
   mkdir -p $HOME/.kube
   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   sudo chown $(id -u):$(id -g) $HOME/.kube/config
   ```

   Now `kubectl get nodes` (run as your user) will talk to the newly created cluster.

2. **Note the `kubeadm join` command** (it includes a token and the hash of the CA certificate). You’ll use that exact command on each worker node to join them to this control plane.

3. **Verify control-plane pods** are running:

   ```bash
   kubectl get pods -n kube-system
   ```

   You should see pods like:

    * `coredns-...` (two replicas)
    * `etcd-master` (if you have a standalone etcd on this node)
    * `kube-apiserver-master`, `kube-controller-manager-master`, `kube-scheduler-master`
    * `kube-proxy-...` (one per node, including the control-plane)
    * `storage-provisioner` (if using hostPath dynamic provisioning, for example)

### 2.6 Join Worker Nodes

On each worker node, after you’ve installed and configured containerd and kubeadm/kubelet/kubectl in the same way (swap off, sysctl applied, correct cgroup driver, etc.), run the join command you copied above. Example:

```bash
sudo kubeadm join master.example.local:6443 \
  --token abcdef.0123456789abcdef \
  --discovery-token-ca-cert-hash sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
```

* If your control plane has multiple endpoints behind a load balancer, use that VIP or hostname instead of a single IP.
* Once that command succeeds, on your control-plane node you should see the new worker appear in `kubectl get nodes`.

### 2.7 Install a CNI Plugin

Kubernetes does not provide pod networking out of the box—you must install a Container Network Interface plugin so pods across nodes can talk to each other. Some popular choices:

1. **Flannel** (simple UDP or VXLAN overlay)

   ```bash
   kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/v0.23.0/Documentation/kube-flannel.yml
   ```

   Make sure the `podSubnet` in your `kubeadm-config.yaml` matches Flannel’s default `10.244.0.0/16`.

2. **Calico** (L3 network with optional BGP, plus NetworkPolicy support)

   ```bash
   kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
   ```

   Calico can also operate in a VXLAN mode or use BGP. It is popular for its rich network policy features.

3. **Weave Net** (mesh overlay)

   ```bash
   kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
   ```

   Weave works well out of the box with minimal configuration.

4. **Cilium** (eBPF-based, high performance)

   ```bash
   kubectl create -f https://raw.githubusercontent.com/cilium/cilium/v1.14.0/install/kubernetes/quick-install.yaml
   ```

   Cilium requires a Linux kernel with eBPF support (≥4.19). It provides very efficient data plane and advanced security features.

After installing your chosen CNI, wait a few minutes and then verify that the CNI pods are all `Running` in `kube-system`:

```bash
kubectl get pods -n kube-system
```

Only once the CNI pods are ready is inter-pod networking functional. Then you can launch your application workloads.

### 2.8 (Optional) Use MetalLB for Services of Type LoadBalancer

On-premise, there is no cloud provider LB. If you want to create a Service of type `LoadBalancer` and have it receive a real IP on your local network, you can install MetalLB:

1. **Deploy MetalLB’s components**

   ```bash
   kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.11/config/manifests/metallb-native.yaml
   ```
2. **Configure an address pool** by creating a ConfigMap in the `metallb-system` namespace. For example, if your LAN has IPs 192.168.1.240–192.168.1.250 reserved for LoadBalancer Services:

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

   ```bash
   kubectl apply -f metallb-config.yaml
   ```
3. **Now whenever you create** a Service of type `LoadBalancer`, MetalLB will pick an unused IP from that pool, announce it via ARP (in layer2 mode), and route traffic to the appropriate node(s).

### 2.9 Basic Security and Best Practices

1. **RBAC (Role-Based Access Control)**
   By default, `kubeadm` sets up RBAC but gives the `admin.conf` user full `cluster-admin` privileges. For production or shared environments, create Roles/ClusterRoles and bind them to individual users or service accounts rather than handing out the admin kubeconfig to everyone.

2. **Pod Security Admission**

    * In newer Kubernetes versions, avoid using Pod Security Policies (PSPs—deprecated) and instead enable **Pod Security Admission**. Label each namespace with the desired enforcement level. For example:

      ```bash
      kubectl label namespace demo pod-security.kubernetes.io/enforce=baseline
      kubectl label namespace demo pod-security.kubernetes.io/enforce-version=v1.27.0
      ```
    * You can also set an “audit” or “warn” policy on other namespaces. This immediately blocks (or warns about) pods that request privileged or unsafe settings.

3. **PersistentVolumes & StorageClasses**

    * For on-premise storage, consider NFS, iSCSI, Ceph, or LVM-backed storage.
    * You can create `PersistentVolume` resources that reference NFS servers, or run an NFS-Client Provisioner in Kubernetes so that `PersistentVolumeClaims` dynamically bind to NFS shares.

4. **Upgrades**

    * Check available versions with

      ```bash
      sudo kubeadm upgrade plan
      ```
    * To upgrade the control-plane:

      ```bash
      sudo kubeadm upgrade apply v1.28.0
      ```
    * Then upgrade `kubelet` and `kubectl` on each node to match (e.g., via `apt-get install kubelet=1.28.0-00 kubectl=1.28.0-00`) and restart the `kubelet`:

      ```bash
      sudo systemctl restart kubelet
      ```
    * Always respect the version skew policy: kubelets may be one minor version older or newer than the control-plane, but you cannot skip more than one minor version.

5. **Monitoring & Metrics**

    * Install the **Metrics Server** so that Horizontal Pod Autoscaler works:

      ```bash
      kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
      ```
    * For production-grade monitoring, deploy Prometheus + Grafana. Include exporters like `node-exporter` and `kubestate-metrics`.

6. **etcd Backup & Restore**

    * On a single control-plane node (non-HA), take periodic etcd snapshots:

      ```bash
      sudo ETCDCTL_API=3 etcdctl snapshot save ~/etcd-snapshot-$(date +%F).db \
        --endpoints=https://127.0.0.1:2379 \
        --cacert=/etc/kubernetes/pki/etcd/ca.crt \
        --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
        --key=/etc/kubernetes/pki/etcd/healthcheck-client.key
      ```
    * Restoring from a snapshot involves stopping the control-plane components, running `etcdctl snapshot restore ...` into a new data directory, and adjusting configuration to point etcd to that new data directory before bringing the API server back up.

## Kubernetes Object Management

### 1.1 Introduction to Kubernetes Objects

Kubernetes is a declarative, API-driven system for orchestrating containerized applications. At its core are **objects**, which represent the desired state of various cluster components (for example, pods, services, deployments, config maps, and more). When you create or update an object, you’re expressing to Kubernetes “This is how I want my cluster to look.” Kubernetes then works to make the actual state of the cluster match your declared (desired) state.

Every Kubernetes object has:

* **`apiVersion`**: Specifies which version of the Kubernetes API you’re using (e.g., `v1`, `apps/v1`).
* **`kind`**: The type of object (e.g., `Pod`, `Deployment`, `Service`).
* **`metadata`**: A collection of fields that uniquely identify the object, such as `name`, `namespace`, `labels`, and `annotations`.
* **`spec`** (and sometimes **`status`**): The “specification” section describes the desired state, whereas the `status` section (populated by the system) reflects the current observed state.

> **Example Skeleton of a Kubernetes Object**
>
> ```yaml
> apiVersion: apps/v1
> kind: Deployment
> metadata:
>   name: nginx-deployment
>   namespace: default
> spec:
>   replicas: 3
>   selector:
>     matchLabels:
>       app: nginx
>   template:
>     metadata:
>       labels:
>         app: nginx
>     spec:
>       containers:
>       - name: nginx
>         image: nginx:1.21
>         ports:
>         - containerPort: 80
> ```

### 1.2 Managing Objects Declaratively

Kubernetes encourages a **declarative** approach (rather than imperative). You write a YAML (or JSON) file that declares the object’s desired state, then ask Kubernetes to apply it. Kubernetes compares that desired state to the current state and makes any necessary changes.

#### 1.2.1 Creating Objects

To create a new object from a file:

```bash
kubectl apply -f <filename>.yaml
```

* If the object doesn’t exist, Kubernetes creates it.
* If it exists, Kubernetes attempts to **merge** changes into the live object (a “patch”).

Alternatively, you can use:

```bash
kubectl create -f <filename>.yaml
```

But note that `create` will error out if an object with the same name already exists (whereas `apply` will update).

#### 1.2.2 Viewing Objects

* **List all objects of a given kind**:

  ```bash
  kubectl get pods               # show all Pods in the current namespace
  kubectl get deployments        # show all Deployments in the current namespace
  ```
* **Show detailed information**:

  ```bash
  kubectl describe deployment nginx-deployment
  ```

  This prints events, status, current replica count vs desired, and other helpful debugging info.
* **Output in YAML or JSON**:

  ```bash
  kubectl get svc myservice -o yaml
  kubectl get pods mypod -o json
  ```

#### 1.2.3 Updating Objects

Since Kubernetes is declarative, updating means modifying the YAML and re-applying:

1. Edit your local YAML file (e.g., change `replicas: 3` to `replicas: 5`).
2. Run:

   ```bash
   kubectl apply -f deployment.yaml
   ```

Kubernetes will perform a rolling update (for workloads that support it). You can also use **`kubectl edit`** to directly edit an object’s live configuration:

```bash
kubectl edit deployment nginx-deployment
```

This opens your default editor with the live spec; saving your edits triggers an update.

#### 1.2.4 Deleting Objects

To delete an object:

```bash
kubectl delete -f deployment.yaml
```

or

```bash
kubectl delete deployment nginx-deployment
```

By default, Kubernetes uses a graceful deletion process (sending a `TERM` signal to containers, waiting for them to shut down). You can force immediate deletion with `--grace-period=0 --force`, but this is usually discouraged unless necessary.

### 1.3 Object Fields and Structure

Every Kubernetes object YAML is structured similarly, which makes learning one kind helpful for understanding others. Let’s break down the sections:

1. **`apiVersion`**

    * Determines which API group and version to use. E.g., `v1` for core objects, `apps/v1` for Deployments/DaemonSets/ReplicaSets, `batch/v1` for Jobs/CronJobs, etc.
2. **`kind`**

    * The object’s type, such as `Pod`, `Service`, `ConfigMap`, `Deployment`, and so on.
3. **`metadata`**

    * **`name`**: A unique identifier for the object within its namespace.
    * **`namespace`**: Logical partition of the cluster; if omitted, defaults to the `default` namespace.
    * **`labels`**: Key/value pairs for grouping and selection.
    * **`annotations`**: Key/value pairs for storing arbitrary non-identifying metadata.
    * **`labels`** and **`annotations`** live under `metadata:`.
4. **`spec`**

    * Defines the “desired state” of the object. For a `Pod`, it lists the containers; for a `Deployment`, it sets replica count and pod template; for a `Service`, it describes ports and selectors; and so on.
5. **`status`**

    * Automatically populated by the Kubernetes control plane reflecting the real-time state (e.g., how many replicas are actually running, pod IP addresses, conditions). Typically, you should not set it yourself in YAML; Kubernetes manages it.

> **Tip**: Use `kubectl explain <kind>.<field>` to see documentation for each field. For example:
>
> ```bash
> kubectl explain deployment.spec.template.spec.containers
> ```

### 1.4 Applying Labels, Annotations, and Namespaces (Preview)

Although these topics are treated in depth later, it’s worth noting here how they fit into object management:

* **Labels** (`metadata.labels`) are used for grouping, selectors, and querying (e.g., telling a Service which pods to route to).
* **Annotations** (`metadata.annotations`) hold non-identifying metadata (e.g., build/release IDs, URLs, arbitrary JSON).
* **Namespaces** partition objects into virtual clusters. Placing `metadata.namespace: my-namespace` in an object’s YAML causes it to belong to that namespace. If you omit the namespace, Kubernetes assumes `default` (or the value of your current `kubectl` context).

### 1.5 Practical Examples of Object Lifecycle

#### 1.5.1 Creating a Simple Pod

```yaml
# pod-demo.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
spec:
  containers:
  - name: nginx-container
    image: nginx:1.21
    ports:
    - containerPort: 80
```

**Apply the Pod**:

```bash
kubectl apply -f pod-demo.yaml
```

**Verify**:

```bash
kubectl get pods
kubectl describe pod nginx-pod
```

**Delete**:

```bash
kubectl delete pod nginx-pod
```

#### 1.5.2 Creating a Deployment for Rolling Updates

```yaml
# deployment-demo.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx-container
        image: nginx:1.21
        ports:
        - containerPort: 80
```

**Apply**:

```bash
kubectl apply -f deployment-demo.yaml
```

**View rollout status**:

```bash
kubectl rollout status deployment/nginx-deployment
```

**Update image version**: Edit `image: nginx:1.21` → `image: nginx:1.22` in the YAML, then:

```bash
kubectl apply -f deployment-demo.yaml
```

Kubernetes will create new pods with the updated image and terminate the old pods in a rolling fashion.

**Rollback if needed**:

```bash
kubectl rollout undo deployment/nginx-deployment
```

#### 1.5.3 Using `kubectl edit` for Quick Tweaks

Suppose you want to temporarily scale your deployment to 5 replicas without touching your local YAML:

```bash
kubectl edit deployment nginx-deployment
```

Change

```yaml
spec:
  replicas: 2
```

to

```yaml
spec:
  replicas: 5
```

Save and exit. Kubernetes will spin up 3 additional pods.

### 1.6 Best Practices and Patterns for Object Management

1. **Keep manifests declarative and in source control**: Store all YAML files in Git (or another VCS) so you have version history.
2. **Use `kubectl apply` over `kubectl create`** for most workflows: It’s idempotent and merges changes.
3. **Label your resources consistently**: Even if your objects don’t need labels for selection, having common labels (e.g., `app=teamX-serviceY`) can simplify debugging, filtering, and dashboards.
4. **Namespace per environment or team**: For multi-tenant clusters, dedicate namespaces to each team or environment (e.g., `dev`, `staging`, `prod`).
5. **Review `kubectl diff` before apply**: You can run:

   ```bash
   kubectl diff -f deployment-demo.yaml
   ```

   This shows you exactly what will change (fields added, removed, or updated).
6. **Annotate objects with audit or build information**: Store Git commit SHA, CI pipeline run, or ticket IDs in annotations so you can trace back “who did what, and why.”

---

## Labels in Kubernetes

### 2.1 What Are Labels?

**Labels** are key/value pairs attached to Kubernetes objects (pods, services, deployments, etc.) under `metadata.labels`. They serve two main purposes:

1. **Organization and grouping**: You can logically group objects (for example, by application, tier, environment, version).
2. **Selection**: Controllers (Deployments, ReplicaSets, DaemonSets) and Services use **label selectors** to identify the set of pods they should manage or route traffic to.

> **Example of Labels**
>
> ```yaml
> kind: Pod
> apiVersion: v1
> metadata:
>   name: mysql
>   labels:
>     app: myapp
>     tier: database
>     environment: production
> spec:
>   containers:
>   - name: mysql
>     image: mysql:8.0
> ```

### 2.2 Label Keys and Values

* **Key syntax**: Must be at most 63 characters (alphanumeric, `-`, `_`, `.`), optionally prefixed by a DNS subdomain (e.g., `example.com/role`). If prefixed, the prefix and slash together must be ≤ 253 characters.
* **Value syntax**: Up to 63 characters (alphanumeric, `-`, `_`, `.`). Values can be empty strings.

> **Valid Label Keys / Values**
>
> * `app: frontend`
> * `tier: backend`
> * `env: staging`
> * `example.com/version: "v1.0"`

### 2.3 Label Selectors

A **label selector** is how you query or filter objects by labels. There are two styles:

1. **Equality-based selectors** (most common):

    * `key=value` or `key==value`
    * `key!=value`
    * Example: `app=nginx`, `environment!=production`
2. **Set-based selectors** (more advanced):

    * `key in (value1,value2,…)`
    * `key notin (value1,value2,…)`
    * `key` (exists)
    * `!key` (does not exist)

#### 2.3.1 Using Selectors with `kubectl`

* **List objects with a given label**:

  ```bash
  kubectl get pods -l app=nginx
  kubectl get services -l environment=production,tier=frontend
  kubectl get pods -l "release in (stable,canary)"
  ```
* **Watch changes to objects matching a selector**:

  ```bash
  kubectl get pods -l app=nginx --watch
  ```

#### 2.3.2 How Controllers Use Selectors

* A **Deployment** defines a `spec.selector.matchLabels` or `matchExpressions` block. Kubernetes uses that to know which pods belong to the Deployment’s ReplicaSet.
* A **Service** uses `spec.selector` to choose which pods to route traffic to.

> **Deployment Example with Selectors**
>
> ```yaml
> apiVersion: apps/v1
> kind: Deployment
> metadata:
>   name: web-deployment
> spec:
>   replicas: 3
>   selector:
>     matchLabels:            # This selector must match labels in pod template
>       app: web
>       tier: frontend
>   template:
>     metadata:
>       labels:
>         app: web
>         tier: frontend
>     spec:
>       containers:
>       - name: nginx
>         image: nginx:1.21
> ```

> **Service Example with Selectors**
>
> ```yaml
> apiVersion: v1
> kind: Service
> metadata:
>   name: web-service
> spec:
>   selector:                # Service will route to pods matching these labels
>     app: web
>     tier: frontend
>   ports:
>   - protocol: TCP
>     port: 80
>     targetPort: 80
>   type: ClusterIP
> ```

### 2.4 Best Practices for Labeling

1. **Use meaningful label keys/values** that reflect application structure, environment, version, and role. For instance:

    * `app`: The name of your application (e.g., `app: payment-service`).
    * `component` or `tier`: E.g., `frontend`, `backend`, `database`.
    * `environment`: E.g., `dev`, `staging`, `prod`.
    * `version`: E.g., `v1.0`, `canary`, `stable`.
2. **Adopt a standard labeling scheme** across teams so tools, dashboards, and policies can assume consistent keys.
3. **Don’t over-label**: Only include labels that will be used for filtering, grouping, or selection. Having dozens of arbitrary labels can become confusing.
4. **Use multi-value labels sparingly**: If you need multiple values, consider using a set-based selector rather than duplicate labels.

### 2.5 Common Labeling Scenarios

#### 2.5.1 Blue-Green or Canary Deployments

You can label different versions differently and use a Service selector to switch traffic. For example:

* **Deployment for v1**:

  ```yaml
  metadata:
    name: web-v1
  spec:
    selector:
      matchLabels:
        app: web
        version: v1
    template:
      metadata:
        labels:
          app: web
          version: v1
  ```
* **Deployment for v2 (canary)**:

  ```yaml
  metadata:
    name: web-v2
  spec:
    replicas: 1
    selector:
      matchLabels:
        app: web
        version: v2
    template:
      metadata:
        labels:
          app: web
          version: v2
  ```
* **Service routes only `v1` initially**:

  ```yaml
  apiVersion: v1
  kind: Service
  metadata:
    name: web-service
  spec:
    selector:
      app: web
      version: v1
    ports:
    - port: 80
      targetPort: 80
  ```

To shift traffic to v2, you change the Service’s `version` selector to `v2` (or both, or use traffic-splitting via Ingress, Istio, etc.).

#### 2.5.2 Multi-Tenancy and Resource Quotas

If you label pods by team or owner (e.g., `team=payments`), you can:

* Setup **NetworkPolicies** to isolate traffic (`podSelector: { matchLabels: { team: payments } }`).
* Define **ResourceQuotas** per namespace but also reconcile them per label with cluster-level policies.

### 2.6 Adding and Modifying Labels Post-Creation

#### 2.6.1 Using `kubectl label`

* **Add or update a label** on a running object:

  ```bash
  kubectl label pod nginx-pod environment=staging
  ```

  If `environment` didn’t exist, it’s added. If it existed, it’s updated.
* **Remove a label**:

  ```bash
  kubectl label pod nginx-pod environment-
  ```

#### 2.6.2 Patching an Object

You can also use a JSON patch to add/update labels:

```bash
kubectl patch deployment web-deployment -p '{"metadata":{"labels":{"environment":"production"}}}'
```

---

## Namespaces in Kubernetes

### 3.1 What Is a Namespace?

A **namespace** is a logical partition within a Kubernetes cluster. It provides scope for:

* **Names**: Objects (Pods, Services, ConfigMaps, etc.) in different namespaces can share the same `name` without collision (e.g., `dev/nginx-pod` vs `prod/nginx-pod`).
* **Resource isolation**: Though not a full security boundary by default, namespaces let you segment cluster resources (e.g., CPU/memory quotas, network policies, RBAC rules) per team, project, or environment.

By default, every cluster has at least three namespaces:

1. **default**: Where user-created objects go when no namespace is specified.
2. **kube-system**: Reserved for system components (API server, scheduler, etc.).
3. **kube-public**: Read-only, accessible to all authenticated users (typically contains cluster info).

You can create additional namespaces for isolation (e.g., `dev`, `staging`, `prod`, or separate by team).

### 3.2 Creating and Deleting Namespaces

#### 3.2.1 Create a Namespace

```yaml
# namespace-dev.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: dev
```

Apply it:

```bash
kubectl apply -f namespace-dev.yaml
kubectl get namespaces
# NAME          STATUS   AGE
# default       Active   10d
# dev           Active   5m
# kube-system   Active   10d
# kube-public   Active   10d
```

#### 3.2.2 Delete a Namespace

```bash
kubectl delete namespace dev
```

Deleting a namespace is asynchronous: Kubernetes will garbage-collect (delete) all objects in that namespace, then remove the namespace entry once everything is cleaned up.

### 3.3 Working with Namespaced Objects

When you create or query most objects, you specify (or default to) a namespace:

* **Creating an object in a specific namespace**:

  ```yaml
  # pod-in-dev.yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: myapp-pod
    namespace: dev
    labels:
      app: myapp
  spec:
    containers:
    - name: myapp
      image: myapp:latest
  ```

  Then:

  ```bash
  kubectl apply -f pod-in-dev.yaml
  ```
* **Without specifying `metadata.namespace`**, objects go into your current `kubectl` context’s default namespace (often `default`).

#### 3.3.1 Switching Namespace Context

You can set your default namespace for a particular context to avoid specifying `-n` or `metadata.namespace` each time:

```bash
kubectl config set-context --current --namespace=dev
```

After this, any `kubectl apply` or `kubectl get` without `-n` will operate in the `dev` namespace.

#### 3.3.2 List Objects by Namespace

* **All namespaces**:

  ```bash
  kubectl get pods --all-namespaces
  ```
* **Specific namespace**:

  ```bash
  kubectl get deployments -n prod
  ```

### 3.4 Resource Quotas and Limits by Namespace

Organizations often enforce resource consumption boundaries per namespace. This prevents a single team or workload from exhausting the entire cluster.

#### 3.4.1 ResourceQuota Object

```yaml
# quota-dev.yaml
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

Apply it in the `dev` namespace. Kubernetes then tracks resource usage in that namespace, preventing new pods if quotas are exceeded.

#### 3.4.2 LimitRange Object

You can also set default resource requests/limits for pods or containers in a namespace.

```yaml
# limitrange-dev.yaml
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

If a pod is created without specifying requests/limits, Kubernetes applies these defaults automatically.

### 3.5 Network Policies by Namespace

Namespaces become network isolation boundaries when combined with NetworkPolicies. For instance, you can allow only pods in the `frontend` namespace to talk to pods in `backend`, while denying other traffic.

```yaml
# allow-frontend-to-backend.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: backend
spec:
  podSelector: {}  # selects all pods in the 'backend' namespace
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: frontend
```

This policy says: “Within the `backend` namespace, allow ingress from any pod whose namespace has label `name=frontend`.”

### 3.6 RBAC and Namespaces

You can assign **RoleBindings** or **ClusterRoleBindings** scoped to specific namespaces:

* **RoleBinding** (namespace-scoped) example:

  ```yaml
  apiVersion: rbac.authorization.k8s.io/v1
  kind: Role
  metadata:
    namespace: dev
    name: pod-reader
  rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "watch", "list"]
  ---
  apiVersion: rbac.authorization.k8s.io/v1
  kind: RoleBinding
  metadata:
    name: read-pods-binding
    namespace: dev
  subjects:
  - kind: User
    name: alice
    apiGroup: rbac.authorization.k8s.io
  roleRef:
    kind: Role
    name: pod-reader
    apiGroup: rbac.authorization.k8s.io
  ```

  This gives user `alice` the ability to list, watch, and get pods in the `dev` namespace.

### 3.7 Best Practices for Namespaces

1. **One namespace per environment**: For example, `dev`, `staging`, `production`. It simplifies resource quotas, RBAC, and resource cleanup.
2. **One namespace per team (if multi-tenant)**: If multiple teams share a cluster, each team can have a dedicated namespace to isolate resources.
3. **Label namespaces consistently**: Annotate or label namespaces with owner, environment, or team metadata (e.g., `environment=prod`, `team=backend`).
4. **Avoid creating too many namespaces**: Each namespace adds overhead (e.g., in etcd). In very large clusters, having thousands of namespaces can degrade performance.
5. **Use `kubectl config set-context`**: Make day-to-day operations easier by switching contexts (and namespaces) rather than supplying `-n` every time.

---

## Annotations in Kubernetes

### 4.1 What Are Annotations?

**Annotations** are arbitrary key/value pairs attached to Kubernetes objects under `metadata.annotations`. Unlike **labels**, which are used for grouping, selection, and identification, annotations are meant for **non-identifying metadata**—often needed for:

* Tooling or automation to record build/release IDs, Git commit hashes, or timestamps.
* Documentation or descriptive text.
* Links to external resources (e.g., URLs to tickets, dashboards).
* Storing configuration data that is too large or verbose for labels.

> **Example of Annotations**
>
> ```yaml
> apiVersion: apps/v1
> kind: Deployment
> metadata:
>   name: webapp
>   labels:
>     app: webapp
>   annotations:
>     build-version: "42"
>     git-commit: "a1b2c3d4"
>     changelog-url: "https://git.example.com/myrepo/commit/a1b2c3d4"
>     maintainer: "ops-team@example.com"
> spec:
>   replicas: 3
>   template:
>     metadata:
>       labels:
>         app: webapp
>     spec:
>       containers:
>       - name: webapp
>         image: example/webapp:latest
> ```

### 4.2 Differences Between Labels and Annotations

| Aspect                   | Labels                                         | Annotations                                                          |
| ------------------------ | ---------------------------------------------- | -------------------------------------------------------------------- |
| **Primary Purpose**      | Selecting and grouping objects                 | Storing arbitrary metadata                                           |
| **Selectors**            | Used in label selectors (Deployment, Service)  | Not used for selection; Kubernetes ignores annotations for selection |
| **Intended Size/Length** | Short (≤ 63 characters for keys/values)        | Can be larger (though still limited by overall metadata size)        |
| **Use Cases**            | `app=frontend`, `env=prod`, `version=v1.2`     | `build-timestamp`, `qa-notes`, `documentation-links`, `owner-info`   |
| **Visibility**           | Often shown in `kubectl get` output by default | Not shown by default but visible via `kubectl describe` or `-o yaml` |

### 4.3 Using Annotations in Practice

#### 4.3.1 Adding Annotations to an Object

You can define annotations in your object’s YAML under `metadata.annotations`:

```yaml
metadata:
  name: redis
  annotations:
    backup/schedule: "daily"
    backup/location: "s3://mybucket/redis-backups"
```

To add an annotation after creation, use `kubectl annotate`:

```bash
kubectl annotate deployment webapp build-version="2025-05-30-001"
```

If the key already exists, the command will fail unless you add `--overwrite`:

```bash
kubectl annotate deployment webapp build-version="2025-05-30-002" --overwrite
```

To remove an annotation:

```bash
kubectl annotate pod mypod backup/schedule-
```

#### 4.3.2 Retrieving Annotations

* **Describe object**:

  ```bash
  kubectl describe pod mypod
  ```

  Under the “Annotations” section, you’ll see all key/value pairs.
* **Get object in YAML/JSON**:

  ```bash
  kubectl get deployment webapp -o yaml
  ```

  Look under `metadata.annotations:`.

### 4.4 Common Use Cases for Annotations

#### 4.4.1 Storing CI/CD Metadata

* **Git Commit SHA**: Record which commit an image was built from.
* **Build Timestamp**: When the container image (or Helm chart) was packaged.
* **CI Pipeline ID or URL**: Link back to the CI job that produced the artifact.

**Example**:

```yaml
metadata:
  name: api-server
  annotations:
    ci-pipeline: "https://ci.example.com/job/api-server/1234"
    git-commit: "f7e71abc"
    image-build-date: "2025-05-30T14:22:00Z"
```

#### 4.4.2 External Configuration for Controllers/Operators

Some operators (for example, the Prometheus Operator or cert-manager) read from annotations to drive behavior:

* **cert-manager**:

  ```yaml
  metadata:
    name: example-cert
    annotations:
      cert-manager.io/cluster-issuer: "letsencrypt-prod"
  spec:
    dnsNames:
    - example.com
  ```

  The annotation `cert-manager.io/cluster-issuer` tells cert-manager which Issuer to use to provision a TLS certificate.

* **Ingress Controllers** (e.g., NGINX Ingress Controller) can read annotations to modify behavior on a per-Ingress basis:

  ```yaml
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: web-ingress
    annotations:
      nginx.ingress.kubernetes.io/rewrite-target: "/"
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
  spec:
    rules:
    - host: example.com
      http:
        paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: web-service
              port:
                number: 80
  ```

#### 4.4.3 Developer Notes and Documentation

Annotations can hold free-form text, such as a short description, owner contact info, or links to runbooks:

```yaml
metadata:
  name: analytics-job
  annotations:
    description: "Runs nightly data aggregation for reporting"
    owner: "data-team@example.com"
    runbook-url: "https://wiki.example.com/display/DataTeam/Analytics+Job"
```

### 4.5 Design Considerations for Annotations

* **Avoid overly large annotation values**: Although annotations can handle larger strings than labels, extremely large values can increase the size of etcd objects and slow down API calls. If you need to store big blobs (e.g., SSL certificates), consider using a `Secret` instead.
* **Use a consistent naming convention**: Don’t litter random keys; adopt a prefix naming scheme when multiple tools/operators might add annotations:

    * For internal tooling: `internal.example.com/backup-schedule`
    * For cert-manager: `cert-manager.io/cluster-issuer` (as documented by cert-manager)
* **Remember that annotations are not indexed**: You cannot use them for fast label-selector lookups. If you need to filter by a key/value frequently, labels are a better choice.

---

## Common Labels in Kubernetes

### 5.1 Why Standardize on Common Labels?

Although arbitrary labels are powerful, having a **standard set of recommended labels** across your organization—or across the ecosystem—greatly simplifies:

* **Automation**: Scripts and tools can assume the presence of known label keys and perform actions accordingly.
* **Discovery and Dashboards**: Monitoring tools (Prometheus, Grafana, etc.) can aggregate metrics by standardized keys.
* **Governance**: Cluster admins can enforce policies (via OPA, Kyverno, or other admission controllers) that rely on certain labels being present.

Kubernetes provides a list of **common labels** under the [Common Labels documentation](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/). These are conventions—not enforced by Kubernetes itself—but widely adopted by many projects.

### 5.2 List of Recommended Common Labels

Here are the most commonly referenced keys, with typical value examples and descriptions:

| **Key**                         | **Value Examples**       | **Description**                                                                                                               |
| ------------------------------- | ------------------------ | ----------------------------------------------------------------------------------------------------------------------------- |
| `app.kubernetes.io/name`        | `nginx`, `redis`         | The name of the application (e.g., “nginx”, “mysql”).                                                                         |
| `app.kubernetes.io/instance`    | `nginx-1`, `redismaster` | A unique identifier for an instance of an application (e.g., “nginx-1” for a specific deployment).                            |
| `app.kubernetes.io/version`     | `v1.0.0`, `2.3.4`        | The version of the application (often the image tag or release tag).                                                          |
| `app.kubernetes.io/component`   | `frontend`, `cache`      | The component within the architecture (e.g., “frontend”, “backend”, “database”, “cache”).                                     |
| `app.kubernetes.io/part-of`     | `ecommerce`, `analytics` | The name of a higher-level application this component is part of (e.g., a microservice “users” might be part of “ecommerce”). |
| `app.kubernetes.io/managed-by`  | `Helm`, `kustomize`      | The tool or operator managing this object (e.g., “Helm”, “Kustomize”, “operator-name”).                                       |
| `app.kubernetes.io/created-by`  | `GitOps`, `CircleCI`     | The party or tool that created or initiated the deployment (e.g., “GitOps”, “Jenkins”, “CircleCI”).                           |
| `app.kubernetes.io/operated-by` | `team-ops`, `dev-team`   | The team or entity responsible for day-to-day operations of the application.                                                  |
| `helm.sh/chart`                 | `nginx-1.2.3`            | The name and version of the Helm chart used (if deployed via Helm).                                                           |
| `heritage`                      | `Helm`, `Kustomize`      | The tool that originally created this resource (often automatically added by Helm).                                           |

> **Note**: All of these keys (except `heritage`) are under the prefix `app.kubernetes.io/`. This “namespace” helps avoid clashes with other labels.

### 5.3 Applying Common Labels in Practice

#### 5.3.1 Example Deployment with Common Labels

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

All these labels serve distinct purposes:

* `app.kubernetes.io/name` and `app.kubernetes.io/instance` identify the application and instance.
* `app.kubernetes.io/version` tracks the specific version of Redis.
* `app.kubernetes.io/part-of` indicates it’s part of a larger “ecommerce-app.”
* `app.kubernetes.io/managed-by` and `helm.sh/chart` show that Helm manages it and which chart version was used.

#### 5.3.2 Service Example Matching on Common Labels

When you create a Service, you can match on some of these standard labels:

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

This ensures that the Service always routes to pods labeled exactly as that instance, even if new pods are created by a Helm upgrade.

### 5.4 Benefits of Adopting Common Labels

1. **Interoperability with Helm Charts**: Helm automatically injects certain labels (e.g., `heritage: Helm`, `helm.sh/chart`) so that tools can identify which resources belong to which release.
2. **Unified Dashboards and Monitoring**: Prometheus exporters can scrape metrics and add relabeling rules based on `app.kubernetes.io/part-of` or `component`, allowing you to group metrics by higher-level applications.
3. **Policy Enforcement**: Admission controllers or policy engines (OPA Gatekeeper, Kyverno) can enforce that every deployment must have `app.kubernetes.io/operated-by` and `app.kubernetes.io/part-of` labels.
4. **Ease of Searching and Filtering**: Running `kubectl get pods -l app.kubernetes.io/part-of=ecommerce-app` gives all pods that belong to that application, regardless of microservice names or versions.

### 5.5 Other Useful Common Labels (Beyond the Official List)

While the Kubernetes docs list the “apps” prefix keys, many organizations introduce supplemental labels to convey internal metadata. Examples include:

* **`team` or `owner`**: Identifies which team or individual owns the resource.
* **`environment`**: `development`, `test`, `staging`, `production`.
* **`git-repo`**: The Git repository URL.
* **`release`**: A release name (especially in GitOps-driven clusters): e.g., `v2.3.1`.

> **Example**:
>
> ```yaml
> metadata:
>   name: frontend
>   labels:
>     app.kubernetes.io/name: frontend
>     app.kubernetes.io/part-of: ecommerce-app
>     app.kubernetes.io/version: "1.2.0"
>     app.kubernetes.io/managed-by: "GitOps"
>     team: "website-team"
>     environment: "production"
> ```

### 5.6 Migrating to Common Labels

If you have existing clusters with ad-hoc labels, consider:

1. **Inventory current labels**:

   ```bash
   kubectl get all --all-namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.labels}{"\n"}{end}'
   ```
2. **Define a standard labeling policy**: Document your organization’s required keys (e.g., `app.kubernetes.io/name`, `app.kubernetes.io/part-of`, `team`, `environment`, etc.).
3. **Use automation (scripts or GitOps)** to patch existing objects with missing labels. For example:

   ```bash
   kubectl label deployment -n dev payment-service app.kubernetes.io/part-of=ecommerce-app --overwrite
   ```
4. **Enforce going forward with Admission Controllers**: Use a policy engine (like Gatekeeper) that rejects any new workloads missing required labels.

