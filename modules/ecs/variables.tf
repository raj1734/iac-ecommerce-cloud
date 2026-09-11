variable "project_name" {
  type = string
}
variable "environment" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "app_subnet_ids" {
  type = list(string)
}
variable "security_group_ids" {
  type = list(string)
}
variable "service_names" {
  type = set(string)
}
variable "service_images" {
  type = map(string)
}
variable "service_cpu" {
  type = number
}
variable "service_memory" {
  type = number
}
variable "desired_count" {
  type = number
}
variable "execution_role_arn" {
  type = string
}
variable "task_role_arn" {
  type = string
}
variable "log_group_names" {
  type = map(string)
}
variable "service_discovery_ns" {
  type = string
}
variable "database_hosts" {
  type = map(string)
}
variable "redis_host" {
  type = string
}
variable "kafka_host" {
  type = string
}
variable "mongo_host" {
  type = string
}
variable "frontend_target_group_arn" {
  type = string
}
variable "gateway_target_group_arn" {
  type = string
}
variable "alb_listener_arn" {
  type = string
}
variable "enable_observability" {
  type = bool
}

variable "db_username" {
  type = string
}
variable "db_password" {
  type      = string
  sensitive = true
}
variable "jwt_secret" {
  type      = string
  sensitive = true
}
variable "config_username" {
  type      = string
  sensitive = true
}
variable "config_password" {
  type      = string
  sensitive = true
}
variable "bootstrap_admin_username" {
  type = string
}
variable "bootstrap_admin_email" {
  type = string
}
variable "bootstrap_admin_password" {
  type      = string
  sensitive = true
}
variable "redis_password" {
  type      = string
  sensitive = true
}


variable "enable_kafka" {
  type        = bool
  description = "Create the DEV single-node Kafka ECS service."
  default     = true
}

variable "enable_redis_container" {
  type    = bool
  default = true
}

variable "enable_mongo" {
  type        = bool
  description = "Create the DEV single-node MongoDB ECS service."
  default     = true
}
