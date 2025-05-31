## Exercise 1: Ephemeral Scratch Space with `emptyDir`

**Objective**
Learn how to use an `emptyDir` volume for temporary (pod-lifetime) storage and verify that its contents persist across container restarts but are deleted when the Pod is removed.

### 1.1. Create a Namespace

```bash
kubectl create namespace volume-exercise
```

### 1.2. Apply a Pod Manifest with `emptyDir`

Create a file named `emptydir-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: emptydir-demo
  namespace: volume-exercise
spec:
  volumes:
    - name: scratch
      emptyDir: {}
  containers:
    - name: writer
      image: busybox:1.35
      command:
        - sh
        - -c
        - |
          echo "Hello, $(date)" >> /mnt/scratch/log.txt
          sleep 3600
      volumeMounts:
        - name: scratch
          mountPath: /mnt/scratch
    - name: reader
      image: busybox:1.35
      command:
        - sh
        - -c
        - |
          while true; do
            echo "--- $(date) - Reader sees: ---"
            cat /mnt/scratch/log.txt
            sleep 30
          done
      volumeMounts:
        - name: scratch
          mountPath: /mnt/scratch
```

Apply it:

```bash
kubectl apply -f emptydir-pod.yaml
```

### 1.3. Verify Behavior

1. **Check Pod Status**:

   ```bash
   kubectl get pods -n volume-exercise emptydir-demo
   ```

   > **Expected:** Pod `emptydir-demo` is in `Running` state, with two containers (`writer` and `reader`).

2. **Watch Reader Logs**:

   ```bash
   kubectl logs -f emptydir-demo -c reader -n volume-exercise
   ```

   > **Expected:**
   > Every 30 seconds, you see “Reader sees:” followed by the contents of `/mnt/scratch/log.txt`, which should contain at least one line starting with “Hello, …”.

3. **Restart the `writer` Container**:

   ```bash
   kubectl exec -it emptydir-demo -n volume-exercise -c writer -- sh -c "kill 1"
   ```

   This simulates a crash in the `writer` container (PID 1 inside that container). kubelet will restart only the `writer` container.

4. **Verify that Data Persists**:

   Within a minute or two, check the `reader` logs again:

   ```bash
   kubectl logs -f emptydir-demo -c reader -n volume-exercise
   ```

   > **Expected:** The existing “Hello, …” lines remain. The restarted `writer` will append a new “Hello, …” next time it runs, and `reader` sees it—showing that the `emptyDir` persisted across container restarts.

5. **Delete the Pod Entirely**:

   ```bash
   kubectl delete pod emptydir-demo -n volume-exercise
   ```

6. **Recreate the Pod**:

   ```bash
   kubectl apply -f emptydir-pod.yaml
   ```

   > **Expected:** Upon recreating, `/mnt/scratch/log.txt` is empty (because a brand-new `emptyDir` was provisioned). The `reader` will only see new lines after the `writer` writes again.

---

## Exercise 2: Injecting ConfigMaps and Secrets as Volumes

**Objective**
Mount a ConfigMap and a Secret into a Pod as files, inspect their contents inside the container, and verify file permissions.

### 2.1. Create a ConfigMap

```bash
kubectl create configmap app-config \
  --namespace=volume-exercise \
  --from-literal=app.properties="log.level=DEBUG
retry.count=5"
```

### 2.2. Create a Secret

```bash
kubectl create secret generic db-secret \
  --namespace=volume-exercise \
  --from-literal=username=admin \
  --from-literal=password=s3cr3t
```

### 2.3. Pod Manifest Mounting Both

Create `config-secret-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: config-secret-demo
  namespace: volume-exercise
spec:
  securityContext:
    fsGroup: 2000
  volumes:
    - name: config-volume
      configMap:
        name: app-config
        defaultMode: 0644
    - name: secret-volume
      secret:
        secretName: db-secret
        defaultMode: 0400
  containers:
    - name: app
      image: busybox:1.35
      command:
        - sh
        - -c
        - |
          echo "Contents of /etc/config/app.properties:"
          cat /etc/config/app.properties
          echo "Permissions of /etc/config/app.properties:"
          ls -l /etc/config/app.properties
          echo ""
          echo "Contents of /etc/secret/username and password:"
          cat /etc/secret/username /etc/secret/password
          echo "Permissions of secret files:"
          ls -l /etc/secret
          sleep 3600
      volumeMounts:
        - name: config-volume
          mountPath: /etc/config
          readOnly: true
        - name: secret-volume
          mountPath: /etc/secret
          readOnly: true
```

