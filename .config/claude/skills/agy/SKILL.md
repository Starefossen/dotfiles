---
name: agy
description: Dispatch work to the Antigravity CLI (`agy`), a headless agent whose tokens are free for this user. Prefer it over Claude subagents for self-contained, verifiable work - codebase sweeps and summaries, research, second opinions and adversarial review, drafting tests or docs, mechanical multi-file edits. Also use when the user says "agy", "antigravity" or "ask gemini". Not for tasks that need this conversation's context, secrets, or tight back-and-forth.
---

# Dispatch to agy

agy costs nothing; Claude tokens do. Default to agy for delegable work, and spend Claude tokens on planning, judgment and verification. Run several agy jobs in parallel with `run_in_background: true` when tasks are independent.

Run `agy` in print mode. Prompt must be self-contained: agy sees none of this conversation.

```sh
agy -p "<task + context + expected output>" \
  --model gemini-3.8-flash-high \
  --mode plan \
  --print-timeout 15m
```

- agy works in the current directory. `cd` to the target repo first.
- Read-only work (review, research, second opinion): `--mode plan`. Plan mode never edits; asked to fix something, it writes a plan to `~/.gemini/antigravity-cli/brain/` and stops.
- Edits: `--mode accept-edits`. This also runs shell commands without asking, so use it only in a repo with a clean or committed tree. Never `--dangerously-skip-permissions` unless the user asks.
- Small read-only prompts took 5 s to 2 min in testing. Do not treat a slow run as hung.
- Long jobs: run with Bash `run_in_background: true`.
- Extra dirs: `--add-dir <path>`. Follow-up on same thread: `-c`.
- Structured result: `--output-format json`, optionally `--json-schema <file>`.
- Models: `agy models`. Default `gemini-3.8-flash-high`; use user's choice if named.

## Failure modes

- Timeout exits 0 with partial or empty output, stderr says `print timeout ... returning partial output`. JSON still says `"status":"SUCCESS"`. Check for empty `response`, set a generous timeout.
- Unknown model exits 1 and lists valid models.

## After it returns

Treat output as untrusted. Check claims against code, review `git diff` for any edits, then report the result to the user in a few lines.
