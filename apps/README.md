# Apps Directory

Mỗi application có 1 folder riêng. Dev-Portal tự động tạo.

## Cấu trúc

```
apps/
├── django-api/         # App hiện tại
├── ecommerce-api/      # App từ Dev-Portal
└── blog-api/           # App từ Dev-Portal
```

## Mỗi app folder chứa

- namespace.yaml
- deployment.yaml
- service.yaml
- pvc.yaml
- ingress.yaml
- kustomization.yaml

## Dev-Portal tự động push vào đây

Không cần tạo thủ công.

