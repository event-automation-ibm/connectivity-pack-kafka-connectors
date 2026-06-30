{{/*
Return releaseNameOverride
*/}}
{{- define "ibm-connectivity-pack.releaseNameOverride" -}}
{{- if .Values.releaseNameOverride }}
{{- .Values.releaseNameOverride }}
{{- else }}
{{- .Release.Name }}
{{- end }}
{{- end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "ibm-connectivity-pack.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "ibm-connectivity-pack.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name (include "ibm-connectivity-pack.releaseNameOverride" .) }}
{{- include "ibm-connectivity-pack.releaseNameOverride" . | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" (include "ibm-connectivity-pack.releaseNameOverride" .) $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "ibm-connectivity-pack.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "ibm-connectivity-pack.labels" -}}
helm.sh/chart: {{ include "ibm-connectivity-pack.chart" . }}
{{ include "ibm-connectivity-pack.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/rand-key: {{randAlphaNum 13 | nospace}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "ibm-connectivity-pack.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ibm-connectivity-pack.name" . }}
app.kubernetes.io/instance: {{ include "ibm-connectivity-pack.releaseNameOverride" . }}
{{- end }}

{{/*
Create the name of the deployment
*/}}
{{- define "ibm-connectivity-pack.deploymentName" -}}
{{- if include "ibm-connectivity-pack.releaseNameOverride" . }}
{{- default (include "ibm-connectivity-pack.releaseNameOverride" .) }}-deployment
{{- end }}
{{- end }}

{{/*
Return namespace
*/}}
{{- define "ibm-connectivity-pack.namespace" -}}
{{- if .Values.namespace }}
{{- .Values.namespace }}
{{- else }}
{{- .Release.Namespace }}
{{- end }}
{{- end }}

{{/*
Create the name of the serviceAccount
*/}}
{{- define "ibm-connectivity-pack.serviceAccountName" -}}
{{- if include "ibm-connectivity-pack.releaseNameOverride" . }}
{{- default (include "ibm-connectivity-pack.releaseNameOverride" .) }}-service-account
{{- end }}
{{- end }}

{{/*
Create the name of the config-map
*/}}
{{- define "ibm-connectivity-pack.configMap" -}}
{{- if include "ibm-connectivity-pack.releaseNameOverride" . }}
{{- default (include "ibm-connectivity-pack.releaseNameOverride" .) }}-configmap
{{- end }}
{{- end }}

{{/*
Create the name of the token store secret
*/}}
{{- define "ibm-connectivity-pack.tokenStore" -}}
{{- if include "ibm-connectivity-pack.releaseNameOverride" . }}
{{- default (include "ibm-connectivity-pack.releaseNameOverride" .) }}-ts
{{- end }}
{{- end }}

{{/*
Create the name of the basic auth secret
*/}}
{{- define "ibm-connectivity-pack.basicAuthCreds" -}}
{{- if include "ibm-connectivity-pack.releaseNameOverride" . }}
{{- default (include "ibm-connectivity-pack.releaseNameOverride" .) }}-creds
{{- end }}
{{- end }}

{{/*
Create the name of the basic auth password
*/}}
{{- define "ibm-connectivity-pack.basicAuthPassword" -}}
{{- if include "ibm-connectivity-pack.releaseNameOverride" . }}
{{- randAlphaNum 13 | nospace -}}
{{- end }}
{{- end }}

{{/*
Create the name of the service
*/}}
{{- define "ibm-connectivity-pack.service" -}}
{{- if include "ibm-connectivity-pack.releaseNameOverride" . }}
{{- default (include "ibm-connectivity-pack.releaseNameOverride" .) }}-service
{{- end }}
{{- end }}

{{/*
Create the Connector service URL
Connector services are accessible via: <service-name>.<namespace>.svc.cluster.local
This URL will trigger pod spawn when invoked (scale-from-zero)
*/}}
{{- define "ibm-connectivity-pack.connectorServiceUrl" -}}
{{- if .Values.knative.enable }}
{{- printf "%s.%s.svc.cluster.local" (include "ibm-connectivity-pack.deploymentName" .) (include "ibm-connectivity-pack.namespace" .) }}
{{- else }}
{{- printf "%s.%s.svc.cluster.local" (include "ibm-connectivity-pack.service" .) (include "ibm-connectivity-pack.namespace" .) }}
{{- end }}
{{- end }}

{{/*
Create the event service route
*/}}
{{- define "ibm-connectivity-pack.eventServiceRoute" -}}
{{- if .Values.certificate.enable }}
{{- printf "https://%s:3004" (include "ibm-connectivity-pack.service" .) }}
{{- else }}
{{- printf "http://%s:3004" (include "ibm-connectivity-pack.service" .) }}
{{- end }}
{{- end }}

{{/*
Create the action service route
*/}}
{{- define "ibm-connectivity-pack.actionServiceRoute" -}}
{{- if .Values.certificate.enable }}
{{- printf "https://%s:3001" (include "ibm-connectivity-pack.service" .) }}
{{- else }}
{{- printf "http://%s:3001" (include "ibm-connectivity-pack.service" .) }}
{{- end }}
{{- end }}

{{/*
Create the webhook service route
*/}}
{{- define "ibm-connectivity-pack.webhookServiceRoute" -}}
{{- if .Values.certificate.enable }}
{{- printf "https://%s:3009" (include "ibm-connectivity-pack.service" .) }}
{{- else }}
{{- printf "http://%s:3009" (include "ibm-connectivity-pack.service" .) }}
{{- end }}
{{- end }}

{{/*
Create the mutal auth service route
*/}}
{{- define "ibm-connectivity-pack.mutualAuthServiceRoute" -}}
{{- printf "https://%s" (include "ibm-connectivity-pack.service" .) }}
{{- end }}

{{/*
Create the java service route
*/}}
{{- define "ibm-connectivity-pack.javaServiceRoute" -}}
{{- if .Values.certificate.enable }}
{{- printf "https://%s:9080/connector-java-services/_lcp_jdbc_connect" (include "ibm-connectivity-pack.service" .) }}
{{- else }}
{{- printf "http://%s:9080/connector-java-services/_lcp_jdbc_connect" (include "ibm-connectivity-pack.service" .) }}
{{- end }}
{{- end }}

{{/*
Create the role
*/}}
{{- define "ibm-connectivity-pack.role" -}}
{{- if include "ibm-connectivity-pack.releaseNameOverride" . }}
{{- default (include "ibm-connectivity-pack.releaseNameOverride" .) }}-role
{{- end }}
{{- end }}

{{/*
Create the rolebinding
*/}}
{{- define "ibm-connectivity-pack.rolebinding" -}}
{{- if include "ibm-connectivity-pack.releaseNameOverride" . }}
{{- default (include "ibm-connectivity-pack.releaseNameOverride" .) }}-rolebinding
{{- end }}
{{- end }}

{{/*
Create the networkpolicy
*/}}
{{- define "ibm-connectivity-pack.networkpolicy" -}}
{{- if include "ibm-connectivity-pack.releaseNameOverride" . }}
{{- default (include "ibm-connectivity-pack.releaseNameOverride" .) }}-networkpolicy
{{- end }}
{{- end }}

{{/*
Create the name for image pull secret name
*/}}
{{- define "ibm-connectivity-pack.imagePullSecretname" -}}
{{- if eq .Values.image.imagePullSecretName  "" }}
{{- default (include "ibm-connectivity-pack.releaseNameOverride" .) }}-image-pull-cred
{{ else }}
{{- .Values.image.imagePullSecretName }}
{{- end }}
{{- end }}

{{/*
Create the name for image pull secret
*/}}
{{- define "ibm-connectivity-pack.imagePullSecret" -}}
{{- if eq .Values.image.imagePullSecretName  "" }}
{{- printf "{\"%s\":{\"username\": \"%s\", \"password\": \"%s\", \"email\": \"%s\" }}" .Values.image.registry .Values.image.imagePullUsername .Values.image.imagePullPassword .Values.image.imagePullEmail }}
{{- end }}
{{- end }}

{{/*
Create the name for stunnel server cert secret
*/}}
{{- define "ibm-connectivity-pack.stunnelServer" -}}
{{- if .Values.certificate.serverSecretName }}
{{- .Values.certificate.serverSecretName }}
{{- else }}
{{- default (include "ibm-connectivity-pack.releaseNameOverride" .) }}-server-certificate
{{- end }}
{{- end }}

{{/*
Create the name for stunnel client cert secret
*/}}
{{- define "ibm-connectivity-pack.stunnelClient" -}}
{{- if .Values.certificate.clientSecretName }}
{{- .Values.certificate.clientSecretName }}
{{- else }}
{{- default (include "ibm-connectivity-pack.releaseNameOverride" .) }}-client-certificate
{{- end }}
{{- end }}


{{- define "ibm-connectivity-pack.stunnelvolume" -}}
{{ if .Values.certificate.enable -}}
- name: stunnel-server
  secret:
    secretName: {{ include "ibm-connectivity-pack.stunnelServer" . }}
    items:
      - key: {{ .Values.certificate.serverCertKeyPropertyName }}
        path: server.key.pem
      - key: {{ .Values.certificate.serverCertPropertyName }}
        path: server.cert.pem
      - key: {{ .Values.certificate.caCertPropertyName }}
        path: server.ca.pem
      {{ if .Values.javaservice.enable -}}
      - key: {{ .Values.certificate.serverKeyStrorePKCSPropertyName }}
        path: server.p12
      - key: {{ .Values.certificate.serverTrustStorePKCSPropertyName }}
        path: truststore.p12
      {{ end }}
{{ if .Values.certificate.MTLSenable -}}
- name: stunnel-client
  secret:
    secretName: {{ include "ibm-connectivity-pack.stunnelClient" . }}
    items:
    - key: {{ .Values.certificate.caCertPropertyName }}
      path: stunnel.ca.pem     
    - key:  {{ .Values.certificate.clientCertPropertyName }}
      path: stunnel.cert.pem
    - key: {{ .Values.certificate.clientCertKeyPropertyName }}
      path: stunnel.key.pem
{{- else }}
- name: stunnel-client
  secret:
    secretName: {{ include "ibm-connectivity-pack.stunnelServer" . }}
    items:
    - key: {{ .Values.certificate.serverCertKeyPropertyName }}
      path: stunnel.key.pem
    - key: {{ .Values.certificate.serverCertPropertyName }}
      path: stunnel.cert.pem
    - key: {{ .Values.certificate.caCertPropertyName }}
      path: stunnel.ca.pem   
{{- end }}
{{- end }}
{{- end }}


{{/*
Create the name for Horizontal Pod Autoscaler
*/}}
{{- define "ibm-connectivity-pack.hpa" -}}
{{- if include "ibm-connectivity-pack.releaseNameOverride" . }}
{{- default (include "ibm-connectivity-pack.releaseNameOverride" .) }}-hpa
{{- end }}
{{- end }}

{{/*
Create the name of prehook job
*/}}
{{- define "ibm-connectivity-pack.preHookJob" -}}
{{- if include "ibm-connectivity-pack.releaseNameOverride" . }}
{{- default (include "ibm-connectivity-pack.releaseNameOverride" .) }}-prehook-job
{{- end }}
{{- end }}

{{/*
Create the name of the posthook job
*/}}
{{- define "ibm-connectivity-pack.postDeleteHookJob" -}}
{{- if include "ibm-connectivity-pack.releaseNameOverride" . }}
{{- default (include "ibm-connectivity-pack.releaseNameOverride" .) }}-post-delete-job
{{- end }}
{{- end }}


{{/*
Create the name of the service
*/}}
{{- define "ibm-connectivity-pack.preHookJobSa" -}}
{{- if include "ibm-connectivity-pack.releaseNameOverride" . }}
{{- include "ibm-connectivity-pack.preHookJob" . }}-sa
{{- end }}
{{- end }}


{{/*
Create the name of the service
*/}}
{{- define "ibm-connectivity-pack.preHookJobRole" -}}
{{- if include "ibm-connectivity-pack.releaseNameOverride" . }}
{{- include "ibm-connectivity-pack.preHookJob" . }}-creator
{{- end }}
{{- end }}

{{/*
Create the name of the service
*/}}
{{- define "ibm-connectivity-pack.preHookJobRoleBinding" -}}
{{- if include "ibm-connectivity-pack.releaseNameOverride" . }}
{{- include "ibm-connectivity-pack.preHookJob" . }}-creator-binding
{{- end }}
{{- end }}

{{/*
Create the name of the service
*/}}
{{- define "ibm-connectivity-pack.config" -}}
{{- if include "ibm-connectivity-pack.releaseNameOverride" . }}
{{- default (include "ibm-connectivity-pack.releaseNameOverride" .) }}-config
{{- end }}
{{- end }}

{{/*
Create the name of the service
*/}}
{{- define "ibm-connectivity-pack.envConfig" -}}
{{- if include "ibm-connectivity-pack.releaseNameOverride" . }}
{{- default (include "ibm-connectivity-pack.releaseNameOverride" .) }}-env-config
{{- end }}
{{- end }}

{{/*
Create the name of the java service TLS
*/}}
{{- define "ibm-connectivity-pack.java-server-conf" -}}
{{- if include "ibm-connectivity-pack.releaseNameOverride" . }}
{{- default (include "ibm-connectivity-pack.releaseNameOverride" .) }}-java-server-config
{{- end }}
{{- end }}


{{/*
Create UDA connector configmap volume
*/}}
{{- define "ibm-connectivity-pack.udaConnectors" -}}
{{- if .Values.action.udaPersistentVolumeClaimName }}
- name: {{ .Values.action.udaPersistentVolumeClaimName }}-uda-vol
  persistentVolumeClaim:
    claimName: {{ .Values.action.udaPersistentVolumeClaimName }}
{{- else }}
{{- $root := . }}
{{- $files := $root.Files.Glob "connectors/*.{json,yaml,yml,car}" }}
{{- range $path, $file := $files }}
- name: {{ base $path | replace "." "-" | lower }}-vol
  configMap:
    name: {{ base $path | replace "." "-" | lower }}-{{- default  $root.Release.Name  }}-config
{{- end }}
{{- end }}
{{- end }}

{{/*
Create UDA connector configmap volume mount
*/}}
{{- define "ibm-connectivity-pack.udaConnectorsMount" -}}
{{- if .Values.action.udaPersistentVolumeClaimName }}
- name: {{ .Values.action.udaPersistentVolumeClaimName }}-uda-vol
  mountPath: /opt/ibm/app/connectors
{{- else }}
{{- $files := .Files.Glob "connectors/*.{json,yaml,yml,car}" }}
{{- range $path, $file := $files }}
- name: {{ base $path | replace "." "-" | lower }}-vol
  mountPath: /opt/ibm/app/connectors/{{ base $path }}
  subPath: {{ base $path }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Render environment variables for node-runtime-metrics
*/}}
{{- define "ibm-connectivity-pack.nodeRuntimeMetrics" }}
{{- if hasKey .Values.action "enableMetrics" }}
- name: ENABLE_METRICS
  value: {{ ternary "true" "false" (eq .Values.action.enableMetrics "true") | quote }}
{{- end }}
{{- if hasKey .Values.action "metricsRotationWindowSec" }}
- name: METRICS_ROTATION_WINDOW_SEC
  value: {{ .Values.action.metricsRotationWindowSec | quote }}
{{- end }}
{{- if hasKey .Values.action "metricsDirectory" }}
- name: METRICS_DIRECTORY
  value: {{ .Values.action.metricsDirectory | quote }}
{{- end }}
{{- if hasKey .Values.action "metricsCollectIntervalMs" }}
- name: METRICS_COLLECT_INTERVAL_MS
  value: {{ .Values.action.metricsCollectIntervalMs | quote }}
{{- end }}
{{- end }}


{{/*
Action probe
*/}}
{{- define "ibm-connectivity-pack.actionProbe" -}}
{{- if .Values.certificate.enable }}
exec:
  command:
    - /bin/sh
    - -c
    - |
{{- if .Values.certificate.MTLSenable }}
      curl --cert /opt/ibm/app/ssl/stunnel.cert.pem --key /opt/ibm/app/ssl/stunnel.key.pem --cacert /opt/ibm/app/ssl/stunnel.ca.pem --silent --fail -k https://localhost:3020/admin/ready || exit 1
{{ else }}
      curl --silent --fail -k https://localhost:3020/admin/ready || exit 1
{{- end }}
{{ else }}
httpGet:
  path: /admin/ready
  port: 3020
  scheme: HTTP
{{- end }}
{{- end }}

{{/*
Event probe
*/}}
{{- define "ibm-connectivity-pack.eventProbe" -}}
{{- if .Values.certificate.enable }}
exec:
  command:
    - /bin/sh
    - -c
    - |
{{- if .Values.certificate.MTLSenable }}    
      curl --cert /opt/ibm/app/ssl/stunnel.cert.pem --key /opt/ibm/app/ssl/stunnel.key.pem --cacert /opt/ibm/app/ssl/stunnel.ca.pem --silent --fail -k https://localhost:3004/admin/ready || exit 1
{{ else }}
      curl --silent --fail -k https://localhost:3004/admin/ready || exit 1
{{- end }}
{{ else }}
httpGet:
  path: /admin/ready
  port: 3004
  scheme: HTTP
{{- end }}
{{- end }}

{{/*
Javaservice probe
*/}}
{{- define "ibm-connectivity-pack.javaserviceprobe" -}}
{{- if .Values.certificate.enable }}
exec:
  command:
    - /bin/sh
    - -c
    - |
{{- if .Values.certificate.MTLSenable }}
      curl --cert /opt/ibm/app/ssl/stunnel.cert.pem --key /opt/ibm/app/ssl/stunnel.key.pem --cacert /opt/ibm/app/ssl/stunnel.ca.pem --silent --fail -k https://localhost:9080/ || exit 1
{{ else }}
      curl --silent --fail -k https://localhost:9080/ || exit 1
{{- end }}
{{ else }}
httpGet:
  path: /
  port: 9080
  scheme: HTTP
{{- end }}
{{- end }}

{{/*
Common Instana environment variables
*/}}
{{- define "ibm-connectivity-pack.instanaEnvVars" -}}
{{- if .Values.instana.enable }}
- name: INSTANA_ENABLE
  value: "true"
- name: INSTANA_AGENT_HOST
  valueFrom:
    fieldRef:
      apiVersion: v1
      fieldPath: status.hostIP
- name: INSTANA_DISABLE_USE_OPENTELEMETRY
  value: {{ .Values.instana.disableUseOpentelemetry | quote }}
- name: INSTANA_PROCESS_NAME
  value: {{ .Release.Name | quote }}
{{- end }}
{{- end }}