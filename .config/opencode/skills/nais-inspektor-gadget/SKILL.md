---
name: nais-inspektor-gadget
description: Debug TCP loss, retransmissions, drops and reordering in dev-fss or prod-fss with Inspektor Gadget
license: MIT
compatibility: Nais on-prem clusters, kubectl access and kubectl-gadget
metadata:
  domain: observability
  tags: inspektor-gadget ebpf tcp network dev-fss prod-fss onprem
---

# Inspektor Gadget on-prem

Use Gadget to identify affected nodes, workloads, processes and socket-tuples. It does not prove where a packet disappeared in the VM, hypervisor or physical network, and it does not read payloads.

The full operator guide is [`nais/vakt/inspektor-gadget.md`](https://github.com/nais/vakt/blob/master/inspektor-gadget.md). Read it before changing the workflow or gadget digests.

## Capture

1. Confirm the context. Never infer `dev-fss` or `prod-fss` from the request.
2. Verify that the DaemonSet is dormant and no stale pilot labels remain.
3. Select one worker that tests a concrete hypothesis. Avoid control-plane nodes.
4. Label it, wait for the agent, then run a bounded `trace_tcpretrans`.
5. Preserve JSONL, remove the label and verify that the agent pod disappears.

```bash
set -euo pipefail

CLUSTER="dev-fss" # or prod-fss
NODE="<worker-node>"
test "$(kubectl config current-context)" = "$CLUSTER"

kubectl -n nais-system get daemonset,pods \
  -l app.kubernetes.io/name=gadget -o wide
kubectl get nodes -l nais.io/inspektor-gadget-pilot=true -o name

kubectl label node "$NODE" nais.io/inspektor-gadget-pilot=true --overwrite
cleanup() {
  kubectl label node "$NODE" nais.io/inspektor-gadget-pilot-
}
trap cleanup EXIT

kubectl -n nais-system wait \
  --for=condition=Ready pod \
  -l app.kubernetes.io/name=gadget \
  --timeout=120s

RUN_ID="${CLUSTER}-$(date -u +%Y%m%dT%H%M%SZ)"
kubectl gadget run \
  ghcr.io/inspektor-gadget/gadget/trace_tcpretrans@sha256:c6cbfd2aeb2af860b6186b6b02ce44ccaced7bf87006e777fe897777b19967af \
  --gadget-namespace nais-system \
  --node "$NODE" \
  --all-namespaces \
  --timeout 120 \
  --name "$RUN_ID-tcpretrans" \
  --output json |
  tee "$RUN_ID-tcpretrans.jsonl"

cleanup
trap - EXIT
kubectl get nodes -l nais.io/inspektor-gadget-pilot=true -o name
kubectl -n nais-system get pods \
  -l app.kubernetes.io/name=gadget -o wide
```

Stop if the agent restarts, is `OOMKilled`, or is not Ready within two minutes. In `prod-fss`, start with one node and 120 seconds. Never remove NetworkPolicy or PolicyException, clear `/sys/fs/bpf`, or use fault injection on shared workers.

## Choose the next gadget

| Signal needed | Gadget |
|---|---|
| Failed `connect`, `accept` or `close` | `trace_tcp` |
| TCP retransmission or loss events | `trace_tcpretrans` |
| Packets dropped by the local kernel | `trace_tcpdrop` |
| Bytes per TCP connection | `top_tcp` |

Use the pinned digests in the vakt guide or `nais/helm-charts/features/inspektor-gadget/values.yaml`.

Interpret the result:

- Mostly SYN retransmissions: reachability, listener, policy or route during connection setup.
- ACK, PSH or FIN retransmissions: established connections are affected.
- `SKB_DROP_REASON_QUEUE_PURGE` during socket teardown: usually kernel cleanup.
- `SKB_DROP_REASON_TCP_OFO_DROP`: the kernel discarded an out-of-order segment.
- Many retransmissions without local drops: investigate VMXNET3, vSwitch, uplink, VXLAN, the physical network or the remote endpoint.
- One node materially worse under comparable traffic: compare its ESXi host, vNIC, uplink, subnet and route with a control node.

Record the UTC window, cluster, nodes, commands, digests, raw JSONL and summaries. JSONL contains workload names, IP addresses and ports; share it only in approved channels.
