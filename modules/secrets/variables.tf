variable "project_name" { type = string }
variable "environment" { type = string }
variable "kms_key_arn" { type = string }
variable "db_master_username" {\n  type      = string\n  sensitive = true\n}
variable "db_master_password" {\n  type      = string\n  sensitive = true\n}
