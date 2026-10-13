#!/usr/bin/env bash
# Downloads every pinned plugin for one architecture from the public catalog,
# verifies the package SHA-256 against ragfit/plugins-allowlist.txt and unpacks it.
#   fetch-plugins.sh <arm64|amd64> <out-dir>
# The output directory is baked into the image as /usr/share/grafana/data/plugins-bundled,
# so nothing is installed at runtime.
set -euo pipefail

# Every entry must start with "<id>/" (plain string prefix, not a regex). Names with a
# leading '/', '.' or '..' segments, '//' or an empty name are rejected, as are symlinks.
check_zip() {
  local zip="$1" id="$2" names long bad
  case "$id" in ""|*/*|.|..) echo "INVALID plugin id: $id"; return 1 ;; esac
  names=$(zipinfo -1 "$zip") || { echo "UNREADABLE package for $id"; return 1; }
  long=$(zipinfo "$zip") || { echo "UNREADABLE package for $id"; return 1; }
  bad=$(awk -v p="$id/" '
    $0 == "" || substr($0, 1, 1) == "/" || index($0, p) != 1 || index($0, "//") ||
    $0 ~ /(^|\/)\.\.?(\/|$)/ { print "  " ($0 == "" ? "<empty name>" : $0) }' <<< "$names")
  if [ -n "$bad" ]; then echo "UNEXPECTED PATH in $id package:"; echo "$bad"; return 1; fi
  if grep -q '^l' <<< "$long"; then echo "SYMLINK in $id package"; return 1; fi
}
# Test hook: fetch-plugins.sh --check-zip <zip> <id>
if [ "${1:-}" = "--check-zip" ]; then check_zip "${2:?zip}" "${3:?id}"; exit $?; fi

ARCH="${1:?arch (arm64|amd64)}"; OUT="${2:?output dir}"
ALLOW="${PLUGINS_ALLOWLIST:-ragfit/plugins-allowlist.txt}"
case "$ARCH" in arm64) col=3 ;; amd64) col=4 ;; *) echo "unsupported arch: $ARCH"; exit 1 ;; esac
[ ! -e "$OUT" ] || [ -z "$(find "$OUT" -mindepth 1 -print -quit)" ] || { echo "output dir not empty: $OUT"; exit 1; }
mkdir -p "$OUT"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
while read -r line; do
  id=$(awk '{print $1}' <<< "$line"); ver=$(awk '{print $2}' <<< "$line"); want=$(awk -v c="$col" '{print $c}' <<< "$line")
  zip="$tmp/$id-$ver-$ARCH.zip"
  curl -fsSL --retry 3 "https://grafana.com/api/plugins/$id/versions/$ver/download?os=linux&arch=$ARCH" -o "$zip"
  got=$(sha256sum "$zip" | cut -d' ' -f1)
  [ "$got" = "$want" ] || { echo "CHECKSUM MISMATCH: $id $ver linux-$ARCH got $got, pinned $want"; exit 1; }
  check_zip "$zip" "$id"
  unzip -q "$zip" -d "$OUT"
  echo "verified and unpacked: $id $ver linux-$ARCH $got"
done < <(grep -v '^#' "$ALLOW" | awk 'NF && $5 != "LicenseRef-proprietary"')
REQUIRE_PINNED=1 "$(dirname "$0")/check-plugins.sh" --dir "$OUT"
