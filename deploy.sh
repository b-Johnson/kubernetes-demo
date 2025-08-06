#!/bin/bash

# Deploy nginx services with ArgoCD and Istio
# This script sets up the complete environment

set -e

echo "🚀 Starting deployment of nginx services with ArgoCD and Istio..."

# Check if required tools are available
check_tools() {
    echo "📋 Checking required tools..."
    
    for tool in kubectl helm argocd; do
        if ! command -v $tool &> /dev/null; then
            echo "❌ $tool is not installed or not in PATH"
            exit 1
        fi
    done
    
    echo "✅ All required tools are available"
}

# Create namespace
setup_namespace() {
    echo "📦 Setting up namespace..."
    kubectl apply -f k8s/namespace.yaml
    echo "✅ Namespace created"
}

# Install ArgoCD if not present
install_argocd() {
    echo "🔧 Checking ArgoCD installation..."
    
    if ! kubectl get namespace argocd &> /dev/null; then
        echo "📥 Installing ArgoCD..."
        kubectl create namespace argocd
        kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
        
        echo "⏳ Waiting for ArgoCD to be ready..."
        kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
        
        echo "🔑 Getting ArgoCD admin password..."
        ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
        echo "ArgoCD admin password: $ARGOCD_PASSWORD"
        
        echo "✅ ArgoCD installed successfully"
    else
        echo "✅ ArgoCD is already installed"
    fi
}

# Install Istio if not present
install_istio() {
    echo "🕸️  Checking Istio installation..."
    
    if ! kubectl get namespace istio-system &> /dev/null; then
        echo "📥 Installing Istio..."
        
        # Download and install istioctl if not present
        if ! command -v istioctl &> /dev/null; then
            echo "📥 Downloading istioctl..."
            curl -L https://istio.io/downloadIstio | sh -
            export PATH="$PWD/istio-*/bin:$PATH"
        fi
        
        # Install Istio
        istioctl install --set values.defaultRevision=default -y
        
        echo "✅ Istio installed successfully"
    else
        echo "✅ Istio is already installed"
    fi
}

# Deploy ArgoCD applications
deploy_apps() {
    echo "🚀 Deploying ArgoCD applications..."
    
    # Apply project first
    kubectl apply -f argocd/project.yaml
    
    # Apply all applications
    kubectl apply -f argocd/
    
    echo "✅ ArgoCD applications deployed"
}

# Setup port forwarding for easy access
setup_port_forwarding() {
    echo "🌐 Setting up port forwarding..."
    
    echo "To access the services, run these commands in separate terminals:"
    echo ""
    echo "# ArgoCD UI (admin/password from above)"
    echo "kubectl port-forward svc/argocd-server -n argocd 8080:443"
    echo ""
    echo "# Istio Gateway"
    echo "kubectl port-forward svc/istio-ingressgateway -n istio-system 8081:80"
    echo ""
    echo "# Add to /etc/hosts:"
    echo "127.0.0.1 nginx-frontend.local"
    echo "127.0.0.1 nginx-api.local"
    echo "127.0.0.1 nginx-admin.local"
    echo ""
}

# Main deployment flow
main() {
    echo "🎯 Starting nginx-demo deployment with ArgoCD and Istio"
    echo "=================================================="
    
    check_tools
    setup_namespace
    install_argocd
    install_istio
    deploy_apps
    setup_port_forwarding
    
    echo ""
    echo "🎉 Deployment completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Wait for all applications to sync in ArgoCD"
    echo "2. Set up port forwarding as shown above"
    echo "3. Access the services at:"
    echo "   - Frontend: http://nginx-frontend.local:8081"
    echo "   - API: http://nginx-api.local:8081"
    echo "   - Admin: http://nginx-admin.local:8081"
    echo ""
}

# Run main function
main "$@"
