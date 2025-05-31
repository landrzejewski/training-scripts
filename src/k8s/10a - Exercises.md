## Prerequisites

1. **Helm v3 Installed**
   Make sure you have Helm v3.x installed on your local machine (or wherever you’ll run these commands).

   ```bash
   helm version
   # Should show something like “version.BuildInfo{Version:"v3.x.x", ...}”
   ```

2. **Kubernetes Access**
   A working kubeconfig that points to a cluster (minikube, kind, GKE, EKS, etc.), with a context set (e.g., `kubectl config current-context` should return your cluster name).

   ```bash
   kubectl config current-context
   ```

3. **Namespace “practice-helm”**
   For isolation, we’ll do most of our work in a dedicated namespace.

   ```bash
   kubectl create namespace practice-helm
   ```

---

## Exercise 1: Create & Inspect a Simple Chart

### 1.1. Scaffold a New Chart

1. Create a directory for your Helm exercises, then scaffold a new chart named `myapp`:

   ```bash
   mkdir -p ~/helm-exercises
   cd ~/helm-exercises
   helm create myapp
   ```

2. Inspect the directory structure of `myapp/`:

   ```bash
   tree myapp/
   ```

   You should see:

   ```
   myapp/
   ├── Chart.yaml
   ├── values.yaml
   ├── charts/
   ├── templates/
   │   ├── deployment.yaml
   │   ├── _helpers.tpl
   │   ├── hpa.yaml
   │   ├── ingress.yaml
   │   ├── NOTES.txt
   │   ├── service.yaml
   │   ├── serviceaccount.yaml
   │   ├── tests/
   │   │   └── test-connection.yaml
   │   └── ... (some default files)
   └── .helmignore
   ```

   > You now have a minimal “Hello, World” Chart with example templates.

### 1.2. Render Templates Locally

1. Preview what Kubernetes manifests Helm will generate (with default values):

   ```bash
   helm template myapp ./myapp
   ```

2. Redirect that output to a file for closer inspection:

   ```bash
   helm template myapp ./myapp > rendered.yaml
   less rendered.yaml
   ```

   Notice how every template is rendered, including:

    * **Deployment** (using default image `nginx:stable`, 1 replica, etc.)
    * **Service** (ClusterIP on port 80)
    * **HorizontalPodAutoscaler** (HPA)
    * **Ingress** (disabled by default)
    * **ServiceAccount**, RBAC rules, etc.

---

## Exercise 2: Customize with values.yaml and Overrides

### 2.1. Modify `values.yaml`

Open `myapp/values.yaml` in your editor. By default you’ll see:

```yaml
replicaCount: 1

image:
  repository: nginx
  pullPolicy: IfNotPresent
  # Overrides the image tag whose default is the chart appVersion.
  tag: ""

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: false
  # ... (more ingress defaults) ...

resources: {}
# ... (nodeSelector, affinity, tolerations) ...
```

Change the following defaults:

```yaml
replicaCount: 2

image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "1.19.10"       # Pin to a known nginx version

service:
  type: NodePort       # Switch from ClusterIP to NodePort
  port: 8080           # Expose on port 8080

# Enable Ingress by default:
ingress:
  enabled: true
  className: ""
  annotations: {}
  hosts:
    - host: myapp.local
      paths:
        - /
  tls: []

resources:
  limits:
    cpu: 200m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 64Mi
```

Save `values.yaml`.

### 2.2. Re‐render Templates with Updated Values

```bash
helm template myapp ./myapp > rendered-custom.yaml
less rendered-custom.yaml
```

Verify:

* **Deployment** now has `replicas: 2` and `image: nginx:1.19.10`.
* **Service** is a `NodePort` on port `8080`.
* **Ingress** section is present since we set `ingress.enabled: true`.
* **Resources** block slots into the container spec.

### 2.3. Override with `--set` and Extra Values File

1. Create a second values file named `override.yaml`:

   ```yaml
   replicaCount: 3

   service:
     type: LoadBalancer
     port: 80

   # Disable Ingress override
   ingress:
     enabled: false
   ```

2. Preview merging (default → values.yaml → override.yaml):

   ```bash
   helm template myapp ./myapp \
     --values myapp/values.yaml \
     --values override.yaml > rendered-override.yaml

   # Confirm:
   # - replicas = 3 (from override.yaml)
   # - service type = LoadBalancer, port = 80 (overridden)
   # - ingress is disabled (override.yaml)
   grep "replicas:" rendered-override.yaml
   grep "type: " rendered-override.yaml | grep Service
   grep "kind: Ingress" rendered-override.yaml
   ```

