#!/usr/bin/env bash
# Generates THIRD_PARTY_NOTICES and license texts for Go and npm dependencies
# into the directory given as $1 (default: dist/licenses). Fails on forbidden licenses.
set -euo pipefail
OUT="${1:-dist/licenses}"
mkdir -p "$OUT/go" "$OUT/npm"
FORBIDDEN_GO="forbidden,unknown"
IGNORES=(--ignore github.com/grafana/grafana)
while read -r mod _; do IGNORES+=(--ignore "$mod"); done < <(grep -v '^#' ragfit/license-exceptions.txt | grep .)
go run github.com/google/go-licenses/v2@v2.0.1 check ./pkg/... --disallowed_types="$FORBIDDEN_GO" "${IGNORES[@]}"
# report/save exit non-zero when a module ships no license file; the gate is "check" above.
# Unresolved modules are listed in THIRD_PARTY_NOTICES and must be reviewed.
go run github.com/google/go-licenses/v2@v2.0.1 report ./pkg/... --ignore github.com/grafana/grafana > "$OUT/go/licenses.csv" 2> "$OUT/go/report.log" || true
go run github.com/google/go-licenses/v2@v2.0.1 save ./pkg/... "${IGNORES[@]}" --save_path "$OUT/go/texts" --force 2>> "$OUT/go/report.log" || true
grep -o "Did not find license for library .*" "$OUT/go/report.log" | sort -u > "$OUT/go/unresolved.txt" || true
test -s "$OUT/go/licenses.csv" || { echo "go-licenses report is empty"; exit 1; }
npx --yes license-checker-rseidelsohn@4.4.2 --production --excludePrivatePackages \
  --failOn 'UNLICENSED;UNKNOWN;SSPL-1.0;BUSL-1.1;Commercial' --csv --out "$OUT/npm/licenses.csv"
{
  echo "THIRD PARTY NOTICES for RagFit Monitor"
  echo "Generated $(date -u +%Y-%m-%d) from commit ${GITHUB_SHA:-local}."
  echo "Full license texts of Go modules: go/texts/. Upstream licensing: LICENSE, LICENSING.md, NOTICE.md."
  echo; echo "== Go modules (module,url,license) =="; cat "$OUT/go/licenses.csv"
  echo; echo "== Go modules without a detected license file (manual review) =="; cat "$OUT/go/unresolved.txt"
  echo; echo "== npm packages (production) =="; cat "$OUT/npm/licenses.csv"
} > "$OUT/THIRD_PARTY_NOTICES"
cp LICENSE LICENSING.md NOTICE.md MODIFICATIONS.md ragfit/license-exceptions.txt "$OUT/"
curl -fsSL https://www.gnu.org/licenses/agpl-3.0.txt -o "$OUT/AGPL-3.0.txt"
