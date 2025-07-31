# Hello-World Application Deployment Guide

This guide provides comprehensive instructions for deploying the hello-world application using different methods and patterns.

## Quick Start

### Prerequisites

- OpenShift cluster
- ArgoCD installed (for GitOps deployment)
- oc binary configured
- Helm (for Helm-based deployment)
- Kustomize (for Kustomize-based deployment)

### Quick Deployment Commands

```bash
# Make the deployment script executable
chmod +x scripts/deploy.sh

# Deploy using Kustomize
./scripts/deploy.sh kustomize dev
./scripts/deploy.sh kustomize staging
./scripts/deploy.sh kustomize prod

# Deploy using Helm
./scripts/deploy.sh helm dev
./scripts/deploy.sh helm staging
./scripts/deploy.sh helm prod

# Deploy using ArgoCD ApplicationSet
./scripts/deploy.sh appset kustomize
./scripts/deploy.sh appset helm
./scripts/deploy.sh appset multi

# Deploy using Apps of Apps pattern
./scripts/deploy.sh apps-of-apps

# Check status
./scripts/deploy.sh status dev
./scripts/deploy.sh argocd-status

# Clean up
./scripts/deploy.sh cleanup dev
```

## Deployment Methods

### 1. Kustomize Deployment

**Best for**: Environment-specific customizations with minimal templating

**Structure**:

```text
config/kustomize/
├── base/                    # Base configuration
└── overlays/               # Environment-specific overlays
    ├── dev/
    ├── staging/
    └── prod/
```

**Deployment**:

```bash
# Local deployment
oc apply -k config/kustomize/overlays/dev
oc apply -k config/kustomize/overlays/staging
oc apply -k config/kustomize/overlays/prod

# ArgoCD deployment
oc apply -f argocd/applicationsets/kustomize-appset.yaml
```

**Features**:

- Environment-specific patches
- Strategic merge patches
- Common labels and annotations
- Namespace isolation
- Resource customization

### 2. Helm Deployment

**Best for**: Complex templating and package management

**Structure**:

```text
config/helm/hello-world/
├── Chart.yaml
├── values.yaml
├── values-dev.yaml
├── values-staging.yaml
├── values-prod.yaml
└── templates/
    ├── _helpers.tpl
    ├── deployment.yaml
    ├── service.yaml
    ├── configmap.yaml
    ├── route.yaml
    ├── hpa.yaml
    └── serviceaccount.yaml
```

**Deployment**:

```bash
# Local deployment
helm install hello-world-dev config/helm/hello-world \
  --values config/helm/hello-world/values-dev.yaml \
  --namespace dev

# ArgoCD deployment
kubectl apply -f argocd/applicationsets/helm-appset.yaml
```

**Features**:

- Template-based configuration
- Conditional resource rendering
- Environment-specific values
- Comprehensive configuration options
- Helm hooks and lifecycle management

### 3. ArgoCD ApplicationSet

**Best for**: Deploying multiple instances with similar configurations

**Types**:

- **Kustomize ApplicationSet**: Deploys Kustomize-based applications
- **Helm ApplicationSet**: Deploys Helm-based applications
- **Multi-Instance ApplicationSet**: Deploys multiple instances with different configurations

**Deployment**:

```bash
# Deploy all environments
oc apply -f argocd/applicationsets/kustomize-appset.yaml
oc apply -f argocd/applicationsets/helm-appset.yaml
oc apply -f argocd/applicationsets/multi-instance-appset.yaml
```

**Features**:

- Automated application creation
- Environment-specific configurations
- GitOps workflow
- Declarative management

### 4. Apps of Apps Pattern

**Best for**: Managing multiple applications with a hierarchical structure

**Structure**:

```text
argocd/apps-of-apps/
├── root-app.yaml           # Root application
├── kustomize-apps-app.yaml # Manages Kustomize apps
└── helm-apps-app.yaml      # Manages Helm apps

argocd/applications/
├── kustomize-apps/         # Individual Kustomize apps
└── helm-apps/              # Individual Helm apps
```

**Deployment**:

```bash
# Deploy the root application
oc apply -f argocd/apps-of-apps/root-app.yaml
```

**Features**:

- Hierarchical application management
- Centralized control
- Scalable architecture
- Environment separation

## Environment Configurations

### Development Environment

- **Replicas**: 1
- **Resources**: 100m CPU, 128Mi memory
- **Log Level**: debug
- **Debug**: enabled
- **HPA**: disabled
- **Namespace**: dev