3. Override a single field on the command line (`--set`):

   ```bash
   helm template myapp ./myapp \
     --set image.tag=1.21.5 \
     --set service.port=9090 > rendered-set.yaml

   grep "image: " rendered-set.yaml
   grep "port:" rendered-set.yaml
   ```

---

## Exercise 3: Install, Upgrade, and Rollback a Release

### 3.1. Install to “practice-helm” Namespace

1. **Install** the chart the first time:

   ```bash
   helm install myapp-release ./myapp \
     --namespace practice-helm \
     --create-namespace \
     --values myapp/values.yaml
   ```

2. **Verify** the Release:

   ```bash
   helm list --namespace practice-helm
   helm status myapp-release --namespace practice-helm
   kubectl get all -n practice-helm
   ```

    * You should see 2 Pods (since `replicaCount: 2`), a Service (`NodePort` on 8080), an Ingress resource, an HPA, etc.

3. **Port-forward** or visit the Service to confirm the app is reachable (nginx default page):

   ```bash
   kubectl port-forward svc/myapp-release 8080:8080 -n practice-helm
   # In your browser / shell:
   curl http://localhost:8080
   ```

### 3.2. Upgrade the Release

1. **Update values.yaml** (in `myapp/values.yaml`) to change the replica count from 2 → 4:

   ```yaml
   replicaCount: 4
   ```

2. **Upgrade** the Release:

   ```bash
   helm upgrade myapp-release ./myapp \
     --namespace practice-helm \
     --values myapp/values.yaml
   ```

3. **Verify**:

   ```bash
   helm history myapp-release -n practice-helm
   kubectl get pods -n practice-helm
   kubectl describe deployment myapp-release -n practice-helm | grep "Replicas"
   ```

    * You should now have 4 Pods instead of 2.
    * The new revision (e.g., `REVISION 2`) is recorded in history.

### 3.3. Rollback to the Previous Revision

1. **Rollback** to revision 1:

   ```bash
   helm rollback myapp-release 1 --namespace practice-helm
   ```

2. **Verify**:

   ```bash
   helm history myapp-release -n practice-helm
   kubectl get pods -n practice-helm
   ```

    * You should see the Pods return to 2 replicas.
    * The history will show a new revision (e.g., revision 3 = rollback to revision 1).

3. **Cleanup**:

   ```bash
   helm uninstall myapp-release --namespace practice-helm
   # Confirm all resources (Deployment, Service, Ingress, etc.) are gone:
   kubectl get all -n practice-helm
   ```

---

## Exercise 4: Lint, Diff, and Package a Chart

### 4.1. Lint the Chart

1. Run `helm lint` on your chart to catch any template errors or missing fields:

   ```bash
   helm lint ./myapp
   ```

    * Ensure there are no errors or warnings. If there are, fix them before proceeding.

### 4.2. Diff Before Upgrading

1. Reinstall your chart (fresh) to see the baseline state:

   ```bash
   helm install myapp-release ./myapp \
     --namespace practice-helm \
     --create-namespace
   ```

2. Modify `myapp/values.yaml`—for example, change the image tag from `1.19.10` → `1.21.6`:

   ```yaml
   image:
     repository: nginx
     pullPolicy: IfNotPresent
     tag: "1.21.6"
   ```

3. **Install the Diff Plugin** (if not already installed):

   ```bash
   helm plugin list | grep diff || helm plugin install https://github.com/databus23/helm-diff
   ```

4. **Preview** what changes the upgrade would make:

   ```bash
   helm diff upgrade myapp-release ./myapp \
     --namespace practice-helm \
     --values myapp/values.yaml
   ```

    * You should see a diff showing that `spec.template.spec.containers[0].image` changes from `nginx:1.19.10` → `nginx:1.21.6`, and possibly an annotation update. This helps catch unintended changes.

5. **Perform the Upgrade** (after verifying the diff):

   ```bash
   helm upgrade myapp-release ./myapp \
     --namespace practice-helm \
     --values myapp/values.yaml
   ```

6. **Confirm** the Pods roll out with the new image:

   ```bash
   kubectl describe deployment myapp-release -n practice-helm | grep "Image:"
   ```

### 4.3. Package and Index the Chart Locally

1. **Package** your chart into a `.tgz`:

   ```bash
   helm package myapp
   # Creates myapp-<chartVersion>.tgz, e.g. myapp-0.1.0.tgz
   ```

