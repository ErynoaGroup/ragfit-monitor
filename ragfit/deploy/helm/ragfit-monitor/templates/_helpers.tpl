{{- define "ragfit-monitor.name" -}}{{ .Release.Name | trunc 63 | trimSuffix "-" }}{{- end -}}
{{- define "ragfit-monitor.labels" -}}
app.kubernetes.io/name: ragfit-monitor
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
{{- define "ragfit-monitor.selector" -}}
app.kubernetes.io/name: ragfit-monitor
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
{{- define "ragfit-monitor.validate" -}}
{{- if not (regexMatch "^sha256:[a-f0-9]{64}$" .Values.image.digest) -}}
{{- fail "image.digest is required and must be sha256:<64 hex>" -}}
{{- end -}}
{{- if not (hasPrefix "https://" .Values.rootUrl) -}}{{- fail "rootUrl is required (https://...)" -}}{{- end -}}
{{- if not (hasPrefix "https://" .Values.sourceUrl) -}}{{- fail "sourceUrl is required (https://...)" -}}{{- end -}}
{{- if not .Values.oauth.existingSecret -}}{{- fail "oauth.existingSecret is required" -}}{{- end -}}
{{- range .Values.extraEnv -}}
{{- $n := toString .name -}}
{{- range $p := list "GF_AUTH_" "GF_SECURITY_" "GF_SERVER_" "GF_PATHS_" "GF_PLUGINS_" "GF_USERS_" "GF_INSTALL_PLUGINS" "RAGFIT_" -}}
{{- if hasPrefix $p $n -}}
{{- fail (printf "extraEnv %s is not allowed: %s* is fixed by the chart (sign-in, security, server, paths, plugins, users)" $n $p) -}}
{{- end -}}
{{- end -}}
{{- /* Credential-like names: matched anywhere in the name on purpose (fail closed), plus URL/DSN names that can carry user:password. */ -}}
{{- if or (regexMatch "(PASS|TOKEN|SECRET|KEY|CREDENTIAL|AUTH)" $n) (regexMatch "(_URL|_URI|_DSN|_CONNSTR|_CONNECTION_STRING)$" $n) -}}
{{- if or (hasKey . "value") (not (dig "valueFrom" "secretKeyRef" "" .)) -}}
{{- fail (printf "extraEnv %s looks like a credential or a URL that can carry one: use valueFrom.secretKeyRef, not value" $n) -}}
{{- end -}}
{{- end -}}
{{- if not (regexMatch "^(GF_(LOG|ANALYTICS|DATABASE|METRICS)_[A-Z0-9_]+|DS_[A-Z0-9_]+)$" $n) -}}
{{- fail (printf "extraEnv %s is not on the allowlist (GF_LOG_*, GF_ANALYTICS_*, GF_DATABASE_*, GF_METRICS_*, DS_* for datasource values)" $n) -}}
{{- end -}}
{{- end -}}
{{- if and .Values.networkPolicy.enabled (not .Values.networkPolicy.ingressFrom) -}}
{{- fail "networkPolicy.ingressFrom must list at least one peer when networkPolicy.enabled is true" -}}
{{- end -}}
{{- if and .Values.provisioning.secretName (not (regexMatch "^[a-z0-9]([-a-z0-9]*[a-z0-9])?$" .Values.provisioning.secretName)) -}}
{{- fail "provisioning.secretName must be a valid Secret name" -}}
{{- end -}}
{{- end -}}
