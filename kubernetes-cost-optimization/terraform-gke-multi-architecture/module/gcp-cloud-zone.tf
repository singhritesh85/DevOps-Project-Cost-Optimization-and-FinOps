################################# GCP Cloud Zone #########################################

resource "google_dns_managed_zone" "dexter_public_zone" {
  name        = "${var.prefix[0]}-public-zone"
  dns_name    = var.dns_name
  description = "Public"
  visibility  = var.dns_zone_visibility

  cloud_logging_config {
    enable_logging = var.enable_logging
  }

  dnssec_config {
    state = var.dnssec_state
  }
}

##### Introduced a time sleep of 150 seconds to do the GCP DNS Nameserver entry in your domain name provider's nameserver ##### 
resource "time_sleep" "wait_150_seconds" {
  depends_on = [google_dns_managed_zone.dexter_public_zone]
  create_duration = "150s"
}

resource "google_dns_record_set" "gcp_dns_record" {
  name         = google_certificate_manager_dns_authorization.dns_authorization.dns_resource_record[0].name
  type         = google_certificate_manager_dns_authorization.dns_authorization.dns_resource_record[0].type
  ttl          = 300
  managed_zone = google_dns_managed_zone.dexter_public_zone.name
  rrdatas      = [google_certificate_manager_dns_authorization.dns_authorization.dns_resource_record[0].data]
  depends_on   = [time_sleep.wait_150_seconds]
}

resource "google_dns_record_set" "a_record" {
  name         = "gitlab.${google_dns_managed_zone.dexter_public_zone.dns_name}"
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_global_address.alb_static_ip.address]
  managed_zone = google_dns_managed_zone.dexter_public_zone.name

  depends_on = [null_resource.gitlab_server]
}
