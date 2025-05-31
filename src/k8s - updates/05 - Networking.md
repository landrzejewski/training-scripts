## 1. Overview of Kubernetes Networking

Kubernetes provides a flat, cluster-wide network namespace in which all Pods can (by default) communicate with one another. However, this “open by default” model can be too permissive for production workloads. To manage and control traffic, Kubernetes offers:

* **Services**: Stable endpoints and load balancing for a set of Pods, decoupling clients from ephemeral Pod IPs.
* **Ingress / Gateway API**: Layer-7 (HTTP/HTTPS, gRPC, TCP) routing constructs that route external traffic into the cluster.
* **Network Policies**: Fine-grained “whitelists” that restrict which Pods or external IPs can talk to which Pods, on which ports and protocols.

Understanding these mechanisms is essential for designing resilient, secure, and scalable Kubernetes applications.

---

<a name="services"></a>

## 2. Kubernetes Services

### 2.1 Role and Core Concepts

* **Problem**: Pods are ephemeral. Each Pod gets its own IP, but if a Pod crashes or is rescheduled, its IP changes. Relying on Pod IPs directly would break connectivity.
* **Solution**: A **Service** provides:

    * A **stable virtual IP** (ClusterIP) within the cluster.
    * A **DNS name** (e.g., `my-service.namespace.svc.cluster.local`) that resolves to that IP.
    * **Automatic load-balancing** to all Pods matching a label selector behind the scenes.

#### Benefits of Services

* **Decoupling**: Consumers (other Pods or external clients) refer to `service-name` instead of individual Pod IPs.
* **Load Balancing**: Kubernetes’ `kube-proxy` distributes traffic across healthy Pods.
* **Resiliency**: When Pods scale up/down or die, the Service’s endpoint list updates automatically.

---

### 2.2 How Services Select Pods

A Service’s `.spec` typically includes:

* `selector`: A set of label key–value pairs. Any Pod whose labels match the selector is included as an endpoint.
* `ports`: One or more ports. Each port has:

    * `port`: The port number on which the Service listens.
    * `targetPort`: The port number on the Pods (container port). This can be a number or a named port.

**Example**:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-svc
spec:
  selector:
    app: web
    tier: frontend
  ports:
    - port: 80
      targetPort: 8080
```

* The Service is reachable at port 80.
* Any Pod labeled `app=web` and `tier=frontend` receives traffic on port 8080.

> **Note**: If you change a Pod’s labels so it no longer matches, Kubernetes automatically removes that Pod from the Service’s endpoints.

---

### 2.3 Types of Services (Use Cases and Behavior)

#### 2.3.1 ClusterIP (Default)

* **Definition**: Exposes the Service on an internal IP within the cluster.
* **Use Case**: Internal communication between Pods (e.g., front-end → back-end).
* **Behavior**:

    * A ClusterIP (e.g., `10.0.0.15`) is allocated.
    * Only accessible from within the cluster.
    * DNS name: `my-service.namespace.svc.cluster.local`.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend
spec:
  type: ClusterIP
  selector:
    app: backend
  ports:
    - port: 5000
      targetPort: 5000
```

#### 2.3.2 NodePort

* **Definition**: Exposes the Service on each Node’s IP at a static port (the “NodePort”).
* **Use Case**: Basic external access without a cloud load balancer.
* **Behavior**:

    1. Kubernetes picks (or you specify) a port in the range 30000–32767 (or your cluster’s configured range).
    2. The Service still has a ClusterIP internally.
    3. Each Node opens the chosen port. Traffic to `<NodeIP>:<NodePort>` is forwarded to Service endpoints.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-nodeport
spec:
  type: NodePort
  selector:
    app: frontend
  ports:
    - port: 80        # Service port
      targetPort: 8080
      nodePort: 30080 # chosen from 30000–32767
```

* If you have Nodes at `10.1.1.10` and `10.1.1.11`, requests to `10.1.1.10:30080` or `10.1.1.11:30080` reach one of the `frontend` Pods.

#### 2.3.3 LoadBalancer

* **Definition**: In cloud environments (GKE, EKS, AKS, etc.), provisions a managed external load balancer with a public IP that forwards to the Service’s NodePort.
* **Use Case**: Expose a Service to the Internet (or VPC) via a cloud-provider LB.
* **Behavior**:

    1. Kubernetes requests a load balancer from the cloud provider.
    2. Once provisioned, you see an `EXTERNAL-IP` in `kubectl get svc`.
    3. Traffic to that IP goes to the Services’ NodePort on one of the Nodes, then to Pods.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-lb
spec:
  type: LoadBalancer
  selector:
    app: frontend
  ports:
    - port: 80
      targetPort: 8080
```

#### 2.3.4 ExternalName

* **Definition**: Creates a Service that maps to a DNS name outside the cluster. Kubernetes returns a CNAME record. No proxying or `kube-proxy` is involved.
* **Use Case**: Let Pods refer to an external resource (e.g., managed database) via a consistent Service name.
* **Behavior**:

    * DNS queries to `my-svc.namespace.svc.cluster.local` return a CNAME to `external.example.com`.
    * Pods query DNS, get back `external.example.com`, and connect directly.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-db
spec:
  type: ExternalName
  externalName: db.example.net
```

#### 2.3.5 Headless Service

* **Definition**: A Service with `clusterIP: None`. No virtual IP is allocated. DNS returns Pod IPs directly.
* **Use Case**: Stateful applications (e.g., databases, message queues) where clients need to connect to specific Pod instances or do custom client-side load balancing.
* **Behavior**:

    * No ClusterIP.
    * DNS A records resolve to the set of Pod IPs matching `spec.selector`.
    * Clients receive a list of Pod IPs and choose how to connect (e.g., Kafka brokers, StatefulSet pods).

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kafka
spec:
  clusterIP: None
  selector:
    app: kafka
  ports:
    - port: 9092
      targetPort: 9092
```

* Pods: `kafka-0`, `kafka-1`, `kafka-2` → each has DNS `kafka-0.kafka.namespace.svc.cluster.local`, etc.

> **When to Use Headless**
> • StatefulSets where each replica needs a stable hostname.
> • Custom client load balancing via DNS.

---

### 2.4 Service Discovery and DNS

* Kubernetes includes **CoreDNS** (or kube-dns) to provide DNS for Services and Pods.
* By default, each Service `foo` in namespace `bar` gets a DNS entry:

  ```
  foo.bar.svc.cluster.local → <ClusterIP>
  ```
* **A and SRV Records**:

    * **ClusterIP Service**: DNS returns a single A record with the Service’s IP.
    * **Headless Service**: DNS returns multiple A records (one per Pod IP).
    * Kubernetes also creates SRV records for each port defined in a Service, enabling clients to discover port numbers programmatically (e.g., `_http._tcp.foo.bar.svc.cluster.local`).
* **Pod DNS**: Each Pod has its own DNS name (`<pod-ip-address>.<namespace>.pod.cluster.local`), but Pods rarely use this directly. Services are the primary mechanism for discovery.
* **Legacy Environment Variables**: In earlier versions, kubelet injected environment variables (`FOO_SERVICE_HOST`, `FOO_SERVICE_PORT`) for each Service into Pods. DNS is now the preferred method.

---

### 2.5 Service Endpoints and `kube-proxy`

#### 2.5.1 Endpoints Object

* When you create a Service (with a `selector`), Kubernetes automatically creates an **Endpoints** object (same name as the Service) that lists the IP\:port of each Pod matching the selector.

  ```bash
  kubectl get svc frontend-svc
  # NAME           TYPE        CLUSTER-IP     PORT(S)   AGE
  # frontend-svc   ClusterIP   10.0.0.42      80/TCP    15m

  kubectl get endpoints frontend-svc
  # NAME           ENDPOINTS                    AGE
  # frontend-svc   10.1.1.12:8080,10.1.2.15:8080 15m
  ```
