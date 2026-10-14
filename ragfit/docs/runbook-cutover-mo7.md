# Runbook: cut over from Grafana 12.0.1 to RagFit Monitor v0.1.3 (MO7)

Generic operator runbook. It contains no instance data: hosts, addresses, namespaces, release names,
account names and secret values are kept in the private deployment repository and its slot log.
Placeholders are written as `<…>`. The general rules of
[runbook-service-account-and-oauth.md](runbook-service-account-and-oauth.md) (temp files, no secrets in
argv, SSO-only admin API, the `api` helper) apply here unchanged.

## Scope and timing
- **From:** the live upstream Grafana 12.0.1, image digest `sha256:06dc8d60…` (full value in the
  private values; record it in the slot log before step 1, it is the rollback target).
- **To:** RagFit Monitor v0.1.3, multi-arch index
  `sha256:ec4d605fd70827dc6d17ea470aab862c44f6265ae1babd2dc6e2daffa93f04a1`
  (`linux/arm64` and `linux/amd64`). Deploy by the index digest only; never by tag.
- **Not before the scheduled date** recorded in the private deploy repo.
- **Only in an assigned change slot**, with a named operator, recorded in the private slot log.
- **Out of scope:** a hostname change of the instance is a separate device action, planned in the
  private deploy repo, in its own slot. MO7 keeps the current hostname. Do not combine the two; if both are
  planned on the same day, MO7 runs first and is closed (post-checks green) before the rename starts.
- MO5 (service account revoke) and MO6 (OAuth app) are separate procedures; MO6 must be done and its
  Secret deployed before MO7, because v0.1.3 has no password login.

## Preconditions (all must hold; any failure means abort before step 1)
1. **Image verified on the target cluster by the operator**, with the pinned public key `ragfit/cosign.pub`
   (SHA-256 fingerprint `1fa4889de51c58c2656371113ad83d35cfe9910e1bdc423b0f128c80dae0a122`),
   fail-closed, no transparency log:

       img=ghcr.io/erynoagroup/ragfit-monitor@sha256:ec4d605fd70827dc6d17ea470aab862c44f6265ae1babd2dc6e2daffa93f04a1
       # the key file must match the pinned fingerprint above (same method as recorded at key creation)
       cosign verify --key ragfit/cosign.pub --insecure-ignore-tlog=true "$img" >/dev/null
       cosign verify-attestation --key ragfit/cosign.pub --insecure-ignore-tlog=true --type spdxjson "$img" >/dev/null
       cosign verify-attestation --key ragfit/cosign.pub --insecure-ignore-tlog=true --type slsaprovenance1 "$img" >/dev/null

   All three exit 0. Also check that the index lists exactly `linux/amd64` and `linux/arm64`
   (`crane manifest "$img" | jq -r '.manifests[].platform | "\(.os)/\(.architecture)"'`) and that the
   provenance names this repository and the release workflow run of v0.1.3.
2. **Deploy gate:** the deployment plan in the private deploy repo pins the same index digest, and its
   verification key is the same public key as `ragfit/cosign.pub`.
3. **MO6 done:** the OAuth app exists in RagFit | Source and the Secret named in `oauth.existingSecret`
   (keys `client_id`, `client_secret`) is present in the target namespace. The team claims
   `ErynoaGroup:platform-admin`, `ErynoaGroup:monitor-editor` and `ErynoaGroup:monitor-viewer` exist and
   at least one tester per role is a member.
4. **Database backup, fresh and verified**, taken in the slot right before step 1 (see *Backup*).
5. **Migration test passed:** a copy of that backup was started with the v0.1.3 digest in a throwaway
   namespace (no ingress, no OAuth needed) and reached `/api/health` with `"database": "ok"`; the pod log
   shows the migrations finished without errors. 12.0.1 → 13.2.4 is a forward-only schema migration, so
   this test is what makes the rollback plan (DB restore) safe to rely on.
6. **Values reviewed and merged** in the private deployment repository: `image.digest` set to the index
   digest, `nodeSelector` `kubernetes.io/arch: arm64`, `rootUrl` unchanged (current hostname),
   `sourceUrl`, `oauth.existingSecret`, provisioning. `ragfit/scripts/test-helm.sh` is green in CI.
