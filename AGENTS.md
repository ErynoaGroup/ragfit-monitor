<!-- Modified by ErynoaGroup, 2026-10-15: Replaced upstream agent instructions with Erynoa Agent Surface adapter -->
# Project agent rules

All eight Erynoa consumers—Claude, Grok, Codex, Copilot, Hermes, OpenClaw, Kimi, and Cursor—must follow the same rules in this repository.

**Canonical project doctrine:** [`erynoa.md`](./erynoa.md) — find or create via skill **`erynoa-md`**.  
**System architecture:** [`docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md).

<!-- ERYNOA-DOCTRINE:BEGIN -->
## Erynoa Doctrine (Law R0–R10 · DynHom R2)

- **R0 Erynoa First:** Only `github.com/ErynoaGroup/*` remotes are permitted for Erynoa work.
- **R1 Cognee Memory:** Recall via `cognee-recall` before claims; Git remains canonical SSOT.
- **R2 DynHom:** Maximal homogen in structure (`erynoa.md`, `flake.nix`, `justfile`, `docs/`), maximal dynamisch in depth from repo signals.
- **R3 Portable Paths:** Use `$AGENT_SURFACE_ROOT`, `$REPO_INDEX_ROOT`, and repo-relative paths — never fixed local user paths.
- **R4 Repo Doctrine:** Read `erynoa.md` Agent planner first; keep `erynoa-gate` green; register in `.repo-index`.
- **R5 Surface SSOT:** Edit portable skills/plugins only in `ErynoaGroup/.ai-harness` (`$AGENT_SURFACE_ROOT`).
- **R6 Voice:** Craft Edge register — concise, path-backed, zero AI-slop.
- **R7 Verify:** Tools over guessing; done requires verification evidence (`just doctor` / `just ci-quick`).
- **R8 Context Pull:** Respect workstation context-sync state.
- **R9 Primat Vorgehen:** Route product/feature work through `primary=erynoa-project · pipeline=vp-<id>`.
- **R10 Research Corpus:** Keep research catalogs in research repos with full EGK links.
<!-- ERYNOA-DOCTRINE:END -->

**Org registry (mandatory):**
`git@github.com:ErynoaGroup/.repo-index.git` · **`$REPO_INDEX_ROOT`** · skill **`repo-index`**.

```bash
export REPO_INDEX_ROOT="${REPO_INDEX_ROOT:?set to your clone of ErynoaGroup/.repo-index}"
git clone git@github.com:ErynoaGroup/.repo-index.git "$REPO_INDEX_ROOT"   # first time
git -C "$REPO_INDEX_ROOT" pull --ff-only
```

This project **must** use an **ErynoaGroup** remote and appear in `repos.yaml`. Unregistered → register or STOP.

<!-- AGENT-SURFACE-SSOT:BEGIN -->
## Agent Surface (global skills SSOT)

**Portable skills and plugins are centralized for all providers — not per-app copies.**

| | |
|--|--|
| **SSOT remote** | `git@github.com:ErynoaGroup/.ai-harness.git` |
| **Local root** | `$AGENT_SURFACE_ROOT` / `$AI_HARNESS_ROOT` (host-set; never a fixed user path in docs) |
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
| OpenAI Codex | `AGENTS.md` (and nested `AGENTS.md`) |
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
