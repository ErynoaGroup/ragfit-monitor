<!-- Modified by ErynoaGroup, 2026-10-15: Replaced upstream CLAUDE.md pointer with Erynoa Agent Surface adapter -->
# Project rules (Claude-compatible)

Claude-compatible adapter for the same eight-consumer contract as `AGENTS.md`.

**Canonical project doctrine:** [`erynoa.md`](./erynoa.md) — skill **`erynoa-md`**.  
**System architecture:** [`docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md).

<!-- ERYNOA-DOCTRINE:BEGIN -->
## Erynoa Doctrine (Law R0–R10 · DynHom R2)

- **R0 Erynoa First:** Remotes under `ErynoaGroup/*` only.
- **R1 Cognee Memory:** Read via `cognee-recall` before claims; Git wins.
- **R2 DynHom:** Homogeneous repository surface (`erynoa.md`, `flake.nix`, `justfile`, `docs/`); signal-driven depth.
- **R3 Portable Paths:** Use `$AGENT_SURFACE_ROOT` / `$REPO_INDEX_ROOT` / git root — never fixed local home paths.
- **R4 Repo Doctrine:** Follow `erynoa.md` Agent planner first; keep `erynoa-gate` green.
- **R5 Surface SSOT:** Edit skills/plugins only in `ErynoaGroup/.ai-harness`.
- **R6 Voice:** Craft Edge — concise, evidenced, zero slop.
- **R7 Verify:** Verify with `just doctor` / `just ci-quick`; ship only on explicit authorization.
- **R8 Context Pull:** Keep workstation context-sync clean.
- **R9 Primat Vorgehen:** Use `primary=erynoa-project · pipeline=vp-<id>` for product changes.
- **R10 Research Corpus:** Keep research in dedicated corpus repos with EGK keys.
<!-- ERYNOA-DOCTRINE:END -->

<!-- AGENT-SURFACE-SSOT:BEGIN -->
## Agent Surface (global skills SSOT)

**Portable skills and plugins are centralized for all providers — not per-app copies.**

| | |
|--|--|
| **SSOT remote** | `git@github.com:ErynoaGroup/.ai-harness.git` |
| **Local root** | `$AGENT_SURFACE_ROOT` / `$AI_HARNESS_ROOT` |
| **Edit skills/plugins** | Only inside the SSOT (`skills/`, `plugins/`, `hooks/`, `justfile`) |
| **Never** | Treat home skill directories as the source of truth (derived symlinks) |
| **Never** | Absolute Mac/Linux home paths as SSOT in `.md` |
| **Install / health** | `cd "$AGENT_SURFACE_ROOT" && just install && just doctor` |
| **Docs / index** | `just index` → `docs/SKILLS.md` |
| **Handbook** | Skill **`agent-surface`** (`/agent-surface`) |
| **Repo doctrine** | Skill **`erynoa-md`** · file **`erynoa.md`** |
| **Large multi-skill work** | **`ultracode`** · **`task-intake`** |

| Provider | Also reads in this repo |
|----------|-------------------------|
| All | **`erynoa.md` (canonical)**, **`docs/ARCHITECTURE.md`** |
| Claude | `CLAUDE.md`, `.claude/` |
| Grok | `AGENTS.md`, `CLAUDE.md` |
| OpenAI Codex | `AGENTS.md` |
| GitHub Copilot | `AGENTS.md` + `.github/copilot-instructions.md` |
| Hermes | `erynoa.md`, `AGENTS.md` |
| OpenClaw | `erynoa.md`, workspace `AGENTS.md` |
| Kimi Code | `AGENTS.md` |
| Cursor | `erynoa.md`, `AGENTS.md` |

<!-- AGENT-SURFACE-SSOT:END -->

<!-- ERYNOA-POINTER:BEGIN -->
## Erynoa project doctrine (canonical)

**Full agent handbook for this repository:** [`erynoa.md`](./erynoa.md) · **Architecture:** [`docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md)

Every coding agent **MUST** find or create `erynoa.md` when interacting with this repo, then follow it.
Load skill **`erynoa-md`** (`/erynoa-md`) to create, deepen, audit, or sync mirrors.
<!-- ERYNOA-POINTER:END -->
