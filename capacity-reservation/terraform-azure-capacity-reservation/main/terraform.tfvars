############################################### Parameters for Azure Resources to be created ##################################################

prefix = "azure"
subscription_id = "5XXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
tenant_id = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
location = ["East US", "East US 2", "Central India", "Central US"]
env = ["dev", "stage", "prod"]
static_dynamic = ["Static", "Dynamic"]
availability_zone = [1] ### Provide the Availability Zones into which the VM to be created.
vm_size = ["Standard_B2s", "Standard_B2ms", "Standard_B4ms", "Standard_DS1_v2", "Standard_D2s_v3", "Standard_F8s_v2"]
admin_username = "ritesh"
admin_password = "Password@#795"
