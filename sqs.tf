resource "aws_sqs_queue" "main_queue" {
  name = "image-processor-${terraform.workspace}-image-queue"
  # max_message_size          = 2048
  delay_seconds             = 90
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

