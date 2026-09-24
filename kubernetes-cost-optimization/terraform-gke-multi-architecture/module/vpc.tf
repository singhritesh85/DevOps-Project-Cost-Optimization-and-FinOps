############################## Create VPC in GCP #######################################

# Create VPC in GCP
resource "google_compute_network" "gcp_vpc" {
  name = "${var.prefix[1]}-vpc"
  auto_create_subnetworks = false   
}

# Create Private Subnet for VPC in GCP
resource "google_compute_subnetwork" "gcp_private_subnet" {
  name = "${var.prefix[1]}-${var.gcp_region}-private-subnet"
  region = var.gcp_region
  network = google_compute_network.gcp_vpc.id 
  private_ip_google_access = true           ### VMs in this Subnet without external IP
  ip_cidr_range = var.ip_range_subnet
  secondary_ip_range {
    range_name    = "secondary-ip-range-for-pods"
    ip_cidr_range = var.pods_ip_range
  }
  secondary_ip_range {
    range_name    = "secondary-ip-range-for-service"
    ip_cidr_range = var.services_ip_range
  }
}

# Create Public Subnet for VPC in GCP
resource "google_compute_subnetwork" "gcp_public_subnet" {
  name = "${var.prefix[1]}-${var.gcp_region}-public-subnet"
  region = var.gcp_region
  network = google_compute_network.gcp_vpc.id
  private_ip_google_access = false           ### VMs in this Subnet with external IP
  ip_cidr_range = var.ip_public_range_subnet
}

# proxy-only subnet
resource "google_compute_subnetwork" "gcp_proxy_subnet" {
  name          = "gitlab-proxy-subnet"
  ip_cidr_range = var.ip_proxy_range_subnet
  region        = var.gcp_region
  purpose       = "REGIONAL_MANAGED_PROXY"  ### "GLOBAL_MANAGED_PROXY"
  role          = "ACTIVE"
  network       = google_compute_network.gcp_vpc.id
}

# GCP NAT Router
resource "google_compute_router" "nat_router" {
  name    = "${var.prefix[1]}-nat-router"
  region  = var.gcp_region
  network = google_compute_network.gcp_vpc.name
}

# GCP Cloud NAT
resource "google_compute_router_nat" "nat_gateway" {
  name                          = "${var.prefix[1]}-nat-gateway"
  router                        = google_compute_router.nat_router.name
  region                        = google_compute_router.nat_router.region
  nat_ip_allocate_option        = "AUTO_ONLY" ### "MANUAL_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.gcp_private_subnet.name
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
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
  name    = "allow-https-ingress"
  network = google_compute_network.gcp_vpc.id  # Replace with your VPC network name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-https"] # Replace with your desired target tag
}

######################################################## Firewall Rule to allow health check ######################################################

resource "google_compute_firewall" "allow_health_check" {
  name          = "allow-health-check"
  direction     = "INGRESS"
  network       = google_compute_network.gcp_vpc.id
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]  ### Google uses specific IP ranges for its health check probes.
  allow {
    protocol = "tcp"
  }
  target_tags = ["allow-health-check"]
}

