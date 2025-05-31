## Exercise 1: Create and Test All Service Types

**Objective**
Learn how to create each of the five built-in Service types—ClusterIP, NodePort, LoadBalancer, ExternalName, and Headless—and observe their behavior.

### 1.1. Prerequisites

1. A cluster with at least one Linux node (so NodePort/LoadBalancer can bind).
2. A simple HTTP application container (we’ll use `nginx:1.21` and `busybox` for ExternalName).
3. You must have permission to create Services, Pods, and (if applicable) LoadBalancer resources.

### 1.2. Create a Namespace for This Exercise

```bash
kubectl create namespace svc-exercise
```

### 1.3. Deploy Two “Backend” Pods with Label `app=demo`

Create a Deployment manifest named `demo-deploy.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-deployment
  namespace: svc-exercise
spec:
  replicas: 2
  selector:
    matchLabels:
      app: demo
  template:
    metadata:
      labels:
        app: demo
    spec:
      containers:
        - name: nginx
          image: nginx:1.21
          ports:
            - containerPort: 80
```

Apply it:

```bash
kubectl apply -f demo-deploy.yaml
```

Verify the Pods are `Running`:

```bash
kubectl get pods -n svc-exercise -l app=demo
```

> **Expected:** 2 Pods named `demo-deployment-<hash>-<index>` in `Running` status.

---

### 1.4. (a) ClusterIP Service (Default)

Create `clusterip-svc.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: demo-clusterip
  namespace: svc-exercise
spec:
  selector:
    app: demo
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
```

Apply:

```bash
kubectl apply -f clusterip-svc.yaml
```

Verify:

```bash
kubectl get svc demo-clusterip -n svc-exercise
kubectl get endpoints demo-clusterip -n svc-exercise
```

> **Expected:**
>
> * A `ClusterIP` is assigned (e.g., `10.96.x.y`).
> * The Endpoints object lists the two Pod IPs on port 80.

**Test from another Pod:**

1. Launch a temporary busybox Pod in the same namespace:

   ```bash
   kubectl run busybox-test \
     --image=busybox:1.35 \
     --rm --restart=Never --namespace=svc-exercise \
     -- sh -c "sleep 3600"
   ```
2. Exec into it:

   ```bash
   kubectl exec -it busybox-test -n svc-exercise -- sh
   ```
3. From inside, `wget -qO- demo-clusterip.svc­-exercise.svc.cluster.local`:

   ```shell
   wget -qO- demo-clusterip
   ```

   You should see the default NGINX HTML response (HTML source).

Exit the busybox shell:

```bash
exit
```

---

### 1.4. (b) NodePort Service

Create `nodeport-svc.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: demo-nodeport
  namespace: svc-exercise
spec:
  type: NodePort
  selector:
    app: demo
  ports:
    - port: 80           # ClusterIP port
      targetPort: 80     # Pod port
      nodePort: 30080    # Must be in 30000–32767
      protocol: TCP
```

Apply:

```bash
kubectl apply -f nodeport-svc.yaml
```

Verify:

```bash
kubectl get svc demo-nodeport -n svc-exercise
kubectl get endpoints demo-nodeport -n svc-exercise
```

> **Expected:**
>
> * Service type is `NodePort`.
> * `NODE-PORT` column shows `30080`.
> * Endpoints list the two Pod IPs.

**Test from **outside** the cluster (or on a worker node):**
If your node IP is `192.168.49.2` (for Kind) or any node’s IP in a bare-metal/VM cluster, run:

```bash
curl http://<NodeIP>:30080
```

> **Expected:**
> You see the default NGINX page HTML.
> If you have multiple nodes, hitting any node’s IP at port 30080 should return the HTML and load balance across Pods.

---

### 1.4. (c) LoadBalancer Service

> **Note:** This only works if your cluster is in a cloud environment that supports provisioning a load balancer (GKE, EKS, AKS). If you’re on Kind/Minikube, you can still create the Service but no external IP will be allocated—Minikube will show `<pending>`.

Create `loadbalancer-svc.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: demo-loadbalancer
  namespace: svc-exercise
spec:
  type: LoadBalancer
  selector:
    app: demo
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
```

Apply:

```bash
kubectl apply -f loadbalancer-svc.yaml
```

Verify:

```bash
kubectl get svc demo-loadbalancer -n svc-exercise
kubectl get endpoints demo-loadbalancer -n svc-exercise
```

> **Expected:**
>
> * In a cloud-provisioned cluster, the `EXTERNAL-IP` field becomes a cloud LB IP or hostname.
> * Endpoints show the same two Pod IPs.

**Test externally:**

```bash
curl http://<EXTERNAL-IP>
```

> **Expected:** NGINX HTML page from one of the Pods.

---

### 1.4. (d) ExternalName Service

This maps a Kubernetes Service name to an external DNS name. In this exercise, we’ll point `externalname-svc` to `nginx.org` as an example.

