#!/usr/bin/env bash
# Verifies a plugin signature offline: MANIFEST.txt must be a valid PGP clear-signed manifest from the
# plugin signing key, name the expected id and version, and list every file of the plugin directory
# with a matching SHA-256 (no missing, no extra files).
#   verify-plugin-signature.sh <plugin-dir> <id> <version>
# The default key is the static plugin signing key in
# pkg/plugins/manager/signature/statickey/static_retriever.go, pinned by its primary key fingerprint
# (STATIC_KEY_FPR). PLUGIN_SIGNING_KEY=<file> overrides the key (tests) and then requires
# PLUGIN_SIGNING_FPR=<primary fingerprint>. The signature must come from exactly that primary key.
set -euo pipefail
STATIC_KEY_FPR=F33B25B691074E84636570F37E4D0C6A708866E7
dir="${1:?plugin dir}"; id="${2:?id}"; ver="${3:?version}"
m="$dir/MANIFEST.txt"
[ -f "$m" ] && [ ! -L "$m" ] || { echo "UNSIGNED: $id has no MANIFEST.txt"; exit 1; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
export GNUPGHOME="$tmp/gnupg"; mkdir -m 700 "$GNUPGHOME"
want_fpr=$STATIC_KEY_FPR
if [ -n "${PLUGIN_SIGNING_KEY:-}" ]; then
  want_fpr="${PLUGIN_SIGNING_FPR:?PLUGIN_SIGNING_FPR is required with PLUGIN_SIGNING_KEY}"
  cp "$PLUGIN_SIGNING_KEY" "$tmp/key.asc"
else
  src=pkg/plugins/manager/signature/statickey/static_retriever.go
  sed -n '/-----BEGIN PGP PUBLIC KEY BLOCK-----/,/-----END PGP PUBLIC KEY BLOCK-----/p' "$src" | sed 's/^const publicKeyText = `//; s/^[[:space:]]*$//' > "$tmp/key.asc"
fi
gpg --batch --quiet --import "$tmp/key.asc" 2>/dev/null || { echo "CANNOT IMPORT signing key"; exit 1; }
have_fpr=$(gpg --batch --with-colons --fingerprint 2>/dev/null | awk -F: '$1=="pub"{p=1; next} p && $1=="fpr"{print $10; p=0}')
[ "$have_fpr" = "$want_fpr" ] || { echo "SIGNING KEY FINGERPRINT MISMATCH: expected $want_fpr, key file has ${have_fpr:-none}"; exit 1; }
# Only the verified cleartext is used from here on.
if ! gpg --batch --status-fd 3 --output "$tmp/manifest.json" --decrypt "$m" 3> "$tmp/status" 2>/dev/null \
   || [ "$(awk '$2=="VALIDSIG"{print $NF}' "$tmp/status")" != "$want_fpr" ]; then
  echo "BAD SIGNATURE: $id MANIFEST.txt"; exit 1
fi
jq -e 'type == "object" and (.files | type == "object")' "$tmp/manifest.json" > /dev/null 2>&1 || { echo "INVALID MANIFEST: $id"; exit 1; }
[ "$(jq -r .plugin "$tmp/manifest.json")" = "$id" ] || { echo "MANIFEST ID MISMATCH: $id"; exit 1; }
[ "$(jq -r .version "$tmp/manifest.json")" = "$ver" ] || { echo "MANIFEST VERSION MISMATCH: $id $ver"; exit 1; }
jq -r '.files | to_entries[] | "\(.value)  \(.key)"' "$tmp/manifest.json" | sort -k2 > "$tmp/want"
(cd "$dir" && find . -type f ! -path ./MANIFEST.txt -printf '%P\n' | sort | while read -r f; do printf '%s  %s\n' "$(sha256sum "$f" | cut -d' ' -f1)" "$f"; done) > "$tmp/have"
if ! diff -q "$tmp/want" "$tmp/have" > /dev/null; then
  echo "MANIFEST FILES MISMATCH: $id"; diff "$tmp/want" "$tmp/have" | grep '^[<>]' | sed 's/^</  manifest:/; s/^>/  on disk: /' | head -20
  exit 1
fi
echo "signed: $id $ver ($(jq -r '.signatureType // "unknown"' "$tmp/manifest.json"), $(jq -r '.files | length' "$tmp/manifest.json") files)"
