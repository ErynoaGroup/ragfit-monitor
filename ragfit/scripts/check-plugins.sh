#!/usr/bin/env bash
# Plugin policy check.
#   check-plugins.sh                 config check only (no preinstalled plugins)
#   check-plugins.sh <image>         config check, then every plugin.json in the image's plugin dirs
#   check-plugins.sh --dir <path>... check every plugin.json under the given directories
# Every plugin.json, top-level or nested inside another plugin, must have an id and
# version pinned in ragfit/plugins-allowlist.txt (override with PLUGINS_ALLOWLIST).
# Symlinks inside plugin directories and unparseable plugin.json files fail the check.
# REQUIRE_PINNED=1 also fails when a pinned public plugin is missing (used on the release image);
# REQUIRE_PINNED=all also requires the proprietary entries (private deployment images).
# Policy per top-level plugin (see ragfit/PLUGINS.md):
#   - the allowlist type (backend|frontend) must match plugin.json ("backend": true),
#   - the license must be AGPL-3.0 compatible, or LicenseRef-proprietary for a type=backend entry
#     marked sdk-only; proprietary backend binaries must be built with grafana-plugin-sdk-go and must
#     not contain any module listed in ragfit/plugin-module-denylist.txt; their JavaScript (module.js)
#     needs a LICENSE-frontend file with an AGPL-3.0 compatible SPDX-License-Identifier,
#   - the plugin must be signed: MANIFEST.txt verified by verify-plugin-signature.sh.
set -euo pipefail
ALLOW="${PLUGINS_ALLOWLIST:-ragfit/plugins-allowlist.txt}"
DENY="${PLUGIN_MODULE_DENYLIST:-ragfit/plugin-module-denylist.txt}"
HERE=$(cd "$(dirname "$0")" && pwd)
COMPATIBLE=" Apache-2.0 MIT BSD-2-Clause BSD-3-Clause ISC MPL-2.0 AGPL-3.0-only AGPL-3.0-or-later "
PROPRIETARY=LicenseRef-proprietary

entry() { grep -v '^#' "$ALLOW" | awk -v i="$1" '$1==i'; }

# check_policy <plugin-dir> <id> <version>: license, type, sdk-only and signature rules.
check_policy() {
  local dir=$1 id=$2 ver=$3 e lic typ flag actual bin mods hit bad=0
  e=$(entry "$id"); lic=$(awk '{print $5}' <<< "$e"); typ=$(awk '{print $6}' <<< "$e"); flag=$(awk '{print $7}' <<< "$e")
  case "$typ" in backend|frontend) ;; *) echo "INVALID ALLOWLIST ENTRY: $id type '$typ' (backend|frontend)"; return 1 ;; esac
  actual=frontend; [ "$(jq -r '.backend == true' "$dir/plugin.json")" = true ] && actual=backend
  [ "$actual" = "$typ" ] || { echo "TYPE MISMATCH: $id is $actual, allowlist says $typ"; bad=1; }
  if [ "$lic" = "$PROPRIETARY" ]; then
    if [ "$typ" != backend ] || [ "$flag" != sdk-only ]; then
      echo "PROPRIETARY NOT ALLOWED: $id must be type=backend and sdk-only (frontend plugins need an AGPL-compatible license)"; bad=1
    fi
    if [ "$actual" = backend ]; then
      local n=0
      for bin in "$dir"/gpx_*; do
        [ -f "$bin" ] || continue; n=$((n+1))
        mods=$(go version -m "$bin" 2>/dev/null | awk '$1=="dep"||$1=="mod"||$1=="=>"{print $2}') \
          || { echo "CANNOT READ build info: $id $(basename "$bin")"; bad=1; continue; }
        grep -qxF github.com/grafana/grafana-plugin-sdk-go <<< "$mods" \
          || { echo "NOT SDK-BUILT: $id $(basename "$bin") does not use grafana-plugin-sdk-go"; bad=1; }
        hit=$(grep -v '^#' "$DENY" | grep . | while read -r d; do awk -v d="$d" '$0==d || index($0, d"/")==1' <<< "$mods"; done | sort -u)
        [ -z "$hit" ] || { echo "FORBIDDEN MODULE in $id $(basename "$bin"):"; sed 's/^/  /' <<< "$hit"; bad=1; }
      done
      [ "$n" -gt 0 ] || { echo "NO BACKEND BINARY: $id is type=backend but has no gpx_* executable"; bad=1; }
      # The frontend part (module.js) runs in the browser application and stays AGPL-3.0 compatible.
      if [ -n "$(find "$dir" -name '*.js' -print -quit)" ]; then
        local fl
        fl=$(sed -n 's/^SPDX-License-Identifier:[[:space:]]*\([^[:space:]]*\)[[:space:]]*$/\1/p' "$dir/LICENSE-frontend" 2>/dev/null | head -1)
        if [ -z "$fl" ]; then echo "NO FRONTEND LICENSE: $id ships JavaScript but no LICENSE-frontend with an SPDX-License-Identifier line"; bad=1
        elif [[ "$COMPATIBLE" != *" $fl "* ]]; then echo "FRONTEND LICENSE NOT ALLOWED: $id frontend part '$fl' (AGPL-3.0 compatible only)"; bad=1; fi
      fi
    fi
  elif [[ "$COMPATIBLE" == *" $lic "* ]]; then
    [ -n "$flag" ] && { echo "INVALID ALLOWLIST ENTRY: $id marker '$flag' is only for proprietary backend plugins"; bad=1; }
    compgen -G "$dir/LICENSE*" > /dev/null || { echo "NO LICENSE FILE: $id"; bad=1; }
  else
    echo "LICENSE NOT ALLOWED: $id '$lic' (AGPL-3.0 compatible, or $PROPRIETARY for sdk-only backend plugins)"; bad=1
  fi
  "$HERE/verify-plugin-signature.sh" "$dir" "$id" "$ver" || bad=1
  return $bad
}

