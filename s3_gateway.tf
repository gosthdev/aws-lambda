resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id       = aws_vpc.main_vpc.id
  service_name = "com.amazonaws.${data.aws_region.current_lambda.region}.s3"
  route_table_ids = [
    aws_route_table.private_rt_a.id,
    aws_route_table.private_rt_b.id
  ]
  
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": "*",
        "Action": ["s3:GetObject", "s3:PutObject"],
        "Resource": [
          "${aws_s3_bucket.s3_bucket.arn}/uploads/*",
          "${aws_s3_bucket.s3_bucket.arn}/processed/*"
        ]
      }
    ]
  })
  vpc_endpoint_type = "Gateway"
}

resource "aws_security_group" "sqs_vpce_sg" {
  name        = "sqs-vpce"
  description = "Permite trafico 443 desde la Lambda de crop al VPCE de SQS"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_crop_lambda.id]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_upload_lambda.id]
  }
}

resource "aws_vpc_endpoint" "sqs_interface" {
  vpc_id              = aws_vpc.main_vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current_lambda.name}.sqs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [
    aws_subnet.private_subnet_a.id,
    aws_subnet.private_subnet_b.id
  ]
  security_group_ids  = [aws_security_group.sqs_vpce_sg.id]
  private_dns_enabled = true
}