### Staging Environment

- **Replicas**: 2
- **Resources**: 200m CPU, 256Mi memory
- **Log Level**: info
- **Debug**: disabled
- **HPA**: disabled
- **Namespace**: staging

### Production Environment

- **Replicas**: 3
- **Resources**: 500m CPU, 512Mi memory
- **Log Level**: warn
- **Debug**: disabled
- **HPA**: enabled (3-10 replicas)
- **Namespace**: prod

## Security Features

### Container Security

- Non-root containers (UID 1000)
- Read-only root filesystem
- Dropped capabilities
- Security contexts

### Network Security

- Network policies (if enabled)
- Ingress with proper annotations
- Service isolation

### Resource Security

- Resource limits and requests
- Pod disruption budgets
- Horizontal Pod Autoscaler

## Monitoring and Observability

### Health Checks

- Liveness probes
- Readiness probes
- Startup probes

### Metrics

- Prometheus annotations
- Metrics endpoint at `/metrics`
- Resource monitoring

### Logging

- Structured JSON logging
- Environment-specific log levels
- Centralized logging support

## Troubleshooting

### Common Issues

1. **Namespace not found**

   ```bash
   oc new-project dev
   ```

2. **Resource conflicts**

   ```bash
   oc get all -n dev -l app=hello-world
   oc delete -k config/kustomize/overlays/dev
   ```

3. **ArgoCD sync issues**

   ```bash
   oc get applications -n argocd
   oc describe application dev-hello-world -n argocd
   ```

4. **Helm template errors**

   ```bash
   helm template hello-world config/helm/hello-world --values values-dev.yaml
   helm lint config/helm/hello-world
   ```

### Debug Commands

```bash
# Check application status
oc get pods -n dev -l app=hello-world
oc logs -l app=hello-world -n dev

# Check ArgoCD status
oc get applications -n argocd
oc get applicationsets -n argocd

# Check Helm releases
helm list -n dev
helm get values hello-world-dev -n dev

# Check Kustomize build
kustomize build config/kustomize/overlays/dev
```

## Best Practices

### 1. GitOps Workflow

- Store all configurations in Git
- Use ArgoCD for automated deployment
- Implement proper RBAC
- Use pull request reviews

### 2. Environment Management

- Separate namespaces for environments
- Environment-specific configurations
- Consistent labeling and annotations
- Resource isolation

### 3. Security

- Use non-root containers
- Implement proper RBAC
- Secure secrets management
- Network policies

### 4. Monitoring

- Implement health checks
- Set up metrics collection
- Configure alerting
- Centralized logging

### 5. Resource Management

- Set appropriate resource limits
- Use HPA for production
- Monitor resource usage
- Implement proper scaling

## Migration Guide

### From Kustomize to Helm

1. Create Helm chart structure
2. Convert Kustomize patches to Helm values
3. Update ArgoCD applications
4. Test in staging environment
5. Deploy to production

### From Helm to Kustomize

1. Extract base configuration
2. Create overlay structure
3. Convert Helm values to Kustomize patches
4. Update ArgoCD applications
5. Test and deploy

## Advanced Features

### Multi-Instance Deployment

The multi-instance ApplicationSet demonstrates deploying multiple instances with different configurations:

```yaml
# Example: Different resource configurations
- instance: dev-instance-1
  replicas: 1
  resources:
    cpu: 100m
    memory: 128Mi
- instance: prod-instance-2
  replicas: 5
  resources:
    cpu: 1000m
    memory: 1Gi
```

### Custom Patches

Create custom patches for specific requirements:

```yaml
# Kustomize patch
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world
spec:
  replicas: 5
  template:
    spec:
      containers:
      - name: hello-world
        resources:
          requests:
            cpu: 500m
            memory: 512Mi
```

### Helm Hooks

Use Helm hooks for lifecycle management:

```yaml
# Example: Pre-install hook
apiVersion: batch/v1
kind: Job
metadata:
  name: pre-install-job
  annotations:
    helm.sh/hook: pre-install
spec:
  # Job specification
```

## Support and Maintenance

### Regular Maintenance

- Update base images regularly
- Review and update dependencies
- Monitor resource usage
- Update security patches

### Backup and Recovery

- Backup ArgoCD applications
- Export Helm releases
- Document configurations
- Test recovery procedures

### Documentation

- Keep README updated
- Document configuration changes
- Maintain troubleshooting guides
- Update deployment procedures
