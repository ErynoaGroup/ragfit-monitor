<!-- Modified by ErynoaGroup, 2026-10-15: Standardized Erynoa documentation map for RagFit | Monitor -->
# Documentation Map — `RagFit | Monitor`

> Kanonischer Einstieg in die Dokumentation von **`RagFit | Monitor`** (`ErynoaGroup/ragfit-monitor`).

## Kern-Dokumente

| Dokument | Zweck |
|----------|-------|
| [`../README.md`](../README.md) | Projekt-Überblick, Status-Tabelle, Quickstart (`nix develop`, `just doctor`, `just image`) und C4-Lite-Modell |
| [`../erynoa.md`](../erynoa.md) | Kanonische Agenten-Doktrin, Self-Orchestration-Planner, Invarianten (`I-1`–`I-5`), Verbote (`F-1`–`F-4`), Domänensprache |
| [`ARCHITECTURE.md`](./ARCHITECTURE.md) | Tiefgehende **RagFit v4.0** Architektur: `RagFit \| Monitor` als Schicht L6 Unified Observability Surface, AGPLv3-Netzwerk-Isolation, OIDC-RBAC, gebackene Plugins und 7-Schichten-Telemetrie (`L0`–`L6`) |
| [`work/ROADMAP.md`](./work/ROADMAP.md) | Aktive Roadmap (`MO0`–`MO7`, `V4-STD`, `MO8`–`MO9`) und Verifikationsstatus |
| [`../MODIFICATIONS.md`](../MODIFICATIONS.md) | Verbindliches Änderungsverzeichnis gegenüber Upstream `v13.2.4` gemäß AGPL-3.0 §5(a) |
| [`../TRADEMARKS.md`](../TRADEMARKS.md) | Markenrechtliche Trennung von Erynoa- und RagFit-Wort-/Bildmarken |

## Betrieb, Deployment & Plugins (`ragfit/`)

- [`../ragfit/PLUGINS.md`](../ragfit/PLUGINS.md) — Plugin-Lizenz-, Signatur- und Allowlist-Policy (`prometheus`, `loki`, `tempo`, `yesoreyeram-infinity-datasource`)
- [`../ragfit/deploy/README.md`](../ragfit/deploy/README.md) — Öffentliches Helm-Chart (`ragfit/deploy/helm/ragfit-monitor`) und Sicherheits-Guards
- [`../ragfit/docs/plugins-onprem.md`](../ragfit/docs/plugins-onprem.md) — On-Prem-Inventar der gebackenen Core-Datenquellen
- [`../ragfit/docs/runbook-service-account-and-oauth.md`](../ragfit/docs/runbook-service-account-and-oauth.md) — Runbook für OIDC-App-Konfiguration und Service-Account-Widerruf (`MO5`/`MO6`)
- [`../ragfit/docs/runbook-cutover-mo7.md`](../ragfit/docs/runbook-cutover-mo7.md) — Cutover-Runbook (`MO7`)

## Work-Root (`docs/work/`)

- [`work/ROADMAP.md`](./work/ROADMAP.md) — Phasenplan & Meilensteine
- `work/specs/` — Spezifikationen (`SE-07`)
- `work/plans/` — Implementierungspläne
- `work/notes/` — Architekturnotizen
