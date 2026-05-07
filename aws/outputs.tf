output "api_endpoint" {
  value       = aws_apigatewayv2_api.api_http.api_endpoint
  description = "API Gateway endpoint for the current workspace."
}
