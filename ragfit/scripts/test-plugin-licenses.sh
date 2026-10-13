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
# Build-info parser (go-buildinfo-deps.awk), fed with crafted `go version -m` output.
parse() { # name expected-rc expected-output(\n-separated, may be empty) input
  local o rc; o=$(printf '%b' "$4" | awk -f ragfit/scripts/go-buildinfo-deps.awk 2>"$tmp/perr"); rc=$?
  if [ "$rc" -eq "$2" ] && [ "$o" = "$(printf '%b' "$3")" ]; then echo "ok   parse: $1"
  else echo "FAIL parse: $1 (rc $rc, want $2)"; echo "$o"; cat "$tmp/perr"; fail=1; fi
}
H='gpx: go1.22.5\n\tpath\texample.invalid/backend\n\tmod\texample.invalid/backend\t(devel)\t\n'
B='\tbuild\t-compiler=gc\n'
parse "plain deps" 0 'a.invalid/x v1.0.0 h1:aaa=\nb.invalid/y v2.0.0 h1:bbb=' \
  "$H"'\tdep\ta.invalid/x\tv1.0.0\th1:aaa=\n\tdep\tb.invalid/y\tv2.0.0\th1:bbb=\n'"$B"
parse "consecutive deps, second replaced" 0 'a.invalid/x v1.0.0 h1:aaa=\nfork.invalid/y v2.1.0 h1:fff=\nc.invalid/z v3.0.0 h1:ccc=' \
  "$H"'\tdep\ta.invalid/x\tv1.0.0\th1:aaa=\n\tdep\tb.invalid/y\tv2.0.0\n\t=>\tfork.invalid/y\tv2.1.0\th1:fff=\n\tdep\tc.invalid/z\tv3.0.0\th1:ccc=\n'"$B"
parse "consecutive deps, both replaced" 0 'fork.invalid/x v1.1.0 h1:f1=\nfork.invalid/y v2.1.0 h1:f2=' \
  "$H"'\tdep\ta.invalid/x\tv1.0.0\n\t=>\tfork.invalid/x\tv1.1.0\th1:f1=\n\tdep\tb.invalid/y\tv2.0.0\n\t=>\tfork.invalid/y\tv2.1.0\th1:f2=\n'"$B"
parse "replaced dep is last before build lines" 0 'fork.invalid/y v2.1.0 h1:fff=' \
  "$H"'\tdep\tb.invalid/y\tv2.0.0\n\t=>\tfork.invalid/y\tv2.1.0\th1:fff=\n'"$B"
parse "dep without hash and without replacement fails" 1 '' \
  "$H"'\tdep\ta.invalid/x\tv1.0.0\n\tdep\tb.invalid/y\tv2.0.0\th1:bbb=\n'"$B"
parse "local directory replacement fails" 1 '' \
  "$H"'\tdep\ta.invalid/x\tv1.0.0\n\t=>\t./local\t(devel)\t\n'"$B"
parse "replacement without dep fails" 1 '' "$H"'\t=>\tfork.invalid/y\tv2.1.0\th1:fff=\n'"$B"
parse "unknown line fails" 1 '' "$H"'\tdep\ta.invalid/x\tv1.0.0\th1:aaa=\n\tweird\tline\n'"$B"
parse "no build info fails" 1 '' 'gpx: go1.22.5\n'
parse "not go version output fails" 1 '' 'garbage\n'
exit $fail
