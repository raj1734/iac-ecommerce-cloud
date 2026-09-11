# Updated DEV IaC Notes

## What changed

1. Removed Amazon DocumentDB from the DEV stack.
2. Removed Amazon MSK from the DEV stack.
3. Added single-node Kafka to `modules/ecs` using `apache/kafka:3.7.2`.
4. Added single-node MongoDB to `modules/ecs` using `mongo:7.0`.
5. Kafka and MongoDB are registered in the existing private Cloud Map namespace:
   - `kafka.<environment>.ecommerce.local:9092`
   - `mongo.<environment>.ecommerce.local:27017`
6. Catalog now uses MongoDB without DocumentDB TLS/replica-set settings.
7. Order/Inventory/Notification now use the private Kafka DNS endpoint.
8. Removed the deprecated Cloud Map `failure_threshold` configuration.
9. ECS CloudWatch logging now uses `data.aws_region.current.region`.
10. Removed the unused MSK security group and MSK KMS key.
11. Simplified the ECS task role to the permissions required by ECS Exec.
12. Removed generated Terraform plan output, IDE metadata, macOS ZIP metadata, and unused managed-service modules.

## Important DEV limitation

Kafka and MongoDB are single-node ECS/Fargate services with ephemeral task storage. They are suitable for DEV/testing only. Data can be lost when a task is replaced.

## Deployment

From `envs/dev`:

```bash
terraform init -upgrade
terraform fmt -recursive ../..
terraform validate
terraform plan -var-file=terraform.tfvars
```

For the first infrastructure-only pass, keep:

```hcl
deploy_services = false
```

After the base infrastructure is ready, build/push the application images, then set:

```hcl
deploy_services = true
```

and run:

```bash
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

When `deploy_services=true`, ECS creates the application services plus Kafka, MongoDB, Zipkin, Prometheus and Grafana.

## Existing Terraform state warning

If Terraform state already contains the previously attempted DocumentDB/MSK resources, the next plan may show those resources for removal because they are no longer present in configuration. Review the plan before applying.
