# ─────────────────────────────────────────────
# VIRTUAL PRIVATE GATEWAY (AWS VPN endpoint)
# ─────────────────────────────────────────────
resource "aws_vpn_gateway" "vgw" {
  vpc_id          = aws_vpc.main.id
  amazon_side_asn = 64512

  tags = {
    Name    = "${var.project_name}-vgw"
    Project = var.project_name
  }
}

# Enable VGW route propagation into private route table
resource "aws_vpn_gateway_route_propagation" "private" {
  vpn_gateway_id = aws_vpn_gateway.vgw.id
  route_table_id = aws_route_table.private.id
}

# ─────────────────────────────────────────────
# CUSTOMER GATEWAY (represents GCP side)
# Fill gcp_vpn_public_ip in tfvars after GCP VPN is created
# ─────────────────────────────────────────────
resource "aws_customer_gateway" "gcp" {
  bgp_asn    = 65000 # Match the ASN configured on GCP Cloud Router
  ip_address = var.gcp_vpn_public_ip
  type       = "ipsec.1"

  tags = {
    Name    = "gcp-customer-gateway"
    Project = var.project_name
  }
}

# ─────────────────────────────────────────────
# SITE-TO-SITE VPN CONNECTION
# ─────────────────────────────────────────────
resource "aws_vpn_connection" "gcp_tunnel" {
  vpn_gateway_id      = aws_vpn_gateway.vgw.id
  customer_gateway_id = aws_customer_gateway.gcp.id
  type                = "ipsec.1"
  static_routes_only  = false # Dynamic BGP routing

  tags = {
    Name    = "${var.project_name}-gcp-vpn"
    Project = var.project_name
  }
}

# ─────────────────────────────────────────────
# OUTPUTS — share tunnel config with GCP team
# ─────────────────────────────────────────────
output "vpn_tunnel1_address" {
  value       = aws_vpn_connection.gcp_tunnel.tunnel1_address
  description = "AWS VPN Tunnel 1 public IP — configure on GCP Cloud VPN"
}

output "vpn_tunnel2_address" {
  value       = aws_vpn_connection.gcp_tunnel.tunnel2_address
  description = "AWS VPN Tunnel 2 public IP — configure on GCP Cloud VPN"
}

output "vpn_tunnel1_preshared_key" {
  value       = aws_vpn_connection.gcp_tunnel.tunnel1_preshared_key
  sensitive   = true
  description = "Pre-shared key for Tunnel 1 — use in GCP VPN peer config"
}

output "vpn_tunnel2_preshared_key" {
  value       = aws_vpn_connection.gcp_tunnel.tunnel2_preshared_key
  sensitive   = true
  description = "Pre-shared key for Tunnel 2"
}
