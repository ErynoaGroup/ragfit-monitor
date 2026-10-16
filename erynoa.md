# erynoa.md — project agent doctrine

<!-- AGENT-PLANNER:BEGIN -->
## Agent planner (self-orchestration)

> **Read this first.** Humans: [README.md](./README.md) · Architecture: [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md).  
> **Law R2 · DynHom:** maximal **homogen** (gleiche Homes/Verträge) · maximal **dynamisch** (Signal-Tiefe). `rule-01-dynamic-homogeneous.md`

| | |
|--|--|
| **Mission** | Schicht L6 Unified Observability Surface (`RagFit \| Monitor`): AGPLv3-netzwerkisoliertes Observability- & Dashboard-Frontend für alle 7 Schichten (`L0`–`L6`) der RagFit v4.0 Plattform mit OIDC-Team-Claim-RBAC, gebackenen/gepinnten Plugins (`prometheus`, `loki`, `tempo`, `infinity`) und Erynoa-Header 1.1.4 |
| **Session goal** | aus Auftrag, sonst: orientieren + `just doctor` |
| **Success** | `just doctor` (`just ci-quick`: `leak-guard.sh`, `verify-upstream-base.sh`, `verify-branding.sh`, `check-plugins.sh`) grün · `nix flake show` grün · `erynoa-gate` grün |
| **DX** | `nix develop` · `just` · `just doctor` · `just ci-quick` · `just image` · `just --list` |
| **Work-root** | `docs/work/` |
| **Branching** | trunk-based · PRs → `main` |
| **Erynoa First** | Remote **must** be `ErynoaGroup/ragfit-monitor` |
| **Paths** | `$AGENT_SURFACE_ROOT` / `$REPO_INDEX_ROOT` / git — never fixed user home paths in doctrine |
| **Repo-index** | MUST register in `git@github.com:ErynoaGroup/.repo-index.git` · skill `repo-index` |

**Read order:** (1) this planner (2) `justfile` & `MODIFICATIONS.md` (3) [README.md](./README.md) & [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md) (4) `ragfit/modified-upstream-files.txt` (5) sections below as needed (6) `docs/work/ROADMAP.md`

**Do first:** confirm repo root and branch → `nix develop` → `just doctor` → classify task → execute → verify

**Orchestration**

| Task | Route |
|------|--------|
| Orient | M0 · planner + `just doctor` |
| Doctrine missing/thin | `erynoa-md` M1–M2 |
| Docs / SPEC·PLAN | `erynoa-docs` |
| Quality | `erynoa-md` M3 |
| Feature / product change (Erynoa org repo) | **`erynoa-project` primary · `pipeline=vp-<id>`** (R9) → `docs/work/` PLAN + branch + implement |
| Ship gate | M5 |
| Wide explore / N independent reads | **subagents** (read-only) → parent merge |

**Subagents:** solo default; independent ready work only within actual free child slots, compatible file ownership and any smaller cap. Contract: `$AGENT_SURFACE_ROOT/skills/agent-surface/references/workflow-runtime.md`.

**Efficiency:** plan→act→verify · progressive disclosure · tools > guessing · compact context.

**Voice:** *Craft Edge* — sharp, path-backed, short; 🎯📋✓ when multi-step; no AI-slop (`voice.md`).

**DynHom:** gleiche Form überall; Tiefe/Packs/Fan-out nur signal-gebunden (Law R2).

**Do not:** skip planner · edit upstream files without recording in `ragfit/modified-upstream-files.txt` and `MODIFICATIONS.md` · use enterprise build tags · commit credentials · push without explicit authorization.
<!-- AGENT-PLANNER:END -->

---

## Identity

| Field | Value |
|-------|--------|
| **Project** | `RagFit \| Monitor` (`ErynoaGroup/ragfit-monitor`) |
| **Purpose** | Schicht L6 Unified Observability Surface: Metrik-, Log-, Trace- und Governance-Dashboards für alle 7 RagFit-Schichten (`L0`–`L6`) (`RagFit \| Bus`, `RagFit \| Ops` `GrokGuard`, `RagFit \| Runner` 60/40 Pool, `RagFit \| Memory`, `RagFit \| Plan`, `RagFit \| Source`) |
| **Plattform-Scope (W8)** | **Plattform-Dienstfamilie `RagFit \| *`** · Schicht `L6` Presentation, BFF & Observability in der 7-Schichten-Gesamtarchitektur (`L0`–`L6`) |
| **Owners** | Niklas Klein / ErynoaGroup |
| **Status / tier** | `v0.1.3` (`MO0`–`MO7`) produktiv · v4.0 Observability-Architektur verankert (Tier 1 Core Platform) |
| **Stack** | Go 1.25, TypeScript / React Frontend Monorepo (`packages/*`, `public/*`), Helm, Nix Flake + `dockerTools.buildLayeredImage`, `just` |
| **Visibility** | public-ready (AGPL-3.0-only §13 source compliance; deployment values stay private) |
| **License** | `AGPL-3.0-only` with `Apache-2.0` directories (see [`LICENSE`](./LICENSE), [`LICENSING.md`](./LICENSING.md), [`NOTICE.md`](./NOTICE.md), [`MODIFICATIONS.md`](./MODIFICATIONS.md), [`TRADEMARKS.md`](./TRADEMARKS.md)) |
| **Default branch** | `main` |
| **last_reviewed** | 2026-10-15 |