Create `externalname-svc.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: demo-external
  namespace: svc-exercise
spec:
  type: ExternalName
  externalName: nginx.org
```

Apply:

```bash
kubectl apply -f externalname-svc.yaml
```

Verify:

```bash
kubectl get svc demo-external -n svc-exercise
```

> **Expected:**
>
> * Service `Type: ExternalName`, `EXTERNAL-NAME: nginx.org`.

**Test DNS resolution from another Pod:**

```bash
kubectl exec -it busybox-test -n svc-exercise -- sh
```

Inside busybox:

```shell
nslookup demo-external.svc-exercise.svc.cluster.local
# or
ping demo-external
```

> **Expected:**
> You get a CNAME chain to `nginx.org` and ultimately the IP of `nginx.org`.
> You can `wget -qO- demo-external.svc-exercise.svc.cluster.local` to fetch the homepage of nginx.org.

Exit the busybox:

```bash
exit
```

---

### 1.4. (e) Headless Service (`clusterIP: None`)

We’ll create a StatefulSet next to demonstrate a headless Service’s DNS behavior. For now, create a Service called `demo-headless` that has no ClusterIP.

Create `headless-svc.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: demo-headless
  namespace: svc-exercise
spec:
  clusterIP: None
  selector:
    app: demo
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
```

Apply:

```bash
kubectl apply -f headless-svc.yaml
```

Verify:

```bash
kubectl get svc demo-headless -n svc-exercise
kubectl get endpoints demo-headless -n svc-exercise
```

> **Expected:**
>
> * `clusterIP: None` (no virtual IP).
> * Under `Endpoints`, you see the Pod IPs on port 80.

**Test DNS records from a Pod:**

```bash
kubectl exec -it busybox-test -n svc-exercise -- sh
```

Inside busybox:

```shell
nslookup demo-headless
# You should see multiple “A” records, one for each Pod IP (e.g., demo-deployment-abc-0, demo-deployment-abc-1).
```

> **Important:** Because this Service is headless, DNS returns the Pod IPs directly. Clients doing a multi‐A lookup can round‐robin on their side.

Exit:

```bash
exit
```

---

## Exercise 2: Validate Service Discovery and DNS within the Cluster

**Objective**
Understand how Kubernetes DNS and Service discovery work. Verify that Services resolve to the correct IPs, and that pods can resolve each other via Service names, namespace FQDN, and short names.

### 2.1. Use the Same Namespace and Pods from Exercise 1

We already have:

* Namespace: `svc-exercise`
* Deployment: `demo-deployment` (Pods labeled `app=demo`)
* Several Services: `demo-clusterip`, `demo-nodeport`, `demo-loadbalancer`, `demo-external`, `demo-headless`

Ensure the `busybox-test` Pod is still running; if not, recreate it:

```bash
kubectl run busybox-test \
  --image=busybox:1.35 \
  --rm --restart=Never --namespace=svc-exercise \
  -- sh -c "sleep 3600"
```

### 2.2. Verify DNS via Short Service Name

Exec into `busybox-test`:

```bash
kubectl exec -it busybox-test -n svc-exercise -- sh
```

Inside busybox:

1. Query the ClusterIP Service by **short name**:

   ```shell
   nslookup demo-clusterip
   ```

   > **Expected:**
   >
   > * Returns the ClusterIP (e.g., `10.96.x.y`).

2. Query with **fully qualified domain name** (FQDN):

   ```shell
   nslookup demo-clusterip.svc-exercise.svc.cluster.local
   ```

   > **Expected:** The same IP, confirming how Kubernetes appends the search domain (`svc-exercise.svc.cluster.local`).

3. Query the **Headless** Service:

   ```shell
   nslookup demo-headless
   ```

   > **Expected:** Multiple “A” records—one for each Pod IP.

4. Curl the Service (using short name):

   ```shell
   wget -qO- http://demo-clusterip
   wget -qO- http://demo-nodeport
   wget -qO- http://demo-headless:80
   # (demo-external resolves out to nginx.org; you’ll see an HTML page from nginx.org)
   wget -qO- http://demo-external
   ```

   > **Expected:**
   >
   > * The first two return the default NGINX HTML.
   > * The headless one also returns HTML (but might round-robin between the two Pods).
   > * `demo-external` returns `nginx.org`’s homepage.

Exit busybox:

```bash
exit
```

---

## Exercise 3: Use Session Affinity (“Sticky Sessions”) on a NodePort Service

**Objective**
Configure session affinity (ClientIP) on a NodePort Service so that repeated requests from the same client IP always land on the same backend Pod, and verify the behavior.

### 3.1. Create a New Deployment That Prints Its Pod Name

Namespace reuse: `svc-exercise`

Create `sticky-deploy.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sticky-demo
  namespace: svc-exercise
spec:
  replicas: 3
  selector:
    matchLabels:
      app: sticky
  template:
    metadata:
      labels:
        app: sticky
    spec:
      containers:
        - name: whoami
          image: hashicorp/http-echo:0.2.3
          args:
            - "-text=$(POD_NAME)"
          env:
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
          ports:
            - containerPort: 5678
```

