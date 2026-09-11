locals {
  db_names = ["auth", "user", "inventory", "order"]
}

# Secret metadata is provisioned here, but NO secret values are written to
# AWS Secrets Manager. Secret values remain managed by Terraform variables.
resource "aws_secretsmanager_secret" "db" {
  for_each = toset(local.db_names)

  name       = "${var.project_name}/${var.environment}/database/${each.key}"
  kms_key_id = var.kms_key_arn
}

resource "aws_secretsmanager_secret" "redis" {
  name       = "${var.project_name}/${var.environment}/redis"
  kms_key_id = var.kms_key_arn
}

resource "aws_secretsmanager_secret" "jwt" {
  name       = "${var.project_name}/${var.environment}/jwt"
  kms_key_id = var.kms_key_arn
}

resource "aws_secretsmanager_secret" "config" {
  name       = "${var.project_name}/${var.environment}/config"
  kms_key_id = var.kms_key_arn
}

resource "aws_secretsmanager_secret" "bootstrap_admin" {
  name       = "${var.project_name}/${var.environment}/bootstrap-admin"
  kms_key_id = var.kms_key_arn
}
