#!/bin/bash

# Mida Storage Deployment Script
# Script để deploy ClickHouse và MinIO lên Kubernetes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="mida-storage"
CLICKHOUSE_RELEASE="clickhouse"
MINIO_RELEASE="minio"

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed"
        exit 1
    fi
    
    # Check helm
    if ! command -v helm &> /dev/null; then
        log_error "helm is not installed"
        exit 1
    fi
    
    # Check cluster connection
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    log_info "Prerequisites check passed"
}

create_namespace() {
    log_info "Creating namespace: $NAMESPACE"
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
}

deploy_clickhouse() {
    log_info "Deploying ClickHouse..."
    cd helmcharts/clickhouse
    
    helm upgrade --install $CLICKHOUSE_RELEASE . \
        --namespace $NAMESPACE \
        --wait \
        --timeout 300s
    
    cd ../..
    log_info "ClickHouse deployed successfully"
}

deploy_minio() {
    log_info "Deploying MinIO..."
    cd helmcharts/minio
    
    helm upgrade --install $MINIO_RELEASE . \
        --namespace $NAMESPACE \
        --wait \
        --timeout 300s
    
    cd ../..
    log_info "MinIO deployed successfully"
}

check_status() {
    log_info "Checking deployment status..."
    
    echo "Pods:"
    kubectl get pods -n $NAMESPACE
    
    echo ""
    echo "Services:"
    kubectl get svc -n $NAMESPACE
    
    echo ""
    echo "PersistentVolumes:"
    kubectl get pvc -n $NAMESPACE
}

get_connection_info() {
    log_info "Getting connection information..."
    
    # Get node IP
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
    if [ -z "$NODE_IP" ]; then
        NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
    fi
    
    echo ""
    echo "=== CONNECTION INFORMATION ==="
    echo "Node IP: $NODE_IP"
    echo ""
    echo "ClickHouse:"
    echo "  - Web Interface: http://$NODE_IP:30900"
    echo "  - Data Port: $NODE_IP:30123"
    echo "  - Username: root"
    echo "  - Password: hoangnx1"
    echo ""
    echo "MinIO:"
    echo "  - Web Console: http://$NODE_IP:30000"
    echo "  - Access Key: minio-admin"
    echo "  - Secret Key: minio-secret-key-2024"
    echo "  - Default Bucket: midareplay-storage"
    echo ""
}

cleanup() {
    log_warn "Cleaning up deployments..."
    
    log_info "Uninstalling MinIO..."
    helm uninstall $MINIO_RELEASE -n $NAMESPACE || true
    
    log_info "Uninstalling ClickHouse..."
    helm uninstall $CLICKHOUSE_RELEASE -n $NAMESPACE || true
    
    log_info "Deleting namespace..."
    kubectl delete namespace $NAMESPACE || true
    
    log_info "Cleanup completed"
}

show_help() {
    echo "Mida Storage Deployment Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  deploy    - Deploy both ClickHouse and MinIO"
    echo "  cleanup   - Remove all deployments"
    echo "  status    - Check deployment status"
    echo "  info      - Show connection information"
    echo "  help      - Show this help message"
    echo ""
}

# Main script
case "$1" in
    "deploy")
        check_prerequisites
        create_namespace
        deploy_clickhouse
        deploy_minio
        check_status
        get_connection_info
        ;;
    "cleanup")
        cleanup
        ;;
    "status")
        check_status
        ;;
    "info")
        get_connection_info
        ;;
    "help"|"--help"|"-h")
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