2. **Create/Update an `index.yaml`** in your local directory:

   ```bash
   helm repo index . --url https://example.com/charts
   ```

    * This produces an `index.yaml` that points at `myapp-0.1.0.tgz` under `https://example.com/charts/myapp-0.1.0.tgz`.
    * For local testing, you can serve this directory via a simple HTTP server (e.g., `python3 -m http.server 8080`).

3. **Add Your Local “Repo” to Helm**:

   ```bash
   helm repo add localcharts http://localhost:8080
   helm repo update
   helm search repo localcharts/myapp
   ```

4. **Install Directly from Your Local Repo**:

   ```bash
   helm install myapp-local localcharts/myapp \
     --namespace practice-helm \
     --set replicaCount=1
   ```

    * This verifies that indexing and packaging worked.
    * Finally, clean up:

      ```bash
      helm uninstall myapp-local --namespace practice-helm
      rm myapp-*.tgz index.yaml
      ```

---

## Exercise 5: Work with Chart Dependencies

### 5.1. Add a Subchart Dependency

Let’s say your `myapp` needs Redis. We’ll add the stable Bitnami Redis Chart as a dependency.

1. **Edit `myapp/Chart.yaml`** to include a `dependencies:` section:

   ```yaml
   apiVersion: v2
   name: myapp
   description: “Demo chart for MyApp with Redis”
   type: application
   version: 0.2.0
   appVersion: “1.0.0”

   dependencies:
     - name: redis
       version: 17.3.14           # pick a valid version from Bitnami repo
       repository: https://charts.bitnami.com/bitnami
       condition: redis.enabled
   ```

2. **Run**:

   ```bash
   cd myapp/
   helm repo add bitnami https://charts.bitnami.com/bitnami
   helm repo update

   helm dependency update
   ```

    * This downloads `redis-17.3.14.tgz` into `myapp/charts/` and creates a `Chart.lock`.

3. **Override Values for Redis** in `myapp/values.yaml` by adding:

   ```yaml
   redis:
     enabled: true
     architecture: standalone
     auth:
       password: mysecretpassword
     primary:
       service:
         type: ClusterIP
   ```

4. **Render** the combined manifests:

   ```bash
   helm template myapp ./myapp > rendered-with-redis.yaml
   grep "kind: StatefulSet" rendered-with-redis.yaml  # Should see Redis StatefulSet
   grep "redis" rendered-with-redis.yaml               # Confirm the Redis resources
   ```

5. **Install** the umbrella chart (myapp + Redis) as a single Release:

   ```bash
   helm install myapp-redis ./myapp \
     --namespace practice-helm \
     --values myapp/values.yaml
   ```

6. **Verify**:

   ```bash
   kubectl get all -n practice-helm
   # You should see:
   # - myapp Deployment/Pods
   # - redis-master StatefulSet/Pods
   # - redis-master Service
   ```

7. **Clean Up**:

   ```bash
   helm uninstall myapp-redis --namespace practice-helm
   ```

---

## Exercise 6: Hooks, Tests, and CRDs

### 6.1. Add a Pre-Install Hook for a Database Migration

1. **Create** a simple Job template under `templates/` named `job-migrate.yaml`:

   ```yaml
   apiVersion: batch/v1
   kind: Job
   metadata:
     name: "{{ include "myapp.fullname" . }}-migrate"
     labels:
       app.kubernetes.io/name: {{ include "myapp.name" . }}
       app.kubernetes.io/instance: {{ .Release.Name }}
     annotations:
       "helm.sh/hook": pre-install
       "helm.sh/hook-weight": "0"
       "helm.sh/hook-delete-policy": hook-succeeded
   spec:
     template:
       metadata:
         name: "{{ include "myapp.fullname" . }}-migrate"
         labels:
           app.kubernetes.io/name: {{ include "myapp.name" . }}
           app.kubernetes.io/instance: {{ .Release.Name }}
       spec:
         restartPolicy: Never
         containers:
           - name: migrate
             image: alpine:3.14
             command:
               - sh
               - -c
               - |
                 echo "Running DB migrations..."
                 sleep 5
                 echo "Migrations complete"
   ```

2. **Install** or Upgrade your chart to see the hook run:

   ```bash
   helm install myapp-hook ./myapp --namespace practice-helm
   ```

    * Watch the Job run before the Deployment is created.
    * You can watch via `kubectl get jobs -n practice-helm` and inspect logs:

      ```bash
      kubectl logs job/myapp-hook-migrate -n practice-helm
      ```