Apply:

```bash
kubectl apply -f sticky-deploy.yaml
```

Wait until all 3 Pods are `Running`:

```bash
kubectl get pods -n svc-exercise -l app=sticky
```

### 3.2. Create a NodePort Service with Session Affinity

Create `sticky-svc.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: sticky-nodeport
  namespace: svc-exercise
spec:
  type: NodePort
  selector:
    app: sticky
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 3600
  ports:
    - port: 80
      targetPort: 5678
      nodePort: 31000
      protocol: TCP
```

Apply:

```bash
kubectl apply -f sticky-svc.yaml
```

Verify:

```bash
kubectl get svc sticky-nodeport -n svc-exercise
kubectl get endpoints sticky-nodeport -n svc-exercise
```

> **Expected:**
>
> * `sessionAffinity: ClientIP`.
> * `NODE-PORT: 31000`.
> * Three endpoints (the 3 Pod IPs on port 5678).

---

### 3.3. Test Session Affinity from a Single External Client

From a machine external to the cluster (or a node), pick one Node’s IP (`<NODE-IP>`). Repeatedly run:

```bash
for i in {1..5}; do curl -s http://<NODE-IP>:31000; done
```

> **Expected:**
>
> * All five requests return the same Pod name (e.g., `sticky-demo-abc123-0`). Because the client’s source IP is “sticky,” kube-proxy always routes to the same backend Pod.

Now, from a **different** client IP (e.g., your laptop vs. a different VM), run the same loop:

```bash
for i in {1..5}; do curl -s http://<NODE-IP>:31000; done
```

> **Expected:**
>
> * You see a different Pod name (some `–1` or `–2`). Each distinct client IP is pinned to its own backend.

---

## Exercise 4: Annotate a Service for ExternalDNS and Test Automatic DNS Record Creation

**Objective**
Leverage `external-dns` integration by annotating a LoadBalancer Service to automatically create a DNS A record in your DNS provider (simulated here as “dry-run”).

> **Note**: To fully test with a cloud DNS provider (Route 53, Cloud DNS, etc.), you need a running `external-dns` controller. For this exercise, we’ll assume `external-dns` is installed and configured to watch Services in the `svc-exercise` namespace and manage a DNS zone you own (e.g., `example.com`). We’ll simulate by creating the annotations and verifying that `external-dns` would pick them up.

### 4.1. Create a Simple Deployment and Service

Reuse the `demo-deployment` from Exercise 1 or create a new one. We’ll make a new Deployment called `webapp`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  namespace: svc-exercise
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
      containers:
        - name: nginx
          image: nginx:1.21
          ports:
            - containerPort: 80
```

Apply:

```bash
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  namespace: svc-exercise
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
      containers:
        - name: nginx
          image: nginx:1.21
          ports:
            - containerPort: 80
EOF
```

### 4.2. Create a LoadBalancer Service with ExternalDNS Annotations

Create `webapp-lb.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp-lb
  namespace: svc-exercise
  annotations:
    external-dns.alpha.kubernetes.io/hostname: webapp.example.com.  # Must end with a dot
    external-dns.alpha.kubernetes.io/ttl: "60"
spec:
  type: LoadBalancer
  selector:
    app: webapp
  ports:
    - name: http
      port: 80
      targetPort: 80
      protocol: TCP
```

Apply:

```bash
kubectl apply -f webapp-lb.yaml
```

Verify Service:

```bash
kubectl get svc webapp-lb -n svc-exercise -o yaml
```

> **Expected:**
>
> * Service type is `LoadBalancer`.
> * `annotations:` contain the `external-dns` keys.
> * Once the cloud LB is provisioned, `external-dns` should see this annotation and create an A record `webapp.example.com → <LoadBalancer IP>`.

In a real cluster with `external-dns` installed, you would check your DNS provider’s console (e.g., Route 53, Cloud DNS) to confirm that `webapp.example.com` was created and points to the LB IP within a minute or so.

---

## Exercise 5: Deploy an NGINX Ingress Controller and Create a Basic Ingress

**Objective**
Install a standard NGINX Ingress Controller (using manifests or Helm), then create two backend Services and an Ingress resource to route traffic by path.

### 5.1. Install NGINX Ingress Controller

> **Note:** If you’re on Minikube, you can do `minikube addons enable ingress`. Otherwise, install via manifest.

```bash
kubectl apply \
  -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/cloud/deploy.yaml
```

Wait for the Ingress controller Pods to be `Running` (in namespace `ingress-nginx`):

```bash
kubectl get pods -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

> **Expected:**
>
> * 2 (or more) Pods like `ingress-nginx-controller-xxxxx` in `Running` status.

---

### 5.2. Deploy Two Backend Deployments + ClusterIP Services

