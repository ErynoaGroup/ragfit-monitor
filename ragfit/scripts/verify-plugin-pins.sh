#!/usr/bin/env bash
# Downloads every pinned plugin from the public catalog and checks version, id,
# license file and SHA-256 of the linux-arm64 and linux-amd64 packages.
set -euo pipefail
ALLOW=ragfit/plugins-allowlist.txt
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
bad=0
while read -r id ver arm64 amd64 lic; do
  for pair in "arm64:$arm64" "amd64:$amd64"; do
    arch=${pair%%:*}; want=${pair#*:}; zip="$tmp/$id-$ver-$arch.zip"
    curl -fsSL "https://grafana.com/api/plugins/$id/versions/$ver/download?os=linux&arch=$arch" -o "$zip"
    got=$(sha256sum "$zip" | cut -d' ' -f1)
    if [ "$got" != "$want" ]; then echo "CHECKSUM MISMATCH: $id $ver linux-$arch $got"; bad=1; continue; fi
    meta=$(unzip -p "$zip" "$id/plugin.json" | jq -r '"\(.id) \(.info.version)"')
    [ "$meta" = "$id $ver" ] || { echo "METADATA MISMATCH: $id $ver linux-$arch: $meta"; bad=1; }
    unzip -p "$zip" "$id/LICENSE" | head -3 | grep -q "Apache License" || [ "$lic" != "Apache-2.0" ] || { echo "LICENSE MISMATCH: $id"; bad=1; }
    echo "ok: $id $ver linux-$arch $got $lic"
  done
done < <(grep -v '^#' "$ALLOW" | grep .)
exit $bad