3. **Cleanup**:

   ```bash
   helm uninstall myapp-hook --namespace practice-helm
   ```

### 6.2. Write a Simple Test Using Helm’s Test Framework

By default, the scaffolded chart includes `templates/tests/test-connection.yaml`. We’ll modify it to probe our app’s Service.

1. **Edit** `templates/tests/test-connection.yaml`:

   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: "{{ include "myapp.fullname" . }}-test-connection"
     labels:
       app.kubernetes.io/name: {{ include "myapp.name" . }}
       app.kubernetes.io/instance: {{ .Release.Name }}
     annotations:
       "helm.sh/hook": test-success
   spec:
     containers:
       - name: wget
         image: busybox
         command:
           - wget
           - "--spider"
           - "http://{{ include "myapp.fullname" . }}:8080"
     restartPolicy: Never
   ```

2. **Install** the chart:

   ```bash
   helm install myapp-test ./myapp --namespace practice-helm
   ```

3. **Run** Helm tests:

   ```bash
   helm test myapp-test --namespace practice-helm
   ```

    * You should see the `test-connection` pod run and exit with success if the Service page is reachable.

4. **Inspect** test logs if needed:

   ```bash
   kubectl logs pod/myapp-test-connection -n practice-helm
   ```

5. **Cleanup**:

   ```bash
   helm uninstall myapp-test --namespace practice-helm
   ```

### 6.3. Handle CRDs via `crds/` Directory

1. **Add** a CRD YAML under `myapp/crds/` (e.g., a dummy `SampleDatabase` CRD). Create `myapp/crds/sampledatabase-crd.yaml`:

   ```yaml
   apiVersion: apiextensions.k8s.io/v1
   kind: CustomResourceDefinition
   metadata:
     name: sampledatabases.example.com
   spec:
     group: example.com
     names:
       kind: SampleDatabase
       plural: sampledatabases
       singular: sampledatabase
     scope: Namespaced
     versions:
       - name: v1
         served: true
         storage: true
         schema:
           openAPIV3Schema:
             type: object
             properties:
               spec:
                 type: object
                 properties:
                   databaseName:
                     type: string
   ```

2. **Remove** any CRD‐related templates from `templates/`—only CRDs in `crds/` get installed automatically by Helm, before any other objects. Ensure you do **not** reference a CR in your other templates yet.

3. **Install** your chart:

   ```bash
   helm install myapp-crd ./myapp --namespace practice-helm
   ```

4. **Verify** that the CRD is installed (even though no CR was created):

   ```bash
   kubectl get crd sampledatabases.example.com
   ```

5. **Cleanup**:

   ```bash
   helm uninstall myapp-crd --namespace practice-helm
   ```

    * Notice: The CRD remains (Helm v3 by design does not delete CRDs on uninstall). To delete it manually:

      ```bash
      kubectl delete crd sampledatabases.example.com
      ```

---

## Exercise 7: GitOps with Helm (Using a Local Git Repo)

> For this exercise, you need Git installed locally and a GitOps‐style tool like Flux or Argo CD. If you don’t have either, simply simulate the process by making changes in a Git repo and manually running `helm upgrade`.

### 7.1. Initialize a Git Repo for Charts

1. **Create** a new folder outside `~/helm-exercises`, e.g.:

   ```bash
   mkdir ~/helm-gitops-demo
   cd ~/helm-gitops-demo
   git init
   ```

2. **Copy** your `myapp/` Chart directory here:

   ```bash
   cp -r ~/helm-exercises/myapp .
   ```

3. **Add & Commit**:

   ```bash
   git add myapp
   git commit -m "Initial commit: myapp Chart v0.2.0 (inc. Redis dependency)"
   ```

4. **Tag** the initial Chart version:

   ```bash
   git tag v0.2.0
   ```

### 7.2. Simulate a GitOps Deployment

1. **In a separate terminal**, install your Chart (pretend this is “production”):

   ```bash
   helm install myapp-gitops ./myapp \
     --namespace practice-helm \
     --values myapp/values.yaml
   ```

2. **Make a Change** in `myapp/values.yaml`—for instance, bump `replicaCount: 2 → 5`.

3. **Commit & Tag**:

   ```bash
   git add myapp/values.yaml
   git commit -m "Scale to 5 replicas for load test"
   git tag v0.3.0
   ```

4. **Manually “Sync” to the Cluster** (in lieu of an actual Flux/Argo operator, simply run `helm upgrade`):

   ```bash
   helm upgrade myapp-gitops ./myapp \
     --namespace practice-helm \
     --values myapp/values.yaml
   ```

5. **Verify** that 5 replicas are now running:

   ```bash
   kubectl get deployment myapp-gitops -n practice-helm -o wide
   ```

6. **Rollback via Git**: Suppose v0.3.0 is problematic and you want to revert to v0.2.0. In a real GitOps flow, you’d revert the Git commit (or change the `HelmRelease` spec). Here, simulate by checking out the old tag:

   ```bash
   git checkout v0.2.0 myapp/values.yaml    # revert values locally
   # Or: git revert HEAD   (to create a new commit that undoes the scale change)
   git commit -m "Revert to 2 replicas"
   ```

7. **Upgrade** to apply the rollback:

   ```bash
   helm upgrade myapp-gitops ./myapp \
     --namespace practice-helm \
     --values myapp/values.yaml
   ```

8. **Confirm** the replica count is back to 2:

   ```bash
   kubectl get deployment myapp-gitops -n practice-helm
   ```

9. **Cleanup**:

   ```bash
   helm uninstall myapp-gitops --namespace practice-helm
   ```

---

## Exercise 8: Use Helm’s OCI Support (Registry-Backed Charts)

> You need an OCI-compatible registry (e.g., Docker Hub, AWS ECR, GitHub Packages) that supports OCI artifacts. For demonstration, we’ll use a local Docker registry.

### 8.1. Run a Local Docker Registry

1. **Launch** a registry in Docker:

   ```bash
   docker run -d -p 5000:5000 --name registry registry:2
   ```

2. **Tag** and **Push** your Chart to the local registry:

   ```bash
   # Package the chart first (version in Chart.yaml must be set):
   helm package myapp
   # Suppose you got myapp-0.3.0.tgz

   # Save it as an OCI artifact
   helm chart save myapp-0.3.0.tgz oci://localhost:5000/myapp:0.3.0

   # Push to the registry
   helm chart push oci://localhost:5000/myapp:0.3.0
   ```

3. **Verify** it’s in the registry (via Docker CLI):

   ```bash
   curl -X GET http://localhost:5000/v2/_catalog
   # Should list “myapp”
   curl -X GET http://localhost:5000/v2/myapp/tags/list
   # Should list “0.3.0”
   ```

### 8.2. Pull & Install from the OCI Registry

1. **Login** to the registry (if needed). For a local insecure registry, you may need to allow insecure-registries in Docker’s daemon.json, or add `--insecure` flags in Helm:

   ```bash
   helm registry login localhost:5000 --username <any> --password <any> --insecure
   ```

2. **Pull** and **Export** the Chart:

   ```bash
   helm chart pull oci://localhost:5000/myapp:0.3.0
   helm chart export oci://localhost:5000/myapp:0.3.0 --destination ./exported
   cd exported/myapp
   ```

3. **Install** directly from the OCI reference (without exporting):

   ```bash
   helm install myapp-oci oci://localhost:5000/myapp:0.3.0 \
     --namespace practice-helm
   ```

4. **Verify** installation:

   ```bash
   kubectl get all -n practice-helm
   ```

5. **Uninstall**:

   ```bash
   helm uninstall myapp-oci --namespace practice-helm
   ```

6. **Clean Up**:

   ```bash
   helm chart remove oci://localhost:5000/myapp:0.3.0
   docker stop registry && docker rm registry
   ```

---

## Exercise 9: Common Pitfall Scenarios

### 9.1. Immutable Field Error

1. **Install** `myapp` normally:

   ```bash
   helm install myapp-immutable ./myapp --namespace practice-helm
   ```

2. **Modify** the `Service` template in `myapp/templates/service.yaml` to hard-code a new `clusterIP`. For example, add:

   ```yaml
   spec:
     type: {{ .Values.service.type }}
     ports:
       - port: {{ .Values.service.port }}
         targetPort: 8080
     clusterIP: "10.0.0.123"      # New immutable addition
   ```

3. **Upgrade**:

   ```bash
   helm upgrade myapp-immutable ./myapp --namespace practice-helm
   ```

    * You’ll see an error like:

      ```
      Error: UPGRADE FAILED: cannot patch "myapp-immutable" with kind Service: Service "myapp-immutable" is invalid: spec.clusterIP: Invalid value: "10.0.0.123": field is immutable
      ```

4. **Fix** by removing the `clusterIP` field from the template or making it conditional (only set when installing). For example:

   ```gotemplate
   spec:
     type: {{ .Values.service.type }}
     ports:
       - port: {{ .Values.service.port }}
         targetPort: 8080
     {{- if not (hasKey .Release.Revision "upgrade") }}
     clusterIP: {{ .Values.service.clusterIP | quote }}
     {{- end }}
   ```

   Or simply rely on Kubernetes to assign a clusterIP by omitting it entirely.

5. **Cleanup**:

   ```bash
   helm uninstall myapp-immutable --namespace practice-helm
   ```

### 9.2. Namespaced vs. Cluster-Scoped Resource Conflict

1. **Create** a `Role` in the chart’s `templates/` that references a hard-coded namespace (e.g., `hardcoded-ns`). For example, add `templates/role.yaml`:

   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: Role
   metadata:
     name: {{ include "myapp.fullname" . }}-role
     namespace: hardcoded-ns       # This is a mistake!
   rules:
     - apiGroups: [""]
       resources: ["pods"]
       verbs: ["get", "list"]
   ```

