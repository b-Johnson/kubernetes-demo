# Kubernetes Demo: Nginx Services with ArgoCD and Istio

This project demonstrates a complete Kubernetes setup with three nginx services deployed using ArgoCD and integrated with Istio service mesh for advanced traffic management, security, and observability.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   nginx-frontend │    │    nginx-api    │    │   nginx-admin   │
│   (3 replicas)   │    │   (2 replicas)  │    │   (1 replica)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │  Istio Gateway  │
                    │ & VirtualService│
                    └─────────────────┘
                                 │
                    ┌─────────────────┐
                    │  Load Balancer  │
                    │   (External)    │
                    └─────────────────┘
```

## 📋 Services Overview

### 🎨 Frontend Service (`nginx-frontend`)
- **Purpose**: User-facing web interface
- **Versions**: v1 (stable) and v2 (enhanced)
- **V1 Replicas**: 3 (for high availability)
- **V2 Replicas**: 2 (for canary testing)
- **Features**:
  - Custom HTML landing page
  - Health check endpoint (`/health`)
  - Istio sidecar injection
  - Circuit breaker protection
  - **Advanced Routing**: Weight, path, and header-based routing

### 🔀 Advanced Routing Capabilities
The frontend service demonstrates multiple Istio routing patterns:

#### Weight-Based Routing
- **Default Split**: 80% traffic to v1, 20% traffic to v2
- **Use Case**: Canary deployments and A/B testing
- **Adjustment**: Use `task traffic-split -- v1=60 v2=40`

#### Path-Based Routing
- **`/v2` path**: Always routes to v2 service
- **`/beta` path**: Routes to v2 for beta features
- **Use Case**: Feature-specific routing and testing

#### Header-Based Routing
- **`version: v2` header**: Forces routing to v2
- **`version: v1` header**: Forces routing to v1
- **Use Case**: Developer testing and user segmentation

### 🔌 API Service (`nginx-api`)
- **Purpose**: REST API endpoints
- **Replicas**: 2 (for load distribution)
- **Endpoints**:
  - `/api/v1/health` - Health status
  - `/api/v1/status` - Service status and available endpoints
- **Features**:
  - JSON responses
  - Rate limiting via Istio
  - Retry policies

### ⚙️ Admin Service (`nginx-admin`)
- **Purpose**: Administrative interface
- **Replicas**: 1 (single instance)
- **Endpoints**:
  - `/admin/health` - Admin health check
  - `/admin/metrics` - Basic system metrics
- **Features**:
  - Restricted access patterns
  - Enhanced security policies

## 🕸️ Istio Service Mesh Features

### Traffic Management
- **Gateway**: Single entry point for all services
- **VirtualServices**: Route-based traffic distribution
- **DestinationRules**: Load balancing and circuit breaker configurations

### Security
- **mTLS**: Mutual TLS encryption between services
- **AuthorizationPolicies**: Fine-grained access control
- **PeerAuthentication**: Service-to-service authentication

### Observability
- **Distributed Tracing**: Request flow tracking
- **Metrics Collection**: Prometheus integration
- **Service Map**: Visual service topology

## 🚀 ArgoCD GitOps

### Applications Managed
1. `nginx-frontend` - Frontend service deployment
2. `nginx-api` - API service deployment
3. `nginx-admin` - Admin service deployment
4. `istio-config` - Istio configuration management

### Features
- **Automated Sync**: Continuous deployment from Git
- **Self-Healing**: Automatic drift correction
- **Rollback Capability**: Easy reversion to previous versions
- **Multi-Environment**: Support for dev/staging/prod

## 🛠️ Prerequisites

Before deploying, ensure you have:

- Kubernetes cluster (v1.25+)
- kubectl configured
- Helm 3.x
- ArgoCD CLI (optional)
- istioctl (will be installed by script if missing)

The `devbox.json` configuration includes all necessary tools:
```bash
# Initialize devbox environment
devbox shell
```

## 🏠 Local Development

### Cluster Management

This project includes tasks for managing a local Kind (Kubernetes in Docker) cluster for development and testing:

#### Create Local Cluster
```bash
# Create a new Kind cluster with custom configuration
task create-cluster
```

This command:
- Creates a local Kubernetes cluster using Kind
- Uses a custom `kind-config.yaml` configuration
- Sets up the cluster ready for Istio and ArgoCD installation

#### Delete Local Cluster
```bash
# Remove the existing Kind cluster
task delete-cluster
```

This command:
- Completely removes the local Kind cluster
- Cleans up all associated resources
- Useful for starting fresh or cleanup

#### Complete Setup Flow
```bash
# Full local development setup
task create-cluster    # Create the cluster
task setup             # Install ArgoCD, Istio, and deploy apps
task port-forward      # Enable local access
```

### Development Workflow

1. **Initial Setup**: `task create-cluster && task setup`
2. **Development**: Make changes to manifests in Git
3. **Testing**: Use `task test-routing` to verify changes
4. **Cleanup**: `task delete-cluster` when done

**Note**: The Kind cluster configuration should include any specific settings needed for Istio load balancer support and proper networking.

## 🚀 Quick Start

### Option 1: Local Development (Recommended)
```bash
# Create local Kind cluster and deploy everything
task create-cluster
task setup
task port-forward
```

### Option 2: Existing Cluster
```bash
# Deploy to existing Kubernetes cluster
git clone <repository-url>
cd kubernetes-demo
./deploy.sh
# OR use task runner
task setup
```

### Access Services

Add to your `/etc/hosts`:
```
127.0.0.1 nginx-frontend.local
127.0.0.1 nginx-api.local
127.0.0.1 nginx-admin.local
```

Set up port forwarding:
```bash
# ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Istio Gateway
kubectl port-forward svc/istio-ingressgateway -n istio-system 8081:80
```

### Access URLs
- **ArgoCD UI**: https://localhost:8080 (admin/[password])
- **Frontend**: http://nginx-frontend.local:8081
- **Frontend V2 Path**: http://nginx-frontend.local:8081/v2
- **Frontend Beta Path**: http://nginx-frontend.local:8081/beta
- **API**: http://nginx-api.local:8081
- **Admin**: http://nginx-admin.local:8081

### Test Advanced Routing
```bash
# Test all routing patterns
task test-routing

