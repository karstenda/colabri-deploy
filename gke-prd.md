# Deploying Colabri to GKE Production (colabri-prd)

This guide covers deploying the Colabri platform to Google Kubernetes Engine (GKE) in the `colabri-prd` project.

## Prerequisites

- **gcloud CLI** installed and configured
- **kubectl** installed
- The **gke-gcloud-auth-plugin** installed
- Access to the `colabri-prd` GCP project
- A running GKE cluster in the project

## Initial Setup

### 1. Authenticate with Google Cloud

```powershell
gcloud auth login
gcloud auth application-default set-quota-project colabri-prd
```

### 2. Set the GCP Project

```powershell
gcloud config set project colabri-prd
```

### 3. Connect to Your GKE Cluster

Make sure the right kubernetes cluster context is set:

```powershell
gcloud components install gke-gcloud-auth-plugin
gcloud config set project colabri-prd
```

Replace `CLUSTER-NAME` and `REGION` with your actual cluster details:

```powershell
gcloud container clusters get-credentials CLUSTER-NAME --region=REGION
```

Example:

```powershell
gcloud container clusters get-credentials colabri-cluster --region=europe-west3
```

### 4. Verify Connection

```powershell
kubectl cluster-info
kubectl get nodes
```

## Deployment

### Deploy the Application

Apply the GKE-specific Kubernetes manifests:

```powershell
kubectl apply -k kubernetes/overlays/gke-prd
```

### Wait for Deployment to Complete

```powershell
kubectl wait --for=condition=available --timeout=300s deployment/colabri-app -n colabri
```

### Verify Deployment

Check all resources in the colabri namespace:

```powershell
kubectl get all -n colabri
```

Check pods status:

```powershell
kubectl get pods -n colabri -w
```

## Accessing the Application

### Get External IP (Ingress)

If using ingress for external access:

```powershell
kubectl get ingress -n colabri
```

### Get LoadBalancer IP (Service)

If using a LoadBalancer service:

```powershell
kubectl get svc -n colabri
```

### Port Forwarding for Testing

For local testing without external access:

```powershell
kubectl port-forward svc/colabri-service 8080:80 -n colabri
```

Then access at: http://localhost:8080

## Managing the Deployment

### View Logs

View logs from all pods:

```powershell
kubectl logs -n colabri -l app=colabri-app --tail=50
```

Follow logs in real-time:

```powershell
kubectl logs -f deployment/colabri-app -n colabri
```

View logs from a specific pod:

```powershell
kubectl logs POD-NAME -n colabri
```

### Restart Deployment

To restart all pods (e.g., after updating configs):

```powershell
kubectl rollout restart deployment colabri-app -n colabri
```

### Check Rollout Status

```powershell
kubectl rollout status deployment/colabri-app -n colabri
```

### Scale the Deployment

The GKE overlay is configured with 1 replica by default. To manually scale:

```powershell
kubectl scale deployment colabri-app --replicas=5 -n colabri
```

## Working with Container Images

### Push Local Images to Google Artifact Registry (GAR)

To deploy your locally built images to GKE, you need to push them to Google Artifact Registry.

1. **Configure Docker to authenticate with Artifact Registry:**

```powershell
gcloud auth configure-docker europe-west3-docker.pkg.dev
```

2. **Tag your local image with the Artifact Registry path:**

```powershell
# Format: REGION-docker.pkg.dev/PROJECT-ID/REPOSITORY/IMAGE-NAME:TAG
docker tag colabri-app:v1.2.3 europe-west3-docker.pkg.dev/colabri-prd/colabri-gar/colabri-app:v1.2.3
```

3. **Push the image to Artifact Registry:**

```powershell
docker push europe-west3-docker.pkg.dev/colabri-prd/colabri-repo/colabri-app:v1.2.3
```

## Updating the Application

### Update Container Image

1. Push your new image to GCR or Artifact Registry (see "Working with Container Images" section above)
2. Update the deployment to use the new image:

```powershell
kubectl set image deployment/colabri-app colabri-app=europe-west3-docker.pkg.dev/colabri-prd/colabri-repo/colabri-app:v1.2.3 -n colabri
```

Or update the image in `kubernetes/base/app-deployment.yaml` and apply:

```powershell
kubectl apply -k kubernetes/overlays/gke-prd
```

3. Monitor the rollout:

```powershell
kubectl rollout status deployment/colabri-app -n colabri
```

### Rollback if Needed

```powershell
kubectl rollout undo deployment/colabri-app -n colabri
```

## Monitoring and Troubleshooting

### Check Resource Usage

```powershell
kubectl top pods -n colabri
kubectl top nodes
```

### Describe Resources

Get detailed information about a resource:

```powershell
kubectl describe pod POD-NAME -n colabri
kubectl describe deployment colabri-app -n colabri
```

### Execute Commands in Pod

```powershell
kubectl exec -it POD-NAME -n colabri -- /bin/bash
```

### Check Events

```powershell
kubectl get events -n colabri --sort-by='.lastTimestamp'
```

## GKE-Specific Configuration

The GKE overlay (`kubernetes/overlays/gke/`) includes:

- **3 replicas** for high availability
- Production-grade resource limits
- GKE-optimized ingress configuration
- Health checks and readiness probes

To view the complete manifest before applying:

```powershell
kubectl kustomize kubernetes/overlays/gke
```

## Cleanup

To remove the entire deployment:

```powershell
kubectl delete -k kubernetes/overlays/gke
```

Or delete just the namespace (removes everything in it):

```powershell
kubectl delete namespace colabri
```
