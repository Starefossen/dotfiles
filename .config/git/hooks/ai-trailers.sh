#!/bin/sh
# The rule, in one place: what AI attribution looks like, and the two checks
# that enforce it. Sourced by git-hook-dispatch.
#
# These hooks are a BACKSTOP, not the control. Two things sit above them:
# Claude Code's own `attribution` setting (which stops the trailers being
# written at all) and a server-side check in CI. Roughly a third of the repos
# on this machine set a LOCAL core.hooksPath — husky, .githooks, simple-git-
# hooks — and a local setting beats the global one, so nothing here runs there.
#
# Deliberately NOT matching a bare "co-authored-by:" — co-authorship is a real
# trailer for real people and must survive untouched.
#
# POSIX ERE with `grep -iE`. Case-insensitivity comes from the FLAG, not from
# [Cc] classes spelled into the pattern: the first draft wrote
# `Co-[Aa]uthored-[Bb]y` and let a fully lowercase `co-authored-by: claude`
# straight through. One flag cannot be got wrong the way twelve classes can.
AI_TRAILER_RE='noreply@anthropic\.com|^[[:space:]]*(co-authored-by|assisted-by|signed-off-by)[[:space:]]*:.*(claude|anthropic)|^[[:space:]]*claude-session[[:space:]]*:|generated with \[?claude|^[[:space:]]*(🤖|>)?[[:space:]]*(https?://)?claude\.ai/code'

# The part of a commit-message FILE that will actually become the message:
# no `#` comments, and nothing below `git commit -v`'s scissors line. Without
# the scissors cut, committing a change to these hooks or to a CLAUDE.md would
# match the trailer text in the DIFF and block a perfectly clean message.
msg_body() {
  sed -e '/^# -* >8 -*$/,$d' -e '/^#/d' "$1"
}

ai_trailer_hits() {
  grep -niE "$AI_TRAILER_RE" 2>/dev/null || true
}

# STRIPS the offending lines rather than refusing.
#
# The adversary here is an agent, and a refusal is precisely the prompt that
# makes one reach for `--no-verify` — which also skips the repo's own hooks and
# its test suite. Stripping produces a green commit with nothing to route
# around. Removals are announced on stderr, so it is never silent.
#
# Exception: a match in the SUBJECT line is refused, not stripped. Deleting
# line 1 either empties the message or promotes a body line to subject, and a
# commit legitimately *about* this policy ("docs: forbid noreply@anthropic.com
# trailers") is exactly the case that hits it.
strip_commit_msg() {
  f="$1"
  hits=$(msg_body "$f" | ai_trailer_hits)
  [ -z "$hits" ] && return 0

  subject=$(msg_body "$f" | sed -n '1p')
  if printf '%s\n' "$subject" | grep -qiE "$AI_TRAILER_RE"; then
    {
      echo ""
      echo "✖ AI attribution in the SUBJECT line:"
      echo "    $subject"
      echo ""
      echo "  Not stripped automatically — removing line 1 would empty the"
      echo "  message or promote a body line into its place. Reword it."
      echo "  Your text is preserved: git commit -e -F .git/COMMIT_EDITMSG"
      echo ""
    } >&2
    exit 1
  fi

  # BSD sed: no /I, and -i needs an explicit backup suffix. grep -v into a
  # temp file and move it back, which is portable and atomic enough here.
  tmp="$f.aitrailers.$$"
  grep -viE "$AI_TRAILER_RE" "$f" > "$tmp" && mv "$tmp" "$f"
  {
    echo "• removed AI-attribution line(s) from the commit message:"
    echo "$hits" | sed 's/^/    /'
  } >&2
  return 0
}

# The real net: rebase, cherry-pick, squash, merge and `--no-verify` all create
# or rewrite commits WITHOUT running commit-msg, and none of them reach a
# remote without passing through here.
check_pre_push() {
  refs="$1"
  remote_name="${2:-}"
  fail=0

  # The identity git would actually use for a commit in THIS repo — nav.no in
  # some, flaatten.org in others. `git config user.email` misses the env-var
  # and per-repo include cases that `git var` resolves.
  me=$(git var GIT_COMMITTER_IDENT 2>/dev/null | sed 's/.*<\(.*\)>.*/\1/')

  # Fed by REDIRECTION, not a pipe: a `while` on the right of a pipe runs in a
  # subshell, so every `fail=1` below would be discarded when the loop ended.
  while IFS=' ' read -r _local_ref local_oid _remote_ref remote_oid; do
    [ -z "${local_oid:-}" ] && continue
    # Branch deletion (all-zero oid): nothing added, nothing to inspect.
    case "$local_oid" in *[!0]*) ;; *) continue ;; esac

    case "$remote_oid" in
      *[!0]*) range="$remote_oid..$local_oid" ;;
      # New branch: only what this REMOTE does not have. Scoped to the remote
      # being pushed to — a fork's refs are not evidence about origin.
      *)      range="$local_oid --not --remotes=${remote_name:-origin}" ;;
    esac

    # Only commits WE committed. Rebasing or amending someone else's work makes
    # us the committer and re-signs it, so the committer is the right key; a
    # colleague's unsigned commit on a branch we merely push is not ours to
    # reject. `--committer` and `--author` on one rev-list are ANDed, not ORed,
    # so the filter is applied here rather than as two flags.
    for sha in $(git rev-list $range --committer="$me" 2>/dev/null); do
      hits=$(git log -1 --format=%B "$sha" | ai_trailer_hits)
      # Attribution can also hide in the author/committer HEADERS —
      # `claude[bot]`, a GIT_AUTHOR_NAME override — where no message check
      # would ever see it.
      ident=$(git log -1 --format='%an %ae %cn %ce' "$sha" | ai_trailer_hits)
      if [ -n "$hits" ] || [ -n "$ident" ]; then
        echo "✖ $(git log -1 --format='%h %s' "$sha")" >&2
        [ -n "$hits" ] && echo "$hits" | sed 's/^/      /' >&2
        [ -n "$ident" ] && echo "      identity: $(git log -1 --format='%an <%ae>' "$sha")" >&2
        echo "      AI attribution. Rewrite: git rebase -i $sha^" >&2
        fail=1
      fi

      # Signature presence is read from the OBJECT, not from `%G?`.
      #
      # `%G?` shells out to gpg, and gpg lives in /opt/homebrew/bin: from any
      # app launched with a minimal PATH (a GUI git client, an IDE terminal)
      # every signed commit reports `N`, and a hook trusting that would block
      # every push and teach everyone `--no-verify`. A `gpgsig` header is
      # present or it is not, and reading it needs no gpg at all.
      #
      # This checks that a signature EXISTS, not that it verifies. Verification
      # belongs server-side, where the keys actually live.
      if ! git cat-file commit "$sha" | sed '/^$/q' | grep -q '^gpgsig'; then
        echo "✖ $(git log -1 --format='%h %s' "$sha")" >&2
        echo "      unsigned. Re-sign: git rebase --exec 'git commit --amend --no-edit' $sha^" >&2
        fail=1
      fi
    done
  done <<REFS
$refs
REFS

  [ "$fail" -eq 0 ] && return 0
  {
    echo ""
    echo "  Push blocked. Override (also skips this repo's own hooks): git push --no-verify"
    echo ""
  } >&2
  exit 1
}
