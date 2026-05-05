resource "aws_apigatewayv2_api" "api-http" {
  name          = "mi-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST"]
    allow_headers = ["*"]
  }

}

resource "aws_apigatewayv2_integration" "integration-http" {
  api_id                 = aws_apigatewayv2_api.api-http.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "POST" 
  integration_uri        = "https://infra .com/upload" 
  payload_format_version = "2.0" 
}

resource "aws_apigatewayv2_route" "route-http" {
  api_id    = aws_apigatewayv2_api.api-http.id
  route_key = "POST /upload"
  target = "integrations/${aws_apigatewayv2_integration.integration-http.id}"
}

resource "aws_apigatewayv2_stage" "stage-http" {
  api_id = aws_apigatewayv2_api.api-http.id
  name   = "$stage"
  auto_deploy = true

  default_route_settings {
    throttling_rate_limit  = 10000
    throttling_burst_limit = 5000
  }

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    format          = jsonencode({
      ip     = "$context.identity.sourceIp"
      time   = "$context.requestTime"
      method = "$context.httpMethod"
      path   = "$context.resourcePath"
      status = "$context.status"
    })
  }
}   

resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/apigateway/http-api-logs"
  retention_in_days = 14
}