#!/bin/bash

# Deploy Colabri platform to Google Kubernetes Engine (GKE)
# Usage: ./deploy-gke.sh [project-id] [cluster-name] [region]

set -e

# Configuration
PROJECT_ID=${1:-"my-gcp-project"}
CLUSTER_NAME=${2:-"colabri-cluster"}
REGION=${3:-"us-central1"}
NAMESPACE="colabri"

echo "================================================"
echo "Deploying Colabri to GKE"
echo "================================================"
echo "Project: $PROJECT_ID"
echo "Cluster: $CLUSTER_NAME"
echo "Region: $REGION"
echo "================================================"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "Error: gcloud CLI is not installed"
    echo "Please install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed"
    echo "Please install it from: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

# Set GCP project
echo "Setting GCP project to $PROJECT_ID..."
gcloud config set project "$PROJECT_ID"

# Get cluster credentials
echo "Getting cluster credentials..."
gcloud container clusters get-credentials "$CLUSTER_NAME" --region="$REGION"

# Verify connection
echo "Verifying cluster connection..."
kubectl cluster-info

# Apply Kubernetes manifests using Kustomize
echo "Applying Kubernetes manifests..."
kubectl apply -k ../kubernetes/overlays/gke

# Wait for deployment to be ready
echo "Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s \
    deployment/colabri-app -n "$NAMESPACE"

# Get service information
echo ""
echo "================================================"
echo "Deployment completed successfully!"
echo "================================================"
echo ""
echo "Resources in namespace '$NAMESPACE':"
kubectl get all -n "$NAMESPACE"

echo ""
echo "To get the external IP (if ingress is configured):"
echo "kubectl get ingress -n $NAMESPACE"

echo ""
echo "To view logs:"
echo "kubectl logs -f deployment/colabri-app -n $NAMESPACE"

echo ""
echo "To port-forward for testing:"
echo "kubectl port-forward svc/colabri-service 8080:80 -n $NAMESPACE"
