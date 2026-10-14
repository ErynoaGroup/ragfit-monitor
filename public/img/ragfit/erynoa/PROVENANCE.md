# Provenance: Erynoa header in RagFit Monitor

| Item | Value |
|---|---|
| Source repository | `ErynoaGroup/.assets` (private) |
| Tag | `erynoa-header-v1.1.1` |
| Commit | `d3ccabf9d59c62b70a0d2fbeafdb12d162d57463` (only this commit; `erynoa-header-v1.1.0` is invalid, see `1.1.1/CHANGELOG.md`) |
| Package path | `templates/web/erynoa-header/` (git tree `4e579f37430c25887f9a18bb5f0099436c22a426`) |
| Copied to | `1.1.1/`: `erynoa-header.v1.css`, `erynoa-header.v1.js`, `erynoa-header.v1.html`, `erynoa-en-lockup.svg`, `SHA256SUMS`, `PROVENANCE.md`, `CHANGELOG.md`, `LICENSE`, `NOTICE.md` |
| Changes to the package files | none (byte-identical; the package `README.md` is not copied). The logo SVG sits next to the CSS, as in the package, because the CSS mask URL is relative |
| Fonts | `fonts/hanken-grotesk/HankenGrotesk-{Regular,Medium,SemiBold}.otf` and `OFL.txt`, byte-identical from `fonts/hanken-grotesk/` at the same commit (upstream `marcologous/hanken-grotesk` at `eff37d18946b018ad239cf5fd3992db5d19b82a0`, SIL OFL 1.1) |
| Checksums | `1.1.1/SHA256SUMS` (the package's own file) and `SHA256SUMS` in this directory (fonts and the RagFit Monitor files) |
| Check | `ragfit/scripts/check-erynoa-header.sh` (runs in CI) |

## How RagFit Monitor uses it

`public/views/index.html` links `1.1.1/erynoa-header.v1.css` and `ragfit-monitor-header.css`
(fonts, fixed position and page offset) and renders the partial on the server, so the bar works
without JavaScript. Compared with `1.1.1/erynoa-header.v1.html`, only these values are filled in:

- `data-erh-theme`: `light` or `dark` from the user's Grafana theme; no attribute for the `system`
  theme, so the bar follows the OS like Grafana does.
- Skip link: `#pageContent` (Grafana's main element) on the requested path, because the page's
  `<base href>` would turn a bare fragment into a link to the home page. A small optional script
  moves focus in place after client-side navigation.
- Logo link: `https://source.<domain>/`; `<domain>` and the service links use the root_url host
  minus its first label, resolved at runtime (`pkg/api/index.go`). No host is stored in the repo.

The v1.1.1 navigation has no Monitor entry, so no link carries `aria-current="page"`.

## Reproduce and verify

```bash
S=d3ccabf9d59c62b70a0d2fbeafdb12d162d57463
for f in erynoa-header.v1.css erynoa-header.v1.js erynoa-header.v1.html erynoa-en-lockup.svg SHA256SUMS PROVENANCE.md CHANGELOG.md LICENSE NOTICE.md; do
  gh api -H "Accept: application/vnd.github.raw" "repos/ErynoaGroup/.assets/contents/templates/web/erynoa-header/$f?ref=$S" | cmp - "1.1.1/$f"
done
(cd 1.1.1 && sha256sum -c SHA256SUMS) && sha256sum -c SHA256SUMS
```
