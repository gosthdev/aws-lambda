resource "aws_lambda_function" "crop_lambda" {
  filename      = data.archive_file.crop_lambda_zip.output_path
  function_name = "crop-lambda"
  role          = aws_iam_role.lambda_crop_role.arn
  handler       = "index.handler"
  code_sha256   = data.archive_file.crop_lambda_zip.output_base64sha256

  runtime = "nodejs20.x"
  memory_size = 512
  timeout = 60

  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.s3_bucket.bucket
      PROCESSED_PREFIX   = "processed/"
    }
  }

  vpc_config {
    subnet_ids         = [
      aws_subnet.private_subnet_a.id,
      aws_subnet.private_subnet_b.id
    ]
    security_group_ids = [aws_security_group.sg_crop_lambda.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.crop_vpc_access_policy,
    aws_cloudwatch_log_group.crop_lambda_logs
  ]
}

data "archive_file" "crop_lambda_zip" {
  type        = "zip"
  source_dir  = "src/lambda_crop"
  output_path = "src/crop_function.zip"
}

resource "aws_cloudwatch_log_group" "crop_lambda_logs" {
  name              = "/aws/lambda/lambda-crop"
  retention_in_days = 14
}

resource "aws_security_group" "sg_crop_lambda" {
  name        = "sg-crop-lambda"
  description = "Permite a la lambda comunicarse con VPCEs de S3 y SQS"
  vpc_id      = aws_vpc.main_vpc.id

  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [data.aws_prefix_list.s3.id]
  }

  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.sqs_vpce_sg.id]
  }
}