## Invariants

1. **I-1** — **Strikte Upstream-Basis-Disziplin (`verify-upstream-base.sh`)**: Eigene Erweiterungen liegen unter `ragfit/`, `.github/`, `.claude/`, `public/img/ragfit/`, `docs/ARCHITECTURE.md`, `docs/work/`, `erynoa.md`, `flake.nix`, `justfile`, `MODIFICATIONS.md` und `TRADEMARKS.md`. Jede Änderung oder Löschung einer Upstream-Datei außerhalb dieser Pfade **muss** sortiert in `ragfit/modified-upstream-files.txt` sowie in `MODIFICATIONS.md` dokumentiert sein.
2. **I-2** — **AGPLv3-Netzwerk-Isolation & Non-Enterprise-Build**: `RagFit | Monitor` ist ausschließlich über offene Netzwerkprotokolle (OTLP/PromQL/LogQL/TraceQL/HTTPS) angebunden — niemals per Code-Einbettung in proprietäre Dienste (`ragfit-ops`, `ragfit-agent`). `IsEnterprise = false` in `pkg/extensions/main.go` ist unantastbar; `enterprise`-Build-Tags sind verboten.
3. **I-3** — **Fail-Closed OIDC & Team-Claim-RBAC**: Authentifizierung erfolgt ausschließlich über Generic OAuth / OIDC (`ragfit/deploy/grafana.ini`) mit vollständiger Team-Claim-Prüfung (`ErynoaGroup:platform-admin`, `ErynoaGroup:ops-editor`, `ErynoaGroup:ops-viewer`), Deny-by-Default, deaktiviertem Passwort-Login und Single-Org-Bindung (`ragfit/scripts/test-role-mapping.py`).
4. **I-4** — **Gebackene, signierte & lizenzgeprüfte Plugins (`check-plugins.sh`)**: Zur Laufzeit werden keinerlei Plugins nachgeladen. Alle erlaubten Datenquellen (`prometheus` 13.2.3, `loki` 13.2.2, `tempo` 13.2.4, `yesoreyeram-infinity-datasource` 3.11.1) sind in `ragfit/plugins-allowlist.txt` per Version und SHA-256 pro Architektur gepinnt, offline signaturgeprüft und samt Drittanbieter-Lizenzen im Image unter `/usr/share/grafana/data/plugins-bundled` gebacken.
5. **I-5** — **Self-Hosted Erynoa Header 1.1.4 & Marken-Trennung**: Der gemeinsame Plattform-Header (`public/img/ragfit/erynoa/1.1.4/`) mit selbst-gehosteter Hanken Grotesk wird serverseitig in `public/views/index.html` und `pkg/api/index.go` gerendert und durch `ragfit/scripts/check-erynoa-header.sh` geprüft; Erynoa-/RagFit-Marken unterliegen `TRADEMARKS.md`.

## Forbidden

1. **F-1** — Commit von Zugangsdaten, privaten Schlüsseln, unverschlüsselten Datasource-Credentials in Helm-Values, Tailnet-Domains oder internen IP-Adressen (`ragfit/scripts/leak-guard.sh`).
2. **F-2** — Änderung oder Löschung von Upstream-Dateien ohne synchronen Eintrag in `ragfit/modified-upstream-files.txt` und `MODIFICATIONS.md`.
3. **F-3** — Verwendung von `enterprise`-Build-Tags, dynamisches Nachladen unsignierter Plugins zur Laufzeit oder Verwendung der Formulierung `based on grafana` außerhalb der Lizenzdateien (`LICENSE`, `NOTICE.md`, `MODIFICATIONS.md`).
4. **F-4** — Home-Skill-Verzeichnisse als SSOT verwenden (ausschließlich `$AGENT_SURFACE_ROOT` / `ErynoaGroup/.ai-harness`).

## How agents work

