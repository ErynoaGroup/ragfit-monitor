# Plugins and on-premises capability (risk R32)

Inventory of every plugin in the RagFit Monitor image, with its type and license and whether it runs
air-gapped. "Air-gapped" means it works with no outside calls and no cloud service; calls to data
sources that the operator configures inside the network are fine.

Basis: release `ragfit-monitor-v0.1.1` (upstream v13.2.4), `ragfit/plugins-allowlist.txt`, the
plugin sources under `public/app/plugins/` and `pkg/tsdb/`, `conf/defaults.ini`, and the vendor docs.

Verification legend:
- **code**: checked in this repository's source at v13.2.4.
- **docs**: checked in the plugin vendor's documentation.
- **unverified**: plausible, but not yet checked line by line. Treat it as open.

## Important: core data sources not in the image

Since 12.x upstream ships most data sources as separate catalog plugins: Prometheus, Loki, Tempo,
Elasticsearch, InfluxDB, MySQL, PostgreSQL, MSSQL, Jaeger, Zipkin, OpenTSDB, Google Cloud Monitoring
and Pyroscope. The upstream `make` targets download them from the public plugin catalog into
`data/plugins-bundled` (`scripts/catalog-plugins-defaults`). The Dockerfile path used by the release
runs only `make build-go`, so **none of them is in the image**. Runtime install and preinstall are
off (`preinstall` empty, enforced by `check-plugins.sh`).

The release log confirms it (code): the image check finds exactly one external plugin, Infinity
3.11.1. Any deployment that uses one of these data sources needs it added the same way as Infinity:
allowlist entry with checksums, license and type, then baked and signature-checked. Otherwise its
datasources fail after an upgrade from 12.x. This has to be settled before such a switch.

## Allowlisted and baked plugins

| Plugin | Version | Type | License | Air-gapped | Known external endpoints | Basis |
|---|---|---|---|---|---|---|
| `yesoreyeram-infinity-datasource` (Infinity) | 3.11.1 | datasource, backend (`gpx_*`) | Apache-2.0 | **Yes**, if every query URL is inside the network | Only the URLs that dashboards or the datasource configure. Without *Allowed hosts*, any host can be queried. Built-in examples and help link to public sample data (unverified). The binary makes no telemetry or licence calls (unverified). | docs (allowed hosts, base URL); code (licence and module scan in `plugin-licenses.sh`, signature check) |

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
- Decide which of the separated core data sources (Prometheus, Loki, Tempo, …) go on the allowlist,
  and bake them. Without that an air-gapped deployment has only Infinity, Graphite, Alertmanager and
  the built-ins.
- Verify the Infinity binary and its frontend for outside calls (static scan of `module.js` and an
  egress-blocked test run).
- Verify the exact AWS and Azure endpoint lists, if those plugins are ever used. Both are cloud-only.
