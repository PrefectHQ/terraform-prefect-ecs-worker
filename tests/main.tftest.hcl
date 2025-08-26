mock_provider "prefect" {}
mock_provider "aws" {
  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/mock-role"
    }
  }
  
  mock_resource "aws_sqs_queue" {
    defaults = {
      arn = "arn:aws:sqs:us-west-2:123456789012:mock-queue"
    }
  }
  
  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::123456789012:policy/mock-policy"
    }
  }
  
  override_data {
    target = data.aws_iam_policy_document.eventbridge_to_sqs
    values = {
      json = "{}"
    }
  }
  
  override_data {
    target = data.aws_iam_policy_document.prefect_worker_read_sqs
    values = {
      json = "{}"
    }
  }
}

variables {
  name = "testing"
  worker_work_pool_name = "testing"
  vpc_id = "vpc-123456"
  worker_subnets = ["subnet-123456"]
  
  prefect_account_id = "00000000-0000-0000-0000-000000000000"
  prefect_workspace_id = "00000000-0000-0000-0000-000000000000"
  prefect_api_key = "test"
}

run "ensure_defaults" {
  command = plan
}

run "ensure_no_observers" {
  variables {
    enable_sqs_monitoring = false
  }
  
  # Assert: No SQS queue created when enable_sqs_monitoring = false
  assert {
    condition = length(aws_sqs_queue.this) == 0
    error_message = "SQS queue should not be created when monitoring is disabled."
  }
  
  # Assert: No EventBridge rule created when enable_sqs_monitoring = false
  assert {
    condition = length(aws_cloudwatch_event_rule.this) == 0
    error_message = "EventBridge rule should not be created when monitoring is disabled."
  }
  
  # Assert: SQS observer env var does NOT exist when enable_sqs_monitoring = false
  assert {
    condition = (
      try(
        tomap({
          for e in jsondecode(aws_ecs_task_definition.prefect_worker_task_definition.container_definitions)[0].environment :
          e.name => e.value
        })["PREFECT_INTEGRATIONS_AWS_ECS_OBSERVER_SQS_QUEUE_NAME"],
        null
      ) == null
    )
    error_message = "SQS env should not be set when monitoring is disabled."
  }
}

run "ensure_extra_env" {
  variables {
    worker_extra_env = {
      EXTRA_ENV_1 = "value1"
    }
  }
  
  assert {
    condition = (
      tomap({
          for env in jsondecode(aws_ecs_task_definition.prefect_worker_task_definition.container_definitions)[0].environment :
          env.name => env.value
      })["EXTRA_ENV_1"] == "value1"
    )
    error_message = "Expected EXTRA_ENV_1 to be set to value1."
  }
}

run "ensure_extra_policy_attachments" {
  variables {
    worker_task_role_extra_policy_attachment = [
      "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
    ]
  }
  
  assert {
    condition = (
      contains(
        [
          for attachment in aws_iam_role_policy_attachment.this :
          attachment.policy_arn
        ],
        "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
      )
    )
    error_message = "Expected AmazonS3ReadOnlyAccess policy to be attached to the task role."
  }
}