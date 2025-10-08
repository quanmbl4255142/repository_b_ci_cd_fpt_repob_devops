# 📊 HƯỚNG DẪN SỬ DỤNG GRAFANA MONITORING CHO ARGOCD

## 🎯 Tổng quan

Bộ monitoring này giúp bạn theo dõi ArgoCD thông qua:
- **Prometheus**: Thu thập metrics từ ArgoCD
- **Grafana**: Hiển thị dashboard trực quan, đẹp mắt

## 🚀 Cài đặt nhanh

### Cách 1: Chạy script tự động (Khuyến nghị)
```bash
cd Repository_B
bash scripts/setup-monitoring.sh
```

Script sẽ tự động:
- ✅ Kiểm tra ArgoCD đang chạy
- ✅ Tạo namespace `monitoring`
- ✅ Deploy Prometheus
- ✅ Deploy Grafana
- ✅ Cấu hình datasource tự động
- ✅ Hiển thị thông tin đăng nhập

### Cách 2: Deploy thủ công
```bash
# Apply toàn bộ manifest
kubectl apply -k monitoring/

# Hoặc deploy từng bước
kubectl apply -f monitoring/grafana/namespace.yaml
kubectl apply -f monitoring/prometheus/rbac.yaml
kubectl apply -f monitoring/prometheus/configmap.yaml
kubectl apply -f monitoring/prometheus/deployment.yaml
kubectl apply -f monitoring/prometheus/service.yaml
kubectl apply -f monitoring/grafana/pvc.yaml
kubectl apply -f monitoring/grafana/configmap-datasource.yaml
kubectl apply -f monitoring/grafana/configmap-dashboards.yaml
kubectl apply -f monitoring/grafana/deployment.yaml
kubectl apply -f monitoring/grafana/service.yaml
```

### Cách 3: Deploy qua ArgoCD (GitOps)
```bash
# Tạo ArgoCD Application cho monitoring
kubectl apply -f monitoring/argocd-monitoring-app.yaml

# ArgoCD sẽ tự động deploy và quản lý monitoring stack
```

## 🌐 Truy cập Grafana

### Qua NodePort (Đơn giản nhất)
```bash
# Truy cập trực tiếp
http://localhost:32000
```

### Qua Port-Forward
```bash
# Forward port 3000
kubectl port-forward svc/grafana-service -n monitoring 3000:3000

# Mở browser
http://localhost:3000
```

### Thông tin đăng nhập
```
Username: admin
Password: admin123
```

**⚠️ Lưu ý**: Nên đổi password sau khi đăng nhập lần đầu!

## 📈 Cài đặt Dashboard ArgoCD

### Bước 1: Login vào Grafana
1. Mở browser: http://localhost:32000
2. Đăng nhập với `admin` / `admin123`

### Bước 2: Kiểm tra Datasource
1. Click vào **⚙️ Configuration** (bên trái)
2. Chọn **Data sources**
3. Bạn sẽ thấy **Prometheus** đã được tự động cấu hình
4. Click vào **Prometheus** → Test
5. Phải hiển thị: ✅ **"Data source is working"**

### Bước 3: Import Dashboard ArgoCD

#### Dashboard 1: ArgoCD Overview
1. Click **➕** → **Import**
2. Nhập ID: `14584`
3. Click **Load**
4. Chọn datasource: **Prometheus**
5. Click **Import**

Dashboard này hiển thị:
- Tổng số applications
- Sync status (Synced/OutOfSync)
- Health status (Healthy/Degraded/Progressing)
- Git sync times

#### Dashboard 2: ArgoCD Application Details
1. Click **➕** → **Import**
2. Nhập ID: `19993`
3. Click **Load**
4. Chọn datasource: **Prometheus**
5. Click **Import**

Dashboard này hiển thị:
- Chi tiết từng application
- Resource usage
- Sync history
- API request rates

#### Dashboard 3: ArgoCD Notifications
1. Click **➕** → **Import**
2. Nhập ID: `19974`
3. Click **Load**
4. Chọn datasource: **Prometheus**
5. Click **Import**

Dashboard này hiển thị:
- Notification history
- Webhook events
- Alert status

### Bước 4: Xem Dashboard
1. Click **🏠 Dashboards** (bên trái)
2. Click vào **Manage** hoặc **Browse**
3. Chọn folder **ArgoCD**
4. Click vào dashboard bạn muốn xem

