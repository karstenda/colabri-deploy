#!/bin/bash

# Remove Colabri deployment from Kubernetes cluster
# Usage: ./teardown.sh [environment]
# Environment: gke or minikube (default: current context)

set -e

ENVIRONMENT=${1:-""}
NAMESPACE="colabri"

echo "================================================"
echo "Tearing down Colabri deployment"
echo "================================================"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed"
    exit 1
fi

# Set context based on environment
if [ "$ENVIRONMENT" == "minikube" ]; then
    echo "Setting context to minikube..."
    kubectl config use-context minikube
elif [ "$ENVIRONMENT" == "gke" ]; then
    echo "Using current GKE context..."
    # Context should already be set by deploy-gke.sh
fi

# Get current context
CURRENT_CONTEXT=$(kubectl config current-context)
echo "Current context: $CURRENT_CONTEXT"

# Confirm deletion
echo ""
echo "WARNING: This will delete all resources in namespace '$NAMESPACE'"
echo "Press Ctrl+C to cancel, or Enter to continue..."
read -r

# Delete all resources in the namespace
echo "Deleting resources in namespace '$NAMESPACE'..."

# Get the script directory and navigate to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

if [ "$ENVIRONMENT" == "gke" ]; then
    kubectl delete -k "$PROJECT_ROOT/kubernetes/overlays/gke" --ignore-not-found=true
elif [ "$ENVIRONMENT" == "minikube" ]; then
    kubectl delete -k "$PROJECT_ROOT/kubernetes/overlays/minikube" --ignore-not-found=true
else
    # Delete namespace (this will delete all resources in it)
    kubectl delete namespace "$NAMESPACE" --ignore-not-found=true
fi

echo ""
echo "================================================"
echo "Teardown completed!"
echo "================================================"

if [ "$ENVIRONMENT" == "minikube" ]; then
    echo ""
    echo "To stop minikube:"
    echo "minikube stop"
    echo ""
    echo "To delete minikube cluster:"
    echo "minikube delete"
fi
