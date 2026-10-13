#!/usr/bin/env bash
# Fails if the repository config preinstalls plugins, or if the given image
# contains a plugin ID that is not in ragfit/plugins-allowlist.txt.
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
ids=$(find "$tmp" -name plugin.json -exec jq -r '.id // empty' {} + | sort -u)
bad=0
for id in $ids; do
  if grep -qxF "$id" <(grep -v '^#' "$ALLOW"); then echo "allowed: $id"; else echo "NOT ALLOWED: $id"; bad=1; fi
done
[ -n "$ids" ] || echo "no external plugins in image"
exit $bad
