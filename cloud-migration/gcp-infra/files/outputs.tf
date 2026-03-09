# ─────────────────────────────────────────────
# OUTPUTS — useful after terraform apply
# ─────────────────────────────────────────────

output "vpc_id" {
  value       = google_compute_network.vpc.id
  description = "VPC Network ID"
}

output "private_subnet_id" {
  value       = google_compute_subnetwork.private.id
  description = "Private Subnet ID"
}

output "public_subnet_id" {
  value       = google_compute_subnetwork.public.id
  description = "Public Subnet ID"
}

output "credresolve_data_analytics_db_ip" {
  value       = google_compute_instance.credresolve_data_analytics_db.network_interface[0].network_ip
  description = "Internal IP of data analytics DB"
}

output "communication_prod_database_ip" {
  value       = google_compute_instance.communication_prod_database.network_interface[0].network_ip
}

output "naadh_production_database_ip" {
  value       = google_compute_instance.naadh_production_database.network_interface[0].network_ip
}

output "naadh_database_stage_ip" {
  value       = google_compute_instance.naadh_database_stage.network_interface[0].network_ip
}

output "credresolve_tiny_db_ip" {
  value       = google_compute_instance.credresolve_tiny_db.network_interface[0].network_ip
}

output "redis_server_ip" {
  value       = google_compute_instance.redis_server.network_interface[0].network_ip
}

output "redis_server_stage_ip" {
  value       = google_compute_instance.redis_server_stage.network_interface[0].network_ip
}

output "metabase_ip" {
  value       = google_compute_instance.credresolve_metabase.network_interface[0].network_ip
}

output "nat_router_name" {
  value = google_compute_router.router.name
}
