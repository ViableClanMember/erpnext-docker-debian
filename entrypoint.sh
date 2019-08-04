#!/bin/bash

echo "Starting docker runtime.."

# turn on debug mode > https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -euxo pipefail

ls -al

if [ ! -d "/bench/bench" ]; then
    echo "No bench detecting, initializing now..."
    cd /bench
    sudo chmod 777 .
    bench init bench --frappe-path https://github.com/ViableClanMember/frappe --frappe-branch master
    cd bench
    bench get-app erpnext https://github.com/frappe/erpnext --branch version-12 || echo "Failed to install erpnext app"
    bench update --patch || echo "Failed to update patch hack"
fi;

cp -f /home/frappe/common_site_config.json /bench/bench/sites/
DB_PASS=$(cat /secrets/DB_PASS) sh -c 'bench config set-common-config -c root_password $DB_PASS'
ls -al

# start supervisor
sudo /usr/bin/supervisord -c /home/frappe/supervisor.conf
