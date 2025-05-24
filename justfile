clusterName := "chainsaw-test"
k8sVersion := "v1.33.1"
chainsawVersion := "v0.2.12"
chainsawImg := "chainsaw-test:tester"

argoRolloutsNS := "argo-rollouts"

# Show list of available commands
default:
    @just --list

# Initialize cluster, build Docker image, load it into Kind, and initialize Helm
init: start-kind docker-build kind-load-images helm-init

# Set up everything in one command: cluster, images, and all components
run: init kuberhealthy-install sleep-10s rollouts-install

# Sleep for 10 seconds to allow resources to stabilize
sleep-10s:
    @echo "Waiting 10 seconds for Kuberhealthy to stabilize..."
    @sleep 10

# Stop and delete the Kind cluster
stop: stop-kind

# Create a Kind cluster with the specified configuration
start-kind:
    @kind create cluster --name {{ clusterName }} \
        --config kind/config.yml \
        --image kindest/node:{{ k8sVersion }}

# Delete the Kind cluster
stop-kind:
    @kind delete cluster --name {{ clusterName }}

# Build the Docker image with Chainsaw, kubectl, and Argo Rollouts CLI
docker-build:
    docker buildx build -t {{ chainsawImg }} src/chainsaw-test \
        --platform=linux/arm64 \
        --build-arg CHAINSAW_VERSION={{ chainsawVersion }} \
        --build-arg K8S_VERSION={{ k8sVersion }}

# Load the built Docker image into Kind
kind-load-images:
    kind load docker-image "{{ chainsawImg }}" --name {{ clusterName }}

# Install Argo Rollouts using Helm
rollouts-install:
    helm upgrade --install argo-rollouts charts/argo-rollouts \
        --namespace {{ argoRolloutsNS }} \
        --create-namespace

# Uninstall Argo Rollouts
rollouts-uninstall:
    helm uninstall argo-rollouts --namespace {{ argoRolloutsNS }}

# Clean up Argo Rollouts by uninstalling and deleting the namespace
rollouts-cleanup: rollouts-uninstall
    kubectl delete namespace {{ argoRolloutsNS }}

# Initialize Helm with required repositories
helm-init:
    helm repo add kuberhealthy https://kuberhealthy.github.io/kuberhealthy/helm-repos

# Install Kuberhealthy for health checks and SLO reporting
kuberhealthy-install:
    helm upgrade --install kuberhealthy charts/kuberhealthy \
        -n kuberhealthy \
        --create-namespace

# Uninstall Kuberhealthy and clean up its namespace
kuberhealthy-uninstall:
    helm uninstall kuberhealthy -n kuberhealthy
    kubectl delete namespace kuberhealthy