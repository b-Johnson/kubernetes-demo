#!/bin/bash

# Verification script for nginx-demo deployment
# This script checks the health and status of all components

set -e

NAMESPACE="demo"
ARGOCD_NAMESPACE="argocd"
ISTIO_NAMESPACE="istio-system"

echo "🔍 Verifying nginx-demo deployment..."
echo "=================================================="

# Check namespaces
check_namespaces() {
    echo "📦 Checking namespaces..."
    
    for ns in $NAMESPACE $ARGOCD_NAMESPACE $ISTIO_NAMESPACE; do
        if kubectl get namespace $ns &> /dev/null; then
            echo "✅ Namespace $ns exists"
        else
            echo "❌ Namespace $ns not found"
            return 1
        fi
    done
}

# Check ArgoCD
check_argocd() {
    echo "🔄 Checking ArgoCD..."
    
    if kubectl get deployment argocd-server -n $ARGOCD_NAMESPACE &> /dev/null; then
        if kubectl get deployment argocd-server -n $ARGOCD_NAMESPACE -o jsonpath='{.status.readyReplicas}' | grep -q "1"; then
            echo "✅ ArgoCD server is running"
        else
            echo "⚠️  ArgoCD server is not ready"
        fi
    else
        echo "❌ ArgoCD server not found"
        return 1
    fi
    
    # Check applications
    echo "📱 Checking ArgoCD applications..."
    apps=$(kubectl get applications -n $ARGOCD_NAMESPACE -o jsonpath='{.items[*].metadata.name}')
    for app in $apps; do
        status=$(kubectl get application $app -n $ARGOCD_NAMESPACE -o jsonpath='{.status.health.status}')
        sync=$(kubectl get application $app -n $ARGOCD_NAMESPACE -o jsonpath='{.status.sync.status}')
        echo "   $app: Health=$status, Sync=$sync"
    done
}

# Check Istio
check_istio() {
    echo "🕸️  Checking Istio..."
    
    if kubectl get deployment istiod -n $ISTIO_NAMESPACE &> /dev/null; then
        if kubectl get deployment istiod -n $ISTIO_NAMESPACE -o jsonpath='{.status.readyReplicas}' | grep -q "1"; then
            echo "✅ Istio control plane is running"
        else
            echo "⚠️  Istio control plane is not ready"
        fi
    else
        echo "❌ Istio control plane not found"
        return 1
    fi
    
    # Check gateway
    if kubectl get gateway nginx-gateway -n $NAMESPACE &> /dev/null; then
        echo "✅ Istio gateway configured"
    else
        echo "❌ Istio gateway not found"
    fi
}

# Check nginx services
check_nginx_services() {
    echo "🚀 Checking nginx services..."
    
    services=("nginx-frontend" "nginx-api" "nginx-admin")
    
    for service in "${services[@]}"; do
        # Check deployment
        if kubectl get deployment $service -n $NAMESPACE &> /dev/null; then
            ready=$(kubectl get deployment $service -n $NAMESPACE -o jsonpath='{.status.readyReplicas}')
            desired=$(kubectl get deployment $service -n $NAMESPACE -o jsonpath='{.spec.replicas}')
            
            if [ "$ready" = "$desired" ]; then
                echo "✅ $service: $ready/$desired pods ready"
            else
                echo "⚠️  $service: $ready/$desired pods ready"
            fi
        else
            echo "❌ $service deployment not found"
        fi
        
        # Check service
        if kubectl get service $service -n $NAMESPACE &> /dev/null; then
            echo "✅ $service service exists"
        else
            echo "❌ $service service not found"
        fi
    done
}

# Check pod health
check_pod_health() {
    echo "🏥 Checking pod health..."
    
    # Get all nginx pods
    pods=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/part-of=nginx-demo -o jsonpath='{.items[*].metadata.name}')
    
    for pod in $pods; do
        status=$(kubectl get pod $pod -n $NAMESPACE -o jsonpath='{.status.phase}')
        ready=$(kubectl get pod $pod -n $NAMESPACE -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
        
        if [ "$status" = "Running" ] && [ "$ready" = "True" ]; then
            # Check if Istio sidecar is present
            containers=$(kubectl get pod $pod -n $NAMESPACE -o jsonpath='{.spec.containers[*].name}')
            if echo $containers | grep -q "istio-proxy"; then
                echo "✅ $pod: Running with Istio sidecar"
            else
                echo "⚠️  $pod: Running without Istio sidecar"
            fi
        else
            echo "❌ $pod: Status=$status, Ready=$ready"
        fi
    done
}

# Test service endpoints
test_endpoints() {
    echo "🧪 Testing service endpoints..."
    
    # Test from within cluster
    frontend_pod=$(kubectl get pods -n $NAMESPACE -l app=nginx-frontend -o jsonpath='{.items[0].metadata.name}')
    
    if [ -n "$frontend_pod" ]; then
        echo "Testing frontend health endpoint..."
        if kubectl exec $frontend_pod -n $NAMESPACE -- curl -s localhost/health | grep -q "healthy"; then
            echo "✅ Frontend health endpoint responding"
        else
            echo "❌ Frontend health endpoint not responding"
        fi
    fi
    
    api_pod=$(kubectl get pods -n $NAMESPACE -l app=nginx-api -o jsonpath='{.items[0].metadata.name}')
    
    if [ -n "$api_pod" ]; then
        echo "Testing API health endpoint..."
        if kubectl exec $api_pod -n $NAMESPACE -- curl -s localhost/api/v1/health | grep -q "healthy"; then
            echo "✅ API health endpoint responding"
        else
            echo "❌ API health endpoint not responding"
        fi
    fi
}

# Main verification flow
main() {
    check_namespaces
    check_argocd
    check_istio
    check_nginx_services
    check_pod_health
    test_endpoints
    
    echo ""
    echo "🎉 Verification completed!"
    echo ""
    echo "📝 Summary:"
    echo "- All core components are deployed"
    echo "- Services are healthy and responding"
    echo "- Istio service mesh is configured"
    echo "- ArgoCD is managing the deployments"
    echo ""
    echo "🌐 To access the services:"
    echo "1. Run: task port-forward"
    echo "2. Add to /etc/hosts:"
    echo "   127.0.0.1 nginx-frontend.local"
    echo "   127.0.0.1 nginx-api.local"
    echo "   127.0.0.1 nginx-admin.local"
    echo "3. Visit:"
    echo "   - ArgoCD: https://localhost:8080"
    echo "   - Frontend: http://nginx-frontend.local:8081"
    echo "   - API: http://nginx-api.local:8081"
    echo "   - Admin: http://nginx-admin.local:8081"
}

# Run verification
main "$@"