* Whenever Pods matching the selector are added/removed/relabeled, the Endpoints object updates automatically. If no Pods match, Endpoints is empty → no traffic is forwarded.

#### 2.5.2 `kube-proxy` and Traffic Routing

* Each Node runs a **kube-proxy** process that watches Services and Endpoints.
* **Implementation Modes**:

    1. **iptables** mode (default in many clusters): Uses iptables rules to match Service IP → Pod IP.
    2. **IPVS** mode: More efficient, kernel-level load-balancing.
* **ClusterIP Flow**:

    1. Client Pod sends a packet to `ClusterIP:port`.
    2. kube-proxy on that node intercepts, rewrites the destination to one of the Pod IPs (from Endpoints), and forwards the packet.
    3. When the Pod responds, kube-proxy rewrites source/destination so the client still sees `ClusterIP`.
* **NodePort Flow**:

    1. External request arrives at `NodeIP:NodePort`.
    2. kube-proxy intercepts on the node, selects a Pod endpoint (maybe on another node), and routes accordingly.
* **externalTrafficPolicy** (for NodePort/LoadBalancer):

    * `Cluster` (default): External traffic can be forwarded to any Pod in the cluster (possibly via another node).
    * `Local`: Traffic only goes to Pods on the same node. If no local Pods exist, that node rejects traffic. This preserves source IP (client IP visible to the Pod).

---

### 2.6 Advanced Service Features

#### 2.6.1 Session Affinity

* By default, each request goes to a random Pod (round-robin or IPVS algorithm).
* **Use Case**: Legacy stateful apps that need “sticky” sessions by client IP.
* Enable via:

  ```yaml
  spec:
    sessionAffinity: ClientIP
    sessionAffinityConfig:
      clientIP:
        timeoutSeconds: 10800  # default is 3 hours
  ```
* kube-proxy tracks client IP → chosen Pod for the duration.
* **Trade-off**: Can lead to uneven load distribution if some clients generate much more traffic.

#### 2.6.2 Service Annotations (External Integrations)

* You can annotate Services with provider- or controller-specific keys. Examples:

    * **Ingress/LoadBalancer Customization**:

        * Health check paths (e.g., `/healthz`).
        * SSL cert configuration (e.g., AWS ACM certificate ARN for AWS LBs).
        * Idle timeouts, load-balancing algorithm selection.
    * **ExternalDNS**:

        * `external-dns.alpha.kubernetes.io/hostname: example.com`
          → ExternalDNS controller creates DNS A record pointing to the Service’s LoadBalancer IP.
    * **Service Mesh / CNI Plugins**:

        * Istio: `sidecar.istio.io/inject: "true"` to enable sidecar injection.
        * Calico network policy: custom annotations to opt in/out of policy.

> **Note**: Annotations do not alter the core Service behavior; they provide metadata that external controllers read and act upon.

#### 2.6.3 Service Topology and External Traffic Policy

* **externalTrafficPolicy: Local** (vs. `Cluster`):

    * **Local**: Preserve client source IP. Node only routes external traffic to Pods on that same node. If no local Pods, traffic is dropped → LB marks node as unhealthy.
    * **Cluster** (default): Node can NAT external traffic to any Pod in the cluster, potentially across nodes.

* **`topologyKeys` (deprecated in newer versions)**:

    * Allowed traffic routing based on node labels (e.g., same zone, namespace).
    * Replaced by more advanced topology-aware routing in newer Kubernetes versions.

---

### 2.7 Example Service Manifests

#### 2.7.1 Basic ClusterIP Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: api-backend
  labels:
    app: api
spec:
  selector:
    app: api
  ports:
    - port: 5000
      targetPort: 5000
      protocol: TCP
# type: ClusterIP is implicit
```

* Accessible within the cluster at `api-backend.namespace.svc.cluster.local:5000`.

#### 2.7.2 NodePort Service with External Traffic Policy & Session Affinity

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-nodeport
  annotations:
    external-dns.alpha.kubernetes.io/hostname: www.example.com
spec:
  type: NodePort
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 8080
      nodePort: 31000        # must be in 30000–32767
      protocol: TCP
  externalTrafficPolicy: Local
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 3600
```

* Exposed at `<NodeIP>:31000`.
* Only routes to Pods on the same node (`Local`).
* Client IP is preserved and “sticky” for 1 hour.

#### 2.7.3 LoadBalancer Service (AWS Example)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: redis-lb
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: tcp
    service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "6379"
    service.beta.kubernetes.io/aws-load-balancer-ssl-cert: arn:aws:acm:us-west-2:123456789012:certificate/abcdefg
spec:
  type: LoadBalancer
  selector:
    app: redis
  ports:
    - name: redis
      port: 6379
      targetPort: 6379
      protocol: TCP
```

* In AWS EKS, this provisions an ELB that listens on 6379 (TLS) and forwards to Redis Pods.

#### 2.7.4 ExternalName Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: legacy-db
spec:
  type: ExternalName
  externalName: db.legacy.example.net
```

* Pods querying `legacy-db.namespace.svc.cluster.local` get a CNAME pointing to `db.legacy.example.net`.

---

### 2.8 Best Practices for Services

1. **Use ClusterIP for Intra-Cluster Communication**

    * Unless you need external exposure, keep Services as `ClusterIP`.

2. **Limit NodePort Usage**

    * Prefer `LoadBalancer` (in cloud) or Ingress. NodePorts expose nodes directly and can conflict with firewalls.

3. **Prefer Headless Services for StatefulSets**

    * Use `clusterIP: None` so StatefulSets get stable DNS entries per Pod (e.g., `statefulset-0.statefulset.namespace.svc.cluster.local`).

4. **Annotate Services for External Integrations**

    * If using a cloud LB, add provider-specific annotations (health checks, SSL certs).
    * If using ExternalDNS, annotate for automatic DNS record creation.

5. **Control External Traffic Policy**

    * Choose `Cluster` vs. `Local` based on whether preserving client IP is important.
    * If using `Local`, ensure Pods are spread across nodes to avoid dropped traffic.

6. **Leverage Session Affinity Sparingly**

    * Only for legacy stateful workloads that cannot externalize session state. Session affinity can skew load distribution.

7. **Monitor Endpoints Health**

    * Regularly `kubectl get endpoints <svc-name>` to confirm Pods appear as expected.
    * If `endpoints` is empty, no Pods match the selector → Service will drop traffic. Use `kubectl describe service <svc-name>` to see events.

8. **Namespace Segmentation**

    * Place Services and their Pods in the same namespace.
    * Use Network Policies to restrict which namespaces/Pods can talk to which Services.

---

<a name="ingress"></a>

## 3. Kubernetes Ingress

An **Ingress** is a Kubernetes API object that defines rules for routing external HTTP/HTTPS traffic to Services within the cluster. Unlike Service types like `NodePort` or `LoadBalancer`, Ingress consolidates HTTP(S) routing (hostnames, paths, TLS, rewrites) in a single object. However, an Ingress resource by itself does nothing— you must install an **Ingress Controller** (e.g., NGINX, Traefik, HAProxy) that watches Ingress resources and configures a reverse proxy.

---

### 3.1 What Is an Ingress and Why It Matters

* **Definition**: A collection of rules specifying how to route HTTP(S) traffic based on:

    * Hostnames (e.g., `foo.example.com`, `bar.example.com`)
    * URL paths (e.g., `/api`, `/ui`)
    * TLS/SSL certificates for HTTPS.
* **Purpose**:

    * **Consolidate** traffic management: Instead of provisioning multiple `LoadBalancer` Services, use one Ingress with many host/path rules.
    * **Virtual hosting**: Host multiple domains behind a single external IP.
    * **Centralize TLS termination**: Offload SSL/TLS to the Ingress Controller, so backend Pods only need to serve HTTP.

