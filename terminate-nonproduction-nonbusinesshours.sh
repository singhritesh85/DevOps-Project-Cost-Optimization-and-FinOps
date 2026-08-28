#!/bin/bash

# -----------------------------
# Configuration
# -----------------------------
EMAIL_TO="abc@gmail.com"
EMAIL_FROM="DevOps Team <devopsteam@explicate-devops.com>"
SUBJECT="AWS Non-Prod Backup and Delete Summary"
LOG_FILE="/tmp/aws_backup_delete_summary.log"

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
if [ "$TIME" -ge 2000 ] || [ "$TIME" -lt 0730 ]; then

    {
        echo "AWS NON-PROD BACKUP AND DELETE EXECUTION LOG"
        echo "======================================================"
        echo "Execution Time : $(date)"
        echo "IST Time       : $TIME_DISPLAY"
        echo "Action         : Backup EC2/RDS and delete resources"
        echo "======================================================"
        echo ""
    } >> "$LOG_FILE"

        # ========================================================
    # Get AWS account ID
    # ========================================================
    ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)

    echo "AWS Account ID: $ACCOUNT_ID" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"

    # ========================================================
    # Get all AWS regions
    # ========================================================
    REGIONS=$(aws ec2 describe-regions --query 'Regions[].RegionName' --output text)

    # ========================================================
    # Process every region
    # ========================================================
    for REGION in $REGIONS; do

        {
            echo ""
            echo "======================================================"
            echo "Checking Region: $REGION"
            echo "======================================================"
        } >> "$LOG_FILE"

        # ====================================================
        # 1. HANDLE EC2 INSTANCES
        # ====================================================

        EC2_DATA=$(aws ec2 describe-instances --region "$REGION" --filters "Name=tag:Environment,Values=non-prod" "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].[InstanceId, Tags[?Key=='Name'].Value | [0]]" --output text)

        if [ -n "$EC2_DATA" ]; then

            echo "$EC2_DATA" | while read -r INSTANCE_ID INSTANCE_NAME; do

                if [ -z "$INSTANCE_NAME" ] || [ "$INSTANCE_NAME" = "None" ]; then
                    INSTANCE_NAME="Unnamed"
                fi

                {
                    echo ""
                    echo "------------------------------------------------------"
                    echo "EC2 Instance"
                    echo "Instance ID   : $INSTANCE_ID"
                    echo "Instance Name : $INSTANCE_NAME"
                    echo "Region        : $REGION"
                    echo "------------------------------------------------------"
                } >> "$LOG_FILE"

                # ------------------------------------------------
                # Get EC2 instance details
                # ------------------------------------------------
                INSTANCE_STATE=$(aws ec2 describe-instances --region "$REGION" --instance-ids "$INSTANCE_ID" --query "Reservations[0].Instances[0].State.Name" --output text)

                if [ "$INSTANCE_STATE" != "running" ]; then
                    echo "Skipping $INSTANCE_ID because state is $INSTANCE_STATE" >> "$LOG_FILE"
                    continue
                fi

                # ------------------------------------------------
                # Create AMI
                # ------------------------------------------------
                AMI_NAME="non-prod-${INSTANCE_NAME}-${INSTANCE_ID}-$(date +%Y%m%d-%H%M%S)"

                echo "Creating AMI: $AMI_NAME" >> "$LOG_FILE"

                AMI_ID=$(aws ec2 create-image --region "$REGION" --instance-id "$INSTANCE_ID" --name "$AMI_NAME" --description "Backup before deleting non-prod EC2 $INSTANCE_ID" --no-reboot --query 'ImageId' --output text 2>> "$LOG_FILE")

                if [ $? -ne 0 ] || [ -z "$AMI_ID" ] || [ "$AMI_ID" = "None" ]; then
                    echo "ERROR: Failed to create AMI for $INSTANCE_ID" >> "$LOG_FILE"
                    echo "Skipping deletion of $INSTANCE_ID." >> "$LOG_FILE"
                    continue
                fi

                echo "AMI created successfully: $AMI_ID" >> "$LOG_FILE"

                # ------------------------------------------------
                # Wait for AMI to become available
                # ------------------------------------------------
                echo "Waiting for AMI $AMI_ID to become available..." >> "$LOG_FILE"

                if aws ec2 wait image-available --region "$REGION" --image-ids "$AMI_ID"; then

                    echo "AMI $AMI_ID is available." >> "$LOG_FILE"

                else
                    echo "ERROR: AMI $AMI_ID did not become available." >> "$LOG_FILE"
                    echo "Skipping deletion of EC2 $INSTANCE_ID." >> "$LOG_FILE"
                    continue
                fi

                # ------------------------------------------------
                # Add backup tags to AMI
                # ------------------------------------------------
                aws ec2 create-tags --region "$REGION" --resources "$AMI_ID" --tags Key=Name,Value="$INSTANCE_NAME-deleted-on-$(date +%Y-%m-%d)" Key=Environment,Value=non-prod Key=BackupType,Value=PreDelete Key=SourceInstance,Value="$INSTANCE_ID" Key=BackupDate,Value="$(date +%Y-%m-%d)" >> "$LOG_FILE" 2>&1

                # ------------------------------------------------
                # Terminate EC2
                # ------------------------------------------------
                echo "Terminating EC2 instance: $INSTANCE_ID" >> "$LOG_FILE"

                if aws ec2 terminate-instances --region "$REGION" --instance-ids "$INSTANCE_ID" > /dev/null 2>> "$LOG_FILE"; then

                    echo "SUCCESS: EC2 $INSTANCE_ID termination initiated." >> "$LOG_FILE"

                else
                    echo "ERROR: Failed to terminate EC2 $INSTANCE_ID." >> "$LOG_FILE"
                fi

            done

        else
            echo "No running non-prod EC2 instances found in $REGION." >> "$LOG_FILE"
        fi


        # ====================================================
        # 2. HANDLE RDS INSTANCES
        # ====================================================

        RDS_DATA=$(aws rds describe-db-instances --region "$REGION" --query "DBInstances[?DBInstanceStatus=='available'].{ID:DBInstanceIdentifier,ARN:DBInstanceArn}" --output text)

        if [ -n "$RDS_DATA" ]; then

            while read -r RDS_ARN RDS_ID; do

                [ -z "$RDS_ID" ] && continue

                # ------------------------------------------------
                # Check Environment tag
                # ------------------------------------------------
                ENVIRONMENT=$(aws rds list-tags-for-resource --region "$REGION" --resource-name "$RDS_ARN" --query "TagList[?Key=='Environment'].Value | [0]" --output text)

                if [ "$ENVIRONMENT" != "non-prod" ]; then
                    continue
                fi

                {
                    echo ""
                    echo "------------------------------------------------------"
                    echo "RDS Instance"
                    echo "RDS ID       : $RDS_ID"
                    echo "Region       : $REGION"
                    echo "Environment  : $ENVIRONMENT"
                    echo "------------------------------------------------------"
                } >> "$LOG_FILE"

                # ------------------------------------------------
                # Create final RDS snapshot
                # ------------------------------------------------
                SNAPSHOT_ID="${RDS_ID}-pre-delete-$(date +%Y%m%d-%H%M%S)"

                echo "Creating final RDS snapshot: $SNAPSHOT_ID" >> "$LOG_FILE"

                SNAPSHOT_RESULT=$(aws rds create-db-snapshot --region "$REGION" --db-instance-identifier "$RDS_ID" --db-snapshot-identifier "$SNAPSHOT_ID" --query 'DBSnapshot.DBSnapshotIdentifier' --output text 2>> "$LOG_FILE")

                if [ $? -ne 0 ] || [ -z "$SNAPSHOT_RESULT" ] || [ "$SNAPSHOT_RESULT" = "None" ]; then
                    echo "ERROR: Failed to create RDS snapshot for $RDS_ID." >> "$LOG_FILE"
                    echo "Skipping deletion of RDS $RDS_ID." >> "$LOG_FILE"
                    continue
                fi

                echo "RDS snapshot created: $SNAPSHOT_ID" >> "$LOG_FILE"

                # ------------------------------------------------
                # Wait for snapshot to complete
                # ------------------------------------------------
                echo "Waiting for RDS snapshot $SNAPSHOT_ID to complete..." >> "$LOG_FILE"

                if aws rds wait db-snapshot-available --region "$REGION" --db-snapshot-identifier "$SNAPSHOT_ID"; then

                    echo "RDS snapshot $SNAPSHOT_ID is available." >> "$LOG_FILE"

                else
                    echo "ERROR: RDS snapshot $SNAPSHOT_ID did not become available." >> "$LOG_FILE"
                    echo "Skipping deletion of RDS $RDS_ID." >> "$LOG_FILE"
                    continue
                fi

                # ------------------------------------------------
                # Add snapshot tags
                # ------------------------------------------------
                aws rds add-tags-to-resource --region "$REGION" --resource-name "arn:aws:rds:$REGION:$ACCOUNT_ID:snapshot:$SNAPSHOT_ID" --tags Key=Environment,Value=non-prod Key=BackupType,Value=PreDelete Key=SourceDB,Value="$RDS_ID" Key=BackupDate,Value="$(date +%Y-%m-%d)" >> "$LOG_FILE" 2>&1

                # ------------------------------------------------
                # Delete RDS instance
                # ------------------------------------------------
                echo "Deleting RDS instance: $RDS_ID" >> "$LOG_FILE"

                if aws rds delete-db-instance --region "$REGION" --db-instance-identifier "$RDS_ID" --skip-final-snapshot > /dev/null 2>> "$LOG_FILE"; then

                    echo "SUCCESS: RDS $RDS_ID deletion initiated." >> "$LOG_FILE"

                else
                    echo "ERROR: Failed to delete RDS $RDS_ID." >> "$LOG_FILE"
                fi

            done <<< "$RDS_DATA"

        else
            echo "No available RDS instances found in $REGION." >> "$LOG_FILE"
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
