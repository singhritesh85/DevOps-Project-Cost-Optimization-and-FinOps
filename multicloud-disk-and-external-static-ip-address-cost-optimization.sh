#!/bin/bash

# -----------------------------
# Configuration
# -----------------------------
EMAIL_TO="abc@gmail.com"
EMAIL_FROM="DevOps Team <devopsteam@explicate-devops.com>"
SUBJECT="Multi-Cloud Global Storage & Network Cleanup Summary"
LOG_FILE="/tmp/cloud_cleanup_summary.log"

# Clear previous log file
> "$LOG_FILE"

TIME_DISPLAY=$(TZ="Asia/Kolkata" date "+%I:%M %p")
TIME=$(TZ="Asia/Kolkata" date +%H%M)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# ============================================================
# Run only around 8:00 AM - 9:00 AM and 8:00 PM - 9:00 PM IST
# (0800 to 0900 OR 2000 to 2100)
# ============================================================
if { [ "$TIME" -ge 0800 ] && [ "$TIME" -lt 0900 ]; } || { [ "$TIME" -ge 2000 ] && [ "$TIME" -lt 2100 ]; }; then

    {
        echo "===================================================="
        echo "Starting Global Multi-Cloud Storage & Network Cleanup"
        echo "Timestamp: $TIMESTAMP"
        echo "IST Time Check: $TIME_DISPLAY"
        echo "===================================================="
    } >> "$LOG_FILE"

    # ----------------------------------------------------
    # 1. AWS RESOURCES (All Regions: EBS Volumes & EIPs)
    # ----------------------------------------------------
    if command -v aws &> /dev/null; then
        {
            echo "--- [AWS] Fetching all active regions ---"
        } >> "$LOG_FILE"

        AWS_REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text 2>/dev/null)

        if [ -z "$AWS_REGIONS" ]; then
            echo "[AWS] Failed to fetch AWS regions or lack permissions." >> "$LOG_FILE"
        else
            for REGION in $AWS_REGIONS; do
                REGION=$(echo "$REGION" | tr -d '\r')
                [ -z "$REGION" ] && continue

                {
                    echo ""
                    echo "--------------------------------------------------"
                    echo "Checking AWS Region: $REGION"
                    echo "--------------------------------------------------"
                } >> "$LOG_FILE"

                # --- EBS Volumes ---
                echo "--- [AWS] Processing EBS Volumes in $REGION ---" >> "$LOG_FILE"
                AWS_VOLS=$(aws ec2 describe-volumes --region "$REGION" --filters Name=status,Values=available --query "Volumes[*].VolumeId" --output text 2>/dev/null)

                if [ -z "$AWS_VOLS" ] || [ "$AWS_VOLS" == "None" ]; then
                    echo "No unattached AWS EBS volumes found in $REGION." >> "$LOG_FILE"
                else
                    for VOL_ID in $AWS_VOLS; do
                        VOL_ID=$(echo "$VOL_ID" | tr -d '\r')
                        [ -z "$VOL_ID" ] && continue
                        SNAP_DESC="Backup-Unattached-${VOL_ID}-${TIMESTAMP}"

                        {
                            echo "  -> Creating snapshot for AWS volume: $VOL_ID"
                        } >> "$LOG_FILE"

                        if aws ec2 create-snapshot --region "$REGION" --volume-id "$VOL_ID" --description "$SNAP_DESC" --tag-specifications "ResourceType=snapshot,Tags=[{Key=Name,Value=$SNAP_DESC}]" > /dev/null 2>&1; then
                            {
                                echo "  -> Deleting AWS volume: $VOL_ID"
                            } >> "$LOG_FILE"

                            if aws ec2 delete-volume --region "$REGION" --volume-id "$VOL_ID" > /dev/null 2>&1; then
                                echo "  [OK] AWS volume $VOL_ID processed." >> "$LOG_FILE"
                            else
                                echo "  [ERROR] Failed to delete AWS volume $VOL_ID" >> "$LOG_FILE"
                            fi
                        else
                            echo "  [ERROR] Failed to create snapshot for AWS volume $VOL_ID. Skipping deletion." >> "$LOG_FILE"
                        fi
                    done
                fi

                # --- Elastic IPs ---
                echo "--- [AWS] Processing Elastic IPs (EIPs) in $REGION ---" >> "$LOG_FILE"
                AWS_EIPS=$(aws ec2 describe-addresses --region "$REGION" --query "Addresses[?AssociationId==null].AllocationId" --output text 2>/dev/null)

                if [ -z "$AWS_EIPS" ] || [ "$AWS_EIPS" == "None" ]; then
                    echo "No unattached AWS Elastic IPs found in $REGION." >> "$LOG_FILE"
                else
                    for ALLOC_ID in $AWS_EIPS; do
                        ALLOC_ID=$(echo "$ALLOC_ID" | tr -d '\r')
                        [ -z "$ALLOC_ID" ] && continue

                        {
                            echo "  -> Releasing unattached AWS Elastic IP (Allocation ID: $ALLOC_ID)"
                        } >> "$LOG_FILE"

                        if aws ec2 release-address --region "$REGION" --allocation-id "$ALLOC_ID" > /dev/null 2>&1; then
                            echo "  [OK] AWS EIP allocation $ALLOC_ID released." >> "$LOG_FILE"
                        else
                            echo "  [ERROR] Failed to release AWS EIP allocation $ALLOC_ID" >> "$LOG_FILE"
                        fi
                    done
                fi
            done
        fi
    else
        echo "[AWS] AWS CLI not found, skipping AWS checks." >> "$LOG_FILE"
    fi

    {
        echo "----------------------------------------------------"
    } >> "$LOG_FILE"

    # ----------------------------------------------------
    # 2. AZURE MANAGED DISKS (All Subscriptions & Regions)
    # ----------------------------------------------------
    if command -v az &> /dev/null; then
        {
            echo "--- [Azure] Processing All Subscriptions & Managed Disks ---"
        } >> "$LOG_FILE"

        AZURE_SUBS=$(az account list --query "[?state=='Enabled'].id" --output tsv 2>/dev/null)

        if [ -z "$AZURE_SUBS" ]; then
            echo "No active Azure subscriptions found or not logged into Azure CLI." >> "$LOG_FILE"
        else
            for SUB_ID in $AZURE_SUBS; do
                SUB_ID=$(echo "$SUB_ID" | tr -d '\r')
                [ -z "$SUB_ID" ] && continue

                {
                    echo ""
                    echo "--------------------------------------------------"
                    echo "Checking Azure Subscription ID: $SUB_ID"
                    echo "--------------------------------------------------"
                } >> "$LOG_FILE"

                AZURE_DISKS=$(az disk list --subscription "$SUB_ID" --query "[?managedBy==null].[id, name, resourceGroup, location]" --output tsv 2>/dev/null)

                if [ -z "$AZURE_DISKS" ]; then
                    echo "No unattached Azure disks found in subscription $SUB_ID." >> "$LOG_FILE"
                else
                    echo "$AZURE_DISKS" | while read -r DISK_ID DISK_NAME RG LOCATION; do
                        DISK_ID=$(echo "$DISK_ID" | tr -d '\r')
                        [ -z "$DISK_ID" ] && continue
                        SNAP_NAME="snap-${DISK_NAME}-${TIMESTAMP}"

                        {
                            echo "  -> Creating snapshot for Azure disk: $DISK_NAME (RG: $RG, Sub: $SUB_ID)"
                        } >> "$LOG_FILE"

                        if az snapshot create --subscription "$SUB_ID" --resource-group "$RG" --name "$SNAP_NAME" --location "$LOCATION" --source "$DISK_ID" > /dev/null 2>&1; then
                            {
                                echo "  -> Deleting Azure disk: $DISK_NAME"
                            } >> "$LOG_FILE"

                            if az disk delete --subscription "$SUB_ID" --ids "$DISK_ID" --yes > /dev/null 2>&1; then
                                echo "  [OK] Azure disk $DISK_NAME processed." >> "$LOG_FILE"
                            else
                                echo "  [ERROR] Failed to delete Azure disk $DISK_NAME" >> "$LOG_FILE"
                            fi
                        else
                            echo "  [ERROR] Failed to create snapshot for Azure disk $DISK_NAME. Skipping deletion." >> "$LOG_FILE"
                        fi
                    done
                fi
            done
        fi
    else
        echo "[Azure] Azure CLI not found, skipping Azure checks." >> "$LOG_FILE"
    fi

    {
        echo "----------------------------------------------------"
    } >> "$LOG_FILE"

    # ----------------------------------------------------
    # 3. GCP RESOURCES (Multi-Project, Zonal, Regional & Global)
    # ----------------------------------------------------
    if command -v gcloud &> /dev/null; then
        PROJECTS=$(gcloud projects list --format="value(projectId)" 2>/dev/null)

        if [ -z "$PROJECTS" ]; then
            echo "No GCP projects found or you lack sufficient permissions." >> "$LOG_FILE"
        else
            for PROJECT in $PROJECTS; do
                PROJECT=$(echo "$PROJECT" | tr -d '\r')
                [ -z "$PROJECT" ] && continue

                {
                    echo ""
                    echo "--------------------------------------------------"
                    echo "Checking GCP project: $PROJECT"
                    echo "--------------------------------------------------"
                } >> "$LOG_FILE"

                # --- Process GCP Persistent Disks (Zonal & Regional Separately) ---
                {
                    echo "--- [GCP] Processing Persistent Disks (Zonal & Regional) in $PROJECT ---"
                } >> "$LOG_FILE"

                # 1. Process Zonal Disks
                GCP_ZONAL_DISKS=$(gcloud compute disks list --project="$PROJECT" --filter="-users:* AND zone:*" --format="value(name,zone.basename())" 2>/dev/null)

                if [ -n "$GCP_ZONAL_DISKS" ]; then
                    echo "$GCP_ZONAL_DISKS" | while read -r DISK_NAME ZONE_VAL; do
                        DISK_NAME=$(echo "$DISK_NAME" | tr -d '\r')
                        ZONE=$(echo "$ZONE_VAL" | tr -d '\r')
                        [ -z "$DISK_NAME" ] || [ -z "$ZONE" ] && continue

                        SNAP_NAME="snap-${DISK_NAME}-${TIMESTAMP}"
                        {
                            echo "  -> Creating snapshot for zonal GCP disk: $DISK_NAME in zone $ZONE"
                        } >> "$LOG_FILE"

                        if gcloud compute disks snapshot "$DISK_NAME" --project="$PROJECT" --zone="$ZONE" --snapshot-names="$SNAP_NAME" --quiet > /dev/null 2>&1; then
                            {
                                echo "  -> Deleting zonal GCP disk: $DISK_NAME"
                            } >> "$LOG_FILE"

                            if gcloud compute disks delete "$DISK_NAME" --project="$PROJECT" --zone="$ZONE" --quiet > /dev/null 2>&1; then
                                echo "  [OK] Zonal GCP disk $DISK_NAME processed." >> "$LOG_FILE"
                            else
                                echo "  [ERROR] Failed to delete zonal GCP disk $DISK_NAME" >> "$LOG_FILE"
                            fi
                        else
                            echo "  [ERROR] Failed to create snapshot for zonal GCP disk $DISK_NAME. Skipping deletion." >> "$LOG_FILE"
                        fi
                    done
                fi

                # 2. Process Regional Disks
                GCP_REGIONAL_DISKS=$(gcloud compute disks list --project="$PROJECT" --filter="-users:* AND region:*" --format="value(name,region.basename())" 2>/dev/null)

                if [ -n "$GCP_REGIONAL_DISKS" ]; then
                    echo "$GCP_REGIONAL_DISKS" | while read -r DISK_NAME REGION_VAL; do
                        DISK_NAME=$(echo "$DISK_NAME" | tr -d '\r')
                        REGION=$(echo "$REGION_VAL" | tr -d '\r')
                        [ -z "$DISK_NAME" ] || [ -z "$REGION" ] && continue

                        SNAP_NAME="snap-${DISK_NAME}-${TIMESTAMP}"
                        {
                            echo "  -> Creating snapshot for regional GCP disk: $DISK_NAME in region $REGION"
                        } >> "$LOG_FILE"

                        if gcloud compute disks snapshot "$DISK_NAME" --project="$PROJECT" --region="$REGION" --snapshot-names="$SNAP_NAME" --quiet > /dev/null 2>&1; then
                            {
                                echo "  -> Deleting regional GCP disk: $DISK_NAME"
                            } >> "$LOG_FILE"

                            if gcloud compute disks delete "$DISK_NAME" --project="$PROJECT" --region="$REGION" --quiet > /dev/null 2>&1; then
                                echo "  [OK] Regional GCP disk $DISK_NAME processed." >> "$LOG_FILE"
                            else
                                echo "  [ERROR] Failed to delete regional GCP disk $DISK_NAME" >> "$LOG_FILE"
                            fi
                        else
                            echo "  [ERROR] Failed to create snapshot for regional GCP disk $DISK_NAME. Skipping deletion." >> "$LOG_FILE"
                        fi
                    done
                fi

                if [ -z "$GCP_ZONAL_DISKS" ] && [ -z "$GCP_REGIONAL_DISKS" ]; then
                    echo "No unattached GCP disks found in project $PROJECT." >> "$LOG_FILE"
                fi

                # --- Process Static External IPs (Regional & Global) ---
                {
                    echo "--- [GCP] Processing Static External IPs (Regional & Global) in $PROJECT ---"
                } >> "$LOG_FILE"

                GCP_IPS=$(gcloud compute addresses list --project="$PROJECT" --filter="status=RESERVED" --format="value(name,region,scope)" 2>/dev/null)

                if [ -z "$GCP_IPS" ]; then
                    echo "No unattached GCP static IPs found in project $PROJECT." >> "$LOG_FILE"
                else
                    echo "$GCP_IPS" | while read -r IP_NAME IP_REGION_PATH IP_SCOPE; do
                        IP_NAME=$(echo "$IP_NAME" | tr -d '\r')
                        [ -z "$IP_NAME" ] && continue

                        if [[ "$IP_SCOPE" == *"global"* ]] || [ -z "$IP_REGION_PATH" ] || [ "$IP_REGION_PATH" == "None" ]; then
                            {
                                echo "  -> Releasing global GCP static IP: $IP_NAME"
                            } >> "$LOG_FILE"

                            if gcloud compute addresses delete "$IP_NAME" --project="$PROJECT" --global --quiet > /dev/null 2>&1; then
                                echo "  [OK] GCP global IP $IP_NAME released." >> "$LOG_FILE"
                            else
                                echo "  [ERROR] Failed to release GCP global IP $IP_NAME" >> "$LOG_FILE"
                            fi
                        else
                            REGION=$(echo "$IP_REGION_PATH" | tr -d '\r' | awk -F'/' '{print $NF}')
                            {
                                echo "  -> Releasing regional GCP static IP: $IP_NAME in region $REGION"
                            } >> "$LOG_FILE"

                            if gcloud compute addresses delete "$IP_NAME" --project="$PROJECT" --region="$REGION" --quiet > /dev/null 2>&1; then
                                echo "  [OK] GCP regional IP $IP_NAME released." >> "$LOG_FILE"
                            else
                                echo "  [ERROR] Failed to release GCP regional IP $IP_NAME" >> "$LOG_FILE"
                            fi
                        fi
                    done
                fi
            done
        fi
    else
        echo "[GCP] Google Cloud SDK not found, skipping GCP checks." >> "$LOG_FILE"
    fi

    {
        echo "===================================================="
        echo "All cloud cleanups completed execution!"
        echo "===================================================="
    } >> "$LOG_FILE"

    # ==========================================
    # 4. SEND EMAIL VIA MAIL COMMAND
    # ==========================================
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
    echo "IST time is $TIME_DISPLAY. Outside the 8 AM / 8 PM execution windows - nothing to do."
fi
