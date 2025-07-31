# Kustomize Hello-World Example

This example demonstrates how to deploy the hello-world application using Kustomize with ArgoCD.

## Structure

```text
config/kustomize/
├── base/                    # Base configuration
│   ├── kustomization.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   └── route.yaml
└── overlays/               # Environment-specific overlays
    ├── dev/
    │   ├── kustomization.yaml
    │   ├── patches/
    │   │   └── replica-count.yaml
    │   └── configmap.yaml
    ├── staging/
    │   ├── kustomization.yaml
    │   ├── patches/
    │   │   └── replica-count.yaml
    │   └── configmap.yaml
    └── prod/
        ├── kustomization.yaml
        ├── patches/
        │   ├── replica-count.yaml
        │   └── hpa.yaml
        └── configmap.yaml
```

## Usage

### Local Deployment

```bash
# Deploy to dev environment
oc apply -k config/kustomize/overlays/dev

# Deploy to staging environment
oc apply -k config/kustomize/overlays/staging

# Deploy to production environment
oc apply -k config/kustomize/overlays/prod
```

### ArgoCD Deployment

#### Using ApplicationSet (Recommended)

```bash
# Deploy all environments using ApplicationSet
oc apply -f argocd/applicationsets/kustomize-appset.yaml
```

#### Using Apps of Apps Pattern

```bash
# Deploy the root application
oc apply -f argocd/apps-of-apps/root-app.yaml
```

## Environment Differences

### Development

- **Replicas**: 1
- **Resources**: 100m CPU, 128Mi memory
- **Log Level**: debug
- **Debug**: enabled
- **HPA**: disabled

### Staging

- **Replicas**: 2
- **Resources**: 200m CPU, 256Mi memory
- **Log Level**: info
- **Debug**: disabled
- **HPA**: disabled

### Production

- **Replicas**: 3
- **Resources**: 500m CPU, 512Mi memory
- **Log Level**: warn
- **Debug**: disabled
- **HPA**: enabled (3-10 replicas)

## Customization

### Adding a New Environment

1. Create a new overlay directory:

```bash
mkdir -p config/kustomize/overlays/new-env
```

2. Create the kustomization.yaml:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

metadata:
  name: hello-world-new-env

namespace: new-env

resources:
  - ../../base
  - configmap.yaml

patchesStrategicMerge:
  - patches/replica-count.yaml

namePrefix: new-env-

commonLabels:
  environment: new-env
  tier: new-env

commonAnnotations:
  environment: new-env
  managed-by: argocd
```

3. Create environment-specific patches and configs

### Modifying Base Configuration

To modify the base configuration, edit files in `config/kustomize/base/`:

- `deployment.yaml`: Main application deployment
- `service.yaml`: Service configuration
- `configmap.yaml`: Default configuration
- `route.yaml`: Route rules

### Adding New Resources

1. Add the resource to the base directory
2. Reference it in `base/kustomization.yaml`
3. Create patches in overlays if needed

## Best Practices

1. **Base Configuration**: Keep base configuration generic and reusable
2. **Overlays**: Use overlays for environment-specific customizations
3. **Patches**: Use strategic merge patches for simple changes
4. **Labels**: Apply consistent labels across all resources
5. **Namespaces**: Use separate namespaces for different environments
6. **Resource Management**: Set appropriate resource requests and limits
7. **Security**: Use non-root containers and security contexts
8. **Monitoring**: Include Prometheus annotations for metrics

## Troubleshooting

### Common Issues

1. **Namespace not found**: Ensure namespaces exist or use `CreateNamespace=true`
2. **Resource conflicts**: Check for naming conflicts with namePrefix
3. **Patch failures**: Verify patch syntax and target resources
4. **Sync issues**: Check ArgoCD application status and logs

### Debug Commands

```bash
# Check Kustomize build
kustomize build config/kustomize/overlays/dev

# Check ArgoCD application status
oc get applications -n argocd

# View application logs
oc logs -l app=hello-world -n dev

# Check resource status
oc get all -n dev -l app=hello-world
```