In namespace `svc-exercise`, create:

1. **`frontend-app`** on port 80 (e.g., nginx:1.21 but prints “Frontend”).
2. **`backend-app`** on port 80 (e.g., `hashicorp/http-echo` that prints “Backend”).

#### 5.2.1. Frontend Deployment + Service

```bash
kubectl apply -n svc-exercise -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: svc-exercise
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
        - name: web
          image: hashicorp/http-echo:0.2.3
          args:
            - "-text=This is the Frontend!"
          ports:
            - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-svc
  namespace: svc-exercise
spec:
  type: ClusterIP
  selector:
    app: frontend
  ports:
    - port: 80
      targetPort: 5678
      protocol: TCP
EOF
```

#### 5.2.2. Backend Deployment + Service

```bash
kubectl apply -n svc-exercise -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: svc-exercise
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - name: web
          image: hashicorp/http-echo:0.2.3
          args:
            - "-text=This is the Backend!"
          ports:
            - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: backend-svc
  namespace: svc-exercise
spec:
  type: ClusterIP
  selector:
    app: backend
  ports:
    - port: 80
      targetPort: 5678
      protocol: TCP
EOF
```

Verify both Services:

```bash
kubectl get svc -n svc-exercise
kubectl get pods -n svc-exercise -l app=frontend
kubectl get pods -n svc-exercise -l app=backend
```

> **Expected:**
>
> * `frontend-svc` and `backend-svc` both exist with distinct ClusterIPs.
> * All Pods are `Running`.

---

### 5.3. Create an Ingress Resource for Path-Based Routing

Create `basic-ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-ingress
  namespace: svc-exercise
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - host: demo.local
      http:
        paths:
          - path: /frontend
            pathType: Prefix
            backend:
              service:
                name: frontend-svc
                port:
                  number: 80
          - path: /backend
            pathType: Prefix
            backend:
              service:
                name: backend-svc
                port:
                  number: 80
```

Apply:

```bash
kubectl apply -f basic-ingress.yaml
```

Verify the Ingress:

```bash
kubectl get ingress demo-ingress -n svc-exercise
kubectl describe ingress demo-ingress -n svc-exercise
```

> **Expected:**
>
> * The Ingress has an ADDRESS (external IP) if your Ingress Controller is fronted by a LoadBalancer (cloud) or NodePort.
> * If using Minikube, run `minikube tunnel` in another terminal to allocate an external IP, or use `minikube ip` + nodePort of the ingress controller service.

---

### 5.4. Test Ingress Routing

1. Add an entry in your local `/etc/hosts` (or DNS) pointing `demo.local` to the Ingress’s external IP. For example:

   ```
   <INGRESS_IP>  demo.local
   ```

2. From your laptop/VM:

   ```bash
   curl ‐H "Host: demo.local" http://demo.local/frontend
   curl ‐H "Host: demo.local" http://demo.local/backend
   ```

> **Expected:**
>
> * `/frontend` returns “This is the Frontend!” text.
> * `/backend` returns “This is the Backend!” text.

If you omit the `Host:` header (e.g., `curl http://<INGRESS_IP>/frontend`), you may get a `404` or default backend depending on your controller config.

---

## Exercise 6: Create an HTTPS Ingress with TLS Termination

**Objective**
Use a TLS certificate to terminate HTTPS at the Ingress Controller, then verify that HTTP→HTTPS redirection and TLS work properly.

### 6.1. Generate a Self-Signed Certificate and Secret

For demonstration, generate a certificate for `secure.local`:

```bash
openssl req \
  -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout secure.local.key \
  -out secure.local.crt \
  -subj "/CN=secure.local/O=dev"
```

Create a Kubernetes TLS secret:

```bash
kubectl create secret tls secure-tls-secret \
  --cert=secure.local.crt \
  --key=secure.local.key \
  --namespace=svc-exercise
```

Verify:

```bash
kubectl get secret secure-tls-secret -n svc-exercise
```

> **Expected:**
> Secret of type `kubernetes.io/tls` exists.

---

### 6.2. Create a Simple Backend Deployment + Service

Reuse `frontend` or create a new one. Here, we’ll create `secure-demo`:

```bash
kubectl apply -n svc-exercise -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-demo
  namespace: svc-exercise
spec:
  replicas: 2
  selector:
    matchLabels:
      app: secure
  template:
    metadata:
      labels:
        app: secure
    spec:
      containers:
        - name: web
          image: hashicorp/http-echo:0.2.3
          args:
            - "-text=Secure Demo!"
          ports:
            - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: secure-svc
  namespace: svc-exercise
spec:
  type: ClusterIP
  selector:
    app: secure
  ports:
    - port: 80
      targetPort: 5678
      protocol: TCP
EOF
```

Verify:

```bash
kubectl get svc secure-svc -n svc-exercise
kubectl get pods -n svc-exercise -l app=secure
```

---

