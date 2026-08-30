resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.project_name}-${var.environment}-redis"
  subnet_ids = var.subnet_ids
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = "${var.project_name}-${var.environment}"

  description = "Redis cache for e-commerce platform"

  engine         = "redis"
  node_type      = var.node_type
  port           = 6379
  parameter_group_name = "default.redis7"

  num_cache_clusters = var.replica_count + 1

  automatic_failover_enabled = var.replica_count > 0
  multi_az_enabled            = var.replica_count > 0

  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = var.security_group_ids

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  kms_key_id                  = var.kms_key_arn

  auth_token = random_password.auth.result

  snapshot_retention_limit = var.replica_count > 0 ? 7 : 1
}

resource "random_password" "auth" {
  length  = 32
  special = true
}
