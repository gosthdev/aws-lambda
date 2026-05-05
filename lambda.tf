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

}
