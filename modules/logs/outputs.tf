output "log_group_names" {
  value = { for k, v in aws_cloudwatch_log_group.service : k => v.name }
}
