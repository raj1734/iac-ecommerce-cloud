output "secrets_key_arn" { value = aws_kms_key.secrets.arn }
output "database_key_arn" { value = aws_kms_key.database.arn }
output "msk_key_arn" { value = aws_kms_key.msk.arn }
