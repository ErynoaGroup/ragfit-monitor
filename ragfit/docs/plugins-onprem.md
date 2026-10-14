# Plugins and on-premises capability (risk R32)

Inventory of every plugin in the RagFit Monitor image, with its type and license and whether it runs
air-gapped. "Air-gapped" means it works with no outside calls and no cloud service; calls to data
sources that the operator configures inside the network are fine.

Basis: release `ragfit-monitor-v0.1.3` (upstream v13.2.4), `ragfit/plugins-allowlist.txt`, the
plugin sources under `public/app/plugins/` and `pkg/tsdb/`, `conf/defaults.ini`, and the vendor docs.

Verification legend:
- **code**: checked in this repository's source at v13.2.4.
- **docs**: checked in the plugin vendor's documentation.
- **unverified**: plausible, but not yet checked line by line. Treat it as open.

## Separated core data sources

Since 12.x upstream ships most data sources as separate catalog plugins: Prometheus, Loki, Tempo,
Elasticsearch, InfluxDB, MySQL, PostgreSQL, MSSQL, Jaeger, Zipkin, OpenTSDB, Google Cloud Monitoring
and Pyroscope. The upstream `make` targets download them from the public plugin catalog into
`data/plugins-bundled` (`scripts/catalog-plugins-defaults`). The Dockerfile path used by the release
runs only `make build-go`, so none of them comes from the upstream build. Runtime install and
preinstall are off (`preinstall` empty, enforced by `check-plugins.sh`).

Up to v0.1.1 the image therefore contained only Infinity as an external plugin. Prometheus, Loki and
Tempo are now on the allowlist and baked the same way as Infinity: pinned version and checksums per
architecture, license and type, and a signature check against the pinned key. Their catalog ids are
`prometheus`, `loki` and `tempo` (`plugin.json` id), and their binaries are named
`gpx_grafana-<name>-datasource`. The pinned version is the one the catalog selects for Grafana 13.2.4,
the same selection the upstream download script uses. The other separated data sources are not baked;
a deployment that needs one adds it through a reviewed allowlist PR.

## Allowlisted and baked plugins

| Plugin | Version | Type | License | Air-gapped | Known external endpoints | Basis |
|---|---|---|---|---|---|---|
| `yesoreyeram-infinity-datasource` (Infinity) | 3.11.1 | datasource, backend (`gpx_*`) | Apache-2.0 | **Yes**, if every query URL is inside the network | Only the URLs that dashboards or the datasource configure. Without *Allowed hosts*, any host can be queried. Built-in examples and help link to public sample data (unverified). The binary makes no telemetry or licence calls (unverified). | docs (allowed hosts, base URL); code (licence and module scan in `plugin-licenses.sh`, signature check) |
| `prometheus` (Prometheus) | 13.2.3 | datasource, backend (`gpx_*`) | AGPL-3.0-only | **Yes**, with an internal Prometheus | Only the configured Prometheus URL. Optional cloud auth (AWS SigV4, Azure) is used only when it is configured (unverified in detail). | code (`LICENSE` in the package, signature, license and module scan) |
| `loki` (Loki) | 13.2.2 | datasource, backend (`gpx_*`) | AGPL-3.0-only | **Yes**, with an internal Loki | Only the configured Loki URL; live tailing goes through the instance (unverified in detail) | code (`LICENSE` in the package, signature, license and module scan) |
| `tempo` (Tempo) | 13.2.4 | datasource, backend (`gpx_*`) | AGPL-3.0-only | **Yes**, with an internal Tempo | Only the configured Tempo URL and the linked data sources configured for traces to logs or metrics (unverified in detail) | code (`LICENSE` in the package, signature, license and module scan) |

### Source, integrity and signature of the baked plugins

