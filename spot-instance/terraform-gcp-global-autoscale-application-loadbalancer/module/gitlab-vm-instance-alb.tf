############################################ Reserver Internal IP Address for GCP VM Instance ###################################################

resource "google_compute_address" "instance_internal_ip" {
  count        = 2
  name         = "${var.prefix}-instance-internal-ip-${count.index + 1}"
  description  = "Internal IP address reserved for VM Instance"
  address_type = "INTERNAL"
  region       = var.gcp_region
  subnetwork   = google_compute_subnetwork.gcp_public_subnet.id
  address      = "172.20.0.${100 + count.index}"
}

################################################### Create Compute Engine VM instances ##########################################################

resource "google_compute_address" "vm_static_ip" {
  count        = 2
  name         = "gitlab-runner-static-ip-${count.index + 1}"
  address_type = "EXTERNAL"
  region       = var.gcp_region  # Replace with your desired region
  ip_version   = "IPV4"         # Default value is IPV4
}

#data "google_compute_zones" "available" {

#}

resource "google_compute_instance" "vm_instance" {
  count        = 2
  name         = count.index == 0 ? "gitlab-server" : "${var.prefix}-gitlab-runner"
  machine_type = count.index == 0 ? var.machine_type[3] : var.machine_type[2]
  zone         = data.google_compute_zones.available.names[count.index]
  boot_disk {
    initialize_params {
      image = "rocky-linux-9-v20260813"
      size  = 20
      type  = "pd-standard" ### Select among pd-standard, pd-balanced or pd-ssd.
      architecture = "X86_64"
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.gcp_public_subnet.id
    network_ip = google_compute_address.instance_internal_ip[count.index].address
    access_config {
      nat_ip = google_compute_address.vm_static_ip[count.index].address   ### Static IP Assigned to GCP VM Instance.
    }
  }
  service_account {
    email = google_service_account.costoptimization_sa.email
    scopes = ["cloud-platform"]
  }
  metadata_startup_script = count.index == 0 ? file("startup-gitlab-server.sh") : file("startup-gitlab-runner.sh")
  scheduling {
    preemptible                 = count.index == 0 ? false : true
    provisioning_model          = count.index == 0 ? "STANDARD" : "SPOT" 
    automatic_restart           = count.index == 0 ? true : false
    on_host_maintenance         = count.index == 0 ? "MIGRATE" : "TERMINATE"
  }

  tags = ["allow-ssh", "allow-health-check"]
}

resource "null_resource" "gitlab_server" {

  provisioner "remote-exec" {
    inline = [
         "sleep 150",
         "sudo firewall-cmd --permanent --add-service=http",
         "sudo firewall-cmd --permanent --add-service=https",
         "sudo firewall-cmd --permanent --add-service=ssh",
         "sudo systemctl reload firewalld",
         "sudo yum install -y policycoreutils-python-utils openssh-server openssh-clients perl",
         "curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh | sudo bash",
         "sudo EXTERNAL_URL=\"http://gitlab.singhritesh85.com\" yum install -y gitlab-ee",
###      "sudo gitlab-ctl reconfigure",  ### Need to run when you do changes in /etc/gitlab/gitlab.rb
         "sudo gitlab-ctl start",
         "sudo gitlab-ctl status",
    ]
  }
  connection {
    type = "ssh"
    host = google_compute_instance.vm_instance[0].network_interface[0].access_config[0].nat_ip
    user = "dexter"
    password = "Password@#795"
  }
  depends_on = [google_compute_instance.vm_instance[0]]
}

# URL Map
resource "google_compute_url_map" "gitlab_urlmap" {
  name        = "${var.prefix}-urlmap-gitlab"
  description = "${var.prefix} Routing Rules for GCP GitLab ALB"

  default_service = google_compute_backend_service.gcp_alb_backend_gitlab.id

  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }
  
  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.gcp_alb_backend_gitlab.id
  }

  test {
    service = google_compute_backend_service.gcp_alb_backend_gitlab.id
    host    = "gitlab.singhritesh85.com"
    path    = "/"
  }
}

resource "google_compute_url_map" "http_redirect_gitlab" {
  name = "${var.prefix}-http-redirect-gitlab"

  default_url_redirect {
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"  ### 301 redirect
    strip_query            = false
    https_redirect         = true  ### Redirection is happening 
  }
}

resource "google_compute_instance_group" "gitlab_server" {
  name        = "gitlab-server-instance-group"
  description = "Instance Group for GitLab Server"
  zone        = google_compute_instance.vm_instance[0].zone ### For GitLab-Server VM Instance  ###"us-central1-a"

  instances = [google_compute_instance.vm_instance[0].id]

  named_port {
    name = "gitlab-application"
    port = "80"
  }
}

resource "google_compute_backend_service" "gcp_alb_backend_gitlab" {
  name     = "${var.prefix}-backend-gitlab"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_instance_group.gitlab_server.id
  }

  health_checks = [google_compute_http_health_check.gcp_alb_health_check_gitlab.id]
  port_name     = "gitlab-application"  ### The same name should appear in the instance groups referenced by this service.

  log_config {
    enable          = true
    optional_mode   = "CUSTOM"
    optional_fields = [ "orca_load_report", "tls.protocol" ]
  }
}

resource "google_compute_http_health_check" "gcp_alb_health_check_gitlab" {
  name                = "${var.prefix}-healthcheck-gitlab"
  request_path        = "/users/sign_in"
  port                = 80
  check_interval_sec  = 5
  timeout_sec         = 3
  healthy_threshold   = 2
  unhealthy_threshold = 2 
}

resource "google_compute_global_address" "alb_static_ip_gitlab" {
  name         = "${var.prefix}-static-ip-gitlab"
  address_type = "EXTERNAL"
  description  = "Static IP for the GCP GitLab ALB"
}

resource "google_compute_global_forwarding_rule" "lb_frontend_https_gitlab" {
  name                  = "${var.prefix}-lb-frontend-https-gitlab"
  target                = google_compute_target_https_proxy.gcp_target_https_proxy_gitlab.id
  port_range            = "443"
  ip_protocol           = "TCP"
  ip_address            = google_compute_global_address.alb_static_ip_gitlab.address
  load_balancing_scheme = "EXTERNAL_MANAGED"
  network_tier          = "PREMIUM"
}

resource "google_compute_global_forwarding_rule" "lb_frontend_http_gitlab" {
  name                  = "${var.prefix}-lb-frontend-http-gitlab"
  target                = google_compute_target_http_proxy.gcp_target_http_proxy_gitlab.id
  port_range            = "80"
  ip_protocol           = "TCP"
  ip_address            = google_compute_global_address.alb_static_ip_gitlab.address
  load_balancing_scheme = "EXTERNAL_MANAGED"
  network_tier          = "PREMIUM"
}

resource "google_compute_target_https_proxy" "gcp_target_https_proxy_gitlab" {
  name             = "${var.prefix}-https-proxy-gitlab"
  url_map          = google_compute_url_map.gitlab_urlmap.id
  certificate_map  = "//certificatemanager.googleapis.com/${google_certificate_manager_certificate_map.gcp_certificate_map.id}"
}

resource "google_compute_target_http_proxy" "gcp_target_http_proxy_gitlab" {
  name             = "${var.prefix}-http-proxy-gitlab"
  url_map          = google_compute_url_map.http_redirect_gitlab.id
}
