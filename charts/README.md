# Helm Charts Relationship

This document describes the relationship between the Helm charts in this repository, specifically focusing on how `argo-rollouts` and `chainsaw-test` work together.

## Chart Relationship Overview

### chainsaw-test

`chainsaw-test` is a library chart that provides a framework for executing [Chainsaw](https://github.com/kyverno/chainsaw) tests against Helm deployments. As a library chart, it does not deploy standalone applications but instead provides templates and resources that can be included in other charts.

Key features:
- Provides templates for test resources including Jobs, ServiceAccounts, and ConfigMaps
- Exposes named templates that other charts can use (like `chainsaw-test.resources`)
- Supports Kuberhealthy integration for health checks

### argo-rollouts

The `argo-rollouts` chart is an application chart that:
1. Deploys the Argo Rollouts controller (via a dependency on the official Argo Helm chart)
2. Includes `chainsaw-test` as a dependency for testing the deployment

This dependency relationship is defined in `charts/argo-rollouts/Chart.yaml`:
```yaml
dependencies:
- name: argo-rollouts
  version: 2.39.3
  repository: https://argoproj.github.io/argo-helm
- name: chainsaw-test
  version: 0.1.0
  repository: file://../chainsaw-test
```

## How They Work Together

When the `argo-rollouts` chart is deployed:

1. The Argo Rollouts controller is installed via the external dependency
2. The `chainsaw-test` library chart is included, providing test capabilities
3. The `argo-rollouts` chart includes `templates/test/resources.yaml` that:
   - Creates appropriate RBAC resources (Role and RoleBinding)
   - Uses the `chainsaw-test.resources` named template to generate test resources
   - References the service account created by the `chainsaw-test` chart

These tests can be executed either:
- As standard Helm tests
- As Kuberhealthy checks on a scheduled basis (configured via `test.kuberhealthy.runInterval` in values)

## Test Implementation

The tests are executed in a containerized environment defined in `tester.yaml`, which references the `chainsaw-test:tester` image that contains the Chainsaw test harness.

---

*Documentation created with Claude Code*