2. **Install** the chart without creating `hardcoded-ns`:

   ```bash
   helm install myapp-bad ./myapp --namespace practice-helm
   ```

    * You’ll get an error like:

      ```
      Error: INSTALLATION FAILED: namespaces "hardcoded-ns" not found
      ```

3. **Fix** by removing `namespace:` from that Role template (so it installs into the target namespace) or use `.Release.Namespace` dynamically:

   ```gotemplate
   metadata:
     name: {{ include "myapp.fullname" . }}-role
     namespace: {{ .Release.Namespace }}       # Correct
   ```

4. **Cleanup**:

   ```bash
   helm uninstall myapp-bad --namespace practice-helm
   ```

---

## Exercise 10: Helm Security & Best Practices Checklist

1. **Never Hard-Code Secrets**

    * Ensure that any sensitive information (passwords, certificates) is not placed in `values.yaml` in plaintext.
    * Instead, store credentials in a Kubernetes `Secret` (manually created) and reference it in your Chart via `lookup` or an external values file that is not checked into Git.

2. **Use `readOnlyRootFilesystem` & SecurityContext**

    * Amend your `myapp/templates/deployment.yaml` to include a strict `securityContext` (e.g., `runAsNonRoot: true`, `readOnlyRootFilesystem: true`, drop all capabilities).
    * Test that the Pod is rejected if these settings aren’t met by adding PodSecurityAdmission in your test namespace (see Kubernetes docs).