Ingress became stable in Kubernetes v1.19. It is ideal for hosting web applications, APIs, or any HTTP(S) workloads.

---

### 3.2 Components of Ingress

1. **Ingress Resource** (YAML object):

    * Defines routing rules mapping hostnames and paths to backend Services.
    * Optionally includes TLS configuration (which hostnames use which TLS secrets).

2. **Ingress Controller**:

    * A Deployment (or DaemonSet) running inside the cluster.
    * Watches Ingress resources and configures a proxy (e.g., NGINX, Envoy) to implement the rules.
    * Typically fronted by a `LoadBalancer` or `NodePort` Service so external traffic can reach it.
    * Examples:

        * **NGINX Ingress Controller**
        * **Traefik**
        * **HAProxy Ingress**
        * **Istio Ingress Gateway** (part of Istio service mesh)
        * Cloud-specific controllers (e.g., GCE Ingress Controller for GCP, AWS ALB Ingress Controller).

> **Important**: You must install at least one Ingress Controller. Without it, Ingress resources have no effect.

---

### 3.3 Anatomy of an Ingress Resource

Below is a basic Ingress manifest illustrating host- and path-based routing with TLS:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx            # Specifies which Ingress Controller (class) handles this
  tls:
    - hosts:
        - shop.example.com
      secretName: shop-tls-secret    # Kubernetes Secret holding TLS cert/key
  rules:
    - host: shop.example.com
      http:
        paths:
          - path: /cart
            pathType: Prefix
            backend:
              service:
                name: cart-service
                port:
                  number: 80
          - path: /checkout
            pathType: Prefix
            backend:
              service:
                name: checkout-service
                port:
                  number: 80
```

#### Breakdown

* **`metadata.annotations`**:

    * Controller-specific hints (e.g., NGINX rewrite rules).
* **`spec.ingressClassName`**:

    * Binds to a specific Ingress Controller (e.g., `nginx`). If omitted, the cluster’s default IngressClass is used.
* **`spec.tls`**:

    * List of TLS blocks. Each block includes:

        * `hosts`: Hostnames to be served over HTTPS.
        * `secretName`: Name of a `kubernetes.io/tls` Secret containing `tls.crt` and `tls.key`.
* **`spec.rules`**:

    * Each rule has:

        * `host`: The hostname (must match the Host header of incoming requests).
        * `http.paths`: A list of path rules.

            * `pathType`:

                * `Prefix`: Matches paths that begin with the specified value (e.g., `/cart`).
                * `Exact`: Only matches exactly `/cart`.
                * `ImplementationSpecific`: Behavior depends on controller.
            * `backend` → `service.name` & `service.port.number`: The Service that should receive the traffic.

> **Behaviour**
>
> 1. Client connects to `https://shop.example.com:443`.
> 2. Ingress Controller presents the TLS certificate from `shop-tls-secret`.
> 3. If URL path starts with `/cart`, traffic goes to `cart-service:80`.
> 4. If URL path starts with `/checkout`, traffic goes to `checkout-service:80`.
> 5. If no rule matches, the Ingress returns a 404 or default backend (if configured).

---

### 3.4 Common Ingress Controller Implementations

* **NGINX Ingress Controller** (most widely used)

    * Relies on NGINX as the reverse proxy.
    * Supports annotations for timeouts, rewriting, SSL settings, rate limiting, etc.
* **Traefik**

    * Kubernetes-native, dynamic configuration.
    * Reads Ingress resources directly to configure routes.
* **HAProxy Ingress Controller**

    * Uses HAProxy’s high performance for HTTP routing.
* **Istio Ingress Gateway**

    * Part of Istio service mesh, uses Envoy to handle L7 traffic.
    * Provides advanced features: traffic shifting, canaries, observability.
* **Cloud-Specific Controllers**

    * GKE’s GCE Ingress Controller: Provisions Google Cloud Load Balancers.
    * AWS ALB Ingress Controller: Provisions AWS ALB (Application Load Balancer).
    * Azure Application Gateway Ingress Controller: Provisions Azure Application Gateway.

---

### 3.5 TLS Termination and Certificates

1. **Create a TLS Secret**

    * Format: `kubernetes.io/tls`
    * Fields:

        * `tls.crt`: PEM-encoded certificate (can include chain).
        * `tls.key`: PEM-encoded private key.
    * Example:

      ```bash
      kubectl create secret tls shop-tls-secret \
        --cert=shop.example.com.crt \
        --key=shop.example.com.key
      ```

2. **Reference the Secret in the Ingress**

   ```yaml
   spec:
     tls:
       - hosts:
           - shop.example.com
         secretName: shop-tls-secret
   ```

    * The Ingress Controller uses that certificate to handle HTTPS on port 443.

3. **Fallback Behavior**

    * If a request arrives for a hostname not listed under `spec.tls`, the TLS handshake may fail or the controller may present a default certificate (depends on controller configuration).

4. **Annotations for SSL Settings** (NGINX example)

   ```yaml
   metadata:
     annotations:
       nginx.ingress.kubernetes.io/ssl-redirect: "true"
       nginx.ingress.kubernetes.io/hsts-max-age: "15724800"
   ```

    * Forces HTTP → HTTPS, sets HSTS headers, etc.

> **Benefit**: Backend Pods serve plain HTTP. TLS is managed at the Ingress, centralizing certificate management.

---

### 3.6 Advanced Ingress Features

#### 3.6.1 Path vs. Exact Matching

* **`pathType: Prefix`**
  Matches paths beginning with the specified value. E.g., `/images` matches `/images/cat.jpg` and `/images/subdir/puppy.png`.
* **`pathType: Exact`**
  Only matches the exact path. `/images` matches only `/images` (not `/images/anything-else`).
* **`pathType: ImplementationSpecific`**
  Delegates matching to the controller. Behavior may vary (often treated like `Prefix`).

#### 3.6.2 Rewrites and Redirects (NGINX Example)

* Use annotations to rewrite the path before sending to the backend:

  ```yaml
  metadata:
    annotations:
      nginx.ingress.kubernetes.io/rewrite-target: /
  spec:
    rules:
      - host: example.com
        http:
          paths:
            - path: /app
              pathType: Prefix
              backend:
                service:
                  name: myapp-service
                  port:
                    number: 80
  ```

    * Requests to `example.com/app/foo` get rewritten to `/foo` when forwarded to `myapp-service`.

#### 3.6.3 Default Backend

* If no rule matches a request’s hostname or path:

    * The Ingress Controller can return a 404.
    * Or route to a **default backend** Service (e.g., a simple “404 page” Service).
* Default backend is configured at the controller level (e.g., in the controller’s ConfigMap or command-line flags).

---

### 3.7 Exposing an Ingress Controller

To allow external traffic to reach the Ingress Controller’s proxy, you commonly use one of:

1. **LoadBalancer Service**

    * The Ingress Controller Deployment is fronted by a Service of type `LoadBalancer`.
    * Example: NGINX Ingress Controller often creates a Service named `ingress-nginx` (type: `LoadBalancer`).
    * Cloud provider provisions an external LB → external IP → traffic flows to Ingress Controller pods.

2. **NodePort Service**

    * If no cloud LB is available, expose the Ingress Controller via a Service of type `NodePort`.
    * You must instruct clients (or DNS) to point to `<NodeIP>:<NodePort>` on your cluster’s nodes.

3. **HostPort / HostNetwork**

    * For bare-metal clusters, Ingress Controller pods set `hostNetwork: true` or use `hostPort: 80/443`.
    * The node’s IP serves as the endpoint directly on ports 80/443.
    * Risk of port conflicts if multiple pods try to bind the same host port.

Once the Ingress Controller is reachable (external IP or NodePort), creating or updating Ingress resources automatically updates the underlying proxy configuration.

