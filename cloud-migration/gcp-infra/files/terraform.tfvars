# ─────────────────────────────────────────────
# FILL THIS FILE WITH YOUR VALUES
# Rename to terraform.tfvars before running
# ─────────────────────────────────────────────

# Your personal GCP project ID
# Find it: GCP Console → top dropdown → copy Project ID (not project name)
project_id = "YOUR-PROJECT-ID-HERE"

# Region and zone — keep as Mumbai to match original
region = "asia-south1"
zone   = "asia-south1-b"

# Set to false for personal/test account (skips 112-vCPU and 32-vCPU VMs)
# Set to true only when migrating to production
create_large_instances = false

# Change this to a strong password
postgres_password = "ChangeMe@1234"
