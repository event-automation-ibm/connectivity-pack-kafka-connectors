{{/*
###############################################################################
# Common Helper Templates
#
# This file contains helper templates shared across multiple container types.
# Used by both standard Deployment and Knative Service.
###############################################################################
*/}}

{{/*
Common volumes for all deployment types
*/}}
{{- define "ibm-connectivity-pack.commonVolumes" -}}
- name: tmp
  emptyDir:
    sizeLimit: 10Gi
- name: workdir
  emptyDir: {}
{{ if .Values.javaservice.enable -}}
- name: jvmlogs
  emptyDir: {}
- name: wlpoutput
  emptyDir: {}
{{ end }}
{{ if .Values.mcp.enable -}}
- name: mcptools
  secret:
    secretName: {{ .Values.mcp.toolsSecretName | quote }}
    items:
      - key: configuration
        path: toolsconfig.json
- name: mcpaccounts
  secret:
    secretName: {{ .Values.mcp.accountsSecretName | quote }}
    items:
      - key: configuration
        path: accounts.yaml
{{ end }}
{{ if .Values.basicAuth.enable -}}
- name: cred
  secret:
    secretName: {{ include "ibm-connectivity-pack.basicAuthCreds" . }}
    optional: true
{{ end }}
{{ if .Values.certificate.enable -}}
- name: tls-override
  configMap:
    name: {{ include "ibm-connectivity-pack.java-server-conf" . }}
    optional: true
{{ end }}
{{- include "ibm-connectivity-pack.stunnelvolume" . }}
{{- include "ibm-connectivity-pack.udaConnectors" . }}
{{- end }}