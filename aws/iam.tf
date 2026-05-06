data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "upload-lambda-role-${local.environment}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "basic_execution_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "vpc_access_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "aws_iam_policy_document" "s3_upload_policy_doc" {
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.s3_bucket.arn}/uploads/*"]
  }
}

resource "aws_iam_policy" "s3_upload_policy" {
  name   = "UploadLambdaS3Policy-${local.environment}"
  policy = data.aws_iam_policy_document.s3_upload_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "s3_upload_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.s3_upload_policy.arn
}

data "aws_iam_policy_document" "crop_lambda_policy_doc" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.s3_bucket.arn}/uploads/*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.s3_bucket.arn}/processed/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:ChangeMessageVisibility",
      "sqs:GetQueueAttributes"
    ]
    resources = [aws_sqs_queue.main_queue.arn]
  }
}

resource "aws_iam_role" "lambda_crop_role" {
  name               = "crop-lambda-role-${local.environment}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "crop_basic_execution_policy" {
  role       = aws_iam_role.lambda_crop_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "crop_vpc_access_policy" {
  role       = aws_iam_role.lambda_crop_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_policy" "crop_lambda_policy" {
  name   = "CropLambdaPolicy-${local.environment}"
  policy = data.aws_iam_policy_document.crop_lambda_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "crop_lambda_attach" {
  role       = aws_iam_role.lambda_crop_role.name
  policy_arn = aws_iam_policy.crop_lambda_policy.arn
}
#