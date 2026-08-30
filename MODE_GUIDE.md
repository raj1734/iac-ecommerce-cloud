# Three Terraform Modes

## 1. Local

Terraform does not create local infrastructure.

Use the existing project:

```text
docker-compose.yml
Spring Boot services
local MongoDB/PostgreSQL/Redis/Kafka as appropriate
```

For AWS Terraform, this mode means **do not run Terraform**.

## 2. Dev / AWS Integration

Use:

```bash
terraform init
terraform plan -var-file=terraform.dev.tfvars
terraform apply -var-file=terraform.dev.tfvars
```

Characteristics:

- 2-AZ VPC
- 1 ECS task per service when enabled
- RDS Single-AZ
- one DocumentDB instance
- Redis without replica
- MSK disabled by default
- WAF enabled
- Route 53 disabled by default
- designed to control cost

To test Kafka:

```hcl
enable_msk = true
```

Then apply again.

## 3. Prod / production-oriented

Use:

```bash
terraform plan -var-file=terraform.prod.tfvars
terraform apply -var-file=terraform.prod.tfvars
```

Characteristics:

- 2 AZ
- 2 ECS tasks per service
- RDS Multi-AZ
- four separate PostgreSQL databases/instances
- two DocumentDB instances
- Redis replica + automatic failover
- three MSK brokers
- WAF
- Route 53
- KMS
- Secrets Manager
- CloudWatch
- ECS Container Insights
- Cloud Map service discovery

## 1-AZ option

The repository also includes:

```bash
terraform plan -var-file=terraform.single-az.tfvars
terraform apply -var-file=terraform.single-az.tfvars
```

This is intended for low-cost AWS testing.

It disables MSK and HA features.

## Recommended workflow

Use:

```text
Local
  |
  | application development
  v
Dev AWS
  |
  | integration / networking / managed services
  v
Prod-like AWS
  |
  | final architecture demonstration
  v
HLD review
```
