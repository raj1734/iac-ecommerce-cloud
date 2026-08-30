# E-Commerce Platform — Terraform Infrastructure

Production-oriented Terraform for the finalized e-commerce HLD.

## Three Terraform modes

This repository supports three deployment modes through separate tfvars files:

1. `local` — no AWS infrastructure. Use this for local development.
2. `dev` — 2-AZ AWS topology with cost-optimized managed services.
3. `prod` — 2-AZ production-like AWS topology with HA-oriented settings.

The Terraform code is shared. Only the mode-specific values change.

## Important

`az_count` controls the application topology:

- `1`: single-AZ development topology.
- `2`: two-AZ topology.

The three project modes are intentionally:

| Mode | AWS | AZ | HA | Intended use |
|---|---|---:|---|---|
| local | No | 0 | No | Local Spring Boot development |
| dev | Yes | 2 | Cost optimized | AWS integration/demo |
| prod | Yes | 2 | Production-like | Architecture demonstration |

`local` is represented by a mode file but does not provision AWS resources. Use the AWS modes for Terraform.

## AWS components

The Terraform structure is designed for:

- Route 53
- VPC, public/private application/data subnets
- Internet Gateway / NAT
- ALB + WAF in 2-AZ mode
- ECS Fargate
- Cloud Map service discovery
- ECR
- RDS PostgreSQL databases
- DocumentDB for Catalog
- ElastiCache Redis
- Amazon MSK
- KMS
- Secrets Manager
- CloudWatch Logs
- IAM/security groups

## Services

The finalized HLD services are treated as required:

- gateway-service
- config-server
- auth-service
- user-service
- catalog-service
- inventory-service
- order-service (Cart + Order)
- payment-service (stub)
- notification-service (stub)

Payment and Notification have no database.

## Deployment

Example:

```bash
cd envs/dev
terraform init
terraform plan -var-file=terraform.dev.tfvars
terraform apply -var-file=terraform.dev.tfvars
```

Production-like:

```bash
cd envs/dev
terraform plan -var-file=terraform.prod.tfvars
terraform apply -var-file=terraform.prod.tfvars
```

Do not commit real secrets or generated `.tfstate` files.

## Cost control

The dev mode deliberately keeps HA-heavy resources smaller:

- ECS desired count = 1
- RDS Multi-AZ = false
- DocumentDB instances = 1
- Redis replica count = 0
- MSK disabled by default

The production-like mode enables the corresponding HA-oriented settings.

For actual production, review AWS service-specific AZ requirements, quotas, backups, monitoring, security controls, and current regional pricing before deployment.
