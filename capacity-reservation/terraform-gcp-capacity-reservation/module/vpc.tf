############################## Create VPC in GCP #######################################

# Create VPC in GCP
resource "google_compute_network" "gcp_vpc" {
  name = "${var.prefix[0]}-vpc"
  auto_create_subnetworks = false   
}

# Create Private Subnet for VPC in GCP
resource "google_compute_subnetwork" "gcp_private_subnet" {
  name = "${var.prefix[0]}-${var.gcp_region}-private-subnet"
  region = var.gcp_region
  network = google_compute_network.gcp_vpc.id 
  private_ip_google_access = true           ### VMs in this Subnet without external IP
  ip_cidr_range = var.ip_range_subnet
}

# Create Public Subnet for VPC in GCP
resource "google_compute_subnetwork" "gcp_public_subnet" {
  name = "${var.prefix[0]}-${var.gcp_region}-public-subnet"
  region = var.gcp_region
  network = google_compute_network.gcp_vpc.id
  private_ip_google_access = false           ### VMs in this Subnet with external IP
  ip_cidr_range = var.ip_public_range_subnet
}

######################################################### Firewall Rule for SSH ################################################################

resource "google_compute_firewall" "allow_port_22" {
  name    = "allow-ssh-ingress"
  network = google_compute_network.gcp_vpc.id  # Replace with your VPC network name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-ssh"] # Replace with your desired target tag
}

######################################################### Firewall Rule for HTTPS ################################################################

resource "google_compute_firewall" "allow_port_443" {
  name    = "allow-http-https-ingress"
  network = google_compute_network.gcp_vpc.id  # Replace with your VPC network name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-http-https"] # Replace with your desired target tag
}
