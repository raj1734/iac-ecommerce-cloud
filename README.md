# E-Commerce Platform - AWS Terraform (DEV)

This is the clean AWS IaC project for the distributed e-commerce platform. The DEV environment is the only root Terraform stack; reusable infrastructure lives under `modules/`.

## No duplicate infrastructure

There is exactly one owner for each infrastructure concern:

- `modules/vpc` - networking
- `modules/security-groups` - security groups
- `modules/ecr` - ECR repositories
- `modules/rds` - PostgreSQL
- `modules/redis` - ElastiCache Redis
- `modules/logs` - CloudWatch log groups
- `modules/ecs` - **all ECS clusters, application services, Kafka, MongoDB, Zipkin, Prometheus and Grafana**
- `modules/ecs-iam` - ECS IAM roles
- `modules/service-discovery` - Cloud Map namespace
- `modules/alb` - public ALB, gateway/storefront target groups and API rule
- `modules/waf` - WAF
- `modules/route53` - optional DNS
- `modules/secrets` - Secrets Manager metadata only; values are NOT written there
- `modules/kms` - KMS keys

Legacy root-level ECS/observability Terraform files are intentionally removed. The project must be run from `envs/dev`.

## AWS topology

Application services:

- Gateway 8080
- Auth 8081
- Catalog 8082
- Order 8083
- Notification 8084
- Inventory 8086
- User 8087
- Payment 8088
- Config Server 8889
- Web Storefront 8090

Observability:

- Zipkin 9411 (private Cloud Map DNS)
- Prometheus 9090 via `/prometheus/`
- Grafana 3000 via `/grafana/`

The public ALB defaults to the storefront. `/api/*` is forwarded to the gateway. The storefront calls the gateway using private Cloud Map DNS.

## Secrets policy for this project

Per the current DEV requirement:

- AWS Secrets Manager **secret metadata is provisioned**.
- Secret values are **not written to Secrets Manager**.
- Values remain Terraform variables and are passed to ECS task definitions.
- Mark sensitive Terraform variables as sensitive.
- Do not commit a real `terraform.tfvars` containing credentials.

This is intentional for the current DEV setup and should be changed before production.

## DEV Kafka and MongoDB

The DEV deployment does not use Amazon MSK or Amazon DocumentDB. Those managed services are intentionally removed because the current AWS account/plan rejected MSK subscription access and imposed a DocumentDB backup-retention restriction.

Instead, Kafka and MongoDB run as single-node ECS/Fargate services using public Docker images:

- Kafka: `apache/kafka:3.7.2`, Cloud Map DNS `kafka.<environment>.ecommerce.local:9092`
- MongoDB: `mongo:7.0`, Cloud Map DNS `mongo.<environment>.ecommerce.local:27017`

This is a DEV/test arrangement. The Kafka and MongoDB tasks use ephemeral ECS storage, so their data is not durable across task replacement. For production, use a durable Kafka deployment and a managed/persistent MongoDB-compatible service.

## First deployment

```bash
cd envs/dev

cp terraform.local.tfvars.example terraform.tfvars
# Put your DEV-only Terraform values in terraform.tfvars.

terraform init
terraform fmt -recursive
terraform validate
terraform plan -var-file=terraform.tfvars
```

For the first pass, keep `deploy_services = false` so the AWS infrastructure, RDS, Redis, Cloud Map, ALB and ECR repositories are created first.

Then push the application images with the existing script. The Kafka and MongoDB ECS services are created together with the application services when `deploy_services = true`:

```bash
./build-and-push.sh latest
```

Finally set `deploy_services = true` and apply again:

```bash
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

Use immutable image tags for repeatable deployments.

## Outputs

```bash
terraform output alb_dns_name
terraform output ecr_repository_urls
terraform output service_discovery_namespace
terraform output grafana_url
terraform output prometheus_url
terraform output kafka_bootstrap_brokers
terraform output mongo_endpoint
```

## Destroy

```bash
terraform destroy -var-file=terraform.tfvars
```
