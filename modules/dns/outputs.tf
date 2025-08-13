output "dns_zone" {
  value       = google_dns_managed_zone.private_zone[*].name
  description = "Name of the private DNS zone"
}
