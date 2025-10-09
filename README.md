# Repository_B - Multi-App GitOps

Quản lý manifests cho NHIỀU Django applications với ArgoCD.

## Cấu trúc

```
Repository_B/
├── apps/                  ← Mỗi Git repo = 1 folder
│   └── django-api/        ← App hiện tại
│
└── argocd-apps/           ← ArgoCD Applications
    └── django-api-app.yaml
```

## Dev-Portal tự động tạo app mới

Khi tạo app mới từ Dev-Portal:
1. Tạo Repository_A mới (Django code + GitHub Actions)
2. Push vào Repository_B:
   - `apps/<app-name>/` ← Manifests
   - `argocd-apps/<app-name>-app.yaml` ← ArgoCD App
3. Apply: `kubectl apply -f argocd-apps/<app-name>-app.yaml`

## Đọc thêm

[HOW-IT-WORKS.md](HOW-IT-WORKS.md) - Luồng chi tiết

