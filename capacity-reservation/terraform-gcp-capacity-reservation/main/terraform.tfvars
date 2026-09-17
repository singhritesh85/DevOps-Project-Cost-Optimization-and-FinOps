############################ Provide Parameters to create GCP Cloud DNS Zone ###################################

project_name = "XXXX-XXXXXXX-2XXXX6"  ### Provide the GCP Account Project ID.
gcp_region = ["us-east1", "us-central1", "asia-south2", "asia-south1", "us-west1"]
prefix = ["gcp"]
ip_range_subnet = "10.10.0.0/20"
ip_public_range_subnet = "10.20.0.0/20"
machine_type = ["n1-standard-1", "e2-small", "e2-medium", "e2-standard-2", "n2-standard-4", "c2-standard-4", "c3-standard-4", "e2-standard-8"]
env  = ["dev", "stage", "prod"]
