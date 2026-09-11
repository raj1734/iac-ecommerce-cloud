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
  value = try(module.alb[0].alb_dns_name, null)
}

output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}

output "rds_endpoints" {
  value     = module.rds.endpoints
  sensitive = true
}

output "mongo_endpoint" {
  value = "mongo.${var.environment}.ecommerce.local:27017"
}

output "redis_endpoint" {
  value     = try(module.redis[0].primary_endpoint, null)
  sensitive = true
}

output "service_discovery_namespace" {
  value = module.service_discovery.namespace_name
}

output "kafka_bootstrap_brokers" {
  value = "kafka.${var.environment}.ecommerce.local:9092"
}

output "prometheus_url" {
  value = try("http://${module.alb[0].alb_dns_name}/prometheus/", null)
}

output "grafana_url" {
  value = try("http://${module.alb[0].alb_dns_name}/grafana/", null)
}