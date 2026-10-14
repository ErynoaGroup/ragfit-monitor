# Runbook: revoke a service account (MO5) and create the OAuth app for sign-in (MO6)

Generic operator runbook for RagFit Monitor. It contains no instance data: names of accounts, tokens,
hosts, addresses and team memberships of a real deployment are kept in the private deployment
repository and its slot log, never here. Placeholders are written as `<…>`.

## Rules for both procedures
- **Only in an assigned change slot**, with a named operator, and recorded in the private slot log.
- **No admin basic auth.** Never send `admin:<password>` or any real user password over HTTP. The only
  basic-auth call allowed is the negative test with the deliberately wrong pair `admin:invalid`.
- **Admin API only through an SSO session**, and only after the role mapping is deployed
  (`role_attribute_path` with `role_attribute_strict = true`, see `ragfit/deploy/grafana.ini`), so the
  operator holds the Admin role through a full team claim. Any other path needs a documented one-time
  exception from the owner of the deployment.
- **No secrets in argv, shell history, logs or chat.** `curl -K -` reads headers from stdin; a session
  cookie or token is never typed on the command line.
- **Temp files:** `umask 077`, paths from `mktemp`, and a `trap` that shreds them on every exit:

      umask 077
      tmp=$(mktemp -d)
      trap 'find "$tmp" -type f -exec shred -u {} + 2>/dev/null; rm -rf "$tmp"' EXIT

- Responses go only into files under `$tmp`. Read single fields with `jq -r`; never print whole JSON
  bodies (they can contain secrets).

Helper used below (the session cookie is read from a file under `$tmp`, never from argv):

    api() { # api <METHOD> <path>
      printf 'header = "Cookie: grafana_session=%s"\n' "$(cat "$tmp/session")" \
        | curl -sS -K - -X "$1" -o "$tmp/out" -w '%{http_code}\n' "$GRAFANA_URL$2"
    }

`GRAFANA_URL` is the public base URL of the instance (set in the shell, not written into this
repository). How the operator obtains the SSO session cookie (browser developer tools into a file
under `$tmp`, or an equivalent private procedure) is described in the private deployment repository.

## Order and dependencies
- **MO6 → MO7 → MO5.** The OAuth app (MO6) and its Secret must exist before the cutover to RagFit
  Monitor (MO7, [runbook-cutover-mo7.md](runbook-cutover-mo7.md)), because the image has no password
  login. MO5 needs an Admin through SSO with the role mapping, which only exists after MO7.
