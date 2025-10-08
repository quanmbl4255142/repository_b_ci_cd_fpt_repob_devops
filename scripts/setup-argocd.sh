#!/bin/bash
# Script khởi động ArgoCD (đã có sẵn ArgoCD)
# Chạy: bash setup-argocd.sh

echo "🚀 Khởi động ArgoCD..."
echo ""

# 1. Kiểm tra và scale up ArgoCD pods
echo "📦 Bước 1: Khởi động ArgoCD pods..."
kubectl scale deployment argocd-server -n argocd-new --replicas=1
kubectl scale deployment argocd-repo-server -n argocd-new --replicas=1
kubectl scale deployment argocd-dex-server -n argocd-new --replicas=1
kubectl scale deployment argocd-redis -n argocd-new --replicas=1
kubectl scale deployment argocd-notifications-controller -n argocd-new --replicas=1
kubectl scale deployment argocd-applicationset-controller -n argocd-new --replicas=1
kubectl scale statefulset argocd-application-controller -n argocd-new --replicas=1

echo "   ⏳ Đợi pods khởi động..."
sleep 10

# 2. Kiểm tra trạng thái ArgoCD
echo ""
echo "📊 Bước 2: Kiểm tra trạng thái ArgoCD..."
kubectl get pods -n argocd-new

# 3. Đảm bảo polling interval = 50s
echo ""
echo "⚙️  Bước 3: Verify cấu hình polling = 50s..."
CURRENT_INTERVAL=$(kubectl get configmap argocd-cm -n argocd-new -o jsonpath='{.data.timeout\.reconciliation}' 2>/dev/null)
if [ "$CURRENT_INTERVAL" != "50s" ]; then
    echo "   🔧 Update polling interval = 50s..."
    kubectl patch configmap argocd-cm -n argocd-new --type merge -p '{"data":{"timeout.reconciliation":"50s"}}'
    kubectl rollout restart statefulset argocd-application-controller -n argocd-new
else
    echo "   ✅ Polling interval đã là 50s"
fi

# 4. Kiểm tra application
echo ""
echo "🎯 Bước 4: Kiểm tra ArgoCD Application..."
kubectl get app django-api-app -n argocd-new 2>/dev/null
if [ $? -ne 0 ]; then
    echo "   ⚠️  Application chưa tồn tại, tạo mới..."
    kubectl apply -f k8s/argocd-application.yaml
else
    echo "   ✅ Application đã tồn tại"
fi

# 5. Lấy ArgoCD password
echo ""
echo "🔑 Bước 5: Lấy ArgoCD admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd-new get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d)
if [ -n "$ARGOCD_PASSWORD" ]; then
    echo "   ✅ Admin Password: $ARGOCD_PASSWORD"
else
    echo "   ⚠️  Không có password (có thể đã đổi)"
fi

# 6. Hiển thị status
echo ""
echo "📊 Bước 6: Trạng thái hiện tại..."
echo ""
echo "=== ArgoCD Pods ==="
kubectl get pods -n argocd-new
echo ""
echo "=== ArgoCD Applications ==="
kubectl get app -n argocd-new
echo ""
echo "=== Django Pods ==="
kubectl get pods -n django-api 2>/dev/null || echo "Namespace django-api chưa có pods"

echo ""
echo "✅ =========================================="
echo "✅ ARGOCD ĐÃ KHỞI ĐỘNG!"
echo "✅ =========================================="
echo ""
echo "🌐 Để truy cập ArgoCD UI:"
echo "   kubectl port-forward svc/argocd-server -n argocd-new 8080:443"
echo "   Truy cập: https://localhost:8080"
echo "   Username: admin"
echo "   Password: $ARGOCD_PASSWORD"
echo ""
echo "🔄 Force sync ngay:"
echo "   kubectl patch app django-api-app -n argocd-new -p '{\"metadata\":{\"annotations\":{\"argocd.argoproj.io/refresh\":\"hard\"}}}' --type merge"
echo ""
echo "📊 Xem status:"
echo "   kubectl get app -n argocd-new"
echo "   kubectl get pods -n django-api"
echo ""

