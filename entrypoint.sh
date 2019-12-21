#!/bin/bash

echo "Starting docker runtime.."

# turn on debug mode > https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -euxo pipefail

ls -al

if [ ! -d "/bench/bench" ]; then
    echo "No bench detecting, initializing now..."
    cd /bench
    sudo chmod 777 .
    bench init bench --frappe-path https://github.com/ViableClanMember/frappe --frappe-branch version-12
    cd bench
    bench get-app erpnext https://github.com/frappe/erpnext --branch version-12
fi;

cp -f /home/frappe/common_site_config.json /bench/bench/sites/
DB_PASS=$(cat /secrets/DB_PASS || true)
if [ -z "$DB_PASS" ]
then
  echo "DB_PASS is empty, trying rancher 1.x..."
  ls -al /run/secrets
  DB_PASS=$(cat /run/secrets/DB_PASS || true)
  if [ -z "$DB_PASS" ]
  then
    echo "DB_PASS is empty, giving up!"
    exit 129
  else
    echo "DB_PASS is NOT empty"
  fi
else
  echo "DB_PASS is NOT empty"
fi
sh -c 'cd /bench/bench && bench config set-common-config -c root_password $DB_PASS'


# TODO: needs redis running
# bench update --patch

ls -al

# start supervisor
sudo /usr/bin/supervisord -c /home/frappe/supervisor.conf
