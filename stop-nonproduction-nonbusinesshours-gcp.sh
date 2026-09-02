#!/bin/bash

# Configuration
EMAIL_TO="abc@gmail.com"
SUBJECT="GCP Non-Prod Resource Scheduler Summary"
LOG_FILE="/tmp/gcp_shutdown_summary.log"

# Clear previous log file
> "$LOG_FILE"

# Get current time in standard 12-hour AM/PM format (e.g., 08:30 PM)
TIME_DISPLAY=$(TZ="Asia/Kolkata" date "+%I:%M %p")

TIME=$(TZ="Asia/Kolkata" date +%H%M)

# 8:00 PM to 7:30 AM IST
if [ "$TIME" -ge 2000 ] || [ "$TIME" -lt 0730 ]; then

    {
        echo "GCP Resource Scheduler Execution Log"
        echo "=========================================="
        echo "Execution Time: $(date)"
        echo "IST Time Check: $TIME_DISPLAY"
        echo "Action: Stopping non-prod GCP instances..."
        echo "=========================================="
        echo ""
    } >> "$LOG_FILE"

    # Get all accessible GCP projects
    PROJECTS=$(gcloud projects list --format="value(projectId)" 2>/dev/null)

    if [ -z "$PROJECTS" ]; then
        echo "No GCP projects found or you lack sufficient permissions." >> "$LOG_FILE"
        exit 1
    fi

    for PROJECT in $PROJECTS; do
        {
            echo "--------------------------------------------------"
            echo "Checking GCP project: $PROJECT"
            echo "--------------------------------------------------"
        } >> "$LOG_FILE"

        # ==========================================
        # 1. HANDLE COMPUTE ENGINE (VM) INSTANCES
        # ==========================================
        # gcloud checks all zones automatically when zone is omitted
        VM_DATA=$(gcloud compute instances list --project="$PROJECT" --filter="labels.environment=non-prod AND status=RUNNING" --format="value(name,zone)" 2>/dev/null || echo "")

        if [ -n "$VM_DATA" ]; then
            echo "$VM_DATA" | while read -r INSTANCE_NAME ZONE; do
                [ -z "$INSTANCE_NAME" ] || [ -z "$ZONE" ] && continue

                echo "Stopping GCP VM instance: $INSTANCE_NAME in zone $ZONE (Project: $PROJECT)" >> "$LOG_FILE"
                gcloud compute instances stop "$INSTANCE_NAME" --zone="$ZONE" --project="$PROJECT" --quiet > /dev/null 2>&1
            done
        else
            echo "No running non-prod Compute Engine instances found in $PROJECT." >> "$LOG_FILE"
        fi

        # ==========================================
        # 2. HANDLE CLOUD SQL INSTANCES
        # ==========================================
        SQL_INSTANCES=$(gcloud sql instances list --project="$PROJECT" --format="value(name)" 2>/dev/null || echo "")

        if [ -n "$SQL_INSTANCES" ]; then
            for SQL_ID in $SQL_INSTANCES; do
                # Check user labels for environment=non-prod
                ENV_LABEL=$(gcloud sql instances describe "$SQL_ID" --project="$PROJECT" --format="value(settings.userLabels.environment)" 2>/dev/null || echo "")

                if [ "$ENV_LABEL" == "non-prod" ]; then
                    # Check current activation policy to avoid redundant updates
                    CURRENT_POLICY=$(gcloud sql instances describe "$SQL_ID" --project="$PROJECT" --format="value(settings.activationPolicy)" 2>/dev/null || echo "")

                    if [ "$CURRENT_POLICY" != "NEVER" ]; then
                        echo "Stopping Cloud SQL instance: $SQL_ID (Project: $PROJECT) by setting activation policy to NEVER" >> "$LOG_FILE"
                        gcloud sql instances patch "$SQL_ID" --activation-policy=NEVER --project="$PROJECT" --quiet > /dev/null 2>&1
                    else
                        echo "Cloud SQL instance $SQL_ID in $PROJECT is already stopped." >> "$LOG_FILE"
                    fi
                fi
            done
        else
            echo "No Cloud SQL instances found or API disabled in $PROJECT." >> "$LOG_FILE"
        fi
    done

    # ==========================================
    # 3. SEND EMAIL VIA MAIL COMMAND
    # ==========================================
    echo "Sending email summary to $EMAIL_TO..."

    if command -v mail &> /dev/null; then
        # Sends the text contents of LOG_FILE with the specified subject
        mail -r "DevOps Team <devopsteam@explicate-devops.com>" -s "$SUBJECT" "$EMAIL_TO" < "$LOG_FILE"
    else
        echo "Error: The 'mail' command was not found on this system." >> "$LOG_FILE"
    fi

else
    echo "IST time is $TIME_DISPLAY. Working hours - nothing to do."
fi