## 📊 Các Metrics quan trọng

### Application Status
```
- argocd_app_info: Thông tin về applications
- argocd_app_sync_total: Tổng số lần sync
- argocd_app_k8s_request_total: Số request tới K8s API
```

### Repository Sync
```
- argocd_git_request_total: Số lần request tới Git
- argocd_git_request_duration_seconds: Thời gian sync Git
```

### Performance
```
- argocd_api_requests_total: Tổng số API requests
- argocd_redis_request_duration: Redis performance
```

## 🔍 Kiểm tra và Troubleshooting

### Kiểm tra Pods
```bash
# Xem tất cả pods trong namespace monitoring
kubectl get pods -n monitoring

# Kết quả mong đợi:
# NAME                          READY   STATUS    RESTARTS   AGE
# prometheus-xxxxxxxxx-xxxxx    1/1     Running   0          5m
# grafana-xxxxxxxxx-xxxxx       1/1     Running   0          5m
```

### Kiểm tra Services
```bash
kubectl get svc -n monitoring

# Kết quả:
# NAME                 TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)
# prometheus-service   ClusterIP   10.x.x.x       <none>        9090/TCP
# grafana-service      NodePort    10.x.x.x       <none>        3000:32000/TCP
```

### Xem Logs

#### Prometheus Logs
```bash
kubectl logs -f deployment/prometheus -n monitoring
```

#### Grafana Logs
```bash
kubectl logs -f deployment/grafana -n monitoring
```

### Vấn đề thường gặp

#### 1. Grafana không kết nối được Prometheus
**Triệu chứng**: Dashboard không có data

**Giải pháp**:
```bash
# Kiểm tra Prometheus có chạy không
kubectl get pods -n monitoring -l app=prometheus

# Test DNS từ Grafana pod
kubectl exec -it deployment/grafana -n monitoring -- \
  nslookup prometheus-service.monitoring.svc.cluster.local

# Nếu DNS không work, restart Grafana
kubectl rollout restart deployment/grafana -n monitoring
```

#### 2. Prometheus không thu thập được metrics ArgoCD
**Triệu chứng**: Targets trong Prometheus UI hiển thị DOWN

**Giải pháp**:
```bash
# Kiểm tra ArgoCD pods có expose metrics không
kubectl get pods -n argocd-new -o wide

# Kiểm tra RBAC của Prometheus
kubectl get clusterrolebinding prometheus

# Restart Prometheus
kubectl rollout restart deployment/prometheus -n monitoring
```

#### 3. Dashboard bị lỗi "No data"
**Triệu chứng**: Dashboard import thành công nhưng không có data

**Giải pháp**:
1. Kiểm tra Datasource: Configuration → Data sources → Test
2. Kiểm tra Time range: Đảm bảo chọn "Last 1 hour" hoặc "Last 5 minutes"
3. Kiểm tra Prometheus targets: http://localhost:9090/targets

#### 4. Grafana pod không start
**Triệu chứng**: Pod ở trạng thái Pending hoặc CrashLoopBackOff

**Giải pháp**:
```bash
# Xem chi tiết pod
kubectl describe pod -n monitoring -l app=grafana

# Kiểm tra PVC
kubectl get pvc -n monitoring

# Nếu PVC pending, kiểm tra storage class
kubectl get storageclass

# Xem logs
kubectl logs -n monitoring -l app=grafana
```

## 🎨 Tùy chỉnh Grafana

### Đổi Password Admin
```bash
# Cách 1: Đổi qua UI
# Login → Profile → Change password

# Cách 2: Đổi qua Environment Variable
kubectl set env deployment/grafana -n monitoring \
  GF_SECURITY_ADMIN_PASSWORD=password_moi_cua_ban

# Restart Grafana
kubectl rollout restart deployment/grafana -n monitoring
```

### Tăng Storage cho Grafana
```bash
# Edit PVC (chỉ hoạt động nếu StorageClass hỗ trợ resize)
kubectl edit pvc grafana-pvc -n monitoring

# Thay đổi:
# storage: 5Gi → storage: 10Gi
```

