---
name: nais-change-workflow
description: Changing Nais platform code — a CRD field in liberator, a naiserator resource, an Application or Naisjob spec, a shared terraform module — through plan, review, implement, adversarial self-review and a draft PR
license: MIT
compatibility: Nais platform development
metadata:
  domain: process
  tags: workflow review pr atlantis blast-radius codegen
---

# Taking a change through the platform

Five stages. One fact justifies them: a merge is usually a deploy to every tenant, so the PR is the last point anything can be reconsidered.

## 1. Plan

Answer these or the plan is not finished.

- **What changes, in which repos.**
- **Blast radius.** `tenants/<tenant>/` is that tenant. `modules/` is every root composing it, usually all. A CRD in `nais/liberator` is every tenant, plus auto-committed docs in `nais/doc`.
- **What happens on merge.** Image, chart, Fasit, `ci-nais` canary, fan-out. Say so if that is what will happen.
- **What is generated.** gqlgen, sqlc, CRD types, the frontend's `schema.graphql`.
- **Whether a human gate applies.** Any `.graphqls` change in `nais/api` needs `@nais/tooling`.

Read the repo's own `AGENTS.md` first.

## 2. Review the plan

Check it against the repo's conventions, what already exists, the callers of anything shared, and reversibility. If a revert will not undo this, say so now.

Revise here. A plan corrected before implementation costs nothing.

## 3. Implement

- Use the repo's `mise` tasks. `nais/helm-charts` is the exception.
- **Regenerate and commit generated output in the same change.**
- Use the offline local path. Do not test against a real tenant.
- Watch test shapes: `naiserator` uses golden YAML with a four-mode matcher where `subset` is subsequence, so it proves presence and never absence. `nais/api` integration tests are Lua.

## 4. Adversarial self-review

Apply `nais-adversarial-review`. For a second pair of eyes that did not write the
change, start the reviewer as its own session: `nav-pilot --persona nais-review`. It owns this stage: six axes run separately, a mandatory finding per axis, and a BLOCK / CONCERNS / CLEAN verdict.

Questions specific to a change in flight:

- Does it do what the plan said, and only that? Scope creep is the usual finding.
- What breaks downstream? Touching `liberator` means checking consumers. Pseudo-version pins update nothing automatically.
- Is the blast radius still what you claimed? It moves during implementation.
- What happens on a tenant that is not `dev-nais`? `nav` has on-prem environments others lack.
- Is generated code committed and consistent with its source?
- What is untested? Name it rather than claiming coverage.
- What could fail *after* the `ci-nais` canary passes? One tenant is the only gate.

Fix what you find, then report what you found, including what you left.

## 5. Draft PR

```bash
git switch -c <branch>
git push -u origin <branch>
gh pr create --draft --title "<title>" --body "<body>"
```

**Draft**, always. It runs Atlantis and the checks, the only way to see an infrastructure plan, without pulling a reviewer onto unfinished work.

Body, in order: what and why; **blast radius**; what merging deploys; what the adversarial review found, unfixed items included; what you are unsure about and what would settle it.

Then read the Atlantis plan. On a shared module it will be large, and it reports the real radius rather than the predicted one.

Do not mark your own work ready for review.
