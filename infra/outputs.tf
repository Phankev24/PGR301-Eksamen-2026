output "service_arn" {
  description = "ARN til ECS Express-tjenesten"
  value       = aws_ecs_express_gateway_service.wishifai.service_arn
}

output "s3_bucket_name" {
  description = "Navnet på opprettet S3 bucket"
  value       = aws_s3_bucket.images.bucket
}

output "dashboard_name" {
  description = "Navnet på CloudWatch Dashboard"
  value       = aws_cloudwatch_dashboard.wishifai_dashboard.dashboard_name
}

output "alarm_name" {
  description = "Navnet på CloudWatch Alarm"
  value       = aws_cloudwatch_metric_alarm.bedrock_latency_alarm.alarm_name
}

output "service_url" {
  description = "Offentlig URL til Wishifai-tjenesten"
  value       = aws_ecs_express_gateway_service.wishifai.ingress_paths[0].endpoint
}