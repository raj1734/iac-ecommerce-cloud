variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "project_name" {
  type    = string
  default = "ecommerce-platform"
}

variable "az_count" {
  type        = number
  description = "1 or 2 application AZs."
  default     = 2

  validation {
    condition     = contains([1, 2], var.az_count)
    error_message = "az_count must be 1 or 2."
  }
}

variable "deploy_services" {
  type    = bool
  default = false
}

variable "enable_msk" {
  type    = bool
  default = false
}

variable "enable_waf" {
  type    = bool
  default = true
}

variable "enable_route53" {
  type    = bool
  default = false
}

variable "route53_zone_id" {
  type    = string
  default = null
}

variable "route53_record_name" {
  type    = string
  default = null
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "app_image_tag" {
  type    = string
  default = "latest"
}

variable "service_cpu" {
  type    = number
  default = 512
}

variable "service_memory" {
  type    = number
  default = 1024
}

variable "ecs_desired_count" {
  type    = number
  default = 1
}

variable "rds_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "rds_multi_az" {
  type    = bool
  default = false
}

variable "documentdb_instance_class" {
  type    = string
  default = "db.t4g.medium"
}

variable "documentdb_instance_count" {
  type    = number
  default = 1
}

variable "redis_node_type" {
  type    = string
  default = "cache.t4g.small"
}

variable "redis_replica_count" {
  type    = number
  default = 0
}

variable "msk_instance_type" {
  type    = string
  default = "kafka.t3.small"
}

variable "msk_broker_count" {
  type    = number
  default = 3
}

variable "db_master_username" {
  type      = string
  default   = "ecommerceadmin"
  sensitive = true
}

variable "db_master_password" {
  type      = string
  sensitive = true

  validation {
    condition     = length(var.db_master_password) >= 16
    error_message = "db_master_password must be at least 16 characters."
  }
}

variable "service_images" {
  type        = map(string)
  default     = {}
  description = "Map of ECS service name to ECR/image URI. Required when deploy_services=true."
}
