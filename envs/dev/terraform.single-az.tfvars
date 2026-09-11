# Single-AZ AWS mode.
# Useful for low-cost infrastructure testing.
aws_region  = "ap-south-1"
environment = "single-az"
az_count    = 1

deploy_services = false

enable_waf     = false
enable_route53 = false

ecs_desired_count = 1

rds_multi_az        = false
rds_instance_class  = "db.t4g.micro"
redis_node_type     = "cache.t4g.small"
redis_replica_count = 0
