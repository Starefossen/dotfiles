---
name: nais-go-review
description: Review a Go pull request, diff or package in a nais repo — api, fasit, naiserator, liberator, cli, v13s, audit-approval — for what gofmt, go vet, staticcheck, golangci-lint and gosec do not catch, and for the checks each repo's CI leaves ungated. Use when asked to review, critique or approve Go code, not when writing it.
license: MIT
compatibility: Nais platform development, Go repos under github.com/nais
metadata:
  domain: process
  tags: go golang review pull-request diff staticcheck golangci-lint gosec testing mocks fakes
---

# Reviewing Go in nais repos

The Go content for `nais-adversarial-review`'s correctness and repository-standards axes. The repo's `AGENTS.md` outranks everything here. If a linter would say it, do not.

## What CI already says

Gated everywhere checked: staticcheck's default S/SA/ST set, unused code, govulncheck, races a test exercises, generated-code drift in api and fasit. No repo has a `.golangci.yml`; golangci-lint runs its default five (errcheck, govet, ineffassign, staticcheck, unused) and only in fasit, cli and audit-approval.

Gated nowhere: naming and initialisms, doc-comment presence, shadowing, `%w` vs `%v`, `go mod tidy` drift. CodeQL blocks nothing (advisory in api, scheduled in naiserator and cli, absent elsewhere).

Verified 2026-09 at api@e01f785, fasit@3cc4ad7, naiserator@dae45ec, audit-approval@d0eb7e9, cli@786f893. A bump in `go.mod`'s `tool` block moves this table; confirm against the repo's mise tasks and CI workflow.

| repo | ungated — review by hand | doubles | behaviour tests |
|---|---|---|---|
| api | unchecked errors; gosec (local only: secrets, weak rand); `go vet` beyond the `go test` subset (copied locks, lost cancel); deprecated APIs; action pins | mockery, regen gated | Lua specs in `integration_tests/`, `-tags integration_test`. A behaviour change without a spec change is incomplete. `.graphqls` needs @nais/tooling |
| fasit | blank-assigned errors; naming | hand-written in `_test.go`, stdlib `testing`, `t.Helper()` | testcontainers, hard-fail without Docker. deadcode runs with `-tags integration_test`: tag-only helpers are live |
| naiserator | unchecked errors; gosec; formatting (no diff check); action pins. Thinnest gate | controller-runtime fake client, testify | hand-written YAML goldens under `pkg/resourcecreator/testdata`, no `-update`. The golden diff is the change; review it as such |
| audit-approval | gomock drift after an interface change (CI diffs sqlc only); action pins | gomock plus hand-written fakes; fakes preferred | `internal/database` runs only in the "Database tests" job, not a required check. `mise run check` auto-fixes; `verify` is the gate |
| cli | genqlient client and `docs/nais_*.md` drift (`mise run generate:graphql`); gosec minus subprocess, SSRF, path, timeout | hand-written mocks, testify | — |
| liberator, v13s | not audited | mockery, testify | — |

## Errors

- `_ = f()` only for best-effort cleanup in a `defer`. errcheck's default is silent on it by design.
- Handle once: log and degrade, or return. `log(...); return err` is both.
- Never branch on `err.Error()`, in code or tests. Sentinel or type, `errors.Is`/`As`; `wantErr bool` when only presence matters.
- `%w` puts the inner error in the package contract; `%v` at a boundary is deliberate translation. Flag `%w` by reflex and prefixes that add nothing.
- `Must*` at init or test setup only. `log.Fatal` once, in `main`; a blanket `recover()` hides corrupted state.

## Concurrency

- A goroutine the change starts has a stop signal and a way for its owner to wait. Reject bare `go f()` in a loop and in `init()`. Prefer synchronous; the caller can add concurrency, never remove it.
- Buffered channel larger than 1: the size, the full-behaviour and the backpressure written down.
- A slice or map stored from a caller or returned from internal state is copied unless ownership transfer is documented.
- `context.Background()` at entrypoints only. A function taking `ctx` returns `error`.
- No mutable package state tests must swap (`var now = time.Now`, registries at init). `init()` does no I/O.
- "Looks racy" needs an interleaving the tests do not run.

## Design

- An interface belongs to its consumer and exists for a second implementation. Exception: repos with a generator (api, audit-approval, v13s, liberator) declare interfaces for doubles by policy; there, check the double was regenerated. In fasit and naiserator an interface with one implementation and no double is a smell.
- Packages are domains, not layers: a new `internal/services` or `internal/repository` is wrong everywhere. api requires singular names; audit-approval's plurals are established.
- Where the repo has `CONTEXT.md` (fasit, v13s), identifiers use its terms exactly.
- Comments say what the signature cannot: concurrent-safe or not, who closes, a `ctx` that behaves unusually, which errors callers may match. Delete comments that restate code. Exception: api follows Go Code Review Comments, so exported names there carry doc comments; do not demand them in fasit or audit-approval.

## Tests

- Stateful fake over strict `EXPECT()` mock unless the call sequence is the assertion. v13s is the outlier; a preference, not a ban.
- A fake standing in for a database gets its rules as one table run against both the fake and the real database.
- `t.Skip` on an unreachable service only where CI turns the same condition into failure (`REQUIRE_DB=1`) or the test hard-fails (testcontainers). api's BigQuery updater test skips under no guard: that is the failure mode.
- Pass/fail stays in the `Test` function. Failure text names function, input (never the row index), got, want. Library-agnostic.
- `t.Error` per independent check; `t.Fatal` when the rest cannot run.
- One `cmp.Diff` on whole values, never on serialized bytes from code you do not own.
- A table whose loop body branches per row is two tests.
- An interface change fans out to every fake and mock in the same PR. Only api, fasit and cli gate the generated half.
- Fixtures are anonymised copies: values replaced, shape kept so the parser still runs. No repo scans for secrets or PII.
- Do not modify or delete an existing test, above all a build-tagged one, without asking; `unused` cannot see tag-only callers.

## Logging

User input never reaches a log line verbatim; strip CR/LF/TAB or log length and type. Nothing in fasit, v13s or audit-approval checks this.

## Verification

- Pass/fail is the unpiped exit code. `go test ./... | grep FAIL` reports grep's.
- A task that rewrites files (`fmt`, audit-approval's `check`) is not a gate.
- A PR bumping a tool pin changes what CI enforces; review it for checks that switched on or off.
