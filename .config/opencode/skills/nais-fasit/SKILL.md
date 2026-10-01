---
name: nais-fasit
description: Fasit, the Nais feature-management control plane — features, Feature.yaml, environmentKinds (management, tenant, onprem), and why a merge reaches every tenant
license: MIT
compatibility: Nais platform development
metadata:
  domain: platform
  tags: fasit features helm oci environment-kinds delivery
---

# Fasit and features

Fasit deploys OCI Helm charts, called **features**, into tenant clusters. It is the platform's feature-management and continuous-delivery control plane.

Not a configuration registry. The older NAV system of the same name is unrelated.

`nais/fasit` (public). Runs in-cluster at `fasit.nais-system:4444`.

## Feature.yaml

A Helm chart becomes a feature by carrying `Feature.yaml` beside `Chart.yaml`. Four top-level keys:

| Key | Meaning |
|---|---|
| `environmentKinds` | **Required.** `management`, `tenant`, `onprem` |
| `values` | Which Helm values Fasit manages |
| `dependencies` | Other features required |
| `timeout` | Deploy timeout, e.g. `1h`. Pattern `^(\d+h)?(\d+m)?(\d+s)?$` |

The published schema sets `additionalProperties: false`, so an editor flags an unknown key. Fasit's own decoder does not reject one. It ignores the key silently at runtime. Trust the editor, not the deploy.

`environmentKinds` explains most of the platform's shape: `management` exists once per tenant, `tenant` in every environment.

Each `values:` entry is keyed by its Helm path and carries **`config`** (operator-entered; `type` is `string`/`int`/`bool`/`string_array`, may be `secret`), **`computed`** (Fasit renders a Go template), or both.

Nested keys use dots: `image.tag` → `image: {tag: ...}`. Escape a literal dot with a backslash.

Schema for editor autocompletion: `https://storage.googleapis.com/fasit-jsonschema/feature.json`

Features live in `nais/helm-charts` (internal). List them, do not memorise:

```bash
gh api repos/nais/helm-charts/contents/features --jq '.[].name'
```

## Hostnames

Fasit's `subdomain` helper is the authority, not the docs, which are wrong here:

- `management` → `<sub>.<tenant>.cloud.nais.io`
- every other kind → `<sub>.<env>.<tenant>.cloud.nais.io`

## Terraform writes what Fasit reads

```hcl
resource "fasit_environment" "env" { tenant_id = ...  name = var.env  kind = "tenant" }
resource "fasit_environment_value" "project_id" {
  environment_id = fasit_environment.env.id
  key            = "project_id"
  value          = google_project.cluster_project.project_id
}
```

Provider `tfregistry.cloud.nais.io/nais/fasit`. A private registry, not registry.terraform.io.

Terraform records facts about infrastructure as environment values; Fasit renders them into Helm values; the chart consumes them. Three repos, one mechanism, no single repo shows it.

## A merge is a deploy

1. Signed image built.
2. Chart packaged, stamped with the image version.
3. Pushed to `oci://europe-north1-docker.pkg.dev/nais-io/nais/feature`.
4. `nais/fasit-deploy` canaries to `ci-nais` with `wait: true`.
5. Fans out to every tenant and on-prem environment.

The canary is the only gate between a merge and every tenant. Treat the pull request as the decision point.

## Traps

- Fasit accepts an unknown key in `Feature.yaml` at deploy time and ignores it silently. Only the editor catches it.
- Wrong `environmentKinds` deploys a management-only feature everywhere.
- The provider resolves only from `tfregistry.cloud.nais.io`.
- A `computed` value's input usually comes from Terraform, not the chart.
