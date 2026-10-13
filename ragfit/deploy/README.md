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

There is no password login in the UI. In an emergency, run inside the pod:

    grafana cli --homepath /usr/share/grafana admin reset-admin-password <new password>

Then re-enable password login temporarily through the deployment
(`GF_AUTH_DISABLE_LOGIN=false`, `GF_AUTH_DISABLE_LOGIN_FORM=false`), fix the problem,
and revert both settings. Both steps go through a reviewed change in the deployment repository.
