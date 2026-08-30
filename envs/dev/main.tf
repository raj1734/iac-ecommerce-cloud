provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

locals {
  services = toset([
    "gateway-service",
    "config-server",
    "auth-service",
    "user-service",
    "catalog-service",
    "inventory-service",
    "order-service",
    "payment-service",
    "notification-service",
    "web-storefront",
    "zipkin"
  ])

  db_services = {
    auth      = "auth-db"
    user      = "user-db"
    inventory = "inventory-db"
    order     = "order-db"
  }

  # In 2-AZ mode the requested production topology is enabled.
  effective_msk = var.az_count == 2 && var.enable_msk
  effective_waf = var.az_count == 2 && var.enable_waf

  service_image_map = merge(
    { for service in local.services : service => "${module.ecr.repository_urls[service]}:${var.app_image_tag}" if service != "zipkin" },
    var.service_images
  )
}

module "vpc" {
  source = "../../modules/vpc"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
  az_count     = var.az_count
}

module "kms" {
  source = "../../modules/kms"

  project_name = var.project_name
  environment  = var.environment
}

module "security_groups" {
  source = "../../modules/security-groups"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
}

module "ecr" {
  source = "../../modules/ecr"

  project_name = var.project_name
  environment  = var.environment
  services     = local.services
}

module "secrets" {
  source = "../../modules/secrets"

  project_name        = var.project_name
  environment         = var.environment
  kms_key_arn         = module.kms.secrets_key_arn
  db_master_username  = var.db_master_username
  db_master_password  = var.db_master_password
}

module "rds" {
  source = "../../modules/rds"

  project_name             = var.project_name
  environment              = var.environment
  subnet_ids               = module.vpc.data_subnet_ids
  security_group_ids       = [module.security_groups.database_sg_id]
  instance_class           = var.rds_instance_class
  multi_az                 = var.az_count == 2 && var.rds_multi_az
  kms_key_arn              = module.kms.database_key_arn
  master_username          = var.db_master_username
  master_password          = var.db_master_password
  database_names            = ["auth_db", "user_db", "inventory_db", "order_db"]
}

module "documentdb" {
  source = "../../modules/documentdb"

  project_name       = var.project_name
  environment        = var.environment
  subnet_ids         = module.vpc.data_subnet_ids
  security_group_ids = [module.security_groups.database_sg_id]
  instance_class     = var.documentdb_instance_class
  instance_count     = var.documentdb_instance_count
  kms_key_arn        = module.kms.database_key_arn
  master_username    = var.db_master_username
  master_password    = var.db_master_password
}

module "redis" {
  source = "../../modules/redis"

  project_name       = var.project_name
  environment        = var.environment
  subnet_ids         = module.vpc.data_subnet_ids
  security_group_ids = [module.security_groups.redis_sg_id]
  node_type          = var.redis_node_type
  replica_count      = var.redis_replica_count
  kms_key_arn        = module.kms.database_key_arn
}

module "msk" {
  count = local.effective_msk ? 1 : 0

  source = "../../modules/msk"

  project_name       = var.project_name
  environment        = var.environment
  subnet_ids         = module.vpc.app_subnet_ids
  security_group_ids = [module.security_groups.msk_sg_id]
  broker_count       = var.msk_broker_count
  instance_type      = var.msk_instance_type
  kms_key_arn        = module.kms.msk_key_arn
}

module "logs" {
  source = "../../modules/logs"

  project_name = var.project_name
  environment  = var.environment
  services     = local.services
}

module "ecs" {
  count = var.deploy_services ? 1 : 0

  source = "../../modules/ecs"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  app_subnet_ids        = module.vpc.app_subnet_ids
  security_group_ids    = [module.security_groups.ecs_sg_id]
  service_names         = local.services
  service_images        = local.service_image_map
  service_cpu           = var.service_cpu
  service_memory        = var.service_memory
  desired_count         = var.ecs_desired_count
  execution_role_arn    = module.ecs_iam[0].execution_role_arn
  task_role_arn         = module.ecs_iam[0].task_role_arn
  log_group_names       = module.logs.log_group_names
  service_discovery_ns  = module.service_discovery.namespace_id
  database_secret_arns  = module.secrets.database_secret_arns
  redis_secret_arn      = module.secrets.redis_secret_arn
  msk_bootstrap_brokers = local.effective_msk ? module.msk[0].bootstrap_brokers : ""
  database_hosts        = module.rds.endpoints
  documentdb_host       = module.documentdb.cluster_endpoint
  redis_host             = module.redis.primary_endpoint
  db_username            = var.db_master_username
  frontend_target_group_arn = module.alb.target_group_arn
}

module "ecs_iam" {
  count = var.deploy_services ? 1 : 0

  source = "../../modules/ecs-iam"

  project_name = var.project_name
  environment  = var.environment
  kms_key_arns = [
    module.kms.secrets_key_arn,
    module.kms.database_key_arn,
    module.kms.msk_key_arn
  ]
  secret_arns = concat(values(module.secrets.database_secret_arns), [module.secrets.redis_secret_arn])
}

module "service_discovery" {
  source = "../../modules/service-discovery"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
}

module "alb" {
  source = "../../modules/alb"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  security_group_ids = [module.security_groups.alb_sg_id]
  gateway_service    = "web-storefront"
  gateway_port       = 8090
  enabled            = true
}

module "waf" {
  count = local.effective_waf ? 1 : 0

  source = "../../modules/waf"

  project_name = var.project_name
  environment  = var.environment
  alb_arn      = module.alb.alb_arn
}

module "route53" {
  count = var.enable_route53 ? 1 : 0

  source = "../../modules/route53"

  zone_id     = var.route53_zone_id
  record_name = var.route53_record_name
  alb_dns     = module.alb.alb_dns_name
  alb_zone_id = module.alb.alb_zone_id
}
