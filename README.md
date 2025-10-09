# Repository_B - Multi-App Kubernetes Manifests

Repository quản lý Kubernetes manifests cho **NHIỀU Django applications** với ArgoCD GitOps.

## 🎯 Mục đích

Repository này chứa K8s manifests cho tất cả applications được deploy bởi **Dev-Portal**. Mỗi application có:
- ✅ Folder riêng trong `apps/<app-name>/`
- ✅ ArgoCD Application riêng trong `argocd-apps/<app-name>-app.yaml`
- ✅ **KHÔNG đè lên nhau**

## 📁 Cấu trúc

```
Repository_B/
├── apps/                      # Manifests cho từng application
│   ├── django-api/            # App 1
│   ├── ecommerce-api/         # App 2
│   └── blog-api/              # App 3
│
├── argocd-apps/               # ArgoCD Applications
│   ├── django-api-app.yaml
│   ├── ecommerce-api-app.yaml
│   ├── blog-api-app.yaml
│   └── app-of-apps.yaml
│
├── monitoring/                # Monitoring stack (Grafana, Prometheus)
│
└── scripts/                   # Helper scripts
    └── add-new-app.ps1
```

## 🚀 Quick Start

### Tạo app mới từ Dev-Portal

1. Truy cập Dev-Portal: http://localhost:8080
2. Điền thông tin app
3. Nhập GitHub token và username
4. Click "Deploy Tự Động"
5. Dev-Portal sẽ tự động:
   - Tạo Repository_A (Django code)
   - Push manifests vào `apps/<app-name>/`
   - Tạo ArgoCD Application

### Apply ArgoCD Application

```bash
# Cách 1: Apply từng app
kubectl apply -f argocd-apps/<app-name>-app.yaml

# Cách 2: App of Apps (khuyến nghị)
kubectl apply -f argocd-apps/app-of-apps.yaml
```

### Verify deployment

```bash
# Check ArgoCD apps
kubectl get app -n argocd-new

# Check pods
kubectl get pods -n <app-name>
```

## 📚 Tài liệu

- **[MULTI-APP-FLOW.md](MULTI-APP-FLOW.md)** - Luồng hoạt động đầy đủ
- **[DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md)** - Hướng dẫn deployment
- **[apps/README.md](apps/README.md)** - Quản lý applications
- **[GIAI-PHAP-REPOSITORY-B.md](../dev-portal-service/GIAI-PHAP-REPOSITORY-B.md)** - Giải pháp chi tiết

## 🔄 Workflow

```
Dev-Portal → Tạo Repo_A → GitHub Actions → Update Repo_B → ArgoCD Sync
```

Chi tiết xem [MULTI-APP-FLOW.md](MULTI-APP-FLOW.md)

## 🛠️ Scripts

### Thêm app mới thủ công

```powershell
.\scripts\add-new-app.ps1 `
  -AppName "my-api" `
  -DockerImage "ghcr.io/user/my-api"
```

## 📊 Applications hiện tại

| Application | Namespace | Status | Repository |
|------------|-----------|--------|------------|
| django-api | django-api | ✅ Active | [Repository_A](../Repository_A) |
| *(apps mới sẽ tự động hiện ở đây)* |

## 🔧 Troubleshooting

Xem [DEPLOYMENT-GUIDE.md#troubleshooting](DEPLOYMENT-GUIDE.md#troubleshooting)

---

**Maintained by**: Dev-Portal System  
**Last updated**: 2025-10-09

