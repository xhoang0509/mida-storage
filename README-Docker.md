# Mida Storage - Docker Compose Deployment

Hướng dẫn chạy ClickHouse và MinIO bằng Docker Compose thay vì Kubernetes.

## Tổng quan

Docker Compose này cung cấp:
- **ClickHouse**: Database cho analytics và logs
- **ClickHouse Backup**: Service backup tự động
- **MinIO**: Object storage tương thích S3

## Cấu hình Services

### ClickHouse
- **Image**: `clickhouse/clickhouse-server:23.8.2.7-alpine`
- **Username**: `root`
- **Password**: `hoangnx1`
- **Ports**:
  - `30900`: HTTP interface (Web UI)
  - `30123`: Native TCP interface
- **Volumes**: Data và logs được persist
- **Features**: JSON support, query cache, memory management

### ClickHouse Backup
- **Image**: `alexakulov/clickhouse-backup:latest`
- **Port**: `7171` (Backup API)
- **Features**: Local backup, S3 support (optional)

### MinIO
- **Image**: `bitnami/minio:2023.2.10-debian-11-r1`
- **Access Key**: `minio-admin`
- **Secret Key**: `minio-secret-key-2024`
- **Ports**:
  - `30000`: Web Console
  - `9000`: API Endpoint
- **Default Bucket**: `midareplay-storage`

## Yêu cầu

- Docker Engine 20.10+
- Docker Compose 2.0+ hoặc docker-compose 1.27+
- Tối thiểu 2GB RAM và 10GB disk space

## Hướng dẫn sử dụng

### Cách 1: Sử dụng script quản lý (Khuyến nghị)

```bash
# Cấp quyền thực thi cho script
chmod +x docker-deploy.sh

# Khởi động tất cả services
./docker-deploy.sh start

# Kiểm tra trạng thái
./docker-deploy.sh status

# Xem thông tin kết nối
./docker-deploy.sh info

# Dừng services
./docker-deploy.sh stop

# Khởi động lại
./docker-deploy.sh restart

# Xóa toàn bộ (bao gồm data)
./docker-deploy.sh cleanup
```

### Cách 2: Sử dụng docker-compose trực tiếp

```bash
# Khởi động services
docker-compose up -d

# Xem logs
docker-compose logs -f

# Kiểm tra trạng thái
docker-compose ps

# Dừng services
docker-compose down

# Xóa volumes (mất data)
docker-compose down -v
```

## Kết nối tới Services

### ClickHouse

#### Web Interface
```bash
# Truy cập web UI
http://localhost:30900

# Login:
# Username: root
# Password: hoangnx1
```

#### Command Line Client
```bash
# Kết nối bằng clickhouse-client
docker exec -it mida-clickhouse clickhouse-client --user root --password hoangnx1

# Hoặc từ host (nếu có clickhouse-client)
clickhouse-client --host localhost --port 30123 --user root --password hoangnx1
```

#### Backup API
```bash
# Tạo backup
curl -X POST http://localhost:7171/backup/create

# Xem danh sách backup
curl http://localhost:7171/backup/list

# Restore backup
curl -X POST http://localhost:7171/backup/restore/BACKUP_NAME
```

### MinIO

#### Web Console
```bash
# Truy cập web console
http://localhost:30000

# Login:
# Access Key: minio-admin
# Secret Key: minio-secret-key-2024
```

#### CLI (mc command)
```bash
# Cài đặt MinIO client
wget https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc

# Cấu hình alias
./mc alias set local http://localhost:9000 minio-admin minio-secret-key-2024

# Liệt kê buckets
./mc ls local

# Upload file
./mc cp file.txt local/midareplay-storage/
```

#### Python SDK
```python
from minio import Minio

client = Minio(
    "localhost:9000",
    access_key="minio-admin",
    secret_key="minio-secret-key-2024",
    secure=False
)

# List buckets
buckets = client.list_buckets()
for bucket in buckets:
    print(bucket.name)
```

## Quản lý Data

### Volumes
Data được lưu trong Docker volumes:
- `clickhouse_data`: ClickHouse database
- `clickhouse_logs`: ClickHouse logs
- `clickhouse_backup`: Backup files
- `minio_data`: MinIO objects

### Backup và Restore

#### ClickHouse Backup
```bash
# Tự động backup (qua API)
curl -X POST http://localhost:7171/backup/create

# Manual backup
docker exec mida-clickhouse clickhouse-client --query "BACKUP DATABASE default TO Disk('backups', 'backup_$(date +%Y%m%d_%H%M%S)')"
```

#### MinIO Backup
```bash
# Backup bucket
./mc mirror local/midareplay-storage/ ./backup/minio/

# Restore bucket
./mc mirror ./backup/minio/ local/midareplay-storage/
```

## Troubleshooting

### ClickHouse không khởi động
```bash
# Kiểm tra logs
docker-compose logs clickhouse

# Kiểm tra cấu hình
docker exec mida-clickhouse cat /etc/clickhouse-server/config.xml

# Restart service
docker-compose restart clickhouse
```

### MinIO không khởi động
```bash
# Kiểm tra logs
docker-compose logs minio

# Kiểm tra permissions
docker exec mida-minio ls -la /data

# Restart service
docker-compose restart minio
```

### Không thể kết nối từ bên ngoài
```bash
# Kiểm tra ports
docker-compose ps

# Kiểm tra network
docker network ls
docker network inspect mida-storage

# Kiểm tra firewall (Linux)
sudo ufw status
```

### Services chạy chậm
```bash
# Kiểm tra resource usage
docker stats

# Tăng memory limit (trong docker-compose.yml)
deploy:
  resources:
    limits:
      memory: 4G
```

## Cấu hình nâng cao

### Thay đổi cấu hình ClickHouse
Chỉnh sửa files trong thư mục `clickhouse-config/` và `clickhouse-users/`, sau đó restart:
```bash
docker-compose restart clickhouse
```

### Thay đổi cấu hình MinIO
Chỉnh sửa environment variables trong `docker-compose.yml`, sau đó:
```bash
docker-compose up -d minio
```

### S3 Backup cho ClickHouse
Uncomment và cấu hình các biến S3 trong `docker-compose.yml`:
```yaml
environment:
  REMOTE_STORAGE: "s3"
  S3_ACCESS_KEY: "minio-admin"
  S3_SECRET_KEY: "minio-secret-key-2024"
  S3_ENDPOINT: "http://minio:9000"
  S3_BUCKET: "clickhouse-backups"
```

## So sánh với Kubernetes

| Tính năng | Kubernetes | Docker Compose |
|-----------|------------|----------------|
| Deployment | Phức tạp, cần cluster | Đơn giản, chỉ cần Docker |
| Scaling | Auto-scaling | Manual scaling |
| HA | Built-in | Cần cấu hình thêm |
| Resource Management | Nâng cao | Cơ bản |
| Development | Phù hợp production | Phù hợp development |
| Networking | Service mesh | Bridge network |

**Khuyến nghị**: 
- Sử dụng Docker Compose cho development và testing
- Sử dụng Kubernetes cho production và staging

---

**Lưu ý**: Cấu hình này phù hợp cho development. Với production, cần thêm SSL/TLS, monitoring, và resource limits phù hợp.
