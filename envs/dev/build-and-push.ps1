param([string]$Tag="v1")
$Root = if ($env:APP_ROOT) { $env:APP_ROOT } else { Resolve-Path "$PSScriptRoot/../../ecommerce-platform-complete" }
$Region = if ($env:AWS_REGION) { $env:AWS_REGION } else { "ap-south-1" }
$Project = if ($env:PROJECT_NAME) { $env:PROJECT_NAME } else { "ecommerce-platform" }
$AccountId = aws sts get-caller-identity --query Account --output text
$Registry = "$AccountId.dkr.ecr.$Region.amazonaws.com"
aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin $Registry
$Services = @("gateway-service","config-server","auth-service","user-service","catalog-service","inventory-service","order-service","payment-service","notification-service","web-storefront")
foreach ($service in $Services) {
  $repo = "$Registry/$Project/$service"
  docker build -t "$repo`:$Tag" "$Root/$service"
  docker push "$repo`:$Tag"
}
Write-Host "Images pushed. Set app_image_tag=$Tag and deploy_services=true before Terraform apply."
