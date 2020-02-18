#! /bin/bash

wp cli update >/dev/null

# Serverpilot 
for user in `find /srv/users -maxdepth 1 -type d`; do
  if [[ $user != "." ]] && [[ -d "${user}/apps" ]]; then
    for web_application in `find "${user}/apps" -maxdepth 1 -type d`; do
      if [[ $web_application != "${user}/apps" ]] && [[ ${user/\/srv\/users\//} != "harvey" ]]; then
        cd "${web_application}/public"
        application_name=`echo ${web_application} | cut -d / -f 6`
        echo "Updating ${application_name}..."
        if [[ -e "${web_application}/public/wp-config.php" ]]; then
          cd "${web_application}/public"
          sudo -u ${user/\/srv\/users\//} wp plugin delete iwp-client wp-migrate-db wp-time-capsule
        fi
      fi
    done
  fi
done

# Runcloud
for user in `find /home -maxdepth 1 -type d`; do
  if [[ $user != "." ]] && [[ -d "${user}/webapps" ]]; then
    for web_application in `find "${user}/webapps" -maxdepth 1 -type d`; do
      if [[ $web_application != "${user}/webapps" ]] && [[ ${user/\/home\//} != "norman" ]]; then
        cd ${web_application}
        application_name=`echo ${web_application} | cut -d / -f 5`
        echo "Updating ${application_name}..."
        if [[ -e "${web_application}/wp-config.php" ]]; then
          cd "${web_application}"
          sudo -u ${user/\/home\//} wp plugin delete iwp-client wp-migrate-db wp-time-capsule
        fi
      fi
    done
  fi
done
