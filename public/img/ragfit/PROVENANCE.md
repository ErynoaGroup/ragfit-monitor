# Provenance: RagFit wordmark files

The RagFit name and logo are Erynoa trademarks, not licensed under the AGPLv3.
See `TRADEMARKS.md` and `LICENSE-NOTICE.md`.

## Source

- Repository: `ErynoaGroup/.assets` (private)
- Commit: `250d5b85b7b69dcbd0feaa9d97e6cdacc2cfaca0`. The logo files are unchanged since `6b9cbe583ee62784f5ccef0a0d18fb132464ff52`.

| File here | Source path in `.assets` | Git blob | Size | SHA-256 |
|---|---|---|---|---|
| `login-wordmark-light.png` | `logos/ragfit/ragfit-by-en-stacked-transparent.png` | `392cb38df25a0109ae26940d9d0fe9442df6e392` | 43263 | `f6a5d2eedf849e9052745485d951c9126a29ae80b941acd37ac66549cd07f11c` |
| `login-wordmark-dark.png` | `logos/ragfit/ragfit-by-en-stacked-white-transparent.png` | `98c4504044a401f6c74b9bdf5403ed5fc23c9119` | 43155 | `c774c69cf62adeb350f0a1f1046300669e8772e44858e4f05f54c8e3e03b068e` |

Both files are byte-identical copies of the `.assets` originals at 1856x560. They are
not cropped, scaled or re-encoded. The login page scales them in CSS with the aspect
ratio kept (max width 464 px).

## Check against `.assets` (2026-10-13)

The intermediate logo export had six files. They were compared with `.assets` at the
commit above via the GitHub contents API, using git blob hashes:

- `*-1856x560.png` (light and dark): blob hashes equal the `.assets` originals, so the files are **byte-identical**.
- `*-928x280.png` and `*-464x140.png`: Lanczos downscales, **not** byte-identical. They are not used here.

## Export provenance (verbatim)

> # Provenance — RagFit | Monitor logo export
> 
> Source repo: `ErynoaGroup/.assets` @ `250d5b85b7b69dcbd0feaa9d97e6cdacc2cfaca0` (logo files unchanged since `6b9cbe583ee62784f5ccef0a0d18fb132464ff52`).
> 
> | Export | Source | Operation |
> |--------|--------|-----------|
> | `login/ragfit-monitor-login-light-1856x560.png` | `logos/ragfit/ragfit-by-en-stacked-transparent.png` | byte-identical copy |
> | `login/ragfit-monitor-login-light-928x280.png` | same | Lanczos downscale (Pillow), no other change |
> | `login/ragfit-monitor-login-light-464x140.png` | same | Lanczos downscale |
> | `login/ragfit-monitor-login-dark-1856x560.png` | `logos/ragfit/ragfit-by-en-stacked-white-transparent.png` | byte-identical copy |
> | `login/ragfit-monitor-login-dark-928x280.png` | same | Lanczos downscale |
> | `login/ragfit-monitor-login-dark-464x140.png` | same | Lanczos downscale |
> 
> Light = black ink for light backgrounds; dark = white ink for dark backgrounds.
> 
> **Not included (gap):** no SVG, no favicon (ico/16/32/192/512), no square app/sidebar icon.
> `.assets` holds no RagFit vector master and no square mark; the wordmark must not be
> redrawn or cropped into a new mark. A square RagFit mark (and ideally an SVG master)
> must first be created in `.assets` (decision: Niklas). Until then RagFit | Monitor keeps
> these slots unbranded (see README).

## Reproduce and verify

```bash
S=250d5b85b7b69dcbd0feaa9d97e6cdacc2cfaca0
for pair in light:ragfit-by-en-stacked-transparent.png dark:ragfit-by-en-stacked-white-transparent.png; do
  gh api -H "Accept: application/vnd.github.raw" \
    "repos/ErynoaGroup/.assets/contents/logos/ragfit/${pair#*:}?ref=$S" > "login-wordmark-${pair%%:*}.png"
done
git hash-object login-wordmark-light.png   # 392cb38df25a0109ae26940d9d0fe9442df6e392
git hash-object login-wordmark-dark.png    # 98c4504044a401f6c74b9bdf5403ed5fc23c9119
sha256sum -c SHA256SUMS
# f6a5d2eedf849e9052745485d951c9126a29ae80b941acd37ac66549cd07f11c  login-wordmark-light.png
# c774c69cf62adeb350f0a1f1046300669e8772e44858e4f05f54c8e3e03b068e  login-wordmark-dark.png
# 63de0ee958e8ea57815bcda6b35ae956dde6d063ebfe90cf32f7f646cf111d48  LICENSE-NOTICE.md
```
