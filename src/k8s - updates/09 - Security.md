## 1. Organizing Cluster and User Information (`kubeconfig`)

All interactions with a Kubernetes cluster—whether by a human operator using `kubectl` or an automated script—are driven by the **kubeconfig** file. This YAML file declares:

* **Clusters:** API server endpoints and trust information
* **Users (Credentials):** How to authenticate as a human or service account
* **Contexts:** Named pairings of a cluster with a user (and an optional namespace)
* **Current Context:** The default context that `kubectl` will use

> **Key Takeaway:** A well-structured kubeconfig makes it easy to switch between clusters and users without having to retype commands or manually provide certificates/tokens.

### 1.1 kubeconfig Structure

A minimal kubeconfig might look like this:

```yaml
apiVersion: v1
kind: Config

clusters:
  - name: dev-cluster
    cluster:
      server: https://dev.example.com:6443
      certificate-authority-data: <base64-CA-cert>

  - name: prod-cluster
    cluster:
      server: https://prod.example.com:6443
      certificate-authority-data: <base64-CA-cert>

users:
  - name: alice
    user:
      client-certificate-data: <base64-user-client-cert>
      client-key-data:         <base64-user-client-key>

  - name: ci-bot
    user:
      token: <bearer-token>

contexts:
  - name: dev-alice
    context:
      cluster:   dev-cluster
      user:      alice
      namespace: development

  - name: prod-ci
    context:
      cluster:   prod-cluster
      user:      ci-bot
      namespace: ci

current-context: dev-alice
```

* **`clusters`**: Each entry pairs a `name` (an arbitrary identifier) with a `cluster` block that includes:

    * `server`: the API server URL (including port)
    * Either `certificate-authority-data` (base64-encoded CA) **or** `certificate-authority` (path to a local CA file)

* **`users`**: Contains one or more sets of credentials. A single user entry can include:

    * `client-certificate-data` + `client-key-data` (for X.509 auth)
    * **OR** a `token` value (for bearer-token or service-account auth)
    * **OR** an `auth-provider` (for OIDC/OAuth flows)

* **`contexts`**: Bundles together:

    * A `cluster` name
    * A `user` name
    * An optional `namespace`
      Each context has its own `name`.

* **`current-context`**: Tells `kubectl` which context to use by default unless overridden.

> **Example Workflow:**
>
> 1. You switch to the “prod-ci” context by running:
     >
     >    ```bash
>    kubectl config use-context prod-ci
>    ```
> 2. Now, all `kubectl` commands are sent to `https://prod.example.com:6443`, using the service-account token of `ci-bot`, scoped to the `ci` namespace.

### 1.2 Merging Multiple kubeconfig Files

In environments where administrators need to manage several clusters simultaneously (for example, a development cluster and a production cluster), it’s common to have separate kubeconfig files. You can merge them by setting the `KUBECONFIG` environment variable with a colon-separated list of file paths:

```bash
export KUBECONFIG=$HOME/.kube/config:/etc/kubernetes/admin.conf:/home/alice/.kube/other-config
```

When you run `kubectl`, it merges all `clusters`, `users`, and `contexts` across those files. You may then choose any of the combined contexts with:

```bash
kubectl config get-contexts
kubectl config use-context <context-name>
```

> **Tip:** If a credential or cluster entry shares the same `name` across multiple files, the last file in the list will override earlier entries with that same name.

---

## 2. User Types: Human Users vs. Service Accounts

Kubernetes separates “users” into two broad categories:

1. **Normal (Human) Users**
2. **Service Accounts** (for workloads running *inside* the cluster)

Understanding these distinctions is crucial for correct authentication and authorization.

### 2.1 Normal (Human) Users

* Kubernetes does **not** maintain a first-class API object called “User” for people.
* Instead, human credentials (X.509 certificates, OIDC tokens, etc.) are **issued externally** (for example, by a corporate CA, a cloud-provider IAM, or an operating department).
* When a human runs `kubectl`, the API server inspects the client certificate’s `CN` (Common Name) or the OIDC token’s subject to determine identity.
* Since there is no `User` resource in the API, you grant permissions to a human by referring to their certificate `CN` (for X.509) or their group/username claim (for OIDC).

> **Example:**
>
> * If an admin issues a certificate with `CN=alice` and `O=dev-team`, then in RBAC configurations (explained in Section 4), you may grant that user:
    >
    >   ```yaml
>   subjects:
>     - kind: User
>       name: alice
>       apiGroup: rbac.authorization.k8s.io
>   ```
    >
    >   Or, grant to the group `dev-team` based on that certificate’s `O=` field.

