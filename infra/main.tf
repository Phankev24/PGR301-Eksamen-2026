resource "aws_s3_bucket" "images" {
  bucket        = "wishifai-images-k${var.candidate_no}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "images" {
  bucket = aws_s3_bucket.images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}



resource "aws_iam_role" "ecs_task_role" {
  name = "wishifai-task-role-k${var.candidate_no}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}



resource "aws_iam_role_policy" "ecs_task_policy" {
  name = "wishifai-task-policy-k${var.candidate_no}"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]
        Resource = [aws_s3_bucket.images.arn, "${aws_s3_bucket.images.arn}/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["rekognition:DetectLabels", "rekognition:DetectText"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["bedrock:InvokeModel"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["cloudwatch:PutMetricData"]
        Resource = "*"
      }
    ]
  })
}



resource "aws_ecs_express_gateway_service" "wishifai" {
  service_name = "wishifai-service-k${var.candidate_no}"

  execution_role_arn      = "arn:aws:iam::244530008913:role/ecsTaskExecutionRole"
  infrastructure_role_arn = "arn:aws:iam::244530008913:role/service-role/ecsInfrastructureRoleForExpressServices"
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  health_check_path = "/actuator/health"

  primary_container {
    image          = "${var.ecr_image_uri}:${var.image_tag}"
    container_port = 8080

    environment {
      name  = "S3_BUCKET"
      value = aws_s3_bucket.images.bucket
    }
  }

  cpu    = "256"
  memory = "512"
}