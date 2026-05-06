resource "aws_sqs_queue" "main_queue" {
  name = "image-processor-${terraform.workspace}-image-queue"
  # max_message_size          = 2048
  # delay_seconds             = 90
  visibility_timeout_seconds = 360
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 20
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.deadletter_queue.arn
    maxReceiveCount     = 3 
  })
}

resource "aws_sqs_queue" "deadletter_queue" {
  name                      = "image-processor-${terraform.workspace}-image-dlq"
  message_retention_seconds = 1209600
}

resource "aws_lambda_event_source_mapping" "sqs_to_lambda" {
  event_source_arn = aws_sqs_queue.main_queue.arn
  function_name    = aws_lambda_function.crop_lambda.arn
  batch_size       = 5 
  function_response_types = ["ReportBatchItemFailures"] 
}

resource "aws_cloudwatch_metric_alarm" "dlq_alarm" {
  alarm_name          = "dlq-message-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = 0   
  dimensions = {
    QueueName = aws_sqs_queue.deadletter_queue.name
  }
  alarm_actions = [aws_sns_topic.sns_topic.arn]
}

data "aws_iam_policy_document" "allow_s3_send_to_sqs_doc" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.main_queue.arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.s3_bucket.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "allow_s3_send_to_sqs" {
  queue_url = aws_sqs_queue.main_queue.id
  policy    = data.aws_iam_policy_document.allow_s3_send_to_sqs_doc.json
}

resource "aws_sns_topic" "sns_topic" {
  name = "image-processing-alarms"
}
