#!/bin/bash

# ==============================================================================
# MULTI-CLOUD FINOPS CONFIGURATION (KUBERNETES CLUSTER)
# ==============================================================================
EMAIL_TO="abc@gmail.com"
EMAIL_FROM="DevOps Team <devopsteam@explicate-devops.com>"
SUBJECT="Multi-Cloud FinOps Execution Report - Auto-managed State"

STATE_FILE="/tmp/global_finops_state.json"
LOG_FILE="/tmp/multi_cloud_finops_execution.log"

# Clear and initialize log with redirection
> "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

if [ ! -f "$STATE_FILE" ]; then
    echo "{}" > "$STATE_FILE"
fi

# Time setup (IST enforcement for out-of-hours shutdown)
TIME_DISPLAY=$(TZ="Asia/Kolkata" date "+%I:%M %p")
TIME=$(TZ="Asia/Kolkata" date +%H%M)

echo "========================================================"
echo "Multi-Cloud Cost Optimization Execution Log"
echo "Execution Time : $(date)"
echo "IST Time Check : $TIME_DISPLAY"
echo "Target Filter  : Environment=non-prod / environment=non-prod"
echo "========================================================"

# Run condition check: 8:00 PM to 7:30 AM IST (2000 to 0730)
if [ "$TIME" -ge 2000 ] || [ "$TIME" -lt 0730 ]; then

    #################################################################
    # 1. KUBERNETES CLUSTERS (AKS, EKS, GKE)
    #################################################################
    echo ""
    echo "--------------------------------------------------------"
    echo "PROCESSING KUBERNETES CLUSTERS (AKS, EKS, GKE)"
    echo "--------------------------------------------------------"

    # --- AZURE AKS ---
    if command -v az &> /dev/null && az account show > /dev/null 2>&1; then
        echo "-> Processing Azure AKS clusters..."
        SUBSCRIPTIONS=$(az account subscription list --query "[?state=='Enabled'].subscriptionId" -o tsv 2>/dev/null)
        AKS_FOUND=false

        for sub in $SUBSCRIPTIONS; do
            az account set --subscription "$sub" > /dev/null 2>&1
            AKS_CLUSTERS=$(az aks list --query "[?tags.Environment=='non-prod'].{name:name, rg:resourceGroup, powerState:powerState.code}" -o json 2>/dev/null)

            if [ -n "$AKS_CLUSTERS" ] && [ "$AKS_CLUSTERS" != "[]" ]; then
                AKS_FOUND=true
                echo "$AKS_CLUSTERS" | jq -c '.[]?' | while read -r cluster_json; do
                    CLUSTER_NAME=$(echo "$cluster_json" | jq -r '.name')
                    RG=$(echo "$cluster_json" | jq -r '.rg')
                    POWER_STATE=$(echo "$cluster_json" | jq -r '.powerState')

                    if [ "$POWER_STATE" != "Stopped" ] && [ "$POWER_STATE" != "Stopping" ]; then
                        echo "   -> Stopping AKS Cluster: $CLUSTER_NAME in RG: $RG"
                        az aks stop --name "$CLUSTER_NAME" --resource-group "$RG" --no-wait > /dev/null 2>&1
                    fi
                done
            fi
        done

        if [ "$AKS_FOUND" = false ]; then
            echo "   -> No AKS cluster found with the tag Environment=non-prod"
        fi
    fi

    # --- AWS EKS ---
    if command -v aws &> /dev/null; then
        echo "-> Processing AWS EKS clusters..."
        AWS_REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text 2>/dev/null)
        EKS_FOUND=false

        for region in $AWS_REGIONS; do
            EKS_CLUSTERS=$(aws eks list-clusters --region "$region" --query "clusters[]" --output text 2>/dev/null)
            for cluster in $EKS_CLUSTERS; do
                [ -z "$cluster" ] && continue

                NODE_GROUPS=$(aws eks list-nodegroups --cluster-name "$cluster" --region "$region" --query "nodegroups[]" --output text 2>/dev/null)
                for ng in $NODE_GROUPS; do
                    [ -z "$ng" ] && continue

                    NG_ARN=$(aws eks describe-nodegroup --cluster-name "$cluster" --nodegroup-name "$ng" --region "$region" --query "nodegroup.nodegroupArn" --output text 2>/dev/null)
                    TAGS=$(aws eks list-tags-for-resource --resource-arn "$NG_ARN" --region "$region" --query "tags" --output json 2>/dev/null)
                    IS_NONPROD=$(echo "$TAGS" | jq -r '.Environment // empty')

                    if [ -z "$IS_NONPROD" ] || [ "$IS_NONPROD" != "non-prod" ]; then
                        CLUSTER_ARN=$(aws eks describe-cluster --name "$cluster" --region "$region" --query "cluster.arn" --output text 2>/dev/null)
                        CLUSTER_TAGS=$(aws eks list-tags-for-resource --resource-arn "$CLUSTER_ARN" --region "$region" --query "tags" --output json 2>/dev/null)
                        IS_NONPROD=$(echo "$CLUSTER_TAGS" | jq -r '.Environment // empty')
                    fi

                    if [ "$IS_NONPROD" == "non-prod" ]; then
                        EKS_FOUND=true
                        NG_CONFIG=$(aws eks describe-nodegroup --cluster-name "$cluster" --nodegroup-name "$ng" --region "$region" --query "nodegroup.scalingConfig" --output json 2>/dev/null)
                        MIN_SIZE=$(echo "$NG_CONFIG" | jq -r '.minSize')
                        MAX_SIZE=$(echo "$NG_CONFIG" | jq -r '.maxSize')
                        DESIRED_SIZE=$(echo "$NG_CONFIG" | jq -r '.desiredSize')
                        STATE_KEY="aws/eks/$region/$cluster/$ng"

                        if [ "$DESIRED_SIZE" -gt 0 ]; then
                            echo "   -> Scaling down EKS Node Group: $ng (min: $MIN_SIZE, max: $MAX_SIZE, desired: $DESIRED_SIZE)"
                            jq --arg key "$STATE_KEY" --argjson min "$MIN_SIZE" --argjson max "$MAX_SIZE" --argjson desired "$DESIRED_SIZE" '.[$key] = {"min": $min, "max": $max, "desired": $desired}' "$STATE_FILE" > tmp.$$.json && mv tmp.$$.json "$STATE_FILE"

                            aws eks update-nodegroup-config --cluster-name "$cluster" --nodegroup-name "$ng" --region "$region" --scaling-config minSize=0,maxSize=1,desiredSize=0 > /dev/null 2>&1
                        fi
                    fi
                done
            done
        done

        if [ "$EKS_FOUND" = false ]; then
            echo "   -> No EKS cluster found with the tag Environment=non-prod"
        fi
    fi

    # --- GCP GKE ---
    if command -v gcloud &> /dev/null; then
        echo "-> Processing GCP GKE clusters..."
        GCP_PROJECTS=$(gcloud projects list --format="value(projectId)" 2>/dev/null)
        GKE_FOUND=false

        for project in $GCP_PROJECTS; do
            GKE_CLUSTERS=$(gcloud container clusters list --project="$project" --format="json" 2>/dev/null)
            [ -z "$GKE_CLUSTERS" ] || [ "$GKE_CLUSTERS" == "[]" ] && continue

            MATCHING_CLUSTERS=$(echo "$GKE_CLUSTERS" | jq -c '[.[]? | select(.resourceLabels.environment=="non-prod")]')
            COUNT=$(echo "$MATCHING_CLUSTERS" | jq 'length')

            if [ "$COUNT" -gt 0 ]; then
                GKE_FOUND=true
                echo "$MATCHING_CLUSTERS" | jq -c '.[]?' | while read -r cluster_json; do
                    CLUSTER_NAME=$(echo "$cluster_json" | jq -r '.name')
                    LOCATION=$(echo "$cluster_json" | jq -r '.location')
                    LOCATION_FLAG=$([[ "$LOCATION" =~ ^[a-z]+-[a-z]+[0-9]-[a-z]$ ]] && echo "--zone=$LOCATION" || echo "--region=$LOCATION")

                    NODE_POOLS=$(gcloud container node-pools list --cluster="$CLUSTER_NAME" --project="$project" $LOCATION_FLAG --format="json" 2>/dev/null)
                    echo "$NODE_POOLS" | jq -c '.[]?' | while read -r pool_json; do
                        POOL_NAME=$(echo "$pool_json" | jq -r '.name')
                        INITIAL_COUNT=$(echo "$pool_json" | jq -r '.initialNodeCount')
                        
                        # Check if autoscaling is enabled on this node pool
                        AUTOSCALING_ENABLED=$(echo "$pool_json" | jq -r '.autoscaling.enabled // false')
                        MIN_NODES=$(echo "$pool_json" | jq -r '.autoscaling.minNodeCount // 0')
                        MAX_NODES=$(echo "$pool_json" | jq -r '.autoscaling.maxNodeCount // 0')
                        
                        STATE_KEY="gcp/gke/$project/$CLUSTER_NAME/$POOL_NAME"

                        if [ "$INITIAL_COUNT" -gt 0 ]; then
                            echo "   -> Resizing GKE Node Pool: $POOL_NAME to 0 nodes (from $INITIAL_COUNT)"
                            
                            # Save state including autoscaling configurations
                            jq --arg key "$STATE_KEY" --argjson count "$INITIAL_COUNT" --argjson autoscaling "$AUTOSCALING_ENABLED" --argjson min "$MIN_NODES" --argjson max "$MAX_NODES" '.[$key] = {"initialCount": $count, "autoscaling": $autoscaling, "minNodes": $min, "maxNodes": $max}' "$STATE_FILE" > tmp.$$.json && mv tmp.$$.json "$STATE_FILE"

                            # If autoscaling is enabled, disable it first
                            if [ "$AUTOSCALING_ENABLED" = "true" ]; then
                                gcloud container clusters update "$CLUSTER_NAME" --node-pool="$POOL_NAME" --no-enable-autoscaling --project="$project" $LOCATION_FLAG --quiet > /dev/null 2>&1
                            fi

                            # Resize node pool down to 0
                            gcloud container clusters resize "$CLUSTER_NAME" --node-pool="$POOL_NAME" --num-nodes=0 --project="$project" $LOCATION_FLAG --quiet > /dev/null 2>&1
                        fi
                    done
                done
            fi
        done

        if [ "$GKE_FOUND" = false ]; then
            echo "   -> No GKE cluster found with the label environment=non-prod"
        fi
    fi

# ==============================================================================
# EMAIL NOTIFICATION DISPATCH
# ==============================================================================
echo "Sending execution summary report to $EMAIL_TO..."

if command -v mail &> /dev/null; then
    mail -r "$EMAIL_FROM" -s "$SUBJECT" "$EMAIL_TO" < "$LOG_FILE"
    if [ $? -eq 0 ]; then
        echo "Email sent successfully to $EMAIL_TO"
    else
        echo "ERROR: Failed to send email via mail command."
    fi
else
    echo "Error: The 'mail' command was not found on this system." >> "$LOG_FILE"
fi
