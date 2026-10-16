# Work ROADMAP — `RagFit | Monitor`

**Stand:** 2026-10-15 · **Work-Root:** `docs/work/` · **Architektur:** [`../ARCHITECTURE.md`](../ARCHITECTURE.md)

---

## Phasen-Übersicht

| Phase / ID | Titel | Status | Nachweis / Referenz |
|------------|-------|--------|---------------------|
| **MO0–MO1** | Upstream-Import (`v13.2.4`), Entfernen der Upstream-Workflows, AGPLv3-Lizenz- & Marken-Trennung (`MODIFICATIONS.md`, `TRADEMARKS.md`) | **done** | `ragfit/scripts/verify-upstream-base.sh` |
| **MO2** | RagFit-Branding (Produkttitel, Login-Wortmarke, neutrale Icons, Startseiten-Willkommenstext) & Erynoa Shared Header `1.1.4` (Self-Hosted Hanken Grotesk) | **done** | `ragfit/scripts/check-erynoa-header.sh`, `ragfit/scripts/verify-branding.sh` |
| **MO3** | Fail-Closed Generic OAuth / OIDC über `RagFit \| Source` / `RagFit \| Auth` mit striktem Team-Claim-RBAC (`ErynoaGroup:*`, Deny-by-Default) | **done** | `ragfit/deploy/grafana.ini`, `ragfit/scripts/test-role-mapping.py` |
| **MO4** | Gebackene, signatur- und lizenzgeprüfte Core-Plugins (`prometheus` 13.2.3, `loki` 13.2.2, `tempo` 13.2.4, `yesoreyeram-infinity-datasource` 3.11.1) | **done** | `ragfit/PLUGINS.md`, `ragfit/scripts/check-plugins.sh` |
| **MO5–MO7** | Öffentliches Helm-Chart (`ragfit/deploy/helm/ragfit-monitor`), OAuth-/Service-Account-Runbook, Multi-Arch Cosign- & SLSA-Release (`v0.1.3`) und Cutover-Runbook | **done** | `ragfit/scripts/test-helm.sh`, `ragfit/docs/runbook-cutover-mo7.md` |
| **V4-STD** | Erynoa-Standardisierung (`erynoa.md`, Adapter-Pointer, `docs/ARCHITECTURE.md`), Bereinigung von Upstream-Meta-Ballast & leichtgewichtiger Nix-OCI-Container-Build (`nix build .#container` / `just image`) | **done** | `flake.nix`, `justfile`, `erynoa.md`, `docs/ARCHITECTURE.md` |
| **MO8** | Vorprovisionierte Golden-Dashboards für `RagFit \| Bus` (JetStream Consumer-Lag & DLQ), `RagFit \| Ops` (`GrokGuard` `TokenLedger` & Outbox-Age) und `RagFit \| Runner` (60/40 Pool-Auslastung) | **planned** | [`ARCHITECTURE.md §4`](../ARCHITECTURE.md#4-kern-observability-domänen-der-ragfit-v40-plattform) |
| **MO9** | Cross-Domain Trace-Correlation-Links (`correlation_id`) zwischen Tempo/Loki und `RagFit \| Console` (`Ops.Run` / `Evidence.Bundle`) | **planned** | [`ARCHITECTURE.md §4`](../ARCHITECTURE.md#4-kern-observability-domänen-der-ragfit-v40-plattform) |

---

## Verifikations-Gates

1. **Lokales Schnell-Gate (`just doctor` / `just ci-quick`):**
   - `./ragfit/scripts/leak-guard.sh`
   - `./ragfit/scripts/verify-upstream-base.sh HEAD`
   - `./ragfit/scripts/verify-branding.sh`
   - `./ragfit/scripts/check-plugins.sh`
2. **Helm- & OAuth-Tests:** `./ragfit/scripts/test-helm.sh` und `python3 ragfit/scripts/test-role-mapping.py`.
3. **Container-Gate (`just image`):** `nix build .#container` (`pkgs.dockerTools.buildLayeredImage`).
4. **Erynoa-Gate:** `erynoa-gate.py --include-soft` und `audit-erynoa.py`.
