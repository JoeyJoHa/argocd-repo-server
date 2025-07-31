#!/bin/bash

# Hello-World Application Deployment Script
# This script provides easy commands to deploy the hello-world application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if oc is available
check_oc() {
    if ! command -v oc &> /dev/null; then
        print_error "oc is not installed or not in PATH"
        exit 1
    fi
}

# Function to check if helm is available
check_helm() {
    if ! command -v helm &> /dev/null; then
        print_error "helm is not installed or not in PATH"
        exit 1
    fi
}

# Function to check if kustomize is available
check_kustomize() {
    if ! command -v kustomize &> /dev/null; then
        print_warning "kustomize is not installed. Some commands may not work."
    fi
}

# Function to deploy using Kustomize
deploy_kustomize() {
    local environment=$1
    local namespace=$2
    
    print_status "Deploying to $environment environment using Kustomize..."
    
    # Create namespace if it doesn't exist
    oc new-project $namespace --skip-config-write 2>/dev/null || true
    
    # Deploy using kustomize
    oc apply -k config/kustomize/overlays/$environment
    
    print_success "Deployed to $environment environment"
}

# Function to deploy using Helm
deploy_helm() {
    local environment=$1
    local namespace=$2
    local release_name="hello-world-$environment"
    
    print_status "Deploying to $environment environment using Helm..."
    
    # Create namespace if it doesn't exist
    oc new-project $namespace --skip-config-write 2>/dev/null || true
    
    # Deploy using helm
    helm upgrade --install $release_name config/helm/hello-world \
        --values config/helm/hello-world/values-$environment.yaml \
        --namespace $namespace \
        --wait \
        --timeout 5m
    
    print_success "Deployed to $environment environment"
}

# Function to deploy using ArgoCD ApplicationSet
deploy_argocd_appset() {
    local appset_type=$1
    
    print_status "Deploying using ArgoCD ApplicationSet ($appset_type)..."
    
    case $appset_type in
        "kustomize")
            oc apply -f argocd/applicationsets/kustomize-appset.yaml
            ;;
        "helm")
            oc apply -f argocd/applicationsets/helm-appset.yaml
            ;;
        "multi")
            oc apply -f argocd/applicationsets/multi-instance-appset.yaml
            ;;
        *)
            print_error "Unknown ApplicationSet type: $appset_type"
            exit 1
            ;;
    esac
    
    print_success "Deployed ApplicationSet ($appset_type)"
}

# Function to deploy using Apps of Apps pattern
deploy_apps_of_apps() {
    print_status "Deploying using Apps of Apps pattern..."
    
    oc apply -f argocd/apps-of-apps/root-app.yaml
    
    print_success "Deployed Apps of Apps pattern"
}

# Function to show status
show_status() {
    local environment=$1
    
    print_status "Checking status for $environment environment..."
    
    echo "=== Pods ==="
    oc get pods -n $environment -l app=hello-world
    
    echo "=== Services ==="
    oc get services -n $environment -l app=hello-world
    
    echo "=== Routes ==="
    oc get routes -n $environment -l app=hello-world
    
    if [ "$environment" = "prod" ]; then
        echo "=== HPA ==="
        oc get hpa -n $environment -l app=hello-world
    fi
}

# Function to show ArgoCD status
show_argocd_status() {
    print_status "Checking ArgoCD applications..."
    
    echo "=== Applications ==="
    oc get applications -n argocd
    
    echo "=== ApplicationSets ==="
    oc get applicationsets -n argocd
}

# Function to clean up
cleanup() {
    local environment=$1
    
    print_warning "Cleaning up $environment environment..."
    
    # Delete using kustomize
    oc delete -k config/kustomize/overlays/$environment --ignore-not-found=true
    
    # Delete using helm
    helm uninstall hello-world-$environment -n $environment --ignore-not-found=true
    
    # Delete namespace
    oc delete project $environment --ignore-not-found=true
    
    print_success "Cleaned up $environment environment"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  kustomize [env]     Deploy using Kustomize (env: dev, staging, prod)"
    echo "  helm [env]          Deploy using Helm (env: dev, staging, prod)"
    echo "  appset [type]       Deploy using ArgoCD ApplicationSet (type: kustomize, helm, multi)"
    echo "  apps-of-apps        Deploy using Apps of Apps pattern"
    echo "  status [env]        Show deployment status (env: dev, staging, prod)"
    echo "  argocd-status       Show ArgoCD applications status"
    echo "  cleanup [env]       Clean up deployment (env: dev, staging, prod)"
    echo "  help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 kustomize dev"
    echo "  $0 helm prod"
    echo "  $0 appset kustomize"
    echo "  $0 apps-of-apps"
    echo "  $0 status dev"
    echo "  $0 cleanup staging"
}

# Main script logic
main() {
    # Check prerequisites
    check_oc
    check_helm
    check_kustomize
    
    case $1 in
        "kustomize")
            if [ -z "$2" ]; then
                print_error "Environment not specified. Use: dev, staging, prod"
                exit 1
            fi
            deploy_kustomize $2 $2
            ;;
        "helm")
            if [ -z "$2" ]; then
                print_error "Environment not specified. Use: dev, staging, prod"
                exit 1
            fi
            deploy_helm $2 $2
            ;;
        "appset")
            if [ -z "$2" ]; then
                print_error "ApplicationSet type not specified. Use: kustomize, helm, multi"
                exit 1
            fi
            deploy_argocd_appset $2
            ;;
        "apps-of-apps")
            deploy_apps_of_apps
            ;;
        "status")
            if [ -z "$2" ]; then
                print_error "Environment not specified. Use: dev, staging, prod"
                exit 1
            fi
            show_status $2
            ;;
        "argocd-status")
            show_argocd_status
            ;;
        "cleanup")
            if [ -z "$2" ]; then
                print_error "Environment not specified. Use: dev, staging, prod"
                exit 1
            fi
            cleanup $2
            ;;
        "help"|"--help"|"-h"|"")
            show_usage
            ;;
        *)
            print_error "Unknown command: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@" 