# GCP Infrastructure Setup — Terraform Guide
## Credresolve Infra (Personal Account Test)

---

## Prerequisites

1. Install Terraform: https://developer.hashicorp.com/terraform/install
2. Install Google Cloud SDK: https://cloud.google.com/sdk/docs/install
3. Authenticate:
   ```bash
   gcloud auth application-default login
   gcloud config set project YOUR-PROJECT-ID
   ```

---

## Step 1 — Enable Required GCP APIs

Run once in your personal project:

```bash
gcloud services enable compute.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
```

---

## Step 2 — Configure Your Variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and set your project_id
```

---

## Step 3 — Initialize Terraform

```bash
terraform init
```

---

## Step 4 — Preview What Will Be Created

```bash
terraform plan
```

Review the output. With `create_large_instances = false`, it will create:
- VPC + 2 subnets + firewall rules
- credresolve-data-analytics-db (c2-standard-8)
- communication-prod-database (n2d-highcpu-4)
- naadh-production-database (n2-custom-16-8192)
- naadh-database-stage (n2d-highcpu-4)
- credresolve-tiny-db (n2d-highcpu-2)
- redis-server (n2-standard-4)
- redis-server-stage (n2d-highcpu-4)
- credresolve-metabase (n2-custom-2-4096)

NOTE: credresolve-prod-database (112 vCPU) and credresolve-database-replica (32 vCPU)
are SKIPPED by default. Set create_large_instances = true only for production.

---

## Step 5 — Apply

```bash
terraform apply
```

Type `yes` when prompted. Takes about 3-5 minutes.

---

## Step 6 — Verify IPs After Apply

```bash
terraform output
```

This prints the internal IPs of all VMs. Note these down — you'll need them
for DMS source endpoint configuration later.

---

## Step 7 — SSH Into VMs (via IAP — no public IP needed)

```bash
gcloud compute ssh credresolve-data-analytics-db \
  --tunnel-through-iap \
  --zone asia-south1-b
```

Verify PostgreSQL is running:
```bash
sudo systemctl status postgresql
sudo -u postgres psql -c "\l"
sudo -u postgres psql -c "SHOW wal_level;"  # Should return: logical
```

---

## Step 8 — Destroy When Done Testing

```bash
terraform destroy
```

Always destroy your test infra when not in use to avoid unnecessary GCP charges.

---

## Cost Estimate (Personal Account — create_large_instances = false)

| VM | Machine Type | Est. Cost/day |
|---|---|---|
| credresolve-data-analytics-db | c2-standard-8 | ~$1.50 |
| communication-prod-database | n2d-highcpu-4 | ~$0.40 |
| naadh-production-database | n2-custom-16-8192 | ~$1.20 |
| naadh-database-stage | n2d-highcpu-4 | ~$0.40 |
| credresolve-tiny-db | n2d-highcpu-2 | ~$0.20 |
| redis-server | n2-standard-4 | ~$0.50 |
| redis-server-stage | n2d-highcpu-4 | ~$0.40 |
| credresolve-metabase | n2-custom-2-4096 | ~$0.20 |
| **Total** | | **~$4.80/day** |

Run `terraform destroy` after testing to stop all charges.

---

## File Structure

```
terraform-gcp/
├── provider.tf          # GCP provider config
├── variables.tf         # All input variables
├── network.tf           # VPC, subnets, firewall, NAT
├── compute.tf           # All VM instances
├── outputs.tf           # IP addresses after apply
├── terraform.tfvars     # Your values (gitignore this)
└── scripts/
    └── postgres_startup.sh  # Auto-installs PostgreSQL with CDC config
```
