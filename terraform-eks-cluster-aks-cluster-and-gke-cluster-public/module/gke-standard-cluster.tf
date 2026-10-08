###################################################### Create Service Account #####################################################

resource "google_service_account" "awx_gke_sa" {
  account_id   = "${var.prefix}-gke-sa"
  display_name = "${var.prefix} Service Account"
}

resource "google_project_iam_binding" "awx_gke_sa_role" {
  project = var.project_name  ### Project ID for your Google Account
  role    = "roles/artifactregistry.reader"
  members = [
    "serviceAccount:${google_service_account.awx_gke_sa.email}",
  ]
}

resource "google_project_iam_binding" "awx_gke_sa_role_defaultnode" {
  project = var.project_name  ### Project ID for your Google Account
  role    = "roles/container.defaultNodeServiceAccount"
  members = [
    "serviceAccount:${google_service_account.awx_gke_sa.email}",
  ]
}

resource "google_project_iam_binding" "awx_gke_sa_role_container_admin" {
  project = var.project_name  ### Project ID for your Google Account
  role    = "roles/container.admin"
  members = [
    "serviceAccount:${google_service_account.awx_gke_sa.email}",
  ]
}

resource "google_project_iam_binding" "awx_gke_sa_role_monitoring_viewer" {
  project = var.project_name  ### Project ID for your Google Account
  role    = "roles/monitoring.viewer"
  members = [
    "serviceAccount:${google_service_account.awx_gke_sa.email}",
  ]
}

resource "google_project_iam_binding" "awx_gke_sa_role_log_viewer" {
  project = var.project_name  ### Project ID for your Google Account
  role    = "roles/logging.viewer"
  members = [
    "serviceAccount:${google_service_account.awx_gke_sa.email}",
  ]
}

resource "google_project_iam_binding" "awx_gke_sa_role_log_writer" {    ### will be used for Google Cloud Operations (Ops) Agent in a GKE cluster
  project = var.project_name  ### Project ID for your Google Account
  role    = "roles/logging.logWriter"
  members = [
    "serviceAccount:${google_service_account.awx_gke_sa.email}",
  ]
}

resource "google_project_iam_binding" "awx_gke_sa_role_monitoring_writer" {   ### will be used for Google Cloud Operations (Ops) Agent in a GKE cluster
  project = var.project_name  ### Project ID for your Google Account
  role    = "roles/monitoring.metricWriter"
  members = [
    "serviceAccount:${google_service_account.awx_gke_sa.email}",
  ]
}

resource "google_project_iam_binding" "awx_gke_sa_role_cluster_viewer" {   ### will be used for Google Cloud Operations (Ops) Agent in a GKE cluster
  project = var.project_name  ### Project ID for your Google Account
  role    = "roles/container.clusterViewer"
  members = [
    "serviceAccount:${google_service_account.awx_gke_sa.email}",
  ]
}

########################################################### GKE Cluster ############################################################

data "google_compute_zones" "available" {

}

