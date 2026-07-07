---
allowed-tools: Bash(kubectl:*)
description: Check Longhorn storage health, PVC status, and volume replicas
---

## Longhorn Storage Health Check

PVC status (all namespaces): !`kubectl get pvc -A -o wide 2>/dev/null`
Longhorn volumes: !`kubectl get volumes.longhorn.io -n longhorn-system -o custom-columns='NAME:.metadata.name,STATE:.status.state,ROBUSTNESS:.status.robustness,SIZE:.spec.size' 2>/dev/null`
Longhorn nodes: !`kubectl get nodes.longhorn.io -n longhorn-system -o custom-columns='NAME:.metadata.name,READY:.status.conditions[-1].status,SCHEDULABLE:.spec.allowScheduling,DISK_USAGE:.status.diskStatus' 2>/dev/null`
Degraded volumes: !`kubectl get volumes.longhorn.io -n longhorn-system -o json 2>/dev/null | kubectl neat 2>/dev/null || kubectl get volumes.longhorn.io -n longhorn-system --no-headers 2>/dev/null | grep -v " attached " | grep -v " detached "`

Analyze Longhorn storage health and identify issues:

1. **PVC Health**:
   - Flag PVCs in Pending or Lost state
   - Check for unbound PVCs
   - Verify all PVCs have a corresponding Longhorn volume

2. **Volume Robustness**:
   - Flag volumes with robustness = Degraded or Faulted
   - Check replica counts match expected
   - Identify volumes with rebuilding replicas

3. **Node Storage Health**:
   - Check each Longhorn node is schedulable
   - Flag nodes with disk pressure
   - Identify nodes with failed disks

4. **Replica Distribution**:
   - Ensure replicas are spread across multiple nodes
   - Flag volumes with fewer replicas than requested

5. **Recommendations**:
   - Volumes requiring immediate attention
   - Nodes that may need disk expansion
   - Suggested eviction or rebalancing actions

Provide a summary of storage health and any volumes or nodes needing attention.
