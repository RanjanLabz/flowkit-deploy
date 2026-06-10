variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "flowkit"
}

variable "instance_type" {
  description = "EC2 instance type (need amd64 for Chrome)"
  type        = string
  default     = "t3.medium"
}

variable "ssh_key_name" {
  description = "AWS key pair name for SSH"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR for SSH access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "api_allowed_cidr" {
  description = "CIDR for worker API access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "vnc_allowed_cidr" {
  description = "CIDR for VNC access (empty = disabled)"
  type        = string
  default     = ""
}

variable "disk_size_gb" {
  description = "Root disk size in GB"
  type        = number
  default     = 50
}

variable "repo_url" {
  description = "Worker repo URL"
  type        = string
  default     = "https://github.com/RanjanLabz/flowkit-vps-worker.git"
}

variable "repo_branch" {
  description = "Git branch"
  type        = string
  default     = "main"
}

variable "worker_id" {
  description = "Unique worker identifier"
  type        = string
  default     = "aws-worker-1"
}

variable "orchestrator_url" {
  description = "Orchestrator URL for auto-registration"
  type        = string
  default     = ""
}

variable "orchestrator_api_key" {
  description = "Orchestrator API key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "redis_url" {
  description = "Redis URL (external)"
  type        = string
  default     = ""
}

variable "vnc_password" {
  description = "VNC password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "app_dir" {
  description = "App install directory"
  type        = string
  default     = "/opt/flow-worker"
}
