#! /bin/bash

# wp cli update >/dev/null

for user in `find /home -maxdepth 1 -type d`; do
  if [[ $user != "." ]] && [[ -d "${user}/webapps" ]]; then
    for web_application in `find "${user}/webapps" -maxdepth 1 -type d`; do
      if [[ $web_application != "${user}/webapps" ]] && [[ ${user/\/home\//} != "arthur" ]]; then
        cd ${web_application}
        application_name=`echo ${web_application} | cut -d / -f 5`
        # echo "Working on ${application_name}..."
        if [[ -e "${web_application}/wp-config.php" ]]; then
          # Backup WordPress MySQL
          sudo -u ${user/\/home\//} wp db export - | gzip > ./${application_name}_db_backup.sql.gz
          cd /root/dropbox && ./dropbox_uploader.sh upload "${web_application}/${application_name}_db_backup.sql.gz" "/${user/\/home\//}/${application_name}/${application_name}_db_backup.sql.gz" >/dev/null
          cd ${web_application} && rm ${application_name}_db_backup.sql.gz

          # Backup WordPress files
          cd "${user}/webapps" && tar -C "${user}/webapps" -czf "${application_name}_website_backup.tar.gz" "${application_name}/" >/dev/null
          cd /root/dropbox && ./dropbox_uploader.sh upload "${user}/webapps/${application_name}_website_backup.tar.gz" "/${user/\/home\//}/${application_name}/${application_name}_website_backup.tar.gz" >/dev/null
          cd "${user}/webapps" && rm ${application_name}_website_backup.tar.gz

          # Update WordPress plugins & core
          cd ${web_application} && sudo -u ${user/\/home\//} wp plugin update --all --exclude=woocommerce --quiet &>/dev/null && sudo -u ${user/\/home\//} wp core update --quiet &>/dev/null
          sudo -u ${user/\/home\//} wp transient delete --expired --quiet &>/dev/null
          sudo -u ${user/\/home\//} wp db optimize --quiet &>/dev/null
        else
          # Backup website application files
          cd "${user}/webapps" && tar -C "${user}/webapps" -czf "${application_name}_website_backup.tar.gz" "${application_name}/" >/dev/null
          cd /root/dropbox && ./dropbox_uploader.sh upload "${user}/webapps/${application_name}_website_backup.tar.gz" "/${user/\/home\//}/${application_name}/${application_name}_website_backup.tar.gz" >/dev/null
          cd "${user}/webapps" && rm ${application_name}_website_backup.tar.gz
        fi
      fi
    done
  fi
done
