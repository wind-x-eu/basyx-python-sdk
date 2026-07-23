{{/*
Resource name for a single component: <release>-<component>, e.g. basyx-aas-repository.
Call with (dict "root" $ "name" $name).
*/}}
{{- define "basyx.componentName" -}}
{{- printf "%s-%s" .root.Release.Name .name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
PVC name for a component. Honors an optional existingClaim on the component.
Call with (dict "root" $ "name" $name "comp" $comp).
*/}}
{{- define "basyx.pvcName" -}}
{{- if and .comp.persistence .comp.persistence.existingClaim -}}
{{- .comp.persistence.existingClaim -}}
{{- else -}}
{{- printf "%s-%s-storage" .root.Release.Name .name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Common labels for a component. Call with (dict "root" $ "name" $name).
*/}}
{{- define "basyx.labels" -}}
app.kubernetes.io/name: basyx-aas-server
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/component: {{ .name }}
app.kubernetes.io/part-of: basyx-aas-server
app.kubernetes.io/managed-by: {{ .root.Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .root.Chart.Name .root.Chart.Version }}
{{- end -}}

{{/*
Selector labels for a component. Call with (dict "root" $ "name" $name).
*/}}
{{- define "basyx.selectorLabels" -}}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/component: {{ .name }}
{{- end -}}
