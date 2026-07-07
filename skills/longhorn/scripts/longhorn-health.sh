#!/bin/bash
# longhorn-health.sh — Longhorn storage health check, outputs JSON
set -euo pipefail

NAMESPACE_FILTER=""

usage() {
    cat <<EOF
Usage: $0 [options]

Options:
    -n <namespace>  Filter PVC check to a specific namespace (default: all)
    --help          Show this help

Output: JSON with pvc_summary, volume_health, and node_health sections
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n) NAMESPACE_FILTER="$2"; shift 2 ;;
        --help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
    esac
done

if ! command -v kubectl &>/dev/null; then
    echo '{"error": "kubectl not found in PATH"}' >&2
    exit 1
fi

# PVC summary
if [[ -n "$NAMESPACE_FILTER" ]]; then
    pvc_json=$(kubectl get pvc -n "$NAMESPACE_FILTER" -o json 2>/dev/null)
else
    pvc_json=$(kubectl get pvc -A -o json 2>/dev/null)
fi

pvc_summary=$(echo "$pvc_json" | python3 -c "
import sys, json
data = json.load(sys.stdin)
items = data.get('items', [])
summary = {'total': len(items), 'bound': 0, 'pending': 0, 'lost': 0, 'other': 0, 'details': []}
for item in items:
    phase = item.get('status', {}).get('phase', 'Unknown')
    if phase == 'Bound': summary['bound'] += 1
    elif phase == 'Pending': summary['pending'] += 1
    elif phase == 'Lost': summary['lost'] += 1
    else: summary['other'] += 1
    if phase != 'Bound':
        summary['details'].append({
            'namespace': item['metadata'].get('namespace', ''),
            'name': item['metadata']['name'],
            'phase': phase,
            'storage_class': item['spec'].get('storageClassName', ''),
            'capacity': item.get('status', {}).get('capacity', {}).get('storage', 'unknown')
        })
print(json.dumps(summary))
" 2>/dev/null || echo '{"error": "failed to parse PVC data"}')

# Longhorn volume health
volume_json=$(kubectl get volumes.longhorn.io -n longhorn-system -o json 2>/dev/null || echo '{"items":[]}')
volume_summary=$(echo "$volume_json" | python3 -c "
import sys, json
data = json.load(sys.stdin)
items = data.get('items', [])
summary = {'total': len(items), 'healthy': 0, 'degraded': 0, 'faulted': 0, 'unknown': 0, 'degraded_list': []}
for item in items:
    robustness = item.get('status', {}).get('robustness', 'Unknown')
    if robustness == 'Healthy': summary['healthy'] += 1
    elif robustness == 'Degraded':
        summary['degraded'] += 1
        summary['degraded_list'].append({'name': item['metadata']['name'], 'state': item.get('status',{}).get('state',''), 'robustness': robustness})
    elif robustness == 'Faulted':
        summary['faulted'] += 1
        summary['degraded_list'].append({'name': item['metadata']['name'], 'state': item.get('status',{}).get('state',''), 'robustness': robustness})
    else:
        summary['unknown'] += 1
print(json.dumps(summary))
" 2>/dev/null || echo '{"error": "failed to parse Longhorn volume data (CRDs may not be available)"}')

# Longhorn node health
node_json=$(kubectl get nodes.longhorn.io -n longhorn-system -o json 2>/dev/null || echo '{"items":[]}')
node_summary=$(echo "$node_json" | python3 -c "
import sys, json
data = json.load(sys.stdin)
items = data.get('items', [])
nodes = []
for item in items:
    conditions = item.get('status', {}).get('conditions', [])
    ready = any(c.get('type') == 'Ready' and c.get('status') == 'True' for c in conditions)
    schedulable = item.get('spec', {}).get('allowScheduling', False)
    nodes.append({'name': item['metadata']['name'], 'ready': ready, 'schedulable': schedulable})
print(json.dumps({'total': len(nodes), 'nodes': nodes}))
" 2>/dev/null || echo '{"error": "failed to parse Longhorn node data"}')

timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

cat <<EOF
{
  "timestamp": "$timestamp",
  "pvc_summary": $pvc_summary,
  "volume_health": $volume_summary,
  "node_health": $node_summary
}
EOF
