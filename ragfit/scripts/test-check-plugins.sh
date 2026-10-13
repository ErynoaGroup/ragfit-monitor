#!/usr/bin/env bash
# Tests for check-plugins.sh --dir: allowlist, nested plugin.json, symlinks, license/type policy,
# sdk-only proprietary backends and signatures. Offline: a throwaway signing key and tiny Go binaries.
set -uo pipefail
repo=$(pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
export GNUPGHOME="$tmp/signer"; mkdir -m 700 "$GNUPGHOME"
gpg --batch --quiet --passphrase '' --quick-gen-key "plugin test signer" default default never 2>/dev/null
gpg --batch --quiet --armor --export > "$tmp/key.asc"
export PLUGIN_SIGNING_KEY="$tmp/key.asc"
export PLUGINS_ALLOWLIST="$tmp/allow.txt"
cat > "$PLUGINS_ALLOWLIST" <<'A'
# test
example-app 1.0.0 x x Apache-2.0 frontend
example-nested-panel 1.0.0 x x Apache-2.0 frontend
example-backend 1.0.0 x x MIT backend
private-ok 1.0.0 - - LicenseRef-proprietary backend sdk-only
private-nomarker 1.0.0 - - LicenseRef-proprietary backend
private-frontend 1.0.0 - - LicenseRef-proprietary frontend sdk-only
gpl2-app 1.0.0 x x GPL-2.0-only frontend
typeless-app 1.0.0 x x Apache-2.0
A
mk() { mkdir -p "$(dirname "$1")"; printf '{"id":"%s","info":{"version":"%s"}%s}\n' "$2" "$3" "${4:-}" > "$1"; }
lic() { printf 'Apache License\nVersion 2.0\n' > "$1/LICENSE"; }
sign() { # sign <plugin-dir>: writes MANIFEST.txt over all files currently in the directory
  local d=$1 id ver
  id=$(jq -r .id "$d/plugin.json"); ver=$(jq -r .info.version "$d/plugin.json")
  (cd "$d" && find . -type f ! -path ./MANIFEST.txt -printf '%P\n' | sort | while read -r f; do
     jq -n --arg f "$f" --arg h "$(sha256sum "$f" | cut -d' ' -f1)" '{($f): $h}'; done | jq -s 'add // {}') > "$tmp/files.json"
  jq -n --arg id "$id" --arg v "$ver" --slurpfile f "$tmp/files.json" \
    '{manifestVersion: "2.0.0", signatureType: "private", plugin: $id, version: $v, files: $f[0]}' \
    | gpg --batch --quiet --clearsign > "$d/MANIFEST.txt"
}
gobin() { # gobin <out> [module...] : tiny binary depending on local stand-ins for the given modules
  local out=$1 src="$tmp/go-$RANDOM" i=0 imports="" calls="" m; shift
  mkdir -p "$src"; printf 'module example.invalid/plugin\n\ngo 1.21\n' > "$src/go.mod"
  for m in "$@"; do
    [ -n "$m" ] || continue
    i=$((i+1)); mkdir -p "$src/dep$i"
    printf 'module %s\n\ngo 1.21\n' "$m" > "$src/dep$i/go.mod"; printf 'package dep\n\nfunc F() {}\n' > "$src/dep$i/dep.go"
    printf 'require %s v0.0.0\nreplace %s => ./dep%s\n' "$m" "$m" "$i" >> "$src/go.mod"
    imports="$imports\n\td$i \"$m\""; calls="$calls d$i.F();"
  done
  if [ -n "$imports" ]; then printf "package main\n\nimport ($imports\n)\n\nfunc main() { $calls }\n" > "$src/main.go"
  else printf 'package main\n\nfunc main() {}\n' > "$src/main.go"; fi
  (cd "$src" && GOFLAGS=-mod=mod go build -o "$out" .) || { echo "FAIL build test binary"; exit 1; }
}
fail=0
run() { # name expected-exit dir
  (cd "$repo" && ragfit/scripts/check-plugins.sh --dir "$3") > "$tmp/out" 2>&1; got=$?
  if [ "$got" -eq "$2" ]; then echo "ok   $1: $(grep -E "^[A-Z]{3,}" "$tmp/out" | head -1 | cut -c1-90)"; else echo "FAIL $1 (exit $got, want $2)"; cat "$tmp/out"; fail=1; fi
}
signed_app() { mk "$1/plugin.json" "$2" "$3" "${4:-}"; lic "$1"; sign "$1"; }

# Allowlist and structure
signed_app "$tmp/c1/example-app" example-app 1.0.0
run "top-level allowed (signed, licensed)" 0 "$tmp/c1"
mk "$tmp/c2/example-app/plugin.json" example-app 1.0.0; mk "$tmp/c2/example-app/panels/nested/plugin.json" example-nested-panel 1.0.0
lic "$tmp/c2/example-app"; sign "$tmp/c2/example-app"
run "nested allowed" 0 "$tmp/c2"
mk "$tmp/c3/example-app/plugin.json" example-app 1.0.0; mk "$tmp/c3/example-app/datasource/plugin.json" unknown-nested-ds 1.0.0
lic "$tmp/c3/example-app"; sign "$tmp/c3/example-app"
run "nested unknown fails" 1 "$tmp/c3"
mk "$tmp/c4/example-app/plugin.json" example-app 1.0.0; mk "$tmp/c4/example-app/a/b/c/plugin.json" example-nested-panel 2.0.0
lic "$tmp/c4/example-app"; sign "$tmp/c4/example-app"
run "nested version mismatch fails" 1 "$tmp/c4"
signed_app "$tmp/c5/other-plugin" other-plugin 1.0.0
run "top-level unknown fails" 1 "$tmp/c5"
signed_app "$tmp/c6/example-app" example-app 1.0.1
run "top-level version mismatch fails" 1 "$tmp/c6"
mkdir -p "$tmp/c7/x"; echo '{"info":{"version":"1"}}' > "$tmp/c7/x/plugin.json"
run "missing id fails" 1 "$tmp/c7"
mkdir -p "$tmp/c8"
run "empty dir passes" 0 "$tmp/c8"
signed_app "$tmp/bad/other-plugin" other-plugin 1.0.0
signed_app "$tmp/c9/example-app" example-app 1.0.0
ln -s "$tmp/bad/other-plugin" "$tmp/c9/linked-plugin"
run "symlinked plugin dir fails" 1 "$tmp/c9"
mkdir -p "$tmp/c10/example-app"; ln -s "$tmp/bad/other-plugin/plugin.json" "$tmp/c10/example-app/plugin.json"
run "symlinked plugin.json fails" 1 "$tmp/c10"
mkdir -p "$tmp/c11/example-app"; echo '{"id": "example-app", "info": ' > "$tmp/c11/example-app/plugin.json"
run "broken plugin.json fails" 1 "$tmp/c11"
mkdir -p "$tmp/c12/example-app"; echo '["example-app"]' > "$tmp/c12/example-app/plugin.json"
run "non-object plugin.json fails" 1 "$tmp/c12"

# Signature
mk "$tmp/s1/example-app/plugin.json" example-app 1.0.0; lic "$tmp/s1/example-app"
run "unsigned plugin fails" 1 "$tmp/s1"
signed_app "$tmp/s2/example-app" example-app 1.0.0; echo extra >> "$tmp/s2/example-app/LICENSE"
run "file changed after signing fails" 1 "$tmp/s2"
signed_app "$tmp/s3/example-app" example-app 1.0.0; echo new > "$tmp/s3/example-app/added.js"
run "file added after signing fails" 1 "$tmp/s3"
signed_app "$tmp/s4/example-app" example-app 1.0.0; sed -i 's/"1.0.0"/"1.0.1"/' "$tmp/s4/example-app/MANIFEST.txt"
run "edited manifest (bad signature) fails" 1 "$tmp/s4"

# License and type policy
mk "$tmp/l1/example-app/plugin.json" example-app 1.0.0; sign "$tmp/l1/example-app"
run "missing LICENSE file fails" 1 "$tmp/l1"
signed_app "$tmp/l2/gpl2-app" gpl2-app 1.0.0
run "incompatible license fails" 1 "$tmp/l2"
signed_app "$tmp/l3/typeless-app" typeless-app 1.0.0
run "allowlist entry without type fails" 1 "$tmp/l3"
signed_app "$tmp/l4/example-app" example-app 1.0.0 ',"backend":true'
run "type mismatch (frontend entry, backend plugin) fails" 1 "$tmp/l4"
mk "$tmp/l5/example-backend/plugin.json" example-backend 1.0.0 ',"backend":true'; lic "$tmp/l5/example-backend"
gobin "$tmp/l5/example-backend/gpx_example_linux_amd64" ""; sign "$tmp/l5/example-backend"
run "open-source backend plugin passes" 0 "$tmp/l5"

# Proprietary backend plugins (sdk-only)
pb() { # pb <dir> <id> <plugin.json extra> <modules...|none>
  local d=$1 id=$2 extra=$3; shift 3
  mk "$d/$id/plugin.json" "$id" 1.0.0 "$extra"
  [ "${1:-}" = none ] || gobin "$d/$id/gpx_private_linux_amd64" "$@"
  sign "$d/$id"
}
B=',"backend":true'; SDK=github.com/grafana/grafana-plugin-sdk-go
pb "$tmp/p1" private-ok "$B" "$SDK"
run "proprietary sdk-only backend passes" 0 "$tmp/p1"
pb "$tmp/p2" private-ok "$B" "$SDK" github.com/grafana/grafana/pkg/plugins
run "proprietary backend with grafana server module fails" 1 "$tmp/p2"
pb "$tmp/p3" private-ok "$B" "$SDK" github.com/grafana/grafana
run "proprietary backend with grafana root module fails" 1 "$tmp/p3"
pb "$tmp/p4" private-ok "$B" "$SDK" github.com/grafana/alerting
run "proprietary backend with other denied module fails" 1 "$tmp/p4"
pb "$tmp/p5" private-ok "$B" ""
run "proprietary backend not built with the SDK fails" 1 "$tmp/p5"
pb "$tmp/p10" private-ok "$B" "$SDK" github.com/grafana/grafana-foo
run "sibling module with the same prefix is not denied" 0 "$tmp/p10"
pb "$tmp/p6" private-ok "$B" none
run "proprietary backend without binary fails" 1 "$tmp/p6"
pb "$tmp/p7" private-nomarker "$B" "$SDK"
run "proprietary backend without sdk-only marker fails" 1 "$tmp/p7"
pb "$tmp/p8" private-frontend '' none
run "proprietary frontend plugin fails" 1 "$tmp/p8"
mk "$tmp/p9/private-ok/plugin.json" private-ok 1.0.0 ',"backend":true'; gobin "$tmp/p9/private-ok/gpx_private_linux_amd64" "$SDK"
run "unsigned proprietary backend fails" 1 "$tmp/p9"

# REQUIRE_PINNED
printf 'example-app 1.0.0 x x Apache-2.0 frontend\nprivate-ok 1.0.0 - - LicenseRef-proprietary backend sdk-only\n' > "$tmp/allow2.txt"
PLUGINS_ALLOWLIST="$tmp/allow2.txt" REQUIRE_PINNED=1 run "required: public entries only (proprietary added privately)" 0 "$tmp/c1"
PLUGINS_ALLOWLIST="$tmp/allow2.txt" REQUIRE_PINNED=all run "required all: missing proprietary plugin fails" 1 "$tmp/c1"
REQUIRE_PINNED=1 run "required: pinned plugin missing fails" 1 "$tmp/c8"
exit $fail
