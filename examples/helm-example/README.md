# Helm Hello-World Example

This example demonstrates how to deploy the hello-world application using Helm with ArgoCD.

## Structure

```text
config/helm/hello-world/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default values
├── values-dev.yaml         # Development values
├── values-staging.yaml     # Staging values
├── values-prod.yaml        # Production values
└── templates/              # Helm templates
    ├── _helpers.tpl        # Helper functions
    ├── deployment.yaml     # Deployment template
    ├── service.yaml        # Service template
    ├── configmap.yaml      # ConfigMap template
    ├── route.yaml          # Route template
    ├── hpa.yaml           # HPA template
    └── serviceaccount.yaml # ServiceAccount template
```

## Usage

### Local Deployment

```bash
# Deploy to dev environment
helm install hello-world-dev config/helm/hello-world \
  --values config/helm/hello-world/values-dev.yaml \
  --namespace dev \
  --create-namespace


# Deploy to staging environment
helm install hello-world-staging config/helm/hello-world \
  --values config/helm/hello-world/values-staging.yaml \
  --namespace staging \
  --create-namespace

# Deploy to production environment
helm install hello-world-prod config/helm/hello-world \
  --values config/helm/hello-world/values-prod.yaml \
  --namespace prod \
  --create-namespace
```

### ArgoCD Deployment

#### Using ApplicationSet (Recommended)

```bash
# Deploy all environments using ApplicationSet
oc apply -f argocd/applicationsets/helm-appset.yaml
```

#### Using Apps of Apps Pattern

```bash
# Deploy the root application
oc apply -f argocd/apps-of-apps/root-app.yaml
```

## Configuration

### Values Structure

The Helm chart uses a comprehensive values structure:

```yaml
# Application configuration
app:
  name: hello-world
  version: "1.0.0"

# Image configuration
image:
  repository: hello-world
  tag: "latest"
  pullPolicy: IfNotPresent

# Environment configuration
environment:
  name: "base"
  logLevel: "info"
  debugEnabled: false

# Deployment configuration
deployment:
  replicas: 1
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%

# Resource configuration
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

# Service configuration
service:
  type: ClusterIP
  port: 80
  targetPort: 80

# Route configuration
route:
  enabled: true
  host: hello-world.local
  annotations: {}
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect

# HPA configuration
hpa:
  enabled: false
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80

# Security configuration
security:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
      - ALL

# Health checks configuration
healthChecks:
  livenessProbe:
    enabled: true
    path: /
    port: 80
    initialDelaySeconds: 30
    periodSeconds: 10
    timeoutSeconds: 5
    failureThreshold: 3
  readinessProbe:
    enabled: true
    path: /
    port: 80
    initialDelaySeconds: 5
    periodSeconds: 5
    timeoutSeconds: 3
    failureThreshold: 3
```

## Environment Differences

### Development (`values-dev.yaml`)

- **Replicas**: 1
- **Resources**: 100m CPU, 128Mi memory
- **Log Level**: debug
- **Debug**: enabled
- **HPA**: disabled

### Staging (`values-staging.yaml`)

- **Replicas**: 2
- **Resources**: 200m CPU, 256Mi memory
- **Log Level**: info
- **Debug**: disabled
- **HPA**: disabled

### Production (`values-prod.yaml`)

- **Replicas**: 3
- **Resources**: 500m CPU, 512Mi memory
- **Log Level**: warn
- **Debug**: disabled
- **HPA**: enabled (3-10 replicas)

## Customization

### Adding a New Environment

1. Create a new values file:

```bash
cp config/helm/hello-world/values-dev.yaml config/helm/hello-world/values-new-env.yaml
```

2. Modify the values for the new environment:

```yaml
environment:
  name: "new-env"
  logLevel: "info"
  debugEnabled: false

deployment:
  replicas: 2

resources:
  requests:
    cpu: 200m
    memory: 256Mi
  limits:
    cpu: 400m
    memory: 512Mi

route:
  host: hello-world-new-env.local
```

3. Update ApplicationSet or create individual application

### Modifying Templates

To modify the Helm templates, edit files in `config/helm/hello-world/templates/`:

- `deployment.yaml`: Main application deployment
- `service.yaml`: Service configuration
- `configmap.yaml`: Configuration management
- `route.yaml`: Route rules
- `hpa.yaml`: Horizontal Pod Autoscaler
- `serviceaccount.yaml`: Service account

### Adding New Resources

1. Create a new template file in `templates/`
2. Use the helper functions for consistent naming
3. Add conditional rendering with `{{- if .Values.feature.enabled }}`
4. Update `values.yaml` with new configuration options

## Best Practices

1. **Values Organization**: Group related values logically
2. **Conditional Rendering**: Use `{{- if }}` for optional features
3. **Helper Functions**: Use `_helpers.tpl` for reusable functions
4. **Default Values**: Provide sensible defaults in `values.yaml`
5. **Environment Separation**: Use separate values files for environments
6. **Security**: Include security contexts and non-root containers
7. **Resource Management**: Set appropriate requests and limits
8. **Documentation**: Document all configurable values

## Troubleshooting

### Common Issues

1. **Template rendering errors**: Check Helm template syntax
2. **Values not applied**: Verify values file path and syntax
3. **Resource conflicts**: Check for naming conflicts
4. **Sync issues**: Check ArgoCD application status

### Debug Commands

```bash
# Test template rendering
helm template hello-world config/helm/hello-world \
  --values config/helm/hello-world/values-dev.yaml

# Lint the chart
helm lint config/helm/hello-world

# Check ArgoCD application status
oc get applications -n argocd

# View application logs
oc logs -l app.kubernetes.io/name=hello-world -n dev

# Check resource status
oc get all -n dev -l app.kubernetes.io/name=hello-world
```

### Helm Commands

```bash
# Install chart
helm install [RELEASE_NAME] [CHART_PATH] --values [VALUES_FILE]

# Upgrade chart
helm upgrade [RELEASE_NAME] [CHART_PATH] --values [VALUES_FILE]

# Uninstall chart
helm uninstall [RELEASE_NAME]

# List releases
helm list

# Get release values
helm get values [RELEASE_NAME]

# Rollback release
helm rollback [RELEASE_NAME] [REVISION]
```
