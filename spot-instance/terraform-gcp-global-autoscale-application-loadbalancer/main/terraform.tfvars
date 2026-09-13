################## Parameters for GCP to be used for the Project ######################

project_name = "XXXX-XXXXXXX-2XXXX6"  ### Provide the GCP Account Project ID. 

gcp_region = ["us-east1", "us-central1", "asia-south2", "asia-south1", "us-west1"]

prefix = "cost-optimization"

ip_range_subnet = "192.168.0.0/24"

ip_public_range_subnet = "172.20.0.0/24"

ip_proxy_range_subnet = "172.20.1.0/24"

machine_type = ["n1-standard-1", "e2-small", "e2-medium", "n2-standard-4", "c2-standard-4", "c3-standard-4"]

database_version = ["MYSQL_5_6", "MYSQL_5_7", "MYSQL_8_0", "MYSQL_8_4", "POSTGRES_11", "POSTGRES_12", "POSTGRES_13", "POSTGRES_14", "POSTGRES_15"]

tier = ["db-f1-micro", "db-n1-standard-1", "db-e2-small", "db-e2-medium", "db-n2-standard-4", "db-c2-standard-4", "db-c3-standard-4"]

env = [ "dev", "stage", "prod" ]

notification_email = "abc@gmail.com"

db_password = "Admin123"

############################### Prameters gor GCP Cloud DNS ###########################

dns_name = "singhritesh85.com."

dns_zone_visibility = ["public", "private"]

enable_logging = ["true", "false"]

dnssec_state = ["on", "off"]