### 2.2 Service Accounts (In-Cluster Identities)

A **ServiceAccount** is a Kubernetes API resource scoped to a namespace. By default, each namespace has a `default` ServiceAccount automatically created. Key points:

* **Purpose:** Grant Pods (and controllers) an identity to talk to the API server *from within* the cluster, without embedding long-lived credentials in code.
* **Token Mounting:**

    * When you schedule a Pod and set `spec.serviceAccountName: my-app-sa`, Kubernetes automatically:

        1. Generates a signed **JWT token** for that ServiceAccount.
        2. Mounts the token as a file in the Pod at `/var/run/secrets/kubernetes.io/serviceaccount/token`.
    * The token includes:

        * ServiceAccount’s namespace
        * ServiceAccount’s name
        * The cluster’s issuer URL
* **Built-In Names:** The Pod’s identity is seen as `system:serviceaccount:<namespace>:<service-account-name>`.

> **Example YAML:**
>
> ```yaml
> apiVersion: v1
> kind: ServiceAccount
> metadata:
>   name: my-app-sa
>   namespace: production
> ---
> apiVersion: apps/v1
> kind: Deployment
> metadata:
>   name: my-app
>   namespace: production
> spec:
>   replicas: 2
>   template:
>     metadata:
>       labels:
>         app: my-app
>     spec:
>       serviceAccountName: my-app-sa
>       containers:
>         - name: server
>           image: myapp:latest
>           # Kubernetes will mount the SA token automatically
> ```
>
> In this example, every Pod in the Deployment will authenticate to the API server as `system:serviceaccount:production:my-app-sa`.

---

## 3. Cluster Authentication: X.509 Certificates for Users

Kubernetes supports multiple authentication modes (bearer token, OIDC, webhook, etc.), but one of the most common for human users is **X.509 client certificates**.

### 3.1 How X.509 Authentication Works

1. **Cluster CA Configuration:** When you start the API server, you specify a trusted Certificate Authority (CA) with flags such as `--client-ca-file=/etc/kubernetes/pki/ca.crt`.
2. **Generating a Key Pair & CSR (Certificate Signing Request) Locally:**

   ```bash
   # 1. Generate a private key for user "developer"
   openssl genrsa -out developer.key 2048

   # 2. Create a CSR; set CN=developer (username) and O=dev-team (group)
   openssl req -new -key developer.key -out developer.csr \
     -subj "/CN=developer/O=dev-team"
   ```

    * The CSR’s subject fields (`CN` and `O`) become Kubernetes’ internal “username” and “group” claims when the certificate is presented.
3. **Signing the CSR:**

    * **Option A (Manual Signing with the Cluster’s CA):**

      ```bash
      openssl x509 -req \
        -in developer.csr \
        -CA /etc/kubernetes/pki/ca.crt \
        -CAkey /etc/kubernetes/pki/ca.key \
        -CAcreateserial \
        -out developer.crt \
        -days 365 \
        -extensions v3_ext \
        -extfile <(printf "extendedKeyUsage = clientAuth")
      ```

      This produces `developer.crt`, a client certificate signed by the cluster’s CA.
    * **Option B (Kubernetes CSR API Workflow):**

        1. Create a `CertificateSigningRequest` object that embeds the base64-encoded CSR:

           ```yaml
           apiVersion: certificates.k8s.io/v1
           kind: CertificateSigningRequest
           metadata:
             name: developer-csr
           spec:
             request: $(cat developer.csr | base64 | tr -d '\n')
             signerName: kubernetes.io/kube-apiserver-client
             usages:
               - client auth
           ```
        2. Apply and approve it:

           ```bash
           kubectl apply -f developer-csr.yaml
           kubectl certificate approve developer-csr
           kubectl get csr developer-csr \
             -o jsonpath='{.status.certificate}' \
             | base64 -d > developer.crt
           ```
4. **Updating kubeconfig for the User:**
   Once you have `developer.key` and `developer.crt`, configure the kubeconfig to embed those credentials:

   ```bash
   kubectl config set-cluster dev-cluster \
     --server=https://dev.example.com:6443 \
     --certificate-authority=/path/to/ca.crt \
     --embed-certs=true

   kubectl config set-credentials developer \
     --client-certificate=developer.crt \
     --client-key=developer.key \
     --embed-certs=true

   kubectl config set-context dev-developer \
     --cluster=dev-cluster \
     --user=developer \
     --namespace=development

   kubectl config use-context dev-developer
   ```

    * `--embed-certs=true` inlines the certificates, avoiding external file references.
    * The API server will reject any request from this user if the certificate is invalid, expired, or has an unexpected subject.