check_dirs() {
  local d links found bad=0 id ver pin file seen=""
  for d in "$@"; do
    [ -d "$d" ] || { echo "NOT A DIRECTORY: $d"; return 1; }
    # Symlinks could hide a disallowed plugin from the scan; they are not allowed at all.
    links=$(find "$d" -type l)
    if [ -n "$links" ]; then
      echo "SYMLINK NOT ALLOWED in plugin directory:"; echo "$links"; bad=1
    fi
  done
  found=$(find "$@" -type f -name plugin.json | sort)
  [ -n "$found" ] || echo "no external plugins found"
  while read -r file; do
    [ -n "$file" ] || continue
    if ! jq -e 'type == "object"' "$file" > /dev/null 2>&1; then
      echo "INVALID plugin.json (not a JSON object): $file"; bad=1; continue
    fi
    id=$(jq -r '.id // ""' "$file"); ver=$(jq -r '.info.version // ""' "$file")
    if [ -z "$id" ]; then echo "NO ID: $file"; bad=1; continue; fi
    pin=$(grep -v '^#' "$ALLOW" | awk -v i="$id" '$1==i {print $2}')
    if [ -z "$pin" ]; then echo "NOT ALLOWED: $id ($file)"; bad=1
    elif [ "$pin" != "$ver" ]; then echo "VERSION MISMATCH: $id $ver, pinned $pin ($file)"; bad=1
    else
      echo "allowed: $id $ver ($file)"; seen="$seen $id"
      # Policy applies to top-level plugins (a nested plugin is covered by its parent's signature).
      for d in "$@"; do
        if [ "$(dirname "$(dirname "$file")")" = "${d%/}" ]; then check_policy "$(dirname "$file")" "$id" "$ver" || bad=1; fi
      done
    fi
  done <<< "$found"
  if [ "${REQUIRE_PINNED:-0}" = "1" ] || [ "${REQUIRE_PINNED:-0}" = "all" ]; then
    for id in $(grep -v '^#' "$ALLOW" | awk -v all="${REQUIRE_PINNED}" 'NF && (all=="all" || $5!="LicenseRef-proprietary") {print $1}'); do
      case " $seen " in *" $id "*) ;; *) echo "MISSING pinned plugin: $id"; bad=1 ;; esac
    done
  fi
  return $bad
}

if [ "${1:-}" = "--dir" ]; then shift; check_dirs "$@"; exit $?; fi

for key in preinstall preinstall_sync preinstall_async; do
  val=$(grep -E "^${key}[[:space:]]*=" conf/defaults.ini | head -1 | cut -d= -f2- | tr -d '[:space:]' || true)
  [ -z "$val" ] || { echo "conf/defaults.ini: $key must be empty, found: $val"; exit 1; }
done
IMAGE="${1:-}"
[ -n "$IMAGE" ] || { echo "config check ok (no image given)"; exit 0; }
tmp=$(mktemp -d); cid=$(docker create "$IMAGE")
trap 'docker rm -f "$cid" >/dev/null; rm -rf "$tmp"' EXIT
for d in /usr/share/grafana/data/plugins-bundled /var/lib/grafana/plugins; do
  mkdir -p "$tmp$d"; docker cp "$cid:$d/." "$tmp$d"
done
check_dirs "$tmp/usr/share/grafana/data/plugins-bundled" "$tmp/var/lib/grafana/plugins"
