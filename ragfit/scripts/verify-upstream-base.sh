#!/usr/bin/env bash
# Own additions are allowed under ragfit/, .github/, .claude/, public/img/ragfit/,
# docs/ARCHITECTURE.md, docs/work/**, erynoa.md, flake.nix, flake.lock, justfile,
# MODIFICATIONS.md and TRADEMARKS.md.
# Modified or removed upstream files must be listed in ragfit/modified-upstream-files.txt.
# Verifies that a ragfit-monitor ref (or dirty working tree) differs from upstream v13.2.4 only in our own files.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
REF="${1:-HEAD}"
UP_TAG=v13.2.4
UP_COMMIT=af4a33e3786594ad72f72d97e6744010330c2977
if ! git rev-parse -q --verify "refs/tags/upstream-$UP_TAG^{commit}" >/dev/null 2>&1; then
  git fetch -q --depth 1 https://github.com/grafana/grafana "refs/tags/$UP_TAG:refs/tags/upstream-$UP_TAG"
fi
test "$(git rev-parse "upstream-$UP_TAG^{commit}")" = "$UP_COMMIT" || { echo "upstream tag SHA mismatch"; exit 1; }
echo "upstream $UP_TAG = $UP_COMMIT (ok)"

if [ "$REF" = "HEAD" ] && [ -n "$(git status --porcelain)" ]; then
  TMP_IDX=$(mktemp)
  trap 'rm -f "$TMP_IDX"' EXIT
  cp .git/index "$TMP_IDX"
  GIT_INDEX_FILE="$TMP_IDX" git add -A
  TREE=$(GIT_INDEX_FILE="$TMP_IDX" git write-tree)
else
  TREE="$REF^{tree}"
fi

DIFF=$(git diff --no-renames --name-status "upstream-$UP_TAG^{tree}" "$TREE" | grep -v -E $'^D\t\\.github/' || true)
echo "$DIFF"
UNEXPECTED=$(echo "$DIFF" | grep -v -E $'^(A\t(MODIFICATIONS\\.md|TRADEMARKS\\.md|erynoa\\.md|flake\\.nix|flake\\.lock|justfile)|M\tREADME\\.md|A\t(ragfit|\\.github|\\.claude|public/img/ragfit|docs/work)/.*|A\tdocs/ARCHITECTURE\\.md)$' || true)
LISTED=ragfit/modified-upstream-files.txt
if [ -f "$LISTED" ]; then
  UNEXPECTED=$(echo "$UNEXPECTED" | grep -v -x -F -f <(grep -v '^#' "$LISTED" | awk 'NF {print "M\t"$0; print "A\t"$0; print "D\t"$0}') || true)
fi
[ -z "$UNEXPECTED" ] && echo "OK: only own files and listed upstream modifications differ" || { echo "UNEXPECTED differences above"; exit 1; }
