# AWS Demo / Dev mode
aws_region  = "ap-south-1"
environment = "dev"
az_count    = 2

deploy_services = true
app_image_tag   = "dev-amd64-008"

service_image_tags = {
  user-service         = "dev-amd64-009"
  inventory-service    = "dev-amd64-009"
  order-service        = "dev-amd64-009"
  payment-service      = "dev-amd64-009"
  notification-service = "dev-amd64-009"
}

ecs_desired_count = 1

rds_multi_az        = false
rds_instance_class  = "db.t4g.micro"
redis_node_type     = "cache.t4g.small"
redis_replica_count = 0
# Terraform-only secret values for this DEV environment.
# Keep this file out of version control if you put real values here.
db_master_password       = "REPLACE_WITH_STRONG_DB_PASSWORD"
redis_password           = "REPLACE_WITH_STRONG_REDIS_PASSWORD"
jwt_secret               = "REPLACE_WITH_AT_LEAST_32_CHARACTER_JWT_SECRET"
config_password          = "REPLACE_WITH_CONFIG_PASSWORD"
bootstrap_admin_password = "REPLACE_WITH_ADMIN_PASSWORD"


# Minimal ECS service test mode.
# Only Config Server and Auth Service are started.
enabled_services  = ["config-server", "auth-service", "user-service", "catalog-service", "inventory-service", "order-service", "payment-service", "notification-service", "gateway-service", "web-storefront"]
enabled_databases = ["auth_db", "user_db", "order_db", "inventory_db"]

# Auth + Config Server do not require these platform components.
enable_redis         = true
enable_kafka         = false
enable_mongo         = true
enable_observability = false
enable_alb           = true

# No public DNS/WAF in minimal test mode.
enable_waf     = false
enable_route53 = false
enable_secrets = false


# Keep ElastiCache provisioned, but use passwordless ECS Redis for applications.
enable_redis_container = true

# Optional: change only the service listed here.
# service_image_tags = { catalog-service = "dev-amd64-003" }
