output "endpoints" {
  value = { for k, v in aws_db_instance.this : k => v.address }
}
