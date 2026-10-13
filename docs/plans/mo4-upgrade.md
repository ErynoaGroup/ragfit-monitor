# MO4: Upgrade of the running instance to RagFit Monitor

Status: plan. Starts only when Bedrock has assigned a slot.

## Starting point
- Running image: `docker.io/grafana/grafana-oss:12.0.1`, digest `sha256:06dc8d60e184705e5dc00e051a6d92342a44010d7d5e538d0a36339e85abb9b7`.
- Target: the signed `ragfit-monitor` release based on V, the newest stable upstream release (currently v13.2.4), pinned by digest.
- 12.0.1 to 13.x is a major upgrade with schema migrations. Downgrades are not supported, so this is its own step and is never combined with other changes.

## Steps
1. Before the slot: take inventory (version, database type, plugins, provisioned objects compared with objects created in the UI).
2. Migration test: run the target image against a copy of the production database in an isolated namespace. Check that migrations complete, dashboards and alert rules load, and every plugin on the allowlist starts.
3. In the slot: back up the database (copy of the SQLite file or pg_dump), stored outside the pod and verified by restoring it.
4. Switch the image digest through a PR in the private deployment repository.
5. Smoke tests: login only with a full team claim, 403 without one, dashboards present, a test alert reaches the contact point, and the source link shows the deployed tag and commit.

## Rollback
- Restore the database backup, then return to `docker.io/grafana/grafana-oss:12.0.1@sha256:06dc8d60e184705e5dc00e051a6d92342a44010d7d5e538d0a36339e85abb9b7`.
- The database must be restored because a 13.x schema does not run on 12.0.1.

Hostnames and domains are not part of this repository; they are set at runtime.