---

### 3.8 Example Workflow: Deploying an Ingress

1. **Deploy Backend Services**

    * Create two Deployments + Services (ClusterIP):

        * `cart-service` (port 80).
        * `checkout-service` (port 80).
    * E.g.:

      ```yaml
      apiVersion: v1
      kind: Service
      metadata:
        name: cart-service
        namespace: shop
      spec:
        selector:
          app: cart
        ports:
          - port: 80
            targetPort: 8080
      ```

2. **Install an Ingress Controller**

    * For example, NGINX Ingress Controller via Helm chart or manifest.
    * Creates:

        * Deployment/DaemonSet for NGINX Controller Pods.
        * Service (type `LoadBalancer`) named `ingress-nginx` with an external IP (in cloud).

3. **Create TLS Secret**

   ```bash
   kubectl create secret tls shop-tls-secret \
     --cert=shop.example.com.crt \
     --key=shop.example.com.key
   ```

    * Stores cert/key for `shop.example.com` in namespace (often `cluster-system` or `shop`).

4. **Define Ingress Resource**

   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: example-ingress
     namespace: shop
     annotations:
       nginx.ingress.kubernetes.io/rewrite-target: /
   spec:
     ingressClassName: nginx
     tls:
       - hosts:
           - shop.example.com
         secretName: shop-tls-secret
     rules:
       - host: shop.example.com
         http:
           paths:
             - path: /cart
               pathType: Prefix
               backend:
                 service:
                   name: cart-service
                   port:
                     number: 80
             - path: /checkout
               pathType: Prefix
               backend:
                 service:
                   name: checkout-service
                   port:
                     number: 80
   ```

5. **Validate**

    * Check Ingress status:

      ```bash
      kubectl get ingress example-ingress -n shop
      # Should show an ADDRESS (external IP or hostname)
      ```
    * Ensure DNS for `shop.example.com` points to the Ingress Controller’s address (or add to `/etc/hosts` for testing).
    * Test with `curl` or browser:

      ```bash
      curl -i http://<ingress-address>/cart/items
      # Response from cart-service Pod
      curl -i https://shop.example.com/checkout
      # Response from checkout-service (with TLS)
      ```
    * Inspect controller logs:

      ```bash
      kubectl logs deployment/ingress-nginx-controller -n ingress-nginx
      ```

---

### 3.9 Best Practices for Ingress

1. **Specify `ingressClassName` Explicitly**

    * In clusters with multiple Ingress controllers, pin the Ingress to the intended controller.
    * Example: `spec.ingressClassName: nginx`.

2. **Use Secure Defaults**

    * Enable HTTP → HTTPS redirect:

      ```yaml
      metadata:
        annotations:
          nginx.ingress.kubernetes.io/ssl-redirect: "true"
          nginx.ingress.kubernetes.io/hsts: "true"
      ```
    * Enforce HSTS (`hsts-max-age`, `hsts-include-subdomains`, etc.).

3. **Limit Path Rewrites**

    * Keep rewrites predictable. Complex rewrites can confuse users (URL vs. backend path).

4. **Leverage Annotations for Fine-Grained Control**

    * Each controller supports custom annotations (timeouts, buffering, rate-limiting, custom error pages).
    * Always consult controller docs (e.g., [NGINX Ingress annotations](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/)).

5. **Monitor Backend Health**

    * Ensure Services referenced by Ingress have healthy endpoints (`kubectl get endpoints <service>`).
    * If no endpoints exist, Ingress returns 502/503.

6. **Authentication, Rate Limiting, Security**

    * Use annotations for BasicAuth, OAuth, or WAF (Web Application Firewall) integrations.
    * Example (NGINX):

      ```yaml
      metadata:
        annotations:
          nginx.ingress.kubernetes.io/enable-global-auth: "true"
      ```
    * Consider using external WAF (e.g., ModSecurity) for public-facing apps.

7. **Version Control Ingress Manifests**

    * Store Ingress YAML in Git alongside other manifests.
    * Changes to hostnames, TLS, or paths become auditable.

8. **Consider Gateway API for Future-Proofing**

    * If you need advanced traffic splitting, header-based routing, multi-cluster, or service-mesh integration, evaluate Gateway API (covered next).
    * Ingress API is feature-frozen; Gateway API is the evolution path.

---

<a name="gateway-api"></a>

## 4. Gateway API

The **Gateway API** is a set of Kubernetes CRDs (Custom Resource Definitions) designed to replace and extend Ingress. It provides a more expressive, extensible, and role-oriented way to configure L3–L7 traffic routing. Gateway API separates concerns among stakeholders (infrastructure, cluster operators, application developers) and supports advanced features such as multi-cluster, multi-protocol (HTTP, TCP, TLS, gRPC), and granular TLS policies.

---

### 4.1 Gateway API Overview and Motivation

**Problems with Ingress**:

* Uses annotations for advanced features (e.g., rewrites, TLS policies, traffic splitting) which are unstructured and controller-specific.
* Single monolithic resource complicates multi-controller/multi-team environments.
* Limited support for routing beyond HTTP (no built-in gRPC or raw TCP routes).

**Gateway API Goals**:

1. **Role-Oriented**

    * Separate responsibilities among Infrastructure Providers, Cluster Operators, and Application Developers.
2. **Portable**

    * Defined as Kubernetes CRDs (`GatewayClass`, `Gateway`, `Route` kinds). Multiple implementations (NGINX, Envoy, Traefik, GKE, AWS ALB, etc.) can consume the same manifests.
3. **Expressive**

    * Native support for protocol-aware matching (HTTP headers, gRPC methods, TLS SNI, raw TCP), traffic splitting/weighting, advanced TLS configuration.
4. **Extensible**

    * Allows custom route kinds (e.g., GRPCRoute, TLSRoute) and additional policy CRDs (e.g., BackendTLSPolicy) without annotation hacks.

---

### 4.2 Key Design Principles

1. **Role-Oriented**

    * **Infrastructure Provider**: Defines a `GatewayClass` (the blueprint for L7 controllers, such as “nginx-gateway-controller” or “aws-alb-controller”).
    * **Cluster Operator**: Instantiates `Gateway` objects (concrete instances with specific configuration, node selectors, IP pools, etc.).
    * **Application Developer**: Creates `Route` objects (e.g., `HTTPRoute`, `TCPRoute`, `GRPCRoute`) that bind to a Gateway to specify how traffic is mapped to backends.

2. **Portable**

    * A single set of YAML manifests works across different environments and controllers (as long as controllers support the same API version and features).

3. **Expressive**

    * Direct support for path, header, method, query param matching (not via annotations).
    * Traffic splitting by weight.
    * Protocol-specific routing (e.g., `GRPCRoute`).

4. **Extensible**

    * Defined extension points (e.g., custom CRDs like `BackendTLSPolicy` or future route kinds) that integrate seamlessly.

---

### 4.3 Core Gateway API Kinds

#### 4.3.1 GatewayClass (`gateway.networking.k8s.io/v1beta1`)

* **Role**: Defined by Infrastructure Provider (e.g., cloud vendor, CNI plugin).
* **Purpose**: Acts as a “blueprint” for Gateways. Associates a controller string with parameters (e.g., AWS ALB, NGINX).
* **Spec Fields**:

    * `controller`: Unique identifier (e.g., `example.com/nginx-gateway-controller`).
    * `parametersRef` (optional): Reference to a provider-specific parameters object (e.g., tags, SSL cert pools).

**Example**:

```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: GatewayClass
metadata:
  name: example-nginx-gatewayclass
spec:
  controller: example.com/nginx-gateway-controller
