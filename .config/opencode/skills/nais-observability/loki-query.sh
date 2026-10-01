#!/usr/bin/env bash
# Query a tenant's Loki. Documented in SKILL.md next to this file.
# Installs without the executable bit, so run it as: bash loki-query.sh ...
set -euo pipefail

SELF=loki-query.sh

usage() {
  cat <<'EOF'
Usage: bash loki-query.sh <tenant> <logql> [--range <start> <end> [step]] [--limit <n>] [--org nais|tenant]

  <tenant>  lowercase tenant name without the .no or .io suffix (narc tenant get)
  <logql>   LogQL expression, quoted

  --range <start> <end> [step]
            range query. start/end as RFC3339 or unix nanoseconds. step is
            optional and only means anything for a metric query.
            Without it, an instant query.
  --limit <n>
            maximum entries returned. Loki's own default applies without it.
  --org nais|tenant
            X-Scope-OrgID. Default: nais, the platform's own data (nais-system,
            node-exporter, alerts). Use tenant for a tenant's workloads.

Prints the API response on stdout and nothing else. Pipe it to jq yourself.
EOF
}

die() { printf '%s: %s\n' "$SELF" "$1" >&2; exit 2; }

tenant=""
query=""
org="nais"
start=""
step=""
limit=""

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --org)
      [ $# -ge 2 ] || die "--org needs a value: nais or tenant"
      org=$2; shift 2 ;;
    --limit)
      [ $# -ge 2 ] || die "--limit needs a number"
      limit=$2; shift 2 ;;
    --range)
      [ $# -ge 3 ] || die "--range needs <start> <end> and optionally <step>"
      start=$2; end=$3; shift 3
      # step is optional, so take a following argument only if it is not a flag.
      if [ $# -ge 1 ]; then
        case "$1" in -*) ;; *) step=$1; shift ;; esac
      fi ;;
    --) shift ;;
    -*) die "unknown option: $1" ;;
    *)
      if [ -z "$tenant" ]; then tenant=$1
      elif [ -z "$query" ]; then query=$1
      else die "unexpected argument: $1"
      fi
      shift ;;
  esac
done

[ -n "$tenant" ] || { usage >&2; die "no tenant. Find it with: narc tenant get"; }
[ -n "$query" ] || die "no LogQL expression. Quote it so the shell keeps the braces and pipes."

norm=$(printf '%s' "$tenant" | tr '[:upper:]' '[:lower:]')
case "$norm" in *.no|*.io) norm=${norm%.*} ;; esac
[ "$norm" = "$tenant" ] || \
  die "tenant must be lowercase and without the .no or .io suffix. Pass '$norm' (check with: narc tenant get)."

case "$org" in
  nais|tenant) ;;
  *) die "--org takes nais or tenant, not '$org'. nais is the platform's own data (default), tenant is the tenant's workloads." ;;
esac

base="https://loki.$tenant.cloud.nais.io/loki/api/v1"
set -- --data-urlencode "query=$query"
if [ -n "$start" ]; then
  url="$base/query_range"
  set -- "$@" --data-urlencode "start=$start" --data-urlencode "end=$end"
  [ -z "$step" ] || set -- "$@" --data-urlencode "step=$step"
else
  url="$base/query"
fi
[ -z "$limit" ] || set -- "$@" --data-urlencode "limit=$limit"

rc=0
response=$(curl -sS -G --connect-timeout 5 -H "X-Scope-OrgID: $org" "$@" -w '\n%{http_code}' "$url") || rc=$?
if [ "$rc" -ne 0 ]; then
  printf '%s: could not reach %s (curl exit %s).\n' "$SELF" "$url" "$rc" >&2
  printf 'That is almost always naisdevice. Connect: nais device connect  (check: nais device status)\n' >&2
  exit 1
fi

code=${response##*$'\n'}
body=${response%$'\n'*}

case "$code" in
  401)
    printf '%s: 401 from %s. The X-Scope-OrgID header did not reach the server; there is no default org.\n' "$SELF" "$url" >&2
    printf 'Behind a proxy that strips headers? Check it. The value this run sent was: %s\n' "$org" >&2
    exit 1 ;;
  403)
    case "$body" in
      *[Pp]rivate*)
        printf '%s: 403 from %s, blocked before it left the sandbox.\n' "$SELF" "$url" >&2
        printf 'Every *.cloud.nais.io name resolves privately over naisdevice, and cplt blocks private targets. Waive the domain once:\n' >&2
        printf '  cplt config set proxy.allow_private_domains cloud.nais.io\n' >&2
        printf 'The match is suffix-based, so that one entry covers every tenant. This is not a query problem: do not rewrite the LogQL.\n' >&2
        exit 1 ;;
    esac ;;
esac

printf '%s\n' "$body"
case "$code" in
  2*) ;;
  *) printf '%s: HTTP %s from %s\n' "$SELF" "$code" "$url" >&2; exit 1 ;;
esac