Apply it:

```bash
kubectl apply -f config-secret-pod.yaml
```

### 2.4. Verify Inside the Pod

Exec into the Pod:

```bash
kubectl exec -it config-secret-demo -n volume-exercise -- sh
```

Inside, you should see:

```shell
# From the command output printed at startup:
Contents of /etc/config/app.properties:
log.level=DEBUG
retry.count=5
Permissions of /etc/config/app.properties:
-rw-r--r--    1 1000     2000           23 Jun  1 12:34 /etc/config/app.properties

Contents of /etc/secret/username and password:
admin
s3cr3t
Permissions of secret files:
-r---r--r--    1 1000     2000            5 Jun  1 12:34 /etc/secret/username
-r---r--r--    1 1000     2000            6 Jun  1 12:34 /etc/secret/password
```

> **Notes**
>
> * `fsGroup: 2000` means the mounted files are group-owned by GID 2000.
> * `defaultMode: 0644` for the ConfigMap yields `-rw-r--r--`.
> * `defaultMode: 0400` for the Secret yields `-r---r--r--` by default (owner can only read; group “fsGroup” can read; others can read because of how Kubernetes projects secrets).

Exit the Pod:

```bash
exit
```

---

## Exercise 3: Using `hostPath` to Access Node Files

> **Warning:** Using `hostPath` can be dangerous (breaks portability and poses security risks). Only run this on a test cluster or ensure `/tmp/hostpath-demo` exists on all nodes.

**Objective**
Mount a directory from the host node into a Pod, write a file from inside the Pod, and verify it on the host.

### 3.1. Prepare a Directory on All Nodes

On each node (or, if single-node cluster, on that node), run:

```bash
sudo mkdir -p /tmp/hostpath-demo
sudo chown 1000:1000 /tmp/hostpath-demo
```

(This ensures a consistent path exists on each node and is writable by UID 1000.)

### 3.2. Create a Pod Using `hostPath`

Create `hostpath-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hostpath-demo
  namespace: volume-exercise
spec:
  volumes:
    - name: host-volume
      hostPath:
        path: /tmp/hostpath-demo
        type: DirectoryOrCreate
  containers:
    - name: writer
      image: busybox:1.35
      securityContext:
        runAsUser: 1000
      command:
        - sh
        - -c
        - |
          echo "Hello from Pod at $(date)" >> /data/out.txt
          sleep 3600
      volumeMounts:
        - name: host-volume
          mountPath: /data
```

Apply it:

```bash
kubectl apply -f hostpath-pod.yaml
```

### 3.3. Verify File on the Host

1. **Check Pod Status**:

   ```bash
   kubectl get pods -n volume-exercise hostpath-demo
   ```

2. **On the Node’s Shell** (where `/tmp/hostpath-demo` was created), run:

   ```bash
   ls -l /tmp/hostpath-demo
   cat /tmp/hostpath-demo/out.txt
   ```

   > **Expected:** You see a file `out.txt` containing “Hello from Pod at …” (verifying that the Pod wrote to the host directory).

3. **Cleanup**:

   ```bash
   kubectl delete pod hostpath-demo -n volume-exercise
   sudo rm -rf /tmp/hostpath-demo/out.txt
   ```

---

## Exercise 4: Statically Provision a PersistentVolume and Bind It to a PVC

**Objective**
Manually create a `PersistentVolume` of type `hostPath`, then create a `PersistentVolumeClaim` that binds to it. Finally, mount that PVC into a Pod and verify data persistence across Pod restarts.

> **Warning:** `hostPath` in a PV is only for demonstration. In production, use network-backed or cloud-backed PVs.

