# Repository B - Multi-App GitOps Repository

Repository này chứa Kubernetes manifests cho nhiều Django API services, được quản lý bởi ArgoCD.

## 📁 Cấu trúc

```
Repository_B/
├── apps/                    # Mỗi app có thư mục riêng
│   ├── django-api/         # App 1
│   │   ├── namespace.yaml
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── pvc.yaml
│   │   ├── ingress.yaml
│   │   └── kustomization.yaml
│   │
│   ├── app-2/              # App 2 (auto-generated)
│   │   └── ...
│   │
│   └── app-n/              # App N
│       └── ...
│
└── k8s/                    # ArgoCD configuration
    └── applicationset.yaml # Auto-discover apps in apps/
```

## 🚀 Cách hoạt động

### 1. Multi-App Structure
- Mỗi app có thư mục riêng trong `apps/<app-name>/`
- Mỗi app deploy vào namespace riêng: `{{app-name}}`
- Không bao giờ đè lên nhau

### 2. ArgoCD ApplicationSet
ApplicationSet tự động:
- Scan thư mục `apps/`
- Tạo ArgoCD Application cho mỗi thư mục tìm thấy
- Deploy vào namespace tương ứng với tên thư mục

### 3. Thêm App Mới

**Bước 1: Tạo thư mục app**
```bash
mkdir -p apps/my-new-app
```

**Bước 2: Copy manifests vào**
```bash
cp <generated-manifests>/*.yaml apps/my-new-app/
```

**Bước 3: Push lên Git**
```bash
git add apps/my-new-app/
git commit -m "Add my-new-app"
git push origin main
```

**ArgoCD sẽ tự động:**
- Phát hiện app mới
- Tạo Application `my-new-app`
- Deploy vào namespace `my-new-app`

### 4. Xóa App

```bash
# Xóa thư mục app
rm -rf apps/my-app

# Push lên Git
git add apps/
git commit -m "Remove my-app"
git push origin main
```

ArgoCD sẽ tự động xóa Application và resources.

## 🔧 Setup ArgoCD

### Deploy ApplicationSet
```bash
kubectl apply -f k8s/applicationset.yaml
```

### Kiểm tra Applications
```bash
# List all apps
kubectl get applications -n argocd-new

# Watch sync status
kubectl get applicationset -n argocd-new
```

## 📊 Current Apps

- **django-api** - Django REST API (port 8000)

## 🛠️ Dev Portal Integration

Khi tạo app mới từ Dev Portal:
1. Manifests được generate vào `apps/<app-name>/`
2. Auto-commit và push lên Repository_B
3. ArgoCD ApplicationSet phát hiện và deploy

## 📝 Notes

- Mỗi app PHẢI có namespace riêng (namespace.yaml)
- Tên thư mục = tên namespace = tên application
- ApplicationSet chỉ scan directories, không scan files
- Image Updater annotations vẫn hoạt động bình thường

## 🔗 Links

- ArgoCD: `https://argocd.yourdomain.com`
- Dashboard: Grafana (if configured)

---

**Quản lý bởi:** Dev Portal  
**ArgoCD Version:** v2.x

