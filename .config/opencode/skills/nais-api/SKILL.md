---
name: nais-api
description: The Nais API — GraphQL control plane behind Nais Console, how to reach it, and how to develop against it locally
license: MIT
compatibility: Nais platform development
metadata:
  domain: platform
  tags: graphql gqlgen sqlc api console codegen mcp
---

# The Nais API

`nais/api` (public, Go): the programmatic entrypoint to a tenant's platform state, and the backend behind Nais Console.

## Reaching it

```
POST https://console.<tenant>.cloud.nais.io/graphql
Authorization: Bearer <token>
```

Discover the host rather than assembling it:

```bash
curl -s "https://storage.googleapis.com/nais-tenant-data/nav.no.json" | jq -r .consoleUrl
```

The API's ingress claims `/graphql`, `/oauth2/`, `/teams/` and `/api/v1/`. The host serves more. `/` is the Console SPA, not a playground. There is a small REST surface for applying whitelisted manifests, and a cluster-internal gRPC service on 3001 that the ingress never exposes.

## Develop locally

**`nais/api` runs with no tenant credentials**: docker compose, seeded Postgres, fake Kubernetes clients reading `data/k8s`. Use it. Do not reach for a real tenant to test a change.

The Nais MCP server can point at that local instance, giving an agent the API surface without touching anything real. The agent package cannot declare an MCP server, so wire it per the server's own instructions.

## Codegen is mandatory

gqlgen for GraphQL, sqlc + pgx for the database. A half-finished run compiles and is wrong. Stray models in `internal/graph/model/donotuse/` are the sign.

After changing a `.graphqls` file or a query: regenerate, commit the output. `mise run generate`. The `Makefile` is a shim over it: every target is a `mise run` call. Either works, and `mise` is the real entry point as in the other repos.

Integration tests are **Lua**, run through `nais/tester`, driven from a Go harness (`integration_tests/zz_run_test.go`, build tag `integration_test`). Look there before concluding something is untested.

## Gates

Any `.graphqls` change requires review from `@nais/tooling`; a GitHub App enforces it. `main` needs no other approving review but gates four status checks.

## The liberator pin

`nais/liberator` publishes **no tags**. Consumers pin `v0.0.0-<date>-<sha>` and Dependabot cannot advance them.

`nais/api`'s pin is months behind and bumping it is a known compile break: `BigQueryDatasetSpec.Project` was removed on the belief only Naiserator used it, which was false. Bump it as its own change, expecting to fix call sites.

## Traps

- Assembling the console URL by hand.
- Editing generated code. `donotuse/` means something went wrong.
- Assuming the Lua files are the whole story; a Go harness runs them.
- Folding a liberator bump into another change.