### 4.1. Create a Static `PersistentVolume`

Create `static-pv.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: hostpath-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /tmp/hostpath-pv-data
    type: DirectoryOrCreate
  persistentVolumeReclaimPolicy: Retain
```

Apply:

```bash
kubectl apply -f static-pv.yaml
```

> **Expected:** The PV appears in `kubectl get pv` with `STATUS: Available`.

### 4.2. Create a Matching `PersistentVolumeClaim`

Create `static-pvc.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: hostpath-pvc
  namespace: volume-exercise
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  volumeName: hostpath-pv
```

Apply:

```bash
kubectl apply -f static-pvc.yaml
```

> **Expected:** The PVC status becomes `Bound`, and the PV’s `STATUS` changes to `Bound` as well.

Verify:

```bash
kubectl get pvc -n volume-exercise
kubectl get pv
```

### 4.3. Use the PVC in a Pod

Create `static-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hostpath-consumer
  namespace: volume-exercise
spec:
  containers:
    - name: app
      image: busybox:1.35
      command:
        - sh
        - -c
        - |
          echo "First line at $(date)" >> /mnt/data/log.txt
          cat /mnt/data/log.txt
          sleep 3600
      volumeMounts:
        - name: data
          mountPath: /mnt/data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: hostpath-pvc
```

Apply:

```bash
kubectl apply -f static-pod.yaml
```

### 4.4. Verify Persistence Across Pod Restarts

1. **Inspect Pod Logs**:

   ```bash
   kubectl logs hostpath-consumer -n volume-exercise
   ```

   > **Expected:** Shows “First line at …”.

2. **Delete and Recreate Pod (Using Same PVC)**:

   ```bash
   kubectl delete pod hostpath-consumer -n volume-exercise
   kubectl apply -f static-pod.yaml
   ```

3. **Check Pod Logs Again**:

   ```bash
   kubectl logs hostpath-consumer -n volume-exercise
   ```

   > **Expected:** Displays both the old “First line…” and a new “First line at …” appended. The data under `/mnt/data/log.txt` was preserved because it lives on the PV.

4. **Clean Up**:

   ```bash
   kubectl delete pod hostpath-consumer -n volume-exercise
   kubectl delete pvc hostpath-pvc -n volume-exercise
   kubectl delete pv hostpath-pv
   sudo rm -rf /tmp/hostpath-pv-data
   ```

---

## Exercise 5: Dynamically Provision a PV with a StorageClass (Cloud or CSI)

> **Prerequisite:** Your cluster must have a default StorageClass or a CSI driver installed. For example, on GKE/EKS, `standard` or `gp2` exists. If you have a custom CSI driver (e.g., `ebs.csi.aws.com` or `csi.vsphere.vmware.com`), you can reference that.

**Objective**
Create a PVC requesting dynamic provisioning via a StorageClass, then mount it in a Pod.

### 5.1. Inspect Existing StorageClasses

```bash
kubectl get storageclass
```

Note the name of a suitable class (e.g., `standard`, `gp2`, or a CSI-backed class).

### 5.2. Create a PVC Without Specifying `volumeName`

Create `dynamic-pvc.yaml` (using a StorageClass called `standard`—replace as needed):

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dynamic-claim
  namespace: volume-exercise
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
  storageClassName: standard
```

Apply:

```bash
kubectl apply -f dynamic-pvc.yaml
```

Verify:

```bash
kubectl get pvc dynamic-claim -n volume-exercise
kubectl get pv
```

> **Expected:** A new PV is dynamically provisioned (PV status becomes `Bound`, PVC status becomes `Bound`).

### 5.3. Use the PVC in a Pod

Create `dynamic-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dynamic-consumer
  namespace: volume-exercise
