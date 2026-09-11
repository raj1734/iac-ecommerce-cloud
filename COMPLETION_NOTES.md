# Clean IaC Completion Notes

The project has been consolidated so that Terraform has one infrastructure owner per concern.

## Important cleanup

Removed legacy root Terraform implementations:

- root `ecs.tf`
- root `main.tf`
- root `observability.tf`
- root `observability-alb.tf`
- root root-level variables/outputs/versions files

The actual deployment root is:

```text
envs/dev/
```

## ECS ownership

`modules/ecs` is the only ECS implementation. It owns:

- ECS cluster
- application task definitions/services
- Kafka and MongoDB task definitions/services
- Cloud Map service registrations for application and platform services
- Zipkin task definition/service
- Prometheus task definition/service
- Grafana task definition/service
- Prometheus/Grafana ALB target groups and listener rules

## Public traffic

- `/` -> web storefront
- `/api/*` -> gateway
- `/prometheus/*` -> Prometheus
- `/grafana/*` -> Grafana

## Secrets

Secrets Manager resources are metadata-only. No `aws_secretsmanager_secret_version` resources are used. DEV secret values remain Terraform variables as requested.
