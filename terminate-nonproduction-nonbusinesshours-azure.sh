#!/bin/bash

# -----------------------------
# Configuration
# -----------------------------
EMAIL_TO="abc@gmail.com"
EMAIL_FROM="DevOps Team <devopsteam@explicate-devops.com>"
SUBJECT="Azure Non-Prod Backup and Delete Summary"
LOG_FILE="/tmp/azure_backup_delete_summary.log"

# Azure Compute Gallery Configuration
GALLERY_RG="rg-shared-infrastructure"   ### Resource group where your gallery lives
GALLERY_NAME="NonProdSharedGallery"     ### Name of your Azure Compute Gallery
GALLERY_LOCATION="eastus"               ### Region for the Compute Group/Gallery
OS_TYPE="Linux"

# Azure Backup Vault Configuration (Retained for reference)
BACKUP_VAULT_RG="rg-shared-infrastructure"
BACKUP_VAULT_NAME="NonProdBackupVault"
BACKUP_LOCATION="eastus"

# Azure Storage Account Configuration for MySQL Backups
STORAGE_RG="rg-shared-infrastructure"
STORAGE_ACCOUNT_NAME="nonprodmysqlbak$(az account show --query id --output tsv | cut -c1-6)" # Generates a unique name for storage account.
STORAGE_CONTAINER_NAME="mysql-backups"
STORAGE_LOCATION="eastus"

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
        echo "AZURE NON-PROD BACKUP AND DELETE EXECUTION LOG"
        echo "======================================================"
        echo "Execution Time : $(date)"
        echo "IST Time       : $TIME_DISPLAY"
        echo "Action         : Create Dynamic Gallery Image / Mydumper MySQL Backup & Delete"
        echo "======================================================"
        echo ""
    } >> "$LOG_FILE"

    # ========================================================
    # Get Azure subscription ID
    # ========================================================
    SUBSCRIPTION_ID=$(az account show --query 'id' --output tsv 2>> "$LOG_FILE")
    echo "Azure Subscription ID: $SUBSCRIPTION_ID" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"

    # ========================================================
    # Ensure Resource Groups exist (Create if missing)
    # ========================================================
    echo "Checking if Resource Group '$GALLERY_RG' exists..." >> "$LOG_FILE"
    if ! az group show --name "$GALLERY_RG" --output none &> /dev/null; then
        echo "Resource Group '$GALLERY_RG' does not exist. Creating in location '$GALLERY_LOCATION'..." >> "$LOG_FILE"
        az group create --name "$GALLERY_RG" --location "$GALLERY_LOCATION" --output none >> "$LOG_FILE" 2>&1
    else
        echo "Resource Group '$GALLERY_RG' already exists." >> "$LOG_FILE"
    fi
    echo "" >> "$LOG_FILE"

    # ========================================================
    # Ensure Azure Compute Gallery exists (Create once if missing)
    # ========================================================
    echo "Checking if Azure Compute Gallery '$GALLERY_NAME' exists..." >> "$LOG_FILE"
    if ! az sig show --resource-group "$GALLERY_RG" --gallery-name "$GALLERY_NAME" --output none &> /dev/null; then
        echo "Gallery does not exist. Creating Compute Gallery '$GALLERY_NAME' in location '$GALLERY_LOCATION'..." >> "$LOG_FILE"
        az sig create --resource-group "$GALLERY_RG" --gallery-name "$GALLERY_NAME" --location "$GALLERY_LOCATION" --output none >> "$LOG_FILE" 2>&1
    else
        echo "Compute Gallery '$GALLERY_NAME' already exists." >> "$LOG_FILE"
    fi

    # ====================================================
    # 1. HANDLE AZURE VIRTUAL MACHINES (DYNAMIC REGION MATCHING)
    # ====================================================
    VM_DATA=$(az vm list -d --query "[?tags.Environment=='non-prod' && powerState=='VM running'].[id, name, resourceGroup, location]" --output tsv 2>> "$LOG_FILE")

    if [ -n "$VM_DATA" ]; then
        echo "$VM_DATA" | while read -r VM_ID VM_NAME RESOURCE_GROUP VM_LOCATION; do
            [ -z "$VM_ID" ] && continue
            [ -z "$VM_NAME" ] || [ "$VM_NAME" = "None" ] && VM_NAME="Unnamed"
            [ -z "$VM_LOCATION" ] && VM_LOCATION="$GALLERY_LOCATION" # Fallback if empty

            {
                echo ""
                echo "------------------------------------------------------"
                echo "Virtual Machine Backup"
                echo "VM Name       : $VM_NAME"
                echo "Resource Group: $RESOURCE_GROUP"
                echo "VM Location   : $VM_LOCATION"
                echo "------------------------------------------------------"
            } >> "$LOG_FILE"

            IMAGE_VERSION="$(date +%Y).$(date +%-m%-d).$(date +%-H%-M)"

            # Dynamically extract storage profile properties from the live VM
            PUB=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query "storageProfile.imageReference.publisher" --output tsv 2>> "$LOG_FILE")
            OFFER=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query "storageProfile.imageReference.offer" --output tsv 2>> "$LOG_FILE")
            SKU=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query "storageProfile.imageReference.sku" --output tsv 2>> "$LOG_FILE")

            # Accurately pull Hyper-V Generation from OS disk or instance profile
            HYPERV_GEN=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query "storageProfile.osDisk.hyperVGeneration" --output tsv 2>> "$LOG_FILE")
            if [ -z "$HYPERV_GEN" ] || [ "$HYPERV_GEN" = "None" ]; then
                HYPERV_GEN=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query "hyperVGeneration" --output tsv 2>> "$LOG_FILE")
            fi
            if [ -z "$HYPERV_GEN" ] || [ "$HYPERV_GEN" = "None" ]; then
                HYPERV_GEN="V2"
            fi

            # Check for Marketplace Purchase Plans (AlmaLinux, RHEL, etc.)
            PLAN_PUB=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query "plan.publisher" --output tsv 2>> "$LOG_FILE")
            PLAN_PROD=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query "plan.product" --output tsv 2>> "$LOG_FILE")
            PLAN_NAME=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query "plan.name" --output tsv 2>> "$LOG_FILE")

            CLEAN_OFFER=$(echo "$OFFER" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
            CLEAN_SKU=$(echo "$SKU" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
            IMAGE_DEF_NAME="${CLEAN_OFFER}-${CLEAN_SKU}-def"

            echo "Detected Profile -> Pub: $PUB | Offer: $OFFER | SKU: $SKU | Gen: $HYPERV_GEN" >> "$LOG_FILE"
            echo "Using Image Definition Name: $IMAGE_DEF_NAME" >> "$LOG_FILE"

            # Ensure Image Definition exists inside the gallery (created in the VM's matching region)
            if ! az sig image-definition show --resource-group "$GALLERY_RG" --gallery-name "$GALLERY_NAME" --gallery-image-definition "$IMAGE_DEF_NAME" --output none &> /dev/null; then
                echo "Creating Image Definition '$IMAGE_DEF_NAME' in location '$VM_LOCATION'..." >> "$LOG_FILE"

                if [ -n "$PLAN_PUB" ] && [ "$PLAN_PUB" != "None" ]; then
                    az sig image-definition create --resource-group "$GALLERY_RG" --gallery-name "$GALLERY_NAME" --gallery-image-definition "$IMAGE_DEF_NAME" --publisher "$PUB" --offer "$OFFER" --sku "$SKU" --os-type "$OS_TYPE" --os-state "Specialized" --hyper-v-generation "$HYPERV_GEN" --location "$VM_LOCATION" --plan-publisher "$PLAN_PUB" --plan-product "$PLAN_PROD" --plan-name "$PLAN_NAME" --output none >> "$LOG_FILE" 2>&1
                else
                    az sig image-definition create --resource-group "$GALLERY_RG" --gallery-name "$GALLERY_NAME" --gallery-image-definition "$IMAGE_DEF_NAME" --publisher "$PUB" --offer "$OFFER" --sku "$SKU" --os-type "$OS_TYPE" --os-state "Specialized" --hyper-v-generation "$HYPERV_GEN" --location "$VM_LOCATION" --output none >> "$LOG_FILE" 2>&1
                fi
            fi

            # Deallocate VM for backup safely
            echo "Deallocating VM: $VM_NAME..." >> "$LOG_FILE"
            az vm deallocate --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --no-wait --output none >> "$LOG_FILE" 2>&1

            echo "Waiting for VM $VM_NAME to fully deallocate..." >> "$LOG_FILE"
            az vm wait --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --custom "powerState == 'VM deallocated'" --timeout 300 2>> "$LOG_FILE"

            # Create Specialized Azure Compute Gallery Image Version in the corresponding VM region
            echo "Creating Specialized Image Version '$IMAGE_VERSION' for VM: $VM_NAME..." >> "$LOG_FILE"
            az sig image-version create --resource-group "$GALLERY_RG" --gallery-name "$GALLERY_NAME" --gallery-image-definition "$IMAGE_DEF_NAME" --gallery-image-version "$IMAGE_VERSION" --virtual-machine "$VM_ID" --location "$VM_LOCATION" --output none >> "$LOG_FILE" 2>&1

            if [ $? -ne 0 ]; then
                echo "CRITICAL ERROR: Failed to create Compute Gallery Image Version for $VM_NAME. SKIPPING DELETION." >> "$LOG_FILE"
                continue
            fi

            echo "SUCCESS: Compute Gallery Image Version created successfully: $IMAGE_VERSION" >> "$LOG_FILE"

            # Delete VM
            echo "Deleting Azure VM: $VM_NAME" >> "$LOG_FILE"
            az vm delete --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --yes --force-deletion --output none >> "$LOG_FILE" 2>&1
            if [ $? -eq 0 ]; then
                echo "SUCCESS: VM $VM_NAME deleted." >> "$LOG_FILE"
            else
                echo "ERROR: Failed to delete VM $VM_NAME." >> "$LOG_FILE"
            fi
        done
    else
        echo "No running non-prod Virtual Machines found." >> "$LOG_FILE"
    fi

    # ====================================================
    # 2. HANDLE AZURE DATABASE FOR MYSQL FLEXIBLE SERVERS (GLOBAL SEARCH ACROSS ALL REGIONS)
    # ====================================================
    MYSQL_DATA=$(az mysql flexible-server list --query "[?tags.Environment=='non-prod' && state=='Ready'].[name, resourceGroup]" --output tsv 2>> "$LOG_FILE")

    if [ -n "$MYSQL_DATA" ]; then

        # Ensure Storage Resource Group exists
        if ! az group show --name "$STORAGE_RG" --output none &> /dev/null; then
            echo "Creating Storage Resource Group '$STORAGE_RG'..." >> "$LOG_FILE"
            az group create --name "$STORAGE_RG" --location "$STORAGE_LOCATION" --output none >> "$LOG_FILE" 2>&1
        fi

        # Ensure Azure Storage Account exists
        if ! az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$STORAGE_RG" --output none &> /dev/null; then
            echo "Creating Storage Account '$STORAGE_ACCOUNT_NAME'..." >> "$LOG_FILE"
            az storage account create --name "$STORAGE_ACCOUNT_NAME" --resource-group "$STORAGE_RG" --location "$STORAGE_LOCATION" --sku Standard_LRS --kind StorageV2 --output none >> "$LOG_FILE" 2>&1
        fi

        # Retrieve Storage Account Connection Key
        STORAGE_KEY=$(az storage account keys list --resource-group "$STORAGE_RG" --account-name "$STORAGE_ACCOUNT_NAME" --query "[0].value" --output tsv 2>> "$LOG_FILE")

        # Ensure Storage Container exists
        az storage container create --name "$STORAGE_CONTAINER_NAME" --account-name "$STORAGE_ACCOUNT_NAME" --account-key "$STORAGE_KEY" --auth-mode key --public-access off --output none >> "$LOG_FILE" 2>&1

        echo "$MYSQL_DATA" | while read -r MYSQL_NAME RESOURCE_GROUP; do
            [ -z "$MYSQL_NAME" ] && continue

            {
                echo ""
                echo "------------------------------------------------------"
                echo "MySQL Flexible Server - Mydumper Backup"
                echo "Server Name   : $MYSQL_NAME"
                echo "Resource Group: $RESOURCE_GROUP"
                echo "------------------------------------------------------"
            } >> "$LOG_FILE"

            # Fetch MySQL Admin Username and FQDN
            MYSQL_FQDN=$(az mysql flexible-server show --resource-group "$RESOURCE_GROUP" --name "$MYSQL_NAME" --query "fullyQualifiedDomainName" --output tsv 2>> "$LOG_FILE")
            MYSQL_USER=$(az mysql flexible-server show --resource-group "$RESOURCE_GROUP" --name "$MYSQL_NAME" --query "administratorLogin" --output tsv 2>> "$LOG_FILE")

            BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
            BACKUP_DIR="/tmp/mysql_backup_${MYSQL_NAME}_${BACKUP_TIMESTAMP}"
            mkdir -p "$BACKUP_DIR"

            echo "Running mydumper on $MYSQL_FQDN..." >> "$LOG_FILE"

            # Ensure mydumper is installed on AlmaLinux 8
            if ! command -v mydumper &> /dev/null; then
                echo "Installing mydumper on AlmaLinux 8 via official RPM..." >> "$LOG_FILE"
                sudo yum install -y epel-release wget glib2 pcre zlib zstd >> "$LOG_FILE" 2>&1

                MYDUMPER_RPM="mydumper-1.0.5-1.el8.x86_64.rpm"
                wget -q "https://github.com/mydumper/mydumper/releases/download/v1.0.5-1/$MYDUMPER_RPM" -O "/tmp/$MYDUMPER_RPM" >> "$LOG_FILE" 2>&1
                sudo yum localinstall -y "/tmp/$MYDUMPER_RPM" >> "$LOG_FILE" 2>&1
                rm -f "/tmp/$MYDUMPER_RPM"
            fi

            # Generate a temporary dynamic password conforming to Azure complexity requirements
            DYNAMIC_PASSWORD="P@ssw0rd$(date +%s)"

            echo "Resetting admin password for $MYSQL_NAME..." >> "$LOG_FILE"
            az mysql flexible-server update --resource-group "$RESOURCE_GROUP" --name "$MYSQL_NAME" --admin-password "$DYNAMIC_PASSWORD" --output none >> "$LOG_FILE" 2>&1

            # Take backup using mydumper
            mydumper -h "$MYSQL_FQDN" -u "$MYSQL_USER" -p "$DYNAMIC_PASSWORD" -o "$BACKUP_DIR" --compress --skip-ddl-locks --trx-tables=0 --regex '^(?!(mysql|information_schema|performance_schema|sys))' >> "$LOG_FILE" 2>&1

            if [ $? -eq 0 ]; then
                echo "Mydumper backup completed. Creating tarball..." >> "$LOG_FILE"
                TARBALL="/tmp/${MYSQL_NAME}_${BACKUP_TIMESTAMP}.tar.gz"
                tar -zcvf "$TARBALL" -C "$BACKUP_DIR" . >> "$LOG_FILE" 2>&1

                echo "Uploading backup to Azure Storage Container '$STORAGE_CONTAINER_NAME'..." >> "$LOG_FILE"
                az storage blob upload --account-name "$STORAGE_ACCOUNT_NAME" --account-key "$STORAGE_KEY" --container-name "$STORAGE_CONTAINER_NAME" --file "$TARBALL" --name "$(basename "$TARBALL")" --output none >> "$LOG_FILE" 2>&1

                if [ $? -eq 0 ]; then
                    echo "SUCCESS: Backup uploaded successfully to Azure Storage." >> "$LOG_FILE"
                else
                    echo "ERROR: Failed to upload backup tarball to Azure Storage." >> "$LOG_FILE"
                fi

                # Cleanup local files
                rm -rf "$BACKUP_DIR" "$TARBALL"
            else
                echo "CRITICAL ERROR: Mydumper failed. SKIPPING DELETION of $MYSQL_NAME." >> "$LOG_FILE"
                rm -rf "$BACKUP_DIR"
                continue
            fi

            # Delete MySQL Flexible Server safely
            echo "Deleting MySQL Flexible Server: $MYSQL_NAME" >> "$LOG_FILE"
            if az mysql flexible-server delete --resource-group "$RESOURCE_GROUP" --name "$MYSQL_NAME" --yes --output none >> "$LOG_FILE" 2>&1; then
                echo "SUCCESS: MySQL server $MYSQL_NAME deleted." >> "$LOG_FILE"
            else
                echo "ERROR: Failed to delete MySQL server $MYSQL_NAME." >> "$LOG_FILE"
            fi

        done
    else
        echo "No available non-prod MySQL Flexible Servers found." >> "$LOG_FILE"
    fi

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
