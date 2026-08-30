# AWS Demo / Dev mode
aws_region          = "ap-south-1"
environment         = "dev"
az_count            = 2

deploy_services     = false

enable_msk         = true
enable_waf         = true
enable_route53     = false

ecs_desired_count  = 1

rds_multi_az       = false
rds_instance_class = "db.t4g.micro"

documentdb_instance_class = "db.t4g.medium"
documentdb_instance_count = 1

redis_node_type     = "cache.t4g.small"
redis_replica_count = 0

msk_instance_type  = "kafka.t3.small"
msk_broker_count   = 3

# Supply securely through a tfvars file that is NOT committed,
# environment variable TF_VAR_db_master_password, or a secret workflow.
# db_master_password = "REPLACE_ME"
