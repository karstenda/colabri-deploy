# Deploying Colabri to Minikube (Local Development)

This guide covers deploying the Colabri platform to Minikube for local development and testing.

## Prerequisites

- **Minikube** installed
- **kubectl** installed
- **Docker** (or another container runtime)

## Installation

### Install Minikube

Download and install from: https://minikube.sigs.k8s.io/docs/start/

For Windows (PowerShell as Administrator):

```powershell
# Using Chocolatey
choco install minikube

# Or using winget
winget install Kubernetes.minikube
```

### Install kubectl

```powershell
# Using Chocolatey
choco install kubernetes-cli

# Or using winget
winget install Kubernetes.kubectl
```

## Initial Setup

### 1. Start Minikube

Start Minikube with appropriate resources:

```powershell
minikube start --cpus=4 --memory=8192 --driver=docker
```

Or use the default settings:

```powershell
minikube start
```

### 2. Verify Minikube is Running

```powershell
minikube status
kubectl cluster-info
```

### 3. Enable Addons (Optional but Recommended)

```powershell
# Enable ingress for external access
minikube addons enable ingress

# Enable metrics server for resource monitoring
minikube addons enable metrics-server

# Enable dashboard for web UI
minikube addons enable dashboard
```

## Deployment

### Deploy the Application

Start Minikube (if not already) and tell kubernetes to deploy on Minikube. Minikube will set itself as the current kubernetes cluster context.

```powershell
minikube start
```

Apply the Minikube-specific Kubernetes manifests:

```powershell
kubectl apply -k kubernetes/overlays/minikube-local
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

### Using Minikube Service Command

The easiest way to access the service:

```powershell
minikube service colabri-app-service -n colabri
```

This automatically opens your browser with the correct URL and port.

### Get Service URL

To get the URL without opening the browser:

```powershell
minikube service colabri-app-service -n colabri --url
```

### Using Port Forwarding

Alternative method for local access:

```powershell
kubectl port-forward svc/colabri-app-service 8080:80 -n colabri
```

Then access at: http://localhost:8080

### Using LoadBalancer with Minikube Tunnel

The Minikube overlay is configured to use LoadBalancer type for the ingress controller. To access the application:

1. Start the Minikube tunnel in a separate terminal (requires administrator privileges):

   ```powershell
   minikube tunnel
   ```

   **Note:** Keep this terminal running. The tunnel must stay active for LoadBalancer services to work.

2. Get the external IP of the ingress controller:

   ```powershell
   kubectl get svc ingress-nginx-controller -n ingress-nginx
   ```

3. Configure your Windows hosts file to map the hostname to the external IP:

   **Edit the hosts file** (requires administrator privileges):

   - Open PowerShell as Administrator
   - Run: `notepad C:\Windows\System32\drivers\etc\hosts`
   - Add the following line (replace with actual EXTERNAL-IP if different):

   ```
   127.0.0.1  app.colabri-local.cloud
   ```

   - Save and close the file

4. Access the application at the configured hostname:
   ```
   http://app.colabri-local.cloud
   ```

### Using Ingress (NodePort Mode)

If ingress is enabled with NodePort (default), get the Minikube IP:

```powershell
minikube ip
```

Configure your Windows hosts file to map the hostname:

**Edit the hosts file** (requires administrator privileges):

- Open PowerShell as Administrator
- Run: `notepad C:\Windows\System32\drivers\etc\hosts`
- Add the following line (replace IP with your actual Minikube IP):

```
192.168.49.2  app.colabri-local.cloud
```

- Save and close the file

Then access at: http://app.colabri-local.cloud

## Enabling HTTPS (Required for Secure Cookies)

Chrome (and most modern browsers) only send cookies marked `SameSite=None` when they also have the `Secure` flag, which means the cookie is delivered exclusively over HTTPS. Follow the steps below to terminate TLS inside Minikube so the local domains resolve over `https://`.

1. **Create & trust a local certificate authority**

   ```powershell
   choco install mkcert    # or use winget/brew
   mkcert -install         # adds the local CA to Windows trust store
   ```

