#!/bin/bash
# Script cài đặt Monitoring Stack (Prometheus + Grafana) cho ArgoCD
# Chạy: bash setup-monitoring.sh

echo "📊 Cài đặt Monitoring Stack cho ArgoCD..."
echo ""

# 1. Kiểm tra ArgoCD đang chạy
echo "🔍 Bước 1: Kiểm tra ArgoCD..."
ARGOCD_PODS=$(kubectl get pods -n argocd-new --no-headers 2>/dev/null | wc -l)
if [ "$ARGOCD_PODS" -eq 0 ]; then
    echo "   ❌ ArgoCD chưa được cài đặt!"
    echo "   Chạy: bash scripts/setup-argocd.sh"
    exit 1
else
    echo "   ✅ ArgoCD đang chạy ($ARGOCD_PODS pods)"
fi

# 2. Tạo namespace monitoring
echo ""
echo "📦 Bước 2: Tạo namespace monitoring..."
kubectl apply -f monitoring/grafana/namespace.yaml
sleep 2

# 3. Deploy Prometheus
echo ""
echo "🔥 Bước 3: Deploy Prometheus..."
kubectl apply -f monitoring/prometheus/rbac.yaml
kubectl apply -f monitoring/prometheus/configmap.yaml
kubectl apply -f monitoring/prometheus/deployment.yaml
kubectl apply -f monitoring/prometheus/service.yaml

echo "   ⏳ Đợi Prometheus khởi động..."
sleep 15

# 4. Deploy Grafana
echo ""
echo "📈 Bước 4: Deploy Grafana..."
kubectl apply -f monitoring/grafana/pvc.yaml
kubectl apply -f monitoring/grafana/configmap-datasource.yaml
kubectl apply -f monitoring/grafana/configmap-dashboards.yaml
kubectl apply -f monitoring/grafana/deployment.yaml
kubectl apply -f monitoring/grafana/service.yaml

echo "   ⏳ Đợi Grafana khởi động..."
sleep 20

# 5. Kiểm tra pods
echo ""
echo "🔍 Bước 5: Kiểm tra trạng thái pods..."
kubectl get pods -n monitoring

# 6. Đợi pods sẵn sàng
echo ""
echo "⏳ Bước 6: Đợi pods sẵn sàng..."
kubectl wait --for=condition=ready pod -l app=prometheus -n monitoring --timeout=120s 2>/dev/null || echo "   ⚠️  Prometheus chưa ready, tiếp tục..."
kubectl wait --for=condition=ready pod -l app=grafana -n monitoring --timeout=120s 2>/dev/null || echo "   ⚠️  Grafana chưa ready, tiếp tục..."

# 7. Kiểm tra services
echo ""
echo "🌐 Bước 7: Kiểm tra services..."
kubectl get svc -n monitoring

# 8. Test Prometheus targets
echo ""
echo "🎯 Bước 8: Test Prometheus configuration..."
sleep 5
PROM_POD=$(kubectl get pods -n monitoring -l app=prometheus -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$PROM_POD" ]; then
    echo "   ✅ Prometheus pod: $PROM_POD"
else
    echo "   ⚠️  Prometheus pod chưa sẵn sàng"
fi

# 9. Lấy Grafana info
echo ""
echo "📊 Bước 9: Lấy thông tin Grafana..."
GRAFANA_POD=$(kubectl get pods -n monitoring -l app=grafana -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$GRAFANA_POD" ]; then
    echo "   ✅ Grafana pod: $GRAFANA_POD"
else
    echo "   ⚠️  Grafana pod chưa sẵn sàng"
fi

# 10. Hiển thị status cuối cùng
echo ""
echo "📊 Bước 10: Trạng thái hiện tại..."
echo ""
echo "=== Monitoring Pods ==="
kubectl get pods -n monitoring
echo ""
echo "=== Monitoring Services ==="
kubectl get svc -n monitoring

# Kết quả
echo ""
echo "✅ =========================================="
echo "✅ MONITORING STACK ĐÃ ĐƯỢC CÀI ĐẶT!"
echo "✅ =========================================="
echo ""
echo "📊 GRAFANA UI:"
echo "   🌐 NodePort: http://localhost:32000"
echo "   👤 Username: admin"
echo "   🔑 Password: admin123"
echo ""
echo "   Hoặc port-forward:"
echo "   kubectl port-forward svc/grafana-service -n monitoring 3000:3000"
echo "   Truy cập: http://localhost:3000"
echo ""
echo "🔥 PROMETHEUS UI:"
echo "   kubectl port-forward svc/prometheus-service -n monitoring 9090:9090"
echo "   Truy cập: http://localhost:9090"
echo ""
echo "📈 IMPORT ARGOCD DASHBOARDS:"
echo "   1. Login vào Grafana"
echo "   2. Vào Dashboards → Import"
echo "   3. Nhập ID dashboard:"
echo "      - ArgoCD Overview: 14584"
echo "      - ArgoCD Application: 19993"
echo "      - ArgoCD Notifications: 19974"
echo "   4. Chọn datasource: Prometheus"
echo "   5. Click Import"
echo ""
echo "🔍 KIỂM TRA:"
echo "   kubectl get pods -n monitoring"
echo "   kubectl logs -f deployment/prometheus -n monitoring"
echo "   kubectl logs -f deployment/grafana -n monitoring"
echo ""
echo "🗑️  XÓA (nếu cần):"
echo "   kubectl delete namespace monitoring"
echo ""