7. **Plugin parity:** every datasource in use on 12.0.1 is covered by a plugin baked into v0.1.3
   (prometheus 13.2.3, loki 13.2.2, tempo 13.2.4, infinity 3.11.1, plus core datasources). Anything else
   is listed and accepted as unavailable before the slot (see [plugins-onprem.md](plugins-onprem.md)).
8. Rollback values (12.0.1 digest and its previous values revision) are at hand and render.

## Backup
SQLite on the PVC (chart default):

    kubectl -n <ns> scale deploy/<release> --replicas=0          # stop writes; also needed for a consistent copy
    kubectl -n <ns> wait --for=delete pod -l app.kubernetes.io/instance=<release> --timeout=120s
    # copy grafana.db from the PVC with a short-lived helper pod into the private backup store
    sha256sum <backup>/grafana.db                                  # record the hash in the slot log
    sqlite3 <backup>/grafana.db 'PRAGMA integrity_check;'          # expect: ok

External database: a native dump (`pg_dump -Fc` / `mysqldump --single-transaction`) to the private
backup store, hash recorded, and a test restore into a scratch database. Credentials come from the
secret store, never from argv. Keep the PVC/volume snapshot as a second copy where the storage supports it.

## Steps
1. Record in the slot log: start time, operator, current digest (`kubectl get deploy -o
   jsonpath='{..image}'`), backup hash.
2. With the deployment still scaled to 0 (from *Backup*), apply the reviewed values through the normal
   deployment path (Helm upgrade from the private repository). Check the rendered pod spec before it
   starts: image ends in the v0.1.3 index digest, `nodeSelector` is `kubernetes.io/arch: arm64`.
3. Scale to 1 replica. Watch the pod: scheduled on an arm64 node, migrations in the log, readiness
   on `/api/health`. Allow up to 10 minutes for migrations; abort to *Rollback* on a crash loop or a
   migration error.
4. Run the post-checks. Record each result (HTTP codes, not bodies).

## Post-checks
- **Health:** `/api/health` returns 200 with `"database": "ok"` and version 13.2.4; pod ready, no
  restarts; node arch `arm64` (`kubectl get node <node> -L kubernetes.io/arch`).
- **Image:** running image digest equals the index digest (or the arm64 child of that index).
- **SSO login via RagFit | Source:** the login page shows only the Source button; sign-in completes and
  lands on the home page with the text "Welcome to RagFit | Monitor."
- **Role mapping** (one tester each, checked with `GET /api/user/orgs` in that session):
  `ErynoaGroup:platform-admin` → Admin, `ErynoaGroup:monitor-editor` → Editor,
  `ErynoaGroup:monitor-viewer` → Viewer; an account without a matching claim is refused.
- **Negative tests:** `admin:invalid` basic auth on `GET /api/org` → 401; no-session API call → 401;
  Viewer write call → 403; anonymous access off.
- **Plugins:** `GET /api/plugins?type=datasource` lists the expected plugins and versions; no plugin
  load errors in the log; each provisioned datasource passes *Save & test*; key dashboards render data.
- **Header:** the Erynoa header renders server-side, nav shows the Monitor entry, logo link points to
  the runtime domain, light and dark theme both readable (theme switch may need a reload, issue #37).
- Existing users, teams, dashboards, folders and alert rules are present (spot check against the slot
  log counts taken before step 1).
- Close: record end time and results; take a screenshot of the header on the real system for the brand review.

## Rollback (by digest plus DB restore)
Trigger: any failed post-check that cannot be fixed by a reviewed config change within the slot.
1. Scale the deployment to 0.
2. Restore the database from the backup taken in this slot (copy `grafana.db` back onto the PVC, or
   restore the dump into the database); verify the hash / integrity check. Do **not** start 12.0.1 on
   the migrated database: the 13.2.4 schema is not supported by 12.0.1.
3. Apply the previous values revision with the 12.0.1 digest `sha256:06dc8d60…` (full value from the
   slot log), by digest only. Revert `nodeSelector` only if the previous values had none.
4. Scale to 1; check `/api/health`, sign-in as before, and the spot-check counts.
5. Record the rollback, the failed check and the time. Changes made in RagFit Monitor between step 3
   and the rollback are lost; note that in the slot log.

## Abort (before step 2)
Nothing has changed except the scale-down: scale back to 1 on the unchanged 12.0.1 values, check
`/api/health`, record the abort. The backup stays in the private store.
