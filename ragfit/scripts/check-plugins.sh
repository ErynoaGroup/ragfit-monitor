#!/usr/bin/env bash
# Fails if the repository config preinstalls plugins, or if the given image
# contains a plugin ID or version that is not pinned in ragfit/plugins-allowlist.txt.
set -euo pipefail
ALLOW=ragfit/plugins-allowlist.txt
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
# Top-level plugin.json files only: "<id> <version>" per plugin.
found=$(find "$tmp/usr/share/grafana/data/plugins-bundled" "$tmp/var/lib/grafana/plugins" -mindepth 2 -maxdepth 2 -name plugin.json -exec jq -r '"\(.id // "") \(.info.version // "")"' {} + | sort -u)
ids=$(echo "$found" | awk 'NF {print $1}' | sort -u)
bad=0
while read -r id ver; do
  [ -n "$id" ] || continue
  pin=$(grep -v '^#' "$ALLOW" | awk -v i="$id" '$1==i {print $2}')
  if [ -z "$pin" ]; then echo "NOT ALLOWED: $id"; bad=1
  elif [ "$pin" != "$ver" ]; then echo "VERSION MISMATCH: $id $ver (pinned $pin)"; bad=1
  else echo "allowed: $id $ver"; fi
done <<< "$found"
[ -n "$ids" ] || echo "no external plugins in image"
exit $bad
