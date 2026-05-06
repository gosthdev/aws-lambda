locals {
  environment = terraform.workspace
  name_prefix = "${var.project_name}-${local.environment}"
  bucket_name = "${var.bucket_name_prefix}-${local.environment}"
}