# Manual routing tests
curl http://nginx-frontend.local:8081                    # Weight-based (80/20 split)
curl http://nginx-frontend.local:8081/v2                 # Path-based to v2
curl http://nginx-frontend.local:8081/beta               # Path-based to v2
curl -H "version: v2" http://nginx-frontend.local:8081   # Header-based to v2

# Adjust traffic split
task traffic-split -- v1=50 v2=50

# Canary deployment
task canary-deploy
```

## 📁 Project Structure

```
kubernetes-demo/
├── apps/                           # Application manifests
│   ├── nginx-frontend/            # Frontend service
│   ├── nginx-api/                 # API service
│   └── nginx-admin/               # Admin service
├── argocd/                        # ArgoCD applications
│   ├── nginx-frontend-app.yaml
│   ├── nginx-api-app.yaml
│   ├── nginx-admin-app.yaml
│   ├── istio-config-app.yaml
│   └── project.yaml
├── istio/                         # Istio configuration
│   ├── gateway.yaml               # Traffic entry point
│   ├── virtual-services.yaml     # Routing rules
│   ├── destination-rules.yaml    # Load balancing
│   └── security-policies.yaml    # Security configuration
├── k8s/                          # Base Kubernetes resources
│   └── namespace.yaml
├── monitoring/                    # Observability setup
│   └── observability.yaml
└── deploy.sh                     # Automated deployment script
```

## 🔧 Configuration Details

### Istio Traffic Policies

#### Load Balancing
- **Frontend**: `LEAST_CONN` - Distributes to least connected pods
- **API**: `ROUND_ROBIN` - Even distribution across pods
- **Admin**: `ROUND_ROBIN` - Simple round-robin for single pod

#### Circuit Breaker
- **Frontend**: 3 consecutive errors trigger 30s ejection
- **API**: 5 consecutive errors with 50% max ejection
- **Admin**: 2 consecutive errors with 100% ejection (fail-fast)

#### Security Policies
- **mTLS**: STRICT mode for all service communication
- **Authorization**: Fine-grained access control per service
- **Ingress**: Controlled external access through gateway

### ArgoCD Sync Policies

All applications configured with:
- **Automated Sync**: Enabled with prune and self-heal
- **Retry Logic**: 5 attempts with exponential backoff
- **History Limit**: 3 revisions retained
- **Health Checks**: Kubernetes-native health monitoring

## 📊 Monitoring and Observability

### Metrics Available
- Request rate per service
- Response time percentiles (50th, 95th, 99th)
- Error rates and status codes
- Circuit breaker status
- Pod resource utilization

### Grafana Dashboard
Pre-configured dashboard available at `monitoring/observability.yaml` includes:
- Service request rates
- Response time trends
- Error rate tracking
- Service topology view

### Distributed Tracing
Jaeger integration provides:
- End-to-end request tracing
- Service dependency mapping
- Performance bottleneck identification
- Error root cause analysis

## � Task Reference

The project includes a comprehensive Taskfile with commands for managing the entire lifecycle:

### Cluster Management
```bash
task create-cluster    # Create local Kind cluster
task delete-cluster    # Delete local Kind cluster
```

### Setup and Deployment
```bash
task setup             # Complete setup (ArgoCD + Istio + Apps)
task check-tools       # Verify required tools are installed
task create-namespace  # Create demo namespace with Istio injection
task install-argocd    # Install ArgoCD
task install-istio     # Install Istio service mesh
task deploy-apps       # Deploy all ArgoCD applications
```

### Monitoring and Status
```bash
task status            # Check status of all deployments
task logs              # Show logs for all nginx services
task get-argocd-password  # Get ArgoCD admin password
```

### Service Management
```bash
task test              # Test all service endpoints
task test-routing      # Test advanced routing rules
task restart           # Restart all nginx services
task scale -- frontend=5 api=3  # Scale services
```

### Traffic Management
```bash
task traffic-split -- v1=60 v2=40  # Adjust traffic split
task canary-deploy     # Gradual traffic shift to v2
```

### Access and Networking
```bash
task port-forward      # Setup port forwarding for local access
task istio-dashboard   # Open Kiali dashboard
```

### Cleanup
```bash
task clean            # Clean up all resources
```

### Usage Examples
```bash
# Full local development cycle
task create-cluster && task setup

