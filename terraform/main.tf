terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# -----------------------------
# S3 Bucket
# -----------------------------
resource "aws_s3_bucket" "automation_reports" {
  bucket = "debo-automation-reports-${var.environment}"
}

# -----------------------------
# SSM Parameter
# -----------------------------
resource "aws_ssm_parameter" "config_example" {
  name  = "/automation/example/config"
  type  = "String"
  value = "initial-value"
}

# -----------------------------
# Lambda Packaging
# -----------------------------
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/automation"
  output_path = "${path.module}/lambda_payload.zip"
}

# -----------------------------
# IAM Role for Lambda
# -----------------------------
resource "aws_iam_role" "lambda_role" {
  name = "automation-lambda-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_ssm_policy" {
  name = "lambda-ssm-policy-${var.environment}"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/automation/example/config"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_s3_policy" {
  name = "lambda-s3-policy-${var.environment}"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "arn:aws:s3:::debo-automation-reports-dev/*"
      }
    ]
  })
}

# -----------------------------
# Lambda Function
# -----------------------------
resource "aws_lambda_function" "automation" {
  function_name = "automation-${var.environment}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      REPORT_BUCKET = aws_s3_bucket.automation_reports.bucket
      CONFIG_PARAM  = aws_ssm_parameter.config_example.name
    }
  }
  
  timeout = 10
}




# -----------------------------
# EventBridge Schedule
# -----------------------------
resource "aws_cloudwatch_event_rule" "daily_automation" {
  name                = "daily-automation-${var.environment}"
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_automation.name
  target_id = "lambda"
  arn       = aws_lambda_function.automation.arn
}

resource "aws_lambda_permission" "allow_events" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.automation.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_automation.arn
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "automation-lambda-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0

  dimensions = {
    FunctionName = aws_lambda_function.automation.function_name
  }

  alarm_description = "Triggers if Lambda has any errors"
  treat_missing_data = "notBreaching"
}
