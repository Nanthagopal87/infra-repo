resource "google_dns_managed_zone" "private_zone" {
  count       = var.enabled ? 1 : 0
  name        = var.name
  dns_name    = var.dns_name
  description = "Private DNS zone for ${var.name}"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = var.network
    }
  }
}
