#!/bin/bash

# Create a new GKE cluster for Colabri platform
# Usage: ./setup-gke-cluster.sh [project-id] [cluster-name] [region]

set -e

# Configuration
PROJECT_ID=${1:-"my-gcp-project"}
CLUSTER_NAME=${2:-"colabri-cluster"}
REGION=${3:-"us-central1"}
MACHINE_TYPE=${4:-"e2-medium"}
NUM_NODES=${5:-3}

echo "================================================"
echo "Creating GKE Cluster"
echo "================================================"
echo "Project: $PROJECT_ID"
echo "Cluster: $CLUSTER_NAME"
echo "Region: $REGION"
echo "Machine Type: $MACHINE_TYPE"
echo "Number of Nodes: $NUM_NODES"
echo "================================================"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "Error: gcloud CLI is not installed"
    echo "Please install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Set GCP project
echo "Setting GCP project to $PROJECT_ID..."
gcloud config set project "$PROJECT_ID"

# Enable required APIs
echo "Enabling required GCP APIs..."
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com

# Create GKE cluster
echo "Creating GKE cluster (this may take several minutes)..."
gcloud container clusters create "$CLUSTER_NAME" \
    --region="$REGION" \
    --machine-type="$MACHINE_TYPE" \
    --num-nodes="$NUM_NODES" \
    --enable-autoscaling \
    --min-nodes=1 \
    --max-nodes=5 \
    --enable-autorepair \
    --enable-autoupgrade \
    --disk-size=50 \
    --disk-type=pd-standard \
    --enable-ip-alias \
    --network=default \
    --subnetwork=default \
    --enable-stackdriver-kubernetes \
    --addons=HorizontalPodAutoscaling,HttpLoadBalancing

# Get cluster credentials
echo "Getting cluster credentials..."
gcloud container clusters get-credentials "$CLUSTER_NAME" --region="$REGION"

# Verify cluster is ready
echo "Verifying cluster..."
kubectl cluster-info
kubectl get nodes

echo ""
echo "================================================"
echo "GKE Cluster created successfully!"
echo "================================================"
echo ""
echo "Cluster Name: $CLUSTER_NAME"
echo "Region: $REGION"
echo "Nodes: $NUM_NODES"
echo ""
echo "Next steps:"
echo "1. Run './deploy-gke.sh $PROJECT_ID $CLUSTER_NAME $REGION' to deploy the application"
echo "2. Configure secrets if needed"
echo "3. Update DNS settings for ingress"
echo ""
echo "To delete the cluster later:"
echo "gcloud container clusters delete $CLUSTER_NAME --region=$REGION"
