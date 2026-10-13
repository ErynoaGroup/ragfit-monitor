# RagFit | Monitor

RagFit | Monitor is the observability and dashboard frontend of the RagFit platform.

- License: AGPL-3.0-only, with some directories under Apache-2.0 (see `LICENSE` and `LICENSING.md`).
- Origin, copyright notices and the list of changes: see `LICENSE`, `NOTICE.md` and `MODIFICATIONS.md`.
- Releases are tagged `ragfit-monitor-vX.Y.Z`. Container images are built only by this repository's CI as a multi-arch index (linux/arm64, linux/amd64), signed and SBOM-attested with the key in `cosign.pub` (no transparency log entry). Verify with `cosign verify --key cosign.pub --insecure-ignore-tlog=true ghcr.io/erynoagroup/ragfit-monitor@<digest>`.

## Source code (AGPL-3.0 §13)

The complete corresponding source code of every released image, including build scripts, Dockerfile, CI workflows and patches, is available in this repository under the release tag the image was built from.
