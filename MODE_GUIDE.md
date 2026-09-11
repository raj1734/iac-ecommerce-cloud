# Terraform Modes

The project has one deployable Terraform root: `envs/dev`.

## 1. Local

Terraform does not create local infrastructure. Run the application using the existing Docker Compose/local setup.

## 2. Dev / AWS Integration

```bash
cd envs/dev
terraform init
terraform plan -var-file=terraform.dev.tfvars
terraform apply -var-file=terraform.dev.tfvars
```

The DEV configuration includes:

- 2-AZ VPC
- ECS Fargate application services
- Kafka and MongoDB as single-node ECS/Fargate Docker services
- Zipkin, Prometheus and Grafana when `deploy_services=true`
- RDS PostgreSQL
- ElastiCache Redis
- WAF when enabled
- optional Route 53
- KMS
- Secrets Manager metadata only
- CloudWatch Logs
- Cloud Map service discovery
- Application Load Balancer

## 3. Lower-cost single-AZ testing

```bash
cd envs/dev
terraform plan -var-file=terraform.single-az.tfvars
terraform apply -var-file=terraform.single-az.tfvars
```

## Production-oriented values

`terraform.prod.tfvars` is retained as the production-oriented parameter set. It is not a separate Terraform root.

```bash
cd envs/dev
terraform plan -var-file=terraform.prod.tfvars
terraform apply -var-file=terraform.prod.tfvars
```

## Secret handling

For the current requirement, secret values stay in Terraform variables. The `modules/secrets` module creates only AWS Secrets Manager secret metadata; it does not create secret versions or write values.
