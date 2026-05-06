resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id       = aws_vpc.main_vpc.id
  service_name = "com.amazonaws.us-east-1.s3"
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
        "Resource": "*"
      }
    ]
  })
  vpc_endpoint_type = "Gateway"
}