spec:
  containers:
    - name: app
      image: busybox:1.35
      command:
        - sh
        - -c
        - |
          echo "Writing to dynamic volume at $(date)" >> /data/log.txt
          cat /data/log.txt
          sleep 3600
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: dynamic-claim
```

Apply:

```bash
kubectl apply -f dynamic-pod.yaml
```

Verify:

```bash
kubectl logs dynamic-consumer -n volume-exercise
```

> **Expected:** Shows “Writing to dynamic volume at …”.

4. **Delete Pod and Recreate** to confirm data persists:

   ```bash
   kubectl delete pod dynamic-consumer -n volume-exercise
   kubectl apply -f dynamic-pod.yaml
   kubectl logs dynamic-consumer -n volume-exercise
   ```

   > **Expected:** The log file now has two lines (old + new), proving persistence.

5. **Clean Up**:

   ```bash
   kubectl delete pod dynamic-consumer -n volume-exercise
   kubectl delete pvc dynamic-claim -n volume-exercise
   ```

   > Depending on your StorageClass’s `reclaimPolicy` (likely `Delete`), the underlying volume (e.g., EBS, GCE PD) is also deleted. If it is `Retain`, you must manually delete the PV afterwards.

---

## Exercise 6: Resize a PVC (if the StorageClass Supports Expansion)

> **Prerequisite:** The StorageClass used must have `allowVolumeExpansion: true`, and your CSI driver must support in-place expansion. Many cloud providers’ default classes do.

**Objective**
Resize an existing PVC from 2 Gi to 4 Gi, then verify the expansion inside the Pod.

### 6.1. Inspect the PVC and StorageClass

Assuming you used `dynamic-claim` from Exercise 5:

```bash
kubectl get pvc dynamic-claim -n volume-exercise -o yaml
kubectl get storageclass standard -o yaml
```

Verify `allowVolumeExpansion: true` under the StorageClass.

### 6.2. Edit the PVC to Request 4 Gi

```bash
kubectl patch pvc dynamic-claim -n volume-exercise \
  -p '{"spec": {"resources": {"requests": {"storage": "4Gi"}}}}'
```

> **Expected:** PVC’s `status.capacity.storage` eventually updates from `2Gi` to `4Gi`. You may see `FileSystemResizePending` in conditions.

### 6.3. If Already Mounted in a Pod

If you currently have `dynamic-consumer` from Exercise 5 running, you need to trigger a volume filesystem resize. In newer Kubernetes versions, this happens automatically when the Pod is restarted:

1. **Delete and Recreate the Pod** (so kubelet remounts and expands the filesystem):

   ```bash
   kubectl delete pod dynamic-consumer -n volume-exercise
   kubectl apply -f dynamic-pod.yaml
   ```

2. **Exec Into the Pod and Check Volume Size**:

   ```bash
   POD=$(kubectl get pod -n volume-exercise -l app=busybox -o jsonpath="{.items[0].metadata.name}")
   kubectl exec -it dynamic-consumer -n volume-exercise -- sh -c "df -h /data"
   ```

   > **Expected:** The `/data` mount shows \~4 Gi available instead of \~2 Gi.

If the resize does not happen automatically, your CSI driver or kubelet may require manual steps (e.g., `resizeFS: true` under PVC), but most managed Kubernetes clusters handle this seamlessly.

---

## Exercise 7: Take a VolumeSnapshot and Restore from It

> **Prerequisite:** Your cluster must have the VolumeSnapshot CRDs installed and a CSI driver that implements snapshot functionality. Many managed Kubernetes offerings (GKE, EKS) enable this via their CSI drivers.

**Objective**
Create a `VolumeSnapshot` of an existing PVC, then restore it into a new PVC and mount that in a Pod.

### 7.1. Verify VolumeSnapshot Support

```bash
kubectl get crd volumesnapshots.snapshot.storage.k8s.io
```

You should see `volumesnapshots.snapshot.storage.k8s.io` and related CRDs. Also list available `VolumeSnapshotClass` objects:

```bash
kubectl get volumesnapshotclass
```

Pick a snapshot class (e.g., `csi-snapshot-class`); if none exists, your cluster may not support snapshots yet.

### 7.2. Create a VolumeSnapshot

Assuming you still have `dynamic-claim` from Exercise 5:

Create `snapshot.yaml`:

```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: dynamic-snapshot
  namespace: volume-exercise
