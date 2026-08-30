variable "project_name" { type = string }
variable "environment" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "security_group_ids" { type = list(string) }
variable "gateway_service" { type = string }
variable "gateway_port" { type = number }
variable "enabled" { type = bool }
