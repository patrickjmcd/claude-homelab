---
allowed-tools: Bash(kubectl:*)
description: Check health of all Kubernetes pods and nodes across the cluster
---

## Kubernetes Cluster Health Check

Node status: !`kubectl get nodes -o wide`
Pod overview: !`kubectl get pods -A --sort-by='.status.phase' | grep -v Running | grep -v Completed | head -40`
All pods: !`kubectl get pods -A -o wide | tail -60`
Resource usage: !`kubectl top nodes 2>/dev/null || echo "metrics-server unavailable"`
ArgoCD app health: !`kubectl get applications -n argocd -o custom-columns='NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status' 2>/dev/null | head -30`

Analyze the cluster health and identify any issues:

1. **Node Health**:
   - Check for NotReady or SchedulingDisabled nodes
   - Review resource pressure (CPU, memory, disk)
   - Identify nodes that are cordoned or tainted unexpectedly

2. **Pod Health**:
   - Flag pods in CrashLoopBackOff, Error, Pending, or OOMKilled states
   - Identify pods with high restart counts
   - Check for pods stuck in Terminating state

3. **ArgoCD Sync Status**:
   - Flag any apps that are OutOfSync or Degraded
   - Note apps in Progressing state for too long

4. **Resource Pressure**:
   - Identify nodes approaching CPU or memory limits
   - Flag namespaces with no resource quotas if relevant

5. **Recommendations**:
   - Pods that need restart or investigation
   - Apps that need manual sync or rollback
   - Nodes requiring maintenance

Provide a prioritized summary of issues and immediate actions required.
