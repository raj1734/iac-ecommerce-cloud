# IaC Completion Notes

The Terraform project now includes the UI tier as a first-class ECS service.

## ECS service topology

- API Gateway: 8080
- Config Server: 8889
- Auth: 8081
- Catalog: 8082
- Order/Cart: 8083
- Notification: 8084
- Inventory: 8086
- User: 8087
- Payment: 8088
- Web Storefront: 8090
- Zipkin: 9411

The public ALB targets **Web Storefront on port 8090**. The storefront calls the Gateway over private Cloud Map DNS. The Gateway then routes to backend services over private Cloud Map DNS.

## Important deployment sequence

1. Provision AWS infrastructure with `deploy_services=false`.
2. Push the application images with `envs/dev/build-and-push.sh <tag>` (or the PowerShell equivalent).
3. Re-run Terraform with `deploy_services=true` and the same `app_image_tag`.

The ECR repositories are created by Terraform. Terraform does not build Docker images itself.

## Secrets

RDS/DocumentDB credentials and the Redis auth token are stored in Secrets Manager and injected into ECS tasks. Kafka services use the ECS task IAM role for MSK IAM authentication.
