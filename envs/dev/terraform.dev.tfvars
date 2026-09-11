# AWS Demo / Dev mode
aws_region  = "ap-south-1"
environment = "dev"
az_count    = 2

deploy_services = true
app_image_tag   = "v1"

enable_waf     = true
enable_route53 = false

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

# Non-secret bootstrap/config values can remain here.
db_master_username       = "ecommerceadmin"
config_username          = "admin"
bootstrap_admin_username = "admin"
bootstrap_admin_email    = "admin@example.com"