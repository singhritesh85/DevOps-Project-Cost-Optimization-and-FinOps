#!/bin/bash

# -----------------------------
# Configuration
# -----------------------------
EMAIL_TO="abc@gmail.com"
EMAIL_FROM="DevOps Team <devopsteam@explicate-devops.com>"
SUBJECT="Azure Tenant-Wide Non-Prod Backup and Delete Summary"
LOG_FILE="/tmp/azure_backup_delete_summary.log"

# Centralized Gallery & Storage Infrastructure Configuration
GALLERY_RG="rg-shared-infrastructure"
GALLERY_NAME="NonProdSharedGallery"
GALLERY_LOCATION="indiasouthcentral"
OS_TYPE="Linux"

STORAGE_RG="rg-shared-infrastructure"
STORAGE_ACCOUNT_NAME="nonprodmysqlbak$(date +%s | cut -c7-12)"
STORAGE_CONTAINER_NAME="mysql-backups"
STORAGE_LOCATION="indiasouthcentral"

# -----------------------------
# Clear previous log
# -----------------------------
> "$LOG_FILE"

# -----------------------------
# Time
# -----------------------------
TIME_DISPLAY=$(TZ="Asia/Kolkata" date "+%I:%M %p")
TIME=$(TZ="Asia/Kolkata" date +%H%M)

