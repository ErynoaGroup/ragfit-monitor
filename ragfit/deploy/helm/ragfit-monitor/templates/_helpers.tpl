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
{{- if has .name (list "GF_INSTALL_PLUGINS" "GF_PLUGINS_PREINSTALL" "GF_PLUGINS_PREINSTALL_SYNC" "GF_PLUGINS_PREINSTALL_ASYNC") -}}
{{- fail (printf "%s is not allowed: plugins are baked into the image" .name) -}}
{{- end -}}
{{- if has .name (list "GF_AUTH_DISABLE_LOGIN" "GF_AUTH_DISABLE_LOGIN_FORM" "GF_AUTH_BASIC_ENABLED" "GF_AUTH_ANONYMOUS_ENABLED") -}}
{{- fail (printf "%s is not allowed in extraEnv: sign-in is fixed by grafana.ini" .name) -}}
{{- end -}}
{{- end -}}
{{- end -}}