### 6.3. Create an Ingress Resource with TLS

Create `secure-ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: secure-ingress
  namespace: svc-exercise
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - secure.local
      secretName: secure-tls-secret
  rules:
    - host: secure.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: secure-svc
                port:
                  number: 80
```

Apply:

```bash
kubectl apply -f secure-ingress.yaml
```

Verify:

```bash
kubectl get ingress secure-ingress -n svc-exercise
kubectl describe ingress secure-ingress -n svc-exercise
```

> **Expected:**
>
> * Under `.status.loadBalancer.ingress` you see an IP.
> * TLS is configured for `secure.local`.

---

### 6.4. Test HTTPS Access

1. Add an entry in `/etc/hosts`:

   ```
   <INGRESS_IP>  secure.local
   ```

2. From your laptop/VM, run:

   ```bash
   curl -k https://secure.local/
   ```

> **Expected:**
>
> * The response “Secure Demo!” is returned.
> * If you try `http://secure.local/`, the annotation `ssl-redirect: "true"` should cause a `301` redirect to `https://secure.local/`.

---

## Exercise 7: Deploy a Simple Gateway API Setup (GatewayClass, Gateway, HTTPRoute)

**Objective**
Set up a basic Gateway API flow: create a `GatewayClass`, provision a `Gateway`, and then define an `HTTPRoute` to route traffic to Services. We’ll use a “fake” controller string because most clusters do not run a full Gateway API controller by default; instead, this exercise will demonstrate the object relationships. If you have a live Gateway controller (e.g., Contour, Istio, or GKE’s Gateway), you can test end-to-end; otherwise you’ll verify that the resources bind correctly.

### 7.1. Install a Gateway API–Compatible Controller (Optional)

> **Optional**: If you already have an implementation (e.g., Contour with `gateway-api` support, NGINX Gateway Controller, Istio), you can skip to create objects. Otherwise, skip this step and simply create the objects in “dry-run” mode to inspect status and relationships.

---

### 7.2. Create a GatewayClass

```bash
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: example-gatewayclass
spec:
  controller: example.com/fake-gateway-controller
EOF
```

Verify:

```bash
kubectl get gatewayclass example-gatewayclass -o yaml
```

> **Expected:**
>
> * `status.conditions[ ]` may show “Accepted: True” if a matching controller exists.
> * Otherwise, you see no conditions or `Status: Unknown/False` because no real controller is running.

---

### 7.3. Create a Gateway

We’ll place the Gateway in the `svc-exercise` namespace. Create `example-gateway.yaml`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: example-gateway
  namespace: svc-exercise
spec:
  gatewayClassName: example-gatewayclass
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      allowedRoutes:
        namespaces:
          from: All
```

Apply:

```bash
kubectl apply -f example-gateway.yaml
```

Verify:

```bash
kubectl get gateway example-gateway -n svc-exercise -o yaml
```

> **Expected:**
>
> * Under `.status.addresses`, if a controller were running, you’d see one or more IPs (e.g., the Service/LoadBalancer IP for the Gateway).
> * `.status.conditions[]` should show “Ready: True” if the controller accepted it. Otherwise, it remains unaccepted.

---

### 7.4. Create Backend Deployments + Services for HTTPRoute

Reuse `frontend-svc` and `backend-svc` from Exercise 5 in `svc-exercise` (or create new ones). For clarity, let’s create two new Services:

```bash
kubectl apply -n svc-exercise -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: route-demo
  namespace: svc-exercise
spec:
  replicas: 2
  selector:
    matchLabels:
      app: route-demo
  template:
    metadata:
      labels:
        app: route-demo
    spec:
      containers:
        - name: echo
          image: hashicorp/http-echo:0.2.3
          args:
            - "-text=Route Demo!"
          ports:
            - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: route-svc
  namespace: svc-exercise
spec:
  type: ClusterIP
  selector:
    app: route-demo
  ports:
    - port: 80
      targetPort: 5678
      protocol: TCP
EOF
```

Verify:

```bash
kubectl get svc route-svc -n svc-exercise
kubectl get pods -n svc-exercise -l app=route-demo
```

---

### 7.5. Create an HTTPRoute Binding to the Gateway

Create `example-httproute.yaml`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: example-httproute
  namespace: svc-exercise
spec:
  parentRefs:
    - name: example-gateway
      sectionName: http
  hostnames:
    - "gateway.demo.local"
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /test
      backendRefs:
        - name: route-svc
          port: 80
```

Apply:

```bash
kubectl apply -f example-httproute.yaml
```

Verify:

```bash
kubectl get httproute example-httproute -n svc-exercise -o yaml
```

> **Expected:**
>
> * If a Gateway Controller is watching, under `.status.parents[]` you’d see that `example-httproute` is “Accepted: True” and bound to `example-gateway/http`.
> * Otherwise, `.status` remains empty/`Pending` because no controller reconciles it.

---

### 7.6. (Optional) Test End-to-End (If a Controller Exists)

