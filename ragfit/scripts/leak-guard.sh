#!/usr/bin/env bash
# Leak-Guard for RagFit | Monitor: blocks Tailnet domains/IPs, private IPs,
# local user/workspace paths, internal hostnames, and credential patterns
# across all Erynoa/RagFit-owned and modified files.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

patterns=(
  '[A-Za-z0-9-]+\.ts\.net'
  '\b100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\.[0-9]{1,3}\.[0-9]{1,3}\b'
  '\b10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\b'
  '\b192\.168\.[0-9]{1,3}\.[0-9]{1,3}\b'
  '\b172\.(1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3}\b'
  '\bfd7a:115c:a1e0:'
  '(^|[^A-Za-z])/(home|workspace|Users)/[A-Za-z0-9._-]+'
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'
  'gh[pousr]_[A-Za-z0-9]{30,}'
  'tskey-[A-Za-z0-9-]+'
  'AGE-SECRET-KEY-1[0-9A-Z]+'
  'github_pat_[A-Za-z0-9_]{20,}'
  '\bAKIA[0-9A-Z]{16}\b'
  '\b[A-Za-z0-9-]+\.(internal|lan|home\.arpa)\b|\bk9ix\b'
)

targets=(
  README.md
  erynoa.md
  AGENTS.md
  CLAUDE.md
  .claude/CLAUDE.md
  .github
  flake.nix
  justfile
  MODIFICATIONS.md
  TRADEMARKS.md
  docs/README.md
  docs/ARCHITECTURE.md
  docs/work
  ragfit
)

existing=()
for t in "${targets[@]}"; do
  [[ -e "$t" ]] && existing+=("$t")
done

fail=0
for p in "${patterns[@]}"; do
  rc=0
  hits=$(grep -rnIE --exclude="leak-guard.sh" --exclude="test-helm.sh" -- "$p" "${existing[@]}" 2>/dev/null) || rc=$?
  if [[ "$rc" -eq 0 && -n "$hits" ]]; then
    echo "::error::leak-guard pattern matched: $p" >&2
    echo "$hits" >&2
    fail=1
  fi
done

if [[ "$fail" -ne 0 ]]; then
  echo "leak-guard: FAILED" >&2
  exit 1
fi
echo "leak-guard: clean"
