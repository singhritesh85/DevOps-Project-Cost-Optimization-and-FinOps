#!/bin/bash

# ==============================================================================
# CONFIGURATION
# ==============================================================================
EMAIL_TO="abc@gmail.com"
EMAIL_FROM="DevOps Team <devopsteam@explicate-devops.com>"
SUBJECT="Multi-Cloud Resource Shutdown Summary"
LOG_FILE="/tmp/multi_cloud_shutdown_summary.log"

# Clear previous log file
> "$LOG_FILE"

# Time setup
TIME_DISPLAY=$(TZ="Asia/Kolkata" date "+%I:%M %p")
TIME=$(TZ="Asia/Kolkata" date +%H%M)

# ==============================================================================
# RUN CONDITION: 8:00 PM to 7:30 AM IST
# ==============================================================================
if [ "$TIME" -ge 2000 ] || [ "$TIME" -lt 0730 ]; then

    {
        echo "========================================================"
        echo "Multi-Cloud Resource Shutdown Execution Log"
        echo "Execution Time : $(date)"
        echo "IST Time Check : $TIME_DISPLAY"
        echo "Target Filter  : Environment=non-prod (GCP: environment=non-prod)"
        echo "========================================================"
        echo ""
    } >> "$LOG_FILE"

    # ------------------------------------------------------------------------------
    # 1. AWS: Scale down Auto Scaling Groups with tag Environment=non-prod
    # ------------------------------------------------------------------------------
    {
        echo "--------------------------------------------------------"
        echo "PROCESSING AWS: Auto Scaling Groups (Tag: Environment=non-prod)"
        echo "--------------------------------------------------------"
    } >> "$LOG_FILE"

    if command -v aws &> /dev/null; then
        AWS_REGIONS=$(aws ec2 describe-regions --query 'Regions[].RegionName' --output text 2>/dev/null)

        if [ -z "$AWS_REGIONS" ]; then
            echo "ERROR: Failed to fetch AWS regions. Check AWS credentials." >> "$LOG_FILE"
        else
            for REGION in $AWS_REGIONS; do
                echo "Checking AWS Region: $REGION" >> "$LOG_FILE"
                ASGS=$(aws autoscaling describe-auto-scaling-groups --region "$REGION" --filters "Name=tag:Environment,Values=non-prod" --query "AutoScalingGroups[].AutoScalingGroupName" --output text 2>/dev/null)

                if [ -n "$ASGS" ] && [ "$ASGS" != "None" ]; then
                    for ASG in $ASGS; do
                        [ -z "$ASG" ] && continue
                        echo "  -> Scaling down non-prod ASG: $ASG in $REGION (Min/Max/Desired = 0)" >> "$LOG_FILE"
                        aws autoscaling update-auto-scaling-group --region "$REGION" --auto-scaling-group-name "$ASG" --min-size 0 --max-size 0 --desired-capacity 0 > /dev/null 2>&1
                    done
                else
                    echo "  -> No matching non-prod ASGs found in $REGION." >> "$LOG_FILE"
                fi
            done
        fi
    else
        echo "WARNING: AWS CLI not found. Skipping AWS." >> "$LOG_FILE"
    fi

    # ------------------------------------------------------------------------------
    # 2. AZURE: Scale down VMSS with tag Environment=non-prod to 0 capacity
    # ------------------------------------------------------------------------------
    {
        echo ""
        echo "--------------------------------------------------------"
        echo "PROCESSING AZURE: Scale VMSS to 0 (Tag: Environment=non-prod)"
        echo "--------------------------------------------------------"
    } >> "$LOG_FILE"

    if command -v az &> /dev/null; then
        if az account show > /dev/null 2>&1; then
            SUBSCRIPTIONS=$(az account list --query "[].id" -o tsv 2>/dev/null)

            for SUB_ID in $SUBSCRIPTIONS; do
                echo "Setting Azure Subscription: $SUB_ID" >> "$LOG_FILE"
                az account set --subscription "$SUB_ID" > /dev/null 2>&1

                VMSS_DATA=$(az vmss list --query "[?tags.Environment=='non-prod'].{name:name, resourceGroup:resourceGroup}" -o tsv 2>/dev/null)
                if [ -n "$VMSS_DATA" ]; then
                    while read -r VMSS_NAME RG_NAME; do
                        [ -z "$VMSS_NAME" ] || [ -z "$RG_NAME" ] && continue
                        echo "  -> Scaling non-prod VMSS: $VMSS_NAME in Resource Group: $RG_NAME to 0 instances" >> "$LOG_FILE"

                        # Dynamically find the autoscale setting name attached to this VMSS
                        AS_NAME=$(az monitor autoscale list --resource-group "$RG_NAME" --query "[?contains(targetResourceUri, '$VMSS_NAME')].name" -o tsv 2>/dev/null)

                        if [ -n "$AS_NAME" ]; then
                            echo "    -> Updating autoscale setting '$AS_NAME' limits to 0" >> "$LOG_FILE"
                            az monitor autoscale update --resource-group "$RG_NAME" --name "$AS_NAME" --set profiles[0].capacity.minimum=0 profiles[0].capacity.maximum=0 profiles[0].capacity.default=0 > /dev/null 2>&1
                        fi

                        # Scale down the VMSS
                        az vmss scale --resource-group "$RG_NAME" --name "$VMSS_NAME" --new-capacity 0 --no-wait > /dev/null 2>&1
                    done <<< "$VMSS_DATA"
                fi
            done
        else
            echo "WARNING: Not logged into Azure CLI. Run 'az login' first. Skipping Azure." >> "$LOG_FILE"
        fi
    else
        echo "WARNING: Azure CLI not found. Skipping Azure." >> "$LOG_FILE"
    fi

    # ==============================================================================
    # 3. GCP: Scale Down Non-Prod MIGs to 0 (Via Template Labels)
    # ==============================================================================
    {
        echo ""
        echo "--------------------------------------------------------"
        echo "PROCESSING GCP: Managed Instance Groups (Template Label Check)"
        echo "--------------------------------------------------------"
    } >> "$LOG_FILE"

    if command -v gcloud &> /dev/null; then
        PROJECT_IDS=$(gcloud projects list --format="value(projectId)" 2>/dev/null)

        if [ -z "$PROJECT_IDS" ]; then
            echo "ERROR: Failed to fetch GCP projects. Check gcloud auth." >> "$LOG_FILE"
        else
            for PROJECT_ID in $PROJECT_IDS; do
                echo "Processing GCP Project: $PROJECT_ID" >> "$LOG_FILE"

                MIG_DATA=$(gcloud compute instance-groups managed list --project="$PROJECT_ID" --format="value(name,zone,region)" --quiet 2>&1)

                if echo "$MIG_DATA" | grep -q "ERROR"; then
                    echo "  -> Skipping project $PROJECT_ID (Compute API may be disabled or unaccessible)." >> "$LOG_FILE"
                    continue
                fi

                if [ -n "$MIG_DATA" ]; then
                    FOUND_NON_PROD_MIG=false

                    while IFS=$'\t' read -r MIG_NAME ZONE_VAL REGION_VAL; do
                        [ -z "$MIG_NAME" ] && continue

                        echo "  [DEBUG] Inspecting MIG: $MIG_NAME (Zone: $ZONE_VAL, Region: $REGION_VAL)" >> "$LOG_FILE"

                        LOCATION_FLAG=""
                        LOC_VAL=""

                        # Smart location detection based on URL contents
                        if [[ "$ZONE_VAL" == */zones/* ]]; then
                            LOC_VAL=$(basename "$ZONE_VAL")
                            LOCATION_FLAG="--zone"
                        elif [[ "$ZONE_VAL" == */regions/* ]]; then
                            LOC_VAL=$(basename "$ZONE_VAL")
                            LOCATION_FLAG="--region"
                        elif [ -n "$REGION_VAL" ] && [ "$REGION_VAL" != "None" ] && [ "$REGION_VAL" != "-" ]; then
                            LOC_VAL=$(basename "$REGION_VAL")
                            LOCATION_FLAG="--region"
                        elif [ -n "$ZONE_VAL" ] && [ "$ZONE_VAL" != "None" ] && [ "$ZONE_VAL" != "-" ]; then
                            # Fallback for plain text names
                            LOC_VAL=$(basename "$ZONE_VAL")
                            LOCATION_FLAG="--zone"
                        fi

                        if [ -n "$LOCATION_FLAG" ]; then
                            # Safely fetch instance template via describe
                            TEMPLATE_URL=$(gcloud compute instance-groups managed describe "$MIG_NAME" --project="$PROJECT_ID" "$LOCATION_FLAG"="$LOC_VAL" --format="value(instanceTemplate)" --quiet 2>/dev/null)
                            if [ -z "$TEMPLATE_URL" ] || [ "$TEMPLATE_URL" = "None" ]; then
                                TEMPLATE_URL=$(gcloud compute instance-groups managed describe "$MIG_NAME" --project="$PROJECT_ID" "$LOCATION_FLAG"="$LOC_VAL" --format="value(versions[0].instanceTemplate)" --quiet 2>/dev/null)
                            fi

                            TEMPLATE_NAME=$(basename "$TEMPLATE_URL")
                            echo "  [DEBUG] Found Template Name: $TEMPLATE_NAME" >> "$LOG_FILE"

                            if [ -n "$TEMPLATE_NAME" ] && [ "$TEMPLATE_NAME" != "None" ]; then
                                # Check if this template has the environment=non-prod label
                                ENV_LABEL=$(gcloud compute instance-templates describe "$TEMPLATE_NAME" --project="$PROJECT_ID" --format="value(properties.labels.environment)" --quiet 2>/dev/null)
                                echo "  [DEBUG] Template Label environment = '$ENV_LABEL'" >> "$LOG_FILE"

                                if [ "$ENV_LABEL" = "non-prod" ]; then
                                    FOUND_NON_PROD_MIG=true
                                    echo "  -> Scaling down non-prod MIG: $MIG_NAME ($LOCATION_FLAG $LOC_VAL) using template: $TEMPLATE_NAME to 0" >> "$LOG_FILE"

                                    # Update autoscaler minimum replicas to 0 (keeping autoscaling active, max preserved)
                                    gcloud compute instance-groups managed set-autoscaling "$MIG_NAME" --project="$PROJECT_ID" "$LOCATION_FLAG"="$LOC_VAL" --min-num-replicas=0 --max-num-replicas=0 --mode=on --quiet > /dev/null 2>&1

                                    # Resize MIG to 0 instances
                                    gcloud compute instance-groups managed resize "$MIG_NAME" --project="$PROJECT_ID" "$LOCATION_FLAG"="$LOC_VAL" --size=0 --quiet > /dev/null 2>&1
                                fi
                            fi
                        else
                            echo "  [DEBUG] Location flag could not be determined for $MIG_NAME." >> "$LOG_FILE"
                        fi
                    done <<< "$MIG_DATA"

                    if [ "$FOUND_NON_PROD_MIG" = false ]; then
                        echo "  -> No Managed Instance Groups with non-prod templates found in project $PROJECT_ID." >> "$LOG_FILE"
                    fi
                else
                    echo "  -> No Managed Instance Groups found in project $PROJECT_ID." >> "$LOG_FILE"
                fi
            done
        fi
    else
        echo "WARNING: Google Cloud SDK (gcloud) not found. Skipping GCP." >> "$LOG_FILE"
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
