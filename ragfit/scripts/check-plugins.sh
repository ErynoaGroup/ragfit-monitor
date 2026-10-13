#!/usr/bin/env bash
# Plugin policy check.
#   check-plugins.sh                 config check only (no preinstalled plugins)
#   check-plugins.sh <image>         config check, then every plugin.json in the image's plugin dirs
#   check-plugins.sh --dir <path>... check every plugin.json under the given directories
# Every plugin.json, top-level or nested inside another plugin, must have an id and
# version pinned in ragfit/plugins-allowlist.txt (override with PLUGINS_ALLOWLIST).
set -euo pipefail
ALLOW="${PLUGINS_ALLOWLIST:-ragfit/plugins-allowlist.txt}"

check_dirs() {
  local found bad=0 id ver pin file
  found=$(find "$@" -type f -name plugin.json 2>/dev/null | sort || true)
  if [ -z "$found" ]; then echo "no external plugins found"; return 0; fi
  while read -r file; do
    id=$(jq -r '.id // ""' "$file"); ver=$(jq -r '.info.version // ""' "$file")
    if [ -z "$id" ]; then echo "NO ID: $file"; bad=1; continue; fi
    pin=$(grep -v '^#' "$ALLOW" | awk -v i="$id" '$1==i {print $2}')
    if [ -z "$pin" ]; then echo "NOT ALLOWED: $id ($file)"; bad=1
    elif [ "$pin" != "$ver" ]; then echo "VERSION MISMATCH: $id $ver, pinned $pin ($file)"; bad=1
    else echo "allowed: $id $ver ($file)"; fi
  done <<< "$found"
  return $bad
}

if [ "${1:-}" = "--dir" ]; then shift; check_dirs "$@"; exit $?; fi

for key in preinstall preinstall_sync preinstall_async; do
  val=$(grep -E "^${key}[[:space:]]*=" conf/defaults.ini | head -1 | cut -d= -f2- | tr -d '[:space:]' || true)
  [ -z "$val" ] || { echo "conf/defaults.ini: $key must be empty, found: $val"; exit 1; }
done
IMAGE="${1:-}"
[ -n "$IMAGE" ] || { echo "config check ok (no image given)"; exit 0; }
tmp=$(mktemp -d); cid=$(docker create "$IMAGE")
trap 'docker rm -f "$cid" >/dev/null; rm -rf "$tmp"' EXIT
for d in /usr/share/grafana/data/plugins-bundled /var/lib/grafana/plugins; do
  mkdir -p "$tmp$d"; docker cp "$cid:$d/." "$tmp$d" 2>/dev/null || true
done
check_dirs "$tmp/usr/share/grafana/data/plugins-bundled" "$tmp/var/lib/grafana/plugins"