resource "google_container_cluster" "gke_cluster" {
  name     = "${var.prefix}-gke-cluster"
  location = var.gcp_region

  node_locations = data.google_compute_zones.available.names   ###["us-central1-a", "us-central1-c"]

  min_master_version = var.min_master_version
  remove_default_node_pool = true   ### Delete default node pool after its creation
  initial_node_count       = 1
  datapath_provider = "ADVANCED_DATAPATH"
  in_transit_encryption_config = "IN_TRANSIT_ENCRYPTION_INTER_NODE_TRANSPARENT"

  network = google_compute_network.gke_vpc.id
  subnetwork = google_compute_subnetwork.gke_subnet.id

  deletion_protection = false       ### You can change it to true
  vertical_pod_autoscaling {
    enabled = true
  }
  workload_identity_config {
    workload_pool = "${var.project_name}.svc.id.goog"
  }
  gateway_api_config {
    channel = "CHANNEL_STANDARD"
  }
  release_channel {
    channel = "REGULAR"
  }

  # Private Cluster Configurations
  private_cluster_config {
    enable_private_endpoint = false  ### To enable private endpoint
    enable_private_nodes    = true  ### To enable private nodes
    master_ipv4_cidr_block  = var.master_ip_range
  }

  # IP Address Ranges
  ip_allocation_policy {
    cluster_secondary_range_name = google_compute_subnetwork.gke_subnet.secondary_ip_range[0].range_name
    services_secondary_range_name = google_compute_subnetwork.gke_subnet.secondary_ip_range[1].range_name
  }

  # Allow access to Kubernetes master API Endpoint
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block = "0.0.0.0/0"
      display_name = "Public Access"
    }
  }

  maintenance_policy {

    recurring_window {
      start_time = "2025-07-05T06:30:00Z"
      end_time   = "2025-07-05T13:30:00Z"
      recurrence = "FREQ=WEEKLY;BYDAY=SA,SU"
    }
  }

  dns_config {
    cluster_dns      = "CLOUD_DNS"
    cluster_dns_scope = "CLUSTER_SCOPE"
  }

  addons_config {
    horizontal_pod_autoscaling {
      disabled = false            ### Enabled by default
    }
    http_load_balancing {
      disabled = false            ### Enabled by default
    }
    gcp_filestore_csi_driver_config {
      enabled = true
    }
    gcs_fuse_csi_driver_config {
      enabled = true
    }
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
    gke_backup_agent_config {
      enabled = true
    }
  }

#  logging_service    = "logging.googleapis.com/kubernetes"
#  monitoring_service = "monitoring.googleapis.com/kubernetes"
#  enable_intranode_visibility = true

  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "APISERVER", "CONTROLLER_MANAGER", "SCHEDULER", "WORKLOADS"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS", "APISERVER", "SCHEDULER", "CONTROLLER_MANAGER", "STORAGE", "HPA", "POD", "DAEMONSET", "DEPLOYMENT", "STATEFULSET", "KUBELET", "CADVISOR", "DCGM", "JOBSET"]

    managed_prometheus {
      enabled = true
    }

    advanced_datapath_observability_config {
      enable_metrics = true
      enable_relay   = true
    }
  }

}

#################################################### GKE Linux Node Pool ####################################################################

resource "google_container_node_pool" "gke_linux_nodepool" {
  count      = 2
  name       = count.index == 0 ? "linux-spot-amd64-nodepool" : "linux-axion-arm64-nodepool"
  location   = var.gcp_region
  node_locations = data.google_compute_zones.available.names   ###["us-central1-a", "us-central1-c"]
  cluster    = google_container_cluster.gke_cluster.name
  version    = var.node_version
  initial_node_count = 1   ### Initial number of nodes to be created in the node pool.
  autoscaling {
    min_node_count = 2
    max_node_count = 4
    location_policy = "BALANCED"    ### Select between ANY and BALANCED.
  }
  node_config {
    spot         = count.index == 0 ? true : false         ### Use Spot GCP VM Instances for AMD64 Processor.
    machine_type = count.index == 0 ? var.machine_type[7] : var.machine_type[8]
    service_account = google_service_account.awx_gke_sa.email  ###Custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    disk_size_gb = 50
    disk_type = count.index == 0 ? "pd-standard" : "hyperdisk-balanced" ### Supported pd-standard, pd-balanced or pd-ssd, default is pd-balanced. However I am using pd-standard because it is cheaper.   
  }
  network_config {
    enable_private_nodes = true
  }

  management {
    auto_repair  = true  ### Auto Repair is Enabled by Default.
    auto_upgrade = true  ### Auto Upgrade is Enabled by Default.
  }

  upgrade_settings {
    max_surge      = 1 # Number of new nodes can be created above the desired node count during the upgrade
    max_unavailable = 0 # Number of nodes can be unavailable during the upgrade
  }

  lifecycle {
    create_before_destroy = true
  }
}

##################################### Create Kubeconfig file ##########################################

resource "null_resource" "gke_kubectl" {
    provisioner "local-exec" {
        command = "gcloud container clusters get-credentials ${google_container_cluster.gke_cluster.name} --region ${google_container_cluster.gke_cluster.location} --project ${var.project_name} && chmod 600 ~/.kube/config"
    }

    depends_on = [google_container_cluster.gke_cluster, google_container_node_pool.gke_linux_nodepool]
}
