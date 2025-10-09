# Cách hoạt động - Multi-App với ArgoCD

## 🎯 Vấn đề giải quyết

**Trước:** Mỗi app mới từ Dev-Portal đè lên manifests cũ  
**Sau:** Mỗi app có folder riêng, KHÔNG đè lên nhau

## 📁 Cấu trúc

```
Repository_B/
├── apps/                    ← Mỗi Git repo 1 folder
│   ├── django-api/          ← App 1
│   ├── ecommerce-api/       ← App 2 (từ Dev-Portal)
│   └── blog-api/            ← App 3 (từ Dev-Portal)
│
└── argocd-apps/             ← ArgoCD Applications
    ├── django-api-app.yaml
    ├── ecommerce-api-app.yaml
    └── blog-api-app.yaml
```

## 🔄 Luồng tự động (HOÀN TOÀN TỰ ĐỘNG)

```
SETUP 1 LẦN DUY NHẤT:
kubectl apply -f argocd-apps/applicationset.yaml
   ↓
SAU ĐÓ MỌI APP TỰ ĐỘNG:

1. Dev-Portal (nhập form)
   ↓
2. Tạo Git mới (Repository_A)
   - Django code
   - .github/workflows/ci-cd.yml
   ↓
3. Push vào Repository_B
   - apps/<app-name>/          ← Manifests
   ↓
4. ApplicationSet TỰ ĐỘNG PHÁT HIỆN folder mới
   → Tự động tạo ArgoCD Application ✅
   ↓
5. ArgoCD sync → App deployed ✅
   ↓
6. Developer push code → GitHub Actions
   ↓
7. Build image → Update apps/<app-name>/deployment.yaml
   ↓
8. ArgoCD auto-sync ✅
```

## ✅ Code đã sẵn sàng

- `dev-portal-service/github_manager.py` - Push đúng `apps/<app-name>/`
- `dev-portal-service/k8s_generator.py` - ArgoCD App trỏ `apps/<app-name>/`
- `.github/workflows/ci-cd.yml` - Update đúng path

## 🚀 Sử dụng

### Tạo app mới
1. Dev-Portal UI: http://localhost:8080
2. Nhập thông tin + GitHub token
3. Click "Deploy Tự Động"
4. Apply: `kubectl apply -f argocd-apps/<app-name>-app.yaml`

### Update app
Developer push code → GitHub Actions tự động update image → ArgoCD sync

---

**Đơn giản vậy thôi!**

