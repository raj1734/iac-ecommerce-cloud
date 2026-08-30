output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "app_subnet_ids" {
  value = module.vpc.app_subnet_ids
}

output "data_subnet_ids" {
  value = module.vpc.data_subnet_ids
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}

output "rds_endpoints" {
  value     = module.rds.endpoints
  sensitive = true
}

output "documentdb_endpoint" {
  value     = module.documentdb.cluster_endpoint
  sensitive = true
}

output "redis_endpoint" {
  value     = module.redis.primary_endpoint
  sensitive = true
}

output "service_discovery_namespace" {
  value = module.service_discovery.namespace_name
}

output "msk_bootstrap_brokers" {
  value = var.enable_msk && var.az_count == 2 ? module.msk[0].bootstrap_brokers : null
  sensitive = true
}
