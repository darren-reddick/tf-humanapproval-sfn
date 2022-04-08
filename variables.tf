variable "region" {
  type        = string
  description = "Name of the AWS region all AWS resources will be provisioned in"
}

variable "stage" {
  type        = string
  description = "The deployment stage"
  default     = "dev"
}

variable "email" {
  type        = string
  description = "The approval email address"
  default     = "darren.reddick@ecs.co.uk"
}