3. **Limit Resource Requests & Limits**

    * Make sure your Chart’s `values.yaml` includes sensible defaults for `resources.requests` and `resources.limits`.
    * Test that pods fail to schedule if they request more than available resources on the node.

4. **Enable `--atomic` & `--cleanup-on-fail` in CI/CD**

    * For any automated `helm upgrade` step, always include flags:

      ```bash
      helm upgrade myapp ./myapp \
        --namespace practice-helm \
        --values myapp/values.yaml \
        --atomic \
        --cleanup-on-fail \
        --timeout 10m \
        --wait
      ```
    * Verify that on a failed upgrade (e.g., invalid template introduced), Helm rolls back automatically.

5. **Chart Linting & Testing**

    * Add `helm lint ./myapp` as a CI step (e.g., in GitHub Actions).
    * Add `helm test` step to verify your test pods complete successfully after each install.

6. **Verify Dependencies Are Locked**

    * Inspect `myapp/Chart.lock` to ensure the Redis version (or any other subchart version) is exactly what you expect.
    * Do not run `helm dependency update` on CI unless you want to fetch newer patch releases—do this manually in development.

7. **Use Semantic Versioning**

    * Bump `version` in `Chart.yaml` properly. If you only changed values, increment patch (e.g., 0.2.0 → 0.2.1). If you changed templates in a backward-compatible way, bump minor (0.2.1 → 0.3.0). For breaking changes, bump major (0.3.0 → 1.0.0).

8. **Document Values**

    * Add comments in `values.yaml` describing each field (e.g., what `resources.limits.cpu` means, what `ingress.hosts` should contain).
    * Optionally, include a `README.md` in the Chart with usage examples.

---

## Cleanup All Practice Resources

When you finish all exercises, you can remove the namespace and any leftover resources:

```bash
helm list --namespace practice-helm | awk 'NR>1 { print $1 }' | xargs -n1 -r helm uninstall --namespace practice-helm
kubectl delete namespace practice-helm
# Optionally remove local helm-exercises folder:
# rm -rf ~/helm-exercises
```
