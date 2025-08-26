# ---------- ECS Task Execution Role ----------
resource "aws_iam_role" "prefect_worker_execution_role" {
  name = "prefect-worker-execution-role-${var.name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "prefect_worker_ecs_policy" {
  role = aws_iam_role.prefect_worker_execution_role.name

  // AmazonECSTaskExecutionRolePolicy is an AWS managed role for creating ECS tasks and services
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ssm_allow_read_prefect_api_key" {
  name = "ssm-allow-read-prefect-api-key-${var.name}"
  role = aws_iam_role.prefect_worker_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kms:Decrypt",
          "secretsmanager:GetSecretValue",
          "ssm:GetParameters"
        ]
        Effect = "Allow"
        Resource = [
          aws_secretsmanager_secret.prefect_api_key.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "allow_create_log_group" {
  name = "logs-allow-create-log-group-${var.name}"
  role = aws_iam_role.prefect_worker_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# ---------- ECS Task Role ----------
resource "aws_iam_role" "prefect_worker_task_role" {
  name  = "prefect-worker-task-role-${var.name}"
  count = var.worker_task_role_arn == null ? 1 : 0

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "prefect_worker_allow_ecs_task" {
  name  = "prefect-worker-allow-ecs-task-${var.name}"
  count = var.worker_task_role_arn == null ? 1 : 0
  role  = aws_iam_role.prefect_worker_task_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "ecr:BatchCheckLayerAvailability", # TODO: check if this is actually required
          "ecr:BatchGetImage",               # TODO: check if this is actually required
          "ecr:GetAuthorizationToken",       # TODO: check if this is actually required
          "ecr:GetDownloadUrlForLayer",      # TODO: check if this is actually required
          "ecs:DeregisterTaskDefinition",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks",
          "ecs:RegisterTaskDefinition",
          "ecs:RunTask",
          "ecs:StopTask",
          "ecs:TagResource",
          "iam:PassRole",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:GetLogEvents",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
