variable "region" {
  type    = string
  default = "us-east-1"
}

variable "aws_access_key" {
  type        = string
  description = "AWS Access Key"
}

variable "aws_secret_key" {
  type        = string
  description = "AWS Secret Key"
}

variable "healthcheck_url" {
  type        = string
  description = "Application Health Check URL. Elastic Beanstalk will call this URL to check the health of the application running on EC2 instances"
  default     = "/"
}

variable "app_port" {
  type    = number
  default = 80
}

# variable "redis_port" {
#   type    = number
#   default = 6379
# }

variable "main_instance_type" {
  type    = string
  default = "t2.medium"
}
