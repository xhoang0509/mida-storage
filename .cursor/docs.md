Dựa vào folder scripts/helmcharts/databases/charts của OpenReplay hãy copy Helmchart vào mida-storage/helmcharts giúp toi và chỉnh sửa theo cấu hình sau 

1. Clickhouse
- setup username: root, password: hoangnx1
- không cần limit resource: CPU, ram, storage
- tự đọng safefull và từ restart
- chỉ cần single node
- public port IP, có thể connect từ bên ngoài vào
2. Minio
- setup sercet_key đơn giản, tự gen và lưu vào file .env
- không cần limit resource: CPU, ram, storage
- tự đọng safefull và từ restart
- chỉ cần single node
- public port IP, có thể connect từ bên ngoài vào


Sau đó hãy hướng dẫn tôi chạy rụm k8s với cấu hình helm chart này