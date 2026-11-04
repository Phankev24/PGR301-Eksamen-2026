output "service_arn" {
  description = "ARN til ECS Express-tjenesten"
  value = aws_ecs_express_gateway_service.wishifai.service_arn
}

output "s3_bucket_name" {
  description = "Navnet på opprettet S3 bucket"
  value = aws_s3_bucket.images.bucket
}