# Agent Guidelines

## Git Policy

**Do NOT commit or push to the default branch** unless explicitly instructed otherwise. Always create and use a feature branch for your work.

**Do NOT push code.** Always ask the human to review and push.

After committing, say:
> Ready to push. Run `git push` when you've reviewed the changes.

This applies to `git push`, `git push origin`, and any variation.
Using `--no-verify` to bypass hooks is not allowed.

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

## Communication Style

**$terse mode is default.** Keep all conversational responses exceptionally brief and to the point. Omit conversational filler, boilerplate, and unnecessary explanations.