1. **Agent planner first** → lesen, `nix develop` starten und `just doctor` (`just ci-quick`) ausführen.
2. **Upstream-Diff-Wächter beachten** → Vor und nach jeder Dateiänderung `./ragfit/scripts/verify-upstream-base.sh HEAD` und `./ragfit/scripts/leak-guard.sh` ausführen. Jede berührte Upstream-Datei erhält den Header-Kommentar `Modified by ErynoaGroup, YYYY-MM-DD: <Zweck>` sowie einen Eintrag in `ragfit/modified-upstream-files.txt` (alphabetisch sortiert!) und `MODIFICATIONS.md`.
3. **Branding & Header-Integrität prüfen** → Nach Änderungen an `public/views/index.html`, `pkg/api/index.go` oder `public/img/ragfit/` stets `./ragfit/scripts/verify-branding.sh` und `./ragfit/scripts/test-check-erynoa-header.sh` ausführen.
4. **Branching & Review** → Trunk-basierte Entwicklung auf `main` über Pull Requests (PR); kein Push ohne explizite Freigabe.

## Architecture map

```text
┌──────────────────────────────────────────────────────────────────────────────┐
│            RagFit | Monitor (Schicht L6 · Unified Observability Surface)      │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐  │
│  │  Erynoa Shared Header 1.1.4 (public/img/ragfit/erynoa/1.1.4/)          │  │
│  │  Server-side Injection in pkg/api/index.go & public/views/index.html   │  │
│  └───────────────────────────────────┬────────────────────────────────────┘  │
│                                      │                                       │
│  ┌───────────────────────┐   ┌───────▼────────────────┐   ┌───────────────┐  │
│  │  RagFit | Auth /      │──▶│  Go Backend (pkg/api)  │◀──│ Provisioned   │  │
│  │  RagFit | Source OIDC │   │  + React Monorepo      │   │ Dashboards    │  │
│  │  Full Team-Claim RBAC │   │  (public/ · packages/) │   │ (conf/ · helm)│  │
│  └───────────────────────┘   └───────┬────────────────┘   └───────────────┘  │
│                                      │                                       │
│  ┌───────────────────────────────────▼────────────────────────────────────┐  │
│  │  Baked & Pinned Core Datasource Plugins (plugins-bundled, UID 472)     │  │
│  │  prometheus 13.2.3 · loki 13.2.2 · tempo 13.2.4 · infinity 3.11.1      │  │
│  └───────┬───────────────────┬──────────────────┬─────────────────┬───────┘  │
│          │                   │                  │                 │          │
│  ┌───────▼───────┐   ┌───────▼───────┐  ┌───────▼───────┐ ┌───────▼───────┐  │
│  │ RagFit | Bus  │   │ RagFit | Ops  │  │RagFit | Runner│ │Schichten 1–4  │  │
│  │Consumer-Lag & │   │Outbox-Age &   │  │60% CI / 40%   │ │Auth · Plan ·  │  │
│  │DLQ-Metriken   │   │GrokGuard Token│  │Agent-Auslast. │ │Source · Memory│  │
│  └───────────────┘   └───────────────┘  └───────────────┘ └───────────────┘  │
└──────────────────────────────────────────────────────────────────────────────┘
```

| Module / path | Responsibility | May depend on |
|---------------|----------------|---------------|
| `ragfit/deploy/` | Gehärtete `grafana.ini` (OIDC, JMESPath-Rollen-Mapping, Security-Defaults) & öffentliches Helm-Chart (`ragfit/deploy/helm/ragfit-monitor`) | Kubernetes Secrets (`$__file{}`) |
| `ragfit/scripts/` | Policy-, Upstream-Diff-, Branding-, Header-, Lizenz- und Plugin-Prüfskripte | `bash`, `git`, `python3`, `jq`, `openssl` |
| `ragfit/docker/` | `Dockerfile.plugins` & `Dockerfile.licenses` für gebackene Plugins und `/licenses` | `ragfit/plugins-allowlist.txt` |
| `public/img/ragfit/` | RagFit-Wortmarken, Platzhalter-Icons und Erynoa-Header `1.1.4` inkl. `SHA256SUMS` | `.assets` (Byte-identischer Import) |
| `pkg/api/` & `public/views/` | Go-HTTP-Server und HTML-Templates mit serverseitigem Erynoa-Header-Rendering | `public/img/ragfit/erynoa/` |
| `packages/` & `public/app/` | Frontend-Monorepo-Pakete (`@grafana/*` / React-UI mit RagFit-Branding-Patches) | `yarn.lock` |

## Domain language

