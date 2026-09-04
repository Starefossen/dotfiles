# Agent Guidelines

## Git Policy

**Do NOT commit or push to the default branch** unless explicitly instructed otherwise. Always create and use a feature branch for your work.

**Pushing a feature branch is allowed. Pushing to the default branch is not.**

You may push your own feature branch and open a pull request against it. The
pull request is the review request — that is what replaces "ask the human to
push". Do not push to `main` (or whatever the default branch is called) under
any circumstances, and do not merge unless the human running the session has
said so for that piece of work.

This is a deliberate change from an earlier, stricter rule. Routing every push
through a human serialised the work behind one person for no safety gain: the
protections that matter live on the default branch, in branch rulesets, required
checks and the merge queue, none of which a feature-branch push touches.

`--no-verify` is not allowed. If the pre-push hook rejects your push, that is the
hook doing its job — read what it says and fix the cause. Commit signing is
configured on this machine (`gpg.format = ssh`, key at
`~/.ssh/id_ed25519_signing`), so an unsigned-commit rejection means something is
wrong with your setup, not with the rule. Never use the flag to get past a
failing test, a lint, or a guard rail.

## Commit and PR Messages

**Do NOT add attribution trailers.** Never append any of these to a commit message or a pull-request body:

- `Co-Authored-By: Claude ...` — or any other AI/agent co-author trailer
- `Claude-Session:` or any similar session/run link
- `Generated with [Claude Code]` — or any equivalent tool footer

Write the message the change deserves and stop there. Attribution belongs in the
conversation, not in the permanent history.

The global `pre-push` hook warns on unsigned commits carrying `Co-authored-by`
trailers, and `git claim` exists to strip them after the fact — but neither is a
licence to add them and clean up later. Do not add them in the first place.

## Guard Rails

**Do NOT circumvent guard rails.** If you encounter a guard rail, failing test, or security check that prevents an action, do not try to bypass it (e.g. do not skip permissions, ignore warnings, or bypass hooks). Instead, skip the action and report the issue to the human operator for review.

## Running Subagents

When you dispatch subagents to do work in parallel, these apply. They come from a
session that ran eight lanes at once and paid for each of these the hard way.

**Never poll with sleep loops.** The harness notifies you when a task finishes
and when a background command exits. An `until ... sleep 30 ... done` around
`gh pr checks` burns tool calls and tokens for information that arrives on its
own. One agent spent over 200 tool calls largely this way.

**One issue per agent, three deliverables, no exploratory scope.** Long briefs
produce long detours. If a brief needs a fourth deliverable it is two briefs.

**Never touch a branch an agent owns.** No `git push`, no rebase, no GitHub
update-branch. Update-branch in particular creates a merge commit and will
reject the agent's next push as non-fast-forward. If a PR needs rebasing, tell
the agent; it knows whether a rebase is safe mid-flight.

**Cap concurrency at about four.** More lanes than that produce merge-queue
contention and rebase churn that costs more than the parallelism wins.

**Have a second model review significant or security-relevant changes** before
they merge. Automated PR review catches syntax and local logic; it does not
question a design decision. Route anything touching security boundaries,
authentication, network policy or config resolution through an adversarial read
by a different model. Docs and mechanical refactors do not need it.

**Give each agent its own working directory.** Two agents cloning to the same
path will collide, and the one that notices has to unpick the other's files.
Name the directory after the task.

**A red CI run can prove less than it looks like.** When you falsify a test by
deleting the fix, check that the test you care about actually ran. A failing
unit assertion aborts `cargo test` before later targets, so the integration test
you were trying to exercise may never have executed. Two red runs are sometimes
needed: one for the cheap assertion, one with it removed so the expensive one is
reached.

**A review you dispatch is not a gate unless you hold the thing being
reviewed.** Agents arm auto-merge as part of finishing. Sending a second model
to review an open PR changes nothing about whether it merges: it will land
while the review runs. If a change must not merge before review, tell its owning
agent to hold and disarm auto-merge, in the same breath as dispatching the
reviewer. Otherwise call it a post-merge audit and be honest that findings
become follow-up PRs.

**Verify what an agent reports before acting on it.** Agents state conclusions
with the same confidence whether they ran something or reasoned about it. Ask
which it was, and check the claims that matter yourself — several times this
week a report was confidently wrong about code that had already changed
underneath it.

## Communication Style

**$terse mode is default.** Keep all conversational responses exceptionally brief and to the point. Omit conversational filler, boilerplate, and unnecessary explanations.
