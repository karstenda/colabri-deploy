# Colabri Deploy

This project contains Kubernetes configurations and scripts to deploy the Colabri platform on Google Cloud (GKE) or locally using Minikube.

## Quick Start

### Deploy to Minikube (Local Development)

```bash
# Using scripts
cd scripts
./deploy-minikube.sh

# Or using Makefile
make deploy-minikube
```

### Deploy to GKE (Production)

```bash
# 1. Create GKE cluster
cd scripts
./setup-gke-cluster.sh my-project colabri-cluster us-central1

# 2. Deploy application
./deploy-gke.sh my-project colabri-cluster us-central1

# Or using Makefile
make setup-gke PROJECT_ID=my-project CLUSTER_NAME=colabri-cluster REGION=us-central1
make deploy-gke PROJECT_ID=my-project CLUSTER_NAME=colabri-cluster REGION=us-central1
```

## Project Structure

- **`kubernetes/base/`** - Base Kubernetes manifests (namespace, deployment, service, etc.)
- **`kubernetes/overlays/gke/`** - GKE-specific configurations
- **`kubernetes/overlays/minikube/`** - Minikube-specific configurations
- **`scripts/`** - Deployment and management scripts
- **`docs/`** - Detailed documentation

## Documentation

- 📚 [Quick Start Guide](docs/QUICK-START.md) - Get started in minutes
- 📖 [Deployment Guide](docs/DEPLOYMENT.md) - Comprehensive deployment instructions
- ⚙️ [Configuration Guide](docs/CONFIGURATION.md) - Configuration options and management
- 🤝 [Contributing](CONTRIBUTING.md) - How to contribute to this project

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
- `status.sh` - Check deployment status
- `teardown.sh` - Remove deployment from cluster

## Make Commands

Run `make help` to see all available commands:

```bash
make validate          # Validate all YAML files
make build-gke         # Build GKE manifests with kustomize
make build-minikube    # Build Minikube manifests with kustomize
make deploy-minikube   # Deploy to Minikube
make status            # Show deployment status
make test-scripts      # Test all shell scripts
```

## Getting Help

For detailed instructions, see the [deployment guide](docs/DEPLOYMENT.md).

## License

See LICENSE file for details.
