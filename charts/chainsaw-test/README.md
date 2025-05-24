# Chainsaw Test

A testing subchart to wrap [Chainsaw](https://github.com/kyverno/chainsaw) for easier Helm integration testing. **Using this chart requires basic familiarity with Chainsaw. Please refer to their [quick start docs](https://kyverno.github.io/chainsaw/latest/quick-start/).**

## Overiew

The chart provisions the following resources:

- `Job` that Chainsaw runs in for Helm tests
- `KuberhealthyCheck` for provisioning a Kuberhealthy Check
- `ConfigMap` that contains the contents a parent chart's `.chainsaw-test` directory
- `ServiceAccount` to which a RoleBinding can reference through a named template that outputs the ServiceAccount's name

## How To Use

These resources are configured with the following in **the parent helm chart**:

### Create A Role & RoleBinding In Parent Chart's `templates/test/` Directory

We need permissions to be associated with our testing resources, so we must create those resources:
```
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ...
  namespace: {{ .Release.Namespace }}
  annotations:
    helm.sh/hook-weight: "0"
rules:
  ...
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ...
  namespace: {{ .Release.Namespace }}
subjects:
  - kind: ServiceAccount
    name: {{ include "chainsaw-test.serviceAccountName" . }}
    namespace: {{ .Release.Namespace }}
roleRef:
  kind: Role
  name: ...
  apiGroup: rbac.authorization.k8s.io
```

### Add The Subchart Resources

Once created, you can add this named template to the bottom of the file:

```
---
{{- include "chainsaw-test.resources" . }}

```

This will generate all of the necessary resources for running your chart's Chainsaw tests

## Running A Chainsaw Test Locally

Writing a test will likely require some initial local testing. To begin doing this you'll likely just want to write out the test locally and invoke against a local/remote cluster from your machine.

This repo is is configured with `chainsaw` already installed via Hermit and the [quick start guide](https://kyverno.github.io/chainsaw/latest/quick-start/) can be followed for understanding how to structure the test file.
