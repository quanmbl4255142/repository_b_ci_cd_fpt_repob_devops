# 🚀 Hướng Dẫn Deployment - Repository_B Multi-App

## ✅ ĐÃ RESTRUCTURE XONG!

Repository_B đã được tái cấu trúc thành **Multi-App Architecture** để giải quyết vấn đề **đè lên manifests** khi dev-portal-service tạo app mới.

## 📊 So sánh Cấu trúc

### ❌ Trước đây (Cấu trúc cũ)

```
Repository_B/
└── k8s/
    ├── argocd-application.yaml  ← CHỈ 1 APPLICATION
    ├── deployment.yaml          ← App mới ĐÈ LÊN app cũ
    ├── service.yaml
    └── ...
```

**Vấn đề:**
- Mỗi app mới từ dev-portal sẽ ghi đè lên `k8s/deployment.yaml`
- Chỉ có thể quản lý 1 app
- Không scale được

### ✅ Bây giờ (Cấu trúc mới)

```
Repository_B/
├── apps/
│   ├── django-api/              ← App gốc
│   │   ├── namespace.yaml
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── ...
│   │
│   ├── ecommerce-api/           ← App mới (KHÔNG đè lên)
│   │   └── ...
│   │
│   └── blog-api/                ← App mới khác (KHÔNG đè lên)
│       └── ...
│
├── argocd-apps/
│   ├── django-api-app.yaml      ← ArgoCD App cho django-api
│   ├── ecommerce-api-app.yaml   ← ArgoCD App cho ecommerce-api
│   ├── blog-api-app.yaml        ← ArgoCD App cho blog-api
│   └── app-of-apps.yaml         ← Master app (optional)
│
└── k8s/                         ← Giữ lại để tham khảo (backup)
```

**Lợi ích:**
- ✅ Mỗi app có folder RIÊNG
- ✅ KHÔNG đè lên nhau
- ✅ Quản lý NHIỀU apps dễ dàng
- ✅ Dev-portal tự động push đúng folder

## 🔄 BƯỚC QUAN TRỌNG: Cập nhật ArgoCD

### Bước 1: Xóa ArgoCD Application cũ

```bash
# Xóa application cũ (trỏ đến k8s/)
kubectl delete app django-api-app -n argocd-new
```

### Bước 2: Apply ArgoCD Application mới

```bash
# Apply application mới (trỏ đến apps/django-api/)
kubectl apply -f argocd-apps/django-api-app.yaml
```

### Bước 3: Kiểm tra sync

```bash
# Xem trạng thái
kubectl get app django-api-app -n argocd-new

# Watch sync process
kubectl get app django-api-app -n argocd-new -w

# Check pods
kubectl get pods -n django-api
```

### Bước 4 (Optional): Sử dụng App of Apps

```bash
# Deploy master app để quản lý tất cả apps
kubectl apply -f argocd-apps/app-of-apps.yaml

# App of Apps sẽ tự động tạo các child apps
kubectl get app -n argocd-new
```

## 📝 Commit và Push Changes

```bash
# Từ thư mục Repository_B

# 1. Add files mới
git add apps/ argocd-apps/ scripts/add-new-app.ps1 DEPLOYMENT-GUIDE.md

# 2. Commit
git commit -m "refactor: Multi-app architecture - Fix manifest overwrite issue"

# 3. Push
git push origin main
```

## 🎯 Cách Dev-Portal hoạt động sau khi restructure

### Luồng tự động

```
1. User tạo app "ecommerce-api" trên Dev-Portal
   ↓
2. Dev-Portal sinh:
   - Django code → Push to Repository_A (new repo)
   - K8s manifests → Push to Repository_B
   ↓
3. GitHub Manager push manifests VÀO:
   ❌ TRƯỚC: Repository_B/k8s/deployment.yaml (GHI ĐÈ)
   ✅ SAU: Repository_B/apps/ecommerce-api/deployment.yaml (RIÊNG)
   ↓
4. ArgoCD Application được tạo:
   Repository_B/argocd-apps/ecommerce-api-app.yaml
   ↓
5. ArgoCD sync → Deploy app mới
   ↓
6. KẾT QUẢ:
   - django-api: VẪN CHẠY ✅
   - ecommerce-api: CHẠY MỚI ✅
   - KHÔNG đè lên nhau ✅
```

### Code đã được update

