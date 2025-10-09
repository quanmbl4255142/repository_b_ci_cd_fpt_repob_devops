# 🚀 SETUP - ApplicationSet Auto-Deploy

## 📋 Cách hoạt động

**ApplicationSet** tự động tạo ArgoCD Application cho mỗi folder trong `apps/`

```
apps/
├── django-api/      → ArgoCD tự động tạo: django-api-app
├── ecommerce-api/   → ArgoCD tự động tạo: ecommerce-api-app
└── blog-api/        → ArgoCD tự động tạo: blog-api-app
```

## ⚙️ SETUP (1 lần duy nhất)

### Bước 1: Commit Repository_B

```bash
cd Repository_B

git add apps/ argocd-apps/ .gitignore README.md HOW-IT-WORKS.md
git commit -m "Add ApplicationSet for auto-deploy"
git push origin main
```

### Bước 2: Apply ApplicationSet

```bash
kubectl apply -f https://raw.githubusercontent.com/QuanMBL4255142/Repository_B_CI_CD_FPT_repoB_Devops/main/argocd-apps/applicationset.yaml
```

### Bước 3: Verify

```bash
# Check ApplicationSet
kubectl get applicationset -n argocd-new

# Check Applications (đã tự động tạo)
kubectl get app -n argocd-new

# Sẽ thấy:
# NAME               SYNC STATUS   HEALTH STATUS
# django-api-app     Synced        Healthy      ← Tự động tạo!
```

## ✅ SAU KHI SETUP

### Tạo app mới từ Dev-Portal

```
1. Nhập form Dev-Portal
2. Click "Deploy Tự Động"
   ↓
3. Dev-Portal push vào Repository_B/apps/new-app/
   ↓
4. ApplicationSet PHÁT HIỆN folder mới
   ↓
5. TỰ ĐỘNG tạo ArgoCD Application ✅
   ↓
6. ArgoCD sync → Pods deployed ✅
```

**HOÀN TOÀN TỰ ĐỘNG - Không cần kubectl apply!**

## 🔍 Check Applications

```bash
# List tất cả apps
kubectl get app -n argocd-new

# Check sync status
kubectl get app <app-name>-app -n argocd-new -o yaml

# Check pods
kubectl get pods -n <app-name>
```

## 🛠️ Troubleshooting

### ApplicationSet không tạo Application mới

```bash
# Check ApplicationSet logs
kubectl logs -n argocd-new deployment/argocd-applicationset-controller

# Force refresh
kubectl patch applicationset multi-app-set -n argocd-new \
  -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}' \
  --type merge
```

### Application bị lỗi sync

```bash
# Check Application status
kubectl describe app <app-name>-app -n argocd-new

# Force sync
kubectl patch app <app-name>-app -n argocd-new \
  -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}' \
  --type merge
```

---

**Đơn giản vậy thôi!** Chỉ setup 1 lần, sau đó mọi app tự động! 🎉

