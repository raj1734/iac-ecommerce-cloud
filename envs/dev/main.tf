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
  application_services = toset([
    "gateway-service",
    "config-server",
    "auth-service",
    "user-service",
    "catalog-service",
    "inventory-service",
    "order-service",
    "payment-service",
    "notification-service",
    "web-storefront"
  ])

  observability_services = toset([
    "zipkin",
    "prometheus",
    "grafana"
  ])

  selected_application_services = toset(var.enabled_services)

  services = setunion(
    local.selected_application_services,
    var.enable_observability ? local.observability_services : toset([]),
    var.enable_kafka ? toset(["kafka"]) : toset([]),
    var.enable_mongo ? toset(["mongo"]) : toset([]),
    var.enable_redis_container ? toset(["redis"]) : toset([])
  )
  log_services = local.services

  # WAF is enabled only in the 2-AZ production-oriented topology.
  effective_waf = var.az_count == 2 && var.enable_waf

  service_image_map = merge(
    { for service in local.selected_application_services : service => "${module.ecr.repository_urls[service]}:${lookup(var.service_image_tags, service, var.app_image_tag)}" },
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
  services     = local.selected_application_services
}

module "secrets" {
  count = var.enable_secrets ? 1 : 0

  source = "../../modules/secrets"

  project_name = var.project_name
  environment  = var.environment
  kms_key_arn  = module.kms.secrets_key_arn
}

module "rds" {
  source = "../../modules/rds"

  project_name       = var.project_name
  environment        = var.environment
  subnet_ids         = module.vpc.data_subnet_ids
  security_group_ids = [module.security_groups.database_sg_id]
  instance_class     = var.rds_instance_class
  multi_az           = var.az_count == 2 && var.rds_multi_az
  kms_key_arn        = module.kms.database_key_arn
  master_username    = var.db_master_username
  master_password    = var.db_master_password
  database_names     = var.enabled_databases
}

module "redis" {
  count = var.enable_redis ? 1 : 0

  source = "../../modules/redis"

  project_name       = var.project_name
  environment        = var.environment
  subnet_ids         = module.vpc.data_subnet_ids
  security_group_ids = [module.security_groups.redis_sg_id]
  node_type          = var.redis_node_type
  replica_count      = var.redis_replica_count
  kms_key_arn        = module.kms.database_key_arn
  auth_token         = var.redis_password
}

module "logs" {
  source = "../../modules/logs"

  project_name = var.project_name
  environment  = var.environment
  services     = local.log_services
}

module "ecs" {
  count = var.deploy_services ? 1 : 0

  source = "../../modules/ecs"

  project_name              = var.project_name
  environment               = var.environment
  vpc_id                    = module.vpc.vpc_id
  app_subnet_ids            = module.vpc.app_subnet_ids
  security_group_ids        = [module.security_groups.ecs_sg_id]
  service_names             = local.selected_application_services
  service_images            = local.service_image_map
  service_cpu               = var.service_cpu
  service_memory            = var.service_memory
  desired_count             = var.ecs_desired_count
  execution_role_arn        = module.ecs_iam[0].execution_role_arn
  task_role_arn             = module.ecs_iam[0].task_role_arn
  log_group_names           = module.logs.log_group_names
  service_discovery_ns      = module.service_discovery.namespace_id
  database_hosts            = module.rds.endpoints
  redis_host                = var.enable_redis_container ? "redis.${var.environment}.ecommerce.local" : (var.enable_redis ? module.redis[0].primary_endpoint : "")
  kafka_host                = "kafka.${var.environment}.ecommerce.local"
  mongo_host                = "mongo.${var.environment}.ecommerce.local"
  db_username               = var.db_master_username
  db_password               = var.db_master_password
  redis_password            = var.redis_password
  jwt_secret                = var.jwt_secret
  config_username           = var.config_username
  config_password           = var.config_password
  bootstrap_admin_username  = var.bootstrap_admin_username
  bootstrap_admin_email     = var.bootstrap_admin_email
  bootstrap_admin_password  = var.bootstrap_admin_password
  frontend_target_group_arn = var.enable_alb ? module.alb[0].storefront_target_group_arn : ""
  gateway_target_group_arn  = var.enable_alb ? module.alb[0].gateway_target_group_arn : ""
  alb_listener_arn          = var.enable_alb ? module.alb[0].listener_arn : ""
  enable_observability      = var.enable_observability
  enable_kafka              = var.enable_kafka
  enable_mongo              = var.enable_mongo
  enable_redis_container    = var.enable_redis_container
}

module "ecs_iam" {
  count = var.deploy_services ? 1 : 0

  source = "../../modules/ecs-iam"

  project_name = var.project_name
  environment  = var.environment
  kms_key_arns = [
    module.kms.secrets_key_arn,
    module.kms.database_key_arn
  ]
  secret_arns = []
}

module "service_discovery" {
  source = "../../modules/service-discovery"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
}

module "alb" {
  count = var.enable_alb ? 1 : 0

  source = "../../modules/alb"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  security_group_ids = [module.security_groups.alb_sg_id]
  gateway_port       = 8080
  storefront_port    = 8090
}

module "waf" {
  count = local.effective_waf && var.enable_alb ? 1 : 0

  source = "../../modules/waf"

  project_name = var.project_name
  environment  = var.environment
  alb_arn      = module.alb[0].alb_arn
}

module "route53" {
  count = var.enable_route53 && var.enable_alb ? 1 : 0

  source = "../../modules/route53"

  zone_id     = var.route53_zone_id
  record_name = var.route53_record_name
  alb_dns     = module.alb[0].alb_dns_name
  alb_zone_id = module.alb[0].alb_zone_id
}
