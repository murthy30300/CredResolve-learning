# ─────────────────────────────────────────────
# VPC
# ─────────────────────────────────────────────
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  description             = "Credresolve VPC - Mumbai region"
}

# ───────────────────────────────────────────
# SUBNETS
# ───────────────────────────────────────────
resource "google_compute_subnetwork" "private" {
  name          = "credresolve-private-subnet"
  ip_cidr_range = var.private_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id

  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_subnetwork" "public" {
  name          = "credresolve-public-subnet"
  ip_cidr_range = var.public_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
}

# ─────────────────────────────────────────────
# CLOUD ROUTER + NAT (so private VMs can reach internet for updates)
# ─────────────────────────────────────────────
resource "google_compute_router" "router" {
  name    = "credresolve-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "credresolve-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.private.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

# ─────────────────────────────────────────────
# FIREWALL RULES
# ─────────────────────────────────────────────

# Allow internal traffic within VPC (all VMs talk to each other)
resource "google_compute_firewall" "allow_internal" {
  name    = "credresolve-allow-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = [var.private_subnet_cidr, var.public_subnet_cidr]
  description   = "Allow all internal VPC traffic"
}

# Allow PostgreSQL from within VPC only
resource "google_compute_firewall" "allow_postgres" {
  name    = "credresolve-allow-postgres"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_ranges = [var.private_subnet_cidr, var.public_subnet_cidr]
  target_tags   = ["all-db", "prod-database"]
  description   = "Allow PostgreSQL access from within VPC"
}

# Allow Redis from within VPC only
resource "google_compute_firewall" "allow_redis" {
  name    = "credresolve-allow-redis"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["6379"]
  }

  source_ranges = [var.private_subnet_cidr, var.public_subnet_cidr]
  target_tags   = ["redis"]
  description   = "Allow Redis access from within VPC"
}

# Allow Metabase UI (port 3000) from within VPC
resource "google_compute_firewall" "allow_metabase" {
  name    = "credresolve-allow-metabase"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["3000"]
  }

  source_ranges = [var.private_subnet_cidr, var.public_subnet_cidr]
  target_tags   = ["metabase"]
  description   = "Allow Metabase UI port"
}

# Allow SSH from IAP (Google Identity-Aware Proxy) - no public SSH exposure
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "credresolve-allow-iap-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # IAP's IP range only — NOT 0.0.0.0/0
  source_ranges = ["35.235.240.0/20"]
  description   = "Allow SSH via IAP tunnel only"
}
