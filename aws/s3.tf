resource "aws_s3_bucket" "s3_bucket" {
  bucket = local.bucket_name
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.s3_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.s3_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.s3_bucket.id

  rule {
    id = "expire-upload"
    status = "Enabled"
    filter {
      prefix = "uploads/"
    }
    expiration {
      days = 30
    }
  }

  rule {
    id = "expire-processed"
    status = "Enabled"
    filter {
      prefix = "processed/"
    }
    expiration {
      days = 90
    }
  }
}

resource "aws_s3_bucket_public_access_block" "access_s3" {
  bucket = aws_s3_bucket.s3_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.s3_bucket.id
  queue {
    queue_arn     = aws_sqs_queue.main_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "uploads/"
  }
  depends_on = [aws_sqs_queue_policy.allow_s3_send_to_sqs]
}