| Term | Meaning |
|------|---------|
| `Unified Observability Surface` | Rolle von `RagFit \| Monitor` in Schicht L6 als zentrale Visualisierungs- und Korrelationsfläche für Metriken (Prometheus), Logs (Loki) und Traces (Tempo). |
| `Modified Upstream Manifest` | Die Datei `ragfit/modified-upstream-files.txt`, die jede gegenüber Upstream `v13.2.4` veränderte oder gelöschte Datei außerhalb der eigenen Verzeichnisse auflistet. |
| `Baked Plugin Allowlist` | Die Datei `ragfit/plugins-allowlist.txt` mit SHA-256-Prüfsummen pro Architektur und Signaturpflicht für alle im Container-Image vorinstallierten Plugins. |
| `GrokGuard Telemetry` | Observability-Metriken aus `RagFit \| Ops` über aktive `BudgetLease`s, Token-Verbrauch (`TokenLedger`), Kostenobergrenzen und abgelehnte Agenten-Dispatches. |
| `JetStream Consumer-Lag` | Überwachungsmetrik für `RagFit \| Bus` (`ragfit-events`, `ragfit-agent-tasks`, `ragfit-dlq`) sowie `Outbox-Age` der Transactional Outbox in `RagFit \| Ops`. |
| `60/40 Runner Split` | Kapazitäts- und Auslastungsmetriken des `RagFit \| Runner`-Flottenpools (60 % klassische CI/CD-Jobs vs. 40 % isolierte KI-Agenten-Sandboxes). |

## Tooling & commands

```bash
nix develop                                      # Nix devShell mit go, nodejs_22, yarn, just, jq, git, python3+pyyaml
just                                             # Rezept-Übersicht anzeigen
just doctor                                      # Vollständiger lokaler Gate-Check (just ci-quick)
just ci-quick                                    # Führt leak-guard.sh, verify-upstream-base.sh, verify-branding.sh & check-plugins.sh aus
just image                                       # Baut leichtgewichtiges Nix OCI-Container-Image (nix build .#container)
nix flake show                                   # Prüft alle Flake-Outputs (packages + devShells)
./ragfit/scripts/verify-upstream-base.sh HEAD    # Prüft Upstream-Diff gegen v13.2.4 und ragfit/modified-upstream-files.txt
./ragfit/scripts/verify-branding.sh              # Prüft Lizenzdateien, Non-Enterprise-Invariante und Erynoa-Header 1.1.4
./ragfit/scripts/test-helm.sh                    # Prüft Helm-Chart-Templates und Credential-Guards
python3 ragfit/scripts/test-role-mapping.py      # Prüft JMESPath OIDC-Rollen-Mapping
yarn install --immutable                         # Deterministische Frontend-Abhängigkeiten (Monorepo)
yarn tsc --noEmit                                # TypeScript-Typecheck für geänderte Frontend-Komponenten
go test -short ./pkg/api/... ./pkg/login/...     # Go-Backend-Tests für API, Header-Injektion und Login
```

Die CI-Workflows unter `.github/workflows/` (`ci-quick.yml`, `ci.yml`, `release.yml`) prüfen Upstream-Basis, Plugin-Signaturen, Lizenzen, Go-Tests und Frontend-Patches.

## Skills & surface

| | |
|--|--|
| Doctrine + planner | `./erynoa.md` · skill `erynoa-md` |
| Docs + README style | skill `erynoa-docs` |
| Product / feature work | skill `erynoa-project` (`pipeline=vp-*`) |
| Global skills SSOT | `git@github.com:ErynoaGroup/.ai-harness.git` · `$AGENT_SURFACE_ROOT` · skill `agent-surface` |
| Org registry | `git@github.com:ErynoaGroup/.repo-index.git` · `$REPO_INDEX_ROOT` · skill `repo-index` |

## Provider adapters

`AGENTS.md`, `CLAUDE.md`, `.claude/CLAUDE.md` und `.github/copilot-instructions.md` sind schlanke Adapter-Pointer auf diese Doktrin (`erynoa.md`) und [`docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md).

## Open questions

- [ ] **MO8 Provisionierte v4.0 Golden-Dashboards**: Auslieferung vorprovisionierter JSON-Dashboards für `RagFit | Bus` (JetStream Consumer-Lag), `RagFit | Ops` (`GrokGuard` `TokenLedger` & Outbox-Age) und `RagFit | Runner` (60/40 Dual-Use Pool) im Helm-Chart.
- [ ] **MO9 Cross-Domain Trace-Links**: Direkte Deep-Links aus Tempo-Trace-Spans (`correlation_id`) zurück in `RagFit | Console` (`Ops.Run` / `Evidence.Bundle`).