# Monitor deployment
task status

# Test routing capabilities
task test-routing

# Perform canary deployment
task canary-deploy

# Cleanup when done
task delete-cluster
```

## �🐛 Troubleshooting

### Common Issues

1. **ArgoCD Application Not Syncing**
   ```bash
   # Check application status
   kubectl get applications -n argocd

   # View sync status
   argocd app get nginx-frontend
   ```

2. **Istio Sidecar Not Injected**
   ```bash
   # Verify namespace labeling
   kubectl get namespace demo --show-labels

   # Check pod sidecar status
   kubectl get pods -n demo -o jsonpath='{.items[*].spec.containers[*].name}'
   ```

3. **Service Not Accessible**
   ```bash
   # Check gateway status
   kubectl get gateway -n demo

   # Verify virtual service configuration
   kubectl get virtualservice -n demo -o yaml
   ```

### Useful Commands

```bash
# Check all nginx pods
kubectl get pods -n demo -l app.kubernetes.io/part-of=nginx-demo

# View Istio proxy configuration
istioctl proxy-config cluster <pod-name> -n demo

# Check ArgoCD application health
argocd app list

# Monitor traffic in real-time
kubectl logs -f deployment/istio-proxy -n istio-system
```

## 🔄 Development Workflow

### Making Changes

1. **Update Application Code**: Modify manifests in `apps/` directory
2. **Commit Changes**: Push to Git repository
3. **ArgoCD Sync**: Applications auto-sync or manual trigger
4. **Verify Deployment**: Check health in ArgoCD UI
5. **Monitor**: Use Grafana/Jaeger for observability

### Testing Changes

```bash
# Dry run deployment
kubectl apply --dry-run=client -f apps/nginx-frontend/

# Test Istio configuration
istioctl analyze

# Validate ArgoCD application
argocd app validate nginx-frontend
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Istio Documentation](https://istio.io/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
