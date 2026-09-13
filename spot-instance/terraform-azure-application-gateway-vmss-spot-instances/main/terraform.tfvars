################## Values of the Variables Used ######################
prefix = "vmss"
location = ["East US", "East US 2", "Central India", "Central US"]
subscription_id = "5XXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
tenant_id = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"

##################################### Parameters to create Azure VM #######################################

vm_count = 2
vm_size = ["Standard_B2s", "Standard_B2ms", "Standard_B4ms", "Standard_DS1_v2"]
disk_size_gb = 32
extra_disk_size_gb = 50
computer_name = "VM"
admin_username = "ritesh"
admin_password = "Password@#795"
static_dynamic = ["Static", "Dynamic"]
availability_zone = [1] ### Provide the Availability Zones into which the VM to be created.
env = ["dev", "stage", "prod"]
email_ids = "abc@abc.com"
