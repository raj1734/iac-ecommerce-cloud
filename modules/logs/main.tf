resource "aws_cloudwatch_log_group" "service" {
  for_each = var.services

  name              = "/ecommerce/${var.environment}/${each.key}"
  retention_in_days = var.environment == "prod" ? 30 : 7
}
