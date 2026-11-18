{{/* Chart name, truncated to fit Kubernetes name limits. */}}
{{- define "allure.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Release-qualified name used as the prefix of every resource. */}}
{{- define "allure.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "allure.apiName" -}}
{{- printf "%s-api" (include "allure.fullname" . | trunc 59 | trimSuffix "-") }}
{{- end }}

{{- define "allure.uiName" -}}
{{- printf "%s-ui" (include "allure.fullname" . | trunc 60 | trimSuffix "-") }}
{{- end }}

{{- define "allure.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "allure.labels" -}}
helm.sh/chart: {{ include "allure.chart" . }}
app.kubernetes.io/name: {{ include "allure.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* Selector labels; call with (dict "root" $ "component" "api"). */}}
{{- define "allure.selectorLabels" -}}
app.kubernetes.io/name: {{ include "allure.name" .root }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{- define "allure.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "allure.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "allure.secretName" -}}
{{- default (include "allure.apiName" .) .Values.api.security.existingSecret }}
{{- end }}

{{- define "allure.claimName" -}}
{{- default (include "allure.apiName" .) .Values.persistence.existingClaim }}
{{- end }}

{{/* Path of the unauthenticated version endpoint, used by probes and helm test. */}}
{{- define "allure.versionPath" -}}
{{- printf "%s/allure-docker-service/version" .Values.api.urlPrefix }}
{{- end }}

{{/* URL browsers use to reach the API, given to the UI. */}}
{{- define "allure.publicApiUrl" -}}
{{- if .Values.ui.publicApiUrl }}
{{- .Values.ui.publicApiUrl }}
{{- else if .Values.ingress.enabled }}
{{- $scheme := ternary "https" "http" (not (empty .Values.ingress.tls)) }}
{{- printf "%s://%s%s" $scheme .Values.ingress.api.host .Values.api.urlPrefix }}
{{- else }}
{{- fail "ui.publicApiUrl is required when ui.enabled is true and ingress.enabled is false" }}
{{- end }}
{{- end }}

{{/* Pod settings shared by the API and UI deployments. */}}
{{- define "allure.podSpec" -}}
serviceAccountName: {{ include "allure.serviceAccountName" . }}
automountServiceAccountToken: false
{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
securityContext:
  {{- toYaml .Values.podSecurityContext | nindent 2 }}
{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
