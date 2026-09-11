variable "project_name" { type = string }
variable "environment" { type = string }
variable "subnet_ids" { type = list(string) }
variable "security_group_ids" { type = list(string) }
variable "instance_class" { type = string }
variable "multi_az" { type = bool }
variable "kms_key_arn" { type = string }
variable "master_username" {
  type      = string
  sensitive = true
}
variable "master_password" {
  type      = string
  sensitive = true
}
variable "database_names" {
  type = list(string)
}
