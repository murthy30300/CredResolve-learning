variable "aws_region" {
  description = "AWS Region — Mumbai to match GCP asia-south1"
  type        = string
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "AWS VPC CIDR — must NOT overlap with GCP 10.1.0.0/16"
  type        = string
  default     = "172.31.0.0/16"
}

variable "private_subnet_cidr" {
  type    = string
  default = "172.31.2.0/24"
}

variable "public_subnet_cidr" {
  type    = string
  default = "172.31.1.0/24"
}

# Second AZ subnet — RDS requires at least 2 AZs for subnet group
variable "private_subnet_cidr_az2" {
  type    = string
  default = "172.31.3.0/24"
}

variable "availability_zone_1" {
  type    = string
  default = "ap-south-1a"
}

variable "availability_zone_2" {
  type    = string
  default = "ap-south-1b"
}

# GCP VPC CIDR — for VPN routing and security group rules
variable "gcp_vpc_cidr" {
  description = "GCP private subnet CIDR — used in security group ingress rules"
  type        = string
  default     = "10.1.0.0/16"
}

variable "gcp_vpn_public_ip" {
  description = "Public IP of your GCP Cloud VPN gateway (fill after GCP VPN is set up)"
  type        = string
  default     = "0.0.0.0" # Replace with actual GCP VPN public IP
}

variable "db_password" {
  description = "Master password for all RDS instances"
  type        = string
  sensitive   = true
  default     = "ChangeMe@1234"
}

variable "project_name" {
  type    = string
  default = "credresolve"
}

# S3 + Athena
variable "analytics_bucket_name" {
  description = "S3 bucket for analytics data (must be globally unique)"
  type        = string
  default     = "credresolve-analytics-data"
}

variable "athena_results_bucket_name" {
  description = "S3 bucket for Athena query results (must be globally unique)"
  type        = string
  default     = "credresolve-athena-results"
}
