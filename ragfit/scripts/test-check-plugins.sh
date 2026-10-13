#!/usr/bin/env bash
# Tests for check-plugins.sh --dir, including nested plugin.json files.
set -uo pipefail
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
export PLUGINS_ALLOWLIST="$tmp/allow.txt"
printf '# test\nexample-app 1.0.0 x x Apache-2.0\nexample-nested-panel 1.0.0 x x Apache-2.0\n' > "$PLUGINS_ALLOWLIST"
mk() { mkdir -p "$(dirname "$1")"; printf '{"id":"%s","info":{"version":"%s"}}\n' "$2" "$3" > "$1"; }
fail=0
run() { # name expected-exit dir (REQUIRE_PINNED is passed through)
  ragfit/scripts/check-plugins.sh --dir "$3" > "$tmp/out" 2>&1; got=$?
  if [ "$got" -eq "$2" ]; then echo "ok   $1"; else echo "FAIL $1 (exit $got, want $2)"; cat "$tmp/out"; fail=1; fi
}
mk "$tmp/c1/example-app/plugin.json" example-app 1.0.0
run "top-level allowed" 0 "$tmp/c1"
mk "$tmp/c2/example-app/plugin.json" example-app 1.0.0
mk "$tmp/c2/example-app/panels/nested/plugin.json" example-nested-panel 1.0.0
run "nested allowed" 0 "$tmp/c2"
mk "$tmp/c3/example-app/plugin.json" example-app 1.0.0
mk "$tmp/c3/example-app/datasource/plugin.json" unknown-nested-ds 1.0.0
run "nested unknown fails" 1 "$tmp/c3"
mk "$tmp/c4/example-app/plugin.json" example-app 1.0.0
mk "$tmp/c4/example-app/a/b/c/plugin.json" example-nested-panel 2.0.0
run "nested version mismatch fails" 1 "$tmp/c4"
mk "$tmp/c5/other-plugin/plugin.json" other-plugin 1.0.0
run "top-level unknown fails" 1 "$tmp/c5"
mk "$tmp/c6/example-app/plugin.json" example-app 1.0.1
run "top-level version mismatch fails" 1 "$tmp/c6"
mkdir -p "$tmp/c7/x"; echo '{"info":{"version":"1"}}' > "$tmp/c7/x/plugin.json"
run "missing id fails" 1 "$tmp/c7"
mkdir -p "$tmp/c8"
run "empty dir passes" 0 "$tmp/c8"
mk "$tmp/bad/other-plugin/plugin.json" other-plugin 1.0.0
mk "$tmp/c9/example-app/plugin.json" example-app 1.0.0
ln -s "$tmp/bad/other-plugin" "$tmp/c9/linked-plugin"
run "symlinked plugin dir fails" 1 "$tmp/c9"
mkdir -p "$tmp/c10/example-app"
ln -s "$tmp/bad/other-plugin/plugin.json" "$tmp/c10/example-app/plugin.json"
run "symlinked plugin.json fails" 1 "$tmp/c10"
mkdir -p "$tmp/c11/example-app"; echo '{"id": "example-app", "info": ' > "$tmp/c11/example-app/plugin.json"
run "broken plugin.json fails" 1 "$tmp/c11"
mkdir -p "$tmp/c12/example-app"; echo '["example-app"]' > "$tmp/c12/example-app/plugin.json"
run "non-object plugin.json fails" 1 "$tmp/c12"
REQUIRE_PINNED=1 run "required: all pinned present passes" 0 "$tmp/c2"
REQUIRE_PINNED=1 run "required: pinned plugin missing fails" 1 "$tmp/c1"
REQUIRE_PINNED=1 run "required: empty dir fails" 1 "$tmp/c8"
exit $fail
