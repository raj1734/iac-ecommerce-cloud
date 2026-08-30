output "bootstrap_brokers" {
  value = aws_msk_cluster.this.bootstrap_brokers_sasl_iam
}
