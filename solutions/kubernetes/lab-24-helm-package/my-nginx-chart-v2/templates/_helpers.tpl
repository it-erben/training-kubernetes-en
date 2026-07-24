{{- define "my-nginx.fullname" -}}
{{- $name := .name | trunc 63 | trimSuffix "-" -}}
{{- $prefixLength := sub 62 (len $name) | int -}}
{{- printf "%s-%s" (.root.Release.Name | trunc $prefixLength | trimSuffix "-") $name -}}
{{- end -}}
