# Service Account in GCP
resource "google_service_account" "multiarchitecture_sa" {
  account_id   = "${var.prefix[0]}-sa"
  display_name = "${var.prefix[0]} Service Account"
}

resource "google_project_iam_member" "service_account_storage_permission" {
  project = var.project_name 
  role    = "roles/owner"   ###"roles/storage.admin"
  member  = "serviceAccount:${google_service_account.multiarchitecture_sa.email}"
}

############################################ Reserver Internal IP Address for GCP VM Instance ###################################################

resource "google_compute_address" "instance_internal_ip" {
  count        = 2
  name         = "${var.prefix[0]}-instance-internal-ip-${count.index + 1}"
  description  = "Internal IP address reserved for VM Instance"
  address_type = "INTERNAL"
  region       = var.gcp_region
  subnetwork   = google_compute_subnetwork.gcp_public_subnet.id 
  address      = "10.20.15.${100 + count.index}"
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
  name         = count.index == 0 ? "gitlab-server" : "${var.prefix[0]}-gitlab-runner"
  machine_type = count.index == 0 ? var.machine_type[7] : var.machine_type[9] 
  zone         = data.google_compute_zones.available.names[count.index]
  boot_disk {
    initialize_params {
      image = "rocky-linux-8-v20251215"
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
    email = google_service_account.multiarchitecture_sa.email
    scopes = ["cloud-platform"]
  }
  metadata_startup_script = count.index == 0 ? file("startup-gitlab-server.sh") : file("startup-gitlab-runner.sh")

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