> **Other Authentication Mechanisms (for reference):**
>
> * **Bearer Tokens:** Commonly used by ServiceAccounts (automatically generated JWTs) or by a custom token issuer.
> * **OpenID Connect (OIDC):** You can configure the API server with flags like `--oidc-issuer-url`, `--oidc-client-id`, etc. Users authenticate through an identity provider (e.g., Azure AD, Google), and the API server validates the ID token.
> * **Webhook/Token Review:** The API server can reach out to an external HTTP endpoint to ask “is this token valid?”

---

## 4. Role-Based Access Control (RBAC)

After a user or ServiceAccount is authenticated, Kubernetes must decide **which operations that identity is allowed to perform**. RBAC (Role-Based Access Control) is the default and recommended authorization mode. It consists of four primary Kubernetes resources:

1. **Role (namespace-scoped)**
2. **ClusterRole (cluster-scoped)**
3. **RoleBinding (namespace-scoped)**
4. **ClusterRoleBinding (cluster-scoped)**

### 4.1 Defining Permissions with Roles and ClusterRoles

* A **Role** grants permission *within a single namespace*.
* A **ClusterRole** grants permission across **all** namespaces (or on cluster-scoped resources, like `nodes`, `namespaces`, `clusterroles`).

Each Role or ClusterRole consists of one or more `rules`, each rule specifying:

* `apiGroups`: Which API group(s) (e.g., `""` for core, `"apps"` for Deployments)
* `resources`: Which resource type(s) (e.g., `pods`, `configmaps`)
* `verbs`: Which verbs/actions are permitted (e.g., `get`, `list`, `watch`, `create`, `update`, `delete`)

> **Example**
>
> 1. **Namespace-Scoped Role** (read-only access to Pods and ConfigMaps in `staging`):
     >
     >    ```yaml
>    apiVersion: rbac.authorization.k8s.io/v1
>    kind: Role
>    metadata:
>      name: read-staging
>      namespace: staging
>    rules:
>      - apiGroups: [""]
>        resources: ["pods", "configmaps"]
>        verbs: ["get", "list", "watch"]
>    ```
>
> 2. **Cluster-Scoped Role** (full node management cluster-wide):
     >
     >    ```yaml
>    apiVersion: rbac.authorization.k8s.io/v1
>    kind: ClusterRole
>    metadata:
>      name: node-admin
>    rules:
>      - apiGroups: [""]
>        resources: ["nodes"]
>        verbs: ["get", "list", "watch", "patch", "update", "delete"]
>    ```

### 4.2 Binding Roles to Users, Groups, or ServiceAccounts

* A **RoleBinding** attaches a `Role` to one or more subjects **within the same namespace**.
* A **ClusterRoleBinding** attaches a `ClusterRole` to subjects **across the entire cluster**.

Each `Binding` has:

* `subjects`: A list of things you’re giving permissions to (each can be a `User`, a `Group`, or a `ServiceAccount`)
* `roleRef`: A reference to either a `Role` or a `ClusterRole`

> **Example**
>
> 1. **RoleBinding**: Grant the `read-staging` Role to user “developer” in namespace `staging`:
     >
     >    ```yaml
>    apiVersion: rbac.authorization.k8s.io/v1
>    kind: RoleBinding
>    metadata:
>      name: bind-read-staging
>      namespace: staging
>    subjects:
>      - kind: User
>        name: developer
>        apiGroup: rbac.authorization.k8s.io
>    roleRef:
>      kind: Role
>      name: read-staging
>      apiGroup: rbac.authorization.k8s.io
>    ```
>
> 2. **ClusterRoleBinding**: Grant the `node-admin` ClusterRole to group “ops-team” cluster-wide:
     >
     >    ```yaml
>    apiVersion: rbac.authorization.k8s.io/v1
>    kind: ClusterRoleBinding
>    metadata:
>      name: bind-node-admin
>    subjects:
>      - kind: Group
>        name: ops-team
>        apiGroup: rbac.authorization.k8s.io
>    roleRef:
>      kind: ClusterRole
>      name: node-admin
>      apiGroup: rbac.authorization.k8s.io
>    ```

When an API request arrives (for example, “`GET /api/v1/namespaces/staging/pods`”), Kubernetes:

