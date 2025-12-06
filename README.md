# Colabri Deploy

This project contains Kubernetes configurations and scripts to deploy the Colabri platform on Google Cloud (GKE) or locally using Minikube.

## Quick Start

### Deploy to Minikube (Local Development)

```bash
cd scripts
./deploy-minikube.sh
```

### Deploy to GKE (Production)

```bash
# 1. Create GKE cluster
cd scripts
./setup-gke-cluster.sh my-project colabri-cluster us-central1

# 2. Deploy application
./deploy-gke.sh my-project colabri-cluster us-central1
```

## Project Structure

- **`kubernetes/base/`** - Base Kubernetes manifests (namespace, deployment, service, etc.)
- **`kubernetes/overlays/gke/`** - GKE-specific configurations
- **`kubernetes/overlays/minikube/`** - Minikube-specific configurations
- **`scripts/`** - Deployment and management scripts
- **`docs/`** - Detailed documentation

## Documentation

See [DEPLOYMENT.md](docs/DEPLOYMENT.md) for comprehensive deployment instructions, configuration options, and troubleshooting.

## Features

- ✅ Kubernetes manifests for containerized deployments
- ✅ Kustomize-based configuration management
- ✅ Separate configurations for GKE and Minikube
- ✅ Automated deployment scripts
- ✅ Health checks and resource limits
- ✅ ConfigMap and Secret management
- ✅ Ingress configuration for external access
- ✅ Easy setup and teardown scripts

## Requirements

- **For GKE**: `gcloud`, `kubectl`, GCP account
- **For Minikube**: `minikube`, `kubectl`, Docker

## Scripts

- `setup-gke-cluster.sh` - Create a new GKE cluster
- `deploy-gke.sh` - Deploy to Google Kubernetes Engine
- `deploy-minikube.sh` - Deploy to local Minikube
- `teardown.sh` - Remove deployment from cluster

## Getting Help

For detailed instructions, see the [deployment guide](docs/DEPLOYMENT.md).

## License

See LICENSE file for details.
