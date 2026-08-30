locals {
  db_names = ["auth", "user", "inventory", "order"]
}

resource "aws_secretsmanager_secret" "db" {
  for_each = toset(local.db_names)

  name       = "${var.project_name}/${var.environment}/database/${each.key}"
  kms_key_id = var.kms_key_arn
}

resource "aws_secretsmanager_secret_version" "db" {
  for_each = toset(local.db_names)

  secret_id = aws_secretsmanager_secret.db[each.key].id

  secret_string = jsonencode({
    username = var.db_master_username
    password = var.db_master_password
    database = "${each.key}_db"
  })
}

resource "aws_secretsmanager_secret" "redis" {
  name       = "${var.project_name}/${var.environment}/redis"
  kms_key_id = var.kms_key_arn
}

resource "aws_secretsmanager_secret_version" "redis" {
  secret_id = aws_secretsmanager_secret.redis.id

  secret_string = jsonencode({
    auth_token = random_password.redis.result
  })
}

resource "random_password" "redis" {
  length  = 32
  special = true
}
