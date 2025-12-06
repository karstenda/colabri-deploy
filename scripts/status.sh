#!/bin/bash

# Check the status of Colabri deployment
# Usage: ./status.sh [namespace]

NAMESPACE=${1:-"colabri"}

echo "================================================"
echo "Colabri Deployment Status"
echo "================================================"
echo "Namespace: $NAMESPACE"
echo "Context: $(kubectl config current-context)"
echo "================================================"
echo ""

# Check if namespace exists
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    echo "❌ Namespace '$NAMESPACE' does not exist"
    echo "The application may not be deployed yet."
    exit 1
fi

echo "✅ Namespace exists"
echo ""

# Get all resources
echo "📦 Resources in namespace:"
echo "---"
kubectl get all -n "$NAMESPACE"
echo ""

# Get deployment status
echo "🚀 Deployment Status:"
echo "---"
kubectl get deployment -n "$NAMESPACE" -o wide
echo ""

# Get pod status with details
echo "🔧 Pod Status:"
echo "---"
kubectl get pods -n "$NAMESPACE" -o wide
echo ""

# Get service information
echo "🌐 Services:"
echo "---"
kubectl get svc -n "$NAMESPACE" -o wide
echo ""

# Check if ingress exists
if kubectl get ingress -n "$NAMESPACE" &> /dev/null; then
    echo "🔗 Ingress:"
    echo "---"
    kubectl get ingress -n "$NAMESPACE"
    echo ""
fi

# Get ConfigMap
echo "⚙️  ConfigMap:"
echo "---"
kubectl get configmap colabri-config -n "$NAMESPACE" -o yaml 2>/dev/null || echo "No ConfigMap found"
echo ""

# Check for recent events
echo "📋 Recent Events:"
echo "---"
kubectl get events -n "$NAMESPACE" --sort-by='.lastTimestamp' | tail -10
echo ""

# Check resource usage if metrics-server is available
echo "📊 Resource Usage:"
echo "---"
if kubectl top pods -n "$NAMESPACE" &> /dev/null; then
    kubectl top pods -n "$NAMESPACE"
else
    echo "⚠️  Metrics not available (metrics-server may not be installed)"
fi
echo ""

echo "================================================"
echo "Quick Commands:"
echo "================================================"
echo "View logs:       kubectl logs -f deployment/colabri-app -n $NAMESPACE"
echo "Describe pod:    kubectl describe pod <pod-name> -n $NAMESPACE"
echo "Port forward:    kubectl port-forward svc/colabri-service 8080:80 -n $NAMESPACE"
echo "Shell access:    kubectl exec -it deployment/colabri-app -n $NAMESPACE -- /bin/sh"
echo "================================================"
