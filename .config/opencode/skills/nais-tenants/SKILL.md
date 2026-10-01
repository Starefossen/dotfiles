---
name: nais-tenants
description: Nais tenancy — tenants, environments, clusters, how to discover the live list, and how to select one
license: MIT
compatibility: Nais platform development
metadata:
  domain: platform
  tags: tenants clusters environments multi-tenancy naisdevice kubectl gcp
---

# Tenants and environment clusters

A **tenant** is one customer organisation: its own GCP folder tree, its own `<tenant>.cloud.nais.io`, one management cluster, one GKE cluster per environment.

**Environment and cluster are the same thing.** Every environment is a separate cluster; every team is a namespace in it. That is why features declare `environmentKinds`, and why Loki and Mimir exist once per tenant while Tempo exists per environment.

## Discovering tenants

Never hardcode the list. Two sources, neither complete.

Public registry, no auth. `nais/cli` uses it:

```bash
curl -s "https://storage.googleapis.com/storage/v1/b/nais-tenant-data/o?fields=items(name)" | jq -r '.items[].name'
curl -s "https://storage.googleapis.com/nais-tenant-data/nav.no.json" | jq .
```

Keyed by email domain, returns the console URL.

Terraform, in `nais/nais-terraform-modules` (internal):

```bash
gh api repos/nais/nais-terraform-modules/contents/tenants --jq '.[].name'
```

`atlantis-serviceaccounts/serviceaccounts.tf` provisions service accounts and state buckets for **more** tenants than have a `tenants/<name>/` root. Cross-check both before concluding a tenant does or does not exist.

Disagreement means they answer different questions: the bucket says who can log in, Terraform says what is provisioned.

## Which tenant

`dev-nais` for platform work. `ci-nais` takes the first canary of every feature deploy. `test-nais` for testing.

`nav`, `atil`, `ldir`, `ssb` and the rest are real customers. Read from them to investigate something specific; never to try something out.

**The `nais` GitHub org deploys into the `nav` tenant.** `nais` is not a tenant.

## One tenant at a time

naisdevice connects to exactly one tenant. There is no second connection alongside it, so nothing can query two tenants in the same session: no comparison of `dev-nais` against `nav`, no loop over the tenant list, no fan-out. A plan that needs two tenants needs two sessions with a human switching in between.

Which one is connected. Two sources, and the file comes first:

```bash
jq -r '.tenant, .connectionState' "$HOME/Library/Application Support/naisdevice/agent-status.json"
nais device status --output json | jq -r '.Tenants[]? | select(.active) | .name'
```

The agent writes `agent-status.json` next to `agent-config.json` ([nais/device#564](https://github.com/nais/device/pull/564)); on Linux that is `$XDG_CONFIG_HOME/naisdevice` or `~/.config/naisdevice`. It carries `connectionState`, `tenant`, `updatedAt` and `heartbeatSeconds`, and **no secrets**. The CLI's document does: `Tenants[].session.key` is the connected tenant's bearer token, so never print that one whole.

The file is also the only one of the two that answers inside cplt. The sandbox denies unix-socket connects, so `nais device status` there exits 1 with `unable to connect to naisdevice; make sure naisdevice is running`, which is exactly what it prints when naisdevice is stopped. One read grant makes the file readable:

```bash
cplt config set allow.read "$HOME/Library/Application Support/naisdevice/agent-status.json"
```

Name the file, never the directory: the directory also holds the device's private key. [navikt/copilot#885](https://github.com/navikt/copilot/issues/885) tracks letting an agentpakke propose that grant, so that the line does not have to be pasted by hand.

Check the file before believing it. The agent removes it on a clean shutdown and leaves it behind on a kill, so presence means the agent got that far, never that it is running now. An `updatedAt` older than a few times `heartbeatSeconds` means the agent is gone or stuck, and `connectionState` then says what was true when it went. Missing or stale: ask the CLI. It is best effort by its own `warning` field — the format can change and the file can be removed.

`AgentStatus.Tenants[]` from the CLI holds one entry per tenant with `name` and `active`, and exactly one carries `active: true`. #564 is merged but not yet in a naisdevice release, so until it is the CLI is the only source there is, and the cluster gate reads it the same way: file first, CLI second, and neither means it says so instead of guessing.

**The name is not the short tenant name.** A stock agent is compiled with one tenant, `NAV`. With the hidden `ILoveNinetiesBoybands` setting on, whose own help text reads "Enable tenant switching":

```bash
nais device config set ILoveNinetiesBoybands true
```

the agent appends the object names from the `naisdevice-enroll-discovery` bucket, which are **domains**: `nav.no`, `dev-nais.io`, `ssb.no`, `arbeidstilsynet.no`, `ci-nais.io`, `test-nais.no`, `miljodir.no`, `landbruksdirektoratet.no`, plus `default` and `nais.io`.

So both commands above answer `NAV`, or something like `dev-nais.io`. Map it before you use it anywhere: drop the `.no` or `.io`, lowercase it, and apply the short names `arbeidstilsynet` → `atil` and `landbruksdirektoratet` → `ldir`. Hosts, cluster names and kubectl contexts all use the short form; comparing a domain against one of those is a silent mismatch, not an error.

**There is no command to switch.** `nais device` has `status`, `connect`, `disconnect`, `gateway`, `doctor` and `config`, and nothing else. The agent does expose a `SetActiveTenant` RPC, but no CLI command calls it; switching is a person choosing the tenant in the naisdevice menu.

So when the tenant you were asked about is not the connected one, stop there and say so:

> naisdevice is connected to `dev-nais`, so I cannot reach `nav` from here. Switching is the naisdevice menu and I have no command for it. Switch and say when to carry on.

Do not answer for the connected tenant instead. That is a real answer to a question nobody asked, and it reads like the right one.

## Selecting a cluster

Interactive by design:

1. Switch tenant in the naisdevice GUI.
2. `gcloud config set account <you>@nais.io`
3. `gcloud auth login --update-adc`
4. `narc kubeconfig`
5. `narc jita grant <entitlement> <tenant> --duration 1h --reason "<why>"`
6. `kubectx`

`--reason` is mandatory, logged, and **read by the tenant**. Write a real one.

**Never propose automating this.** Just-in-time elevation is a control; pre-granting it defeats the control rather than saving time.