1. Ensure the Gateway’s `.status.addresses[]` field has an IP (or Hostname).
2. Add an `/etc/hosts` entry mapping `gateway.demo.local → <Gateway IP>`.
3. Run:

   ```bash
   curl http://gateway.demo.local/test
   ```

> **Expected:**
>
> * You receive the “Route Demo!” response from the `route-svc` pods.

If you don’t have a running controller, you can at least confirm object relationships:

```bash
kubectl describe httproute example-httproute -n svc-exercise
```

You’ll see whether `example-gateway` would have picked it up, and inspect any `Conditions` showing issues (e.g., “ParentNotFound” if the Gateway’s `gatewayClassName` is unrecognized).

---

## Exercise 8: Use Gateway API for Traffic Splitting (Canary Release)

**Objective**
Extend the HTTPRoute from Exercise 7 to split traffic between two Services by weight (e.g., 80/20). Observe how clients get routed.

> **Prerequisite:** You must have a Gateway implementation running that supports weights in HTTPRoute. If not, this will be a “dry-run” exercise to inspect the resource spec.

### 8.1. Create Two Backends: `stable-svc` (80%) and `canary-svc` (20%)

In `svc-exercise`, create two Deployments + Services:

```bash
# Stable version
kubectl apply -n svc-exercise -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: stable
  namespace: svc-exercise
spec:
  replicas: 2
  selector:
    matchLabels:
      app: stable
  template:
    metadata:
      labels:
        app: stable
    spec:
      containers:
        - name: echo
          image: hashicorp/http-echo:0.2.3
          args:
            - "-text=Stable Version"
          ports:
            - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: stable-svc
  namespace: svc-exercise
spec:
  selector:
    app: stable
  ports:
    - port: 80
      targetPort: 5678
      protocol: TCP
EOF

# Canary version
kubectl apply -n svc-exercise -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: canary
  namespace: svc-exercise
spec:
  replicas: 1
  selector:
    matchLabels:
      app: canary
  template:
    metadata:
      labels:
        app: canary
    spec:
      containers:
        - name: echo
          image: hashicorp/http-echo:0.2.3
          args:
            - "-text=Canary Version"
          ports:
            - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: canary-svc
  namespace: svc-exercise
spec:
  selector:
    app: canary
  ports:
    - port: 80
      targetPort: 5678
      protocol: TCP
EOF
```

Verify:

```bash
kubectl get svc stable-svc canary-svc -n svc-exercise
kubectl get pods -n svc-exercise -l app=stable
kubectl get pods -n svc-exercise -l app=canary
```

---

### 8.2. Create a Weighted HTTPRoute

Modify the existing `example-httproute` or create a new one `weighted-httproute.yaml`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: weighted-httproute
  namespace: svc-exercise
spec:
  parentRefs:
    - name: example-gateway
      sectionName: http
  hostnames:
    - "gateway.demo.local"
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /test
      backendRefs:
        - name: stable-svc
          port: 80
          weight: 80
        - name: canary-svc
          port: 80
          weight: 20
```

Apply:

```bash
kubectl apply -f weighted-httproute.yaml
```

Verify:

```bash
kubectl describe httproute weighted-httproute -n svc-exercise
```

> **Expected (with a real Gateway controller):**
>
> * Conditions show the route is accepted by `example-gateway/http`.
> * Under `.status`, you’d see `ResolvedRefs` indicate both Services are ready.

---

### 8.3. Test Weighted Traffic (If Controller Exists)

1. Ensure `gateway.demo.local` resolves to the Gateway’s IP (add to `/etc/hosts`).
2. Fire off multiple requests and tally responses:

   ```bash
   for i in {1..50}; do curl -s http://gateway.demo.local/test; done | sort | uniq -c
   ```

> **Expected:** Roughly 40 responses “Stable Version” and 10 responses “Canary Version” (80/20 split).

If no controller, you’ll at least confirm the YAML is syntactically correct and the route is associated with the correct Gateway.

---

## Exercise 9: Create Simple NetworkPolicies to Isolate Pods

**Objective**
Learn how to write basic NetworkPolicies to enforce pod-to-pod and namespace-to-namespace traffic restrictions. We’ll create a three-tier “app” environment (`web → api → db`) in a new namespace `np-exercise` and lock down communication so that only permitted traffic flows.

### 9.1. Create a New Namespace

```bash
kubectl create namespace np-exercise
```

### 9.2. Label the Namespace

```bash
kubectl label namespace np-exercise name=np-exercise
```

### 9.3. Deploy Three Deployments + Services

In `np-exercise`, create:

1. **Web tier** (Pods labeled `tier=web`, listening on port 80).
2. **API tier** (Pods labeled `tier=api`, listening on port 3000).
3. **DB tier** (Pods labeled `tier=db`, listening on port 5432).

Use this single manifest:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: np-exercise
spec:
  replicas: 2
  selector:
    matchLabels:
      tier: web
  template:
    metadata:
      labels:
        tier: web
    spec:
      containers:
        - name: web
          image: hashicorp/http-echo:0.2.3
          args:
            - "-text=Web Tier"
          ports:
            - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: web-svc
  namespace: np-exercise
spec:
  selector:
    tier: web
  ports:
    - name: http
      port: 80
      targetPort: 5678
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: np-exercise
spec:
  replicas: 2
  selector:
    matchLabels:
      tier: api
  template:
    metadata:
      labels:
        tier: api
    spec:
      containers:
        - name: api
          image: hashicorp/http-echo:0.2.3
          args:
            - "-text=API Tier"
          ports:
            - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: api-svc
  namespace: np-exercise
spec:
  selector:
    tier: api
  ports:
    - name: http
      port: 3000
      targetPort: 5678
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: db
  namespace: np-exercise
spec:
  replicas: 1
  selector:
    matchLabels:
      tier: db
  template:
    metadata:
      labels:
        tier: db
    spec:
      containers:
        - name: postgres
          image: postgres:13    # Just to have port 5432 open
          env:
            - name: POSTGRES_PASSWORD
              value: example
          ports:
            - containerPort: 5432
---
apiVersion: v1
kind: Service
metadata:
  name: db-svc
  namespace: np-exercise
spec:
  selector:
    tier: db
  ports:
    - name: postgres
      port: 5432
      targetPort: 5432
```

