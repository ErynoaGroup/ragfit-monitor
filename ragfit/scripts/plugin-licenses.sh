#!/usr/bin/env bash
# License bundle and gate for baked plugins, including the Go modules compiled into their backend binaries.
#   plugin-licenses.sh <plugins-dir> <out-dir>
# For every plugin directory: copies LICENSE*/NOTICE* and module.js.LICENSE.txt. For every backend
# binary (gpx_*): reads the embedded module list (go version -m), downloads each module from the Go
# module proxy, checks its hash against the hash embedded in the binary, copies its license files and
# fails on a missing license file or a forbidden license (AGPL/GPL/LGPL/SSPL/BUSL/commercial) unless the
# module is listed in ragfit/license-exceptions.txt.
set -euo pipefail
IN="${1:?plugins dir}"; OUT="${2:?output dir}"
EXC=ragfit/license-exceptions.txt
HERE=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$OUT"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
# go mod download runs outside any module so the repository go.mod does not interfere.
export GOFLAGS=-mod=mod
bad=0
excepted() { grep -v '^#' "$EXC" | awk '{print $1}' | grep -qxF -- "$1"; }
for pdir in "$IN"/*/; do
  id=$(basename "$pdir"); po="$OUT/$id"; mkdir -p "$po"
  found=0
  for f in "$pdir"LICENSE* "$pdir"NOTICE* "$pdir"module.js.LICENSE.txt; do
    [ -f "$f" ] && { cp "$f" "$po/"; found=1; }
  done
  [ "$found" = 1 ] || { echo "NO LICENSE FILE in plugin $id"; bad=1; }
  for bin in "$pdir"gpx_*; do
    [ -f "$bin" ] || continue
    go version -m "$bin" > "$tmp/mods" || { echo "CANNOT READ build info: $bin"; bad=1; continue; }
    # dep lines, with a following "=>" replacement taking precedence; fails closed (see the awk file).
    awk -f "$HERE/go-buildinfo-deps.awk" "$tmp/mods" > "$tmp/deps.raw" || { echo "UNPARSEABLE build info: $bin"; bad=1; continue; }
    sort -u "$tmp/deps.raw" > "$tmp/deps"
    : > "$po/go-modules.txt"
    while read -r mod ver sum; do
      j=$(cd "$tmp" && go mod download -json "$mod@$ver" 2>/dev/null) || { echo "DOWNLOAD FAILED: $mod $ver"; bad=1; continue; }
      dir=$(jq -r .Dir <<< "$j"); got=$(jq -r .Sum <<< "$j")
      if [ "$got" != "$sum" ]; then echo "HASH MISMATCH: $mod $ver binary $sum proxy $got"; bad=1; continue; fi
      md="$po/go/$mod"; mkdir -p "$md"
      lic=$(command find "$dir" -maxdepth 1 -type f \( -iname 'LICEN[CS]E*' -o -iname 'COPYING*' -o -iname 'NOTICE*' \) | sort)
      if [ -z "$lic" ]; then
        if excepted "$mod"; then echo "excepted (no license file): $mod"; else echo "NO LICENSE FILE: $mod $ver"; bad=1; fi
      fi
      while read -r f; do [ -n "$f" ] && cp "$f" "$md/"; done <<< "$lic"
      kind=unknown
      if [ -n "$lic" ]; then
        head=$( { while read -r f; do cat "$f"; done <<< "$lic"; } | head -c 4000 || true)
        case "$head" in
          *"GNU AFFERO GENERAL PUBLIC"*) kind=AGPL ;;
          *"GNU LESSER GENERAL PUBLIC"*) kind=LGPL ;;
          *"GNU GENERAL PUBLIC LICENSE"*) kind=GPL ;;
          *"Server Side Public License"*) kind=SSPL ;;
          *"Business Source License"*) kind=BUSL ;;
          *"Apache License"*) kind=Apache-2.0 ;;
          *"Mozilla Public License"*) kind=MPL-2.0 ;;
          *"Permission is hereby granted, free of charge"*) kind=MIT ;;
          *"Redistribution and use in source and binary forms"*) kind=BSD ;;
          *"ISC License"*|*"Permission to use, copy, modify, and/or distribute"*) kind=ISC ;;
        esac
      fi
      case "$kind" in
        AGPL|LGPL|GPL|SSPL|BUSL|unknown)
          if excepted "$mod"; then echo "excepted ($kind): $mod"
          elif [ -n "$lic" ]; then echo "REVIEW NEEDED ($kind): $mod $ver"; bad=1; fi ;;
      esac
      echo "$mod $ver $kind" >> "$po/go-modules.txt"
    done < "$tmp/deps"
    echo "plugin $id: $(wc -l < "$po/go-modules.txt") Go modules from $(basename "$bin")"
  done
done
exit $bad
