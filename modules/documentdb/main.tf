resource "aws_docdb_subnet_group" "this" {
  name       = "${var.project_name}-${var.environment}-docdb"
  subnet_ids = var.subnet_ids
}

resource "aws_docdb_cluster" "this" {
  cluster_identifier = "${var.project_name}-${var.environment}-catalog"

  engine         = "docdb"
  master_username = var.master_username
  master_password = var.master_password

  db_subnet_group_name   = aws_docdb_subnet_group.this.name
  vpc_security_group_ids = var.security_group_ids

  storage_encrypted = true
  kms_key_id        = var.kms_key_arn

  backup_retention_period = 7
  preferred_backup_window = "18:00-19:00"
  skip_final_snapshot     = false

  deletion_protection = var.instance_count > 1
}

resource "aws_docdb_cluster_instance" "this" {
  count = var.instance_count

  identifier         = "${var.project_name}-${var.environment}-catalog-${count.index + 1}"
  cluster_identifier  = aws_docdb_cluster.this.id
  instance_class      = var.instance_class
  engine              = "docdb"

  auto_minor_version_upgrade = true
}
