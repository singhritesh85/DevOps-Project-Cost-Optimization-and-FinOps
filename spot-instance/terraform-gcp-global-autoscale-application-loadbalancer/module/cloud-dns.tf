################################################# GCP Cloud DNS #############################################

resource "google_dns_managed_zone" "cloud_logging_enabled_zone" {
  name        = "public-hosted-zone-logging-enabled"
  dns_name    = var.dns_name
  description = "cloud logging enabled Public DNS zone"
  visibility  = var.dns_zone_visibility

  cloud_logging_config {
    enable_logging = var.enable_logging
  }

  dnssec_config {
    state = var.dnssec_state
  }

}

resource "google_dns_record_set" "gcp_dns_record" {
  name         = google_certificate_manager_dns_authorization.dns_authorization.dns_resource_record[0].name
  type         = google_certificate_manager_dns_authorization.dns_authorization.dns_resource_record[0].type
  ttl          = 300
  managed_zone = google_dns_managed_zone.cloud_logging_enabled_zone.name
  rrdatas      = [google_certificate_manager_dns_authorization.dns_authorization.dns_resource_record[0].data]
  depends_on   = [time_sleep.wait_150_seconds]
}

resource "google_dns_record_set" "a_record" {
  name         = "costoptimization.${google_dns_managed_zone.cloud_logging_enabled_zone.dns_name}"
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_global_address.alb_static_ip.address]
  managed_zone = google_dns_managed_zone.cloud_logging_enabled_zone.name

  depends_on = [google_compute_region_autoscaler.autoscaler]
}

resource "google_dns_record_set" "a_record_gitlab" {
  name         = "gitlab.${google_dns_managed_zone.cloud_logging_enabled_zone.dns_name}"
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_global_address.alb_static_ip_gitlab.address]
  managed_zone = google_dns_managed_zone.cloud_logging_enabled_zone.name

  depends_on = [google_compute_region_autoscaler.autoscaler]
}
