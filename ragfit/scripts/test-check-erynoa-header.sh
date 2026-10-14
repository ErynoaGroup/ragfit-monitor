#!/usr/bin/env bash
# Offline tests for check-erynoa-header.sh: passes on the repo, fails on each kind of drift.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; ROOT="$(cd "$HERE/../.." && pwd)"
C="$HERE/check-erynoa-header.sh"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
n=0
pass() { "$@" >/dev/null 2>&1 || { echo "FAIL (expected pass): $*"; exit 1; }; n=$((n+1)); }
fails() { local why=$1; shift; if "$@" >/dev/null 2>&1; then echo "FAIL (expected failure): $why"; exit 1; fi; n=$((n+1)); }
fresh() { rm -rf "$T/e" && cp -r "$ROOT/public/img/ragfit/erynoa" "$T/e" && cp "$ROOT/public/views/index.html" "$T/index.html"; }

fresh; pass env ERYNOA_DIR="$T/e" "$C" "$T/index.html"
fresh; echo "/* x */" >> "$T/e/1.1.2/erynoa-header.v1.css"; fails "package file changed" env ERYNOA_DIR="$T/e" "$C" "$T/index.html"
fresh; cp "$T/e/1.1.2/LICENSE" "$T/e/1.1.2/extra.txt"; fails "extra file in 1.1.2" env ERYNOA_DIR="$T/e" "$C" "$T/index.html"
fresh; rm "$T/e/1.1.2/CHANGELOG.md"; fails "missing file in 1.1.2" env ERYNOA_DIR="$T/e" "$C" "$T/index.html"
fresh; echo x >> "$T/e/fonts/hanken-grotesk/OFL.txt"; fails "font license changed" env ERYNOA_DIR="$T/e" "$C" "$T/index.html"
fresh; cp "$T/e/fonts/hanken-grotesk/OFL.txt" "$T/e/fonts/hanken-grotesk/x.otf"; fails "unlisted font" env ERYNOA_DIR="$T/e" "$C" "$T/index.html"
fresh; sed -i 's|>Plan</a>|>Planning</a>|' "$T/index.html"; fails "nav label changed" env ERYNOA_DIR="$T/e" "$C" "$T/index.html"
fresh; sed -i 's|https://source.\[\[.ErynoaDomain\]\]/" aria-label|https://source.example.org/" aria-label|' "$T/index.html"; fails "host in logo link" env ERYNOA_DIR="$T/e" "$C" "$T/index.html"
fresh; sed -i '/erynoa\/ragfit-monitor-header.css/d' "$T/index.html"; fails "glue CSS not linked" env ERYNOA_DIR="$T/e" "$C" "$T/index.html"
fresh; sed -i '/<header class="erh"/,/<\/header>/d' "$T/index.html"; fails "header missing" env ERYNOA_DIR="$T/e" "$C" "$T/index.html"
fresh; sed -i 's| aria-current="page">Monitor<|>Monitor<|' "$T/index.html"; fails "monitor not marked current" env ERYNOA_DIR="$T/e" "$C" "$T/index.html"
fresh; sed -i 's|>Plan</a>|>Plan</a>|; s|data-erh-service="plan"   href="\([^"]*\)">|data-erh-service="plan"   href="\1" aria-current="page">|' "$T/index.html"; fails "second current entry" env ERYNOA_DIR="$T/e" "$C" "$T/index.html"
fresh; sed -i '/data-erh-service="monitor"/d' "$T/index.html"; fails "monitor entry missing" env ERYNOA_DIR="$T/e" "$C" "$T/index.html"
fresh; sed -i '0,/\[\[ if \.ErynoaDomain \]\]/{/\[\[ if \.ErynoaDomain \]\]/d}' "$T/index.html"; fails "stylesheets not wrapped" env ERYNOA_DIR="$T/e" "$C" "$T/index.html"
fresh; python3 - "$T/index.html" <<'PY'
import sys; p=sys.argv[1]; s=open(p).read(); i=s.index('[[ if .ErynoaDomain ]]', s.index('<body')); s=s[:i]+s[i+len('[[ if .ErynoaDomain ]]'):]; open(p,'w').write(s)
PY
fails "header not wrapped" env ERYNOA_DIR="$T/e" "$C" "$T/index.html"
echo "ok: $n check-erynoa-header tests"
