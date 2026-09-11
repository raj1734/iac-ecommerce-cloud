# Terraform Architecture

```text
                         Route 53 (optional)
                                |
                                v
                               WAF
                                |
                                v
                               ALB
                    +-----------+-----------+
                    |           |           |
                  /api/*     /grafana/  /prometheus/
                    |           |           |
                 Gateway      Grafana    Prometheus
                    |
             ECS Fargate cluster
                    |
      +-------------+--------------------+
      |             |                    |
   Config       Business services    Web Storefront
                    |                    ^
        +-----------+-----------+        |
        |           |           |        |
      Auth        User       Catalog -----+
        |           |           |
       RDS         RDS       ECS MongoDB
        |                       |
   Inventory/Order              Redis
        |
       RDS
        |
       ECS Kafka

Observability inside the same ECS cluster:
- Zipkin (private Cloud Map DNS)
- Prometheus
- Grafana
```

## Single-owner rule

There is one Terraform implementation for each concern. The `envs/dev` root composes reusable modules. The `modules/ecs` module is the only owner of ECS resources and also owns the observability ECS services.

## Application communication

- Browser -> Web Storefront
- Web Storefront -> Gateway over Cloud Map
- Gateway -> Auth/User/Catalog/Inventory/Order/Payment/Notification
- Order -> Catalog/Inventory/Payment/User
- Order/Inventory/Notification -> Kafka over private Cloud Map DNS
- Application services -> Zipkin for tracing
- Prometheus -> `/actuator/prometheus` on application services
- Grafana -> Prometheus

## Data ownership

- Auth -> PostgreSQL `auth_db`
- User -> PostgreSQL `user_db`
- Inventory -> PostgreSQL `inventory_db`
- Order -> PostgreSQL `order_db`
- Catalog -> Amazon ECS MongoDB `catalog_db`
- Gateway/Catalog -> Redis

## Secrets

Secrets Manager secret metadata is provisioned, but no secret values are written to Secrets Manager. Current DEV credentials remain Terraform variables and are passed to ECS task definitions.
