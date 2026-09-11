#!/usr/bin/env bash
set -euo pipefail

TAG="${1:-v1}"
ROOT="${APP_ROOT:-$(cd "$(dirname "$0")/../../../ecommerce-platform-cloud" && pwd)}"
REGION="${AWS_REGION:-ap-south-1}"
PROJECT="${PROJECT_NAME:-ecommerce-platform}"
ENV="${ENVIRONMENT:-dev}"
PLATFORM="${PLATFORM:-linux/amd64}"

# Comma-separated list of services to build.
# Default matches the minimal DEV test configuration.
SERVICES="${SERVICES:-config-server,auth-service}"
IFS=',' read -r -a services <<< "$SERVICES"

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo "=========================================="
echo "E-Commerce Platform Image Build"
echo "=========================================="
echo "Environment : $ENV"
echo "Region      : $REGION"
echo "Platform    : $PLATFORM"
echo "Tag         : $TAG"
echo "Services    : ${services[*]}"
echo "=========================================="

aws ecr get-login-password --region "$REGION"   | docker login --username AWS --password-stdin "$REGISTRY"

for service in "${services[@]}"; do
  repo="${REGISTRY}/${PROJECT}/${service}"

  echo
  echo "Building $service:$TAG for $PLATFORM"

  docker buildx build     --platform "$PLATFORM"     -t "$repo:$TAG"     --push     "$ROOT/$service"

  echo "Pushed $repo:$TAG"
done

echo
echo "Images pushed successfully."
echo
echo "Terraform:"
echo "  terraform plan -var-file=terraform.tfvars"
echo "  terraform apply -var-file=terraform.tfvars"
