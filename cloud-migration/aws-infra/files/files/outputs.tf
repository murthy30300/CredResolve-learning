# ─────────────────────────────────────────────
# NETWORK
# ─────────────────────────────────────────────
output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnet_id" {
  value = aws_subnet.private.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

# ─────────────────────────────────────────────
# VPN — share with GCP team to configure Cloud VPN
# ─────────────────────────────────────────────
output "vpn_gateway_id" {
  value = aws_vpn_gateway.vgw.id
}

output "vpn_tunnel1_ip" {
  value       = aws_vpn_connection.gcp_tunnel.tunnel1_address
  description = "Configure this IP as peer on GCP Cloud VPN"
}

output "vpn_tunnel2_ip" {
  value       = aws_vpn_connection.gcp_tunnel.tunnel2_address
  description = "Configure this IP as peer on GCP Cloud VPN (backup tunnel)"
}

output "vpn_preshared_key_tunnel1" {
  value     = aws_vpn_connection.gcp_tunnel.tunnel1_preshared_key
  sensitive = true
}

# ─────────────────────────────────────────────
# RDS ENDPOINTS — update app connection strings
# ─────────────────────────────────────────────
output "naadh_prod_rds_endpoint" {
  value       = aws_db_instance.naadh_production.address
  description = "Replace naadh-production-database GCP IP (10.1.2.9) with this"
}

output "naadh_stage_rds_endpoint" {
  value = aws_db_instance.naadh_stage.address
}

output "credresolve_prod_rds_endpoint" {
  value = aws_db_instance.credresolve_prod.address
}

output "communication_prod_rds_endpoint" {
  value       = aws_db_instance.communication_prod.address
  description = "Replace communication-prod-database GCP IP (10.1.2.4) with this"
}

output "credresolve_tiny_rds_endpoint" {
  value = aws_db_instance.credresolve_tiny.address
}

output "data_analytics_rds_endpoint" {
  value = aws_db_instance.data_analytics.address
}

# ─────────────────────────────────────────────
# ELASTICACHE ENDPOINTS
# ─────────────────────────────────────────────
output "redis_prod_endpoint" {
  value       = aws_elasticache_replication_group.redis_prod.primary_endpoint_address
  description = "Replace redis-server GCP IP (10.1.2.8) with this"
}

output "redis_stage_endpoint" {
  value       = aws_elasticache_replication_group.redis_stage.primary_endpoint_address
  description = "Replace redis-server-stage GCP IP (10.1.2.6) with this"
}

# ─────────────────────────────────────────────
# ANALYTICS — S3 + Athena
# ─────────────────────────────────────────────
output "analytics_s3_bucket" {
  value       = aws_s3_bucket.analytics.bucket
  description = "Data lake bucket — replaces BigQuery datasets"
}

output "athena_results_bucket" {
  value = aws_s3_bucket.athena_results.bucket
}

output "athena_workgroup" {
  value = aws_athena_workgroup.main.name
}

output "glue_crawler_name" {
  value       = aws_glue_crawler.analytics.name
  description = "Run this crawler after DMS exports data to S3"
}

# ─────────────────────────────────────────────
# METABASE
# ─────────────────────────────────────────────
output "metabase_private_ip" {
  value       = aws_instance.metabase.private_ip
  description = "Access Metabase via SSM tunnel or internal load balancer"
}

# ─────────────────────────────────────────────
# DMS
# ─────────────────────────────────────────────
output "dms_replication_instance_arn" {
  value = aws_dms_replication_instance.main.replication_instance_arn
}