# ============================================================
# Run only between 8:00 PM and 7:30 AM IST
# ============================================================
if [ "$TIME" -ge 1300 ] || [ "$TIME" -lt 0730 ]; then

    {
        echo "AZURE TENANT-WIDE NON-PROD BACKUP AND DELETE EXECUTION LOG"
        echo "======================================================"
        echo "Execution Time : $(date)"
        echo "IST Time       : $TIME_DISPLAY"
        echo "Action         : Tenant-Wide Dynamic Gallery Image / MySQL Backup & Delete"
        echo "======================================================"
        echo ""
    } >> "$LOG_FILE"

    # ========================================================
    # Fetch All Accessible Subscriptions in the Tenant
    # ========================================================
    SUBSCRIPTIONS=$(az account list --query "[?state=='Enabled'].id" --output tsv)

    if [ -z "$SUBSCRIPTIONS" ]; then
        echo "CRITICAL ERROR: No enabled Azure subscriptions found or not logged in." >> "$LOG_FILE"
        exit 1
    fi

    for SUB_ID in $SUBSCRIPTIONS; do
        echo "====================================================" >> "$LOG_FILE"
        echo "Processing Subscription ID: $SUB_ID" >> "$LOG_FILE"
        echo "====================================================" >> "$LOG_FILE"

        # Switch context to the current subscription
        az account set --subscription "$SUB_ID" >> "$LOG_FILE" 2>&1

        # ====================================================
        # 1. HANDLE VIRTUAL MACHINES (TENANT-WIDE & MULTI-REGION)
        # ====================================================
        VM_DATA=$(az vm list -d --query "[?tags.Environment=='non-prod' && powerState=='VM running'].[id, name, resourceGroup, location]" --output tsv 2>> "$LOG_FILE")

        if [ -n "$VM_DATA" ]; then
            echo "$VM_DATA" | while read -r VM_ID VM_NAME RESOURCE_GROUP VM_LOCATION; do
                [ -z "$VM_ID" ] && continue
                [ -z "$VM_NAME" ] || [ "$VM_NAME" = "None" ] && VM_NAME="Unnamed"
                [ -z "$VM_LOCATION" ] && VM_LOCATION="$GALLERY_LOCATION"

                {
                    echo ""
                    echo "------------------------------------------------------"
                    echo "Virtual Machine Backup (Sub: $SUB_ID)"
                    echo "VM Name       : $VM_NAME"
                    echo "Resource Group: $RESOURCE_GROUP"
                    echo "VM Location   : $VM_LOCATION"
                    echo "------------------------------------------------------"
                } >> "$LOG_FILE"

                IMAGE_VERSION="$(date +%Y).$(date +%-m%-d).$(date +%-H%-M)"

                # Extract VM properties
                PUB=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query "storageProfile.imageReference.publisher" --output tsv 2>> "$LOG_FILE")
                OFFER=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query "storageProfile.imageReference.offer" --output tsv 2>> "$LOG_FILE")
                SKU=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query "storageProfile.imageReference.sku" --output tsv 2>> "$LOG_FILE")

                HYPERV_GEN=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query "storageProfile.osDisk.hyperVGeneration" --output tsv 2>> "$LOG_FILE")
                [ -z "$HYPERV_GEN" ] || [ "$HYPERV_GEN" = "None" ] && HYPERV_GEN=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query "hyperVGeneration" --output tsv 2>> "$LOG_FILE")
                [ -z "$HYPERV_GEN" ] || [ "$HYPERV_GEN" = "None" ] && HYPERV_GEN="V2"

                PLAN_PUB=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query "plan.publisher" --output tsv 2>> "$LOG_FILE")
                PLAN_PROD=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query "plan.product" --output tsv 2>> "$LOG_FILE")
                PLAN_NAME=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query "plan.name" --output tsv 2>> "$LOG_FILE")

                # Capture attached NIC IDs before deletion
                NIC_IDS=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query "networkProfile.networkInterfaces[].id" --output tsv 2>> "$LOG_FILE")

                # Ensure centralized gallery RG and Gallery exist
                if ! az group show --name "$GALLERY_RG" --output none &> /dev/null; then
                    az group create --name "$GALLERY_RG" --location "$GALLERY_LOCATION" --output none >> "$LOG_FILE" 2>&1
                fi
                if ! az sig show --resource-group "$GALLERY_RG" --gallery-name "$GALLERY_NAME" --output none &> /dev/null; then
                    az sig create --resource-group "$GALLERY_RG" --gallery-name "$GALLERY_NAME" --location "$GALLERY_LOCATION" --output none >> "$LOG_FILE" 2>&1
                fi

                # Check if an Image Definition matching publisher/offer/sku already exists globally in the gallery
                EXISTING_DEF=$(az sig image-definition list --resource-group "$GALLERY_RG" --gallery-name "$GALLERY_NAME" --query "[?identifier.publisher=='$PUB' && identifier.offer=='$OFFER' && identifier.sku=='$SKU'].name | [0]" --output tsv 2>> "$LOG_FILE")

                if [ -n "$EXISTING_DEF" ] && [ "$EXISTING_DEF" != "None" ]; then
                    IMAGE_DEF_NAME="$EXISTING_DEF"
                    echo "Found existing matching Image Definition: $IMAGE_DEF_NAME" >> "$LOG_FILE"
                else
                    CLEAN_OFFER=$(echo "$OFFER" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
                    CLEAN_SKU=$(echo "$SKU" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
                    IMAGE_DEF_NAME="${CLEAN_OFFER}-${CLEAN_SKU}-def"

                    echo "Creating Image Definition '$IMAGE_DEF_NAME' in location '$GALLERY_LOCATION'..." >> "$LOG_FILE"
                    if [ -n "$PLAN_PUB" ] && [ "$PLAN_PUB" != "None" ]; then
                        az sig image-definition create --resource-group "$GALLERY_RG" --gallery-name "$GALLERY_NAME" --gallery-image-definition "$IMAGE_DEF_NAME" --publisher "$PUB" --offer "$OFFER" --sku "$SKU" --os-type "$OS_TYPE" --os-state "Specialized" --hyper-v-generation "$HYPERV_GEN" --location "$GALLERY_LOCATION" --plan-publisher "$PLAN_PUB" --plan-product "$PLAN_PROD" --plan-name "$PLAN_NAME" --output none >> "$LOG_FILE" 2>&1
                    else
                        az sig image-definition create --resource-group "$GALLERY_RG" --gallery-name "$GALLERY_NAME" --gallery-image-definition "$IMAGE_DEF_NAME" --publisher "$PUB" --offer "$OFFER" --sku "$SKU" --os-type "$OS_TYPE" --os-state "Specialized" --hyper-v-generation "$HYPERV_GEN" --location "$GALLERY_LOCATION" --output none >> "$LOG_FILE" 2>&1
                    fi
                fi

                # Deallocate and Wait
                echo "Deallocating VM: $VM_NAME..." >> "$LOG_FILE"
                az vm deallocate --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --no-wait --output none >> "$LOG_FILE" 2>&1
                az vm wait --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --custom "powerState == 'VM deallocated'" --timeout 300 2>> "$LOG_FILE"

                # Create Image Version aligned with the VM's exact region
                echo "Creating Specialized Image Version '$IMAGE_VERSION' for VM: $VM_NAME in region $VM_LOCATION..." >> "$LOG_FILE"
                az sig image-version create --resource-group "$GALLERY_RG" --gallery-name "$GALLERY_NAME" --gallery-image-definition "$IMAGE_DEF_NAME" --gallery-image-version "$IMAGE_VERSION" --virtual-machine "$VM_ID" --location "$VM_LOCATION" --target-regions "$VM_LOCATION" --output none >> "$LOG_FILE" 2>&1

                if [ $? -ne 0 ]; then
                    echo "CRITICAL ERROR: Failed to create Compute Gallery Image Version for $VM_NAME. SKIPPING DELETION." >> "$LOG_FILE"
                    continue
                fi

                echo "SUCCESS: Compute Gallery Image Version created successfully: $IMAGE_VERSION" >> "$LOG_FILE"

                # Delete VM and associated networking artifacts (NIC, Public IP, NSG)
                echo "Deleting Azure VM: $VM_NAME" >> "$LOG_FILE"
                az vm delete --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --yes --force-deletion --output none >> "$LOG_FILE" 2>&1
                if [ $? -eq 0 ]; then
                    echo "SUCCESS: VM $VM_NAME deleted." >> "$LOG_FILE"

                    for NIC_ID in $NIC_IDS; do
                        [ -z "$NIC_ID" ] && continue
                        NIC_NAME=$(basename "$NIC_ID")

                        # Check for Public IP associated via IP Configuration
                        PIP_ID=$(az network nic show --resource-group "$RESOURCE_GROUP" --name "$NIC_NAME" --query "ipConfigurations[0].publicIpAddress.id" --output tsv 2>> "$LOG_FILE")
                        NSG_ID=$(az network nic show --resource-group "$RESOURCE_GROUP" --name "$NIC_NAME" --query "networkSecurityGroup.id" --output tsv 2>> "$LOG_FILE")

                        echo "Deleting Network Interface: $NIC_NAME" >> "$LOG_FILE"
                        az network nic delete --resource-group "$RESOURCE_GROUP" --name "$NIC_NAME" --output none >> "$LOG_FILE" 2>&1

                        if [ -n "$PIP_ID" ] && [ "$PIP_ID" != "None" ]; then
                            PIP_NAME=$(basename "$PIP_ID")
                            echo "Deleting associated Public IP: $PIP_NAME" >> "$LOG_FILE"
                            az network public-ip delete --resource-group "$RESOURCE_GROUP" --name "$PIP_NAME" --output none >> "$LOG_FILE" 2>&1
                        fi

                        if [ -n "$NSG_ID" ] && [ "$NSG_ID" != "None" ]; then
                            NSG_NAME=$(basename "$NSG_ID")
                            echo "Deleting orphaned Network Security Group: $NSG_NAME" >> "$LOG_FILE"
                            az network nsg delete --resource-group "$RESOURCE_GROUP" --name "$NSG_NAME" --output none >> "$LOG_FILE" 2>&1
                        fi
                    done

                    # Additional sweep for any orphaned Public IPs in the same resource group matching non-prod tags or naming conventions if needed
                    ORPHANED_PIPS=$(az network public-ip list --resource-group "$RESOURCE_GROUP" --query "[?ipConfiguration == null].name" --output tsv 2>> "$LOG_FILE")
                    for OP_PIP in $ORPHANED_PIPS; do
                        [ -z "$OP_PIP" ] && continue
                        echo "Deleting orphaned unattached Public IP: $OP_PIP" >> "$LOG_FILE"
                        az network public-ip delete --resource-group "$RESOURCE_GROUP" --name "$OP_PIP" --output none >> "$LOG_FILE" 2>&1
                    done

                else
                    echo "ERROR: Failed to delete VM $VM_NAME." >> "$LOG_FILE"
                fi
            done
        else
            echo "No running non-prod Virtual Machines found in subscription $SUB_ID." >> "$LOG_FILE"
        fi

        # ====================================================
        # 2. HANDLE MYSQL FLEXIBLE SERVERS (TENANT-WIDE & MULTI-REGION)
        # ====================================================
        MYSQL_DATA=$(az mysql flexible-server list --query "[?tags.Environment=='non-prod' && state=='Ready'].[name, resourceGroup]" --output tsv 2>> "$LOG_FILE")

        if [ -n "$MYSQL_DATA" ]; then
            if ! az group show --name "$STORAGE_RG" --output none &> /dev/null; then
                az group create --name "$STORAGE_RG" --location "$STORAGE_LOCATION" --output none >> "$LOG_FILE" 2>&1
            fi
            if ! az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$STORAGE_RG" --output none &> /dev/null; then
                az storage account create --name "$STORAGE_ACCOUNT_NAME" --resource-group "$STORAGE_RG" --location "$STORAGE_LOCATION" --sku Standard_LRS --kind StorageV2 --output none >> "$LOG_FILE" 2>&1
            fi
            STORAGE_KEY=$(az storage account keys list --resource-group "$STORAGE_RG" --account-name "$STORAGE_ACCOUNT_NAME" --query "[0].value" --output tsv 2>> "$LOG_FILE")
            az storage container create --name "$STORAGE_CONTAINER_NAME" --account-name "$STORAGE_ACCOUNT_NAME" --account-key "$STORAGE_KEY" --auth-mode key --public-access off --output none >> "$LOG_FILE" 2>&1

            echo "$MYSQL_DATA" | while read -r MYSQL_NAME RESOURCE_GROUP; do
                [ -z "$MYSQL_NAME" ] && continue

                {
                    echo ""
                    echo "------------------------------------------------------"
                    echo "MySQL Backup (Sub: $SUB_ID)"
                    echo "Server Name   : $MYSQL_NAME"
                    echo "Resource Group: $RESOURCE_GROUP"
                    echo "------------------------------------------------------"
                } >> "$LOG_FILE"

                MYSQL_FQDN=$(az mysql flexible-server show --resource-group "$RESOURCE_GROUP" --name "$MYSQL_NAME" --query "fullyQualifiedDomainName" --output tsv 2>> "$LOG_FILE")
                MYSQL_USER=$(az mysql flexible-server show --resource-group "$RESOURCE_GROUP" --name "$MYSQL_NAME" --query "administratorLogin" --output tsv 2>> "$LOG_FILE")

                BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
                BACKUP_DIR="/tmp/mysql_backup_${MYSQL_NAME}_${BACKUP_TIMESTAMP}"
                mkdir -p "$BACKUP_DIR"

                if ! command -v mydumper &> /dev/null; then
                    sudo yum install -y epel-release wget glib2 pcre zlib zstd >> "$LOG_FILE" 2>&1
                    MYDUMPER_RPM="mydumper-1.0.5-1.el8.x86_64.rpm"
                    wget -q "https://github.com/mydumper/mydumper/releases/download/v1.0.5-1/$MYDUMPER_RPM" -O "/tmp/$MYDUMPER_RPM" >> "$LOG_FILE" 2>&1
                    sudo yum localinstall -y "/tmp/$MYDUMPER_RPM" >> "$LOG_FILE" 2>&1
                    rm -f "/tmp/$MYDUMPER_RPM"
                fi

                DYNAMIC_PASSWORD="P@ssw0rd$(date +%s)"
                az mysql flexible-server update --resource-group "$RESOURCE_GROUP" --name "$MYSQL_NAME" --admin-password "$DYNAMIC_PASSWORD" --output none >> "$LOG_FILE" 2>&1

                mydumper -h "$MYSQL_FQDN" -u "$MYSQL_USER" -p "$DYNAMIC_PASSWORD" -o "$BACKUP_DIR" --compress --skip-ddl-locks --trx-tables=0 --regex '^(?!(mysql|information_schema|performance_schema|sys))' >> "$LOG_FILE" 2>&1

                if [ $? -eq 0 ]; then
                    TARBALL="/tmp/${MYSQL_NAME}_${BACKUP_TIMESTAMP}.tar.gz"
                    tar -zcvf "$TARBALL" -C "$BACKUP_DIR" . >> "$LOG_FILE" 2>&1
                    az storage blob upload --account-name "$STORAGE_ACCOUNT_NAME" --account-key "$STORAGE_KEY" --container-name "$STORAGE_CONTAINER_NAME" --file "$TARBALL" --name "$(basename "$TARBALL")" --output none >> "$LOG_FILE" 2>&1
                    rm -rf "$BACKUP_DIR" "$TARBALL"
                else
                    echo "CRITICAL ERROR: Mydumper failed. SKIPPING DELETION of $MYSQL_NAME." >> "$LOG_FILE"
                    rm -rf "$BACKUP_DIR"
                    continue
                fi

                echo "Deleting MySQL Flexible Server: $MYSQL_NAME" >> "$LOG_FILE"
                az mysql flexible-server delete --resource-group "$RESOURCE_GROUP" --name "$MYSQL_NAME" --yes --output none >> "$LOG_FILE" 2>&1
            done
        else
            echo "No available non-prod MySQL Flexible Servers found in subscription $SUB_ID." >> "$LOG_FILE"
        fi

    done

    # ========================================================
    # Email Summary
    # ========================================================
    echo "Sending email summary to $EMAIL_TO..."
    if command -v mail &> /dev/null; then
        mail -r "$EMAIL_FROM" -s "$SUBJECT" "$EMAIL_TO" < "$LOG_FILE"
        if [ $? -eq 0 ]; then
            echo "Email sent successfully to $EMAIL_TO"
        else
            echo "ERROR: Failed to send email."
        fi
    else
        echo "Error: The 'mail' command was not found on this system." >> "$LOG_FILE"
    fi

else
    echo "IST time is $TIME_DISPLAY. Working hours - nothing to do."
fi
