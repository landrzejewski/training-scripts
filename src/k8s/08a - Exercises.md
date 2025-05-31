## 1. Node Maintenance Exercises

### Exercise 1.1: Cordoning and Draining a Node

1. **Create a simple Deployment**:

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: nginx-deploy
   spec:
     replicas: 3
     selector:
       matchLabels:
         app: nginx-sample
     template:
       metadata:
         labels:
           app: nginx-sample
       spec:
         containers:
           - name: nginx
             image: nginx:stable
   ```

    * Apply it (`kubectl apply -f`) and wait until 3 Pods are Running.
2. **Choose one worker node** (e.g., `worker-node-1`) and mark it unschedulable:

   ```
   kubectl cordon worker-node-1
   ```
3. **Verify** that new Pods will not land on that node by scaling the Deployment up (e.g., `kubectl scale deployment/nginx-deploy --replicas=5`) and observing that the new Pods schedule only on the remaining schedulable nodes.
4. **Drain** the cordoned node, evicting all Pods (ignore DaemonSets and emptyDir data):

   ```
   kubectl drain worker-node-1 --ignore-daemonsets --delete-emptydir-data
   ```

    * Observe that the 3 nginx Pods that were on `worker-node-1` get evicted and rescheduled elsewhere.
5. **Uncordon** the node once you’re done:

   ```
   kubectl uncordon worker-node-1
   ```

### Exercise 1.2: Taint-Driven Eviction

1. **Label one node** for maintenance:

   ```
   kubectl taint nodes worker-node-1 maintenance=true:NoExecute
   ```
2. **On a Pod that should stay during maintenance**, add a toleration. For example, patch the nginx Deployment’s Pod template to include:

   ```yaml
   spec:
     template:
       spec:
         tolerations:
           - key: "maintenance"
             operator: "Equal"
             value: "true"
             effect: "NoExecute"
             tolerationSeconds: 600
   ```

   Then reapply the Deployment (e.g. `kubectl apply -f patched-deployment.yaml` or use `kubectl patch`).
3. **Verify**:

    * Pods **without** this toleration get evicted almost immediately when the taint is applied.
    * The Pod **with** that toleration remains on the tainted node for up to 10 minutes (or until you manually untolerate/remove the taint).
4. **Remove the taint**:

   ```
   kubectl taint nodes worker-node-1 maintenance:NoExecute-
   ```

    * Check that scheduling returns to normal on `worker-node-1`.

---

## 2. Application Update Strategy Exercises

### Exercise 2.1: RollingUpdate vs. Recreate

1. **Create two Docker images** of a simple HTTP server (for example, a Python Flask or Node.js app) that respond on `/` with “Version A” or “Version B.” Tag them `registry/myapp:v1` and `registry/myapp:v2`.
2. **RollingUpdate Deployment**:

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: rolling-demo
   spec:
     replicas: 3
     selector:
       matchLabels:
         app: rolling-demo
     strategy:
       type: RollingUpdate
       rollingUpdate:
         maxSurge: 1
         maxUnavailable: 1
     template:
       metadata:
         labels:
           app: rolling-demo
       spec:
         containers:
           - name: web
             image: registry/myapp:v1
             ports:
               - containerPort: 8080
   ```

    * Apply it and confirm all 3 Pods serve “Version A.”
    * Now update `image: registry/myapp:v2` in the Deployment and `kubectl apply -f`. Watch how Pods are gradually replaced, ensuring at least 2 are always available.
3. **Recreate Deployment**:

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: recreate-demo
   spec:
     replicas: 3
     selector:
       matchLabels:
         app: recreate-demo
     strategy:
       type: Recreate
     template:
       metadata:
         labels:
           app: recreate-demo
       spec:
         containers:
           - name: web
             image: registry/myapp:v1
             ports:
               - containerPort: 8080
   ```

    * Apply it, verify “Version A,” then update to “Version B” and apply. Notice all Pods are terminated first, then the new ones come up, causing a brief downtime.

### Exercise 2.2: Blue/Green Deployment

1. **Deploy “Blue” version**:

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: web-blue
   spec:
     replicas: 2
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
             image: registry/myapp:blue
             ports:
               - containerPort: 80
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: web-svc
   spec:
     selector:
       app: web
       version: blue
     ports:
       - port: 80
         targetPort: 80
   ```

    * Apply both. Confirm `web-svc` routes to the “blue” Pods.
