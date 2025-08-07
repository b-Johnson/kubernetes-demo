#!/bin/bash

# Routing Demonstration Script
# This script demonstrates the different routing capabilities

set -e

FRONTEND_URL="http://nginx-frontend.local:8081"
NAMESPACE="demo"

echo "🔀 Nginx Frontend Routing Demonstration"
echo "======================================="
echo ""

# Check if services are running
check_services() {
    echo "📋 Checking service availability..."
    
    if ! kubectl get deployment nginx-frontend -n $NAMESPACE &> /dev/null; then
        echo "❌ nginx-frontend v1 not found"
        exit 1
    fi
    
    if ! kubectl get deployment nginx-frontend-v2 -n $NAMESPACE &> /dev/null; then
        echo "❌ nginx-frontend-v2 not found"
        exit 1
    fi
    
    echo "✅ Both frontend services are available"
}

# Test weight-based routing
test_weight_routing() {
    echo ""
    echo "1️⃣  Weight-Based Routing Test (80% v1, 20% v2)"
    echo "================================================"
    echo "Making 10 requests to see traffic distribution..."
    
    v1_count=0
    v2_count=0
    
    for i in {1..10}; do
        response=$(kubectl exec -n $NAMESPACE deployment/nginx-frontend -- curl -s $FRONTEND_URL 2>/dev/null || echo "failed")
        if [[ $response == *"Frontend Service V2"* ]]; then
            v2_count=$((v2_count + 1))
            echo "Request $i: v2 ✨"
        elif [[ $response == *"Frontend Service"* ]]; then
            v1_count=$((v1_count + 1))
            echo "Request $i: v1"
        else
            echo "Request $i: failed"
        fi
        sleep 0.5
    done
    
    echo ""
    echo "Results: v1=$v1_count requests, v2=$v2_count requests"
    echo "Expected: ~80% v1, ~20% v2"
}

# Test path-based routing
test_path_routing() {
    echo ""
    echo "2️⃣  Path-Based Routing Test"
    echo "============================"
    
    echo "Testing /v2 path (should route to v2):"
    v2_response=$(kubectl exec -n $NAMESPACE deployment/nginx-frontend -- curl -s "$FRONTEND_URL/v2" 2>/dev/null || echo "failed")
    if [[ $v2_response == *"V2 Path-Based Routing"* ]]; then
        echo "✅ /v2 path correctly routed to v2"
    else
        echo "❌ /v2 path routing failed"
    fi
    
    echo ""
    echo "Testing /beta path (should route to v2):"
    beta_response=$(kubectl exec -n $NAMESPACE deployment/nginx-frontend -- curl -s "$FRONTEND_URL/beta" 2>/dev/null || echo "failed")
    if [[ $beta_response == *"Beta Features"* ]]; then
        echo "✅ /beta path correctly routed to v2"
    else
        echo "❌ /beta path routing failed"
    fi
}

# Test header-based routing
test_header_routing() {
    echo ""
    echo "3️⃣  Header-Based Routing Test"
    echo "============================="
    
    echo "Testing with version=v2 header (should route to v2):"
    header_response=$(kubectl exec -n $NAMESPACE deployment/nginx-frontend -- curl -s -H "version: v2" $FRONTEND_URL 2>/dev/null || echo "failed")
    if [[ $header_response == *"Frontend Service V2"* ]]; then
        echo "✅ Header-based routing to v2 successful"
    else
        echo "❌ Header-based routing failed"
    fi
    
    echo ""
    echo "Testing with version=v1 header (should route to v1):"
    v1_response=$(kubectl exec -n $NAMESPACE deployment/nginx-frontend -- curl -s -H "version: v1" $FRONTEND_URL 2>/dev/null || echo "failed")
    if [[ $v1_response == *"Frontend Service"* ]] && [[ $v1_response != *"V2"* ]]; then
        echo "✅ Header-based routing to v1 successful"
    else
        echo "❌ Header-based routing to v1 failed"
    fi
}

# Test health endpoints
test_health_endpoints() {
    echo ""
    echo "4️⃣  Health Endpoint Test"
    echo "======================="
    
    echo "Testing v1 health endpoint:"
    v1_health=$(kubectl exec -n $NAMESPACE deployment/nginx-frontend -- curl -s "$FRONTEND_URL/health" 2>/dev/null || echo "failed")
    echo "v1 health: $v1_health"
    
    echo ""
    echo "Testing v2 health endpoint (via header routing):"
    v2_health=$(kubectl exec -n $NAMESPACE deployment/nginx-frontend -- curl -s -H "version: v2" "$FRONTEND_URL/health" 2>/dev/null || echo "failed")
    echo "v2 health: $v2_health"
}

# Show routing configuration
show_routing_config() {
    echo ""
    echo "📖 Current Routing Configuration"
    echo "================================"
    echo ""
    echo "VirtualService Rules:"
    echo "1. Header-based: version=v2 → v2 service"
    echo "2. Path-based: /v2, /beta → v2 service"
    echo "3. Weight-based: / → 80% v1, 20% v2"
    echo ""
    echo "DestinationRule Subsets:"
    echo "- v1: version=v1 label"
    echo "- v2: version=v2 label"
    echo ""
}

# Manual testing instructions
show_manual_tests() {
    echo ""
    echo "🧪 Manual Testing Instructions"
    echo "=============================="
    echo ""
    echo "After setting up port forwarding (task port-forward), test these URLs:"
    echo ""
    echo "Weight-based routing (80/20 split):"
    echo "  curl $FRONTEND_URL"
    echo ""
    echo "Path-based routing:"
    echo "  curl $FRONTEND_URL/v2"
    echo "  curl $FRONTEND_URL/beta"
    echo ""
    echo "Header-based routing:"
    echo "  curl -H 'version: v2' $FRONTEND_URL"
    echo "  curl -H 'version: v1' $FRONTEND_URL"
    echo ""
    echo "Browser testing:"
    echo "  - Visit $FRONTEND_URL multiple times (see weight-based routing)"
    echo "  - Visit $FRONTEND_URL/v2 (path-based to v2)"
    echo "  - Visit $FRONTEND_URL/beta (path-based to v2)"
    echo ""
}

# Main execution
main() {
    check_services
    show_routing_config
    test_weight_routing
    test_path_routing
    test_header_routing
    test_health_endpoints
    show_manual_tests
    
    echo ""
    echo "🎉 Routing demonstration completed!"
    echo ""
    echo "💡 Tips:"
    echo "- Run this script multiple times to see weight-based distribution"
    echo "- Use browser dev tools to inspect headers and responses"
    echo "- Check Istio/Kiali dashboard for traffic visualization"
    echo ""
}

# Run demonstration
main "$@"
