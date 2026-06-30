{{/*
###############################################################################
# Action Connectors Helper Templates
#
# This file contains helper templates for the Action Connectors container.
# Used by both standard Deployment and Knative Service.
###############################################################################
*/}}

{{/*
Action container specification
*/}}
{{- define "ibm-connectivity-pack.actionContainer" -}}
name: {{ .Values.action.name }}
resources:
  {{- toYaml .Values.action.resources | nindent 2 }}
readinessProbe:
  {{- include "ibm-connectivity-pack.actionProbe" . | nindent 2 }}
  timeoutSeconds: 30
  periodSeconds: 10
  successThreshold: 1
  failureThreshold: 3
{{- if not .Values.knative.enable }}
startupProbe:
  {{- include "ibm-connectivity-pack.actionProbe" . | nindent 2 }}
  timeoutSeconds: 1
  periodSeconds: 5
  successThreshold: 1
  failureThreshold: 120
{{- end }}
livenessProbe:
  {{- include "ibm-connectivity-pack.actionProbe" . | nindent 2 }}
  timeoutSeconds: 30
  periodSeconds: 10
  successThreshold: 1
  failureThreshold: 3
envFrom:
  - configMapRef:
      optional: true
      name: {{ include "ibm-connectivity-pack.envConfig" . }}
env:
  {{- include "ibm-connectivity-pack.actionContainerEnv" . | nindent 2 }}
ports:
  - containerPort: 3020
    protocol: TCP
securityContext:
  {{- toYaml .Values.securityContext | nindent 2 }}
imagePullPolicy: IfNotPresent
volumeMounts:
  {{- include "ibm-connectivity-pack.actionContainerVolumeMounts" . | nindent 2 }}
image: {{ .Values.image.registry }}/{{ .Values.image.path }}/{{ .Values.action.image }}@{{ .Values.action.digest }}
{{- end }}

{{/*
Action container environment variables
*/}}
{{- define "ibm-connectivity-pack.actionContainerEnv" -}}
{{- include "ibm-connectivity-pack.nodeRuntimeMetrics" . }}
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
- name: CONNECTOR_SERVICE_ROUTE
  value: {{ include "ibm-connectivity-pack.actionServiceRoute" .}}
- name: ENABLE_DYNAMIC_CREDENTIALS_MODE
  value: 'true'
- name: ENABLE_REFRESH_TOKEN_MODE
  value: {{ ternary true false (.Values.enableRefreshTokenMode) | quote }}
- name: CONNECTOR_SERVICE_PORT
  value: "3020"
- name: ENABLE_LEGACY_API_VERSIONS
  value: {{ ternary true false (.Values.enableLegacyApiVersions) | quote }}
- name: STRICT_DISCOVERY_ACCOUNT
  value: {{ ternary true false (.Values.strictdiscoveryaccount) | quote }}
- name: RATE_LIMIT_WINDOW_MS
  value: {{ .Values.rateLimitWindowMs | default "60000" | quote }}
- name: RATE_LIMIT_MAX_REQUESTS
  value: {{ .Values.rateLimitMaxRequests | default "1000" | quote }}
- name: OPENAPI_SCHEMA_NO_ANONYMOUS_TYPES
  value: {{ ternary true false (.Values.openapiSchemaNoAnonymousTypes) | quote }}
- name: FEATURE_TOGGLES_OVERRIDE
  value: "{\"epic3633-stateless-account\": 1, \"epic3627-ea-connector-service\": 1, \"epic3660-enable-refresh-token-api\": 1, \"epic19598-mssharepoint-claimcheck-src\": 1, \"epic20879-google-bigquery-enable-newschema\": 1, \"epic20879-google-bigquery-enable-upsert\": 1 }"
- name: LCP_HTTP_PORT
  value: "3020"
- name: FIREFLY_DESIGNER_RUNTIME_MODE
  value: "ACP"
- name: FIREFLY_ROUTE_EVENTS_CONNECTOR_PROVIDER
  value: {{ include "ibm-connectivity-pack.eventServiceRoute" .}}
