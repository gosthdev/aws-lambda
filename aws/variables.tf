variable "environment" {
  type        = string
  description = "Deployment environment name (dev, qa, prod)."

  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "environment must be one of: dev, qa, prod."
  }
}

variable "project_name" {
  type        = string
  description = "Project name prefix for shared resources."
  default     = "image-processing"
}

variable "bucket_name_prefix" {
  type        = string
  description = "Prefix for the S3 bucket name."
  default     = "image-processing-bucket"
}

variable "aws_region" {
  type        = string
  description = "AWS region for deployment."
  default     = "us-east-1"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."
  default     = "10.0.0.0/16"
}

variable "private_subnet_a_cidr" {
  type        = string
  description = "CIDR block for private subnet A."
  default     = "10.0.11.0/24"
}

variable "private_subnet_b_cidr" {
  type        = string
  description = "CIDR block for private subnet B."
  default     = "10.0.12.0/24"
}

variable "public_subnet_a_cidr" {
  type        = string
  description = "CIDR block for public subnet A."
  default     = "10.0.1.0/24"
}

variable "public_subnet_b_cidr" {
  type        = string
  description = "CIDR block for public subnet B."
  default     = "10.0.2.0/24"
}

variable "availability_zone_a" {
  type        = string
  description = "Availability zone for subnet A."
  default     = "us-east-1a"
}

variable "availability_zone_b" {
  type        = string
  description = "Availability zone for subnet B."
  default     = "us-east-1b"
}