Apply:

```bash
kubectl apply -f - <<EOF
(apiVersion/apps/v1, etc.—the above YAML)
EOF
```

Verify:

```bash
kubectl get pods,svc -n np-exercise
```

> **Expected:**
>
> * Pods for `web`, `api`, `db` are `Running`.
> * Services `web-svc:80`, `api-svc:3000`, and `db-svc:5432` exist.

---

### 9.4. Baseline Connectivity (No NetworkPolicies)

1. Launch a temporary busybox Pod in `np-exercise`:

   ```bash
   kubectl run np-test \
     --image=busybox:1.35 \
     --restart=Never \
     --rm \
     --namespace=np-exercise \
     -- sh -c "sleep 3600"
   ```

2. Exec into it:

   ```bash
   kubectl exec -it np-test -n np-exercise -- sh
   ```

3. Test connectivity:

   ```shell
   # Web → API
   wget -qO- http://api-svc:3000
   # API → DB
   wget -qO- --timeout=2 http://db-svc:5432   # Will not be HTTP, but we’re checking port reachability
   ```

   (Use `nc -z api-svc 5678` for raw TCP if needed.)

> **Expected (with no policies):**
>
> * All connections succeed (HTTP echo or raw TCP connection).

Exit busybox:

```bash
exit
```

---

### 9.5. Create a NetworkPolicy to Restrict API Tier: Only Allow Ingress from Web Tier on Port 3000

Create `api-policy.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-allow-web
  namespace: np-exercise
spec:
  podSelector:
    matchLabels:
      tier: api
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              tier: web
      ports:
        - protocol: TCP
          port: 3000
```

Apply:

```bash
kubectl apply -f api-policy.yaml
```

---

### 9.6. Create a NetworkPolicy to Restrict DB Tier: Only Allow Ingress from API Tier on Port 5432

Create `db-policy.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-allow-api
  namespace: np-exercise
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
              tier: api
      ports:
        - protocol: TCP
          port: 5432
```

Apply:

```bash
kubectl apply -f db-policy.yaml
```

---

### 9.7. Test Connectivity After Applying Policies

Launch a new busybox test Pod (or reuse `np-test` by exiting and recreating if it terminated).

Inside busybox:

1. **Web Pod trying to reach API Pod:**

   ```bash
   # Simulate from web-pod; but from busybox it's equivalent to “some Pod in the namespace”
   wget -qO- http://api-svc:3000 && echo "Success" || echo "Fail"
   ```

   > **Expected:** “Success” (because `api-policy` allows traffic from any Pod labeled `tier=web`—but since busybox isn’t labeled `tier=web`, it’s denied).

2. **Busybox (not labeled `tier=web`) trying to reach API:**

   ```bash
   wget -qO- http://api-svc:3000 && echo "Success" || echo "Fail"
   ```

   > **Expected:** “Fail”—busybox is not labeled `tier=web`, so it cannot connect to API.

3. **Simulate a request from the actual Web Pod:**

   ```bash
   WEB_POD=$(kubectl get pod -l tier=web -n np-exercise -o jsonpath="{.items[0].metadata.name}")
   kubectl exec -it $WEB_POD -n np-exercise -- wget -qO- http://api-svc:3000 && echo "Success" || echo "Fail"
   ```

   > **Expected:** “Success”—because the Web Pod’s label matches `tier=web`.

4. **Busybox → DB:**

   ```bash
   wget -qO- --timeout=2 http://db-svc:5432 && echo "Success" || echo "Fail"
   ```

   > **Expected:** “Fail”—because only Pods labeled `tier=api` may connect to DB.

