# 🚀 Multi-App Flow - Dev-Portal → Git → Actions → ArgoCD

## 📋 Tổng quan

Hệ thống cho phép tạo **NHIỀU Django applications** từ Dev-Portal, mỗi app sẽ:
- ✅ Có Git repository riêng (Repository_A)
- ✅ Có folder riêng trong Repository_B: `apps/<app-name>/`
- ✅ Có ArgoCD Application riêng: `argocd-apps/<app-name>-app.yaml`
- ✅ **KHÔNG đè lên nhau**

## 🔄 Luồng hoạt động đầy đủ

```
┌─────────────────────────────────────────────────────────────────┐
│  BƯỚC 1: User tạo app từ Dev-Portal                             │
└─────────────────────────────────────────────────────────────────┘
                            ↓
    User điền form: 
    - Project: "ecommerce_api"
    - Models: Product, Category
    - GitHub username: "myuser"
    - GitHub token: "ghp_xxx"
    - Repo_A name: "ecommerce-api"
    - Repo_B name: "Repository_B"
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│  BƯỚC 2: Dev-Portal tự động tạo & push                          │
└─────────────────────────────────────────────────────────────────┘
                            ↓
    2.1. Tạo Django code
         ├─ models.py
         ├─ views.py
         ├─ serializers.py
         ├─ Dockerfile
         └─ .github/workflows/ci-cd.yml
                            ↓
    2.2. Push code → Repository_A (NEW)
         https://github.com/myuser/ecommerce-api
                            ↓
    2.3. Generate K8s manifests
         ├─ namespace.yaml
         ├─ deployment.yaml
         ├─ service.yaml
         ├─ pvc.yaml
         ├─ ingress.yaml
         ├─ kustomization.yaml
         └─ argocd-application.yaml
                            ↓
    2.4. Push manifests → Repository_B
         Repository_B/
         ├── apps/
         │   ├── django-api/         ← App cũ (giữ nguyên)
         │   └── ecommerce-api/      ← APP MỚI!
         │       ├── namespace.yaml
         │       ├── deployment.yaml
         │       └── ...
         └── argocd-apps/
             ├── django-api-app.yaml
             └── ecommerce-api-app.yaml  ← APP MỚI!
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│  BƯỚC 3: Apply ArgoCD Application (Manual/Auto)                 │
└─────────────────────────────────────────────────────────────────┘
                            ↓
    kubectl apply -f https://raw.githubusercontent.com/\
        myuser/Repository_B/main/argocd-apps/ecommerce-api-app.yaml
                            ↓
    ArgoCD sync → Deploy app lên K8s
                            ↓
    ✅ ecommerce-api RUNNING!
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│  BƯỚC 4: Developer sửa code & push (Các lần sau)                │
└─────────────────────────────────────────────────────────────────┘
                            ↓
    Developer:
    - Sửa models.py, views.py
    - git commit & push → Repository_A (ecommerce-api)
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│  BƯỚC 5: GitHub Actions tự động chạy                            │
└─────────────────────────────────────────────────────────────────┘
                            ↓
    5.1. Test Django code
    5.2. Build Docker image
         → ghcr.io/myuser/ecommerce-api:abc123
    5.3. Push image to registry
                            ↓
    5.4. Checkout Repository_B
    5.5. Update deployment.yaml:
         Repository_B/apps/ecommerce-api/deployment.yaml
         
         BEFORE: image: ghcr.io/myuser/ecommerce-api:latest
         AFTER:  image: ghcr.io/myuser/ecommerce-api:abc123
                            ↓
    5.6. Commit & push Repository_B
    5.7. Trigger ArgoCD sync
                            ↓
    ✅ ArgoCD auto-sync → Pods restart với image mới!
```

## 📁 Cấu trúc Repository_B (Multi-App)

```
Repository_B/
├── apps/                           ← MỖI APP 1 FOLDER
│   ├── django-api/                 ← App 1 (cũ)
│   │   ├── namespace.yaml
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── pvc.yaml
│   │   ├── ingress.yaml
│   │   └── kustomization.yaml
│   │
│   ├── ecommerce-api/              ← App 2 (mới)
│   │   ├── namespace.yaml
│   │   ├── deployment.yaml
│   │   └── ...
│   │
│   ├── blog-api/                   ← App 3 (mới)
│   │   └── ...
│   │
│   └── user-service/               ← App 4 (mới)
│       └── ...
│
├── argocd-apps/                    ← MỖI APP 1 ARGOCD APPLICATION
│   ├── django-api-app.yaml         ← Trỏ đến apps/django-api/
│   ├── ecommerce-api-app.yaml      ← Trỏ đến apps/ecommerce-api/
│   ├── blog-api-app.yaml           ← Trỏ đến apps/blog-api/
│   ├── user-service-app.yaml       ← Trỏ đến apps/user-service/
│   └── app-of-apps.yaml            ← Master app (optional)
│
├── monitoring/                     ← Monitoring stack
│   ├── grafana/
│   └── prometheus/
│
└── scripts/
    └── add-new-app.ps1             ← Helper script
```