- The hostname rename `grafana` → `monitor` (devstack #418) is a separate device action. It changes
  `<monitor-root-url>` and therefore the MO6 redirect URI (see MO6, *Hostname change*).
- None of these procedures is run from this repository or by CI. Each one needs its own slot.

---

## MO5: revoke a service account

Revoke means: delete the service account and with it every token. It is not a rotation; nothing new is
issued.

### Prerequisites
- Decision to revoke recorded (owner, reason, slot) in the private tracker. The account is referred to
  by its numeric id `<sa-id>` only.
- Role mapping deployed and an operator with the Admin role through a full team claim
  (`ErynoaGroup:<admin-team>`).
- A fresh, verified database backup (see the rollback note below).
- A list of consumers of the account (dashboards, automations) and confirmation that they are stopped
  or moved. Consumers that still use the token will fail with 401 after the step.
- Run by Bedrock in an assigned slot. The account's name may appear in the private slot log only; this
  repository and public tickets use `<sa-id>`.

### Steps
1. Set up `$tmp`, the `trap` and the `api` helper; put the session cookie into `$tmp/session`.
2. Confirm the session is an Admin, through SSO:

       api GET /api/user/orgs            # expect 200
       jq -r '.[] | select(.orgId==1) | .role' "$tmp/out"   # expect Admin

3. Look up the account and record only id, login and role in the slot log (no token data):

       api GET /api/serviceaccounts/<sa-id>       # expect 200
       jq -r '.id, .login, .role' "$tmp/out"
       api GET /api/serviceaccounts/<sa-id>/tokens
       jq -r 'length' "$tmp/out"                  # number of tokens only
       jq -r '.[] | [.id, .lastUsedAt, .expiration] | @tsv' "$tmp/out"   # no token values

   If a token was used after the consumers were reported stopped, abort: a consumer is still active.

4. Delete the account (this deletes its tokens):

       api DELETE /api/serviceaccounts/<sa-id>    # expect 200

### Verification
- `api GET /api/serviceaccounts/<sa-id>` returns 404.
- The old token is rejected: the person or system that held the token runs one read call with it, from
  a file and through `curl -K -`, and gets **401**. The token itself is never handed to the operator.
- Negative test: basic auth with `admin:invalid` against `GET /api/org` returns **401**.
- `api GET /api/serviceaccounts/search?query=<sa-login>` does not list the account.
- Record date, time, operator and the HTTP codes in the slot log.

### Rollback
A deleted service account and its tokens cannot be restored by the API. Rollback is not a restore of
the database (that would also roll back every other change). If a consumer still needs access, create a
**new** service account with the least role needed, an expiry, and a named owner, through the same
SSO session, and hand the token over through the secret store of the deployment. Record it as a new
decision.

### Abort
Stop before step 4 if any prerequisite fails. Log out of the SSO session, let the `trap` shred `$tmp`
(check that it is gone), and record the abort in the slot log. Nothing is left half-done because step 4
is the only write.

---

## MO6: create the OAuth app in RagFit | Source for Monitor sign-in

### Prerequisites
- An owner account in RagFit | Source for the organization that will own the app.
- The teams used for roles exist in Source and are named in the claim pattern `ErynoaGroup:<team>`
  (full `Org:team` claims only; a bare organization claim is never accepted). Membership is managed by
  people in Source, not by the app.
- The public base URL of the Monitor instance is known (`<monitor-root-url>`, from the private
  deployment values).
- A secret store for the client secret (the private deployment repository's encrypted secrets or a
  Kubernetes Secret created from them).

### Steps
1. In Source, as the organization owner, open the organization settings, *Applications*, and create a
   new OAuth2 application:
   - **Name:** `RagFit Monitor`
   - **Redirect URI:** `<monitor-root-url>/login/generic_oauth` (exact match, https only, no
     wildcard)
   - **Confidential client:** on (Monitor keeps the secret server-side)
2. Copy the client id and the client secret **directly into the secret store**. The secret is shown
   once; never paste it into chat, tickets, shell commands or this repository.
3. Reference both values only as a secret: the chart expects an existing Secret with the keys
   `client_id` and `client_secret` (`oauth.existingSecret`), mounted and read through `$__file{}`
   in `grafana.ini`.
4. Settings on the Monitor side (already in `ragfit/deploy/grafana.ini`; do not change them per
   instance):
   - `scopes = openid profile email groups`
   - `use_pkce = true` (PKCE with S256; Source supports PKCE for confidential clients, so it is on)
   - `groups_attribute_path = groups`, `allowed_groups` and `role_attribute_path` with full
     `ErynoaGroup:<team>` claims, `role_attribute_strict = true`
   - `auth_url`, `token_url`, `api_url` built from the Source base URL at runtime
5. Deploy the Secret and the configuration through the normal reviewed deployment path.
6. Record in the slot log: app name, owner, creation time, redirect URI (as `<monitor-root-url>/…`
   placeholder in public places), and where the secret is stored. Never the client secret.

### Hostname change
The redirect URI is an exact match. When the rename `grafana` → `monitor` (devstack #418) is done, the
app's redirect URI and `rootUrl` change in the same slot: add the new URI in Source, deploy the new
`rootUrl`, verify sign-in on the new name, then remove the old URI. No redirect from the old name is
kept, so the old URI has no use afterwards.

**On hold by Niklas since 2026-10-14 14:51.** The deployment reconciler does not patch an existing
Source OAuth app; it only checks for drift. Changing `redirect_uris` needs a run with
`ROTATE_GRAFANA=1`, which makes Source issue a **new client secret** into the Secret
`monitoring/oidc-source-grafana` and then requires a Grafana restart to pick it up. This is a secret
action: it runs only after Niklas's explicit OK, in an assigned slot, and is recorded in the slot log.

### Verification
- A member of an admin team signs in through Source and `GET /api/user/orgs` (with that session) shows
  the expected role.
- A member of an editor or viewer team gets Editor or Viewer.
- An account without a matching team claim is refused (no session, no new user); an API call without
  a valid session returns **401**, a call above the user's role returns **403**.
- `admin:invalid` basic auth returns **401**.
- The redirect URI in Source matches exactly; a changed redirect is rejected by Source.
- The authorization request carries `code_challenge_method=S256` (PKCE active), visible in the
  browser's network panel; the token request authenticates the client in the header.
- Signing out of Monitor ends the session; a new sign-in goes through Source again.

### Rollback
- Configuration error: revert the deployment change; the previous sign-in configuration returns.
- Leaked or wrong secret: regenerate the client secret in Source, replace it in the secret store,
  redeploy. The old secret stops working at once.
- Remove the app: delete the OAuth2 application in Source; all its grants and tokens end. Sign-in
  through Source then fails until a new app exists, so keep the CLI emergency path in mind (`grafana
  cli admin reset-admin-password --password-from-stdin` inside the pod).

### Abort
If the app was created but not deployed, delete it in Source (or keep it unused and record that),
remove any partial secret from the secret store, and record the abort. If the deployment was started,
revert it through the normal path. Never re-enable the password login form as a shortcut.
