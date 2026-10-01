---
name: nais-adversarial-review
description: Attack your own change before opening a PR — six axes, a mandatory finding per axis, and a BLOCK/CONCERNS/CLEAN verdict
license: MIT
compatibility: Nais platform development
metadata:
  domain: process
  tags: review adversarial self-review pre-pr blast-radius
---

# Adversarial self-review

Run this after implementing and before opening the draft PR.

The failure mode this prevents is a review that summarises the change instead of attacking it. **Review primary evidence, not your implementation summary or your memory of what you intended.**

## Boundary

Resolve the base, then account for staged, unstaged, committed **and untracked** changes. Read every new untracked file in full. Ordinary diff output omits it.

Stop, and say so, when the diff is empty, the base is ambiguous, or you cannot safely separate unrelated work.

## Six axes, separately

Each axis is a separate pass. Do not let one axis rerank another's findings.

1. **Correctness.** Trace changed control and data flow: errors, state transitions, cleanup, concurrency, failure handling.
2. **Regression.** Affected callers, contracts, shared defaults, migrations, behaviour outside the edit. If you touched `nais/liberator`, name the consumers; pseudo-version pins update nothing automatically.
3. **Edge cases.** Empty, missing, malformed, repeated, concurrent, timeout, retry, partial failure.
4. **Requirement coverage.** Map each acceptance criterion to concrete code or test evidence.
5. **Repository standards.** The repo's own `AGENTS.md` outranks any heuristic here. Architecture, naming, language, tests, delivery.
6. **Scope.** Every hunk must serve the task. Also name requested behaviour the diff does **not** implement.

### Platform axes

On this platform, additionally:

- **Blast radius.** Still what the plan claimed? It moves during implementation. `modules/` is every tenant.
- **Beyond `dev-nais`.** What happens on a tenant with on-prem environments, or without them?
- **After the canary.** `ci-nais` is one tenant and the only gate before fan-out. What passes there and fails elsewhere?
- **Generated code.** Committed, and consistent with its source?

## Every axis must produce a finding

**An axis that reports nothing has not looked hard enough.** Write what you found, however small, or state what you inspected and what the evidence does not prove.

A finding raised by two or more axes is promoted one severity level.

## Verdict

End with one:

| Verdict | Rule |
|---|---|
| **BLOCK** | one or more critical findings |
| **CONCERNS** | two or more warnings |
| **CLEAN** | neither. It still states what was inspected and what the evidence does not prove |

## Gates

Discover deterministic gates from the repo's instructions, build files, test config and CI rather than assuming a toolchain. Run the smallest relevant checks, then the required final gates after the last edit. Record commands, results and exit codes. Distinguish fresh evidence from stale or unverified claims.

## Anti-patterns

Any of these means you did not do the review:

- "LGTM", "no issues found", or a summary of the change.
- Cosmetic findings only.
- Pulling punches on your own work.
- Restating the diff instead of interrogating it.
- Ignoring test gaps.
- Reviewing only changed lines, never their callers.

## Report

Material findings first, ordered by consequence. Each one: path and line, the concrete failure mode, the smallest useful correction.

Then: acceptance-criterion coverage, gate evidence, remaining uncertainty, and the verdict.

Fix in-scope findings before opening the PR. Carry the rest into the PR body. Unfixed findings belong in the open, not in a memory.
