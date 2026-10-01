#!/usr/bin/env bash
# Query a tenant's Mimir. Documented in SKILL.md next to this file.
# Installs without the executable bit, so run it as: bash mimir-query.sh ...
set -euo pipefail

SELF=mimir-query.sh

usage() {
  cat <<'EOF'
Usage: bash mimir-query.sh <tenant> <promql> [--range <start> <end> <step>] [--org nais|tenant]

  <tenant>  lowercase tenant name without the .no or .io suffix (narc tenant get)
  <promql>  PromQL expression, quoted

  --range <start> <end> <step>
            range query. start/end as RFC3339 or unix seconds, step like 30s.
            Without it, an instant query.
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

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --org)
      [ $# -ge 2 ] || die "--org needs a value: nais or tenant"
      org=$2; shift 2 ;;
    --range)
      [ $# -ge 4 ] || die "--range needs <start> <end> <step>"
      start=$2; end=$3; step=$4; shift 4 ;;
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
[ -n "$query" ] || die "no PromQL expression. Quote it so the shell keeps the braces."

norm=$(printf '%s' "$tenant" | tr '[:upper:]' '[:lower:]')
case "$norm" in *.no|*.io) norm=${norm%.*} ;; esac
[ "$norm" = "$tenant" ] || \
  die "tenant must be lowercase and without the .no or .io suffix. Pass '$norm' (check with: narc tenant get)."

case "$org" in
  nais|tenant) ;;
  *) die "--org takes nais or tenant, not '$org'. nais is the platform's own data (default), tenant is the tenant's workloads." ;;
esac

base="https://mimir.$tenant.cloud.nais.io/prometheus/api/v1"
if [ -n "$start" ]; then
  url="$base/query_range"
  set -- --data-urlencode "query=$query" \
         --data-urlencode "start=$start" \
         --data-urlencode "end=$end" \
         --data-urlencode "step=$step"
else
  url="$base/query"
  set -- --data-urlencode "query=$query"
fi

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
        printf 'The match is suffix-based, so that one entry covers every tenant. This is not a query problem: do not rewrite the PromQL.\n' >&2
        exit 1 ;;
    esac ;;
esac

printf '%s\n' "$body"
case "$code" in
  2*) ;;
  *) printf '%s: HTTP %s from %s\n' "$SELF" "$code" "$url" >&2; exit 1 ;;
esac
