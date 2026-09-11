resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

data "aws_region" "current" {}

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
  }

  namespace = "${var.environment}.ecommerce.local"

  common_environment = concat(
    [
      { name = "CONFIG_SERVER_HOST", value = "config-server.${local.namespace}" }
    ],
    var.enable_observability ? [
      { name = "TRACING_ENDPOINT", value = "http://zipkin.${local.namespace}:9411/api/v2/spans" },
      { name = "TRACING_SAMPLING_PROBABILITY", value = "1.0" }
    ] : []
  )
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
    image     = lookup(var.service_images, each.key, "public.ecr.aws/docker/library/eclipse-temurin:17-jre")
    essential = true

    portMappings = [{
      containerPort = local.ports[each.key]
      hostPort      = local.ports[each.key]
      protocol      = "tcp"
    }]

    environment = concat(
      local.common_environment,
      [{ name = "SPRING_PROFILES_ACTIVE", value = each.key == "config-server" ? "native" : var.environment }],
      each.key == "web-storefront" ? [
        { name = "GATEWAY_URL", value = "http://gateway-service.${local.namespace}:8080" }
      ] : [],
      each.key == "gateway-service" ? [
        { name = "JWT_SECRET", value = var.jwt_secret },
        { name = "AUTH_SERVICE_URL", value = "http://auth-service.${local.namespace}:8081" },
        { name = "USER_SERVICE_URL", value = "http://user-service.${local.namespace}:8087" },
        { name = "CATALOG_SERVICE_URL", value = "http://catalog-service.${local.namespace}:8082" },
        { name = "INVENTORY_SERVICE_URL", value = "http://inventory-service.${local.namespace}:8086" },
        { name = "ORDER_SERVICE_URL", value = "http://order-service.${local.namespace}:8083" },
        { name = "PAYMENT_SERVICE_URL", value = "http://payment-service.${local.namespace}:8088" },
        { name = "NOTIFICATION_SERVICE_URL", value = "http://notification-service.${local.namespace}:8084" },
        { name = "SPRING_REDIS_HOST", value = var.redis_host },
        { name = "SPRING_REDIS_PORT", value = "6379" },
        { name = "REDIS_PASSWORD", value = var.enable_redis_container ? "" : var.redis_password },
        { name = "SPRING_REDIS_SSL", value = "false" }
      ] : [],
      each.key == "order-service" ? [
        { name = "CATALOG_SERVICE_URL", value = "http://catalog-service.${local.namespace}:8082" },
        { name = "INVENTORY_SERVICE_URL", value = "http://inventory-service.${local.namespace}:8086" },
        { name = "PAYMENT_SERVICE_URL", value = "http://payment-service.${local.namespace}:8088" },
        { name = "USER_SERVICE_URL", value = "http://user-service.${local.namespace}:8087" }
      ] : [],
      contains(["auth-service", "user-service", "inventory-service", "order-service"], each.key) ? [
        { name = "SPRING_DATASOURCE_URL", value = "jdbc:postgresql://${var.database_hosts[replace(each.key, "-service", "")]}:5432/${replace(each.key, "-service", "")}_db" },
        { name = "DB_USERNAME", value = var.db_username },
        { name = "DB_PASSWORD", value = var.db_password }
      ] : [],
      contains(["order-service", "inventory-service", "notification-service"], each.key) ? [
        { name = "KAFKA_BROKERS", value = "${var.kafka_host}:9092" },
        { name = "SPRING_KAFKA_BOOTSTRAP_SERVERS", value = "${var.kafka_host}:9092" }
      ] : [],
      each.key == "catalog-service" ? [
        { name = "CATALOG_REPOSITORY_TYPE", value = "mongo" },
        { name = "CATALOG_CACHE_TYPE", value = "redis" },
        { name = "SPRING_DATA_MONGODB_URI", value = "mongodb://${var.db_username}:${var.db_password}@${var.mongo_host}:27017/catalog_db?authSource=admin" },
        { name = "SPRING_REDIS_HOST", value = var.redis_host },
        { name = "SPRING_REDIS_PORT", value = "6379" },
        { name = "REDIS_PASSWORD", value = var.enable_redis_container ? "" : var.redis_password },
        { name = "SPRING_REDIS_SSL", value = "false" }
      ] : [],
      each.key == "config-server" ? [
        { name = "CONFIG_REPO_PATH", value = "classpath:/config-repo" },
        { name = "CONFIG_USERNAME", value = var.config_username },
        { name = "CONFIG_PASSWORD", value = var.config_password }
      ] : [],
      each.key == "auth-service" ? [
        { name = "JWT_SECRET", value = var.jwt_secret },
        { name = "JWT_EXPIRATION", value = "86400000" },
        { name = "JWT_REFRESH_EXPIRATION", value = "604800000" },
        { name = "AUTH_BOOTSTRAP_ADMIN_ENABLED", value = "true" },
        { name = "AUTH_BOOTSTRAP_ADMIN_USERNAME", value = var.bootstrap_admin_username },
        { name = "AUTH_BOOTSTRAP_ADMIN_EMAIL", value = var.bootstrap_admin_email },
        { name = "AUTH_BOOTSTRAP_ADMIN_PASSWORD", value = var.bootstrap_admin_password }
      ] : []
    )

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = var.log_group_names[each.key]
        awslogs-region        = data.aws_region.current.region
        awslogs-stream-prefix = "ecs"
      }
    }

    linuxParameters = {
      initProcessEnabled = true
    }
  }])
}

