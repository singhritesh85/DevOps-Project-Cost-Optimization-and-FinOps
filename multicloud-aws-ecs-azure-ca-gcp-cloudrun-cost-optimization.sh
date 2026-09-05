#!/bin/bash

# ==============================================================================
# CONFIGURATION
# ==============================================================================
EMAIL_TO="abc@gmail.com"
EMAIL_FROM="DevOps Team <devopsteam@explicate-devops.com>"
SUBJECT="Multi-Cloud Cost Optimization: Container Shutdown Summary"
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
        echo "Multi-Cloud Cost Optimization Shutdown Execution Log"
        echo "Execution Time : $(date)"
        echo "IST Time Check : $TIME_DISPLAY"
        echo "Target Filter  : Environment=non-prod"
        echo "========================================================"
        echo ""
    } >> "$LOG_FILE"

    # ------------------------------------------------------------------------------
    # 1. AWS ECS: Scale down Services with Tag Environment=non-prod to 0
    # ------------------------------------------------------------------------------
    {
        echo "--------------------------------------------------------"
        echo "PROCESSING AWS: ECS Services (Tag: Environment=non-prod)"
        echo "--------------------------------------------------------"
    } >> "$LOG_FILE"

    if command -v aws &> /dev/null; then
        AWS_REGIONS=$(aws ec2 describe-regions --query 'Regions[].RegionName' --output text 2>/dev/null)

        if [ -z "$AWS_REGIONS" ]; then
            echo "ERROR: Failed to fetch AWS regions. Check AWS credentials." >> "$LOG_FILE"
        else
            for REGION in $AWS_REGIONS; do
                echo "Checking AWS Region: $REGION" >> "$LOG_FILE"
                ECS_CLUSTERS=$(aws ecs list-clusters --region "$REGION" --query "clusterArns[]" --output text 2>/dev/null)

                if [ -n "$ECS_CLUSTERS" ] && [ "$ECS_CLUSTERS" != "None" ]; then
                    for CLUSTER in $ECS_CLUSTERS; do
                        [ -z "$CLUSTER" ] && continue
                        ECS_SERVICES=$(aws ecs list-services --cluster "$CLUSTER" --region "$REGION" --query "serviceArns[]" --output text 2>/dev/null)

                        if [ -n "$ECS_SERVICES" ] && [ "$ECS_SERVICES" != "None" ]; then
                            for SERVICE in $ECS_SERVICES; do
                                SVC_TAGS=$(aws ecs list-tags-for-resource --resource-arn "$SERVICE" --region "$REGION" --query "tags[?key=='Environment' && value=='non-prod']" --output text 2>/dev/null)
                                if [ -n "$SVC_TAGS" ]; then
                                    echo "  -> Scaling down non-prod ECS Service: $SERVICE in cluster $CLUSTER to desired-count 0" >> "$LOG_FILE"
                                    aws ecs update-service --cluster "$CLUSTER" --service "$SERVICE" --desired-count 0 --region "$REGION" > /dev/null 2>&1
                                fi
                            done
                        fi
                    done
                else
                    echo "  -> No ECS clusters found in $REGION." >> "$LOG_FILE"
                fi
            done
        fi
    else
        echo "WARNING: AWS CLI not found. Skipping AWS." >> "$LOG_FILE"
    fi

    # ------------------------------------------------------------------------------------------------------------------------------
    # 2. AZURE CONTAINER APPS: Scale down replicas to min=0, max=1 (Tag: Environment=non-prod) and then stopping Azure Container App
    # ------------------------------------------------------------------------------------------------------------------------------
    {
        echo ""
        echo "--------------------------------------------------------"
        echo "PROCESSING AZURE: Container Apps (Tag: Environment=non-prod)"
        echo "--------------------------------------------------------"
    } >> "$LOG_FILE"

    if command -v az &> /dev/null; then
        if az account show > /dev/null 2>&1; then
            SUBSCRIPTIONS=$(az account list --query "[].id" -o tsv 2>/dev/null)

            for SUB_ID in $SUBSCRIPTIONS; do
                echo "Setting Azure Subscription: $SUB_ID" >> "$LOG_FILE"
                az account set --subscription "$SUB_ID" > /dev/null 2>&1

                ACA_DATA=$(az containerapp list --query "[?tags.Environment=='non-prod'].{name:name, resourceGroup:resourceGroup}" -o tsv 2>/dev/null)
                if [ -n "$ACA_DATA" ]; then
                    while read -r ACA_NAME ACA_RG; do
                        [ -z "$ACA_NAME" ] || [ -z "$ACA_RG" ] && continue
                        echo "  -> Setting Container App: $ACA_NAME in RG: $ACA_RG replicas to min=0, max=1 and then stopping it" >> "$LOG_FILE"
                        az containerapp update --name "$ACA_NAME" --resource-group "$ACA_RG" --min-replicas 0 --max-replicas 1 > /dev/null 2>&1
                        az rest --method POST --url "/subscriptions/$SUB_ID/resourceGroups/$ACA_RG/providers/Microsoft.App/containerapps/$ACA_NAME/stop?api-version=2023-05-01" > /dev/null 2>&1
                    done <<< "$ACA_DATA"
                else
                    echo "  -> No matching non-prod Container Apps found in subscription $SUB_ID." >> "$LOG_FILE"
                fi
            done
        else
            echo "WARNING: Not logged into Azure CLI. Run 'az login' first. Skipping Azure." >> "$LOG_FILE"
        fi
    else
        echo "WARNING: Azure CLI not found. Skipping Azure." >> "$LOG_FILE"
    fi

    # ------------------------------------------------------------------------------
    # 3. GCP CLOUD RUN: Scale down instances to min=0, max=1 (Label: environment=non-prod)
    # ------------------------------------------------------------------------------
    {
        echo ""
        echo "--------------------------------------------------------"
        echo "PROCESSING GCP: Cloud Run Services (Label: environment=non-prod)"
        echo "--------------------------------------------------------"
    } >> "$LOG_FILE"

    if command -v gcloud &> /dev/null; then
        PROJECT_IDS=$(gcloud projects list --format="value(projectId)" 2>/dev/null)

        if [ -z "$PROJECT_IDS" ]; then
            echo "ERROR: Failed to fetch GCP projects. Check gcloud auth." >> "$LOG_FILE"
        else
            for PROJECT_ID in $PROJECT_IDS; do
                echo "Processing GCP Project: $PROJECT_ID" >> "$LOG_FILE"

                # Pull name and region globally across managed services
                CR_DATA=$(gcloud run services list --project="$PROJECT_ID" --format="value(metadata.name, region)" --quiet 2>/dev/null)

                if echo "$CR_DATA" | grep -q "ERROR"; then
                    echo "  -> Skipping project $PROJECT_ID (Cloud Run API may be disabled or unaccessible)." >> "$LOG_FILE"
                    continue
                fi

                if [ -n "$CR_DATA" ]; then
                    FOUND_NON_PROD_CR=false

                    while IFS=$'\t' read -r CR_NAME CR_REGION; do
                        [ -z "$CR_NAME" ] && continue
                        [ -z "$CR_REGION" ] && continue

                        # Check if the service has the non-prod label
                        CR_LABEL=$(gcloud run services describe "$CR_NAME" --project="$PROJECT_ID" --region="$CR_REGION" --format="value(metadata.labels.environment)" 2>/dev/null)

                        if [ "$CR_LABEL" = "non-prod" ]; then
                            FOUND_NON_PROD_CR=true
                            echo "  -> Scaling down Cloud Run Service: $CR_NAME in region $CR_REGION to min=0 and max=1" >> "$LOG_FILE"
                            gcloud run services update "$CR_NAME" --project="$PROJECT_ID" --region="$CR_REGION" --min=0 --max=1 --quiet > /dev/null 2>&1
                        fi
                    done < <(gcloud run services list --project="$PROJECT_ID" --format="value(metadata.name, region)" --quiet 2>/dev/null)

                    if [ "$FOUND_NON_PROD_CR" = false ]; then
                        echo "  -> No Cloud Run services with non-prod label found in project $PROJECT_ID." >> "$LOG_FILE"
                    fi
                else
                    echo "  -> No Cloud Run services found in project $PROJECT_ID." >> "$LOG_FILE"
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
