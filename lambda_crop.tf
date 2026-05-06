resource "aws_lambda_function" "crop_lambda" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "crop_lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  code_sha256   = data.archive_file.lambda_zip.output_base64sha256

  runtime = "nodejs20.x"
  memory_size = 256
  timeout = 60

  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.s3_bucket.bucket
      PROCESSED_PREFIX   = "processed/"
    }
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "src/lambda/index.js"
  output_path = "src/lambda/function.zip"
}