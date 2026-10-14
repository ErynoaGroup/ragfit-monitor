# Provenance: Erynoa header in RagFit Monitor

| Item | Value |
|---|---|
| Source repository | `ErynoaGroup/.assets` (private) |
| Tag | `erynoa-header-v1.1.4` |
| Commit | `ab60361029df2f9f0f5d7ba0ed2702ece9ec0ab1` (only this commit; not v1.1.0 to v1.1.3) |
| Package path | `templates/web/erynoa-header/` (git tree `f0dff220317afe49bad728f8c9eb02c3d6f29908`) |
| Copied to | `1.1.4/`: `erynoa-header.v1.css`, `erynoa-header.v1.js`, `erynoa-header.v1.html`, `erynoa-en-lockup.svg`, `SHA256SUMS`, `PROVENANCE.md`, `CHANGELOG.md`, `LICENSE`, `NOTICE.md` |
| Changes to the package files | none (byte-identical; the package `README.md` is not copied). The logo is an inline `<svg>` with `<use>` references to `erynoa-en-lockup.svg` in the same versioned folder (`__ERH_ASSET_BASE__`) |
| Fonts | `fonts/hanken-grotesk/HankenGrotesk-{Regular,Medium,SemiBold}.otf` and `OFL.txt`, byte-identical from `fonts/hanken-grotesk/` at the same commit (upstream `marcologous/hanken-grotesk` at `eff37d18946b018ad239cf5fd3992db5d19b82a0`, SIL OFL 1.1) |
| Checksums | `1.1.4/SHA256SUMS` (the package's own file) and `SHA256SUMS` in this directory (fonts and the RagFit Monitor files) |
| Check | `ragfit/scripts/check-erynoa-header.sh` (runs in CI) |

## How RagFit Monitor uses it

`public/views/index.html` links `1.1.4/erynoa-header.v1.css` and `ragfit-monitor-header.css`
(fonts, fixed position and page offset) and renders the partial on the server, so the bar works
without JavaScript. Compared with `1.1.4/erynoa-header.v1.html`, only these values are filled in:

- `data-erh-theme`: `light` or `dark` from the user's Grafana theme; no attribute for the `system`
  theme, so the bar follows the OS like Grafana does.
- Skip link: `#pageContent` (Grafana's main element) on the requested path, because the page's
  `<base href>` would turn a bare fragment into a link to the home page. A small optional script
  moves focus in place after client-side navigation.
- Asset base (`__ERH_ASSET_BASE__`): the versioned folder `public/build/img/ragfit/erynoa/1.1.4/` with a trailing slash, same origin. The web component (and its `assets` attribute) is not used; the page renders the partial on the server.
- Logo link: `https://source.<domain>/`; `<domain>` and the service links use the root_url host
  minus its first label, resolved at runtime (`pkg/api/index.go`). No host is stored in the repo.
  Fail closed: without a derivable base domain (no root_url host, an IP address, or fewer than
  three labels such as localhost) the page renders no header, no skip script and no header stylesheets.

- Current service: the Monitor entry (new in 1.1.2) carries `aria-current="page"` (`current="monitor"`).

## Reproduce and verify

```bash
S=ab60361029df2f9f0f5d7ba0ed2702ece9ec0ab1
for f in erynoa-header.v1.css erynoa-header.v1.js erynoa-header.v1.html erynoa-en-lockup.svg SHA256SUMS PROVENANCE.md CHANGELOG.md LICENSE NOTICE.md; do
  gh api -H "Accept: application/vnd.github.raw" "repos/ErynoaGroup/.assets/contents/templates/web/erynoa-header/$f?ref=$S" | cmp - "1.1.4/$f"
done
(cd 1.1.4 && sha256sum -c SHA256SUMS) && sha256sum -c SHA256SUMS
```
