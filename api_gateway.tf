resource "aws_apigatewayv2_api" "api_http" {
  name          = "mi-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST"]
    allow_headers = ["*"]
  }

}

resource "aws_apigatewayv2_integration" "integration_http" {
  api_id                 = aws_apigatewayv2_api.api_http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.upload_lambda.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "route_http" {
  api_id    = aws_apigatewayv2_api.api_http.id
  route_key = "POST /upload"
  target = "integrations/${aws_apigatewayv2_integration.integration_http.id}"
}

resource "aws_apigatewayv2_stage" "stage_http" {
  api_id      = aws_apigatewayv2_api.api_http.id
  name        = "$default"
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

#Revisar bonito
resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/apigateway/http-api-logs"
  retention_in_days = 14
}

resource "aws_lambda_permission" "allow_apigw_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api_http.execution_arn}/*/*"
}