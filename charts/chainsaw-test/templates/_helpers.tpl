{{/*
Take the tag of the chainsaw image to use from either the parent chart values
or use the default value specified in this helper function.

The `default` function fails if you try and access `.Values.test.image.tag` directly if
`.Values.test.image` is not defined at all. For this reason we can do some trickery to
use default to pull out the dictionary of `.Values.test.image` and then access the tag key.
If the `.Values.test.image` object is not defined we give it a default value of the same
structure as what we would expect to be in the parent chart values.
*/}}
{{- define "chainsaw-test.image" -}}
{{- $defaultImg := "docker.io/library/chainsaw-test:tester" }}
{{- $override :=  default (dict "image" $defaultImg) .Values.test.image }}
{{- $override.image }}
{{- end }}

{{/*
Consistent trimPrefix function for chainsaw file names
*/}}
{{- define "chainsaw-test.testFileTrimPrefix" -}}
{{ trimPrefix ".chainsaw-test/" .}}
{{- end }}

{{/*
Helper function for rendering a normalized file path as a ConfigMap key since `/`
is an invalid character in key names
*/}}
{{- define "chainsaw-test.normalizeTestFilePath" -}}
{{ regexReplaceAll "/" (include "chainsaw-test.testFileTrimPrefix" .) "."}}
{{- end }}

{{/*
Render the pod spec for the test Job or Kuberhealthy check. The pod spec is the same
between the two so we can abstract the logic into one place to make it easier to edit
properties.

For runtime-specific changes that can be passed to the process at excution time, use
annotations/labels in "chainsaw-test.jobSpec" and "chainsaw-test.khcSpec" and add an env
var to this spec.
*/}}
{{- define "chainsaw-test.podSpec" -}}
serviceAccountName: {{ include "chainsaw-test.serviceAccountName" . }}
containers:
  - name: chainsaw-runner
    image: {{ include "chainsaw-test.image" . }}
    imagePullPolicy: IfNotPresent
    # Always confine the test to the namespace it is running in
    args:
      - --namespace
      - {{ .Release.Namespace}}
    {{- with .Values.test.args }}
      {{- . | toYaml | nindent 6 }}
    {{- end }}
    env:
      - name: CHAINSAW_CONTEXT
        valueFrom:
          fieldRef:
            fieldPath: metadata.annotations['chainsaw.k8s.io/context']
      - name: AWS_REGION
        value: {{ .Values.test.region | default "us-west-2" | quote }}
    {{- with .Values.test.env }}
      {{- . | toYaml | nindent 6 }}
    {{- end }}
    {{- with .Values.test.resources }}
    resources:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    volumeMounts:
    - name: chainsaw-config-volume
      mountPath: /chainsaw
volumes:
  - name: chainsaw-config-volume
    configMap:
      name: {{ include "chainsaw-test.configMapName" . }}
      items:
      {{- range $path, $_ :=  .Files.Glob  ".chainsaw-test/**" }}
      - key: {{ include "chainsaw-test.normalizeTestFilePath" $path }}
        path: {{ include "chainsaw-test.testFileTrimPrefix" $path | quote }}
      {{- end }}
restartPolicy: Never
terminationGracePeriodSeconds: 5
{{- end }}

{{/*
Renders the Job spec for the test Job. This is the test run after an upgrade or install
of the Helm chart by either ArgoCD or Helm.

The pod spec comes from the above heper function but everything else on the Job can be managed
in this template.
*/}}
{{- define "chainsaw-test.jobSpec" -}}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .Chart.Name }}-helm-test-{{ .Release.Revision }}
  namespace: {{ .Release.Namespace }}
  annotations:
    helm.sh/hook-weight: "1"
    helm.sh/hook: post-install,post-upgrade,test
    helm.sh/hook-delete-policy: before-hook-creation,hook-succeeded
    argocd.argoproj.io/hook: PostSync
    argocd.argoproj.io/hook-delete-policy: HookSucceeded
spec:
  ttlSecondsAfterFinished: 1800
  backoffLimit: 0
  template:
    metadata:
      annotations:
        karpenter.sh/do-not-disrupt: "true"
        chainsaw.k8s.io/context: helm
      {{- if .Values.test.labels }}
      labels:
        {{- .Values.test.labels | toYaml | nindent 4 }}
      {{- end }}
    spec:
      {{- include "chainsaw-test.podSpec" . | nindent 6 }}
{{- end }}

{{/*
Renders the KuberhealthyCheck spec for that Kuberhealthy will execute on a cron.

The pod spec comes from the above heper function but everything else on the KHC can
be managed in this template.
*/}}
{{- define "chainsaw-test.khcSpec" -}}
apiVersion: comcast.github.io/v1
kind: KuberhealthyCheck
metadata:
  name: {{ .Chart.Name }}-chainsaw
  namespace: {{ .Release.Namespace }}
spec:
  runInterval: {{ default "10m" .Values.test.kuberhealthy.runInterval }}
  timeout: {{ default "5m" .Values.test.kuberhealthy.timeout }}
  extraAnnotations:
    karpenter.sh/do-not-disrupt: "true"
    chainsaw.k8s.io/context: kuberhealthy
  {{- if .Values.test.labels }}
  extraLabels:
    {{- .Values.test.labels | toYaml | nindent 4 }}
  {{- end }}
  podSpec:
    {{- include "chainsaw-test.podSpec" . | nindent 4 }}
{{- end }}

{{/*
This ConfigMap pulls the contents of a parent chart's .chainsaw-test directory into a
resource that can be mounted into the test pod.
*/}}
{{- define "chainsaw-test.chainsawConfigMap" -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "chainsaw-test.configMapName" . }}
  namespace: {{ .Release.Namespace }}
data:
{{- range $path, $_ :=  .Files.Glob  ".chainsaw-test/**" }}
{{- include "chainsaw-test.normalizeTestFilePath" $path | quote | nindent 2 }}: |-
    {{- $.Files.Get $path | nindent 4 }}
{{- end }}
{{- end }}

{{/*
This creates the ServiceAccount which will be used by the test Job and Kuberhealthy check.
*/}}
{{- define "chainsaw-test.serviceAccount" -}}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "chainsaw-test.serviceAccountName" . }}
  namespace: {{ .Release.Namespace }}
automountServiceAccountToken: true
{{- end }}

{{/*
ServiceAccountName is a helper to consistently use the name of the ServiceAccount in all the necessary
contexts. Also available to be referenced in parent charts when creating RoleBindings.
*/}}
{{- define "chainsaw-test.serviceAccountName" -}}
{{ .Chart.Name }}-chainsaw
{{- end }}

{{/*
ConfigMapName is a helper to consistently use the name of the ConfigMap in all the necessary contexts
*/}}
{{- define "chainsaw-test.configMapName" -}}
{{ .Chart.Name}}-chainsaw-config
{{- end }}


{{/*
Resources is a helper that includes all the resources needed to execute the chainsaw test as a
Kuberhealthy check or a Helm test Job.
*/}}
{{- define "chainsaw-test.resources" -}}
{{ include "chainsaw-test.serviceAccount" . }}
---
{{ include "chainsaw-test.chainsawConfigMap" . }}
{{- if not .Values.test.disableHelm }}
---
{{ include "chainsaw-test.jobSpec" . }}
{{- end }}
{{ if not .Values.test.disableKuberhealthy }}
---
{{ include "chainsaw-test.khcSpec" . }}
{{- end }}
{{- end }}
