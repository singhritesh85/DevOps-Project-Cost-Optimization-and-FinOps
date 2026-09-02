#!/bin/bash

# -----------------------------
# Configuration
# -----------------------------
EMAIL_TO="abc@gmail.com"
EMAIL_FROM="DevOps Team <devopsteam@explicate-devops.com>"
SUBJECT="GCP Non-Prod Machine Image and DB Backup & Delete Summary"
LOG_FILE="/tmp/gcp_backup_delete_summary.log"

# Centralized GCS Storage Configuration for Database Dumps
STORAGE_BUCKET_NAME="gcp-nonprod-backup-vault-central"
STORAGE_LOCATION="US"

# Clear previous log file
> "$LOG_FILE"

TIME_DISPLAY=$(TZ="Asia/Kolkata" date "+%I:%M %p")
TIME=$(TZ="Asia/Kolkata" date +%H%M)

# ============================================================
# Run only between 8:00 PM and 7:30 AM IST (2000 to 0730)
# ============================================================
if [ "$TIME" -ge 2000 ] || [ "$TIME" -lt 0730 ]; then

    {
        echo "GCP Non-Prod Backup & Delete Execution Log"
        echo "=========================================="
        echo "Execution Time : $(date)"
        echo "IST Time Check : $TIME_DISPLAY"
        echo "Action         : Machine Image, DB GCS Export & Deletion"
        echo "=========================================="
        echo ""
    } >> "$LOG_FILE"

    # Get all accessible GCP projects
    PROJECTS=$(gcloud projects list --format="value(projectId)" 2>/dev/null)

    if [ -z "$PROJECTS" ]; then
        echo "No GCP projects found or you lack sufficient permissions." >> "$LOG_FILE"
        exit 1
    fi

    # Dynamically select the first project from the list to host the central bucket
    CENTRAL_PROJECT=$(echo "$PROJECTS" | head -n 1)

    # ==========================================================
    # Check and Create Centralized GCS Backup Bucket if Not Exist
    # ==========================================================
    echo "Checking if centralized backup bucket 'gs://$STORAGE_BUCKET_NAME' exists in project $CENTRAL_PROJECT..." >> "$LOG_FILE"

    if ! gsutil ls -p "$CENTRAL_PROJECT" "gs://$STORAGE_BUCKET_NAME" &> /dev/null; then
        echo "Bucket does not exist. Creating 'gs://$STORAGE_BUCKET_NAME' in project $CENTRAL_PROJECT..." >> "$LOG_FILE"

        gsutil mb -p "$CENTRAL_PROJECT" -l "$STORAGE_LOCATION" "gs://$STORAGE_BUCKET_NAME" >> "$LOG_FILE" 2>&1

        if [ $? -eq 0 ]; then
            echo "SUCCESS: GCS backup bucket created successfully." >> "$LOG_FILE"
        else
            echo "CRITICAL ERROR: Failed to create GCS bucket 'gs://$STORAGE_BUCKET_NAME'. Exiting." >> "$LOG_FILE"
            exit 1
        fi
    else
        echo "SUCCESS: GCS backup bucket 'gs://$STORAGE_BUCKET_NAME' already exists." >> "$LOG_FILE"
    fi

    for PROJECT in $PROJECTS; do
        {
            echo ""
            echo "--------------------------------------------------"
            echo "Checking GCP project: $PROJECT"
            echo "--------------------------------------------------"
        } >> "$LOG_FILE"

        # ==========================================
        # 1. HANDLE COMPUTE ENGINE (VM) INSTANCES
        # ==========================================
        VM_DATA=$(gcloud compute instances list --project="$PROJECT" --filter="labels.environment=non-prod AND status=RUNNING" --format="value(name,zone)" 2>/dev/null || echo "")

        if [ -n "$VM_DATA" ]; then
            echo "$VM_DATA" | while read -r INSTANCE_NAME ZONE; do
                [ -z "$INSTANCE_NAME" ] || [ -z "$ZONE" ] && continue

                {
                    echo ""
                    echo "--------------------------------------------------"
                    echo "Compute Engine VM"
                    echo "Instance Name : $INSTANCE_NAME"
                    echo "Zone          : $ZONE"
                    echo "--------------------------------------------------"
                } >> "$LOG_FILE"

                MACHINE_IMAGE_NAME="mi-${INSTANCE_NAME}-$(date +%Y%m%d-%H%M%S)"
                echo "Creating Machine Image: $MACHINE_IMAGE_NAME" >> "$LOG_FILE"

                gcloud compute machine-images create "$MACHINE_IMAGE_NAME" --source-instance="$INSTANCE_NAME" --source-instance-zone="$ZONE" --project="$PROJECT" --quiet >> "$LOG_FILE" 2>&1

                if [ $? -eq 0 ]; then
                    echo "SUCCESS: Machine Image $MACHINE_IMAGE_NAME created." >> "$LOG_FILE"

                    echo "Deleting VM instance: $INSTANCE_NAME" >> "$LOG_FILE"
                    gcloud compute instances delete "$INSTANCE_NAME" --zone="$ZONE" --project="$PROJECT" --quiet > /dev/null 2>&1

                    if [ $? -eq 0 ]; then
                        echo "SUCCESS: VM $INSTANCE_NAME deleted." >> "$LOG_FILE"
                    else
                        echo "ERROR: Failed to delete VM $INSTANCE_NAME." >> "$LOG_FILE"
                    fi
                else
                    echo "ERROR: Failed to create Machine Image for $INSTANCE_NAME. Skipping deletion." >> "$LOG_FILE"
                fi
            done
        else
            echo "No running non-prod Compute Engine instances found in $PROJECT." >> "$LOG_FILE"
        fi

        # ==========================================
        # 2. HANDLE CLOUD SQL INSTANCES (GCS EXPORT)
        # ==========================================
        SQL_INSTANCES=$(gcloud sql instances list --project="$PROJECT" --format="value(name)" 2>/dev/null || echo "")

        if [ -n "$SQL_INSTANCES" ]; then
            for SQL_ID in $SQL_INSTANCES; do
                ENV_LABEL=$(gcloud sql instances describe "$SQL_ID" --project="$PROJECT" --format="value(settings.userLabels.environment)" 2>/dev/null || echo "")

                if [ "$ENV_LABEL" == "non-prod" ]; then
                    STATE=$(gcloud sql instances describe "$SQL_ID" --project="$PROJECT" --format="value(state)" 2>/dev/null || echo "")

                    if [ "$STATE" == "RUNNABLE" ]; then
                        {
                            echo ""
                            echo "------------------------------------------------------"
                            echo "Cloud SQL Instance Backup (Project: $PROJECT)"
                            echo "Instance Name : $SQL_ID"
                            echo "------------------------------------------------------"
                        } >> "$LOG_FILE"

                        # Fetch service account and grant access
                        SQL_SA=$(gcloud sql instances describe "$SQL_ID" --project="$PROJECT" --format="value(serviceAccountEmailAddress)" 2>/dev/null)

                        if [ -n "$SQL_SA" ]; then
                            echo "Granting bucket write permissions to Cloud SQL Service Account: $SQL_SA" >> "$LOG_FILE"
                            gsutil iam ch "serviceAccount:${SQL_SA}:objectAdmin" "gs://$STORAGE_BUCKET_NAME" >> "$LOG_FILE" 2>&1
                        else
                            echo "WARNING: Could not fetch service account for $SQL_ID. Export might fail." >> "$LOG_FILE"
                        fi

                        BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
                        DUMP_FILE_URI="gs://$STORAGE_BUCKET_NAME/sql_dumps/${PROJECT}_${SQL_ID}_${BACKUP_TIMESTAMP}.sql.gz"

                        echo "Exporting Cloud SQL database directly to GCS: $DUMP_FILE_URI" >> "$LOG_FILE"

                        gcloud sql export sql "$SQL_ID" "$DUMP_FILE_URI" --project="$PROJECT" --quiet >> "$LOG_FILE" 2>&1

                        if [ $? -eq 0 ]; then
                            echo "SUCCESS: Cloud SQL export completed successfully." >> "$LOG_FILE"

                            echo "Deleting Cloud SQL instance: $SQL_ID" >> "$LOG_FILE"
                            gcloud sql instances delete "$SQL_ID" --project="$PROJECT" --quiet > /dev/null 2>&1

                            if [ $? -eq 0 ]; then
                                echo "SUCCESS: Cloud SQL $SQL_ID deleted." >> "$LOG_FILE"
                            else
                                echo "ERROR: Failed to delete Cloud SQL $SQL_ID." >> "$LOG_FILE"
                            fi
                        else
                            echo "CRITICAL ERROR: Cloud SQL export failed. SKIPPING DELETION of $SQL_ID." >> "$LOG_FILE"
                        fi
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
