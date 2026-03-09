# AWS Infrastructure — Terraform Guide
## Credresolve AWS Infra (Personal Account Test)

---

## Architecture Overview

```
AWS VPC (172.31.0.0/16) ←──VPN Tunnel──→ GCP VPC (10.1.0.0/16)
│
├── Public Subnet (172.31.1.0/24)
│   └── NAT Gateway
│
├── Private Subnet AZ1 (172.31.2.0/24)
│   ├── RDS PostgreSQL instances (all DBs)
│   ├── ElastiCache Redis (prod + stage)
│   ├── EC2 Metabase
│   └── DMS Replication Instance
│
└── Private Subnet AZ2 (172.31.3.0/24)
    └── RDS + ElastiCache standby (required for subnet groups)

Analytics Stack (replaces BigQuery):
  GCP data-analytics-db → DMS → S3 (Parquet) → Glue Catalog → Athena
```

---

## GCP → AWS Migration Mapping

| GCP VM | GCP IP | AWS Resource |
|---|---|---|
| naadh-production-database | 10.1.2.9 | RDS naadh-production-database |
| naadh-database-stage | 10.1.2.7 | RDS naadh-database-stage |
| credresolve-prod-database | — | RDS credresolve-prod-database |
| communication-prod-database | 10.1.2.4 | RDS communication-prod-database |
| credresolve-tiny-db | 10.1.2.5 | RDS credresolve-tiny-db |
| credresolve-data-analytics-db | 10.1.2.3 | RDS + S3 + Athena |
| redis-server | 10.1.2.8 | ElastiCache Redis (prod) |
| redis-server-stage | 10.1.2.6 | ElastiCache Redis (stage) |
| credresolve-metabase | 10.1.2.2 | EC2 t3.medium |
| BigQuery datasets | — | S3 + Glue + Athena |

---

## Step 1 — Prerequisites

```bash
# Install AWS CLI
brew install awscli   # macOS
# or: https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html

# Configure with your personal AWS account
aws configure
# Enter: Access Key, Secret Key, region: ap-south-1, format: json

# Install Terraform (if not already)
brew install terraform
```

---

## Step 2 — Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars:
# - Change S3 bucket names (must be globally unique — add your name/suffix)
# - Change db_password
# - Leave gcp_vpn_public_ip as 0.0.0.0 for now (fill after VPN step)
```

---

## Step 3 — Initialize and Apply

```bash
terraform init
terraform plan
terraform apply
# Takes about 15-20 minutes (RDS and ElastiCache are slow to provision)
```

---

## Step 4 — Set Up VPN (GCP side)

After `terraform apply`, get the AWS tunnel IPs:

```bash
terraform output vpn_tunnel1_ip
terraform output vpn_tunnel2_ip
terraform output -raw vpn_preshared_key_tunnel1
```

Then on GCP side, create Cloud VPN:
```bash
# Create HA VPN gateway
gcloud compute vpn-gateways create credresolve-vpn-gw \
  --network=credresolve-vpc-mumbai \
  --region=asia-south1

# Create Cloud Router
gcloud compute routers create credresolve-router \
  --network=credresolve-vpc-mumbai \
  --region=asia-south1 \
  --asn=65000

# Create VPN tunnel (use AWS tunnel1 IP and preshared key from above)
gcloud compute vpn-tunnels create aws-tunnel-1 \
  --peer-address=<AWS_TUNNEL1_IP> \
  --shared-secret=<PRESHARED_KEY> \
  --vpn-gateway=credresolve-vpn-gw \
  --interface=0 \
  --ike-version=2 \
  --region=asia-south1 \
  --router=credresolve-router
```

Then update `gcp_vpn_public_ip` in terraform.tfvars with the GCP gateway public IP and run:
```bash
terraform apply   # Updates Customer Gateway with real GCP IP
```

---

## Step 5 — Verify VPN Tunnel

In AWS Console → VPC → Site-to-Site VPN → your connection → Tunnel Details
Both tunnels should show Status: UP

Test connectivity from an EC2 in private subnet:
```bash
# SSM into Metabase EC2
aws ssm start-session --target <instance-id>

# Test reach to GCP VMs
nc -zv 10.1.2.9 5432   # naadh-production-database
nc -zv 10.1.2.4 5432   # communication-prod-database
nc -zv 10.1.2.8 6379   # redis-server
```

---

## Step 6 — Test DMS Endpoints

In AWS Console → DMS → Endpoints → select each source endpoint
→ Test connection → select your replication instance → Run test

All should show: Status: successful

---

## Step 7 — Start Migration Tasks

In AWS Console → DMS → Database migration tasks → Start each task
Order:
1. naadh-prod-migration (full-load-and-cdc)
2. communication-prod-migration (full-load-and-cdc)
3. analytics-to-s3 (full-load only — exports to S3 for Athena)

---

## Step 8 — Set Up Athena (after analytics-to-s3 task completes)

```bash
# Run the Glue crawler to auto-discover schema from S3 data
aws glue start-crawler --name credresolve-analytics-crawler

# Once crawler finishes, query in Athena console:
# SELECT * FROM credresolve_analytics.your_table LIMIT 10;
# Use workgroup: credresolve-workgroup
```

---

## File Structure

```
terraform-aws/
├── provider.tf          # AWS provider
├── variables.tf         # All variables
├── network.tf           # VPC, subnets, IGW, NAT, route tables
├── vpn.tf               # VGW, Customer Gateway, Site-to-Site VPN
├── security_groups.tf   # SGs for RDS, Redis, EC2, DMS
├── rds.tf               # All RDS PostgreSQL instances
├── elasticache.tf       # Redis prod + stage
├── analytics.tf         # S3 buckets, Athena workgroup, Glue catalog
├── dms.tf               # DMS instance, endpoints, migration tasks
├── ec2.tf               # Metabase EC2
├── outputs.tf           # All endpoint URLs and IPs
└── terraform.tfvars     # Your values (never commit to git)
```

---

## Important Notes

- S3 bucket names must be globally unique — add a personal suffix
- RDS takes ~10 mins to provision, ElastiCache ~5 mins
- DMS tasks will fail until VPN tunnel is UP — always verify VPN first
- Run `terraform destroy` when done testing to stop all charges
- Estimated test cost: ~$5-8/day with all resources running
