#!/bin/bash

# Function to send an SMS
send_sms() {
    local phone="$1"
    local sms_message="$2"
    curl -X POST https://textbelt.com/text \
         --data-urlencode phone="${phone}" \
         --data-urlencode message="${sms_message}" \
         -d key=7f38d58d46dc157881d892aa5489e0e416d62331wEHCKusY15hEfcG1VtYDccaoT
}

# Function to upload a file to Dropbox and handle errors
upload_to_dropbox() {
    local source_file="$1"
    local destination_path="$2"
    local application_name="$3"
    local error_message=""

    # Upload the file to Dropbox
    cd /root/dropbox && ./dropbox_uploader.sh upload "$source_file" "$destination_path" >/dev/null

    # Check the exit code to determine if the upload was successful
    if [[ $? -ne 0 ]]; then
        error_message="Error occurred while uploading $application_name to Dropbox."
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $error_message" >> ~/scripts/error_log.txt  # Log error message
        send_sms "+32495783990" "$error_message"  # Send SMS notification
    fi
}

# wp cli update >/dev/null

for user in $(find /home -maxdepth 1 -type d); do
    if [[ $user != "." ]] && [[ -d "${user}/webapps" ]]; then
        for web_application in $(find "${user}/webapps" -maxdepth 1 -type d); do
            if [[ $web_application != "${user}/webapps" ]]; then
                cd ${web_application}
                application_name=$(echo ${web_application} | cut -d / -f 5)
                # echo "Working on ${application_name}..."
                if [[ -e "${web_application}/wp-config.php" ]]; then
                    # Backup WordPress MySQL
                    sudo -u ${user/\/home\//} wp db export - | gzip > ./${application_name}_db_backup.sql.gz
                    upload_to_dropbox "${web_application}/${application_name}_db_backup.sql.gz" "/${user/\/home\//}/${application_name}/${application_name}_db_backup.sql.gz" "$application_name"
                    cd ${web_application} && rm ${application_name}_db_backup.sql.gz

                    # Backup WordPress files
                    cd "${user}/webapps" && tar -C "${user}/webapps" -czf "${application_name}_website_backup.tar.gz" "${application_name}/" >/dev/null
                    upload_to_dropbox "${user}/webapps/${application_name}_website_backup.tar.gz" "/${user/\/home\//}/${application_name}/${application_name}_website_backup.tar.gz" "$application_name"
                    cd "${user}/webapps" && rm ${application_name}_website_backup.tar.gz
                else
                    # Backup website application files
                    cd "${user}/webapps" && tar -C "${user}/webapps" -czf "${application_name}_website_backup.tar.gz" "${application_name}/" >/dev/null
                    upload_to_dropbox "${user}/webapps/${application_name}_website_backup.tar.gz" "/${user/\/home\//}/${application_name}/${application_name}_website_backup.tar.gz" "$application_name"
                    cd "${user}/webapps" && rm ${application_name}_website_backup.tar.gz
                fi
            fi
        done
    fi
done
