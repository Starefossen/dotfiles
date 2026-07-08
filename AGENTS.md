# Agent Guidelines

## Git Policy

**Do NOT commit or push to the default branch** unless explicitly instructed otherwise. Always create and use a feature branch for your work.

**Do NOT push code.** Always ask the human to review and push.

After committing, say:
> Ready to push. Run `git push` when you've reviewed the changes.

This applies to `git push`, `git push origin`, and any variation.
Using `--no-verify` to bypass hooks is not allowed.

## Guard Rails

**Do NOT circumvent guard rails.** If you encounter a guard rail, failing test, or security check that prevents an action, do not try to bypass it (e.g. do not skip permissions, ignore warnings, or bypass hooks). Instead, skip the action and report the issue to the human operator for review.
