# Service Account in GCP
resource "google_service_account" "dexter_vm_sa" {
  account_id   = "${var.prefix[0]}-sa"
  display_name = "${var.prefix[0]} Service Account"
}

resource "google_project_iam_member" "service_account_storage_permission" {
  project = var.project_name 
  role    = "roles/owner"   ###"roles/storage.admin"
  member  = "serviceAccount:${google_service_account.dexter_vm_sa.email}"
}

############################################ Reserver Internal IP Address for GCP VM Instance ###################################################

resource "google_compute_address" "instance_internal_ip" {
  count        = 1
  name         = "${var.prefix[0]}-instance-internal-ip-${count.index + 1}"
  description  = "Internal IP address reserved for VM Instance"
  address_type = "INTERNAL"
  region       = var.gcp_region
  subnetwork   = google_compute_subnetwork.gcp_public_subnet.id 
  address      = "10.20.15.${100 + count.index}"
}

################################################### Create Compute Engine VM instances ##########################################################

resource "google_compute_address" "vm_static_ip" {
  count        = 1
  name         = "dexter-vm-static-ip-${count.index + 1}"
  address_type = "EXTERNAL"
  region       = var.gcp_region  # Replace with your desired region
  ip_version   = "IPV4"         # Default value is IPV4
}

data "google_compute_zones" "available" {

}

resource "google_compute_instance" "vm_instance" {
  count        = 1
  name         = "${var.prefix[0]}-dexter-server"
  machine_type = var.machine_type[7]   ### var.machine_type[2] ### e2-medium (2 vCPUs, 4 GB RAM) and e2-standard-8 (8 vCPUs, 32 GB RAM)
  zone         = data.google_compute_zones.available.names[count.index]
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "rocky-linux-8-v20260720"
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
    email = google_service_account.dexter_vm_sa.email
    scopes = ["cloud-platform"]
  }
  metadata_startup_script = file("startup.sh")
  tags = ["allow-ssh", "allow-http-https"]
}