## 🎯 Mapping: Repo_A ↔ Repo_B ↔ ArgoCD

| Repository_A (Code) | Repository_B (Manifests) | ArgoCD Application | Namespace |
|---------------------|--------------------------|-------------------|-----------|
| `django-api` | `apps/django-api/` | `django-api-app` | `django-api` |
| `ecommerce-api` | `apps/ecommerce-api/` | `ecommerce-api-app` | `ecommerce-api` |
| `blog-api` | `apps/blog-api/` | `blog-api-app` | `blog-api` |
| `user-service` | `apps/user-service/` | `user-service-app` | `user-service` |

## 📝 Example: Tạo app "ecommerce-api"

### Input (Dev-Portal UI)

```json
{
  "project_config": {
    "project_name": "ecommerce_api",
    "app_name": "products",
    "github_username": "myuser",
    "docker_registry": "ghcr.io",
    "repo_b_url": "https://github.com/myuser/Repository_B.git",
    "enable_cicd": true,
    "models": [
      {
        "name": "Product",
        "api_endpoint": "products",
        "fields": [...]
      }
    ]
  },
  "github_token": "ghp_xxxxxxxxxxxx",
  "repo_a_name": "ecommerce-api",
  "repo_b_name": "Repository_B",
  "create_new_repo_a": true,
  "auto_push_repo_b": true
}
```

### Output (Tự động tạo)

#### 1. Repository_A: `https://github.com/myuser/ecommerce-api`

```
ecommerce-api/
├── products/
│   ├── models.py        (Product model)
│   ├── views.py
│   ├── serializers.py
│   └── urls.py
├── ecommerce_api/
│   ├── settings.py
│   └── urls.py
├── Dockerfile
├── requirements.txt
└── .github/workflows/ci-cd.yml
```

#### 2. Repository_B: Updated

```
Repository_B/
├── apps/
│   └── ecommerce-api/   ← NEW!
│       ├── namespace.yaml
│       ├── deployment.yaml
│       └── ...
└── argocd-apps/
    └── ecommerce-api-app.yaml  ← NEW!
```

#### 3. ArgoCD Application

```yaml
# argocd-apps/ecommerce-api-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ecommerce-api-app
  namespace: argocd-new
spec:
  source:
    repoURL: https://github.com/myuser/Repository_B.git
    path: apps/ecommerce-api      # ← Trỏ đúng folder
  destination:
    namespace: ecommerce-api
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## ✅ Kiểm tra kết quả

### Sau khi Dev-Portal tạo xong

```bash
# Check Repository_B
cd Repository_B
git pull
ls apps/                    # Thấy ecommerce-api/
ls argocd-apps/            # Thấy ecommerce-api-app.yaml

# Apply ArgoCD
kubectl apply -f argocd-apps/ecommerce-api-app.yaml

# Check ArgoCD
kubectl get app -n argocd-new
# NAME                  SYNC STATUS   HEALTH STATUS
# django-api-app        Synced        Healthy      ← Cũ, vẫn chạy
# ecommerce-api-app     Synced        Healthy      ← Mới!

# Check pods
kubectl get pods -n ecommerce-api
# NAME                             READY   STATUS    RESTARTS
# ecommerce-api-xxxxxxxxx-xxxxx    1/1     Running   0
```

### Sau khi push code mới

```bash
# Developer push code
cd ecommerce-api
git commit -m "Update product model"
git push origin main

# GitHub Actions tự động:
# ✅ Build image mới
# ✅ Update apps/ecommerce-api/deployment.yaml
# ✅ Trigger ArgoCD sync

# Check update
kubectl get pods -n ecommerce-api -w
# Thấy pods restart với image mới
```

## 🔧 Code đã sẵn sàng

### ✅ `github_manager.py` (line 146-188)

```python
def update_repository_b_manifests(self, repo_b_name, app_name, manifests):
    for file_name, content in manifests.items():
        if file_name == 'argocd-application.yaml':
            file_path = f"argocd-apps/{app_name}-app.yaml"  # ✅
        else:
            file_path = f"apps/{app_name}/{file_name}"      # ✅
```

### ✅ `k8s_generator.py` (line 211-242)

```python
def generate_argocd_application(self):
    return f'''
    source:
      path: apps/{self.app_name}  # ✅ Trỏ đúng apps/
    '''
```

### ✅ `.github/workflows/ci-cd.yml` (Generated)

```yaml
DEPLOYMENT_FILE="apps/{app_name}/deployment.yaml"  # ✅ Update đúng path
```

## 🎉 Kết luận

- ✅ **Mỗi app Git** → 1 folder riêng trong Repository_B
- ✅ **Mỗi app** → 1 ArgoCD Application riêng
- ✅ **KHÔNG đè lên nhau**
- ✅ **Tự động từ đầu đến cuối**
- ✅ **Code đã sẵn sàng, không cần sửa gì**

---

**Updated**: 2025-10-09  
**Status**: ✅ Production Ready

