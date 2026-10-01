---
name: nais-terraform
description: The OpenTofu and Atlantis setup behind Nais infrastructure — per-tenant roots, shared modules, and what a change touches
license: MIT
compatibility: Nais platform development
metadata:
  domain: infrastructure
  tags: opentofu terraform atlantis gcp tenants modules state
---

# Nais infrastructure as code

**OpenTofu, not Terraform.** The binary is `tofu`. Plans and applies run through **Atlantis** from pull requests, never from a laptop.

Two internal repos: `nais/nais-terraform-modules` (per tenant) and `nais/nais-io-terraform-modules` (the `nais.io` infrastructure). A 404 means missing org access, not a missing repo.

## Layout

```
tenants/<tenant>/   one standalone root per tenant
modules/            shared modules the roots compose
atlantis.yaml       the projects Atlantis knows
```

Modules: `tenant`, `management`, `onprem`, `aiven`, `cnpg`, `loadbalancer`, `naisdevice-controlplane`, `naisdevice-gateway`, `github_tenant_auth`.

Each root has its own state and service account:

```hcl
backend "gcs" {
  bucket                      = "nais-tf-state-dev-nais"
  impersonate_service_account = "nais-tf-dev-nais@nais-io.iam.gserviceaccount.com"
}
```

Pattern: `nais-tf-state-<tenant>`, `nais-tf-<tenant>@nais-io.iam.gserviceaccount.com`.

Module sources are relative local paths: `source = "../../modules/tenant"`. Nothing is published to registry.terraform.io.

## Blast radius

Answer this before proposing an edit.

- `tenants/<tenant>/`: that tenant.
- `modules/`: **every root that composes it**, usually all of them. Check the callers.

Read the plan Atlantis posts. It is the only thing that reports the real radius rather than the predicted one.

## Finding things

```bash
gh api repos/nais/nais-terraform-modules/contents/tenants --jq '.[].name'
gh api repos/nais/nais-terraform-modules/contents/modules --jq '.[].name'
```

GitHub rate limits code search to roughly ten requests per minute and caps results. Beyond a spot check, clone and grep.

## Traps

- Saying "terraform" when the tool is `tofu`.
- Proposing a local apply. Applies go through Atlantis on a PR.
- Editing a shared module for one tenant's need is a fleet-wide change. Use the tenant root or a variable.
- Looking for module versions. Sources are local paths; `main` is what every tenant gets.
