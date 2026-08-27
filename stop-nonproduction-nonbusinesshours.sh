#!/bin/bash

# Configuration
EMAIL_TO="abc@gmail.com"
SUBJECT="AWS Non-Prod Resource Scheduler Summary"
LOG_FILE="/tmp/aws_shutdown_summary.log"

# Clear previous log file
> "$LOG_FILE"

# Get current time in standard 12-hour AM/PM format (e.g., 08:30 PM)
TIME_DISPLAY=$(TZ="Asia/Kolkata" date "+%I:%M %p")

TIME=$(TZ="Asia/Kolkata" date +%H%M)

# 8:00 PM to 7:30 AM IST
if [ "$TIME" -ge 2000 ] || [ "$TIME" -lt 0730 ]; then

    {
        echo "AWS Resource Scheduler Execution Log"
        echo "=========================================="
        echo "Execution Time: $(date)"
        echo "IST Time Check: $TIME_DISPLAY"
        echo "Action: Stopping non-prod instances..."
        echo "=========================================="
        echo ""
    } >> "$LOG_FILE"

    REGIONS=$(aws ec2 describe-regions --query 'Regions[].RegionName' --output text)

    for REGION in $REGIONS; do
        {
            echo "--------------------------------------------------"
            echo "Checking region: $REGION"
        } >> "$LOG_FILE"

        # ==========================================
        # 1. HANDLE EC2 INSTANCES
        # ==========================================
        EC2_DATA=$(aws ec2 describe-instances --region "$REGION" --filters "Name=tag:Environment,Values=non-prod" "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].[InstanceId, Tags[?Key=='Name'].Value | [0]]" --output text)

        if [ -n "$EC2_DATA" ]; then
            echo "$EC2_DATA" | while read -r INSTANCE_ID INSTANCE_NAME; do
                [ -z "$INSTANCE_NAME" ] || [ "$INSTANCE_NAME" = "None" ] && INSTANCE_NAME="Unnamed"

                echo "Stopping EC2 instance: $INSTANCE_NAME ($INSTANCE_ID) in $REGION" >> "$LOG_FILE"
                aws ec2 stop-instances --region "$REGION" --instance-ids "$INSTANCE_ID" > /dev/null
            done
        else
            echo "No running non-prod EC2 instances found in $REGION." >> "$LOG_FILE"
        fi

        # ==========================================
        # 2. HANDLE RDS INSTANCES
        # ==========================================
        RDS_INSTANCES=$(aws rds describe-db-instances --region "$REGION" --query "DBInstances[?DBInstanceStatus=='available' && TagList[?Key=='Environment' && Value=='non-prod']].DBInstanceIdentifier" --output text)

        if [ -n "$RDS_INSTANCES" ] && [ "$RDS_INSTANCES" != "None" ]; then
            for RDS_ID in $RDS_INSTANCES; do
                echo "Stopping RDS instance: $RDS_ID in $REGION" >> "$LOG_FILE"
                aws rds stop-db-instance --region "$REGION" --db-instance-identifier "$RDS_ID" > /dev/null
            done
        else
            echo "No running non-prod RDS instances found in $REGION." >> "$LOG_FILE"
        fi
    done

    # ==========================================
    # 3. SEND EMAIL VIA MAIL COMMAND
    # ==========================================
    echo "Sending email summary to $EMAIL_TO..."

    if command -v mail &> /dev/null; then
        # Sends the text contents of LOG_FILE with the specified subject
        mail -r "DevOps Team <xyz@gmail.com>" -s "$SUBJECT" "$EMAIL_TO" < "$LOG_FILE"
    else
        echo "Error: The 'mail' command was not found on this system." >> "$LOG_FILE"
    fi

else
    echo "IST time is $TIME_DISPLAY. Working hours - nothing to do."
fi
