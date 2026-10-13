# Modifications

This repository is a modified version of the upstream project published at
https://github.com/grafana/grafana (Copyright Grafana Labs), licensed under
AGPL-3.0-only with selected directories under Apache-2.0 as described in
`LICENSING.md`. All original license files, copyright notices and file headers
are retained unchanged.

Upstream base: tag `v13.2.4`, commit `af4a33e3786594ad72f72d97e6744010330c2977`
(annotated tag object `6259becc8e86265fdf35a73e08eef5bd92b5cd73`).

Each modified upstream file additionally carries the header line
`Modified by ErynoaGroup, <YYYY-MM-DD>: <purpose>` next to its original header.

## Change log

| Date | Change | Files | Purpose |
|---|---|---|---|
| 2026-10-13 | Imported upstream tree at v13.2.4 | all | Base of this repository |
| 2026-10-13 | Added sign-in configuration (no upstream file changed) | `ragfit/deploy/**`, `ragfit/scripts/test-role-mapping.py`, `.github/workflows/ci-quick.yml` | Generic OAuth via RagFit Source only, role mapping on the full team claim, deny by default, no password login, one org |
| 2026-10-13 | Allowed one community data source plugin, pinned by version and checksum (no upstream file changed) | `ragfit/plugins-allowlist.txt`, `ragfit/license-exceptions.txt`, `ragfit/scripts/check-plugins.sh`, `ragfit/scripts/verify-plugin-pins.sh`, `.github/workflows/ci-quick.yml` | Plugin used by the running instance; Apache-2.0 |
| 2026-10-13 | Removed upstream `.github/` directory (workflows, CODEOWNERS, issue templates, bot configs) | `.github/**` | Upstream automation must not run in this repository; own CI follows in a separate change |
| 2026-10-13 | Replaced `README.md` | `README.md` | Product README for RagFit Monitor; upstream marks are not used outside LICENSE, NOTICE and this file |
| 2026-10-13 | Added own CI and release tooling (no upstream file changed) | `.github/workflows/*`, `ragfit/**` | Policy checks, reviewed license exceptions, license bundle with THIRD_PARTY_NOTICES under /licenses in the image, plugin allowlist, GHCR release signed keyless and verified, SBOM attestation |
| 2026-10-13 | Added this file | `MODIFICATIONS.md` | Change notice per AGPL-3.0 §5(a) |
