---
allowed-tools: Bash(kubectl:*), Bash(top:*), Bash(free:*), Bash(sensors:*), Bash(uptime:*), Bash(df:*), Bash(ps:*)
description: Check CPU, RAM, temps, and system load across cluster nodes and local machine
---

## System Resource Monitoring

Cluster node resources: !`kubectl top nodes 2>/dev/null || echo "metrics-server unavailable"`
Top CPU pods: !`kubectl top pods -A --sort-by=cpu 2>/dev/null | head -20`
Top memory pods: !`kubectl top pods -A --sort-by=memory 2>/dev/null | head -20`
Local load average: !`uptime`
Local memory: !`free -h`
Temperatures: !`sensors 2>/dev/null || echo "lm-sensors not installed"`

Analyze the current system resource usage and identify:
1. **Cluster-level pressure**: Nodes approaching CPU or memory limits
2. **Top resource consumers**: Pods using disproportionate CPU or memory
3. **OOM risk**: Pods near their memory limits or recently OOMKilled
4. **Local machine**: High CPU processes, memory pressure on this host
5. **Temperature anomalies**: Thermal issues on local machine
6. **Load trends**: Sustained high load vs transient spikes

Provide recommendations for resource limits, pod eviction candidates, or node scaling if resources are constrained.