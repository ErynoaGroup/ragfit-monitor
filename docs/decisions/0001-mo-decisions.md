# 0001: RagFit Monitor base and project decisions

Status: accepted, 2026-10-13. Decided by Niklas Klein.

1. Base: V = the newest stable upstream OSS release, currently v13.2.4 (commit af4a33e3786594ad72f72d97e6744010330c2977). The running instance (12.0.1) is moved to the fork in a separate major-upgrade step, see docs/plans/mo4-upgrade.md.
2. Origin is named only in LICENSE, NOTICE and MODIFICATIONS.md. No request to the upstream vendor for permission to name it elsewhere.
3. Team sync: Option A, OSS role mapping. role_attribute_path maps full team claims only; no team-sync patch.
4. Teams: ErynoaGroup:monitor-editor maps to Editor, ErynoaGroup:monitor-viewer maps to Viewer, ErynoaGroup:platform-admin maps to Admin. A bare organization claim is never accepted.
5. Organizations: a single org.
6. On-premises delivery: not planned. The MO10 gate is not active.
7. Helm templates are public in this repository under deploy/helm. Values (domain, secrets, dashboards) stay private.
8. Emergency admin access: only via the CLI inside the pod. No login-form patch.
9. Plugins: only plugins on an explicit allowlist (core plugins and freely licensed community plugins). No private-signed, enterprise or commercial plugins.
10. Maintenance: RagFit Monitor maintains the fork. Reviews are done by sister service agents, Lookout and Panorama.
