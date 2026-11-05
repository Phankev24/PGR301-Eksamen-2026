variable "aws_region" {
  description = "AWS-region som brukes"
  type        = string
  default     = "eu-west-1"
}

variable "candidate_no" {
  description = "Kandidatnummer for ressurser og identifisering"
  type        = string
  default     = "28"
}

variable "image_tag" {
  description = "Docker image tag for Wishifai-applikasjonen"
  type        = string
  default     = "latest"
}

variable "ecr_image_uri" {
  description = "Full URI til ECR-imaget"
  type        = string
  default     = "244530008913.dkr.ecr.eu-west-1.amazonaws.com/wishifai-app-k28"
}