2. **Deploy “Green” version** (identical, except `version: green` and `image: registry/myapp:green`):

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: web-green
   spec:
     replicas: 2
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
             image: registry/myapp:green
             ports:
               - containerPort: 80
   ```
3. **Smoke-test “Green”**:

    * Temporarily port-forward or expose it (e.g., `kubectl port-forward deployment/web-green 8080:80`) and verify it’s working.
4. **Switch the Service to Green**:

   ```
   kubectl patch svc web-svc -p '{"spec":{"selector":{"app":"web","version":"green"}}}'
   ```

    * Now all traffic to `web-svc` goes to green. Validate it.
5. **Rollback to Blue (if needed)**:

   ```
   kubectl patch svc web-svc -p '{"spec":{"selector":{"app":"web","version":"blue"}}}'
   ```

### Exercise 2.3: Simple Istio-Based Canary

(If Istio is installed; otherwise skip or adapt using your service mesh of choice.)

1. **Deploy a base `web-svc` Deployment/Service** labeled `version: v1`.
2. **Install an Istio VirtualService and DestinationRule**:

   ```yaml
   apiVersion: networking.istio.io/v1alpha3
   kind: DestinationRule
   metadata:
     name: web-destination
   spec:
     host: web-svc
     subsets:
       - name: v1
         labels:
           version: v1
       - name: v2
         labels:
           version: v2
   ---
   apiVersion: networking.istio.io/v1alpha3
   kind: VirtualService
   metadata:
     name: web-virtualservice
   spec:
     hosts:
       - web-svc
     http:
       - route:
           - destination:
               host: web-svc
               subset: v1
             weight: 90
           - destination:
               host: web-svc
               subset: v2
             weight: 10
   ```
3. **Deploy a small “v2” Pod**:

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: web-canary
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
       spec:
         containers:
           - name: web
             image: registry/myapp:v2
             ports:
               - containerPort: 80
   ```
4. **Observe Traffic Split**: send a bunch of requests to `web-svc`. \~10% should go to v2, 90% to v1. Adjust weights as desired.

---

## 3. Custom Resource Definitions (CRD) Exercises

### Exercise 3.1: Define and Use a Simple “Widget” CRD

1. **Create a file `widget-crd.yaml`** with the following:

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
           status: {}
         additionalPrinterColumns:
           - name: Size
             type: integer
             jsonPath: .spec.size
           - name: Color
             type: string
             jsonPath: .spec.color
     scope: Namespaced
     names:
       plural: widgets
       singular: widget
       kind: Widget
       shortNames:
         - wd
   ```
2. **Apply**:

   ```
   kubectl apply -f widget-crd.yaml
   ```
3. **Create a sample custom resource** `my-widget.yaml`:

   ```yaml
   apiVersion: example.com/v1alpha1
   kind: Widget
   metadata:
     name: test-widget
   spec:
     size: 5
     color: "green"
   ```

   ```
   kubectl apply -f my-widget.yaml
   ```
4. **Verify**:

   ```
   kubectl get widgets
   # Should show “test-widget” with columns Size=5, Color=green
   kubectl describe widget test-widget
   ```
5. **(Optional)** Write a tiny Bash script (or use `kubectl patch`) to update the Widget’s `.status` manually:

   ```bash
   kubectl patch widget test-widget -p '{"status":{"phase":"Ready"}}' --type=merge
   kubectl get widget test-widget -o yaml
   # Observe that status.phase: Ready appears under status
   ```

### Exercise 3.2: Create a Controller Skeleton with Kubebuilder

1. **Install Kubebuilder** (v2.x or newer) on your local machine.
2. **Initialize a new project**:

   ```bash
   mkdir widget-operator && cd widget-operator
   kubebuilder init --domain example.com --repo github.com/my-org/widget-operator
   ```
3. **Create an API and Controller**:

   ```bash
   kubebuilder create api --group example --version v1alpha1 --kind Widget
   ```
4. **Implement a minimal reconcile loop** in `controllers/widget_controller.go`’s `Reconcile()` that simply logs the `Widget`’s `.spec.color`.
5. **Build and run locally** with `make run`, then create a `Widget` (as in Exercise 3.1) and watch the controller logs to see it reconciling.

*(This exercise simply familiarizes you with scaffolding; you don’t need a full working operator.)*

---

## 4. Downward API Exercises

### Exercise 4.1: Expose Pod Metadata via Environment Variables

1. **Write a Pod spec** named `downward-env.yaml`:

   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: downward-env-demo
     labels:
       app: down-demo
       tier: backend
     annotations:
       log-level: debug
   spec:
     containers:
       - name: busybox
         image: busybox
         command:
           - sh
           - -c
           - |
             echo "Pod: $POD_NAME"
             echo "Namespace: $POD_NAMESPACE"
             echo "App Label: $LABEL_APP"
             echo "Log Level: $ANNOT_LOG_LEVEL"
             echo "CPU Request (milliCPU): $CPU_REQUEST"
             echo "Memory Request (MiB): $MEMORY_REQUEST"
             sleep 3600
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
                 containerName: busybox
                 resource: requests.cpu
                 divisor: "1"
           - name: MEMORY_REQUEST
             valueFrom:
               resourceFieldRef:
                 containerName: busybox
                 resource: requests.memory
                 divisor: "1Mi"
         resources:
           requests:
             cpu: "200m"
             memory: "256Mi"
   ```