spec:
  volumeSnapshotClassName: csi-snapshot-class     # Replace with your snapshot class
  source:
    persistentVolumeClaimName: dynamic-claim
```

Apply:

```bash
kubectl apply -f snapshot.yaml
```

Verify:

```bash
kubectl get volumesnapshot dynamic-snapshot -n volume-exercise
kubectl describe volumesnapshot dynamic-snapshot -n volume-exercise
```

> **Expected:** `Status.readyToUse: True` eventually, indicating the snapshot is complete.

### 7.3. Restore into a New PVC

Create `restore-pvc.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: restored-claim
  namespace: volume-exercise
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 4Gi    # Must be ≥ snapshot size
  storageClassName: standard    # Same class that can restore
  dataSource:
    name: dynamic-snapshot
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
```

Apply:

```bash
kubectl apply -f restore-pvc.yaml
```

Verify:

```bash
kubectl get pvc restored-claim -n volume-exercise
```

> **Expected:** The new PVC becomes `Bound`, and a new PV is provisioned/restored from the snapshot.

### 7.4. Mount the Restored PVC in a Pod

Create `restore-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: restore-consumer
  namespace: volume-exercise
spec:
  containers:
    - name: app
      image: busybox:1.35
      command:
        - sh
        - -c
        - |
          echo "Listing restored data under /data:"
          ls -l /data
          cat /data/log.txt
          sleep 3600
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: restored-claim
```

Apply:

```bash
kubectl apply -f restore-pod.yaml
kubectl logs restore-consumer -n volume-exercise
```

> **Expected:** You see the same content that was on `/data/log.txt` in the original `dynamic-consumer` Pod—confirming the restore worked.

4. **Clean Up**:

   ```bash
   kubectl delete pod restore-consumer -n volume-exercise
   kubectl delete pvc restored-claim -n volume-exercise
   kubectl delete volumesnapshot dynamic-snapshot -n volume-exercise
   ```

   If your `VolumeSnapshotClass` has `deletionPolicy: Delete`, deleting the `VolumeSnapshot` also removes the underlying snapshot. Then delete the original PVC:

   ```bash
   kubectl delete pvc dynamic-claim -n volume-exercise
   ```

---

## Exercise 8: Use `fsGroup` to Adjust File Ownership on Volumes

**Objective**
Mount an `emptyDir` or a PVC into a Pod while ensuring a non-root container can write to it via `fsGroup` and `runAsUser`.

### 8.1. Pod Manifest with `fsGroup` (using `emptyDir`)

Create `fsgroup-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: fsgroup-demo
  namespace: volume-exercise
spec:
  securityContext:
    fsGroup: 3000
  volumes:
    - name: data
      emptyDir: {}
  containers:
    - name: app
      image: ubuntu:20.04
      command:
        - sh
        - -c
        - |
          id
          ls -ld /data
          touch /data/testfile
          ls -l /data/testfile
          sleep 3600
      securityContext:
        runAsUser: 1000
        runAsGroup: 3000
      volumeMounts:
        - name: data
          mountPath: /data
```

Apply:

```bash
kubectl apply -f fsgroup-pod.yaml
```

### 8.2. Verify Ownership and Permissions

Exec into the Pod:

```bash
kubectl exec -it fsgroup-demo -n volume-exercise -- sh
```

Inside, you should see:

```shell
# Output of id:
uid=1000 gid=3000 groups=3000

# Output of ls -ld /data:
drwxrwxrwx    2 1000    3000            0 Jun  1 12:34 /data

# After touch /data/testfile:
-rw-r--r--    1 1000    3000            0 Jun  1 12:34 /data/testfile
```

> **Explanation:**
>
> * The `emptyDir` was initially owned by `root:root`. Because of `fsGroup: 3000`, Kubernetes recursively chowned `/data` to `root:3000` (GID 3000) before starting the container.
> * The container runs as `1000:3000`, so it can write to `/data`. Files created inside get `UID=1000, GID=3000`.

Exit the Pod:

```bash
exit
```

4. **Cleanup**:

   ```bash
   kubectl delete pod fsgroup-demo -n volume-exercise
   ```

### 8.3. Using `fsGroup` with a PVC

Assuming you still have `dynamic-claim` or `restored-claim` (both are PVCs bound to a PV), modify the Pod to use that PVC:

Create `fsgroup-pvc-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: fsgroup-pvc-demo
  namespace: volume-exercise
