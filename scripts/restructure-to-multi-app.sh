#!/bin/bash

# Script tự động tái cấu trúc Repository_B sang Multi-App Architecture
# Author: Django Dev Portal Team
# Version: 1.0.0

set -e

echo "🚀 Repository_B Multi-App Restructuring Script"
echo "=============================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if we're in Repository_B
if [ ! -d "k8s" ]; then
    echo -e "${RED}❌ Error: k8s/ directory not found!${NC}"
    echo "Please run this script from Repository_B root directory"
    exit 1
fi

echo -e "${BLUE}📋 Step 1: Backup current structure${NC}"
if [ ! -d "backup" ]; then
    mkdir -p backup
    cp -r k8s backup/k8s_$(date +%Y%m%d_%H%M%S)
    echo -e "${GREEN}✅ Backup created in backup/${NC}"
else
    cp -r k8s backup/k8s_$(date +%Y%m%d_%H%M%S)
    echo -e "${GREEN}✅ Backup updated${NC}"
fi

echo ""
echo -e "${BLUE}📋 Step 2: Create new directory structure${NC}"
mkdir -p apps/django-api
mkdir -p argocd-apps
echo -e "${GREEN}✅ Directories created${NC}"

echo ""
echo -e "${BLUE}📋 Step 3: Move existing manifests to apps/django-api/${NC}"
# Move all yaml files except argocd-application.yaml
for file in k8s/*.yaml; do
    filename=$(basename "$file")
    if [ "$filename" != "argocd-application.yaml" ]; then
        cp "$file" "apps/django-api/$filename"
        echo "  → Moved $filename"
    fi
done
echo -e "${GREEN}✅ Manifests moved${NC}"

echo ""
echo -e "${BLUE}📋 Step 4: Create new ArgoCD Application for django-api${NC}"
cat > argocd-apps/django-api-app.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: django-api-app
  namespace: argocd-new
  finalizers:
    - resources-finalizer.argocd.argoproj.io
  annotations:
    notifications.argoproj.io/subscribe.on-deployed.webhook: webhook:argocd-webhook
spec:
  project: default
  source:
    repoURL: https://github.com/QuanMBL4255142/Repository_B_CI_CD_FPT_repoB_Devops.git
    targetRevision: HEAD
    path: apps/django-api
  destination:
    server: https://kubernetes.default.svc
    namespace: django-api
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
    - CreateNamespace=true
    - PrunePropagationPolicy=foreground
    - PruneLast=true
    - ServerSideApply=true
    - Replace=true
  revisionHistoryLimit: 3
EOF
echo -e "${GREEN}✅ ArgoCD Application created${NC}"

echo ""
echo -e "${BLUE}📋 Step 5: Create App of Apps (optional)${NC}"
cat > argocd-apps/app-of-apps.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-of-apps
  namespace: argocd-new
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/QuanMBL4255142/Repository_B_CI_CD_FPT_repoB_Devops.git
    targetRevision: HEAD
    path: argocd-apps
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd-new
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF
echo -e "${GREEN}✅ App of Apps created${NC}"

echo ""
echo -e "${BLUE}📋 Step 6: Create script to add new apps${NC}"
cat > scripts/add-new-app.sh << 'EOFSCRIPT'
#!/bin/bash

# Script to add new application to Repository_B
# Usage: ./add-new-app.sh <app-name> <git-repo-url> <docker-image>

set -e

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <app-name> <git-repo-url> <docker-image>"
    echo "Example: $0 ecommerce-api https://github.com/user/ecommerce-api.git ghcr.io/user/ecommerce-api"
    exit 1
fi

APP_NAME=$1
GIT_REPO=$2
DOCKER_IMAGE=$3

echo "🚀 Adding new app: $APP_NAME"
echo "================================"

# Create app directory
mkdir -p "apps/$APP_NAME"

# Create namespace.yaml
cat > "apps/$APP_NAME/namespace.yaml" << EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $APP_NAME
  labels:
    name: $APP_NAME
EOF

# Create deployment.yaml
cat > "apps/$APP_NAME/deployment.yaml" << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $APP_NAME
  namespace: $APP_NAME
  labels:
    app: $APP_NAME
spec:
  replicas: 2
  selector:
    matchLabels:
      app: $APP_NAME
  template:
    metadata:
      labels:
        app: $APP_NAME
      annotations:
        timestamp: "$(date +%s)"
    spec:
      initContainers:
      - name: init-data-dir
        image: busybox:latest
        command: ['sh', '-c', 'mkdir -p /app/data && chmod 777 /app/data']
        volumeMounts:
        - name: app-data
          mountPath: /app/data
      containers:
      - name: $APP_NAME
        image: $DOCKER_IMAGE:latest
        command: ["/bin/sh", "-c"]
        args:
          - |
            python manage.py migrate --noinput
            python manage.py collectstatic --noinput
            gunicorn --bind 0.0.0.0:8000 django_api.wsgi:application
        ports:
        - containerPort: 8000
        env:
        - name: DJANGO_SETTINGS_MODULE
          value: "django_api.settings"
        volumeMounts:
        - name: app-data
          mountPath: /app/data
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /api/health/
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /api/health/
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: app-data
        persistentVolumeClaim:
          claimName: ${APP_NAME}-pvc
EOF

# Create service.yaml
cat > "apps/$APP_NAME/service.yaml" << EOF
apiVersion: v1
kind: Service
metadata:
  name: ${APP_NAME}-service
  namespace: $APP_NAME
  labels:
    app: $APP_NAME
spec:
  type: ClusterIP
  ports:
  - port: 8000
    targetPort: 8000
    protocol: TCP
    name: http
  selector:
    app: $APP_NAME
EOF

# Create pvc.yaml
cat > "apps/$APP_NAME/pvc.yaml" << EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${APP_NAME}-pvc
  namespace: $APP_NAME
  labels:
    app: $APP_NAME
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: standard
EOF

# Create ingress.yaml
cat > "apps/$APP_NAME/ingress.yaml" << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${APP_NAME}-ingress
  namespace: $APP_NAME
  labels:
    app: $APP_NAME
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: ${APP_NAME}.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ${APP_NAME}-service
            port:
              number: 8000
EOF

# Create kustomization.yaml
cat > "apps/$APP_NAME/kustomization.yaml" << EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- namespace.yaml
- pvc.yaml
- deployment.yaml
- service.yaml
- ingress.yaml

commonLabels:
  app: $APP_NAME
  version: v1.0.0

namespace: $APP_NAME
EOF

# Create ArgoCD Application
cat > "argocd-apps/${APP_NAME}-app.yaml" << EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${APP_NAME}-app
  namespace: argocd-new
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/QuanMBL4255142/Repository_B_CI_CD_FPT_repoB_Devops.git
    targetRevision: HEAD
    path: apps/$APP_NAME
  destination:
    server: https://kubernetes.default.svc
    namespace: $APP_NAME
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
    - CreateNamespace=true
    - PrunePropagationPolicy=foreground
  revisionHistoryLimit: 3
EOF

echo "✅ App structure created!"
echo ""
echo "📝 Next steps:"
echo "1. git add apps/$APP_NAME argocd-apps/${APP_NAME}-app.yaml"
echo "2. git commit -m 'Add $APP_NAME application'"
echo "3. git push origin main"
echo "4. kubectl apply -f argocd-apps/${APP_NAME}-app.yaml"
EOFSCRIPT

chmod +x scripts/add-new-app.sh
echo -e "${GREEN}✅ Helper script created${NC}"

echo ""
echo -e "${BLUE}📋 Step 7: Create README for new structure${NC}"
cat > apps/README.md << 'EOF'
# Apps Directory

This directory contains Kubernetes manifests for all applications managed by ArgoCD.

## Structure

```
apps/
├── django-api/         # Original app from Repository_A
├── ecommerce-api/      # New app example
└── blog-api/           # New app example
```

## Adding a New App

### Method 1: Using Script (Recommended)

```bash
cd Repository_B
./scripts/add-new-app.sh <app-name> <git-repo-url> <docker-image>
```

Example:
```bash
./scripts/add-new-app.sh ecommerce-api \
  https://github.com/user/ecommerce-api.git \
  ghcr.io/user/ecommerce-api
```

### Method 2: Manual

1. Create directory: `mkdir -p apps/my-app`
2. Add manifests: namespace, deployment, service, pvc, ingress, kustomization
3. Create ArgoCD app: `argocd-apps/my-app-app.yaml`
4. Commit and push
5. Apply: `kubectl apply -f argocd-apps/my-app-app.yaml`

## Directory Structure for Each App

```
apps/my-app/
├── namespace.yaml       # Kubernetes namespace
├── deployment.yaml      # Application deployment
├── service.yaml         # Service definition
├── pvc.yaml            # Persistent volume claim
├── ingress.yaml        # Ingress rules
└── kustomization.yaml  # Kustomize config
```

## Best Practices

1. **One app = One directory**
2. **Use meaningful names** (lowercase, hyphen-separated)
3. **Include health checks** in deployment
4. **Set resource limits** (memory, CPU)
5. **Use PVC** for data persistence
6. **Tag images properly** (not just :latest)

## Managing Apps

### List all apps
```bash
kubectl get applications -n argocd-new
```

### Sync an app
```bash
kubectl patch app my-app-app -n argocd-new \
  -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}' \
  --type merge
```

### Delete an app
```bash
kubectl delete app my-app-app -n argocd-new
kubectl delete namespace my-app
```

## Troubleshooting

### App not syncing
```bash
# Check app status
kubectl describe app my-app-app -n argocd-new

# Check ArgoCD logs
kubectl logs -f statefulset/argocd-application-controller -n argocd-new
```

### Deployment issues
```bash
# Check pods
kubectl get pods -n my-app

# Check events
kubectl get events -n my-app --sort-by='.lastTimestamp'
```

---

For more information, see: [GIAI-PHAP-REPOSITORY-B.md](../dev-portal-service/GIAI-PHAP-REPOSITORY-B.md)
EOF
echo -e "${GREEN}✅ README created${NC}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Restructuring completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}📋 New structure:${NC}"
echo "Repository_B/"
echo "├── apps/"
echo "│   └── django-api/      (existing app moved here)"
echo "├── argocd-apps/"
echo "│   ├── django-api-app.yaml"
echo "│   └── app-of-apps.yaml"
echo "└── backup/"
echo "    └── k8s_TIMESTAMP/   (backup of old structure)"
echo ""
echo -e "${YELLOW}📝 Next steps:${NC}"
echo "1. Review the changes"
echo "2. Test locally if needed"
echo "3. Commit and push:"
echo "   ${BLUE}git add apps/ argocd-apps/ scripts/ backup/${NC}"
echo "   ${BLUE}git commit -m 'Refactor: Multi-app architecture'${NC}"
echo "   ${BLUE}git push origin main${NC}"
echo ""
echo "4. Update ArgoCD:"
echo "   ${BLUE}kubectl delete app django-api-app -n argocd-new${NC}"
echo "   ${BLUE}kubectl apply -f argocd-apps/django-api-app.yaml${NC}"
echo ""
echo "5. (Optional) Use App of Apps pattern:"
echo "   ${BLUE}kubectl apply -f argocd-apps/app-of-apps.yaml${NC}"
echo ""
echo -e "${GREEN}🎉 Repository_B is now ready for multiple applications!${NC}"

#