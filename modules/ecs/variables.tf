variable "project_name" { type = string }
variable "environment" { type = string }
variable "vpc_id" { type = string }
variable "app_subnet_ids" { type = list(string) }
variable "security_group_ids" { type = list(string) }
variable "service_names" { type = set(string) }
variable "service_images" { type = map(string) }
variable "service_cpu" { type = number }
variable "service_memory" { type = number }
variable "desired_count" { type = number }
variable "execution_role_arn" { type = string }
variable "task_role_arn" { type = string }
variable "log_group_names" { type = map(string) }
variable "service_discovery_ns" { type = string }
variable "database_secret_arns" { type = map(string) }
variable "redis_secret_arn" { type = string }
variable "msk_bootstrap_brokers" { type = string }

variable "database_hosts" { type = map(string) }
variable "documentdb_host" { type = string }
variable "redis_host" { type = string }
variable "frontend_target_group_arn" { type = string }

variable "db_username" { type = string }