1. Authenticates the client (e.g., “developer” via X.509 certificate).
2. Enumerates all RoleBindings in `staging` and all ClusterRoleBindings in the cluster that mention “developer” (or any group it belongs to).
3. Checks whether any of those bindings reference a Role/ClusterRole whose rules allow the `get` verb on the `pods` resource in the `""` (core) API group. If at least one binding matches, the request is allowed; otherwise, it is denied.

### 4.3 RBAC Best Practices

1. **Principle of Least Privilege**

    * Grant only the smallest set of verbs/resources a subject needs. For example, if a service only needs to read ConfigMaps, do not give it permission to modify Secrets or manage Pods.

2. **Namespace Isolation**

    * Use namespace-scoped Roles and RoleBindings for most application workloads. Only create broad ClusterRoles when necessary (for example, managing nodes or cluster-scoped network configurations).

3. **Use Groups (via OIDC/LDAP Claims)**

    * If your org’s identity provider can emit group claims (for example, `dev-team`, `qa-team`), bind to those groups instead of individual users. This makes it easier to add/remove people without updating Kubernetes YAML every time.

4. **Separate Read-Only vs. Read-Write**

    * Create distinct Roles (e.g., `view-pods`, `edit-configmaps`) rather than one giant “admin” role.

5. **Audit and Rotate Permissions**

    * Periodically review all RoleBindings and ClusterRoleBindings. Remove any stale or unused ones.
    * When a service or person no longer needs access (for example, if a developer changes teams), revoke or update their RoleBindings.

---

## 5. Admission Controllers: Validating and Mutating API Requests

After authentication and authorization, every API request still passes through the **admission control** phase. Admission controllers can be grouped into two categories:

1. **Validating Admission Controllers**
2. **Mutating Admission Controllers**

They either approve/deny requests (Validating) or modify requests on the fly (Mutating) before objects are persisted.

> **Key Principle:** Layering admission control on top of RBAC ensures that even an authorized user cannot create resources that violate cluster policies.

### 5.1 Built-In Admission Controllers

Kubernetes ships with a set of built-in admission controllers that enforce fundamental security and governance rules. Some common ones include:

* **NamespaceLifecycle:** Prevents deletion of a namespace that still has resources (protects against orphaned objects).
* **LimitRanger:** Enforces default resource requests/limits in Pods (if a default `LimitRange` is defined in the namespace).
* **ServiceAccount:** Ensures that Pods reference a valid ServiceAccount and automatically injects a ServiceAccount token if not provided.
* **DefaultStorageClass:** Automatically assigns a default `StorageClass` to a `PersistentVolumeClaim` when none is specified.
* **PersistentVolumeLabel:** Applies topology labels to `PersistentVolume` objects.
* **CertificateApproval / CertificateSigning / CertificateSubjectRestriction:** Manage how CSRs are approved or rejected based on policy.
* **PodSecurity (v1.25+):** Enforces Pod security standards (e.g., `restricted` vs. `baseline`). Replaces the deprecated `PodSecurityPolicy`.
* **ResourceQuota:** Tracks and enforces quotas (e.g., CPU, memory, number of objects) per namespace.

When you start the API server, you can specify exactly which admission controllers to enable or disable:

```bash
kube-apiserver \
  --enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,CertificateApproval,CertificateSigning,CertificateSubjectRestriction,ResourceQuota,PodSecurity \
  --disable-admission-plugins=PodSecurityPolicy
```

* If an enabled admission controller rejects a request (for example, a Pod violates memory limits), the API server returns an error immediately, and no further admission plugins run.

### 5.2 Custom Admission Webhooks

For organization-specific or more nuanced policies beyond what built-in controllers can do, you can deploy your own **Admission Webhook** services. These are Kubernetes workloads (or external HTTPS endpoints) that the API server calls during admission. There are two webhook types:

1. **MutatingWebhookConfiguration:**

    * Can modify the incoming object before it is stored.
    * Common use: auto-injecting sidecar containers (e.g., Istio, logging agents), adding default labels/annotations, injecting resource requests.
2. **ValidatingWebhookConfiguration:**

    * Checks the incoming object and returns “allowed: true” or “allowed: false” (with an error message).
    * Common use: enforcing internal security policy (e.g., no `hostPath` mounts, no privileged containers).

Each webhook configuration includes:

