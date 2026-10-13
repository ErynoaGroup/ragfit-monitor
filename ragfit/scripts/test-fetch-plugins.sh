#!/usr/bin/env bash
# Offline tests for the package path checks in fetch-plugins.sh (no download).
set -uo pipefail
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail=0
run() { # name expected-exit zip id
  ragfit/scripts/fetch-plugins.sh --check-zip "$3" "$4" > "$tmp/out" 2>&1; got=$?
  if [ "$got" -eq "$2" ]; then echo "ok   $1"; else echo "FAIL $1 (exit $got, want $2)"; cat "$tmp/out"; fail=1; fi
}
mkz() { # zip-name entry... ("name@link" makes a symlink entry)
  python3 - "$tmp/$1" "${@:2}" <<'PY'
import sys, zipfile
with zipfile.ZipFile(sys.argv[1], "w") as z:
    for e in sys.argv[2:]:
        if e.endswith("@link"):
            i = zipfile.ZipInfo(e[:-5]); i.external_attr = 0o120777 << 16
            z.writestr(i, "/etc/passwd")
        else:
            z.writestr(e, "{}")
PY
}
mkz good.zip example.app/plugin.json example.app/dist/module.js
run "entries under the id pass" 0 "$tmp/good.zip" example.app
mkz dotid.zip exampleXapp/plugin.json
run "dot in id is not a regex wildcard" 1 "$tmp/dotid.zip" example.app
mkz prefix.zip example.app-evil/plugin.json
run "longer id with same prefix fails" 1 "$tmp/prefix.zip" example.app
mkz extra.zip example.app/plugin.json other/plugin.json
run "extra top-level dir fails" 1 "$tmp/extra.zip" example.app
mkz trav.zip example.app/../x
run "path traversal fails" 1 "$tmp/trav.zip" example.app
mkz link.zip example.app/plugin.json example.app/link@link
run "symlink entry fails" 1 "$tmp/link.zip" example.app
mkz abs.zip example.app/plugin.json /etc/evil
run "absolute path fails" 1 "$tmp/abs.zip" example.app
mkz absid.zip /example.app/plugin.json
run "absolute path under the id fails" 1 "$tmp/absid.zip" example.app
mkz dot.zip ./example.app/plugin.json
run "leading ./ fails" 1 "$tmp/dot.zip" example.app
mkz dotmid.zip example.app/./plugin.json
run "./ segment fails" 1 "$tmp/dotmid.zip" example.app
mkz dslash.zip example.app//plugin.json
run "double slash fails" 1 "$tmp/dslash.zip" example.app
mkz lead2.zip //etc/evil
run "leading // fails" 1 "$tmp/lead2.zip" example.app
mkz trav2.zip example.app/a/../../x
run "nested .. fails" 1 "$tmp/trav2.zip" example.app
mkz bare.zip example.app
run "entry equal to the id without slash fails" 1 "$tmp/bare.zip" example.app
mkz dots.zip example.app/a..b.json
run "dots inside a name pass" 0 "$tmp/dots.zip" example.app
echo garbage > "$tmp/broken.zip"
run "unreadable package fails" 1 "$tmp/broken.zip" example.app
exit $fail
