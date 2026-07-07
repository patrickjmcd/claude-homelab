---
allowed-tools: Bash(kubectl:*), Bash(df:*), Bash(du:*), Bash(lsblk:*), Bash(findmnt:*)
description: Analyze disk space usage across cluster PVCs, Longhorn volumes, and local mounts
---

## Comprehensive Disk Usage Analysis

PVC status (all namespaces): !`kubectl get pvc -A -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,STATUS:.status.phase,CAPACITY:.status.capacity.storage,STORAGECLASS:.spec.storageClassName' 2>/dev/null`
Longhorn volume summary: !`kubectl get volumes.longhorn.io -n longhorn-system -o custom-columns='NAME:.metadata.name,STATE:.status.state,SIZE:.spec.size,ROBUSTNESS:.status.robustness' 2>/dev/null`
Local mount usage: !`df -h`
Large local directories: !`du -h --max-depth=1 /mnt/* 2>/dev/null | sort -h | tail -20`

Perform a comprehensive disk space analysis:

1. **PVC Health**:
   - Flag PVCs in Pending or Lost state
   - Identify PVCs approaching capacity (where metrics are available)
   - Check for unbound PVCs wasting allocation

2. **Longhorn Volume State**:
   - Flag Degraded or Faulted volumes
   - Identify volumes with fewer replicas than expected
   - Check overall Longhorn disk utilization per node

3. **SMB / Network Storage**:
   - Check SMB-backed PVCs are bound and accessible
   - Note any PVCs referencing unavailable SMB shares

4. **Local Mount Analysis**:
   - Identify filesystems above 80% usage
   - Check for critically full filesystems (>95%)
   - Note any read-only mounts that shouldn't be

5. **Cleanup Targets**:
   - Orphaned PVCs (Released phase, no matching PV)
   - Old log volumes or ephemeral storage consuming space
   - Completed job artifacts that can be pruned

6. **Recommendations**:
   - PVCs that need expansion (via Longhorn UI or kubectl patch)
   - Immediate actions for critical space issues
   - Long-term storage optimization suggestions

Provide a prioritized list of actions to address storage issues safely.
All PVC resizing goes through Longhorn — never shrink a volume.