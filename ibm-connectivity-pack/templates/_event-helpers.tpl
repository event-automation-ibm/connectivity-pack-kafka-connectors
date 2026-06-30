{{/*
###############################################################################
# Event Connectors Helper Templates
#
# This file contains helper templates for the Event Connectors container.
# Used by both standard Deployment and Knative Service.
###############################################################################
*/}}

{{/*
Event container specification
*/}}
{{- define "ibm-connectivity-pack.eventContainer" -}}
name: {{ .Values.event.name }}
imagePullPolicy: IfNotPresent
resources:
  {{- toYaml .Values.event.resources | nindent 2 }}
readinessProbe:
  {{- include "ibm-connectivity-pack.eventProbe" . | nindent 2 }}
  timeoutSeconds: 4
  periodSeconds: 5
  successThreshold: 1
  failureThreshold: 1
{{- if not .Values.knative.enable }}
startupProbe:
  {{- include "ibm-connectivity-pack.eventProbe" . | nindent 2 }}
  timeoutSeconds: 1
  periodSeconds: 5
  successThreshold: 1
  failureThreshold: 120
{{- end }}
livenessProbe:
  {{- include "ibm-connectivity-pack.eventProbe" . | nindent 2 }}
  timeoutSeconds: 5
  periodSeconds: 10
  successThreshold: 1
  failureThreshold: 1
envFrom:
  - configMapRef:
      optional: true
      name: {{ include "ibm-connectivity-pack.envConfig" . }}
env:
  {{- include "ibm-connectivity-pack.eventContainerEnv" . | nindent 2 }}
securityContext:
  {{- toYaml .Values.securityContext | nindent 2 }}
ports:
  - name: ecpleadelect
    containerPort: 3003
    protocol: UDP
  - name: webhook
    containerPort: 3009
    protocol: TCP
volumeMounts:
  {{- include "ibm-connectivity-pack.eventContainerVolumeMounts" . | nindent 2 }}
image: {{ .Values.image.registry }}/{{ .Values.image.path }}/{{ .Values.event.image }}@{{ .Values.event.digest }}
{{- end }}

{{/*
Event container environment variables
*/}}
{{- define "ibm-connectivity-pack.eventContainerEnv" -}}
- name: ECP_IPC_PATH
  value: '3004'
- name: ENABLE_DYNAMIC_CREDENTIALS_MODE
  value: 'true'
- name: ENABLE_REFRESH_TOKEN_MODE
  value: {{ ternary true false (.Values.enableRefreshTokenMode) | quote }}
- name: FIREFLY_ROUTE_LOOPBACK_CONNECTOR_PROVIDER
  value: {{ include "ibm-connectivity-pack.actionServiceRoute" .}}
- name: FEATURE_TOGGLES_OVERRIDE
  value: "{\"epic3633-stateless-account\": 1, \"epic3627-ea-connector-service\": 1, \"epic3660-enable-refresh-token-api\": 1 }"
- name: CONNECTOR_SERVICE_EVENTS
  value: {{ .Values.event.enable | quote }}
- name: DESIGNER_FLOWS_OPERATION_MODE
  value: local
- name: FIREFLY_USERID
  value: default
- name: NAMESPACE
  value: {{ include "ibm-connectivity-pack.namespace" . }}
- name: SERVICE_NAME
  value: {{ include "ibm-connectivity-pack.service" .}}
- name: ECP_SERVICE_ROUTE
  value: {{ include "ibm-connectivity-pack.eventServiceRoute" .}}
- name: WCP_IPC_PATH
  value: "3009"
- name: WEBHOOK_PROVIDER_BASEURL
  value: {{ include "ibm-connectivity-pack.webhookServiceRoute" .}}
- name: LEADER_ELECTION_PORT
  value: "3003"
- name: CS_WEB_SOCKET_SERVER_PORT
  value: "3022"
- name: APPLICATION_MEM_LIMIT
  value: {{ .Values.event.resources.limits.memory }}
- name: WORKING_DIRECTORY
  value: /opt/ibm/app/workdir
- name: CONNECTOR_SERVICE_EVENTS_ALLOWLIST
  value: {{- toYaml .Values.csCommon.eventList | indent 2 }}
- name: CONNECTOR_SERVICE_ENABLE_WS
  value: 'true'
- name: CONNECTOR_ACCOUNT
  value: /opt/ibm/app/accounts
- name: POD_NAME
  valueFrom:
    fieldRef:
      apiVersion: v1
      fieldPath: metadata.name
- name: POD_IP
  valueFrom:
    fieldRef:
      fieldPath: status.podIP
{{- include "ibm-connectivity-pack.instanaEnvVars" . }}
{{- if .Values.instana.enable }}
- name: INSTANA_SERVICE_NAME
  value: {{ .Values.event.name | quote }}
{{- end }}
- name: SERVER_NAME
  value: {{ .Release.Name }}
- name: bunyan
  value: {{ .Values.bunyan }}
- name: TOKEN_STORE_SECRET_NAME
  value: {{ include "ibm-connectivity-pack.tokenStore" .}}
- name: MQSI_DISABLE_SALESFORCE_CONNECTOR
  value: '1'
- name: DEVELOPMENT_MODE
  value: 'false'
- name: SUBSCRIBE_PERSISTENCE
  value: k8s
- name: SINGLE_REPLICA
  value: 'true'
- name: CONNECTOR_SERVICE_AUTH_CREDS_FILE
  value: "/opt/ibm/app/creds"
- name: CONNECTOR_SERVICE_ENABLE_WS_PRODUCER
  value: 'true'
{{ if .Values.certificate.enable -}}
- name: SERVER_TLS_KEY_PATH
  value: /etc/stunnel/secrets/server.key.pem
- name: SERVER_TLS_CERT_PATH
  value: /etc/stunnel/secrets/server.cert.pem
{{ if .Values.certificate.MTLSenable -}}
- name: SERVER_MTLS_CA_PATH
  value: /etc/stunnel/secrets/server.ca.pem
- name: MUTUAL_AUTH
  value: {{ include "ibm-connectivity-pack.mutualAuthServiceRoute" .}}
{{ end }}
{{ end }}
{{- end }}

{{/*
Event container volume mounts
*/}}
{{- define "ibm-connectivity-pack.eventContainerVolumeMounts" -}}
- name: tmp
  mountPath: /tmp
- name: workdir
  readOnly: true
  mountPath: /opt/ibm/app/workdir
{{ if .Values.certificate.enable -}}
- name: stunnel-client
  readOnly: true
  mountPath: /opt/ibm/app/ssl
- name: stunnel-server
  mountPath: /etc/stunnel/secrets
{{ end }}
{{ if .Values.basicAuth.enable -}}
- name: cred
  readOnly: true
  mountPath: "/opt/ibm/app/creds"
{{ end }}
{{- end }}