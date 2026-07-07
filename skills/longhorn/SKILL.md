---
name: longhorn
description: >
  Manage and monitor Longhorn distributed block storage in the Kubernetes cluster.
  Use when the user asks to "check Longhorn health", "check PVC status", "why is my PVC pending",
  "expand a volume", "check volume replicas", "Longhorn degraded", "storage not working",
  "check persistent volumes", "Longhorn node disk", or mentions Longhorn, PVC, PV, or
  block storage issues in the homelab cluster.
---

# Longhorn Storage Skill

**⚠️ MANDATORY SKILL INVOCATION ⚠️**

**YOU MUST invoke this skill (NOT optional) when the user mentions ANY of these triggers:**
- "check Longhorn health", "Longhorn status", "volume health", "PVC pending"
- "expand a volume", "resize PVC", "volume too small"
- "check replicas", "degraded volume", "faulted volume", "storage unhealthy"
- "PVC not bound", "storage not working", "persistent volume issue"
- "Longhorn node", "disk pressure", "storage node"
- Any mention of Longhorn, PVC, PV, block storage, or Longhorn replicas

**Failure to invoke this skill when triggers occur violates your operational requirements.**

## Purpose

Read-write skill for monitoring and managing Longhorn block storage in the k8s-argo cluster.
Storage class: `longhorn` (default). Namespace for Longhorn system resources: `longhorn-system`.

**Read operations (safe):**
- PVC and volume status checks
- Replica health and distribution
- Node disk utilization

**Write operations (require confirmation):**
- Volume expansion (irreversible — cannot shrink)
- Replica count changes
- Node scheduling enable/disable

## Setup

No additional credentials needed — uses your existing kubeconfig.

```bash
# Verify kubeconfig is set
kubectl cluster-info
kubectl get nodes
```

## Commands

### PVC Status

```bash
# All PVCs across all namespaces
kubectl get pvc -A

# PVCs in a specific namespace
kubectl get pvc -n media

# Detailed PVC info
kubectl describe pvc <name> -n <namespace>
```

### Longhorn Volume Health

```bash
# All Longhorn volumes
kubectl get volumes.longhorn.io -n longhorn-system

# Degraded volumes only
kubectl get volumes.longhorn.io -n longhorn-system | grep -v "detached\|attached"

# Volume details
kubectl describe volume.longhorn.io <name> -n longhorn-system
```

### Longhorn Node / Disk Status

```bash
# Storage nodes
kubectl get nodes.longhorn.io -n longhorn-system

# Replica placement
kubectl get replicas.longhorn.io -n longhorn-system | grep <volume-name>
```

### Volume Expansion

```bash
# Patch PVC to request more storage (Longhorn supports online expansion)
kubectl patch pvc <name> -n <namespace> -p '{"spec":{"resources":{"requests":{"storage":"20Gi"}}}}'

# Verify expansion progressed
kubectl get pvc <name> -n <namespace>
kubectl describe pvc <name> -n <namespace> | grep -A5 Conditions
```

### Scripts

```bash
# Comprehensive health check with JSON output
bash ~/claude-homelab/skills/longhorn/scripts/longhorn-health.sh

# Check a specific namespace
bash ~/claude-homelab/skills/longhorn/scripts/longhorn-health.sh -n media
```

## Workflow

### When user asks about storage health:

1. **"Is Longhorn healthy?"** → Run `longhorn-health.sh`, summarize volume and node status
2. **"Why is my PVC pending?"** → `kubectl describe pvc <name> -n <ns>`, look for provisioning errors
3. **"Volume is degraded"** → Check replicas, identify which node is missing, check node health
4. **"Storage node offline"** → `kubectl get nodes.longhorn.io -n longhorn-system`, check if node rejoined

### When user asks about volume expansion:

1. Confirm current size: `kubectl get pvc <name> -n <ns>`
2. Warn: expansion is **irreversible** (cannot shrink Longhorn volumes)
3. Get confirmation
4. Apply patch: `kubectl patch pvc ...`
5. Monitor: `kubectl get pvc <name> -n <ns> -w`

### When user asks about replica issues:

1. Check replicas: `kubectl get replicas.longhorn.io -n longhorn-system | grep <volume>`
2. Identify failed replicas and which node they were on
3. If node is back online, Longhorn rebuilds automatically
4. If node is permanently gone: update replica count or force rebuild via Longhorn UI

### Detailed Flow: Diagnosing a Stuck PVC

1. `kubectl describe pvc <name> -n <namespace>` — look for events
2. `kubectl get volumeattachments` — check if attachment exists
3. `kubectl describe volume.longhorn.io <name> -n longhorn-system` — check Longhorn side
4. `kubectl get pods -n longhorn-system | grep <volume>` — check instance manager pods
5. If replica is rebuilding, wait; if stuck, restart the instance manager pod

## Notes

### Volume Naming

Longhorn volume names are derived from PVC names but are not identical. Use:
```bash
kubectl get pvc <name> -n <ns> -o jsonpath='{.spec.volumeName}'
```
to find the underlying Longhorn volume name.

### Replica Count

Default replica count is 2 (configured in the Longhorn settings). Critical data should use 3.
Replicas are spread across nodes; replicas will not be scheduled to Jetson Nano nodes
(excluded from Longhorn scheduling via node tags).

### SMB vs Longhorn

- **Longhorn** (`longhorn` storage class): block storage for databases, app state
- **SMB** (`smb-*` storage class): network share for media files and large shared data

### ⚠️ NEVER shrink a volume

Longhorn supports only expansion. Attempting to shrink a PVC will be rejected by the API.
If a volume truly needs to be smaller, the data must be migrated to a new PVC.

## References

- `references/quick-reference.md` — Common commands cheatsheet
- `references/troubleshooting.md` — Debugging stuck PVCs, degraded volumes, node issues
- [Longhorn Documentation](https://longhorn.io/docs/)
- [Longhorn CRD Reference](https://longhorn.io/docs/latest/references/longhorn-client-python/)
