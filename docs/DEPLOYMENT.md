# Colabri Platform Deployment Guide

This guide explains how to deploy the Colabri platform on Google Kubernetes Engine (GKE) or locally using Minikube.

## Prerequisites

### Common Requirements
- `kubectl` (Kubernetes CLI) - [Installation Guide](https://kubernetes.io/docs/tasks/tools/)
- `git` for cloning this repository

### For GKE Deployment
- Google Cloud Platform account
- `gcloud` CLI - [Installation Guide](https://cloud.google.com/sdk/docs/install)
- GCP project with billing enabled
- Required IAM permissions to create GKE clusters

### For Minikube Deployment
- `minikube` - [Installation Guide](https://minikube.sigs.k8s.io/docs/start/)
- Docker or another supported driver
- At least 4GB of free RAM

## Project Structure

```
colabri-deploy/
├── kubernetes/
│   ├── base/                    # Base Kubernetes manifests
│   │   ├── namespace.yaml       # Namespace definition
│   │   ├── deployment.yaml      # Application deployment
│   │   ├── service.yaml         # Service definition
│   │   ├── configmap.yaml       # Configuration
│   │   ├── secret.yaml.example  # Secret template
│   │   └── ingress.yaml         # Ingress configuration
│   └── overlays/
│       ├── gke/                 # GKE-specific configurations
│       └── minikube/            # Minikube-specific configurations
├── scripts/
│   ├── setup-gke-cluster.sh     # Create GKE cluster
│   ├── deploy-gke.sh            # Deploy to GKE
│   ├── deploy-minikube.sh       # Deploy to Minikube
│   └── teardown.sh              # Remove deployment
└── docs/
    └── DEPLOYMENT.md            # This file
```

## Deployment Options

### Option 1: Deploy to Google Kubernetes Engine (GKE)

#### Step 1: Create GKE Cluster

```bash
cd scripts
./setup-gke-cluster.sh [project-id] [cluster-name] [region]
```

Example:
```bash
./setup-gke-cluster.sh my-gcp-project colabri-cluster us-central1
```

This script will:
- Enable required GCP APIs
- Create a GKE cluster with autoscaling
- Configure kubectl to use the new cluster

#### Step 2: Configure Your Container Image

Update the deployment to use your actual container image:

```bash
# Edit kubernetes/base/deployment.yaml
# Replace PROJECT_ID with your actual GCP project ID
# Replace v1.0.0 with your actual image tag
nano kubernetes/base/deployment.yaml
```

Or use Kustomize image transformer by adding to `kubernetes/overlays/gke/kustomization.yaml`:
```yaml
images:
- name: gcr.io/PROJECT_ID/colabri-app
  newName: gcr.io/my-actual-project/colabri-app
  newTag: v1.0.0
```

#### Step 3: Configure Secrets (Optional)

If your application requires secrets:

```bash
# Copy the example secret file
cp kubernetes/base/secret.yaml.example kubernetes/base/secret.yaml

# Edit and add your base64-encoded secrets
# Example: echo -n 'my-password' | base64
nano kubernetes/base/secret.yaml
```

#### Step 4: Deploy Application

```bash
./deploy-gke.sh [project-id] [cluster-name] [region]
```

Example:
```bash
./deploy-gke.sh my-gcp-project colabri-cluster us-central1
```

#### Step 5: Verify Deployment

```bash
# Check all resources
kubectl get all -n colabri

# Check ingress
kubectl get ingress -n colabri

# View logs
kubectl logs -f deployment/colabri-app -n colabri
```

### Option 2: Deploy to Minikube (Local Development)

#### Step 1: Deploy Application

The script will automatically start Minikube if it's not running:

```bash
cd scripts
./deploy-minikube.sh
```

This script will:
- Start Minikube (if not running)
- Enable required addons (ingress, metrics-server)
- Deploy the application
- Display access information

#### Step 2: Access Application

The script will display the access URL. You can also use:

```bash
# Get the URL
minikube service colabri-service -n colabri --url

# Or open in browser
minikube service colabri-service -n colabri
```

#### Step 3: Verify Deployment

```bash
# Check resources
kubectl get all -n colabri

# View logs
kubectl logs -f deployment/colabri-app -n colabri

# Access dashboard
minikube dashboard
```

## Configuration

### Environment Variables

Edit `kubernetes/base/configmap.yaml` to configure application settings:

```yaml
data:
  environment: "production"
  log_level: "info"
  # Add your configuration here
```

### Resource Limits

Resource limits are different for GKE and Minikube:

**GKE** (Production):
- Requests: 512Mi memory, 500m CPU
- Limits: 1Gi memory, 1000m CPU
- Replicas: 3

**Minikube** (Development):
- Requests: 128Mi memory, 100m CPU
- Limits: 256Mi memory, 250m CPU
- Replicas: 1

## Customization

### Using Kustomize

This project uses Kustomize for managing configurations. You can customize overlays:

```bash
# View the generated manifests without applying
kubectl kustomize kubernetes/overlays/gke
kubectl kustomize kubernetes/overlays/minikube

# Apply with customizations
kubectl apply -k kubernetes/overlays/gke
kubectl apply -k kubernetes/overlays/minikube
```

### Modifying Deployments

To customize the deployment:

1. Edit base manifests in `kubernetes/base/`
2. Edit overlay patches in `kubernetes/overlays/gke/` or `kubernetes/overlays/minikube/`
3. Redeploy using the appropriate script

## Teardown

### Remove Deployment

```bash
cd scripts
./teardown.sh [environment]
```

Examples:
```bash
# Remove from Minikube
./teardown.sh minikube

# Remove from GKE
./teardown.sh gke
```

### Delete GKE Cluster

```bash
gcloud container clusters delete [cluster-name] --region=[region]
```

Example:
```bash
gcloud container clusters delete colabri-cluster --region=us-central1
```

### Stop Minikube

```bash
minikube stop
# Or delete completely
minikube delete
```

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -n colabri
kubectl describe pod [pod-name] -n colabri
```

### View Logs

```bash
# Live logs
kubectl logs -f deployment/colabri-app -n colabri

# Previous logs (if pod crashed)
kubectl logs --previous [pod-name] -n colabri
```

### Check Events

```bash
kubectl get events -n colabri --sort-by='.lastTimestamp'
```

### Port Forward for Testing

```bash
# GKE
kubectl port-forward svc/colabri-service 8080:80 -n colabri

# Then access at http://localhost:8080
```

### Common Issues

1. **ImagePullBackOff**: Image cannot be pulled from registry
   ```bash
   # Check pod details to see the exact error
   kubectl describe pod <pod-name> -n colabri
   
   # Verify the image exists in your registry
   gcloud container images list --repository=gcr.io/YOUR-PROJECT-ID
   
   # Check if credentials are configured (for GKE)
   kubectl get serviceaccount default -n colabri -o yaml
   
   # For private registries, create an image pull secret
   kubectl create secret docker-registry regcred \
     --docker-server=gcr.io \
     --docker-username=_json_key \
     --docker-password="$(cat key.json)" \
     -n colabri
   ```

2. **CrashLoopBackOff**: Application is crashing repeatedly
   ```bash
   # Check application logs for errors
   kubectl logs <pod-name> -n colabri
   
   # Check previous container logs if pod restarted
   kubectl logs <pod-name> -n colabri --previous
   ```

3. **Pending Pods**: Pods cannot be scheduled
   ```bash
   # Check why pod is pending
   kubectl describe pod <pod-name> -n colabri
   
   # Check node resources
   kubectl top nodes
   
   # Check if there are enough nodes
   kubectl get nodes
   ```

## Monitoring and Maintenance

### View Resource Usage

```bash
# Resource usage
kubectl top pods -n colabri
kubectl top nodes

# Deployment status
kubectl rollout status deployment/colabri-app -n colabri
```

### Update Deployment

```bash
# Update image
kubectl set image deployment/colabri-app colabri-app=gcr.io/PROJECT_ID/colabri-app:v2 -n colabri

# Or reapply manifests
kubectl apply -k kubernetes/overlays/gke
```

### Scale Deployment

```bash
# Scale manually
kubectl scale deployment/colabri-app --replicas=5 -n colabri

# Or edit the kustomization.yaml file
```

## Best Practices

1. **Always use version tags** for container images, not `latest`
2. **Store secrets securely** using Kubernetes Secrets or external secret managers
3. **Set resource requests and limits** appropriately
4. **Use health checks** (liveness and readiness probes)
5. **Enable monitoring** and logging solutions
6. **Backup configurations** and important data regularly
7. **Test in Minikube** before deploying to production GKE

## Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [Kustomize Documentation](https://kustomize.io/)
