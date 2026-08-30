locals {
  dbs = {
    auth      = "auth_db"
    user      = "user_db"
    inventory = "inventory_db"
    order     = "order_db"
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-${var.environment}-rds"
  subnet_ids = var.subnet_ids
}

resource "aws_db_instance" "this" {
  for_each = local.dbs

  identifier = "${var.project_name}-${var.environment}-${each.key}-db"

  engine         = "postgres"
  engine_version = "16"

  instance_class = var.instance_class

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = var.kms_key_arn

  db_name  = each.value
  username = var.master_username
  password = var.master_password
  port     = 5432

  multi_az = var.multi_az

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.security_group_ids

  backup_retention_period = var.multi_az ? 7 : 1
  deletion_protection     = var.multi_az
  skip_final_snapshot     = !var.multi_az

  publicly_accessible    = false
  auto_minor_version_upgrade = true

  performance_insights_enabled = true

  tags = {
    Service = each.key
  }
}
