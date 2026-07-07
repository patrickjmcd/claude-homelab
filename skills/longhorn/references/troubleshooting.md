# Longhorn Troubleshooting

## PVC Stuck in Pending

**Symptoms:** `kubectl get pvc -A` shows a PVC with `STATUS=Pending`

**Causes and fixes:**

1. **No matching storage class**
   ```bash
   kubectl describe pvc <name> -n <ns>
   # Look for: "no storage class found" or "provisioner not found"
   kubectl get storageclass  # verify "longhorn" exists
   ```

2. **Longhorn has no schedulable nodes**
   ```bash
   kubectl get nodes.longhorn.io -n longhorn-system
   # AllowScheduling must be true on at least one node
   ```

3. **Insufficient disk space on Longhorn nodes**
   ```bash
   kubectl describe node.longhorn.io <node> -n longhorn-system
   # Check StorageAvailable vs StorageScheduled
   ```

4. **Longhorn manager pod unhealthy**
   ```bash
   kubectl get pods -n longhorn-system | grep longhorn-manager
   kubectl logs -n longhorn-system -l app=longhorn-manager --tail=50
   ```

---

## Volume Stuck as Degraded

**Symptoms:** `robustness=Degraded` in `kubectl get volumes.longhorn.io -n longhorn-system`

**Causes and fixes:**

1. **A replica node is offline**
   ```bash
   kubectl get nodes  # check all k8s nodes are Ready
   kubectl get nodes.longhorn.io -n longhorn-system  # check Longhorn node status
   ```
   If the node came back, Longhorn will rebuild automatically. Watch:
   ```bash
   kubectl get replicas.longhorn.io -n longhorn-system | grep <volume>
   ```

2. **Replica rebuild failed**
   ```bash
   kubectl describe replicas.longhorn.io -n longhorn-system | grep -A10 <volume>
   # Look for error messages
   ```
   Force rebuild by deleting the failed replica (Longhorn recreates it):
   ```bash
   kubectl delete replica.longhorn.io <replica-name> -n longhorn-system
   ```

---

## Volume Faulted

**Symptoms:** `robustness=Faulted` — no healthy replicas remain.

⚠️ This is a data-loss risk. Do not detach or delete without understanding the cause.

1. **Check what happened**
   ```bash
   kubectl describe volume.longhorn.io <name> -n longhorn-system
   kubectl get events -n longhorn-system | grep <volume>
   ```

2. **If data is still in a replica**
   - Go to Longhorn UI → Volumes → select the volume
   - Try "Salvage" to recover from the last good replica

3. **If all replicas are gone**
   - Data is lost. Delete the PVC and restore from backup.

---

## PVC Expansion Not Completing

**Symptoms:** PVC shows new capacity in `spec` but `status.capacity` hasn't updated.

1. **Check conditions**
   ```bash
   kubectl describe pvc <name> -n <ns> | grep -A10 Conditions
   # Look for FileSystemResizePending
   ```

2. **Pod must be running for filesystem resize**
   Longhorn expands the block device online, but the filesystem resize requires the pod to be running.
   If the pod is not running, start it; the resize completes on next mount.

3. **Force resize by restarting the pod**
   ```bash
   kubectl rollout restart deployment/<name> -n <ns>
   ```

---

## Instance Manager Pod CrashLooping

**Symptoms:** `kubectl get pods -n longhorn-system` shows instance-manager pods restarting.

1. **Check logs**
   ```bash
   kubectl logs -n longhorn-system <instance-manager-pod> --previous
   ```

2. **Check node disk health**
   If the underlying node has disk errors, the instance manager will fail.
   Check node with: `dmesg | grep -i error` on the affected node.

3. **Restart the instance manager**
   Longhorn will recreate it:
   ```bash
   kubectl delete pod <instance-manager-pod> -n longhorn-system
   ```

---

## SMB PVC Not Mounting

SMB-backed PVCs use the CSI SMB driver in `csi-smb-provisioner` namespace, not Longhorn.

```bash
# Check CSI SMB driver pods
kubectl get pods -n csi-smb-provisioner

# Check events on the PVC
kubectl describe pvc <name> -n <ns>

# Credentials are in csi-smb-provisioner namespace from 1Password
kubectl get secret -n csi-smb-provisioner
```

---

## General Diagnostic Flow

```
PVC not working?
├── kubectl describe pvc <name> -n <ns>
│   ├── Status=Pending → provisioner issue (see "PVC Stuck in Pending" above)
│   ├── Status=Bound → look at the pod using it
│   └── Status=Lost → PV was deleted; recreate PVC from backup
│
├── Pod not starting due to volume?
│   └── kubectl describe pod <name> -n <ns>
│       └── Look for "volume mount failed" or "timed out waiting for volume"
│           → Check volumeattachment, check Longhorn volume state
│
└── Longhorn volume degraded?
    └── kubectl get volumes.longhorn.io -n longhorn-system
        └── Check robustness and replica count
            → See "Volume Stuck as Degraded" above
```