### Enable SMTP cho Email Alerts
```bash
# Edit deployment
kubectl edit deployment grafana -n monitoring

# Thêm env variables:
# - name: GF_SMTP_ENABLED
#   value: "true"
# - name: GF_SMTP_HOST
#   value: "smtp.gmail.com:587"
# - name: GF_SMTP_USER
#   value: "your-email@gmail.com"
# - name: GF_SMTP_PASSWORD
#   value: "your-app-password"
# - name: GF_SMTP_FROM_ADDRESS
#   value: "your-email@gmail.com"
```

## 📊 Tạo Alert Rules (Nâng cao)

### Alert khi Application OutOfSync
1. Vào Dashboard → Edit
2. Thêm Alert rule:
```
Name: Application OutOfSync
Condition: argocd_app_info{sync_status="OutOfSync"} > 0
For: 5m
Annotations:
  Summary: Application {{ $labels.name }} is OutOfSync
```

### Alert khi Application Unhealthy
```
Name: Application Unhealthy
Condition: argocd_app_info{health_status!="Healthy"} > 0
For: 5m
```

## 🔄 Update và Backup

### Update Grafana version
```bash
# Edit deployment
kubectl set image deployment/grafana \
  grafana=grafana/grafana:10.2.0 \
  -n monitoring
```

### Backup Grafana Dashboards
```bash
# Export tất cả dashboards qua API
kubectl port-forward svc/grafana-service -n monitoring 3000:3000

# Sử dụng Grafana API để export
# hoặc export thủ công từ UI: Dashboard → Settings → JSON Model
```

### Backup Prometheus Data
```bash
# Tạo snapshot của PV (nếu dùng PVC)
kubectl get pvc -n monitoring

# Hoặc export metrics sang remote storage (Thanos, Cortex)
```

## 🗑️ Gỡ cài đặt

### Xóa toàn bộ monitoring stack
```bash
# Cách 1: Xóa namespace (nhanh nhất)
kubectl delete namespace monitoring

# Cách 2: Xóa từng resource
kubectl delete -k monitoring/

# Cách 3: Nếu deploy qua ArgoCD
kubectl delete app monitoring-stack -n argocd-new
```

### Xóa chỉ Grafana (giữ Prometheus)
```bash
kubectl delete deployment grafana -n monitoring
kubectl delete service grafana-service -n monitoring
kubectl delete pvc grafana-pvc -n monitoring
```

## 📚 Tips & Best Practices

### 1. Security
- ⚠️ Đổi password admin ngay sau khi setup
- 🔒 Không expose Grafana ra internet trực tiếp
- 🔐 Sử dụng HTTPS với certificate

### 2. Performance
- 📊 Điều chỉnh scrape interval phù hợp (default: 15s)
- 💾 Cấu hình retention cho Prometheus (default: 15 days)
- 🚀 Sử dụng PVC cho Prometheus nếu cần lưu data lâu dài

### 3. Monitoring
- 📈 Tạo alert cho các metrics quan trọng
- 📧 Cấu hình notification channels (Email, Slack, etc.)
- 📊 Tạo custom dashboard cho use case riêng

### 4. High Availability
- 🔄 Tăng replicas cho Prometheus (cần cấu hình thêm)
- 🎯 Sử dụng Thanos/Cortex cho long-term storage
- 💪 Setup Grafana HA với shared database

## ✅ Checklist sau khi cài đặt

- [ ] Grafana UI mở được: http://localhost:32000
- [ ] Login thành công với admin/admin123
- [ ] Datasource Prometheus status: ✅ Working
- [ ] Import được dashboard ArgoCD (ID: 14584)
- [ ] Dashboard hiển thị metrics của ArgoCD
- [ ] Prometheus targets status: UP
- [ ] Đã đổi password admin
- [ ] Backup cấu hình Grafana

## 🎯 Kết luận

Setup này cung cấp:
- ✅ Full observability cho ArgoCD
- ✅ Dashboard đẹp, trực quan
- ✅ Real-time monitoring
- ✅ Dễ dàng troubleshoot
- ✅ Tích hợp hoàn hảo với GitOps workflow

**Chúc bạn monitoring vui vẻ! 🚀📊**

## 📞 Liên hệ & Hỗ trợ

- [Grafana Documentation](https://grafana.com/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [ArgoCD Metrics](https://argo-cd.readthedocs.io/en/stable/operator-manual/metrics/)
- [Grafana Dashboards Community](https://grafana.com/grafana/dashboards/)

