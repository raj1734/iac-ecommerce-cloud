variable "project_name" { type = string }
variable "environment" { type = string }
variable "subnet_ids" { type = list(string) }
variable "security_group_ids" { type = list(string) }
variable "broker_count" { type = number }
variable "instance_type" { type = string }
variable "kms_key_arn" { type = string }
