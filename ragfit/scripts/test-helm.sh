#!/usr/bin/env bash
# Checks for the public deployment templates (no cluster needed).
set -uo pipefail
c=ragfit/deploy/helm/ragfit-monitor; v=$c/ci/example-values.yaml
fail=0
ok()  { echo "ok   $1"; }
bad() { echo "FAIL $1"; fail=1; }
cmp -s ragfit/deploy/grafana.ini "$c/files/grafana.ini" && ok "chart grafana.ini equals ragfit/deploy/grafana.ini" || bad "chart grafana.ini differs from ragfit/deploy/grafana.ini"
helm lint "$c" -f "$v" > /dev/null && ok "helm lint" || bad "helm lint"
out=$(helm template t "$c" -f "$v") && ok "renders with example values" || bad "render"
grep -q 'image: "ghcr.io/erynoagroup/ragfit-monitor@sha256:' <<< "$out" && ok "image pinned by digest" || bad "image not pinned by digest"
! grep -qE 'GF_INSTALL_PLUGINS|GF_PLUGINS_PREINSTALL' <<< "$out" && ok "no runtime plugin install" || bad "runtime plugin install in render"
grep -q 'disable_login_form = true' <<< "$out" && ok "login form disabled" || bad "login form not disabled"
# Leak check: only reserved example names may appear in the rendered output.
! grep -oE '[a-z0-9.-]+\.(ts\.net|internal|lan|local)\b' <<< "$out" | grep -v 'svc.cluster.local' | grep -q . && ok "no internal hostnames" || bad "internal hostname in render"
expect_fail() { # name args...
  local name=$1; shift
  if helm template t "$c" -f "$v" "$@" > /dev/null 2>&1; then bad "$name (rendered, should fail)"; else ok "$name"; fi
}
expect_fail "missing digest fails" --set image.digest=
expect_fail "tag instead of digest fails" --set image.digest=13.2.4
expect_fail "missing rootUrl fails" --set rootUrl=
expect_fail "http sourceUrl fails" --set sourceUrl=http://source.example.invalid
expect_fail "missing oauth secret fails" --set oauth.existingSecret=
expect_fail "GF_INSTALL_PLUGINS in extraEnv fails" --set 'extraEnv[0].name=GF_INSTALL_PLUGINS' --set 'extraEnv[0].value=x'
expect_fail "re-enabling the login form fails" --set 'extraEnv[0].name=GF_AUTH_DISABLE_LOGIN_FORM' --set 'extraEnv[0].value=false'
exit $fail
