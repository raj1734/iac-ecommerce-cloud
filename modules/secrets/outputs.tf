output "database_secret_arns" {
  value = { for k, v in aws_secretsmanager_secret.db : k => v.arn }
}

output "redis_secret_arn" {
  value = aws_secretsmanager_secret.redis.arn
}

output "jwt_secret_arn" {
  value = aws_secretsmanager_secret.jwt.arn
}

output "config_secret_arn" {
  value = aws_secretsmanager_secret.config.arn
}

output "bootstrap_admin_secret_arn" {
  value = aws_secretsmanager_secret.bootstrap_admin.arn
}
