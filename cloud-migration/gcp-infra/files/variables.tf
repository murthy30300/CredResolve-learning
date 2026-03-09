variable "project_id" {
  description = "Your GCP Project ID"
  type        = string
  # Replace with your personal GCP project ID
  # e.g. "my-personal-project-123456"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "asia-south1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "asia-south1-b"
}

variable "vpc_name" {
  description = "VPC Network name"
  type        = string
  default     = "credresolve-vpc-mumbai"
}

variable "private_subnet_cidr" {
  type    = string
  default = "10.1.2.0/24"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.1.0.0/24"
}

# Set to true to create all VMs, false to skip expensive ones for testing
variable "create_large_instances" {
  description = "Set false in personal/test account to skip very large VMs"
  type        = bool
  default     = false
}

variable "postgres_password" {
  description = "Password for PostgreSQL VMs (used in startup script)"
  type        = string
  sensitive   = true
  default     = "ChangeMe@1234"
}
