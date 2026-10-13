# Deployment configuration

`grafana.ini` is the public authentication and organization template.
The deployment repository supplies the values (domain, secrets, dashboards); they
are not part of this repository.

## Sign-in

- Only RagFit | Source, as a generic OAuth provider with PKCE and client auth in the header.
- Authorization uses only the full group claim `ErynoaGroup:<team>`:

| Group claim | Role |
|---|---|
| `ErynoaGroup:platform-admin` | Admin |
| `ErynoaGroup:monitor-editor` | Editor |
| `ErynoaGroup:monitor-viewer` | Viewer |
| anything else, including a bare `ErynoaGroup` | login refused |

- One organization (id 1). No sign-up outside OAuth, no organization creation.
- Login form, built-in password login, basic auth and anonymous access are disabled.
- `ragfit/scripts/test-role-mapping.py` checks the mapping in CI.

## Emergency admin (CLI only)

There is no password login: not in the UI and not over basic auth. The password-login settings are
never re-enabled, not even in an emergency; the Helm chart refuses to render if they are overridden.

Emergency access is the CLI inside the pod only. The password comes from stdin, so it never shows
up in argv or the shell history:

    kubectl exec -i <pod> -- grafana cli --homepath /usr/share/grafana admin reset-admin-password --password-from-stdin

If sign-in through RagFit | Source is broken, fix the OAuth configuration (client, secret, team
claims) through a reviewed change in the deployment repository. Do not open a password path.

## Helm chart

`helm/ragfit-monitor` contains the deployment templates. The values (domains, image digest,
secret names, datasources, dashboards) are supplied by the private deployment repository.

- Required values: `image.digest` (`sha256:…`, tags are not accepted), `rootUrl`, `sourceUrl`
  (both `https://`), `oauth.existingSecret` (keys `client_id`, `client_secret`).
- `files/grafana.ini` is a copy of `grafana.ini` in this directory; CI checks that both are identical.
- `extraEnv` is an allowlist: `GF_LOG_*`, `GF_ANALYTICS_*`, `GF_DATABASE_*`, `GF_METRICS_*`, and `DS_*`
  for datasource values. `GF_AUTH_*`, `GF_SECURITY_*`, `GF_SERVER_*`, `GF_PATHS_*`, `GF_PLUGINS_*`,
  `GF_USERS_*`, `GF_INSTALL_PLUGINS` and `RAGFIT_*` make rendering fail. Plugins are baked into the image.
- Datasource credentials: an existing Secret (`provisioning.secretName`), mounted read-only at
  `/run/secrets/ragfit-monitor-datasources/`, referenced in the datasources YAML with `$__file{…}`.
- Dashboards are file-provisioned with `disableDeletion: true` and `allowUiUpdates: false`.
- `ragfit/scripts/test-helm.sh` runs lint, render, leak (hostnames, IPs) and guard checks with `ci/example-values.yaml`.
