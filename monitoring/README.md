# 📊 Monitoring Stack cho ArgoCD

Stack monitoring này bao gồm Prometheus và Grafana để theo dõi ArgoCD.

## 🏗️ Kiến trúc

```
┌─────────────────┐
│    Grafana      │  ← UI Dashboard (Port 32000)
│  (monitoring)   │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│   Prometheus    │  ← Thu thập metrics
│  (monitoring)   │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│     ArgoCD      │  ← Metrics endpoints
│  (argocd-new)   │
└─────────────────┘
```

## 📦 Components

### 1. Prometheus
- **Namespace**: monitoring
- **Port**: 9090
- **Chức năng**: Thu thập metrics từ ArgoCD components
- **Scrape targets**:
  - ArgoCD Application Controller (port 8082)
  - ArgoCD Server (port 8083)
  - ArgoCD Repo Server (port 8084)

### 2. Grafana
- **Namespace**: monitoring
- **Port**: 3000 (NodePort: 32000)
- **Credentials**:
  - Username: `admin`
  - Password: `admin123`
- **Storage**: PVC 5Gi
- **Datasource**: Prometheus (tự động cấu hình)

## 🚀 Cài đặt

### Cách 1: Deploy thủ công
```bash
# Apply toàn bộ monitoring stack
kubectl apply -k monitoring/

# Kiểm tra pods
kubectl get pods -n monitoring

# Đợi pods sẵn sàng
kubectl wait --for=condition=ready pod -l app=prometheus -n monitoring --timeout=300s
kubectl wait --for=condition=ready pod -l app=grafana -n monitoring --timeout=300s
```

### Cách 2: Deploy qua ArgoCD (Khuyến nghị)
```bash
# Tạo ArgoCD Application cho monitoring
kubectl apply -f monitoring/argocd-monitoring-app.yaml

# Kiểm tra sync status
kubectl get app monitoring-stack -n argocd-new

# Force sync nếu cần
kubectl patch app monitoring-stack -n argocd-new \
  -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}' \
  --type merge
```

## 🌐 Truy cập

### Grafana UI
```bash
# Truy cập qua NodePort
http://localhost:32000

# Hoặc port-forward
kubectl port-forward svc/grafana-service -n monitoring 3000:3000
# Truy cập: http://localhost:3000
```

**Login**:
- Username: `admin`
- Password: `admin123`

### Prometheus UI
```bash
# Port-forward
kubectl port-forward svc/prometheus-service -n monitoring 9090:9090
# Truy cập: http://localhost:9090
```

## 📊 Sử dụng Grafana

### Bước 1: Kiểm tra Datasource
1. Login vào Grafana
2. Vào **Configuration** → **Data sources**
3. Kiểm tra Prometheus datasource đã được tự động thêm
4. Test connection → Phải thấy "Data source is working"

### Bước 2: Import ArgoCD Dashboards
Grafana có sẵn các dashboard templates cho ArgoCD:

1. Vào **Dashboards** → **Import**
2. Nhập ID của dashboard ArgoCD từ Grafana.com:
   - **ArgoCD Overview**: ID `14584`
   - **ArgoCD Application**: ID `19993`
   - **ArgoCD Notifications**: ID `19974`

3. Chọn datasource: **Prometheus**
4. Click **Import**

### Bước 3: Xem Metrics
Dashboard sẽ hiển thị:
- ✅ Sync status của applications
- ✅ Health status
- ✅ Số lượng resources được quản lý
- ✅ API request rate
- ✅ Git repository sync times
- ✅ Resource usage (CPU, Memory)

## 🔍 Metrics quan trọng

### ArgoCD Metrics
```promql
# Số applications đang Synced
sum(argocd_app_info{sync_status="Synced"})

# Số applications OutOfSync
sum(argocd_app_info{sync_status="OutOfSync"})

# Health status
sum by (health_status) (argocd_app_info)

# Repository sync duration
argocd_git_request_duration_seconds

# API request rate
rate(argocd_api_requests_total[5m])
```

## 🛠️ Troubleshooting

### Prometheus không thu thập được metrics
```bash
# Kiểm tra Prometheus targets
kubectl port-forward svc/prometheus-service -n monitoring 9090:9090
# Vào http://localhost:9090/targets

# Kiểm tra RBAC
kubectl get clusterrolebinding prometheus -o yaml

# Kiểm tra logs
kubectl logs -f deployment/prometheus -n monitoring
```

### Grafana không kết nối được Prometheus
```bash
# Kiểm tra service
kubectl get svc -n monitoring

# Test DNS resolution từ Grafana pod
kubectl exec -it deployment/grafana -n monitoring -- nslookup prometheus-service.monitoring.svc.cluster.local

# Kiểm tra logs
kubectl logs -f deployment/grafana -n monitoring
```

### ArgoCD metrics không xuất hiện
```bash
# Enable metrics trong ArgoCD
kubectl patch configmap argocd-cmd-params-cm -n argocd-new \
  --type merge \
  -p '{"data":{"server.insecure":"true"}}'

# Restart ArgoCD components
kubectl rollout restart deployment argocd-server -n argocd-new
kubectl rollout restart statefulset argocd-application-controller -n argocd-new
```

## 📝 Cấu hình nâng cao

### Thay đổi Grafana admin password
```bash
# Update password trong deployment
kubectl set env deployment/grafana -n monitoring GF_SECURITY_ADMIN_PASSWORD=new_password

# Hoặc edit deployment
kubectl edit deployment grafana -n monitoring
```

### Thêm retention cho Prometheus
```bash
# Edit deployment, thêm args
- '--storage.tsdb.retention.time=30d'
- '--storage.tsdb.retention.size=10GB'
```

### Thêm PVC cho Prometheus
```yaml
# Tạo PVC
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: prometheus-pvc
  namespace: monitoring
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi

# Update deployment volume
volumes:
  - name: prometheus-storage
    persistentVolumeClaim:
      claimName: prometheus-pvc
```

## 🗑️ Xóa monitoring stack

```bash
# Xóa qua ArgoCD
kubectl delete app monitoring-stack -n argocd-new

# Hoặc xóa thủ công
kubectl delete -k monitoring/

# Xóa namespace
kubectl delete namespace monitoring
```

## 📚 Tài liệu tham khảo

- [ArgoCD Metrics](https://argo-cd.readthedocs.io/en/stable/operator-manual/metrics/)
- [Prometheus Operator](https://prometheus-operator.dev/)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)

## ✅ Checklist hoàn thành

- [x] Prometheus deployment
- [x] Grafana deployment
- [x] RBAC cho Prometheus
- [x] ConfigMap cho datasource
- [x] Service endpoints
- [x] ArgoCD Application
- [x] Documentation

## 🎯 Kết quả

Sau khi setup xong:
- ✅ Prometheus scrape metrics từ ArgoCD mỗi 15s
- ✅ Grafana hiển thị real-time dashboard
- ✅ Có thể theo dõi sync status, health, performance
- ✅ Alert khi có vấn đề (có thể mở rộng)
- ✅ Tích hợp hoàn toàn với ArgoCD GitOps workflow

