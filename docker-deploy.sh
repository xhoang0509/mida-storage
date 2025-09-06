#!/bin/bash

# Mida Storage Docker Compose Management Script
# Script để quản lý ClickHouse và MinIO bằng Docker Compose

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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
    
    # Check docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    
    # Check docker-compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not installed"
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        exit 1
    fi
    
    log_info "Prerequisites check passed"
}

create_directories() {
    log_info "Creating configuration directories..."
    mkdir -p clickhouse-config clickhouse-users
    log_info "Configuration directories created"
}

start_services() {
    log_info "Starting ClickHouse and MinIO services..."
    docker-compose up -d
    log_info "Services started successfully"
}

stop_services() {
    log_info "Stopping services..."
    docker-compose down
    log_info "Services stopped"
}

restart_services() {
    log_info "Restarting services..."
    docker-compose restart
    log_info "Services restarted"
}

check_status() {
    log_info "Checking services status..."
    docker-compose ps
    echo ""
    log_info "Service logs (last 20 lines):"
    echo "=== ClickHouse logs ==="
    docker-compose logs --tail=20 clickhouse
    echo ""
    echo "=== MinIO logs ==="
    docker-compose logs --tail=20 minio
}

get_connection_info() {
    log_info "Getting connection information..."
    
    # Get Docker host IP
    if command -v docker-machine &> /dev/null && docker-machine active &> /dev/null; then
        DOCKER_IP=$(docker-machine ip $(docker-machine active))
    else
        DOCKER_IP="localhost"
    fi
    
    echo ""
    echo "=== CONNECTION INFORMATION ==="
    echo "Docker Host: $DOCKER_IP"
    echo ""
    echo "ClickHouse:"
    echo "  - Web Interface: http://$DOCKER_IP:30900"
    echo "  - Data Port: $DOCKER_IP:30123"
    echo "  - Username: root"
    echo "  - Password: hoangnx1"
    echo ""
    echo "ClickHouse Backup API:"
    echo "  - Backup API: http://$DOCKER_IP:7171"
    echo ""
    echo "MinIO:"
    echo "  - Web Console: http://$DOCKER_IP:30000"
    echo "  - API Endpoint: http://$DOCKER_IP:9000"
    echo "  - Access Key: minio-admin"
    echo "  - Secret Key: minio-secret-key-2024"
    echo "  - Default Bucket: midareplay-storage"
    echo ""
}

cleanup() {
    log_warn "Cleaning up services and data..."
    docker-compose down -v
    docker-compose rm -f
    log_info "Cleanup completed"
}

show_help() {
    echo "Mida Storage Docker Compose Management Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start     - Start ClickHouse and MinIO services"
    echo "  stop      - Stop services"
    echo "  restart   - Restart services"
    echo "  status    - Check services status and logs"
    echo "  info      - Show connection information"
    echo "  cleanup   - Stop services and remove volumes"
    echo "  help      - Show this help message"
    echo ""
}

# Main script
case "$1" in
    "start")
        check_prerequisites
        create_directories
        start_services
        sleep 10  # Wait for services to start
        check_status
        get_connection_info
        ;;
    "stop")
        stop_services
        ;;
    "restart")
        restart_services
        ;;
    "status")
        check_status
        ;;
    "info")
        get_connection_info
        ;;
    "cleanup")
        cleanup
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
