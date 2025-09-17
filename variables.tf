variable "aws_region" {
  description = "The AWS region where resources will be created"
  type        = string
  default     = "us-west-2"
}

variable "key_pair_name" {
  description = "The name of an existing EC2 key pair for SSH access"
  type        = string
}

variable "my_ip" {
  description = "Your local IP address for restricting SSH access (null for open access)"
  type        = string
  default     = null
}

variable "git_repo_url" {
  description = "The URL of the Django project repository"
  type        = string
  default     = "https://github.com/BoXu1225/DjangoTest.git"
}