# Chainsaw Test Harness

A demo repository using [Chainsaw](https://github.com/kyverno/chainsaw) to validate user journeys with [Argo Rollouts](https://argoproj.github.io/rollouts/) blue-green deployments.

## Overview

This repository demonstrates how to:

1. Define and test critical user journeys in Kubernetes
2. Validate blue/green deployment workflows with declarative tests
3. Ensure reliable experiences through automated journey validation
4. Connect user journey success metrics to SLOs
5. Package journey validations for continuous monitoring

The project serves as a practical example of validating Kubernetes platform user journeys using Chainsaw and Argo Rollouts.

## What is Chainsaw?

[Chainsaw](https://kyverno.github.io/chainsaw) is a testing framework for Kubernetes that allows you to:

- Define tests in a declarative YAML format
- Apply Kubernetes resources and wait for specific conditions
- Test complex deployment scenarios in a reproducible way
- Execute scripts as part of test steps
- Assert on resource states and conditions

## Repository Structure

- `/charts` - Helm charts for testing
  - `argo-rollouts` - Chart for testing Argo Rollouts
  - `chainsaw-test` - Library chart for Chainsaw tests
  - `kuberhealthy` - Chart for health checking
- `/kind` - Kind cluster configuration
- `/src`
  - `chainsaw-test` - Docker image responsible for running Chainsaw tests

## Prerequisites

- Docker

You'll also need the following tools, which can be installed manually or via Hermit (see below):

- [Chainsaw](https://github.com/kyverno/chainsaw)
- [Kind](https://kind.sigs.k8s.io/)
- [Just](https://github.com/casey/just)
- [Helm](https://helm.sh/)
- kubectl

## Development Environment

### Option 1: Using Hermit (Recommended)

This repository uses [Hermit](https://cashapp.github.io/hermit/) to manage development tools. Using Hermit is **optional but recommended** as it automatically installs all required tools at the correct versions.

Activate the Hermit environment:

```bash
source bin/activate-hermit
```

This command will automatically install and configure:

- chainsaw
- helm
- just
- kind
- kubectl

Once activated, these tools will be available in your PATH. You'll know Hermit is active when you see a confirmation message like "Hermit environment activated".

### Option 2: Manual Installation

If you prefer not to use Hermit, you can manually install the required tools:

1. Install chainsaw: [Chainsaw Installation](https://kyverno.github.io/chainsaw/latest/installation/)
2. Install kind: [Kind Installation](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
3. Install just: [Just Installation](https://github.com/casey/just#installation)
4. Install helm: [Helm Installation](https://helm.sh/docs/intro/install/)
5. Install kubectl: [kubectl Installation](https://kubernetes.io/docs/tasks/tools/)

## Getting Started

### One-step Setup (Recommended)

Set up everything with a single command:

```bash
just run
```

This command will:

1. Create a Kind cluster
2. Build and load the Chainsaw test image
3. Install Kuberhealthy for health checks
4. Install Argo Rollouts

### Manual Setup

Alternatively, you can set up components individually:

```bash
# Initialize cluster and build image
just init

# Install Kuberhealthy
just kuberhealthy-install

# Install Argo Rollouts
just rollouts-install
```

## User Journey: Blue/Green Deployments

This repository validates a critical platform user journey: **safely deploying application updates using blue/green strategy**.

The journey consists of these key steps:

1. User deploys initial application version ("blue")
2. User updates to new version ("green") which creates a preview environment
3. User verifies the new version works correctly in the preview
4. User promotes the new version to production
5. Platform ensures the transition completes successfully

The test validates that this journey works reliably and consistently for platform users. It ensures the Argo Rollouts controller correctly manages the transition between versions, handling service routing and scaling as expected.

## Running Tests Locally

For local development and testing:

```bash
# If using Hermit, activate it first (optional but recommended)
source bin/activate-hermit

# Navigate to the test directory
cd charts/argo-rollouts/.chainsaw-test

# Run the test with chainsaw
chainsaw test -v --namespace argo-rollouts
```

This test will:

1. Create initial "blue" deployment
2. Update to "green" deployment
3. Simulate user promotion of the new version
4. Validate successful completion
5. Assert on the final state

## From User Journeys to SLOs

This repository demonstrates how to connect user journey validation to platform observability:

- **Journey Definitions**: Clearly defined user workflows in declarative format
- **Automated Validation**: Tests that simulate real user interactions
- **Continuous Monitoring**: Journey tests run as periodic health checks
- **SLO Generation**: Journey success rates drive platform reliability metrics
- **Alerting**: Detect journey failures before they impact users

These integrations help platform teams ensure users can successfully accomplish their tasks on the platform and maintain reliability metrics based on actual user workflows.

## Cleanup

To delete the Kind cluster:

```bash
just stop
```

## Available Commands

The repository includes several useful commands managed through [Just](https://github.com/casey/just):

```bash
just                    # List all available commands
just run                # Setup everything in one command (recommended)
just init               # Initialize cluster, build image, setup Helm
just kuberhealthy-install # Install Kuberhealthy for health checks
just rollouts-install   # Install Argo Rollouts
just stop               # Delete the Kind cluster
just rollouts-cleanup   # Remove Argo Rollouts and its namespace
just kuberhealthy-uninstall # Remove Kuberhealthy and its namespace
```

These commands are fully documented in the justfile and can be viewed by running `just --list`.

## Additional Resources

This repository serves as a companion to the talk "Kubernetes Platform User Journeys & SLOs" presented at [DASH 2025](https://www.dashcon.io/sessions/kubernetes-platform-user-journeys-slos/).

---

*Documentation created with Claude Code*