```

* Once created, only a controller whose name matches `spec.controller` can claim Gateways that reference this class.

---

#### 4.3.2 Gateway (`gateway.networking.k8s.io/v1beta1`)

* **Role**: Managed by Cluster Operator (or Infrastructure Provider via controller).

* **Purpose**: Defines an instance of traffic-handling infrastructure (e.g., a cloud load balancer or an NGINX proxy setup) at the cluster or namespace level.

* **Spec Fields**:

    * `gatewayClassName` (required): Name of a `GatewayClass`.
    * `listeners`: List of `Listener` objects, each specifying:

        * `name` (string).
        * `protocol` (HTTP, HTTPS, TCP, TLS, UDP).
        * `port` (integer 1–65535).
        * For HTTPS/TLS: a `tls` block pointing to one or more certificate Secrets.
        * `allowedRoutes`: Filter specifying which `Route` CRs (by namespace, labels) are allowed to bind.

* **Status Fields**:

    * Usually includes `addresses` (e.g., external IP or hostname) once the Gateway is provisioned by its controller.

**Example**:

```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: example-gateway
  namespace: cluster-system
spec:
  gatewayClassName: example-nginx-gatewayclass
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      allowedRoutes:
        namespaces:
          from: All
    - name: https
      protocol: HTTPS
      port: 443
      tls:
        certificateRefs:
          - name: shop-tls-secret
      allowedRoutes:
        namespaces:
          from: All
```

* The controller for `example-nginx-gatewayclass` sees this Gateway, provisions an NGINX proxy (or cloud LB), and exposes it on ports 80/443 with TLS from `shop-tls-secret`.
* `allowedRoutes.namespaces.from: All` means any Route in any namespace can bind (unless further restricted by labels).

---

#### 4.3.3 Routes (e.g., HTTPRoute, TCPRoute, TLSRoute, GRPCRoute)

* **Role**: Defined by Application Developer. Describe application-level routing rules.

* **Purpose**: Associate backend Services (or ExternalServices) with a specific Gateway listener, based on criteria like hostname, path, header, method, SNI, etc.

* **Core Route Kinds**:

    1. **HTTPRoute** (`gateway.networking.k8s.io/v1beta1`):

        * Matches on HTTP attributes: hostnames, paths, headers, query params, methods.
        * Supports traffic splitting/weighting via multiple `backendRefs`.
    2. **TCPRoute**:

        * Routes raw TCP connections by port to backends.
    3. **TLSRoute**:

        * Matches TLS connections at layer 4 using SNI (Server Name Indication).
        * Forwards encrypted traffic directly to backend (no TLS termination).
    4. **GRPCRoute**:

        * HTTP/2 + gRPC-specific matching (service name, method).
        * Allows granular routing of gRPC calls.

* **Spec Fields (HTTPRoute Example)**:

    * `parentRefs`: Which Gateways (and optionally, which listener by name via `sectionName`) this route binds to.
    * `hostnames`: List of hostnames (e.g., `shop.example.com`).
    * `rules`: Array of rules, each with:

        * `matches`: Criteria (path, header, query, method).
        * `backendRefs`: List of backends (Service names + ports + optional `weight` for traffic splitting).

**HTTPRoute Example**:

```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: shop-router
  namespace: shop
spec:
  parentRefs:
    - name: example-gateway
      sectionName: http
  hostnames:
    - shop.example.com
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /cart
      backendRefs:
        - name: cart-service
          port: 80
          weight: 80
        - name: discount-service
          port: 80
          weight: 20
    - matches:
        - path:
            type: PathPrefix
            value: /checkout
      backendRefs:
        - name: checkout-service
          port: 80
```

* Binds to the `http` listener on `example-gateway`.
* Traffic to `/cart` is split 80/20 between `cart-service` and `discount-service`.
* Traffic to `/checkout` goes to `checkout-service`.

---

### 4.4 How GatewayClass, Gateway, and Routes Relate

```
[GatewayClass] 
      ↑ (className)
      |
[Gateway] ────────► [Listener (protocol, port, TLS)] ── allowedRoutes ──► [Routes (HTTPRoute, TCPRoute, etc.)] ── backends (Services)
```

1. **GatewayClass → Gateway**

    * A Gateway’s `spec.gatewayClassName` must match a `GatewayClass`’s metadata name.
    * Only the controller with matching `spec.controller` handles that Gateway.

2. **Gateway → Listener**

    * Each Gateway defines one or more Listeners (e.g., HTTP on port 80, HTTPS on 443, TCP on 5432).
    * A Listener’s `allowedRoutes` filter (namespaces/from, selectors) determines which Routes can bind.

3. **Route → Gateway Listener**

    * Each Route’s `spec.parentRefs` must refer to the Gateway name and optionally the listener’s `sectionName`.
    * The Gateway’s controller reconciles to attach/configure those Routes.

4. **Route Rules → Backends**

    * Route rules reference Kubernetes Services (or `ExternalService` if supported) via `backendRefs`.
    * Each backend is a Service name + port + optional `weight`.

5. **Traffic Flow**

    * External clients reach the Gateway’s external endpoint (IP, hostname).
    * The controller’s dataplane proxy inspects L7 data (Host header, path, headers, gRPC method, SNI) and forwards to the appropriate Service endpoints (Pods).

---

### 4.5 End-to-End Gateway API Example

Below is a step-by-step example of configuring an HTTP/HTTPS gateway for an ecommerce “shop” application.

#### 4.5.1 Create a GatewayClass (Infrastructure Provider)

```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: GatewayClass
metadata:
  name: example-nginx-gatewayclass
spec:
  controller: example.com/nginx-gateway-controller
```

* The cluster has an NGINX-based controller watching GatewayClasses with `controller: example.com/nginx-gateway-controller`.

#### 4.5.2 Provision a Gateway (Cluster Operator)

```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: shop-gateway
  namespace: cluster-system
spec:
  gatewayClassName: example-nginx-gatewayclass
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      allowedRoutes:
        namespaces:
          from: All
    - name: https
      protocol: HTTPS
      port: 443
      tls:
        certificateRefs:
          - name: shop-tls-secret
      allowedRoutes:
        namespaces:
          from: All
```

* The NGINX controller:

    1. Deploys NGINX pods (or updates existing).
    2. Creates a Service (type: `LoadBalancer`) listening on ports 80/443.
    3. On port 443, uses certificates from `shop-tls-secret` in `cluster-system`.

#### 4.5.3 Define Application Services (Development Team)

```yaml
# cart-service.yaml (namespace: shop)
apiVersion: v1
kind: Service
metadata:
  name: cart-service
  namespace: shop
spec:
  selector:
    app: cart
  ports:
    - port: 80
      targetPort: 8080

---
# checkout-service.yaml (namespace: shop)
apiVersion: v1
kind: Service
metadata:
  name: checkout-service
  namespace: shop
spec:
  selector:
    app: checkout
  ports:
    - port: 80
      targetPort: 8080
```

* Assume two Deployments exist: Pods labeled `app=cart` (listening on 8080) and `app=checkout` (listening on 8080).

#### 4.5.4 Create an HTTPRoute (Application Developer)

```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: shop-route
  namespace: shop
spec:
  parentRefs:
    - name: shop-gateway
      sectionName: http
  hostnames:
    - shop.example.com
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /cart
      backendRefs:
        - name: cart-service
          port: 80
    - matches:
        - path:
            type: PathPrefix
            value: /checkout
      backendRefs:
        - name: checkout-service
          port: 80
