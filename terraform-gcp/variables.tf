variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "flowkit"
}

variable "machine_type" {
  description = "GCP machine type"
  type        = string
  default     = "e2-standard-2"
}

variable "ssh_allowed_cidr" {
  description = "CIDR for SSH"
  type        = string
  default     = "0.0.0.0/0"
}

variable "api_allowed_cidr" {
  description = "CIDR for worker API"
  type        = string
  default     = "0.0.0.0/0"
}

variable "vnc_allowed_cidr" {
  description = "CIDR for VNC (empty = disabled)"
  type        = string
  default     = ""
}

variable "disk_size_gb" {
  description = "Boot disk size GB"
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
  description = "Unique worker ID"
  type        = string
  default     = "gcp-worker-1"
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
