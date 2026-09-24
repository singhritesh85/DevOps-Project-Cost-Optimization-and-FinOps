############################ Provide Parameters to create GCP Cloud DNS Zone ###################################

project_name = "XXXX-XXXXXXX-2XXXX6"  ### Provide the GCP Account Project ID.
gcp_region = ["us-east1", "us-central1", "asia-south2", "asia-south1", "us-west1"]
prefix = ["gitlab", "multi-architecture"]
ip_range_subnet = "10.10.0.0/20"
ip_public_range_subnet = "10.20.0.0/20"
ip_proxy_range_subnet = "10.20.16.0/20"
master_ip_range = "172.16.0.0/28"
pods_ip_range = "172.17.0.0/16"
services_ip_range = "172.19.0.0/16"
machine_type = ["n1-standard-1", "e2-small", "e2-medium", "e2-standard-2", "n2-standard-4", "c2-standard-4", "c3-standard-4", "t2d-standard-2", "c4a-standard-2", "t2d-standard-1", "t2a-standard-2"]
dns_name = "singhritesh85.com."
dns_zone_visibility = ["public", "private"]
enable_logging = ["true", "false"]
dnssec_state = ["on", "off"]
env  = ["dev", "stage", "prod"]
min_master_version = ["1.36.4", "1.35.6", "1.32.6", "1.30.12"] ###["v1.33.4-gke.1134000", "v1.32.4-gke.1415000", "v1.30.12-gke.1246000"]
node_version = ["1.36.4", "1.35.6", "1.32.6", "1.30.12"]       ###["v1.33.4-gke.1134000", "v1.32.4-gke.1415000", "v1.30.12-gke.1246000"]
