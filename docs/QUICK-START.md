# Quick Start Guide

Get Colabri deployed in minutes!

## For Local Development (Minikube)

### Prerequisites
- Install [Minikube](https://minikube.sigs.k8s.io/docs/start/)
- Install [kubectl](https://kubernetes.io/docs/tasks/tools/)

### Deploy in 1 Command

```bash
cd scripts
./deploy-minikube.sh
```

That's it! The script will:
- Start Minikube (if not running)
- Deploy the application
- Show you the access URL

### Access Your Application

```bash
# Get the URL
minikube service colabri-service -n colabri --url

# Or open in browser
minikube service colabri-service -n colabri
```

### Check Status

```bash
./status.sh
```

### View Logs

```bash
kubectl logs -f deployment/colabri-app -n colabri
```

### Clean Up

```bash
./teardown.sh minikube
minikube stop
```

---

## For Google Cloud (GKE)

### Prerequisites
- GCP account with billing enabled
- Install [gcloud CLI](https://cloud.google.com/sdk/docs/install)
- Install [kubectl](https://kubernetes.io/docs/tasks/tools/)

### Deploy in 2 Commands

```bash
cd scripts

# 1. Create cluster (takes ~5 minutes)
./setup-gke-cluster.sh my-project colabri-cluster us-central1

# 2. Deploy application
./deploy-gke.sh my-project colabri-cluster us-central1
```

### Check Status

```bash
./status.sh
```

### Access Your Application

```bash
# Port forward for testing
kubectl port-forward svc/colabri-service 8080:80 -n colabri

# Then visit: http://localhost:8080
```

### View Logs

```bash
kubectl logs -f deployment/colabri-app -n colabri
```

### Clean Up

```bash
# Remove application
./teardown.sh gke

# Delete cluster (to stop billing)
gcloud container clusters delete colabri-cluster --region=us-central1
```

---

## Common Operations

### Update Configuration

```bash
# Edit configuration
nano ../kubernetes/base/configmap.yaml

# Apply changes
kubectl apply -k ../kubernetes/overlays/gke  # or minikube
kubectl rollout restart deployment/colabri-app -n colabri
```

### Scale Application

```bash
# Scale to 5 replicas
kubectl scale deployment/colabri-app --replicas=5 -n colabri
```

### View All Resources

```bash
kubectl get all -n colabri
```

### Shell into Pod

```bash
kubectl exec -it deployment/colabri-app -n colabri -- /bin/sh
```

---

## Troubleshooting

### Pods not starting?

```bash
# Check pod status
kubectl get pods -n colabri

# Describe a pod to see why it's failing
kubectl describe pod <pod-name> -n colabri

# Check logs
kubectl logs <pod-name> -n colabri
```

### Can't access application?

```bash
# Check service
kubectl get svc -n colabri

# Check ingress (if using)
kubectl get ingress -n colabri

# Port forward to test
kubectl port-forward svc/colabri-service 8080:80 -n colabri
```

### Need more help?

See the full [Deployment Guide](DEPLOYMENT.md) for detailed instructions.
