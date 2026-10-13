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
has() { grep -qE -- "$2" <<< "$out" && ok "$1" || bad "$1"; }
hasnt() { grep -qE -- "$2" <<< "$out" && bad "$1" || ok "$1"; }
has "image pinned by digest" 'image: "ghcr.io/erynoagroup/ragfit-monitor@sha256:[0-9a-f]{64}"'
hasnt "no runtime plugin install" 'GF_INSTALL_PLUGINS|GF_PLUGINS_PREINSTALL'
has "login form disabled" 'disable_login_form = true'
has "basic auth disabled" '^\s+enabled = false'
has "runAsGroup 472" 'runAsGroup: 472'
has "service links off" 'enableServiceLinks: false'
has "datasource secret mounted read-only" 'mountPath: /run/secrets/ragfit-monitor-datasources'
has "datasource credential via \$__file" '\$__file\{/run/secrets/ragfit-monitor-datasources/'
hasnt "no plain secureJsonData values" 'basicAuthPassword: [^$]'
# Leak check: no internal hostnames and no IPs other than the loopback/unspecified addresses.
hasnt "no internal hostnames" '[a-z0-9-]+\.(ts\.net|internal|lan|home\.arpa)\b|tail[0-9a-f]{6}'
ips=$(grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' <<< "$out" | grep -vxE '127\.0\.0\.1|0\.0\.0\.0' || true)
[ -z "$ips" ] && ok "no IP addresses" || bad "IP addresses in render: $(tr '\n' ' ' <<< "$ips")"
leak_probe=$(printf 'url: http://100.64.1.2:9090\nurl: http://10.0.0.5\n' | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | grep -vxE '127\.0\.0\.1|0\.0\.0\.0' | wc -l)
[ "$leak_probe" = 2 ] && ok "IP leak check catches 100.64.0.0/10 and private ranges" || bad "IP leak check self-test"
expect_fail() { # name args...
  local name=$1; shift
  if helm template t "$c" -f "$v" "$@" > /dev/null 2>&1; then bad "$name (rendered, should fail)"; else ok "$name"; fi
}
expect_ok() {
  local name=$1; shift
  if helm template t "$c" -f "$v" "$@" > /dev/null 2>&1; then ok "$name"; else bad "$name (should render)"; fi
}
expect_fail "missing digest fails" --set image.digest=
expect_fail "tag instead of digest fails" --set image.digest=13.2.4
expect_fail "missing rootUrl fails" --set rootUrl=
expect_fail "http sourceUrl fails" --set sourceUrl=http://source.example.invalid
expect_fail "missing oauth secret fails" --set oauth.existingSecret=
expect_fail "invalid datasource secret name fails" --set provisioning.secretName=Bad_Name
env_fail() { expect_fail "extraEnv $1 fails" --set "extraEnv[0].name=$1" --set 'extraEnv[0].value=x'; }
# one per rejected prefix
for p in GF_AUTH_X GF_SECURITY_X GF_SERVER_X GF_PATHS_X GF_PLUGINS_X GF_USERS_X RAGFIT_X; do env_fail "$p"; done
# named keys
for k in GF_AUTH_GENERIC_OAUTH_ROLE_ATTRIBUTE_PATH GF_AUTH_GENERIC_OAUTH_ALLOWED_GROUPS GF_AUTH_PROXY_ENABLED \
         GF_AUTH_JWT_ENABLED GF_AUTH_ANONYMOUS_ENABLED GF_AUTH_ANONYMOUS_ORG_ROLE GF_AUTH_DISABLE_LOGIN \
         GF_AUTH_DISABLE_LOGIN_FORM GF_AUTH_BASIC_ENABLED GF_SECURITY_ADMIN_PASSWORD GF_SECURITY_DISABLE_INITIAL_ADMIN_CREATION \
         GF_SERVER_ROOT_URL GF_PATHS_CONFIG GF_PATHS_PLUGINS GF_PLUGINS_ALLOW_LOADING_UNSIGNED_PLUGINS \
         GF_PLUGINS_PREINSTALL GF_INSTALL_PLUGINS GF_USERS_ALLOW_SIGN_UP GF_USERS_AUTO_ASSIGN_ORG_ROLE \
         GF_FEATURE_TOGGLES_ENABLE GF_RENDERING_SERVER_URL RAGFIT_SOURCE_URL PATH; do env_fail "$k"; done
expect_ok "extraEnv GF_LOG_LEVEL renders" --set 'extraEnv[0].name=GF_LOG_LEVEL' --set 'extraEnv[0].value=info'
expect_ok "extraEnv GF_DATABASE_TYPE renders" --set 'extraEnv[0].name=GF_DATABASE_TYPE' --set 'extraEnv[0].value=sqlite3'
exit $fail