- name: OPENAPI_FILES_MOUNT_DIRECTORY
  value: "./connectors"
- name: CONNECTOR_SERVICE
  value: 'true'
- name: DESIGNER_FLOWS_OPERATION_MODE
  value: local
- name: DEVELOPMENT_MODE
  value: 'false'
- name: FIREFLY_USERID
  value: default
- name: APPLICATION_MEM_LIMIT
  value: {{ .Values.action.resources.limits.memory }}
- name: bunyan
  value: {{ .Values.bunyan }}
- name: CONNECTOR_ACCOUNT
  value: /opt/ibm/app/accounts
- name: NAMESPACE
  value: {{ include "ibm-connectivity-pack.namespace" . }}
- name: TOKEN_STORE_SECRET_NAME
  value: {{ include "ibm-connectivity-pack.tokenStore" .}}
- name: MQSI_DISABLE_SALESFORCE_CONNECTOR
  value: '1'
- name: FIREFLY_ROUTE_LOOPBACK_CONNECTOR_PROVIDER
  value: {{ include "ibm-connectivity-pack.actionServiceRoute" .}}
- name: SERVICE_NAME
  value: {{ .Values.action.name }}
- name: WORKING_DIRECTORY
  value: /opt/ibm/app/workdir
- name: CONNECTOR_SERVICE_AUTH_CREDS_FILE
  value: "/opt/ibm/app/creds"
- name: CONNECTOR_SERVICE_EVENTS_ALLOWLIST
  value: {{- toYaml .Values.csCommon.eventList | indent 2 }}
- name: SINGLE_TENANT
  value: 'true'
- name: CONNECTOR_SERVICE_EVENTS
  value: {{ .Values.event.enable | quote }}
- name: SUBSCRIBE_PERSISTENCE
  value: k8s
- name: CONNECTOR_JAVA_SERVICE
  value: {{ include "ibm-connectivity-pack.javaServiceRoute" .}}
- name: LOOPBACK_DEFAULT_TIMEOUT
  value: {{ .Values.action.fileStreamingTimeout | quote }}
- name: MAX_CLAIMCHECK_FILE_SIZE
  value: {{ .Values.action.maxFileSize | quote }}
{{ if .Values.javaservice.enable -}}
- name: STANDALONE_CLIENT
  value: 'true'
{{ end }}
{{ if .Values.mcp.enable -}}
- name: ENABLE_MCP
  value: 'true'
- name: MCP_ACCOUNT_CONFIG_FILE
  value: '/opt/ibm/app/mcpaccounts/accounts.yaml'
- name: MCP_TOOL_CONFIG_FILE
  value: '/opt/ibm/app/mcptools/toolsconfig.json'
- name: MCP_SERVER_TRANSPORT
  value: 'StreamableHTTPServer'
{{ if .Values.enableRefreshTokenMode -}}
- name: MCP_ACCOUNT_CONFIG_SECRET_NAME
  value: {{ .Values.mcp.accountsSecretName }}
- name: MCP_ACCOUNT_CONFIG_SECRET_NAMESPACE
  value: {{ include "ibm-connectivity-pack.namespace" . }}
{{ end }}
{{ if .Values.mcp.oauth.enable -}}
- name: MCP_OAUTH_SETTINGS
  value: {{ .Values.mcp.oauth.settings | quote }}
{{ end }}
{{ end }}
- name: TECH_CONN_CCT_MODE
  value: development_mode
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
  value: {{ .Values.action.name | quote }}
{{- end }}
{{- end }}

{{/*
Action container volume mounts
*/}}
{{- define "ibm-connectivity-pack.actionContainerVolumeMounts" -}}
- name: tmp
  mountPath: /tmp
- name: workdir
  readOnly: true
  mountPath: /opt/ibm/app/workdir
{{ if .Values.mcp.enable -}}
- name: mcpaccounts
  readOnly: true
  mountPath: /opt/ibm/app/mcpaccounts
- name: mcptools
  readOnly: true
  mountPath: /opt/ibm/app/mcptools
{{ end }}
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
{{- include "ibm-connectivity-pack.udaConnectorsMount" . }}
{{- end }}