```

* Binds to the `http` listener (port 80) on `shop-gateway`.
* Traffic for `shop.example.com/cart` → `cart-service:80`.
* Traffic for `shop.example.com/checkout` → `checkout-service:80`.

#### 4.5.5 Verify End-to-End

1. **Check Gateway Status**

   ```bash
   kubectl get gateway shop-gateway -n cluster-system
   # Look for .status.addresses (external IP or hostname)
   ```

2. **Test HTTP Routing**

   ```bash
   curl http://<gateway-address>/cart/items
   curl http://<gateway-address>/checkout
   ```

3. **Test HTTPS Routing**

    * Ensure DNS or `/etc/hosts` maps `shop.example.com` → `<gateway-address>`.

      ```bash
      curl -k https://shop.example.com/cart
      ```
    * Controller uses `shop-tls-secret` to serve TLS.

4. **Inspect Controller Logs**

   ```bash
   kubectl logs deployment/nginx-gateway-controller -n cluster-system
   ```

    * Look for any errors (e.g., missing TLS secret, unavailable backend).

---

### 4.6 Advanced Gateway API Features

#### 4.6.1 Traffic Splitting and Weighting

* Within a single `HTTPRoute` rule, specify multiple `backendRefs` each with a `weight`:

  ```yaml
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: stable-service
          port: 80
          weight: 90
        - name: canary-service
          port: 80
          weight: 10
  ```

    * Traffic to `/` is split 90% → `stable-service`, 10% → `canary-service`.
* Useful for gradual canary releases or A/B testing without an external tool.

#### 4.6.2 Header, Query, and Method Matching

* `HTTPRoute.spec.rules[].matches` can include:

    * **Headers**:

      ```yaml
      matches:
        - headers:
            - name: "X-User-Type"
              value: "premium"
      ```
    * **Query Params**:

      ```yaml
      matches:
        - queryParams:
            - name: "version"
              value: "beta"
      ```
    * **HTTP Methods**:

      ```yaml
      matches:
        - method:
            name: GET
      ```
* Enables advanced routing (e.g., route only `POST /write` to write-backend).

#### 4.6.3 TLS Passthrough and SNI (TLSRoute)

* Use `TLSRoute` to match TLS via SNI without terminating:

  ```yaml
  apiVersion: gateway.networking.k8s.io/v1beta1
  kind: TLSRoute
  metadata:
    name: shop-tlsroute
    namespace: shop
  spec:
    parentRefs:
      - name: shop-gateway
        sectionName: https
    hostnames:
      - api.shop.example.com
    rules:
      - matches:
          - sniHosts: ["api.shop.example.com"]
        backendRefs:
          - name: backend-tls-service
            port: 443
  ```
* Gateway forwards encrypted TLS traffic directly to `backend-tls-service:443`, preserving end-to-end encryption.

#### 4.6.4 gRPC Routing (GRPCRoute)

* Routes gRPC methods to different backends:

  ```yaml
  apiVersion: gateway.networking.k8s.io/v1beta1
  kind: GRPCRoute
  metadata:
    name: shopping-grpc-route
    namespace: shop
  spec:
    parentRefs:
      - name: shop-gateway
        sectionName: http
    hostnames:
      - grpc.shop.example.com
    rules:
      - matches:
          - method:
              name: GetCart
        backendRefs:
          - name: shopping-grpc-svc
            port: 50051
      - matches:
          - method:
              name: Checkout
        backendRefs:
          - name: checkout-grpc-svc
            port: 50052
  ```
* Useful for microservices architecture with gRPC-based APIs, allowing per-method routing.

#### 4.6.5 Backend TLS Policy (BackendTLSPolicy)

* Introduced in Gateway API v1.2, lets you configure TLS from Gateway to backend Pods (end-to-end TLS).

  ```yaml
  apiVersion: gateway.networking.k8s.io/v1alpha2
  kind: BackendTLSPolicy
  metadata:
    name: service-tls-policy
    namespace: shop
  spec:
    targetRef:
      group: ""
      kind: Service
      name: backend-service
    tls:
      certificateRefs:
        - name: backend-cert-secret
      mode: RequireTLS
      validation:
        caCertificates:
          secretName: backend-ca-secret
  ```
* **`mode: RequireTLS`**: Gateway uses TLS when connecting to `backend-service`.
* **`validation.caCertificates`**: Gateway verifies server certificates from backend Pods.
* Can enforce mTLS if backend Pods present client certificates.

---

### 4.7 Lifecycle and Status of Gateway Resources

1. **GatewayClass Creation**

    * Administrator applies a `GatewayClass`.
    * Controller watches and updates `GatewayClass.status.conditions` (e.g., `Accepted`: `True`).

2. **Gateway Creation**

    * Applying a `Gateway` triggers its controller (as per `gatewayClassName`).
    * Controller provisions dataplane resources (e.g., cloud load balancer or NGINX pods).
    * Once ready, `Gateway.status.addresses` lists external IPs/hostnames.

3. **Route Creation**

    * Developers create `HTTPRoute`, `TCPRoute`, etc.
    * Controller examines each `parentRefs` to see which Gateway(s) to bind.
    * If accepted, `HTTPRoute.status.parents` shows which Gateways/listeners are bound and any conflicts.

4. **Traffic Flow**

    * Clients send HTTP/TLS requests to the Gateway’s address.
    * Gateway’s dataplane proxy matches rules from attached routes and forwards to backend Service endpoints.

5. **Updates**

    * Modifying a `Route` (e.g., adding a path) or a `Gateway` (e.g., adding a new listener) triggers reconciliation.
    * Controller pushes updated configuration to the dataplane (e.g., reloads NGINX, reconfigures cloud LB).

6. **Deletion**

    * Deleting a `Route` removes it from Gateway’s configuration (requests no longer match).
    * Deleting a `Gateway` (once no Routes reference it) causes controller to tear down underlying infrastructure (e.g., cloud LB).

Throughout, **status.conditions** on each resource (e.g., `Ready`, `ResolvedRefs`, `Accepted`) help diagnose misconfigurations (e.g., missing TLS secret, overlapping host rules).

---

### 4.8 Migrating from Ingress to Gateway API

* **Ingress is Feature-Frozen**. Gateway API is the forward-looking replacement.
* **Key Migration Steps**:

    1. **Convert Ingress rules → HTTPRoute**

        * Host and path matches map directly to `HTTPRoute.spec.hostnames` and `spec.rules.matches.path`.
        * Annotations (e.g., rewrites, timeouts) often map to built-in fields or Gateway annotations.
    2. **Define a GatewayClass + Gateway** instead of relying on default Ingress controller.

        * Choose distinct classes for different workloads (e.g., `public-nginx-gatewayclass`, `internal-alb-gatewayclass`).
    3. **Use richer matching** (headers, methods, gRPC) where needed instead of hacky annotations.
* **Benefits**:

    * Separate concerns between cluster operators (who provision Gateways) and application developers (who write Routes).
    * Avoid reliance on controller-specific annotations.
    * Future-proof: Gateway API evolves (e.g., v1.1, v1.2 adding gRPC, advanced TLS features).

---

### 4.9 Best Practices for Gateway API

1. **Always Specify `ingressClassName` / `gatewayClassName`**

    * Prevent ambiguity in multi-controller clusters.

2. **Use Namespaces to Isolate Routes**

    * `HTTPRoute` in namespace `A` can only bind to Gateways that allow routes from that namespace (`allowedRoutes.namespaces.from: Selector` or `All`).
    * Use labels on Routes and Gateways to enforce scoping.

3. **Keep TLS Secrets in the Same Namespace as `Gateway`**

    * Most controllers require TLS `Secret` to reside in the Gateway’s namespace, unless cross-namespace references are supported.

4. **Use `BackendTLSPolicy` for End-to-End Security**

    * For sensitive workloads, ensure TLS is used from Gateway → backend Pods, not just at the client side.

5. **Monitor `status.conditions` on Resources**

    * **GatewayClass**: `Accepted: True` indicates the controller recognizes it.
    * **Gateway**: `Ready: True` indicates dataplane resources are provisioned.
    * **HTTPRoute (and others)**: `ResolvedRefs: True`, `Accepted: True` indicates routes are bound.

6. **Plan for Traffic Splitting and Canary Releases**

    * Use `weight` in `backendRefs` to shift traffic gradually.
    * Keep stable and canary backends in the same `HTTPRoute`.

7. **Namespace and Label-Based Access Controls**

    * Leverage `allowedRoutes` on `Listener` to restrict which namespaces or labeled Routes can bind (e.g., only routes in `prod` namespace).

8. **Extend with Custom Routes or Policies**

    * If you need Kafka routing, or additional TLS negotiation policies, Gateway API’s extension model allows custom CRDs (e.g., `KafkaRoute`, `ReferenceGrant` for cross-namespace references).

9. **When to Use Gateway API vs. Ingress**

    * **Gateway API**: You need advanced L7 features (header-based routing, traffic weighting, fine-grained TLS), multi-team isolation, or plan to integrate with a service mesh.
    * **Ingress**: Simple HTTP-only routing in a single namespace may not require the complexity of Gateway API. But note: Gateway API is the road ahead.

---

<a name="network-policies"></a>

## 5. Kubernetes Network Policies

**Network Policies** provide a namespaced way to control how Pods are allowed to communicate with each other and with external network endpoints. In Kubernetes, the default is “all traffic allowed.” Network Policies let you implement a “zero-trust” or “least-privilege” model by explicitly whitelisting which sources (Pods, namespaces, or CIDRs) can connect to which Pods, on which ports/protocols.

---

### 5.1 Why Network Policies Matter

* **Flat Networking by Default**: All Pods can talk to any other Pod and any external IP unless restricted.

* **Security & Compliance**:

    * Microsegmentation: Only allow specific Pod-to-Pod connections (e.g., front-end → back-end database).
    * Prevent lateral movement: If one Pod is compromised, block it from reaching sensitive Pods.
    * Egress Control: Limit Pods’ outbound traffic (e.g., only allow calls to specific external APIs or logs endpoints).
    * Regulatory Requirements: Many compliance frameworks (PCI-DSS, HIPAA, GDPR) mandate network segmentation.

* **Namespace-Scoped**: Policies apply at the namespace level. You can give each application or team its own set of policies without impacting others.

---

### 5.2 How Network Policies Work

A **NetworkPolicy** object defines:

1. **Pod Selector**: Which Pods (in the namespace) the policy applies to.
2. **Policy Types**: One or both of:

    * `Ingress`: Controls inbound traffic to the selected Pods.
    * `Egress`: Controls outbound traffic from the selected Pods.
3. **Rules**: For each type, a list of “allow” rules specifying:

    * **Peers**: Which sources (for Ingress) or destinations (for Egress) are allowed. Peers can be:

        * `podSelector` (same namespace).
        * `namespaceSelector` (labels on other namespaces).
        * `ipBlock` (CIDR ranges, with optional exclusions).
    * **Ports**: Which port(s) + protocol(s) are allowed.

> **Important**: Network Policies are **whitelists**.
>
> * If a Pod is not selected by any NetworkPolicy, it is wide open (Ingress and Egress allowed).
> * If a Pod is selected by a policy that specifies only Ingress rules (and no Egress block), inbound traffic is restricted per rules, but outbound remains allowed.
> * Defining a policy with zero Ingress rules but `policyTypes: [Ingress]` means “deny all ingress” to selected Pods.

---

### 5.3 NetworkPolicy API Overview

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: my-network-policy
  namespace: my-namespace
spec:
  podSelector:                # which Pods this policy applies to
    matchLabels:
      role: db
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              role: frontend
        - namespaceSelector:
            matchLabels:
              environment: production
      ports:
        - protocol: TCP
          port: 5432
  egress:
    - to:
        - ipBlock:
            cidr: 10.0.0.0/16
            except:
              - 10.0.5.0/24
      ports:
        - protocol: TCP
          port: 1234
```