2. **Apply**:

   ```
   kubectl apply -f downward-env.yaml
   ```
3. **Describe or exec into the Pod** to see the printed environment variables:

   ```
   kubectl logs downward-env-demo
   # You should see lines like “Pod: downward-env-demo”, “Namespace: default”, etc.
   ```

### Exercise 4.2: Expose Pod Metadata via Volumes

1. **Write a Pod spec** `downward-volume.yaml`:

   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: downward-vol-demo
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
           - sh
           - -c
           - |
             echo "Pod name file: $(cat /etc/podinfo/podname)"
             echo "Labels file: $(cat /etc/podinfo/labels)"
             echo "CPU request file: $(cat /etc/podinfo/cpu)m"
             echo "Memory request file: $(cat /etc/podinfo/memory)Mi"
             sleep 3600
         volumeMounts:
           - name: podinfo
             mountPath: /etc/podinfo
         resources:
           requests:
             cpu: "300m"
             memory: "512Mi"
   ```
2. **Apply**:

   ```
   kubectl apply -f downward-volume.yaml
   ```
3. **Check logs**:

   ```
   kubectl logs downward-vol-demo
   ```

    * You should see the contents of `/etc/podinfo/podname`, `/etc/podinfo/labels`, `/etc/podinfo/cpu`, etc.

---

## 5. Logging & Monitoring Exercises

> **Note**: You can run these in a single-node test cluster (e.g., minikube). Some resource limits may need lowering.

### Exercise 5.1: Set Up a Simple ELK Stack with Fluentd

1. **Deploy an Elasticsearch StatefulSet** (3 replicas) with 50 Gi PVs each, as shown previously in section 1.3.1. Wait until all 3 Pods are `Ready`.
2. **Deploy Kibana** (1 replica) pointing at your Elasticsearch service; wait until it’s `Ready`.
3. **Create a Namespace** for logging and a ConfigMap for Fluentd config:

   ```yaml
   apiVersion: v1
   kind: Namespace
   metadata:
     name: logging
   ---
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: fluentd-config
     namespace: logging
   data:
     fluent.conf: |
       <source>
         @type tail
         path /var/log/containers/*.log
         pos_file /var/log/fluentd-containers.log.pos
         tag kube.*
         <parse>
           @type multi_format
           <pattern>
             format json
             time_format %Y-%m-%dT%H:%M:%S.%NZ
           </pattern>
           <pattern>
             format none
           </pattern>
         </parse>
       </source>
       <match kube.**>
         @type elasticsearch
         host elasticsearch.logging.svc.cluster.local
         port 9200
         logstash_format true
         logstash_prefix kubernetes-logs
         include_tag_key true
         type_name _doc
         flush_interval 5s
       </match>
   ```
4. **Deploy Fluentd as a DaemonSet** in `logging` namespace, mounting host log directories and using the above ConfigMap. For example:

   ```yaml
   apiVersion: apps/v1
   kind: DaemonSet
   metadata:
     name: fluentd
     namespace: logging
   spec:
     selector:
       matchLabels:
         app: fluentd
     template:
       metadata:
         labels:
           app: fluentd
       spec:
         serviceAccountName: fluentd
         containers:
           - name: fluentd
             image: fluent/fluentd:v1.14.0-debian-1.0
             env:
               - name: FLUENT_CONF
                 value: fluent.conf
             volumeMounts:
               - name: config-volume
                 mountPath: /fluentd/etc
               - name: varlog
                 mountPath: /var/log/containers
                 readOnly: true
         volumes:
           - name: config-volume
             configMap:
               name: fluentd-config
           - name: varlog
             hostPath:
               path: /var/log/containers
   ```

    * Wait until all Fluentd Pods are Running.
5. **Generate application logs**:

    * Deploy a simple Pod that writes to stdout/stderr (for instance, a busybox “echo” loop).
    * Check Elasticsearch indices:

      ```
      curl -X GET "http://elasticsearch.logging.svc.cluster.local:9200/_cat/indices?v"
      ```

      You should see an index like `kubernetes-logs-YYYY.MM.DD`.
6. **Open Kibana** (port-forward `kubectl port-forward svc/kibana 5601:5601 -n logging`) and:

    * Create an index pattern `kubernetes-logs-*`.
    * Explore the data in Discover and build a basic dashboard (e.g., count of log entries per Pod).

### Exercise 5.2: Deploy Graylog with Sidecar (Optional Alternative)

1. **Deploy MongoDB** (1 replica) and Elasticsearch (as above) in a `graylog` namespace.
2. **Create a Secret** for Graylog root password (SHA256 of “admin123”):

   ```bash
   echo -n "admin123" | sha256sum | awk '{print $1}' > ./sha256.txt
   kubectl create secret generic graylog-secret \
     --from-literal=password_secret="$(openssl rand -base64 32)" \
     --from-file=root_password_sha2=./sha256.txt \
     --namespace graylog
   ```
3. **Deploy Graylog Server**:

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: graylog
     namespace: graylog
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
                 value: "http://graylog.graylog.svc.cluster.local:9000/"
             ports:
               - containerPort: 9000   # Web UI
               - containerPort: 12201  # GELF TCP
             volumeMounts:
               - name: graylog-data
                 mountPath: /usr/share/graylog/data
         volumes:
           - name: graylog-data
             emptyDir: {}
   ```
4. **Expose Graylog** (ClusterIP Service) and **deploy a Sidecar DaemonSet** that runs Filebeat on each node, forwarding logs to Graylog’s GELF input (port 12201).
5. **Create a Fluentd or Filebeat config** to send logs to Graylog in GELF format. Confirm logs show up in the Graylog UI.
6. **Use Graylog UI** to create a “Stream” that filters only logs from a specific Pod label, then set up a simple alert (e.g., when a certain log message appears more than 5 times in 10 minutes).

---

## 6. Prometheus + Grafana Monitoring Exercises

### Exercise 6.1: Install kube-prometheus-stack via Helm

1. **Install Helm** (v3.x) if not already installed.
2. **Add the Prometheus community repo**:

   ```
   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   helm repo update
   ```
3. **Install kube-prometheus-stack** into a `monitoring` namespace:

   ```
   kubectl create namespace monitoring
   helm install kube-prom-stack prometheus-community/kube-prometheus-stack \
     --namespace monitoring \
     --set grafana.adminPassword="YourGrafanaPass123"
   ```
4. **Verify** all components (`prometheus-operator`, `prometheus`, `alertmanager`, `grafana`, `kube-state-metrics`, `node-exporter`) are up and Running.
5. **Port-forward Grafana**:

   ```
   kubectl port-forward svc/kube-prom-stack-grafana 3000:80 -n monitoring
   ```

    * Log in at [http://localhost:3000](http://localhost:3000) using `admin / YourGrafanaPass123`.
6. **Explore built-in dashboards**: e.g., “Cluster / Nodes,” “Pod Summary,” “Workloads / Deployments.” Confirm you’re seeing real metrics for your cluster.

### Exercise 6.2: Create a Custom Alert Rule

1. **Create a PrometheusRule** in the `monitoring` namespace called `node-memory-alert.yaml`:

   ```yaml
   apiVersion: monitoring.coreos.com/v1
   kind: PrometheusRule
   metadata:
     name: node-memory-alert
     namespace: monitoring
   spec:
     groups:
       - name: node.rules
         rules:
           - alert: NodeMemoryHigh
             expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 80
             for: 2m
             labels:
               severity: warning
             annotations:
               summary: "Node memory usage is above 80%"
               description: "Memory usage on {{ $labels.instance }} is > 80% for more than 2 minutes."
   ```
2. **Apply** it:

   ```
   kubectl apply -f node-memory-alert.yaml
   ```
3. **Simulate high memory** on one node (e.g., deploy a Pod that spins up a memory hog: `kubectl run -i --tty memhog --image=busybox -- sh -c "dd if=/dev/zero of=/dev/null bs=1M count=2000; sleep 600"` in multiple replicas or adjust to consume memory).
4. **Check Alertmanager** (port-forward `kubectl port-forward svc/kube-prom-stack-alertmanager 9093 -n monitoring`) to see if `NodeMemoryHigh` fires. If you have configured email/slack receivers, verify notifications come through.
5. **View the alert** in Grafana’s “Alerting → Alert Rules” panel to confirm it’s listed.

### Exercise 6.3: Custom Grafana Dashboard

1. **Open Grafana** (already port-forwarded to [http://localhost:3000](http://localhost:3000)).
2. **Create a new dashboard**:

    * Add a single panel showing **CPU usage per node**: PromQL query something like:

      ```
      100 - (avg by (instance)(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
      ```
    * Save it as “Node CPU Usage.”
3. **Add another panel** tracking **Pod restart counts**:

    * Query:

      ```
      sum(rate(kube_pod_container_status_restarts_total[15m])) by (pod)
      ```
    * Place it under the same dashboard.
4. **Set up a Grafana alert** on the “Node CPU Usage” panel that triggers if any node’s CPU usage goes above 90% for more than 1 minute, sending a notification to a test email or webhook channel.

