#!/usr/bin/env bash
set -euo pipefail

TAG="${1:-v1}"
ROOT="${APP_ROOT:-$(cd "$(dirname "$0")/../../ecommerce-platform-complete" && pwd)}"
REGION="${AWS_REGION:-ap-south-1}"
PROJECT="${PROJECT_NAME:-ecommerce-platform}"
ENV="${ENVIRONMENT:-dev}"

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REGISTRY"

services=(gateway-service config-server auth-service user-service catalog-service inventory-service order-service payment-service notification-service web-storefront)
for service in "${services[@]}"; do
  repo="${REGISTRY}/${PROJECT}/${service}"
  echo "Building $service:$TAG"
  docker build -t "$repo:$TAG" "$ROOT/$service"
  docker push "$repo:$TAG"
done

echo "Images pushed. Apply Terraform with app_image_tag=$TAG and deploy_services=true."