| Plugin | Source | SHA-256 linux-arm64 zip | SHA-256 linux-amd64 zip | Signature |
|---|---|---|---|---|
| `yesoreyeram-infinity-datasource` 3.11.1 | public plugin catalog | `4d42f7525d495f40274436674e8ae0768e10545fb3bc6fe71c7750517cddcd9f` | `422668d177ff14de3c97f3b128cee09890d04aa767e4513bb7b6c5336fa737d7` | `MANIFEST.txt`, checked offline against the pinned plugin signing key |
| `prometheus` 13.2.3 | public plugin catalog | `a49bb6a6fe6e79578dc78841ce7f437a50d294a0fdb74bf25214cd6ce75d85db` | `8bdd6583e398f84d497dabec0287563b9eee471d711dea08a21482db5cd5a294` | same |
| `loki` 13.2.2 | public plugin catalog | `7351ef25f01bf5347ad0db13b66a8cbc8b6b91272dc11f42ea2d700a3ac60163` | `0d1f5794d34febc54e55ac05ac92ea4ad6548ec3f2521865116c9ed46f7d55e9` | same |
| `tempo` 13.2.4 | public plugin catalog | `b55cc94908ea2736d783940b2dc503d6217e83e014e8705e5a16d6887fb4c3d5` | `a89fa4ee83a61e58dac30eae3ce42ae6f677545d05e419b88f0a6f5f6cfdf8e7` | same |

The source of truth is `ragfit/plugins-allowlist.txt`; this table mirrors it for v0.1.3. The package
is downloaded at build time from the catalog download endpoint (`fetch-plugins.sh`), rejected unless
its SHA-256 matches the pin, then `verify-plugin-signature.sh` checks `MANIFEST.txt` (signature, id,
version, per-file SHA-256) and `check-plugins.sh` / `plugin-licenses.sh` check type, license and the
Go modules in the backend binary. Any mismatch fails the build. Runtime installs are off, so the
image contains exactly these versions. The image itself is signed with the release key and carries
SPDX SBOM and SLSA provenance attestations.

### How to update a baked plugin
1. Pick the version the catalog lists as compatible with the Grafana version of this fork.
2. In one reviewed PR, change the line in `ragfit/plugins-allowlist.txt` (version and both SHA-256
   values) and the tables in this file. `verify-plugin-pins.sh` recomputes the checksums from the
   catalog; never copy them from a third party.
3. CI runs the pin, signature, license and bake checks for both architectures; a new Go module with a
   non-compatible license needs a reviewed entry in `ragfit/license-exceptions.txt` or the update is
   dropped.
4. Release a new image through the release workflow and deploy it by digest. Rollback is the previous
   image digest; plugins are never installed or downgraded inside a running pod.
5. Adding a new plugin follows the same path, plus the policy in `ragfit/PLUGINS.md`.

Recommendation: provision Infinity with `jsonData.allowedHosts` listing only internal hosts. Infinity
requires allowed hosts anyway once authentication or custom headers are set.

## Core plugins compiled into the image

All are part of this repository: licence AGPL-3.0-only, version = Grafana version (`%VERSION%` in
`plugin.json`, here 13.2.4). Every `plugin.json` also contains documentation links to the vendor
website. Those are plain links, not calls.

### Data sources
| Plugin | Type | Air-gapped | Known external endpoints | Basis |
|---|---|---|---|---|
| `grafana` (built-in, `-- Grafana --`) | datasource, backend | Yes | none | code |
| `dashboard` (`-- Dashboard --`) | datasource, frontend | Yes | none | code |
| `mixed` (`-- Mixed --`) | datasource, frontend | Yes | none | code |
| `grafana-testdata-datasource` | datasource, backend | Yes | none (generated data) | code |
| `alertmanager` | datasource, frontend | Yes, with an internal Alertmanager | the configured Alertmanager URL | code |
| `graphite` | datasource, backend | Yes, with an internal Graphite | the configured Graphite URL | code |
| `cloudwatch` | datasource, backend | **No**, needs AWS | AWS regional service endpoints (CloudWatch, Logs, STS, EC2/tagging), or custom endpoints in the settings | code (AWS SDK); exact list unverified |
| `grafana-azure-monitor-datasource` | datasource, backend | **No**, needs Azure | Azure Resource Manager, Entra ID login, Log Analytics / Application Insights, and `metrics.monitor.azure.*` per cloud (public, US gov, China) | code (`metrics.monitor.azure.*`); other hosts from the Azure SDK cloud settings, unverified |

