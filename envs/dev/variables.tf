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




variable "enabled_services" {
  type        = list(string)
  description = "Application ECS services to run. Defaults to all application services."
  default = [
    "gateway-service",
    "config-server",
    "auth-service",
    "user-service",
    "catalog-service",
    "inventory-service",
    "order-service",
    "payment-service",
    "notification-service",
    "web-storefront"
  ]

  validation {
    condition = alltrue([
      for service in var.enabled_services :
      contains([
        "gateway-service",
        "config-server",
        "auth-service",
        "user-service",
        "catalog-service",
        "inventory-service",
        "order-service",
        "payment-service",
        "notification-service",
        "web-storefront"
      ], service)
    ])
    error_message = "enabled_services contains an unsupported application service."
  }
}

variable "enabled_databases" {
  type        = list(string)
  description = "RDS databases to create. Defaults to all application databases."
  default     = ["auth_db", "user_db", "inventory_db", "order_db"]

  validation {
    condition = alltrue([
      for db in var.enabled_databases :
      contains(["auth_db", "user_db", "inventory_db", "order_db"], db)
    ])
    error_message = "enabled_databases contains an unsupported database."
  }
}

variable "enable_redis_container" {
  type        = bool
  description = "Create a passwordless DEV Redis ECS container. ElastiCache remains independently provisioned when enable_redis=true."
  default     = true
}

variable "enable_redis" {
  type        = bool
  description = "Create ElastiCache Redis."
  default     = true
}

variable "enable_kafka" {
  type        = bool
  description = "Create the DEV single-node Kafka ECS service."
  default     = true
}

variable "enable_mongo" {
  type        = bool
  description = "Create the DEV single-node MongoDB ECS service."
  default     = true
}

variable "enable_observability" {
  type        = bool
  description = "Create Zipkin, Prometheus and Grafana ECS services."
  default     = true
}

variable "enable_alb" {
  type        = bool
  description = "Create the public Application Load Balancer."
  default     = true
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



variable "redis_node_type" {
  type    = string
  default = "cache.t4g.small"
}

variable "redis_replica_count" {
  type    = number
  default = 0
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

variable "service_image_tags" {
  type        = map(string)
  default     = {}
  description = "Optional per-service image tags. Overrides app_image_tag only for listed services."
}

variable "service_images" {
  type        = map(string)
  default     = {}
  description = "Map of ECS service name to ECR/image URI. Required when deploy_services=true."
}

variable "redis_password" {
  type      = string
  sensitive = true

  validation {
    condition     = length(var.redis_password) >= 16
    error_message = "redis_password must be at least 16 characters."
  }
}

variable "jwt_secret" {
  type      = string
  sensitive = true

  validation {
    condition     = length(var.jwt_secret) >= 32
    error_message = "jwt_secret must be at least 32 characters."
  }
}

variable "config_username" {
  type      = string
  default   = "admin"
  sensitive = true
}

variable "config_password" {
  type      = string
  sensitive = true

  validation {
    condition     = length(var.config_password) >= 8
    error_message = "config_password must be at least 8 characters."
  }
}

variable "bootstrap_admin_username" {
  type    = string
  default = "admin"
}

variable "bootstrap_admin_email" {
  type    = string
  default = "admin@example.com"
}

variable "bootstrap_admin_password" {
  type      = string
  sensitive = true

  validation {
    condition     = length(var.bootstrap_admin_password) >= 8
    error_message = "bootstrap_admin_password must be at least 8 characters."
  }
}


variable "enable_secrets" {
  type        = bool
  description = "Create Secrets Manager metadata."
  default     = true
}
