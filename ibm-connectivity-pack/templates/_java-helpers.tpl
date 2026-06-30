{{/*
###############################################################################
# Java Service Helper Templates
#
# This file contains helper templates for the Java Service container.
# Used by both standard Deployment and Knative Service.
###############################################################################
*/}}

{{/*
Java service container specification
*/}}
{{- define "ibm-connectivity-pack.javaServiceContainer" -}}
name: {{ .Values.javaservice.name }}
imagePullPolicy: IfNotPresent
resources:
  {{- toYaml .Values.javaservice.resources | nindent 2 }}
readinessProbe:
  {{- include "ibm-connectivity-pack.javaserviceprobe" . | nindent 2 }}
  timeoutSeconds: 30
  periodSeconds: 10
  successThreshold: 1
  failureThreshold: 3
{{- if not .Values.knative.enable }}
startupProbe:
  {{- include "ibm-connectivity-pack.javaserviceprobe" . | nindent 2 }}
  timeoutSeconds: 5
  periodSeconds: 5
  successThreshold: 1
  failureThreshold: 30
  initialDelaySeconds: 15
{{- end }}
livenessProbe:
  {{- include "ibm-connectivity-pack.javaserviceprobe" . | nindent 2 }}
  timeoutSeconds: 30
  periodSeconds: 10
  successThreshold: 1
  failureThreshold: 3
securityContext:
  capabilities:
    drop:
      - ALL
  privileged: false
  runAsNonRoot: true
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  seccompProfile:
    type: RuntimeDefault
env:
  {{- include "ibm-connectivity-pack.javaServiceContainerEnv" . | nindent 2 }}
  {{- include "ibm-connectivity-pack.instanaEnvVars" . | nindent 2 }}
  {{- if .Values.instana.enable }}
  - name: INSTANA_SERVICE_NAME
    value: {{ .Values.javaservice.name | quote }}
  {{- end }}
volumeMounts:
  {{- include "ibm-connectivity-pack.javaServiceContainerVolumeMounts" . | nindent 2 }}
ports:
  - name: javaservice
    containerPort: 9080
    protocol: TCP
image: {{ .Values.image.registry }}/{{ .Values.image.path }}/{{ .Values.javaservice.image }}@{{ .Values.javaservice.digest }}
{{- end }}

{{/*
Java service container environment variables
*/}}
{{- define "ibm-connectivity-pack.javaServiceContainerEnv" -}}
- name: NAMESPACE
  value: {{ include "ibm-connectivity-pack.namespace" . }}
{{ if .Values.certificate.enable -}}
- name: SERVER_TLS_KEYSTORE_PATH
  value: /etc/stunnel/secrets/server.p12
- name: PKCS_PASSWORD
  value: {{ .Values.certificate.pkcsPassword | quote }}
{{ if .Values.certificate.MTLSenable -}}
- name: SERVER_MTLS_TRUSTSTORE_PATH
  value: /etc/stunnel/secrets/truststore.p12
{{ end }}
{{ end }}
{{- end }}

{{/*
Java service container volume mounts
*/}}
{{- define "ibm-connectivity-pack.javaServiceContainerVolumeMounts" -}}
{{ if .Values.certificate.enable -}}
- name: stunnel-server
  mountPath: /etc/stunnel/secrets
- name: stunnel-client
  readOnly: true
  mountPath: /opt/ibm/app/ssl
- name: tls-override
  mountPath: /opt/ol/wlp/usr/servers/defaultServer/configDropins/overrides/
{{ end }}
- name: jvmlogs
  mountPath: /logs/
- name: wlpoutput
  mountPath: /opt/ol/wlp/output
{{- end }}