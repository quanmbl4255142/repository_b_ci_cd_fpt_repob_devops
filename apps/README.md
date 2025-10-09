# Apps Directory - Repository_B Multi-App Architecture

Thư mục này chứa Kubernetes manifests cho tất cả applications được quản lý bởi ArgoCD.

## 📁 Cấu trúc

```
apps/
├── django-api/         # App gốc từ Repository_A
│   ├── namespace.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── pvc.yaml
│   ├── ingress.yaml
│   └── kustomization.yaml
│
├── ecommerce-api/      # App mới từ Dev Portal
│   └── ... (tương tự)
│
└── blog-api/           # App mới từ Dev Portal
    └── ... (tương tự)
```

## 🎯 Giải quyết vấn đề gì?

**Trước đây (Cấu trúc cũ):**
```
Repository_B/
└── k8s/
    ├── deployment.yaml   ← CHỈ 1 APP
    └── service.yaml      ← Mỗi app mới sẽ ĐÈ LÊN app cũ
```

**Bây giờ (Cấu trúc mới):**
```
Repository_B/
├── apps/
│   ├── django-api/       ← Mỗi app có folder RIÊNG
│   ├── ecommerce-api/    ← KHÔNG đè lên nhau
│   └── blog-api/         ← Độc lập hoàn toàn
└── argocd-apps/
    ├── django-api-app.yaml
    ├── ecommerce-api-app.yaml
    └── blog-api-app.yaml
```

## ✅ Lợi ích

1. ✅ **Không đè lên nhau**: Mỗi app có folder riêng
2. ✅ **Dễ quản lý**: Rõ ràng, có tổ chức
3. ✅ **Scale tốt**: Thêm app = thêm folder
4. ✅ **CI/CD riêng**: Mỗi app có pipeline riêng
5. ✅ **ArgoCD riêng**: Mỗi app có Application riêng

## 🚀 Thêm App Mới

### Phương pháp 1: Sử dụng Script (Khuyến nghị)

```powershell
# Từ thư mục Repository_B
.\scripts\add-new-app.ps1 -AppName "my-new-api" -DockerImage "ghcr.io/user/my-new-api"
```

Script sẽ tự động tạo:
- `apps/my-new-api/` với tất cả manifests
- `argocd-apps/my-new-api-app.yaml`

### Phương pháp 2: Từ Dev Portal (Tự động)

Khi bạn sử dụng Dev Portal để tạo app mới:

1. Dev Portal sẽ tự động push manifests vào `apps/<app-name>/`
2. Tạo ArgoCD Application vào `argocd-apps/<app-name>-app.yaml`
3. Commit và push lên Repository_B
4. ArgoCD tự động sync

**Code trong `github_manager.py` đã được update:**
```python
def update_repository_b_manifests(self, repo_b_name: str, app_name: str, 
                                  manifests: Dict[str, str]):
    # Push vào apps/<app-name>/ thay vì k8s/
    file_path = f"apps/{app_name}/{file_name}"
```

## 📝 Cấu trúc cho mỗi App

Mỗi app folder phải có:

```
apps/my-app/
├── namespace.yaml       # Kubernetes namespace
├── deployment.yaml      # Application deployment
├── service.yaml         # Service ClusterIP
├── pvc.yaml            # PersistentVolumeClaim
├── ingress.yaml        # Ingress rules
└── kustomization.yaml  # Kustomize config
```

## 🔄 Workflow CI/CD

### Từ Dev Portal

```
1. User tạo app trên Dev Portal
   ↓
2. Dev Portal sinh code + K8s manifests
   ↓
3. Push code → Repository_A (Django app)
4. Push manifests → Repository_B/apps/<app-name>/
   ↓
5. GitHub Actions build image
   ↓
6. ArgoCD sync tự động
   ↓
7. App deployed ✅
```

### Workflow GitHub Actions (Repository_A)

File `.github/workflows/ci-cd.yml` trong Django app đã được update:

```yaml
# Update image trong Repository_B
DEPLOYMENT_FILE="apps/<app-name>/deployment.yaml"
sed -i "s|image: .*|image: ghcr.io/user/repo:latest|g" "$DEPLOYMENT_FILE"
```

## 🛠️ Quản lý Apps

### Liệt kê tất cả apps

```bash
kubectl get applications -n argocd-new
```

### Sync một app

```bash
kubectl patch app my-app-app -n argocd-new \
  -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}' \
  --type merge
```

### Xem trạng thái app

```bash
kubectl get app my-app-app -n argocd-new -o yaml
kubectl get pods -n my-app
```

### Xóa app

```bash
# Xóa ArgoCD Application (sẽ tự động xóa resources)
kubectl delete app my-app-app -n argocd-new

# Hoặc xóa namespace trực tiếp
kubectl delete namespace my-app
```

## 🔧 Troubleshooting

### App không sync

```bash
# Check app status
kubectl describe app my-app-app -n argocd-new

# Check ArgoCD logs
kubectl logs -f statefulset/argocd-application-controller -n argocd-new
```

### Deployment failed

```bash
# Check pods
kubectl get pods -n my-app

# Check events
kubectl get events -n my-app --sort-by='.lastTimestamp'

# Check logs
kubectl logs -f deployment/my-app -n my-app
```

### Manifests không update

```bash
# Force sync từ Git
kubectl patch app my-app-app -n argocd-new \
  --type merge \
  -p '{"operation":{"sync":{"syncStrategy":{"force":true}}}}'
```

## 📊 Best Practices

1. **Tên app**: Lowercase, dùng dấu gạch ngang (ví dụ: `ecommerce-api`)
2. **Namespace**: Mỗi app 1 namespace riêng
3. **Resources**: Đặt limits hợp lý cho memory/CPU
4. **Health checks**: Luôn có liveness & readiness probes
5. **PVC**: Sử dụng PersistentVolume cho data
6. **Image tags**: Tránh dùng `:latest` trong production

## 📚 Tài liệu tham khảo

- [GIAI-PHAP-REPOSITORY-B.md](../dev-portal-service/GIAI-PHAP-REPOSITORY-B.md) - Giải pháp chi tiết
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Kustomize Documentation](https://kustomize.io/)

## 💡 Ví dụ

### Thêm app "ecommerce-api"

```powershell
# 1. Tạo app structure
.\scripts\add-new-app.ps1 `
  -AppName "ecommerce-api" `
  -DockerImage "ghcr.io/myuser/ecommerce-api"

# 2. Commit và push
git add apps/ecommerce-api argocd-apps/ecommerce-api-app.yaml
git commit -m "Add ecommerce-api application"
git push origin main

# 3. Deploy với ArgoCD
kubectl apply -f argocd-apps/ecommerce-api-app.yaml

# 4. Kiểm tra
kubectl get app ecommerce-api-app -n argocd-new
kubectl get pods -n ecommerce-api
```

---

**Tạo bởi**: Django Dev Portal  
**Ngày cập nhật**: 2025-10-09

