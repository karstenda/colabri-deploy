# Configuration Guide

This guide explains how to configure the Colabri platform deployment.

## Environment Configuration

### ConfigMap

The application configuration is managed through Kubernetes ConfigMaps. Edit `kubernetes/base/configmap.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: colabri-config
  namespace: colabri
data:
  environment: "production"
  log_level: "info"
  # Add your configuration variables here
  api_timeout: "30"
  max_connections: "100"
```

### Secrets

For sensitive data like passwords and API keys, use Kubernetes Secrets.

1. Copy the example secret file:
```bash
cp kubernetes/base/secret.yaml.example kubernetes/base/secret.yaml
```

2. Encode your secrets in base64:
```bash
echo -n 'my-password' | base64
# Output: bXktcGFzc3dvcmQ=
```

3. Edit `kubernetes/base/secret.yaml`:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: colabri-secrets
  namespace: colabri
type: Opaque
data:
  database-password: bXktcGFzc3dvcmQ=
  api-key: eW91ci1hcGkta2V5
```

4. Apply the secret:
```bash
kubectl apply -f kubernetes/base/secret.yaml
```

**Important**: Never commit `secret.yaml` to version control!

## Image Configuration

### GKE Deployment

**Option 1**: Edit `kubernetes/base/deployment.yaml` directly:

```yaml
containers:
- name: colabri-app
  image: gcr.io/YOUR-PROJECT-ID/colabri-app:v1.0.0
```

**Option 2** (Recommended): Use Kustomize image transformer in `kubernetes/overlays/gke/kustomization.yaml`:

```yaml
images:
- name: gcr.io/PROJECT_ID/colabri-app
  newName: gcr.io/my-actual-project/colabri-app
  newTag: v1.0.0
```

This allows you to keep the base manifests generic and override the image in environment-specific overlays.

### Minikube Deployment

For local development, you can use local images:

```bash
# Build image inside Minikube
eval $(minikube docker-env)
docker build -t colabri-app:local .

# The deployment will use: colabri-app:local
```

## Resource Configuration

### Production (GKE)

Edit `kubernetes/overlays/gke/deployment-patch.yaml`:

```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "500m"
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

### Development (Minikube)

Edit `kubernetes/overlays/minikube/deployment-patch.yaml`:

```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "250m"
```

## Scaling Configuration

### Replicas

Edit the kustomization.yaml in the appropriate overlay:

**GKE**: `kubernetes/overlays/gke/kustomization.yaml`
```yaml
replicas:
- name: colabri-app
  count: 3
```

**Minikube**: `kubernetes/overlays/minikube/kustomization.yaml`
```yaml
replicas:
- name: colabri-app
  count: 1
```

### Horizontal Pod Autoscaling (HPA)

For automatic scaling, create an HPA resource:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: colabri-app-hpa
  namespace: colabri
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: colabri-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

## Network Configuration

### Service Type

**GKE** uses ClusterIP with Ingress:
```yaml
spec:
  type: ClusterIP
```

**Minikube** uses NodePort for direct access:
```yaml
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080
```

### Ingress Configuration

Edit `kubernetes/base/ingress.yaml`:

```yaml
spec:
  tls:
  - hosts:
    - your-domain.com
    secretName: colabri-tls-cert
  rules:
  - host: your-domain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: colabri-service
            port:
              number: 80
```

For GKE, update `kubernetes/overlays/gke/ingress-patch.yaml`:

```yaml
metadata:
  annotations:
    kubernetes.io/ingress.global-static-ip-name: "your-static-ip"
    networking.gke.io/managed-certificates: "your-cert-name"
```

## Health Checks

Configure liveness and readiness probes in `kubernetes/base/deployment.yaml`:

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 3
```

## Environment-Specific Variables

You can inject ConfigMap values as environment variables:

```yaml
env:
- name: ENVIRONMENT
  valueFrom:
    configMapKeyRef:
      name: colabri-config
      key: environment
- name: LOG_LEVEL
  valueFrom:
    configMapKeyRef:
      name: colabri-config
      key: log_level
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: colabri-secrets
      key: database-password
```

## Applying Configuration Changes

After modifying configurations:

### GKE
```bash
kubectl apply -k kubernetes/overlays/gke
kubectl rollout restart deployment/colabri-app -n colabri
```

### Minikube
```bash
kubectl apply -k kubernetes/overlays/minikube
kubectl rollout restart deployment/colabri-app -n colabri
```

## Configuration Best Practices

1. **Use ConfigMaps for non-sensitive data** - Application settings, feature flags, etc.
2. **Use Secrets for sensitive data** - Passwords, API keys, certificates
3. **Never commit secrets** - Add secret.yaml to .gitignore
4. **Use environment-specific overlays** - Keep dev and prod configs separate
5. **Version your images** - Use specific tags, not `latest`
6. **Set resource limits** - Prevent resource exhaustion
7. **Configure health checks** - Enable automatic recovery
8. **Use namespaces** - Isolate environments

## External Configuration Management

For advanced use cases, consider:

- **Google Secret Manager** (for GKE)
- **HashiCorp Vault**
- **Sealed Secrets**
- **External Secrets Operator**

## Troubleshooting

### View Current Configuration

```bash
# View ConfigMap
kubectl get configmap colabri-config -n colabri -o yaml

# View Secret (base64 encoded)
kubectl get secret colabri-secrets -n colabri -o yaml

# Decode secret
kubectl get secret colabri-secrets -n colabri -o jsonpath='{.data.database-password}' | base64 -d
```

### Verify Environment Variables

```bash
kubectl exec -it deployment/colabri-app -n colabri -- env | grep -i colabri
```

### Configuration Not Applied

```bash
# Force rollout restart
kubectl rollout restart deployment/colabri-app -n colabri

# Check rollout status
kubectl rollout status deployment/colabri-app -n colabri
```
