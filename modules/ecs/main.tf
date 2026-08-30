resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_service_discovery_service" "service" {
  for_each = var.service_names

  name = each.key

  dns_config {
    namespace_id = var.service_discovery_ns

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_ecs_task_definition" "service" {
  for_each = var.service_names

  family                   = "${var.project_name}-${var.environment}-${each.key}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.service_cpu
  memory                   = var.service_memory

  execution_role_arn = var.execution_role_arn
  task_role_arn      = var.task_role_arn

  container_definitions = jsonencode([{
    name      = each.key
    image     = each.key == "zipkin" ? "openzipkin/zipkin:3" : lookup(var.service_images, each.key, "public.ecr.aws/docker/library/eclipse-temurin:17-jre")
    essential = true

    portMappings = [{
      containerPort = local.ports[each.key]
      hostPort      = local.ports[each.key]
      protocol      = "tcp"
    }]

    environment = concat(
      [
        { name = "SPRING_PROFILES_ACTIVE", value = each.key == "config-server" ? "native" : var.environment },
        { name = "CONFIG_SERVER_HOST", value = "config-server.${var.environment}.ecommerce.local" },
        { name = "TRACING_ENDPOINT", value = "http://zipkin.${var.environment}.ecommerce.local:9411/api/v2/spans" },
        { name = "EUREKA_CLIENT_ENABLED", value = "false" }
      ],
      each.key == "web-storefront" ? [
        { name = "GATEWAY_URL", value = "http://gateway-service.${var.environment}.ecommerce.local:8080" }
      ] : [],
      each.key == "gateway-service" ? [
        { name = "AUTH_SERVICE_URL", value = "http://auth-service.${var.environment}.ecommerce.local:8081" },
        { name = "USER_SERVICE_URL", value = "http://user-service.${var.environment}.ecommerce.local:8087" },
        { name = "CATALOG_SERVICE_URL", value = "http://catalog-service.${var.environment}.ecommerce.local:8082" },
        { name = "INVENTORY_SERVICE_URL", value = "http://inventory-service.${var.environment}.ecommerce.local:8086" },
        { name = "ORDER_SERVICE_URL", value = "http://order-service.${var.environment}.ecommerce.local:8083" },
        { name = "PAYMENT_SERVICE_URL", value = "http://payment-service.${var.environment}.ecommerce.local:8088" },
        { name = "NOTIFICATION_SERVICE_URL", value = "http://notification-service.${var.environment}.ecommerce.local:8084" },
        { name = "SPRING_REDIS_HOST", value = var.redis_host },
        { name = "SPRING_REDIS_PORT", value = "6379" }
      ] : [],
      each.key == "order-service" ? [
        { name = "CATALOG_SERVICE_URL", value = "http://catalog-service.${var.environment}.ecommerce.local:8082" },
        { name = "INVENTORY_SERVICE_URL", value = "http://inventory-service.${var.environment}.ecommerce.local:8086" },
        { name = "PAYMENT_SERVICE_URL", value = "http://payment-service.${var.environment}.ecommerce.local:8088" },
        { name = "USER_SERVICE_URL", value = "http://user-service.${var.environment}.ecommerce.local:8087" }
      ] : [],
      contains(["auth-service", "user-service", "inventory-service", "order-service"], each.key) ? [
        { name = "DB_HOST", value = var.database_hosts[replace(each.key, "-service", "")] },
        { name = "DB_USERNAME", value = var.db_username }
      ] : [],
      contains(["order-service", "inventory-service", "payment-service", "notification-service"], each.key) ? [
        { name = "KAFKA_BROKERS", value = var.msk_bootstrap_brokers }
      ] : [],
      each.key == "catalog-service" ? [
        { name = "MONGO_HOST", value = var.documentdb_host },
        { name = "MONGO_USERNAME", value = var.db_username },
        { name = "REDIS_HOST", value = var.redis_host }
      ] : []
    )

    secrets = concat(
      contains(["auth-service", "user-service", "inventory-service", "order-service"], each.key) ? [
        { name = "DB_PASSWORD", valueFrom = "${var.database_secret_arns[replace(each.key, "-service", "")]}:password::" }
      ] : [],
      contains(["gateway-service", "catalog-service"], each.key) ? [
        { name = "REDIS_PASSWORD", valueFrom = "${var.redis_secret_arn}:auth_token::" }
      ] : []
    )

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = var.log_group_names[each.key]
        awslogs-region        = data.aws_region.current.name
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

locals {
  ports = {
    gateway-service      = 8080
    config-server        = 8889
    auth-service         = 8081
    user-service         = 8087
    catalog-service      = 8082
    inventory-service    = 8086
    order-service        = 8083
    payment-service      = 8088
    notification-service = 8084
    web-storefront       = 8090
    zipkin                = 9411
  }
}

data "aws_region" "current" {}

resource "aws_ecs_service" "service" {
  for_each = var.service_names

  name            = each.key
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.service[each.key].arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  network_configuration {
    subnets          = var.app_subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.service[each.key].arn
  }

  enable_execute_command = true

  dynamic "load_balancer" {
    for_each = each.key == "web-storefront" ? [1] : []
    content {
      target_group_arn = var.frontend_target_group_arn
      container_name   = each.key
      container_port   = local.ports[each.key]
    }
  }
}
