#!/usr/bin/env bash
# Verifies RagFit | Monitor license notices, non-enterprise build invariant,
# origin wording rules, and Erynoa shared top-bar header 1.1.4.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

for f in LICENSE LICENSING.md NOTICE.md MODIFICATIONS.md TRADEMARKS.md; do
  test -f "$f" || { echo "missing license/notice file: $f" >&2; exit 1; }
done

grep -Eq 'IsEnterprise( bool)? = false' pkg/extensions/main.go || {
  echo "IsEnterprise = false check failed" >&2
  exit 1
}

if grep -rnE 'GO_BUILD_TAGS=[a-z,]*enterprise|WIRE_TAGS=[a-z,]*enterprise|-tags[= ][a-z,]*enterprise' ragfit .github; then
  echo "enterprise build tag must not be used" >&2
  exit 1
fi

if grep -rniI 'based on grafana' README.md ragfit --exclude="verify-branding.sh"; then
  echo "origin wording 'based on grafana' only permitted in license files" >&2
  exit 1
fi

./ragfit/scripts/check-erynoa-header.sh
echo "verify-branding: ok"