* **`webhooks`** array, where each entry has:

    * `name`: The DNS name of your webhook (e.g., `policy.example.com`).
    * `clientConfig`: How to call your service (either a `service` reference or a `URL`) and the `caBundle` to verify its TLS certificate.
    * `rules`: Which operations (`CREATE`, `UPDATE`, etc.), API groups, versions, and resources the webhook should intercept.
    * `failurePolicy`:

        * `Fail` means if the webhook cannot be contacted or errors, Kubernetes will reject the request (strong enforcement).
        * `Ignore` means on failure, the API server proceeds as if the webhook allowed the request.
    * `timeoutSeconds`: How long to wait for the webhook to respond before timing out.

> **Example: Validating Webhook**
>
> ```yaml
> apiVersion: admissionregistration.k8s.io/v1
> kind: ValidatingWebhookConfiguration
> metadata:
>   name: example-validate
> webhooks:
>   - name: validate.example.com
>     clientConfig:
>       service:
>         name: example-webhook-svc
>         namespace: webhooks
>         path: /validate
>       caBundle: <base64-CA-cert-of-webhook>
>     rules:
>       - operations: ["CREATE", "UPDATE"]
>         apiGroups: ["apps"]
>         apiVersions: ["v1"]
>         resources: ["deployments"]
>     failurePolicy: Fail
>     timeoutSeconds: 5
>     admissionReviewVersions: ["v1"]
> ```

#### 5.2.1 Developing a Webhook Service

1. **Implement the Admission Review API:**

    * Your service must accept HTTP `POST` requests with a JSON body matching the `AdmissionReview` schema (`kind: AdmissionReview` with `request` fields).
    * For **Validating**, return an `AdmissionReview` with `response.allowed=true/false` (and a `status.message` if denied).
    * For **Mutating**, return an `AdmissionReview` with `response.patch` (base64-encoded JSON patch) and `response.patchType: "JSONPatch"`, plus `allowed:true`.

2. **Enable the Webhook Flags on the API Server**

    * In `kube-apiserver` startup flags:

      ```bash
      --enable-admission-plugins=...,MutatingAdmissionWebhook,ValidatingAdmissionWebhook
      ```
    * Webhooks must be registered *after* these plugins are enabled.

3. **Secure TLS Communication**

    * Webhook servers should present a certificate issued by a CA that the API server trusts.
    * Embed that CA’s certificate in `caBundle` of your WebhookConfiguration so the API server can verify the connection.

### 5.3 Admission Controller Best Practices

1. **Enable Only Necessary Plugins**

    * Unnecessary admission controllers add latency to every API call. Review and enable only the plugins you need (e.g., `PodSecurity`, `ResourceQuota`, etc.).

2. **Use Namespace-Level Pod Security Admission (PSA)**

    * Replace Pod Security Policy (deprecated) by labeling namespaces with `pod-security.kubernetes.io/enforce=<mode>`.
    * Modes:

        * `privileged` (no restrictions, for system/cluster workloads)
        * `baseline` (blocks known privilege escalations)
        * `restricted` (most stringent: non-root, read-only root FS, no privileged mode, minimal capabilities)
    * Example to enforce “restricted” on namespace `production`:

      ```bash
      kubectl label namespace production pod-security.kubernetes.io/enforce=restricted
      kubectl label namespace production pod-security.kubernetes.io/enforce-version=latest
      ```
    * Any Pod that violates the `restricted` standard will be denied.

3. **Secure Custom Webhooks**

    * Use a strong, trusted CA for TLS.
    * Keep `timeoutSeconds` low (e.g., 5 seconds) to avoid slow API calls.
    * Consider `failurePolicy: Ignore` for non-critical checks so that a webhook outage does not block the entire cluster.

4. **Avoid Long-Running Admission Logic**

    * Webhooks should be idempotent, stateless, and return quickly.
    * Do not rely on external network calls or slow operations.

5. **Throttle/Rate-Limit Webhooks**

    * If your webhook service is under heavy load, kindly degrade (e.g., with `failurePolicy: Ignore`) rather than cause cascading failures.

---

### References for Further Reading

* **kubeconfig and Organizing Cluster Access**
  [https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/)
* **Kubernetes Authentication**
  [https://kubernetes.io/docs/reference/access-authn-authz/authentication/](https://kubernetes.io/docs/reference/access-authn-authz/authentication/)
* **Kubernetes RBAC**
  [https://kubernetes.io/docs/reference/access-authn-authz/rbac/](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
* **Admission Controllers**
  [https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/)
* **Pod Security Admission (PSA)**
  [https://kubernetes.io/docs/concepts/security/pod-security-admission/](https://kubernetes.io/docs/concepts/security/pod-security-admission/)

