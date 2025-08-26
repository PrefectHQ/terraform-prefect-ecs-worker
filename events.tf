resource "aws_sqs_queue" "this" {
  count = var.enable_sqs_monitoring ? 1 : 0

  name_prefix = "prefect-worker-"
}

resource "aws_sqs_queue_policy" "this" {
  count = var.enable_sqs_monitoring ? 1 : 0

  queue_url = aws_sqs_queue.this[0].id
  policy    = data.aws_iam_policy_document.eventbridge_to_sqs[0].json
}

resource "aws_cloudwatch_event_rule" "this" {
  count = var.enable_sqs_monitoring ? 1 : 0

  name = "ecs-cluster-all-events"

  # Match any ECS event whose 'resources' includes this cluster ARN
  event_pattern = jsonencode({
    "source" : ["aws.ecs"],
    "resources" : [aws_ecs_cluster.prefect_worker_cluster.arn]
  })
}

resource "aws_cloudwatch_event_target" "this" {
  count = var.enable_sqs_monitoring ? 1 : 0

  rule      = aws_cloudwatch_event_rule.this[0].name
  target_id = "send-to-sqs"
  arn       = aws_sqs_queue.this[0].arn
}
