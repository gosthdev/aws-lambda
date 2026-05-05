resource "aws_lambda_function" "upload_lambda" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "upload-lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  code_sha256   = data.archive_file.lambda_zip.output_base64sha256

  runtime = "nodejs20.x"
  
  memory_size = 256
  timeout     = 30

  environment {
    variables = {
      S3_BUCKET     = aws_s3_bucket.s3_bucket.bucket
      UPLOAD_PREFIX = "uploads/"
    }
  }

  vpc_config {
    subnet_ids         = [
      aws_subnet.private_subnet_a.id, 
      aws_subnet.private_subnet_b.id  
    ]
    security_group_ids = [aws_security_group.sg_upload_lambda.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.vpc_access_policy,
    aws_cloudwatch_log_group.lambda_logs
  ]
}


data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "src/lambda" 
  output_path = "src/function.zip"
}
