# Script to add new application to Repository_B
# Usage: .\add-new-app.ps1 -AppName <app-name> -DockerImage <docker-image>
# Example: .\add-new-app.ps1 -AppName ecommerce-api -DockerImage ghcr.io/user/ecommerce-api

param(
    [Parameter(Mandatory=$true)]
    [string]$AppName,
    
    [Parameter(Mandatory=$true)]
    [string]$DockerImage,
    
    [Parameter(Mandatory=$false)]
    [string]$RepoURL = "https://github.com/QuanMBL4255142/Repository_B_CI_CD_FPT_repoB_Devops.git"
)

Write-Host "🚀 Adding new app: $AppName" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""

# Create app directory
$appPath = "apps\$AppName"
if (!(Test-Path $appPath)) {
    New-Item -ItemType Directory -Path $appPath -Force | Out-Null
    Write-Host "✅ Created directory: $appPath" -ForegroundColor Green
} else {
    Write-Host "⚠️  Directory already exists: $appPath" -ForegroundColor Yellow
}

# Create namespace.yaml
$namespaceContent = @"
apiVersion: v1
kind: Namespace
metadata:
  name: $AppName
  labels:
    name: $AppName
    managed-by: dev-portal
"@
Set-Content -Path "$appPath\namespace.yaml" -Value $namespaceContent
Write-Host "✅ Created namespace.yaml" -ForegroundColor Green

# Create deployment.yaml
$timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
$deploymentContent = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $AppName
  namespace: $AppName
  labels:
    app: $AppName
  annotations:
    argocd-image-updater.argoproj.io/image-list: ${AppName}=${DockerImage}
    argocd-image-updater.argoproj.io/write-back-method: git
    argocd-image-updater.argoproj.io/write-back-target: apps/${AppName}/deployment.yaml
    argocd-image-updater.argoproj.io/${AppName}.update-strategy: latest
spec:
  replicas: 2
  selector:
    matchLabels:
      app: $AppName
  template:
    metadata:
      labels:
        app: $AppName
      annotations:
        timestamp: "$timestamp"
    spec:
      initContainers:
      - name: init-data-dir
        image: busybox:latest
        command: ['sh', '-c', 'mkdir -p /app/data && chmod 777 /app/data']
        volumeMounts:
        - name: app-data
          mountPath: /app/data
      containers:
      - name: $AppName
        image: ${DockerImage}:latest
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
          claimName: ${AppName}-pvc
"@
Set-Content -Path "$appPath\deployment.yaml" -Value $deploymentContent
Write-Host "✅ Created deployment.yaml" -ForegroundColor Green

# Create service.yaml
$serviceContent = @"
apiVersion: v1
kind: Service
metadata:
  name: ${AppName}-service
  namespace: $AppName
  labels:
    app: $AppName
spec:
  type: ClusterIP
  ports:
  - port: 8000
    targetPort: 8000
    protocol: TCP
    name: http
  selector:
    app: $AppName
"@
Set-Content -Path "$appPath\service.yaml" -Value $serviceContent
Write-Host "✅ Created service.yaml" -ForegroundColor Green

# Create pvc.yaml
$pvcContent = @"
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${AppName}-pvc
  namespace: $AppName
  labels:
    app: $AppName
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: standard
"@
Set-Content -Path "$appPath\pvc.yaml" -Value $pvcContent
Write-Host "✅ Created pvc.yaml" -ForegroundColor Green

# Create ingress.yaml
$ingressContent = @"
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${AppName}-ingress
  namespace: $AppName
  labels:
    app: $AppName
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: ${AppName}.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ${AppName}-service
            port:
              number: 8000
"@
Set-Content -Path "$appPath\ingress.yaml" -Value $ingressContent
Write-Host "✅ Created ingress.yaml" -ForegroundColor Green

# Create kustomization.yaml
$kustomizationContent = @"
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- namespace.yaml
- pvc.yaml
- deployment.yaml
- service.yaml
- ingress.yaml

commonLabels:
  app: $AppName
  version: v1.0.0
  managed-by: dev-portal

namespace: $AppName
"@
Set-Content -Path "$appPath\kustomization.yaml" -Value $kustomizationContent
Write-Host "✅ Created kustomization.yaml" -ForegroundColor Green

# Create ArgoCD Application
$argocdAppContent = @"
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${AppName}-app
  namespace: argocd-new
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: $RepoURL
    targetRevision: HEAD
    path: apps/$AppName
  destination:
    server: https://kubernetes.default.svc
    namespace: $AppName
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
    - CreateNamespace=true
    - PrunePropagationPolicy=foreground
  revisionHistoryLimit: 3
"@
Set-Content -Path "argocd-apps\${AppName}-app.yaml" -Value $argocdAppContent
Write-Host "✅ Created ArgoCD Application" -ForegroundColor Green

Write-Host ""
Write-Host "================================" -ForegroundColor Green
Write-Host "✅ App structure created!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Next steps:" -ForegroundColor Yellow
Write-Host "1. git add apps/$AppName argocd-apps/${AppName}-app.yaml"
Write-Host "2. git commit -m 'Add $AppName application'"
Write-Host "3. git push origin main"
Write-Host "4. kubectl apply -f argocd-apps/${AppName}-app.yaml"
Write-Host ""
