# Hello-World Application with ArgoCD

This repository contains manifests for a hello-world application that can be deployed using ArgoCD with multiple deployment strategies:

1. **Kustomize-based deployment** - Using Kustomize overlays for environment-specific configurations
2. **Helm-based deployment** - Using Helm charts for templated deployments
3. **ApplicationSet** - For deploying multiple instances of the application
4. **Apps of Apps** - For managing multiple applications

## Project Structure

```text
.
├── README.md
├── config/
│   ├── kustomize/
│   │   ├── base/
│   │   │   ├── kustomization.yaml
│   │   │   ├── deployment.yaml
│   │   │   ├── service.yaml
│   │   │   ├── configmap.yaml
│   │   │   └── route.yaml
│   │   └── overlays/
│   │       ├── dev/
│   │       │   ├── kustomization.yaml
│   │       │   ├── patches/
│   │       │   │   └── replica-count.yaml
│   │       │   └── configmap.yaml
│   │       ├── staging/
│   │       │   ├── kustomization.yaml
│   │       │   ├── patches/
│   │       │   │   └── replica-count.yaml
│   │       │   └── configmap.yaml
│   │       └── prod/
│   │           ├── kustomization.yaml
│   │           ├── patches/
│   │           │   ├── replica-count.yaml
│   │           │   └── hpa.yaml
│   │           └── configmap.yaml
│   └── helm/
│       └── hello-world/
│           ├── Chart.yaml
│           ├── values.yaml
│           ├── templates/
│           │   ├── _helpers.tpl
│           │   ├── deployment.yaml
│           │   ├── service.yaml
│           │   ├── configmap.yaml
│           │   ├── route.yaml
│           │   └── hpa.yaml
│           └── README.md
├── argocd/
│   ├── applications/
│   │   ├── kustomize-apps/
│   │   │   ├── dev-app.yaml
│   │   │   ├── staging-app.yaml
│   │   │   └── prod-app.yaml
│   │   └── helm-apps/
│   │       ├── dev-helm-app.yaml
│   │       ├── staging-helm-app.yaml
│   │       └── prod-helm-app.yaml
│   ├── applicationsets/
│   │   ├── kustomize-appset.yaml
│   │   ├── helm-appset.yaml
│   │   └── multi-instance-appset.yaml
│   └── apps-of-apps/
│       ├── kustomize-apps-app.yaml
│       ├── helm-apps-app.yaml
│       └── root-app.yaml
└── examples/
    ├── kustomize-example/
    │   └── README.md
    └── helm-example/
        └── README.md
```

## Quick Start

### Prerequisites

- OpenShift cluster
- ArgoCD installed
- oc binary configured

### Deploy using Kustomize

```bash
# Deploy to dev environment
oc apply -k config/kustomize/overlays/dev

# Deploy to staging environment
oc apply -k config/kustomize/overlays/staging

# Deploy to production environment
oc apply -k config/kustomize/overlays/prod
```

### Deploy using Helm

```bash
# Deploy to dev environment
helm install hello-world-dev config/helm/hello-world \
  --values config/helm/hello-world/values-dev.yaml \
  --namespace dev

# Deploy to staging environment
helm install hello-world-staging config/helm/hello-world \
  --values config/helm/hello-world/values-staging.yaml \
  --namespace staging

# Deploy to production environment
helm install hello-world-prod config/helm/hello-world \
  --values config/helm/hello-world/values-prod.yaml \
  --namespace prod
```

### Deploy using ArgoCD

#### ApplicationSet (Recommended for multiple instances)

```bash
# Deploy Kustomize-based applications
oc apply -f argocd/applicationsets/kustomize-appset.yaml

# Deploy Helm-based applications
oc apply -f argocd/applicationsets/helm-appset.yaml

# Deploy multiple instances
oc apply -f argocd/applicationsets/multi-instance-appset.yaml
```

#### Apps of Apps Pattern

```bash
# Deploy the root application that manages other applications
oc apply -f argocd/apps-of-apps/root-app.yaml
```

## Features

- **Multi-environment support**: Dev, staging, and production configurations
- **Resource management**: Proper resource requests and limits
- **Health checks**: Liveness and readiness probes
- **Auto-scaling**: Horizontal Pod Autoscaler for production
- **Security**: Non-root containers, security contexts
- **Monitoring**: Prometheus annotations for metrics
- **Ingress support**: Configurable ingress rules
- **ConfigMap management**: Environment-specific configurations

## Configuration

### Environment Variables

- `ENVIRONMENT`: The deployment environment (dev, staging, prod)
- `LOG_LEVEL`: Logging level (debug, info, warn, error)
- `PORT`: Application port (default: 8080)

### Resource Requirements

- **Dev**: 100m CPU, 128Mi memory
- **Staging**: 200m CPU, 256Mi memory
- **Production**: 500m CPU, 512Mi memory

### Scaling

- **Dev**: 1 replica
- **Staging**: 2 replicas
- **Production**: 3+ replicas with HPA

## Monitoring and Observability

The application includes:

- Prometheus metrics endpoint at `/metrics`
- Health check endpoint at `/health`
- Readiness probe endpoint at `/ready`
- Structured JSON logging
- Kubernetes resource metrics

## Security

- Non-root containers
- Read-only root filesystem
- Drop unnecessary capabilities
- Network policies (if enabled)
- RBAC for service accounts

## Troubleshooting

### Common Issues

1. **Application not starting**: Check resource limits and requests
2. **Health checks failing**: Verify application endpoints
3. **Ingress not working**: Check ingress controller and annotations
4. **Scaling issues**: Review HPA configuration and metrics

### Debug Commands

```bash
# Check application status
oc get pods -l app=hello-world

# View application logs
oc logs -l app=hello-world

# Check ArgoCD application status
oc get applications -n argocd

# View ArgoCD application details
oc describe application hello-world-dev -n argocd
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with different environments
5. Submit a pull request

## License

MIT License - see LICENSE file for details
