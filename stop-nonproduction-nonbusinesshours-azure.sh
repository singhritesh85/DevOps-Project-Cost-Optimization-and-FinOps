#!/bin/bash

# ==========================================================
# Stops non-prod Azure VMs during non-working hours
# ==========================================================

# Configuration
EMAIL_TO="abc@gmail.com"
SUBJECT="Azure Non-Prod Resource Scheduler Summary"
LOG_FILE="/tmp/azure_shutdown_summary.log"

# Clear previous log file
> "$LOG_FILE"

# ==========================================================
# Get current time in IST
# ==========================================================

TIME_DISPLAY=$(TZ="Asia/Kolkata" date "+%I:%M %p")
TIME=$(TZ="Asia/Kolkata" date +%H%M)

# ==========================================================
# 8:00 PM to 7:30 AM IST
# ==========================================================

if [ "$TIME" -ge 2000 ] || [ "$TIME" -lt 0730 ]; then

    {
        echo "Azure Resource Scheduler Execution Log"
        echo "=========================================="
        echo "Execution Time: $(date)"
        echo "IST Time Check: $TIME_DISPLAY"
        echo "Action: Stopping non-prod Azure VMs..."
        echo "=========================================="
        echo ""
    } >> "$LOG_FILE"

    # ======================================================
    # Check Azure Login
    # ======================================================

    if ! az account show &> /dev/null; then
        echo "ERROR: Azure CLI is not authenticated." >> "$LOG_FILE"
        echo "Please run 'az login' before running this script." >> "$LOG_FILE"
        exit 1
    fi

    # ======================================================
    # Get all enabled Azure subscriptions
    # ======================================================

    SUBSCRIPTIONS=$(az account list --query "[?state=='Enabled'].id" --output tsv)

    if [ -z "$SUBSCRIPTIONS" ]; then
        echo "No enabled Azure subscriptions found." >> "$LOG_FILE"
        exit 1
    fi

    # ======================================================
    # Process each subscription
    # ======================================================

    for SUBSCRIPTION_ID in $SUBSCRIPTIONS; do

        SUBSCRIPTION_NAME=$(az account show --subscription "$SUBSCRIPTION_ID" --query "name" --output tsv 2>/dev/null)

        {
            echo ""
            echo "--------------------------------------------------"
            echo "Subscription: $SUBSCRIPTION_NAME"
            echo "Subscription ID: $SUBSCRIPTION_ID"
            echo "--------------------------------------------------"
        } >> "$LOG_FILE"

        # Set subscription
        az account set --subscription "$SUBSCRIPTION_ID"

        # ==================================================
        # 1. HANDLE AZURE VIRTUAL MACHINES
        # ==================================================

        echo "" >> "$LOG_FILE"
        echo "Checking running non-prod Azure VMs..." >> "$LOG_FILE"

        VMS=$(az vm list --subscription "$SUBSCRIPTION_ID" --show-details --query "[?powerState=='VM running' && tags.Environment=='non-prod'].[name,resourceGroup,location]" --output tsv)

        if [ -n "$VMS" ]; then

            echo "$VMS" | while IFS=$'\t' read -r VM_NAME RESOURCE_GROUP LOCATION; do

                [ -z "$VM_NAME" ] && VM_NAME="Unnamed"

                {
                    echo "Stopping Azure VM: $VM_NAME"
                    echo "Resource Group: $RESOURCE_GROUP"
                    echo "Location: $LOCATION"
                } >> "$LOG_FILE"

                # Stop/deallocate VM
                if az vm deallocate --subscription "$SUBSCRIPTION_ID" --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --no-wait; then

                    echo "SUCCESS: Stop command submitted for VM: $VM_NAME" >> "$LOG_FILE"

                else

                    echo "ERROR: Failed to stop VM: $VM_NAME" >> "$LOG_FILE"

                fi

                echo "" >> "$LOG_FILE"

            done

        else

            echo "No running non-prod Azure VMs found in subscription $SUBSCRIPTION_NAME." >> "$LOG_FILE"

        fi

        # ==================================================
        # 2. CHECK AND STOP NON-PROD AZURE MYSQL FLEXIBLE SERVERS
        # ==================================================

        echo "" >> "$LOG_FILE"
        echo "Checking non-prod Azure Database for MySQL Flexible Servers..." >> "$LOG_FILE"

        MYSQL_DATABASES=$(az resource list --subscription "$SUBSCRIPTION_ID" --resource-type "Microsoft.DBforMySQL/flexibleServers" --query "[?tags.Environment=='non-prod'].[name,resourceGroup,id]" --output tsv)

        if [ -n "$MYSQL_DATABASES" ]; then

            echo "$MYSQL_DATABASES" | while IFS=$'\t' read -r DB_NAME RESOURCE_GROUP DB_ID; do

                echo "Non-prod Azure Database for MySQL Flexible Server found:" >> "$LOG_FILE"
                echo "Database: $DB_NAME" >> "$LOG_FILE"
                echo "Resource Group: $RESOURCE_GROUP" >> "$LOG_FILE"
                echo "Resource ID: $DB_ID" >> "$LOG_FILE"

                echo "Stopping MySQL Flexible Server: $DB_NAME..." >> "$LOG_FILE"

                if az mysql flexible-server stop --subscription "$SUBSCRIPTION_ID" --resource-group "$RESOURCE_GROUP" --name "$DB_NAME" >> "$LOG_FILE" 2>&1; then

                    echo "Successfully stopped: $DB_NAME" >> "$LOG_FILE"

                else

                    echo "ERROR: Failed to stop: $DB_NAME" >> "$LOG_FILE"

                fi

                echo "" >> "$LOG_FILE"

            done

        else

            echo "No non-prod Azure Database for MySQL Flexible Servers found in subscription $SUBSCRIPTION_NAME." >> "$LOG_FILE"

        fi
    done

    # ======================================================
    # 3. SEND EMAIL SUMMARY
    # ======================================================

    echo "Sending email summary to $EMAIL_TO..."

    if command -v mail &> /dev/null; then

        mail -r "DevOps Team <xyz@gmail.com>" -s "$SUBJECT" "$EMAIL_TO" < "$LOG_FILE"

        if [ $? -eq 0 ]; then
            echo "Email sent successfully to $EMAIL_TO."
        else
            echo "ERROR: Failed to send email." >> "$LOG_FILE"
        fi

    else

        echo "ERROR: The 'mail' command was not found on this system." >> "$LOG_FILE"

    fi

else

    echo "IST time is $TIME_DISPLAY. Working hours - nothing to do."

fi
