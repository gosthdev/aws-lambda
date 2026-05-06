locals {
  environment = var.environment
  name_prefix = "${var.project_name}-${local.environment}"
  bucket_name = "${var.bucket_name_prefix}-${local.environment}"
}
