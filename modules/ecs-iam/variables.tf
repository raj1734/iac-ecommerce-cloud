variable "project_name" { type = string }
variable "environment" { type = string }
variable "kms_key_arns" { type = list(string) }
variable "secret_arns" { type = list(string) }
