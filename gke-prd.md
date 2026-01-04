# Deploying Colabri to GKE Production (colabri-prd)

This guide covers deploying the Colabri platform to Google Kubernetes Engine (GKE) in the `colabri-prd` project.

## Prerequisites

- **gcloud CLI** installed and configured
- **kubectl** installed
- The **gke-gcloud-auth-plugin** installed
- Access to the `colabri-prd` GCP project
- The GCS Fuse CSI driver enabled in the GCP project
- A running GKE cluster in the project

## Secrets

The overlay expects the file `kubernetes/overlays/gke-prd/secrets.yaml` to exist **before** you run `kubectl apply`. The canonical copy of that file lives in Secret Manager inside the `colabri-prd` project under the `colabri-app_app_env` secret. Use `gcloud` to materialize the latest version locally (adjust the output path if you keep the file elsewhere):

### Linux / macOS

```bash
cd src
gcloud secrets versions access latest --secret="secrets_yaml" --format='get(payload.data)' | tr '_-' '/+' | base64 -d > kubernetes/overlays/gke-prd/secrets.yaml
```

### Windows

```powershell
cd src
(gcloud secrets versions access latest --secret="secrets_yaml" --format='get(payload.data)') -replace '_', '/' -replace '-', '+' | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) } | Out-File kubernetes/overlays/gke-prd/secrets.yaml -Encoding UTF8
```

> The `tr` / `-replace` steps normalize the character set before decoding because Secret Manager returns URL-safe base64.

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

First install the gke-gcloud-auth-plugin so we can authenticate to the cluster.

```powershell
gcloud components install gke-gcloud-auth-plugin
```

Now you can get the credentials to connect to your project and cluster.

```powershell
gcloud config set project colabri-prd
gcloud container clusters get-credentials colabri-cluster --region=europe-west3
```

### 4. Enable the GCS Fuse CSI Driver

To enable the GCS Fuse CSI driver on the cluster, run the following command:

```powershell
gcloud container clusters update colabri-cluster --region europe-west3 --update-addons=GcsFuseCsiDriver=ENABLED
```

### 5. Verify Connection

```powershell
kubectl cluster-info
kubectl get nodes
```

## Deployment

### Set the kubectl context

Start by setting the kubernetes context to the colabri cluster.

```powershell
gcloud config set project colabri-prd
gcloud container clusters get-credentials colabri-cluster --region=europe-west3
```

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
docker tag colabri-app:latest europe-west3-docker.pkg.dev/colabri-prd/colabri-gar/colabri-app:v1.2.3
```

3. **Push the image to Artifact Registry:**

```powershell
docker push europe-west3-docker.pkg.dev/colabri-prd/colabri-gar/colabri-app:v1.2.3
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
