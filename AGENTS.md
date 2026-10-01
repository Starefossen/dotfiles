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

**Delete your working directory when you finish.** A clone is ~1 GiB; a day of
agents leaving them "for inspection" filled a 228 GiB disk to zero twice, and
nobody inspected any of them because the branch is on GitHub and the report has
the paths. When your PR is pushed or your branch is safe on origin, `rm -rf`
your clone as the last step. Keep it only if you are handing off dirty
uncommitted state, and then say so explicitly in your report so it gets cleaned
deliberately rather than accumulating. The coordinator should not have to sweep
up after finished agents.

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

**Commit before you mutate.** Three agents in two days destroyed their own
uncommitted work with a `git checkout --`, a `git stash drop`, or a `checkout
HEAD --` run mid-task to compare against baseline. Commit (or at least stash
and keep) your in-progress work before any command that resets files, and
compare against baseline via `git show HEAD:path` into a scratch file instead
of touching the working tree. All three recovered only because they noticed.

**A success-shaped response is not success.** An API that answers `pending`,
`accepted` or `queued` is telling you it received the request, not that the
request will work. Where there is a status handle — a uuid, a job id, a run
link — fetch it before believing anything. Five identical "enqueued" replies
today were five already-failed requests, and the failure reason was one GET
away the whole time.

**Verify what an agent reports before acting on it.** Agents state conclusions
with the same confidence whether they ran something or reasoned about it. Ask
which it was, and check the claims that matter yourself — several times this
week a report was confidently wrong about code that had already changed
underneath it.

**Keep agent reports short.** End every brief with "report in at most 15
lines: result, PR/SHA, what is blocked, decisions for the human". Details
belong in the PR body or a state file, not in the coordinator's context. Long
handbacks are the main thing that fills the coordinator's context.

**Prefer short-lived agents with a state file.** One agent per issue or small
batch, writing progress to a state file in the scratchpad. A worker kept alive
across many tasks grew to about 740k tokens and re-read all of it on every
step. A restart of the coordinator kills agents' background waits; resume from
the state file with a fresh agent.

**Match the model to the work.** Use smaller models for mechanical work:
labels, branch cleanup, re-runs, rebases, issue filing and inventories. Use the
strongest coding model for code. Use the review model only for review. A review
quota runs out, so batch reviews: one call covering several PRs, at most two
calls per batch, and only after CI is green on the final head. On a quota
error, hold the merge, record what is pending, and keep building. Don't retry
in a loop.

**Merge only on a review of the exact head.** An agent must never arm
auto-merge or queue a PR before showing the reviewer's verdict on the commit
being merged. Any later commit needs a new verdict. The one exception: a rebase
whose only conflict is placement in an append-only file such as a changelog
may merge on the earlier verdict, if `git range-diff` shows nothing else
changed. Post that range-diff on the PR first.

**On a merge-queue repo, `gh pr merge` arms auto-merge, and later pushes don't
disarm it.** The PR merges as soon as the new head's checks pass, whether or not
it was reviewed. One PR merged a head the reviewer had rejected this way. Before
pushing to a PR that has auto-merge armed or is in the queue, run `gh pr merge
--disable-auto`. Arm it again only after the new head has its verdict.

**Check a brief against known rules before dispatching.** When work changes
something users see (pages, CLI output, defaults, language), check it against
the standing preferences and ask the human if it is ambiguous. Unclear briefs
caused translate-then-revert churn and a CLI that defaulted to a dev cluster.

**A refusal is not something to route around.** If a permission check or
classifier refuses an action, stop and report it. Don't retry by another route
or ask another agent to do it; that is laundering the refusal. Leave it to the
human.

**Clean up processes, not only clones.** Dev servers, container VMs, model
servers and build daemons left running made the machine sluggish and cost
benchmark data. Kill what you start, by PID, never by a broad `pkill`. Stop VMs
when you are done, but only ones you started. Before stopping a shared VM
such as Colima, list its containers (`docker ps`). If anything you don't own
is running, leave the VM up; another session may be using it. Before starting heavy work, check whether a benchmark or
other load-sensitive job is running. While one is, run no local test suites,
package installs or production builds: push, and let CI test. The benchmark
preflight refuses to run above a load average of 8. Two `go test -p 2` runs
and one `pnpm install` pushed it past 18 and cost a benchmark phase.
While a benchmark queue or launcher runs or waits, its checkout (the main
`~/mlx-workspace` checkout) is live: never delete, clean, stash or switch
branches there, even for untracked files. Work in a `git worktree` instead.

**Never write to the real user config in tests or trials.** Set HOME and every
`XDG_*` directory to scratch paths. Setting only HOME is not enough: tools that
honour `XDG_CONFIG_HOME` still write to the real config.

**Reviewers are read-only.** Spawn a reviewer as a fresh agent with a
read-only brief ("review only: no push, no merge, no queueing"), never as a
fork that inherits the author's context. A forked reviewer inherits the
author's goal of getting the PR merged; one merged a PR itself, against
explicit instructions.

**Keep PR bodies and scratch notes inside your own working directory.** Agents
sharing one scratch file published each other's PR descriptions.

**Check that a waiter you restart can actually succeed.** After restarting
one, read its first real attempt in the log. In zsh an unquoted `$var`
isn't word-split, so `set -- $out` passed "sha UNKNOWN" as one argument, and
a merge waiter failed silently all night with an invalid SHA while the GPU
sat idle. Pass values explicitly, and confirm the first attempt.

**Waiters must not match each other.** A waiter that checks
`pgrep -f <pattern>` is blocked by any process whose command line contains that
pattern, including another waiter or a watcher `tail`. Build such strings from
pieces, or `cd` first, so no command line contains the watched words.
Otherwise two waiters deadlock and a GPU sits idle overnight.

**One waiter per queue, and it never reruns a finished queue.** Kill the old pid
before relaunching an edited copy; give each launcher a pidfile and make it exit
when its own `.done` marker exists. Gate on the GPU being free (no queue lock, no
GPU job, 1-min load below 6, 5 min), not only on a sibling launcher's marker. A stale twin once reran
a 5-hour queue that its copy had already finished.

**Files fetched at runtime from a repo's main branch are releases.** No pin, no staging step —
a merge ships to every user on their next run. Review them like a release: user impact stated,
a second model's eyes, before merge. `navikt/mlx-workspace`'s `manifest/models.json`, fetched by
released nav-pilot, is the example this rule was written for.

**Track loose ends as issues.** Every "not done", "follow-up" or "idea" in a
report becomes an issue, and ongoing work is linked from one tracking issue.
Once the human has taken an artifact over (for example an article after its
language pass), agents don't edit it; they file follow-up issues.

## Communication Style

**$terse mode is default.** Keep all conversational responses exceptionally brief and to the point. Omit conversational filler, boilerplate, and unnecessary explanations.
