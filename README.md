# Colabri Deployment

This repository contains Kubernetes configurations and scripts for deploying the Colabri platform.

## Deployment Guides

Please refer to the specific guide for your target environment:

- **[Local Development (Minikube)](minikube-local.md)**: Instructions for setting up and deploying Colabri locally using Minikube.
- **[Production (GKE)](gke-prd.md)**: Instructions for deploying Colabri to Google Kubernetes Engine (GKE) for production.

## Repository Structure

- `kubernetes/base`: Base Kubernetes manifests common to all environments.
- `kubernetes/overlays`: Environment-specific configurations (patches) using Kustomize.
  - `minikube-local`: Configuration for local development.
  - `gke-prd`: Configuration for production deployment on GKE.
- `scripts`: Helper scripts for deployment tasks.