**File `github_manager.py` (dòng 146-188):**
```python
def update_repository_b_manifests(self, repo_b_name: str, app_name: str, 
                                  manifests: Dict[str, str]) -> Dict:
    """Cập nhật K8s manifests trong Repository_B"""
    results = []
    
    for file_name, content in manifests.items():
        if file_name == 'argocd-application.yaml':
            # ArgoCD app đi vào argocd-apps/
            file_path = f"argocd-apps/{app_name}-app.yaml"
        else:
            # Các manifests khác vào apps/<app-name>/
            file_path = f"apps/{app_name}/{file_name}"  # ← ĐÂY!
```

**File `k8s_generator.py` (dòng 211-242):**
```python
def generate_argocd_application(self) -> str:
    """Generate ArgoCD Application YAML"""
    return f'''
    ...
    source:
      repoURL: {self.repo_b_url}
      targetRevision: HEAD
      path: apps/{self.app_name}  # ← ĐÂY!
    ...
    '''
```

## 🧪 Test với App Mới

### Test 1: Tạo app thủ công bằng script

```powershell
# Từ Repository_B
.\scripts\add-new-app.ps1 `
  -AppName "test-api" `
  -DockerImage "ghcr.io/youruser/test-api"

# Commit và push
git add apps/test-api argocd-apps/test-api-app.yaml
git commit -m "Add test-api"
git push origin main

# Deploy
kubectl apply -f argocd-apps/test-api-app.yaml
```

### Test 2: Tạo app qua Dev-Portal

1. Truy cập Dev-Portal: http://localhost:8080
2. Điền thông tin app mới
3. Nhập GitHub token và username
4. Click "Deploy Tự Động"
5. Dev-Portal sẽ:
   - Tạo Repository_A cho code Django
   - Push manifests vào `Repository_B/apps/<app-name>/`
   - Tạo ArgoCD Application
6. Kiểm tra:
   ```bash
   kubectl get app -n argocd-new
   kubectl get pods -n <app-name>
   ```

## 🔧 Troubleshooting

### Lỗi: ArgoCD không tìm thấy manifests

**Triệu chứng:**
```
Application django-api-app sync failed: path 'k8s' does not exist
```

**Nguyên nhân:**  
ArgoCD Application cũ vẫn trỏ đến `path: k8s`

**Giải pháp:**
```bash
# Xóa app cũ
kubectl delete app django-api-app -n argocd-new

# Apply app mới (trỏ đến apps/django-api)
kubectl apply -f argocd-apps/django-api-app.yaml
```

### Lỗi: Dev-Portal vẫn push vào k8s/

**Nguyên nhân:**  
Code dev-portal cũ chưa được update

**Giải pháp:**
```bash
# Pull code mới từ git
cd dev-portal-service
git pull origin main

# Hoặc restart dev-portal
docker-compose restart
```

### Lỗi: App mới đè lên app cũ

**Nguyên nhân:**  
Chưa commit/push cấu trúc mới lên git

**Giải pháp:**
```bash
cd Repository_B
git add apps/ argocd-apps/
git commit -m "Multi-app structure"
git push origin main
```

## 📚 Tài liệu chi tiết

- [apps/README.md](apps/README.md) - Hướng dẫn quản lý apps
- [GIAI-PHAP-REPOSITORY-B.md](../dev-portal-service/GIAI-PHAP-REPOSITORY-B.md) - Giải pháp chi tiết
- [scripts/add-new-app.ps1](scripts/add-new-app.ps1) - Script helper

## ✅ Checklist sau khi restructure

- [ ] Backup cấu trúc cũ (đã có trong `backup/`)
- [ ] Tạo cấu trúc mới `apps/`, `argocd-apps/`
- [ ] Di chuyển django-api vào `apps/django-api/`
- [ ] Commit và push lên git
- [ ] Xóa ArgoCD Application cũ
- [ ] Apply ArgoCD Application mới
- [ ] Verify django-api vẫn chạy
- [ ] Test tạo app mới
- [ ] Verify app mới KHÔNG đè lên app cũ

## 🎉 Kết quả mong đợi

Sau khi hoàn thành:

```bash
$ kubectl get app -n argocd-new
NAME               SYNC STATUS   HEALTH STATUS
django-api-app     Synced        Healthy         ← App cũ VẪN CHẠY
ecommerce-api-app  Synced        Healthy         ← App mới
blog-api-app       Synced        Healthy         ← App mới khác
```

```bash
$ kubectl get pods --all-namespaces | grep -E '(django-api|ecommerce|blog)'
django-api       django-api-xxx        1/1   Running   ← VẪN CHẠY
ecommerce-api    ecommerce-api-xxx     1/1   Running   ← MỚI
blog-api         blog-api-xxx          1/1   Running   ← MỚI
```

---

**Tạo bởi**: Django Dev Portal Team  
**Ngày**: 2025-10-09  
**Vấn đề giải quyết**: Dev-portal manifests bị đè lên nhau