5. **Simulate from API Pod → DB:**

   ```bash
   API_POD=$(kubectl get pod -l tier=api -n np-exercise -o jsonpath="{.items[0].metadata.name}")
   kubectl exec -it $API_POD -n np-exercise -- wget -qO- --timeout=2 http://db-svc:5432 && echo "Success" || echo "Fail"
   ```

   > **Expected:** “Success”—`db-policy` allows traffic from Pods labeled `tier=api`.

Exit busybox:

```bash
exit
```

---

## Exercise 10: Create a Complex NetworkPolicy with NamespaceSelector and IPBlock

**Objective**
Write a NetworkPolicy that allows egress traffic from Pods in one namespace (`np-exercise`) to a specific external IP range (e.g., `8.8.8.0/24`) except a smaller block (`8.8.8.128/25`), and also allows egress to internal DB Service. At the same time, deny all other egress.

### 10.1. Create or Reuse the `np-exercise` Namespace and the `web` Deployment from Exercise 9

Ensure you have:

* Namespace: `np-exercise`
* Pods labeled `tier=web`, `tier=api`, `tier=db`
* Services: `web-svc`, `api-svc`, `db-svc`

---

### 10.2. Create a NetworkPolicy Restricting Egress

We want:

1. Any Pod labeled `tier=api` may only egress to:

    * The `db-svc` ClusterIP on port 5432 (internal).
    * **Or** any IP in `8.8.8.0/24` **except** the subset `8.8.8.128/25`.

2. All other egress from those Pods is dropped.

Create `complex-egress-policy.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-egress-complex
  namespace: np-exercise
spec:
  podSelector:
    matchLabels:
      tier: api
  policyTypes:
    - Egress
  egress:
    # Allow to DB Service via its ClusterIP
    - to:
        - namespaceSelector:
            matchLabels:
              name: np-exercise
          podSelector:
            matchLabels:
              tier: db
      ports:
        - protocol: TCP
          port: 5432
    # Allow to external IPBlock 8.8.8.0/24 except 8.8.8.128/25
    - to:
        - ipBlock:
            cidr: 8.8.8.0/24
            except:
              - 8.8.8.128/25
      ports:
        - protocol: TCP
          port: 53   # Assume DNS or any service at 8.8.8.x
```

Apply:

```bash
kubectl apply -f complex-egress-policy.yaml
```

> **Explanation:**
>
> * The first rule’s `namespaceSelector: matchLabels: name=np-exercise` plus `podSelector: matchLabels: tier=db` means “any Pod in the `np-exercise` namespace labeled `tier=db`”—i.e., the DB Pod.
> * The second rule’s `ipBlock` is the external range, but excludes the subset.
> * Egress is locked down (anything not matching these two rules is dropped).

---

### 10.3. Verify Complex Egress Behavior

1. Launch a busybox Pod labeled `tier=api` to simulate the API Pod (or just identify an existing `api-` Pod):

   ```bash
   API_POD=$(kubectl get pod -l tier=api -n np-exercise -o jsonpath="{.items[0].metadata.name}")
   ```

2. From inside the API Pod, try to connect to the DB:

   ```bash
   kubectl exec -it $API_POD -n np-exercise -- wget -qO- --timeout=2 http://db-svc:5432 && echo "DB Success" || echo "DB Fail"
   ```

   > **Expected:** “DB Success”

3. From inside the API Pod, try to connect to an allowed external IP (e.g., `8.8.8.8` on port 53). For demonstration, install `nslookup` or use `nc`:

   ```bash
   kubectl exec -it $API_POD -n np-exercise -- nc -vz 8.8.8.8 53
   ```

   > **Expected:** “succeeded” (exit code 0).

4. From inside the API Pod, try to connect to a disallowed external IP in the excluded range, e.g., `8.8.8.200` (which is in `8.8.8.128/25`):

   ```bash
   kubectl exec -it $API_POD -n np-exercise -- nc -vz 8.8.8.200 53
   ```

   > **Expected:** “connection timed out” or “refused” (blocked).

5. From inside the API Pod, try any other external IP (e.g., `1.1.1.1` on port 80):

   ```bash
   kubectl exec -it $API_POD -n np-exercise -- nc -vz 1.1.1.1 80
   ```

   > **Expected:** “connection timed out” (blocked because not in any allowed egress rule).

---

## Cleanup Tips

When you finish these exercises, you can delete all the namespaces and resources created:

```bash
kubectl delete namespace svc-exercise
kubectl delete namespace np-exercise
```

Or, if you prefer to delete individual resources (Services, Deployments, Ingress, etc.), do so via:

```bash
kubectl delete -n svc-exercise svc,deploy,ingress --all
kubectl delete -n svc-exercise networkpolicy --all
kubectl delete -n np-exercise svc,deploy networkpolicy --all
```
