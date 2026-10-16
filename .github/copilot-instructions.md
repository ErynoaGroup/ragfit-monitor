<!-- AGENT-SURFACE-SSOT:BEGIN -->
# GitHub Copilot — repository instructions

You are working in a repository that uses the **Erynoa Agent Surface SSOT** for portable skills and plugins shared across eight consumers: Claude, Grok, Codex, Copilot, Hermes, OpenClaw, Kimi, and Cursor.

## Mandatory — project doctrine

- **Read and follow** root **`erynoa.md`** (canonical agent handbook for this repo) and [`docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md).
- If `erynoa.md` is missing, create it using skill **`erynoa-md`** (or `just stamp-init` from the Agent Surface SSOT).
- Do **not** invent a second full doctrine only in this file — keep this file thin; depth lives in `erynoa.md`.

<!-- ERYNOA-DOCTRINE:BEGIN -->
## Erynoa Doctrine (Law R0–R10 · DynHom R2)

- **R0 Erynoa First:** Erynoa remotes live under **`github.com/ErynoaGroup/*`** only.
- **R1 Cognee Memory:** Recall via `cognee-recall` before claims; Git wins.
- **R2 DynHom:** Homogeneous repo surface (`erynoa.md`, `flake.nix`, `justfile`, `docs/`); dynamic depth by repo signal.
- **R3 Portable Paths:** Never hardcode fixed local user paths into doctrine — use `$AGENT_SURFACE_ROOT` / `$REPO_INDEX_ROOT` / git.
- **R4 Repo Doctrine:** Planner in `erynoa.md` first; keep `erynoa-gate` green; register in `.repo-index`.
- **R5 Surface SSOT:** Edit skills/plugins only in `git@github.com:ErynoaGroup/.ai-harness.git` (`$AGENT_SURFACE_ROOT`).
- **R6 Voice:** Craft Edge — sharp, path-backed, no slop.
- **R7 Verify:** Verify with tools (`just doctor` / `just ci-quick`); ship only on explicit word.
- **R8 Context Pull:** Respect workstation context-sync state.
- **R9 Primat Vorgehen:** Use `primary=erynoa-project · pipeline=vp-<id>` for product work.
- **R10 Research Corpus:** Keep research in corpus repos with EGK keys.
<!-- ERYNOA-DOCTRINE:END -->

## Also read

- Root [`erynoa.md`](../erynoa.md) (full doctrine)
- [`docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md) (RagFit v4.0 architecture)
- Root `AGENTS.md` / `CLAUDE.md` (adapters + surface block)
<!-- AGENT-SURFACE-SSOT:END -->

<!-- ERYNOA-POINTER:BEGIN -->
## Erynoa project doctrine (canonical)

**Full agent handbook for this repository:** [`erynoa.md`](../erynoa.md) · **Architecture:** [`docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md)

Every coding agent **MUST** find or create `erynoa.md` when interacting with this repo, then follow it.
Load skill **`erynoa-md`** (`/erynoa-md`) to create, deepen, audit, or sync mirrors.
<!-- ERYNOA-POINTER:END -->
