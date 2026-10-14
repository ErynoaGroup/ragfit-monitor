#!/usr/bin/env bash
# Checks the vendored Erynoa header 1.1.4 (public/img/ragfit/erynoa/): the package's own SHA256SUMS,
# the exact file set, our SHA256SUMS (fonts and glue), and that public/views/index.html renders the
# package's partial with only the allowed values filled in (theme, skip link, logo link, domain,
# current="monitor", asset base = the versioned folder), all inside [[ if .ErynoaDomain ]] so nothing renders without a derivable domain.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
D="${ERYNOA_DIR:-$ROOT/public/img/ragfit/erynoa}"
INDEX="${1:-$ROOT/public/views/index.html}"
fail() { echo "FAIL: $*" >&2; exit 1; }

(cd "$D/1.1.4" && sha256sum --quiet --strict -c SHA256SUMS) || fail "1.1.4/SHA256SUMS"
want="CHANGELOG.md LICENSE NOTICE.md PROVENANCE.md SHA256SUMS erynoa-en-lockup.svg erynoa-header.v1.css erynoa-header.v1.html erynoa-header.v1.js"
got=$(cd "$D/1.1.4" && LC_ALL=C ls -A | tr '\n' ' ' | sed 's/ $//')
[ "$got" = "$want" ] || fail "unexpected file set in 1.1.4/: $got"
grep -q 'data-erynoa-header="1.1.4"' "$D/1.1.4/erynoa-header.v1.html" || fail "package is not 1.1.4"
(cd "$D" && sha256sum --quiet --strict -c SHA256SUMS) || fail "SHA256SUMS"
for f in $(cd "$D" && find fonts -type f | sort); do
  grep -q "  $f\$" "$D/SHA256SUMS" || fail "$f is not listed in SHA256SUMS"
done

# Expected markup: the package partial with the placeholders and the theme filled in.
expected=$(sed -n '/^<header /,/^<\/header>/p' "$D/1.1.4/erynoa-header.v1.html" \
  | sed -e 's|__ERH_SKIP_TARGET__|[[.ErynoaSkipHref]]|' \
        -e 's|__ERH_HOME_URL__|https://source.[[.ErynoaDomain]]/|' \
        -e 's|__ERYNOA_DOMAIN__|[[.ErynoaDomain]]|g' \
        -e 's|__ERH_ASSET_BASE__|[[.Assets.ContentDeliveryURL]]public/build/img/ragfit/erynoa/1.1.4/|g' \
        -e 's|data-erh-service="monitor" href="\([^"]*\)">|data-erh-service="monitor" href="\1" aria-current="page">|' \
        -e 's|data-erynoa-header="1.1.4">|data-erynoa-header="1.1.4"[[ if or (eq .ThemeType "light") (eq .ThemeType "dark") ]] data-erh-theme="[[ .ThemeType ]]"[[ end ]]>|' \
  | sed -e 's/^[[:space:]]*//')
actual=$(sed -n '/^[[:space:]]*<header class="erh"/,/^[[:space:]]*<\/header>/p' "$INDEX" | sed -e 's/^[[:space:]]*//')
[ -n "$actual" ] || fail "no Erynoa header in $INDEX"
[ "$expected" = "$actual" ] || { diff <(echo "$expected") <(echo "$actual") >&2 || true; fail "header markup in $INDEX differs from the 1.1.4 partial"; }
# Fail closed: header, skip script and stylesheets only when a base domain was derived.
awk '
  /^[[:space:]]*\[\[ if \.ErynoaDomain \]\][[:space:]]*$/ { if (open) bad=1; open=1; blocks++; next }
  /^[[:space:]]*\[\[ end \]\][[:space:]]*$/ && open { open=0; next }
  /erh|erynoa\// && !/^[[:space:]]*<!--/ && !/^[[:space:]]+(skip link|derivable base domain)/ { if (!open) bad=1; seen++ }
  END { exit (bad || open || blocks != 2 || !seen) }
' "$INDEX" || fail "Erynoa header, skip script or stylesheets not wrapped in [[ if .ErynoaDomain ]] (exactly two wrappers)"
for css in 1.1.4/erynoa-header.v1.css ragfit-monitor-header.css; do
  grep -qF "public/build/img/ragfit/erynoa/$css\"" "$INDEX" || fail "$css is not linked in $INDEX"
done
# Self-hosted only: no external URL in the stylesheets.
! grep -nE 'url\((["'\'']?)(https?:)?//' "$D/1.1.4/erynoa-header.v1.css" "$D/ragfit-monitor-header.css" || fail "external URL in CSS"
echo "ok: Erynoa header 1.1.4 (checksums, file set, markup in $(basename "$INDEX"))"
