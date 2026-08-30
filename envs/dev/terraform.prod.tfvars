# Production-oriented 2-AZ mode
aws_region          = "ap-south-1"
environment         = "prod"
az_count            = 2

deploy_services     = true

enable_msk          = true
enable_waf          = true
enable_route53      = true

ecs_desired_count  = 2

rds_multi_az       = true
rds_instance_class = "db.t4g.small"

documentdb_instance_class = "db.t4g.medium"
documentdb_instance_count = 2

redis_node_type     = "cache.t4g.small"
redis_replica_count = 1

msk_instance_type  = "kafka.t3.small"
msk_broker_count   = 3

# Configure these before apply:
# route53_zone_id     = "ZXXXXXXXXXXXXX"
# route53_record_name = "shop.example.com"
#
# db_master_password = "REPLACE_ME"
#
# service_images = {
#   gateway-service     = "123456789012.dkr.ecr.ap-south-1.amazonaws.com/ecommerce-platform-gateway-service:latest"
#   config-server       = "123456789012.dkr.ecr.ap-south-1.amazonaws.com/ecommerce-platform-config-server:latest"
#   auth-service        = "123456789012.dkr.ecr.ap-south-1.amazonaws.com/ecommerce-platform-auth-service:latest"
#   user-service        = "123456789012.dkr.ecr.ap-south-1.amazonaws.com/ecommerce-platform-user-service:latest"
#   catalog-service     = "123456789012.dkr.ecr.ap-south-1.amazonaws.com/ecommerce-platform-catalog-service:latest"
#   inventory-service   = "123456789012.dkr.ecr.ap-south-1.amazonaws.com/ecommerce-platform-inventory-service:latest"
#   order-service       = "123456789012.dkr.ecr.ap-south-1.amazonaws.com/ecommerce-platform-order-service:latest"
#   payment-service     = "123456789012.dkr.ecr.ap-south-1.amazonaws.com/ecommerce-platform-payment-service:latest"
#   notification-service= "123456789012.dkr.ecr.ap-south-1.amazonaws.com/ecommerce-platform-notification-service:latest"
# }
