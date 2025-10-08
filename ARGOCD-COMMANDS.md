# 📚 ArgoCD - Các lệnh thường dùng

## 🚀 Khởi động ArgoCD lần đầu

```bash
# Chạy script tự động
cd Repository_B
bash setup-argocd.sh
```

## 🔧 Các lệnh cấu hình cơ bản

### 1. Cài đặt ArgoCD
```bash
# Tạo namespace
kubectl create namespace argocd-new

# Cài ArgoCD
kubectl apply -n argocd-new -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Đợi pods sẵn sàng
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd-new --timeout=300s
```

### 2. Cấu hình auto-sync nhanh (50 giây)
```bash
# Set polling interval = 50s
kubectl patch configmap argocd-cm -n argocd-new --type merge -p '{"data":{"timeout.reconciliation":"50s"}}'

# Restart ArgoCD
kubectl rollout restart deployment argocd-repo-server -n argocd-new
kubectl rollout restart statefulset argocd-application-controller -n argocd-new
```

### 3. Deploy application
```bash
# Tạo namespace cho app
kubectl apply -f k8s/namespace.yaml

# Deploy ArgoCD Application
kubectl apply -f k8s/argocd-application.yaml

# Deploy webhook (optional)
kubectl apply -f k8s/argocd-webhook.yaml
```

### 4. Lấy password admin
```bash
kubectl -n argocd-new get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### 5. Truy cập ArgoCD UI
```bash
# Port forward
kubectl port-forward svc/argocd-server -n argocd-new 8080:443

# Truy cập: https://localhost:8080
# Username: admin
# Password: (từ lệnh trên)
```

## 🔍 Kiểm tra trạng thái

```bash
# Xem ArgoCD pods
kubectl get pods -n argocd-new

# Xem applications
kubectl get applications -n argocd-new

# Xem chi tiết app
kubectl get app django-api-app -n argocd-new -o yaml

# Xem Django pods
kubectl get pods -n django-api

# Xem deployment
kubectl get deployment django-api -n django-api
```

## 🔄 Force sync thủ công

```bash
# Method 1: Hard refresh
kubectl patch app django-api-app -n argocd-new \
  -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}' \
  --type merge

# Method 2: Trigger sync
kubectl patch app django-api-app -n argocd-new \
  -p '{"operation":{"initiatedBy":{"username":"manual"},"sync":{"revision":"HEAD"}}}' \
  --type merge
```

## 📊 Xem logs

```bash
# ArgoCD application controller
kubectl logs -f statefulset/argocd-application-controller -n argocd-new

# ArgoCD repo server
kubectl logs -f deployment/argocd-repo-server -n argocd-new

# Django app logs
kubectl logs -f deployment/django-api -n django-api

# Logs của pod cụ thể
kubectl logs -f <pod-name> -n django-api
```

## 🛠️ Troubleshooting

```bash
# Xem events
kubectl get events -n argocd-new --sort-by='.lastTimestamp'
kubectl get events -n django-api --sort-by='.lastTimestamp'

# Describe application
kubectl describe app django-api-app -n argocd-new

# Describe deployment
kubectl describe deployment django-api -n django-api

# Xem trạng thái sync
kubectl get app django-api-app -n argocd-new -o jsonpath='{.status.sync.status}'

# Xem revision hiện tại
kubectl get app django-api-app -n argocd-new -o jsonpath='{.status.sync.revision}'
```

## 🗑️ Xóa và cài lại

```bash
# Xóa application (giữ ArgoCD)
kubectl delete app django-api-app -n argocd-new

# Xóa Django resources
kubectl delete namespace django-api

# Xóa hoàn toàn ArgoCD
kubectl delete namespace argocd-new

# Sau đó chạy lại setup
bash setup-argocd.sh
```

## ⚙️ Cấu hình nâng cao

### Thay đổi polling interval
```bash
# Set 30 giây
kubectl patch configmap argocd-cm -n argocd-new --type merge -p '{"data":{"timeout.reconciliation":"30s"}}'

# Set 1 phút
kubectl patch configmap argocd-cm -n argocd-new --type merge -p '{"data":{"timeout.reconciliation":"60s"}}'

# Restart để apply
kubectl rollout restart statefulset argocd-application-controller -n argocd-new
```

### Kiểm tra cấu hình hiện tại
```bash
# Xem polling interval
kubectl get configmap argocd-cm -n argocd-new -o jsonpath='{.data.timeout\.reconciliation}'

# Xem toàn bộ config
kubectl get configmap argocd-cm -n argocd-new -o yaml
```

## 📝 Workflow CI/CD

1. **Developer push code** → Repository_A
2. **GitHub Actions**:
   - Build Docker image
   - Push to GHCR
   - Update `deployment.yaml` trong Repository_B
   - Update timestamp annotation
   - Push changes
3. **ArgoCD** (tự động sau ~50s):
   - Detect git changes
   - Sync deployment
   - Restart pods với image mới
4. **Kubernetes**:
   - Tạo pods mới
   - Database được giữ nguyên (PVC)
   - Auto run migrations
   - Rolling update pods

## 🎯 Kết quả mong đợi

- ✅ ArgoCD tự động sync mỗi **50 giây**
- ✅ Pods tự động restart khi có update
- ✅ Database **không mất data** khi restart
- ✅ Zero downtime deployment
- ✅ Auto run migrations