2. **Generate certs for the local domains**

   ```powershell
   mkcert app.colabri-local.cloud doc.colabri-local.cloud "*.colabri-local.cloud"
   ```

   Mkcert writes a `.pem` (certificate) and `.key` file in your current directory. Rename them if you want, e.g., `colabri-local.crt` and `colabri-local.key`.

3. **Create the Kubernetes TLS secret manifest (`kubernetes/overlays/minikube-local/tls-secrets.yaml`)**

   1. Base64-encode the generated cert/key (PowerShell example):

      ```powershell
      $crt = [Convert]::ToBase64String([IO.File]::ReadAllBytes('colabri-local.crt'))
      $key = [Convert]::ToBase64String([IO.File]::ReadAllBytes('colabri-local.key'))
      ```

   2. Paste the values into the checked-in secret manifest:

      ```yaml
      apiVersion: v1
      kind: Secret
      metadata:
        name: colabri-local-tls
        namespace: colabri
      type: kubernetes.io/tls
      data:
        tls.crt: <base64 from $crt>
        tls.key: <base64 from $key>
      ```

   The minikube overlay already references `tls-secrets.yaml` in its `kustomization.yaml`, so running `kubectl apply -k kubernetes/overlays/minikube-local` creates or updates the TLS secret automatically.

4. **Reapply the overlay so the ingress picks up TLS**

   ```powershell
   kubectl apply -k kubernetes/overlays/minikube-local
   ```

5. **Map the hosts file to the Minikube IP (HTTPS works for both subdomains)**

   ```
   192.168.49.2  app.colabri-local.cloud doc.colabri-local.cloud
   ```

6. **Access everything over HTTPS**

   - `https://app.colabri-local.cloud`
   - Client-side code should connect to `wss://doc.colabri-local.cloud/<workspaceId>`

With TLS active, cookies marked `SameSite=None; Secure` are accepted locally, so the doc service receives the `auth_token` cookie during WebSocket handshakes.

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

To restart all pods (e.g., after updating configs or images):

```powershell
kubectl rollout restart deployment colabri-app -n colabri
```

### Check Rollout Status

```powershell
kubectl rollout status deployment/colabri-app -n colabri
```

## Working with Container Images

### Load Local Image into Minikube

If you build images locally, load them into Minikube. Use versioned tags for better tracking:

```powershell
# Load a specific version
minikube image load colabri-app:v1.0.0

# Or load the latest version
minikube image load colabri-app:latest
```

**Workflow for pushing new versions:**

1. Build your Docker image locally with a version tag:

   ```powershell
   docker build -t colabri-app:v1.2.3 .
   ```

2. Load the image into Minikube:

   ```powershell
   minikube image load colabri-app:v1.2.3
   ```

3. Update your deployment to use the new version (edit `kubernetes/base/app-deployment.yaml` or use kubectl):

   ```powershell
   kubectl set image deployment/colabri-app colabri-app=colabri-app:v1.2.3 -n colabri
   ```

4. Verify the rollout:
   ```powershell
   kubectl rollout status deployment/colabri-app -n colabri
   ```

### Build Image Directly in Minikube

Configure your shell to use Minikube's Docker daemon:

```powershell
minikube docker-env | Invoke-Expression
docker build -t colabri-app:latest .
```

### List Images in Minikube

```powershell
minikube image ls
```

## Updating the Application

### Update Container Image

1. Build your new image with a version tag:

```powershell
docker build -t colabri-app:v1.2.3 .
```

2. Load the new image into Minikube:

```powershell
minikube image load colabri-app:v1.2.3
```

3. Update the deployment to use the new image:

```powershell
kubectl set image deployment/colabri-app colabri-app=colabri-app:v1.2.3 -n colabri
```

Or if you're using the same tag (e.g., `latest`), restart the deployment:

```powershell
minikube image load colabri-app:latest
kubectl rollout restart deployment colabri-app -n colabri
```

### Update Manifests

