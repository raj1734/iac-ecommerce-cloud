variable "project_name" { type = string }
variable "environment" { type = string }
variable "subnet_ids" { type = list(string) }
variable "security_group_ids" { type = list(string) }
variable "instance_class" { type = string }
variable "instance_count" { type = number }
variable "kms_key_arn" { type = string }
variable "master_username" {\n  type      = string\n  sensitive = true\n}
variable "master_password" {\n  type      = string\n  sensitive = true\n}