#### 5.3.1 `podSelector`

* Selects Pods in the same namespace by label.
* If empty (`{}`), selects **all Pods** in that namespace.

#### 5.3.2 `policyTypes`

* A list containing one or both of:

    * `Ingress`
    * `Egress`
* If omitted, the default is `Ingress` only (for backward compatibility).

#### 5.3.3 `ingress` Rules

Each item in the `ingress` array is an “allow” rule.

* **`from`**: Array of peer definitions (OR logic). Each can be:

    * `podSelector`: Pods in the same namespace matching labels.
    * `namespaceSelector`: Pods in any namespace matching namespace labels.
    * `ipBlock`: IP CIDR (with optional `except`).
* **`ports`**: Array of ports (protocol + port). Only these destination ports on the Pod are allowed. If `ports` omitted, any port is allowed (for matched peers).

Example:

```yaml
ingress:
  - from:
      - podSelector:
          matchLabels:
            role: frontend
      - namespaceSelector:
          matchLabels:
            environment: production
    ports:
      - protocol: TCP
        port: 5432
```

* Allow inbound TCP traffic to port 5432 on selected Pods if the source Pod is:

    1. In the same namespace with `role=frontend`, OR
    2. In a namespace labeled `environment=production`.

#### 5.3.4 `egress` Rules

Each item in the `egress` array is an “allow” rule for outbound traffic from selected Pods.

* **`to`**: Array of peer definitions (OR logic): `podSelector`, `namespaceSelector`, `ipBlock`.
* **`ports`**: Array of destination ports (protocol + port). If omitted, any destination port is allowed.

Example:

```yaml
egress:
  - to:
      - ipBlock:
          cidr: 10.0.0.0/16
          except:
            - 10.0.5.0/24
    ports:
      - protocol: TCP
        port: 1234
```

* Allow outbound TCP traffic **only** to any IP in `10.0.0.0/16` except `10.0.5.0/24`, on port 1234. All other egress is rejected.

---

### 5.4 Common NetworkPolicy Examples

#### 5.4.1 Deny All Ingress Except Specific Pods

Label Pods that **are** allowed:

```bash
kubectl label pod frontend-1 -n team-a allow=true
kubectl label pod frontend-2 -n team-a allow=true
```

Create a policy:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress-except-allowed
  namespace: team-a
spec:
  podSelector: {}             # applies to all Pods in team-a
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              allow: "true"
```

* Any Pod without label `allow=true` cannot receive any inbound traffic.
* Egress is still allowed (no Egress block present).

To also deny all egress, add:

```yaml
  policyTypes:
    - Ingress
    - Egress
  egress: []
```

---

#### 5.4.2 Allow Ingress Only from Same Namespace

Allow only traffic from Pods in namespace `team-b` to Pods labeled `role=db` in `team-b`:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-allow-team-communication
  namespace: team-b
spec:
  podSelector:
    matchLabels:
      role: db
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: team-b
```

* Any Pod in namespaces other than `team-b` cannot connect to `role=db` Pods on any port.

---

#### 5.4.3 Restrict Egress to an External CIDR/Service

Suppose Pods in namespace `logging` must send logs **only** to `10.1.1.100/32` on TCP port 514:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-syslog-egress
  namespace: logging
spec:
  podSelector: {}  # all Pods in logging
  policyTypes:
    - Egress
  egress:
    - to:
        - ipBlock:
            cidr: 10.1.1.100/32
      ports:
        - protocol: TCP
          port: 514
```

* Outbound to any other IP/port is blocked.
* Ingress remains wide-open (unless another policy exists).

---

#### 5.4.4 Three-Tier Pod-to-Pod Whitelisting

Namespace: `prod`
Tiers: `web`, `app`, `db`.

* **Requirement**:

    * `web` Pods can talk to `app` Pods on port 8080 only.
    * `app` Pods can talk to `db` Pods on port 5432 only.
    * No other inbound connections are allowed to `app` or `db`.

**Step 1: Allow only `web` → `app` (deny all other ingress to `app`):**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: app-deny-all-except-web
  namespace: prod
spec:
  podSelector:
    matchLabels:
      tier: app
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              tier: web
      ports:
        - protocol: TCP
          port: 8080
```