### Panels
| Plugin | Air-gapped | Known external endpoints | Basis |
|---|---|---|---|
| `alertlist`, `annolist`, `barchart`, `bargauge`, `candlestick`, `dashlist`, `debug`, `flamegraph`, `gauge`, `heatmap`, `histogram`, `logs`, `logstable`, `nodeGraph`, `piechart`, `stat`, `state-timeline`, `status-history`, `table`, `timeseries`, `traces`, `trend`, `xychart` | Yes | none (data comes from the server API) | code (URL scan: only documentation links) |
| `live` | Yes | the instance's own websocket | code |
| `canvas` | Yes, with local images | only image or icon URLs that a dashboard sets | code |
| `text` | Yes, with local content | only content a dashboard embeds (HTML or Markdown with external images or links) | code |
| `gettingstarted` | Yes | links to the vendor tutorials and docs; reads only the local `/api/plugins` | code |
| `welcome` | Yes | links to the vendor docs, community forum and chat | code |
| `news` | **No** by default | `https://grafana.com/blog/news.xml` as the default feed, or any feed URL a dashboard sets | code (`DEFAULT_FEED_URL`) |
| `geomap` | **No** by default | Default base layer from CARTO (`basemaps.cartocdn.com`). Optional layers: ArcGIS (`services.arcgisonline.com`), OpenStreetMap, Stadia Maps (`tiles.stadiamaps.com`, sample style), XYZ or MapLibre URLs set by users. The gazetteers are local files. | code (`layers/basemaps/*.ts`, CSP default `*.cartocdn.com`) |

## Server settings with outside calls (not plugins, relevant to R32)

From `conf/defaults.ini` (code). The values are upstream defaults. `ragfit/deploy/grafana.ini` does not
change them today:

| Setting | Default | Effect | Air-gapped value |
|---|---|---|---|
| `[analytics] reporting_enabled` | `true` | usage stats to the vendor | `false` |
| `[analytics] check_for_updates`, `check_for_plugin_updates` | `true` | version checks against the vendor | `false` |
| `[analytics] feedback_links_enabled` | `true` | links only | either |
| `[security] disable_gravatar` / `gravatar_url` | `false` / public Gravatar | avatar images from Gravatar | `true` |
| `[news] news_feed_enabled` | `false` in `defaults.ini` (code default `true` if unset) | news drawer feed from the vendor | `false` (set explicitly) |
| `[plugins] plugin_catalog_url`, `public_key_retrieval_disabled` | vendor catalog / `false` | catalog links; key retrieval for signature checks | `public_key_retrieval_disabled = true` (the static key is built in) |
| `[geomap] default_baselayer_config`, `enable_custom_baselayers` | CARTO / `true` | see geomap | set an internal tile server, or accept no base map |
| `[security] content_security_policy_template` | allows `grafana.com`, `*.cartocdn.com` | browser connect targets | drop both when air-gapped |

These are recommendations for an on-premises deployment. Changing them is a separate, reviewed
configuration change.

## Open items
- Decide whether further separated core data sources (Elasticsearch, PostgreSQL, …) go on the
  allowlist. Prometheus, Loki and Tempo are baked.
- Run the same egress-blocked test for Prometheus, Loki and Tempo.
- Verify the Infinity binary and its frontend for outside calls (static scan of `module.js` and an
  egress-blocked test run).
- Verify the exact AWS and Azure endpoint lists, if those plugins are ever used. Both are cloud-only.