Edit the configuration files and reapply:

```powershell
kubectl apply -k kubernetes/overlays/minikube
```

### Rollback if Needed

```powershell
kubectl rollout undo deployment/colabri-app -n colabri
```

## Configuration Management

### Update ConfigMaps

Edit the ConfigMap and reapply:

```powershell
kubectl apply -k kubernetes/overlays/minikube
kubectl rollout restart deployment colabri-app -n colabri
```

### Update Secrets

Update secrets in `kubernetes/overlays/minikube/secrets.yaml` and reapply:

```powershell
kubectl apply -k kubernetes/overlays/minikube
kubectl rollout restart deployment colabri-app -n colabri
```

## Monitoring and Troubleshooting

### Open Minikube Dashboard

Launch the Kubernetes dashboard:

```powershell
minikube dashboard
```

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

Or for sh:

```powershell
kubectl exec -it POD-NAME -n colabri -- /bin/sh
```

### Check Events

```powershell
kubectl get events -n colabri --sort-by='.lastTimestamp'
```

### View Minikube Logs

```powershell
minikube logs
```

## Minikube Management

### Pause/Unpause Minikube

To free up resources without deleting the cluster:

```powershell
minikube pause
minikube unpause
```

### Stop Minikube

```powershell
minikube stop
```

### Start Minikube Again

```powershell
minikube start
```

### Delete Minikube Cluster

To completely remove the cluster:

```powershell
minikube delete
```

### SSH into Minikube Node

```powershell
minikube ssh
```

## Minikube-Specific Configuration

The Minikube overlay (`kubernetes/overlays/minikube/`) includes:

- **1 replica** (suitable for local development)
- NodePort service for easy access
- Development-friendly resource limits
- Local ingress configuration
- Secrets for testing

To view the complete manifest before applying:

```powershell
kubectl kustomize kubernetes/overlays/minikube
```

## Cleanup

### Remove the Deployment

```powershell
kubectl delete -k kubernetes/overlays/minikube
```

Or delete just the namespace:

```powershell
kubectl delete namespace colabri
```

### Reset Minikube

To start fresh:

```powershell
minikube delete
minikube start
```

## Automation Script

You can also use the provided PowerShell script:

```powershell
.\scripts\deploy-minikube.ps1
```

Or the bash script (requires Git Bash or WSL):

```bash
bash scripts/deploy-minikube.sh
```

## Useful Minikube Commands

```powershell
# Get Minikube status
minikube status

# Get cluster IP
minikube ip

# List addons
minikube addons list

# View Minikube config
minikube config view

# Increase resources (requires restart)
minikube config set cpus 4
minikube config set memory 8192

# Access Docker daemon
minikube docker-env

# Open service in browser
minikube service colabri-app-service -n colabri
```

## Tips for Local Development

1. **Use image pull policy IfNotPresent** to avoid pulling from remote registries
2. **Load images directly** into Minikube for faster iterations
3. **Use port-forward** for quick testing without ingress setup
4. **Enable metrics-server** addon for resource monitoring
5. **Pause Minikube** when not in use to save system resources
6. **Use minikube tunnel** if you need LoadBalancer services

## Common Issues

### Pod ImagePullBackOff

If using local images, make sure to load them into Minikube with the correct version:

```powershell
minikube image load colabri-app:v1.0.0
```

Verify the image is loaded:

```powershell
minikube image ls | Select-String colabri-app
```

### Service Not Accessible

Use `minikube service` command instead of trying to access cluster IP directly:

```powershell
minikube service colabri-app-service -n colabri
```

### Insufficient Resources

Increase Minikube resources:

```powershell
minikube stop
minikube delete
minikube start --cpus=4 --memory=8192
```

## Support

For issues or questions:

- Check deployment status: `kubectl get all -n colabri`
- View logs: `kubectl logs -n colabri -l app=colabri-app --tail=100`
- Review events: `kubectl get events -n colabri`
- Check Minikube status: `minikube status`
- View Minikube logs: `minikube logs`