spec:
  securityContext:
    fsGroup: 4000
  containers:
    - name: app
      image: ubuntu:20.04
      command:
        - sh
        - -c
        - |
          id
          ls -ld /mnt/pvc
          touch /mnt/pvc/testfile2
          ls -l /mnt/pvc/testfile2
          sleep 3600
      securityContext:
        runAsUser: 2000
        runAsGroup: 4000
      volumeMounts:
        - name: pvc-data
          mountPath: /mnt/pvc
  volumes:
    - name: pvc-data
      persistentVolumeClaim:
        claimName: dynamic-claim    # or restored-claim
```

Apply:

```bash
kubectl apply -f fsgroup-pvc-pod.yaml
```

Exec and check:

```bash
kubectl exec -it fsgroup-pvc-demo -n volume-exercise -- sh
```

Inside:

```shell
# id output:
uid=2000 gid=4000 groups=4000

# ls -ld /mnt/pvc:
drwxrwxrwx    2 root    4000            0 Jun  1 12:34 /mnt/pvc

# touch file and ls:
-rw-r--r--    1 2000    4000            0 Jun  1 12:34 /mnt/pvc/testfile2
```

> **Expected:** Ownership is `2000:4000` for the new file; directory group is `4000` because of `fsGroup`.

Exit and clean up:

```bash
exit
kubectl delete pod fsgroup-pvc-demo -n volume-exercise
```

---

## Exercise 9: Projected Volume Merging ConfigMap, Secret, and Downward API

**Objective**
Combine multiple volume sources (ConfigMap, Secret, Downward API) into a single mount (projected volume), and verify all data appears correctly.

### 9.1. Create Another ConfigMap and Secret

```bash
kubectl create configmap multi-config \
  --namespace=volume-exercise \
  --from-literal=config.yaml="mode=prod
timeout=30"

kubectl create secret generic multi-secret \
  --namespace=volume-exercise \
  --from-literal=token=abcd1234
```

### 9.2. Create a Pod with a Projected Volume

Create `projected-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: projected-demo
  namespace: volume-exercise
  labels:
    app: projected-demo
spec:
  volumes:
    - name: multi-volume
      projected:
        sources:
          - configMap:
              name: multi-config
              items:
                - key: config.yaml
                  path: config/config.yaml
              defaultMode: 0644
          - secret:
              name: multi-secret
              items:
                - key: token
                  path: secrets/token.txt
              defaultMode: 0400
          - downwardAPI:
              items:
                - path: metadata/labels
                  fieldRef:
                    fieldPath: metadata.labels
              defaultMode: 0444
  containers:
    - name: app
      image: busybox:1.35
      command:
        - sh
        - -c
        - |
          echo "=== Contents of /etc/projected/config/config.yaml ==="
          cat /etc/projected/config/config.yaml
          echo ""
          echo "=== Contents of /etc/projected/secrets/token.txt ==="
          cat /etc/projected/secrets/token.txt
          echo ""
          echo "=== Contents of /etc/projected/metadata/labels ==="
          cat /etc/projected/metadata/labels
          echo ""
          echo "=== Listing /etc/projected with permissions ==="
          ls -R /etc/projected
          sleep 3600
      volumeMounts:
        - name: multi-volume
          mountPath: /etc/projected
          readOnly: true
```

Apply:

```bash
kubectl apply -f projected-pod.yaml
```

### 9.3. Verify Projected Contents

Exec into the Pod:

```bash
kubectl exec -it projected-demo -n volume-exercise -- sh
```

Inside, you should see:

```shell
=== Contents of /etc/projected/config/config.yaml ===
mode=prod
timeout=30

=== Contents of /etc/projected/secrets/token.txt ===
abcd1234