resource "aws_ecs_service" "service" {
  for_each = var.service_names

  name            = each.key
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.service[each.key].arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  enable_execute_command             = true

  network_configuration {
    subnets          = var.app_subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.service[each.key].arn
  }

  dynamic "load_balancer" {
    for_each = each.key == "gateway-service" ? [1] : []
    content {
      target_group_arn = var.gateway_target_group_arn
      container_name   = each.key
      container_port   = local.ports[each.key]
    }
  }

  dynamic "load_balancer" {
    for_each = each.key == "web-storefront" ? [1] : []
    content {
      target_group_arn = var.frontend_target_group_arn
      container_name   = each.key
      container_port   = local.ports[each.key]
    }
  }

}


# ------------------------------------------------------------
# DEV platform dependencies
#
# Kafka and MongoDB run as single-node ECS/Fargate services using
# public Docker images. They are intentionally DEV-oriented:
# storage is ephemeral and data is lost if the task is replaced.
# ------------------------------------------------------------

resource "aws_service_discovery_service" "kafka" {
  count = var.enable_kafka ? 1 : 0
  name  = "kafka"

  dns_config {
    namespace_id = var.service_discovery_ns

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }
}

resource "aws_ecs_task_definition" "kafka" {
  count                    = var.enable_kafka ? 1 : 0
  family                   = "${var.project_name}-${var.environment}-kafka"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"

  execution_role_arn = var.execution_role_arn
  task_role_arn      = var.task_role_arn

  ephemeral_storage {
    size_in_gib = 21
  }

  container_definitions = jsonencode([{
    name      = "kafka"
    image     = "apache/kafka:3.7.2"
    essential = true

    portMappings = [
      {
        containerPort = 9092
        hostPort      = 9092
        protocol      = "tcp"
      },
      {
        containerPort = 9093
        hostPort      = 9093
        protocol      = "tcp"
      }
    ]

    environment = [
      { name = "KAFKA_NODE_ID", value = "1" },
      { name = "KAFKA_PROCESS_ROLES", value = "broker,controller" },
      { name = "KAFKA_LISTENER_SECURITY_PROTOCOL_MAP", value = "CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT" },
      { name = "KAFKA_LISTENERS", value = "PLAINTEXT://0.0.0.0:9092,CONTROLLER://0.0.0.0:9093" },
      { name = "KAFKA_ADVERTISED_LISTENERS", value = "PLAINTEXT://kafka.${local.namespace}:9092" },
      { name = "KAFKA_CONTROLLER_LISTENER_NAMES", value = "CONTROLLER" },
      { name = "KAFKA_CONTROLLER_QUORUM_VOTERS", value = "1@localhost:9093" },
      { name = "KAFKA_INTER_BROKER_LISTENER_NAME", value = "PLAINTEXT" },
      { name = "KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR", value = "1" },
      { name = "KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR", value = "1" },
      { name = "KAFKA_TRANSACTION_STATE_LOG_MIN_ISR", value = "1" },
      { name = "KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS", value = "0" },
      { name = "KAFKA_AUTO_CREATE_TOPICS_ENABLE", value = "true" },
      { name = "KAFKA_NUM_PARTITIONS", value = "3" }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = var.log_group_names["kafka"]
        awslogs-region        = data.aws_region.current.region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "kafka" {
  count                  = var.enable_kafka ? 1 : 0
  name                   = "kafka"
  cluster                = aws_ecs_cluster.this.id
  task_definition        = aws_ecs_task_definition.kafka[0].arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = true

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 200

  network_configuration {
    subnets          = var.app_subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.kafka[0].arn
  }
}

resource "aws_service_discovery_service" "mongo" {
  count = var.enable_mongo ? 1 : 0
  name  = "mongo"

  dns_config {
    namespace_id = var.service_discovery_ns

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }
}

resource "aws_ecs_task_definition" "mongo" {
  count                    = var.enable_mongo ? 1 : 0
  family                   = "${var.project_name}-${var.environment}-mongo"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = var.execution_role_arn
  task_role_arn      = var.task_role_arn

  ephemeral_storage {
    size_in_gib = 21
  }

  container_definitions = jsonencode([{
    name      = "mongo"
    image     = "mongo:7.0"
    essential = true

    portMappings = [{
      containerPort = 27017
      hostPort      = 27017
      protocol      = "tcp"
    }]

    environment = [
      { name = "MONGO_INITDB_ROOT_USERNAME", value = var.db_username },
      { name = "MONGO_INITDB_ROOT_PASSWORD", value = var.db_password }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = var.log_group_names["mongo"]
        awslogs-region        = data.aws_region.current.region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "mongo" {
  count                  = var.enable_mongo ? 1 : 0
  name                   = "mongo"
  cluster                = aws_ecs_cluster.this.id
  task_definition        = aws_ecs_task_definition.mongo[0].arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = true

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 200

  network_configuration {
    subnets          = var.app_subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.mongo[0].arn
  }
}

# ------------------------------------------------------------
# DEV passwordless Redis container. ElastiCache is intentionally
# independent and may remain provisioned for later use.
# ------------------------------------------------------------
resource "aws_service_discovery_service" "redis" {
  count = var.enable_redis_container ? 1 : 0
  name  = "redis"

  dns_config {
    namespace_id = var.service_discovery_ns
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
}

resource "aws_ecs_task_definition" "redis" {
  count                    = var.enable_redis_container ? 1 : 0
  family                   = "${var.project_name}-${var.environment}-redis"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  ephemeral_storage { size_in_gib = 21 }

  container_definitions = jsonencode([{
    name         = "redis"
    image        = "redis:7.2-alpine"
    essential    = true
    command      = ["redis-server", "--appendonly", "yes"]
    portMappings = [{ containerPort = 6379, hostPort = 6379, protocol = "tcp" }]
    healthCheck = {
      command     = ["CMD-SHELL", "redis-cli ping | grep PONG"]
      interval    = 5
      timeout     = 3
      retries     = 10
      startPeriod = 5
    }
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = var.log_group_names["redis"]
        awslogs-region        = data.aws_region.current.region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "redis" {
  count                  = var.enable_redis_container ? 1 : 0
  name                   = "redis"
  cluster                = aws_ecs_cluster.this.id
  task_definition        = aws_ecs_task_definition.redis[0].arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets          = var.app_subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = false
  }

  service_registries { registry_arn = aws_service_discovery_service.redis[0].arn }
}

# ------------------------------------------------------------
# Observability: one ECS service per component. These resources
# are deliberately kept inside the ECS module so there is no
# second/root ECS implementation.
# ------------------------------------------------------------
resource "aws_service_discovery_service" "zipkin" {
  count = var.enable_observability ? 1 : 0

  name = "zipkin"

  dns_config {
    namespace_id = var.service_discovery_ns
    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}

resource "aws_ecs_task_definition" "zipkin" {
  count = var.enable_observability ? 1 : 0

  family                   = "${var.project_name}-${var.environment}-zipkin"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([{
    name         = "zipkin"
    image        = "openzipkin/zipkin:3"
    essential    = true
    portMappings = [{ containerPort = 9411, hostPort = 9411, protocol = "tcp" }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = var.log_group_names["zipkin"]
        awslogs-region        = data.aws_region.current.region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "zipkin" {
  count = var.enable_observability ? 1 : 0

  name                   = "zipkin"
  cluster                = aws_ecs_cluster.this.id
  task_definition        = aws_ecs_task_definition.zipkin[0].arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets          = var.app_subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.zipkin[0].arn
  }
}

resource "aws_service_discovery_service" "prometheus" {
  count = var.enable_observability ? 1 : 0

  name = "prometheus"

  dns_config {
    namespace_id = var.service_discovery_ns
    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}

resource "aws_ecs_task_definition" "prometheus" {
  count = var.enable_observability ? 1 : 0

  family                   = "${var.project_name}-${var.environment}-prometheus"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([{
    name         = "prometheus"
    image        = "prom/prometheus:v2.48.0"
    essential    = true
    portMappings = [{ containerPort = 9090, hostPort = 9090, protocol = "tcp" }]
    entryPoint   = ["/bin/sh", "-c"]
    command = [<<-EOT
      cat >/tmp/prometheus.yml <<'CONFIG'
      global:
        scrape_interval: 15s
      scrape_configs:
        - job_name: ecommerce-services
          metrics_path: /actuator/prometheus
          static_configs:
            - targets:
                - gateway-service.${local.namespace}:8080
                - auth-service.${local.namespace}:8081
                - user-service.${local.namespace}:8087
                - catalog-service.${local.namespace}:8082
                - inventory-service.${local.namespace}:8086
                - order-service.${local.namespace}:8083
                - payment-service.${local.namespace}:8088
                - notification-service.${local.namespace}:8084
                - config-server.${local.namespace}:8889
                - web-storefront.${local.namespace}:8090
      CONFIG
      exec /bin/prometheus --config.file=/tmp/prometheus.yml --web.external-url=/prometheus/
    EOT
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = var.log_group_names["prometheus"]
        awslogs-region        = data.aws_region.current.region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "prometheus" {
  count = var.enable_observability ? 1 : 0

  name                   = "prometheus"
  cluster                = aws_ecs_cluster.this.id
  task_definition        = aws_ecs_task_definition.prometheus[0].arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets          = var.app_subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.prometheus[0].arn
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.prometheus[0].arn
    container_name   = "prometheus"
    container_port   = 9090
  }

  depends_on = [aws_lb_listener_rule.prometheus]
}

resource "aws_service_discovery_service" "grafana" {
  count = var.enable_observability ? 1 : 0

  name = "grafana"

  dns_config {
    namespace_id = var.service_discovery_ns
    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}

resource "aws_ecs_task_definition" "grafana" {
  count = var.enable_observability ? 1 : 0

  family                   = "${var.project_name}-${var.environment}-grafana"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([{
    name         = "grafana"
    image        = "grafana/grafana:10.2.0"
    essential    = true
    portMappings = [{ containerPort = 3000, hostPort = 3000, protocol = "tcp" }]
    entryPoint   = ["/bin/sh", "-c"]
    command = [<<-EOT
      mkdir -p /etc/grafana/provisioning/datasources
      cat >/etc/grafana/provisioning/datasources/prometheus.yml <<'CONFIG'
      apiVersion: 1
      datasources:
        - name: Prometheus
          type: prometheus
          access: proxy
          url: http://prometheus.${local.namespace}:9090
          isDefault: true
      CONFIG
      exec /run.sh
    EOT
    ]
    environment = [
      { name = "GF_SECURITY_ADMIN_USER", value = "admin" },
      { name = "GF_SECURITY_ADMIN_PASSWORD", value = "admin" },
      { name = "GF_USERS_ALLOW_SIGN_UP", value = "false" },
      { name = "GF_SERVER_ROOT_URL", value = "%(protocol)s://%(domain)s/grafana/" },
      { name = "GF_SERVER_SERVE_FROM_SUB_PATH", value = "true" }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = var.log_group_names["grafana"]
        awslogs-region        = data.aws_region.current.region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "grafana" {
  count = var.enable_observability ? 1 : 0

  name                   = "grafana"
  cluster                = aws_ecs_cluster.this.id
  task_definition        = aws_ecs_task_definition.grafana[0].arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets          = var.app_subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.grafana[0].arn
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.grafana[0].arn
    container_name   = "grafana"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener_rule.grafana]
}

resource "aws_lb_target_group" "prometheus" {
  count = var.enable_observability ? 1 : 0

  name        = "${var.project_name}-${var.environment}-prom"
  port        = 9090
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/-/healthy"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group" "grafana" {
  count = var.enable_observability ? 1 : 0

  name        = "${var.project_name}-${var.environment}-graf"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/api/health"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener_rule" "prometheus" {
  count = var.enable_observability ? 1 : 0

  listener_arn = var.alb_listener_arn
  priority     = 20

  condition {
    path_pattern {
      values = ["/prometheus", "/prometheus/*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prometheus[0].arn
  }
}

resource "aws_lb_listener_rule" "grafana" {
  count = var.enable_observability ? 1 : 0

  listener_arn = var.alb_listener_arn
  priority     = 30

  condition {
    path_pattern {
      values = ["/grafana", "/grafana/*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana[0].arn
  }
}
