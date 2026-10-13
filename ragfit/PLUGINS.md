# Plugins and licensing

This section sets out which plugins RagFit Monitor accepts and why. The repository itself is
licensed under AGPL-3.0-only (see LICENSE and LICENSING.md). This text is an engineering policy,
not legal advice.

## Rules

| Plugin kind | Allowed license | Where it may ship |
|---|---|---|
| Frontend plugin (runs in the same browser application) | AGPL-3.0 compatible only: Apache-2.0, MIT, BSD-2-Clause, BSD-3-Clause, ISC, MPL-2.0, AGPL-3.0 | public image or private deployment |
| Backend plugin, open source (separate process) | AGPL-3.0 compatible as above | public image or private deployment |
| Backend plugin, proprietary | `LicenseRef-proprietary`, only if **sdk-only** | private deployment only, never in the public image |

Every plugin, whatever its license:
- is pinned in an allowlist by id and version (public entries also by package SHA-256),
- has a type that matches its `plugin.json` (`backend`, or `frontend` when there is no backend),
- is signed: `MANIFEST.txt` must carry a valid signature from the plugin signing key, name the same id
  and version, and list every file of the plugin directory with a matching SHA-256,
- ships its license file (`LICENSE*`).

### sdk-only backend plugins
A proprietary backend plugin runs in its own process and talks to the server only through the plugin
protocol. It qualifies as sdk-only when:
- it is built with `github.com/grafana/grafana-plugin-sdk-go` (Apache-2.0),
- none of the modules listed in `ragfit/plugin-module-denylist.txt` are compiled into it (server code
  under AGPL-3.0, e.g. `github.com/grafana/grafana` and everything below it),
- no source code from this repository is copied into it,
- the Apache-2.0 obligations of the SDK and other libraries are met (license and notice files shipped).

Frontend plugins share the browser application with AGPL-3.0 code, so they are always held to the
AGPL-3.0 compatible list, even when they only use the Apache-2.0 packages `@grafana/ui`, `@grafana/data`
and `@grafana/runtime`.

## Allowlist format
`ragfit/plugins-allowlist.txt`, one plugin per line:

    <id> <version> <sha256 linux-arm64 zip> <sha256 linux-amd64 zip> <license> <type> [sdk-only]

- `license`: an SPDX id from the compatible list, or `LicenseRef-proprietary`.
- `type`: `backend` or `frontend`.
- `sdk-only`: required for `LicenseRef-proprietary` and only allowed there.

Public entries come from the public plugin catalog. They are verified by checksum
(`verify-plugin-pins.sh`, `fetch-plugins.sh`) and baked into the public image. Proprietary entries are
never listed in this repository. A private deployment keeps its own copy of the allowlist with
checksums `-`, adds those plugins in its own image layer, and runs the same check with
`PLUGINS_ALLOWLIST=<copy> REQUIRE_PINNED=all`.

## Checks
- `check-plugins.sh` (`--dir` or an image) enforces the allowlist, type, license, sdk-only and signature rules.
- `verify-plugin-signature.sh` verifies `MANIFEST.txt` offline.
- `plugin-licenses.sh` collects the license texts of plugins and of every Go module compiled into their
  backend binaries. It checks module hashes against the binary and rejects copyleft or unknown module
  licenses unless there is a reviewed exception in `ragfit/license-exceptions.txt`.
- `test-check-plugins.sh`, `test-fetch-plugins.sh` and `test-plugin-licenses.sh` run offline in ci-quick.