=== Contents of /etc/projected/metadata/labels ===
app=projected-demo

=== Listing /etc/projected with permissions ===
/etc/projected:
config  metadata  secrets

/etc/projected/config:
total 4
-rw-r--r--    1 1000    2000           11 Jun  1 12:34 config.yaml

/etc/projected/metadata:
total 4
-r--r--r--    1 1000    2000           20 Jun  1 12:34 labels

/etc/projected/secrets:
total 4
-r--r--r--    1 1000    2000            8 Jun  1 12:34 token.txt
```

> **Notes:**
>
> * The ConfigMap file is placed at `/etc/projected/config/config.yaml` with `0644`.
> * The Secret file is at `/etc/projected/secrets/token.txt` with `0400` (by default).
> * The Downward API file `metadata/labels` shows the Pod’s label (`app=projected-demo`).
> * All three sources are merged under `/etc/projected` via the projected volume.

Exit and clean up:

```bash
exit
kubectl delete pod projected-demo -n volume-exercise
```

---

## Exercise 10: Ephemeral CSI Volume in a Pod

> **Prerequisite:** Your cluster must have a CSI driver that supports ephemeral volumes (e.g., a local-hostpath CSI driver or a RAM disk CSI). The driver name below is illustrative; replace with your driver’s name if available (e.g., `csi-rwx-local.example.com`).

**Objective**
Request an ephemeral CSI volume inside a Pod for scratch space and verify it’s automatically created and destroyed with the Pod.

### 10.1. Create an Ephemeral CSI Pod Manifest

Create `csi-ephemeral-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: csi-ephemeral-demo
  namespace: volume-exercise
spec:
  containers:
    - name: app
      image: busybox:1.35
      command:
        - sh
        - -c
        - |
          echo "Writing 100MB of zeros to /scratch/data.bin"
          dd if=/dev/zero of=/scratch/data.bin bs=1M count=100
          echo "File size on /scratch:"
          ls -lh /scratch/data.bin
          sleep 3600
      volumeMounts:
        - name: scratch
          mountPath: /scratch
  volumes:
    - name: scratch
      csi:
        driver: example.csi.ramdisk       # Replace with your ephemeral-capable CSI driver
        fsType: ext4
        volumeAttributes:
          size: "1Gi"                     # Request a 1 Gi ephemeral volume
        ephemeral: true
```

Apply:

```bash
kubectl apply -f csi-ephemeral-pod.yaml
```

### 10.2. Verify Ephemeral Volume Creation

1. **Check Pod Status**:

   ```bash
   kubectl get pod csi-ephemeral-demo -n volume-exercise
   ```

   > **Expected:** Pod is `Running`. Meanwhile, the CSI driver’s logs (on the node) should show that it created a 1 Gi ramdisk or similar ephemeral backing.

2. **Exec and Confirm File Creation**:

   ```bash
   kubectl exec -it csi-ephemeral-demo -n volume-exercise -- sh -c "ls -lh /scratch/data.bin"
   ```

   > **Expected:** The file exists and is \~100 MB in size.

3. **Delete the Pod**:

   ```bash
   kubectl delete pod csi-ephemeral-demo -n volume-exercise
   ```

4. **Verify Ephemeral Volume Cleanup**:

   On the node where the Pod ran, confirm the ephemeral volume is gone (this depends on the driver—e.g., check `/var/lib/kubelet/plugins/example.csi.ramdisk/` for volume\_mounts). The backing storage should be deleted automatically.

---

## Cleanup All Resources

After completing the exercises, you can delete the namespace (which removes most resources):

```bash
kubectl delete namespace volume-exercise
```

If any PVs remain in `Released` or `Failed` state (e.g., from Exercise 4’s static `hostPath-pv` or dynamic PVs with `ReclaimPolicy: Retain`), delete them manually:

```bash
kubectl get pv
kubectl delete pv <pv-name>
```

Additionally, you may need to remove leftover directories on nodes (e.g., `/tmp/hostpath-pv-data`, `/tmp/hostpath-demo`) to fully clean up.

