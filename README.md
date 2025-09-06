# Mida Storage - ClickHouse & MinIO Deployment

Hướng dẫn deploy ClickHouse và MinIO lên Kubernetes cluster sử dụng Helm charts.

## Cấu hình

### ClickHouse
- **Username**: `root`
- **Password**: `hoangnx1`
- **Mode**: Single node
- **Public ports**: 30900 (web), 30123 (data)
- **Resource**: Không giới hạn CPU, RAM, Storage
- **Features**: Tự động backup và restart

### MinIO
- **Access Key**: `minio-admin`
- **Secret Key**: `minio-secret-key-2024`
- **Mode**: Standalone (single node)
- **Public port**: 30000
- **Default bucket**: `midareplay-storage`
- **Resource**: Không giới hạn CPU, RAM, Storage
- **Features**: Tự động restart

## Yêu cầu

- Kubernetes cluster đang chạy
- Helm 3.x đã được cài đặt
- kubectl đã được cấu hình để kết nối cluster

## Hướng dẫn Deploy

### Bước 1: Tạo Namespace

```bash
kubectl create namespace mida-storage
```

### Bước 2: Deploy ClickHouse

```bash
# Di chuyển đến thư mục ClickHouse
cd helmcharts/clickhouse

# Deploy ClickHouse
helm install clickhouse . -n mida-storage

# Kiểm tra trạng thái
kubectl get pods -n mida-storage
kubectl get svc -n mida-storage
```

### Bước 3: Deploy MinIO

```bash
# Di chuyển đến thư mục MinIO
cd ../minio

# Deploy MinIO
helm install minio . -n mida-storage

# Kiểm tra trạng thái
kubectl get pods -n mida-storage
kubectl get svc -n mida-storage
```

### Bước 4: Kiểm tra Services

```bash
# Xem tất cả services
kubectl get svc -n mida-storage

# Lấy NodePort để kết nối từ bên ngoài
kubectl get svc -n mida-storage -o wide
```

## Kết nối từ bên ngoài

### ClickHouse
```bash
# Kết nối qua web interface (port 30900)
http://<NODE_IP>:30900

# Kết nối qua client (port 30123)
clickhouse-client --host <NODE_IP> --port 30123 --user root --password hoangnx1
```

### MinIO
```bash
# Kết nối qua web interface (port 30000)
http://<NODE_IP>:30000

# Credentials:
# Access Key: minio-admin
# Secret Key: minio-secret-key-2024
```

## Lệnh hữu ích

### Xem logs
```bash
# ClickHouse logs
kubectl logs -f deployment/clickhouse -n mida-storage

# MinIO logs
kubectl logs -f deployment/minio -n mida-storage
```

### Restart services
```bash
# Restart ClickHouse
kubectl rollout restart statefulset/clickhouse -n mida-storage

# Restart MinIO
kubectl rollout restart deployment/minio -n mida-storage
```

### Xóa deployment
```bash
# Xóa MinIO
helm uninstall minio -n mida-storage

# Xóa ClickHouse
helm uninstall clickhouse -n mida-storage

# Xóa namespace
kubectl delete namespace mida-storage
```

## Cấu hình nâng cao

### Thay đổi cấu hình ClickHouse
Chỉnh sửa file `helmcharts/clickhouse/values.yaml` và update:

```bash
helm upgrade clickhouse ./helmcharts/clickhouse -n mida-storage
```

### Thay đổi cấu hình MinIO
Chỉnh sửa file `helmcharts/minio/values.yaml` và update:

```bash
helm upgrade minio ./helmcharts/minio -n mida-storage
```

### Backup và Restore

#### ClickHouse Backup
```bash
# Truy cập backup API (port 7171)
curl http://<NODE_IP>:7171/backup/create

# Xem danh sách backup
curl http://<NODE_IP>:7171/backup/list
```

#### MinIO Backup
MinIO tự động sync dữ liệu với persistent volume. Backup được thực hiện thông qua:
- Persistent Volume snapshots
- MinIO replication (nếu cấu hình)

## Troubleshooting

### ClickHouse không khởi động
```bash
# Kiểm tra logs
kubectl logs -f statefulset/clickhouse -n mida-storage

# Kiểm tra persistent volume
kubectl get pv,pvc -n mida-storage
```

### MinIO không khởi động
```bash
# Kiểm tra logs
kubectl logs -f deployment/minio -n mida-storage

# Kiểm tra service
kubectl describe svc minio -n mida-storage
```

### Không thể kết nối từ bên ngoài
```bash
# Kiểm tra NodePort services
kubectl get svc -n mida-storage

# Kiểm tra firewall rules trên nodes
# Đảm bảo ports 30000, 30123, 30900 đã được mở
```

## Cấu hình Security

### ClickHouse Security
- Mật khẩu đã được cấu hình: `hoangnx1`
- User `root` có full permissions
- Listen trên tất cả interfaces (0.0.0.0)

### MinIO Security
- Access/Secret keys đã được cấu hình
- Web UI enabled để quản lý
- Default bucket `midareplay-storage` được tạo tự động

## Monitoring

### ClickHouse Metrics
```bash
# System metrics
SELECT * FROM system.metrics;

# Query log
SELECT * FROM system.query_log LIMIT 10;
```

### MinIO Metrics
- Truy cập MinIO Console: http://<NODE_IP>:30000
- Xem metrics trong tab "Monitoring"

---

**Lưu ý**: Đây là cấu hình cho development/testing. Đối với production, cần cấu hình thêm SSL/TLS, authentication mạnh hơn, và resource limits phù hợp.
