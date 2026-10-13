#!/usr/bin/env bash
# Own additions are allowed under ragfit/, .github/ and docs/; any change to upstream files must be listed here.
# Verifies that a ragfit-monitor ref differs from upstream v13.2.4 only in our own files.
set -euo pipefail
REF="${1:-HEAD}"
UP_TAG=v13.2.4
UP_COMMIT=af4a33e3786594ad72f72d97e6744010330c2977
git fetch -q --depth 1 https://github.com/grafana/grafana "refs/tags/$UP_TAG:refs/tags/upstream-$UP_TAG"
test "$(git rev-parse "upstream-$UP_TAG^{commit}")" = "$UP_COMMIT" || { echo "upstream tag SHA mismatch"; exit 1; }
echo "upstream $UP_TAG = $UP_COMMIT (ok)"
DIFF=$(git diff --no-renames --name-status "upstream-$UP_TAG^{tree}" "$REF^{tree}" | grep -v -E $'^D\t\\.github/' || true)
echo "$DIFF"
UNEXPECTED=$(echo "$DIFF" | grep -v -E $'^(A\tMODIFICATIONS\\.md|M\tREADME\\.md|A\tdocs/decisions/0001-mo-decisions\\.md|A\tdocs/plans/mo4-upgrade\\.md|A\t(ragfit|\\.github|docs)/.*)$' || true)
[ -z "$UNEXPECTED" ] && echo "OK: only own files differ (.github removed, README.md replaced, MODIFICATIONS.md and docs added)" || { echo "UNEXPECTED differences above"; exit 1; }
