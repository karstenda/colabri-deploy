#!/bin/bash

# Deploy Colabri platform to local Minikube cluster
# Usage: ./deploy-minikube.sh

set -e

NAMESPACE="colabri"

echo "================================================"
echo "Deploying Colabri to Minikube"
echo "================================================"

# Check if minikube is installed
if ! command -v minikube &> /dev/null; then
    echo "Error: minikube is not installed"
    echo "Please install it from: https://minikube.sigs.k8s.io/docs/start/"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed"
    echo "Please install it from: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

# Check if minikube is running
if ! minikube status &> /dev/null; then
    echo "Minikube is not running. Starting minikube..."
    minikube start --driver=docker --memory=4096 --cpus=2
else
    echo "Minikube is already running."
fi

# Set kubectl context to minikube
echo "Setting kubectl context to minikube..."
kubectl config use-context minikube

# Verify connection
echo "Verifying cluster connection..."
kubectl cluster-info

# Enable required addons
echo "Enabling minikube addons..."
minikube addons enable ingress
minikube addons enable metrics-server

# Apply Kubernetes manifests using Kustomize
echo "Applying Kubernetes manifests..."
kubectl apply -k ../kubernetes/overlays/minikube

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

# Get the minikube IP and NodePort
MINIKUBE_IP=$(minikube ip)
NODE_PORT=$(kubectl get svc colabri-service -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].nodePort}')

echo ""
echo "================================================"
echo "Access your application at:"
echo "http://$MINIKUBE_IP:$NODE_PORT"
echo "================================================"

echo ""
echo "To open in browser:"
echo "minikube service colabri-service -n $NAMESPACE"

echo ""
echo "To view logs:"
echo "kubectl logs -f deployment/colabri-app -n $NAMESPACE"

echo ""
echo "To access the Kubernetes dashboard:"
echo "minikube dashboard"
