---
allowed-tools: Bash(kubectl:*)
description: Check ArgoCD application sync and health status across all apps
---

## ArgoCD Application Sync Status

All applications: !`kubectl get applications -n argocd -o custom-columns='NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status,REVISION:.status.sync.revision' 2>/dev/null`
OutOfSync apps: !`kubectl get applications -n argocd -o json 2>/dev/null | python3 -c "import sys,json; apps=json.load(sys.stdin)['items']; [print(a['metadata']['name'], a['status']['sync']['status'], a.get('status',{}).get('health',{}).get('status','')) for a in apps if a.get('status',{}).get('sync',{}).get('status') != 'Synced']" 2>/dev/null || echo "All apps synced or unable to check"`
Recent events: !`kubectl get events -n argocd --sort-by='.lastTimestamp' | tail -20 2>/dev/null`

Analyze the ArgoCD sync status and provide actionable guidance:

1. **Sync Status**:
   - List any apps that are OutOfSync and why
   - Identify apps stuck in Progressing state
   - Note any apps with sync errors or hook failures

2. **Health Status**:
   - Flag Degraded or Missing apps
   - Identify apps with unhealthy child resources (pods, deployments)

3. **Recent Activity**:
   - Summarize recent sync events
   - Flag any repeated sync failures

4. **Recommended Actions**:
   - Apps that need `kubectl rollout restart` or manual sync
   - Apps where image tags may need updating (never use `latest`)
   - Config drift that should be committed to git

5. **GitOps Reminders**:
   - All fixes should go through git → ArgoCD, not `kubectl apply` directly
   - If an app is OutOfSync due to manual changes, commit those changes or revert

Provide a prioritized list of apps requiring attention and the correct GitOps remediation steps.
