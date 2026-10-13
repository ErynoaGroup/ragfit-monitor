#!/usr/bin/env bash
# Offline tests for plugin-licenses.sh (a tiny backend binary without dependencies, no downloads).
set -uo pipefail
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail=0
run() { # name expected-rc plugins-dir
  ragfit/scripts/plugin-licenses.sh "$3" "$tmp/out-$RANDOM" > "$tmp/log" 2>&1; got=$?
  if [ "$got" -eq "$2" ]; then echo "ok   $1"; else echo "FAIL $1 (rc $got, want $2)"; cat "$tmp/log"; fail=1; fi
}
mkdir -p "$tmp/src"
printf 'module example.invalid/backend\n\ngo 1.21\n' > "$tmp/src/go.mod"
printf 'package main\n\nfunc main() {}\n' > "$tmp/src/main.go"
(cd "$tmp/src" && GOFLAGS=-mod=mod go build -o "$tmp/gpx_example" .) || { echo "FAIL build test binary"; exit 1; }
mkdir -p "$tmp/p1/example-app"; cp "$tmp/gpx_example" "$tmp/p1/example-app/gpx_example_linux_amd64"
printf 'Apache License\nVersion 2.0\n' > "$tmp/p1/example-app/LICENSE"
run "plugin with license and backend binary passes" 0 "$tmp/p1"
mkdir -p "$tmp/p2/example-app"; cp "$tmp/gpx_example" "$tmp/p2/example-app/gpx_example_linux_amd64"
run "plugin without license file fails" 1 "$tmp/p2"
mkdir -p "$tmp/p3/example-app"; printf 'Apache License\n' > "$tmp/p3/example-app/LICENSE"; echo garbage > "$tmp/p3/example-app/gpx_broken"
run "unreadable backend binary fails" 1 "$tmp/p3"
exit $fail
