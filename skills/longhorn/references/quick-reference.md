# Longhorn Quick Reference

## PVC Operations

```bash
# List all PVCs (all namespaces)
kubectl get pvc -A

# List PVCs in a namespace
kubectl get pvc -n media

# Describe a PVC (shows events, bound volume name)
kubectl describe pvc <name> -n <namespace>

# Get the underlying Longhorn volume name
kubectl get pvc <name> -n <namespace> -o jsonpath='{.spec.volumeName}'

# Expand a PVC (online, no downtime needed for RWO on most filesystems)
kubectl patch pvc <name> -n <namespace> \
  -p '{"spec":{"resources":{"requests":{"storage":"20Gi"}}}}'

# Watch expansion progress
kubectl get pvc <name> -n <namespace> -w
```

## Longhorn Volume Operations

```bash
# List all Longhorn volumes
kubectl get volumes.longhorn.io -n longhorn-system

# List volumes with robustness info
kubectl get volumes.longhorn.io -n longhorn-system \
  -o custom-columns='NAME:.metadata.name,STATE:.status.state,ROBUSTNESS:.status.robustness'

# Describe a volume
kubectl describe volume.longhorn.io <name> -n longhorn-system

# List replicas for a volume
kubectl get replicas.longhorn.io -n longhorn-system | grep <volume-name>
```

## Longhorn Node / Disk

```bash
# List Longhorn storage nodes
kubectl get nodes.longhorn.io -n longhorn-system

# Describe a Longhorn node (shows disk usage)
kubectl describe node.longhorn.io <node-name> -n longhorn-system

# Check if a node is schedulable for Longhorn
kubectl get node.longhorn.io <node-name> -n longhorn-system \
  -o jsonpath='{.spec.allowScheduling}'
```

## Health Script

```bash
# Full health check (JSON output)
bash ~/claude-homelab/skills/longhorn/scripts/longhorn-health.sh

# Check specific namespace PVCs only
bash ~/claude-homelab/skills/longhorn/scripts/longhorn-health.sh -n media

# Pretty-print with jq
bash ~/claude-homelab/skills/longhorn/scripts/longhorn-health.sh | jq .
```

## Longhorn System Pods

```bash
# All Longhorn pods
kubectl get pods -n longhorn-system

# Instance managers (one per node)
kubectl get pods -n longhorn-system | grep instance-manager

# Restart a stuck instance manager (use with care)
kubectl delete pod <instance-manager-pod> -n longhorn-system
```

## Storage Classes

```bash
# List storage classes
kubectl get storageclass

# Check Longhorn is default
kubectl get storageclass | grep "(default)"
```

## Volume Attachment

```bash
# List volume attachments
kubectl get volumeattachments

# Check which node a volume is attached to
kubectl get volumeattachment | grep <pv-name>
```