**Step 2: Allow only `app` → `db` (deny all other ingress to `db`):**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-deny-all-except-app
  namespace: prod
spec:
  podSelector:
    matchLabels:
      tier: db
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              tier: app
      ports:
        - protocol: TCP
          port: 5432
```

* `web` Pods have no policy selecting them → they remain fully allowed (both Ingress and Egress).
* `app` Pods can receive traffic only from `web` on port 8080; outbound from `app` remains allowed by default.
* `db` Pods can receive traffic only from `app` on port 5432; their outbound is open by default.

> **Note**: If you want to lock down egress (e.g., prevent `app` Pods from calling external services), add an Egress policy for them.

---

### 5.5 CNI Requirements and Enforcement

* **Network Policy Enforcement** is done by the cluster’s **CNI plugin**.
* **Not all CNIs support Network Policies**. Popular CNIs that do include:

    * **Calico**
    * **Cilium**
    * **Weave Net** (in “Weave Net Plugin” mode)
    * **Antrea**
    * **Canal** (Calico + Flannel)
    * **Kube-Router**
* If your CNI does **not** implement NetworkPolicy, the policies exist in the API server but have **no effect** (Pods remain open).
* Always verify CNI compatibility before relying on Network Policies for security.

---

### 5.6 Debugging and Observability

When traffic is unexpectedly blocked or allowed, use the following steps:

1. **Confirm Pod and Endpoints**

    * Ensure both client and server Pods are running and labeled correctly:

      ```bash
      kubectl get pods -l tier=app -n prod
      kubectl describe pod app-xyz-123 -n prod
      ```

2. **Verify NetworkPolicy Selection**

    * Describe the policy to see which Pods it selects:

      ```bash
      kubectl describe networkpolicy app-deny-all-except-web -n prod
      ```
    * Confirm `podSelector` matches intended Pods.
    * Check `policyTypes` and that `ingress`/`egress` rules align with expectations.

3. **Check CNI Enforcement**

    * Many CNIs provide commands or dashboards to view active policies:

        * **Calico**:

          ```bash
          calicoctl get networkpolicies -o wide
          calicoctl policy get
          ```
        * **Cilium**:

          ```bash
          cilium policy get
          cilium status
          ```
    * These show which policies are applied on each node and any dropped traffic logs.

4. **Test Connectivity from Inside a Pod**

    * Exec into a client Pod and use `curl`, `nc`, or `telnet` to test:

      ```bash
      kubectl exec -it <client-pod> -n prod -- sh
      # Inside Pod shell:
      nc -vz db-service 5432
      ```
    * A refused or timed-out connection indicates either the Service is unavailable or a NetworkPolicy is blocking it.

5. **Check Service Endpoints**

    * If using a Service, ensure it has endpoints:

      ```bash
      kubectl get endpoints db-service -n prod
      ```
    * If Endpoints is empty, the Service isn’t routing to any Pods, so traffic never reaches the Pod layer.

6. **Logging & Packet Captures (Advanced)**

    * Some CNIs (Calico, Cilium) can log dropped packets or allow `tcpdump` on host veth interfaces to see exactly why a flow is blocked.
    * Consult your CNI’s documentation for enabling debug/packet capture.

---

### 5.7 Best Practices and Considerations for Network Policies

1. **Start with “Deny All” and Gradually Open**

    * Create a default policy that denies all ingress and/or egress in a namespace, then add specific allow rules.

   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: deny-all
     namespace: secure-ns
   spec:
     podSelector: {}
     policyTypes:
       - Ingress
       - Egress
     ingress: []  # no allow rules → deny all inbound
     egress: []   # no allow rules → deny all outbound
   ```

    * This “fail-closed” approach prevents accidental wide-open holes.

2. **Label Consistently**

    * Establish a labeling scheme (e.g., `app=frontend`, `app=db`, `environment=prod`) and use these labels in both Pod specs and NetworkPolicy selectors.

3. **Namespace Isolation**

    * If you want to ensure Pods in namespace A cannot talk to namespace B, label each namespace (e.g., `name=team-a`, `name=team-b`) and create a policy in each namespace’s default to restrict ingress only from its own namespace:

      ```yaml
      apiVersion: networking.k8s.io/v1
      kind: NetworkPolicy
      metadata:
        name: namespace-isolation
        namespace: team-a
      spec:
        podSelector: {}
        policyTypes:
          - Ingress
        ingress:
          - from:
              - namespaceSelector:
                  matchLabels:
                    name: team-a
      ```
    * Now, only Pods in `team-a` can connect to Pods in `team-a`. Other namespaces are blocked by default.

4. **Beware of Implicit “Allow”**

    * If no policy selects a Pod, that Pod is fully open (ingress + egress). When adding new Pods, double-check which policies exist in that namespace. You might need to add a new policy to protect the new Pods.

5. **Combine PodSelector + NamespaceSelector**

    * When allowing traffic from specific Pods in a different namespace, chain both selectors:

      ```yaml
      ingress:
        - from:
            - namespaceSelector:
                matchLabels:
                  environment: staging
              podSelector:
                matchLabels:
                  app: metrics
      ```
    * Only Pods labeled `app=metrics` in namespaces labeled `environment=staging` are allowed.

6. **IPBlock for External Dependencies**

    * Use `ipBlock.cidr` when Pods must call external IPs (e.g., external API).
    * Use `except` to exclude subnets (e.g., remote office network).

      ```yaml
      egress:
        - to:
            - ipBlock:
                cidr: 198.51.100.0/24
                except:
                  - 198.51.100.128/25
          ports:
            - protocol: TCP
              port: 443
      ```

7. **Combine Multiple Policies for the Same Pods**

    * You can define more than one NetworkPolicy selecting the same Pods. Kubernetes merges all “allow” rules.
    * For example, one policy might allow egress to DNS, another allows egress to a logging server. Combined, Pods can talk to both.
    * However, if any policy selects a Pod and denies all (no rules), it blocks that direction unless another policy explicitly allows it. In Kubernetes, all policies are additive: a Packet is allowed if **any** policy’s `ingress` or `egress` rule matches it.

8. **Plan for Service Traffic**

    * Recall that a Service’s traffic is DNAT’d: client → Service ClusterIP → chosen Pod IP.
    * When you write a policy, the actual destination is the Pod IP; the source might appear as the original Pod IP, or a node IP if kube-proxy SNAT is used.
    * For `NodePort`/`LoadBalancer` traffic, you may need to allow the node CIDR (e.g., `10.244.0.0/16`) as a peer since kube-proxy might SNAT.

9. **Monitor and Audit Regularly**

    * Periodically run:

      ```bash
      kubectl get networkpolicy --all-namespaces
      ```
    * Review policies for stale or overly permissive rules.
    * Use CI/CD linting to prevent deployments that remove critical labels (breaking selectors) without updating related policies.

---

## Additional Learning Resources

* **Official Kubernetes Documentation**

    * [Services, Load Balancing, and Networking](https://kubernetes.io/docs/concepts/services-networking/)
    * [Ingress Concepts](https://kubernetes.io/docs/concepts/services-networking/ingress/)
    * [Gateway API Overview](https://kubernetes.io/docs/concepts/services-networking/gateway/)
    * [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

* **Tutorials and Samples**

    * Many cloud providers (GKE, EKS, AKS) have step-by-step guides for deploying Ingress Controllers and Gateway API controllers.
    * Calico and Cilium documentation for deeper dives into Network Policy enforcement and debugging.

* **Community Blogs and Talks**

    * Look for Kubernetes conference talks on Gateway API, Ingress best practices, and Network Policy security patterns.
    * Cloud provider blogs often publish tutorials on configuring Ingress with their managed controllers (e.g., AWS ALB Ingress, GCP GLB Ingress).

