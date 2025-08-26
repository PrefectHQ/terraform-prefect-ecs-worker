// Region specified in AWS provider
data "aws_region" "current" {}

resource "aws_secretsmanager_secret" "prefect_api_key" {
  name_prefix             = "prefect-api-key-${var.name}-"
  recovery_window_in_days = var.secrets_manager_recovery_in_days
}

resource "aws_secretsmanager_secret_version" "prefect_api_key_version" {
  secret_id     = aws_secretsmanager_secret.prefect_api_key.id
  secret_string = var.prefect_api_key
}

resource "aws_cloudwatch_log_group" "prefect_worker_log_group" {
  name              = "prefect-worker-log-group-${var.name}"
  retention_in_days = var.worker_log_retention_in_days
}
