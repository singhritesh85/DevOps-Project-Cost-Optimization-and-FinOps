############################################### Parameters for Azure Resources to be created ##################################################

prefix = "multi-architecture"
subscription_id = "5XXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
tenant_id = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
location = ["East US", "East US 2", "Central India", "Central US"]
env = ["dev", "stage", "prod"]
static_dynamic = ["Static", "Dynamic"]
availability_zone = [1] ### Provide the Availability Zones into which the VM to be created.
kubernetes_version_aks = ["1.26.6", "1.26.10", "1.27.3", "1.27.7", "1.28.0", "1.28.3", "1.28.5", "1.29.0", "1.29.2", "1.30.0", "1.30.12", "1.31.8", "1.32.4", "1.33.0", "1.34.4", "1.35.5", "1.36.4"]
action_group_shortname = "aks-action"
email_address = "abc@gmail.com"  ### Provide Group Email Address on which notification should be send.
vm_size = ["Standard_B2s", "Standard_B2ms", "Standard_B4ms", "Standard_DS1_v2", "Standard_B2as_v2"]
admin_username = "ritesh"
admin_password = "Password@#795"
dns_zone_name = "singhritesh85.com"
